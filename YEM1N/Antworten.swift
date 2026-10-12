import Foundation

// ============================================================
// MARK: - Antworten einer Runde (für die Eltern-Übersicht)
// ============================================================
//
// Am Ende jeder Runde merkt sich das Kind-Gerät zu jeder Aufgabe, was das Kind
// eingegeben hat. Das geht als kurzer JSON-Text im Feld "details" des
// Rundenergebnisses in die Cloud. Die Eltern sehen damit nicht nur, in welcher
// Übung es hakt, sondern genau bei welcher Aufgabe und was das Kind geschrieben hat.

/// Eine einzelne Aufgabe einer Runde, so wie die Eltern sie sehen.
/// Die kurzen Schlüssel halten den Cloud-Eintrag klein.
struct AntwortDetail: Codable, Equatable, Identifiable {
    /// Nummer der Aufgabe in der Runde, ab 1
    var nr: Int
    /// Frage, zum Beispiel "Rechne."
    var frage: String
    /// Rechnung oder Wort, zum Beispiel "7 · 8 =" oder "Hun?"
    var rechnung: String
    /// Was das Kind eingegeben hat. Leer, wenn es die Lösung angeschaut hat.
    var eingabe: String
    /// Die richtige Lösung, lesbar aufbereitet
    var loesung: String
    /// "richtig", "falsch", "angeschaut" oder "offen"
    var stand: String

    var id: Int { nr }

    enum CodingKeys: String, CodingKey {
        case nr = "n", frage = "f", rechnung = "r", eingabe = "e", loesung = "l", stand = "s"
    }

    var istProblem: Bool { stand == AntwortStand.falsch || stand == AntwortStand.angeschaut }
}

enum AntwortStand {
    static let richtig = "richtig"
    static let falsch = "falsch"
    static let angeschaut = "angeschaut"
    static let offen = "offen"
}

enum AntwortProtokoll {
    /// Obergrenze für einen Text im Protokoll, damit lange Sachaufgaben den Eintrag nicht aufblähen.
    static let maxTextLaenge = 240

    // MARK: Aufbauen (Kind-Gerät)

    /// Ein Eintrag aus den Daten einer Aufgabe. Mit einfachen Werten, damit es sich gut testen lässt.
    static func eintrag(nr: Int, art: String, frage: String, rechnung: String,
                        antwort: String, antwort2: String, reihen: [[Int]],
                        richtig: Bool?, angesehen: Bool,
                        gegeben: String, soll: String) -> AntwortDetail {
        let stand: String
        if angesehen {
            stand = AntwortStand.angeschaut
        } else if let richtig {
            stand = richtig ? AntwortStand.richtig : AntwortStand.falsch
        } else {
            stand = AntwortStand.offen
        }
        return AntwortDetail(nr: nr,
                             frage: kuerze(frage),
                             rechnung: kuerze(rechnungText(art: art, rechnung: rechnung, reihen: reihen)),
                             eingabe: stand == AntwortStand.angeschaut ? "" : kuerze(gegeben),
                             loesung: kuerze(loesungText(art: art, antwort: antwort, antwort2: antwort2,
                                                         reihen: reihen, soll: soll)),
                             stand: stand)
    }

    /// Bei Zahlenmauern gibt es keine Rechnung, dann beschreiben wir die unterste Reihe.
    static func rechnungText(art: String, rechnung: String, reihen: [[Int]]) -> String {
        if art == "mauer" {
            let unten = (reihen.first ?? []).map(String.init).joined(separator: ", ")
            return unten.isEmpty ? "Zahlenmauer" : "Zahlenmauer, unten: \(unten)"
        }
        return rechnung
    }

    static func loesungText(art: String, antwort: String, antwort2: String,
                            reihen: [[Int]], soll: String) -> String {
        switch art {
        case "rest":
            return "\(antwort) Rest \(antwort2)"
        case "mauer":
            if !soll.isEmpty { return soll }
            if let spitze = reihen.last?.first { return "Spitze \(spitze)" }
            return ""
        default:
            return antwort
        }
    }

    static func kuerze(_ text: String) -> String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count > maxTextLaenge else { return t }
        return String(t.prefix(maxTextLaenge)) + " ..."
    }

    // MARK: Speichern und Lesen

    static func json(_ liste: [AntwortDetail]) -> String {
        guard !liste.isEmpty,
              let d = try? JSONEncoder().encode(liste),
              let s = String(data: d, encoding: .utf8) else { return "" }
        return s
    }

    static func liste(aus json: String) -> [AntwortDetail] {
        guard !json.isEmpty, let d = json.data(using: .utf8),
              let liste = try? JSONDecoder().decode([AntwortDetail].self, from: d) else { return [] }
        return liste.sorted { $0.nr < $1.nr }
    }

    // MARK: Auswerten (Eltern-Gerät)

    /// Eingabe für die Anzeige. Mehrzeilige Rechnungen (Rätsel, Sachaufgaben) werden einzeilig.
    static func einzeilig(_ text: String) -> String {
        text.split(whereSeparator: { $0.isNewline }).joined(separator: " ")
    }
}

/// Eine Aufgabe, bei der das Kind über mehrere Runden Probleme hatte.
struct ProblemAufgabe: Identifiable, Equatable {
    let uebung: String
    let frage: String
    let rechnung: String
    let loesung: String
    var falsch: Int = 0
    var angeschaut: Int = 0
    var richtig: Int = 0
    /// Die falschen Eingaben des Kindes, neueste zuerst, ohne Wiederholungen
    var falscheEingaben: [String] = []
    var zuletzt: Date = .distantPast
    /// true, wenn das Kind die Aufgabe beim letzten Mal richtig hatte
    var zuletztRichtig = false

    var id: String { uebung + "|" + frage + "|" + rechnung }
    var problemAnzahl: Int { falsch + angeschaut }
}

extension AntwortProtokoll {
    /// Sammelt über alle Runden die Aufgaben, die falsch waren oder deren Lösung angeschaut wurde.
    /// Gleiche Aufgaben aus verschiedenen Runden werden zusammengefasst.
    /// Sortiert: zuerst die, die noch nicht sitzen, dann nach Anzahl der Probleme.
    static func problemAufgaben(_ runden: [(uebung: String, zeitpunkt: Date, details: String)],
                                limit: Int = 8) -> [ProblemAufgabe] {
        var sammlung: [String: ProblemAufgabe] = [:]
        let sortiert = runden.sorted { $0.zeitpunkt < $1.zeitpunkt }
        for runde in sortiert {
            for d in liste(aus: runde.details) where d.stand != AntwortStand.offen {
                var p = sammlung[runde.uebung + "|" + d.frage + "|" + d.rechnung]
                    ?? ProblemAufgabe(uebung: runde.uebung, frage: d.frage,
                                      rechnung: d.rechnung, loesung: d.loesung)
                switch d.stand {
                case AntwortStand.falsch:
                    p.falsch += 1
                    let e = einzeilig(d.eingabe)
                    if !e.isEmpty {
                        p.falscheEingaben.removeAll { $0 == e }
                        p.falscheEingaben.insert(e, at: 0)
                    }
                case AntwortStand.angeschaut:
                    p.angeschaut += 1
                default:
                    p.richtig += 1
                }
                p.zuletztRichtig = d.stand == AntwortStand.richtig
                p.zuletzt = runde.zeitpunkt
                sammlung[p.id] = p
            }
        }
        let probleme = sammlung.values.filter { $0.problemAnzahl > 0 }
        let reihenfolge = probleme.sorted { a, b in
            if a.zuletztRichtig != b.zuletztRichtig { return !a.zuletztRichtig }
            if a.problemAnzahl != b.problemAnzahl { return a.problemAnzahl > b.problemAnzahl }
            return a.zuletzt > b.zuletzt
        }
        return Array(reihenfolge.prefix(limit))
    }
}

extension Aufgabe {
    /// Der Eintrag für das Antwort-Protokoll der Runde.
    func antwortDetail(nr: Int) -> AntwortDetail {
        AntwortProtokoll.eintrag(nr: nr, art: art, frage: frage, rechnung: rechnung,
                                 antwort: antwort, antwort2: antwort2, reihen: reihen,
                                 richtig: richtig, angesehen: angesehen,
                                 gegeben: gegeben, soll: gegebenSoll)
    }
}

// MARK: - Beispieldaten für die Eltern-Übersicht

extension AntwortProtokoll {
    /// Erfundene Antworten für eine Beispielrunde. Die Aufgaben kommen aus einem kleinen Vorrat,
    /// damit sich dieselben Aufgaben über mehrere Runden wiederholen, wie im echten Leben.
    static func beispiel(uebung: String, gesamt: Int, richtig: Int, angesehen: Int) -> String {
        var staende: [String] = Array(repeating: AntwortStand.richtig, count: max(gesamt, 0))
        let falschAnzahl = max(gesamt - richtig - angesehen, 0)
        for i in 0..<min(falschAnzahl + angesehen, staende.count) {
            staende[i] = i < falschAnzahl ? AntwortStand.falsch : AntwortStand.angeschaut
        }
        staende.shuffle()
        var liste: [AntwortDetail] = []
        for (i, stand) in staende.enumerated() {
            let (frage, rechnung, loesung, falsch) = beispielAufgabe(uebung, nr: i)
            liste.append(AntwortDetail(nr: i + 1, frage: frage, rechnung: rechnung,
                                       eingabe: stand == AntwortStand.richtig ? loesung
                                           : (stand == AntwortStand.falsch ? falsch : ""),
                                       loesung: loesung, stand: stand))
        }
        return json(liste)
    }

    private static func beispielAufgabe(_ uebung: String, nr: Int)
        -> (frage: String, rechnung: String, loesung: String, falsch: String) {
        switch uebung {
        case "Teilen mit Rest":
            let vorrat = [(58, 4), (47, 6), (93, 7), (35, 8), (76, 5), (29, 3)]
            let (a, b) = vorrat[Int.random(in: 0..<vorrat.count)]
            return ("Teile mit Rest. Rechne bis zum Ende.", "\(a) : \(b) =",
                    "\(a / b) Rest \(a % b)", "\(a / b - 1) Rest \(a % b + b)")
        case "Zahlenmauern":
            let unten = [Int.random(in: 3...15), Int.random(in: 3...15), Int.random(in: 3...15)]
            let mitte = unten[0] + unten[1]
            return ("Fülle die Mauer von unten nach oben.",
                    "Zahlenmauer, unten: " + unten.map(String.init).joined(separator: ", "),
                    "\(unten[0]) + \(unten[1]) = \(mitte)", "\(mitte + 10)")
        case "Sachaufgaben":
            let vorrat = [("Mia hat 4 Kisten mit je 9 Äpfeln. Wie viele Äpfel sind das?", 36, 13),
                          ("Ben hat 63 Murmeln und gibt 18 ab. Wie viele bleiben?", 45, 55),
                          ("Lena teilt 48 Sticker gerecht an 6 Kinder. Wie viele bekommt jedes?", 8, 42)]
            let (text, l, f) = vorrat[Int.random(in: 0..<vorrat.count)]
            return ("Lies genau. Rechne und antworte.", text, "\(l)", "\(f)")
        default:
            let vorrat = [(7, 8), (6, 7), (8, 6), (9, 7), (6, 9), (4, 8), (3, 7), (8, 8)]
            let (a, b) = vorrat[Int.random(in: 0..<vorrat.count)]
            return ("Rechne.", "\(a) · \(b) =", "\(a * b)", "\(a * b + (Bool.random() ? a : -b))")
        }
    }
}
