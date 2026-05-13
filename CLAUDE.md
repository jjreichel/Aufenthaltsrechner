# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Single-file web app (`index.html`) — kein Build-Schritt, keine Dependencies zu installieren. Direkt im Browser öffnen.

```
open index.html
# oder für Foto-Import (Drag & Drop aus Photos.app):
python3 -m http.server 8080
```

## Architektur

Zentraler Zustand ist `dayMap`: ein flaches Objekt `{ "YYYY-MM-DD": "Ländername", ... }`, in `localStorage` unter `stays-180-365-v2` persistiert (Format `{ version: 2, days: dayMap }`). Beim Laden wird automatisch von V1 (Array von Ranges) auf V2 migriert.

### Datenfluss

```
dayMap  →  buildAllDayData()  →  allDayData  →  render*()
```

`buildAllDayData()` berechnet per Prefix-Sum für jeden Tag 2024–2027 das Rolling-365-Fenster: wie viele Tage war man je Land in den vorangegangenen 365 Tagen? Ergebnis ist `allDayData`:

```js
{ "2024-05-13": { sums: { "Deutschland": 42 }, here: "Deutschland"|null, exceed: bool } }
```

`exceed` ist `true`, wenn für _irgendein_ Land `sums[land] > 180`. Tage mit `exceed` erhalten roten Rahmen im Kalender.

### Re-render

Jede Zustandsänderung läuft über `rerender()`:

```
rerender() → buildAllDayData() → renderCountriesDatalist()
                               → renderLogbook()
                               → renderStats()
                               → renderCalendar()
```

### Foto-Import

Pipeline: `processFiles()` → exifr (EXIF-Parse im Browser) → `reverseGeocode()` (bigdatacloud.net, gecacht in `geoCache`) → `openPhotoReview()` (Modal zur Kontrolle) → Import in `dayMap`.

### Farbzuweisung

Länder bekommen Farben aus `COLORS[]` anhand ihrer Sortierposition in `countriesList()` — d. h. die Farbe eines Landes kann sich ändern, wenn ein neues Land mit früherem alphabetischen Rang hinzukommt.

## Externe Abhängigkeiten

| Zweck | URL |
|---|---|
| EXIF-Parse | `cdn.jsdelivr.net/npm/exifr/dist/full.umd.js` |
| Reverse-Geocoding | `api.bigdatacloud.net/data/reverse-geocode-client` |
| Schriften | Google Fonts (Cormorant Garamond, IBM Plex Sans) |
