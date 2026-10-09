# YEM1N: Arbeitsregeln

Übungs-App für Cems Kinder (Yemin, Klasse 3, und Evîn, Vorschule).
SwiftUI mit SwiftData lokal, CloudKit für Ergebnisse, Joker und Aufgabenpakete.

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
4. **CloudKit.** Neue Felder oder Record-Typen müssen in `cloudkit/schema.ckdb`
   stehen, und Cem muss sie in die Produktionsumgebung ausrollen.

## Schreibweise

Keine Gedankenstriche, weder im Code noch in Texten noch in Commit-Nachrichten.
Minus ist ein normaler Bindestrich, Mal ist `·`, Geteilt ist `:`.
Oberflächentexte und Kommentare auf Deutsch, kindgerecht und ohne Fachjargon.

## Aufbau

Eine Datei je Themenbereich in `YEM1N/`, siehe Dateinamen. Der Ordner ist im
Projekt synchronisiert, neue Dateien werden ohne Zutun mitgebaut.
