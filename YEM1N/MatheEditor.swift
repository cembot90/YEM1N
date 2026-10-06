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
