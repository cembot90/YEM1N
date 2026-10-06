import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications

// MARK: - Design (Lacivert und Sari)

enum Theme {
    static let gelb = Color(red: 1.0, green: 0.93, blue: 0.0)
    static let navy = Color(red: 0.0, green: 0.125, blue: 0.357)
    static let tiefNavy = Color(red: 0.0, green: 0.045, blue: 0.16)
    static let koralle = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let mint = Color(red: 0.45, green: 0.95, blue: 0.62)
    static let himmel = Color(red: 0.45, green: 0.78, blue: 1.0)
    static let textSanft = Color.white.opacity(0.7)
}

struct HintergrundView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.navy, Theme.tiefNavy],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color(red: 0.16, green: 0.4, blue: 0.85).opacity(0.35), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }
}

struct GlasKarteStil: ViewModifier {
    let radius: CGFloat
    @AppStorage("glasEffekt") private var glas = true

    @ViewBuilder
    func body(content: Content) -> some View {
        if !glas {
            content.flachKarte(radius: radius)
        } else {
            // Liquid Glass ab iOS 26, sonst Material mit feiner Kante
            #if compiler(>=6.2)
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular, in: .rect(cornerRadius: radius))
            } else {
                content.materialKarte(radius: radius)
            }
            #else
            content.materialKarte(radius: radius)
            #endif
        }
    }
}

extension View {
    func glasKarte(radius: CGFloat = 24) -> some View {
        modifier(GlasKarteStil(radius: radius))
    }

    func flachKarte(radius: CGFloat) -> some View {
        self
            .background(Color.white.opacity(0.09),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }

    func materialKarte(radius: CGFloat) -> some View {
        self
            .background(.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
    }
}

struct Fortschrittsring: View {
    var wert: Double
    var breite: CGFloat = 7

    var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.14), lineWidth: breite)
            Circle()
                .trim(from: 0, to: min(max(wert, 0), 1))
                .stroke(Theme.gelb, style: StrokeStyle(lineWidth: breite, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.snappy, value: wert)
        }
    }
}

struct TastenStil: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct GelberKnopf: View {
    let titel: String
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Text(titel)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
        .padding(.horizontal, 24)
    }
}

// MARK: - Datenmodell
// Hierarchie: Klassenarbeit (Klasse, Fach, Titel) > Uebung > Aufgabe

@Model
final class Klassenarbeit {
    var klasse: String = ""
    var fach: String = ""
    var titel: String = ""
    var erstellt: Date = Date.now
    @Relationship(deleteRule: .cascade, inverse: \Uebung.arbeit)
    var uebungen: [Uebung] = []

    init(klasse: String, fach: String, titel: String) {
        self.klasse = klasse
        self.fach = fach
        self.titel = titel
    }

    var sortierteUebungen: [Uebung] { uebungen.sorted { $0.reihenfolge < $1.reihenfolge } }
    var fertigeUebungen: Int { uebungen.filter { $0.istFertig }.count }
    var sterne: Int { uebungen.reduce(0) { $0 + $1.sterne } }
    var maxSterne: Int { uebungen.count * 3 }
}

@Model
final class Uebung {
    var titel: String = ""
    var gruppe: String = ""
    var symbol: String = ""
    var tipp: String = ""
    var reihenfolge: Int = 0
    var beste: Int = 0
    var sterne: Int = 0
    var arbeit: Klassenarbeit?
    @Relationship(deleteRule: .cascade, inverse: \Aufgabe.uebung)
    var aufgaben: [Aufgabe] = []

    init(titel: String, gruppe: String, symbol: String, tipp: String, reihenfolge: Int) {
        self.titel = titel
        self.gruppe = gruppe
        self.symbol = symbol
        self.tipp = tipp
        self.reihenfolge = reihenfolge
    }

    var sortierteAufgaben: [Aufgabe] { aufgaben.sorted { $0.reihenfolge < $1.reihenfolge } }
    var beantwortet: Int { aufgaben.filter { $0.erledigt }.count }
    var angesehenAnzahl: Int { aufgaben.filter { $0.angesehen }.count }
    var richtigAnzahl: Int { aufgaben.filter { $0.richtig == true }.count }
    var istFertig: Bool { !aufgaben.isEmpty && beantwortet == aufgaben.count }
    var laufend: Bool { beantwortet > 0 && !istFertig }

    func sternAnzahl(fuer gut: Int) -> Int {
        sterneFuer(gut: gut, gesamt: aufgaben.count)
    }
}

@Model
final class Aufgabe {
    var art: String = "zahl"          // zahl, rest, vergleich, mauer
    var frage: String = ""
    var rechnung: String = ""
    var hinweis: String = ""
    var erklaerung: String = ""
    var antwort: String = ""
    var antwort2: String = ""
    var reihenJSON: String = ""
    var reihenfolge: Int = 0
    var richtig: Bool?
    var angesehen: Bool = false       // Lösung wurde angezeigt (zählt weder richtig noch falsch)
    var uebung: Uebung?

    var erledigt: Bool { richtig != nil || angesehen }

    init(art: String, frage: String, rechnung: String, hinweis: String,
         erklaerung: String, antwort: String, antwort2: String,
         reihenJSON: String, reihenfolge: Int) {
        self.art = art
        self.frage = frage
        self.rechnung = rechnung
        self.hinweis = hinweis
        self.erklaerung = erklaerung
        self.antwort = antwort
        self.antwort2 = antwort2
        self.reihenJSON = reihenJSON
        self.reihenfolge = reihenfolge
    }

    var reihen: [[Int]] {
        guard let d = reihenJSON.data(using: .utf8),
              let r = try? JSONDecoder().decode([[Int]].self, from: d) else { return [] }
        return r
    }

    // Faktoren aus "3 · 5 =" lesen (für das Punktefeld)
    var faktoren: (Int, Int)? {
        guard art == "zahl", !rechnung.contains("\n") else { return nil }
        let t = rechnung.replacingOccurrences(of: " =", with: "")
        let teile = t.components(separatedBy: " · ")
        guard teile.count == 2,
              let a = Int(teile[0]), let b = Int(teile[1]),
              (1...10).contains(a), (1...10).contains(b) else { return nil }
        return (a, b)
    }
}

// MARK: - Ergebnisse einer Runde
// Kind-Gerät: Warteschlange (quelle "lokal", gesendet false)
// Eltern-Gerät: Anzeige im Dashboard (quelle "cloud" oder "demo")

@Model
final class RundenErgebnis {
    var eintragID: String = UUID().uuidString
    var klasse: String = ""
    var fach: String = ""
    var arbeit: String = ""
    var uebung: String = ""
    var richtig: Int = 0
    var gesamt: Int = 0
    var angesehen: Int = 0
    var sterne: Int = 0
    var zeitpunkt: Date = Date.now
    var quelle: String = "lokal"
    var gesendet: Bool = false

    init(klasse: String, fach: String, arbeit: String, uebung: String,
         richtig: Int, gesamt: Int, angesehen: Int,
         zeitpunkt: Date = Date.now, quelle: String) {
        self.klasse = klasse
        self.fach = fach
        self.arbeit = arbeit
        self.uebung = uebung
        self.richtig = richtig
        self.gesamt = gesamt
        self.angesehen = angesehen
        self.sterne = sterneFuer(gut: richtig, gesamt: gesamt)
        self.zeitpunkt = zeitpunkt
        self.quelle = quelle
    }

    var anteil: Double { gesamt > 0 ? Double(richtig) / Double(gesamt) : 0 }
}

func sterneFuer(gut: Int, gesamt: Int) -> Int {
    guard gesamt > 0 else { return 0 }
    let anteil = Double(gut) / Double(gesamt)
    if anteil >= 0.9 { return 3 }
    if anteil >= 0.7 { return 2 }
    if anteil >= 0.5 { return 1 }
    return 0
}

// MARK: - Import-Format (von Claude geliefert)

struct ArbeitPaket: Decodable {
    let klasse: String
    let fach: String
    let arbeit: String
    let uebungen: [UebungPaket]
}

struct UebungPaket: Decodable {
    let titel: String
    let gruppe: String?
    let symbol: String?
    let tipp: String?
    let aufgaben: [AufgabePaket]
}

struct AufgabePaket: Decodable {
    let art: String?
    let frage: String?
    let rechnung: String?
    let hinweis: String?
    let erklaerung: String?
    let antwort: String?
    let antwort2: String?
    let reihen: [[Int]]?

    enum CodingKeys: String, CodingKey {
        case art, frage, rechnung, hinweis, erklaerung, antwort, antwort2, reihen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        art = try c.decodeIfPresent(String.self, forKey: .art)
        frage = try c.decodeIfPresent(String.self, forKey: .frage)
        rechnung = try c.decodeIfPresent(String.self, forKey: .rechnung)
        hinweis = try c.decodeIfPresent(String.self, forKey: .hinweis)
        erklaerung = try c.decodeIfPresent(String.self, forKey: .erklaerung)
        antwort = AufgabePaket.text(c, .antwort)
        antwort2 = AufgabePaket.text(c, .antwort2)
        reihen = try c.decodeIfPresent([[Int]].self, forKey: .reihen)
    }

    // Antworten dürfen als Text oder als Zahl im JSON stehen
    private static func text(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String? {
        if let s = try? c.decode(String.self, forKey: key) { return s }
        if let i = try? c.decode(Int.self, forKey: key) { return String(i) }
        return nil
    }
}

// MARK: - Haptik

enum Haptik {
    static func erfolg() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func fehler() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func leicht() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
}

// MARK: - CloudKit (Stufe 1: nur Verbindungstest)

enum CloudKitDienst {
    // Schreibt einen Test-Datensatz in die öffentliche CloudKit-Datenbank.
    // Im Development-Umfeld legt CloudKit den Datensatztyp dabei automatisch an.
    static func verbindungTesten() async -> String {
        let container = CKContainer.default()
        do {
            let status = try await container.accountStatus()
            guard status == .available else {
                return "iCloud ist auf diesem Gerät nicht verfügbar (Status \(status.rawValue)). Bitte in den Einstellungen bei iCloud anmelden."
            }
            let datensatz = CKRecord(recordType: "RundenErgebnis")
            datensatz["familienCode"] = "TEST" as CKRecordValue
            datensatz["uebung"] = "Verbindungstest" as CKRecordValue
            datensatz["richtig"] = 9 as CKRecordValue
            datensatz["gesamt"] = 10 as CKRecordValue
            datensatz["angesehen"] = 0 as CKRecordValue
            datensatz["zeitpunkt"] = Date() as CKRecordValue
            let gespeichert = try await container.publicCloudDatabase.save(datensatz)
            return "Verbindung steht. Test-Datensatz gespeichert:\n\(gespeichert.recordID.recordName)"
        } catch {
            return "Fehler: \(error.localizedDescription)"
        }
    }
}

// MARK: - App-Einstieg

// MARK: - Familiencode

enum Familiencode {
    private static let zeichen = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    // Zehn Zeichen ohne verwechselbare Buchstaben, angezeigt als XXXXX-XXXXX
    static func neu() -> String {
        let roh = (0..<10).map { _ in zeichen.randomElement() ?? "A" }
        return String(roh[0..<5]) + "-" + String(roh[5..<10])
    }

    static func bereinigt(_ text: String) -> String {
        let erlaubt = Set(zeichen)
        let roh = text.uppercased().filter { erlaubt.contains($0) }
        let kurz = String(roh.prefix(10))
        guard kurz.count > 5 else { return kurz }
        return String(kurz.prefix(5)) + "-" + String(kurz.dropFirst(5))
    }

    static func istGueltig(_ text: String) -> Bool {
        bereinigt(text).count == 11
    }
}

// MARK: - Beispieldaten für das Eltern-Dashboard

enum Beispieldaten {
    static func laden(in context: ModelContext) {
        let plan: [(String, Int)] = [
            ("Teilen mit Rest", 10), ("Einmaleins", 12), ("Kernaufgaben", 10),
            ("Zahlenmauern", 4), ("Sachaufgaben", 8), ("Punkt vor Strich", 10),
            ("Geteilt", 10), ("Alles gemischt", 12)
        ]
        for _ in 0..<16 {
            let (titel, gesamt) = plan.randomElement() ?? ("Einmaleins", 12)
            let schwach = titel == "Teilen mit Rest" || titel == "Sachaufgaben"
            let untergrenze = schwach ? gesamt * 3 / 10 : gesamt * 7 / 10
            let obergrenze = schwach ? gesamt * 6 / 10 : gesamt
            let richtig = Int.random(in: untergrenze...max(untergrenze, obergrenze))
            let wunsch = Int.random(in: 0...2) == 0 ? Int.random(in: 1...2) : 0
            let angesehen = min(wunsch, gesamt - richtig)
            let stunden = Int.random(in: 0...6) * 24 + Int.random(in: 0...8)
            let zeit = Calendar.current.date(byAdding: .hour, value: -stunden, to: Date.now) ?? Date.now
            context.insert(RundenErgebnis(klasse: "Klasse 3", fach: "Mathe",
                                          arbeit: "Klassenarbeit Nr. 1", uebung: titel,
                                          richtig: richtig, gesamt: gesamt,
                                          angesehen: angesehen, zeitpunkt: zeit,
                                          quelle: "demo"))
        }
    }

    static func loeschen(in context: ModelContext) {
        try? context.delete(model: RundenErgebnis.self,
                            where: #Predicate<RundenErgebnis> { $0.quelle == "demo" })
    }
}

// MARK: - Einstieg: Modus wählen (Kind oder Eltern)

struct WurzelView: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase

    var body: some View {
        Group {
            switch modus {
            case "kind": KindTabs()
            case "eltern": ElternTabs()
            default: ModusAuswahlView()
            }
        }
        .task(id: modus + "|" + familienCode) { await cloudStart() }
        .onChange(of: phase) {
            if phase == .active { Task { await CloudSync.aktiv(context) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await CloudSync.aktiv(context, erzwingen: true) }
        }
    }

    private func cloudStart() async {
        guard !modus.isEmpty, Familiencode.istGueltig(familienCode) else { return }
        let marke = modus + "|" + familienCode
        if UserDefaults.standard.string(forKey: "cloudEingerichtet") == marke {
            CloudStatus.shared.meldung = "Cloud ist bereit. Mitteilungen sind eingerichtet."
            await CloudSync.aktiv(context)
            return
        }
        CloudStatus.shared.meldung = "Cloud wird eingerichtet ..."
        let ergebnis = await CloudDienst.einrichten(code: familienCode, rolle: modus)
        CloudStatus.shared.meldung = ergebnis
        if ergebnis.hasPrefix("Cloud ist bereit") {
            UserDefaults.standard.set(marke, forKey: "cloudEingerichtet")
        }
        await CloudSync.aktiv(context, erzwingen: true)
    }
}

struct ModusAuswahlView: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @State private var schritt = 0          // 0 Auswahl, 1 Kind, 2 Eltern
    @State private var codeEingabe = ""
    @State private var neuerCode = ""

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("YEM1N")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                        Text("Wer benutzt dieses Gerät?")
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                    }
                    .padding(.top, 40)

                    switch schritt {
                    case 1: kindSchritt
                    case 2: elternSchritt
                    case 3: elternBeitreten
                    default: auswahl
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
        .animation(.smooth, value: schritt)
    }

    // MARK: Auswahl

    @ViewBuilder
    private var auswahl: some View {
        VStack(spacing: 14) {
            wahlKarte(titel: "Kind", text: "Ich übe Mathe.", symbol: "graduationcap.fill") {
                codeEingabe = familienCode
                schritt = 1
            }
            wahlKarte(titel: "Eltern", text: "Ich sehe den Fortschritt.", symbol: "bell.badge.fill") {
                neuerCode = familienCode.isEmpty ? Familiencode.neu() : familienCode
                schritt = 2
            }
        }
    }

    private func wahlKarte(titel: String, text: String, symbol: String,
                           aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack(spacing: 16) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 62, height: 62)
                    .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(titel)
                        .font(.system(.title2, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.white)
                    Text(text)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSanft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gelb)
            }
            .padding(18)
            .glasKarte(radius: 28)
        }
        .buttonStyle(TastenStil())
    }

    // MARK: Kind

    @ViewBuilder
    private var kindSchritt: some View {
        let gueltig = Familiencode.istGueltig(codeEingabe)
        VStack(spacing: 16) {
            Text("Familiencode eingeben")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Den Code zeigt das Eltern-Gerät an. Du kannst ihn auch später in den Einstellungen eintragen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            TextField("XXXXX-XXXXX", text: $codeEingabe)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onChange(of: codeEingabe) {
                    let b = Familiencode.bereinigt(codeEingabe)
                    if b != codeEingabe { codeEingabe = b }
                }

            GelberKnopf(titel: "Weiter") {
                familienCode = Familiencode.bereinigt(codeEingabe)
                modus = "kind"
            }
            .disabled(!gueltig)
            .opacity(gueltig ? 1 : 0.4)

            Button("Ohne Code starten") { modus = "kind" }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Button("Zurück") { schritt = 0 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }

    // MARK: Eltern

    @ViewBuilder
    private var elternSchritt: some View {
        VStack(spacing: 16) {
            Text("Euer Familiencode")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text(neuerCode)
                .font(.system(size: 34, weight: .black, design: .monospaced))
                .foregroundStyle(Theme.gelb)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .glasKarte(radius: 24)
            Text("Gib diesen Code auf dem Gerät deines Kindes ein. Nur damit gehören die Ergebnisse zu euch.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            ShareLink(item: Nachricht.familiencode(neuerCode)) {
                Label("Code teilen", systemImage: "square.and.arrow.up")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gelb)
            }

            GelberKnopf(titel: "Fertig") {
                familienCode = neuerCode
                modus = "eltern"
            }
            Button("Ich habe schon einen Code") {
                codeEingabe = ""
                schritt = 3
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(Theme.gelb)
            Button("Zurück") { schritt = 0 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }

    // MARK: Zweites Elternteil

    @ViewBuilder
    private var elternBeitreten: some View {
        let gueltig = Familiencode.istGueltig(codeEingabe)
        VStack(spacing: 16) {
            Text("Code vom anderen Elternteil")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Gib den Familiencode ein, den das andere Eltern-Gerät anzeigt. Dann siehst du dieselben Ergebnisse.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            TextField("XXXXX-XXXXX", text: $codeEingabe)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onChange(of: codeEingabe) {
                    let b = Familiencode.bereinigt(codeEingabe)
                    if b != codeEingabe { codeEingabe = b }
                }

            GelberKnopf(titel: "Verbinden") {
                familienCode = Familiencode.bereinigt(codeEingabe)
                modus = "eltern"
            }
            .disabled(!gueltig)
            .opacity(gueltig ? 1 : 0.4)

            Button("Zurück") { schritt = 2 }
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSanft)
        }
    }
}

// MARK: - Eltern: Übersicht und Üben

struct ElternTabs: View {
    var body: some View {
        TabView {
            ElternDashboardView()
                .tabItem { Label("Übersicht", systemImage: "chart.bar.fill") }
            StartView()
                .tabItem { Label("Mathe", systemImage: "plus.forwardslash.minus") }
            SprachStartView()
                .tabItem { Label("Sprachen", systemImage: "globe") }
            JokerLigaView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
        }
    }
}

struct SchwaecheEintrag: Identifiable {
    let titel: String
    let anteil: Double
    let runden: Int
    var id: String { titel }
}

struct StatKachel: View {
    let titel: String
    let wert: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.gelb)
            Text(wert)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(titel)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .glasKarte(radius: 22)
    }
}

struct ElternDashboardView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("familienCode") private var familienCode = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle != "lokal" },
           sort: \RundenErgebnis.zeitpunkt, order: .reverse)
    private var ergebnisse: [RundenErgebnis]
    @State private var zeigeEinstellungen = false

    private var heute: [RundenErgebnis] {
        ergebnisse.filter { Calendar.current.isDateInToday($0.zeitpunkt) }
    }

    private var woche: [RundenErgebnis] {
        let kal = Calendar.current
        let grenze = kal.date(byAdding: .day, value: -6, to: kal.startOfDay(for: Date.now)) ?? Date.distantPast
        return ergebnisse.filter { $0.zeitpunkt >= grenze }
    }

    private var schwaechste: [SchwaecheEintrag] {
        let gruppiert = Dictionary(grouping: woche, by: \.uebung)
        let alle = gruppiert.map { titel, liste -> SchwaecheEintrag in
            let r = liste.reduce(0) { $0 + $1.richtig }
            let g = liste.reduce(0) { $0 + $1.gesamt }
            return SchwaecheEintrag(titel: titel,
                                    anteil: g > 0 ? Double(r) / Double(g) : 0,
                                    runden: liste.count)
        }
        return Array(alle.sorted { $0.anteil < $1.anteil }.prefix(3))
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    kopf
                    if ergebnisse.isEmpty {
                        leer
                    } else {
                        kacheln
                        wochenbalken
                        schwaecheKarte
                        letzteRunden
                    }
                    demoKnoepfe
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .refreshable { await CloudSync.aktiv(context, erzwingen: true) }
        }
        .task { await CloudSync.aktiv(context) }
        .sheet(isPresented: $zeigeEinstellungen) { EinstellungenView() }
    }

    // MARK: Teile

    private var kopf: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N Eltern")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text(familienCode.isEmpty ? "Noch kein Familiencode" : "Familiencode: \(familienCode)")
                    .font(.system(.footnote, design: .monospaced))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Button { zeigeEinstellungen = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 44, height: 44)
                    .background(Theme.gelb, in: Circle())
            }
        }
    }

    private var leer: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(Theme.gelb)
            Text("Noch keine Ergebnisse")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Text("Sobald dein Kind eine Runde beendet, erscheint sie hier und du bekommst eine Mitteilung. Zum Ausprobieren kannst du Beispieldaten laden.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 28)
    }

    private var kacheln: some View {
        let r = heute.reduce(0) { $0 + $1.richtig }
        let g = heute.reduce(0) { $0 + $1.gesamt }
        let s = heute.reduce(0) { $0 + $1.sterne }
        return HStack(spacing: 12) {
            StatKachel(titel: "Runden heute", wert: "\(heute.count)", symbol: "flag.checkered")
            StatKachel(titel: "Richtig", wert: g > 0 ? "\(r)/\(g)" : "-", symbol: "checkmark.circle.fill")
            StatKachel(titel: "Sterne", wert: "\(s)", symbol: "star.fill")
        }
    }

    private var wochenbalken: some View {
        let kal = Calendar.current
        let start = kal.startOfDay(for: Date.now)
        let tage = (0..<7).reversed().map { kal.date(byAdding: .day, value: -$0, to: start) ?? start }
        let zahlen = tage.map { tag in
            ergebnisse.filter { kal.isDate($0.zeitpunkt, inSameDayAs: tag) }.count
        }
        let maximum = max(zahlen.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Letzte 7 Tage")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(tage.enumerated()), id: \.offset) { i, tag in
                    VStack(spacing: 6) {
                        Text("\(zahlen[i])")
                            .font(.caption2.bold())
                            .foregroundStyle(zahlen[i] > 0 ? Theme.gelb : Theme.textSanft)
                        Capsule()
                            .fill(zahlen[i] > 0 ? Theme.gelb : Color.white.opacity(0.14))
                            .frame(height: 8 + 56 * CGFloat(zahlen[i]) / CGFloat(maximum))
                        Text(tag.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2)
                            .foregroundStyle(Theme.textSanft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 110, alignment: .bottom)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func schwaecheFarbe(_ anteil: Double) -> Color {
        if anteil < 0.6 { return Theme.koralle }
        if anteil < 0.8 { return Theme.gelb }
        return Theme.mint
    }

    private var schwaecheKarte: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Hier lohnt sich Üben")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if schwaechste.isEmpty {
                Text("Noch keine Daten aus den letzten 7 Tagen.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                ForEach(schwaechste) { eintrag in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(eintrag.titel)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text("\(Int((eintrag.anteil * 100).rounded())) %")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(schwaecheFarbe(eintrag.anteil))
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.14))
                                Capsule()
                                    .fill(schwaecheFarbe(eintrag.anteil))
                                    .frame(width: geo.size.width * eintrag.anteil)
                            }
                        }
                        .frame(height: 7)
                        Text("\(eintrag.runden) \(eintrag.runden == 1 ? "Runde" : "Runden")")
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var letzteRunden: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Letzte Runden")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ForEach(Array(ergebnisse.prefix(8)), id: \.eintragID) { e in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(e.uebung)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Text("\(e.arbeit) · " + e.zeitpunkt.formatted(.relative(presentation: .named)))
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(e.richtig) von \(e.gesamt)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i < e.sterne ? Theme.gelb : Color.white.opacity(0.22))
                            }
                            if e.angesehen > 0 {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Theme.himmel)
                                Text("\(e.angesehen)")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.himmel)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    @ViewBuilder
    private var demoKnoepfe: some View {
        if ergebnisse.contains(where: { $0.quelle == "demo" }) {
            Button("Beispieldaten löschen") { Beispieldaten.loeschen(in: context) }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
        } else if ergebnisse.isEmpty {
            Button("Beispieldaten laden") { Beispieldaten.laden(in: context) }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
        }
    }
}

// MARK: - Einstellungen

struct EinstellungenView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" && $0.gesendet == false })
    private var offene: [RundenErgebnis]
    @State private var codeEingabe = ""
    @AppStorage("glasEffekt") private var glas = true

    private let zeile = Color.white.opacity(0.08)

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                Form {
                    Section("Dieses Gerät") {
                        Label(modus == "eltern" ? "Eltern-Gerät" : "Kind-Gerät",
                              systemImage: modus == "eltern" ? "bell.badge.fill" : "graduationcap.fill")
                    }
                    .listRowBackground(zeile)

                    Section("Familiencode") {
                        if modus == "eltern" {
                            Text(familienCode.isEmpty ? "Noch keiner" : familienCode)
                                .font(.system(.title2, design: .monospaced).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                            if !familienCode.isEmpty {
                                ShareLink(item: Nachricht.familiencode(familienCode)) {
                                    Label("Code teilen", systemImage: "square.and.arrow.up")
                                }
                            }
                            Button("Neuen Code erzeugen") { familienCode = Familiencode.neu() }
                            Text("Oder einen vorhandenen Code übernehmen, zum Beispiel vom anderen Elternteil:")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        TextField("XXXXX-XXXXX", text: $codeEingabe)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: codeEingabe) {
                                let b = Familiencode.bereinigt(codeEingabe)
                                if b != codeEingabe { codeEingabe = b }
                            }
                        Button("Code speichern") {
                            familienCode = Familiencode.bereinigt(codeEingabe)
                        }
                        .disabled(!Familiencode.istGueltig(codeEingabe) || codeEingabe == familienCode)
                    }
                    .listRowBackground(zeile)

                    if modus != "eltern" {
                        Section {
                            Label("Noch nicht gesendet: \(offene.count)", systemImage: "tray.full")
                            Text("Ergebnisse werden automatisch an die Eltern gesendet, sobald das Gerät online ist und ein Familiencode eingetragen ist.")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        } header: {
                            Text("Ergebnisse")
                        }
                        .listRowBackground(zeile)
                    }

                    Section {
                        Toggle("Glas-Effekte", isOn: $glas)
                    } header: {
                        Text("Darstellung")
                    } footer: {
                        Text("Aus macht die App auf älteren iPhones flüssiger. Das Aussehen wird dann etwas flacher.")
                    }
                    .listRowBackground(zeile)

                    Section {
                        Button("Modus zurücksetzen", role: .destructive) {
                            modus = ""
                            dismiss()
                        }
                    } footer: {
                        Text("Klassenarbeiten und Fortschritt bleiben erhalten.")
                    }
                    .listRowBackground(zeile)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .onAppear { codeEingabe = familienCode }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }
}

@main
struct MatheApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let container: ModelContainer

    init() {
        let schema = Schema([Klassenarbeit.self, Uebung.self, Aufgabe.self, RundenErgebnis.self])
        // SwiftData bleibt lokal auf dem Gerät. Ohne diese Zeile würde SwiftData
        // nach dem Aktivieren von iCloud die Daten automatisch in die private
        // iCloud-Datenbank spiegeln.
        let konfiguration = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            container = try ModelContainer(for: schema, configurations: konfiguration)
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WurzelView()
                .tint(Theme.gelb)
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
    }
}

// MARK: - Startansicht: Klasse > Fach > Klassenarbeit

struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Klassenarbeit.klasse),
                  SortDescriptor(\Klassenarbeit.fach),
                  SortDescriptor(\Klassenarbeit.erstellt)])
    private var alleArbeiten: [Klassenarbeit]

    @State private var fehler: String?
    @State private var zeigeEinfuegen = false
    @State private var zeigeDatei = false
    @State private var eingabeText = ""
    @State private var cloudKitMeldung: String?
    @State private var infoMeldung: String?
    @State private var zeigeEinstellungen = false
    @State private var zeigeEditor = false
    @AppStorage("modus") private var modus = ""

    private var klassen: [String] { Array(Set(alleArbeiten.map(\.klasse))).sorted() }

    private func faecher(_ klasse: String) -> [String] {
        Array(Set(alleArbeiten.filter { $0.klasse == klasse }.map(\.fach))).sorted()
    }

    private func arbeiten(_ klasse: String, _ fach: String) -> [Klassenarbeit] {
        alleArbeiten.filter { $0.klasse == klasse && $0.fach == fach }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                VStack(spacing: 0) {
                    kopf
                    if alleArbeiten.isEmpty { leer } else { liste }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("CloudKit-Test",
                   isPresented: Binding(get: { cloudKitMeldung != nil },
                                        set: { if !$0 { cloudKitMeldung = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(cloudKitMeldung ?? "")
            }
            .alert("Hinweis",
                   isPresented: Binding(get: { infoMeldung != nil },
                                        set: { if !$0 { infoMeldung = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(infoMeldung ?? "")
            }
            .sheet(isPresented: $zeigeEinstellungen) { EinstellungenView() }
            .sheet(isPresented: $zeigeEditor) {
                NavigationStack { MatheEditorView() }
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .navigationDestination(for: Klassenarbeit.self) { ArbeitView(arbeit: $0) }
            .navigationDestination(for: Uebung.self) { UebungView(uebung: $0) }
            .fileImporter(isPresented: $zeigeDatei,
                          allowedContentTypes: [.json, .plainText]) { ergebnis in
                switch ergebnis {
                case .success(let url):
                    let zugriff = url.startAccessingSecurityScopedResource()
                    defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
                    importiereData(try? Data(contentsOf: url))
                case .failure(let e):
                    fehler = e.localizedDescription
                }
            }
            .sheet(isPresented: $zeigeEinfuegen) { einfuegenSheet }
            .alert("Import nicht möglich",
                   isPresented: Binding(get: { fehler != nil && !zeigeEinfuegen },
                                        set: { if !$0 { fehler = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(fehler ?? "")
            }
        }
    }

    // MARK: Kopf

    private var kopf: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text("Rechnen üben")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Menu {
                Button("Text einfügen", systemImage: "text.cursor") {
                    fehler = nil
                    zeigeEinfuegen = true
                }
                Button("Aus Zwischenablage einfügen", systemImage: "doc.on.clipboard") {
                    importiereText(UIPasteboard.general.string)
                }
                Button("Datei importieren", systemImage: "folder") { zeigeDatei = true }
                if modus == "eltern" {
                    Button("Aufgaben-Editor", systemImage: "square.and.pencil") { zeigeEditor = true }
                }
                Divider()
                Button("Einstellungen", systemImage: "gearshape") { zeigeEinstellungen = true }
                Button("CloudKit testen", systemImage: "icloud") {
                    Task { cloudKitMeldung = await CloudKitDienst.verbindungTesten() }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 48, height: 48)
                    .background(Theme.gelb, in: Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var leer: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 54))
                .foregroundStyle(Theme.gelb)
                .symbolEffect(.pulse)
            Text("Noch keine Klassenarbeit")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Text("Tippe auf das Plus und füge das JSON von Claude ein.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Liste

    private var liste: some View {
        List {
            ForEach(klassen, id: \.self) { klasse in
                Text(klasse)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 14, leading: 24, bottom: 2, trailing: 24))

                ForEach(faecher(klasse), id: \.self) { fach in
                    Label(fach, systemImage: "book.closed.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.gelb)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 24, bottom: 0, trailing: 24))

                    let treffer = arbeiten(klasse, fach)
                    ForEach(treffer) { a in
                        ZStack {
                            ArbeitKarte(arbeit: a)
                            NavigationLink(value: a) { EmptyView() }.opacity(0)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                    }
                    .onDelete { offsets in
                        offsets.forEach { context.delete(treffer[$0]) }
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }

    private var einfuegenSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $eingabeText)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    if let fehler {
                        Text(fehler)
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .padding()
            }
            .navigationTitle("JSON einfügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { zeigeEinfuegen = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importieren") {
                        if importiereText(eingabeText) {
                            eingabeText = ""
                            zeigeEinfuegen = false
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }

    // MARK: Import

    @discardableResult
    private func importiereText(_ text: String?) -> Bool {
        importiereData(text?.data(using: .utf8))
    }

    @discardableResult
    private func importiereData(_ daten: Data?) -> Bool {
        guard let daten, var text = String(data: daten, encoding: .utf8), !text.isEmpty else {
            fehler = "Es wurde kein Text gefunden."
            return false
        }
        // Falls Code-Zaun oder Begleittext mitkopiert wurde: nur das JSON-Objekt nehmen
        if let s = text.firstIndex(of: "{"), let e = text.lastIndex(of: "}"), s < e {
            text = String(text[s...e])
        }
        // Sprachkatalog statt Klassenarbeit: an den Sprachbereich weitergeben
        if text.contains("\"sprachkatalog\"") || (text.contains("\"themen\"") && !text.contains("\"uebungen\"")) {
            if let n = SprachKatalogStore.shared.importiere(text) {
                infoMeldung = "\(n) Sprachthema/Sprachthemen geladen. Du findest sie im Tab Sprachen."
                return true
            }
            fehler = "Das Sprachformat passt nicht. Erwartet wird ein JSON mit einer Liste „themen“."
            return false
        }
        guard let bereinigt = text.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: bereinigt) else {
            fehler = "Das Format passt nicht. Bitte das JSON von Claude komplett kopieren."
            return false
        }
        guard !paket.uebungen.isEmpty, paket.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else {
            fehler = "Die Klassenarbeit enthält keine Übungen oder leere Übungen."
            return false
        }
        if alleArbeiten.contains(where: {
            $0.klasse == paket.klasse && $0.fach == paket.fach && $0.titel == paket.arbeit
        }) {
            fehler = "\(paket.arbeit) (\(paket.klasse), \(paket.fach)) ist schon vorhanden. Zum Ersetzen in der Liste nach links wischen und löschen."
            return false
        }

        let arbeit = Klassenarbeit(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit)
        context.insert(arbeit)
        for (i, up) in paket.uebungen.enumerated() {
            let uebung = Uebung(titel: up.titel,
                                gruppe: up.gruppe ?? "Aufgaben",
                                symbol: up.symbol ?? "✎",
                                tipp: up.tipp ?? "",
                                reihenfolge: i)
            context.insert(uebung)
            uebung.arbeit = arbeit
            for (j, ap) in up.aufgaben.enumerated() {
                let reihenJSON = ap.reihen
                    .flatMap { try? JSONEncoder().encode($0) }
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let aufgabe = Aufgabe(art: ap.art ?? "zahl",
                                      frage: ap.frage ?? "",
                                      rechnung: ap.rechnung ?? "",
                                      hinweis: ap.hinweis ?? "",
                                      erklaerung: ap.erklaerung ?? "",
                                      antwort: ap.antwort ?? "",
                                      antwort2: ap.antwort2 ?? "",
                                      reihenJSON: reihenJSON,
                                      reihenfolge: j)
                context.insert(aufgabe)
                aufgabe.uebung = uebung
            }
        }
        return true
    }
}

struct ArbeitKarte: View {
    let arbeit: Klassenarbeit

    private var anteil: Double {
        Double(arbeit.fertigeUebungen) / Double(max(arbeit.uebungen.count, 1))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Fortschrittsring(wert: anteil, breite: 7)
                Text("\(arbeit.fertigeUebungen)/\(arbeit.uebungen.count)")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 5) {
                Text(arbeit.titel)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                HStack(spacing: 5) {
                    Image(systemName: "star.fill").foregroundStyle(Theme.gelb)
                    Text("\(arbeit.sterne) von \(arbeit.maxSterne)")
                        .foregroundStyle(Theme.textSanft)
                }
                .font(.system(.subheadline, design: .rounded).weight(.medium))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.gelb)
        }
        .padding(18)
        .glasKarte(radius: 28)
    }
}

// MARK: - Übungsmenü einer Klassenarbeit

struct ArbeitView: View {
    let arbeit: Klassenarbeit

    private var gruppen: [String] {
        var geordnet: [String] = []
        for u in arbeit.sortierteUebungen where !geordnet.contains(u.gruppe) {
            geordnet.append(u.gruppe)
        }
        return geordnet
    }

    private func uebungen(in gruppe: String) -> [Uebung] {
        arbeit.sortierteUebungen.filter { $0.gruppe == gruppe }
    }

    private func spalten(_ anzahl: Int) -> [GridItem] {
        anzahl == 1
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    kopfkarte
                    ForEach(gruppen, id: \.self) { gruppe in
                        let liste = uebungen(in: gruppe)
                        VStack(alignment: .leading, spacing: 10) {
                            Text(gruppe)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.gelb)
                                .padding(.leading, 4)
                            LazyVGrid(columns: spalten(liste.count), spacing: 12) {
                                ForEach(liste) { u in
                                    NavigationLink(value: u) { UebungKachel(uebung: u) }
                                        .buttonStyle(TastenStil())
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(arbeit.titel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var kopfkarte: some View {
        HStack(spacing: 18) {
            ZStack {
                Fortschrittsring(wert: Double(arbeit.sterne) / Double(max(arbeit.maxSterne, 1)),
                                 breite: 9)
                Image(systemName: "star.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Theme.gelb)
            }
            .frame(width: 78, height: 78)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(arbeit.klasse) · \(arbeit.fach)")
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
                Text("\(arbeit.sterne) von \(arbeit.maxSterne) Sternen")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText())
                Text("\(arbeit.fertigeUebungen) von \(arbeit.uebungen.count) Übungen geschafft")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 30)
    }
}

struct UebungKachel: View {
    let uebung: Uebung

    private var status: String {
        let n = uebung.aufgaben.count
        if uebung.laufend { return "Aufgabe \(uebung.beantwortet + 1) von \(n)" }
        if uebung.beste > 0 || uebung.istFertig { return "Bestes: \(uebung.beste) von \(n)" }
        return "Noch nicht geübt"
    }

    private var anteil: Double {
        Double(uebung.beantwortet) / Double(max(uebung.aufgaben.count, 1))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(uebung.symbol)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(Theme.navy)
                    .padding(.horizontal, 12)
                    .frame(minWidth: 46, minHeight: 38)
                    .background(Theme.gelb, in: Capsule())
                Spacer()
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(i < uebung.sterne ? Theme.gelb : Color.white.opacity(0.22))
                    }
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
            Text(uebung.titel)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            Text(status)
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
            if uebung.laufend {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.14))
                        Capsule().fill(Theme.gelb).frame(width: geo.size.width * anteil)
                    }
                }
                .frame(height: 5)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(14)
        .glasKarte(radius: 26)
    }
}

// MARK: - Punktefeld

struct PunkteFeld: View {
    let reihen: Int
    let spalten: Int

    var body: some View {
        let punkt: CGFloat = (reihen > 6 || spalten > 8) ? 12 : 16
        VStack(spacing: 5) {
            ForEach(0..<reihen, id: \.self) { _ in
                HStack(spacing: 5) {
                    ForEach(0..<spalten, id: \.self) { _ in
                        Circle()
                            .fill(Theme.gelb.gradient)
                            .frame(width: punkt, height: punkt)
                    }
                }
            }
        }
    }
}

// MARK: - Wackeln bei falscher Antwort

struct Wackeln: GeometryEffect {
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 10 * sin(animatableData * .pi * 3), y: 0)
        )
    }
}

// MARK: - Zahlentastatur

struct ZahlenTastatur: View {
    @Binding var text: String
    var maxLaenge: Int = 3
    var onPruefen: () -> Void

    private let tasten = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]
    private let spalten = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        LazyVGrid(columns: spalten, spacing: 12) {
            ForEach(tasten, id: \.self) { taste in
                Button { tippen(taste) } label: {
                    inhalt(taste)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .foregroundStyle(taste == "✓" ? Theme.navy : Color.white)
                        .background(farbe(taste),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(taste == "✓" ? 0 : 0.10), lineWidth: 1)
                        )
                }
                .buttonStyle(TastenStil())
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func inhalt(_ taste: String) -> some View {
        switch taste {
        case "⌫":
            Image(systemName: "delete.left.fill").font(.system(size: 22, weight: .bold))
        case "✓":
            Image(systemName: "checkmark").font(.system(size: 26, weight: .black))
        default:
            Text(taste).font(.system(size: 30, weight: .bold, design: .rounded))
        }
    }

    private func farbe(_ taste: String) -> Color {
        switch taste {
        case "✓": return Theme.gelb
        case "⌫": return Theme.koralle.opacity(0.30)
        default: return Color.white.opacity(0.10)
        }
    }

    private func tippen(_ taste: String) {
        switch taste {
        case "⌫": if !text.isEmpty { text.removeLast() }
        case "✓": onPruefen()
        default: if text.count < maxLaenge { text += taste }
        }
    }
}

// MARK: - Übungsansicht

enum Bewertung {
    case richtig, falsch, loesung
}

struct UebungView: View {
    @Bindable var uebung: Uebung
    @Environment(\.dismiss) private var dismiss

    @State private var eingabe = ""
    @State private var eingabe2 = ""
    @State private var aktivesFeld = 1
    @State private var bewertet: Aufgabe?
    @State private var bewertung: Bewertung = .richtig
    @State private var zeigeLoesungDialog = false
    @State private var zeigeJokerSheet = false
    @State private var jokerText = ""
    @State private var jokerMeldung: String? = nil
    @Environment(\.modelContext) private var context
    @AppStorage("modus") private var modus = ""
    @State private var lobWort = "Richtig."
    @State private var erklaerungText = ""
    @State private var mauerWerte: [[Int?]] = []
    @State private var mauerSchritt = 0
    @State private var kurzerHinweis: String?
    @State private var wackeln = 0

    private var naechste: Aufgabe? { uebung.sortierteAufgaben.first { !$0.erledigt } }
    private var aktuell: Aufgabe? { bewertet ?? naechste }

    var body: some View {
        ZStack {
            HintergrundView()

            if let a = aktuell {
                ScrollView {
                    VStack(spacing: 18) {
                        kopfzeile
                        karte(a)
                            .id(a.persistentModelID)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)))
                        unten(a)
                    }
                    .padding(.vertical, 12)
                    .animation(.smooth(duration: 0.35), value: aktuell?.persistentModelID)
                }
                .scrollIndicators(.hidden)
            } else {
                ergebnis
            }
        }
        .navigationTitle(uebung.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { bereiteVor() }
        .onChange(of: aktuell?.persistentModelID) { bereiteVor() }
        .confirmationDialog("Lösung anzeigen?",
                            isPresented: $zeigeLoesungDialog,
                            titleVisibility: .visible) {
            Button("Lösung zeigen") {
                if let a = aktuell, bewertet == nil { zeigeLoesung(a) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Aufgabe zählt dann nicht als richtig.")
        }
        .sheet(isPresented: $zeigeJokerSheet) {
            ShareSheet(items: [jokerText])
        }
        .alert("Joker", isPresented: Binding(get: { jokerMeldung != nil },
                                             set: { if !$0 { jokerMeldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(jokerMeldung ?? "")
        }
    }

    // MARK: Kopf mit Fortschritt

    private var kopfzeile: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(Array(uebung.sortierteAufgaben.enumerated()), id: \.offset) { _, t in
                    Capsule()
                        .fill(balkenFarbe(t))
                        .frame(height: 6)
                }
            }
            let nummer = min(uebung.beantwortet + (bewertet == nil ? 1 : 0), uebung.aufgaben.count)
            HStack {
                Text("Aufgabe \(nummer) von \(uebung.aufgaben.count)")
                    .contentTransition(.numericText())
                Spacer()
                Label("\(uebung.richtigAnzahl)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.gelb)
                    .contentTransition(.numericText())
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.textSanft)
        }
        .padding(.horizontal, 24)
    }

    private func balkenFarbe(_ t: Aufgabe) -> Color {
        if t.richtig == true { return Theme.gelb }
        if t.richtig == false { return Theme.koralle }
        if t.angesehen { return Theme.himmel }
        if t === aktuell { return Color.white }
        return Color.white.opacity(0.2)
    }

    // MARK: Aufgabenkarte

    private func karte(_ a: Aufgabe) -> some View {
        VStack(spacing: 16) {
            Text(a.frage)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            if a.art == "mauer" {
                mauer(a)
            } else {
                if let (x, y) = a.faktoren, a.hinweis.isEmpty {
                    PunkteFeld(reihen: x, spalten: y)
                }
                Text(angezeigteRechnung(a))
                    .font(grosseSchrift(a)
                          ? Font.system(size: 42, weight: .heavy, design: .rounded)
                          : Font.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)

                if !a.hinweis.isEmpty {
                    Text(a.hinweis)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.gelb)
                        .multilineTextAlignment(.center)
                }
                felder(a)
            }
            rueckmeldung
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 34)
        .padding(.horizontal, 20)
    }

    private func grosseSchrift(_ a: Aufgabe) -> Bool {
        a.rechnung.count <= 14 && !a.rechnung.contains("\n")
    }

    // Bei Vergleichsaufgaben steht nach der Antwort das richtige Zeichen in der Mitte
    private func angezeigteRechnung(_ a: Aufgabe) -> String {
        if a.art == "vergleich", bewertet != nil {
            return a.rechnung.replacingOccurrences(of: "?", with: a.antwort)
        }
        return a.rechnung
    }

    private var loesungAngezeigt: Bool { bewertet != nil && bewertung == .loesung }

    private func randFarbe(aktiv: Bool) -> Color {
        if loesungAngezeigt { return Theme.himmel }
        if aktiv && bewertet == nil { return Theme.gelb }
        return Color.clear
    }

    @ViewBuilder
    private func felder(_ a: Aufgabe) -> some View {
        if a.art == "rest" {
            HStack(spacing: 14) {
                feldPaar(titel: "Ergebnis", wert: eingabe, aktiv: aktivesFeld == 1, nummer: 1)
                feldPaar(titel: "Rest", wert: eingabe2, aktiv: aktivesFeld == 2, nummer: 2)
            }
            .modifier(Wackeln(animatableData: CGFloat(wackeln)))
        } else if a.art != "vergleich" {
            feldPaar(titel: "", wert: eingabe, aktiv: true, nummer: 1)
                .modifier(Wackeln(animatableData: CGFloat(wackeln)))
        }
    }

    private func feldPaar(titel: String, wert: String, aktiv: Bool, nummer: Int) -> some View {
        VStack(spacing: 6) {
            Text(wert.isEmpty ? "?" : wert)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(wert.isEmpty ? Color.white.opacity(0.35)
                                              : (loesungAngezeigt ? Theme.himmel : Color.white))
                .frame(minWidth: 104, minHeight: 62)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(randFarbe(aktiv: aktiv), lineWidth: 2.5)
                )
                .onTapGesture {
                    if bewertet == nil { aktivesFeld = nummer }
                }
            if !titel.isEmpty {
                Text(titel)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
            }
        }
    }

    // MARK: Rückmeldung

    @ViewBuilder
    private var rueckmeldung: some View {
        if bewertet != nil {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if bewertung == .loesung {
                        Image(systemName: "eye.fill")
                    }
                    Text(rueckTitel)
                }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(rueckFarbe)
                if !erklaerungText.isEmpty {
                    Text(erklaerungText)
                        .font(.subheadline)
                        .foregroundStyle(Color.white)
                }
                if bewertung == .loesung {
                    Text("Zählt nicht als richtig.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(rueckFarbe.opacity(0.20),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if let k = kurzerHinweis {
            Text(k)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.mint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.green.opacity(0.20),
                            in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var rueckTitel: String {
        switch bewertung {
        case .richtig: return lobWort
        case .falsch: return "Noch nicht richtig."
        case .loesung: return "Lösung angezeigt"
        }
    }

    private var rueckFarbe: Color {
        switch bewertung {
        case .richtig: return Theme.mint
        case .falsch: return Theme.koralle
        case .loesung: return Theme.himmel
        }
    }

    // MARK: Eingabebereich unten

    @ViewBuilder
    private func unten(_ a: Aufgabe) -> some View {
        if bewertet != nil {
            GelberKnopf(titel: uebung.istFertig ? "Fertig" : "Weiter") { bewertet = nil }
        } else {
            eingabeBereich(a)
            HStack(spacing: 12) {
                loesungKnopf
                JokerKnopf(uebrig: JokerStand.shared.uebrigHeute) { starteJoker(a) }
            }
        }
    }

    @ViewBuilder
    private func eingabeBereich(_ a: Aufgabe) -> some View {
        if a.art == "vergleich" {
            HStack(spacing: 12) {
                ForEach(["<", ">", "="], id: \.self) { z in
                    Button {
                        melde(a, ok: z == a.antwort, erklaerung: a.erklaerung)
                    } label: {
                        Text(z)
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 68)
                            .foregroundStyle(Color.white)
                            .background(Color.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(TastenStil())
                }
            }
            .padding(.horizontal, 24)
        } else {
            ZahlenTastatur(text: aktuellerText, maxLaenge: 3) { pruefen(a) }
        }
    }

    private var aktuellerText: Binding<String> {
        Binding(
            get: { aktivesFeld == 2 ? eingabe2 : eingabe },
            set: { if aktivesFeld == 2 { eingabe2 = $0 } else { eingabe = $0 } }
        )
    }

    private func starteJoker(_ a: Aufgabe) {
        guard JokerStand.shared.nutze() else {
            jokerMeldung = "Heute sind alle Joker aufgebraucht. Du schaffst das, versuch es noch einmal!"
            return
        }
        jokerText = Nachricht.jokerMathe(a)
        let kurz = Nachricht.jokerKurzMathe(a)
        let fach = a.uebung?.arbeit?.fach ?? "Mathe"
        let name = a.uebung?.titel ?? ""
        Task {
            if await JokerSender.sende(text: kurz, fach: fach, uebung: name) {
                jokerMeldung = "🃏 Joker abgeschickt! Deine Familie bekommt gleich eine Mitteilung. Die Tipps findest du im Tab Joker."
            } else {
                zeigeJokerSheet = true
            }
        }
    }

    private var loesungKnopf: some View {
        Button { zeigeLoesungDialog = true } label: {
            Label("Lösung zeigen", systemImage: "eye")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.himmel)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Theme.himmel.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    // MARK: Zahlenmauer

    @ViewBuilder
    private func mauer(_ a: Aufgabe) -> some View {
        let reihen = a.reihen
        let pos = mauerPosition(a)
        VStack(spacing: 5) {
            ForEach(Array(reihen.indices.reversed()), id: \.self) { i in
                HStack(spacing: 5) {
                    ForEach(reihen[i].indices, id: \.self) { j in
                        stein(reihen: reihen, i: i, j: j, pos: pos)
                    }
                }
            }
        }
    }

    private func stein(reihen: [[Int]], i: Int, j: Int, pos: (reihe: Int, spalte: Int)?) -> some View {
        var text = ""
        var hintergrund = Color.white.opacity(0.06)
        var schrift = Color.white
        var rand = Color.clear
        if i == 0 {
            text = String(reihen[i][j])
            hintergrund = Theme.gelb
            schrift = Theme.navy
        } else if mauerWerte.indices.contains(i),
                  mauerWerte[i].indices.contains(j),
                  let w = mauerWerte[i][j] {
            text = String(w)
            hintergrund = Color.white.opacity(0.18)
        } else if let p = pos, p.reihe == i, p.spalte == j, bewertet == nil {
            text = eingabe
            rand = Theme.gelb
            hintergrund = Color.white.opacity(0.10)
        }
        return Text(text)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(schrift)
            .frame(width: 58, height: 46)
            .background(hintergrund, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(rand, lineWidth: 2.5))
    }

    private func mauerPosition(_ a: Aufgabe) -> (reihe: Int, spalte: Int)? {
        let reihen = a.reihen
        guard reihen.count > 1 else { return nil }
        var n = 0
        for i in 1..<reihen.count {
            for j in 0..<reihen[i].count {
                if n == mauerSchritt { return (i, j) }
                n += 1
            }
        }
        return nil
    }

    private func mauerAnzahl(_ a: Aufgabe) -> Int {
        let reihen = a.reihen
        guard reihen.count > 1 else { return 0 }
        return reihen[1...].reduce(0) { $0 + $1.count }
    }

    // MARK: Logik

    private func bereiteVor() {
        eingabe = ""
        eingabe2 = ""
        aktivesFeld = 1
        mauerSchritt = 0
        kurzerHinweis = nil
        if let a = aktuell, a.art == "mauer" {
            var start: [[Int?]] = []
            for (i, r) in a.reihen.enumerated() {
                if i == 0 {
                    start.append(r.map { Optional($0) })
                } else {
                    start.append(Array<Int?>(repeating: nil, count: r.count))
                }
            }
            mauerWerte = start
        } else {
            mauerWerte = []
        }
    }

    private func gleich(_ x: String, _ y: String) -> Bool {
        if let i = Int(x), let j = Int(y) { return i == j }
        return x == y
    }

    private func pruefen(_ a: Aufgabe) {
        switch a.art {
        case "mauer":
            pruefeMauer(a)
        case "rest":
            if eingabe.isEmpty || eingabe2.isEmpty {
                if !eingabe.isEmpty && eingabe2.isEmpty { aktivesFeld = 2 }
                return
            }
            melde(a, ok: gleich(eingabe, a.antwort) && gleich(eingabe2, a.antwort2),
                  erklaerung: a.erklaerung)
        default:
            guard !eingabe.isEmpty else { return }
            melde(a, ok: gleich(eingabe, a.antwort), erklaerung: a.erklaerung)
        }
    }

    private func pruefeMauer(_ a: Aufgabe) {
        guard !eingabe.isEmpty, let pos = mauerPosition(a) else { return }
        let reihen = a.reihen
        let soll = reihen[pos.reihe][pos.spalte]
        let unten = reihen[pos.reihe - 1]
        if Int(eingabe) == soll {
            mauerWerte[pos.reihe][pos.spalte] = soll
            mauerSchritt += 1
            eingabe = ""
            Haptik.leicht()
            if mauerSchritt >= mauerAnzahl(a) {
                melde(a, ok: true, erklaerung: "Die Mauer stimmt komplett.")
            } else {
                kurzerHinweis = "Richtig. Weiter nach oben."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { kurzerHinweis = nil }
            }
        } else {
            mauerWerte[pos.reihe][pos.spalte] = soll
            eingabe = ""
            melde(a, ok: false,
                  erklaerung: "Hier gehört \(soll) hin: \(unten[pos.spalte]) + \(unten[pos.spalte + 1]) = \(soll)")
        }
    }

    private func melde(_ a: Aufgabe, ok: Bool, erklaerung: String) {
        a.richtig = ok
        bewertet = a
        bewertung = ok ? .richtig : .falsch
        kurzerHinweis = nil
        lobWort = ["Richtig.", "Stimmt.", "Genau so.", "Sehr gut."].randomElement() ?? "Richtig."
        if ok {
            Haptik.erfolg()
        } else {
            Haptik.fehler()
            withAnimation(.default) { wackeln += 1 }
        }
        if erklaerung.isEmpty {
            erklaerungText = a.art == "zahl"
                ? a.rechnung.replacingOccurrences(of: "\n", with: " ") + " " + a.antwort
                : ""
        } else {
            erklaerungText = erklaerung
        }
        if uebung.istFertig { abschliessen() }
    }

    private func zeigeLoesung(_ a: Aufgabe) {
        a.angesehen = true          // richtig bleibt bewusst leer
        bewertet = a
        bewertung = .loesung
        kurzerHinweis = nil
        Haptik.leicht()

        var zeilen: [String] = []
        switch a.art {
        case "rest":
            eingabe = a.antwort
            eingabe2 = a.antwort2
            zeilen.append("Lösung: \(a.antwort) Rest \(a.antwort2)")
        case "vergleich":
            zeilen.append("Lösung: \(a.antwort)")
        case "mauer":
            let reihen = a.reihen
            var voll = mauerWerte
            for i in reihen.indices where i > 0 && voll.indices.contains(i) {
                for j in reihen[i].indices where voll[i].indices.contains(j) {
                    voll[i][j] = reihen[i][j]
                }
            }
            mauerWerte = voll
            eingabe = ""
            zeilen.append("Die Mauer ist jetzt ausgefüllt.")
        default:
            eingabe = a.antwort
            zeilen.append("Lösung: \(a.antwort)")
        }
        if !a.erklaerung.isEmpty && a.art != "mauer" {
            zeilen.append(a.erklaerung)
        }
        erklaerungText = zeilen.joined(separator: "\n")
        if uebung.istFertig { abschliessen() }
    }

    private func abschliessen() {
        let gut = uebung.richtigAnzahl
        if gut > uebung.beste { uebung.beste = gut }
        uebung.sterne = max(uebung.sterne, uebung.sternAnzahl(fuer: gut))
        // Auf dem Kind-Gerät landet jede fertige Runde in der Warteschlange
        if modus == "kind" {
            context.insert(RundenErgebnis(
                klasse: uebung.arbeit?.klasse ?? "",
                fach: uebung.arbeit?.fach ?? "",
                arbeit: uebung.arbeit?.titel ?? "",
                uebung: uebung.titel,
                richtig: gut,
                gesamt: uebung.aufgaben.count,
                angesehen: uebung.angesehenAnzahl,
                quelle: "lokal"))
            CloudSync.anstossen(context)
        }
    }

    private func neuStarten() {
        uebung.aufgaben.forEach {
            $0.richtig = nil
            $0.angesehen = false
        }
        bewertet = nil
    }

    // MARK: Ergebnis

    @ViewBuilder
    private var ergebnis: some View {
        let gut = uebung.richtigAnzahl
        let n = uebung.sternAnzahl(fuer: gut)
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < n ? "star.fill" : "star")
                            .font(.system(size: 58))
                            .foregroundStyle(i < n ? Theme.gelb : Color.white.opacity(0.25))
                            .symbolEffect(.bounce, value: n)
                    }
                }
                Text("\(gut) von \(uebung.aufgaben.count)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                if uebung.angesehenAnzahl > 0 {
                    Label("\(uebung.angesehenAnzahl) Lösung\(uebung.angesehenAnzahl == 1 ? "" : "en") angeschaut",
                          systemImage: "eye.fill")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.himmel)
                }
                Text(lob(n))
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
                    .multilineTextAlignment(.center)

                if !uebung.tipp.isEmpty && gut < uebung.aufgaben.count {
                    Text("Tipp: " + uebung.tipp)
                        .font(.subheadline)
                        .foregroundStyle(Color.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.gelb.opacity(0.18),
                                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 24)
                }

                GelberKnopf(titel: "Nochmal üben") { neuStarten() }

                ShareLink(item: Nachricht.ergebnisMathe(uebung)) {
                    Label("Ergebnis an Eltern schicken", systemImage: "paperplane.fill")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Theme.gelb.opacity(0.15), in: Capsule())
                        .overlay(Capsule().stroke(Theme.gelb.opacity(0.5), lineWidth: 1.5))
                }
                .padding(.horizontal, 24)

                Button("Zurück zur Auswahl") { dismiss() }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                    .padding(.top, 4)
            }
            .padding(.top, 50)
        }
        .scrollIndicators(.hidden)
    }

    // Zusammenfassung für die Eltern (Stufe 0: manuell über das Teilen-Menü)
    private var ergebnisText: String {
        let gut = uebung.richtigAnzahl
        let n = uebung.sternAnzahl(fuer: gut)
        let sterne = String(repeating: "★", count: n) + String(repeating: "☆", count: 3 - n)
        var zeilen = [
            "YEM1N \(sterne)",
            "\(uebung.titel): \(gut) von \(uebung.aufgaben.count) richtig"
        ]
        if let a = uebung.arbeit {
            zeilen.append("\(a.klasse) · \(a.fach) · \(a.titel)")
        }
        if uebung.angesehenAnzahl > 0 {
            zeilen.append("Lösung angeschaut: \(uebung.angesehenAnzahl)")
        }
        let fehler = uebung.sortierteAufgaben
            .filter { $0.richtig == false }
            .prefix(3)
            .map { aufgabe -> String in
                let roh = aufgabe.rechnung.isEmpty ? aufgabe.frage : aufgabe.rechnung
                return String(roh.replacingOccurrences(of: "\n", with: " ").prefix(40))
            }
        if !fehler.isEmpty {
            zeilen.append("Noch nicht sicher: " + fehler.joined(separator: "; "))
        }
        return zeilen.joined(separator: "\n")
    }

    private func lob(_ sterne: Int) -> String {
        switch sterne {
        case 3: return "Das saß. Weiter so."
        case 2: return "Schon richtig gut."
        case 1: return "Das wird. Übe die Runde nochmal."
        default: return "Kein Problem. Gemeinsam nochmal anschauen."
        }
    }
}

// ============================================================
// MARK: - Sprachen (Englisch und Türkisch)
// ============================================================

// MARK: Katalog-Modelle

struct SprachInfo: Decodable {
    let name: String
    let flagge: String
    let sprachcode: String
}

struct Wort: Decodable, Identifiable {
    var id: String
    let emoji: String?
    let hinweis: String?
    let texte: [String: String]
    let alt: [String: [String]]
    var themaID: String
    var bilder: Bool

    private struct Schluessel: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Schluessel.self)
        var texte: [String: String] = [:]
        var emoji: String?
        var hinweis: String?
        var eigeneID = ""
        var alt: [String: [String]] = [:]
        for key in c.allKeys {
            switch key.stringValue {
            case "emoji": emoji = try? c.decode(String.self, forKey: key)
            case "hinweis": hinweis = try? c.decode(String.self, forKey: key)
            case "id": eigeneID = (try? c.decode(String.self, forKey: key)) ?? ""
            case "alt": alt = (try? c.decode([String: [String]].self, forKey: key)) ?? [:]
            default:
                if let s = try? c.decode(String.self, forKey: key) { texte[key.stringValue] = s }
            }
        }
        guard texte["de"] != nil else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath,
                                      debugDescription: "Wort ohne deutsches Feld"))
        }
        self.id = eigeneID
        self.emoji = emoji
        self.hinweis = hinweis
        self.texte = texte
        self.alt = alt
        self.themaID = ""
        self.bilder = true
    }
}

struct Thema: Decodable, Identifiable {
    let id: String
    let titel: String
    let emoji: String
    let stufe: Int
    let bilder: Bool
    let typ: String
    let woerter: [Wort]

    enum Keys: String, CodingKey { case id, titel, emoji, stufe, bilder, typ, woerter }

    init(id: String, titel: String, emoji: String, stufe: Int, bilder: Bool, typ: String, woerter: [Wort]) {
        self.id = id
        self.titel = titel
        self.emoji = emoji
        self.stufe = stufe
        self.bilder = bilder
        self.typ = typ
        self.woerter = woerter
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        let idWert = try c.decode(String.self, forKey: .id)
        let bilderWert = (try? c.decode(Bool.self, forKey: .bilder)) ?? true
        let roh = try c.decode([Wort].self, forKey: .woerter)
        self.id = idWert
        self.titel = try c.decode(String.self, forKey: .titel)
        self.emoji = (try? c.decode(String.self, forKey: .emoji)) ?? "📘"
        self.stufe = (try? c.decode(Int.self, forKey: .stufe)) ?? 2
        self.bilder = bilderWert
        self.typ = (try? c.decode(String.self, forKey: .typ)) ?? "woerter"
        self.woerter = roh.map { original -> Wort in
            var w = original
            w.themaID = idWert
            w.bilder = bilderWert
            if w.id.isEmpty {
                let basis = w.texte["en"] ?? w.texte["de"] ?? ""
                w.id = idWert + "/" + SprachHelfer.slug(basis)
            }
            return w
        }
    }
}

struct SprachKatalog: Decodable {
    var sprachen: [String: SprachInfo]
    var lernsprachen: [String]
    var themen: [Thema]

    enum Keys: String, CodingKey { case sprachen, lernsprachen, themen }

    init(sprachen: [String: SprachInfo], lernsprachen: [String], themen: [Thema]) {
        self.sprachen = sprachen
        self.lernsprachen = lernsprachen
        self.themen = themen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        self.sprachen = try c.decode([String: SprachInfo].self, forKey: .sprachen)
        self.lernsprachen = (try? c.decode([String].self, forKey: .lernsprachen)) ?? ["en", "tr"]
        self.themen = try c.decode([Thema].self, forKey: .themen)
    }
}

struct ThemenPaket: Decodable {
    let sprachen: [String: SprachInfo]?
    let lernsprachen: [String]?
    let themen: [Thema]
}

// MARK: Katalog-Speicher (eingebauter Katalog plus nachgeladene Themen)

@Observable
final class SprachKatalogStore {
    static let shared = SprachKatalogStore()
    var katalog = SprachKatalog(sprachen: [:], lernsprachen: [], themen: [])
    private let extraKey = "sprachKatalogExtraTexte"

    init() { baueNeu() }

    private func extraTexte() -> [String] {
        UserDefaults.standard.stringArray(forKey: extraKey) ?? []
    }

    func baueNeu() {
        var k = (try? JSONDecoder().decode(SprachKatalog.self, from: Data(SprachKatalogDaten.json.utf8)))
            ?? SprachKatalog(sprachen: [:], lernsprachen: [], themen: [])
        for text in extraTexte() {
            guard let p = try? JSONDecoder().decode(ThemenPaket.self, from: Data(text.utf8)) else { continue }
            if let neue = p.sprachen {
                for (code, info) in neue { k.sprachen[code] = info }
            }
            if let neue = p.lernsprachen {
                for code in neue where !k.lernsprachen.contains(code) { k.lernsprachen.append(code) }
            }
            for t in p.themen {
                if let i = k.themen.firstIndex(where: { $0.id == t.id }) {
                    k.themen[i] = t
                } else {
                    k.themen.append(t)
                }
            }
        }
        // Themen aus dem Vokabel-Editor haben Vorrang
        if let data = SprachEditorStore.shared.katalogDaten(),
           let p = try? JSONDecoder().decode(ThemenPaket.self, from: data) {
            for t in p.themen {
                if let i = k.themen.firstIndex(where: { $0.id == t.id }) {
                    k.themen[i] = t
                } else {
                    k.themen.append(t)
                }
            }
        }
        katalog = k
    }

    // Gibt die Anzahl geladener Themen zurück oder nil bei ungültigem Format
    func importiere(_ text: String) -> Int? {
        var t = text
        if let s = t.firstIndex(of: "{"), let e = t.lastIndex(of: "}"), s < e {
            t = String(t[s...e])
        }
        guard let p = try? JSONDecoder().decode(ThemenPaket.self, from: Data(t.utf8)),
              !p.themen.isEmpty,
              p.themen.allSatisfy({ !$0.woerter.isEmpty }) else { return nil }
        var liste = extraTexte()
        liste.append(t)
        UserDefaults.standard.set(liste, forKey: extraKey)
        baueNeu()
        return p.themen.count
    }

    func extraZuruecksetzen() {
        UserDefaults.standard.removeObject(forKey: extraKey)
        baueNeu()
    }

    func sprache(_ code: String) -> SprachInfo {
        katalog.sprachen[code] ?? SprachInfo(name: code, flagge: "🌍", sprachcode: "en-GB")
    }

    func alleWoerter(_ code: String) -> [Wort] {
        katalog.themen.flatMap { $0.woerter }.filter { $0.texte[code] != nil }
    }

    func themaWoerter(_ themaID: String) -> [Wort] {
        katalog.themen.first(where: { $0.id == themaID })?.woerter ?? []
    }
}

// MARK: Lernstand (Karteikasten, wird im Gerät gespeichert)

struct LernEintrag: Codable {
    var b: Int = 0
    var n: Date = Date.distantPast
    var r: Int = 0
    var f: Int = 0
}

struct VerlaufEintrag: Codable, Identifiable {
    var id = UUID()
    var ts: Date
    var sp: String
    var thema: String
    var art: String
    var richtig: Int
    var gesamt: Int
}

@Observable
final class SprachStand {
    static let shared = SprachStand()
    var eintraege: [String: LernEintrag] = [:]
    var verlauf: [VerlaufEintrag] = []
    private let key = "sprachStandV1"
    static let dauer: [TimeInterval] = [0, 86_400, 3 * 86_400, 7 * 86_400]

    private struct Speicher: Codable {
        var eintraege: [String: LernEintrag]
        var verlauf: [VerlaufEintrag]
    }

    init() { lade() }

    private func lade() {
        guard let d = UserDefaults.standard.data(forKey: key),
              let s = try? JSONDecoder().decode(Speicher.self, from: d) else { return }
        eintraege = s.eintraege
        verlauf = s.verlauf
    }

    func sichere() {
        let s = Speicher(eintraege: eintraege, verlauf: verlauf)
        if let d = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }

    func eintrag(_ w: Wort, _ c: String) -> LernEintrag {
        eintraege[c + "|" + w.id] ?? LernEintrag()
    }

    func bewerte(_ w: Wort, _ c: String, richtig ok: Bool) {
        var e = eintrag(w, c)
        if ok {
            e.r += 1
            e.b = min(e.b + 1, 3)
        } else {
            e.f += 1
            e.b = 0
        }
        e.n = Date.now.addingTimeInterval(SprachStand.dauer[e.b])
        eintraege[c + "|" + w.id] = e
        sichere()
    }

    func kannIch(_ w: Wort, _ c: String) {
        var e = eintrag(w, c)
        e.b = max(e.b, 1)
        e.n = Date.now.addingTimeInterval(SprachStand.dauer[e.b])
        eintraege[c + "|" + w.id] = e
        sichere()
    }

    func gelernt(_ w: Wort, _ c: String) -> Bool { eintrag(w, c).b >= 2 }

    func gesehen(_ w: Wort, _ c: String) -> Bool {
        let e = eintrag(w, c)
        return e.r + e.f > 0 || e.b > 0
    }

    func faellig(_ c: String, _ woerter: [Wort]) -> [Wort] {
        woerter.filter { gesehen($0, c) && eintrag($0, c).n <= Date.now }
    }

    func zuruecksetzen() {
        eintraege = [:]
        verlauf = []
        sichere()
    }
}

// MARK: Schreibweise prüfen

enum SprachHelfer {
    enum Tipp { case richtig, fast, falsch }

    static func slug(_ s: String) -> String {
        let basis = s.folding(options: .diacriticInsensitive, locale: nil).lowercased()
        var out = ""
        var letzterStrich = false
        for ch in basis {
            if ch.isASCII && (ch.isLetter || ch.isNumber) {
                out.append(ch)
                letzterStrich = false
            } else if !letzterStrich {
                out.append("-")
                letzterStrich = true
            }
        }
        return out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    static func bild(_ w: Wort) -> String {
        w.bilder ? (w.emoji ?? "") : ""
    }

    static func akzeptiert(_ w: Wort, _ sp: String) -> [String] {
        [w.texte[sp] ?? ""] + (w.alt[sp] ?? [])
    }

    static func norm(_ s: String, _ sp: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        t = sp == "tr" ? t.lowercased(with: Locale(identifier: "tr")) : t.lowercased()
        let weg = CharacterSet(charactersIn: ".,!?;:…\"'“”‘’")
        t = t.components(separatedBy: weg).joined()
        t = t.replacingOccurrences(of: "-", with: " ")
        t = t.replacingOccurrences(of: "\u{2013}", with: " ")
        t = t.replacingOccurrences(of: "\u{2014}", with: " ")
        t = t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        if sp == "en" {
            for p in ["to ", "the ", "a ", "an "] where t.hasPrefix(p) {
                t = String(t.dropFirst(p.count))
                break
            }
        }
        return t
    }

    // Sonderzeichen vereinfachen, damit "kirmizi" als fast richtig für "kırmızı" gilt
    static func falte(_ s: String) -> String {
        var t = s
        let paare: [(String, String)] = [
            ("ı", "i"), ("İ", "i"), ("ğ", "g"), ("ü", "u"), ("ş", "s"), ("ö", "o"),
            ("ç", "c"), ("â", "a"), ("ä", "a"), ("î", "i"), ("û", "u"), ("ß", "ss")
        ]
        for (a, b) in paare { t = t.replacingOccurrences(of: a, with: b) }
        return t.replacingOccurrences(of: " ", with: "")
    }

    static func pruefeTipp(_ w: Wort, _ eingabe: String, _ sp: String) -> Tipp {
        let e = norm(eingabe, sp)
        let liste = akzeptiert(w, sp)
        if liste.contains(where: { norm($0, sp) == e }) { return .richtig }
        if liste.contains(where: { falte(norm($0, sp)) == falte(e) }) { return .fast }
        return .falsch
    }
}

// MARK: Sprachausgabe

final class Sprecher {
    static let shared = Sprecher()
    private let synth = AVSpeechSynthesizer()

    func hatStimme(_ code: String) -> Bool {
        AVSpeechSynthesisVoice(language: code) != nil
    }

    func sprich(_ text: String, code: String) {
        let an = UserDefaults.standard.object(forKey: "sprachTon") as? Bool ?? true
        guard an, !text.isEmpty else { return }
        let sitzung = AVAudioSession.sharedInstance()
        try? sitzung.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? sitzung.setActive(true)
        synth.stopSpeaking(at: .immediate)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: code)
        u.rate = 0.42
        u.pitchMultiplier = 1.05
        synth.speak(u)
    }
}

// MARK: Fragen und Sitzung

enum SprachArt: String {
    case quiz, hoeren, tippen, test, paare

    var titel: String {
        switch self {
        case .quiz: return "Quiz"
        case .hoeren: return "Hören"
        case .tippen: return "Tippen"
        case .test: return "Vokabeltest"
        case .paare: return "Paare"
        }
    }
}

enum FrageTyp { case de2f, f2de, bild, hoer, tipp }

enum FrageErgebnis { case offen, richtig, falsch }

struct AntwortOption: Identifiable {
    let id = UUID()
    let text: String
    let ok: Bool
}

struct Frage: Identifiable {
    let id = UUID()
    let wort: Wort
    let typ: FrageTyp
    let optionen: [AntwortOption]
}

enum SprachGenerator {
    static func nachStand(_ liste: [Wort], _ c: String) -> [Wort] {
        let stand = SprachStand.shared
        let bewertet = liste.map { w -> (Wort, Double) in
            let e = stand.eintrag(w, c)
            let zufall = Double.random(in: 0..<3)
            return (w, Double(e.b) * 2 + zufall - (e.f > 0 ? 1 : 0))
        }
        return bewertet.sorted { $0.1 < $1.1 }.map { $0.0 }
    }

    static func gewichtet(_ liste: [Wort], n: Int, sprache c: String) -> [Wort] {
        Array(nachStand(liste, c).prefix(n)).shuffled()
    }

    static func baueFrage(_ w: Wort, art: SprachArt, nr: Int, sprache c: String) -> Frage {
        let hatBild = !SprachHelfer.bild(w).isEmpty
        let typen: [FrageTyp] = hatBild ? [.de2f, .f2de, .bild] : [.de2f, .f2de]
        let typ: FrageTyp
        switch art {
        case .hoeren:
            typ = .hoer
        case .tippen:
            typ = .tipp
        case .test:
            typ = (nr % 2 == 1) ? .tipp : (typen.randomElement() ?? .de2f)
        default:
            typ = typen.randomElement() ?? .de2f
        }
        let opts: [AntwortOption] = (typ == .tipp) ? [] : optionen(w, typ, c)
        return Frage(wort: w, typ: typ, optionen: opts)
    }

    static func optionen(_ w: Wort, _ typ: FrageTyp, _ c: String) -> [AntwortOption] {
        let store = SprachKatalogStore.shared
        let deSeite = (typ == .f2de || typ == .hoer)

        func text(_ x: Wort) -> String {
            if deSeite {
                let b = SprachHelfer.bild(x)
                return (b.isEmpty ? "" : b + " ") + (x.texte["de"] ?? "")
            }
            return x.texte[c] ?? ""
        }
        func schluessel(_ x: Wort) -> String {
            deSeite ? (x.texte["de"] ?? "").lowercased() : SprachHelfer.norm(x.texte[c] ?? "", c)
        }

        var sperre: Set<String> = [schluessel(w)]
        if !deSeite {
            for a in SprachHelfer.akzeptiert(w, c) { sperre.insert(SprachHelfer.norm(a, c)) }
        }
        let eigene = store.themaWoerter(w.themaID).filter { $0.id != w.id && $0.texte[c] != nil }.shuffled()
        let fremde = store.alleWoerter(c).filter { $0.themaID != w.themaID }.shuffled()
        var opts = [AntwortOption(text: text(w), ok: true)]
        for x in eigene + fremde {
            if opts.count >= 4 { break }
            let k = schluessel(x)
            if sperre.contains(k) { continue }
            sperre.insert(k)
            opts.append(AntwortOption(text: text(x), ok: false))
        }
        return opts.shuffled()
    }
}

@Observable
final class SprachSitzung {
    let thema: Thema
    let art: SprachArt
    let sprache: String
    var fragen: [Frage] = []
    var index = 0
    var richtig = 0
    var fehler: [Wort] = []
    var ergebnisse: [FrageErgebnis] = []
    var beantwortet = false
    var gewaehlt: Int? = nil
    var tippErgebnis: SprachHelfer.Tipp? = nil
    var tippText = ""
    var fertig = false

    init(thema: Thema, art: SprachArt, sprache: String, woerter: [Wort]) {
        self.thema = thema
        self.art = art
        self.sprache = sprache
        let auswahl = SprachGenerator.gewichtet(woerter, n: min(10, woerter.count), sprache: sprache)
        var liste: [Frage] = []
        for (i, w) in auswahl.enumerated() {
            liste.append(SprachGenerator.baueFrage(w, art: art, nr: i, sprache: sprache))
        }
        self.fragen = liste
        self.ergebnisse = Array(repeating: FrageErgebnis.offen, count: liste.count)
    }

    var aktuelle: Frage? { fragen.indices.contains(index) ? fragen[index] : nil }

    func antworteOption(_ i: Int) {
        guard !beantwortet, let f = aktuelle, f.optionen.indices.contains(i) else { return }
        gewaehlt = i
        wertung(f.optionen[i].ok)
    }

    func pruefeTipp(_ text: String) {
        guard !beantwortet, let f = aktuelle else { return }
        let r = SprachHelfer.pruefeTipp(f.wort, text, sprache)
        tippText = text
        tippErgebnis = r
        wertung(r != .falsch)
    }

    private func wertung(_ ok: Bool) {
        guard let f = aktuelle else { return }
        beantwortet = true
        ergebnisse[index] = ok ? .richtig : .falsch
        SprachStand.shared.bewerte(f.wort, sprache, richtig: ok)
        if ok {
            richtig += 1
            Haptik.erfolg()
        } else {
            fehler.append(f.wort)
            Haptik.fehler()
        }
    }

    func weiter() {
        if index + 1 >= fragen.count {
            fertig = true
            return
        }
        index += 1
        beantwortet = false
        gewaehlt = nil
        tippErgebnis = nil
        tippText = ""
    }
}

// Ergebnis speichern: Verlauf auf dem Gerät und, auf dem Kind-Gerät, in die Warteschlange
enum SprachErgebnis {
    static func speichere(thema: Thema, art: SprachArt, sprache: String,
                          richtig: Int, gesamt: Int, context: ModelContext, istKind: Bool) {
        let stand = SprachStand.shared
        stand.verlauf.append(VerlaufEintrag(ts: Date.now, sp: sprache, thema: thema.titel,
                                            art: art.rawValue, richtig: richtig, gesamt: gesamt))
        if stand.verlauf.count > 300 { stand.verlauf = Array(stand.verlauf.suffix(300)) }
        stand.sichere()
        if istKind {
            let info = SprachKatalogStore.shared.sprache(sprache)
            context.insert(RundenErgebnis(klasse: "Sprachen", fach: info.name, arbeit: "Wortschatz",
                                          uebung: "\(info.flagge) \(thema.titel)",
                                          richtig: richtig, gesamt: gesamt, angesehen: 0,
                                          quelle: "lokal"))
            CloudSync.anstossen(context)
        }
    }

    static func teilenText(thema: Thema, art: SprachArt, sprache: String,
                           richtig: Int, gesamt: Int, fehler: [Wort] = []) -> String {
        Nachricht.ergebnisSprache(thema: thema, art: art, sprache: sprache,
                                  richtig: richtig, gesamt: gesamt, fehler: fehler)
    }
}

// MARK: Tabs

struct KindTabs: View {
    var body: some View {
        TabView {
            StartView()
                .tabItem { Label("Mathe", systemImage: "plus.forwardslash.minus") }
            SprachStartView()
                .tabItem { Label("Sprachen", systemImage: "globe") }
            KindJokerView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
        }
    }
}

// MARK: Sprachen: Startseite

struct SprachStartView: View {
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared
    @AppStorage("sprachTon") private var ton = true

    private var stimmenFehlen: Bool {
        !store.katalog.lernsprachen.allSatisfy {
            Sprecher.shared.hatStimme(store.sprache($0).sprachcode)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        kopf
                        if stimmenFehlen { warnung }
                        Text("Was möchtest du lernen?")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                        ForEach(store.katalog.lernsprachen, id: \.self) { c in
                            sprachKarte(c)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var kopf: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text("Sprachen lernen")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Button { ton.toggle() } label: {
                rundSymbol(ton ? "speaker.wave.2.fill" : "speaker.slash.fill")
            }
            NavigationLink { SprachBerichtView() } label: { rundSymbol("chart.bar.fill") }
            NavigationLink { SprachEinstellungenView() } label: { rundSymbol("gearshape.fill") }
        }
    }

    private func rundSymbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.12), in: Circle())
    }

    private var warnung: some View {
        Text("Auf diesem Gerät fehlt eine Stimme für eine Sprache. Vorlesen klappt dort nicht, das Lernen geht trotzdem.")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(12)
            .background(Theme.gelb.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func sprachKarte(_ c: String) -> some View {
        let info = store.sprache(c)
        let woerter = store.alleWoerter(c)
        let g = woerter.filter { stand.gelernt($0, c) }.count
        let anteil = woerter.isEmpty ? 0 : Double(g) / Double(woerter.count)
        return NavigationLink {
            SprachThemenView(sprache: c)
        } label: {
            HStack(spacing: 16) {
                Text(info.flagge).font(.system(size: 44))
                VStack(alignment: .leading, spacing: 6) {
                    Text(info.name)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.white)
                    Text("\(g) von \(woerter.count) Wörtern gelernt")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSanft)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.14))
                            Capsule().fill(Theme.gelb).frame(width: geo.size.width * anteil)
                        }
                    }
                    .frame(height: 7)
                }
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gelb)
            }
            .padding(18)
            .glasKarte(radius: 28)
        }
        .buttonStyle(TastenStil())
    }
}

// MARK: Sprachen: Themenliste

struct SprachThemenView: View {
    @State var sprache: String
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var info: SprachInfo { store.sprache(sprache) }
    private var faellige: [Wort] { stand.faellig(sprache, store.alleWoerter(sprache)) }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    chips
                    wiederholen
                    ForEach([1, 2, 3], id: \.self) { stufe in
                        stufenBlock(stufe)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(info.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(store.katalog.lernsprachen, id: \.self) { c in
                let aktiv = (c == sprache)
                Button { sprache = c } label: {
                    Text("\(store.sprache(c).flagge) \(store.sprache(c).name)")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(aktiv ? Theme.navy : Color.white)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }

    @ViewBuilder
    private var wiederholen: some View {
        let liste = faellige
        if liste.isEmpty {
            Text("🔁 Heute ist nichts zu wiederholen.")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSanft)
                .frame(maxWidth: .infinity)
                .padding(16)
                .glasKarte(radius: 24)
        } else {
            NavigationLink {
                SprachFragenView(thema: Thema(id: "*", titel: "Wiederholen", emoji: "🔁", stufe: 1,
                                              bilder: true, typ: "woerter", woerter: liste),
                                 art: .quiz, sprache: sprache, woerter: liste)
            } label: {
                Text("🔁 Heute wiederholen (\(liste.count))")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
        }
    }

    @ViewBuilder
    private func stufenBlock(_ stufe: Int) -> some View {
        let themen = store.katalog.themen.filter { $0.stufe == stufe && $0.woerter.contains(where: { $0.texte[sprache] != nil }) }
        if !themen.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(stufenTitel(stufe))
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                    .padding(.leading, 4)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(themen) { t in kachel(t) }
                }
            }
        }
    }

    private func stufenTitel(_ s: Int) -> String {
        switch s {
        case 1: return "Stufe 1: Los geht’s"
        case 2: return "Stufe 2: Weiter geht’s"
        default: return "Stufe 3: Für Profis"
        }
    }

    private func kachel(_ t: Thema) -> some View {
        let ws = t.woerter.filter { $0.texte[sprache] != nil }
        let g = ws.filter { stand.gelernt($0, sprache) }.count
        let anteil = ws.isEmpty ? 0 : Double(g) / Double(ws.count)
        let sterne = anteil >= 0.95 ? 3 : (anteil >= 0.7 ? 2 : (anteil >= 0.4 ? 1 : 0))
        return NavigationLink {
            SprachThemaView(thema: t, sprache: sprache)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(t.emoji).font(.system(size: 34))
                Text(t.titel)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text("\(g) von \(ws.count)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(i < sterne ? Theme.gelb : Color.white.opacity(0.22))
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(14)
            .glasKarte(radius: 26)
        }
        .buttonStyle(TastenStil())
    }
}

// MARK: Sprachen: Thema mit Lernmodi

struct SprachThemaView: View {
    let thema: Thema
    let sprache: String
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var info: SprachInfo { store.sprache(sprache) }
    private var woerter: [Wort] { thema.woerter.filter { $0.texte[sprache] != nil } }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 4) {
                        Text(thema.emoji).font(.system(size: 56))
                        Text("\(woerter.count) Wörter · \(info.flagge) \(info.name)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                    }
                    modi
                    wortliste
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(thema.titel)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var modi: some View {
        NavigationLink { SprachKartenView(thema: thema, sprache: sprache, woerter: woerter) } label: {
            modusZeile("🃏", "Lernen", "Karten ansehen und anhören")
        }
        .buttonStyle(TastenStil())
        NavigationLink { SprachFragenView(thema: thema, art: .quiz, sprache: sprache, woerter: woerter) } label: {
            modusZeile("🎯", "Quiz", "Aussuchen, 10 Fragen")
        }
        .buttonStyle(TastenStil())
        NavigationLink { SprachFragenView(thema: thema, art: .hoeren, sprache: sprache, woerter: woerter) } label: {
            modusZeile("🎧", "Hören", "Wort hören und verstehen")
        }
        .buttonStyle(TastenStil())
        NavigationLink { SprachFragenView(thema: thema, art: .tippen, sprache: sprache, woerter: woerter) } label: {
            modusZeile("⌨️", "Tippen", "Wort selbst schreiben")
        }
        .buttonStyle(TastenStil())
        if woerter.count >= 4 {
            NavigationLink { SprachPaareView(thema: thema, sprache: sprache, woerter: woerter) } label: {
                modusZeile("🧩", "Paare", "Passende Paare finden")
            }
            .buttonStyle(TastenStil())
        }
        NavigationLink { SprachFragenView(thema: thema, art: .test, sprache: sprache, woerter: woerter) } label: {
            modusZeile("📝", "Vokabeltest", "Gemischt, 10 Fragen mit Stern")
        }
        .buttonStyle(TastenStil())
    }

    private func modusZeile(_ ico: String, _ titel: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Text(ico)
                .font(.system(size: 28))
                .frame(width: 54, height: 54)
                .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.gelb)
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private var wortliste: some View {
        DisclosureGroup {
            VStack(spacing: 0) {
                ForEach(woerter) { w in
                    wortZeile(w)
                }
            }
            .padding(.top, 6)
        } label: {
            Text("Alle Wörter ansehen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private func wortZeile(_ w: Wort) -> some View {
        let e = stand.eintrag(w, sprache)
        let fremd = w.texte[sprache] ?? ""
        return HStack(spacing: 12) {
            Button {
                Sprecher.shared.sprich(fremd, code: info.sprachcode)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 38, height: 38)
                    .background(Theme.gelb, in: Circle())
            }
            .buttonStyle(TastenStil())
            VStack(alignment: .leading, spacing: 2) {
                Text(fremd)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                Text("\(SprachHelfer.bild(w)) \(w.texte["de"] ?? "")")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            HStack(spacing: 3) {
                ForEach(1...3, id: \.self) { i in
                    Circle()
                        .fill(e.b >= i ? Theme.gelb : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: Sprachen: Karteikarten

struct SprachKartenView: View {
    let thema: Thema
    let sprache: String
    let woerter: [Wort]
    @Environment(\.dismiss) private var dismiss
    @State private var liste: [Wort] = []
    @State private var i = 0
    @State private var auf = false
    @State private var kann = 0
    @State private var nochmal = 0
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var info: SprachInfo { store.sprache(sprache) }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 16) {
                    if i < liste.count {
                        karteikarte(liste[i])
                    } else if !liste.isEmpty {
                        ende
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(thema.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if liste.isEmpty { starte() } }
    }

    private func starte() {
        liste = woerter.sorted { stand.eintrag($0, sprache).b < stand.eintrag($1, sprache).b }
        i = 0
        auf = false
        kann = 0
        nochmal = 0
    }

    private func karteikarte(_ w: Wort) -> some View {
        let fremd = w.texte[sprache] ?? ""
        let b = SprachHelfer.bild(w)
        return VStack(spacing: 16) {
            HStack {
                Text("Karte \(i + 1) von \(liste.count)")
                Spacer()
                Text("\(kann) gekonnt")
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.textSanft)

            VStack(spacing: 10) {
                if !b.isEmpty { Text(b).font(.system(size: 80)) }
                if auf {
                    Text(w.texte["de"] ?? "")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textSanft)
                    Text(fremd)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .multilineTextAlignment(.center)
                    Button {
                        Sprecher.shared.sprich(fremd, code: info.sprachcode)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.navy)
                            .frame(width: 52, height: 52)
                            .background(Theme.gelb, in: Circle())
                    }
                    .buttonStyle(TastenStil())
                    if let h = w.hinweis {
                        Text(h)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.himmel)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text(w.texte["de"] ?? "")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                    Text("Tippe, um das Wort zu sehen")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 260)
            .padding(22)
            .glasKarte(radius: 32)
            .contentShape(Rectangle())
            .onTapGesture {
                auf.toggle()
                if auf { Sprecher.shared.sprich(fremd, code: info.sprachcode) }
            }

            if auf {
                GelberKnopf(titel: "✅ Kann ich") {
                    stand.kannIch(w, sprache)
                    kann += 1
                    weiter()
                }
                Button {
                    nochmal += 1
                    weiter()
                } label: {
                    Text("🔁 Nochmal")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.koralle)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Theme.koralle.opacity(0.18), in: Capsule())
                }
                .buttonStyle(TastenStil())
                .padding(.horizontal, 24)
            }
        }
    }

    private func weiter() {
        i += 1
        auf = false
    }

    private var ende: some View {
        VStack(spacing: 16) {
            Text("🎉").font(.system(size: 70))
            Text("Alle Karten durch")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(Color.white)
            Text("\(kann) gekonnt, \(nochmal) zum Wiederholen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
            GelberKnopf(titel: "🔁 Karten nochmal") { starte() }
            Button("Zurück zum Thema") { dismiss() }
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.gelb)
        }
        .padding(.top, 40)
    }
}

// MARK: Sprachen: Fragen (Quiz, Hören, Tippen, Vokabeltest)

struct SprachFragenView: View {
    let thema: Thema
    let art: SprachArt
    let sprache: String
    let woerter: [Wort]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("modus") private var modus = ""
    @State private var sitzung: SprachSitzung?
    @State private var eingabe = ""
    @State private var zeigeJokerSheet = false
    @State private var jokerText = ""
    @State private var jokerMeldung: String? = nil
    @FocusState private var fokus: Bool
    private let store = SprachKatalogStore.shared

    private var info: SprachInfo { store.sprache(sprache) }

    var body: some View {
        ZStack {
            HintergrundView()
            if let s = sitzung {
                if s.fragen.isEmpty {
                    Text("Für dieses Thema gibt es noch keine Wörter.")
                        .foregroundStyle(Theme.textSanft)
                } else if s.fertig {
                    ergebnis(s)
                } else {
                    frageAnsicht(s)
                }
            }
        }
        .navigationTitle("\(art.titel): \(thema.titel)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if sitzung == nil { neueSitzung(woerter, art) }
        }
        .onChange(of: sitzung?.index) { sprichFrage() }
        .onChange(of: sitzung?.fertig) {
            if sitzung?.fertig == true { speichere() }
        }
        .sheet(isPresented: $zeigeJokerSheet) {
            ShareSheet(items: [jokerText])
        }
        .alert("Joker", isPresented: Binding(get: { jokerMeldung != nil },
                                             set: { if !$0 { jokerMeldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(jokerMeldung ?? "")
        }
    }

    // MARK: Ablauf

    private func neueSitzung(_ liste: [Wort], _ a: SprachArt) {
        sitzung = SprachSitzung(thema: thema, art: a, sprache: sprache, woerter: liste)
        eingabe = ""
        sprichFrage()
    }

    private func sprichFrage() {
        guard let s = sitzung, !s.fertig, !s.beantwortet, let f = s.aktuelle else { return }
        if f.typ == .f2de || f.typ == .hoer {
            Sprecher.shared.sprich(f.wort.texte[sprache] ?? "", code: info.sprachcode)
        }
    }

    private func speichere() {
        guard let s = sitzung else { return }
        SprachErgebnis.speichere(thema: s.thema, art: s.art, sprache: sprache,
                                 richtig: s.richtig, gesamt: s.fragen.count,
                                 context: context, istKind: modus == "kind")
    }

    private func antworte(_ i: Int, _ s: SprachSitzung) {
        guard !s.beantwortet, let f = s.aktuelle else { return }
        s.antworteOption(i)
        Sprecher.shared.sprich(f.wort.texte[sprache] ?? "", code: info.sprachcode)
    }

    private func pruefeTipp(_ s: SprachSitzung) {
        guard !s.beantwortet, let f = s.aktuelle else { return }
        let t = eingabe.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return }
        s.pruefeTipp(t)
        fokus = false
        Sprecher.shared.sprich(f.wort.texte[sprache] ?? "", code: info.sprachcode)
    }

    private func weiter(_ s: SprachSitzung) {
        eingabe = ""
        s.weiter()
    }

    // MARK: Frage

    @ViewBuilder
    private func frageAnsicht(_ s: SprachSitzung) -> some View {
        if let f = s.aktuelle {
            ScrollView {
                VStack(spacing: 16) {
                    fortschritt(s)
                    karte(f)
                    if f.typ == .tipp {
                        tippBereich(s)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Array(f.optionen.enumerated()), id: \.offset) { i, o in
                                optionKnopf(i, o, s)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    if !s.beantwortet && art != .test {
                        JokerKnopf(uebrig: JokerStand.shared.uebrigHeute) { starteJoker(f) }
                    }
                    if s.beantwortet {
                        rueckmeldung(f, s)
                        GelberKnopf(titel: s.index + 1 >= s.fragen.count ? "Ergebnis" : "Weiter") {
                            weiter(s)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func starteJoker(_ f: Frage) {
        guard JokerStand.shared.nutze() else {
            jokerMeldung = "Heute sind alle Joker aufgebraucht. Du schaffst das, versuch es noch einmal!"
            return
        }
        jokerText = Nachricht.jokerSprache(f, sprache: sprache)
        let kurz = Nachricht.jokerKurzSprache(f, sprache: sprache)
        let fach = info.name
        let name = thema.titel
        Task {
            if await JokerSender.sende(text: kurz, fach: fach, uebung: name) {
                jokerMeldung = "🃏 Joker abgeschickt! Deine Familie bekommt gleich eine Mitteilung. Die Tipps findest du im Tab Joker."
            } else {
                zeigeJokerSheet = true
            }
        }
    }

    private func segmentFarbe(_ s: SprachSitzung, _ i: Int) -> Color {
        switch s.ergebnisse[i] {
        case .richtig: return Theme.gelb
        case .falsch: return Theme.koralle
        case .offen: return i == s.index ? Color.white : Color.white.opacity(0.2)
        }
    }

    private func fortschritt(_ s: SprachSitzung) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<s.fragen.count, id: \.self) { i in
                    Capsule().fill(segmentFarbe(s, i)).frame(height: 6)
                }
            }
            HStack {
                Text("Frage \(s.index + 1) von \(s.fragen.count)")
                Spacer()
                Label("\(s.richtig)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(Theme.gelb)
            }
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(Theme.textSanft)
        }
        .padding(.horizontal, 24)
    }

    private func lautsprecher(_ text: String, groesse: CGFloat = 44) -> some View {
        Button {
            Sprecher.shared.sprich(text, code: info.sprachcode)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: groesse * 0.45, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: groesse, height: groesse)
                .background(Theme.gelb, in: Circle())
        }
        .buttonStyle(TastenStil())
    }

    private func hilfe(_ text: String) -> some View {
        Text(text)
            .font(.system(.subheadline, design: .rounded).weight(.medium))
            .foregroundStyle(Theme.textSanft)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func prompt(_ f: Frage) -> some View {
        let w = f.wort
        let b = SprachHelfer.bild(w)
        let fremd = w.texte[sprache] ?? ""
        let de = w.texte["de"] ?? ""
        switch f.typ {
        case .de2f, .tipp:
            VStack(spacing: 6) {
                if !b.isEmpty { Text(b).font(.system(size: 72)) }
                Text(de)
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                hilfe(f.typ == .tipp ? "Schreibe es auf \(info.name)." : "Wie heißt das auf \(info.name)?")
            }
        case .bild:
            VStack(spacing: 6) {
                Text(b).font(.system(size: 88))
                hilfe("Wie heißt das auf \(info.name)?")
            }
        case .f2de:
            VStack(spacing: 10) {
                Text(fremd)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                    .multilineTextAlignment(.center)
                lautsprecher(fremd)
                hilfe("Was bedeutet das?")
            }
        case .hoer:
            VStack(spacing: 10) {
                lautsprecher(fremd, groesse: 84)
                hilfe("Was hörst du?")
            }
        }
    }

    private func karte(_ f: Frage) -> some View {
        prompt(f)
            .frame(maxWidth: .infinity)
            .padding(24)
            .glasKarte(radius: 32)
            .padding(.horizontal, 20)
    }

    private func optionKnopf(_ i: Int, _ o: AntwortOption, _ s: SprachSitzung) -> some View {
        var hintergrund = Color.white.opacity(0.10)
        var schrift = Color.white
        var rand = Color.white.opacity(0.14)
        if s.beantwortet {
            if o.ok {
                hintergrund = Theme.mint.opacity(0.22)
                schrift = Theme.mint
                rand = Theme.mint
            } else if s.gewaehlt == i {
                hintergrund = Theme.koralle.opacity(0.22)
                schrift = Theme.koralle
                rand = Theme.koralle
            } else {
                schrift = Color.white.opacity(0.45)
            }
        }
        return Button {
            antworte(i, s)
        } label: {
            Text(o.text)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(schrift)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .background(hintergrund, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(rand, lineWidth: 1.5)
                )
        }
        .buttonStyle(TastenStil())
    }

    private func tippBereich(_ s: SprachSitzung) -> some View {
        VStack(spacing: 10) {
            TextField("…", text: $eingabe)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($fokus)
                .disabled(s.beantwortet)
                .submitLabel(.done)
                .onSubmit { pruefeTipp(s) }
                .padding(16)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.gelb, lineWidth: 2)
                )
            if sprache == "tr" && !s.beantwortet {
                HStack(spacing: 6) {
                    ForEach(["ç", "ğ", "ı", "ö", "ş", "ü", "İ"], id: \.self) { z in
                        Button { eingabe += z } label: {
                            Text(z)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(TastenStil())
                    }
                }
            }
            if !s.beantwortet {
                GelberKnopf(titel: "Prüfen") { pruefeTipp(s) }
                    .padding(.horizontal, -24)
            }
        }
        .padding(.horizontal, 20)
    }

    private func rueckmeldung(_ f: Frage, _ s: SprachSitzung) -> some View {
        let ok = s.ergebnisse[s.index] == .richtig
        let fast = (f.typ == .tipp && s.tippErgebnis == .fast)
        let titel = fast ? "Richtig! Achte auf die Sonderzeichen:" : (ok ? "Richtig!" : "Das war:")
        let farbe: Color = fast ? Theme.gelb : (ok ? Theme.mint : Theme.koralle)
        let fremd = f.wort.texte[sprache] ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            Text(titel)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(farbe)
            HStack(spacing: 10) {
                lautsprecher(fremd, groesse: 40)
                Text(fremd)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
            }
            Text("\(SprachHelfer.bild(f.wort)) \(f.wort.texte["de"] ?? "")")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
            if let h = f.wort.hinweis {
                Text(h)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.himmel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(farbe.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.horizontal, 20)
    }

    // MARK: Ergebnis

    private func ergebnis(_ s: SprachSitzung) -> some View {
        SprachErgebnisAnsicht(
            sprache: sprache,
            richtig: s.richtig,
            gesamt: s.fragen.count,
            fehler: s.fehler,
            teilenText: SprachErgebnis.teilenText(thema: s.thema, art: s.art, sprache: sprache,
                                                  richtig: s.richtig, gesamt: s.fragen.count, fehler: s.fehler),
            zeigeFehlerUeben: true,
            fehlerUeben: { neueSitzung(s.fehler, .quiz) },
            nochmal: { neueSitzung(woerter, s.art) },
            zurueck: { dismiss() }
        )
    }
}

struct SprachErgebnisAnsicht: View {
    let sprache: String
    let richtig: Int
    let gesamt: Int
    let fehler: [Wort]
    let teilenText: String
    let zeigeFehlerUeben: Bool
    let fehlerUeben: () -> Void
    let nochmal: () -> Void
    let zurueck: () -> Void

    private var sterne: Int { sterneFuer(gut: richtig, gesamt: gesamt) }

    private var lob: String {
        switch sterne {
        case 3: return "Fantastisch!"
        case 2: return "Schon richtig gut!"
        case 1: return "Das wird. Noch eine Runde?"
        default: return "Kein Problem. Üben macht den Meister."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < sterne ? "star.fill" : "star")
                            .font(.system(size: 58))
                            .foregroundStyle(i < sterne ? Theme.gelb : Color.white.opacity(0.25))
                            .symbolEffect(.bounce, value: sterne)
                    }
                }
                Text("\(richtig) von \(gesamt)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(lob)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)

                if !fehler.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Das üben wir noch:")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        ForEach(fehler) { w in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.texte[sprache] ?? "")
                                        .font(.system(.body, design: .rounded).weight(.bold))
                                        .foregroundStyle(Color.white)
                                    Text("\(SprachHelfer.bild(w)) \(w.texte["de"] ?? "")")
                                        .font(.footnote)
                                        .foregroundStyle(Theme.textSanft)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 26)
                    .padding(.horizontal, 20)
                }

                if zeigeFehlerUeben && !fehler.isEmpty {
                    GelberKnopf(titel: "🔁 Fehler üben", aktion: fehlerUeben)
                }
                Button(action: nochmal) {
                    Text("Nochmal")
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.gelb)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .background(Theme.gelb.opacity(0.15), in: Capsule())
                }
                .buttonStyle(TastenStil())
                .padding(.horizontal, 24)

                ShareLink(item: teilenText) {
                    Label("Ergebnis teilen", systemImage: "square.and.arrow.up")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                }
                Button("Zurück zum Thema", action: zurueck)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSanft)
            }
            .padding(.top, 30)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: Sprachen: Paare finden

struct SprachPaareView: View {
    let thema: Thema
    let sprache: String
    let woerter: [Wort]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("modus") private var modus = ""
    @State private var links: [Wort] = []
    @State private var rechts: [Wort] = []
    @State private var gl: Int? = nil
    @State private var gr: Int? = nil
    @State private var geloest: Set<String> = []
    @State private var fehl: [String: Int] = [:]
    @State private var sperre = false
    @State private var flashL: Int? = nil
    @State private var flashR: Int? = nil
    @State private var fertig = false
    @State private var richtigAnzahl = 0
    @State private var fehlerWoerter: [Wort] = []
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var info: SprachInfo { store.sprache(sprache) }

    var body: some View {
        ZStack {
            HintergrundView()
            if fertig {
                SprachErgebnisAnsicht(
                    sprache: sprache,
                    richtig: richtigAnzahl,
                    gesamt: links.count,
                    fehler: fehlerWoerter,
                    teilenText: SprachErgebnis.teilenText(thema: thema, art: .paare, sprache: sprache,
                                                          richtig: richtigAnzahl, gesamt: links.count, fehler: fehlerWoerter),
                    zeigeFehlerUeben: false,
                    fehlerUeben: {},
                    nochmal: { starte() },
                    zurueck: { dismiss() }
                )
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        HStack {
                            Text("\(geloest.count) von \(links.count) gefunden")
                            Spacer()
                        }
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textSanft)

                        HStack(alignment: .top, spacing: 10) {
                            VStack(spacing: 10) {
                                ForEach(Array(links.enumerated()), id: \.offset) { i, w in
                                    paarKnopf(text: w.texte[sprache] ?? "", wort: w,
                                              gewaehlt: gl == i, fehler: flashL == i) {
                                        waehleLinks(i)
                                    }
                                }
                            }
                            VStack(spacing: 10) {
                                ForEach(Array(rechts.enumerated()), id: \.offset) { i, w in
                                    paarKnopf(text: "\(SprachHelfer.bild(w)) \(w.texte["de"] ?? "")", wort: w,
                                              gewaehlt: gr == i, fehler: flashR == i) {
                                        waehleRechts(i)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Paare: \(thema.titel)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if links.isEmpty { starte() } }
    }

    private func paarKnopf(text: String, wort: Wort, gewaehlt: Bool, fehler: Bool,
                           aktion: @escaping () -> Void) -> some View {
        let gefunden = geloest.contains(wort.id)
        var hintergrund = Color.white.opacity(0.10)
        var schrift = Color.white
        var rand = Color.white.opacity(0.14)
        if gefunden {
            hintergrund = Theme.mint.opacity(0.20)
            schrift = Theme.mint
            rand = Theme.mint
        } else if fehler {
            hintergrund = Theme.koralle.opacity(0.25)
            rand = Theme.koralle
        } else if gewaehlt {
            hintergrund = Theme.gelb.opacity(0.18)
            rand = Theme.gelb
        }
        return Button(action: aktion) {
            Text(text)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(schrift)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 62)
                .padding(.horizontal, 6)
                .background(hintergrund, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(rand, lineWidth: 1.5)
                )
        }
        .buttonStyle(TastenStil())
        .disabled(gefunden)
    }

    private func starte() {
        var gesehen = Set<String>()
        var auswahl: [Wort] = []
        for w in SprachGenerator.nachStand(woerter, sprache) {
            if auswahl.count >= 6 { break }
            let a = "f" + SprachHelfer.norm(w.texte[sprache] ?? "", sprache)
            let b = "d" + (w.texte["de"] ?? "").lowercased()
            if gesehen.contains(a) || gesehen.contains(b) { continue }
            gesehen.insert(a)
            gesehen.insert(b)
            auswahl.append(w)
        }
        links = auswahl
        rechts = auswahl.shuffled()
        gl = nil
        gr = nil
        geloest = []
        fehl = [:]
        sperre = false
        flashL = nil
        flashR = nil
        fertig = false
    }

    private func waehleLinks(_ i: Int) {
        guard !sperre, links.indices.contains(i) else { return }
        gl = i
        Sprecher.shared.sprich(links[i].texte[sprache] ?? "", code: info.sprachcode)
        pruefe()
    }

    private func waehleRechts(_ i: Int) {
        guard !sperre, rechts.indices.contains(i) else { return }
        gr = i
        pruefe()
    }

    private func pruefe() {
        guard let l = gl, let r = gr else { return }
        let wl = links[l]
        let wr = rechts[r]
        if wl.id == wr.id {
            geloest.insert(wl.id)
            gl = nil
            gr = nil
            Haptik.leicht()
            if geloest.count == links.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { beende() }
            }
        } else {
            fehl[wl.id, default: 0] += 1
            flashL = l
            flashR = r
            sperre = true
            Haptik.fehler()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                flashL = nil
                flashR = nil
                gl = nil
                gr = nil
                sperre = false
            }
        }
    }

    private func beende() {
        var richtig = 0
        var fehler: [Wort] = []
        for w in links {
            let ok = (fehl[w.id] ?? 0) == 0
            stand.bewerte(w, sprache, richtig: ok)
            if ok { richtig += 1 } else { fehler.append(w) }
        }
        richtigAnzahl = richtig
        fehlerWoerter = fehler
        fertig = true
        SprachErgebnis.speichere(thema: thema, art: .paare, sprache: sprache,
                                 richtig: richtig, gesamt: links.count,
                                 context: context, istKind: modus == "kind")
    }
}

// MARK: Sprachen: Bericht

struct SchwierigesWort: Identifiable {
    let wort: Wort
    let fehler: Int
    var id: String { wort.id }
}

struct SprachBerichtView: View {
    @State private var c = "en"
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var info: SprachInfo { store.sprache(c) }
    private var woerter: [Wort] { store.alleWoerter(c) }
    private var gelernt: Int { woerter.filter { stand.gelernt($0, c) }.count }

    private var schwierigste: [SchwierigesWort] {
        var liste: [SchwierigesWort] = []
        for w in woerter {
            let f = stand.eintrag(w, c).f
            if f > 0 { liste.append(SchwierigesWort(wort: w, fehler: f)) }
        }
        return Array(liste.sorted { $0.fehler > $1.fehler }.prefix(8))
    }

    private var letzte: [VerlaufEintrag] {
        Array(stand.verlauf.filter { $0.sp == c }.suffix(8).reversed())
    }

    private var berichtText: String { Nachricht.berichtSprache(c) }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    chips
                    uebersicht
                    themenKarte
                    schwerKarte
                    verlaufKarte
                    ShareLink(item: berichtText) {
                        Label("Bericht teilen", systemImage: "square.and.arrow.up")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.navy)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.gelb, in: Capsule())
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Bericht")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let erste = store.katalog.lernsprachen.first, !store.katalog.lernsprachen.contains(c) { c = erste }
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(store.katalog.lernsprachen, id: \.self) { code in
                let aktiv = (code == c)
                Button { c = code } label: {
                    Text("\(store.sprache(code).flagge) \(store.sprache(code).name)")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(aktiv ? Theme.navy : Color.white)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }

    private var uebersicht: some View {
        VStack(spacing: 4) {
            Text("\(gelernt) von \(woerter.count)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
            Text("Wörter gelernt (\(info.flagge) \(info.name))")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .glasKarte(radius: 26)
    }

    private var themenKarte: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Themen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            ForEach(store.katalog.themen.filter { $0.woerter.contains(where: { $0.texte[c] != nil }) }) { t in
                let ws = t.woerter.filter { $0.texte[c] != nil }
                let g = ws.filter { stand.gelernt($0, c) }.count
                let anteil = ws.isEmpty ? 0 : Double(g) / Double(ws.count)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("\(t.emoji) \(t.titel)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Text("\(g)/\(ws.count)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textSanft)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.14))
                            Capsule().fill(Theme.gelb).frame(width: geo.size.width * anteil)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var schwerKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schwierigste Wörter")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if schwierigste.isEmpty {
                Text("Noch keine Fehler.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                ForEach(schwierigste) { eintrag in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(eintrag.wort.texte[c] ?? "")
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.white)
                            Text(eintrag.wort.texte["de"] ?? "")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        Spacer()
                        Text("\(eintrag.fehler)× falsch")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.koralle)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var verlaufKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Letzte Runden")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if letzte.isEmpty {
                Text("Noch nichts geübt.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSanft)
            } else {
                ForEach(letzte) { x in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(x.thema)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Color.white)
                            Text(x.ts.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(Theme.textSanft)
                        }
                        Spacer()
                        Text("\(x.richtig) von \(x.gesamt)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}

// MARK: Sprachen: Einstellungen (weitere Themen laden, Lernstand löschen)

struct SprachEinstellungenView: View {
    @State private var text = ""
    @State private var meldung: String? = nil
    @State private var zeigeDatei = false
    @State private var zeigeReset = false
    @AppStorage("modus") private var modus = ""
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if modus == "eltern" {
                        NavigationLink {
                            SprachEditorListeView()
                        } label: {
                            HStack(spacing: 14) {
                                Text("✏️").font(.system(size: 28))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Themen bearbeiten")
                                        .font(.system(.title3, design: .rounded).weight(.heavy))
                                        .foregroundStyle(Color.white)
                                    Text("Eigene Themen anlegen, Wörter korrigieren")
                                        .font(.footnote)
                                        .foregroundStyle(Theme.textSanft)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Theme.gelb)
                            }
                            .padding(16)
                            .glasKarte(radius: 26)
                        }
                        .buttonStyle(TastenStil())
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Weitere Themen laden")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text("Füge ein JSON mit neuen Themen ein oder wähle eine Datei. Themen mit gleicher ID werden ersetzt.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        TextEditor(text: $text)
                            .font(.system(.footnote, design: .monospaced))
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 140)
                            .padding(10)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        if let meldung {
                            Text(meldung)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.himmel)
                        }
                        GelberKnopf(titel: "Importieren") { importiere(text) }
                            .padding(.horizontal, -24)
                        Button("Datei wählen") { zeigeDatei = true }
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.gelb)
                    }
                    .padding(16)
                    .glasKarte(radius: 26)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Zurücksetzen")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text("Löscht den Lernstand der Sprachen auf diesem Gerät und die zusätzlich geladenen Themen. Mathe bleibt unberührt.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        Button("Lernstand löschen", role: .destructive) { zeigeReset = true }
                            .font(.system(.headline, design: .rounded))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 26)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $zeigeDatei, allowedContentTypes: [.json, .plainText]) { ergebnis in
            switch ergebnis {
            case .success(let url):
                let zugriff = url.startAccessingSecurityScopedResource()
                defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
                if let d = try? Data(contentsOf: url), let t = String(data: d, encoding: .utf8) {
                    importiere(t)
                } else {
                    meldung = "Die Datei konnte nicht gelesen werden."
                }
            case .failure(let e):
                meldung = e.localizedDescription
            }
        }
        .confirmationDialog("Lernstand wirklich löschen?", isPresented: $zeigeReset, titleVisibility: .visible) {
            Button("Löschen", role: .destructive) {
                stand.zuruecksetzen()
                store.extraZuruecksetzen()
                meldung = "Zurückgesetzt."
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func importiere(_ t: String) {
        if let n = store.importiere(t) {
            meldung = "\(n) Thema/Themen geladen."
            text = ""
        } else {
            meldung = "Das Format passt nicht. Erwartet wird ein JSON mit einer Liste „themen“."
        }
    }
}


// ============================================================
// MARK: - Editor (Mathe und Vokabeln) und Eltern-Joker
// ============================================================

// MARK: Teilen-Fenster (mit Rückmeldung, ob geteilt wurde)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onFertig: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in onFertig?() }
        return vc
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

// MARK: - Mathe: Entwurfsmodell (wird als JSON gespeichert und geteilt)

struct MatheAufgabe: Codable, Identifiable, Equatable {
    var id = UUID()
    var art = "zahl"
    var frage = ""
    var rechnung = ""
    var hinweis = ""
    var antwort = ""
    var antwort2 = ""
    var erklaerung = ""
    var reihen: [[Int]] = []

    func dict() -> [String: Any] {
        var d: [String: Any] = ["art": art, "frage": frage]
        if art == "mauer" {
            d["reihen"] = reihen
            return d
        }
        d["rechnung"] = rechnung
        if !hinweis.isEmpty { d["hinweis"] = hinweis }
        d["antwort"] = antwort
        if art == "rest" { d["antwort2"] = antwort2 }
        if !erklaerung.isEmpty { d["erklaerung"] = erklaerung }
        return d
    }

    var kurz: String {
        switch art {
        case "mauer":
            return "Mauer: " + (reihen.first ?? []).map { String($0) }.joined(separator: " ")
        case "rest":
            return "\(rechnung) \(antwort) Rest \(antwort2)"
        case "vergleich":
            return rechnung.replacingOccurrences(of: "  ?  ", with: " ? ") + " → " + antwort
        default:
            return rechnung.replacingOccurrences(of: "\n", with: " ") + " → " + antwort
        }
    }
}

struct MatheUebung: Codable, Identifiable, Equatable {
    var id = UUID()
    var titel: String = ""
    var gruppe: String = "Knobeln"
    var symbol: String = "✎"
    var tipp: String = ""
    var vorlage: String = ""
    var aufgaben: [MatheAufgabe] = []

    func dict() -> [String: Any] {
        var d: [String: Any] = ["titel": titel, "gruppe": gruppe, "symbol": symbol,
                                "aufgaben": aufgaben.map { $0.dict() }]
        if !tipp.isEmpty { d["tipp"] = tipp }
        return d
    }
}

struct MatheArbeit: Codable, Equatable {
    var klasse = "Klasse 3"
    var fach = "Mathe"
    var titel = ""
    var uebungen: [MatheUebung] = []

    func jsonText() -> String {
        let d: [String: Any] = ["klasse": klasse, "fach": fach, "arbeit": titel,
                                "uebungen": uebungen.map { $0.dict() }]
        guard let data = try? JSONSerialization.data(withJSONObject: d,
                                                     options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }
}

enum MatheEntwurf {
    private static let key = "matheEntwurfV1"

    static func lade() -> MatheArbeit {
        if let d = UserDefaults.standard.data(forKey: key),
           let a = try? JSONDecoder().decode(MatheArbeit.self, from: d) { return a }
        return MatheArbeit()
    }

    static func sichere(_ a: MatheArbeit) {
        if let d = try? JSONEncoder().encode(a) { UserDefaults.standard.set(d, forKey: key) }
    }

    static func loesche() { UserDefaults.standard.removeObject(forKey: key) }
}

// MARK: - Mathe: Rechner (exakt, ganze Zahlen)

enum MatheRechner {
    struct Fehler: Error { let text: String }

    enum Zeichen {
        case zahl(Int)
        case op(Character)
        case auf
        case zu
    }

    static func zerlege(_ roh: String) throws -> [Zeichen] {
        var t: [Zeichen] = []
        var zahl = ""
        func abschluss() throws {
            if zahl.isEmpty { return }
            guard let n = Int(zahl), n <= 1_000_000 else { throw Fehler(text: "Eine Zahl ist zu groß.") }
            t.append(.zahl(n))
            zahl = ""
        }
        for ch in roh {
            if ch.isASCII && ch.isNumber {
                zahl.append(ch)
                continue
            }
            try abschluss()
            switch ch {
            case " ", "=", "\n":
                continue
            case "+":
                t.append(.op("+"))
            case "-", "\u{2212}", "\u{2013}", "\u{2014}":
                t.append(.op("-"))
            case "·", "*", "×", "x", "X", "•":
                t.append(.op("*"))
            case ":", "/", "÷":
                t.append(.op("/"))
            case "(":
                t.append(.auf)
            case ")":
                t.append(.zu)
            default:
                throw Fehler(text: "Das Zeichen „\(ch)“ kennt der Rechner nicht.")
            }
        }
        try abschluss()
        return t
    }

    struct Parser {
        let tokens: [Zeichen]
        var i = 0

        mutating func ausdruck() throws -> Int {
            var w = try term()
            while i < tokens.count, case .op(let o) = tokens[i], o == "+" || o == "-" {
                i += 1
                let r = try term()
                w = (o == "+") ? w + r : w - r
            }
            return w
        }

        mutating func term() throws -> Int {
            var w = try faktor()
            while i < tokens.count, case .op(let o) = tokens[i], o == "*" || o == "/" {
                i += 1
                let r = try faktor()
                if o == "*" {
                    let (p, ueberlauf) = w.multipliedReportingOverflow(by: r)
                    if ueberlauf || abs(p) > 1_000_000_000 { throw Fehler(text: "Die Zahlen werden zu groß.") }
                    w = p
                } else {
                    if r == 0 { throw Fehler(text: "Durch null teilen geht nicht.") }
                    if w % r != 0 { throw Fehler(text: "\(w) : \(r) geht nicht auf.") }
                    w = w / r
                }
            }
            return w
        }

        mutating func faktor() throws -> Int {
            guard i < tokens.count else { throw Fehler(text: "Die Rechnung ist unvollständig.") }
            switch tokens[i] {
            case .zahl(let n):
                i += 1
                return n
            case .auf:
                i += 1
                let w = try ausdruck()
                guard i < tokens.count, case .zu = tokens[i] else { throw Fehler(text: "Eine Klammer fehlt.") }
                i += 1
                return w
            default:
                throw Fehler(text: "Hier fehlt eine Zahl.")
            }
        }
    }

    static func werte(_ roh: String) throws -> Int {
        let t = try zerlege(roh)
        if t.isEmpty { throw Fehler(text: "Bitte eine Rechnung eingeben.") }
        var p = Parser(tokens: t)
        let w = try p.ausdruck()
        if p.i != t.count { throw Fehler(text: "Die Rechnung ist nicht ganz verständlich.") }
        return w
    }

    // Schöne Schreibweise: Operatoren mit Leerzeichen, Mal als Punkt
    static func anzeige(_ roh: String) -> String {
        guard let t = try? zerlege(roh) else { return roh }
        var s = ""
        for z in t {
            switch z {
            case .zahl(let n): s += String(n)
            case .auf: s += "("
            case .zu: s += ")"
            case .op(let o):
                switch o {
                case "+": s += " + "
                case "-": s += " - "
                case "*": s += " · "
                default: s += " : "
                }
            }
        }
        return s
    }
}

// MARK: - Mathe: Generatoren (Portierung der 13 Übungsarten aus dem Rechenheft)

struct MatheVorlage {
    let id: String
    let name: String
    let symbol: String
    let gruppe: String
    let anzahl: Int
    let tipp: String
    let mach: @MainActor () -> MatheAufgabe
}

enum MatheGenerator {
    static let namen = ["Jule", "Ali", "Mia", "Tom", "Lena", "Ben", "Sara", "Emil", "Nele", "Jonas", "Ida", "Luis"]

    static func z(_ a: Int, _ b: Int) -> Int { Int.random(in: min(a, b)...max(a, b)) }
    static func wahr(_ p: Double) -> Bool { Double.random(in: 0..<1) < p }

    static func zahlwort(_ k: Int) -> String {
        let liste = ["", "Einer", "Zweier", "Dreier", "Vierer", "Fünfer", "Sechser", "Siebener", "Achter", "Neuner", "Zehner"]
        return liste.indices.contains(k) ? liste[k] : ""
    }

    static func minusWort() -> MatheAufgabe {
        let art = z(1, 3)
        var a = 0
        var b = 0
        if art == 1 {
            a = z(31, 99); b = z(3, 9)
        } else if art == 2 {
            a = z(41, 99); b = z(11, 39)
        } else {
            a = z(50, 99); b = z(10, 50)
            b = b - (b % 10)
            if b < 10 { b = 10 }
        }
        let text = Bool.random() ? "Subtrahiere von \(a) die Zahl \(b)." : "Wie heißt die Differenz der Zahlen \(a) und \(b)?"
        return MatheAufgabe(art: "zahl", frage: "Notiere die passende Rechnung.", rechnung: text,
                            antwort: String(a - b), erklaerung: "\(a) - \(b) = \(a - b)")
    }

    static func malWort() -> MatheAufgabe {
        let a = z(2, 10)
        let b = z(2, 10)
        let text = Bool.random() ? "Multipliziere die Zahlen \(a) und \(b)." : "Wie heißt das Produkt der Zahlen \(a) und \(b)?"
        if wahr(0.18) {
            let c = [2, 5, 10].randomElement() ?? 2
            let d = [2, 5].randomElement() ?? 2
            let e = 10
            return MatheAufgabe(art: "zahl", frage: "Notiere die passende Rechnung.",
                                rechnung: "Wie heißt das Produkt der Zahlen \(d), \(c) und \(e)?",
                                antwort: String(d * c * e), erklaerung: "\(d) · \(c) · \(e) = \(d * c * e)")
        }
        return MatheAufgabe(art: "zahl", frage: "Notiere die passende Rechnung.", rechnung: text,
                            antwort: String(a * b), erklaerung: "\(a) · \(b) = \(a * b)")
    }

    static func kern() -> MatheAufgabe {
        let k = [1, 2, 5, 10].randomElement() ?? 1
        let n = z(2, 10)
        return MatheAufgabe(art: "zahl", frage: "Das ist eine Kernaufgabe.", rechnung: "\(k) · \(n) =",
                            antwort: String(k * n))
    }

    static func nachbar() -> MatheAufgabe {
        let k = [2, 5, 10].randomElement() ?? 2
        let n = z(3, 10)
        let nachbarZahl = (k == 10) ? 9 : k + 1
        let zeichen = (k == 10) ? "-" : "+"
        return MatheAufgabe(art: "zahl", frage: "Erst die Kernaufgabe, dann der Nachbar.",
                            rechnung: "\(nachbarZahl) · \(n) =",
                            hinweis: "Du weißt: \(k) · \(n) = \(k * n). Also \(zeichen) \(n).",
                            antwort: String(nachbarZahl * n),
                            erklaerung: "\(k) · \(n) = \(k * n), dann \(zeichen) \(n) = \(nachbarZahl * n)")
    }

    static func einmaleins() -> MatheAufgabe {
        let a = z(2, 10)
        let b = z(2, 10)
        return MatheAufgabe(art: "zahl", frage: "Rechne.", rechnung: "\(a) · \(b) =", antwort: String(a * b))
    }

    static func umkehr() -> MatheAufgabe {
        let b = z(2, 10)
        let q = z(2, 10)
        let a = b * q
        return MatheAufgabe(art: "zahl", frage: "Rechne und denk an die Umkehraufgabe.", rechnung: "\(a) : \(b) =",
                            hinweis: "Denn ___ · \(b) = \(a)", antwort: String(q),
                            erklaerung: "\(a) : \(b) = \(q), denn \(q) · \(b) = \(a)")
    }

    static func rest() -> MatheAufgabe {
        var a = 0
        var b = 0
        if wahr(0.45) {
            b = z(3, 9)
            let q = z(10, 16)
            a = b * q + z(0, b - 1)
            if a > 100 { a = 100 }
        } else {
            b = z(2, 9)
            a = z(b + 1, 60)
        }
        let q = a / b
        let r = a % b
        return MatheAufgabe(art: "rest", frage: "Teile mit Rest. Rechne bis zum Ende.", rechnung: "\(a) : \(b) =",
                            antwort: String(q), antwort2: String(r),
                            erklaerung: "\(a) : \(b) = \(q)" + (r > 0 ? " R \(r)" : " (kein Rest)"))
    }

    static func punkt() -> MatheAufgabe {
        let f = z(1, 6)
        var text = ""
        var erg = 0
        if f == 1 {
            let b = z(2, 9), c = z(2, 9), a = z(2, 20)
            text = "\(a) + \(b) · \(c)"; erg = a + b * c
        } else if f == 2 {
            let b = z(2, 9), c = z(2, 9), a = z(2, 20)
            text = "\(b) · \(c) + \(a)"; erg = b * c + a
        } else if f == 3 {
            let b = z(2, 9), c = z(2, 9)
            let a = z(b * c, b * c + 40)
            text = "\(a) - \(b) · \(c)"; erg = a - b * c
        } else if f == 4 {
            let c = z(2, 9), q = z(2, 9)
            let b = c * q
            let a = z(5, 60)
            text = "\(a) + \(b) : \(c)"; erg = a + q
        } else if f == 5 {
            let c = z(2, 9), q = z(2, 9)
            let b = c * q
            let a = z(5, 60)
            text = "\(b) : \(c) + \(a)"; erg = q + a
        } else {
            let c = z(2, 9), q = z(2, 9)
            let b = c * q
            let a = z(q, 60)
            text = "\(a) - \(b) : \(c)"; erg = a - q
        }
        return MatheAufgabe(art: "zahl", frage: "Punkt vor Strich.", rechnung: text + " =", antwort: String(erg),
                            erklaerung: "Zuerst die Punktrechnung, dann plus oder minus.")
    }

    static func vergleich() -> MatheAufgabe {
        let links: String
        let rechts: String
        let lw: Int
        let rw: Int
        if wahr(0.3) {
            let a = z(2, 10), b = z(2, 10)
            links = "\(a) · \(b)"
            lw = a * b
            var r = [lw, lw + z(1, 12), lw - z(1, 12)].randomElement() ?? lw
            if r < 0 { r = lw + 5 }
            rw = r
            rechts = String(r)
        } else {
            let a1 = z(2, 10), b1 = z(2, 10)
            var a2 = z(2, 10)
            var b2 = z(2, 10)
            if wahr(0.25) { a2 = b1; b2 = a1 }
            links = "\(a1) · \(b1)"
            rechts = "\(a2) · \(b2)"
            lw = a1 * b1
            rw = a2 * b2
        }
        let zeichen = lw > rw ? ">" : (lw < rw ? "<" : "=")
        return MatheAufgabe(art: "vergleich", frage: "Was gehört in die Mitte?", rechnung: "\(links)  ?  \(rechts)",
                            antwort: zeichen, erklaerung: "\(lw) \(zeichen) \(rw)")
    }

    static func raetsel() -> MatheAufgabe {
        for _ in 0..<400 {
            let gerade = Bool.random()
            let k = z(3, 9)
            let start = z(20, 70)
            let ende = start + z(15, 28)
            var treffer: [Int] = []
            for n in (start + 1)..<ende {
                if n % k != 0 { continue }
                if gerade && n % 2 != 0 { continue }
                if !gerade && n % 2 != 1 { continue }
                treffer.append(n)
            }
            if treffer.count == 1 {
                let paritaet = gerade ? "gerade" : "ungerade"
                let text = "Meine Zahl ist \(paritaet).\nSie ist eine \(zahlwort(k))zahl.\nSie liegt zwischen \(start) und \(ende)."
                return MatheAufgabe(art: "zahl", frage: "Wie heißt die Zahl?", rechnung: text, antwort: String(treffer[0]))
            }
        }
        return MatheAufgabe(art: "zahl", frage: "Wie heißt die Zahl?",
                            rechnung: "Meine Zahl ist ungerade.\nSie ist eine Neunerzahl.\nSie liegt zwischen 46 und 70.",
                            antwort: "63")
    }

    static func sach() -> MatheAufgabe {
        let n = namen.shuffled()
        let na = n[0]
        let nb = n[1]
        let frage = "Lies genau. Rechne und antworte."
        let f = z(1, 5)
        if f == 1 {
            let x = z(30, 80), d = z(8, 20)
            return MatheAufgabe(art: "zahl", frage: frage,
                                rechnung: "\(na) schwimmt \(x) m weit.\n\(nb) schafft \(d) m mehr als \(na).\nWie weit schwimmt \(nb)?",
                                antwort: String(x + d), erklaerung: "\(x) + \(d) = \(x + d)")
        }
        if f == 2 {
            let y = z(40, 95), e = z(8, 30)
            return MatheAufgabe(art: "zahl", frage: frage,
                                rechnung: "\(na) hat \(y) Sticker.\n\(nb) hat \(e) Sticker weniger.\nWie viele Sticker hat \(nb)?",
                                antwort: String(y - e), erklaerung: "\(y) - \(e) = \(y - e)")
        }
        if f == 3 {
            let k = z(3, 9), m = z(4, 10)
            return MatheAufgabe(art: "zahl", frage: frage,
                                rechnung: "In einer Kiste liegen \(m) Äpfel.\nEs gibt \(k) Kisten.\nWie viele Äpfel sind das?",
                                antwort: String(k * m), erklaerung: "\(k) · \(m) = \(k * m)")
        }
        if f == 4 {
            let kinder = z(3, 8), proKind = z(3, 9)
            let gesamt = kinder * proKind
            return MatheAufgabe(art: "zahl", frage: frage,
                                rechnung: "\(kinder) Kinder teilen \(gesamt) Bonbons gerecht auf.\nWie viele bekommt jedes Kind?",
                                antwort: String(proKind), erklaerung: "\(gesamt) : \(kinder) = \(proKind)")
        }
        let seiten = z(60, 100), gelesen = z(15, 55)
        return MatheAufgabe(art: "zahl", frage: frage,
                            rechnung: "Ein Buch hat \(seiten) Seiten.\n\(na) hat schon \(gelesen) Seiten gelesen.\nWie viele Seiten fehlen noch?",
                            antwort: String(seiten - gelesen), erklaerung: "\(seiten) - \(gelesen) = \(seiten - gelesen)")
    }

    static func mauer() -> MatheAufgabe {
        var reihen: [[Int]] = []
        var oben = 0
        repeat {
            let basis = [z(3, 15), z(3, 15), z(3, 15), z(3, 15)]
            reihen = [basis]
            while let letzte = reihen.last, letzte.count > 1 {
                var neu: [Int] = []
                for i in 0..<(letzte.count - 1) { neu.append(letzte[i] + letzte[i + 1]) }
                reihen.append(neu)
            }
            oben = reihen.last?.first ?? 0
        } while oben > 100
        return MatheAufgabe(art: "mauer", frage: "Fülle die Mauer von unten nach oben.", reihen: reihen)
    }

    static func gemischt() -> MatheAufgabe {
        let liste: [@MainActor () -> MatheAufgabe] = [
            { minusWort() },
            { malWort() },
            { einmaleins() },
            { nachbar() },
            { umkehr() },
            { rest() },
            { punkt() },
            { vergleich() },
            { raetsel() },
            { sach() }
        ]
        let f = liste.randomElement() ?? { einmaleins() }
        return f()
    }

    static let restTipp = "Bei geteilt nicht bei 10 stehen bleiben. 48 : 4 sind 12, nicht 10 Rest 8. Teile weiter, bis der Rest kleiner ist als die Zahl, durch die du teilst."

    static let vorlagen: [MatheVorlage] = [
        MatheVorlage(id: "minuswort", name: "Minus mit Wörtern", symbol: "-", gruppe: "Zum Aufwärmen", anzahl: 10, tipp: "", mach: { MatheGenerator.minusWort() }),
        MatheVorlage(id: "malwort", name: "Mal mit Wörtern", symbol: "·", gruppe: "Zum Aufwärmen", anzahl: 10, tipp: "", mach: { MatheGenerator.malWort() }),
        MatheVorlage(id: "kern", name: "Kernaufgaben", symbol: "1· 2· 5·", gruppe: "Mal und Geteilt", anzahl: 10, tipp: "", mach: { MatheGenerator.kern() }),
        MatheVorlage(id: "nachbar", name: "Nachbaraufgaben", symbol: "+1", gruppe: "Mal und Geteilt", anzahl: 10, tipp: "", mach: { MatheGenerator.nachbar() }),
        MatheVorlage(id: "einmaleins", name: "Einmaleins", symbol: "7·8", gruppe: "Mal und Geteilt", anzahl: 12, tipp: "", mach: { MatheGenerator.einmaleins() }),
        MatheVorlage(id: "umkehr", name: "Geteilt", symbol: ":", gruppe: "Mal und Geteilt", anzahl: 10, tipp: "", mach: { MatheGenerator.umkehr() }),
        MatheVorlage(id: "rest", name: "Teilen mit Rest", symbol: "R", gruppe: "Mal und Geteilt", anzahl: 10, tipp: MatheGenerator.restTipp, mach: { MatheGenerator.rest() }),
        MatheVorlage(id: "punkt", name: "Punkt vor Strich", symbol: "·+", gruppe: "Knobeln", anzahl: 10, tipp: "", mach: { MatheGenerator.punkt() }),
        MatheVorlage(id: "vergleich", name: "Größer oder kleiner", symbol: "< >", gruppe: "Knobeln", anzahl: 10, tipp: "", mach: { MatheGenerator.vergleich() }),
        MatheVorlage(id: "mauer", name: "Zahlenmauern", symbol: "▲", gruppe: "Knobeln", anzahl: 4, tipp: "", mach: { MatheGenerator.mauer() }),
        MatheVorlage(id: "raetsel", name: "Zahlenrätsel", symbol: "?", gruppe: "Knobeln", anzahl: 8, tipp: "", mach: { MatheGenerator.raetsel() }),
        MatheVorlage(id: "sach", name: "Sachaufgaben", symbol: "✎", gruppe: "Knobeln", anzahl: 8, tipp: "", mach: { MatheGenerator.sach() }),
        MatheVorlage(id: "gemischt", name: "Alles gemischt", symbol: "★", gruppe: "Wie in der Klassenarbeit", anzahl: 12, tipp: "", mach: { MatheGenerator.gemischt() })
    ]

    static func schluessel(_ a: MatheAufgabe) -> String {
        if a.art == "mauer" {
            return "M" + a.reihen.map { $0.map { String($0) }.joined(separator: ",") }.joined(separator: "|")
        }
        return a.rechnung
    }

    // Erzeugt neue Aufgaben, die in "ausschluss" noch nicht vorkommen
    static func fuelle(_ v: MatheVorlage, anzahl: Int, ausschluss: inout Set<String>) -> [MatheAufgabe] {
        var liste: [MatheAufgabe] = []
        var versuche = 0
        while liste.count < anzahl && versuche < 5000 {
            versuche += 1
            let t = v.mach()
            let k = schluessel(t)
            if ausschluss.contains(k) { continue }
            if v.id == "rest" {
                let zwei = liste.filter { (Int($0.antwort) ?? 0) >= 10 }.count
                let ein = liste.count - zwei
                let istZwei = (Int(t.antwort) ?? 0) >= 10
                if istZwei {
                    if zwei >= (anzahl + 1) / 2 { continue }
                } else {
                    if ein >= anzahl / 2 { continue }
                }
            }
            ausschluss.insert(k)
            liste.append(t)
        }
        return liste
    }

    static func uebung(_ v: MatheVorlage, ausschluss: inout Set<String>) -> MatheUebung {
        MatheUebung(titel: v.name, gruppe: v.gruppe, symbol: v.symbol, tipp: v.tipp, vorlage: v.id,
                    aufgaben: fuelle(v, anzahl: v.anzahl, ausschluss: &ausschluss))
    }

    static func neueArbeit(titel: String, klasse: String, fach: String, ausschluss: Set<String>) -> MatheArbeit {
        var sperre = ausschluss
        var arbeit = MatheArbeit(klasse: klasse, fach: fach, titel: titel, uebungen: [])
        for v in vorlagen { arbeit.uebungen.append(uebung(v, ausschluss: &sperre)) }
        return arbeit
    }
}

// Aufgaben-Schlüssel aus vorhandenen Klassenarbeiten, damit nichts doppelt vorkommt
func vorhandeneSchluessel(_ arbeiten: [Klassenarbeit]) -> Set<String> {
    var s = Set<String>()
    for a in arbeiten {
        for u in a.uebungen {
            for t in u.aufgaben {
                if t.art == "mauer" {
                    s.insert("M" + t.reihen.map { $0.map { String($0) }.joined(separator: ",") }.joined(separator: "|"))
                } else {
                    s.insert(t.rechnung)
                }
            }
        }
    }
    return s
}

// Entwurf in die Datenbank dieses Geräts schreiben. Gibt eine Fehlermeldung zurück oder nil.
func legeMatheArbeitAn(_ arbeit: MatheArbeit, context: ModelContext, vorhandene: [Klassenarbeit]) -> String? {
    if vorhandene.contains(where: { $0.klasse == arbeit.klasse && $0.fach == arbeit.fach && $0.titel == arbeit.titel }) {
        return "\(arbeit.titel) gibt es auf diesem Gerät schon. Wähle einen anderen Titel oder lösche die alte Arbeit."
    }
    let neu = Klassenarbeit(klasse: arbeit.klasse, fach: arbeit.fach, titel: arbeit.titel)
    context.insert(neu)
    for (i, u) in arbeit.uebungen.enumerated() {
        let ue = Uebung(titel: u.titel, gruppe: u.gruppe, symbol: u.symbol, tipp: u.tipp, reihenfolge: i)
        context.insert(ue)
        ue.arbeit = neu
        for (j, t) in u.aufgaben.enumerated() {
            let reihenJSON = (try? JSONEncoder().encode(t.reihen)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let au = Aufgabe(art: t.art, frage: t.frage, rechnung: t.rechnung, hinweis: t.hinweis,
                             erklaerung: t.erklaerung, antwort: t.antwort, antwort2: t.antwort2,
                             reihenJSON: t.art == "mauer" ? reihenJSON : "", reihenfolge: j)
            context.insert(au)
            au.uebung = ue
        }
    }
    return nil
}

// MARK: - Mathe-Editor: Hauptansicht

struct MatheEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var vorhandene: [Klassenarbeit]
    @State private var arbeit = MatheEntwurf.lade()
    @State private var meldung: String? = nil
    @State private var zeigeVerwerfen = false
    @State private var zeigeVollErsetzen = false

    private var feld: Color { Color.white.opacity(0.08) }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Kopf") {
                    TextField("Klasse", text: $arbeit.klasse)
                    TextField("Fach", text: $arbeit.fach)
                    TextField("Titel, zum Beispiel Übungsset Nr. 2", text: $arbeit.titel)
                }
                .listRowBackground(feld)

                Section {
                    Button {
                        if arbeit.uebungen.isEmpty { vollErzeugen() } else { zeigeVollErsetzen = true }
                    } label: {
                        Label("Komplette Arbeit erzeugen (13 Übungen)", systemImage: "wand.and.stars")
                    }
                    Menu {
                        ForEach(MatheGenerator.vorlagen, id: \.id) { v in
                            Button("\(v.name) (\(v.anzahl))") { vorlageHinzufuegen(v) }
                        }
                    } label: {
                        Label("Einzelne Übung aus Vorlage", systemImage: "plus.square.on.square")
                    }
                    Button {
                        arbeit.uebungen.append(MatheUebung(titel: "Eigene Übung", gruppe: "Eigene Aufgaben", symbol: "✎"))
                    } label: {
                        Label("Leere eigene Übung", systemImage: "square.and.pencil")
                    }
                } header: {
                    Text("Schnellstart")
                } footer: {
                    Text("Die App berechnet alle Lösungen selbst. Neue Aufgaben wiederholen keine Aufgaben, die schon auf diesem Gerät sind.")
                }
                .listRowBackground(feld)

                Section("Übungen (\(arbeit.uebungen.count))") {
                    if arbeit.uebungen.isEmpty {
                        Text("Noch keine Übung. Erzeuge eine komplette Arbeit oder füge Übungen hinzu.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                    ForEach($arbeit.uebungen) { $u in
                        NavigationLink {
                            MatheUebungEditor(uebung: $u, uebrigeSchluessel: schluesselOhne(u.id))
                        } label: {
                            HStack(spacing: 12) {
                                Text(u.symbol)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Theme.navy)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .frame(width: 44, height: 34)
                                    .background(Theme.gelb, in: Capsule())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(u.titel.isEmpty ? "Ohne Titel" : u.titel)
                                        .font(.system(.body, design: .rounded).weight(.bold))
                                    Text("\(u.aufgaben.count) Aufgaben · \(u.gruppe)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSanft)
                                }
                            }
                        }
                    }
                    .onDelete { arbeit.uebungen.remove(atOffsets: $0) }
                    .onMove { arbeit.uebungen.move(fromOffsets: $0, toOffset: $1) }
                }
                .listRowBackground(feld)

                Section {
                    Button { pruefeUndSpeichere() } label: {
                        Label("Prüfen und auf diesem Gerät speichern", systemImage: "checkmark.seal.fill")
                    }
                    ShareLink(item: arbeit.jsonText()) {
                        Label("Als JSON teilen (für das Kind-Gerät)", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) { zeigeVerwerfen = true } label: {
                        Label("Entwurf verwerfen", systemImage: "trash")
                    }
                } header: {
                    Text("Fertig")
                } footer: {
                    Text("Auf dem Kind-Gerät fügst du das JSON mit Plus, Text einfügen ein.")
                }
                .listRowBackground(feld)
            }
            .scrollContentBackground(.hidden)
            .confirmationDialog("Alle Übungen ersetzen?", isPresented: $zeigeVollErsetzen, titleVisibility: .visible) {
                Button("Ersetzen", role: .destructive) { vollErzeugen() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Die vorhandenen Übungen im Entwurf werden durch 13 neue ersetzt.")
            }
        }
        .navigationTitle("Aufgaben-Editor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            ToolbarItem(placement: .primaryAction) { EditButton() }
        }
        .onChange(of: arbeit) { MatheEntwurf.sichere(arbeit) }
        .alert("Aufgaben-Editor", isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(meldung ?? "")
        }
        .confirmationDialog("Entwurf verwerfen?", isPresented: $zeigeVerwerfen, titleVisibility: .visible) {
            Button("Verwerfen", role: .destructive) {
                arbeit = MatheArbeit()
                MatheEntwurf.loesche()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    // MARK: Aktionen

    private func ausschlussMenge() -> Set<String> {
        var s = vorhandeneSchluessel(vorhandene)
        for u in arbeit.uebungen { for t in u.aufgaben { s.insert(MatheGenerator.schluessel(t)) } }
        return s
    }

    private func schluesselOhne(_ id: UUID) -> Set<String> {
        var s = vorhandeneSchluessel(vorhandene)
        for u in arbeit.uebungen where u.id != id {
            for t in u.aufgaben { s.insert(MatheGenerator.schluessel(t)) }
        }
        return s
    }

    private func vorschlagTitel() -> String {
        "Übungsset Nr. \(vorhandene.count + 1)"
    }

    private func vollErzeugen() {
        let titel = arbeit.titel.trimmingCharacters(in: .whitespaces).isEmpty ? vorschlagTitel() : arbeit.titel
        arbeit = MatheGenerator.neueArbeit(titel: titel, klasse: arbeit.klasse, fach: arbeit.fach,
                                           ausschluss: vorhandeneSchluessel(vorhandene))
    }

    private func vorlageHinzufuegen(_ v: MatheVorlage) {
        var s = ausschlussMenge()
        arbeit.uebungen.append(MatheGenerator.uebung(v, ausschluss: &s))
    }

    private func pruefeUndSpeichere() {
        var probleme: [String] = []
        if arbeit.titel.trimmingCharacters(in: .whitespaces).isEmpty { probleme.append("Der Titel fehlt.") }
        if arbeit.uebungen.isEmpty { probleme.append("Es gibt keine Übung.") }
        for u in arbeit.uebungen {
            if u.titel.trimmingCharacters(in: .whitespaces).isEmpty { probleme.append("Eine Übung hat keinen Titel.") }
            if u.aufgaben.isEmpty { probleme.append("Die Übung „\(u.titel)“ hat keine Aufgaben.") }
        }
        if !probleme.isEmpty {
            meldung = probleme.joined(separator: "\n")
            return
        }
        if let fehler = legeMatheArbeitAn(arbeit, context: context, vorhandene: vorhandene) {
            meldung = fehler
        } else {
            meldung = "Gespeichert. Du findest „\(arbeit.titel)“ jetzt in der Mathe-Liste dieses Geräts."
        }
    }
}

// MARK: - Mathe-Editor: eine Übung bearbeiten

struct NeueAufgabe: Identifiable {
    let id = UUID()
    let art: MatheAufgabenArt
}

struct MatheUebungEditor: View {
    @Binding var uebung: MatheUebung
    let uebrigeSchluessel: Set<String>
    @State private var neue: NeueAufgabe? = nil
    private var feld: Color { Color.white.opacity(0.08) }
    private let gruppen = ["Zum Aufwärmen", "Mal und Geteilt", "Knobeln", "Wie in der Klassenarbeit", "Eigene Aufgaben"]

    private var vorlage: MatheVorlage? {
        MatheGenerator.vorlagen.first { $0.id == uebung.vorlage }
    }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Übung") {
                    TextField("Titel", text: $uebung.titel)
                    Picker("Gruppe", selection: $uebung.gruppe) {
                        ForEach(gruppenListe, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Symbol, zum Beispiel 7·8", text: $uebung.symbol)
                    TextField("Tipp am Ende (optional)", text: $uebung.tipp, axis: .vertical)
                }
                .listRowBackground(feld)

                Section("Aufgaben (\(uebung.aufgaben.count))") {
                    if uebung.aufgaben.isEmpty {
                        Text("Noch keine Aufgabe.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                    ForEach(uebung.aufgaben) { a in
                        Text(a.kurz)
                            .font(.system(.body, design: .rounded))
                            .lineLimit(2)
                    }
                    .onDelete { uebung.aufgaben.remove(atOffsets: $0) }
                    .onMove { uebung.aufgaben.move(fromOffsets: $0, toOffset: $1) }
                }
                .listRowBackground(feld)

                Section {
                    Menu {
                        ForEach(MatheAufgabenArt.allCases) { art in
                            Button { neue = NeueAufgabe(art: art) } label: {
                                Label(art.titel, systemImage: art.symbol)
                            }
                        }
                    } label: {
                        Label("Eigene Aufgabe hinzufügen", systemImage: "plus.circle.fill")
                    }
                    if let v = vorlage {
                        Button { ergaenze(v, 5) } label: {
                            Label("Baukasten: 5 neue Aufgaben dazu", systemImage: "wand.and.stars")
                        }
                        Button { ergaenze(v, 10) } label: {
                            Label("Baukasten: 10 neue Aufgaben dazu", systemImage: "wand.and.stars")
                        }
                        Button(role: .destructive) { ersetze(v) } label: {
                            Label("Alle Aufgaben durch neue ersetzen", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                } header: {
                    Text("Hinzufügen")
                } footer: {
                    Text("Eine Aufgabe bearbeitest du, indem du sie löschst (nach links wischen) und neu anlegst.")
                }
                .listRowBackground(feld)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(uebung.titel.isEmpty ? "Übung" : uebung.titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { EditButton() } }
        .sheet(item: $neue) { n in
            MatheAufgabeFormular(art: n.art) { aufgabe in
                uebung.aufgaben.append(aufgabe)
            }
            .preferredColorScheme(.dark)
            .tint(Theme.gelb)
        }
    }

    private var gruppenListe: [String] {
        gruppen.contains(uebung.gruppe) ? gruppen : gruppen + [uebung.gruppe]
    }

    private func eigeneSchluessel() -> Set<String> {
        var s = uebrigeSchluessel
        for t in uebung.aufgaben { s.insert(MatheGenerator.schluessel(t)) }
        return s
    }

    private func ergaenze(_ v: MatheVorlage, _ n: Int) {
        var s = eigeneSchluessel()
        uebung.aufgaben.append(contentsOf: MatheGenerator.fuelle(v, anzahl: n, ausschluss: &s))
    }

    private func ersetze(_ v: MatheVorlage) {
        var s = uebrigeSchluessel
        uebung.aufgaben = MatheGenerator.fuelle(v, anzahl: v.anzahl, ausschluss: &s)
    }
}

// MARK: - Mathe-Editor: Formular für eine einzelne Aufgabe

enum MatheAufgabenArt: String, CaseIterable, Identifiable {
    case rechnung, rest, vergleich, mauer, raetsel, sach, wort, frei

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .rechnung: return "Rechnung (Lösung wird berechnet)"
        case .rest: return "Teilen mit Rest"
        case .vergleich: return "Größer oder kleiner"
        case .mauer: return "Zahlenmauer"
        case .raetsel: return "Zahlenrätsel"
        case .sach: return "Sachaufgabe"
        case .wort: return "Rechnung mit Wörtern"
        case .frei: return "Freie Aufgabe (Lösung selbst eingeben)"
        }
    }

    var symbol: String {
        switch self {
        case .rechnung: return "plus.forwardslash.minus"
        case .rest: return "divide"
        case .vergleich: return "lessthan.circle"
        case .mauer: return "triangle"
        case .raetsel: return "questionmark.circle"
        case .sach: return "text.book.closed"
        case .wort: return "text.quote"
        case .frei: return "pencil"
        }
    }

    var standardFrage: String {
        switch self {
        case .rechnung: return "Rechne."
        case .rest: return "Teile mit Rest. Rechne bis zum Ende."
        case .vergleich: return "Was gehört in die Mitte?"
        case .mauer: return "Fülle die Mauer von unten nach oben."
        case .raetsel: return "Wie heißt die Zahl?"
        case .sach: return "Lies genau. Rechne und antworte."
        case .wort: return "Notiere die passende Rechnung."
        case .frei: return "Rechne."
        }
    }
}

struct FormularErgebnis {
    var aufgabe: MatheAufgabe? = nil
    var fehler: String? = nil
    var hinweis: String? = nil
}

struct MatheAufgabeFormular: View {
    let art: MatheAufgabenArt
    let speichern: (MatheAufgabe) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var frage = ""
    @State private var hinweis = ""
    @State private var ausdruck = ""
    @State private var zahlA = ""
    @State private var zahlB = ""
    @State private var links = ""
    @State private var rechts = ""
    @State private var m1 = ""
    @State private var m2 = ""
    @State private var m3 = ""
    @State private var m4 = ""
    @State private var gerade = true
    @State private var xer = 5
    @State private var von = ""
    @State private var bis = ""
    @State private var text = ""
    @State private var wortMinus = true
    @State private var wortVariante = 0
    @State private var freiRechnung = ""
    @State private var freiAntwort = ""

    private var feld: Color { Color.white.opacity(0.08) }

    private func zahl(_ s: String) -> Int? { Int(s.trimmingCharacters(in: .whitespaces)) }

    // MARK: Aufgabe aus den Eingaben bauen

    private var ergebnis: FormularErgebnis {
        let f = frage.trimmingCharacters(in: .whitespaces).isEmpty ? art.standardFrage : frage
        switch art {
        case .rechnung:
            do {
                let w = try MatheRechner.werte(ausdruck)
                guard (0...999).contains(w) else {
                    return FormularErgebnis(fehler: "Das Ergebnis muss zwischen 0 und 999 liegen (hier: \(w)).")
                }
                let anz = MatheRechner.anzeige(ausdruck)
                var a = MatheAufgabe(art: "zahl", frage: f, rechnung: anz + " =", antwort: String(w),
                                     erklaerung: "\(anz) = \(w)")
                a.hinweis = hinweis
                return FormularErgebnis(aufgabe: a)
            } catch let fehler as MatheRechner.Fehler {
                return FormularErgebnis(fehler: fehler.text)
            } catch {
                return FormularErgebnis(fehler: "Unbekannter Fehler.")
            }
        case .rest:
            guard let a = zahl(zahlA), let b = zahl(zahlB) else { return FormularErgebnis(fehler: "Bitte beide Zahlen eingeben.") }
            guard a >= 0, a <= 999, b >= 2, b <= 99 else { return FormularErgebnis(fehler: "Die erste Zahl darf höchstens 999 sein, der Teiler muss zwischen 2 und 99 liegen.") }
            let q = a / b
            let r = a % b
            let e = "\(a) : \(b) = \(q)" + (r > 0 ? " R \(r)" : " (kein Rest)")
            let aufg = MatheAufgabe(art: "rest", frage: f, rechnung: "\(a) : \(b) =", antwort: String(q),
                                    antwort2: String(r), erklaerung: e)
            let warn = r == 0 ? "Hinweis: Diese Aufgabe geht ohne Rest auf." : nil
            return FormularErgebnis(aufgabe: aufg, hinweis: warn)
        case .vergleich:
            do {
                let lw = try MatheRechner.werte(links)
                let rw = try MatheRechner.werte(rechts)
                let zeichen = lw > rw ? ">" : (lw < rw ? "<" : "=")
                let aufg = MatheAufgabe(art: "vergleich", frage: f,
                                        rechnung: "\(MatheRechner.anzeige(links))  ?  \(MatheRechner.anzeige(rechts))",
                                        antwort: zeichen, erklaerung: "\(lw) \(zeichen) \(rw)")
                return FormularErgebnis(aufgabe: aufg)
            } catch let fehler as MatheRechner.Fehler {
                return FormularErgebnis(fehler: fehler.text)
            } catch {
                return FormularErgebnis(fehler: "Unbekannter Fehler.")
            }
        case .mauer:
            let basis = [zahl(m1), zahl(m2), zahl(m3), zahl(m4)]
            guard basis.allSatisfy({ $0 != nil }) else { return FormularErgebnis(fehler: "Bitte alle vier Zahlen der untersten Reihe eingeben.") }
            let b = basis.compactMap { $0 }
            guard b.allSatisfy({ $0 >= 1 && $0 <= 99 }) else { return FormularErgebnis(fehler: "Die Zahlen müssen zwischen 1 und 99 liegen.") }
            var reihen: [[Int]] = [b]
            while let letzte = reihen.last, letzte.count > 1 {
                var neu: [Int] = []
                for i in 0..<(letzte.count - 1) { neu.append(letzte[i] + letzte[i + 1]) }
                reihen.append(neu)
            }
            let spitze = reihen.last?.first ?? 0
            if spitze > 999 { return FormularErgebnis(fehler: "Die Spitze (\(spitze)) darf höchstens 999 sein.") }
            let warn = spitze > 100 ? "Hinweis: Die Spitze ist \(spitze). In Klasse 3 bleibt man meist bis 100." : nil
            return FormularErgebnis(aufgabe: MatheAufgabe(art: "mauer", frage: f, reihen: reihen), hinweis: warn)
        case .raetsel:
            guard let v = zahl(von), let bs = zahl(bis) else { return FormularErgebnis(fehler: "Bitte „zwischen“ und „und“ eingeben.") }
            guard bs - v >= 2, v >= 0, bs <= 1000 else { return FormularErgebnis(fehler: "Der Bereich muss mindestens drei Zahlen umfassen und unter 1000 liegen.") }
            var treffer: [Int] = []
            for n in (v + 1)..<bs {
                if n % xer != 0 { continue }
                if gerade && n % 2 != 0 { continue }
                if !gerade && n % 2 != 1 { continue }
                treffer.append(n)
            }
            if treffer.count != 1 {
                let liste = treffer.isEmpty ? "keine" : treffer.map { String($0) }.joined(separator: ", ")
                return FormularErgebnis(fehler: "Die Lösung muss eindeutig sein. Passende Zahlen: \(liste).")
            }
            let paritaet = gerade ? "gerade" : "ungerade"
            let t = "Meine Zahl ist \(paritaet).\nSie ist eine \(MatheGenerator.zahlwort(xer))zahl.\nSie liegt zwischen \(v) und \(bs)."
            return FormularErgebnis(aufgabe: MatheAufgabe(art: "zahl", frage: f, rechnung: t, antwort: String(treffer[0])))
        case .sach:
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.isEmpty { return FormularErgebnis(fehler: "Bitte den Text der Aufgabe eingeben.") }
            do {
                let w = try MatheRechner.werte(ausdruck)
                guard (0...999).contains(w) else {
                    return FormularErgebnis(fehler: "Das Ergebnis muss zwischen 0 und 999 liegen (hier: \(w)).")
                }
                let anz = MatheRechner.anzeige(ausdruck)
                let aufg = MatheAufgabe(art: "zahl", frage: f, rechnung: t, antwort: String(w), erklaerung: "\(anz) = \(w)")
                return FormularErgebnis(aufgabe: aufg)
            } catch let fehler as MatheRechner.Fehler {
                return FormularErgebnis(fehler: fehler.text)
            } catch {
                return FormularErgebnis(fehler: "Unbekannter Fehler.")
            }
        case .wort:
            guard let a = zahl(zahlA), let b = zahl(zahlB) else { return FormularErgebnis(fehler: "Bitte beide Zahlen eingeben.") }
            if wortMinus {
                guard a > b, b >= 0, a <= 999 else { return FormularErgebnis(fehler: "Die erste Zahl muss größer sein als die zweite und höchstens 999.") }
                let t = wortVariante == 0 ? "Subtrahiere von \(a) die Zahl \(b)." : "Wie heißt die Differenz der Zahlen \(a) und \(b)?"
                return FormularErgebnis(aufgabe: MatheAufgabe(art: "zahl", frage: f, rechnung: t, antwort: String(a - b),
                                                              erklaerung: "\(a) - \(b) = \(a - b)"))
            } else {
                guard a >= 0, b >= 0, a * b <= 999 else { return FormularErgebnis(fehler: "Das Produkt darf höchstens 999 sein.") }
                let t = wortVariante == 0 ? "Multipliziere die Zahlen \(a) und \(b)." : "Wie heißt das Produkt der Zahlen \(a) und \(b)?"
                return FormularErgebnis(aufgabe: MatheAufgabe(art: "zahl", frage: f, rechnung: t, antwort: String(a * b),
                                                              erklaerung: "\(a) · \(b) = \(a * b)"))
            }
        case .frei:
            let r = freiRechnung.trimmingCharacters(in: .whitespacesAndNewlines)
            if r.isEmpty { return FormularErgebnis(fehler: "Bitte die Aufgabe eingeben.") }
            guard let w = zahl(freiAntwort), (0...999).contains(w) else { return FormularErgebnis(fehler: "Die Lösung muss eine ganze Zahl von 0 bis 999 sein.") }
            var a = MatheAufgabe(art: "zahl", frage: f, rechnung: r, antwort: String(w))
            a.hinweis = hinweis
            return FormularErgebnis(aufgabe: a, hinweis: "Bei freien Aufgaben prüft die App die Lösung nicht. Bitte noch einmal selbst nachrechnen.")
        }
    }

    // MARK: Oberfläche

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                List {
                    Section("Anweisung") {
                        TextField(art.standardFrage, text: $frage)
                    }
                    .listRowBackground(feld)

                    eingaben

                    Section("Vorschau") {
                        let e = ergebnis
                        if let a = e.aufgabe {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(a.art == "mauer" ? "Mauer mit Spitze \(a.reihen.last?.first ?? 0)" : a.rechnung)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                if a.art != "mauer" {
                                    Text("Lösung: \(a.antwort)" + (a.art == "rest" ? " Rest \(a.antwort2)" : ""))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(Theme.mint)
                                }
                                if let h = e.hinweis {
                                    Text(h).font(.footnote).foregroundStyle(Theme.himmel)
                                }
                            }
                        } else if let fehler = e.fehler {
                            Text(fehler).font(.footnote.weight(.semibold)).foregroundStyle(Theme.koralle)
                        }
                    }
                    .listRowBackground(feld)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(art.titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        if let a = ergebnis.aufgabe {
                            speichern(a)
                            dismiss()
                        }
                    }
                    .disabled(ergebnis.aufgabe == nil)
                }
            }
        }
    }

    @ViewBuilder
    private var eingaben: some View {
        switch art {
        case .rechnung:
            Section {
                TextField("zum Beispiel 7 · 8 oder 9 · 9 + 8", text: $ausdruck)
                    .keyboardType(.numbersAndPunctuation)
                TextField("Hinweis (optional)", text: $hinweis)
            } header: {
                Text("Rechnung")
            } footer: {
                Text("Erlaubt sind + - · : und Klammern. Statt · kannst du * oder x tippen.")
            }
            .listRowBackground(feld)
        case .rest:
            Section("Teilen mit Rest") {
                TextField("Zahl, die geteilt wird (zum Beispiel 58)", text: $zahlA).keyboardType(.numberPad)
                TextField("Geteilt durch (zum Beispiel 4)", text: $zahlB).keyboardType(.numberPad)
            }
            .listRowBackground(feld)
        case .vergleich:
            Section("Linke und rechte Seite") {
                TextField("links, zum Beispiel 5 · 5", text: $links).keyboardType(.numbersAndPunctuation)
                TextField("rechts, zum Beispiel 9 · 7", text: $rechts).keyboardType(.numbersAndPunctuation)
            }
            .listRowBackground(feld)
        case .mauer:
            Section("Unterste Reihe (vier Zahlen)") {
                HStack(spacing: 8) {
                    TextField("1", text: $m1).keyboardType(.numberPad).multilineTextAlignment(.center)
                    TextField("2", text: $m2).keyboardType(.numberPad).multilineTextAlignment(.center)
                    TextField("3", text: $m3).keyboardType(.numberPad).multilineTextAlignment(.center)
                    TextField("4", text: $m4).keyboardType(.numberPad).multilineTextAlignment(.center)
                }
            }
            .listRowBackground(feld)
        case .raetsel:
            Section("Bedingungen") {
                Picker("Die Zahl ist", selection: $gerade) {
                    Text("gerade").tag(true)
                    Text("ungerade").tag(false)
                }
                .pickerStyle(.segmented)
                Picker("Sie gehört zur", selection: $xer) {
                    ForEach(2...10, id: \.self) { k in Text("\(MatheGenerator.zahlwort(k))zahl").tag(k) }
                }
                TextField("Sie liegt zwischen … (zum Beispiel 21)", text: $von).keyboardType(.numberPad)
                TextField("und … (zum Beispiel 44)", text: $bis).keyboardType(.numberPad)
            }
            .listRowBackground(feld)
        case .sach:
            Section {
                TextField("Text der Aufgabe", text: $text, axis: .vertical).lineLimit(3...8)
                TextField("Rechnung, zum Beispiel 5 · 4", text: $ausdruck).keyboardType(.numbersAndPunctuation)
            } header: {
                Text("Sachaufgabe")
            } footer: {
                Text("Die Lösung berechnet die App aus deiner Rechnung.")
            }
            .listRowBackground(feld)
        case .wort:
            Section("Rechnung mit Wörtern") {
                Picker("Rechenart", selection: $wortMinus) {
                    Text("Minus").tag(true)
                    Text("Mal").tag(false)
                }
                .pickerStyle(.segmented)
                Picker("Formulierung", selection: $wortVariante) {
                    Text("Variante 1").tag(0)
                    Text("Variante 2").tag(1)
                }
                .pickerStyle(.segmented)
                TextField("Erste Zahl", text: $zahlA).keyboardType(.numberPad)
                TextField("Zweite Zahl", text: $zahlB).keyboardType(.numberPad)
            }
            .listRowBackground(feld)
        case .frei:
            Section("Freie Aufgabe") {
                TextField("Aufgabe", text: $freiRechnung, axis: .vertical).lineLimit(2...6)
                TextField("Lösung (ganze Zahl)", text: $freiAntwort).keyboardType(.numberPad)
                TextField("Hinweis (optional)", text: $hinweis)
            }
            .listRowBackground(feld)
        }
    }
}

// MARK: - Vokabel-Editor

struct EditorWort: Codable, Identifiable, Equatable {
    var id = UUID()
    var emoji = ""
    var de = ""
    var en = ""
    var tr = ""
    var altEn = ""
    var altTr = ""
    var hinweis = ""

    static func liste(_ s: String) -> [String] {
        s.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var gueltig: Bool {
        !de.trimmingCharacters(in: .whitespaces).isEmpty
            && !en.trimmingCharacters(in: .whitespaces).isEmpty
            && !tr.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func katalogDict() -> [String: Any] {
        var d: [String: Any] = ["de": de, "en": en, "tr": tr]
        if !emoji.isEmpty { d["emoji"] = emoji }
        var alt: [String: [String]] = [:]
        let e = EditorWort.liste(altEn)
        let t = EditorWort.liste(altTr)
        if !e.isEmpty { alt["en"] = e }
        if !t.isEmpty { alt["tr"] = t }
        if !alt.isEmpty { d["alt"] = alt }
        if !hinweis.isEmpty { d["hinweis"] = hinweis }
        return d
    }
}

struct EditorThema: Codable, Identifiable, Equatable {
    var id: String
    var titel: String
    var emoji: String
    var stufe: Int
    var bilder: Bool
    var woerter: [EditorWort]

    func katalogDict() -> [String: Any] {
        ["id": id, "titel": titel, "emoji": emoji, "stufe": stufe, "bilder": bilder,
         "typ": "woerter", "woerter": woerter.map { $0.katalogDict() }]
    }

    func jsonText() -> String {
        let d: [String: Any] = ["themen": [katalogDict()]]
        guard let data = try? JSONSerialization.data(withJSONObject: d,
                                                     options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]),
              let s = String(data: data, encoding: .utf8) else { return "" }
        return s
    }

    static func aus(_ t: Thema) -> EditorThema {
        EditorThema(id: t.id, titel: t.titel, emoji: t.emoji, stufe: t.stufe, bilder: t.bilder,
                    woerter: t.woerter.map { w in
                        EditorWort(emoji: w.emoji ?? "", de: w.texte["de"] ?? "", en: w.texte["en"] ?? "",
                                   tr: w.texte["tr"] ?? "", altEn: (w.alt["en"] ?? []).joined(separator: ", "),
                                   altTr: (w.alt["tr"] ?? []).joined(separator: ", "), hinweis: w.hinweis ?? "")
                    })
    }
}

@Observable
final class SprachEditorStore {
    static let shared = SprachEditorStore()
    var themen: [EditorThema] = []
    private let key = "sprachEditorThemenV1"

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let t = try? JSONDecoder().decode([EditorThema].self, from: d) {
            themen = t
        }
    }

    func hat(_ id: String) -> Bool { themen.contains { $0.id == id } }

    func katalogDaten() -> Data? {
        if themen.isEmpty { return nil }
        let d: [String: Any] = ["themen": themen.map { $0.katalogDict() }]
        return try? JSONSerialization.data(withJSONObject: d)
    }

    private func sichere() {
        if let d = try? JSONEncoder().encode(themen) { UserDefaults.standard.set(d, forKey: key) }
        SprachKatalogStore.shared.baueNeu()
    }

    func speichere(_ t: EditorThema) {
        if let i = themen.firstIndex(where: { $0.id == t.id }) {
            themen[i] = t
        } else {
            themen.append(t)
        }
        sichere()
    }

    func loesche(_ id: String) {
        themen.removeAll { $0.id == id }
        sichere()
    }
}

struct SprachEditorListeView: View {
    private let store = SprachKatalogStore.shared
    private let editor = SprachEditorStore.shared
    @State private var geheZu: String? = nil

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Button { neuesThema() } label: {
                        Label("Neues Thema anlegen", systemImage: "plus.circle.fill")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.navy)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(Theme.gelb, in: Capsule())
                    }
                    .buttonStyle(TastenStil())

                    Text("Eingebaute Themen kannst du ändern, zum Beispiel um ein Wort zu korrigieren. Die geänderte Fassung gilt dann auf diesem Gerät.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)

                    ForEach(store.katalog.themen) { t in
                        NavigationLink { SprachThemaEditorView(themaID: t.id) } label: { zeile(t) }
                            .buttonStyle(TastenStil())
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Themen bearbeiten")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $geheZu) { id in SprachThemaEditorView(themaID: id) }
    }

    private func neuesThema() {
        let kurz = String(UUID().uuidString.prefix(6)).lowercased()
        let t = EditorThema(id: "eigen-" + kurz, titel: "Neues Thema", emoji: "✨", stufe: 2, bilder: true, woerter: [])
        editor.speichere(t)
        geheZu = t.id
    }

    private func zeile(_ t: Thema) -> some View {
        let eigen = t.id.hasPrefix("eigen-")
        let geaendert = editor.hat(t.id) && !eigen
        return HStack(spacing: 12) {
            Text(t.emoji).font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(t.titel)
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.white)
                Text("\(t.woerter.count) Wörter · Stufe \(t.stufe)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            if eigen {
                Text("eigen").font(.caption2.weight(.heavy)).foregroundStyle(Theme.navy)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.gelb, in: Capsule())
            } else if geaendert {
                Text("geändert").font(.caption2.weight(.heavy)).foregroundStyle(Theme.navy)
                    .padding(.horizontal, 8).padding(.vertical, 3).background(Theme.himmel, in: Capsule())
            }
            Image(systemName: "chevron.right").font(.footnote.weight(.bold)).foregroundStyle(Theme.gelb)
        }
        .padding(14)
        .glasKarte(radius: 22)
    }
}

struct SprachThemaEditorView: View {
    let themaID: String
    @Environment(\.dismiss) private var dismiss
    @State private var entwurf = EditorThema(id: "", titel: "", emoji: "✨", stufe: 2, bilder: true, woerter: [])
    @State private var geladen = false
    @State private var original = EditorThema(id: "", titel: "", emoji: "✨", stufe: 2, bilder: true, woerter: [])
    @State private var meldung: String? = nil
    @State private var zeigeLoeschen = false
    private let store = SprachKatalogStore.shared
    private let editor = SprachEditorStore.shared
    private var feld: Color { Color.white.opacity(0.08) }

    private var istEigen: Bool { themaID.hasPrefix("eigen-") }

    private var probleme: [String] {
        var p: [String] = []
        if entwurf.titel.trimmingCharacters(in: .whitespaces).isEmpty { p.append("Der Titel fehlt.") }
        if entwurf.woerter.isEmpty { p.append("Das Thema hat noch keine Wörter.") }
        for w in entwurf.woerter where !w.gueltig {
            p.append("Beim Wort „\(w.de.isEmpty ? "?" : w.de)“ fehlt Deutsch, Englisch oder Türkisch.")
        }
        let en = entwurf.woerter.map { $0.en.lowercased().trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if Set(en).count != en.count { p.append("Ein englisches Wort kommt doppelt vor.") }
        return p
    }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Thema") {
                    TextField("Titel", text: $entwurf.titel)
                    TextField("Emoji", text: $entwurf.emoji)
                    Picker("Stufe", selection: $entwurf.stufe) {
                        Text("Stufe 1").tag(1)
                        Text("Stufe 2").tag(2)
                        Text("Stufe 3").tag(3)
                    }
                    Toggle("Bilder (Emoji) in Fragen zeigen", isOn: $entwurf.bilder)
                }
                .listRowBackground(feld)

                Section("Wörter (\(entwurf.woerter.count))") {
                    ForEach($entwurf.woerter) { $w in
                        NavigationLink {
                            WortEditorView(wort: $w)
                        } label: {
                            HStack(spacing: 10) {
                                Text(w.emoji.isEmpty ? "·" : w.emoji).font(.system(size: 24))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(w.de.isEmpty ? "Neues Wort" : w.de)
                                        .font(.system(.body, design: .rounded).weight(.bold))
                                    Text("\(w.en) · \(w.tr)")
                                        .font(.caption)
                                        .foregroundStyle(w.gueltig ? Theme.textSanft : Theme.koralle)
                                }
                            }
                        }
                    }
                    .onDelete { entwurf.woerter.remove(atOffsets: $0) }
                    Button {
                        entwurf.woerter.append(EditorWort())
                    } label: {
                        Label("Wort hinzufügen", systemImage: "plus.circle.fill")
                    }
                }
                .listRowBackground(feld)

                if !probleme.isEmpty {
                    Section("Noch zu tun") {
                        ForEach(probleme, id: \.self) { p in
                            Text(p).font(.footnote).foregroundStyle(Theme.koralle)
                        }
                    }
                    .listRowBackground(feld)
                }

                Section {
                    Button { speichere() } label: {
                        Label("Speichern", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!probleme.isEmpty)
                    ShareLink(item: entwurf.jsonText()) {
                        Label("Als JSON teilen (für das Kind-Gerät)", systemImage: "square.and.arrow.up")
                    }
                    if istEigen {
                        Button(role: .destructive) { zeigeLoeschen = true } label: {
                            Label("Thema löschen", systemImage: "trash")
                        }
                    } else if editor.hat(themaID) {
                        Button(role: .destructive) { zeigeLoeschen = true } label: {
                            Label("Auf die eingebaute Fassung zurücksetzen", systemImage: "arrow.uturn.backward")
                        }
                    }
                } footer: {
                    Text("Auf dem Kind-Gerät fügst du das JSON unter Sprachen, Einstellungen, Weitere Themen laden ein (oder mit Plus, Text einfügen im Mathe-Tab).")
                }
                .listRowBackground(feld)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(entwurf.titel.isEmpty ? "Thema" : entwurf.titel)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .primaryAction) { EditButton() } }
        .onAppear { lade() }
        .onDisappear {
            if geladen && entwurf != original && probleme.isEmpty { editor.speichere(entwurf) }
        }
        .alert("Thema", isPresented: Binding(get: { meldung != nil }, set: { if !$0 { meldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(meldung ?? "")
        }
        .confirmationDialog(istEigen ? "Thema löschen?" : "Zurücksetzen?", isPresented: $zeigeLoeschen, titleVisibility: .visible) {
            Button(istEigen ? "Löschen" : "Zurücksetzen", role: .destructive) {
                editor.loesche(themaID)
                original = entwurf
                dismiss()
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func lade() {
        if geladen { return }
        if let vorhanden = editor.themen.first(where: { $0.id == themaID }) {
            entwurf = vorhanden
        } else if let t = store.katalog.themen.first(where: { $0.id == themaID }) {
            entwurf = EditorThema.aus(t)
        }
        original = entwurf
        geladen = true
    }

    private func speichere() {
        editor.speichere(entwurf)
        original = entwurf
        meldung = "Gespeichert. Das Thema ist jetzt im Sprachbereich dieses Geräts zu sehen."
    }
}

struct WortEditorView: View {
    @Binding var wort: EditorWort
    private var feld: Color { Color.white.opacity(0.08) }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                Section("Wort") {
                    TextField("Emoji (optional)", text: $wort.emoji)
                    TextField("Deutsch, zum Beispiel der Hund", text: $wort.de)
                    TextField("Englisch, zum Beispiel dog", text: $wort.en)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Türkisch, zum Beispiel köpek", text: $wort.tr)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    HStack(spacing: 6) {
                        ForEach(["ç", "ğ", "ı", "ö", "ş", "ü", "İ"], id: \.self) { z in
                            Button { wort.tr += z } label: {
                                Text(z)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .listRowBackground(feld)

                Section {
                    TextField("Englisch, zum Beispiel mom, mummy", text: $wort.altEn)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Türkisch, zum Beispiel bere", text: $wort.altTr)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Weitere richtige Schreibweisen")
                } footer: {
                    Text("Mit Komma trennen. Diese Varianten zählen beim Tippen auch als richtig.")
                }
                .listRowBackground(feld)

                Section("Hinweis (optional)") {
                    TextField("zum Beispiel Mamas Mutter heißt anneanne", text: $wort.hinweis, axis: .vertical)
                }
                .listRowBackground(feld)

                if !wort.gueltig {
                    Section {
                        Text("Deutsch, Englisch und Türkisch müssen ausgefüllt sein.")
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                    .listRowBackground(feld)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(wort.de.isEmpty ? "Neues Wort" : wort.de)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Eltern-Joker

enum JokerPunkteArt: String, CaseIterable, Codable {
    case schnell, zweite, hilfreich, verraten

    var titel: String {
        switch self {
        case .schnell: return "Erste Antwort"
        case .zweite: return "Zweite Antwort"
        case .hilfreich: return "Hilfreich (Daumen vom Kind)"
        case .verraten: return "Lösung verraten"
        }
    }

    var emoji: String {
        switch self {
        case .schnell: return "⚡"
        case .zweite: return "🥈"
        case .hilfreich: return "👍"
        case .verraten: return "🙈"
        }
    }

    var punkte: Int {
        switch self {
        case .schnell: return 3
        case .zweite: return 1
        case .hilfreich: return 2
        case .verraten: return -2
        }
    }
}

struct JokerMitglied: Codable, Identifiable {
    var id = UUID()
    var name: String
    var emoji: String
}

struct JokerEreignis: Codable, Identifiable {
    var id = UUID()
    var ts: Date
    var mitgliedID: UUID
    var art: JokerPunkteArt
}

@Observable
final class JokerStand {
    static let shared = JokerStand()
    var mitglieder: [JokerMitglied] = []
    var ereignisse: [JokerEreignis] = []
    var nutzungen: [Date] = []
    var limitProTag = 3
    var ligaAn = true
    private let key = "jokerStandV1"

    private struct Speicher: Codable {
        var mitglieder: [JokerMitglied]
        var ereignisse: [JokerEreignis]
        var nutzungen: [Date]
        var limitProTag: Int
        var ligaAn: Bool
    }

    init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(Speicher.self, from: d) {
            mitglieder = s.mitglieder
            ereignisse = s.ereignisse
            nutzungen = s.nutzungen
            limitProTag = s.limitProTag
            ligaAn = s.ligaAn
        }
        if mitglieder.isEmpty {
            mitglieder = [JokerMitglied(name: "Papa", emoji: "👨"),
                          JokerMitglied(name: "Mama", emoji: "👩"),
                          JokerMitglied(name: "Geschwister", emoji: "🧑")]
        }
    }

    func sichere() {
        let s = Speicher(mitglieder: mitglieder, ereignisse: ereignisse, nutzungen: nutzungen,
                         limitProTag: limitProTag, ligaAn: ligaAn)
        if let d = try? JSONEncoder().encode(s) { UserDefaults.standard.set(d, forKey: key) }
    }

    var heuteGenutzt: Int {
        nutzungen.filter { Calendar.current.isDateInToday($0) }.count
    }

    var uebrigHeute: Int { max(0, limitProTag - heuteGenutzt) }

    // Verbraucht einen Joker. Gibt false zurück, wenn heute keiner mehr übrig ist.
    func nutze() -> Bool {
        if uebrigHeute <= 0 { return false }
        nutzungen.append(Date.now)
        if nutzungen.count > 200 { nutzungen = Array(nutzungen.suffix(200)) }
        sichere()
        return true
    }

    func vergib(_ art: JokerPunkteArt, an id: UUID) {
        ereignisse.append(JokerEreignis(ts: Date.now, mitgliedID: id, art: art))
        sichere()
    }

    func letztesRueckgaengig() {
        if !ereignisse.isEmpty {
            ereignisse.removeLast()
            sichere()
        }
    }

    func punkte(_ id: UUID, seit: Date?) -> Int {
        ereignisse.filter { $0.mitgliedID == id && (seit == nil || $0.ts >= seit!) }
            .reduce(0) { $0 + $1.art.punkte }
    }

    func anzahl(_ art: JokerPunkteArt, _ id: UUID) -> Int {
        ereignisse.filter { $0.mitgliedID == id && $0.art == art }.count
    }

    func mitglied(_ id: UUID) -> JokerMitglied? { mitglieder.first { $0.id == id } }
}

// Texte für den Joker: nie die Lösung verraten
enum JokerText {
    static func mathe(_ a: Aufgabe) -> String {
        let kern: String
        if a.art == "mauer" {
            let basis = (a.reihen.first ?? []).map { String($0) }.joined(separator: " ")
            kern = "Zahlenmauer, unterste Reihe: \(basis)"
        } else {
            kern = a.rechnung.replacingOccurrences(of: "\n", with: " ")
        }
        return "🃏 YEM1N Joker! Ich brauche einen Tipp (bitte nicht die Lösung verraten):\n\(a.frage)\n\(kern)"
    }

    static func sprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        return "🃏 YEM1N Joker! \(info.flagge) Ich brauche einen Tipp (bitte nicht die Lösung verraten):\n\(kern)"
    }
}

struct JokerKnopf: View {
    let uebrig: Int
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Label("Joker (\(uebrig))", systemImage: "suit.spade.fill")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
                .padding(.vertical, 10)
                .padding(.horizontal, 18)
                .background(Theme.gelb.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }
}

// MARK: Eltern-Liga (Punkte werden vorerst von Hand eingetragen)

struct LigaZeile: Identifiable {
    let mitglied: JokerMitglied
    let punkte: Int
    var id: UUID { mitglied.id }
}

struct JokerLigaView: View {
    private let joker = JokerStand.shared
    @AppStorage("jokerIch") private var jokerIch = ""
    @State private var gesamt = false
    @State private var gewaehlt: UUID? = nil
    @State private var neuerName = ""
    @State private var neuesEmoji = "🙂"
    @State private var letzteMeldung = ""

    private var wochenStart: Date? {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date.now)?.start
    }

    private var rangliste: [LigaZeile] {
        let seit: Date? = gesamt ? nil : wochenStart
        var liste: [LigaZeile] = []
        for m in joker.mitglieder {
            liste.append(LigaZeile(mitglied: m, punkte: joker.punkte(m.id, seit: seit) + JokerCloud.shared.punkte(name: m.name, seit: seit)))
        }
        return liste.sorted { $0.punkte > $1.punkte }
    }

    private func platzText(_ platz: Int) -> String {
        let medaillen = ["🥇", "🥈", "🥉"]
        return medaillen.indices.contains(platz) ? medaillen[platz] : "\(platz + 1)."
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        JokerPostfachView()
                        if joker.ligaAn { liga }
                        eintragen
                        einstellungen
                        CloudStatusKarte()
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Eltern-Joker")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text("Wer dem Kind zuerst hilft, bekommt Punkte.")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var liga: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Zeitraum", selection: $gesamt) {
                Text("Diese Woche").tag(false)
                Text("Gesamt").tag(true)
            }
            .pickerStyle(.segmented)
            ForEach(Array(rangliste.enumerated()), id: \.element.id) { platz, eintrag in
                HStack(spacing: 12) {
                    Text(platzText(platz))
                        .font(.system(size: 24))
                        .frame(width: 36)
                    Text(eintrag.mitglied.emoji).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eintrag.mitglied.name)
                            .font(.system(.body, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        Text(abzeichen(eintrag.mitglied.id))
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                    Text("\(eintrag.punkte)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                }
            }
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private func abzeichen(_ id: UUID) -> String {
        var a: [String] = []
        if joker.anzahl(.schnell, id) >= 3 { a.append("⚡ Blitz-Helfer") }
        if joker.anzahl(.hilfreich, id) >= 3 { a.append("👍 Lieblingshelfer") }
        if joker.anzahl(.verraten, id) >= 2 { a.append("🙈 Verräter") }
        if joker.punkte(id, seit: nil) >= 20 { a.append("🏅 Joker-Profi") }
        return a.isEmpty ? "noch keine Abzeichen" : a.joined(separator: " · ")
    }

    private var eintragen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Punkte eintragen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Tipps aus dem Joker-Postfach zählen automatisch. Hier trägst du Sonderfälle ein, zum Beispiel wenn jemand die Lösung verraten hat.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 8) {
                ForEach(joker.mitglieder) { m in
                    let aktiv = (gewaehlt ?? joker.mitglieder.first?.id) == m.id
                    Button { gewaehlt = m.id } label: {
                        Text("\(m.emoji) \(m.name)")
                            .font(.system(.footnote, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
            }
            ForEach(JokerPunkteArt.allCases, id: \.self) { art in
                Button { vergib(art) } label: {
                    HStack {
                        Text("\(art.emoji) \(art.titel)")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Text(art.punkte > 0 ? "+\(art.punkte)" : "\(art.punkte)")
                            .font(.system(.body, design: .rounded).weight(.heavy))
                            .foregroundStyle(art.punkte > 0 ? Theme.mint : Theme.koralle)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(TastenStil())
            }
            if !letzteMeldung.isEmpty {
                HStack {
                    Text(letzteMeldung)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.himmel)
                    Spacer()
                    Button("Rückgängig") {
                        joker.letztesRueckgaengig()
                        letzteMeldung = ""
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.gelb)
                }
            }
        }
        .padding(16)
        .glasKarte(radius: 26)
    }

    private func vergib(_ art: JokerPunkteArt) {
        guard let id = gewaehlt ?? joker.mitglieder.first?.id, let m = joker.mitglied(id) else { return }
        joker.vergib(art, an: id)
        Haptik.leicht()
        letzteMeldung = "\(m.emoji) \(m.name): \(art.punkte > 0 ? "+" : "")\(art.punkte) (\(art.titel))"
    }

    private var einstellungen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Einstellungen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Dieses Gerät gehört zu")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 8) {
                ForEach(joker.mitglieder) { m in
                    let ich = joker.mitglieder.first(where: { $0.id.uuidString == jokerIch }) ?? joker.mitglieder.first
                    let aktiv = (ich?.id == m.id)
                    Button { jokerIch = m.id.uuidString } label: {
                        Text("\(m.emoji) \(m.name)")
                            .font(.system(.footnote, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .frame(maxWidth: .infinity, minHeight: 38)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
            }
            Stepper("Joker pro Tag fürs Kind: \(joker.limitProTag)",
                    value: Binding(get: { joker.limitProTag },
                                   set: { joker.limitProTag = $0; joker.sichere() }),
                    in: 1...10)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            Toggle("Liga anzeigen", isOn: Binding(get: { joker.ligaAn },
                                                  set: { joker.ligaAn = $0; joker.sichere() }))
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
                .tint(Theme.gelb)

            Text("Mitspieler")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            ForEach(joker.mitglieder) { m in
                HStack {
                    Text("\(m.emoji) \(m.name)")
                        .foregroundStyle(Color.white)
                    Spacer()
                    if joker.mitglieder.count > 1 {
                        Button(role: .destructive) {
                            joker.mitglieder.removeAll { $0.id == m.id }
                            joker.ereignisse.removeAll { $0.mitgliedID == m.id }
                            joker.sichere()
                        } label: {
                            Image(systemName: "trash").foregroundStyle(Theme.koralle)
                        }
                    }
                }
            }
            HStack(spacing: 8) {
                TextField("🙂", text: $neuesEmoji)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                TextField("Name hinzufügen", text: $neuerName)
                    .padding(10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button {
                    let n = neuerName.trimmingCharacters(in: .whitespaces)
                    if n.isEmpty { return }
                    joker.mitglieder.append(JokerMitglied(name: n, emoji: neuesEmoji.isEmpty ? "🙂" : neuesEmoji))
                    joker.sichere()
                    neuerName = ""
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 40, height: 40)
                        .background(Theme.gelb, in: Circle())
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}


// MARK: - Nachrichten an die Familie (Texte fürs Teilen-Menü)

// Alle Texte, die YEM1N an die Familie schickt (Teilen-Menü jetzt, später auch Mitteilungen).
// Aussehen und Wortlaut änderst du nur hier.

enum Nachricht {
    static let logo = "𝗬𝗘𝗠𝟭𝗡"
    static let linie = "━━━━━━━━━━━━━━"

    // MARK: Bausteine

    static func prozent(_ richtig: Int, _ gesamt: Int) -> Int {
        guard gesamt > 0 else { return 0 }
        return Int((Double(richtig) / Double(gesamt) * 100).rounded())
    }

    // Zehn Felder, gelb für richtig
    static func balken(_ richtig: Int, _ gesamt: Int) -> String {
        let laenge = 10
        guard gesamt > 0 else { return String(repeating: "⬜️", count: laenge) }
        let voll = min(laenge, max(0, Int((Double(richtig) / Double(gesamt) * Double(laenge)).rounded())))
        return String(repeating: "🟨", count: voll) + String(repeating: "⬜️", count: laenge - voll)
    }

    static func sterne(_ n: Int) -> String {
        let an = min(max(n, 0), 3)
        return String(repeating: "⭐️", count: an) + String(repeating: "▫️", count: 3 - an)
    }

    // Zuruf je nach Sternen
    static func zuruf(_ sterne: Int) -> String {
        switch sterne {
        case 3: return "TOOOR! Weltklasse, so macht man das! ⚽️🔥"
        case 2: return "Starker Spielzug! Nur noch ein bisschen Feinschliff. 💪"
        case 1: return "Anstoß geglückt. Gleich noch eine Runde, dann sitzt es! 🚀"
        default: return "Kein Ding. Gemeinsam anschauen, dann klappt es. 🤝"
        }
    }

    private static func jokerFuss() -> [String] {
        [
            linie,
            "💡 Gebt mir einen Tipp, aber verratet nicht die Lösung!",
            "⚡️ Wer zuerst hilft: +3 Punkte",
            "👍 Wenn der Tipp hilft: +2 Punkte"
        ]
    }

    // MARK: Mathe: Rundenergebnis

    static func ergebnisMathe(_ u: Uebung) -> String {
        let gut = u.richtigAnzahl
        let gesamt = u.aufgaben.count
        let n = sterneFuer(gut: gut, gesamt: gesamt)
        var z: [String] = []
        z.append("🏆 \(logo) · Runde geschafft!")
        z.append(linie)
        z.append("\(u.symbol) \(u.titel)")
        z.append("\(sterne(n))  \(gut) von \(gesamt) richtig")
        z.append("\(balken(gut, gesamt))  \(prozent(gut, gesamt)) %")
        z.append(linie)
        if let a = u.arbeit {
            z.append("📚 \(a.klasse) · \(a.fach) · \(a.titel)")
        }
        if u.angesehenAnzahl > 0 {
            z.append("👀 Lösung angeschaut: \(u.angesehenAnzahl)")
        }
        var fehler: [String] = []
        for a in u.sortierteAufgaben where a.richtig == false {
            if fehler.count >= 3 { break }
            fehler.append(kurz(a))
        }
        if !fehler.isEmpty {
            z.append("🔎 Noch üben: " + fehler.joined(separator: "  ·  "))
        }
        z.append("")
        z.append(zuruf(n))
        return z.joined(separator: "\n")
    }

    private static func kurz(_ a: Aufgabe) -> String {
        if a.art == "mauer" { return "Zahlenmauer" }
        let roh = a.rechnung.isEmpty ? a.frage : a.rechnung
        return String(roh.replacingOccurrences(of: "\n", with: " ").prefix(34))
    }

    // MARK: Sprachen: Rundenergebnis

    static func ergebnisSprache(thema: Thema, art: SprachArt, sprache: String,
                                richtig: Int, gesamt: Int, fehler: [Wort] = []) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let n = sterneFuer(gut: richtig, gesamt: gesamt)
        var z: [String] = []
        z.append("🏆 \(logo) · Sprachrunde geschafft!")
        z.append(linie)
        z.append("\(info.flagge) \(info.name) · \(thema.emoji) \(thema.titel)")
        z.append("🎮 \(art.titel)")
        z.append("\(sterne(n))  \(richtig) von \(gesamt) richtig")
        z.append("\(balken(richtig, gesamt))  \(prozent(richtig, gesamt)) %")
        z.append(linie)
        var liste: [String] = []
        for w in fehler {
            if liste.count >= 3 { break }
            let fremd = w.texte[sprache] ?? ""
            let de = w.texte["de"] ?? ""
            liste.append("\(fremd) = \(de)")
        }
        if !liste.isEmpty {
            z.append("🔎 Noch üben: " + liste.joined(separator: "  ·  "))
        }
        z.append("")
        z.append(zuruf(n))
        return z.joined(separator: "\n")
    }

    // MARK: Joker

    static func jokerMathe(_ a: Aufgabe) -> String {
        var z: [String] = []
        z.append("🃏🚨 \(logo) · JOKER!")
        z.append(linie)
        z.append("Ich komme nicht weiter und brauche eure Hilfe!")
        if let u = a.uebung {
            z.append("📚 Mathe · \(u.symbol) \(u.titel)")
        }
        z.append("")
        if !a.frage.isEmpty {
            z.append("📝 \(a.frage)")
        }
        z.append("❓ " + aufgabenText(a))
        z.append(contentsOf: jokerFuss())
        return z.joined(separator: "\n")
    }

    private static func aufgabenText(_ a: Aufgabe) -> String {
        if a.art == "mauer" {
            let basis = (a.reihen.first ?? []).map { String($0) }.joined(separator: " · ")
            return "Zahlenmauer, unterste Reihe: \(basis)"
        }
        return a.rechnung.replacingOccurrences(of: "\n", with: " ")
    }

    static func jokerSprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        var z: [String] = []
        z.append("🃏🚨 \(logo) · JOKER!")
        z.append(linie)
        z.append("Ich komme nicht weiter und brauche eure Hilfe!")
        z.append("\(info.flagge) \(info.name)")
        z.append("")
        z.append("❓ " + kern)
        z.append(contentsOf: jokerFuss())
        return z.joined(separator: "\n")
    }

    // Kurzfassung für die Cloud (das Postfach der Eltern zeigt nur die Aufgabe)
    static func jokerKurzMathe(_ a: Aufgabe) -> String {
        var z: [String] = []
        if let u = a.uebung {
            z.append("📚 Mathe · \(u.symbol) \(u.titel)")
        }
        if !a.frage.isEmpty {
            z.append("📝 \(a.frage)")
        }
        z.append("❓ " + aufgabenText(a))
        return z.joined(separator: "\n")
    }

    static func jokerKurzSprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        return "\(info.flagge) \(info.name)\n❓ " + kern
    }

    // MARK: Sprachen: Lernbericht

    static func berichtSprache(_ c: String) -> String {
        let store = SprachKatalogStore.shared
        let stand = SprachStand.shared
        let info = store.sprache(c)
        let woerter = store.alleWoerter(c)
        let gelernt = woerter.filter { stand.gelernt($0, c) }.count

        var z: [String] = []
        z.append("📊 \(logo) · Lernbericht")
        z.append(linie)
        z.append("\(info.flagge) \(info.name)")
        z.append("🎯 \(gelernt) von \(woerter.count) Wörtern gelernt")
        z.append("\(balken(gelernt, woerter.count))  \(prozent(gelernt, woerter.count)) %")

        let letzte = Array(stand.verlauf.filter { $0.sp == c }.suffix(5).reversed())
        if !letzte.isEmpty {
            z.append(linie)
            z.append("🔥 Letzte Runden")
            for x in letzte {
                let datum = x.ts.formatted(.dateTime.day(.twoDigits).month(.twoDigits))
                let st = sterne(sterneFuer(gut: x.richtig, gesamt: x.gesamt))
                z.append("• \(datum)  \(x.thema)  \(x.richtig)/\(x.gesamt)  \(st)")
            }
        }

        var knifflig: [(String, Int)] = []
        for w in woerter {
            let f = stand.eintrag(w, c).f
            if f > 0 { knifflig.append((w.texte[c] ?? "", f)) }
        }
        knifflig.sort { $0.1 > $1.1 }
        if !knifflig.isEmpty {
            var teile: [String] = []
            for k in knifflig.prefix(3) { teile.append("\(k.0) (\(k.1)×)") }
            z.append(linie)
            z.append("🔎 Knifflig: " + teile.joined(separator: " · "))
        }
        z.append(linie)
        z.append("Dranbleiben, Champion! 💛💙")
        return z.joined(separator: "\n")
    }

    // MARK: Familiencode

    static func familiencode(_ code: String) -> String {
        [
            "🔐 \(logo) · Familiencode",
            linie,
            code,
            linie,
            "So verbindest du dein Gerät:",
            "1️⃣ App YEM1N öffnen",
            "2️⃣ „Kind“ oder „Eltern“ wählen",
            "3️⃣ Code eingeben",
            "",
            "Bitte nicht weitergeben, der Code gehört nur eurer Familie. 💛💙"
        ].joined(separator: "\n")
    }
}


// ============================================================
// MARK: - Cloud: Joker, Ergebnisse und Mitteilungen (CloudKit)
// ============================================================

extension Notification.Name {
    nonisolated static let cloudPush = Notification.Name("yem1nCloudPush")
}

// Registriert das Gerät für Mitteilungen und meldet eingehende CloudKit-Pushes an die App.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }

    nonisolated func application(_ application: UIApplication,
                                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        NotificationCenter.default.post(name: .cloudPush, object: nil)
        return .newData
    }
}

// MARK: Datenmodelle aus der Cloud

struct CloudAntwort: Identifiable {
    let id: String
    let anfrageID: String
    let absender: String
    let emoji: String
    let text: String
    let erstellt: Date
    var daumen: Bool
}

struct CloudAnfrage: Identifiable {
    let id: String
    let kind: String
    let fach: String
    let uebung: String
    let text: String
    let erstellt: Date
    var antworten: [CloudAntwort]
}

@Observable
final class CloudStatus {
    static let shared = CloudStatus()
    var meldung = ""
    var arbeitet = false
}

// MARK: CloudKit-Zugriff

enum CloudDienst {
    static var db: CKDatabase { CKContainer.default().publicCloudDatabase }

    // nil bedeutet: iCloud ist bereit, sonst steht hier der Grund
    static func kontoProblem() async -> String? {
        do {
            let s = try await CKContainer.default().accountStatus()
            if s == .available { return nil }
            return "iCloud ist auf diesem Gerät nicht verfügbar. Bitte in den Einstellungen bei iCloud anmelden."
        } catch {
            return "iCloud-Fehler: \(error.localizedDescription)"
        }
    }

    static func fehlertext(_ error: Error) -> String {
        let t = error.localizedDescription
        if t.contains("queryable") || t.contains("not marked") {
            return "Im CloudKit Dashboard fehlt ein Index (Feld familienCode, Typ Queryable). \(t)"
        }
        if t.contains("record type") {
            return "Der Datensatztyp gibt es noch nicht. Bitte auf Cloud neu einrichten tippen. \(t)"
        }
        return t
    }

    // MARK: Lesen

    static func holeRecords(_ typ: String, code: String, limit: Int = 200) async throws -> [CKRecord] {
        let q = CKQuery(recordType: typ, predicate: NSPredicate(format: "familienCode == %@", code))
        let antwort = try await db.records(matching: q, resultsLimit: limit)
        var liste: [CKRecord] = []
        for (_, ergebnis) in antwort.matchResults {
            if let r = try? ergebnis.get() { liste.append(r) }
        }
        return liste
    }

    static func ladeJoker(code: String) async throws -> [CloudAnfrage] {
        let anfragen = try await holeRecords("JokerAnfrage", code: code)
        let antworten = (try? await holeRecords("JokerAntwort", code: code)) ?? []
        let daumen = (try? await holeRecords("JokerDaumen", code: code)) ?? []

        var daumenIDs = Set<String>()
        for d in daumen {
            if let id = d["antwortID"] as? String { daumenIDs.insert(id) }
        }
        var alle: [CloudAntwort] = []
        for r in antworten {
            alle.append(CloudAntwort(id: r.recordID.recordName,
                                     anfrageID: (r["anfrageID"] as? String) ?? "",
                                     absender: (r["absender"] as? String) ?? "?",
                                     emoji: (r["emoji"] as? String) ?? "🙂",
                                     text: (r["text"] as? String) ?? "",
                                     erstellt: r.creationDate ?? Date.distantPast,
                                     daumen: daumenIDs.contains(r.recordID.recordName)))
        }
        var liste: [CloudAnfrage] = []
        for r in anfragen {
            let id = r.recordID.recordName
            let meine = alle.filter { $0.anfrageID == id }.sorted { $0.erstellt < $1.erstellt }
            liste.append(CloudAnfrage(id: id,
                                      kind: (r["kind"] as? String) ?? "Kind",
                                      fach: (r["fach"] as? String) ?? "",
                                      uebung: (r["uebung"] as? String) ?? "",
                                      text: (r["text"] as? String) ?? "",
                                      erstellt: r.creationDate ?? Date.distantPast,
                                      antworten: meine))
        }
        return liste.sorted { $0.erstellt > $1.erstellt }
    }

    // MARK: Schreiben

    static func sendeJoker(code: String, kind: String, fach: String, uebung: String, text: String) async throws {
        let r = CKRecord(recordType: "JokerAnfrage")
        r["familienCode"] = code as CKRecordValue
        r["kind"] = kind as CKRecordValue
        r["fach"] = fach as CKRecordValue
        r["uebung"] = uebung as CKRecordValue
        r["text"] = text as CKRecordValue
        r["status"] = "offen" as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeAntwort(code: String, anfrageID: String, absender: String, emoji: String, text: String) async throws {
        let r = CKRecord(recordType: "JokerAntwort")
        r["familienCode"] = code as CKRecordValue
        r["anfrageID"] = anfrageID as CKRecordValue
        r["absender"] = absender as CKRecordValue
        r["emoji"] = emoji as CKRecordValue
        r["text"] = text as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeDaumen(code: String, anfrageID: String, antwortID: String, absender: String) async throws {
        let id = CKRecord.ID(recordName: "daumen-" + antwortID)
        let r = CKRecord(recordType: "JokerDaumen", recordID: id)
        r["familienCode"] = code as CKRecordValue
        r["anfrageID"] = anfrageID as CKRecordValue
        r["antwortID"] = antwortID as CKRecordValue
        r["absender"] = absender as CKRecordValue
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // Daumen war schon vergeben
        }
    }

    static func sendeErgebnis(code: String, e: RundenErgebnis) async throws {
        let id = CKRecord.ID(recordName: "erg-" + e.eintragID)
        let r = CKRecord(recordType: "RundenErgebnis", recordID: id)
        r["familienCode"] = code as CKRecordValue
        r["eintragID"] = e.eintragID as CKRecordValue
        r["klasse"] = e.klasse as CKRecordValue
        r["fach"] = e.fach as CKRecordValue
        r["arbeit"] = e.arbeit as CKRecordValue
        r["uebung"] = e.uebung as CKRecordValue
        r["richtig"] = e.richtig as CKRecordValue
        r["gesamt"] = e.gesamt as CKRecordValue
        r["angesehen"] = e.angesehen as CKRecordValue
        r["sterne"] = e.sterne as CKRecordValue
        r["zeitpunkt"] = e.zeitpunkt as CKRecordValue
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // Ergebnis ist schon in der Cloud
        }
    }

    // MARK: Einrichtung (Datensatztypen anlegen und Mitteilungen abonnieren)

    private static func schemaBeispiel(_ typ: String, _ felder: [String: CKRecordValue]) async throws {
        let id = CKRecord.ID(recordName: "schema-" + typ)
        let r = CKRecord(recordType: typ, recordID: id)
        for (k, v) in felder { r[k] = v }
        do {
            _ = try await db.save(r)
        } catch let fehler as CKError where fehler.code == .serverRecordChanged {
            // gibt es schon
        }
    }

    static func schemaAnlegen() async throws {
        let code = "SCHEMA" as CKRecordValue
        try await schemaBeispiel("JokerAnfrage", ["familienCode": code, "kind": "Kind" as CKRecordValue,
                                                  "fach": "Mathe" as CKRecordValue, "uebung": "Test" as CKRecordValue,
                                                  "text": "Test" as CKRecordValue, "status": "offen" as CKRecordValue])
        try await schemaBeispiel("JokerAntwort", ["familienCode": code, "anfrageID": "x" as CKRecordValue,
                                                  "absender": "Test" as CKRecordValue, "emoji": "🙂" as CKRecordValue,
                                                  "text": "Test" as CKRecordValue])
        try await schemaBeispiel("JokerDaumen", ["familienCode": code, "anfrageID": "x" as CKRecordValue,
                                                 "antwortID": "x" as CKRecordValue, "absender": "Test" as CKRecordValue])
        try await schemaBeispiel("RundenErgebnis", ["familienCode": code, "eintragID": "schema" as CKRecordValue,
                                                   "klasse": "Test" as CKRecordValue, "fach": "Test" as CKRecordValue,
                                                   "arbeit": "Test" as CKRecordValue, "uebung": "Test" as CKRecordValue,
                                                   "richtig": 1 as CKRecordValue, "gesamt": 1 as CKRecordValue,
                                                   "angesehen": 0 as CKRecordValue, "sterne": 3 as CKRecordValue,
                                                   "zeitpunkt": Date() as CKRecordValue])
    }

    static func abo(typ: String, code: String, text: String) async throws {
        let predicate = NSPredicate(format: "familienCode == %@", code)
        let abo = CKQuerySubscription(recordType: typ, predicate: predicate,
                                      subscriptionID: "\(typ)-\(code)",
                                      options: [.firesOnRecordCreation])
        let info = CKSubscription.NotificationInfo()
        info.alertBody = text
        info.soundName = "default"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        abo.notificationInfo = info
        _ = try await db.save(abo)
    }

    static func einrichten(code: String, rolle: String) async -> String {
        if let problem = await kontoProblem() { return problem }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        do {
            try await schemaAnlegen()
        } catch {
            return "Datensatztypen anlegen nicht möglich: \(fehlertext(error))"
        }
        do {
            if rolle == "eltern" {
                try await abo(typ: "JokerAnfrage", code: code,
                              text: "🃏 Joker-Alarm! Dein Kind braucht Hilfe. Tippe und hilf als Erste:r!")
                try await abo(typ: "RundenErgebnis", code: code,
                              text: "🏆 Dein Kind hat eine Runde geschafft!")
            } else {
                try await abo(typ: "JokerAntwort", code: code,
                              text: "💡 Du hast einen Tipp bekommen! Schau im Tab Joker nach.")
            }
        } catch {
            return "Mitteilungen einrichten nicht möglich: \(fehlertext(error))"
        }
        return "Cloud ist bereit. Mitteilungen sind eingerichtet."
    }
}

// MARK: Ergebnisse senden und holen

enum CloudSync {
    private static var code: String { UserDefaults.standard.string(forKey: "familienCode") ?? "" }
    private static var modus: String { UserDefaults.standard.string(forKey: "modus") ?? "" }

    static func anstossen(_ context: ModelContext) {
        Task { await sendeOffene(context) }
    }

    // Kind-Gerät: alle noch nicht gesendeten Ergebnisse hochladen
    static func sendeOffene(_ context: ModelContext) async {
        guard modus == "kind", Familiencode.istGueltig(code) else { return }
        let beschreibung = FetchDescriptor<RundenErgebnis>(
            predicate: #Predicate { $0.quelle == "lokal" && $0.gesendet == false })
        guard let offene = try? context.fetch(beschreibung), !offene.isEmpty else { return }
        for e in offene {
            do {
                try await CloudDienst.sendeErgebnis(code: code, e: e)
                e.gesendet = true
            } catch {
                CloudStatus.shared.meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
                break
            }
        }
        try? context.save()
    }

    // Eltern-Gerät: neue Ergebnisse der Kinder abholen
    static func holeErgebnisse(_ context: ModelContext) async {
        guard modus == "eltern", Familiencode.istGueltig(code) else { return }
        do {
            let records = try await CloudDienst.holeRecords("RundenErgebnis", code: code, limit: 300)
            let vorhanden = (try? context.fetch(FetchDescriptor<RundenErgebnis>())) ?? []
            var ids = Set<String>()
            for v in vorhanden { ids.insert(v.eintragID) }
            for r in records {
                guard let id = r["eintragID"] as? String, !ids.contains(id) else { continue }
                let e = RundenErgebnis(klasse: (r["klasse"] as? String) ?? "",
                                       fach: (r["fach"] as? String) ?? "",
                                       arbeit: (r["arbeit"] as? String) ?? "",
                                       uebung: (r["uebung"] as? String) ?? "",
                                       richtig: (r["richtig"] as? Int) ?? 0,
                                       gesamt: (r["gesamt"] as? Int) ?? 0,
                                       angesehen: (r["angesehen"] as? Int) ?? 0,
                                       zeitpunkt: (r["zeitpunkt"] as? Date) ?? (r.creationDate ?? Date.now),
                                       quelle: "cloud")
                e.eintragID = id
                context.insert(e)
                ids.insert(id)
            }
            try? context.save()
        } catch {
            CloudStatus.shared.meldung = "Ergebnisse holen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }

    // Wird beim Öffnen der App, bei Mitteilungen und beim Aktualisieren aufgerufen
    nonisolated(unsafe) private static var letzterLauf = Date.distantPast

    static func aktiv(_ context: ModelContext, erzwingen: Bool = false) async {
        if !erzwingen && Date().timeIntervalSince(letzterLauf) < 5 { return }
        letzterLauf = Date()
        if modus == "kind" { await sendeOffene(context) }
        if modus == "eltern" { await holeErgebnisse(context) }
        if !modus.isEmpty { await JokerCloud.shared.aktualisieren() }
    }
}

// MARK: Joker: Speicher der Cloud-Anfragen

@Observable
final class JokerCloud {
    static let shared = JokerCloud()
    var anfragen: [CloudAnfrage] = []
    var laedt = false
    var fehler = ""

    func aktualisieren() async {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) else {
            fehler = "Noch kein Familiencode."
            return
        }
        laedt = true
        do {
            anfragen = try await CloudDienst.ladeJoker(code: code)
            fehler = ""
        } catch {
            fehler = "Laden nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        laedt = false
    }

    // Punkte aus der Cloud: erste Person +3, zweite +1, Daumen vom Kind +2
    func punkte(name: String, seit: Date?) -> Int {
        var summe = 0
        for a in anfragen {
            let sortiert = a.antworten.sorted { $0.erstellt < $1.erstellt }
            var reihenfolge: [String] = []
            for x in sortiert where !reihenfolge.contains(x.absender) {
                reihenfolge.append(x.absender)
            }
            for (platz, person) in reihenfolge.enumerated() where person == name {
                let zeit = sortiert.first(where: { $0.absender == person })?.erstellt ?? Date.distantPast
                let zaehlt = (seit == nil) || (zeit >= (seit ?? Date.distantPast))
                if zaehlt {
                    if platz == 0 { summe += 3 }
                    if platz == 1 { summe += 1 }
                }
            }
            for x in sortiert where x.absender == name && x.daumen {
                let zaehlt = (seit == nil) || (x.erstellt >= (seit ?? Date.distantPast))
                if zaehlt { summe += 2 }
            }
        }
        return summe
    }
}

// Kind-Gerät: Joker über die Cloud schicken. Gibt false zurück, wenn es nicht geklappt hat.
enum JokerSender {
    static func sende(text: String, fach: String, uebung: String) async -> Bool {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) else { return false }
        if await CloudDienst.kontoProblem() != nil { return false }
        let name = UserDefaults.standard.string(forKey: "kindName") ?? ""
        do {
            try await CloudDienst.sendeJoker(code: code, kind: name.isEmpty ? "Kind" : name,
                                             fach: fach, uebung: uebung, text: text)
            await JokerCloud.shared.aktualisieren()
            return true
        } catch {
            JokerCloud.shared.fehler = "Joker senden nicht möglich: \(CloudDienst.fehlertext(error))"
            return false
        }
    }
}

// MARK: Eltern: Joker-Postfach

struct JokerPostfachView: View {
    private let cloud = JokerCloud.shared
    @State private var antwortAuf: CloudAnfrage? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Joker-Postfach")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                if cloud.laedt { ProgressView().tint(Theme.gelb) }
                Button { Task { await cloud.aktualisieren() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.gelb)
                }
            }
            if !cloud.fehler.isEmpty {
                Text(cloud.fehler)
                    .font(.footnote)
                    .foregroundStyle(Theme.koralle)
            }
            if cloud.anfragen.isEmpty && cloud.fehler.isEmpty {
                Text("Noch keine Joker-Anfrage. Sobald dein Kind einen Joker nutzt, bekommst du eine Mitteilung und siehst sie hier.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            ForEach(Array(cloud.anfragen.prefix(8))) { a in
                karte(a)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
        .task { await cloud.aktualisieren() }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await cloud.aktualisieren() }
        }
        .sheet(item: $antwortAuf) { a in
            JokerAntwortSheet(anfrage: a)
                .preferredColorScheme(.dark)
                .tint(Theme.gelb)
        }
    }

    private func karte(_ a: CloudAnfrage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🃏 \(a.kind)")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Text(a.erstellt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            Text(a.text)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            ForEach(a.antworten) { x in
                HStack(alignment: .top, spacing: 6) {
                    Text(x.emoji)
                    Text("\(x.absender): \(x.text)")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                    if x.daumen { Text("👍") }
                }
            }
            Button { antwortAuf = a } label: {
                Text(a.antworten.isEmpty ? "Jetzt helfen" : "Auch antworten")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
        }
        .padding(14)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct JokerAntwortSheet: View {
    let anfrage: CloudAnfrage
    @Environment(\.dismiss) private var dismiss
    @AppStorage("familienCode") private var familienCode = ""
    @AppStorage("jokerIch") private var jokerIch = ""
    @State private var text = ""
    @State private var sendet = false
    @State private var meldung = ""
    private let joker = JokerStand.shared

    private var tipps: [String] {
        if anfrage.fach == "Mathe" {
            return ["💡 Zerlege die Aufgabe in kleine Schritte.",
                    "🔁 Denk an die Umkehraufgabe.",
                    "✋ Zeichne es dir auf oder nimm die Finger zu Hilfe.",
                    "🧮 Fang mit einer Aufgabe an, die du schon kannst.",
                    "📖 Lies die Aufgabe noch einmal in Ruhe."]
        }
        return ["🔊 Sprich das Wort laut aus und höre genau hin.",
                "🖼️ Stell dir ein Bild dazu vor.",
                "📖 Schau in der Wortliste unter dem Thema nach.",
                "🔁 Erinnerst du dich an ein ähnliches Wort?",
                "🌟 Rate mutig, du schaffst das!"]
    }

    private var ich: JokerMitglied? {
        joker.mitglieder.first(where: { $0.id.uuidString == jokerIch }) ?? joker.mitglieder.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("🃏 \(anfrage.kind) braucht Hilfe")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text(anfrage.text)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        if !anfrage.antworten.isEmpty {
                            Text("Schon geantwortet")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.textSanft)
                            ForEach(anfrage.antworten) { x in
                                Text("\(x.emoji) \(x.absender): \(x.text)")
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }

                        Text("Tipp-Karten")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textSanft)
                        ForEach(tipps, id: \.self) { t in
                            Button { text = t } label: {
                                Text(t)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Color.white)
                                    .multilineTextAlignment(.leading)
                                    .padding(12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(TastenStil())
                        }

                        TextField("Oder schreibe deinen eigenen Tipp", text: $text, axis: .vertical)
                            .lineLimit(2...5)
                            .padding(14)
                            .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text("Bitte nicht die Lösung verraten. Dafür gibt es Punktabzug.")
                            .font(.footnote)
                            .foregroundStyle(Theme.himmel)

                        if !meldung.isEmpty {
                            Text(meldung).font(.footnote).foregroundStyle(Theme.koralle)
                        }

                        GelberKnopf(titel: sendet ? "Sende ..." : "Tipp senden") { sende() }
                            .padding(.horizontal, -24)
                            .disabled(sendet || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Hilf mit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Schließen") { dismiss() } }
            }
        }
    }

    private func sende() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let m = ich else { return }
        sendet = true
        meldung = ""
        Task {
            do {
                try await CloudDienst.sendeAntwort(code: familienCode, anfrageID: anfrage.id,
                                                   absender: m.name, emoji: m.emoji, text: t)
                await JokerCloud.shared.aktualisieren()
                Haptik.erfolg()
                dismiss()
            } catch {
                meldung = "Senden nicht möglich: \(CloudDienst.fehlertext(error))"
            }
            sendet = false
        }
    }
}

// MARK: Kind: Joker-Tab mit den Tipps der Familie

struct KindJokerView: View {
    private let cloud = JokerCloud.shared
    private let joker = JokerStand.shared
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("familienCode") private var familienCode = ""

    private var meinName: String { kindName.isEmpty ? "Kind" : kindName }
    private var meine: [CloudAnfrage] { cloud.anfragen.filter { $0.kind == meinName } }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        namenFeld
                        if !cloud.fehler.isEmpty {
                            Text(cloud.fehler).font(.footnote).foregroundStyle(Theme.koralle)
                        }
                        if meine.isEmpty {
                            Text("Noch kein Joker benutzt. Wenn du bei einer Aufgabe nicht weiter kannst, tippe auf 🃏 Joker. Deine Familie bekommt sofort eine Mitteilung und schickt dir Tipps.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSanft)
                        }
                        ForEach(Array(meine.prefix(10))) { a in
                            karte(a)
                        }
                        CloudStatusKarte()
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await cloud.aktualisieren() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await cloud.aktualisieren() }
            .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
                Task { await cloud.aktualisieren() }
            }
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Joker")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text("Heute übrig: \(joker.uebrigHeute) von \(joker.limitProTag)")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var namenFeld: some View {
        HStack(spacing: 10) {
            Text("Mein Name")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
            TextField("zum Beispiel Yemin", text: $kindName)
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func karte(_ a: CloudAnfrage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(a.fach.isEmpty ? "Joker" : a.fach)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Text(a.erstellt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            Text(a.text)
                .font(.system(.body, design: .rounded).weight(.semibold))
                .foregroundStyle(Color.white)
            if a.antworten.isEmpty {
                Text("Noch kein Tipp. Gleich kommt Hilfe!")
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
            ForEach(a.antworten) { x in
                HStack(alignment: .top, spacing: 8) {
                    Text(x.emoji).font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(x.absender)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text(x.text)
                            .font(.subheadline)
                            .foregroundStyle(Color.white)
                    }
                    Spacer()
                    if x.daumen {
                        Text("👍")
                    } else {
                        Button { daumen(a, x) } label: {
                            Text("👍 Hat geholfen")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.gelb, in: Capsule())
                        }
                        .buttonStyle(TastenStil())
                    }
                }
                .padding(10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 24)
    }

    private func daumen(_ a: CloudAnfrage, _ x: CloudAntwort) {
        Task {
            try? await CloudDienst.sendeDaumen(code: familienCode, anfrageID: a.id,
                                               antwortID: x.id, absender: x.absender)
            Haptik.erfolg()
            await cloud.aktualisieren()
        }
    }
}

// MARK: Status und Neu-Einrichtung der Cloud

struct CloudStatusKarte: View {
    private let status = CloudStatus.shared
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""
    @Environment(\.modelContext) private var context

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cloud-Status")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(status.meldung.isEmpty ? "Noch nicht geprüft." : status.meldung)
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            if !Familiencode.istGueltig(familienCode) {
                Text("Es fehlt noch ein Familiencode (Einstellungen).")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.koralle)
            }
            Button {
                Task {
                    status.arbeitet = true
                    status.meldung = "Cloud wird eingerichtet ..."
                    let ergebnis = await CloudDienst.einrichten(code: familienCode, rolle: modus)
                    status.meldung = ergebnis
                    if ergebnis.hasPrefix("Cloud ist bereit") {
                        UserDefaults.standard.set(modus + "|" + familienCode, forKey: "cloudEingerichtet")
                    }
                    await CloudSync.aktiv(context, erzwingen: true)
                    status.arbeitet = false
                }
            } label: {
                Text(status.arbeitet ? "Bitte warten ..." : "Cloud neu einrichten und prüfen")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(status.arbeitet || !Familiencode.istGueltig(familienCode))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}


// MARK: - Eingebauter Sprachkatalog (Englisch und Türkisch)

enum SprachKatalogDaten {
    static let json = #"""
{
 "typ": "sprachkatalog",
 "version": 1,
 "titel": "YEM1N Sprachen",
 "sprachen": {"de": {"name": "Deutsch", "flagge": "🇩🇪", "sprachcode": "de-DE"}, "en": {"name": "Englisch", "flagge": "🇬🇧", "sprachcode": "en-GB"}, "tr": {"name": "Türkisch", "flagge": "🇹🇷", "sprachcode": "tr-TR"}},
 "lernsprachen": ["en", "tr"],
 "themen": [
  {
   "id": "hallo", "titel": "Hallo & Danke", "emoji": "👋", "stufe": 1,
   "woerter": [
    {"emoji": "👋", "de": "Hallo", "en": "hello", "tr": "merhaba", "alt": {"en": ["hi"]}},
    {"emoji": "🚶", "de": "Tschüss", "en": "goodbye", "tr": "hoşça kal", "alt": {"en": ["bye"], "tr": ["güle güle"]}, "hinweis": "Wer geht, sagt „hoşça kal“. Wer bleibt, sagt „güle güle“."},
    {"emoji": "✅", "de": "ja", "en": "yes", "tr": "evet"},
    {"emoji": "❌", "de": "nein", "en": "no", "tr": "hayır"},
    {"emoji": "🙏", "de": "Danke", "en": "thank you", "tr": "teşekkürler", "alt": {"en": ["thanks"], "tr": ["teşekkür ederim", "sağ ol"]}},
    {"emoji": "🙋", "de": "bitte", "en": "please", "tr": "lütfen"},
    {"emoji": "😔", "de": "Entschuldigung", "en": "sorry", "tr": "özür dilerim", "alt": {"tr": ["pardon"]}},
    {"emoji": "🧑‍🤝‍🧑", "de": "der Freund", "en": "friend", "tr": "arkadaş"},
    {"emoji": "🏷️", "de": "der Name", "en": "name", "tr": "ad", "alt": {"tr": ["isim"]}}
   ]
  },
  {
   "id": "zahl0", "titel": "Zahlen 0 bis 10", "emoji": "🔢", "stufe": 1,
   "woerter": [
    {"emoji": "0️⃣", "de": "null", "en": "zero", "tr": "sıfır"},
    {"emoji": "1️⃣", "de": "eins", "en": "one", "tr": "bir"},
    {"emoji": "2️⃣", "de": "zwei", "en": "two", "tr": "iki"},
    {"emoji": "3️⃣", "de": "drei", "en": "three", "tr": "üç"},
    {"emoji": "4️⃣", "de": "vier", "en": "four", "tr": "dört"},
    {"emoji": "5️⃣", "de": "fünf", "en": "five", "tr": "beş"},
    {"emoji": "6️⃣", "de": "sechs", "en": "six", "tr": "altı"},
    {"emoji": "7️⃣", "de": "sieben", "en": "seven", "tr": "yedi"},
    {"emoji": "8️⃣", "de": "acht", "en": "eight", "tr": "sekiz"},
    {"emoji": "9️⃣", "de": "neun", "en": "nine", "tr": "dokuz"},
    {"emoji": "🔟", "de": "zehn", "en": "ten", "tr": "on"}
   ]
  },
  {
   "id": "farben", "titel": "Farben", "emoji": "🎨", "stufe": 1,
   "woerter": [
    {"emoji": "🔴", "de": "rot", "en": "red", "tr": "kırmızı"},
    {"emoji": "🔵", "de": "blau", "en": "blue", "tr": "mavi"},
    {"emoji": "🟡", "de": "gelb", "en": "yellow", "tr": "sarı"},
    {"emoji": "🟢", "de": "grün", "en": "green", "tr": "yeşil"},
    {"emoji": "🟠", "de": "orange", "en": "orange", "tr": "turuncu"},
    {"emoji": "🟣", "de": "lila", "en": "purple", "tr": "mor"},
    {"emoji": "⚫", "de": "schwarz", "en": "black", "tr": "siyah"},
    {"emoji": "⚪", "de": "weiß", "en": "white", "tr": "beyaz"},
    {"emoji": "🟤", "de": "braun", "en": "brown", "tr": "kahverengi"},
    {"emoji": "🎀", "de": "rosa", "en": "pink", "tr": "pembe"},
    {"emoji": "🩶", "de": "grau", "en": "grey", "tr": "gri", "alt": {"en": ["gray"]}}
   ]
  },
  {
   "id": "haustiere", "titel": "Haustiere & Bauernhof", "emoji": "🐶", "stufe": 1,
   "woerter": [
    {"emoji": "🐶", "de": "der Hund", "en": "dog", "tr": "köpek"},
    {"emoji": "🐱", "de": "die Katze", "en": "cat", "tr": "kedi"},
    {"emoji": "🐦", "de": "der Vogel", "en": "bird", "tr": "kuş"},
    {"emoji": "🐟", "de": "der Fisch", "en": "fish", "tr": "balık"},
    {"emoji": "🐴", "de": "das Pferd", "en": "horse", "tr": "at"},
    {"emoji": "🐮", "de": "die Kuh", "en": "cow", "tr": "inek"},
    {"emoji": "🐷", "de": "das Schwein", "en": "pig", "tr": "domuz"},
    {"emoji": "🐑", "de": "das Schaf", "en": "sheep", "tr": "koyun"},
    {"emoji": "🐔", "de": "das Huhn", "en": "chicken", "tr": "tavuk"},
    {"emoji": "🐭", "de": "die Maus", "en": "mouse", "tr": "fare"},
    {"emoji": "🐰", "de": "der Hase", "en": "rabbit", "tr": "tavşan"},
    {"emoji": "🦆", "de": "die Ente", "en": "duck", "tr": "ördek"}
   ]
  },
  {
   "id": "familie", "titel": "Familie", "emoji": "👨‍👩‍👧‍👦", "stufe": 1,
   "woerter": [
    {"emoji": "👩", "de": "die Mama", "en": "mum", "tr": "anne", "alt": {"en": ["mom", "mummy", "mother"]}},
    {"emoji": "👨", "de": "der Papa", "en": "dad", "tr": "baba", "alt": {"en": ["daddy", "father"]}},
    {"emoji": "👦", "de": "der Bruder", "en": "brother", "tr": "erkek kardeş"},
    {"emoji": "👧", "de": "die Schwester", "en": "sister", "tr": "kız kardeş"},
    {"emoji": "🧑", "de": "der große Bruder", "en": "big brother", "tr": "abi", "alt": {"en": ["older brother"], "tr": ["ağabey"]}},
    {"emoji": "👱‍♀️", "de": "die große Schwester", "en": "big sister", "tr": "abla", "alt": {"en": ["older sister"]}},
    {"emoji": "👵", "de": "die Oma", "en": "grandma", "tr": "anneanne", "alt": {"en": ["granny", "grandmother", "nan"], "tr": ["babaanne"]}, "hinweis": "Mamas Mutter heißt „anneanne“, Papas Mutter heißt „babaanne“."},
    {"emoji": "👴", "de": "der Opa", "en": "grandpa", "tr": "dede", "alt": {"en": ["grandad", "grandfather"]}},
    {"emoji": "🙋‍♀️", "de": "die Tante", "en": "aunt", "tr": "teyze", "alt": {"en": ["auntie"], "tr": ["hala"]}, "hinweis": "Mamas Schwester heißt „teyze“, Papas Schwester heißt „hala“."},
    {"emoji": "🙋‍♂️", "de": "der Onkel", "en": "uncle", "tr": "dayı", "alt": {"tr": ["amca"]}, "hinweis": "Mamas Bruder heißt „dayı“, Papas Bruder heißt „amca“."},
    {"emoji": "👶", "de": "das Baby", "en": "baby", "tr": "bebek"},
    {"emoji": "🧒", "de": "das Kind", "en": "child", "tr": "çocuk", "alt": {"en": ["kid"]}},
    {"emoji": "👨‍👩‍👧‍👦", "de": "die Familie", "en": "family", "tr": "aile"}
   ]
  },
  {
   "id": "koerper", "titel": "Körper", "emoji": "🧍", "stufe": 1,
   "woerter": [
    {"emoji": "🙂", "de": "der Kopf", "en": "head", "tr": "baş"},
    {"emoji": "👁️", "de": "das Auge", "en": "eye", "tr": "göz"},
    {"emoji": "👂", "de": "das Ohr", "en": "ear", "tr": "kulak"},
    {"emoji": "👃", "de": "die Nase", "en": "nose", "tr": "burun"},
    {"emoji": "👄", "de": "der Mund", "en": "mouth", "tr": "ağız"},
    {"emoji": "✋", "de": "die Hand", "en": "hand", "tr": "el"},
    {"emoji": "🦶", "de": "der Fuß", "en": "foot", "tr": "ayak"},
    {"emoji": "🦵", "de": "das Bein", "en": "leg", "tr": "bacak"},
    {"emoji": "💪", "de": "der Arm", "en": "arm", "tr": "kol"},
    {"emoji": "🦷", "de": "der Zahn", "en": "tooth", "tr": "diş"},
    {"emoji": "💇", "de": "die Haare", "en": "hair", "tr": "saç"},
    {"emoji": "❤️", "de": "das Herz", "en": "heart", "tr": "kalp"}
   ]
  },
  {
   "id": "obst", "titel": "Obst & Gemüse", "emoji": "🍎", "stufe": 1,
   "woerter": [
    {"emoji": "🍎", "de": "der Apfel", "en": "apple", "tr": "elma"},
    {"emoji": "🍌", "de": "die Banane", "en": "banana", "tr": "muz"},
    {"emoji": "🍐", "de": "die Birne", "en": "pear", "tr": "armut"},
    {"emoji": "🍇", "de": "die Traube", "en": "grape", "tr": "üzüm", "alt": {"en": ["grapes"]}},
    {"emoji": "🍓", "de": "die Erdbeere", "en": "strawberry", "tr": "çilek"},
    {"emoji": "🍉", "de": "die Wassermelone", "en": "watermelon", "tr": "karpuz"},
    {"emoji": "🍋", "de": "die Zitrone", "en": "lemon", "tr": "limon"},
    {"emoji": "🍒", "de": "die Kirsche", "en": "cherry", "tr": "kiraz"},
    {"emoji": "🍅", "de": "die Tomate", "en": "tomato", "tr": "domates"},
    {"emoji": "🥔", "de": "die Kartoffel", "en": "potato", "tr": "patates"},
    {"emoji": "🥕", "de": "die Karotte", "en": "carrot", "tr": "havuç"},
    {"emoji": "🥒", "de": "die Gurke", "en": "cucumber", "tr": "salatalık"}
   ]
  },
  {
   "id": "essen", "titel": "Essen & Trinken", "emoji": "🍞", "stufe": 1,
   "woerter": [
    {"emoji": "🍞", "de": "das Brot", "en": "bread", "tr": "ekmek"},
    {"emoji": "🥛", "de": "die Milch", "en": "milk", "tr": "süt"},
    {"emoji": "💧", "de": "das Wasser", "en": "water", "tr": "su"},
    {"emoji": "🍵", "de": "der Tee", "en": "tea", "tr": "çay"},
    {"emoji": "🧃", "de": "der Saft", "en": "juice", "tr": "meyve suyu"},
    {"emoji": "🧀", "de": "der Käse", "en": "cheese", "tr": "peynir"},
    {"emoji": "🥚", "de": "das Ei", "en": "egg", "tr": "yumurta"},
    {"emoji": "🍰", "de": "der Kuchen", "en": "cake", "tr": "pasta", "hinweis": "„pasta“ heißt auf Türkisch Kuchen. Nudeln heißen „makarna“."},
    {"emoji": "🍦", "de": "das Eis", "en": "ice cream", "tr": "dondurma", "alt": {"en": ["ice-cream"]}},
    {"emoji": "🍲", "de": "die Suppe", "en": "soup", "tr": "çorba"},
    {"emoji": "🥩", "de": "das Fleisch", "en": "meat", "tr": "et"},
    {"emoji": "🍯", "de": "der Honig", "en": "honey", "tr": "bal"},
    {"emoji": "🍫", "de": "die Schokolade", "en": "chocolate", "tr": "çikolata"},
    {"emoji": "🍕", "de": "die Pizza", "en": "pizza", "tr": "pizza"}
   ]
  },
  {
   "id": "wildtiere", "titel": "Wilde Tiere", "emoji": "🦁", "stufe": 2,
   "woerter": [
    {"emoji": "🦁", "de": "der Löwe", "en": "lion", "tr": "aslan"},
    {"emoji": "🐘", "de": "der Elefant", "en": "elephant", "tr": "fil"},
    {"emoji": "🐵", "de": "der Affe", "en": "monkey", "tr": "maymun"},
    {"emoji": "🐻", "de": "der Bär", "en": "bear", "tr": "ayı"},
    {"emoji": "🐺", "de": "der Wolf", "en": "wolf", "tr": "kurt"},
    {"emoji": "🦊", "de": "der Fuchs", "en": "fox", "tr": "tilki"},
    {"emoji": "🦒", "de": "die Giraffe", "en": "giraffe", "tr": "zürafa"},
    {"emoji": "🐯", "de": "der Tiger", "en": "tiger", "tr": "kaplan"},
    {"emoji": "🐍", "de": "die Schlange", "en": "snake", "tr": "yılan"},
    {"emoji": "🐸", "de": "der Frosch", "en": "frog", "tr": "kurbağa"},
    {"emoji": "🦋", "de": "der Schmetterling", "en": "butterfly", "tr": "kelebek"},
    {"emoji": "🐝", "de": "die Biene", "en": "bee", "tr": "arı"}
   ]
  },
  {
   "id": "zuhause", "titel": "Zuhause", "emoji": "🏠", "stufe": 2,
   "woerter": [
    {"emoji": "🏠", "de": "das Haus", "en": "house", "tr": "ev"},
    {"emoji": "🛋️", "de": "das Zimmer", "en": "room", "tr": "oda"},
    {"emoji": "🚪", "de": "die Tür", "en": "door", "tr": "kapı"},
    {"emoji": "🪟", "de": "das Fenster", "en": "window", "tr": "pencere"},
    {"emoji": "🍽️", "de": "der Tisch", "en": "table", "tr": "masa"},
    {"emoji": "🪑", "de": "der Stuhl", "en": "chair", "tr": "sandalye"},
    {"emoji": "🛏️", "de": "das Bett", "en": "bed", "tr": "yatak"},
    {"emoji": "🍳", "de": "die Küche", "en": "kitchen", "tr": "mutfak"},
    {"emoji": "🛁", "de": "das Bad", "en": "bathroom", "tr": "banyo"},
    {"emoji": "🌳", "de": "der Garten", "en": "garden", "tr": "bahçe"},
    {"emoji": "💡", "de": "die Lampe", "en": "lamp", "tr": "lamba"},
    {"emoji": "🔑", "de": "der Schlüssel", "en": "key", "tr": "anahtar"},
    {"emoji": "📺", "de": "der Fernseher", "en": "TV", "tr": "televizyon", "alt": {"en": ["television"]}},
    {"emoji": "🕐", "de": "die Uhr", "en": "clock", "tr": "saat"}
   ]
  },
  {
   "id": "schule", "titel": "Schule", "emoji": "🏫", "stufe": 2,
   "woerter": [
    {"emoji": "🏫", "de": "die Schule", "en": "school", "tr": "okul"},
    {"emoji": "👥", "de": "die Klasse", "en": "class", "tr": "sınıf"},
    {"emoji": "👩‍🏫", "de": "die Lehrerin", "en": "teacher", "tr": "öğretmen"},
    {"emoji": "🧑‍🎓", "de": "der Schüler", "en": "pupil", "tr": "öğrenci", "alt": {"en": ["student"]}},
    {"emoji": "📖", "de": "das Buch", "en": "book", "tr": "kitap"},
    {"emoji": "📓", "de": "das Heft", "en": "exercise book", "tr": "defter", "alt": {"en": ["notebook"]}},
    {"emoji": "✏️", "de": "der Bleistift", "en": "pencil", "tr": "kurşun kalem"},
    {"emoji": "🧽", "de": "der Radiergummi", "en": "rubber", "tr": "silgi", "alt": {"en": ["eraser"]}},
    {"emoji": "📏", "de": "das Lineal", "en": "ruler", "tr": "cetvel"},
    {"emoji": "✂️", "de": "die Schere", "en": "scissors", "tr": "makas"},
    {"emoji": "🎒", "de": "die Schultasche", "en": "school bag", "tr": "okul çantası", "alt": {"en": ["schoolbag", "bag"], "tr": ["çanta"]}},
    {"emoji": "📝", "de": "die Hausaufgaben", "en": "homework", "tr": "ödev"},
    {"emoji": "🔔", "de": "die Pause", "en": "break", "tr": "teneffüs", "alt": {"en": ["playtime"], "tr": ["ara"]}},
    {"emoji": "➗", "de": "die Mathe", "en": "maths", "tr": "matematik", "alt": {"en": ["math"]}}
   ]
  },
  {
   "id": "kleidung", "titel": "Kleidung", "emoji": "👕", "stufe": 2,
   "woerter": [
    {"emoji": "👕", "de": "das T-Shirt", "en": "t-shirt", "tr": "tişört"},
    {"emoji": "👖", "de": "die Hose", "en": "trousers", "tr": "pantolon", "alt": {"en": ["pants"]}},
    {"emoji": "👗", "de": "das Kleid", "en": "dress", "tr": "elbise"},
    {"emoji": "👟", "de": "die Schuhe", "en": "shoes", "tr": "ayakkabı"},
    {"emoji": "🧦", "de": "die Socken", "en": "socks", "tr": "çorap"},
    {"emoji": "🧢", "de": "die Mütze", "en": "hat", "tr": "şapka", "alt": {"en": ["cap"], "tr": ["bere"]}},
    {"emoji": "🧥", "de": "die Jacke", "en": "jacket", "tr": "ceket"},
    {"emoji": "🧶", "de": "der Pullover", "en": "jumper", "tr": "kazak", "alt": {"en": ["sweater", "pullover"]}},
    {"emoji": "🧤", "de": "die Handschuhe", "en": "gloves", "tr": "eldiven"},
    {"emoji": "🧣", "de": "der Schal", "en": "scarf", "tr": "atkı"},
    {"emoji": "👓", "de": "die Brille", "en": "glasses", "tr": "gözlük"}
   ]
  },
  {
   "id": "wetter", "titel": "Wetter & Natur", "emoji": "☀️", "stufe": 2,
   "woerter": [
    {"emoji": "☀️", "de": "die Sonne", "en": "sun", "tr": "güneş"},
    {"emoji": "🌙", "de": "der Mond", "en": "moon", "tr": "ay"},
    {"emoji": "⭐", "de": "der Stern", "en": "star", "tr": "yıldız"},
    {"emoji": "☁️", "de": "die Wolke", "en": "cloud", "tr": "bulut"},
    {"emoji": "🌧️", "de": "der Regen", "en": "rain", "tr": "yağmur"},
    {"emoji": "❄️", "de": "der Schnee", "en": "snow", "tr": "kar"},
    {"emoji": "💨", "de": "der Wind", "en": "wind", "tr": "rüzgâr", "alt": {"tr": ["rüzgar"]}},
    {"emoji": "🌸", "de": "die Blume", "en": "flower", "tr": "çiçek"},
    {"emoji": "🌳", "de": "der Baum", "en": "tree", "tr": "ağaç"},
    {"emoji": "🌊", "de": "das Meer", "en": "sea", "tr": "deniz"},
    {"emoji": "⛰️", "de": "der Berg", "en": "mountain", "tr": "dağ"},
    {"emoji": "🌤️", "de": "der Himmel", "en": "sky", "tr": "gökyüzü", "alt": {"tr": ["gök"]}},
    {"emoji": "🔥", "de": "das Feuer", "en": "fire", "tr": "ateş"}
   ]
  },
  {
   "id": "fahrzeuge", "titel": "Fahrzeuge", "emoji": "🚗", "stufe": 2,
   "woerter": [
    {"emoji": "🚗", "de": "das Auto", "en": "car", "tr": "araba", "alt": {"tr": ["otomobil"]}},
    {"emoji": "🚌", "de": "der Bus", "en": "bus", "tr": "otobüs"},
    {"emoji": "🚆", "de": "der Zug", "en": "train", "tr": "tren"},
    {"emoji": "🚲", "de": "das Fahrrad", "en": "bike", "tr": "bisiklet", "alt": {"en": ["bicycle"]}},
    {"emoji": "✈️", "de": "das Flugzeug", "en": "plane", "tr": "uçak", "alt": {"en": ["aeroplane", "airplane"]}},
    {"emoji": "🚢", "de": "das Schiff", "en": "ship", "tr": "gemi"},
    {"emoji": "⛵", "de": "das Boot", "en": "boat", "tr": "tekne"},
    {"emoji": "🚜", "de": "der Traktor", "en": "tractor", "tr": "traktör"},
    {"emoji": "🚒", "de": "das Feuerwehrauto", "en": "fire engine", "tr": "itfaiye arabası", "alt": {"en": ["fire truck"]}},
    {"emoji": "🚑", "de": "der Krankenwagen", "en": "ambulance", "tr": "ambulans"},
    {"emoji": "🏍️", "de": "das Motorrad", "en": "motorbike", "tr": "motosiklet", "alt": {"en": ["motorcycle"]}},
    {"emoji": "🚁", "de": "der Hubschrauber", "en": "helicopter", "tr": "helikopter"}
   ]
  },
  {
   "id": "stadt", "titel": "Stadt & Orte", "emoji": "🏙️", "stufe": 2,
   "woerter": [
    {"emoji": "🏙️", "de": "die Stadt", "en": "city", "tr": "şehir", "alt": {"tr": ["kent"]}},
    {"emoji": "🏘️", "de": "das Dorf", "en": "village", "tr": "köy"},
    {"emoji": "🛣️", "de": "die Straße", "en": "street", "tr": "sokak", "alt": {"en": ["road"], "tr": ["yol"]}},
    {"emoji": "🏞️", "de": "der Park", "en": "park", "tr": "park"},
    {"emoji": "🛝", "de": "der Spielplatz", "en": "playground", "tr": "oyun parkı"},
    {"emoji": "🛒", "de": "der Supermarkt", "en": "supermarket", "tr": "süpermarket", "alt": {"tr": ["market"]}},
    {"emoji": "🥖", "de": "die Bäckerei", "en": "bakery", "tr": "fırın", "alt": {"tr": ["ekmek fırını"]}},
    {"emoji": "🏥", "de": "das Krankenhaus", "en": "hospital", "tr": "hastane"},
    {"emoji": "🚉", "de": "der Bahnhof", "en": "station", "tr": "istasyon", "alt": {"en": ["train station", "railway station"], "tr": ["gar"]}},
    {"emoji": "🎬", "de": "das Kino", "en": "cinema", "tr": "sinema"},
    {"emoji": "🌉", "de": "die Brücke", "en": "bridge", "tr": "köprü"},
    {"emoji": "🏛️", "de": "das Museum", "en": "museum", "tr": "müze"}
   ]
  },
  {
   "id": "freizeit", "titel": "Spielen & Freizeit", "emoji": "🎮", "stufe": 2,
   "woerter": [
    {"emoji": "🧸", "de": "das Spielzeug", "en": "toy", "tr": "oyuncak"},
    {"emoji": "🏐", "de": "der Ball", "en": "ball", "tr": "top"},
    {"emoji": "⚽", "de": "der Fußball", "en": "football", "tr": "futbol", "alt": {"en": ["soccer"]}},
    {"emoji": "🪆", "de": "die Puppe", "en": "doll", "tr": "oyuncak bebek"},
    {"emoji": "🧩", "de": "das Puzzle", "en": "puzzle", "tr": "yapboz", "alt": {"tr": ["puzzle"]}},
    {"emoji": "🎮", "de": "das Spiel", "en": "game", "tr": "oyun"},
    {"emoji": "♟️", "de": "das Schach", "en": "chess", "tr": "satranç"},
    {"emoji": "🪁", "de": "der Drachen (zum Fliegen)", "en": "kite", "tr": "uçurtma"},
    {"emoji": "🎵", "de": "die Musik", "en": "music", "tr": "müzik"},
    {"emoji": "🎸", "de": "die Gitarre", "en": "guitar", "tr": "gitar"},
    {"emoji": "📱", "de": "das Handy", "en": "mobile phone", "tr": "cep telefonu", "alt": {"en": ["phone", "mobile", "cell phone"], "tr": ["telefon"]}},
    {"emoji": "💻", "de": "der Computer", "en": "computer", "tr": "bilgisayar"},
    {"emoji": "📷", "de": "die Kamera", "en": "camera", "tr": "kamera"},
    {"emoji": "🖼️", "de": "das Bild", "en": "picture", "tr": "resim"}
   ]
  },
  {
   "id": "wochentage", "titel": "Wochentage", "emoji": "📅", "stufe": 2, "bilder": false,
   "woerter": [
    {"de": "Montag", "en": "Monday", "tr": "Pazartesi"},
    {"de": "Dienstag", "en": "Tuesday", "tr": "Salı"},
    {"de": "Mittwoch", "en": "Wednesday", "tr": "Çarşamba"},
    {"de": "Donnerstag", "en": "Thursday", "tr": "Perşembe"},
    {"de": "Freitag", "en": "Friday", "tr": "Cuma"},
    {"de": "Samstag", "en": "Saturday", "tr": "Cumartesi"},
    {"de": "Sonntag", "en": "Sunday", "tr": "Pazar"}
   ]
  },
  {
   "id": "zahl20", "titel": "Zahlen 11 bis 20", "emoji": "🔢", "stufe": 2,
   "woerter": [
    {"emoji": "11", "de": "elf", "en": "eleven", "tr": "on bir"},
    {"emoji": "12", "de": "zwölf", "en": "twelve", "tr": "on iki"},
    {"emoji": "13", "de": "dreizehn", "en": "thirteen", "tr": "on üç"},
    {"emoji": "14", "de": "vierzehn", "en": "fourteen", "tr": "on dört"},
    {"emoji": "15", "de": "fünfzehn", "en": "fifteen", "tr": "on beş"},
    {"emoji": "16", "de": "sechzehn", "en": "sixteen", "tr": "on altı"},
    {"emoji": "17", "de": "siebzehn", "en": "seventeen", "tr": "on yedi"},
    {"emoji": "18", "de": "achtzehn", "en": "eighteen", "tr": "on sekiz"},
    {"emoji": "19", "de": "neunzehn", "en": "nineteen", "tr": "on dokuz"},
    {"emoji": "20", "de": "zwanzig", "en": "twenty", "tr": "yirmi"}
   ]
  },
  {
   "id": "monate", "titel": "Monate", "emoji": "🗓️", "stufe": 3, "bilder": false,
   "woerter": [
    {"de": "Januar", "en": "January", "tr": "Ocak"},
    {"de": "Februar", "en": "February", "tr": "Şubat"},
    {"de": "März", "en": "March", "tr": "Mart"},
    {"de": "April", "en": "April", "tr": "Nisan"},
    {"de": "Mai", "en": "May", "tr": "Mayıs"},
    {"de": "Juni", "en": "June", "tr": "Haziran"},
    {"de": "Juli", "en": "July", "tr": "Temmuz"},
    {"de": "August", "en": "August", "tr": "Ağustos"},
    {"de": "September", "en": "September", "tr": "Eylül"},
    {"de": "Oktober", "en": "October", "tr": "Ekim"},
    {"de": "November", "en": "November", "tr": "Kasım"},
    {"de": "Dezember", "en": "December", "tr": "Aralık"}
   ]
  },
  {
   "id": "zeit", "titel": "Jahreszeiten & Zeit", "emoji": "🌷", "stufe": 3,
   "woerter": [
    {"emoji": "🌷", "de": "der Frühling", "en": "spring", "tr": "ilkbahar", "alt": {"tr": ["bahar"]}},
    {"emoji": "🏖️", "de": "der Sommer", "en": "summer", "tr": "yaz"},
    {"emoji": "🍂", "de": "der Herbst", "en": "autumn", "tr": "sonbahar", "alt": {"en": ["fall"]}},
    {"emoji": "☃️", "de": "der Winter", "en": "winter", "tr": "kış"},
    {"de": "heute", "en": "today", "tr": "bugün"},
    {"de": "gestern", "en": "yesterday", "tr": "dün"},
    {"de": "morgen (der nächste Tag)", "en": "tomorrow", "tr": "yarın"},
    {"emoji": "🌅", "de": "der Morgen (früh)", "en": "morning", "tr": "sabah"},
    {"emoji": "🌇", "de": "der Abend", "en": "evening", "tr": "akşam"},
    {"emoji": "🌙", "de": "die Nacht", "en": "night", "tr": "gece"},
    {"emoji": "📆", "de": "die Woche", "en": "week", "tr": "hafta"},
    {"emoji": "🎆", "de": "das Jahr", "en": "year", "tr": "yıl"},
    {"emoji": "🌞", "de": "der Tag", "en": "day", "tr": "gün"}
   ]
  },
  {
   "id": "taetigkeiten", "titel": "Tätigkeiten", "emoji": "🏃", "stufe": 3,
   "woerter": [
    {"emoji": "🏃", "de": "laufen", "en": "run", "tr": "koşmak"},
    {"emoji": "🏊", "de": "schwimmen", "en": "swim", "tr": "yüzmek"},
    {"emoji": "🦘", "de": "springen", "en": "jump", "tr": "zıplamak"},
    {"emoji": "🍽️", "de": "essen", "en": "eat", "tr": "yemek"},
    {"emoji": "🥤", "de": "trinken", "en": "drink", "tr": "içmek"},
    {"emoji": "😴", "de": "schlafen", "en": "sleep", "tr": "uyumak"},
    {"emoji": "🎮", "de": "spielen", "en": "play", "tr": "oynamak"},
    {"emoji": "📖", "de": "lesen", "en": "read", "tr": "okumak"},
    {"emoji": "✍️", "de": "schreiben", "en": "write", "tr": "yazmak"},
    {"emoji": "🎤", "de": "singen", "en": "sing", "tr": "şarkı söylemek"},
    {"emoji": "💃", "de": "tanzen", "en": "dance", "tr": "dans etmek"},
    {"emoji": "😂", "de": "lachen", "en": "laugh", "tr": "gülmek"},
    {"emoji": "😢", "de": "weinen", "en": "cry", "tr": "ağlamak"},
    {"emoji": "🤝", "de": "helfen", "en": "help", "tr": "yardım etmek"}
   ]
  },
  {
   "id": "gegenteile", "titel": "Gegenteile", "emoji": "↔️", "stufe": 3,
   "woerter": [
    {"emoji": "🐘", "de": "groß", "en": "big", "tr": "büyük"},
    {"emoji": "🐜", "de": "klein", "en": "small", "tr": "küçük"},
    {"emoji": "🥵", "de": "heiß", "en": "hot", "tr": "sıcak"},
    {"emoji": "🥶", "de": "kalt", "en": "cold", "tr": "soğuk"},
    {"emoji": "🐇", "de": "schnell", "en": "fast", "tr": "hızlı"},
    {"emoji": "🐢", "de": "langsam", "en": "slow", "tr": "yavaş"},
    {"emoji": "🆕", "de": "neu", "en": "new", "tr": "yeni"},
    {"emoji": "🕰️", "de": "alt", "en": "old", "tr": "eski", "hinweis": "„eski“ sagt man bei Dingen. Bei Menschen heißt alt „yaşlı“."},
    {"emoji": "👍", "de": "gut", "en": "good", "tr": "iyi"},
    {"emoji": "👎", "de": "schlecht", "en": "bad", "tr": "kötü"},
    {"emoji": "😊", "de": "glücklich", "en": "happy", "tr": "mutlu"},
    {"emoji": "😔", "de": "traurig", "en": "sad", "tr": "üzgün"},
    {"emoji": "🤫", "de": "leise", "en": "quiet", "tr": "sessiz"},
    {"emoji": "🌺", "de": "schön", "en": "beautiful", "tr": "güzel", "alt": {"en": ["pretty", "nice"]}}
   ]
  },
  {
   "id": "zehner", "titel": "Zehnerzahlen bis 100", "emoji": "💯", "stufe": 3,
   "woerter": [
    {"emoji": "30", "de": "dreißig", "en": "thirty", "tr": "otuz"},
    {"emoji": "40", "de": "vierzig", "en": "forty", "tr": "kırk"},
    {"emoji": "50", "de": "fünfzig", "en": "fifty", "tr": "elli"},
    {"emoji": "60", "de": "sechzig", "en": "sixty", "tr": "altmış"},
    {"emoji": "70", "de": "siebzig", "en": "seventy", "tr": "yetmiş"},
    {"emoji": "80", "de": "achtzig", "en": "eighty", "tr": "seksen"},
    {"emoji": "90", "de": "neunzig", "en": "ninety", "tr": "doksan"},
    {"emoji": "100", "de": "hundert", "en": "hundred", "tr": "yüz"}
   ]
  },
  {
   "id": "saetze", "titel": "Kleine Sätze", "emoji": "💬", "stufe": 3, "bilder": false, "typ": "saetze",
   "woerter": [
    {"emoji": "🌅", "de": "Guten Morgen!", "en": "Good morning!", "tr": "Günaydın!"},
    {"emoji": "🌇", "de": "Guten Abend!", "en": "Good evening!", "tr": "İyi akşamlar!"},
    {"emoji": "🌙", "de": "Gute Nacht!", "en": "Good night!", "tr": "İyi geceler!"},
    {"emoji": "🙂", "de": "Wie geht es dir?", "en": "How are you?", "tr": "Nasılsın?"},
    {"emoji": "😊", "de": "Mir geht es gut.", "en": "I am fine.", "tr": "İyiyim.", "alt": {"en": ["I'm fine.", "I am good.", "I'm good."]}},
    {"emoji": "❓", "de": "Wie heißt du?", "en": "What is your name?", "tr": "Adın ne?", "alt": {"en": ["What's your name?"], "tr": ["Senin adın ne?", "Adın nedir?"]}},
    {"emoji": "🙋", "de": "Ich heiße Ali.", "en": "My name is Ali.", "tr": "Benim adım Ali.", "alt": {"tr": ["Adım Ali."]}},
    {"emoji": "🎂", "de": "Wie alt bist du?", "en": "How old are you?", "tr": "Kaç yaşındasın?"},
    {"emoji": "🔢", "de": "Ich bin acht Jahre alt.", "en": "I am eight years old.", "tr": "Ben sekiz yaşındayım.", "alt": {"en": ["I'm eight years old.", "I'm eight.", "I am eight."], "tr": ["Sekiz yaşındayım."]}},
    {"emoji": "🍽️", "de": "Ich habe Hunger.", "en": "I am hungry.", "tr": "Acıktım.", "alt": {"en": ["I'm hungry."], "tr": ["Karnım aç."]}},
    {"emoji": "🥤", "de": "Ich habe Durst.", "en": "I am thirsty.", "tr": "Susadım.", "alt": {"en": ["I'm thirsty."]}},
    {"emoji": "❤️", "de": "Ich liebe dich.", "en": "I love you.", "tr": "Seni seviyorum."},
    {"emoji": "🤷", "de": "Ich verstehe das nicht.", "en": "I do not understand.", "tr": "Anlamıyorum.", "alt": {"en": ["I don't understand.", "I do not understand that.", "I don't understand that."], "tr": ["Bunu anlamıyorum."]}},
    {"emoji": "🆘", "de": "Kannst du mir helfen?", "en": "Can you help me?", "tr": "Bana yardım edebilir misin?"},
    {"emoji": "🚻", "de": "Wo ist die Toilette?", "en": "Where is the toilet?", "tr": "Tuvalet nerede?"},
    {"emoji": "🧑‍🤝‍🧑", "de": "Das ist mein Freund.", "en": "This is my friend.", "tr": "Bu benim arkadaşım."},
    {"emoji": "🍕", "de": "Ich mag Pizza.", "en": "I like pizza.", "tr": "Pizzayı severim.", "alt": {"tr": ["Pizza severim."]}},
    {"emoji": "⚽", "de": "Ich spiele Fußball.", "en": "I play football.", "tr": "Futbol oynuyorum.", "alt": {"en": ["I play soccer."]}},
    {"emoji": "🔍", "de": "Was ist das?", "en": "What is this?", "tr": "Bu nedir?", "alt": {"en": ["What is that?", "What's this?"], "tr": ["Bu ne?"]}},
    {"emoji": "🥵", "de": "Heute ist es heiß.", "en": "It is hot today.", "tr": "Bugün hava sıcak.", "alt": {"en": ["It's hot today."]}},
    {"emoji": "👋", "de": "Bis morgen!", "en": "See you tomorrow!", "tr": "Yarın görüşürüz!"},
    {"emoji": "😊", "de": "Gern geschehen!", "en": "You are welcome!", "tr": "Rica ederim!", "alt": {"en": ["You're welcome!", "No problem!"]}},
    {"emoji": "🍀", "de": "Viel Glück!", "en": "Good luck!", "tr": "Bol şans!", "alt": {"tr": ["İyi şanslar!"]}},
    {"emoji": "🎉", "de": "Herzlichen Glückwunsch!", "en": "Congratulations!", "tr": "Tebrikler!"},
    {"emoji": "🎈", "de": "Alles Gute zum Geburtstag!", "en": "Happy birthday!", "tr": "Doğum günün kutlu olsun!", "alt": {"tr": ["İyi ki doğdun!"]}}
   ]
  }
 ]
}
"""#
}
