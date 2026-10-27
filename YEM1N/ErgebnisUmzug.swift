import Foundation

/// Beim Wechsel auf eine neue Familie (zum Beispiel nach der Umstellung auf den Familien-Dienst, Protokoll 2)
/// schickt das Kind-Gerät seine bisherigen Runden noch einmal an die neue Familie.
/// So behalten die Eltern ihre Übersicht und den Wochenbericht. Auf dem Kind-Gerät selbst ändert sich nichts,
/// Sterne, Münzen und Runden liegen dort und werden nie gelöscht.
/// Doppelt gesendet schadet nicht: Jeder Eintrag hat eine feste Kennung, der Dienst nimmt ihn nur einmal an.
nonisolated enum ErgebnisUmzug {
    static let schluessel = "ergebnisseNeuGesendetAn"
    /// So lange hält der Dienst Ergebnisse. Ältere schicken wir nicht mehr hoch.
    static let tage = 365
    /// Pause zwischen zwei Einträgen bei vielen Runden, damit die Bremse des Dienstes (120 Anfragen pro Minute) nicht anschlägt.
    static let pauseMillisekunden = 700
    static let ab = 50

    /// true, solange für diese Familie noch nicht neu gesendet wurde.
    static func faellig(familie: String, speicher: UserDefaults = .standard) -> Bool {
        !familie.isEmpty && speicher.string(forKey: schluessel) != familie
    }

    static func erledigt(familie: String, speicher: UserDefaults = .standard) {
        speicher.set(familie, forKey: schluessel)
    }

    /// Ältere Runden als diese Grenze werden nicht mehr gesendet.
    static func grenze(jetzt: Date = .now) -> Date {
        jetzt.addingTimeInterval(-Double(tage) * 86_400)
    }

    /// Bei vielen offenen Runden kurz warten, bei wenigen gar nicht.
    static func pause(bei anzahl: Int) -> Duration? {
        anzahl > ab ? .milliseconds(pauseMillisekunden) : nil
    }
}
