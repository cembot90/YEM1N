import SwiftUI

// ============================================================
// MARK: - Hero-Design
// Gemeinsame Bausteine für das Aussehen der App: große Kopfkarten,
// Bereichskarten und Einstellungszeilen. Alles in den zwei Farben der
// gewählten Farbwelt (Blau und Gelb oder Rosa). Schriften sind groß und
// kräftig, damit Kinder sie gut lesen können.
// ============================================================

/// Feste Schriftgrößen, damit alle Seiten gleich aussehen.
enum Schrift {
    static let heroTitel = Font.system(size: 36, weight: .black, design: .rounded)
    static let heroUntertitel = Font.system(.headline, design: .rounded).weight(.semibold)
    static let kicker = Font.system(.footnote, design: .rounded).weight(.heavy)
    static let abschnitt = Font.system(.title3, design: .rounded).weight(.heavy)
    static let kartenTitel = Font.system(.title3, design: .rounded).weight(.heavy)
    static let kartenText = Font.system(.subheadline, design: .rounded).weight(.semibold)
    static let zeilenTitel = Font.system(.body, design: .rounded).weight(.bold)
    static let zeilenText = Font.system(.footnote, design: .rounded).weight(.medium)
}

/// Ein kleines Etikett in der Kopfkarte, zum Beispiel "🔥 5 Tage".
struct HeroChip: Identifiable {
    let text: String
    var hervorgehoben = false
    var id: String { text }
}

/// Große Kopfkarte oben auf einer Seite. Links Titel und Untertitel, rechts ein großes Bild,
/// darunter optional kleine Etiketten. Knöpfe kommen über `aktionen` oben rechts dazu.
struct HeroKopf<Aktionen: View>: View {
    let kicker: String
    let titel: String
    var untertitel: String = ""
    var bild: String = ""
    var chips: [HeroChip] = []
    @ViewBuilder var aktionen: () -> Aktionen

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(kicker.uppercased())
                    .font(Schrift.kicker)
                    .tracking(1.2)
                    .foregroundStyle(Theme.gelb)
                Spacer(minLength: 8)
                // borderless: Auch in einer Liste reagiert jeder Knopf für sich.
                aktionen()
                    .buttonStyle(.borderless)
            }
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(titel)
                        .font(Schrift.heroTitel)
                        .foregroundStyle(Color.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    if !untertitel.isEmpty {
                        Text(untertitel)
                            .font(Schrift.heroUntertitel)
                            .foregroundStyle(Color.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if !bild.isEmpty {
                    Text(bild)
                        .font(.system(size: 64))
                        .shadow(color: Theme.gelb.opacity(0.45), radius: 18)
                        .accessibilityHidden(true)
                }
            }
            if !chips.isEmpty {
                HStack(spacing: 8) {
                    ForEach(chips) { c in
                        Text(c.text)
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(c.hervorgehoben ? Theme.navy : Color.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(c.hervorgehoben ? Theme.gelb : Color.white.opacity(0.16),
                                        in: Capsule())
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { HeroFlaeche(radius: 30) }
    }
}

extension HeroKopf where Aktionen == EmptyView {
    init(kicker: String, titel: String, untertitel: String = "", bild: String = "",
         chips: [HeroChip] = []) {
        self.kicker = kicker
        self.titel = titel
        self.untertitel = untertitel
        self.bild = bild
        self.chips = chips
        self.aktionen = { EmptyView() }
    }
}

/// Der farbige Untergrund der Kopfkarte: Verlauf mit zwei weichen Lichtkreisen.
/// Bewusst ohne Weichzeichner, damit es auch auf älteren iPhones flüssig bleibt.
struct HeroFlaeche: View {
    var radius: CGFloat = 30

    var body: some View {
        let form = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            LinearGradient(colors: [Theme.glanz, Theme.navy],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(colors: [Theme.gelb.opacity(0.38), .clear],
                           center: UnitPoint(x: 0.95, y: 0.05), startRadius: 0, endRadius: 190)
            RadialGradient(colors: [Theme.himmel.opacity(0.22), .clear],
                           center: UnitPoint(x: 0.0, y: 1.0), startRadius: 0, endRadius: 220)
        }
        .clipShape(form)
        .overlay(form.stroke(LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                            startPoint: .top, endPoint: .bottom), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.25), radius: 16, y: 8)
    }
}

/// Große antippbare Karte für einen Bereich, zum Beispiel "Schule" oder "Sprachen".
struct BereichsKarte: View {
    let bild: String
    let titel: String
    var text: String = ""
    var fortschritt: Double? = nil
    /// Gelb gefüllt für das Wichtigste auf der Seite, sonst dunkel.
    var betont = false

    var body: some View {
        HStack(spacing: 16) {
            Text(bild)
                .font(.system(size: 40))
                .frame(width: 64, height: 64)
                .background((betont ? Theme.navy : Color.white).opacity(betont ? 0.14 : 0.10),
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(titel)
                    .font(Schrift.kartenTitel)
                    .foregroundStyle(betont ? Theme.navy : Color.white)
                if !text.isEmpty {
                    Text(text)
                        .font(Schrift.kartenText)
                        .foregroundStyle(betont ? Theme.navy.opacity(0.75) : Theme.textSanft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let f = fortschritt {
                    FortschrittsBalken(wert: f, hell: betont)
                        .padding(.top, 2)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(betont ? Theme.navy : Theme.gelb)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            if betont {
                RoundedRectangle(cornerRadius: 26, style: .continuous).fill(Theme.gelb)
                    .shadow(color: Theme.gelb.opacity(0.35), radius: 14, y: 6)
            } else {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.09))
                    .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

/// Schmaler Balken für Fortschritt, von 0 bis 1.
struct FortschrittsBalken: View {
    let wert: Double
    var hell = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill((hell ? Theme.navy : Color.white).opacity(0.18))
                Capsule().fill(hell ? Theme.navy : Theme.gelb)
                    .frame(width: geo.size.width * min(max(wert, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

/// Überschrift über einer Gruppe von Karten.
struct AbschnittsTitel: View {
    let titel: String
    var text: String = ""

    init(_ titel: String, text: String = "") {
        self.titel = titel
        self.text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
                .font(Schrift.abschnitt)
                .foregroundStyle(Theme.gelb)
            if !text.isEmpty {
                Text(text)
                    .font(Schrift.zeilenText)
                    .foregroundStyle(Theme.textSanft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

/// Runder Knopf mit Symbol, zum Beispiel für die Kopfkarte.
struct RundSymbol: View {
    let symbol: String
    var betont = false

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(betont ? Theme.navy : Color.white)
            .frame(width: 46, height: 46)
            .background(betont ? Theme.gelb : Color.white.opacity(0.16), in: Circle())
            .contentShape(Circle())
    }
}

/// Eine Zeile in den Einstellungen: farbiges Symbol, Titel, kurze Erklärung, Pfeil.
struct EinstellungsZeile: View {
    let symbol: String
    let titel: String
    var text: String = ""
    var farbe: Color = Theme.gelb
    var pfeil = true

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: 42, height: 42)
                .background(farbe, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(titel)
                    .font(Schrift.zeilenTitel)
                    .foregroundStyle(Color.white)
                if !text.isEmpty {
                    Text(text)
                        .font(Schrift.zeilenText)
                        .foregroundStyle(Theme.textSanft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
            if pfeil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

/// Weiße Gruppe für mehrere Einstellungszeilen, mit feinen Trennlinien.
struct ZeilenGruppe<Inhalt: View>: View {
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        VStack(spacing: 0) {
            inhalt()
        }
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
}

/// Trennlinie zwischen zwei Zeilen einer ZeilenGruppe.
struct ZeilenTrenner: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.10))
            .frame(height: 1)
            .padding(.leading, 70)
    }
}

/// Einheitlicher Seitenrahmen: Hintergrund, Scrollbereich und Abstand.
struct HeroSeite<Inhalt: View>: View {
    var abstand: CGFloat = 16
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: abstand) {
                    inhalt()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// Für Bereiche, die als Vollbild geöffnet werden: schmale Leiste oben mit "Fertig".
struct VollbildRahmen<Inhalt: View>: View {
    let titel: String
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        // Leiste und Inhalt untereinander, nicht übereinander. So schiebt sich der
        // Inhalt nicht unter die Leiste, auch wenn er einen eigenen Navigationsrahmen hat.
        VStack(spacing: 0) {
            HStack {
                Text(titel)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Spacer()
                Button { dismiss() } label: {
                    Text("Fertig")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Theme.tiefNavy.ignoresSafeArea(edges: .top))
            inhalt()
                .clipped()
        }
        .preferredColorScheme(.dark)
        .tint(Theme.gelb)
    }
}
