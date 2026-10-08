import Foundation

// ============================================================
// MARK: - Fehlerplan: Fehler kommen nach ein paar Tagen wieder
// Wer einen Fehler einmal richtig wiederholt, hat ihn noch nicht sicher.
// Er kommt nach 3 Tagen noch einmal. Erst die zweite richtige Antwort
// macht ihn zu einem gemeisterten Fehler. Eine falsche Antwort stellt den
// Fehler auf Anfang, er kommt dann schon morgen wieder.
// Der Plan liegt nur auf dem Gerät. Die Aufgaben selbst bleiben unverändert.
// ============================================================

enum Fehlerplan {
    static let faelligKey = "fehlerFaellig"
    static let stufeKey = "fehlerStufe"

    /// So oft muss ein Fehler richtig wiederholt werden.
    static let noetig = 2
    /// Tage bis zur nächsten Wiederholung nach einer richtigen Antwort.
    static let abstandNachRichtig = [3, 7]
    /// Tage bis zur nächsten Wiederholung nach einer falschen Antwort.
    static let abstandNachFehler = 1

    // MARK: Lesen

    private static func faelligkeiten(_ speicher: UserDefaults) -> [String: Double] {
        (speicher.dictionary(forKey: faelligKey) as? [String: Double]) ?? [:]
    }

    private static func stufen(_ speicher: UserDefaults) -> [String: Int] {
        (speicher.dictionary(forKey: stufeKey) as? [String: Int]) ?? [:]
    }

    /// Ohne Eintrag ist ein Fehler sofort dran.
    static func faelligAb(_ schluessel: String, speicher: UserDefaults = .standard) -> Date? {
        guard let t = faelligkeiten(speicher)[schluessel] else { return nil }
        return Date(timeIntervalSince1970: t)
    }

    /// Die ganze Tabelle auf einmal. Wer viele Fehler prüft, liest sie nur einmal
    /// und fragt dann mit `istFaellig(_:in:jetzt:)`, statt sie bei jeder Aufgabe neu zu laden.
    static func tabelle(speicher: UserDefaults = .standard) -> [String: Double] {
        faelligkeiten(speicher)
    }

    static func istFaellig(_ schluessel: String, in tabelle: [String: Double],
                           jetzt: Date = Date.now) -> Bool {
        guard let t = tabelle[schluessel] else { return true }
        return Date(timeIntervalSince1970: t) <= jetzt
    }

    static func istFaellig(_ schluessel: String, jetzt: Date = Date.now,
                           speicher: UserDefaults = .standard) -> Bool {
        guard let ab = faelligAb(schluessel, speicher: speicher) else { return true }
        return ab <= jetzt
    }

    // MARK: Antworten merken

    private static func tag(in tagen: Int, ab jetzt: Date, kalender: Calendar) -> Date {
        let spaeter = kalender.date(byAdding: .day, value: tagen, to: jetzt)
            ?? jetzt.addingTimeInterval(Double(tagen) * 86400)
        return kalender.startOfDay(for: spaeter)
    }

    /// true, wenn der Fehler damit gemeistert ist.
    @discardableResult
    static func richtig(_ schluessel: String, jetzt: Date = Date.now,
                        speicher: UserDefaults = .standard,
                        kalender: Calendar = .current) -> Bool {
        var faellig = faelligkeiten(speicher)
        var stufe = stufen(speicher)
        let neu = (stufe[schluessel] ?? 0) + 1
        if neu >= noetig {
            faellig[schluessel] = nil
            stufe[schluessel] = nil
            speicher.set(faellig, forKey: faelligKey)
            speicher.set(stufe, forKey: stufeKey)
            return true
        }
        let index = min(neu - 1, abstandNachRichtig.count - 1)
        stufe[schluessel] = neu
        faellig[schluessel] = tag(in: abstandNachRichtig[index], ab: jetzt, kalender: kalender)
            .timeIntervalSince1970
        speicher.set(faellig, forKey: faelligKey)
        speicher.set(stufe, forKey: stufeKey)
        return false
    }

    static func falsch(_ schluessel: String, jetzt: Date = Date.now,
                       speicher: UserDefaults = .standard,
                       kalender: Calendar = .current) {
        var faellig = faelligkeiten(speicher)
        var stufe = stufen(speicher)
        stufe[schluessel] = 0
        faellig[schluessel] = tag(in: abstandNachFehler, ab: jetzt, kalender: kalender)
            .timeIntervalSince1970
        speicher.set(faellig, forKey: faelligKey)
        speicher.set(stufe, forKey: stufeKey)
    }
}
