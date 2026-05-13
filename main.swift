import Cocoa
import WebKit
import Photos
import CoreLocation

final class PhotosBridge: NSObject, WKScriptMessageHandler {
    weak var webView: WKWebView?
    private let geocoder = CLGeocoder()

    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              (body["action"] as? String) == "scanPhotos",
              let start = body["start"] as? String,
              let end   = body["end"]   as? String else { return }
        scanPhotos(from: start, to: end)
    }

    private func scanPhotos(from start: String, to end: String) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self else { return }
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    self.js("window.photosError('Kein Zugriff auf Photos.app – bitte in Systemeinstellungen \u{2192} Datenschutz \u{2192} Fotos erlauben.')")
                }
                return
            }
            self.fetchAndGeocode(from: start, to: end)
        }
    }

    private func fetchAndGeocode(from start: String, to end: String) {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        guard let s = fmt.date(from: start),
              let eRaw = fmt.date(from: end),
              let e = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: eRaw)
        else {
            DispatchQueue.main.async { self.js("window.photosError('Ungültiges Datum')") }
            return
        }

        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate <= %@",
                                     s as NSDate, e as NSDate)
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let assets = PHAsset.fetchAssets(with: .image, options: opts)

        var byDate: [String: CLLocation] = [:]
        var noGps = 0
        assets.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            let d = fmt.string(from: date)
            if let loc = asset.location {
                if byDate[d] == nil { byDate[d] = loc }
            } else {
                noGps += 1
            }
        }

        let days = byDate.keys.sorted()
        DispatchQueue.main.async {
            self.js("window.photosProgress && window.photosProgress(0, \(days.count))")
        }
        geocodeDays(days, locations: byDate, noGps: noGps,
                    photoTotal: assets.count, dayTotal: days.count, done: 0, acc: [:])
    }

    private func geocodeDays(_ remaining: [String], locations: [String: CLLocation],
                              noGps: Int, photoTotal: Int, dayTotal: Int, done: Int,
                              acc: [String: String]) {
        guard let day = remaining.first else {
            DispatchQueue.main.async {
                guard let data = try? JSONSerialization.data(withJSONObject: acc),
                      let json = String(data: data, encoding: .utf8) else { return }
                self.js("window.photosResult(\(json), \(noGps), \(photoTotal))")
            }
            return
        }
        let rest = Array(remaining.dropFirst())
        geocoder.reverseGeocodeLocation(locations[day]!) { [weak self] marks, _ in
            guard let self else { return }
            var next = acc
            if let country = marks?.first?.country { next[day] = country }
            let newDone = done + 1
            DispatchQueue.main.async {
                self.js("window.photosProgress && window.photosProgress(\(newDone), \(dayTotal))")
            }
            // CLGeocoder: ~1 Anfrage/Sekunde erlaubt
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.geocodeDays(rest, locations: locations, noGps: noGps,
                                 photoTotal: photoTotal, dayTotal: dayTotal,
                                 done: newDone, acc: next)
            }
        }
    }

    private func js(_ script: String) {
        webView?.evaluateJavaScript(script, completionHandler: nil)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    let bridge = PhotosBridge()

    func applicationDidFinishLaunching(_ n: Notification) {
        let config = WKWebViewConfiguration()
        config.userContentController.add(bridge, name: "photosBridge")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1280, height: 860),
                            configuration: config)
        bridge.webView = webView

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 860),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "JJRs Aufenthaltsrechner 180 / 365"
        window.contentView = webView
        window.setFrameAutosaveName("MainWindow")
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
