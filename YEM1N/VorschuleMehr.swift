import SwiftUI
import SwiftData
import Foundation

// ============================================================
// MARK: - Vorschule: fit für die Schule
// ============================================================
//
// Die Bildungspläne für Kinder bis 10 Jahre (Hessen und Bayern: Bildungs- und Erziehungsplan,
// NRW: Bildungsgrundsätze) nennen für den Übergang in die Schule vor allem:
//   Mengen auf einen Blick erfassen und vergleichen, die Zahlwortreihe, einfache Rechengeschichten,
//   Laute wahrnehmen (Reime, Silben, Anlaute), Lagebegriffe wie links und rechts,
//   Gefühle erkennen, Reihenfolgen verstehen, genau hinschauen, sicher im Straßenverkehr.
// Jede Frage hier hat eine deutsche und, wo es Sinn ergibt, eine türkische Fassung.
// Bei Reimen und Silben geht es um deutsche Wörter, darum gibt es dort nur Deutsch.

enum VorschulMehr {
    typealias F = VorschulFrage

    static func eine(_ art: VorschulArt, stufe: Int) -> F {
        switch art {
        case .wuerfel: return wuerfel()
        case .minus: return minus(stufe)
        case .zahlbild: return zahlbild(stufe)
        case .teilen: return teilen(stufe)
        case .buchstabe: return buchstabe()
        case .reime: return reim()
        case .silben: return silben()
        case .lage: return lage()
        case .gefuehle: return gefuehl()
        case .reihenfolge: return reihenfolge()
        case .tierwelt: return tierwelt()
        case .verkehr: return verkehr()
        default: return unterschied()
        }
    }

    /// Optionen mischen und die richtige finden
    static func gemischt(_ richtig: String, _ andere: [String], anzahl: Int = 3) -> (optionen: [String], index: Int) {
        var liste = [richtig]
        for a in andere.shuffled() where a != richtig && !liste.contains(a) && liste.count < anzahl {
            liste.append(a)
        }
        liste.shuffle()
        return (liste, liste.firstIndex(of: richtig) ?? 0)
    }

    // MARK: Zahlen

    static let wuerfelBilder = ["⚀", "⚁", "⚂", "⚃", "⚄", "⚅"]

    static func wuerfel() -> F {
        let n = Int.random(in: 1...6)
        let o = VorschulGenerator.zahlenOptionen(richtig: n, von: 1, bis: 6)
        return F(text: VorschulText(de: "Wie viele Punkte hat der Würfel?", tr: "Zarda kaç nokta var?"),
                 gross: wuerfelBilder[n - 1], optionen: o.optionen, richtig: o.index)
    }

    static func minus(_ stufe: Int) -> F {
        let m = stufe == 1 ? 5 : 10
        let n = Int.random(in: 2...m)
        let weg = Int.random(in: 1...(n - 1))
        let e = ["🎈", "🐦", "🦋", "🐝"].randomElement() ?? "🎈"
        let o = VorschulGenerator.zahlenOptionen(richtig: n - weg, von: 0, bis: m)
        return F(text: VorschulText(de: "Es waren \(n). \(weg) sind weggeflogen. Wie viele sind noch da?",
                                    tr: "\(n) tane vardı. \(weg) tanesi uçtu. Kaç tane kaldı?"),
                 zeige: Array(repeating: e, count: n - weg) + Array(repeating: "💨", count: weg),
                 optionen: o.optionen, richtig: o.index)
    }

    static func zahlbild(_ stufe: Int) -> F {
        let m = stufe == 1 ? 5 : 10
        let n = Int.random(in: 1...m)
        let e = VorschulGenerator.dinge.randomElement() ?? "⭐"
        let o = VorschulGenerator.zahlenOptionen(richtig: n, von: 1, bis: m)
        return F(text: VorschulText(de: "Wo sind es \(n)?", tr: "Hangisinde \(n) tane var?"),
                 gross: String(n),
                 optionen: o.optionen.map { VorschulGenerator.gruppe(Int($0) ?? 1, e) }, richtig: o.index,
                 gruppenOptionen: true)
    }

    static func teilen(_ stufe: Int) -> F {
        let kinder = Int.random(in: 2...3)
        let je = Int.random(in: 1...(stufe == 3 ? 6 : (stufe == 1 ? 2 : 4)))
        let e = ["🍪", "🍓", "🍬", "🍎"].randomElement() ?? "🍪"
        let o = VorschulGenerator.zahlenOptionen(richtig: je, von: 1, bis: 10)
        return F(text: VorschulText(de: "Teile gerecht auf \(kinder) Kinder auf. Wie viele bekommt jedes Kind?",
                                    tr: "\(kinder) çocuğa eşit paylaştır. Her çocuk kaç tane alır?"),
                 zeige: Array(repeating: e, count: kinder * je),
                 optionen: o.optionen, richtig: o.index)
    }

    // MARK: Sprache und Laute

    static let buchstaben = ["A", "B", "D", "E", "F", "H", "I", "K", "L", "M", "N", "O", "P", "R", "S", "T", "U", "Z"]

    static func buchstabe() -> F {
        let b = buchstaben.randomElement() ?? "A"
        let o = gemischt(b, buchstaben)
        return F(text: VorschulText(de: "Tippe auf das \(b).", tr: "\(b) harfine dokun."),
                 optionen: o.optionen, richtig: o.index)
    }

    /// Bild und Wort, das zweite reimt sich auf das erste
    static let reimPaare: [((String, String), (String, String))] = [
        (("🐭", "Maus"), ("🏠", "Haus")), (("🌹", "Rose"), ("👖", "Hose")), (("🐰", "Hase"), ("👃", "Nase")),
        (("🦵", "Bein"), ("🐷", "Schwein")), (("🫖", "Kanne"), ("🌲", "Tanne")), (("🐶", "Hund"), ("👄", "Mund")),
        (("🐱", "Katze"), ("🐾", "Tatze")), (("👜", "Tasche"), ("🍾", "Flasche")), (("✋", "Hand"), ("🏖️", "Sand"))
    ]

    static func reim() -> F {
        let p = reimPaare.randomElement() ?? reimPaare[0]
        let tausch = Bool.random()
        let (frage, antwort) = tausch ? (p.1, p.0) : (p.0, p.1)
        let andere = reimPaare.filter { $0.0.1 != p.0.1 }.flatMap { [$0.0.0, $0.1.0] }
        let o = gemischt(antwort.0, andere)
        return F(text: VorschulText(de: "Was reimt sich auf \(frage.1)?", tr: nil),
                 gross: frage.0, optionen: o.optionen, richtig: o.index)
    }

    /// Bild, Wort, Anzahl der Silben
    static let silbenBilder: [(String, String, Int)] = [
        ("🍌", "Banane", 3), ("🍎", "Apfel", 2), ("⚽", "Ball", 1), ("🐘", "Elefant", 3), ("🚗", "Auto", 2),
        ("🐶", "Hund", 1), ("🍅", "Tomate", 3), ("🐱", "Katze", 2), ("🍫", "Schokolade", 4), ("🦒", "Giraffe", 3),
        ("🐟", "Fisch", 1), ("🚀", "Rakete", 3), ("☀️", "Sonne", 2), ("🌙", "Mond", 1), ("🐊", "Krokodil", 3),
        ("🌸", "Blume", 2)
    ]

    static func silben() -> F {
        let (bild, wort, n) = silbenBilder.randomElement() ?? silbenBilder[0]
        return F(text: VorschulText(de: "Wie viele Silben hat \(wort)? Klatsche mit!", tr: nil),
                 gross: bild, optionen: ["1", "2", "3", "4"], richtig: n - 1)
    }

    // MARK: Entdecken

    static let tierReihe = ["🐶", "🐱", "🐰", "🐻", "🦊", "🐸", "🐼", "🐵"]

    static func lage() -> F {
        let drei = Array(tierReihe.shuffled().prefix(3))
        let wahl = Int.random(in: 0...2)
        let texte = [VorschulText(de: "Wer ist ganz links?", tr: "En solda kim var?"),
                     VorschulText(de: "Wer ist in der Mitte?", tr: "Ortada kim var?"),
                     VorschulText(de: "Wer ist ganz rechts?", tr: "En sağda kim var?")]
        let o = gemischt(drei[wahl], drei)
        return F(text: texte[wahl], zeige: drei, optionen: o.optionen, richtig: o.index)
    }

    static let gefuehle: [(String, String, String)] = [
        ("😀", "fröhlich", "mutlu"), ("😢", "traurig", "üzgün"), ("😠", "wütend", "kızgın"),
        ("😨", "ängstlich", "korkmuş"), ("😲", "überrascht", "şaşırmış"), ("😴", "müde", "uykulu")
    ]

    static func gefuehl() -> F {
        let g = gefuehle.randomElement() ?? gefuehle[0]
        let o = gemischt(g.0, gefuehle.map { $0.0 })
        return F(text: VorschulText(de: "Wer ist \(g.1)?", tr: "Hangisi \(g.2)?"),
                 optionen: o.optionen, richtig: o.index)
    }

    /// Was davor passiert, was als Nächstes kommt
    static let ablaeufe: [([String], String)] = [
        (["🥚", "🐣"], "🐔"), (["🐛"], "🦋"), (["🌱", "🌿"], "🌻"), (["🌅", "☀️"], "🌙"),
        (["❄️", "🌷"], "☀️"), (["🌷", "☀️"], "🍂"), (["☀️", "🍂"], "❄️"), (["🍂", "❄️"], "🌷"),
        (["👶", "🧒"], "🧑"), (["🌧️"], "🌈"), (["🧊"], "💧")
    ]

    static func reihenfolge() -> F {
        let a = ablaeufe.randomElement() ?? ablaeufe[0]
        let o = gemischt(a.1, ablaeufe.map { $0.1 })
        return F(text: VorschulText(de: "Was kommt als Nächstes?", tr: "Sırada ne var?"),
                 folge: a.0, optionen: o.optionen, richtig: o.index)
    }

    /// Tier und wo es lebt
    static let lebensraeume: [(String, String)] = [
        ("🐟", "🌊"), ("🐬", "🌊"), ("🐙", "🌊"), ("🦉", "🌳"), ("🦊", "🌳"), ("🐿️", "🌳"),
        ("🐪", "🏜️"), ("🦂", "🏜️"), ("🐧", "🧊"), ("🐻‍❄️", "🧊"), ("🐄", "🏡"), ("🐖", "🏡"), ("🐑", "🏡")
    ]

    static func tierwelt() -> F {
        let (tier, ort) = lebensraeume.randomElement() ?? lebensraeume[0]
        let o = gemischt(ort, ["🌊", "🌳", "🏜️", "🧊", "🏡"])
        return F(text: VorschulText(de: "Wo lebt dieses Tier?", tr: "Bu hayvan nerede yaşar?"),
                 gross: tier, optionen: o.optionen, richtig: o.index)
    }

    static let verkehrsFragen: [(VorschulText, String, [String])] = [
        (VorschulText(de: "Bei welcher Ampelfarbe darfst du gehen?", tr: "Hangi ışıkta karşıya geçebilirsin?"), "🟢", ["🔴", "🟡"]),
        (VorschulText(de: "Bei welcher Ampelfarbe bleibst du stehen?", tr: "Hangi ışıkta durursun?"), "🔴", ["🟢", "🔵"]),
        (VorschulText(de: "Was machst du, bevor du über die Straße gehst?", tr: "Karşıya geçmeden önce ne yaparsın?"), "👀", ["🏃", "🙈"]),
        (VorschulText(de: "Was setzt du beim Fahrradfahren auf den Kopf?", tr: "Bisiklete binerken başına ne takarsın?"), "⛑️", ["🎩", "👑"]),
        (VorschulText(de: "Was macht dich im Dunkeln gut sichtbar?", tr: "Karanlıkta seni ne görünür yapar?"), "🦺", ["🕶️", "🧢"]),
        (VorschulText(de: "Wo gehst du sicher über die Straße?", tr: "Karşıya nerede güvenle geçersin?"), "🚸", ["🌳", "🚧"])
    ]

    static func verkehr() -> F {
        let (text, richtig, falsch) = verkehrsFragen.randomElement() ?? verkehrsFragen[0]
        let o = gemischt(richtig, falsch)
        return F(text: text, optionen: o.optionen, richtig: o.index)
    }

    /// Zwei Bilder, die sich ähnlich sehen
    static let aehnlich: [(String, String)] = [
        ("🐶", "🐕"), ("🐱", "🐈"), ("🙂", "🙃"), ("⭐", "🌟"), ("🍎", "🍏"), ("🚗", "🚙"),
        ("🐟", "🐠"), ("❤️", "🧡"), ("🔵", "🟦"), ("🌲", "🌳"), ("😀", "😃"), ("🐭", "🐹")
    ]

    static func unterschied() -> F {
        let (gleich, anders) = aehnlich.randomElement() ?? aehnlich[0]
        var bilder = Array(repeating: gleich, count: 3)
        let stelle = Int.random(in: 0...3)
        bilder.insert(anders, at: stelle)
        return F(text: VorschulText(de: "Welches Bild ist anders?", tr: "Hangi resim farklı?"),
                 optionen: bilder, richtig: stelle)
    }
}

// MARK: - Schulstart-Pass: ein Stempel für jedes geschaffte Spiel

struct SchulstartPass: View {
    @Query(filter: #Predicate<RundenErgebnis> { $0.klasse == "Vorschule" && $0.quelle == "lokal" })
    private var runden: [RundenErgebnis]

    static var stationen: [VorschulArt] { VorschulArt.allCases.filter { $0 != .mix } }

    private var gestempelt: Set<String> {
        Set(runden.filter { $0.sterne >= 1 }.map { $0.uebung })
    }

    private func hat(_ a: VorschulArt) -> Bool { gestempelt.contains("\(a.emoji) \(a.titel)") }

    var body: some View {
        let anzahl = Self.stationen.filter { hat($0) }.count
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("🎒 Mein Schulstart-Pass")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.white)
                Spacer()
                Text("\(anzahl) von \(Self.stationen.count)")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                    .contentTransition(.numericText())
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 8)], spacing: 8) {
                ForEach(Self.stationen) { a in
                    Text(a.emoji)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .background(hat(a) ? Theme.gelb.opacity(0.85) : Color.white.opacity(0.08), in: Circle())
                        .grayscale(hat(a) ? 0 : 1)
                        .opacity(hat(a) ? 1 : 0.45)
                        .accessibilityLabel("\(a.titel): \(hat(a) ? "geschafft" : "noch offen")")
                }
            }
            Text(anzahl == Self.stationen.count
                 ? "Alle Stempel! Du bist bereit für die Schule. 🎉"
                 : "Schaffe jedes Spiel mit mindestens einem Stern und sammle alle Stempel.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
        }
        .padding(16)
        .glasKarte(radius: 24)
    }
}
