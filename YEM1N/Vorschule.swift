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
import WebKit
import CoreImage.CIFilterBuiltins

// ============================================================
// MARK: - Vorschule (Zählen, Zuordnen, Muster, Memory für die Kleinen)
// ============================================================

enum VorschulArt: String, CaseIterable, Identifiable, Hashable {
    case mix, zaehlen, zahlen, plus, mehr, nachbar, formen, anlaut, anders, muster, memory
    // Fit für die Schule: Vorläuferfähigkeiten aus den Bildungsplänen
    case wuerfel, minus, zahlbild, teilen
    case buchstabe, reime, silben
    case lage, gefuehle, reihenfolge, tierwelt, verkehr, unterschied

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
        case .wuerfel: return "Würfelbilder"
        case .minus: return "Wegnehmen"
        case .zahlbild: return "Zahl und Menge"
        case .teilen: return "Gerecht teilen"
        case .buchstabe: return "Buchstaben finden"
        case .reime: return "Reime"
        case .silben: return "Silben klatschen"
        case .lage: return "Links, Mitte, rechts"
        case .gefuehle: return "Gefühle"
        case .reihenfolge: return "Was kommt danach?"
        case .tierwelt: return "Wo lebt das Tier?"
        case .verkehr: return "Sicher unterwegs"
        case .unterschied: return "Finde das andere Bild"
        }
    }

    /// Übungen mit Zahlen. Nur für sie gilt der Zahlenraum.
    static let rechnen: [VorschulArt] = [.zaehlen, .wuerfel, .zahlen, .zahlbild, .plus, .minus, .mehr, .nachbar, .teilen]
    static let sprache: [VorschulArt] = [.anlaut, .buchstabe, .reime, .silben]
    static let spielen: [VorschulArt] = [.formen, .lage, .muster, .unterschied, .anders, .reihenfolge,
                                         .gefuehle, .tierwelt, .verkehr, .memory, .mix]

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
        case .wuerfel: return "🎯"
        case .minus: return "🎈"
        case .zahlbild: return "🔟"
        case .teilen: return "🍪"
        case .buchstabe: return "🅰️"
        case .reime: return "🐭"
        case .silben: return "👏"
        case .lage: return "👈"
        case .gefuehle: return "😊"
        case .reihenfolge: return "🐣"
        case .tierwelt: return "🌍"
        case .verkehr: return "🚦"
        case .unterschied: return "🔎"
        }
    }
}

/// Eine Frage auf Deutsch und, wo es passt, auf Türkisch und Englisch.
/// Fehlt eine Sprache, wird die Frage auf Deutsch gezeigt und vorgelesen.
struct VorschulText {
    let de: String
    let tr: String?
    var en: String? = nil

    /// Die Sprache, in der diese Frage wirklich kommt: die gewünschte, wenn es sie gibt, sonst Deutsch
    func sprache(_ wunsch: String) -> String {
        switch wunsch {
        case "tr": return tr == nil ? "de" : "tr"
        case "en": return en == nil ? "de" : "en"
        default: return "de"
        }
    }

    func text(_ wunsch: String) -> String {
        switch sprache(wunsch) {
        case "tr": return tr ?? de
        case "en": return en ?? de
        default: return de
        }
    }
}

/// Die Vorschule spricht Deutsch. Englisch und Türkisch sind ein Zusatz, den die Eltern
/// unter Einstellungen, Bereiche einschalten. Erst dann gibt es den Umschalter in der Vorschule.
enum VorschulSprache {
    static let wahlSchluessel = "vorschulSprache"
    static let englischSchluessel = "vorschulEnglisch"
    static let tuerkischSchluessel = "vorschulTuerkisch"

    /// Was der Umschalter anbietet. Nur Deutsch heißt: kein Umschalter.
    static func angebot(englisch: Bool, tuerkisch: Bool) -> [String] {
        ["de"] + (englisch ? ["en"] : []) + (tuerkisch ? ["tr"] : [])
    }

    /// Die Sprache, die gerade gilt. Ist die gewählte Sprache ausgeschaltet, gilt Deutsch.
    static func aktiv(gewaehlt: String, englisch: Bool, tuerkisch: Bool) -> String {
        angebot(englisch: englisch, tuerkisch: tuerkisch).contains(gewaehlt) ? gewaehlt : "de"
    }

    /// Die Sprache aus den Einstellungen dieses Geräts
    static var jetzt: String {
        let d = UserDefaults.standard
        return aktiv(gewaehlt: d.string(forKey: wahlSchluessel) ?? "de",
                     englisch: d.bool(forKey: englischSchluessel),
                     tuerkisch: d.bool(forKey: tuerkischSchluessel))
    }

    /// Sprachcode für die Stimme
    static func code(_ sprache: String) -> String {
        switch sprache {
        case "tr": return "tr-TR"
        case "en": return "en-GB"
        default: return "de-DE"
        }
    }

    /// Name auf dem Umschalter, in der Sprache selbst
    static func name(_ sprache: String) -> String {
        switch sprache {
        case "tr": return "Türkçe"
        case "en": return "English"
        default: return "Deutsch"
        }
    }
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

    static let formen: [(frage: VorschulText, emoji: String)] = [
        (VorschulText(de: "Wo ist der Kreis?", tr: "Daire hangisi?", en: "Where is the circle?"), "🔵"),
        (VorschulText(de: "Wo ist das Quadrat?", tr: "Kare hangisi?", en: "Where is the square?"), "🟩"),
        (VorschulText(de: "Wo ist das Dreieck?", tr: "Üçgen hangisi?", en: "Where is the triangle?"), "🔺"),
        (VorschulText(de: "Wo ist der Stern?", tr: "Yıldız hangisi?", en: "Where is the star?"), "⭐"),
        (VorschulText(de: "Wo ist das Herz?", tr: "Kalp hangisi?", en: "Where is the heart?"), "💜")
    ]

    static let farben: [(frage: VorschulText, emoji: String)] = [
        (VorschulText(de: "Tippe auf Rot.", tr: "Kırmızı olanı bul.", en: "Tap the red one."), "🔴"),
        (VorschulText(de: "Tippe auf Blau.", tr: "Mavi olanı bul.", en: "Tap the blue one."), "🔵"),
        (VorschulText(de: "Tippe auf Gelb.", tr: "Sarı olanı bul.", en: "Tap the yellow one."), "🟡"),
        (VorschulText(de: "Tippe auf Grün.", tr: "Yeşil olanı bul.", en: "Tap the green one."), "🟢"),
        (VorschulText(de: "Tippe auf Lila.", tr: "Mor olanı bul.", en: "Tap the purple one."), "🟣"),
        (VorschulText(de: "Tippe auf Orange.", tr: "Turuncu olanı bul.", en: "Tap the orange one."), "🟠")
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
            return VorschulFrage(text: VorschulText(de: "Wie viele siehst du?", tr: "Kaç tane görüyorsun?", en: "How many can you see?"),
                                 zeige: Array(repeating: e, count: n),
                                 optionen: o.optionen, richtig: o.index)

        case .zahlen:
            let m = grenze(stufe)
            let n = Int.random(in: 1...m)
            let o = zahlenOptionen(richtig: n, von: 1, bis: m)
            return VorschulFrage(text: VorschulText(de: "Tippe auf die \(n).", tr: "\(n) sayısına dokun.", en: "Tap the \(n)."),
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
            return VorschulFrage(text: VorschulText(de: "\(x) plus \(y). Wie viel ist das?", tr: "\(x) artı \(y) kaç eder?",
                                                    en: "\(x) plus \(y). How many is that?"),
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
                ? VorschulText(de: "Wo sind mehr?", tr: "Hangisi daha fazla?", en: "Which side has more?")
                : VorschulText(de: "Wo sind weniger?", tr: "Hangisi daha az?", en: "Which side has fewer?")
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
                ? VorschulText(de: "Welche Zahl kommt nach der \(n)?", tr: "\(n) sayısından sonra hangi sayı gelir?",
                               en: "Which number comes after \(n)?")
                : VorschulText(de: "Welche Zahl kommt vor der \(n)?", tr: "\(n) sayısından önce hangi sayı gelir?",
                               en: "Which number comes before \(n)?")
            return VorschulFrage(text: text, gross: String(n), optionen: o.optionen, richtig: o.index)

        case .formen:
            let quelle = Bool.random() ? formen : farben
            let drei = Array(quelle.shuffled().prefix(3))
            let r = Int.random(in: 0..<3)
            return VorschulFrage(text: drei[r].frage,
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
            return VorschulFrage(text: VorschulText(de: "Was passt nicht dazu?", tr: "Hangisi diğerlerine uymuyor?",
                                                    en: "Which one does not belong?"),
                                 optionen: optionen, richtig: optionen.firstIndex(of: fremd) ?? 0)

        case .wuerfel, .minus, .zahlbild, .teilen, .buchstabe, .reime, .silben,
             .lage, .gefuehle, .reihenfolge, .tierwelt, .verkehr, .unterschied:
            return VorschulMehr.eine(art, stufe: stufe)

        default:
            let p = ["🔴", "🔵", "🟡", "🟢", "🟣", "🟠", "⭐", "❤️", "🍎", "🐟"].shuffled()
            let a = p[0]
            let b = p[1]
            let c = p[2]
            let muster: [String]
            // Muster hängen nicht vom Zahlenraum ab, die Art wechselt zufällig
            switch Int.random(in: 1...4) {
            case 1: muster = [a, b]
            case 2: muster = [a, a, b]
            case 3: muster = [a, b, b]
            default: muster = [a, b, c]
            }
            let l = muster.count
            let anzahl = Int.random(in: (l + 1)...(2 * l + 1))
            let folge = (0..<anzahl).map { muster[$0 % l] }
            let richtig = muster[anzahl % l]
            var optionen = [richtig]
            for e in p where optionen.count < 3 && e != richtig { optionen.append(e) }
            optionen.shuffle()
            return VorschulFrage(text: VorschulText(de: "Wie geht es weiter?", tr: "Sıradaki hangisi?", en: "What comes next?"),
                                 folge: folge,
                                 optionen: optionen, richtig: optionen.firstIndex(of: richtig) ?? 0)
        }
    }
}

enum VorschulTon {
    /// `sprache`: fest vorgegeben, zum Beispiel "en" bei Englisch für Kleine.
    /// Ohne Vorgabe gilt die Sprache aus dem Umschalter der Vorschule.
    static func sag(_ t: VorschulText, stimmung: SprechStimmung = .normal, sprache fest: String? = nil) {
        let sprache = t.sprache(fest ?? VorschulSprache.jetzt)
        Sprecher.shared.sprich(t.text(sprache), code: VorschulSprache.code(sprache), stimmung: stimmung)
    }

    static var name: String { UserDefaults.standard.string(forKey: "kindName") ?? "" }

    static func sag(_ t: LobText, stimmung: SprechStimmung = .normal, sprache: String? = nil) {
        sag(VorschulText(de: t.de, tr: t.tr, en: t.en), stimmung: stimmung, sprache: sprache)
    }

    /// Lob mit viel Abwechslung, siehe Lob.swift
    static func lob(serie: Int = 0, nachFehler: Bool = false, sprache: String? = nil) {
        sag(Lob.fuerRichtig(serie: serie, nachFehler: nachFehler, name: name), stimmung: .froh, sprache: sprache)
    }

    static func nochmal(sprache: String? = nil) {
        sag(Lob.fuerNochmal(), sprache: sprache)
    }

    static func ende(richtig: Int, gesamt: Int, sprache: String? = nil) {
        sag(Lob.fuerEnde(richtig: richtig, gesamt: gesamt, name: name), stimmung: .froh, sprache: sprache)
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
    @AppStorage(VorschulSprache.wahlSchluessel) private var sprache = "de"
    @AppStorage(VorschulSprache.englischSchluessel) private var englisch = false
    @AppStorage(VorschulSprache.tuerkischSchluessel) private var tuerkisch = false
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("modus") private var modus = ""
    @Namespace private var zoomRaum

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        kopf
                        // Nur wenn die Eltern Englisch oder Türkisch eingeschaltet haben
                        let angebot = VorschulSprache.angebot(englisch: englisch, tuerkisch: tuerkisch)
                        if angebot.count > 1 {
                            Picker("Sprache", selection: Binding(
                                get: { VorschulSprache.aktiv(gewaehlt: sprache, englisch: englisch, tuerkisch: tuerkisch) },
                                set: { sprache = $0 })) {
                                ForEach(angebot, id: \.self) { Text(VorschulSprache.name($0)).tag($0) }
                            }
                            .pickerStyle(.segmented)
                        }
                        if modus != "eltern" {
                            SchulstartPass()
                        }
                        abschnitt("Zahlen und Rechnen")
                        zahlenraum
                        raster(VorschulArt.rechnen)
                        abschnitt("Sprache und Laute")
                        raster(VorschulArt.sprache)
                        abschnitt("Spielen und Entdecken")
                        raster(VorschulArt.spielen)
                        if englisch {
                            abschnitt("🇬🇧 Englisch für Kleine")
                            englischRaster
                        }
                        pakete
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: VorschulArt.self) { art in
                Group {
                    if art == .memory {
                        VorschulMemory()
                    } else {
                        VorschulRunde(art: art)
                    }
                }
                .zoomZiel(art, in: zoomRaum)
            }
            .navigationDestination(for: EnglischThema.self) { EnglischThemaView(thema: $0) }
            .navigationDestination(for: Klassenarbeit.self) { VorschulPaketListe(arbeit: $0) }
            .navigationDestination(for: Uebung.self) { VorschulRunde(art: .mix, quelle: $0) }
            .confirmationDialog("Paket löschen?", isPresented: Binding(get: { loeschen != nil },
                                                                     set: { if !$0 { loeschen = nil } }),
                                titleVisibility: .visible) {
                Button("Ja, löschen", role: .destructive) {
                    if let a = loeschen { context.delete(a); try? context.save() }
                    loeschen = nil
                }
                Button("Nein, behalten", role: .cancel) { loeschen = nil }
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
        HeroKopf(kicker: "YEM1N", titel: "Vorschule",
                 untertitel: kindName.isEmpty ? "Spielen und fit für die Schule werden" : "Hallo \(kindName)! Spielen und fit für die Schule werden",
                 bild: "🧸")
    }

    private func abschnitt(_ titel: String) -> some View {
        Text(titel)
            .font(.system(.title3, design: .rounded).weight(.heavy))
            .foregroundStyle(Theme.gelb)
            .padding(.top, 8)
    }

    private var zahlenraum: some View {
        HStack(spacing: 12) {
            Text("Zahlenraum")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Color.white)
            Picker("Zahlenraum", selection: $stufe) {
                Text("Bis 5").tag(1)
                Text("Bis 10").tag(2)
                Text("Bis 20").tag(3)
            }
            .pickerStyle(.segmented)
        }
    }

    private func raster(_ arten: [VorschulArt]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
            ForEach(Array(arten.enumerated()), id: \.element.id) { i, art in
                NavigationLink(value: art) {
                    karte(art)
                        .zoomQuelle(art, in: zoomRaum)
                }
                .buttonStyle(TastenStil())
                .einblenden(i)
            }
        }
    }

    private var englischRaster: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
            ForEach(Array(EnglischThema.allCases.enumerated()), id: \.element.id) { i, thema in
                NavigationLink(value: thema) {
                    karte(emoji: thema.emoji, titel: thema.titel)
                }
                .buttonStyle(TastenStil())
                .einblenden(i)
            }
        }
    }

    private func karte(_ art: VorschulArt) -> some View {
        karte(emoji: art.emoji, titel: art.titel)
    }

    private func karte(emoji: String, titel: String) -> some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 52))
            Text(titel)
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
    /// Englisch für Kleine: Wörter hören und antippen, alles auf Englisch
    var englisch: EnglischThema? = nil
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @AppStorage("modus") private var modus = ""
    @AppStorage("vorschulStufe") private var stufe = 2
    @AppStorage(VorschulSprache.wahlSchluessel) private var sprache = "de"
    @AppStorage(VorschulSprache.englischSchluessel) private var englischAn = false
    @AppStorage(VorschulSprache.tuerkischSchluessel) private var tuerkisch = false
    @State private var fragen: [VorschulFrage] = []
    @State private var nr = 0
    @State private var perfekt = 0
    /// Richtig beim ersten Versuch, so oft hintereinander
    @State private var serie = 0
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
        .navigationTitle(englisch?.titel ?? quelle?.titel ?? art.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if fragen.isEmpty { neu() } }
    }

    private func frage(_ f: VorschulFrage) -> some View {
        ScrollView {
            VStack(spacing: 22) {
                ProgressView(value: Double(nr), total: Double(fragen.count))
                    .tint(Theme.gelb)

                Button { VorschulTon.sag(f.text, sprache: festeSprache) } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundStyle(Theme.gelb)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(f.text.text(festeSprache ?? VorschulSprache.aktiv(gewaehlt: sprache, englisch: englischAn, tuerkisch: tuerkisch)))
                                .font(.system(.title3, design: .rounded).weight(.heavy))
                                .foregroundStyle(Color.white)
                                .multilineTextAlignment(.leading)
                            if englisch != nil {
                                // Für die Eltern: was das Wort heißt
                                Text(f.text.de)
                                    .font(.footnote)
                                    .foregroundStyle(Theme.textSanft)
                            }
                        }
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
                .jubeln()
            Text("\(perfekt) von \(fragen.count) gleich richtig!")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < sterne ? "star.fill" : "star")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.gelb)
                        .shadow(color: Theme.gelb.opacity(i < sterne ? 0.6 : 0), radius: 12)
                        .einblenden(i * 3)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if sterne >= 1 {
                KonfettiRegen(anzahl: sterne == 3 ? 110 : 60)
                    .ignoresSafeArea()
            }
        }
    }

    /// Bei Englisch für Kleine spricht alles Englisch, egal was oben eingestellt ist
    private var festeSprache: String? { englisch == nil ? nil : "en" }

    private func neu() {
        if let t = englisch {
            fragen = VorschulEnglisch.fragen(t)
        } else if let u = quelle {
            fragen = VorschulPaket.fragen(u)
        } else {
            fragen = VorschulGenerator.fragen(art, stufe: stufe)
        }
        nr = 0
        perfekt = 0
        serie = 0
        zuruecksetzen()
        gespeichert = false
        if let f = fragen.first { VorschulTon.sag(f.text, sprache: festeSprache) }
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
            let ersterVersuch = falsch.isEmpty
            if ersterVersuch { perfekt += 1 }
            serie = ersterVersuch ? serie + 1 : 0
            sperre = true
            Haptik.erfolg()
            VorschulTon.lob(serie: serie, nachFehler: !ersterVersuch, sprache: festeSprache)
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                weiter()
            }
        } else {
            falsch.insert(i)
            schuettel = i
            serie = 0
            Haptik.fehler()
            VorschulTon.nochmal(sprache: festeSprache)
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
            VorschulTon.sag(fragen[nr].text, sprache: festeSprache)
        } else {
            abschliessen()
        }
    }

    private func abschliessen() {
        guard !gespeichert else { return }
        gespeichert = true
        VorschulTon.ende(richtig: perfekt, gesamt: fragen.count, sprache: festeSprache)
        guard modus == "kind" else { return }
        Muenzen.gutschreiben(Muenzen.verdient(richtig: perfekt, gesamt: fragen.count, angesehen: 0))
        Muenzen.rundeGeschafft()
        HaustierDienst.rundeGeschafft(richtig: perfekt, gesamt: fragen.count, angesehen: 0)
        let arbeitName = quelle?.arbeit?.titel ?? "Übungen"
        let uebungName = englisch?.uebungName
            ?? quelle.map { "\($0.symbol) \($0.titel)" } ?? "\(art.emoji) \(art.titel)"
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
    @State private var karten: [VorschulKarte] = []
    @State private var erste: Int?
    @State private var zuege = 0
    @State private var sperre = false
    @State private var fertig = false

    // Memory hat nichts mit dem Zahlenraum zu tun, deshalb immer 4 Paare
    private let paare = 4

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
        VorschulTon.ende(richtig: paare, gesamt: max(paare, zuege))
        fertig = true
        guard modus == "kind" else { return }
        HaustierDienst.rundeGeschafft(richtig: paare, gesamt: max(paare, zuege), angesehen: 0)
        context.insert(RundenErgebnis(klasse: "Vorschule", fach: "Vorschule", arbeit: "Übungen",
                                      uebung: "🃏 Memory",
                                      richtig: paare, gesamt: max(paare, zuege), angesehen: 0,
                                      quelle: "lokal"))
        try? context.save()
        CloudSync.anstossen(context)
    }
}
