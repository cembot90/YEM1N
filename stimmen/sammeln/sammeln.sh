#!/bin/bash
# Sammelt alle Sätze, die die App mit Studio-Stimme vorlesen kann.
# Braucht nur Swift und Python, läuft unter Linux und macOS.
# Aufruf aus dem Repo-Ordner: stimmen/sammeln/sammeln.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
SWIFTC="${SWIFTC:-swiftc}"
arbeit="$(mktemp -d)"
python3 stimmen/sammeln/auszug.py YEM1N "$arbeit/auszug.swift" \
  "feste=Eule.swift:TierStimme" "feste=Haustier.swift:Haustier" \
  "feste=Vorschule.swift:*" "feste=VorschuleMehr.swift:*" \
  Vorschule.swift:VorschulArt,VorschulText,VorschulFrage,VorschulGenerator,VorschulTon \
  VorschuleMehr.swift:VorschulMehr
"$SWIFTC" -O -o "$arbeit/sammler" YEM1N/VorleseText.swift stimmen/sammeln/platzhalter.swift \
  "$arbeit/auszug.swift" stimmen/sammeln/main.swift
mkdir -p stimmen/saetze
"$arbeit/sammler" stimmen/saetze
rm -rf "$arbeit"
