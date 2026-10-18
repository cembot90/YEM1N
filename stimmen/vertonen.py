#!/usr/bin/env python3
"""Vertont die gesammelten Sätze mit Azure Speech und legt sie als
YEM1N/Studio/studio_<sprache>_<name>.mp3 in die App.

Liest stimmen/saetze/<sprache>.tsv (Name, Tab, Text) aus dem Sammler.
Vertont nur, was noch fehlt, und löscht Aufnahmen, die niemand mehr braucht.
Ändert sich in stimmen/stimmen.json die Stimme, wird die Sprache neu vertont.

Umgebung: AZURE_SPEECH_KEY, AZURE_SPEECH_REGION (zum Beispiel westeurope).
Ohne Schlüssel passiert nichts, dann liest die App mit der Gerätestimme.
Wahlweise BUDGET (Zeichen je Lauf, Standard 400000, der kostenlose Tarif hat
500000 im Monat) und PAUSE (Sekunden zwischen zwei Anfragen, Standard 3.2,
der kostenlose Tarif erlaubt 20 Anfragen pro Minute).
"""
import json, os, sys, time, urllib.error, urllib.request
from xml.sax.saxutils import escape

WURZEL = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
STUDIO = os.path.join(WURZEL, "YEM1N", "Studio")
SAETZE = os.path.join(WURZEL, "stimmen", "saetze")


def lies_saetze(sprache):
    pfad = os.path.join(SAETZE, sprache + ".tsv")
    erg = {}
    if os.path.exists(pfad):
        for zeile in open(pfad, encoding="utf-8"):
            zeile = zeile.rstrip("\n")
            if "\t" in zeile:
                name, text = zeile.split("\t", 1)
                erg[name] = text
    return erg


def vertone(text, s, schluessel, region):
    ssml = (f'<speak version="1.0" xmlns="http://www.w3.org/2001/10/synthesis" xml:lang="{s["sprache"]}">'
            f'<voice name="{s["stimme"]}"><prosody rate="{s["tempo"]}">{escape(text)}</prosody></voice></speak>')
    anfrage = urllib.request.Request(
        f"https://{region}.tts.speech.microsoft.com/cognitiveservices/v1",
        data=ssml.encode("utf-8"), method="POST",
        headers={"Ocp-Apim-Subscription-Key": schluessel,
                 "Content-Type": "application/ssml+xml",
                 "X-Microsoft-OutputFormat": "audio-24khz-48kbitrate-mono-mp3",
                 "User-Agent": "YEM1N-Studio"})
    for versuch in range(6):
        try:
            with urllib.request.urlopen(anfrage, timeout=60) as antwort:
                return antwort.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 503):
                warte = int(e.headers.get("Retry-After") or 10) * (versuch + 1)
                print(f"  Azure bremst ({e.code}), warte {warte} s", flush=True)
                time.sleep(warte)
                continue
            raise SystemExit(f"Azure lehnt ab: {e.code} {e.read()[:300]!r}")
    raise SystemExit("Azure antwortet nicht. Später noch einmal versuchen.")


def main():
    schluessel = os.environ.get("AZURE_SPEECH_KEY", "").strip()
    region = os.environ.get("AZURE_SPEECH_REGION", "").strip() or "westeurope"
    budget = int(os.environ.get("BUDGET", "400000"))
    pause = float(os.environ.get("PAUSE", "3.2"))
    stimmen = json.load(open(os.path.join(WURZEL, "stimmen", "stimmen.json"), encoding="utf-8"))
    stand_pfad = os.path.join(SAETZE, "stand.json")
    stand = json.load(open(stand_pfad)) if os.path.exists(stand_pfad) else {}
    os.makedirs(STUDIO, exist_ok=True)

    verbraucht = 0
    for sprache, s in stimmen.items():
        saetze = lies_saetze(sprache)
        praefix = f"studio_{sprache}_"
        vorhanden = {f[:-4] for f in os.listdir(STUDIO) if f.startswith(praefix) and f.endswith(".mp3")}
        # Andere Stimme gewählt: alles dieser Sprache neu
        if stand.get(sprache) != s["stimme"] and schluessel:
            for name in vorhanden:
                os.remove(os.path.join(STUDIO, name + ".mp3"))
            vorhanden = set()
            stand[sprache] = s["stimme"]
        # Nicht mehr gebraucht
        for name in vorhanden - set(saetze):
            os.remove(os.path.join(STUDIO, name + ".mp3"))
        fehlend = [n for n in sorted(saetze) if n not in vorhanden]
        zeichen = sum(len(saetze[n]) for n in fehlend)
        print(f"{sprache}: {len(saetze)} Sätze, {len(fehlend)} fehlen ({zeichen} Zeichen)", flush=True)
        if not schluessel:
            continue
        for i, name in enumerate(fehlend, 1):
            text = saetze[name]
            if verbraucht + len(text) > budget:
                print(f"Budget von {budget} Zeichen erreicht, der Rest kommt beim nächsten Lauf.")
                break
            daten = vertone(text, s, schluessel, region)
            with open(os.path.join(STUDIO, name + ".mp3"), "wb") as f:
                f.write(daten)
            verbraucht += len(text)
            if i % 25 == 0:
                print(f"  {i}/{len(fehlend)}", flush=True)
            time.sleep(pause)

    if not schluessel:
        print("Kein AZURE_SPEECH_KEY gesetzt, es wurde nichts vertont.")
    json.dump(stand, open(stand_pfad, "w"), indent=1, sort_keys=True)
    print(f"Fertig, {verbraucht} Zeichen vertont.")


main()
