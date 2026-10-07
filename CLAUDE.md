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

Vor dem Push nach `main` muss klar sein, dass der Code baut. Wenn er noch nie
kompiliert wurde, erst auf `entwicklung` ablegen und Cem bauen lassen.

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
