#!/bin/bash
set -e
mkdir -p Aufenthaltsrechner.app/Contents/{MacOS,Resources}
swiftc -framework Cocoa -framework WebKit -framework Photos -framework CoreLocation \
  main.swift -o Aufenthaltsrechner.app/Contents/MacOS/Aufenthaltsrechner
cp index.html Aufenthaltsrechner.app/Contents/Resources/
echo "✓ Build fertig — open Aufenthaltsrechner.app"
