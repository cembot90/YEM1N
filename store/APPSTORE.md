# YEM1N iPhone: Angaben für App Store Connect

Diese Datei sammelt, was Cem in App Store Connect eintragen oder entscheiden muss. Sie ist ein Entwurf zum Kopieren und kein Rechtsrat.
Stand 26.10.2026. Die Angaben müssen zu `YEM1N/Datenschutz.swift`, `docs/index.html` und `YEM1N/PrivacyInfo.xcprivacy` passen (siehe CLAUDE.md, Punkt Datenschutz).

## 1. Voraussetzung

Die Familie läuft über den eigenen Familien-Dienst (Protokoll 2). Bevor die App öffentlich erscheint, muss sie auf echten Geräten laufen
(Testliste im Claude-Projekt: `Testliste-iPhone-Familie`) und der alte Weg abgeschaltet sein (`cloud/ABSCHALTEN-V1.md` im Android-Repo).
TestFlight mit geschlossenem Kreis ist vorher in Ordnung. Die öffentliche Datenschutzseite (GitHub Pages) zeigt `main`. Sie beschreibt
den neuen Familien-Dienst erst, wenn `entwicklung` nach `main` kommt.

## 2. App-Datenschutz ("Privacy Nutrition Label")

Das Privacy-Manifest in der App (`YEM1N/PrivacyInfo.xcprivacy`) sagt dasselbe. Es gilt nur für Geräte, die zu einer Familie gehören und deren Eltern
eingewilligt haben. Ohne Familie verlässt nichts das Gerät.

| Frage in App Store Connect | Antwort |
| --- | --- |
| Erhebt die App Daten? | Ja |
| Tracking (Verknüpfung mit Daten anderer Firmen, Werbung)? | Nein. Kein Tracking, keine Tracking-Domains |
| Kontaktinfo: Name | Ja. Vorname oder Spitzname des Kindes und Name des Geräts (freiwillig). Mit Nutzer verknüpft: Ja. Zweck: App-Funktionen |
| Kennungen: Geräte-ID | Ja. Kennung aus dem öffentlichen Geräteschlüssel und Push-Kennung. Mit Nutzer verknüpft: Ja. Zweck: App-Funktionen |
| Nutzungsdaten: Sonstige Nutzungsdaten | Ja. Ergebnisse der Übungsrunden, Stand des Haustiers. Mit Nutzer verknüpft: Ja. Zweck: App-Funktionen |
| Nutzerinhalte: Sonstige Nutzerinhalte | Ja. Joker-Fragen und -Antworten, Duell-Ergebnisse. Mit Nutzer verknüpft: Ja. Zweck: App-Funktionen |
| Standort, Kontakte, Fotos, Gesundheit, Finanzen, Browserverlauf, Diagnosedaten, Käufe | Nein |

"Mit Nutzer verknüpft" steht auf Ja, weil die Daten über die Geräte-Kennung einer Familie zugeordnet sind, auch wenn es kein Konto und keinen
Klarnamen gibt. Das ist die vorsichtigere Antwort und entspricht dem Manifest.

Dienstleister: Cloudflare (Familien-Dienst, Speicherung in der EU, Verarbeiter), Apple (CloudKit liest nur öffentliche Klassenpakete, es geht nur
der Klassencode über das Netz). Keine Weitergabe zu Werbung oder Analyse.

## 3. Altersfreigabe und Kinderkategorie (Entscheidung)

Apple verlangt für die Kinderkategorie ([Richtlinie 1.3](https://developer.apple.com/app-store/review/guidelines/)):
keine Links aus der App heraus und keine Kaufangebote außerhalb eines Elternschutzes (Parental Gate), keine Weitergabe von
personenbezogenen Daten oder Geräteinformationen an Dritte, keine Analyse- und Werbedienste von Dritten.

Heute gilt für YEM1N:

- Keine Werbung, keine Analyse, keine Käufe. Das passt.
- Links aus der App: Datenschutz, Anleitung und Impressum öffnen Webseiten (`Datenschutz.swift`, `AnleitungInfo.swift`, `Rechtliches.swift`).
  Diese Seiten liegen nicht hinter der Eltern-PIN. Für die Kinderkategorie müssten sie hinter einen Elternschutz.
- Der Familien-Dienst ist ein eigener Dienst, den Cloudflare nur betreibt, mit Einwilligung der Eltern. Ob Apple das als "Dritte" ansieht, entscheidet
  die Prüfung. Das ist ein Risiko für die Kinderkategorie.

Empfehlung: Zuerst ohne Kinderkategorie veröffentlichen (Kategorie Bildung, Altersfreigabe nach dem Fragebogen, voraussichtlich 4+). Wer später in die
Kinderkategorie will, braucht einen Elternschutz vor allen Links und eine Prüfung der Datenwege. Das baut Claude auf Wunsch. Hinweis von Apple: Wer
einmal in der Kinderkategorie ist, muss die Regeln auch nach dem Verlassen der Kategorie weiter einhalten.

Altersfragebogen (Stand der Fragen bitte in App Store Connect lesen, sie ändern sich): keine Gewalt, kein Glücksspiel (Münzen sind nur Spielgeld, nichts
lässt sich kaufen oder auszahlen), keine Nutzerinhalte für Fremde (Joker nur in der Familie), kein freier Webzugang (nur eigene Seiten), kein Chat mit Fremden.

## 4. Anbieterstatus (EU)

Apple verlangt eine Angabe, ob du Händler (Trader) nach dem Digital Services Act bist. Als Händler zeigt Apple Anschrift, Telefon und E-Mail öffentlich auf der
Produktseite in den EU-Ländern. Apple sagt, dass es das nicht für dich beurteilen kann
([Apple-Hilfe](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements)).
Auch bei Verteilung nur über TestFlight bist du dort kein Händler. Für den Store: kostenlos, ohne Werbung, privates Projekt spricht für "kein Händler". Die
Einschätzung ist deine, am besten kurz mit einer Rechtsberatung klären. Dieselbe Angabe gilt in Google Play (siehe Android-Repo, `store/VEROEFFENTLICHUNG.md`, Abschnitt 7).

## 5. Weitere Angaben

- Datenschutz-URL: `https://cembot90.github.io/YEM1N/` (erst nach dem Merge auf `main` aktuell, siehe Punkt 1).
- Support-URL und Kontakt: `https://cembot90.github.io/YEM1N/` und die Adresse aus `Rechtliches.swift` (öffentlich sichtbar, bei Bedarf eine eigene Adresse einrichten).
- Verschlüsselung: Im Projekt steht `ITSAppUsesNonExemptEncryption = NO`. Die App benutzt nur die Verschlüsselung des Systems (HTTPS, CryptoKit für Hash und Unterschrift).
  Dann braucht TestFlight keine Exportfrage bei jedem Build.
- Berechtigungen: Kamera (nur QR-Code scannen, Text steht in den Projekteinstellungen), Mitteilungen (nach Frage, neutral ohne Namen und Inhalte).
- Konten: Es gibt keine Konten. Löschen geht trotzdem in der App: Einstellungen > Familie (ganze Familie löschen, oder als Kind beim Verlassen die eigenen Einträge).
- Mindest-iOS: im Projekt eingestellt, bitte die Zielgeräte der Familie prüfen, bevor die App öffentlich geht.

## 6. Hinweise für die App-Prüfung (Feld "Notizen zur Prüfung")

Vorschlag:

> YEM1N ist eine Übungs-App für Vorschule und Grundschule. Es gibt keine Konten und keine Anmeldung. Alle Übungen, Spiele und das Haustier laufen
> ohne Internet und ohne Familie. Die Funktionen für Familien (Joker, Ergebnisse für Eltern, Duell) brauchen zwei Geräte: Ein Eltern-Gerät legt unter
> Einstellungen > Familie eine Familie an und zeigt einen QR-Code, das zweite Gerät scannt ihn und wird vom Eltern-Gerät erlaubt. Der Elternbereich ist mit
> einer PIN geschützt, die beim ersten Öffnen selbst festgelegt wird. Daten gehen nur mit Einwilligung der Eltern und nur innerhalb der Familie an den
> Familien-Dienst (Cloudflare, EU). Ein kurzes Video des Ablaufs mit zwei Geräten liegt hier: <Link>.

Ein kurzes Bildschirmvideo mit zwei Geräten (Koppeln, Erlauben, Joker) vermeidet Rückfragen der Prüfung. Das nimmt nur Cem auf.
