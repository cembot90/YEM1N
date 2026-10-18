import Foundation

// ============================================================
// MARK: - Vorlesetexte und Namen der Studio-Aufnahmen
// ============================================================
//
// Diese Datei braucht nur Foundation. Der Sammler unter stimmen/sammeln
// übersetzt sie unter Linux mit, damit die Namen der Aufnahmen in der App
// und beim Vertonen immer genau gleich gebildet werden.

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

    /// Name der Studio-Aufnahme ohne Endung, zum Beispiel "studio_de_9f2c...".
    /// FNV-1a mit 64 Bit über Sprache und gesprochenen Text. Das ist kein
    /// Schutz, nur ein kurzer, fester Name, der überall gleich herauskommt.
    nonisolated static func aufnahme(_ text: String, sprache code: String) -> String {
        let sp = sprache(code)
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for b in (sp + "|" + gesprochen(text)).utf8 {
            h ^= UInt64(b)
            h = h &* 0x0000_0100_0000_01b3
        }
        let hex = String(h, radix: 16)
        return "studio_" + sp + "_" + String(repeating: "0", count: 16 - hex.count) + hex
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
