import Foundation

// ============================================================
// MARK: - Vorlesetexte
// ============================================================
//
// Diese Datei braucht nur Foundation, damit pruefen/linux-tests.sh sie
// unter Linux mitprüfen kann.

/// Wie ein Satz klingen soll. Nur die Gerätestimme Thorsten kann das unterscheiden,
/// alle anderen Stimmen sprechen immer normal.
nonisolated enum SprechStimmung: Sendable {
    case normal, froh, leise
}

enum VorleseText {
    /// Der Text so, wie er gesprochen wird: ohne Bilder und Emojis,
    /// ohne doppelte Leerzeichen und Zeilenumbrüche.
    nonisolated static func gesprochen(_ text: String) -> String {
        let ohne = text.precomposedStringWithCanonicalMapping.unicodeScalars.filter { s in
            let bild = s.properties.isEmoji && s.value > 0x7F
            return !bild && s.value != 0xFE0F && s.value != 0x200D
        }
        let roh = String(String.UnicodeScalarView(ohne))
        return roh.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Sprache aus einem Code wie "de-DE": "de"
    nonisolated static func sprache(_ code: String) -> String {
        String(code.prefix(2)).lowercased()
    }

    /// Was beim Antippen des Lautsprechers in einer Übung gesprochen wird:
    /// Frage und Rechnung, die Zeichen als Wörter.
    nonisolated static func aufgabe(frage: String, rechnung: String) -> String {
        var t = frage + ". " + rechnung
        let tausch: [(String, String)] = [
            ("\n", ". "), (" · ", " mal "), (" : ", " geteilt durch "),
            (" - ", " minus "), (" + ", " plus "), ("=", " gleich "),
            (" ? ", " und "), ("<", " kleiner "), (">", " größer ")
        ]
        for (alt, neu) in tausch { t = t.replacingOccurrences(of: alt, with: neu) }
        return t
    }
}
