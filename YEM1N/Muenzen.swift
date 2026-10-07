import SwiftUI
import Foundation

// ============================================================
// MARK: - Münzen: verdienen durch Üben, ausgeben für Spiele
// ============================================================

enum Muenzen {
    /// Für jede Aufgabe, die gleich richtig war.
    static let proRichtig = 1
    /// Zusatz für eine starke Runde, aber nur ohne angeschaute Lösungen.
    static let bonusZweiSterne = 2
    static let bonusDreiSterne = 5
    /// Was eine Spielrunde kostet.
    static let preisProSpiel = 15

    private static let standKey = "muenzen"
    private static let spielDatumKey = "spieleDatum"
    private static let spielAnzahlKey = "spieleHeute"
    private static let rundeDatumKey = "rundeDatum"

    // MARK: Verdienen

    /// Angeschaute Lösungen zählen nicht als richtig, Spicken bringt also nichts.
    static func verdient(richtig: Int, gesamt: Int, angesehen: Int) -> Int {
        guard richtig > 0, gesamt > 0 else { return 0 }
        var summe = richtig * proRichtig
        if angesehen == 0 {
            let sterne = sterneFuer(gut: richtig, gesamt: gesamt)
            if sterne >= 3 {
                summe += bonusDreiSterne
            } else if sterne == 2 {
                summe += bonusZweiSterne
            }
        }
        return summe
    }

    // MARK: Konto

    static var stand: Int {
        UserDefaults.standard.integer(forKey: standKey)
    }

    static func gutschreiben(_ anzahl: Int) {
        guard anzahl > 0 else { return }
        UserDefaults.standard.set(stand + anzahl, forKey: standKey)
    }

    @discardableResult
    static func bezahlen(_ anzahl: Int) -> Bool {
        guard anzahl > 0, stand >= anzahl else { return false }
        UserDefaults.standard.set(stand - anzahl, forKey: standKey)
        return true
    }

    // MARK: Tag

    private static var heute: String {
        let t = Calendar.current.dateComponents([.year, .month, .day], from: Date.now)
        return "\(t.year ?? 0)-\(t.month ?? 0)-\(t.day ?? 0)"
    }

    /// Wird nach jeder fertigen Übungsrunde gesetzt.
    static func rundeGeschafft() {
        UserDefaults.standard.set(heute, forKey: rundeDatumKey)
    }

    static var heuteSchonGeuebt: Bool {
        UserDefaults.standard.string(forKey: rundeDatumKey) == heute
    }

    static var spieleHeute: Int {
        let speicher = UserDefaults.standard
        guard speicher.string(forKey: spielDatumKey) == heute else { return 0 }
        return speicher.integer(forKey: spielAnzahlKey)
    }

    static func spielGestartet() {
        let speicher = UserDefaults.standard
        let neu = spieleHeute + 1
        speicher.set(heute, forKey: spielDatumKey)
        speicher.set(neu, forKey: spielAnzahlKey)
    }

    // MARK: Bestenliste

    static func bestwert(_ spiel: String) -> Int {
        UserDefaults.standard.integer(forKey: "bestwert-" + spiel)
    }

    /// true, wenn es ein neuer Rekord war.
    static func merkeBestwert(_ spiel: String, _ punkte: Int) -> Bool {
        guard punkte > bestwert(spiel) else { return false }
        UserDefaults.standard.set(punkte, forKey: "bestwert-" + spiel)
        return true
    }
}

// ============================================================
// MARK: - Die Spiele
// ============================================================

enum SpielArt: String, CaseIterable, Identifiable {
    case lauf, jagd, hockey

    var id: String { rawValue }

    /// Unter diesem Namen wird der Bestwert gespeichert.
    var schluessel: String { rawValue }

    var titel: String {
        switch self {
        case .lauf: return "Zahlenlauf"
        case .jagd: return "Münzjagd"
        case .hockey: return "Münz-Hockey"
        }
    }

    var beschreibung: String {
        switch self {
        case .lauf: return "Spring über die Kakteen und sammle Münzen. Es wird immer schneller."
        case .jagd: return "Sammle auf den Plattformen alle Münzen ein. Weich den Fliegern aus."
        case .hockey: return "Tischhockey gegen den Computer. Wer zuerst fünf Tore hat, gewinnt."
        }
    }

    var bild: String {
        switch self {
        case .lauf: return "held_lauf1"
        case .jagd: return "held_sprung"
        case .hockey: return "muenze"
        }
    }

    @ViewBuilder
    var ansicht: some View {
        switch self {
        case .lauf: SpielLaufView()
        case .jagd: SpielJagdView()
        case .hockey: SpielHockeyView()
        }
    }
}

// ============================================================
// MARK: - Spieleübersicht
// ============================================================

struct SpieleView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("muenzen") private var muenzen = 0
    @AppStorage("spieleErlaubt") private var erlaubt = true
    @AppStorage("spieleProTag") private var proTag = 3
    @AppStorage("kindName") private var kindName = ""
    @AppStorage("modus") private var modus = ""
    @State private var aktiv: SpielArt?
    @State private var gespieltHeute = Muenzen.spieleHeute
    @State private var bestwerte: [String: Int] = SpieleView.leseBestwerte()

    private static func leseBestwerte() -> [String: Int] {
        var d: [String: Int] = [:]
        for art in SpielArt.allCases { d[art.schluessel] = Muenzen.bestwert(art.schluessel) }
        return d
    }

    private func starte(_ art: SpielArt) {
        guard sperre == nil else { return }
        if testModus {
            aktiv = art
        } else if Muenzen.bezahlen(Muenzen.preisProSpiel) {
            Muenzen.spielGestartet()
            muenzen = Muenzen.stand
            gespieltHeute = Muenzen.spieleHeute
            aktiv = art
        }
    }

    /// Auf dem Eltern-Gerät darf ohne Münzen gespielt werden, zum Ausprobieren.
    private var testModus: Bool { modus == "eltern" }

    /// Grund, warum gerade nicht gespielt werden kann, sonst nil.
    private var sperre: String? {
        if testModus { return nil }
        if !erlaubt {
            return "Die Spiele sind in den Einstellungen ausgeschaltet. Frag deine Eltern."
        }
        if !Muenzen.heuteSchonGeuebt {
            return "Erst eine Übung schaffen, dann darfst du spielen."
        }
        if gespieltHeute >= proTag {
            return "Für heute ist Schluss. Du hast schon \(gespieltHeute) von \(proTag) Spielen gemacht."
        }
        if muenzen < Muenzen.preisProSpiel {
            return "Du brauchst \(Muenzen.preisProSpiel) Münzen. Du hast \(muenzen). Übe weiter, dann klappt es."
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 16) {
                        kontoKarte
                        ForEach(SpielArt.allCases) { art in
                            spielKarte(art)
                        }
                        if let grund = sperre {
                            Text(grund)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.gelb)
                                .multilineTextAlignment(.center)
                                .padding(16)
                                .frame(maxWidth: .infinity)
                                .glasKarte(radius: 22)
                        }
                        if !testModus { verdienstKarte }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Spiele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .fullScreenCover(item: $aktiv, onDismiss: {
                gespieltHeute = Muenzen.spieleHeute
                bestwerte = SpieleView.leseBestwerte()
                muenzen = Muenzen.stand
            }) { art in
                art.ansicht
            }
        }
    }

    private var knopfText: String {
        if testModus { return "Ausprobieren, kostet nichts" }
        return sperre == nil ? "Spielen für \(Muenzen.preisProSpiel) Münzen" : "Noch nicht möglich"
    }

    @ViewBuilder
    private var kontoKarte: some View {
        if testModus { elternKarte } else { kindKonto }
    }

    private var elternKarte: some View {
        HStack(spacing: 16) {
            Image(systemName: "eye.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Theme.navy)
                .frame(width: 48, height: 48)
                .background(Theme.gelb, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Zum Ausprobieren")
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Text("Auf dem Eltern-Gerät kostet das Spiel keine Münzen und zählt nicht gegen das Tageslimit. So siehst du, was dein Kind bekommt.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private var kindKonto: some View {
        HStack(spacing: 16) {
            Image("muenze")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(muenzen) Münzen")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                    .contentTransition(.numericText())
                Text("Heute gespielt: \(gespieltHeute) von \(proTag)")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func spielKarte(_ art: SpielArt) -> some View {
        let bestwert = bestwerte[art.schluessel] ?? 0
        return VStack(spacing: 12) {
            Image(art.bild)
                .resizable()
                .scaledToFit()
                .frame(height: 76)
            Text(art.titel)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text(art.beschreibung)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSanft)
            if bestwert > 0 {
                Label("Bestwert: \(bestwert)", systemImage: "crown.fill")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.gelb)
            }
            Button {
                starte(art)
            } label: {
                Text(knopfText)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
            .disabled(sperre != nil)
            .opacity(sperre == nil ? 1 : 0.4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glasKarte(radius: 30)
    }

    private var verdienstKarte: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("So verdienst du Münzen")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            zeile("Eine Münze für jede Aufgabe, die gleich richtig ist.")
            zeile("\(Muenzen.bonusDreiSterne) Münzen extra für drei Sterne, \(Muenzen.bonusZweiSterne) für zwei Sterne.")
            zeile("Für angeschaute Lösungen gibt es nichts. Selbst denken lohnt sich.")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 26)
    }

    private func zeile(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").foregroundStyle(Theme.gelb)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.white)
        }
    }
}
