#!/bin/bash
# Richtet die Sperrbildschirm-Anzeige (Live Activity) im iOS-Projekt ein.
# Aufruf am Mac im Ordner capacitor/:   bash scripts/setup-live-activity.sh
# Kann beliebig oft laufen (aendert nichts doppelt).
set -e
cd "$(dirname "$0")/.."

APP=ios/App/App
PROJ=ios/App/App.xcodeproj/project.pbxproj
NATIVE=native

if [ ! -d "$APP" ]; then
  echo "FEHLER: ios/ fehlt. Erst 'npx cap add ios' und 'npm run sync' ausfuehren."
  exit 1
fi

# 1) App: Plugin-Code ans Ende von AppDelegate.swift
if grep -q "LiveRoundPlugin" "$APP/AppDelegate.swift"; then
  echo "- AppDelegate.swift: Plugin schon drin"
else
  printf '\n' >> "$APP/AppDelegate.swift"
  cat "$NATIVE/LiveRoundApp.swift" >> "$APP/AppDelegate.swift"
  echo "- AppDelegate.swift: Plugin angehaengt"
fi

# 2) Start-Controller austauschen (SceneDelegate + Storyboard)
if [ -f "$APP/SceneDelegate.swift" ]; then
  sed -i.bak 's/CAPBridgeViewController()/LiveRoundViewController()/' "$APP/SceneDelegate.swift"
  rm -f "$APP/SceneDelegate.swift.bak"
  echo "- SceneDelegate.swift: LiveRoundViewController gesetzt"
fi
if [ -f "$APP/Base.lproj/Main.storyboard" ]; then
  sed -i.bak 's/customClass="CAPBridgeViewController" customModule="Capacitor"/customClass="LiveRoundViewController" customModule="App"/' "$APP/Base.lproj/Main.storyboard"
  rm -f "$APP/Base.lproj/Main.storyboard.bak"
  echo "- Main.storyboard: customClass gesetzt"
fi

# 3) Info.plist: Live Activities erlauben
/usr/libexec/PlistBuddy -c "Add :NSSupportsLiveActivities bool true" "$APP/Info.plist" 2>/dev/null \
  || /usr/libexec/PlistBuddy -c "Set :NSSupportsLiveActivities true" "$APP/Info.plist"
echo "- Info.plist: NSSupportsLiveActivities = true"

# 4) Mindest-iOS 16.2 fuer alle Targets (App + Widget)
sed -i.bak 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]*;/IPHONEOS_DEPLOYMENT_TARGET = 16.2;/' "$PROJ"
rm -f "$PROJ.bak"
echo "- Xcode-Projekt: Mindest-iOS 16.2"

# 5) Widget-Extension: Wizard-Dateien durch unseren Code ersetzen
WIDGET=$(find ios/App -maxdepth 1 -type d -name "*Widget*" | head -1)
if [ -z "$WIDGET" ]; then
  echo ""
  echo "HINWEIS: Noch kein Widget-Ordner gefunden."
  echo "Erst in Xcode: File > New > Target > Widget Extension (Name: PocketCaddyWidget,"
  echo "Haken bei 'Include Live Activity'), danach dieses Skript nochmal ausfuehren."
  exit 0
fi

BUNDLE=$(find "$WIDGET" -maxdepth 1 -name "*Bundle.swift" | head -1)
LIVE=$(find "$WIDGET" -maxdepth 1 -name "*LiveActivity.swift" | head -1)
if [ -z "$BUNDLE" ] || [ -z "$LIVE" ]; then
  echo "FEHLER: In $WIDGET fehlen *Bundle.swift / *LiveActivity.swift."
  echo "Wurde 'Include Live Activity' im Xcode-Wizard angehakt?"
  exit 1
fi

cp "$NATIVE/PocketCaddyWidgetBundle.swift" "$BUNDLE"
cp "$NATIVE/PocketCaddyWidgetLiveActivity.swift" "$LIVE"
for f in "$WIDGET"/*.swift; do
  if [ "$f" != "$BUNDLE" ] && [ "$f" != "$LIVE" ]; then
    echo "// ersetzt durch setup-live-activity.sh" > "$f"
  fi
done
echo "- Widget ($WIDGET): Bundle + Live Activity eingespielt"
echo ""
echo "Fertig. In Xcode oben Scheme 'App' waehlen und auf Play druecken."
