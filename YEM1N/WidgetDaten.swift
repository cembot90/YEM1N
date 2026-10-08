import Foundation
import WidgetKit

// ============================================================
// MARK: - Brücke zum Sperrbildschirm-Widget
// Das Widget ist ein eigenes kleines Programm und kann die Daten der App nicht
// lesen. Die App legt deshalb einen kleinen Stand in die gemeinsame App Group.
// Er enthält nur Name, Bild und Stimmung des Haustiers und die Serie.
// Das bleibt auf dem Gerät und geht nicht in die Cloud.
// ============================================================

struct WidgetStand: Codable, Equatable {
    var vorhanden: Bool
    var emoji: String
    var hut: String
    var name: String
    var stufe: String
    /// Kurzer Satz, zum Beispiel "ist froh" oder "hat Hunger".
    var text: String
    /// Ab dann ist das Tier hungrig. Das Widget wechselt dann selbst den Text.
    var hungrigAb: Date?
    var serie: Int
    /// Bis dahin gilt die Serie noch. Danach blendet das Widget sie aus.
    var serieBis: Date?
    var erstellt: Date
}

enum WidgetBruecke {
    static let gruppe = "group.de.cemaras.yem1n"
    static let key = "widgetStand"
    static let serieKey = "widgetSerie"
    static let serieBisKey = "widgetSerieBis"

    static func kurztext(_ h: Haustier) -> String {
        if h.stufe == .ei { return "wartet aufs Schlüpfen" }
        switch h.stimmung {
        case .froh: return "ist froh"
        case .zufrieden: return "ist zufrieden"
        case .hungrig: return "hat Hunger"
        case .traurig: return "ist traurig"
        }
    }

    /// Die Serie lebt bis zum Ende des Tages nach der letzten Runde.
    static func serieBis(letzteRunde: Date?, kalender: Calendar = .current) -> Date? {
        guard let d = letzteRunde else { return nil }
        let tag = kalender.startOfDay(for: d)
        return kalender.date(byAdding: .day, value: 2, to: tag)
    }

    static func stand(haustier: Haustier?, serie: Int, serieBis: Date? = nil,
                      jetzt: Date = Date.now) -> WidgetStand {
        guard var h = haustier else {
            return WidgetStand(vorhanden: false, emoji: "🥚", hut: "", name: "", stufe: "",
                               text: "Such dir ein Haustier aus", hungrigAb: nil,
                               serie: serie, serieBis: serieBis, erstellt: jetzt)
        }
        h.aktualisiere(jetzt: jetzt)
        var hungrigAb: Date?
        if h.stufe != .ei && h.satt >= Haustier.hungrigGrenze {
            let stunden = (h.satt - Haustier.hungrigGrenze) / Haustier.sattProStunde
            hungrigAb = jetzt.addingTimeInterval(stunden * 3600)
        }
        return WidgetStand(vorhanden: true, emoji: h.emoji,
                           hut: HaustierHut.finde(h.hut)?.emoji ?? "",
                           name: h.name, stufe: h.stufe.name, text: kurztext(h),
                           hungrigAb: hungrigAb, serie: serie, serieBis: serieBis,
                           erstellt: jetzt)
    }

    /// Schreibt den aktuellen Stand in die App Group und lädt das Widget neu.
    /// `serie` und `letzteRunde` werden nur gemerkt, wenn sie angegeben sind.
    static func aktualisieren(serie: Int? = nil, letzteRunde: Date? = nil,
                              speicher: UserDefaults = .standard,
                              gemeinsam: UserDefaults? = UserDefaults(suiteName: WidgetBruecke.gruppe),
                              jetzt: Date = Date.now, neuLaden: Bool = true) {
        if let serie {
            speicher.set(serie, forKey: serieKey)
            if let bis = serieBis(letzteRunde: letzteRunde) {
                speicher.set(bis.timeIntervalSince1970, forKey: serieBisKey)
            } else {
                speicher.removeObject(forKey: serieBisKey)
            }
        }
        let bisZeit = speicher.object(forKey: serieBisKey) as? Double
        let s = stand(haustier: HaustierSpeicher.laden(speicher: speicher),
                      serie: speicher.integer(forKey: serieKey),
                      serieBis: bisZeit.map { Date(timeIntervalSince1970: $0) },
                      jetzt: jetzt)
        guard let gemeinsam, let daten = try? JSONEncoder().encode(s) else { return }
        gemeinsam.set(daten, forKey: key)
        if neuLaden { WidgetCenter.shared.reloadAllTimelines() }
    }
}
