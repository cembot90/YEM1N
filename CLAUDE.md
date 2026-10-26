# YEM1N: Arbeitsregeln

Übungs-App für Cems Kinder (Yemin, Klasse 3, und Evîn, Vorschule).
SwiftUI mit SwiftData lokal. Familien laufen über den eigenen Familien-Dienst (Cloudflare, EU, Protokoll 2),
CloudKit gibt es nur noch für Aufgabenpakete der Klasse (lesen, Unterschrift prüfen).

## Aufgabenteilung

Cem fasst den Swift-Code nicht an. Alle Codeänderungen laufen über dieses Repo.
Cem macht alles, wofür Zugriff auf seinen Mac oder sein Apple-Konto nötig ist:
Xcode-Einstellungen, neue Berechtigungen in der Info.plist, Xcode-Cloud-Workflows,
App Store Connect, TestFlight, Tests auf echten Geräten.

## Auslieferung

`main` ist scharf. Jeder Push dorthin löst bei Xcode Cloud aus: Build, dann die
Unit-Tests, dann Archive, dann Verteilung an TestFlight. Rote Tests stoppen die
Auslieferung. `entwicklung` ist der Werkstattbereich ohne Auslieferung.

Kleine Änderungen (Texte, Anleitung, Farben, kleine Korrekturen) legt Claude direkt
auf `main` ab, wenn der Code sehr wahrscheinlich baut. Größere Eingriffe in den
Swift-Code (neue Funktionen, Datenmodell, CloudKit) kommen erst auf `entwicklung`,
und Cem baut sie auf seinem Gerät, bevor es auf `main` geht. `entwicklung` und
`main` werden immer per Fast-Forward gleichgezogen, die Historie wird nicht
umgeschrieben. Cem reicht dann ein normales `git pull`.

## TestFlight-Text zu jedem Build

Nach jedem Push auf `main`, der eine neue App-Version ausliefert, schreibt Claude
Cem sofort den Text für "Was soll getestet werden?" in TestFlight (Vorlage unten).
Er enthält nur, was sich für Tester gegenüber dem letzten verteilten Build ändert,
in einfachen Worten, mit wenigen Dingen zum Ausprobieren. Reine Änderungen an
`docs/` ändern die App nicht und brauchen keinen Text. Die Buildnummer vergibt
Xcode Cloud, Claude nennt sie nur, wenn Cem sie kennt.

Vorlage:
- Kopfzeile: "Neu in Build N (seit Build M):"
- Abschnitte in Großbuchstaben je Neuerung, kurze Sätze
- "Bitte besonders ausprobieren:" mit nummerierten Punkten
- "Bekannte Einschränkungen:" nur wenn es welche gibt
- Schluss: Feedback über TestFlight oder die Infoseite in den Einstellungen

## Bei jeder Funktionsänderung mitziehen

1. **Bedienungsanleitung.** Quelle ist `docs/anleitung.html`, erzeugt aus dem
   Markdown-Text der Anleitung. Neue oder geänderte Funktionen gehören in das
   passende Kapitel, und die Kurzfassung in `AnleitungInfo.swift` (die Offline-
   Karten) muss dazu passen. Die Anleitung wird aus der App heraus von GitHub
   Pages geladen, Änderungen wirken also ohne neue App-Version.
2. **Tests.** Neue Logik bekommt Tests in `YEM1NTests/`. Reine Oberfläche nicht.
3. **Datenschutz.** Wenn neue Daten erhoben oder übertragen werden, müssen
   `DatenschutzView` in `Datenschutz.swift`, `docs/index.html` und die Angaben
   in App Store Connect zusammenpassen.
4. **Familien-Dienst und CloudKit.** Neue Einträge der Familie brauchen einen Typ im Worker
   (`server/src/v2/typen.js` im Repo `cembot90/yem1n-android`, Tabelle in `cloud/PROTOKOLL-V2.md`) und in
   `FamilienProtokoll.swift`. Cem muss den Worker danach mit `npx wrangler@latest deploy` neu veröffentlichen.
   Felder oder Record-Typen für Klassenpakete stehen weiter in `cloudkit/schema.ckdb`.
5. **Vorstellungsseite.** `docs/vorstellung.html` stellt YEM1N Eltern und
   Lehrkräften vor (läuft ohne Internet, Beispiele zum Ausprobieren). Neue
   Funktionen, die für sie zählen, kommen dort mit hinein. Danach die Seite als
   Artefakt neu veröffentlichen und Cem die Datei schicken. Die Datei braucht
   `<meta charset="utf-8">`, sonst sind auf dem iPhone die Umlaute kaputt.

## Stimmen

Vorlesen geht immer über `Sprecher.sprich`: erst die Gerätestimme, wenn sie geladen ist, sonst die iOS-Stimme.
Die Gerätestimmen (Piper über sherpa-onnx, Paket in Xcode) liegen im Release `stimmen-1`, gebaut von
`stimmen/modelle/packen.py` über die Action "Gerätestimmen packen". Größe und SHA-256 stehen fest in
`GeraeteStimmeDaten.swift`. Studio-Aufnahmen mit Azure hat Cem abgelehnt, nicht wieder vorschlagen.

## Prüfen ohne Mac

`pruefen/linux-tests.sh` übersetzt die Logik ohne Oberfläche unter Linux und lässt die Tests von
Lernwelt, Vorschule und Stimmen laufen (Swift 6.1 oder neuer, Pfad über `SWIFTC`). Vor jedem Push laufen lassen.

## Schreibweise

Keine Gedankenstriche, weder im Code noch in Texten noch in Commit-Nachrichten.
Minus ist ein normaler Bindestrich, Mal ist `·`, Geteilt ist `:`.
Oberflächentexte und Kommentare auf Deutsch, kindgerecht und ohne Fachjargon.

## Aufbau

Eine Datei je Themenbereich in `YEM1N/`, siehe Dateinamen. Der Ordner ist im
Projekt synchronisiert, neue Dateien werden ohne Zutun mitgebaut.

## Familien-Dienst (Protokoll 2)

Entscheidung 25.10.2026 (Cem): ein abgetrenntes Fach je Familie bei Cloudflare (Worker mit Durable Object, EU),
ein Schlüssel je Gerät (Secure Enclave, im Simulator ein Software-Schlüssel), neue Geräte nur per QR-Code
(`yem1n://koppeln?f=...&t=...`, 10 Minuten, einmal) mit Freigabe durch ein Eltern-Gerät, auch bei Kindern.
Der alte Familiencode (CloudKit, öffentlich lesbar) ist abgelöst. Alte Einträge räumt `AlterFamilienweg` einmal auf.

- `Sha256.swift`, `FamilienProtokoll.swift`, `FamilienClient.swift`, `ElternPin.swift`: reine Logik, läuft unter Linux (`pruefen/linux-tests.sh`).
- `GeraetSchluessel.swift` (Secure Enclave), `FamilienNetz.swift` (URLSession), `FamilienModell.swift` (Zustand, `@Observable`).
- `Cloud.swift` (Joker, Ergebnisse, Sync, Mitteilungen), `CloudPakete.swift` (Pakete der Familie und der Klasse), `DuellCloud.swift`, `HaustierCloud.swift`.
- Oberfläche: `FamilieAnsicht.swift` (Einstellungen > Familie), `PinTor.swift` (PIN für den Elternbereich), Familien-Schritt in `ProfilAssistent.swift`.
- Tests: `FamilieTests.swift` (Logik, falscher Dienst), `FamilieKryptoTests.swift` (CryptoKit gegen die Prüfwerte in `cloud/testvektoren-v2.json` im Android-Repo).
- Einträge lassen sich im Dienst nicht einzeln löschen. Das Haustier wird mit `{}` überschrieben, Pakete und alles andere verfallen nach der Frist.

## Prüfen mit GitHub

Es gibt keinen Mac für Claude. `logik.yml` (Linux) und `ios-bauen.yml` (macOS, baut die App im Simulator und lässt alle Tests laufen)
laufen bei jedem Push auf `entwicklung`. Fehler stehen als Hinweise im Lauf (`gh api repos/cembot90/yem1n/check-runs/<id>/annotations`).
Die Log-Dateien selbst lassen sich vom Arbeitsplatz aus nicht laden.
