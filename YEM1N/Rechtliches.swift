import SwiftUI

// ============================================================
// MARK: - Einwilligung, Impressum und Beta-Hinweise
// ============================================================

/// Die Einwilligung der Eltern zur Datenschutzerklärung. Gespeichert wird nur auf
/// dem Gerät: welche Fassung bestätigt wurde und wann.
enum Einwilligung {
    /// Wird erhöht, wenn sich die Datenschutzerklärung inhaltlich ändert.
    /// Dann fragt die App auf allen Geräten noch einmal.
    /// 5: Die Familie läuft über ein eigenes, abgetrenntes Fach bei Cloudflare in der EU (Protokoll 2),
    /// nicht mehr über den Familiencode in CloudKit.
    static let aktuelleVersion = 5
    static let versionKey = "einwilligungVersion"
    static let datumKey = "einwilligungDatum"

    static func erforderlich(gespeicherteVersion: Int) -> Bool {
        gespeicherteVersion < aktuelleVersion
    }

    static func speichern(speicher: UserDefaults = .standard, jetzt: Date = Date.now) {
        speicher.set(aktuelleVersion, forKey: versionKey)
        speicher.set(jetzt.timeIntervalSince1970, forKey: datumKey)
    }

    static func widerrufen(speicher: UserDefaults = .standard) {
        speicher.removeObject(forKey: versionKey)
        speicher.removeObject(forKey: datumKey)
    }

    static func datum(speicher: UserDefaults = .standard) -> Date? {
        let t = speicher.double(forKey: datumKey)
        return t > 0 ? Date(timeIntervalSince1970: t) : nil
    }

    static func datumText(_ datum: Date?, kalender: Calendar = .current) -> String {
        guard let datum else { return "noch nicht erteilt" }
        let f = DateFormatter()
        f.calendar = kalender
        f.locale = Locale(identifier: "de_DE")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: datum)
    }
}

/// Kurze Sätze, die neben Eingabefeldern stehen.
enum RechtHinweise {
    static let name = "Ein Vorname oder Spitzname reicht. Bitte keinen Nachnamen."
    static let freitext = "Schreib hier keine Nachnamen, Adressen oder Telefonnummern. Alle Geräte deiner Familie können den Text lesen."
}

// ============================================================
// MARK: - Einwilligung einholen
// ============================================================

struct EinwilligungView: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage(Einwilligung.versionKey) private var version = 0
    @State private var bestaetigt = false

    private var istKind: Bool { modus == "kind" }

    private var punkte: [String] {
        [
            "Die App speichert Übungen, Ergebnisse und Einstellungen auf diesem Gerät.",
            "Nur wenn dieses Gerät zu einer Familie gehört, gehen Ergebnisse, der Name des Kindes (freiwillig), Joker-Nachrichten, Duelle und das Haustier (Name, Art, Zustand) an die Familie. Jede Familie hat ein eigenes, abgetrenntes Fach bei Cloudflare in der EU. Neue Geräte kommen nur mit einem QR-Code dazu und müssen von den Eltern erlaubt werden. Für Namen reicht ein Vorname oder Spitzname.",
            "Mitteilungen laufen über Apple. Sie enthalten keine Namen und keine Inhalte, nur einen kurzen festen Satz.",
            "Es gibt keine Werbung, keine Analysedienste und kein Benutzerkonto.",
            "Der Familien-Dienst löscht Einträge nach spätestens 12 Monaten selbst. Du kannst die Familie jederzeit in den Einstellungen unter Familie löschen und die Einwilligung widerrufen."
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Bevor es losgeht")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                            .padding(.top, 30)
                        Text(istKind
                             ? "Bitte lass diesen Schritt von einem Elternteil oder einer erziehungsberechtigten Person lesen und bestätigen."
                             : "Bitte lies kurz, welche Daten die App verarbeitet.")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.white)

                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(punkte, id: \.self) { p in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•").foregroundStyle(Theme.gelb)
                                    Text(p).font(.subheadline).foregroundStyle(Color.white)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glasKarte(radius: 22)

                        NavigationLink { DatenschutzView() } label: {
                            Label("Datenschutzerklärung lesen", systemImage: "hand.raised.fill")
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                        }

                        Button { bestaetigt.toggle() } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: bestaetigt ? "checkmark.square.fill" : "square")
                                    .font(.title2)
                                    .foregroundStyle(Theme.gelb)
                                Text(istKind
                                     ? "Ich bin Elternteil oder erziehungsberechtigte Person. Ich habe die Datenschutzerklärung gelesen und willige in die beschriebene Verarbeitung für mein Kind ein."
                                     : "Ich habe die Datenschutzerklärung gelesen und willige in die beschriebene Verarbeitung ein.")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.white)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            Einwilligung.speichern()
                            version = Einwilligung.aktuelleVersion
                        } label: {
                            Text("Einverstanden, weiter")
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(Theme.gelb, in: Capsule())
                        }
                        .buttonStyle(TastenStil())
                        .disabled(!bestaetigt)
                        .opacity(bestaetigt ? 1 : 0.4)

                        Button("Nicht einverstanden") { modus = "" }
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textSanft)
                            .frame(maxWidth: .infinity)
                        Text("Ohne Einwilligung kann die App nicht genutzt werden. Du kommst zurück zur Auswahl.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// ============================================================
// MARK: - Impressum und Beta-Hinweise
// ============================================================

struct RechtTextSeite: View {
    let titel: String
    let abschnitte: [(String, String)]
    var webAdresse: String? = nil

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(abschnitte, id: \.0) { a in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(a.0)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.gelb)
                            Text(a.1)
                                .font(.subheadline)
                                .foregroundStyle(Color.white)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glasKarte(radius: 22)
                    }
                    if let webAdresse, let url = URL(string: webAdresse) {
                        Link(destination: url) {
                            Label("Im Browser öffnen", systemImage: "safari")
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(Theme.gelb, in: Capsule())
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(titel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

enum RechtTexte {
    static let anbieter = "Cem Aras, Schulweg 20, 65618 Selters (Taunus)"
    static let telefon = "+49 172 7579888"
    static let mail = "cembot@icloud.com"
    static let seite = "https://cembot90.github.io/YEM1N/"

    static let impressum: [(String, String)] = [
        ("Angaben nach § 5 DDG", "\(anbieter), Deutschland."),
        ("Kontakt", "Telefon: \(telefon)\nE-Mail: \(mail)"),
        ("Hinweis", "YEM1N wird kostenlos und ohne Werbung angeboten."),
        ("Haftung für Links", "Die App verlinkt auf die Anleitung und die Datenschutzerklärung auf GitHub Pages. Für fremde Inhalte, auf die verlinkt wird, sind die jeweiligen Anbieter verantwortlich.")
    ]

    static let beta: [(String, String)] = [
        ("Beta-Version", "YEM1N wird laufend weiterentwickelt. Funktionen können sich ändern, Fehler sind möglich. Wenn dir etwas auffällt, schreib kurz unter Info > Feedback an den Admin."),
        ("Aufgaben und Lösungen", "Aufgaben und Lösungen werden sorgfältig erstellt und geprüft, können aber Fehler enthalten. Die App ersetzt keinen Unterricht und kein Lehrwerk. Aufgabenpakete der Eltern oder einer Klasse stammen von den Personen, die sie veröffentlicht haben."),
        ("Haftung", "Für Schäden haftet der Anbieter nur bei Vorsatz und grober Fahrlässigkeit. Bei der Verletzung von Leben, Körper oder Gesundheit und nach zwingenden gesetzlichen Vorschriften haftet er nach dem Gesetz."),
        ("Grafiken", "Die Spielgrafiken stammen von Kenney (kenney.nl) und stehen unter der Lizenz CC0."),
        ("Stimmen", "Die Gerätestimmen sind Piper-Stimmen: Thorsten (Thorsten-Voice) und Fahrettin (NabuCasa voice-datasets), beide unter der Lizenz CC0, und Cori (Bryce Beattie), gemeinfrei aus LibriVox-Aufnahmen. Sie laufen mit sherpa-onnx (Apache-2.0) und ONNX Runtime (MIT), die Aussprache kommt von espeak-ng (GPL-3.0)."),
        ("Datenschutz", "Wie die App mit Daten umgeht, steht unter Info > Datenschutzhinweise.")
    ]
}

struct ImpressumView: View {
    var body: some View {
        RechtTextSeite(titel: "Impressum", abschnitte: RechtTexte.impressum,
                       webAdresse: RechtTexte.seite + "impressum.html")
    }
}

struct BetaHinweisView: View {
    var body: some View {
        RechtTextSeite(titel: "Beta und Haftung", abschnitte: RechtTexte.beta,
                       webAdresse: RechtTexte.seite + "nutzung.html")
    }
}
