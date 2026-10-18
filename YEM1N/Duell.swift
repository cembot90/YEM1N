import SwiftUI
import Foundation

// ============================================================
// MARK: - Duell: Kopfrechnen gegen die Familie
// ============================================================
//
// Zwei rechnen gleichzeitig zehn Aufgaben, jede und jeder auf der eigenen Stufe.
// So kann ein Kind aus Klasse 1 gegen Papa auf der Stufe Profi gewinnen.
// Wer mehr richtig hat, gewinnt. Bei Gleichstand zählt die Zeit.
// Eine falsche Antwort kostet 3 Sekunden.
// Gespielt wird zu zweit an einem Gerät (oben und unten) oder als Herausforderung
// über die Familien-Cloud (DuellCloud.swift). Münzen kostet das Duell nicht, es ist Üben.

enum DuellStufe: String, CaseIterable, Identifiable, Codable {
    case klasse1, klasse2, klasse3, klasse4, profi

    var id: String { rawValue }

    var name: String {
        switch self {
        case .klasse1: return "Klasse 1"
        case .klasse2: return "Klasse 2"
        case .klasse3: return "Klasse 3"
        case .klasse4: return "Klasse 4"
        case .profi: return "Profi"
        }
    }

    var emoji: String {
        switch self {
        case .klasse1: return "🐣"
        case .klasse2: return "🐥"
        case .klasse3: return "🦊"
        case .klasse4: return "🦁"
        case .profi: return "🧠"
        }
    }

    var beschreibung: String {
        switch self {
        case .klasse1: return "Plus und Minus bis 20"
        case .klasse2: return "Plus und Minus bis 100, Mal mit 2, 5 und 10"
        case .klasse3: return "Einmaleins, Geteilt, Rechnen mit Zehnern bis 1000"
        case .klasse4: return "Großes Mal und Geteilt, Rechnen bis 1000"
        case .profi: return "Für Erwachsene: richtig knifflig"
        }
    }

    /// Die Stufe zur Klasse aus dem Profil. Ohne Klasse ist es Klasse 3.
    static func passend(zuKlasse k: String) -> DuellStufe {
        switch k {
        case "Vorschule", "Klasse 1": return .klasse1
        case "Klasse 2": return .klasse2
        case "Klasse 4": return .klasse4
        default: return .klasse3
        }
    }
}

struct DuellAufgabe: Codable, Equatable {
    let rechnung: String
    let antwort: Int
}

/// Das Ergebnis eines Durchgangs. Die Sekunden enthalten schon die Strafzeit.
struct DuellStand: Codable, Equatable {
    var richtig: Int
    var falsch: Int
    var sekunden: Double
}

enum DuellRegeln {
    static let anzahl = 10
    static let strafSekunden = 3.0

    // MARK: Aufgaben

    static func aufgaben(_ stufe: DuellStufe, anzahl: Int = anzahl) -> [DuellAufgabe] {
        var g = SystemRandomNumberGenerator()
        return aufgaben(stufe, anzahl: anzahl, zufall: &g)
    }

    /// Zehn verschiedene Aufgaben einer Stufe. Alle Ergebnisse liegen zwischen 1 und 999.
    static func aufgaben<G: RandomNumberGenerator>(_ stufe: DuellStufe, anzahl: Int = anzahl,
                                                   zufall g: inout G) -> [DuellAufgabe] {
        var liste: [DuellAufgabe] = []
        var gesehen = Set<String>()
        var versuche = 0
        while liste.count < anzahl && versuche < 1000 {
            versuche += 1
            let a = eine(stufe, zufall: &g)
            if gesehen.insert(a.rechnung).inserted { liste.append(a) }
        }
        return liste
    }

    static func eine<G: RandomNumberGenerator>(_ stufe: DuellStufe, zufall g: inout G) -> DuellAufgabe {
        func z(_ r: ClosedRange<Int>) -> Int { Int.random(in: r, using: &g) }
        func plus(_ a: Int, _ b: Int) -> DuellAufgabe { DuellAufgabe(rechnung: "\(a) + \(b)", antwort: a + b) }
        func minus(_ a: Int, _ b: Int) -> DuellAufgabe { DuellAufgabe(rechnung: "\(a) - \(b)", antwort: a - b) }
        func mal(_ a: Int, _ b: Int) -> DuellAufgabe { DuellAufgabe(rechnung: "\(a) · \(b)", antwort: a * b) }
        func geteilt(_ teiler: Int, _ ergebnis: Int) -> DuellAufgabe {
            DuellAufgabe(rechnung: "\(teiler * ergebnis) : \(teiler)", antwort: ergebnis)
        }

        let wahl = z(0...99)
        switch stufe {
        case .klasse1:
            if wahl < 50 {
                let summe = z(3...20)
                let a = z(1...(summe - 1))
                return plus(a, summe - a)
            }
            let a = z(3...20)
            return minus(a, z(1...(a - 1)))
        case .klasse2:
            if wahl < 35 {
                let a = z(11...79)
                return plus(a, z(3...(99 - a)))
            }
            if wahl < 70 {
                let a = z(20...99)
                return minus(a, z(3...(a - 5)))
            }
            let kern = [2, 5, 10][z(0...2)]
            return wahl < 85 ? mal(z(1...10), kern) : mal(kern, z(1...10))
        case .klasse3:
            if wahl < 40 { return mal(z(2...10), z(2...10)) }
            if wahl < 70 { return geteilt(z(2...10), z(2...10)) }
            if wahl < 85 {
                let a = z(10...80) * 10
                return plus(a, z(1...(99 - a / 10)) * 10)
            }
            let a = z(20...99) * 10
            return minus(a, z(1...(a / 10 - 1)) * 10)
        case .klasse4:
            if wahl < 35 { return mal(z(11...40), z(2...9)) }
            if wahl < 60 { return geteilt(z(2...9), z(11...40)) }
            if wahl < 80 {
                let a = z(120...880)
                return plus(a, z(11...(999 - a)))
            }
            let a = z(200...999)
            return minus(a, z(11...(a - 100)))
        case .profi:
            if wahl < 35 { return mal(z(12...25), z(12...25)) }
            if wahl < 60 {
                let t = z(3...9)
                return geteilt(t, z(21...(999 / t)))
            }
            if wahl < 80 {
                let a = z(234...765)
                return plus(a, z(111...(999 - a)))
            }
            let a = z(400...999)
            return minus(a, z(123...(a - 50)))
        }
    }

    // MARK: Wertung

    /// 0, wenn der erste gewinnt, 1 für den zweiten, nil bei Gleichstand.
    static func sieger(_ a: DuellStand, _ b: DuellStand) -> Int? {
        if a.richtig != b.richtig { return a.richtig > b.richtig ? 0 : 1 }
        if abs(a.sekunden - b.sekunden) < 0.1 { return nil }
        return a.sekunden < b.sekunden ? 0 : 1
    }

    /// "48,3 s"
    static func zeitText(_ sekunden: Double) -> String {
        let zehntel = max(0, Int((sekunden * 10).rounded()))
        return "\(zehntel / 10),\(zehntel % 10) s"
    }

    static func standText(_ s: DuellStand) -> String {
        "\(s.richtig) von \(s.richtig + s.falsch) richtig in \(zeitText(s.sekunden))"
    }
}

/// Ein Durchgang einer Person: welche Aufgabe dran ist und wie es bisher lief.
struct DuellLauf: Equatable {
    let aufgaben: [DuellAufgabe]
    var antworten: [Bool] = []
    var strafe: Double = 0

    var index: Int { antworten.count }
    var fertig: Bool { index >= aufgaben.count }
    var aktuelle: DuellAufgabe? { fertig ? nil : aufgaben[index] }
    var richtig: Int { antworten.filter { $0 }.count }
    var falsch: Int { antworten.count - richtig }

    /// true bei richtig, false bei falsch, nil wenn nichts zu prüfen war.
    @discardableResult
    mutating func antworte(_ text: String) -> Bool? {
        guard let a = aktuelle, let n = Int(text) else { return nil }
        let ok = n == a.antwort
        antworten.append(ok)
        if !ok { strafe += DuellRegeln.strafSekunden }
        return ok
    }

    func stand(sekunden roh: Double) -> DuellStand {
        DuellStand(richtig: richtig, falsch: falsch, sekunden: roh + strafe)
    }
}

// MARK: - Startseite des Duells

struct DuellView: View {
    var zeigeSchliessen = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("modus") private var modus = ""
    @AppStorage("familienCode") private var familienCode = ""

    @State private var name1 = ""
    @State private var stufe1: DuellStufe = .klasse3
    @State private var name2 = ""
    @State private var stufe2: DuellStufe = .profi
    @State private var spiel: DuellGeraetSpiel?
    @State private var vorbereitet = false

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    kopf
                    AbschnittsTitel("Zu zweit an diesem Gerät",
                                    text: "Einer sitzt oben, einer unten. Jeder rechnet auf seiner Stufe.")
                    VStack(spacing: 12) {
                        spielerKarte(nummer: 1, name: $name1, stufe: $stufe1)
                        spielerKarte(nummer: 2, name: $name2, stufe: $stufe2)
                        GelberKnopf(titel: "⚔️ Los geht's") {
                            spiel = DuellGeraetSpiel(
                                spieler: [DuellTeilnehmer(name: sauber(name1, ersatz: "Spieler 1"), stufe: stufe1),
                                          DuellTeilnehmer(name: sauber(name2, ersatz: "Spieler 2"), stufe: stufe2)])
                        }
                    }
                    regeln
                    if Familiencode.istGueltig(familienCode) {
                        DuellFamilienBereich()
                    } else {
                        Text("Mit einem Familiencode kannst du auch Herausforderungen an deine Familie schicken. Den Code findest du in den Einstellungen.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .topTrailing) {
            if zeigeSchliessen {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 40, height: 40)
                        .background(Theme.gelb, in: Circle())
                }
                .padding(16)
                .accessibilityLabel("Schließen")
            }
        }
        .onAppear(perform: vorbereiten)
        .fullScreenCover(item: $spiel) { s in
            DuellGeraetView(spieler: s.spieler)
                .preferredColorScheme(.dark)
                .tint(Theme.gelb)
        }
    }

    private func sauber(_ n: String, ersatz: String) -> String {
        let t = n.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? ersatz : String(t.prefix(14))
    }

    private func vorbereiten() {
        guard !vorbereitet else { return }
        vorbereitet = true
        let kind = kindName.trimmingCharacters(in: .whitespaces)
        if modus == "eltern" {
            name1 = kind.isEmpty ? "Kind" : kind
            name2 = CloudDienst.ichName()
        } else {
            name1 = kind.isEmpty ? "Ich" : kind
            name2 = "Papa"
        }
        stufe1 = DuellStufe.passend(zuKlasse: kindKlasse)
        stufe2 = .profi
    }

    private var kopf: some View {
        HStack(spacing: 14) {
            Text("⚔️").font(.system(size: 46))
            VStack(alignment: .leading, spacing: 4) {
                Text("Duell")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(Color.white)
                Text("Kopfrechnen gegen deine Familie")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(.top, zeigeSchliessen ? 28 : 0)
    }

    private func spielerKarte(nummer: Int, name: Binding<String>, stufe: Binding<DuellStufe>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(stufe.wrappedValue.emoji).font(.system(size: 30))
                TextField(nummer == 1 ? "Name oben" : "Name unten", text: name)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                Text(nummer == 1 ? "oben" : "unten")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            }
            StufenWahl(stufe: stufe)
        }
        .padding(16)
        .glasKarte(radius: 24)
    }

    private var regeln: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("So geht's", systemImage: "info.circle.fill")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Jeder rechnet \(DuellRegeln.anzahl) Aufgaben. Wer mehr richtig hat, gewinnt. Bei Gleichstand gewinnt, wer schneller war. Eine falsche Antwort kostet 3 Sekunden.")
                .font(.subheadline)
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gelb.opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Stufe als Menü mit Erklärung
struct StufenWahl: View {
    @Binding var stufe: DuellStufe

    var body: some View {
        Menu {
            Picker("Stufe", selection: $stufe) {
                ForEach(DuellStufe.allCases) { s in
                    Text("\(s.emoji) \(s.name)").tag(s)
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stufe: \(stufe.name)")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.gelb)
                    Text(stufe.beschreibung)
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .foregroundStyle(Theme.gelb)
            }
            .padding(12)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct DuellTeilnehmer: Equatable {
    var name: String
    var stufe: DuellStufe
}

struct DuellGeraetSpiel: Identifiable {
    let id = UUID()
    let spieler: [DuellTeilnehmer]
}

// MARK: - Zu zweit an einem Gerät

struct DuellGeraetView: View {
    let spieler: [DuellTeilnehmer]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig

    @State private var laeufe: [DuellLauf] = []
    @State private var enden: [Date?] = [nil, nil]
    @State private var start: Date?
    @State private var countdown = 3
    @State private var runde = 0

    private var beideFertig: Bool { enden.allSatisfy { $0 != nil } && start != nil }

    var body: some View {
        GeometryReader { g in
            let quer = g.size.width > g.size.height * 1.1
            // So hoch dürfen die Tasten sein, damit eine Hälfte ganz auf den Bildschirm passt
            let haelfte = quer ? g.size.height : (g.size.height - 44) / 2
            let tasten = min(max((haelfte - 170) / 4 - 6, 30), 52)
            ZStack {
                HintergrundView()
                if laeufe.count == 2 {
                    if quer {
                        HStack(spacing: 0) {
                            feld(0, tasten: tasten)
                            mitte(quer: true)
                            feld(1, tasten: tasten)
                        }
                    } else {
                        VStack(spacing: 0) {
                            // Oben sitzt die zweite Person gegenüber, darum steht die Hälfte auf dem Kopf
                            feld(0, tasten: tasten).rotationEffect(.degrees(180))
                            mitte(quer: false)
                            feld(1, tasten: tasten)
                        }
                    }
                }
                if start == nil && countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.gelb)
                        .shadow(color: Theme.gelb.opacity(0.6), radius: 20)
                        .contentTransition(.numericText(countsDown: true))
                        .allowsHitTesting(false)
                }
                if beideFertig { ergebnis }
            }
        }
        .statusBarHidden()
        .task(id: runde) { await starten() }
    }

    private func feld(_ i: Int, tasten: CGFloat) -> some View {
        DuellSpielerFeld(name: spieler[i].name, stufe: spieler[i].stufe,
                         lauf: $laeufe[i], start: start, ende: enden[i], tastenHoehe: tasten) {
            enden[i] = Date.now
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func mitte(quer: Bool) -> some View {
        Group {
            if quer {
                VStack {
                    schliessen
                    Spacer()
                    Text("⚔️").font(.system(size: 28))
                    Spacer()
                }
                .frame(width: 56)
                .padding(.vertical, 16)
            } else {
                HStack {
                    schliessen
                    Spacer()
                    Text("⚔️").font(.system(size: 22))
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
            }
        }
        .background(Theme.gelb.opacity(0.10))
    }

    private var schliessen: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: 36, height: 36)
                .background(Theme.gelb, in: Circle())
        }
        .accessibilityLabel("Duell beenden")
    }

    private func starten() async {
        laeufe = spieler.map { DuellLauf(aufgaben: DuellRegeln.aufgaben($0.stufe)) }
        enden = [nil, nil]
        start = nil
        if !ruhig {
            for n in [3, 2, 1] {
                withAnimation(.snappy) { countdown = n }
                Haptik.leicht()
                do { try await Task.sleep(for: .milliseconds(800)) } catch { return }
            }
        }
        countdown = 0
        Haptik.erfolg()
        start = Date.now
    }

    private func stand(_ i: Int) -> DuellStand {
        let s = start ?? Date.now
        let e = enden[i] ?? Date.now
        return laeufe[i].stand(sekunden: e.timeIntervalSince(s))
    }

    private var ergebnis: some View {
        let a = stand(0), b = stand(1)
        let sieger = DuellRegeln.sieger(a, b)
        return ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(sieger == nil ? "🤝" : "🏆")
                    .font(.system(size: 70))
                    .jubeln()
                Text(sieger.map { "\(spieler[$0].name) gewinnt!" } ?? "Unentschieden!")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(Theme.gelb)
                    .multilineTextAlignment(.center)
                VStack(spacing: 8) {
                    zeile(spieler[0], a, gewonnen: sieger == 0)
                    zeile(spieler[1], b, gewonnen: sieger == 1)
                }
                GelberKnopf(titel: "Revanche") { runde += 1 }
                Button("Fertig") { dismiss() }
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gelb)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .glasKarte(radius: 30)
            .padding(24)
            KonfettiRegen(anzahl: 90)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .transition(.opacity)
    }

    private func zeile(_ t: DuellTeilnehmer, _ s: DuellStand, gewonnen: Bool) -> some View {
        HStack(spacing: 10) {
            Text(t.stufe.emoji).font(.system(size: 26))
            VStack(alignment: .leading, spacing: 2) {
                Text(t.name)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(gewonnen ? Theme.navy : Color.white)
                Text(DuellRegeln.standText(s))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(gewonnen ? Theme.navy.opacity(0.8) : Theme.textSanft)
            }
            Spacer()
            if gewonnen { Image(systemName: "crown.fill").foregroundStyle(Theme.navy) }
        }
        .padding(12)
        .background(gewonnen ? Theme.gelb : Color.white.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Die Hälfte einer Person

struct DuellSpielerFeld: View {
    let name: String
    let stufe: DuellStufe
    @Binding var lauf: DuellLauf
    let start: Date?
    let ende: Date?
    var tastenHoehe: CGFloat = 48
    var beiFertig: () -> Void

    @State private var eingabe = ""
    @State private var wackeln = 0
    @State private var erfolg = 0
    @State private var zuletztFalsch: String?

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("\(stufe.emoji) \(name)")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                Spacer()
                uhr
            }
            HStack(spacing: 4) {
                ForEach(0..<lauf.aufgaben.count, id: \.self) { i in
                    Capsule()
                        .fill(punktFarbe(i))
                        .frame(height: 6)
                }
            }
            Spacer(minLength: 0)
            if let a = lauf.aktuelle, start != nil {
                HStack(spacing: 10) {
                    Text("\(a.rechnung) =")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(eingabe.isEmpty ? "?" : eingabe)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(eingabe.isEmpty ? Color.white.opacity(0.35) : Theme.gelb)
                        .frame(minWidth: 80)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .kopfschuetteln(wackeln)
                .federn(erfolg)
                Text(zuletztFalsch ?? " ")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.koralle)
                Spacer(minLength: 0)
                DuellTastatur(text: $eingabe, hoehe: tastenHoehe) { pruefen() }
            } else if lauf.fertig {
                VStack(spacing: 6) {
                    Text("Fertig! 🎉")
                        .font(.system(.title, design: .rounded).weight(.black))
                        .foregroundStyle(Theme.gelb)
                    Text("\(lauf.richtig) von \(lauf.aufgaben.count) richtig")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("Warte auf die andere Seite ...")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
                Spacer(minLength: 0)
            } else {
                Text("Gleich geht's los!")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textSanft)
                Spacer(minLength: 0)
            }
        }
        .padding(14)
        .onChange(of: start) { eingabe = "" }
    }

    private func punktFarbe(_ i: Int) -> Color {
        if i < lauf.antworten.count { return lauf.antworten[i] ? Theme.mint : Theme.koralle }
        if i == lauf.index { return Color.white }
        return Color.white.opacity(0.2)
    }

    private var uhr: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            let s: Double = {
                guard let start else { return 0 }
                return (ende ?? ctx.date).timeIntervalSince(start) + lauf.strafe
            }()
            Text(DuellRegeln.zeitText(s))
                .font(.system(.subheadline, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(Theme.gelb)
        }
    }

    private func pruefen() {
        guard let a = lauf.aktuelle, let ok = lauf.antworte(eingabe) else { return }
        eingabe = ""
        if ok {
            Haptik.leicht()
            erfolg += 1
            zuletztFalsch = nil
        } else {
            Haptik.fehler()
            withAnimation(.default) { wackeln += 1 }
            let text = "\(a.rechnung) = \(a.antwort)   +3 s"
            zuletztFalsch = text
            Task {
                do { try await Task.sleep(for: .milliseconds(1600)) } catch { return }
                if zuletztFalsch == text { zuletztFalsch = nil }
            }
        }
        if lauf.fertig { beiFertig() }
    }
}

/// Kleine Zahlentasten, damit zwei Hälften auf ein iPhone passen
struct DuellTastatur: View {
    @Binding var text: String
    var hoehe: CGFloat = 44
    var onPruefen: () -> Void

    private let tasten = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "⌫", "0", "✓"]
    private let spalten = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        LazyVGrid(columns: spalten, spacing: 6) {
            ForEach(tasten, id: \.self) { taste in
                Button { tippen(taste) } label: {
                    Group {
                        switch taste {
                        case "⌫": Image(systemName: "delete.left.fill").font(.system(size: 18, weight: .bold))
                        case "✓": Image(systemName: "checkmark").font(.system(size: 22, weight: .black))
                        default: Text(taste).font(.system(size: 24, weight: .bold, design: .rounded))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: hoehe)
                    .foregroundStyle(taste == "✓" ? Theme.navy : Color.white)
                    .background(taste == "✓" ? Theme.gelb : (taste == "⌫" ? Theme.koralle.opacity(0.30) : Color.white.opacity(0.10)),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(TastenStil())
            }
        }
        .frame(maxWidth: 360)
    }

    private func tippen(_ taste: String) {
        switch taste {
        case "⌫": if !text.isEmpty { text.removeLast() }
        case "✓": onPruefen()
        default: if text.count < 3 { text += taste }
        }
    }
}

// MARK: - Allein spielen, für eine Herausforderung über die Cloud

struct DuellSoloView: View {
    let name: String
    let stufe: DuellStufe
    let aufgaben: [DuellAufgabe]
    /// Kommt genau einmal, wenn alle Aufgaben gerechnet sind
    var beiEnde: (DuellStand) -> Void
    var gegner: (name: String, stand: DuellStand)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var lauf: DuellLauf
    @State private var start: Date?
    @State private var ende: Date?
    @State private var countdown = 3

    init(name: String, stufe: DuellStufe, aufgaben: [DuellAufgabe],
         gegner: (name: String, stand: DuellStand)? = nil,
         beiEnde: @escaping (DuellStand) -> Void) {
        self.name = name
        self.stufe = stufe
        self.aufgaben = aufgaben
        self.gegner = gegner
        self.beiEnde = beiEnde
        _lauf = State(initialValue: DuellLauf(aufgaben: aufgaben))
    }

    private var meinStand: DuellStand? {
        guard let start, let ende else { return nil }
        return lauf.stand(sekunden: ende.timeIntervalSince(start))
    }

    var body: some View {
        ZStack {
            HintergrundView()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.navy)
                            .frame(width: 38, height: 38)
                            .background(Theme.gelb, in: Circle())
                    }
                    .accessibilityLabel("Beenden")
                    Spacer()
                    if let gegner {
                        Text("Gegen \(gegner.name): \(gegner.stand.richtig) richtig, \(DuellRegeln.zeitText(gegner.stand.sekunden))")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.textSanft)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                DuellSpielerFeld(name: name, stufe: stufe, lauf: $lauf, start: start, ende: ende,
                                 tastenHoehe: 54) {
                    let jetzt = Date.now
                    ende = jetzt
                    if let start { beiEnde(lauf.stand(sekunden: jetzt.timeIntervalSince(start))) }
                }
                .frame(maxWidth: 520)
            }
            if start == nil && countdown > 0 {
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.gelb)
                    .contentTransition(.numericText(countsDown: true))
                    .allowsHitTesting(false)
            }
            if let s = meinStand {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea()
                    VStack(spacing: 14) {
                        Text(ergebnisEmoji(s)).font(.system(size: 64)).jubeln()
                        Text(ergebnisTitel(s))
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundStyle(Theme.gelb)
                            .multilineTextAlignment(.center)
                        Text(DuellRegeln.standText(s))
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Color.white)
                        Text(gegner == nil ? "Deine Familie bekommt die Herausforderung jetzt." : "Das Ergebnis ist bei deiner Familie.")
                            .font(.footnote)
                            .foregroundStyle(Theme.textSanft)
                            .multilineTextAlignment(.center)
                        GelberKnopf(titel: "Fertig") { dismiss() }
                    }
                    .padding(24)
                    .frame(maxWidth: 420)
                    .glasKarte(radius: 30)
                    .padding(24)
                }
                .transition(.opacity)
            }
        }
        .task { await starten() }
    }

    private func ergebnisEmoji(_ s: DuellStand) -> String {
        guard let g = gegner else { return "⚔️" }
        switch DuellRegeln.sieger(s, g.stand) {
        case 0: return "🏆"
        case 1: return "💪"
        default: return "🤝"
        }
    }

    private func ergebnisTitel(_ s: DuellStand) -> String {
        guard let g = gegner else { return "Herausforderung steht!" }
        switch DuellRegeln.sieger(s, g.stand) {
        case 0: return "Du hast gewonnen!"
        case 1: return "\(g.name) war diesmal besser. Revanche?"
        default: return "Unentschieden!"
        }
    }

    private func starten() async {
        guard start == nil else { return }
        if !ruhig {
            for n in [3, 2, 1] {
                withAnimation(.snappy) { countdown = n }
                Haptik.leicht()
                do { try await Task.sleep(for: .milliseconds(800)) } catch { return }
            }
        }
        countdown = 0
        start = Date.now
    }
}
