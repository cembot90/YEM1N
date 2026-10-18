#!/bin/bash
# Prüft die Logik ohne Oberfläche unter Linux: Lernwelt, Vorschule, Stimmen.
# SwiftUI, SwiftData und AVFoundation gibt es dort nicht. Deshalb schneidet
# stimmen/sammeln/auszug.py nur die reinen Typen aus den App-Dateien aus.
# Braucht Swift 6.1 oder neuer (SWIFTC=/pfad/zu/swiftc) und Python 3.
# Aufruf aus dem Repo-Ordner: pruefen/linux-tests.sh
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
python3 stimmen/sammeln/auszug.py $Y "$arbeit/lern.swift" \
  Lehrplan.swift:Bundesland,LehrFach,LernAufgabe,LernThema,Lern,Lernwelt AufgabenBild.swift:Noten \
  Sprachen.swift:SprachInfo,Wort,Thema,SprachKatalog,SprachHelfer SprachKatalog.swift:SprachKatalogDaten \
  MatheEditor.swift:MatheRechner
python3 - "$arbeit" <<'PY'
import sys
a = sys.argv[1]
s = open(f"{a}/lern.swift").read()
i = s.index("    static func gespeichert(")
j = s.index("        return u\n    }\n", i) + len("        return u\n    }\n")
open(f"{a}/lern.swift", "w").write(s[:i] + s[j:])  # SwiftData-Teil weglassen
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
python3 stimmen/sammeln/auszug.py $Y "$arbeit/vor.swift" \
  Vorschule.swift:VorschulArt,VorschulText,VorschulFrage,VorschulGenerator,VorschulTon VorschuleMehr.swift:VorschulMehr
ohneApp $T/VorschuleTests.swift > "$arbeit/VorschuleTests.swift"
ohneApp $T/StimmenTests.swift > "$arbeit/StimmenTests.swift"
"$SWIFTC" -parse-as-library -O -o "$arbeit/vor" "$arbeit/vor.swift" stimmen/sammeln/platzhalter.swift \
  $Y/VorleseText.swift $Y/GeraeteStimmeDaten.swift \
  "$arbeit/VorschuleTests.swift" "$arbeit/StimmenTests.swift" "$arbeit/start.swift"
laufen "$arbeit/vor"
exit $fehler
