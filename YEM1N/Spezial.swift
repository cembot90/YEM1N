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
