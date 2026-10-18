#!/usr/bin/env python3
"""Baut die Pakete der Gerätestimmen aus den fertigen sherpa-onnx-Modellen.

Lädt die Piper-Stimmen von den Releases von k2-fsa/sherpa-onnx, nimmt nur
die nötigen Dateien und packt sie als einfaches tar (ohne Kompression), das
die App selbst auspacken kann. Größe und SHA-256 müssen genau zu pakete.json
passen, denn die App prüft beides beim Laden.

Aufruf: python3 stimmen/modelle/packen.py [Arbeitsordner]
"""
import hashlib, io, json, os, sys, tarfile, urllib.request

HIER = os.path.dirname(os.path.abspath(__file__))
QUELLE = "https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/"


def lade(name, ziel):
    pfad = os.path.join(ziel, name + ".tar.bz2")
    if not os.path.exists(pfad):
        print("Lade", name, flush=True)
        urllib.request.urlretrieve(QUELLE + name + ".tar.bz2", pfad)
    return tarfile.open(pfad, "r:bz2")


def packe(ausgabe, dateien):
    """dateien: Liste von (Name im Paket, Bytes). Immer gleich sortiert und
    ohne Zeitstempel, damit jedes Mal genau dieselbe Datei herauskommt."""
    with tarfile.open(ausgabe, "w", format=tarfile.USTAR_FORMAT) as t:
        for name, daten in sorted(dateien):
            ti = tarfile.TarInfo(name)
            ti.size = len(daten)
            ti.mode = 0o644
            ti.mtime = 0
            ti.uid = ti.gid = 0
            ti.uname = ti.gname = ""
            t.addfile(ti, io.BytesIO(daten))


def inhalt(archiv, filter_fn):
    erg = []
    for m in archiv.getmembers():
        if m.isfile():
            teile = m.name.split("/", 1)
            if len(teile) == 2:
                neu = filter_fn(teile[1])
                if neu:
                    erg.append((neu, archiv.extractfile(m).read()))
    return erg


def main():
    arbeit = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HIER, "bau")
    os.makedirs(arbeit, exist_ok=True)
    pakete = json.load(open(os.path.join(HIER, "pakete.json")))
    fehler = False
    for p in pakete:
        archiv = lade(p["quelle"], arbeit)
        if p["art"] == "aussprache":
            behalten = set(p["sprachen"])
            def f(rel):
                if not rel.startswith("espeak-ng-data/"):
                    return None
                datei = rel.split("/")[-1]
                if rel.count("/") == 1 and datei.endswith("_dict") and datei[:-5] not in behalten:
                    return None
                return rel
        else:
            def f(rel, p=p):
                if rel == p["modell"]:
                    return p["ordner"] + "/stimme.onnx"
                if rel in ("tokens.txt", "MODEL_CARD"):
                    return p["ordner"] + "/" + rel
                return None
        ausgabe = os.path.join(arbeit, p["id"] + ".tar")
        packe(ausgabe, inhalt(archiv, f))
        daten = open(ausgabe, "rb").read()
        sha = hashlib.sha256(daten).hexdigest()
        ok = len(daten) == p["bytes"] and sha == p["sha256"]
        print(f'{p["id"]}: {len(daten)} Bytes, {sha} {"passt" if ok else "PASST NICHT"}')
        fehler = fehler or not ok
    # Die App kennt Größe und Prüfsumme fest, beides muss dort genauso stehen
    swift = open(os.path.join(HIER, "..", "..", "YEM1N", "GeraeteStimmeDaten.swift"), encoding="utf-8").read()
    for p in pakete:
        zahl = f'{p["bytes"]:,}'.replace(",", "_")
        if p["sha256"] not in swift or zahl not in swift:
            print(f'{p["id"]}: steht in GeraeteStimmeDaten.swift nicht mit {zahl} Bytes und dieser Prüfsumme')
            fehler = True
    if fehler:
        sys.exit("Die Pakete passen nicht zu pakete.json. Bitte pakete.json und GeraeteStimmeDaten.swift angleichen.")


main()
