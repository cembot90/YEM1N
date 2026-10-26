import SwiftUI
import Foundation
import Combine

// ============================================================
// MARK: - Duell über die Familien-Cloud
// ============================================================
//
// Wer herausfordert, rechnet zuerst und schickt das Ergebnis mit den Aufgaben für die
// anderen in das Familien-Fach. Alle anderen Geräte der Familie sehen die Herausforderung,
// rechnen ihre eigenen Aufgaben und schicken ihr Ergebnis zurück. Danach sehen alle, wer
// gewonnen hat. Gespeichert werden nur Vorname, Stufe, Aufgaben und Ergebnis.
// Herausforderungen gelten 14 Tage. Danach verschwinden sie im Familien-Dienst von selbst.

struct DuellHerausforderung: Codable, Identifiable, Equatable {
    var id: String
    var von: String
    var vonGeraet: String
    var vonStufe: DuellStufe
    var vonStand: DuellStand
    var anStufe: DuellStufe
    /// Die Aufgaben für alle, die annehmen
    var aufgaben: [DuellAufgabe]
    var zeitpunkt: Date
}

struct DuellAntwort: Codable, Identifiable, Equatable {
    var duellID: String
    var name: String
    var geraet: String
    var stand: DuellStand
    var zeitpunkt: Date

    var id: String { duellID + "-" + geraet }
}

enum DuellPost {
    static let geraetKey = "duellGeraet"
    static let haltbarTage = 14

    /// Eine feste, zufällige Kennung für dieses Gerät. Sie sagt nichts über die Person.
    static func geraet(speicher: UserDefaults = .standard) -> String {
        if let g = speicher.string(forKey: geraetKey), !g.isEmpty { return g }
        let neu = UUID().uuidString
        speicher.set(neu, forKey: geraetKey)
        return neu
    }

    static func frisch(_ d: Date, jetzt: Date) -> Bool {
        jetzt.timeIntervalSince(d) < Double(haltbarTage) * 86400
    }

    /// Herausforderungen der anderen, die dieses Gerät noch nicht angenommen hat. Neueste zuerst.
    static func offen(_ duelle: [DuellHerausforderung], _ antworten: [DuellAntwort],
                      geraet: String, jetzt: Date = Date.now) -> [DuellHerausforderung] {
        duelle
            .filter { d in
                d.vonGeraet != geraet && frisch(d.zeitpunkt, jetzt: jetzt)
                    && !antworten.contains { $0.duellID == d.id && $0.geraet == geraet }
            }
            .sorted { $0.zeitpunkt > $1.zeitpunkt }
    }

    /// Eigene Herausforderungen, auf die noch niemand geantwortet hat.
    static func wartend(_ duelle: [DuellHerausforderung], _ antworten: [DuellAntwort],
                        geraet: String, jetzt: Date = Date.now) -> [DuellHerausforderung] {
        duelle
            .filter { d in
                d.vonGeraet == geraet && frisch(d.zeitpunkt, jetzt: jetzt)
                    && !antworten.contains { $0.duellID == d.id }
            }
            .sorted { $0.zeitpunkt > $1.zeitpunkt }
    }

    struct Paarung: Identifiable, Equatable {
        let duell: DuellHerausforderung
        let antwort: DuellAntwort
        var id: String { antwort.id }
        /// 0: wer herausgefordert hat, 1: wer angenommen hat, nil: unentschieden
        var sieger: Int? { DuellRegeln.sieger(duell.vonStand, antwort.stand) }
        var siegerName: String? {
            switch sieger {
            case 0: return duell.von
            case 1: return antwort.name
            default: return nil
            }
        }
    }

    /// Alle entschiedenen Duelle der Familie, das zuletzt beantwortete zuerst.
    static func entschieden(_ duelle: [DuellHerausforderung], _ antworten: [DuellAntwort],
                            anzahl: Int = 10) -> [Paarung] {
        let nachID = Dictionary(duelle.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return antworten
            .compactMap { a in nachID[a.duellID].map { Paarung(duell: $0, antwort: a) } }
            .sorted { $0.antwort.zeitpunkt > $1.antwort.zeitpunkt }
            .prefix(anzahl)
            .map { $0 }
    }

    // MARK: Als Text in der Cloud

    static func text<T: Encodable>(_ wert: T) -> String? {
        guard let d = try? JSONEncoder().encode(wert) else { return nil }
        return String(data: d, encoding: .utf8)
    }

    static func lies<T: Decodable>(_ text: String, als typ: T.Type) -> T? {
        guard let d = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(typ, from: d)
    }
}

enum DuellCloud {
    /// Mehr nimmt der Familien-Dienst pro Duell nicht an.
    static let maxZeichen = 20000

    static func sende(_ d: DuellHerausforderung) async throws {
        guard let text = DuellPost.text(d), text.utf16.count <= maxZeichen else {
            throw PaketFehler(text: "Die Herausforderung ist zu groß zum Verschicken.")
        }
        try await CloudDienst.sende(FamilienProtokoll.duell(id: d.id, json: text))
    }

    /// Je Gerät und Duell zählt nur die erste Antwort, der Dienst hält sich daran.
    static func sende(_ a: DuellAntwort) async throws {
        guard let text = DuellPost.text(a), text.utf16.count <= maxZeichen else {
            throw PaketFehler(text: "Das Ergebnis ist zu groß zum Verschicken.")
        }
        try await CloudDienst.sende(FamilienProtokoll.duellAntwort(duellId: a.duellID, json: text))
    }

    static func lade() async throws -> (duelle: [DuellHerausforderung], antworten: [DuellAntwort]) {
        let d = try await CloudDienst.lies(FamilienProtokoll.typDuell)
        let a = try await CloudDienst.lies(FamilienProtokoll.typDuellAntwort)
        // Herausforderungen verfallen im Dienst nach 14 Tagen von selbst. Da ist kein Aufräumen nötig.
        let duelle = d.compactMap { DuellPost.lies($0.text("json"), als: DuellHerausforderung.self) }
        let antworten = a.compactMap { DuellPost.lies($0.text("json"), als: DuellAntwort.self) }
        return (duelle, antworten)
    }
}

// MARK: - Bereich auf der Duell-Seite

struct DuellSoloSpiel: Identifiable {
    enum Art {
        /// Eigene Herausforderung: danach bekommen die anderen diese Aufgaben
        case neu(anStufe: DuellStufe, fuerAndere: [DuellAufgabe])
        case antwort(DuellHerausforderung)
    }

    let id = UUID()
    let stufe: DuellStufe
    let aufgaben: [DuellAufgabe]
    let art: Art
}

struct DuellFamilienBereich: View {
    private let familie = FamilienModell.shared
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @AppStorage("modus") private var modus = ""

    @State private var duelle: [DuellHerausforderung] = []
    @State private var antworten: [DuellAntwort] = []
    @State private var laedt = false
    @State private var meldung: String?
    @State private var meineStufe: DuellStufe = .klasse3
    @State private var andereStufe: DuellStufe = .klasse3
    @State private var spiel: DuellSoloSpiel?
    @State private var vorbereitet = false

    private var geraet: String { DuellPost.geraet() }

    private var ich: String {
        if modus == "eltern" { return CloudDienst.ichName() }
        let n = kindName.trimmingCharacters(in: .whitespacesAndNewlines)
        return n.isEmpty ? "Kind" : n
    }

    private var offen: [DuellHerausforderung] { DuellPost.offen(duelle, antworten, geraet: geraet) }
    private var wartend: [DuellHerausforderung] { DuellPost.wartend(duelle, antworten, geraet: geraet) }
    private var entschieden: [DuellPost.Paarung] { DuellPost.entschieden(duelle, antworten) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom) {
                AbschnittsTitel("Herausforderung an die Familie",
                                text: "Du rechnest vor, die anderen rechnen nach. Jeder auf seiner Stufe.")
                Spacer()
                Button {
                    Task { await laden() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.gelb)
                        .rotationEffect(.degrees(laedt ? 360 : 0))
                        .animation(laedt ? .linear(duration: 0.9).repeatForever(autoreverses: false) : .default,
                                   value: laedt)
                }
                .accessibilityLabel("Aktualisieren")
            }

            ForEach(offen) { d in
                Button { annehmen(d) } label: { offenKarte(d) }
                    .buttonStyle(TastenStil())
            }

            neueKarte

            ForEach(wartend) { d in
                HStack(spacing: 10) {
                    Text("⏳").font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Deine Herausforderung wartet")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        Text("\(DuellRegeln.standText(d.vonStand)). Die anderen rechnen auf \(d.anStufe.name).")
                            .font(.caption)
                            .foregroundStyle(Theme.textSanft)
                    }
                    Spacer()
                }
                .padding(14)
                .flachKarte(radius: 18)
            }

            if !entschieden.isEmpty {
                Text("Entschieden")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                    .padding(.top, 6)
                ForEach(entschieden) { p in paarungKarte(p) }
            }

            if let meldung {
                Text(meldung)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.koralle)
            }
        }
        .onAppear(perform: vorbereiten)
        .task { await laden() }
        .onReceive(NotificationCenter.default.publisher(for: .cloudPush)) { _ in
            Task { await laden() }
        }
        .fullScreenCover(item: $spiel) { s in
            solo(s)
                .preferredColorScheme(.dark)
                .tint(Theme.gelb)
        }
    }

    private func vorbereiten() {
        guard !vorbereitet else { return }
        vorbereitet = true
        let klasse = DuellStufe.passend(zuKlasse: kindKlasse)
        if modus == "eltern" {
            meineStufe = .profi
            andereStufe = klasse
        } else {
            meineStufe = klasse
            andereStufe = .profi
        }
    }

    @ViewBuilder
    private func solo(_ s: DuellSoloSpiel) -> some View {
        switch s.art {
        case .neu(let anStufe, let fuerAndere):
            DuellSoloView(name: ich, stufe: s.stufe, aufgaben: s.aufgaben) { stand in
                let d = DuellHerausforderung(id: UUID().uuidString, von: ich, vonGeraet: geraet,
                                             vonStufe: s.stufe, vonStand: stand, anStufe: anStufe,
                                             aufgaben: fuerAndere, zeitpunkt: Date.now)
                duelle.append(d)
                Task { await schicke(d) }
            }
        case .antwort(let d):
            DuellSoloView(name: ich, stufe: s.stufe, aufgaben: s.aufgaben,
                          gegner: (name: d.von, stand: d.vonStand)) { stand in
                let a = DuellAntwort(duellID: d.id, name: ich, geraet: geraet, stand: stand, zeitpunkt: Date.now)
                antworten.append(a)
                Task { await schicke(a) }
            }
        }
    }

    private func starteNeu() {
        let fuerAndere = DuellRegeln.aufgaben(andereStufe)
        spiel = DuellSoloSpiel(stufe: meineStufe, aufgaben: DuellRegeln.aufgaben(meineStufe),
                               art: .neu(anStufe: andereStufe, fuerAndere: fuerAndere))
    }

    private func annehmen(_ d: DuellHerausforderung) {
        let aufgaben = d.aufgaben.isEmpty ? DuellRegeln.aufgaben(d.anStufe) : d.aufgaben
        spiel = DuellSoloSpiel(stufe: d.anStufe, aufgaben: aufgaben, art: .antwort(d))
    }

    private func laden() async {
        guard familie.aktiv, !laedt else { return }
        laedt = true
        defer { laedt = false }
        do {
            let neu = try await DuellCloud.lade()
            // Was gerade erst geschickt wurde, steht vielleicht noch nicht in der Cloud
            let ids = Set(neu.duelle.map { $0.id })
            let antwortIDs = Set(neu.antworten.map { $0.id })
            duelle = neu.duelle + duelle.filter { !ids.contains($0.id) && $0.vonGeraet == geraet }
            antworten = neu.antworten + antworten.filter { !antwortIDs.contains($0.id) && $0.geraet == geraet }
            meldung = nil
        } catch {
            meldung = "Die Duelle konnten nicht geladen werden. \(CloudDienst.fehlertext(error))"
        }
    }

    private func schicke(_ d: DuellHerausforderung) async {
        do {
            try await DuellCloud.sende(d)
            meldung = nil
        } catch {
            meldung = "Die Herausforderung ging nicht raus. Prüfe das Internet. \(CloudDienst.fehlertext(error))"
        }
    }

    private func schicke(_ a: DuellAntwort) async {
        do {
            try await DuellCloud.sende(a)
            meldung = nil
        } catch {
            meldung = "Dein Ergebnis ging nicht raus. Prüfe das Internet. \(CloudDienst.fehlertext(error))"
        }
    }

    // MARK: Karten

    private func offenKarte(_ d: DuellHerausforderung) -> some View {
        HStack(spacing: 12) {
            Text("⚔️").font(.system(size: 34))
            VStack(alignment: .leading, spacing: 3) {
                Text("\(d.von) fordert dich heraus!")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                Text("\(d.von) hat \(DuellRegeln.standText(d.vonStand)).")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.navy.opacity(0.8))
                Text("Du rechnest auf \(d.anStufe.emoji) \(d.anStufe.name). Tippe zum Annehmen.")
                    .font(.caption)
                    .foregroundStyle(Theme.navy.opacity(0.8))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(Theme.navy)
        }
        .padding(16)
        .background(Theme.gelb, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var neueKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Neue Herausforderung")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("Ich rechne auf")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSanft)
            StufenWahl(stufe: $meineStufe)
            Text("Die anderen rechnen auf")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.textSanft)
            StufenWahl(stufe: $andereStufe)
            GelberKnopf(titel: "Vorrechnen und abschicken") { starteNeu() }
        }
        .padding(16)
        .glasKarte(radius: 24)
    }

    private func paarungKarte(_ p: DuellPost.Paarung) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(p.siegerName.map { "🏆 \($0) gewinnt" } ?? "🤝 Unentschieden")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Spacer()
                Text(p.antwort.zeitpunkt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(Theme.textSanft)
            }
            Text("\(p.duell.vonStufe.emoji) \(p.duell.von): \(DuellRegeln.standText(p.duell.vonStand))")
                .font(.caption)
                .foregroundStyle(Color.white)
            Text("\(p.duell.anStufe.emoji) \(p.antwort.name): \(DuellRegeln.standText(p.antwort.stand))")
                .font(.caption)
                .foregroundStyle(Color.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .flachKarte(radius: 18)
    }
}
