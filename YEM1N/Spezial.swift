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

    // Wird aufgerufen, wenn eine Aufgabe richtig beantwortet wurde.
    // Im Fehlerheft zählt das erst nach der zweiten richtigen Wiederholung.
    static func gemeistert(_ a: Aufgabe, in context: ModelContext) {
        guard !a.quellKey.isEmpty else { return }
        guard Fehlerplan.richtig(a.quellKey) else { return }
        // Nur falsch beantwortete Originale kommen infrage. So lädt die App nicht jede Aufgabe.
        let beschreibung = FetchDescriptor<Aufgabe>(
            predicate: #Predicate<Aufgabe> { $0.quellKey == "" && $0.richtig == false })
        let alle = (try? context.fetch(beschreibung)) ?? []
        for o in alle where schluessel(o) == a.quellKey {
            o.gemeistert = true
        }
    }

    // Wird aufgerufen, wenn eine Aufgabe falsch beantwortet wurde
    static func falschBeantwortet(_ a: Aufgabe) {
        guard !a.quellKey.isEmpty else { return }
        Fehlerplan.falsch(a.quellKey)
    }

    /// Wie viele Fehler jetzt dran sind und wie viele erst in einigen Tagen wiederkommen.
    static func fehlerStand(alle: [Klassenarbeit], jetzt: Date = Date.now) -> (faellig: Int, wartend: Int) {
        var faellig = 0
        var wartend = 0
        let tabelle = Fehlerplan.tabelle()
        for k in alle {
            for u in k.uebungen {
                for a in u.aufgaben where a.richtig == false && !a.gemeistert {
                    if Fehlerplan.istFaellig(schluessel(a), in: tabelle, jetzt: jetzt) { faellig += 1 } else { wartend += 1 }
                }
            }
        }
        return (faellig, wartend)
    }

    /// Schnelle Variante für die Startseite: holt nur die falsch beantworteten Originale
    /// aus der Datenbank, statt alle Klassenarbeiten mit allen Aufgaben zu durchlaufen.
    static func fehlerStand(in context: ModelContext, jetzt: Date = Date.now) -> (faellig: Int, wartend: Int) {
        let beschreibung = FetchDescriptor<Aufgabe>(
            predicate: #Predicate<Aufgabe> { $0.richtig == false && $0.gemeistert == false && $0.quellKey == "" })
        let falsche = (try? context.fetch(beschreibung)) ?? []
        let tabelle = Fehlerplan.tabelle()
        var faellig = 0
        var wartend = 0
        for a in falsche {
            guard let arbeit = a.uebung?.arbeit, arbeit.spezial.isEmpty, arbeit.fach != "Vorschule" else { continue }
            if Fehlerplan.istFaellig(schluessel(a), in: tabelle, jetzt: jetzt) { faellig += 1 } else { wartend += 1 }
        }
        return (faellig, wartend)
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

    // Fehlerheft: bis zu 15 fällige, noch nicht gemeisterte Fehler als neue Runde
    static func fehlerheft(alle: [Klassenarbeit], in context: ModelContext) -> Klassenarbeit? {
        var fehler: [Aufgabe] = []
        let tabelle = Fehlerplan.tabelle()
        for k in alle {
            for u in k.sortierteUebungen {
                for a in u.sortierteAufgaben where a.richtig == false && !a.gemeistert {
                    if Fehlerplan.istFaellig(schluessel(a), in: tabelle) { fehler.append(a) }
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

    /// Jeder Bereich kommt mindestens einmal vor. Die übrigen Aufgaben werden bei
    /// jeder Probearbeit anders auf die Bereiche verteilt, die Reihenfolge der
    /// Bereiche bleibt wie in einer echten Klassenarbeit.
    static let probeBereiche = ["minuswort", "malwort", "kern", "nachbar", "einmaleins",
                                "umkehr", "rest", "punkt", "vergleich", "mauer", "raetsel", "sach"]
    static let probeAufgaben = 20
    /// Mehr als zwei Zahlenmauern wären zu viel Schreibarbeit.
    static let probeMaxMauern = 2

    static func probePlan<G: RandomNumberGenerator>(zufall: inout G) -> [(String, Int)] {
        var anzahl = Dictionary(uniqueKeysWithValues: probeBereiche.map { ($0, 1) })
        var uebrig = probeAufgaben - probeBereiche.count
        while uebrig > 0 {
            guard let id = probeBereiche.randomElement(using: &zufall) else { break }
            if id == "mauer" && (anzahl[id] ?? 0) >= probeMaxMauern { continue }
            anzahl[id, default: 0] += 1
            uebrig -= 1
        }
        return probeBereiche.map { ($0, anzahl[$0] ?? 1) }
    }

    /// Eine angefangene Probearbeit wird nur weitergemacht, wenn sie heute begonnen
    /// wurde und schon Antworten hat. Sonst gibt es beim Antippen neue Aufgaben.
    static func probeWeiterfuehren(erstellt: Date, beantwortet: Int, jetzt: Date = Date.now,
                                   kalender: Calendar = .current) -> Bool {
        beantwortet > 0 && kalender.isDate(erstellt, inSameDayAs: jetzt)
    }

    static func beantwortetAnzahl(_ k: Klassenarbeit) -> Int {
        k.uebungen.reduce(0) { $0 + $1.aufgaben.filter { $0.richtig != nil }.count }
    }

    static func probe(alle: [Klassenarbeit], fruehere: [Klassenarbeit] = [],
                      in context: ModelContext) -> Klassenarbeit {
        var generator = SystemRandomNumberGenerator()
        let plan = probePlan(zufall: &generator)
        // Weder die Aufgaben der Klassenarbeiten noch die der letzten Probearbeit
        var sperre = vorhandeneSchluessel(alle + fruehere)
        let arbeit = neueArbeit(titel: "Probearbeit", art: "probe", klasse: klasseVon(alle), in: context)
        let u = neueUebung(arbeit, titel: "Probearbeit", gruppe: "Wie in der Klassenarbeit", symbol: "★",
                           tipp: "", reihenfolge: 0, in: context)
        var inDieserProbe = Set<String>()
        var nummer = 0
        for (id, anzahl) in plan {
            guard let v = MatheGenerator.vorlagen.first(where: { $0.id == id }) else { continue }
            var aufgaben = MatheGenerator.fuelle(v, anzahl: anzahl, ausschluss: &sperre)
            for m in aufgaben { inDieserProbe.insert(MatheGenerator.schluessel(m)) }
            if aufgaben.count < anzahl {
                // Kleine Bereiche (Kernaufgaben, Umkehraufgaben) sind nach vielen
                // Klassenarbeiten leer gefischt. Dann dürfen sie wiederkommen.
                var nurDiese = inDieserProbe
                aufgaben += MatheGenerator.fuelle(v, anzahl: anzahl - aufgaben.count, ausschluss: &nurDiese)
            }
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
