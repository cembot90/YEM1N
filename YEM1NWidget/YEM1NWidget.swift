import WidgetKit
import SwiftUI

// ============================================================
// MARK: - Haustier-Widget für den Sperrbildschirm
// Das Widget liest nur den kleinen Stand, den die App in die gemeinsame
// App Group legt. Es rechnet nichts selbst aus und sendet nichts.
// ============================================================

/// Gleiche Felder wie `WidgetStand` in der App. Das Widget kann den Code der
/// App nicht sehen, deshalb steht die Form hier noch einmal.
struct WidgetStand: Codable, Equatable {
    var vorhanden: Bool
    var emoji: String
    var hut: String
    var name: String
    var stufe: String
    var text: String
    var hungrigAb: Date?
    var serie: Int
    var serieBis: Date?
    var erstellt: Date

    static let leer = WidgetStand(vorhanden: false, emoji: "🥚", hut: "", name: "",
                                  stufe: "", text: "Öffne die App", hungrigAb: nil,
                                  serie: 0, serieBis: nil, erstellt: .now)

    static let beispiel = WidgetStand(vorhanden: true, emoji: "🐱", hut: "🎩", name: "Pip",
                                      stufe: "Kind", text: "ist froh",
                                      hungrigAb: nil, serie: 5, serieBis: nil, erstellt: .now)

    static func laden() -> WidgetStand {
        guard let daten = UserDefaults(suiteName: "group.de.cemaras.yem1n")?.data(forKey: "widgetStand"),
              let stand = try? JSONDecoder().decode(WidgetStand.self, from: daten)
        else { return .leer }
        return stand
    }
}

struct HaustierEintrag: TimelineEntry {
    let date: Date
    let stand: WidgetStand

    /// Ab dem Zeitpunkt `hungrigAb` wechselt der Text von selbst.
    var text: String {
        if stand.vorhanden, let ab = stand.hungrigAb, date >= ab { return "hat Hunger" }
        return stand.text
    }

    /// Die Serie verschwindet, wenn sie nicht mehr gilt.
    var serie: Int? {
        guard stand.serie > 0 else { return nil }
        if let bis = stand.serieBis, date >= bis { return nil }
        return stand.serie
    }

    var name: String { stand.vorhanden ? stand.name : "YEM1N" }
}

struct HaustierProvider: TimelineProvider {
    func placeholder(in context: Context) -> HaustierEintrag {
        HaustierEintrag(date: .now, stand: .beispiel)
    }

    func getSnapshot(in context: Context, completion: @escaping (HaustierEintrag) -> Void) {
        completion(HaustierEintrag(date: .now, stand: context.isPreview ? .beispiel : .laden()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HaustierEintrag>) -> Void) {
        let stand = WidgetStand.laden()
        let jetzt = Date.now
        var zeiten = [jetzt]
        for z in [stand.hungrigAb, stand.serieBis] {
            if let z, z > jetzt { zeiten.append(z) }
        }
        let eintraege = zeiten.sorted().map { HaustierEintrag(date: $0, stand: stand) }
        // Spätestens nach 3 Stunden noch einmal nachsehen.
        let naechste = jetzt.addingTimeInterval(3 * 3600)
        completion(Timeline(entries: eintraege, policy: .after(naechste)))
    }
}

struct HaustierWidgetAnsicht: View {
    @Environment(\.widgetFamily) private var familie
    let eintrag: HaustierEintrag

    private var tier: String { eintrag.stand.emoji }

    var body: some View {
        switch familie {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text(tier).font(.title2)
                    if let s = eintrag.serie {
                        Text("🔥\(s)").font(.caption2.weight(.bold))
                    }
                }
            }
        case .accessoryInline:
            if let s = eintrag.serie {
                Text("\(tier) \(eintrag.name) \(eintrag.text) · 🔥 \(s)")
            } else {
                Text("\(tier) \(eintrag.name) \(eintrag.text)")
            }
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Text(tier).font(.largeTitle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(eintrag.name).font(.headline).lineLimit(1)
                    Text(eintrag.text).font(.caption).lineLimit(1)
                    if let s = eintrag.serie {
                        Text("🔥 \(s) Tage in Folge").font(.caption2)
                    }
                }
                Spacer(minLength: 0)
            }
        default:
            VStack(spacing: 4) {
                Text(tier).font(.system(size: 52))
                Text(eintrag.name)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .lineLimit(1)
                Text(eintrag.text).font(.caption).lineLimit(1)
                if let s = eintrag.serie {
                    Text("🔥 \(s)").font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(.white)
        }
    }
}

struct YEM1NWidget: Widget {
    let kind: String = "YEM1NWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HaustierProvider()) { eintrag in
            HaustierWidgetAnsicht(eintrag: eintrag)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(red: 0.0, green: 0.125, blue: 0.357),
                                            Color(red: 0.0, green: 0.045, blue: 0.16)],
                                   startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Haustier")
        .description("Dein Haustier und deine Serie, auch auf dem Sperrbildschirm.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular,
                            .accessoryInline, .systemSmall])
    }
}

#Preview("Sperrbildschirm", as: .accessoryRectangular) {
    YEM1NWidget()
} timeline: {
    HaustierEintrag(date: .now, stand: .beispiel)
}

#Preview("Home", as: .systemSmall) {
    YEM1NWidget()
} timeline: {
    HaustierEintrag(date: .now, stand: .beispiel)
}
