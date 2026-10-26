#!/bin/bash
# Prüft die Logik ohne Oberfläche unter Linux: Lernwelt, Vorschule, Stimmen,
# Erklärbilder, Rechenweg, Duell, Handschrift, Familien-Protokoll und Eltern-PIN.
# SwiftUI, SwiftData und AVFoundation gibt es dort nicht. Deshalb schneidet
# pruefen/auszug.py nur die reinen Typen aus den App-Dateien aus.
# Braucht Swift 6.1 oder neuer (SWIFTC=/pfad/zu/swiftc) und Python 3.
# Aufruf aus dem Repo-Ordner: pruefen/linux-tests.sh (Fehler zeigt der Workflow auch als Hinweis)
set -euo pipefail
cd "$(dirname "$0")/.."
SWIFTC="${SWIFTC:-swiftc}"
Y=YEM1N
T=YEM1NTests
arbeit="$(mktemp -d)"
trap 'rm -rf "$arbeit"' EXIT

cat > "$arbeit/start.swift" <<'SWIFT'
import Testing
@main struct Start { static func main() async { await Testing.__swiftPMEntryPoint() as Never } }
SWIFT
ohneApp() { sed -e 's/@testable import YEM1N//' -e 's/^import SwiftData//' "$1"; }

echo "== Lernwelt"
python3 pruefen/auszug.py $Y "$arbeit/lern.swift" \
  Lehrplan.swift:Bundesland,LehrFach,LernAufgabe,LernThema,Schuljahr,Lern,Lernwelt AufgabenBild.swift:Noten \
  Sprachen.swift:SprachInfo,Wort,Thema,SprachKatalog,SprachHelfer SprachKatalog.swift:SprachKatalogDaten \
  MatheEditor.swift:MatheRechner
python3 - "$arbeit" <<'PY'
import sys
a = sys.argv[1]
s = open(f"{a}/lern.swift").read()
i = s.index("    static func gespeichert(")
j = s.index("        return u\n    }\n", i) + len("        return u\n    }\n")
s = s[:i] + s[j:]  # SwiftData-Teil weglassen
# In der App ist alles auf dem Hauptthread. Ohne diese Voreinstellung unter Linux
# braucht es die Markierung nicht.
s = s.replace("@MainActor () -> LernAufgabe", "() -> LernAufgabe")
open(f"{a}/lern.swift", "w").write(s)
t = open("YEM1NTests/LehrplanTests.swift").read().replace("@testable import YEM1N", "").replace("import SwiftData", "")
t = t[:t.index("    // MARK: Speichern als Übung")] + "}\n"
open(f"{a}/LehrplanTests.swift", "w").write(t)
h = open("YEM1NTests/TestHelfer.swift").read()
i = h.index("func zahlen"); j = h.index("\n}\n", i) + 3
open(f"{a}/helfer.swift", "w").write("import Foundation\n" + h[i:j])
PY
"$SWIFTC" -parse-as-library -O -o "$arbeit/lern" "$arbeit/lern.swift" $Y/Lehrplan[A-Z]*.swift \
  "$arbeit/LehrplanTests.swift" "$arbeit/helfer.swift" "$arbeit/start.swift"
laufen() {
  if "$1" > "$arbeit/ausgabe.txt" 2>&1; then
    grep -E "Test run with" "$arbeit/ausgabe.txt" || true
  else
    grep -E "✘|recorded an issue|Test run with" "$arbeit/ausgabe.txt" || cat "$arbeit/ausgabe.txt"
    fehler=1
  fi
}
fehler=0
laufen "$arbeit/lern"

echo "== Vorschule und Stimmen"
python3 pruefen/auszug.py $Y "$arbeit/vor.swift" \
  Vorschule.swift:VorschulArt,VorschulText,VorschulSprache,VorschulFrage,VorschulGenerator,VorschulTon VorschuleMehr.swift:VorschulMehr
ohneApp $T/VorschuleTests.swift > "$arbeit/VorschuleTests.swift"
ohneApp $T/StimmenTests.swift > "$arbeit/StimmenTests.swift"
ohneApp $T/LobTests.swift > "$arbeit/LobTests.swift"
"$SWIFTC" -parse-as-library -O -o "$arbeit/vor" "$arbeit/vor.swift" pruefen/platzhalter.swift \
  $Y/VorleseText.swift $Y/GeraeteStimmeDaten.swift $Y/Lob.swift $Y/VorschulEnglisch.swift \
  "$arbeit/VorschuleTests.swift" "$arbeit/StimmenTests.swift" "$arbeit/LobTests.swift" "$arbeit/start.swift"
laufen "$arbeit/vor"

echo "== Erklärbilder, Rechenweg, Duell, Handschrift"
python3 pruefen/auszug.py $Y "$arbeit/rest.swift" \
  ErklaerBild.swift:ErklaerBild,ErklaerBildPlan MatheEditor.swift:MatheRechner \
  Duell.swift:DuellStufe,DuellAufgabe,DuellStand,DuellRegeln,DuellLauf \
  DuellCloud.swift:DuellHerausforderung,DuellAntwort,DuellPost \
  Cloud.swift:MitteilungsZiel Handschrift.swift:Handschrift
python3 - "$arbeit" <<'PY'
import sys
a = sys.argv[1]
s = open(f"{a}/rest.swift").read()
# Texterkennung und Zeichnen gibt es unter Linux nicht
for anfang in ["    nonisolated static func erkenne(", "    static func bild(von zeichnung: PKDrawing)"]:
    i = s.index(anfang)
    j = s.index("\n    }\n", i) + 7
    s = s[:i] + s[j:]
s += """
final class UIDevice {
    nonisolated(unsafe) static let current = UIDevice()
    enum Art { case phone, pad }
    var userInterfaceIdiom: Art { .phone }
}
final class CKNotification {
    init?(fromRemoteNotificationDictionary: [AnyHashable: Any]) { return nil }
    var subscriptionID: String? { nil }
}
"""
open(f"{a}/rest.swift", "w").write(s)
PY
for f in ErklaerBildTests RechenwegTests DuellTests HandschriftTests; do ohneApp $T/$f.swift > "$arbeit/$f.swift"; done
"$SWIFTC" -parse-as-library -O -o "$arbeit/rest" "$arbeit/rest.swift" $Y/Rechenweg.swift "$arbeit/helfer.swift" \
  "$arbeit/ErklaerBildTests.swift" "$arbeit/RechenwegTests.swift" "$arbeit/DuellTests.swift" "$arbeit/HandschriftTests.swift" "$arbeit/start.swift"
laufen "$arbeit/rest"

echo "== Familie (Protokoll 2) und Eltern-PIN"
ohneApp $T/FamilieTests.swift > "$arbeit/FamilieTests.swift"
"$SWIFTC" -parse-as-library -O -o "$arbeit/fam" $Y/Sha256.swift $Y/FamilienProtokoll.swift $Y/FamilienClient.swift \
  $Y/ElternPin.swift "$arbeit/FamilieTests.swift" "$arbeit/start.swift"
laufen "$arbeit/fam"
exit $fehler
