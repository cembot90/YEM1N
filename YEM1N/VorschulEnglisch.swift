import Foundation

// ============================================================
// MARK: - Englisch für Kleine (Vorschule)
// ============================================================
//
// Englisch so, wie es in der Kita läuft: hören und antippen, ohne Lesen.
// Das Bild ist die Bedeutung, die Stimme sagt das englische Wort.
// Erst hört das Kind die Wörter in Ruhe an, dann kommt ein Spiel:
// "Tap the dog!" und drei Bilder zur Wahl.
// Diese Datei braucht nur Foundation, damit pruefen/linux-tests.sh sie prüfen kann.

/// Ein Wort mit Bild, deutscher Bedeutung für die Eltern und englischem Wort.
struct EnglischWort: Hashable, Sendable {
    let bild: String
    let de: String
    let en: String
    /// Mehrzahl wie "trousers": "Where are the trousers?"
    var mehrzahl = false
    /// Farben und Zahlen stehen ohne "the": "Tap red!"
    var ohneArtikel = false
}

enum EnglischThema: String, CaseIterable, Identifiable, Hashable {
    case farben, zahlen, tiere, essen, koerper, kleidung, dinge, gemischt

    var id: String { rawValue }

    var titel: String {
        switch self {
        case .farben: return "Farben"
        case .zahlen: return "Zahlen"
        case .tiere: return "Tiere"
        case .essen: return "Essen"
        case .koerper: return "Mein Körper"
        case .kleidung: return "Kleidung"
        case .dinge: return "Spielen und draußen"
        case .gemischt: return "Alles gemischt"
        }
    }

    /// Englischer Name, den die Stimme beim Öffnen sagt
    var titelEn: String {
        switch self {
        case .farben: return "Colours"
        case .zahlen: return "Numbers"
        case .tiere: return "Animals"
        case .essen: return "Food"
        case .koerper: return "My body"
        case .kleidung: return "Clothes"
        case .dinge: return "Play and outside"
        case .gemischt: return "Everything mixed"
        }
    }

    var emoji: String {
        switch self {
        case .farben: return "🎨"
        case .zahlen: return "🔢"
        case .tiere: return "🐶"
        case .essen: return "🍎"
        case .koerper: return "👃"
        case .kleidung: return "👕"
        case .dinge: return "⚽"
        case .gemischt: return "🎲"
        }
    }

    /// Wörter dieses Themas. "Alles gemischt" hat keine eigenen.
    var woerter: [EnglischWort] {
        switch self {
        case .farben: return VorschulEnglisch.farben
        case .zahlen: return VorschulEnglisch.zahlen
        case .tiere: return VorschulEnglisch.tiere
        case .essen: return VorschulEnglisch.essen
        case .koerper: return VorschulEnglisch.koerper
        case .kleidung: return VorschulEnglisch.kleidung
        case .dinge: return VorschulEnglisch.dinge
        case .gemischt: return EnglischThema.mitWoertern.flatMap(\.woerter)
        }
    }

    /// Alle Themen mit eigenen Wörtern
    static let mitWoertern: [EnglischThema] = [.farben, .zahlen, .tiere, .essen, .koerper, .kleidung, .dinge]

    /// Name für Ergebnisse und Eltern-Übersicht
    var uebungName: String { "🇬🇧 \(titel)" }
}

enum VorschulEnglisch {
    static func f(_ bild: String, _ de: String, _ en: String) -> EnglischWort {
        EnglischWort(bild: bild, de: de, en: en, ohneArtikel: true)
    }

    static let farben: [EnglischWort] = [
        f("🔴", "rot", "red"), f("🔵", "blau", "blue"), f("🟡", "gelb", "yellow"),
        f("🟢", "grün", "green"), f("🟠", "orange", "orange"), f("🟣", "lila", "purple"),
        f("⚫", "schwarz", "black"), f("⚪", "weiß", "white"), f("🟤", "braun", "brown")
    ]

    static let zahlen: [EnglischWort] = [
        f("1", "eins", "one"), f("2", "zwei", "two"), f("3", "drei", "three"), f("4", "vier", "four"),
        f("5", "fünf", "five"), f("6", "sechs", "six"), f("7", "sieben", "seven"), f("8", "acht", "eight"),
        f("9", "neun", "nine"), f("10", "zehn", "ten")
    ]

    static let tiere: [EnglischWort] = [
        EnglischWort(bild: "🐶", de: "der Hund", en: "dog"), EnglischWort(bild: "🐱", de: "die Katze", en: "cat"),
        EnglischWort(bild: "🐦", de: "der Vogel", en: "bird"), EnglischWort(bild: "🐟", de: "der Fisch", en: "fish"),
        EnglischWort(bild: "🐴", de: "das Pferd", en: "horse"), EnglischWort(bild: "🐮", de: "die Kuh", en: "cow"),
        EnglischWort(bild: "🐷", de: "das Schwein", en: "pig"), EnglischWort(bild: "🦆", de: "die Ente", en: "duck"),
        EnglischWort(bild: "🐭", de: "die Maus", en: "mouse"), EnglischWort(bild: "🐰", de: "der Hase", en: "rabbit"),
        EnglischWort(bild: "🦁", de: "der Löwe", en: "lion"), EnglischWort(bild: "🐘", de: "der Elefant", en: "elephant"),
        EnglischWort(bild: "🐸", de: "der Frosch", en: "frog"), EnglischWort(bild: "🐻", de: "der Bär", en: "bear")
    ]

    static let essen: [EnglischWort] = [
        EnglischWort(bild: "🍎", de: "der Apfel", en: "apple"), EnglischWort(bild: "🍌", de: "die Banane", en: "banana"),
        EnglischWort(bild: "🍐", de: "die Birne", en: "pear"), EnglischWort(bild: "🍓", de: "die Erdbeere", en: "strawberry"),
        EnglischWort(bild: "🍇", de: "die Weintrauben", en: "grapes", mehrzahl: true),
        EnglischWort(bild: "🥕", de: "die Karotte", en: "carrot"), EnglischWort(bild: "🍞", de: "das Brot", en: "bread"),
        EnglischWort(bild: "🧀", de: "der Käse", en: "cheese"), EnglischWort(bild: "🥚", de: "das Ei", en: "egg"),
        EnglischWort(bild: "🥛", de: "die Milch", en: "milk"), EnglischWort(bild: "🍰", de: "der Kuchen", en: "cake"),
        EnglischWort(bild: "🍦", de: "das Eis", en: "ice cream")
    ]

    static let koerper: [EnglischWort] = [
        EnglischWort(bild: "👃", de: "die Nase", en: "nose"), EnglischWort(bild: "👂", de: "das Ohr", en: "ear"),
        EnglischWort(bild: "👁️", de: "das Auge", en: "eye"), EnglischWort(bild: "👄", de: "der Mund", en: "mouth"),
        EnglischWort(bild: "✋", de: "die Hand", en: "hand"), EnglischWort(bild: "🦶", de: "der Fuß", en: "foot"),
        EnglischWort(bild: "🦵", de: "das Bein", en: "leg"), EnglischWort(bild: "🦷", de: "der Zahn", en: "tooth")
    ]

    static let kleidung: [EnglischWort] = [
        EnglischWort(bild: "👕", de: "das T-Shirt", en: "T-shirt"), EnglischWort(bild: "👖", de: "die Hose", en: "trousers", mehrzahl: true),
        EnglischWort(bild: "👗", de: "das Kleid", en: "dress"), EnglischWort(bild: "🧥", de: "die Jacke", en: "coat"),
        EnglischWort(bild: "🧦", de: "die Socken", en: "socks", mehrzahl: true), EnglischWort(bild: "👟", de: "die Schuhe", en: "shoes", mehrzahl: true),
        EnglischWort(bild: "🧢", de: "die Mütze", en: "cap"), EnglischWort(bild: "🧣", de: "der Schal", en: "scarf"),
        EnglischWort(bild: "🧤", de: "die Handschuhe", en: "gloves", mehrzahl: true)
    ]

    static let dinge: [EnglischWort] = [
        EnglischWort(bild: "⚽", de: "der Ball", en: "ball"), EnglischWort(bild: "🚗", de: "das Auto", en: "car"),
        EnglischWort(bild: "🚌", de: "der Bus", en: "bus"), EnglischWort(bild: "🚂", de: "der Zug", en: "train"),
        EnglischWort(bild: "✈️", de: "das Flugzeug", en: "plane"), EnglischWort(bild: "📖", de: "das Buch", en: "book"),
        EnglischWort(bild: "🏠", de: "das Haus", en: "house"), EnglischWort(bild: "☀️", de: "die Sonne", en: "sun"),
        EnglischWort(bild: "🌙", de: "der Mond", en: "moon"), EnglischWort(bild: "⭐", de: "der Stern", en: "star"),
        EnglischWort(bild: "🌳", de: "der Baum", en: "tree"), EnglischWort(bild: "🌸", de: "die Blume", en: "flower")
    ]

    // MARK: Sätze

    /// Was die Stimme beim Anhören sagt: nur das Wort, damit es gut hängen bleibt
    static func anhoeren(_ w: EnglischWort) -> String { w.en }

    /// Die Aufforderung im Spiel. `art` wählt eine von drei Formen.
    static func aufforderung(_ w: EnglischWort, art: Int) -> String {
        let ding = w.ohneArtikel ? w.en : "the \(w.en)"
        switch art % 3 {
        case 0: return "Tap \(ding)!"
        case 1: return "Where \(w.mehrzahl ? "are" : "is") \(ding)?"
        default: return "Find \(ding)!"
        }
    }

    /// Was die Eltern unter der Aufforderung lesen: "dog: der Hund"
    static func bedeutung(_ w: EnglischWort) -> String { "\(w.en): \(w.de)" }

    // MARK: Spiel

    /// Eine Runde: jedes Wort höchstens einmal gesucht, drei Bilder zur Wahl.
    static func fragen(_ thema: EnglischThema, anzahl: Int = 8) -> [VorschulFrage] {
        var ziele: [(EnglischWort, [EnglischWort])] = []
        if thema == .gemischt {
            // Aus jedem Thema etwas, die anderen Bilder kommen aus demselben Thema
            var themen = EnglischThema.mitWoertern.shuffled()
            var runden = 0
            while ziele.count < anzahl, runden < 200 {
                runden += 1
                let t = themen.removeFirst()
                if let w = t.woerter.randomElement() { ziele.append((w, t.woerter)) }
                if themen.isEmpty && ziele.count < anzahl { themen = EnglischThema.mitWoertern.shuffled() }
                ziele = eindeutig(ziele)
            }
        } else {
            let liste = thema.woerter
            ziele = liste.shuffled().prefix(anzahl).map { ($0, liste) }
        }
        return ziele.enumerated().map { i, paar in frage(paar.0, aus: paar.1, art: i) }
    }

    private static func eindeutig(_ liste: [(EnglischWort, [EnglischWort])]) -> [(EnglischWort, [EnglischWort])] {
        var gesehen = Set<String>()
        return liste.filter { gesehen.insert($0.0.en).inserted }
    }

    static func frage(_ w: EnglischWort, aus liste: [EnglischWort], art: Int) -> VorschulFrage {
        var optionen = [w.bild]
        for a in liste.shuffled() where optionen.count < 3 && !optionen.contains(a.bild) {
            optionen.append(a.bild)
        }
        optionen.shuffle()
        return VorschulFrage(text: VorschulText(de: bedeutung(w), tr: nil, en: aufforderung(w, art: art)),
                             optionen: optionen,
                             richtig: optionen.firstIndex(of: w.bild) ?? 0)
    }
}
