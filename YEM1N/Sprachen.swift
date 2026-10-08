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
// MARK: - Sprachen (Englisch, Türkisch und Italienisch)
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
    /// Hinweise nur für eine Sprache, zum Beispiel zu "anneanne" oder "l'amico".
    let hinweise: [String: String]
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
        var hinweise: [String: String] = [:]
        var eigeneID = ""
        var alt: [String: [String]] = [:]
        for key in c.allKeys {
            switch key.stringValue {
            case "emoji": emoji = try? c.decode(String.self, forKey: key)
            case "hinweis": hinweis = try? c.decode(String.self, forKey: key)
            case "hinweise": hinweise = (try? c.decode([String: String].self, forKey: key)) ?? [:]
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
        self.hinweise = hinweise
        self.texte = texte
        self.alt = alt
        self.themaID = ""
        self.bilder = true
    }
}

extension Wort {
    /// Der Hinweis für diese Lernsprache. Ein Hinweis nur für eine andere Sprache
    /// erscheint hier nicht, ein allgemeiner Hinweis gilt für alle.
    func hinweis(fuer sprache: String) -> String? {
        if let h = hinweise[sprache], !h.isEmpty { return h }
        if let h = hinweis, !h.isEmpty { return h }
        return nil
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
        self.lernsprachen = (try? c.decode([String].self, forKey: .lernsprachen)) ?? ["en", "tr", "it"]
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
        if sp == "it" {
            // l'amico und l’amico sind dasselbe, der Artikel davor ist egal
            t = t.replacingOccurrences(of: "\u{2019}", with: "'").replacingOccurrences(of: "\u{2018}", with: "'")
            for p in ["l'", "un'"] where t.hasPrefix(p) {
                t = String(t.dropFirst(p.count))
                break
            }
        }
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
        if sp == "it" {
            for p in ["il ", "lo ", "la ", "i ", "gli ", "le ", "un ", "uno ", "una "] where t.hasPrefix(p) {
                t = String(t.dropFirst(p.count))
                break
            }
        }
        return t
    }

    /// Die Zusatztasten über der Tastatur beim Tippen.
    static func sonderzeichen(_ sp: String) -> [String] {
        switch sp {
        case "tr": return ["ç", "ğ", "ı", "ö", "ş", "ü", "İ"]
        case "it": return ["à", "è", "é", "ì", "ò", "ù"]
        default: return []
        }
    }

    // Sonderzeichen vereinfachen, damit "kirmizi" als fast richtig für "kırmızı" gilt
    static func falte(_ s: String) -> String {
        var t = s
        let paare: [(String, String)] = [
            ("ı", "i"), ("İ", "i"), ("ğ", "g"), ("ü", "u"), ("ş", "s"), ("ö", "o"),
            ("ç", "c"), ("â", "a"), ("ä", "a"), ("î", "i"), ("û", "u"), ("ß", "ss"),
            ("à", "a"), ("è", "e"), ("é", "e"), ("ì", "i"), ("ò", "o"), ("ù", "u")
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
            HaustierDienst.rundeGeschafft(richtig: richtig, gesamt: gesamt, angesehen: 0)
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
    @AppStorage(SprachAuswahl.schluessel) private var sprachWahl = ""
    @AppStorage(HaustierSpeicher.key) private var haustierDaten = Data()
    @Environment(\.scenePhase) private var phase

    private var hatSprachen: Bool {
        !SprachAuswahl.aktiv(roh: sprachWahl, alle: SprachKatalogStore.shared.katalog.lernsprachen).isEmpty
    }

    var body: some View {
        TabView {
            StartView()
                .tabItem { Label("Schule", systemImage: "books.vertical.fill") }
            if hatSprachen {
                SprachStartView()
                    .tabItem { Label("Sprachen", systemImage: "globe") }
            }
            if vorschul {
                VorschuleView()
                    .tabItem { Label("Vorschule", systemImage: "sparkles") }
            }
            HaustierView()
                .tabItem { Label("Haustier", systemImage: "pawprint.fill") }
                .badge(HaustierDienst.braucheAufmerksamkeit(haustierDaten) ? 1 : 0)
            KindJokerView()
                .tabItem { Label("Joker", systemImage: "suit.spade.fill") }
            EinstellungenView(eingebettet: true)
                .tabItem { Label("Einstellungen", systemImage: "gearshape.fill") }
        }
        .task {
            WidgetBruecke.aktualisieren()
            await HaustierErinnerung.aktualisieren()
        }
        .onChange(of: phase) {
            if phase == .active {
                WidgetBruecke.aktualisieren()
                Task { await HaustierErinnerung.aktualisieren() }
            }
        }
    }
}

// MARK: Sprachen: Startseite

struct SprachStartView: View {
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared
    @AppStorage("sprachTon") private var ton = true
    @AppStorage(SprachAuswahl.schluessel) private var sprachWahl = ""

    private var aktive: [String] {
        SprachAuswahl.aktiv(roh: sprachWahl, alle: store.katalog.lernsprachen)
    }

    private var stimmenFehlen: Bool {
        !aktive.allSatisfy {
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
                        ForEach(aktive, id: \.self) { c in
                            sprachKarte(c)
                        }
                        if aktive.isEmpty {
                            Text("Du hast keine Sprache gewählt. Wähle in den Einstellungen unter „Sprachen“, was du lernen möchtest.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSanft)
                                .padding(16)
                                .glasKarte(radius: 22)
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
    @AppStorage(SprachAuswahl.schluessel) private var sprachWahl = ""
    private let store = SprachKatalogStore.shared
    private let stand = SprachStand.shared

    private var aktive: [String] {
        SprachAuswahl.aktiv(roh: sprachWahl, alle: store.katalog.lernsprachen)
    }

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
            ForEach(aktive, id: \.self) { c in
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
                    if let h = w.hinweis(fuer: sprache) {
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
            if !SprachHelfer.sonderzeichen(sprache).isEmpty && !s.beantwortet {
                HStack(spacing: 6) {
                    ForEach(SprachHelfer.sonderzeichen(sprache), id: \.self) { z in
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
            if let h = f.wort.hinweis(fuer: sprache) {
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
    @AppStorage(SprachAuswahl.schluessel) private var sprachWahl = ""

    private var aktive: [String] {
        SprachAuswahl.aktiv(roh: sprachWahl, alle: store.katalog.lernsprachen)
    }
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
            if let erste = aktive.first, !aktive.contains(c) { c = erste }
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            ForEach(aktive, id: \.self) { code in
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
