import Foundation

// ============================================================
// MARK: - Eltern-PIN
// ============================================================
//
// Die PIN schützt den Bereich der Eltern (Familie, Geräte erlauben, Ergebnisse, Joker beantworten),
// damit ein Kind ihn nicht aus Versehen oder aus Neugier öffnet. Sie ist eine Sperre für Kinder, kein Tresor:
// Die Daten der Familie schützt der Schlüssel des Geräts, nicht die PIN.
// Reine Logik, gleiche Rechnung wie auf Android (logik/ElternPin.kt).

nonisolated enum ElternPin {
    static let minLaenge = 4
    static let maxLaenge = 8

    /// So lange bleibt der Bereich nach der richtigen PIN offen, in Sekunden.
    static let offenSekunden: TimeInterval = 5 * 60

    private static let runden = 5000

    /// Nur Ziffern, 4 bis 8 Stück.
    static func gueltig(_ pin: String) -> Bool {
        (minLaenge...maxLaenge).contains(pin.count) && pin.allSatisfy { ("0"..."9").contains($0) }
    }

    /// Einfache Folgen und Wiederholungen sind zu leicht zu erraten (1234, 0000, 4321).
    static func zuLeicht(_ pin: String) -> Bool {
        let z = Array(pin.utf8)
        if z.count < minLaenge { return true }
        if z.allSatisfy({ $0 == z[0] }) { return true }
        let schritte = (1..<z.count).map { Int(z[$0]) - Int(z[$0 - 1]) }
        return schritte.allSatisfy { $0 == 1 } || schritte.allSatisfy { $0 == -1 }
    }

    /// Einmal pro PIN, damit gleiche PINs auf verschiedenen Geräten verschiedene Werte ergeben. [zufall] sind 16 Zufallsbytes.
    static func salz(_ zufall: [UInt8]) -> String { Sha256.hex(zufall) }

    static func hash(_ pin: String, salz: String) -> String {
        let salzBytes = Array(salz.utf8)
        var h = Sha256.hash(Array((salz + ":" + pin).utf8))
        for _ in 0..<runden {
            h = Sha256.hash(h + salzBytes)
        }
        return Sha256.hex(h)
    }

    static func stimmt(_ pin: String, salz: String, hash gespeichert: String) -> Bool {
        if salz.isEmpty || gespeichert.isEmpty { return false }
        let a = Array(hash(pin, salz: salz).utf8)
        let b = Array(gespeichert.utf8)
        // Gleich lange Prüfung, damit die Dauer nichts verrät.
        var unterschied = UInt8(a.count == b.count ? 0 : 1)
        for i in 0..<min(a.count, b.count) { unterschied |= a[i] ^ b[i] }
        return unterschied == 0
    }

    /// Wartezeit in Sekunden nach so vielen falschen Eingaben in Folge. Die ersten zwei sind frei.
    static func sperreSekunden(_ fehlversuche: Int) -> TimeInterval {
        switch fehlversuche {
        case ..<3: return 0
        case 3: return 30
        case 4: return 60
        case 5: return 5 * 60
        default: return 15 * 60
        }
    }

    /// Freundlicher Text für die Wartezeit.
    static func sperreText(_ sekunden: TimeInterval) -> String {
        let s = max(Int(sekunden.rounded(.up)), 1)
        if s == 1 { return "Bitte noch 1 Sekunde warten." }
        if s < 90 { return "Bitte noch \(s) Sekunden warten." }
        return "Bitte noch \((s + 59) / 60) Minuten warten."
    }
}
