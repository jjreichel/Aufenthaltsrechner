# JJRs Aufenthaltsrechner 180 / 365

Persönliches Tool zur Überwachung der steuerlichen und aufenthaltsrechtlichen 180/365-Tage-Regel: maximal 180 Aufenthaltstage je Land innerhalb eines rollierenden 365-Tage-Fensters.

Alle Daten verbleiben lokal im Browser (localStorage). Kein Server, keine Konten.

## Funktionalität

### Aufenthalte erfassen

Manuell: Land, Start- und Enddatum eingeben — beide Daten sind inklusiv. Bestehende Einträge werden überschrieben.

Per Klick auf einen Kalendertag: Land direkt setzen oder löschen.

### Foto-Import (Photos.app)

Fotos aus macOS Photos.app per Drag & Drop in die App ziehen oder über den Button auswählen. Das Tool liest GPS-Koordinaten aus dem EXIF-Header und ermittelt daraus automatisch das Land per Reverse-Geocoding.

**Zeitraum-Modus:** Von- und Bis-Datum setzen, dann Fotos ziehen — alle Fotos im Zeitraum werden ohne Rückfrage direkt importiert. Fotos außerhalb des Zeitraums werden ignoriert. Ohne gesetzten Zeitraum erscheint ein Prüfschritt vor dem Import.

Voraussetzung: Fotos im Originalformat (nicht konvertiert), da sonst EXIF-Metadaten fehlen.

### Kalender

Jahresansicht 2024–2027, ein Pixel pro Tag. Tage mit Aufenthalt sind farbig (je Land eine Farbe), Tage an denen für irgendein Land die 180-Tage-Grenze überschritten wird erhalten einen roten Rahmen. Hover zeigt das Rolling-365-Fenster pro Land.

### Status-Karten

Pro erfasstem Land: aktueller Rolling-365-Wert und All-Time-High mit Datum.

## Technisches

Single-file (`index.html`), kein Build-Schritt.

```
open index.html
# für Foto-Drag-Drop aus Photos.app:
python3 -m http.server 8080
```

Externe Abhängigkeiten: [exifr](https://github.com/MikeKovarik/exifr) (EXIF-Parse), [bigdatacloud.net](https://www.bigdatacloud.com/) (Reverse-Geocoding), Google Fonts.

---

*Tool zur eigenen Orientierung — ersetzt weder Steuerberater noch Visumsrecherche.*  
*JJR & SV Viking*
