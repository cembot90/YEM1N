import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security

// MARK: - Design (Lacivert und Sari)

enum Theme {
    // Farbwelt wird in den Einstellungen gewählt: "blau" (Standard) oder "rosa"
    static var rosa: Bool = UserDefaults.standard.string(forKey: "farbwelt") == "rosa"

    static var gelb: Color {
        rosa ? Color(red: 1.0, green: 0.45, blue: 0.74) : Color(red: 1.0, green: 0.93, blue: 0.0)
    }
    static var navy: Color {
        rosa ? Color(red: 0.36, green: 0.07, blue: 0.31) : Color(red: 0.0, green: 0.125, blue: 0.357)
    }
    static var tiefNavy: Color {
        rosa ? Color(red: 0.14, green: 0.02, blue: 0.14) : Color(red: 0.0, green: 0.045, blue: 0.16)
    }
    static var glanz: Color {
        rosa ? Color(red: 0.92, green: 0.30, blue: 0.66) : Color(red: 0.16, green: 0.4, blue: 0.85)
    }
    static var himmel: Color {
        rosa ? Color(red: 0.80, green: 0.68, blue: 1.0) : Color(red: 0.45, green: 0.78, blue: 1.0)
    }
    static let koralle = Color(red: 1.0, green: 0.42, blue: 0.42)
    static let mint = Color(red: 0.45, green: 0.95, blue: 0.62)
    static let textSanft = Color.white.opacity(0.7)
}

struct HintergrundView: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.navy, Theme.tiefNavy],
                           startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Theme.glanz.opacity(0.35), .clear],
                           center: .top, startRadius: 0, endRadius: 420)
        }
        .ignoresSafeArea()
    }
}

struct GlasKarteStil: ViewModifier {
    let radius: CGFloat
    @AppStorage("glasEffekt") private var glas = false

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

// Eingabe für Textaufgaben (Deutsch): normale Tastatur, Umlaute und ß als Tasten
struct TextAntwortFeld: View {
    @Binding var text: String
    var onPruefen: () -> Void
    @FocusState private var fokus: Bool

    private let sonderzeichen = ["ä", "ö", "ü", "ß", "Ä", "Ö", "Ü"]

    var body: some View {
        VStack(spacing: 12) {
            TextField("Antwort", text: $text)
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($fokus)
                .onSubmit(onPruefen)
                .frame(minHeight: 62)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.gelb, lineWidth: 2.5)
                )
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(sonderzeichen, id: \.self) { z in
                    Button { text += z } label: {
                        Text(z)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .foregroundStyle(Color.white)
                            .background(Color.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TastenStil())
                }
            }
            .padding(.horizontal, 24)

            GelberKnopf(titel: "Prüfen", aktion: onPruefen)
        }
        .onAppear { fokus = true }
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
    var spezial: String = ""          // "", "fehlerheft", "training" oder "probe"
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
    var art: String = "zahl"          // zahl, rest, vergleich, mauer, text
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
    var quellKey: String = ""         // bei Kopien im Fehlerheft: Verweis auf die Originalaufgabe
    var gemeistert: Bool = false      // Fehler wurde im Fehlerheft richtig wiederholt
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
    var kind: String = ""

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
        self.kind = UserDefaults.standard.string(forKey: "kindName") ?? ""
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
    // Nur für art "wahl" (Vorschule): Bild, türkische Frage, große Zahl/Buchstabe, Folge, Antwortknöpfe
    let bild: String?
    let tr: String?
    let gross: String?
    let folge: [String]?
    let optionen: [String]?

    enum CodingKeys: String, CodingKey {
        case art, frage, rechnung, hinweis, erklaerung, antwort, antwort2, reihen
        case bild, tr, gross, folge, optionen
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
        bild = try c.decodeIfPresent(String.self, forKey: .bild)
        tr = try c.decodeIfPresent(String.self, forKey: .tr)
        gross = AufgabePaket.text(c, .gross)
        folge = try? c.decodeIfPresent([String].self, forKey: .folge)
        optionen = try? c.decodeIfPresent([String].self, forKey: .optionen)
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
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @State private var offenesPaket: ArbeitPaket?
    @State private var offenerText = ""
    @State private var zeigeOffen = false
    @State private var offenMeldung: String?
    @AppStorage("profilFertig") private var profilFertig = false

    var body: some View {
        Group {
            switch modus {
            case "kind": KindTabs()
            case "eltern": ElternTabs()
            default: ModusAuswahlView()
            }
        }
        .id(farbwelt)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(HintergrundView())
        .tint(Theme.gelb)
        .onOpenURL { url in
            guard url.isFileURL else { return }
            let zugriff = url.startAccessingSecurityScopedResource()
            defer { if zugriff { url.stopAccessingSecurityScopedResource() } }
            guard let daten = try? Data(contentsOf: url),
                  let roh = String(data: daten, encoding: .utf8),
                  let gelesen = PaketAktion.lese(roh) else {
                offenMeldung = "Diese Datei ist kein YEM1N-Paket."
                return
            }
            offenesPaket = gelesen.paket
            offenerText = gelesen.text
            zeigeOffen = true
        }
        .confirmationDialog("\(offenesPaket?.arbeit ?? "Paket") importieren?",
                            isPresented: $zeigeOffen, titleVisibility: .visible) {
            if modus == "eltern" {
                Button("An meine Familie veröffentlichen") {
                    if let p = offenesPaket {
                        Task { offenMeldung = await PaketAktion.veroeffentliche(p, text: offenerText, context: context) }
                    }
                }
                if CloudDienst.klassenCloudCode != nil {
                    Button("An die Klasse veröffentlichen") {
                        if let p = offenesPaket {
                            Task { offenMeldung = await PaketAktion.veroeffentliche(p, text: offenerText, context: context, klasse: true) }
                        }
                    }
                }
            }
            Button("Nur auf diesem Gerät importieren") {
                if let p = offenesPaket { offenMeldung = PaketAktion.lokal(p, context: context) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            if let p = offenesPaket {
                Text("\(p.klasse), \(p.fach): \(PaketAktion.anzahl(p)) Aufgaben")
            }
        }
        .alert("Hinweis", isPresented: Binding(get: { offenMeldung != nil },
                                              set: { if !$0 { offenMeldung = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(offenMeldung ?? "")
        }
        .fullScreenCover(isPresented: Binding(get: { !modus.isEmpty && !profilFertig },
                                              set: { _ in })) {
            ProfilAssistent()
                .preferredColorScheme(.dark)
        }
        .task(id: CloudDienst.marke(modus: modus, code: familienCode)) { await cloudStart() }
        .onChange(of: phase) {
            if phase == .active { Task { await CloudSync.aktiv(context) } }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await CloudSync.aktiv(context, erzwingen: true) }
        }
    }

    private func cloudStart() async {
        guard !modus.isEmpty, Familiencode.istGueltig(familienCode) else { return }
        let marke = CloudDienst.marke(modus: modus, code: familienCode)
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
    @AppStorage("klassenCode") private var klassenCode = ""
    @State private var schritt = 0          // 0 Auswahl, 1 Kind, 2 Eltern
    @State private var codeEingabe = ""
    @State private var klassenEingabe = ""
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
            wahlKarte(titel: "Kind", text: "Ich übe für die Schule.", symbol: "graduationcap.fill") {
                codeEingabe = familienCode
                klassenEingabe = klassenCode
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
        let famLeer = codeEingabe.isEmpty
        let klaLeer = klassenEingabe.isEmpty
        let famOK = famLeer || Familiencode.istGueltig(codeEingabe)
        let klaOK = klaLeer || Familiencode.istGueltig(klassenEingabe)
        let gueltig = famOK && klaOK && !(famLeer && klaLeer)
        VStack(spacing: 16) {
            Text("Code eingeben")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Trage den Familiencode (vom Eltern-Gerät), den Klassencode oder beide ein. Ein Code reicht. Du kannst alles auch später in den Einstellungen eintragen.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)

            codeFeld("Familiencode", $codeEingabe)
            codeFeld("Klassencode", $klassenEingabe)

            GelberKnopf(titel: "Weiter") {
                familienCode = Familiencode.bereinigt(codeEingabe)
                klassenCode = Familiencode.bereinigt(klassenEingabe)
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

    private func codeFeld(_ titel: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titel)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
            TextField("XXXXX-XXXXX", text: text)
                .font(.system(.title2, design: .monospaced).weight(.bold))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding(16)
                .background(Color.white.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .onChange(of: text.wrappedValue) {
                    let b = Familiencode.bereinigt(text.wrappedValue)
                    if b != text.wrappedValue { text.wrappedValue = b }
                }
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
    @AppStorage("vorschulTabEltern") private var vorschul = false

    var body: some View {
        TabView {
            ElternDashboardView()
                .tabItem { Label("Übersicht", systemImage: "chart.bar.fill") }
            StartView()
                .tabItem { Label("Schule", systemImage: "books.vertical.fill") }
            SprachStartView()
                .tabItem { Label("Sprachen", systemImage: "globe") }
            if vorschul {
                VorschuleView()
                    .tabItem { Label("Vorschule", systemImage: "sparkles") }
            }
            JokerLigaView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
            EinstellungenView(eingebettet: true)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
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
    private var alleErgebnisse: [RundenErgebnis]
    @State private var kindFilter = ""
    @State private var zeigeEinstellungen = false

    private var ergebnisse: [RundenErgebnis] {
        kindFilter.isEmpty ? alleErgebnisse : alleErgebnisse.filter { $0.kind == kindFilter }
    }

    private var kinder: [String] {
        Array(Set(alleErgebnisse.map { $0.kind }.filter { !$0.isEmpty })).sorted()
    }

    private var kindWahl: some View {
        Picker("Kind", selection: $kindFilter) {
            Text("Alle").tag("")
            ForEach(kinder, id: \.self) { name in
                Text(name).tag(name)
            }
        }
        .pickerStyle(.segmented)
    }

    private var berichtText: String {
        let kal = Calendar.current
        let grenze = kal.date(byAdding: .day, value: -6, to: kal.startOfDay(for: Date.now)) ?? Date.distantPast
        let diese = alleErgebnisse.filter { $0.zeitpunkt >= grenze }
        let namen: [String] = kinder.isEmpty ? [""] : kinder
        var zeilen: [String] = ["📊 YEM1N Wochenbericht"]
        for name in namen {
            let l = diese.filter { name.isEmpty || $0.kind == name }
            let titel = name.isEmpty ? "Diese Woche" : name
            if l.isEmpty {
                zeilen.append("")
                zeilen.append("\(titel): keine Runden")
                continue
            }
            let r = l.reduce(0) { $0 + $1.richtig }
            let g = l.reduce(0) { $0 + $1.gesamt }
            let st = l.reduce(0) { $0 + $1.sterne }
            var tage = Set<Date>()
            for e in l { tage.insert(kal.startOfDay(for: e.zeitpunkt)) }
            let prozent = g > 0 ? Int((Double(r) / Double(g) * 100).rounded()) : 0
            zeilen.append("")
            zeilen.append("⭐ \(titel)")
            zeilen.append("Runden: \(l.count) an \(tage.count) Tagen")
            zeilen.append("Richtig: \(r) von \(g) (\(prozent) %)")
            zeilen.append("Sterne: \(st)")
            let gruppiert = Dictionary(grouping: l, by: { $0.uebung })
            var bereiche: [(String, Double)] = []
            for (u, liste) in gruppiert {
                let rr = liste.reduce(0) { $0 + $1.richtig }
                let gg = liste.reduce(0) { $0 + $1.gesamt }
                if gg > 0 { bereiche.append((u, Double(rr) / Double(gg))) }
            }
            bereiche.sort { $0.1 > $1.1 }
            if let stark = bereiche.first { zeilen.append("💪 Stark: \(stark.0)") }
            if bereiche.count > 1, let schwach = bereiche.last { zeilen.append("🎯 Üben: \(schwach.0)") }
        }
        return zeilen.joined(separator: "\n")
    }

    private var wochenberichtKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wochenbericht")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text(berichtText)
                .font(.footnote)
                .foregroundStyle(Color.white)
            ShareLink(item: berichtText) {
                Label("Bericht teilen", systemImage: "square.and.arrow.up")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
            }
            Text("Jeden Sonntag um 18 Uhr erinnert dich eine Mitteilung daran.")
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

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
                    if kinder.count > 1 { kindWahl }
                    if ergebnisse.isEmpty {
                        leer
                    } else {
                        kacheln
                        wochenbalken
                        wochenberichtKarte
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
        .task { await Wochenbericht.planen() }
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
                        Text((e.kind.isEmpty ? "" : e.kind + " · ") + "\(e.arbeit) · " + e.zeitpunkt.formatted(.relative(presentation: .named)))
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
    @State private var zeigeReset = false
    @AppStorage("glasEffekt") private var glas = false
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("tagesziel") private var tagesziel = 2
    @AppStorage("klassenCode") private var klassenCode = ""
    @AppStorage("vorschulTab") private var vorschulKind = true
    @AppStorage("vorschulTabEltern") private var vorschulEltern = false
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("profilFertig") private var profilFertig = true
    @State private var klassenEingabe = ""
    @State private var klassenAdmin = false
    @State private var klassenInfo = ""
    @State private var zeigeLoeschen = false
    @State private var datenInfo = ""
    @State private var kindNameEntwurf = ""
    @FocusState private var fokus: String?
    let eingebettet: Bool

    init(eingebettet: Bool = false) {
        self.eingebettet = eingebettet
    }

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

                    Section {
                        if modus == "eltern" {
                            Text(klassenCode.isEmpty ? "Noch keiner" : klassenCode)
                                .font(.system(.title3, design: .monospaced).weight(.bold))
                                .foregroundStyle(Theme.gelb)
                            if !klassenCode.isEmpty {
                                ShareLink(item: "📚 YEM1N Klassencode: \(klassenCode)\nIn der App unter Einstellungen > Klassencode eintragen, dann erscheinen die Aufgaben der Klasse automatisch.") {
                                    Label("Klassencode teilen", systemImage: "square.and.arrow.up")
                                }
                            }
                            Button("Neuen Klassencode erzeugen") {
                                let neu = Familiencode.neu()
                                Task {
                                    do {
                                        try await CloudDienst.erzeugeKlassenSchluessel("K-" + neu)
                                        klassenCode = neu
                                        klassenInfo = "Klassencode angelegt. Dieses Gerät ist jetzt Admin der Klasse."
                                    } catch {
                                        klassenInfo = "Anlegen nicht möglich: \(CloudDienst.fehlertext(error))"
                                    }
                                    klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
                                }
                            }
                            if !klassenCode.isEmpty {
                                Label(klassenAdmin ? "Dieses Gerät ist Admin" : "Nur Lesen, kein Admin-Schlüssel",
                                      systemImage: klassenAdmin ? "checkmark.seal.fill" : "lock.fill")
                                    .font(.footnote)
                                    .foregroundStyle(klassenAdmin ? Theme.mint : Theme.textSanft)
                            }
                            if !klassenCode.isEmpty && !klassenAdmin {
                                Button("Admin dieses Klassencodes werden") {
                                    Task {
                                        do {
                                            try await CloudDienst.erzeugeKlassenSchluessel("K-" + klassenCode)
                                            klassenInfo = "Dieses Gerät ist jetzt Admin."
                                        } catch {
                                            klassenInfo = "Nicht möglich, der Code gehört schon einem anderen Gerät."
                                        }
                                        klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode)
                                    }
                                }
                            }
                        }
                        TextField("Klassencode, XXXXX-XXXXX", text: $klassenEingabe)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: klassenEingabe) {
                                let b = Familiencode.bereinigt(klassenEingabe)
                                if b != klassenEingabe { klassenEingabe = b }
                            }
                        Button("Klassencode speichern") {
                            klassenCode = Familiencode.bereinigt(klassenEingabe)
                            klassenEingabe = klassenCode
                        }
                        .disabled(!Familiencode.istGueltig(klassenEingabe) || klassenEingabe == klassenCode)
                        if !klassenCode.isEmpty && modus != "eltern" {
                            Button("Klassencode entfernen", role: .destructive) {
                                UserDefaults.standard.removeObject(forKey: "klassenPin-K-" + klassenCode)
                                klassenCode = ""
                                klassenEingabe = ""
                            }
                        }
                        if !klassenInfo.isEmpty {
                            Text(klassenInfo).font(.footnote).foregroundStyle(Theme.textSanft)
                        }
                    } header: {
                        Text("Klassencode (nur Aufgaben)")
                    } footer: {
                        Text("Über den Klassencode kommen nur Aufgabenpakete an, vom Admin digital unterschrieben. Ergebnisse und Joker bleiben in der Familie.")
                    }
                    .task { klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode) }
                    .onChange(of: klassenCode) { klassenAdmin = Klassensiegel.istAdmin("K-" + klassenCode) }
                    .listRowBackground(zeile)

                    Section {
                        NavigationLink { DatenschutzView() } label: {
                            Label("Datenschutzhinweise", systemImage: "hand.raised.fill")
                        }
                        Button("Meine Cloud-Daten löschen", role: .destructive) { zeigeLoeschen = true }
                        if !datenInfo.isEmpty {
                            Text(datenInfo).font(.footnote).foregroundStyle(Theme.textSanft)
                        }
                    } header: {
                        Text("Datenschutz")
                    } footer: {
                        Text("Löscht die Cloud-Einträge des Familiencodes, die dieses Gerät angelegt hat. Auf jedem Gerät der Familie einmal ausführen.")
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

                    if modus == "eltern" {
                        Section {
                            NavigationLink { PaketeView() } label: {
                                Label("Aufgaben per Cloud verteilen", systemImage: "icloud.and.arrow.up")
                            }
                        } footer: {
                            Text("Klassenarbeiten und Übungssets hochladen. Die Kind-Geräte laden sie automatisch.")
                        }
                        .listRowBackground(zeile)
                    }

                    Section {
                        NavigationLink { CloudDiagnoseView() } label: {
                            Label("Cloud-Diagnose", systemImage: "icloud")
                        }
                    } footer: {
                        Text("Für Eltern: Verbindung testen und die Cloud neu einrichten.")
                    }
                    .listRowBackground(zeile)

                    if modus == "kind" {
                        Section {
                            TextField("Name, zum Beispiel Yemin", text: $kindNameEntwurf)
                                .focused($fokus, equals: "name")
                            Picker("Klasse", selection: $kindKlasse) {
                                Text("Alle").tag("")
                                ForEach(ProfilDaten.klassen, id: \.self) { k in Text(k).tag(k) }
                            }
                            Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                                    value: $tagesziel, in: 1...10)
                            Button("Einrichtung noch einmal ansehen") { profilFertig = false }
                        } header: {
                            Text("Profil")
                        } footer: {
                            Text("Der Name erscheint bei den Eltern und in der App. Mit einer Klasse lädt das Gerät nur passende Aufgabenpakete, bei Alle bekommt es alle.")
                        }
                        .listRowBackground(zeile)
                    } else if modus == "eltern" {
                        Section {
                            Picker("Ich bin", selection: Binding(
                                get: {
                                    jokerIch.isEmpty ? (JokerStand.shared.mitglieder.first?.id.uuidString ?? "") : jokerIch
                                },
                                set: { jokerIch = $0 })) {
                                ForEach(JokerStand.shared.mitglieder) { m in
                                    Text("\(m.emoji) \(m.name)").tag(m.id.uuidString)
                                }
                            }
                            Button("Einrichtung noch einmal ansehen") { profilFertig = false }
                        } header: {
                            Text("Profil")
                        } footer: {
                            Text("Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen. Weitere Namen legst du im Tab Joker an.")
                        }
                        .listRowBackground(zeile)
                    }

                    Section {
                        Picker("Farbwelt", selection: Binding(get: { farbwelt },
                                                              set: { neu in
                            Theme.rosa = (neu == "rosa")
                            farbwelt = neu
                        })) {
                            Text("Blau und Gelb").tag("blau")
                            Text("Rosa").tag("rosa")
                        }
                        Toggle("Glas-Effekte", isOn: $glas)
                        if modus == "eltern" {
                            Toggle("Tab Vorschule anzeigen", isOn: $vorschulEltern)
                        } else {
                            Toggle("Tab Vorschule anzeigen", isOn: $vorschulKind)
                        }
                    } header: {
                        Text("Darstellung")
                    } footer: {
                        Text("Aus macht die App auf älteren iPhones flüssiger. Das Aussehen wird dann etwas flacher.")
                    }
                    .listRowBackground(zeile)

                    Section {
                        Button("Gerätemodus ändern (Kind oder Eltern)", role: .destructive) {
                            zeigeReset = true
                        }
                    } footer: {
                        Text("Danach erscheint wieder die Auswahl Kind oder Eltern. Familiencode, Klassenarbeiten und Fortschritt bleiben erhalten.")
                    }
                    .listRowBackground(zeile)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !eingebettet {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Fertig") { dismiss() }
                    }
                }
            }
            .confirmationDialog("Gerätemodus wirklich ändern?", isPresented: $zeigeReset,
                                titleVisibility: .visible) {
                Button("Ändern", role: .destructive) {
                    modus = ""
                    dismiss()
                }
                Button("Abbrechen", role: .cancel) {}
            }
            .confirmationDialog("Cloud-Daten wirklich löschen?", isPresented: $zeigeLoeschen,
                                titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    guard Familiencode.istGueltig(familienCode) else {
                        datenInfo = "Es ist kein Familiencode eingetragen."
                        return
                    }
                    datenInfo = "Wird gelöscht ..."
                    Task {
                        let n = await CloudDienst.loescheEigeneDaten(code: familienCode)
                        datenInfo = "\(n) Einträge in der Cloud gelöscht."
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Entfernt die Cloud-Einträge dieses Familiencodes, die dieses Gerät angelegt hat. Ergebnisse auf dem Gerät bleiben.")
            }
            .onAppear {
                codeEingabe = familienCode
                klassenEingabe = klassenCode
                kindNameEntwurf = kindName
            }
            .onChange(of: fokus) {
                kindName = kindNameEntwurf.trimmingCharacters(in: .whitespaces)
            }
            .onDisappear {
                kindName = kindNameEntwurf.trimmingCharacters(in: .whitespaces)
            }
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
        // Geräte, die schon einen Namen eingetragen haben, brauchen den Einrichtungsassistenten nicht
        let vorgaben = UserDefaults.standard
        if vorgaben.object(forKey: "profilFertig") == nil {
            let hatName = !(vorgaben.string(forKey: "kindName") ?? "").isEmpty
            let hatIch = !(vorgaben.string(forKey: "jokerIch") ?? "").isEmpty
            if hatName || hatIch { vorgaben.set(true, forKey: "profilFertig") }
        }
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

    @State private var fachFilter = "Alle"
    @State private var fehler: String?
    @State private var zeigeEinfuegen = false
    @State private var zeigeDatei = false
    @State private var eingabeText = ""
    @State private var infoMeldung: String?
    @State private var zeigeEinstellungen = false
    @State private var zeigeEditor = false
    @State private var zeigePakete = false
    @State private var zeigeErfolge = false
    @State private var pfad = NavigationPath()
    @State private var zwischenPaket: ArbeitPaket?
    @State private var zwischenText = ""
    @State private var zeigeZwischen = false
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokale: [RundenErgebnis]

    private var normale: [Klassenarbeit] {
        alleArbeiten.filter { $0.spezial.isEmpty && $0.fach != "Vorschule" }
    }

    private var alleFaecher: [String] { Array(Set(normale.map(\.fach))).sorted() }
    private var aktuellerFilter: String { alleFaecher.contains(fachFilter) ? fachFilter : "Alle" }

    private var offeneFehler: Int {
        var n = 0
        for k in normale {
            for u in k.uebungen {
                for a in u.aufgaben where a.richtig == false && !a.gemeistert { n += 1 }
            }
        }
        return n
    }

    private func oeffneSpezial(_ art: String) {
        if let offen = alleArbeiten.first(where: { $0.spezial == art && $0.fertigeUebungen < $0.uebungen.count }) {
            pfad.append(offen)
            return
        }
        let neu: Klassenarbeit?
        switch art {
        case "fehlerheft": neu = Spezial.fehlerheft(alle: normale, in: context)
        case "training": neu = Spezial.training(alle: normale, ergebnisse: lokale, in: context)
        default: neu = Spezial.probe(alle: normale, in: context)
        }
        guard let neu else {
            infoMeldung = "Keine offenen Fehler. Super gemacht! 🎉"
            return
        }
        for alt in alleArbeiten where alt.spezial == art { context.delete(alt) }
        pfad.append(neu)
    }

    private func pruefeZwischenablage() {
        guard let gelesen = PaketAktion.lese(UIPasteboard.general.string ?? "") else {
            infoMeldung = "In der Zwischenablage liegt kein passendes JSON von Claude. Kopiere es im Chat und tippe dann noch einmal hier."
            return
        }
        zwischenPaket = gelesen.paket
        zwischenText = gelesen.text
        zeigeZwischen = true
    }

    private func neueAufgabenHolen() async {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) || CloudDienst.klassenCloudCode != nil else {
            infoMeldung = "Es fehlt noch ein Familiencode oder Klassencode. Bitte im Tab Einstellungen eintragen."
            return
        }
        let n = await CloudSync.holePakete(context)
        if n > 1 { infoMeldung = "\(n) neue Aufgabenpakete geladen." }
        else if n == 1 { infoMeldung = "1 neues Aufgabenpaket geladen." }
        else if n == 0 { infoMeldung = "Alles aktuell. Es gibt nichts Neues." }
        else { infoMeldung = CloudStatus.shared.meldung }
    }

    private var gefiltert: [Klassenarbeit] {
        aktuellerFilter == "Alle" ? normale : normale.filter { $0.fach == aktuellerFilter }
    }

    private var klassen: [String] { Array(Set(gefiltert.map(\.klasse))).sorted() }

    private func faecher(_ klasse: String) -> [String] {
        Array(Set(gefiltert.filter { $0.klasse == klasse }.map(\.fach))).sorted()
    }

    private func arbeiten(_ klasse: String, _ fach: String) -> [Klassenarbeit] {
        normale.filter { $0.klasse == klasse && $0.fach == fach }
    }

    var body: some View {
        NavigationStack(path: $pfad) {
            ZStack {
                HintergrundView()
                VStack(spacing: 0) {
                    kopf
                    if normale.isEmpty { leer } else { liste }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            .sheet(isPresented: $zeigePakete) {
                NavigationStack { PaketeView() }
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .sheet(isPresented: $zeigeErfolge) {
                ErfolgeView()
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
            .confirmationDialog("\(zwischenPaket?.arbeit ?? "Paket") veröffentlichen?",
                                isPresented: $zeigeZwischen, titleVisibility: .visible) {
                Button("An meine Familie veröffentlichen") {
                    if let p = zwischenPaket {
                        Task { infoMeldung = await PaketAktion.veroeffentliche(p, text: zwischenText, context: context) }
                    }
                }
                if CloudDienst.klassenCloudCode != nil {
                    Button("An die Klasse veröffentlichen") {
                        if let p = zwischenPaket {
                            Task { infoMeldung = await PaketAktion.veroeffentliche(p, text: zwischenText, context: context, klasse: true) }
                        }
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                if let p = zwischenPaket {
                    Text("\(p.klasse), \(p.fach): \(PaketAktion.anzahl(p)) Aufgaben. Die Kind-Geräte laden das Paket automatisch.")
                }
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

    private var untertitel: String {
        var text = kindName.isEmpty ? "Schule üben" : "Hallo \(kindName)! Schule üben"
        let serie = Erfolge.serie(lokale)
        if modus != "eltern" && serie > 0 { text += " · 🔥 \(serie)" }
        return text
    }

    private var kopf: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YEM1N")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                Text(untertitel)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            if modus != "eltern" {
                Button { zeigeErfolge = true } label: {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.gelb)
                        .frame(width: 48, height: 48)
                        .background(Color.white.opacity(0.12), in: Circle())
                }
            }
            Menu {
                Button("Text einfügen", systemImage: "text.cursor") {
                    fehler = nil
                    zeigeEinfuegen = true
                }
                Button("Aus Zwischenablage einfügen", systemImage: "doc.on.clipboard") {
                    importiereText(UIPasteboard.general.string)
                }
                Button("Datei importieren", systemImage: "folder") { zeigeDatei = true }
                if modus == "kind" {
                    Button("Neue Aufgaben holen", systemImage: "icloud.and.arrow.down") {
                        Task { await neueAufgabenHolen() }
                    }
                }
                if modus == "eltern" {
                    Button("Aufgaben-Editor", systemImage: "square.and.pencil") { zeigeEditor = true }
                    Button("Cloud-Pakete", systemImage: "icloud.and.arrow.up") { zeigePakete = true }
                }
                Divider()
                Button("Einstellungen", systemImage: "gearshape") { zeigeEinstellungen = true }
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
            Text(modus == "kind"
                 ? "Neue Aufgaben kommen automatisch von deinen Eltern."
                 : "Tippe auf das Plus und füge das JSON von Claude ein.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if modus == "kind" {
                GelberKnopf(titel: "Neue Aufgaben holen") {
                    Task { await neueAufgabenHolen() }
                }
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Liste

    private var liste: some View {
        List {
            extraZeile
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))

            if alleFaecher.count > 1 {
                fachChips
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 2, leading: 20, bottom: 2, trailing: 20))
            }

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
        .refreshable { await CloudSync.aktiv(context, erzwingen: true) }
    }

    private var fachChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Alle"] + alleFaecher, id: \.self) { f in
                    let aktiv = aktuellerFilter == f
                    Button { fachFilter = f } label: {
                        Text(f)
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 36)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var extraZeile: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Extra")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            HStack(spacing: 10) {
                extraKnopf("📓", "Fehlerheft", offeneFehler > 0 ? "\(offeneFehler) offen" : "alles gut") {
                    oeffneSpezial("fehlerheft")
                }
                extraKnopf("🎯", "Training", "für heute") {
                    oeffneSpezial("training")
                }
                extraKnopf("📝", "Probearbeit", "30 Minuten") {
                    oeffneSpezial("probe")
                }
            }
            if modus == "eltern" {
                Button { pruefeZwischenablage() } label: {
                    Label("JSON aus Zwischenablage veröffentlichen", systemImage: "icloud.and.arrow.up")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .frame(maxWidth: .infinity, minHeight: 46)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }

    private func extraKnopf(_ emoji: String, _ titel: String, _ untertitel: String,
                            aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            VStack(spacing: 4) {
                Text(emoji).font(.system(size: 28))
                Text(titel)
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(untertitel)
                    .font(.caption2)
                    .foregroundStyle(Theme.textSanft)
            }
            .frame(maxWidth: .infinity, minHeight: 84)
            .glasKarte(radius: 20)
        }
        .buttonStyle(TastenStil())
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

        PaketImport.einfuegen(paket, in: context)
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
    @State private var probeStart = Date.now
    @State private var zeigeNotiz = false
    @State private var notiz = PKDrawing()

    private var istProbe: Bool { uebung.arbeit?.spezial == "probe" }

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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { zeigeNotiz = true } label: {
                    Image(systemName: "pencil.tip.crop.circle")
                }
            }
        }
        .sheet(isPresented: $zeigeNotiz) { notizSheet }
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
                if istProbe { probeUhr }
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
                if let (x, y) = a.faktoren, a.hinweis.isEmpty, !istProbe {
                    PunkteFeld(reihen: x, spalten: y)
                }
                Text(angezeigteRechnung(a))
                    .font(grosseSchrift(a)
                          ? Font.system(size: 42, weight: .heavy, design: .rounded)
                          : Font.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)

                if !a.hinweis.isEmpty && !istProbe {
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
        } else if a.art == "text" {
            // Bei Textaufgaben wird im Eingabefeld unten geschrieben, hier erscheint die Antwort erst nach dem Prüfen
            if bewertet != nil {
                feldPaar(titel: "", wert: eingabe, aktiv: false, nummer: 1)
                    .modifier(Wackeln(animatableData: CGFloat(wackeln)))
            }
        } else if a.art != "vergleich" {
            feldPaar(titel: "", wert: eingabe, aktiv: true, nummer: 1)
                .modifier(Wackeln(animatableData: CGFloat(wackeln)))
        }
    }

    private func feldPaar(titel: String, wert: String, aktiv: Bool, nummer: Int) -> some View {
        VStack(spacing: 6) {
            Text(wert.isEmpty ? "?" : wert)
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 12)
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
            if !istProbe {
                HStack(spacing: 12) {
                    loesungKnopf
                    JokerKnopf(uebrig: JokerStand.shared.uebrigHeute) { starteJoker(a) }
                }
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
        } else if a.art == "text" {
            TextAntwortFeld(text: $eingabe) { pruefen(a) }
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
            jokerMeldung = "Heute sind alle Joker aufgebraucht. Versuch es noch einmal oder frag im Tab Joker nach neuen Jokern."
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

    private var probeUhr: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let rest = max(0, 30 * 60 - Int(ctx.date.timeIntervalSince(probeStart)))
            Label(String(format: "%d:%02d", rest / 60, rest % 60), systemImage: "timer")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(rest < 300 ? Theme.koralle : Theme.gelb)
        }
    }

    private var notizSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                NotizblockView(zeichnung: $notiz)
            }
            .navigationTitle("Notizblock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Löschen", role: .destructive) { notiz = PKDrawing() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { zeigeNotiz = false }
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
        .presentationDetents([.medium, .large])
    }

    private func bereiteVor() {
        notiz = PKDrawing()
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
        case "text":
            let e = normalisiert(eingabe)
            guard !e.isEmpty else { return }
            melde(a, ok: e == normalisiert(a.antwort), erklaerung: a.erklaerung)
        default:
            guard !eingabe.isEmpty else { return }
            melde(a, ok: gleich(eingabe, a.antwort), erklaerung: a.erklaerung)
        }
    }

    // Textantworten: Leerzeichen am Rand und doppelte Leerzeichen ignorieren, Groß und Klein zählt
    private func normalisiert(_ t: String) -> String {
        t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
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
        if ok { Spezial.gemeistert(a, in: context) }
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
                : (a.art == "text" ? "Richtig: \(a.antwort)" : "")
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
        probeStart = Date.now
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
                if istProbe {
                    Text("Note: \(Spezial.note(gut: gut, gesamt: uebung.aufgaben.count))")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                    Text("Das ist eine Schätzung wie in der Schule.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
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
    @AppStorage("vorschulTab") private var vorschul = true

    var body: some View {
        TabView {
            StartView()
                .tabItem { Label("Schule", systemImage: "books.vertical.fill") }
            SprachStartView()
                .tabItem { Label("Sprachen", systemImage: "globe") }
            if vorschul {
                VorschuleView()
                    .tabItem { Label("Vorschule", systemImage: "sparkles") }
            }
            KindJokerView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
            EinstellungenView(eingebettet: true)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
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
            jokerMeldung = "Heute sind alle Joker aufgebraucht. Versuch es noch einmal oder frag im Tab Joker nach neuen Jokern."
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

    // Setzt die heutigen Joker auf das volle Limit zurück
    func auffuellen() {
        nutzungen.removeAll { Calendar.current.isDateInToday($0) }
        sichere()
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
                        JokerNachschubView()
                        if joker.ligaAn { liga }
                        eintragen
                        einstellungen
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
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        return true
    }

    nonisolated func application(_ application: UIApplication,
                                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set("registriert", forKey: "pushStatus")
    }

    nonisolated func application(_ application: UIApplication,
                                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UserDefaults.standard.set("Fehler: \(error.localizedDescription)", forKey: "pushStatus")
    }

    nonisolated func application(_ application: UIApplication,
                                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        NotificationCenter.default.post(name: .cloudPush, object: nil)
        return .newData
    }

    // Ohne diese Methode zeigt iOS bei geöffneter App kein Banner
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        NotificationCenter.default.post(name: .cloudPush, object: nil)
        return [.banner, .list, .sound, .badge]
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
        r["kind"] = e.kind as CKRecordValue
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
        try await schemaBeispiel("JokerNachschub", ["familienCode": code, "kind": "Test" as CKRecordValue])
        try await schemaBeispiel("JokerFreigabe", ["familienCode": code, "anzahl": 3 as CKRecordValue])
        try await schemaBeispiel("Lernpaket", ["familienCode": code, "klasse": "Test" as CKRecordValue,
                                               "fach": "Test" as CKRecordValue, "titel": "Test" as CKRecordValue,
                                               "json": "{}" as CKRecordValue, "aufgaben": 0 as CKRecordValue])
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
                try await aboDaumen(code: code, name: ichName())
                try await abo(typ: "JokerNachschub", code: code,
                              text: "🃏 Dein Kind hat keine Joker mehr und fragt nach neuen. Tippe zum Freigeben!")
            } else {
                try await abo(typ: "JokerAntwort", code: code,
                              text: "💡 Du hast einen Tipp bekommen! Schau im Tab Joker nach.")
                try await abo(typ: "JokerFreigabe", code: code,
                              text: "🎉 Neue Joker! Du hast wieder alle Joker für heute.")
                try await abo(typ: "Lernpaket", code: code,
                              text: "📚 Neue Aufgaben für dich sind da! Öffne YEM1N und leg los. 💪")
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
                e.kind = (r["kind"] as? String) ?? ""
                context.insert(e)
                ids.insert(id)
            }
            try? context.save()
        } catch {
            CloudStatus.shared.meldung = "Ergebnisse holen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }

    // Kind-Gerät: Joker-Freigaben der Eltern anwenden (Joker wieder auf das Limit setzen)
    static func holeFreigaben() async {
        guard modus == "kind", Familiencode.istGueltig(code) else { return }
        guard let liste = try? await CloudDienst.holeRecords("JokerFreigabe", code: code, limit: 100) else { return }
        var benutzt = Set(UserDefaults.standard.stringArray(forKey: "jokerFreigaben") ?? [])
        var neu = false
        for r in liste where !benutzt.contains(r.recordID.recordName) {
            benutzt.insert(r.recordID.recordName)
            neu = true
        }
        if neu {
            JokerStand.shared.auffuellen()
            UserDefaults.standard.set(Array(benutzt), forKey: "jokerFreigaben")
        }
    }

    // Kind-Gerät: neue Klassenarbeiten und Übungssets laden. Vorhandene bleiben mit Fortschritt unberührt.
    // Ergebnis: Anzahl neuer Pakete, bei einem Fehler -1
    @discardableResult
    static func holePakete(_ context: ModelContext) async -> Int {
        var codes: [String] = []
        if Familiencode.istGueltig(code) { codes.append(code) }
        if let k = CloudDienst.klassenCloudCode { codes.append(k) }
        guard modus == "kind", !codes.isEmpty else { return 0 }
        do {
            var koepfe: [(paket: CloudPaket, herkunft: String)] = []
            for c in codes {
                for p in try await CloudDienst.ladePakete(code: c) { koepfe.append((p, c)) }
            }
            var neu = 0
            var ungueltig = 0
            let meineKlasse = (UserDefaults.standard.string(forKey: "kindKlasse") ?? "")
                .trimmingCharacters(in: .whitespaces).lowercased()
            for eintrag in koepfe {
                let k = eintrag.paket
                if !meineKlasse.isEmpty && k.klasse.lowercased() != meineKlasse { continue }
                if PaketImport.vorhanden(klasse: k.klasse, fach: k.fach, titel: k.titel, in: context) { continue }
                let text: String
                if eintrag.herkunft.hasPrefix("K-") {
                    // Pakete aus der Klasse müssen vom Admin unterschrieben sein
                    guard let signiert = try await CloudDienst.ladePaketSigniert(id: k.id),
                          let oeffentlich = await Klassensiegel.vertrauterSchluessel(eintrag.herkunft),
                          Klassensiegel.pruefe(code: eintrag.herkunft, json: signiert.json,
                                               sig: signiert.sig, oeffentlich: oeffentlich) else {
                        ungueltig += 1
                        continue
                    }
                    text = signiert.json
                } else {
                    guard let t = try await CloudDienst.ladePaketText(id: k.id) else { continue }
                    text = t
                }
                guard let daten = text.data(using: .utf8),
                      let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
                      !paket.uebungen.isEmpty else { continue }
                if PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) { continue }
                PaketImport.einfuegen(paket, in: context)
                neu += 1
            }
            if neu > 0 { try? context.save() }
            if ungueltig > 0 {
                CloudStatus.shared.meldung = "\(ungueltig) Paket(e) der Klasse ohne gültige Unterschrift wurden ignoriert."
            }
            return neu
        } catch {
            CloudStatus.shared.meldung = "Neue Aufgaben holen nicht möglich: \(CloudDienst.fehlertext(error))"
            return -1
        }
    }

    // Wird beim Öffnen der App, bei Mitteilungen und beim Aktualisieren aufgerufen
    nonisolated(unsafe) private static var letzterLauf = Date.distantPast

    static func aktiv(_ context: ModelContext, erzwingen: Bool = false) async {
        if !erzwingen && Date().timeIntervalSince(letzterLauf) < 5 { return }
        letzterLauf = Date()
        if modus == "kind" {
            await sendeOffene(context)
            await holeFreigaben()
            await holePakete(context)
        }
        if modus == "eltern" { await holeErgebnisse(context) }
        if !modus.isEmpty { await JokerCloud.shared.aktualisieren() }
    }
}

// MARK: Joker: Speicher der Cloud-Anfragen

@Observable
final class JokerCloud {
    static let shared = JokerCloud()
    var anfragen: [CloudAnfrage] = []
    var nachschub: [CloudNachschub] = []
    var freigaben: [Date] = []
    var erledigt: Set<String> = Set(UserDefaults.standard.stringArray(forKey: "jokerErledigt") ?? [])
    var laedt = false
    var fehler = ""

    // Was im Postfach angezeigt wird (erledigte Anfragen sind nur ausgeblendet, die Punkte bleiben)
    var sichtbar: [CloudAnfrage] { anfragen.filter { !erledigt.contains($0.id) } }

    func erledige(_ id: String) {
        erledigt.insert(id)
        UserDefaults.standard.set(Array(erledigt), forKey: "jokerErledigt")
    }

    func alleErledigen() {
        for a in anfragen { erledigt.insert(a.id) }
        UserDefaults.standard.set(Array(erledigt), forKey: "jokerErledigt")
    }

    func aktualisieren() async {
        let code = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        guard Familiencode.istGueltig(code) else {
            fehler = "Noch kein Familiencode."
            return
        }
        laedt = true
        do {
            anfragen = try await CloudDienst.ladeJoker(code: code)
            nachschub = (try? await CloudDienst.ladeNachschub(code: code)) ?? []
            freigaben = (try? await CloudDienst.ladeFreigaben(code: code)) ?? []
            if UserDefaults.standard.string(forKey: "modus") == "kind" {
                await CloudSync.holeFreigaben()
            }
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
                if !cloud.sichtbar.isEmpty {
                    Button {
                        withAnimation(.snappy) { cloud.alleErledigen() }
                    } label: {
                        Text("Alle erledigt")
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.navy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Theme.gelb, in: Capsule())
                    }
                    .buttonStyle(TastenStil())
                }
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
            if cloud.sichtbar.isEmpty && cloud.fehler.isEmpty {
                Text(cloud.anfragen.isEmpty
                     ? "Noch keine Joker-Anfrage. Sobald dein Kind einen Joker nutzt, bekommst du eine Mitteilung und siehst sie hier."
                     : "Alles erledigt. 🎉 Neue Anfragen erscheinen hier von selbst.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            } else if !cloud.sichtbar.isEmpty {
                Text("Nach links oder rechts wischen blendet eine Anfrage als erledigt aus.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            ForEach(Array(cloud.sichtbar.prefix(8))) { a in
                karte(a)
                    .wischErledigt { cloud.erledige(a.id) }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
        .task {
            while !Task.isCancelled {
                await cloud.aktualisieren()
                try? await Task.sleep(for: .seconds(10))
            }
        }
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
                Button {
                    withAnimation(.snappy) { cloud.erledige(a.id) }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.mint)
                }
                .buttonStyle(.plain)
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
    @State private var nachschubLaeuft = false
    @State private var nachschubInfo = ""

    private var meinName: String { kindName.isEmpty ? "Kind" : kindName }

    private func nachschubAnfragen() async {
        guard Familiencode.istGueltig(familienCode) else {
            nachschubInfo = "Es fehlt noch ein Familiencode. Frag deine Eltern."
            return
        }
        nachschubLaeuft = true
        do {
            try await CloudDienst.sendeNachschub(code: familienCode, kind: meinName)
            Haptik.erfolg()
            nachschubInfo = "Anfrage ist raus. Deine Eltern bekommen eine Mitteilung."
        } catch {
            nachschubInfo = "Das hat nicht geklappt. Bist du online?"
        }
        nachschubLaeuft = false
    }
    private var meine: [CloudAnfrage] { cloud.anfragen.filter { $0.kind == meinName } }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        if Familiencode.istGueltig(familienCode) {
                            nachschubBereich
                        } else {
                            Text("Dieses Gerät gehört zu keiner Familie, nur zu einer Klasse. Darum gibt es hier keine Joker-Antworten von Eltern. Wenn du bei einer Aufgabe auf 🃏 Joker tippst, kannst du die Frage stattdessen per Nachricht an jemanden schicken. Einen Familiencode trägst du in den Einstellungen ein.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSanft)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .glasKarte(radius: 22)
                        }
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
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await cloud.aktualisieren() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                while !Task.isCancelled {
                    await cloud.aktualisieren()
                    try? await Task.sleep(for: .seconds(8))
                }
            }
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

    private var nachschubBereich: some View {
        VStack(alignment: .leading, spacing: 6) {
            if joker.uebrigHeute < joker.limitProTag {
                Button {
                    Task { await nachschubAnfragen() }
                } label: {
                    Text(nachschubLaeuft ? "Wird gesendet ..." : "🃏 Neue Joker anfragen")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
                .disabled(nachschubLaeuft)
            }
            if !nachschubInfo.isEmpty {
                Text(nachschubInfo)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
    }

    private var namenFeld: some View {
        HStack(spacing: 10) {
            Text("Ich bin")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
            Text(kindName.isEmpty ? "Noch kein Name (Einstellungen > Profil)" : kindName)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(kindName.isEmpty ? Theme.textSanft : Color.white)
            Spacer()
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
                        UserDefaults.standard.set(CloudDienst.marke(modus: modus, code: familienCode), forKey: "cloudEingerichtet")
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

// ============================================================
// MARK: - Cloud-Pakete: Klassenarbeiten und Übungssets verteilen
// ============================================================

struct CloudPaket: Identifiable {
    let id: String
    let klasse: String
    let fach: String
    let titel: String
    let erstellt: Date
}

enum PaketJSON {
    // Eine Klassenarbeit als JSON-Text im Importformat
    static func text(von a: Klassenarbeit) -> String? {
        var uebungen: [[String: Any]] = []
        for u in a.sortierteUebungen {
            var aufgaben: [[String: Any]] = []
            for x in u.sortierteAufgaben {
                var d: [String: Any] = ["art": x.art, "frage": x.frage,
                                        "rechnung": x.rechnung, "antwort": x.antwort]
                if !x.hinweis.isEmpty { d["hinweis"] = x.hinweis }
                if !x.erklaerung.isEmpty { d["erklaerung"] = x.erklaerung }
                if !x.antwort2.isEmpty { d["antwort2"] = x.antwort2 }
                if x.art == "mauer" { d["reihen"] = x.reihen }
                aufgaben.append(d)
            }
            var ud: [String: Any] = ["titel": u.titel, "gruppe": u.gruppe,
                                     "symbol": u.symbol, "aufgaben": aufgaben]
            if !u.tipp.isEmpty { ud["tipp"] = u.tipp }
            uebungen.append(ud)
        }
        let wurzel: [String: Any] = ["klasse": a.klasse, "fach": a.fach,
                                     "arbeit": a.titel, "uebungen": uebungen]
        guard let daten = try? JSONSerialization.data(withJSONObject: wurzel) else { return nil }
        return String(data: daten, encoding: .utf8)
    }

    // Stabiler Name des Cloud-Datensatzes, damit erneutes Hochladen ersetzt statt verdoppelt
    static func schluessel(klasse: String, fach: String, titel: String) -> String {
        let erlaubt = Set("abcdefghijklmnopqrstuvwxyz0123456789")
        var aus = ""
        var letzterStrich = false
        for z in (klasse + "-" + fach + "-" + titel).lowercased() {
            if erlaubt.contains(z) {
                aus.append(z)
                letzterStrich = false
            } else if !letzterStrich {
                aus.append("-")
                letzterStrich = true
            }
        }
        return aus
    }

    // Aus eingefügtem Text das JSON-Objekt herauslösen (falls Code-Zaun oder Begleittext dabei ist)
    static func bereinigt(_ text: String) -> String {
        if let s = text.firstIndex(of: "{"), let e = text.lastIndex(of: "}"), s < e {
            return String(text[s...e])
        }
        return text
    }
}

enum PaketImport {
    static func vorhanden(klasse: String, fach: String, titel: String, in context: ModelContext) -> Bool {
        let alle = (try? context.fetch(FetchDescriptor<Klassenarbeit>())) ?? []
        return alle.contains { $0.klasse == klasse && $0.fach == fach && $0.titel == titel }
    }

    static func einfuegen(_ paket: ArbeitPaket, in context: ModelContext) {
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
                var reihenJSON = ap.reihen
                    .flatMap { try? JSONEncoder().encode($0) }
                    .flatMap { String(data: $0, encoding: .utf8) } ?? ""
                let aufgabe: Aufgabe
                if ap.art == "wahl" {
                    // Vorschule: rechnung = Bild, hinweis = türkische Frage, erklaerung = große Zahl,
                    // antwort2 = Folge, reihenJSON = Antwortknöpfe
                    reihenJSON = (try? JSONEncoder().encode(ap.optionen ?? []))
                        .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
                    aufgabe = Aufgabe(art: "wahl",
                                      frage: ap.frage ?? "",
                                      rechnung: ap.bild ?? "",
                                      hinweis: ap.tr ?? "",
                                      erklaerung: ap.gross ?? "",
                                      antwort: ap.antwort ?? "",
                                      antwort2: (ap.folge ?? []).joined(separator: " "),
                                      reihenJSON: reihenJSON,
                                      reihenfolge: j)
                } else {
                    aufgabe = Aufgabe(art: ap.art ?? "zahl",
                                      frage: ap.frage ?? "",
                                      rechnung: ap.rechnung ?? "",
                                      hinweis: ap.hinweis ?? "",
                                      erklaerung: ap.erklaerung ?? "",
                                      antwort: ap.antwort ?? "",
                                      antwort2: ap.antwort2 ?? "",
                                      reihenJSON: reihenJSON,
                                      reihenfolge: j)
                }
                context.insert(aufgabe)
                aufgabe.uebung = uebung
            }
        }
    }
}

extension CloudDienst {
    // Der Klassencode wird in der Cloud mit "K-" markiert, damit er nie mit einem Familiencode verwechselt wird
    static var klassenCloudCode: String? {
        let c = UserDefaults.standard.string(forKey: "klassenCode") ?? ""
        return Familiencode.istGueltig(c) ? "K-" + Familiencode.bereinigt(c) : nil
    }

    // Nur die Kopfdaten laden, der große JSON-Text kommt erst bei Bedarf
    static func ladePakete(code: String) async throws -> [CloudPaket] {
        let q = CKQuery(recordType: "Lernpaket",
                        predicate: NSPredicate(format: "familienCode == %@", code))
        let keys: [CKRecord.FieldKey] = ["klasse", "fach", "titel"]
        let antwort = try await db.records(matching: q, desiredKeys: keys, resultsLimit: 100)
        var liste: [CloudPaket] = []
        for (_, ergebnis) in antwort.matchResults {
            guard let r = try? ergebnis.get() else { continue }
            liste.append(CloudPaket(id: r.recordID.recordName,
                                    klasse: (r["klasse"] as? String) ?? "",
                                    fach: (r["fach"] as? String) ?? "",
                                    titel: (r["titel"] as? String) ?? "",
                                    erstellt: r.creationDate ?? Date.distantPast))
        }
        return liste.sorted { $0.erstellt < $1.erstellt }
    }

    static func ladePaketSigniert(id: String) async throws -> (json: String, sig: String)? {
        let r = try await db.record(for: CKRecord.ID(recordName: id))
        guard let j = r["json"] as? String, let sg = r["sig"] as? String else { return nil }
        return (j, sg)
    }

    // Admin-Schlüssel anlegen: der öffentliche Teil kommt in die Cloud, der private bleibt im Schlüsselbund
    static func erzeugeKlassenSchluessel(_ code: String) async throws {
        let k = Curve25519.Signing.PrivateKey()
        let r = CKRecord(recordType: "KlassenSchluessel",
                         recordID: CKRecord.ID(recordName: "klassenkey-" + code))
        r["klassenCode"] = code as CKRecordValue
        r["publicKey"] = k.publicKey.rawRepresentation.base64EncodedString() as CKRecordValue
        let erg = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
        for (_, e) in erg.saveResults { _ = try e.get() }
        Schluesselbund.speichere(k.rawRepresentation, konto: Klassensiegel.konto(code))
        UserDefaults.standard.removeObject(forKey: "klassenPin-" + code)
    }

    static func ladeKlassenSchluessel(_ code: String) async -> Data? {
        guard let r = try? await db.record(for: CKRecord.ID(recordName: "klassenkey-" + code)),
              let b64 = r["publicKey"] as? String else { return nil }
        return Data(base64Encoded: b64)
    }

    // Datenschutz: löscht alle Einträge dieses Familiencodes, die dieses Gerät angelegt hat
    static func loescheEigeneDaten(code: String) async -> Int {
        let typen = ["RundenErgebnis", "JokerAnfrage", "JokerAntwort", "JokerDaumen",
                     "JokerNachschub", "JokerFreigabe", "Lernpaket"]
        var geloescht = 0
        for typ in typen {
            let q = CKQuery(recordType: typ, predicate: NSPredicate(format: "familienCode == %@", code))
            guard let antwort = try? await db.records(matching: q, desiredKeys: [], resultsLimit: 400) else { continue }
            var ids: [CKRecord.ID] = []
            for (id, ergebnis) in antwort.matchResults {
                if (try? ergebnis.get()) != nil { ids.append(id) }
            }
            if ids.isEmpty { continue }
            guard let erg = try? await db.modifyRecords(saving: [], deleting: ids) else { continue }
            for (_, e) in erg.deleteResults {
                if (try? e.get()) != nil { geloescht += 1 }
            }
        }
        return geloescht
    }

    static func ladePaketText(id: String) async throws -> String? {
        let r = try await db.record(for: CKRecord.ID(recordName: id))
        return r["json"] as? String
    }

    static func hochladen(code: String, paket: ArbeitPaket, json: String) async throws {
        let name = "paket-" + code + "-" + PaketJSON.schluessel(klasse: paket.klasse,
                                                              fach: paket.fach, titel: paket.arbeit)
        let r = CKRecord(recordType: "Lernpaket", recordID: CKRecord.ID(recordName: name))
        r["familienCode"] = code as CKRecordValue
        r["klasse"] = paket.klasse as CKRecordValue
        r["fach"] = paket.fach as CKRecordValue
        r["titel"] = paket.arbeit as CKRecordValue
        r["json"] = json as CKRecordValue
        r["aufgaben"] = paket.uebungen.reduce(0) { $0 + $1.aufgaben.count } as CKRecordValue
        if code.hasPrefix("K-") {
            guard let sig = Klassensiegel.signiere(code: code, json: json) else { throw KlassenFehler.keinSchluessel }
            r["sig"] = sig as CKRecordValue
        }
        let ergebnis = try await db.modifyRecords(saving: [r], deleting: [], savePolicy: .allKeys)
        for (_, e) in ergebnis.saveResults { _ = try e.get() }
    }

    static func loeschePaket(id: String) async throws {
        _ = try await db.deleteRecord(withID: CKRecord.ID(recordName: id))
    }
}

// Eltern: Aufgaben in die Cloud stellen, Kind-Geräte laden sie von selbst
struct PaketeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Klassenarbeit.klasse), SortDescriptor(\Klassenarbeit.fach),
                  SortDescriptor(\Klassenarbeit.erstellt)])
    private var arbeiten: [Klassenarbeit]
    @AppStorage("familienCode") private var familienCode = ""
    @State private var cloud: [CloudPaket] = []
    @State private var klassenCloud: [CloudPaket] = []
    @State private var fuerKlasse = false
    @State private var meldung = ""
    @State private var zeigeEinfuegen = false
    @State private var eingabe = ""
    @State private var fehlerText = ""
    @State private var arbeitet = false

    private let zeile = Color.white.opacity(0.08)

    private func inCloud(_ a: Klassenarbeit) -> Bool {
        cloud.contains { $0.klasse == a.klasse && $0.fach == a.fach && $0.titel == a.titel }
    }

    private var eigene: [Klassenarbeit] { arbeiten.filter { $0.spezial.isEmpty } }

    var body: some View {
        ZStack {
            HintergrundView()
            List {
                if !Familiencode.istGueltig(familienCode) && CloudDienst.klassenCloudCode == nil {
                    Section {
                        Text("Zuerst im Tab Einstellungen einen Familiencode eintragen.")
                            .foregroundStyle(Theme.koralle)
                    }
                    .listRowBackground(zeile)
                }

                Section {
                    Button {
                        fehlerText = ""
                        zeigeEinfuegen = true
                    } label: {
                        Label("JSON einfügen und veröffentlichen", systemImage: "doc.on.clipboard")
                    }
                } footer: {
                    Text("Das JSON von Claude einfügen. Es landet direkt in der Cloud und auch hier auf dem Gerät.")
                }
                .listRowBackground(zeile)

                Section {
                    if eigene.isEmpty {
                        Text("Keine Klassenarbeit auf diesem Gerät.")
                            .foregroundStyle(Theme.textSanft)
                    }
                    ForEach(eigene) { a in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.titel).font(.headline)
                                Text("\(a.klasse), \(a.fach)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSanft)
                            }
                            Spacer()
                            if inCloud(a) {
                                Image(systemName: "checkmark.icloud.fill").foregroundStyle(Theme.mint)
                            }
                            Menu(inCloud(a) ? "Erneut senden" : "Senden") {
                                Button("An meine Familie") { Task { await hochladen(a, klasse: false) } }
                                if CloudDienst.klassenCloudCode != nil {
                                    Button("An die Klasse") { Task { await hochladen(a, klasse: true) } }
                                }
                            }
                            .disabled(arbeitet)
                        }
                    }
                } header: {
                    Text("Auf diesem Gerät")
                } footer: {
                    Text("Kind-Geräte laden nur Pakete, die sie noch nicht haben. Vorhandene bleiben mit Fortschritt unverändert.")
                }
                .listRowBackground(zeile)

                Section {
                    if cloud.isEmpty {
                        Text("Noch nichts in der Cloud.").foregroundStyle(Theme.textSanft)
                    }
                    ForEach(cloud) { p in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.titel).font(.headline)
                            Text("\(p.klasse), \(p.fach)")
                                .font(.caption)
                                .foregroundStyle(Theme.textSanft)
                        }
                    }
                    .onDelete { offsets in
                        let ziele = offsets.map { cloud[$0] }
                        Task {
                            for p in ziele { try? await CloudDienst.loeschePaket(id: p.id) }
                            await laden()
                        }
                    }
                } header: {
                    Text("In der Cloud")
                } footer: {
                    Text("Nach links wischen entfernt ein Paket aus der Cloud. Auf den Kind-Geräten bleibt es erhalten.")
                }
                .listRowBackground(zeile)

                if CloudDienst.klassenCloudCode != nil {
                    Section {
                        if klassenCloud.isEmpty {
                            Text("Noch nichts beim Klassencode.").foregroundStyle(Theme.textSanft)
                        }
                        ForEach(klassenCloud) { p in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(p.titel).font(.headline)
                                Text("\(p.klasse), \(p.fach)")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }
                        .onDelete { offsets in
                            let ziele = offsets.map { klassenCloud[$0] }
                            Task {
                                for p in ziele { try? await CloudDienst.loeschePaket(id: p.id) }
                                await laden()
                            }
                        }
                    } header: {
                        Text("Bei der Klasse")
                    } footer: {
                        Text("Diese Pakete laden alle Geräte mit deinem Klassencode. Nur du kannst deine Pakete ändern oder löschen.")
                    }
                    .listRowBackground(zeile)
                }

                if !meldung.isEmpty {
                    Section { Text(meldung).font(.footnote) }
                        .listRowBackground(zeile)
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Cloud-Pakete")
        .navigationBarTitleDisplayMode(.inline)
        .task { await laden() }
        .refreshable { await laden() }
        .sheet(isPresented: $zeigeEinfuegen) { einfuegenSheet }
    }

    private var einfuegenSheet: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                VStack(alignment: .leading, spacing: 10) {
                    Button("Aus Zwischenablage einfügen") {
                        eingabe = UIPasteboard.general.string ?? ""
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    if CloudDienst.klassenCloudCode != nil {
                        Toggle("An die Klasse statt an meine Familie", isOn: $fuerKlasse)
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                    }
                    TextEditor(text: $eingabe)
                        .font(.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(Color.white.opacity(0.08),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    if !fehlerText.isEmpty {
                        Text(fehlerText)
                            .font(.footnote)
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .padding()
            }
            .navigationTitle("JSON veröffentlichen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { zeigeEinfuegen = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(arbeitet ? "Bitte warten ..." : "Veröffentlichen") {
                        Task { await veroeffentlichen() }
                    }
                    .disabled(arbeitet || eingabe.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }

    private func laden() async {
        do {
            if Familiencode.istGueltig(familienCode) {
                cloud = try await CloudDienst.ladePakete(code: familienCode)
            }
            if let k = CloudDienst.klassenCloudCode {
                klassenCloud = try await CloudDienst.ladePakete(code: k)
            }
        } catch {
            meldung = CloudDienst.fehlertext(error)
        }
    }

    // Zielcode: Klassencode oder Familiencode
    private func zielCode(klasse: Bool) -> String? {
        if klasse { return CloudDienst.klassenCloudCode }
        return Familiencode.istGueltig(familienCode) ? familienCode : nil
    }

    private func hochladen(_ a: Klassenarbeit, klasse: Bool) async {
        guard let ziel = zielCode(klasse: klasse) else {
            meldung = klasse ? "Bitte zuerst einen Klassencode eintragen." : "Bitte zuerst einen Familiencode eintragen."
            return
        }
        guard let json = PaketJSON.text(von: a),
              let daten = json.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten) else {
            meldung = "Das Paket konnte nicht erstellt werden."
            return
        }
        arbeitet = true
        meldung = "Wird hochgeladen ..."
        do {
            try await CloudDienst.hochladen(code: ziel, paket: paket, json: json)
            meldung = klasse ? "\(a.titel) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                             : "\(a.titel) ist in der Cloud. Die Kind-Geräte laden es automatisch."
            await laden()
        } catch {
            meldung = "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        arbeitet = false
    }

    private func veroeffentlichen() async {
        guard let ziel = zielCode(klasse: fuerKlasse) else {
            fehlerText = fuerKlasse ? "Bitte zuerst einen Klassencode eintragen." : "Bitte zuerst einen Familiencode eintragen."
            return
        }
        let text = PaketJSON.bereinigt(eingabe)
        guard let daten = text.data(using: .utf8),
              let paket = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
              !paket.uebungen.isEmpty,
              paket.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else {
            fehlerText = "Das Format passt nicht. Es geht um Klassenarbeiten und Übungssets, bitte das JSON von Claude komplett kopieren."
            return
        }
        fehlerText = ""
        arbeitet = true
        do {
            try await CloudDienst.hochladen(code: ziel, paket: paket, json: text)
            if !PaketImport.vorhanden(klasse: paket.klasse, fach: paket.fach, titel: paket.arbeit, in: context) {
                PaketImport.einfuegen(paket, in: context)
                try? context.save()
            }
            meldung = fuerKlasse ? "\(paket.arbeit) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                                 : "\(paket.arbeit) ist in der Cloud. Die Kind-Geräte laden es automatisch."
            eingabe = ""
            zeigeEinfuegen = false
            await laden()
        } catch {
            fehlerText = "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        arbeitet = false
    }
}

// ============================================================
// MARK: - Joker-Nachschub und Cloud-Diagnose
// ============================================================

struct CloudNachschub: Identifiable {
    let id: String
    let kind: String
    let erstellt: Date
}

extension CloudDienst {
    static func sendeNachschub(code: String, kind: String) async throws {
        let r = CKRecord(recordType: "JokerNachschub")
        r["familienCode"] = code as CKRecordValue
        r["kind"] = kind as CKRecordValue
        _ = try await db.save(r)
    }

    static func sendeFreigabe(code: String) async throws {
        let r = CKRecord(recordType: "JokerFreigabe")
        r["familienCode"] = code as CKRecordValue
        r["anzahl"] = 3 as CKRecordValue
        _ = try await db.save(r)
    }

    static func ladeNachschub(code: String) async throws -> [CloudNachschub] {
        let records = try await holeRecords("JokerNachschub", code: code, limit: 100)
        var liste: [CloudNachschub] = []
        for r in records {
            liste.append(CloudNachschub(id: r.recordID.recordName,
                                        kind: (r["kind"] as? String) ?? "Kind",
                                        erstellt: r.creationDate ?? Date.distantPast))
        }
        return liste
    }

    static func ladeFreigaben(code: String) async throws -> [Date] {
        let records = try await holeRecords("JokerFreigabe", code: code, limit: 100)
        var liste: [Date] = []
        for r in records {
            liste.append(r.creationDate ?? Date.distantPast)
        }
        return liste
    }
}

// Eltern: Joker des Kindes wieder auffüllen, auf Anfrage oder jederzeit
struct JokerNachschubView: View {
    private let cloud = JokerCloud.shared
    @AppStorage("familienCode") private var familienCode = ""
    @State private var info = ""
    @State private var laeuft = false

    private var offene: [CloudNachschub] {
        let letzte = cloud.freigaben.max() ?? Date.distantPast
        return cloud.nachschub.filter { $0.erstellt > letzte }.sorted { $0.erstellt > $1.erstellt }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Joker-Nachschub")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            if let a = offene.first {
                Text("\(a.kind) hat keine Joker mehr und fragt nach neuen (\(a.erstellt.formatted(.relative(presentation: .named)))).")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
            } else {
                Text("Keine offene Anfrage. Du kannst die Joker trotzdem jederzeit auffüllen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Button {
                Task { await freigeben() }
            } label: {
                Text(laeuft ? "Bitte warten ..." : "Joker wieder auf 3 auffüllen")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(laeuft || !Familiencode.istGueltig(familienCode))
            if !info.isEmpty {
                Text(info)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func freigeben() async {
        laeuft = true
        do {
            try await CloudDienst.sendeFreigabe(code: familienCode)
            Haptik.erfolg()
            info = "Freigegeben. Das Kind-Gerät füllt die Joker auf, sobald es online ist."
            await cloud.aktualisieren()
        } catch {
            info = "Freigabe nicht möglich: \(CloudDienst.fehlertext(error))"
        }
        laeuft = false
    }
}

// In den Einstellungen: Cloud prüfen und neu einrichten, damit das Kind nicht versehentlich darauf tippt
struct CloudDiagnoseView: View {
    @State private var testMeldung = ""
    @State private var testet = false

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CloudStatusKarte()
                    PushDiagnoseKarte()
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Verbindungstest")
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        Text("Schreibt einen Test-Datensatz in die Cloud und zeigt, ob die Verbindung steht.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                        Button {
                            Task {
                                testet = true
                                testMeldung = await CloudKitDienst.verbindungTesten()
                                testet = false
                            }
                        } label: {
                            Text(testet ? "Bitte warten ..." : "CloudKit testen")
                                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.navy)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(Theme.gelb, in: Capsule())
                        }
                        .buttonStyle(TastenStil())
                        .disabled(testet)
                        if !testMeldung.isEmpty {
                            Text(testMeldung)
                                .font(.footnote)
                                .foregroundStyle(Theme.himmel)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glasKarte(radius: 26)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Cloud-Diagnose")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Zeigt, warum Mitteilungen ankommen oder nicht
struct PushDiagnoseKarte: View {
    @State private var erlaubnis = "wird geprüft ..."
    @State private var registrierung = "wird geprüft ..."
    @State private var abos = "wird geprüft ..."
    @State private var testInfo = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mitteilungen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            zeile("Erlaubnis", erlaubnis)
            zeile("Anmeldung bei Apple", registrierung)
            zeile("Abos in der Cloud", abos)
            HStack(spacing: 10) {
                Button { Task { await pruefen() } } label: { knopf("Prüfen") }
                    .buttonStyle(TastenStil())
                Button { Task { await testSenden() } } label: { knopf("Test in 5 Sekunden") }
                    .buttonStyle(TastenStil())
            }
            if !testInfo.isEmpty {
                Text(testInfo)
                    .font(.footnote)
                    .foregroundStyle(Theme.himmel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
        .task { await pruefen() }
    }

    private func zeile(_ titel: String, _ wert: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.textSanft)
            Text(wert)
                .font(.footnote)
                .foregroundStyle(Color.white)
        }
    }

    private func knopf(_ titel: String) -> some View {
        Text(titel)
            .font(.system(.footnote, design: .rounded).weight(.heavy))
            .foregroundStyle(Theme.navy)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Theme.gelb, in: Capsule())
    }

    private func pruefen() async {
        let einstellungen = await UNUserNotificationCenter.current().notificationSettings()
        switch einstellungen.authorizationStatus {
        case .authorized: erlaubnis = "erlaubt"
        case .denied: erlaubnis = "ABGELEHNT. Bitte in den iPhone-Einstellungen unter Mitteilungen bei YEM1N erlauben."
        case .notDetermined: erlaubnis = "noch nicht gefragt. Bitte Cloud neu einrichten."
        case .provisional: erlaubnis = "vorläufig erlaubt"
        case .ephemeral: erlaubnis = "vorübergehend erlaubt"
        @unknown default: erlaubnis = "unbekannt"
        }
        registrierung = UserDefaults.standard.string(forKey: "pushStatus") ?? "noch keine Rückmeldung von Apple"
        do {
            let alle = try await CloudDienst.db.allSubscriptions()
            abos = alle.isEmpty ? "keine" : alle.map { $0.subscriptionID }.sorted().joined(separator: "\n")
        } catch {
            abos = "Fehler: \(error.localizedDescription)"
        }
    }

    private func testSenden() async {
        let inhalt = UNMutableNotificationContent()
        inhalt.title = "YEM1N"
        inhalt.body = "Test: So sieht eine Mitteilung aus."
        inhalt.sound = .default
        let anfrage = UNNotificationRequest(identifier: UUID().uuidString, content: inhalt,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        do {
            try await UNUserNotificationCenter.current().add(anfrage)
            testInfo = "Kommt in 5 Sekunden. Sperre das iPhone oder bleib in der App, beides sollte ein Banner zeigen."
        } catch {
            testInfo = "Test nicht möglich: \(error.localizedDescription)"
        }
    }
}

// Wischen zum Erledigen: Karte nach links oder rechts ziehen
struct WischErledigt: ViewModifier {
    let aktion: () -> Void
    @State private var versatz: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: versatz)
            .opacity(1 - min(abs(versatz) / 300, 0.6))
            .simultaneousGesture(
                DragGesture(minimumDistance: 24)
                    .onChanged { wert in
                        if abs(wert.translation.width) > abs(wert.translation.height) {
                            versatz = wert.translation.width
                        }
                    }
                    .onEnded { wert in
                        let waagrecht = abs(wert.translation.width) > abs(wert.translation.height)
                        if waagrecht && abs(wert.translation.width) > 110 {
                            withAnimation(.easeOut(duration: 0.2)) {
                                versatz = wert.translation.width > 0 ? 500 : -500
                            }
                            Task {
                                try? await Task.sleep(for: .milliseconds(220))
                                aktion()
                                versatz = 0
                            }
                        } else {
                            withAnimation(.snappy) { versatz = 0 }
                        }
                    }
            )
    }
}

extension View {
    func wischErledigt(_ aktion: @escaping () -> Void) -> some View {
        modifier(WischErledigt(aktion: aktion))
    }
}

extension CloudDienst {
    // Name des Elternteils auf diesem Gerät, so wie er bei Joker-Antworten verwendet wird
    static func ichName() -> String {
        let id = UserDefaults.standard.string(forKey: "jokerIch") ?? ""
        let liste = JokerStand.shared.mitglieder
        return liste.first(where: { $0.id.uuidString == id })?.name ?? liste.first?.name ?? "Papa"
    }

    // Merker, damit die Cloud neu eingerichtet wird, wenn sich Modus, Familiencode oder Elternteil ändern
    static func marke(modus: String, code: String) -> String {
        modus + "|" + code + "|v4|" + (modus == "eltern" ? ichName() : "")
    }

    // Mitteilung nur an den Elternteil, dessen Tipp mit 👍 bewertet wurde
    static func aboDaumen(code: String, name: String) async throws {
        let predicate = NSPredicate(format: "familienCode == %@ AND absender == %@", code, name)
        let abo = CKQuerySubscription(recordType: "JokerDaumen", predicate: predicate,
                                      subscriptionID: "JokerDaumen-\(code)-\(name)",
                                      options: [.firesOnRecordCreation])
        let info = CKSubscription.NotificationInfo()
        info.alertBody = "👍 Dein Tipp hat geholfen! Das gibt Extra-Punkte in der Joker-Liga."
        info.soundName = "default"
        info.shouldBadge = true
        info.shouldSendContentAvailable = true
        abo.notificationInfo = info
        _ = try await db.save(abo)
    }
}

// ============================================================
// MARK: - Fehlerheft, Training, Probearbeit
// ============================================================

@MainActor
enum Spezial {
    // Eindeutiger Schlüssel einer Originalaufgabe
    static func schluessel(_ a: Aufgabe) -> String {
        let u = a.uebung
        let k = u?.arbeit
        return [k?.klasse ?? "", k?.fach ?? "", k?.titel ?? "", u?.titel ?? "", String(a.reihenfolge)]
            .joined(separator: "|")
    }

    static func kopie(_ a: Aufgabe, reihenfolge: Int) -> Aufgabe {
        let neu = Aufgabe(art: a.art, frage: a.frage, rechnung: a.rechnung, hinweis: a.hinweis,
                          erklaerung: a.erklaerung, antwort: a.antwort, antwort2: a.antwort2,
                          reihenJSON: a.reihenJSON, reihenfolge: reihenfolge)
        neu.quellKey = schluessel(a)
        return neu
    }

    static func aufgabe(_ m: MatheAufgabe, reihenfolge: Int) -> Aufgabe {
        var reihenJSON = ""
        if !m.reihen.isEmpty,
           let daten = try? JSONEncoder().encode(m.reihen),
           let text = String(data: daten, encoding: .utf8) {
            reihenJSON = text
        }
        return Aufgabe(art: m.art, frage: m.frage, rechnung: m.rechnung, hinweis: m.hinweis,
                       erklaerung: m.erklaerung, antwort: m.antwort, antwort2: m.antwort2,
                       reihenJSON: reihenJSON, reihenfolge: reihenfolge)
    }

    // Wird aufgerufen, wenn eine Aufgabe richtig beantwortet wurde
    static func gemeistert(_ a: Aufgabe, in context: ModelContext) {
        guard !a.quellKey.isEmpty else { return }
        let alle = (try? context.fetch(FetchDescriptor<Aufgabe>())) ?? []
        for o in alle where o.quellKey.isEmpty && schluessel(o) == a.quellKey {
            o.gemeistert = true
        }
    }

    static func note(gut: Int, gesamt: Int) -> Int {
        guard gesamt > 0 else { return 6 }
        let anteil = Double(gut) / Double(gesamt)
        if anteil >= 0.95 { return 1 }
        if anteil >= 0.82 { return 2 }
        if anteil >= 0.67 { return 3 }
        if anteil >= 0.50 { return 4 }
        if anteil >= 0.25 { return 5 }
        return 6
    }

    private static func neueArbeit(titel: String, art: String, klasse: String, fach: String = "Mathe",
                                   in context: ModelContext) -> Klassenarbeit {
        let arbeit = Klassenarbeit(klasse: klasse, fach: fach, titel: titel)
        arbeit.spezial = art
        context.insert(arbeit)
        return arbeit
    }

    private static func neueUebung(_ arbeit: Klassenarbeit, titel: String, gruppe: String,
                                   symbol: String, tipp: String, reihenfolge: Int,
                                   in context: ModelContext) -> Uebung {
        let u = Uebung(titel: titel, gruppe: gruppe, symbol: symbol, tipp: tipp, reihenfolge: reihenfolge)
        context.insert(u)
        u.arbeit = arbeit
        return u
    }

    private static func klasseVon(_ alle: [Klassenarbeit]) -> String {
        let eigene = (UserDefaults.standard.string(forKey: "kindKlasse") ?? "")
            .trimmingCharacters(in: .whitespaces)
        if !eigene.isEmpty { return eigene }
        return alle.first?.klasse ?? "Klasse 3"
    }

    // Fehlerheft: bis zu 15 noch nicht gemeisterte Fehler als neue Runde
    static func fehlerheft(alle: [Klassenarbeit], in context: ModelContext) -> Klassenarbeit? {
        var fehler: [Aufgabe] = []
        for k in alle {
            for u in k.sortierteUebungen {
                for a in u.sortierteAufgaben where a.richtig == false && !a.gemeistert {
                    fehler.append(a)
                }
            }
        }
        guard !fehler.isEmpty else { return nil }
        fehler.shuffle()
        let auswahl = Array(fehler.prefix(15))
        var faecher = Set<String>()
        for a in auswahl { if let f = a.uebung?.arbeit?.fach { faecher.insert(f) } }
        let fach = faecher.count == 1 ? (faecher.first ?? "Mathe") : "Gemischt"
        let arbeit = neueArbeit(titel: "Fehlerheft", art: "fehlerheft", klasse: klasseVon(alle), fach: fach, in: context)
        let u = neueUebung(arbeit, titel: "Fehlerheft", gruppe: "Nochmal versuchen", symbol: "✎",
                           tipp: "Schau dir die Erklärung genau an.", reihenfolge: 0, in: context)
        for (i, a) in auswahl.enumerated() {
            let k = kopie(a, reihenfolge: i)
            context.insert(k)
            k.uebung = u
        }
        return arbeit
    }

    // Training: neue Aufgaben zu den zwei schwächsten Bereichen
    static func training(alle: [Klassenarbeit], ergebnisse: [RundenErgebnis], in context: ModelContext) -> Klassenarbeit {
        let gruppiert = Dictionary(grouping: ergebnisse, by: { $0.uebung })
        var wertung: [(MatheVorlage, Double)] = []
        for v in MatheGenerator.vorlagen where v.id != "gemischt" {
            if let liste = gruppiert[v.name], !liste.isEmpty {
                let r = liste.reduce(0) { $0 + $1.richtig }
                let g = liste.reduce(0) { $0 + $1.gesamt }
                wertung.append((v, g > 0 ? Double(r) / Double(g) : 1.0))
            }
        }
        wertung.sort { $0.1 < $1.1 }
        var picks: [MatheVorlage] = []
        for (v, anteil) in wertung where anteil < 0.95 && picks.count < 2 {
            picks.append(v)
        }
        var rest = MatheGenerator.vorlagen.filter { $0.id != "gemischt" }
        rest.shuffle()
        for v in rest where picks.count < 2 {
            if !picks.contains(where: { $0.id == v.id }) { picks.append(v) }
        }
        let arbeit = neueArbeit(titel: "Training heute", art: "training", klasse: klasseVon(alle), in: context)
        for (i, v) in picks.enumerated() {
            var sperre = Set<String>()
            let aufgaben = MatheGenerator.fuelle(v, anzahl: 8, ausschluss: &sperre)
            let u = neueUebung(arbeit, titel: v.name, gruppe: "Training", symbol: v.symbol,
                               tipp: v.tipp, reihenfolge: i, in: context)
            for (j, m) in aufgaben.enumerated() {
                let a = aufgabe(m, reihenfolge: j)
                context.insert(a)
                a.uebung = u
            }
        }
        return arbeit
    }

    // Probearbeit: 20 neue Aufgaben quer durch alle Bereiche, mit Uhr und Note
    static func probe(alle: [Klassenarbeit], in context: ModelContext) -> Klassenarbeit {
        let plan: [(String, Int)] = [
            ("minuswort", 1), ("malwort", 1), ("kern", 1), ("nachbar", 1), ("einmaleins", 3),
            ("umkehr", 2), ("rest", 3), ("punkt", 2), ("vergleich", 2), ("mauer", 1),
            ("raetsel", 1), ("sach", 2)
        ]
        var sperre = vorhandeneSchluessel(alle)
        let arbeit = neueArbeit(titel: "Probearbeit", art: "probe", klasse: klasseVon(alle), in: context)
        let u = neueUebung(arbeit, titel: "Probearbeit", gruppe: "Wie in der Klassenarbeit", symbol: "★",
                           tipp: "", reihenfolge: 0, in: context)
        var nummer = 0
        for (id, anzahl) in plan {
            guard let v = MatheGenerator.vorlagen.first(where: { $0.id == id }) else { continue }
            let aufgaben = MatheGenerator.fuelle(v, anzahl: anzahl, ausschluss: &sperre)
            for m in aufgaben {
                let a = aufgabe(m, reihenfolge: nummer)
                context.insert(a)
                a.uebung = u
                nummer += 1
            }
        }
        return arbeit
    }
}

// ============================================================
// MARK: - Erfolge: Serie, Tagesziel, Pokale
// ============================================================

struct Pokal: Identifiable {
    let id: String
    let emoji: String
    let titel: String
    let erreicht: Bool
}

enum Erfolge {
    static func tageMitRunde(_ liste: [RundenErgebnis]) -> Set<Date> {
        let kal = Calendar.current
        var tage = Set<Date>()
        for e in liste { tage.insert(kal.startOfDay(for: e.zeitpunkt)) }
        return tage
    }

    // Aufeinanderfolgende Tage mit mindestens einer Runde, bis heute oder gestern
    static func serie(_ liste: [RundenErgebnis]) -> Int {
        let kal = Calendar.current
        let tage = tageMitRunde(liste)
        var tag = kal.startOfDay(for: Date.now)
        if !tage.contains(tag) {
            tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag
        }
        var n = 0
        while tage.contains(tag) {
            n += 1
            tag = kal.date(byAdding: .day, value: -1, to: tag) ?? tag.addingTimeInterval(-86400)
        }
        return n
    }

    static func besteSerie(_ liste: [RundenErgebnis]) -> Int {
        let kal = Calendar.current
        let tage = tageMitRunde(liste).sorted()
        var beste = 0
        var aktuell = 0
        var vorher: Date?
        for t in tage {
            if let v = vorher, kal.date(byAdding: .day, value: 1, to: v) == t {
                aktuell += 1
            } else {
                aktuell = 1
            }
            beste = max(beste, aktuell)
            vorher = t
        }
        return beste
    }

    static func rundenHeute(_ liste: [RundenErgebnis]) -> Int {
        liste.filter { Calendar.current.isDateInToday($0.zeitpunkt) }.count
    }

    static func zieltage(_ liste: [RundenErgebnis], ziel: Int) -> Int {
        let kal = Calendar.current
        var zaehler: [Date: Int] = [:]
        for e in liste { zaehler[kal.startOfDay(for: e.zeitpunkt), default: 0] += 1 }
        return zaehler.values.filter { $0 >= ziel }.count
    }

    static func pokale(_ liste: [RundenErgebnis], ziel: Int) -> [Pokal] {
        let n = liste.count
        let sterne = liste.reduce(0) { $0 + $1.sterne }
        let beste = besteSerie(liste)
        let dreiSterne = liste.contains { $0.sterne == 3 }
        let fehlerfrei = liste.contains { $0.gesamt > 0 && $0.richtig == $0.gesamt && $0.angesehen == 0 }
        let zielTage = zieltage(liste, ziel: ziel)
        return [
            Pokal(id: "erste", emoji: "🎯", titel: "Erste Runde", erreicht: n >= 1),
            Pokal(id: "r10", emoji: "🥉", titel: "10 Runden", erreicht: n >= 10),
            Pokal(id: "r50", emoji: "🥈", titel: "50 Runden", erreicht: n >= 50),
            Pokal(id: "r100", emoji: "🥇", titel: "100 Runden", erreicht: n >= 100),
            Pokal(id: "s3", emoji: "🔥", titel: "3 Tage in Folge", erreicht: beste >= 3),
            Pokal(id: "s7", emoji: "⚡", titel: "7 Tage in Folge", erreicht: beste >= 7),
            Pokal(id: "s14", emoji: "👑", titel: "14 Tage in Folge", erreicht: beste >= 14),
            Pokal(id: "s30", emoji: "🏆", titel: "30 Tage in Folge", erreicht: beste >= 30),
            Pokal(id: "stern", emoji: "⭐", titel: "3 Sterne", erreicht: dreiSterne),
            Pokal(id: "st50", emoji: "🌟", titel: "50 Sterne", erreicht: sterne >= 50),
            Pokal(id: "st150", emoji: "💫", titel: "150 Sterne", erreicht: sterne >= 150),
            Pokal(id: "fehlerfrei", emoji: "💯", titel: "Ohne Fehler", erreicht: fehlerfrei),
            Pokal(id: "ziel5", emoji: "🎉", titel: "Tagesziel 5 Tage", erreicht: zielTage >= 5)
        ]
    }
}

struct ErfolgeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<RundenErgebnis> { $0.quelle == "lokal" })
    private var lokale: [RundenErgebnis]
    @AppStorage("tagesziel") private var ziel = 2
    @AppStorage("kindName") private var kindName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        serieKarte
                        zielKarte
                        pokaleKarte
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(kindName.isEmpty ? "Meine Erfolge" : "Erfolge von \(kindName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var serieKarte: some View {
        let serie = Erfolge.serie(lokale)
        return HStack(spacing: 16) {
            Text("🔥").font(.system(size: 46))
            VStack(alignment: .leading, spacing: 2) {
                Text(serie == 1 ? "1 Tag in Folge" : "\(serie) Tage in Folge")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text("Beste Serie: \(Erfolge.besteSerie(lokale))")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var zielKarte: some View {
        let heute = Erfolge.rundenHeute(lokale)
        let anteil = min(Double(heute) / Double(max(ziel, 1)), 1)
        return HStack(spacing: 16) {
            ZStack {
                Fortschrittsring(wert: anteil, breite: 8)
                Text("\(heute)/\(ziel)")
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 2) {
                Text("Tagesziel")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text(heute >= ziel ? "Geschafft! 🎉" : "Noch \(ziel - heute) \(ziel - heute == 1 ? "Runde" : "Runden")")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var pokaleKarte: some View {
        let liste = Erfolge.pokale(lokale, ziel: ziel)
        let geschafft = liste.filter { $0.erreicht }.count
        return VStack(alignment: .leading, spacing: 12) {
            Text("Pokale: \(geschafft) von \(liste.count)")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(liste) { p in
                    VStack(spacing: 4) {
                        Text(p.emoji)
                            .font(.system(size: 34))
                            .opacity(p.erreicht ? 1 : 0.25)
                        Text(p.titel)
                            .font(.system(.caption, design: .rounded).weight(.heavy))
                            .foregroundStyle(p.erreicht ? Color.white : Theme.textSanft)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .padding(6)
                    .background(Color.white.opacity(p.erreicht ? 0.12 : 0.05),
                                in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }
}

// ============================================================
// MARK: - Pakete aus Zwischenablage oder Datei, Wochenbericht, Notizblock
// ============================================================

@MainActor
enum PaketAktion {
    static func lese(_ roh: String) -> (paket: ArbeitPaket, text: String)? {
        let text = PaketJSON.bereinigt(roh)
        guard let daten = text.data(using: .utf8),
              let p = try? JSONDecoder().decode(ArbeitPaket.self, from: daten),
              !p.uebungen.isEmpty,
              p.uebungen.allSatisfy({ !$0.aufgaben.isEmpty }) else { return nil }
        // Vorschul-Aufgaben: 2 bis 4 Knöpfe, die Antwort muss einer davon sein
        for u in p.uebungen {
            for a in u.aufgaben where a.art == "wahl" {
                guard let o = a.optionen, (2...4).contains(o.count),
                      let r = a.antwort, o.contains(r),
                      !(a.frage ?? "").isEmpty else { return nil }
            }
        }
        return (p, text)
    }

    static func anzahl(_ p: ArbeitPaket) -> Int {
        p.uebungen.reduce(0) { $0 + $1.aufgaben.count }
    }

    // Nur auf diesem Gerät importieren
    static func lokal(_ p: ArbeitPaket, context: ModelContext) -> String {
        if PaketImport.vorhanden(klasse: p.klasse, fach: p.fach, titel: p.arbeit, in: context) {
            return "\(p.arbeit) ist auf diesem Gerät schon vorhanden."
        }
        PaketImport.einfuegen(p, in: context)
        try? context.save()
        return "\(p.arbeit) wurde importiert."
    }

    // Eltern: in die Cloud stellen und auch hier importieren
    static func veroeffentliche(_ p: ArbeitPaket, text: String, context: ModelContext, klasse: Bool = false) async -> String {
        let familie = UserDefaults.standard.string(forKey: "familienCode") ?? ""
        let ziel: String
        if klasse {
            guard let k = CloudDienst.klassenCloudCode else {
                return "Bitte zuerst im Tab Einstellungen einen Klassencode eintragen oder erzeugen."
            }
            ziel = k
        } else {
            guard Familiencode.istGueltig(familie) else {
                return "Bitte zuerst im Tab Einstellungen einen Familiencode eintragen."
            }
            ziel = familie
        }
        do {
            try await CloudDienst.hochladen(code: ziel, paket: p, json: text)
            if !PaketImport.vorhanden(klasse: p.klasse, fach: p.fach, titel: p.arbeit, in: context) {
                PaketImport.einfuegen(p, in: context)
                try? context.save()
            }
            return klasse ? "\(p.arbeit) ist beim Klassencode. Alle Geräte mit diesem Code laden es automatisch."
                          : "\(p.arbeit) ist in der Cloud. Die Kind-Geräte laden es automatisch."
        } catch {
            return "Hochladen nicht möglich: \(CloudDienst.fehlertext(error))"
        }
    }
}

enum Wochenbericht {
    // Erinnerung jeden Sonntag um 18 Uhr, der Bericht selbst steht im Eltern-Dashboard
    static func planen() async {
        let zentrale = UNUserNotificationCenter.current()
        let einstellungen = await zentrale.notificationSettings()
        guard einstellungen.authorizationStatus == .authorized else { return }
        let inhalt = UNMutableNotificationContent()
        inhalt.title = "📊 Euer YEM1N-Wochenbericht"
        inhalt.body = "Die Woche ist geschafft. Tippe, um zu sehen, wie sie gelaufen ist."
        inhalt.sound = .default
        var d = DateComponents()
        d.weekday = 1
        d.hour = 18
        d.minute = 0
        let ausloeser = UNCalendarNotificationTrigger(dateMatching: d, repeats: true)
        let anfrage = UNNotificationRequest(identifier: "wochenbericht", content: inhalt, trigger: ausloeser)
        try? await zentrale.add(anfrage)
    }
}

// Notizblock zum Rechnen mit Finger oder Apple Pencil
struct NotizblockView: UIViewRepresentable {
    @Binding var zeichnung: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        let c = PKCanvasView()
        c.drawingPolicy = .anyInput
        c.backgroundColor = .clear
        c.isOpaque = false
        c.drawing = zeichnung
        c.tool = PKInkingTool(.pen, color: .white, width: 4)
        c.delegate = context.coordinator
        return c
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != zeichnung {
            uiView.drawing = zeichnung
        }
    }

    func makeCoordinator() -> Koordinator { Koordinator(self) }

    final class Koordinator: NSObject, PKCanvasViewDelegate {
        var eltern: NotizblockView
        init(_ eltern: NotizblockView) { self.eltern = eltern }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            eltern.zeichnung = canvasView.drawing
        }
    }
}

// ============================================================
// MARK: - Vorschule (Zählen, Zuordnen, Muster, Memory für die Kleinen)
// ============================================================

enum VorschulArt: String, CaseIterable, Identifiable, Hashable {
    case mix, zaehlen, zahlen, plus, mehr, nachbar, formen, anlaut, anders, muster, memory

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .mix: return "Alles gemischt"
        case .zaehlen: return "Zählen"
        case .zahlen: return "Zahlen"
        case .plus: return "Plus"
        case .mehr: return "Mehr oder weniger"
        case .nachbar: return "Davor und danach"
        case .formen: return "Formen und Farben"
        case .anlaut: return "Anfangsbuchstaben"
        case .anders: return "Was passt nicht?"
        case .muster: return "Muster"
        case .memory: return "Memory"
        }
    }

    var emoji: String {
        switch self {
        case .mix: return "🎲"
        case .zaehlen: return "🍎"
        case .zahlen: return "🔢"
        case .plus: return "➕"
        case .mehr: return "⚖️"
        case .nachbar: return "↔️"
        case .formen: return "🎨"
        case .anlaut: return "🔤"
        case .anders: return "🧐"
        case .muster: return "🧩"
        case .memory: return "🃏"
        }
    }
}

struct VorschulText {
    let de: String
    let tr: String?
}

struct VorschulFrage: Identifiable {
    let id = UUID()
    var text: VorschulText
    var zeige: [String] = []
    var zeigeZwei: [String] = []
    var plus = false
    var gross = ""
    var folge: [String] = []
    var optionen: [String]
    var richtig: Int
    var gruppenOptionen = false

    var schluessel: String {
        text.de + "|" + zeige.joined() + "|" + zeigeZwei.joined() + "|" + gross + "|"
            + folge.joined() + "|" + optionen.joined(separator: ",")
    }
}

enum VorschulGenerator {
    static let dinge = ["🍎", "⭐", "🐶", "🎈", "🚗", "🐟", "🌸", "🍪", "🐱", "🍓"]

    static let formen: [(frageDe: String, frageTr: String, emoji: String)] = [
        ("Wo ist der Kreis?", "Daire hangisi?", "🔵"),
        ("Wo ist das Quadrat?", "Kare hangisi?", "🟩"),
        ("Wo ist das Dreieck?", "Üçgen hangisi?", "🔺"),
        ("Wo ist der Stern?", "Yıldız hangisi?", "⭐"),
        ("Wo ist das Herz?", "Kalp hangisi?", "💜")
    ]

    static let farben: [(frageDe: String, frageTr: String, emoji: String)] = [
        ("Tippe auf Rot.", "Kırmızı olanı bul.", "🔴"),
        ("Tippe auf Blau.", "Mavi olanı bul.", "🔵"),
        ("Tippe auf Gelb.", "Sarı olanı bul.", "🟡"),
        ("Tippe auf Grün.", "Yeşil olanı bul.", "🟢"),
        ("Tippe auf Lila.", "Mor olanı bul.", "🟣"),
        ("Tippe auf Orange.", "Turuncu olanı bul.", "🟠")
    ]

    static let anlaute: [(emoji: String, wort: String, buchstabe: String)] = [
        ("🍎", "Apfel", "A"), ("🚗", "Auto", "A"), ("🐻", "Bär", "B"), ("🍌", "Banane", "B"),
        ("🎈", "Ballon", "B"), ("🪁", "Drachen", "D"), ("🐘", "Elefant", "E"), ("🦆", "Ente", "E"),
        ("🐟", "Fisch", "F"), ("🐸", "Frosch", "F"), ("🐶", "Hund", "H"), ("🏠", "Haus", "H"),
        ("🦔", "Igel", "I"), ("🐱", "Katze", "K"), ("🐄", "Kuh", "K"), ("🦁", "Löwe", "L"),
        ("🐭", "Maus", "M"), ("🌙", "Mond", "M"), ("👃", "Nase", "N"), ("🍊", "Orange", "O"),
        ("🐴", "Pferd", "P"), ("🐧", "Pinguin", "P"), ("🌹", "Rose", "R"), ("🌈", "Regenbogen", "R"),
        ("🌞", "Sonne", "S"), ("🧦", "Socke", "S"), ("🐯", "Tiger", "T"), ("🍅", "Tomate", "T"),
        ("⏰", "Uhr", "U"), ("🐳", "Wal", "W"), ("☁️", "Wolke", "W"), ("🦓", "Zebra", "Z"),
        ("🚂", "Zug", "Z")
    ]

    static let gruppen: [[String]] = [
        ["🐶", "🐱", "🐭", "🐰", "🐻", "🦁"],
        ["🍎", "🍌", "🍓", "🍇", "🍊", "🍐"],
        ["🚗", "🚌", "🚲", "✈️", "🚂", "🚢"],
        ["🌹", "🌻", "🌷", "🌼"],
        ["⚽", "🏀", "🎾", "🏐"]
    ]

    static func grenze(_ stufe: Int) -> Int { stufe == 1 ? 5 : (stufe == 2 ? 10 : 20) }

    // Drei verschiedene Zahlen, eine davon ist richtig
    static func zahlenOptionen(richtig: Int, von: Int, bis: Int) -> (optionen: [String], index: Int) {
        var menge: Set<Int> = [richtig]
        var versuche = 0
        while menge.count < 3 && versuche < 200 {
            versuche += 1
            let abstand = Int.random(in: 1...3) * (Bool.random() ? 1 : -1)
            let z = richtig + abstand
            if z >= von && z <= bis { menge.insert(z) }
        }
        if menge.count < 3 {
            for z in von...bis where menge.count < 3 { menge.insert(z) }
        }
        let liste = Array(menge).shuffled()
        let idx = liste.firstIndex(of: richtig) ?? 0
        return (liste.map { String($0) }, idx)
    }

    // Emoji-Gruppe als Text, nach fünf Stück ein Zeilenumbruch
    static func gruppe(_ n: Int, _ emoji: String) -> String {
        var teile: [String] = []
        for i in 0..<n {
            teile.append(emoji)
            if (i + 1) % 5 == 0 && i + 1 < n { teile.append("\n") }
        }
        return teile.joined()
    }

    static func fragen(_ art: VorschulArt, stufe: Int, anzahl: Int = 8) -> [VorschulFrage] {
        let arten = VorschulArt.allCases.filter { $0 != .mix && $0 != .memory }
        var liste: [VorschulFrage] = []
        var gesehen = Set<String>()
        for _ in 0..<anzahl {
            var f = eine(art == .mix ? (arten.randomElement() ?? .zaehlen) : art, stufe: stufe)
            var versuche = 0
            while gesehen.contains(f.schluessel) && versuche < 10 {
                versuche += 1
                f = eine(art == .mix ? (arten.randomElement() ?? .zaehlen) : art, stufe: stufe)
            }
            gesehen.insert(f.schluessel)
            liste.append(f)
        }
        return liste
    }

    static func eine(_ art: VorschulArt, stufe: Int) -> VorschulFrage {
        switch art {
        case .zaehlen:
            let m = stufe == 1 ? 5 : 10
            let n = Int.random(in: 1...m)
            let e = dinge.randomElement() ?? "⭐"
            let o = zahlenOptionen(richtig: n, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "Wie viele siehst du?", tr: "Kaç tane görüyorsun?"),
                                 zeige: Array(repeating: e, count: n),
                                 optionen: o.optionen, richtig: o.index)

        case .zahlen:
            let m = grenze(stufe)
            let n = Int.random(in: 1...m)
            let o = zahlenOptionen(richtig: n, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "Tippe auf die \(n).", tr: "\(n) sayısına dokun."),
                                 optionen: o.optionen, richtig: o.index)

        case .plus:
            let m = grenze(stufe)
            var x = 1
            var y = 1
            if stufe == 3 {
                x = Int.random(in: 2...10)
                y = Int.random(in: 1...min(10, m - x))
            } else {
                x = Int.random(in: 1...(m - 1))
                y = Int.random(in: 1...(m - x))
            }
            let paar = dinge.shuffled()
            let o = zahlenOptionen(richtig: x + y, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "\(x) plus \(y). Wie viel ist das?", tr: "\(x) artı \(y) kaç eder?"),
                                 zeige: Array(repeating: paar[0], count: x),
                                 zeigeZwei: Array(repeating: paar[1], count: y),
                                 plus: true,
                                 optionen: o.optionen, richtig: o.index)

        case .mehr:
            let m = stufe == 1 ? 5 : 10
            let x = Int.random(in: 1...m)
            var y = Int.random(in: 1...m)
            while y == x { y = Int.random(in: 1...m) }
            let e = dinge.randomElement() ?? "🍎"
            let fragtMehr = Int.random(in: 0..<10) < 7
            let tausch = Bool.random()
            let a = tausch ? y : x
            let b = tausch ? x : y
            let idx: Int
            if fragtMehr { idx = a > b ? 0 : 1 } else { idx = a < b ? 0 : 1 }
            let text = fragtMehr
                ? VorschulText(de: "Wo sind mehr?", tr: "Hangisi daha fazla?")
                : VorschulText(de: "Wo sind weniger?", tr: "Hangisi daha az?")
            return VorschulFrage(text: text,
                                 optionen: [gruppe(a, e), gruppe(b, e)], richtig: idx,
                                 gruppenOptionen: true)

        case .nachbar:
            let m = grenze(stufe)
            let danach = Bool.random()
            let n = danach ? Int.random(in: 1...(m - 1)) : Int.random(in: 2...m)
            let ziel = danach ? n + 1 : n - 1
            let o = zahlenOptionen(richtig: ziel, von: 0, bis: m)
            let text = danach
                ? VorschulText(de: "Welche Zahl kommt nach der \(n)?", tr: "\(n) sayısından sonra hangi sayı gelir?")
                : VorschulText(de: "Welche Zahl kommt vor der \(n)?", tr: "\(n) sayısından önce hangi sayı gelir?")
            return VorschulFrage(text: text, gross: String(n), optionen: o.optionen, richtig: o.index)

        case .formen:
            let quelle = Bool.random() ? formen : farben
            let drei = Array(quelle.shuffled().prefix(3))
            let r = Int.random(in: 0..<3)
            return VorschulFrage(text: VorschulText(de: drei[r].frageDe, tr: drei[r].frageTr),
                                 optionen: drei.map { $0.emoji }, richtig: r)

        case .anlaut:
            let item = anlaute.randomElement() ?? anlaute[0]
            var buchstaben = Array(Set(anlaute.map { $0.buchstabe })).filter { $0 != item.buchstabe }
            buchstaben.shuffle()
            var optionen = Array(buchstaben.prefix(2)) + [item.buchstabe]
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Womit fängt \(item.wort) an?", tr: nil),
                                 gross: item.emoji,
                                 optionen: optionen, richtig: optionen.firstIndex(of: item.buchstabe) ?? 0)

        case .anders:
            let g = gruppen.shuffled()
            let eigene = Array(g[0].shuffled().prefix(3))
            let fremd = g[1].randomElement() ?? "🍎"
            var optionen = eigene + [fremd]
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Was passt nicht dazu?", tr: "Hangisi diğerlerine uymuyor?"),
                                 optionen: optionen, richtig: optionen.firstIndex(of: fremd) ?? 0)

        default:
            let p = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠", "⭐", "❤️", "🍎", "🐟"].shuffled()
            let a = p[0]
            let b = p[1]
            let c = p[2]
            let muster: [String]
            switch stufe {
            case 1: muster = [a, b]
            case 2: muster = Bool.random() ? [a, a, b] : [a, b, b]
            default: muster = [a, b, c]
            }
            let l = muster.count
            let anzahl = Int.random(in: (l + 1)...(2 * l + 1))
            let folge = (0..<anzahl).map { muster[$0 % l] }
            let richtig = muster[anzahl % l]
            var optionen = [richtig]
            for e in p where optionen.count < 3 && e != richtig { optionen.append(e) }
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Wie geht es weiter?", tr: "Sıradaki hangisi?"),
                                 folge: folge,
                                 optionen: optionen, richtig: optionen.firstIndex(of: richtig) ?? 0)
        }
    }
}

enum VorschulTon {
    static func sag(_ t: VorschulText) {
        let sprache = UserDefaults.standard.string(forKey: "vorschulSprache") ?? "de"
        if sprache == "tr", let tr = t.tr {
            Sprecher.shared.sprich(tr, code: "tr-TR")
        } else {
            Sprecher.shared.sprich(t.de, code: "de-DE")
        }
    }

    static func lob() {
        let lob: [VorschulText] = [
            VorschulText(de: "Super!", tr: "Harika!"),
            VorschulText(de: "Toll gemacht!", tr: "Aferin!"),
            VorschulText(de: "Richtig!", tr: "Doğru!"),
            VorschulText(de: "Prima!", tr: "Bravo!")
        ]
        sag(lob.randomElement() ?? lob[0])
    }

    static func nochmal() {
        sag(VorschulText(de: "Probier es noch einmal.", tr: "Bir daha dene."))
    }
}

struct EmojiReihen: View {
    let emojis: [String]
    var groesse: CGFloat = 38

    var body: some View {
        let reihen = stride(from: 0, to: emojis.count, by: 5).map {
            Array(emojis[$0..<min($0 + 5, emojis.count)])
        }
        VStack(spacing: 6) {
            ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                HStack(spacing: 6) {
                    ForEach(Array(reihe.enumerated()), id: \.offset) { _, e in
                        Text(e).font(.system(size: groesse))
                    }
                }
            }
        }
    }
}

enum VorschulPaket {
    // Aufgaben aus einem importierten Vorschul-Paket in Fragen für die Runde umwandeln
    static func fragen(_ u: Uebung) -> [VorschulFrage] {
        var liste: [VorschulFrage] = []
        for a in u.sortierteAufgaben where a.art == "wahl" {
            guard let d = a.reihenJSON.data(using: .utf8),
                  let opt = try? JSONDecoder().decode([String].self, from: d),
                  opt.count >= 2, opt.contains(a.antwort) else { continue }
            let gemischt = opt.shuffled()
            guard let richtig = gemischt.firstIndex(of: a.antwort) else { continue }
            var f = VorschulFrage(text: VorschulText(de: a.frage, tr: a.hinweis.isEmpty ? nil : a.hinweis),
                                  optionen: gemischt, richtig: richtig)
            f.gross = a.erklaerung
            f.folge = a.antwort2.split(separator: " ").map(String.init)
            let teile = a.rechnung.components(separatedBy: "+")
            func zeichen(_ t: String) -> [String] {
                t.filter { !$0.isWhitespace }.map { String($0) }
            }
            if teile.count == 2 {
                f.plus = true
                f.zeige = zeichen(teile[0])
                f.zeigeZwei = zeichen(teile[1])
            } else {
                f.zeige = zeichen(a.rechnung)
            }
            f.gruppenOptionen = opt.contains { $0.count > 2 }
            liste.append(f)
        }
        return liste.shuffled()
    }
}

struct VorschulPaketListe: View {
    let arbeit: Klassenarbeit

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(arbeit.sortierteUebungen) { u in
                        NavigationLink(value: u) {
                            HStack(spacing: 14) {
                                Text(u.symbol).font(.system(size: 40))
                                Text(u.titel)
                                    .font(.system(.title3, design: .rounded).weight(.heavy))
                                    .foregroundStyle(Color.white)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(Theme.gelb)
                            }
                            .padding(16)
                            .glasKarte(radius: 24)
                        }
                        .buttonStyle(TastenStil())
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(arbeit.titel)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VorschuleView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Klassenarbeit.erstellt) private var alleArbeiten: [Klassenarbeit]
    @State private var loeschen: Klassenarbeit?
    @AppStorage("vorschulStufe") private var stufe = 2
    @AppStorage("vorschulSprache") private var sprache = "de"
    @AppStorage("kindName") private var kindName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        auswahl
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                            ForEach(VorschulArt.allCases) { art in
                                NavigationLink(value: art) { karte(art) }
                                    .buttonStyle(TastenStil())
                            }
                        }
                        pakete
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: VorschulArt.self) { art in
                if art == .memory {
                    VorschulMemory()
                } else {
                    VorschulRunde(art: art)
                }
            }
            .navigationDestination(for: Klassenarbeit.self) { VorschulPaketListe(arbeit: $0) }
            .navigationDestination(for: Uebung.self) { VorschulRunde(art: .mix, quelle: $0) }
            .confirmationDialog("Paket löschen?", isPresented: Binding(get: { loeschen != nil },
                                                                     set: { if !$0 { loeschen = nil } }),
                                titleVisibility: .visible) {
                Button("Löschen", role: .destructive) {
                    if let a = loeschen { context.delete(a); try? context.save() }
                    loeschen = nil
                }
                Button("Abbrechen", role: .cancel) { loeschen = nil }
            }
        }
    }

    private var eigenePakete: [Klassenarbeit] {
        alleArbeiten.filter { $0.fach == "Vorschule" && $0.spezial.isEmpty }
    }

    @ViewBuilder
    private var pakete: some View {
        if !eigenePakete.isEmpty {
            Text("Eigene Pakete")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
                .padding(.top, 8)
            ForEach(eigenePakete) { a in
                NavigationLink(value: a) {
                    HStack(spacing: 14) {
                        Text("📦").font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(a.titel)
                                .font(.system(.headline, design: .rounded).weight(.heavy))
                                .foregroundStyle(Color.white)
                            Text("\(a.uebungen.count) Übungen")
                                .font(.footnote)
                                .foregroundStyle(Theme.textSanft)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Theme.gelb)
                    }
                    .padding(16)
                    .glasKarte(radius: 24)
                }
                .buttonStyle(TastenStil())
                .contextMenu {
                    Button("Paket löschen", systemImage: "trash", role: .destructive) { loeschen = a }
                }
            }
        }
    }

    private var kopf: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Vorschule")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            Text(kindName.isEmpty ? "Spielen und lernen" : "Hallo \(kindName)! Spielen und lernen")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSanft)
        }
    }

    private var auswahl: some View {
        VStack(spacing: 10) {
            Picker("Zahlenraum", selection: $stufe) {
                Text("Bis 5").tag(1)
                Text("Bis 10").tag(2)
                Text("Bis 20").tag(3)
            }
            .pickerStyle(.segmented)
            Picker("Sprache", selection: $sprache) {
                Text("Deutsch").tag("de")
                Text("Türkçe").tag("tr")
            }
            .pickerStyle(.segmented)
        }
    }

    private func karte(_ art: VorschulArt) -> some View {
        VStack(spacing: 8) {
            Text(art.emoji).font(.system(size: 52))
            Text(art.titel)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(8)
        .glasKarte(radius: 26)
    }
}

struct VorschulRunde: View {
    let art: VorschulArt
    var quelle: Uebung? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulStufe") private var stufe = 2
    @AppStorage("vorschulSprache") private var sprache = "de"
    @State private var fragen: [VorschulFrage] = []
    @State private var nr = 0
    @State private var perfekt = 0
    @State private var falsch: Set<Int> = []
    @State private var richtigGewaehlt: Int?
    @State private var schuettel: Int?
    @State private var sperre = false
    @State private var gespeichert = false

    var body: some View {
        ZStack {
            HintergrundView()
            if fragen.isEmpty {
                ProgressView()
            } else if nr >= fragen.count {
                ergebnis
            } else {
                frage(fragen[nr])
            }
        }
        .navigationTitle(quelle?.titel ?? art.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fragen.isEmpty { neu() } }
    }

    private func frage(_ f: VorschulFrage) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                ProgressView(value: Double(nr), total: Double(fragen.count))
                    .tint(Theme.gelb)

                Button { VorschulTon.sag(f.text) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Theme.gelb)
                        Text(sprache == "tr" ? (f.text.tr ?? f.text.de) : f.text.de)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .glasKarte(radius: 22)
                }
                .buttonStyle(TastenStil())

                bild(f)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 14)], spacing: 14) {
                    ForEach(Array(f.optionen.enumerated()), id: \.offset) { i, o in
                        optionKnopf(i, o, f)
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private func bild(_ f: VorschulFrage) -> some View {
        if !f.gross.isEmpty {
            Text(f.gross)
                .font(.system(size: 96, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
        }
        if !f.zeige.isEmpty {
            EmojiReihen(emojis: f.zeige)
        }
        if f.plus {
            Text("+")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.gelb)
            EmojiReihen(emojis: f.zeigeZwei)
        }
        if !f.folge.isEmpty {
            Text(f.folge.joined(separator: " ") + " ❓")
                .font(.system(size: 40))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
    }

    private func optionKnopf(_ i: Int, _ o: String, _ f: VorschulFrage) -> some View {
        let istRichtig = richtigGewaehlt == i
        let istFalsch = falsch.contains(i)
        let farbe: Color = istRichtig ? Theme.mint.opacity(0.6)
            : (istFalsch ? Theme.koralle.opacity(0.35) : Color.white.opacity(0.14))
        return Button { wahl(i, f) } label: {
            Text(o)
                .font(.system(size: f.gruppenOptionen ? 30 : 54, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, minHeight: 112)
                .padding(6)
                .background(farbe, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(istRichtig ? Theme.mint : Color.white.opacity(0.18), lineWidth: istRichtig ? 4 : 1.5)
                )
                .opacity(istFalsch ? 0.45 : 1)
                .scaleEffect(istRichtig ? 1.06 : 1)
                .offset(x: schuettel == i ? 9 : 0)
                .animation(.spring(response: 0.18, dampingFraction: 0.25), value: schuettel)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: richtigGewaehlt)
        }
        .buttonStyle(TastenStil())
    }

    private var ergebnis: some View {
        let sterne = sterneFuer(gut: perfekt, gesamt: fragen.count)
        return VStack(spacing: 18) {
            Text(sterne == 3 ? "🎉" : (sterne >= 1 ? "👏" : "💪"))
                .font(.system(size: 90))
            Text("\(perfekt) von \(fragen.count) gleich richtig!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < sterne ? "star.fill" : "star")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.gelb)
                }
            }
            Button { neu() } label: {
                Label("Nochmal", systemImage: "arrow.clockwise")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: 280, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            Button("Fertig") { dismiss() }
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .padding(24)
    }

    private func neu() {
        if let u = quelle {
            fragen = VorschulPaket.fragen(u)
        } else {
            fragen = VorschulGenerator.fragen(art, stufe: stufe)
        }
        nr = 0
        perfekt = 0
        zuruecksetzen()
        gespeichert = false
        if let f = fragen.first { VorschulTon.sag(f.text) }
    }

    private func zuruecksetzen() {
        falsch = []
        richtigGewaehlt = nil
        schuettel = nil
        sperre = false
    }

    private func wahl(_ i: Int, _ f: VorschulFrage) {
        guard !sperre, richtigGewaehlt == nil, !falsch.contains(i) else { return }
        if i == f.richtig {
            richtigGewaehlt = i
            if falsch.isEmpty { perfekt += 1 }
            sperre = true
            Haptik.erfolg()
            VorschulTon.lob()
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                weiter()
            }
        } else {
            falsch.insert(i)
            schuettel = i
            Haptik.fehler()
            VorschulTon.nochmal()
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                schuettel = nil
            }
        }
    }

    private func weiter() {
        nr += 1
        zuruecksetzen()
        if nr < fragen.count {
            VorschulTon.sag(fragen[nr].text)
        } else {
            abschliessen()
        }
    }

    private func abschliessen() {
        guard !gespeichert else { return }
        gespeichert = true
        VorschulTon.sag(VorschulText(de: "Das hast du toll gemacht!", tr: "Çok güzel yaptın!"))
        guard modus == "kind" else { return }
        let arbeitName = quelle?.arbeit?.titel ?? "Übungen"
        let uebungName = quelle.map { "\($0.symbol) \($0.titel)" } ?? "\(art.emoji) \(art.titel)"
        context.insert(RundenErgebnis(klasse: "Vorschule", fach: "Vorschule", arbeit: arbeitName,
                                      uebung: uebungName,
                                      richtig: perfekt, gesamt: fragen.count, angesehen: 0,
                                      quelle: "lokal"))
        try? context.save()
        CloudSync.anstossen(context)
    }
}

struct VorschulKarte: Identifiable {
    let id = UUID()
    let paar: Int
    let emoji: String
    var offen = false
    var weg = false
}

struct VorschulMemory: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulStufe") private var stufe = 2
    @State private var karten: [VorschulKarte] = []
    @State private var erste: Int?
    @State private var zuege = 0
    @State private var sperre = false
    @State private var fertig = false

    private var paare: Int { stufe == 1 ? 3 : (stufe == 2 ? 4 : 6) }

    var body: some View {
        ZStack {
            HintergrundView()
            if fertig {
                geschafft
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Finde zwei gleiche Bilder")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 12) {
                            ForEach(Array(karten.enumerated()), id: \.element.id) { i, k in
                                kartenKnopf(i, k)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle("Memory")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if karten.isEmpty { neu() } }
    }

    private func kartenKnopf(_ i: Int, _ k: VorschulKarte) -> some View {
        let zeigen = k.offen || k.weg
        return Button { tippe(i) } label: {
            Text(zeigen ? k.emoji : "❔")
                .font(.system(size: 44))
                .frame(maxWidth: .infinity, minHeight: 96)
                .background(zeigen ? Color.white.opacity(0.16) : Theme.gelb.opacity(0.85),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .opacity(k.weg ? 0.3 : 1)
        }
        .buttonStyle(TastenStil())
    }

    private var geschafft: some View {
        VStack(spacing: 18) {
            Text("🎉").font(.system(size: 90))
            Text("Alle Paare gefunden!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
            Text("In \(zuege) Zügen")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
            Button { neu() } label: {
                Label("Nochmal", systemImage: "arrow.clockwise")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: 280, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            Button("Fertig") { dismiss() }
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .padding(24)
    }

    private func neu() {
        let pool = (VorschulGenerator.dinge + ["🐰", "🦁", "🐸", "🍌", "🚌", "🌻"]).shuffled()
        var liste: [VorschulKarte] = []
        for (i, e) in pool.prefix(paare).enumerated() {
            liste.append(VorschulKarte(paar: i, emoji: e))
            liste.append(VorschulKarte(paar: i, emoji: e))
        }
        karten = liste.shuffled()
        erste = nil
        zuege = 0
        sperre = false
        fertig = false
    }

    private func tippe(_ i: Int) {
        guard !sperre, karten.indices.contains(i), !karten[i].offen, !karten[i].weg else { return }
        Haptik.leicht()
        withAnimation(.snappy) { karten[i].offen = true }
        guard let e = erste else {
            erste = i
            return
        }
        zuege += 1
        erste = nil
        if karten[e].paar == karten[i].paar {
            Haptik.erfolg()
            withAnimation(.snappy) {
                karten[e].weg = true
                karten[i].weg = true
            }
            if karten.allSatisfy({ $0.weg }) { abschliessen() }
        } else {
            sperre = true
            Task {
                try? await Task.sleep(for: .seconds(0.9))
                withAnimation(.snappy) {
                    karten[e].offen = false
                    karten[i].offen = false
                }
                sperre = false
            }
        }
    }

    private func abschliessen() {
        VorschulTon.lob()
        fertig = true
        guard modus == "kind" else { return }
        context.insert(RundenErgebnis(klasse: "Vorschule", fach: "Vorschule", arbeit: "Übungen",
                                      uebung: "🃏 Memory",
                                      richtig: paare, gesamt: max(paare, zuege), angesehen: 0,
                                      quelle: "lokal"))
        try? context.save()
        CloudSync.anstossen(context)
    }
}

// ============================================================
// MARK: - Klassencode absichern (digitale Unterschrift)
// ============================================================

enum KlassenFehler: LocalizedError {
    case keinSchluessel

    var errorDescription: String? {
        "Auf diesem Gerät fehlt der Admin-Schlüssel für diesen Klassencode. Nur das Gerät, das den Klassencode angelegt hat, darf Pakete an die Klasse senden."
    }
}

enum Schluesselbund {
    private static let dienst = "de.cemaras.yem1n.klasse"

    static func speichere(_ daten: Data, konto: String) {
        let basis: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto
        ]
        SecItemDelete(basis as CFDictionary)
        var neu = basis
        neu[kSecValueData as String] = daten
        neu[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(neu as CFDictionary, nil)
    }

    static func lese(konto: String) -> Data? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ergebnis: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ergebnis) == errSecSuccess else { return nil }
        return ergebnis as? Data
    }
}

enum Klassensiegel {
    static func konto(_ code: String) -> String { "klassenkey-" + code }

    static func privaterSchluessel(_ code: String) -> Curve25519.Signing.PrivateKey? {
        guard let d = Schluesselbund.lese(konto: konto(code)) else { return nil }
        return try? Curve25519.Signing.PrivateKey(rawRepresentation: d)
    }

    static func istAdmin(_ code: String) -> Bool { privaterSchluessel(code) != nil }

    private static func nachricht(_ code: String, _ json: String) -> Data {
        Data((code + "|" + json).utf8)
    }

    static func signiere(code: String, json: String) -> String? {
        guard let k = privaterSchluessel(code),
              let sig = try? k.signature(for: nachricht(code, json)) else { return nil }
        return sig.base64EncodedString()
    }

    static func pruefe(code: String, json: String, sig: String, oeffentlich: Data) -> Bool {
        guard let sd = Data(base64Encoded: sig),
              let pk = try? Curve25519.Signing.PublicKey(rawRepresentation: oeffentlich) else { return false }
        return pk.isValidSignature(sd, for: nachricht(code, json))
    }

    // Der öffentliche Schlüssel wird beim ersten Mal gemerkt. Danach muss die Cloud denselben liefern.
    static func vertrauterSchluessel(_ code: String) async -> Data? {
        let feld = "klassenPin-" + code
        let geholt = await CloudDienst.ladeKlassenSchluessel(code)
        if let b64 = UserDefaults.standard.string(forKey: feld), let gemerkt = Data(base64Encoded: b64) {
            if let g = geholt, g != gemerkt { return nil }
            return gemerkt
        }
        guard let g = geholt else { return nil }
        UserDefaults.standard.set(g.base64EncodedString(), forKey: feld)
        return g
    }
}

// ============================================================
// MARK: - Datenschutz
// ============================================================

struct DatenschutzView: View {
    private let abschnitte: [(String, String)] = [
        ("Verantwortlicher",
         "Cem Aras, Schulweg 20, 65618 Selters (Taunus). Telefon: 0172-7579888, E-Mail: cembot@icloud.com."),
        ("Auf deinem Gerät",
         "YEM1N speichert Klassenarbeiten, Aufgaben, Ergebnisse und Einstellungen (zum Beispiel Name des Kindes, Klasse, Farbwelt, Tagesziel) auf diesem Gerät. Das bleibt dort, bis du die App löschst."),
        ("In der Cloud",
         "Nur wenn ein Familiencode eingetragen ist, nutzt die App die iCloud (CloudKit) von Apple. Dort liegen Rundenergebnisse (Fach, Übung, Anzahl richtig, Sterne, Zeitpunkt und der Name des Kindes, falls eingetragen), Joker-Nachrichten und Aufgabenpakete. Wer den Familiencode kennt, kann diese Einträge lesen. Gib ihn deshalb nur an Eltern weiter, denen du vertraust. Für den Namen des Kindes reicht ein Vorname oder Spitzname. Apple speichert technisch, welche pseudonyme iCloud-Kennung einen Eintrag angelegt hat, einen Klarnamen sehe ich dadurch nicht."),
        ("Klassencode",
         "Über den Klassencode kommen nur Aufgabenpakete an. Sie sind vom Admin digital unterschrieben, sonst nimmt die App sie nicht an. Ergebnisse und Joker laufen nie über den Klassencode."),
        ("Kein Tracking",
         "Die App enthält keine Werbung, keine Analysedienste und keine Software von Drittanbietern. Es gibt kein Benutzerkonto bei mir. Die Sprachausgabe läuft auf dem Gerät. Es werden keine Fotos, Kontakte, Standortdaten oder Mikrofonaufnahmen erhoben."),
        ("Mitteilungen",
         "Die App sendet Mitteilungen zwischen Eltern- und Kindgeräten über Apple. Dafür gibt Apple ein technisches Gerätekennzeichen aus. Die Erlaubnis kannst du jederzeit in den iOS-Einstellungen widerrufen."),
        ("Zwecke und Rechtsgrundlagen",
         "Die Daten werden nur verarbeitet, damit die App funktioniert: Üben, Ergebnisübersicht für Eltern, Joker und Aufgabenverteilung. Rechtsgrundlage ist Art. 6 Abs. 1 lit. b DSGVO und, soweit Eltern die App für ihr Kind einrichten, deren Einwilligung nach Art. 6 Abs. 1 lit. a in Verbindung mit Art. 8 DSGVO. Für Mitteilungen gilt deine Einwilligung. Die digitale Unterschrift der Klassenpakete dient der Sicherheit (Art. 6 Abs. 1 lit. f DSGVO)."),
        ("Empfänger",
         "Die Cloud-Daten und Mitteilungen laufen über Apple (iCloud/CloudKit und Apple Push Notification Service). Eine Übermittlung in Drittländer, insbesondere die USA, kann dabei nicht ausgeschlossen werden. Apple stützt sich dafür auf Standardvertragsklauseln und das EU-US Data Privacy Framework. Weitere Empfänger gibt es nicht."),
        ("Speicherdauer und Löschen",
         "Daten auf dem Gerät bleiben, bis du die App löschst. Cloud-Einträge bleiben, bis sie gelöscht werden. Mit dem Knopf unten löschst du die Cloud-Einträge dieses Familiencodes, die dieses Gerät angelegt hat. Nutze ihn auf jedem Gerät der Familie. Du kannst mich auch per E-Mail um Löschung bitten."),
        ("Deine Rechte",
         "Du hast das Recht auf Auskunft, Berichtigung, Löschung, Einschränkung der Verarbeitung, Datenübertragbarkeit und Widerspruch sowie das Recht, eine Einwilligung jederzeit zu widerrufen. Schreibe dazu an die oben genannte E-Mail-Adresse. Du kannst dich außerdem bei einer Datenschutzaufsichtsbehörde beschweren, zum Beispiel beim Hessischen Beauftragten für Datenschutz und Informationsfreiheit in Wiesbaden."),
        ("Kinder",
         "Die App richtet sich an Eltern, die sie gemeinsam mit ihren Kindern nutzen. Familiencode, Klassencode und Name sollten Eltern einrichten.")
    ]

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
                    if let url = URL(string: "https://cembot90.github.io/YEM1N/") {
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
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ============================================================
// MARK: - Profil und Einrichtungsassistent
// ============================================================

enum ProfilDaten {
    static let klassen = ["Vorschule", "Klasse 1", "Klasse 2", "Klasse 3", "Klasse 4"]
}

struct ProfilAssistent: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("farbwelt") private var farbwelt = "blau"
    @AppStorage("tagesziel") private var tagesziel = 2
    @AppStorage("vorschulTab") private var vorschulTab = true
    @AppStorage("jokerIch") private var jokerIch = ""
    @AppStorage("profilFertig") private var profilFertig = false
    @State private var schritt = 0
    @State private var name = ""
    @State private var klasse = ""
    @State private var geladen = false
    private let joker = JokerStand.shared

    private var istKind: Bool { modus == "kind" }
    private var letzterSchritt: Int { istKind ? 2 : 0 }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 22) {
                    Text("Willkommen bei YEM1N")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    if istKind {
                        Text("Schritt \(schritt + 1) von 3")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSanft)
                    }
                    inhalt
                    knoepfe
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            guard !geladen else { return }
            geladen = true
            name = kindName
            klasse = kindKlasse
        }
    }

    @ViewBuilder
    private var inhalt: some View {
        if !istKind {
            frageKarte("Wer bist du?", "Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen.") {
                let aktuell = jokerIch.isEmpty ? (joker.mitglieder.first?.id.uuidString ?? "") : jokerIch
                VStack(spacing: 10) {
                    ForEach(joker.mitglieder) { m in
                        chip("\(m.emoji) \(m.name)", aktiv: aktuell == m.id.uuidString) {
                            jokerIch = m.id.uuidString
                        }
                    }
                }
            }
        } else if schritt == 0 {
            frageKarte("Wie heißt das Kind?", "Ein Vorname oder Spitzname reicht. Der Name erscheint bei den Eltern.") {
                TextField("Name", text: $name)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        } else if schritt == 1 {
            frageKarte("In welcher Klasse?", "Danach lädt das Gerät nur passende Aufgabenpakete. Du kannst es später ändern.") {
                VStack(spacing: 10) {
                    ForEach(ProfilDaten.klassen, id: \.self) { k in
                        chip(k, aktiv: klasse == k) { klasse = k }
                    }
                    chip("Weiß ich nicht", aktiv: klasse.isEmpty) { klasse = "" }
                }
            }
        } else {
            frageKarte("Farben und Ziel", "Wähle die Farbwelt und wie viele Runden pro Tag das Ziel sind.") {
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        farbKarte("Blau und Gelb", "blau")
                        farbKarte("Rosa", "rosa")
                    }
                    Stepper("Tagesziel: \(tagesziel) \(tagesziel == 1 ? "Runde" : "Runden")",
                            value: $tagesziel, in: 1...10)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color.white)
                }
            }
        }
    }

    private var knoepfe: some View {
        VStack(spacing: 12) {
            Button {
                if schritt < letzterSchritt {
                    schritt += 1
                } else {
                    fertigstellen()
                }
            } label: {
                Text(schritt < letzterSchritt ? "Weiter" : "Los geht's")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            if schritt > 0 {
                Button("Zurück") { schritt -= 1 }
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            } else {
                Button("Später einrichten") { profilFertig = true }
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            }
        }
    }

    private func fertigstellen() {
        if istKind {
            kindName = name.trimmingCharacters(in: .whitespaces)
            kindKlasse = klasse
            if klasse == "Vorschule" {
                vorschulTab = true
            } else if !klasse.isEmpty {
                vorschulTab = false
            }
        }
        profilFertig = true
    }

    private func frageKarte<Inhalt: View>(_ titel: String, _ text: String,
                                          @ViewBuilder inhalt: () -> Inhalt) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(titel)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textSanft)
            inhalt()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func chip(_ titel: String, aktiv: Bool, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Text(titel)
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(aktiv ? Theme.navy : Color.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(aktiv ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    private func farbKarte(_ titel: String, _ wert: String) -> some View {
        let aktiv = farbwelt == wert
        let farben: [Color] = wert == "rosa"
            ? [Color(red: 0.36, green: 0.07, blue: 0.31), Color(red: 1.0, green: 0.45, blue: 0.74)]
            : [Color(red: 0.0, green: 0.125, blue: 0.357), Color(red: 1.0, green: 0.93, blue: 0.0)]
        return Button {
            Theme.rosa = (wert == "rosa")
            farbwelt = wert
        } label: {
            VStack(spacing: 8) {
                LinearGradient(colors: farben, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text(titel)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(aktiv ? 0.18 : 0.06),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(aktiv ? Theme.gelb : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(TastenStil())
    }
}
