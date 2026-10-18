import SwiftUI
import SwiftData
import Foundation

// ============================================================
// MARK: - Lernwelt: fertige Aufgaben nach dem Lehrplan
// ============================================================
//
// Ohne dass Eltern etwas laden müssen, gibt es hier Aufgaben für Klasse 1 bis 4 in
// Mathe, Deutsch, Englisch, Musik und Kunst. Grundlage sind die Lehrpläne von Hessen
// (Kerncurriculum), Bayern (LehrplanPLUS) und Nordrhein-Westfalen (Lehrplan 2021),
// die alle auf den Bildungsstandards der Kultusministerkonferenz aufbauen.
// Wo ein Land ein Thema in einer anderen Klasse hat, steht das beim Thema.
//
// Jedes Thema erzeugt seine Aufgaben selbst, jedes Mal neue. Die Rechnungen rechnet
// der Code, die Wörter stehen in geprüften Listen. Geübt wird in der normalen Übung,
// darum gibt es Sterne, Münzen, Ergebnisse für die Eltern, Stift und Erklärbilder.

enum Bundesland: String, CaseIterable, Identifiable {
    case hessen, bayern, nrw

    static let key = "bundesland"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .hessen: return "Hessen"
        case .bayern: return "Bayern"
        case .nrw: return "Nordrhein-Westfalen"
        }
    }

    var kurz: String { self == .nrw ? "NRW" : name }

    var lehrplan: String {
        switch self {
        case .hessen: return "Kerncurriculum Hessen"
        case .bayern: return "LehrplanPLUS Bayern"
        case .nrw: return "Lehrplan NRW"
        }
    }

    /// Ohne Auswahl gilt Hessen.
    static func aus(_ roh: String) -> Bundesland { Bundesland(rawValue: roh) ?? .hessen }
}

enum LehrFach: String, CaseIterable, Identifiable {
    case mathe, deutsch, englisch, musik, kunst

    var id: String { rawValue }

    var name: String {
        switch self {
        case .mathe: return "Mathe"
        case .deutsch: return "Deutsch"
        case .englisch: return "Englisch"
        case .musik: return "Musik"
        case .kunst: return "Kunst"
        }
    }

    var emoji: String {
        switch self {
        case .mathe: return "🔢"
        case .deutsch: return "📖"
        case .englisch: return "🇬🇧"
        case .musik: return "🎵"
        case .kunst: return "🎨"
        }
    }
}

/// Eine Aufgabe, bevor sie in die Übung kommt.
struct LernAufgabe: Equatable {
    /// "zahl", "rest" oder "wahl" (Antwort antippen)
    var art = "zahl"
    var frage: String
    var rechnung = ""
    var antwort: String
    var antwort2 = ""
    var hinweis = ""
    var erklaerung = ""
    /// Bei "wahl": alle Antworten zum Antippen, die richtige ist dabei
    var optionen: [String] = []
    /// Ein kleines Bild über der Aufgabe, siehe AufgabenBild
    var bild = ""
    /// Nur bei "mauer": die Steine von unten nach oben
    var reihen: [[Int]] = []

    /// Zwei Aufgaben mit gleichem Schlüssel gelten als dieselbe.
    var schluessel: String {
        [art, frage, rechnung, bild, antwort, reihen.map { $0.map(String.init).joined(separator: ",") }.joined(separator: ";")]
            .joined(separator: "|")
    }
}

struct LernThema: Identifiable {
    let id: String
    let fach: LehrFach
    let titel: String
    let emoji: String
    let beschreibung: String
    /// In dieser Klasse steht das Thema im Lehrplan
    let klasse: Int
    /// Länder, die das Thema in einer anderen Klasse haben
    var abweichend: [Bundesland: Int] = [:]
    /// false bei Extras außerhalb des Lehrplans, etwa Englisch in Klasse 1 und 2
    var lehrplan = true
    var tipp = ""
    let erzeuge: () -> LernAufgabe

    func klasse(in land: Bundesland) -> Int { abweichend[land] ?? klasse }
}

// MARK: - Helfer zum Erzeugen

enum Lern {
    static func z(_ r: ClosedRange<Int>) -> Int { Int.random(in: r) }

    /// Ein zufälliges Element. Die Listen hier sind nie leer.
    static func eins<T>(_ liste: [T]) -> T { liste[Int.random(in: 0..<liste.count)] }

    static func wahr(_ anteil: Double) -> Bool { Double.random(in: 0..<1) < anteil }

    /// Große Zahlen mit Abstand wie im Schulbuch: 45 300
    static func gross(_ n: Int) -> String {
        guard n >= 10_000 else { return String(n) }
        var ziffern = Array(String(n))
        var teile: [String] = []
        while ziffern.count > 3 {
            teile.insert(String(ziffern.suffix(3)), at: 0)
            ziffern.removeLast(3)
        }
        teile.insert(String(ziffern), at: 0)
        return teile.joined(separator: " ")
    }

    /// Eine Aufgabe zum Antippen. Doppelte und falsche Antworten, die gleich der richtigen
    /// sind, fallen weg. Die Reihenfolge der Knöpfe ist jedes Mal anders.
    static func wahl(frage: String, rechnung: String = "", richtig: String, falsch: [String],
                     anzahl: Int = 3, bild: String = "", hinweis: String = "",
                     erklaerung: String = "") -> LernAufgabe {
        var andere: [String] = []
        for f in falsch.shuffled() where f != richtig && !andere.contains(f) && andere.count < anzahl - 1 {
            andere.append(f)
        }
        return LernAufgabe(art: "wahl", frage: frage, rechnung: rechnung, antwort: richtig,
                           hinweis: hinweis, erklaerung: erklaerung,
                           optionen: ([richtig] + andere).shuffled(), bild: bild)
    }

    /// Größer, kleiner oder gleich. Die Seiten stehen als Text da, die Werte rechnet der Aufrufer.
    static func vergleich(_ links: String, _ a: Int, _ rechts: String, _ b: Int) -> LernAufgabe {
        let zeichen = a < b ? "<" : (a > b ? ">" : "=")
        let l = links == String(a) ? links : "\(links) = \(a)"
        let r = rechts == String(b) ? rechts : "\(rechts) = \(b)"
        return LernAufgabe(art: "vergleich", frage: "Was gehört in die Mitte?",
                           rechnung: "\(links)  ?  \(rechts)", antwort: zeichen,
                           erklaerung: links == String(a) && rechts == String(b)
                               ? "\(links) \(zeichen) \(rechts)"
                               : "\(l) und \(r), also \(a) \(zeichen) \(b)")
    }

    static func zahl(_ frage: String, _ rechnung: String, _ antwort: Int,
                     erklaerung: String = "", hinweis: String = "") -> LernAufgabe {
        LernAufgabe(art: "zahl", frage: frage, rechnung: rechnung, antwort: String(antwort),
                    hinweis: hinweis, erklaerung: erklaerung)
    }
}

// MARK: - Alle Themen und das Speichern als Übung

enum Lernwelt {
    static let spezial = "lernwelt"
    static let anzahl = 10

    static var themen: [LernThema] {
        LehrplanMathe.themen + LehrplanMatheMehr.themen
            + LehrplanDeutsch.themen + LehrplanDeutschMehr.themen + LehrplanLesen.themen
            + LehrplanEnglisch.themen + LehrplanMusik.themen + LehrplanKunst.themen
    }

    static func themenFuer(_ fach: LehrFach, klasse: Int, land: Bundesland) -> [LernThema] {
        themen.filter { $0.fach == fach && $0.klasse(in: land) == klasse }
    }

    /// Zehn verschiedene Aufgaben eines Themas
    static func aufgaben(_ t: LernThema, anzahl: Int = anzahl) -> [LernAufgabe] {
        var liste: [LernAufgabe] = []
        var gesehen = Set<String>()
        var versuche = 0
        while liste.count < anzahl && versuche < 600 {
            versuche += 1
            let a = t.erzeuge()
            if gesehen.insert(a.schluessel).inserted { liste.append(a) }
        }
        return liste
    }

    /// Die Klasse aus dem Profil als Zahl. Vorschule übt mit Klasse 1, ohne Klasse gibt es nil.
    static func klasse(aus profil: String) -> Int? {
        if profil == "Vorschule" { return 1 }
        guard let n = Int(profil.filter(\.isNumber)), (1...4).contains(n) else { return nil }
        return n
    }

    /// Zuerst die eigene Klasse, dann die anderen
    static func klassenReihenfolge(eigene: Int?) -> [Int] {
        guard let e = eigene else { return [1, 2, 3, 4] }
        return [e] + [1, 2, 3, 4].filter { $0 != e }
    }

    static func gespeichert(_ t: LernThema, in vorhandene: [Klassenarbeit]) -> Klassenarbeit? {
        vorhandene.first { $0.spezial == spezial && $0.uebungen.first?.gruppe == t.id }
    }

    /// Die Übung zu einem Thema. Eine angefangene geht weiter, eine fertige bekommt neue Aufgaben.
    /// Sterne und Bestwert bleiben dabei erhalten.
    static func uebung(fuer t: LernThema, land: Bundesland, vorhandene: [Klassenarbeit],
                       in context: ModelContext) -> Uebung {
        var beste = 0
        var sterne = 0
        if let alt = gespeichert(t, in: vorhandene), let u = alt.uebungen.first {
            if !u.aufgaben.isEmpty && !u.istFertig { return u }
            beste = u.beste
            sterne = u.sterne
            context.delete(alt)
        }
        let arbeit = Klassenarbeit(klasse: "Klasse \(t.klasse(in: land))", fach: t.fach.name, titel: "Lernwelt")
        arbeit.spezial = spezial
        context.insert(arbeit)
        let u = Uebung(titel: t.titel, gruppe: t.id, symbol: t.emoji, tipp: t.tipp, reihenfolge: 0)
        u.beste = beste
        u.sterne = sterne
        context.insert(u)
        u.arbeit = arbeit
        for (i, la) in aufgaben(t).enumerated() {
            var reihenJSON = ""
            if !la.reihen.isEmpty, let d = try? JSONEncoder().encode(la.reihen) {
                reihenJSON = String(data: d, encoding: .utf8) ?? ""
            }
            let a = Aufgabe(art: la.art, frage: la.frage, rechnung: la.rechnung, hinweis: la.hinweis,
                            erklaerung: la.erklaerung, antwort: la.antwort, antwort2: la.antwort2,
                            reihenJSON: reihenJSON, reihenfolge: i)
            a.optionen = la.optionen.joined(separator: "\n")
            a.bild = la.bild
            context.insert(a)
            a.uebung = u
        }
        return u
    }
}

// MARK: - Ansicht

/// Ziel für die Navigation im Tab Schule
struct LernweltZiel: Hashable {}

struct LernweltView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(Bundesland.key) private var landRoh = ""
    @AppStorage("kindKlasse") private var kindKlasse = ""
    @Query(filter: #Predicate<Klassenarbeit> { $0.spezial == "lernwelt" })
    private var gespeicherte: [Klassenarbeit]
    @State private var fach: LehrFach = .mathe
    @State private var offen: Uebung?
    @State private var andereOffen = false

    private var land: Bundesland { Bundesland.aus(landRoh) }
    private var eigene: Int? { Lernwelt.klasse(aus: kindKlasse) }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    kopf
                    fachWahl
                    let reihen = Lernwelt.klassenReihenfolge(eigene: eigene)
                    ForEach(Array(reihen.enumerated()), id: \.element) { i, k in
                        if eigene == nil || i == 0 {
                            klassenAbschnitt(k)
                        } else if andereOffen {
                            klassenAbschnitt(k)
                        }
                        if eigene != nil && i == 0 {
                            andereKnopf
                        }
                    }
                    Text("Die Aufgaben folgen dem \(land.lehrplan) und den Bildungsstandards der Kultusministerkonferenz. Schulbücher und Lehrkräfte setzen die Reihenfolge manchmal etwas anders.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                        .padding(.top, 6)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Lernwelt")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $offen) { UebungView(uebung: $0) }
    }

    private var kopf: some View {
        HStack(spacing: 14) {
            Text("🌍").font(.system(size: 44))
            VStack(alignment: .leading, spacing: 4) {
                Text("Lernwelt")
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(Color.white)
                Text("Aufgaben nach dem Lehrplan, immer wieder neu")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
            Menu {
                Picker("Bundesland", selection: Binding(get: { land.rawValue }, set: { landRoh = $0 })) {
                    ForEach(Bundesland.allCases) { b in Text(b.name).tag(b.rawValue) }
                }
            } label: {
                Text(land.kurz)
                    .font(.system(.footnote, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Theme.gelb, in: Capsule())
            }
            .accessibilityLabel("Bundesland: \(land.name)")
        }
    }

    private var fachWahl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LehrFach.allCases) { f in
                    let aktiv = f == fach
                    Button {
                        withAnimation(.smooth(duration: 0.25)) { fach = f }
                    } label: {
                        Text("\(f.emoji) \(f.name)")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(aktiv ? Theme.navy : Color.white)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 38)
                            .background(aktiv ? Theme.gelb : Color.white.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var andereKnopf: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) { andereOffen.toggle() }
        } label: {
            Label(andereOffen ? "Andere Klassen ausblenden" : "Andere Klassen zum Wiederholen oder Vorgreifen",
                  systemImage: andereOffen ? "chevron.up" : "chevron.down")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.gelb)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Theme.gelb.opacity(0.12), in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    @ViewBuilder
    private func klassenAbschnitt(_ k: Int) -> some View {
        let liste = Lernwelt.themenFuer(fach, klasse: k, land: land)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Klasse \(k)")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                if k == eigene {
                    Text("deine Klasse")
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.gelb, in: Capsule())
                }
            }
            if liste.isEmpty {
                Text(fach == .englisch
                     ? "Englisch steht ab Klasse 3 im Lehrplan."
                     : "Für diese Klasse kommen bald Themen dazu.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            ForEach(liste) { t in
                Button { oeffne(t) } label: { themaKarte(t) }
                    .buttonStyle(TastenStil())
            }
        }
    }

    private func themaKarte(_ t: LernThema) -> some View {
        let u = Lernwelt.gespeichert(t, in: gespeicherte)?.uebungen.first
        return HStack(spacing: 14) {
            Text(t.emoji)
                .font(.system(size: 30))
                .frame(width: 52, height: 52)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(t.titel)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                    if !t.lehrplan {
                        Text("Extra")
                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.navy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.mint, in: Capsule())
                    }
                }
                Text(t.beschreibung)
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
                    .multilineTextAlignment(.leading)
                if let u, u.laufend {
                    Text("Weiter bei Aufgabe \(u.beantwortet + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Theme.gelb)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(i < (u?.sterne ?? 0) ? Theme.gelb : Color.white.opacity(0.22))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 22)
    }

    private func oeffne(_ t: LernThema) {
        Haptik.leicht()
        offen = Lernwelt.uebung(fuer: t, land: land, vorhandene: gespeicherte, in: context)
    }
}

/// Die große Karte im Tab Schule
struct LernweltKarte: View {
    var body: some View {
        BereichsKarte(bild: "🌍", titel: "Lernwelt",
                      text: "Mathe, Deutsch, Englisch, Musik und Kunst nach dem Lehrplan. Immer neue Aufgaben.",
                      betont: true)
    }
}
