import Foundation
import FoundationModels

// ============================================================
// MARK: - KI auf dem Gerät
// ============================================================
//
// Formuliert Texte mit Apples Sprachmodell direkt auf dem iPhone (Foundation Models).
// Es geht nichts ins Internet, es kostet nichts und funktioniert offline.
// Das Modell gibt es nur auf Geräten mit Apple Intelligence. Sonst, oder wenn
// die KI etwas Unpassendes schreibt, bleibt es beim festen Text aus dem Code.
//
// Wichtig: Die KI rechnet nichts und entscheidet nichts. Sie bekommt fertige,
// geprüfte Sätze und darf sie nur umformulieren. Jede Zahl in ihrer Antwort
// muss schon in den Fakten stehen, sonst wird die Antwort verworfen.

enum KIText {

    /// true, wenn das Sprachmodell auf diesem Gerät bereit ist und Deutsch kann.
    static var verfuegbar: Bool {
        let modell = SystemLanguageModel.default
        guard case .available = modell.availability else { return false }
        return modell.supportedLanguages.contains { $0.languageCode?.identifier == "de" }
    }

    /// Kurzer Grund für die Anzeige in der Eltern-Übersicht.
    static var statusText: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return verfuegbar ? "KI auf diesem Gerät aktiv" : "KI kann auf diesem Gerät noch kein Deutsch"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Apple Intelligence ist ausgeschaltet"
        case .unavailable(.modelNotReady):
            return "Die KI wird noch geladen"
        case .unavailable(.deviceNotEligible):
            return "Dieses Gerät hat keine Apple Intelligence"
        default:
            return "KI auf diesem Gerät nicht verfügbar"
        }
    }

    /// Lässt die KI einen fertigen Text umformulieren.
    /// - Parameters:
    ///   - anweisung: Rolle und Stil, zum Beispiel "für ein Kind der 3. Klasse"
    ///   - fakten: alle Fakten und der feste Text. Nur Zahlen daraus dürfen vorkommen.
    ///   - ersatz: der feste Text, falls die KI nicht kann oder nicht darf
    ///   - wartezeit: so lange wird höchstens gewartet
    /// - Returns: der KI-Text und ob er wirklich von der KI stammt
    static func formuliere(anweisung: String, fakten: String, ersatz: String,
                           maxZeichen: Int = 400,
                           wartezeit: Duration = .seconds(6)) async -> (text: String, vonKI: Bool) {
        guard verfuegbar else { return (ersatz, false) }
        let ergebnis = await mitZeitlimit(wartezeit) {
            let sitzung = LanguageModelSession(instructions: anweisung)
            let optionen = GenerationOptions(temperature: 0.4)
            let antwort = try await sitzung.respond(to: fakten, options: optionen)
            return antwort.content
        }
        guard let roh = ergebnis else { return (ersatz, false) }
        let text = bereinige(roh)
        guard istBrauchbar(text, fakten: fakten, maxZeichen: maxZeichen) else { return (ersatz, false) }
        return (text, true)
    }

    // MARK: Prüfen (ohne KI testbar)

    /// Die KI-Antwort wird nur benutzt, wenn sie kurz genug ist und keine neuen Zahlen erfindet.
    static func istBrauchbar(_ text: String, fakten: String, maxZeichen: Int) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard t.count >= 10, t.count <= maxZeichen else { return false }
        let erlaubt = Set(zahlen(in: fakten))
        return zahlen(in: t).allSatisfy { erlaubt.contains($0) }
    }

    /// Alle ganzen Zahlen in einem Text.
    static func zahlen(in text: String) -> [Int] {
        var liste: [Int] = []
        var aktuell = ""
        for ch in text {
            if ch.isASCII && ch.isNumber {
                aktuell.append(ch)
            } else {
                if let n = Int(aktuell) { liste.append(n) }
                aktuell = ""
            }
        }
        if let n = Int(aktuell) { liste.append(n) }
        return liste
    }

    /// Entfernt Gedankenstriche, Markdown und Anführungszeichen um den ganzen Text.
    static func bereinige(_ roh: String) -> String {
        var t = roh
        for strich in ["\u{2014}", "\u{2013}"] {
            t = t.replacingOccurrences(of: " \(strich) ", with: ", ")
            t = t.replacingOccurrences(of: strich, with: "-")
        }
        t = t.replacingOccurrences(of: "**", with: "")
        t = t.replacingOccurrences(of: "*", with: "·")
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        for (auf, zu) in [("\"", "\""), ("„", "“"), ("“", "”")] where t.hasPrefix(auf) && t.hasSuffix(zu) && t.count > 2 {
            t = String(t.dropFirst().dropLast())
        }
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Zeitlimit

    private static func mitZeitlimit(_ dauer: Duration,
                                     _ arbeit: @escaping @Sendable () async throws -> String) async -> String? {
        await withTaskGroup(of: String?.self) { gruppe in
            gruppe.addTask { try? await arbeit() }
            gruppe.addTask {
                try? await Task.sleep(for: dauer)
                return nil
            }
            let erstes = await gruppe.next() ?? nil
            gruppe.cancelAll()
            return erstes
        }
    }
}
