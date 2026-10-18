#!/usr/bin/env python3
"""Schneidet einzelne Typen ohne Oberfläche aus den App-Dateien aus,
damit der Sammler sie unter Linux übersetzen kann.
Aufruf: auszug.py <App-Ordner> <Ziel-Datei> Datei:Name1,Name2 ..."""
import re, sys

def bloecke(text):
    """Liefert (name, start, ende) für jede Deklaration auf oberster Ebene."""
    i, n, tiefe = 0, len(text), 0
    erg, start, name = [], None, None
    zeile_anfang = True
    while i < n:
        c = text[i]
        # Kommentare und Texte überspringen
        if text.startswith("//", i):
            j = text.find("\n", i); i = n if j < 0 else j; continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2); i = n if j < 0 else j + 2; continue
        if text.startswith('"""', i):
            j = text.find('"""', i + 3); i = n if j < 0 else j + 3; continue
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"' and text[j] != "\n":
                if text[j] == "\\":
                    if j + 1 < n and text[j + 1] == "(":
                        # Einschub \( ... ) mit Klammern zählen
                        k, t = j + 2, 1
                        while k < n and t:
                            if text[k] == "(": t += 1
                            elif text[k] == ")": t -= 1
                            elif text[k] == '"':
                                k += 1
                                while k < n and text[k] != '"': k += 2 if text[k] == "\\" else 1
                            k += 1
                        j = k; continue
                    j += 2; continue
                j += 1
            i = j + 1; continue
        if tiefe == 0 and start is None:
            m = re.match(r"(?:(?:public|private|fileprivate|internal|nonisolated|final|@MainActor|@Observable|@Model)\s+)*"
                         r"(?:struct|enum|class|extension|actor)\s+([A-Za-z_][A-Za-z0-9_.]*)", text[i:])
            if m and (i == 0 or text[i - 1] in "\n"):
                start, name = i, m.group(1)
        if c == "{":
            tiefe += 1
        elif c == "}":
            tiefe -= 1
            if tiefe == 0 and start is not None:
                erg.append((name, start, i + 1)); start = None
        i += 1
    return erg

LITERAL = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
PAAR = re.compile(r'VorschulText\(de:\s*"((?:[^"\\\n]|\\.)*)",\s*tr:\s*"((?:[^"\\\n]|\\.)*)"\)')

def satzartig(roh):
    """Nur ganze Sätze ohne Einschübe, keine Schlüssel oder Bildnamen."""
    if "\\(" in roh or len(roh) < 3:
        return False
    return any(ch.isalpha() for ch in roh) and (" " in roh or roh[-1:] in ".!?")

def feste_saetze(ordner, auftraege):
    """auftraege: Liste von (datei, namen) für Blöcke, deren Texte Olli oder das Tier sprechen."""
    de, tr = [], []
    for datei, namen in auftraege:
        text = open(f"{ordner}/{datei}", encoding="utf-8").read()
        for name, a, e in bloecke(text):
            if namen != "*" and name not in namen.split(","):
                continue
            block = text[a:e]
            paare = PAAR.findall(block)
            for d, t in paare:
                if satzartig(d): de.append(d)
                if satzartig(t): tr.append(t)
            ohne_paare = PAAR.sub("", block)
            if datei.startswith("Vorschule"):
                continue  # dort zählen nur die Paare
            for m in LITERAL.finditer(ohne_paare):
                if satzartig(m.group(1)):
                    de.append(m.group(1))
    def liste(xs):
        return ",\n        ".join('"' + x + '"' for x in dict.fromkeys(xs))
    return ("enum FesteSaetze {\n    static let alle: [(String, [String])] = [\n"
            f'    ("de", [\n        {liste(de)}\n    ]),\n'
            f'    ("tr", [\n        {liste(tr)}\n    ])\n    ]\n}}\n')

def main():
    ordner, ziel, *wuensche = sys.argv[1:]
    teile = ["import Foundation\n"]
    feste = [w[len("feste="):].split(":") for w in wuensche if w.startswith("feste=")]
    wuensche = [w for w in wuensche if not w.startswith("feste=")]
    if feste:
        teile.append(feste_saetze(ordner, feste))
    for w in wuensche:
        datei, namen = w.split(":")
        text = open(f"{ordner}/{datei}", encoding="utf-8").read()
        gefunden = {}
        for name, a, e in bloecke(text):
            gefunden.setdefault(name, []).append(text[a:e])
        for nm in namen.split(","):
            if nm not in gefunden:
                sys.exit(f"{nm} nicht in {datei} gefunden")
            teile.extend(b + "\n" for b in gefunden[nm])
    open(ziel, "w", encoding="utf-8").write("\n".join(teile))

main()
