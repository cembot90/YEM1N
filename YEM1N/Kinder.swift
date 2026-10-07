import Foundation

// ============================================================
// MARK: - Kinder in der Familie
// Die Eltern sehen, welche Kinder Ergebnisse geschickt haben und wann
// zuletzt. Alte oder doppelte Einträge lassen sich entfernen.
// ============================================================

struct KindEintrag: Identifiable, Equatable {
    let name: String
    let runden: Int
    let zuletzt: Date
    var id: String { Kinder.schluessel(name) }
}

enum Kinder {
    private static let entferntKey = "kinderEntfernt"

    /// Namen gelten als gleich, auch wenn ein Leerzeichen, Groß und Klein
    /// oder ein Akzent anders ist. "Yemin" und "Yemin " sind dasselbe Kind.
    static func schluessel(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    static func gleich(_ a: String, _ b: String) -> Bool {
        schluessel(a) == schluessel(b)
    }

    /// Fasst alle Ergebnisse zu einer Liste von Kindern zusammen.
    /// Angezeigt wird die Schreibweise der neuesten Runde.
    static func liste(aus eintraege: [(name: String, zeitpunkt: Date)]) -> [KindEintrag] {
        struct Sammler { var anzeige: String; var runden: Int; var zuletzt: Date }
        var sammlung: [String: Sammler] = [:]
        for e in eintraege {
            let sauber = e.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sauber.isEmpty else { continue }
            let k = schluessel(sauber)
            if var s = sammlung[k] {
                s.runden += 1
                if e.zeitpunkt > s.zuletzt {
                    s.zuletzt = e.zeitpunkt
                    s.anzeige = sauber
                }
                sammlung[k] = s
            } else {
                sammlung[k] = Sammler(anzeige: sauber, runden: 1, zuletzt: e.zeitpunkt)
            }
        }
        return sammlung.values
            .map { KindEintrag(name: $0.anzeige, runden: $0.runden, zuletzt: $0.zuletzt) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // MARK: Entfernen
    // Die Cloud gehört dem Kind-Gerät, die Eltern können dort nichts löschen.
    // Beim Entfernen merkt sich das Eltern-Gerät deshalb den Zeitpunkt. Alles bis
    // dahin wird nicht mehr angezeigt oder geholt. Spielt das Kind später weiter,
    // erscheint es mit den neuen Runden wieder.

    static func entfernen(_ name: String, am jetzt: Date = Date.now,
                          speicher: UserDefaults = .standard) {
        var d = (speicher.dictionary(forKey: entferntKey) as? [String: Double]) ?? [:]
        d[schluessel(name)] = jetzt.timeIntervalSince1970
        speicher.set(d, forKey: entferntKey)
    }

    static func istEntfernt(_ name: String, zeitpunkt: Date,
                            speicher: UserDefaults = .standard) -> Bool {
        let d = (speicher.dictionary(forKey: entferntKey) as? [String: Double]) ?? [:]
        guard let grenze = d[schluessel(name)] else { return false }
        return zeitpunkt.timeIntervalSince1970 <= grenze
    }

    // MARK: Text

    static func tageSeit(_ datum: Date, jetzt: Date = Date.now,
                         kalender: Calendar = .current) -> Int {
        let a = kalender.startOfDay(for: datum)
        let b = kalender.startOfDay(for: jetzt)
        return max(kalender.dateComponents([.day], from: a, to: b).day ?? 0, 0)
    }

    static func zuletztText(_ datum: Date, jetzt: Date = Date.now,
                            kalender: Calendar = .current) -> String {
        let tage = tageSeit(datum, jetzt: jetzt, kalender: kalender)
        switch tage {
        case 0: return "heute"
        case 1: return "gestern"
        case 2..<14: return "vor \(tage) Tagen"
        case 14..<60: return "vor \(tage / 7) Wochen"
        default: return "vor \(tage / 30) Monaten"
        }
    }

    /// Wer lange nichts mehr gemacht hat, wird in der Liste markiert.
    static let langeInaktivTage = 30
}
