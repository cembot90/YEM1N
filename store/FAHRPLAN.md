# YEM1N: Fahrplan bis in die Stores

Stand 01.11.2026. Gemeinsamer Plan für iPhone und Android. Die Einzelheiten zum Eintragen stehen in `store/APPSTORE.md`,
`store/STORETEXTE.md` und im Android-Repo in `store/VEROEFFENTLICHUNG.md`. Dies ist eine Sammlung zum Abarbeiten und kein
Rechts- oder Steuerrat. Beträge und Grenzen ändern sich, vor einer Entscheidung beim Gewerbeamt, Finanzamt oder einer Beratung
nachfragen.

## 1. Reihenfolge

1. **Beide Apps auf echten Geräten testen** (`docs/TESTPLAN-GERAETE.md` im Android-Repo). Erst wenn das läuft, lohnt sich alles Weitere.
2. **Entscheiden: privat oder Gewerbe** (Abschnitt 2). Davon hängen Anbieterstatus, Impressum und Konten ab.
3. **Rechtliches fertig machen** (Abschnitt 3): Impressum, Datenschutzerklärung, Verträge zur Auftragsverarbeitung.
4. **Konten und Tarife** (Abschnitt 4): Apple Developer Program, Google Play Console, Cloudflare Workers Paid.
5. **Geschlossener Test** mit Familie und Freunden: TestFlight extern, Google Play geschlossener Test (Abschnitt 4).
6. **Store-Einträge** mit Texten und Bildern (`store/STORETEXTE.md`), App-Prüfung, Veröffentlichung.

## 2. Gewerbe (wenn du dich dafür entscheidest)

Für eine App, die du dauerhaft anbietest und verbesserst, ist ein Gewerbe der übliche Weg. Auch kostenlos kann es sinnvoll sein,
sobald Einnahmen dazukommen (Kaufpreis, Unterstützer-Kauf, Spenden über eine Firma).

- **Gewerbeanmeldung** beim Gewerbeamt deiner Stadt, oft online. Kostet je nach Stadt etwa 15 bis 60 Euro.
  Tätigkeit zum Beispiel: "Entwicklung und Vertrieb von Software (Apps)".
- **Finanzamt:** Kurz danach kommt die Aufforderung, den Fragebogen zur steuerlichen Erfassung über ELSTER auszufüllen.
  Dort lässt sich die **Kleinunternehmerregelung** wählen (keine Umsatzsteuer auf deinen Umsatz, Grenzen seit 2025:
  Vorjahr bis 25.000 Euro, laufendes Jahr bis 100.000 Euro). Die Stores rechnen die Umsatzsteuer gegenüber den Käufern
  meist selbst ab, trotzdem mit dem Finanzamt oder einer Steuerberatung klären, wie Apple und Google bei dir zu buchen sind.
- **Nebenberuflich:** Wenn du angestellt bist, den Arbeitgeber informieren, falls der Arbeitsvertrag das verlangt.
- **IHK:** Mitgliedschaft kommt automatisch. Bei kleinem Gewinn als Einzelunternehmer ist meist kein Beitrag fällig.
- **Einnahmen-Überschuss-Rechnung** einmal im Jahr mit der Steuererklärung. Belege sammeln: Apple 99 US-Dollar im Jahr,
  Google 25 US-Dollar einmalig, Cloudflare, Domain, Geräte anteilig.
- **Haftung:** Als Einzelunternehmer haftest du privat. Eine Berufs- oder Betriebshaftpflicht für Software ist zu überlegen.

## 3. Rechtliches

- **Anbieterstatus (EU, Digital Services Act):** Mit Gewerbe bist du in beiden Stores **Händler**. Dann zeigen Apple und Google
  Anschrift, Telefon und E-Mail öffentlich. Wer seine Wohnadresse nicht zeigen will, kann eine Geschäftsanschrift nutzen
  (zum Beispiel einen Anbieter für Geschäftsadressen). Die Angabe muss überall gleich sein.
- **Impressum:** In der App (Info > Impressum) und auf der Webseite. Name, ladungsfähige Anschrift, E-Mail, bei Gewerbe
  gegebenenfalls Umsatzsteuer-Nummer oder Hinweis auf die Kleinunternehmerregelung. Grundlage ist das Digitale-Dienste-Gesetz (DDG).
- **Datenschutzerklärung:** Gibt es schon (`docs/index.html`, in der App `Datenschutz.swift` und `InfoTexte.kt`). Bei Gewerbe
  den Verantwortlichen anpassen. Vor dem Start von einer fachkundigen Stelle prüfen lassen.
- **Auftragsverarbeitung:** Cloudflare (Familien-Dienst) bietet den Vertrag in den Kontoeinstellungen an, Google für Firebase
  Cloud Messaging ebenso. Beide abschließen und im Verzeichnis der Verarbeitungstätigkeiten eintragen.
- **Kinder:** Die App richtet sich an Kinder. Apple: Kinderkategorie mit Eltern-Sperre vor allem, was nach außen führt.
  Google: Programm "Für Familien" mit Zielgruppe unter 13. Die Prüfpunkte stehen in `store/APPSTORE.md` und `store/VEROEFFENTLICHUNG.md`.

## 4. Konten und Tarife

| Was | Kosten | Hinweis |
|---|---|---|
| Apple Developer Program | 99 US-Dollar im Jahr | Als Einzelunternehmer meist als Einzelperson. Eine Organisation braucht eine D-U-N-S-Nummer und in der Regel eine eingetragene Firma. |
| Google Play Console | 25 US-Dollar einmalig | Neue private Konten brauchen vor der Veröffentlichung einen geschlossenen Test mit mindestens 12 Testern über 14 Tage. |
| Cloudflare Workers Paid | etwa 5 US-Dollar im Monat | Für den Betrieb. Tageslimit je Familie und Notausschalter sind im Worker eingebaut. |
| Domain (optional) | etwa 10 bis 20 Euro im Jahr | Schöner als `github.io` für Datenschutz und Impressum. |

## 5. Wie die App sich tragen kann (ohne Werbung)

Werbung und Tracking passen nicht zu einer Kinder-App und sind in beiden Kinderprogrammen stark eingeschränkt. Möglich sind:

- **Kostenlos** mit freiwilligem **Unterstützer-Kauf** (einmalig, schaltet zum Beispiel einen Hut fürs Haustier frei). Kauf nur
  hinter der Eltern-PIN, damit Kinder nicht aus Versehen kaufen.
- **Einmaliger Kaufpreis** (zum Beispiel 2,99 Euro), dafür alles ohne Einschränkung.
- **Schulen und Klassen:** Der Klassencode ist schon da. Später könnte es eine Lizenz für Lehrkräfte geben.

Für jede Form mit Geld braucht es das Gewerbe, die Bankdaten und Steuerangaben in App Store Connect und in der Play Console.
