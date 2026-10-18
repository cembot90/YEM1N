import Foundation

// ============================================================
// MARK: - Lernwelt Englisch, Musik und Kunst
// ============================================================

// MARK: Englisch
// Im Lehrplan ab Klasse 3. Für Klasse 1 und 2 gibt es ein paar Themen zum Reinschnuppern,
// die als Extra gekennzeichnet sind. Die Wörter kommen aus dem eingebauten Sprachkatalog.

enum LehrplanEnglisch {
    static var themen: [LernThema] {
        [
            thema("e1-farben", "Colours: Farben", "🎨", "red, blue, green ...", klasse: 1, katalog: "farben", lehrplan: false),
            thema("e1-zahlen", "Numbers: Zahlen bis 10", "🔢", "one, two, three ...", klasse: 1, katalog: "zahl0", lehrplan: false),
            thema("e2-tiere", "Animals: Haustiere", "🐶", "dog, cat, horse ...", klasse: 2, katalog: "haustiere", lehrplan: false),
            thema("e2-obst", "Fruit: Obst und Gemüse", "🍎", "apple, banana ...", klasse: 2, katalog: "obst", lehrplan: false),
            thema("e3-familie", "Family: Familie", "👨‍👩‍👧", "mother, father, sister ...", klasse: 3, katalog: "familie"),
            thema("e3-kleidung", "Clothes: Kleidung", "👕", "T-shirt, shoes, hat ...", klasse: 3, katalog: "kleidung"),
            thema("e3-schule", "School: Schule", "🏫", "pencil, book, teacher ...", klasse: 3, katalog: "schule"),
            thema("e3-zahlen", "Numbers: 11 bis 20", "🔢", "eleven, twelve ...", klasse: 3, katalog: "zahl20"),
            thema("e3-tage", "Days: Wochentage", "📅", "Monday, Tuesday ...", klasse: 3, katalog: "wochentage"),
            thema("e4-wetter", "Weather: Wetter", "☀️", "sun, rain, snow ...", klasse: 4, katalog: "wetter"),
            thema("e4-monate", "Months: Monate", "🗓️", "January, February ...", klasse: 4, katalog: "monate"),
            thema("e4-zeit", "Seasons: Jahreszeiten", "🌷", "spring, summer ...", klasse: 4, katalog: "zeit"),
            thema("e4-wildtiere", "Wild animals: Wilde Tiere", "🦁", "lion, tiger, monkey ...", klasse: 4, katalog: "wildtiere"),
            thema("e4-freizeit", "Hobbies: Freizeit", "⚽", "ball, game, music ...", klasse: 4, katalog: "freizeit"),
            thema("e3-koerper", "Body: Körper", "🧍", "head, hand, foot ...", klasse: 3, katalog: "koerper"),
            thema("e3-essen", "Food: Essen und Trinken", "🍞", "bread, milk, water ...", klasse: 3, katalog: "essen"),
            thema("e3-hallo", "Hello! Begrüßen und Danken", "👋", "hello, thank you, sorry ...", klasse: 3, katalog: "hallo"),
            thema("e4-zuhause", "Home: Zuhause", "🏠", "house, bed, kitchen ...", klasse: 4, katalog: "zuhause"),
            thema("e4-fahrzeuge", "Transport: Fahrzeuge", "🚗", "car, bus, train ...", klasse: 4, katalog: "fahrzeuge"),
            thema("e4-stadt", "Town: Stadt und Orte", "🏙️", "shop, park, school ...", klasse: 4, katalog: "stadt"),
            thema("e4-tun", "Actions: Tätigkeiten", "🏃", "run, swim, read ...", klasse: 4, katalog: "taetigkeiten"),
            thema("e4-gegenteile", "Opposites: Gegenteile", "↔️", "big, small, hot, cold ...", klasse: 4, katalog: "gegenteile")
        ]
    }

    private static func thema(_ id: String, _ titel: String, _ emoji: String, _ text: String,
                              klasse: Int, katalog: String, lehrplan: Bool = true) -> LernThema {
        LernThema(id: id, fach: .englisch, titel: titel, emoji: emoji, beschreibung: text,
                  klasse: klasse, lehrplan: lehrplan,
                  tipp: "Tippe auf den Lautsprecher und sprich das englische Wort laut nach.",
                  erzeuge: { LehrplanEnglisch.vokabel(katalog) })
    }

    /// Deutsch und Englisch aus dem eingebauten Katalog, ohne eigene Themen aus dem Editor
    static let woerter: [String: [(emoji: String, de: String, en: String)]] = {
        guard let k = try? JSONDecoder().decode(SprachKatalog.self, from: Data(SprachKatalogDaten.json.utf8)) else {
            return [:]
        }
        var d: [String: [(emoji: String, de: String, en: String)]] = [:]
        for t in k.themen {
            d[t.id] = t.woerter.compactMap { w in
                guard let de = w.texte["de"], let en = w.texte["en"], !de.isEmpty, !en.isEmpty else { return nil }
                return (w.emoji ?? "", de, en)
            }
        }
        return d
    }()

    static func vokabel(_ katalog: String) -> LernAufgabe {
        let liste = woerter[katalog] ?? []
        guard liste.count >= 3 else {
            return Lern.wahl(frage: "Wie heißt das auf Englisch?", rechnung: "Hallo", richtig: "hello",
                             falsch: ["goodbye", "thank you"])
        }
        let w = Lern.eins(liste)
        // Hören: Das Wort klingt, das Kind tippt das passende Bild an
        let mitBild = liste.filter { !$0.emoji.isEmpty && !$0.emoji.unicodeScalars.allSatisfy { $0.properties.numericType != nil } }
        if mitBild.count >= 3, !w.emoji.isEmpty, mitBild.contains(where: { $0.en == w.en }), Lern.wahr(0.33) {
            return Lern.wahl(frage: "Hör gut zu! Welches Bild passt?", richtig: w.emoji,
                             falsch: mitBild.map { $0.emoji }, bild: "englisch:\(w.en)",
                             erklaerung: "\(w.en) heißt \(w.de) \(w.emoji).")
        }
        if Lern.wahr(0.5) {
            let vorne = w.emoji.isEmpty ? "" : w.emoji + " "
            return Lern.wahl(frage: "Wie heißt das auf Englisch?", rechnung: vorne + w.de,
                             richtig: w.en, falsch: liste.map { $0.en },
                             erklaerung: "\(w.de) heißt auf Englisch \(w.en).")
        }
        return Lern.wahl(frage: "Was bedeutet das englische Wort?", rechnung: w.en,
                         richtig: w.de, falsch: liste.map { $0.de }, bild: "englisch:\(w.en)",
                         erklaerung: "\(w.en) heißt \(w.de).")
    }
}

// MARK: Musik
// Klasse 1 und 2: Instrumente, laut und leise, Notenwerte
// Klasse 3 und 4: Noten lesen, Instrumentenfamilien, Takt, Fachbegriffe, Komponisten

enum LehrplanMusik {
    static var themen: [LernThema] {
        [
            LernThema(id: "mu1-instrumente", fach: .musik, titel: "Instrumente erkennen", emoji: "🥁",
                      beschreibung: "Wie heißt das Instrument?", klasse: 1, erzeuge: instrument),
            LernThema(id: "mu1-laut", fach: .musik, titel: "Laut oder leise?", emoji: "🔊",
                      beschreibung: "Geräusche um uns herum", klasse: 1, erzeuge: lautLeise),
            LernThema(id: "mu2-notenwerte", fach: .musik, titel: "Notenwerte", emoji: "🎼",
                      beschreibung: "Ganze, halbe und Viertelnoten", klasse: 2,
                      tipp: "Eine ganze Note dauert 4 Schläge, eine halbe 2 und eine Viertelnote 1.",
                      erzeuge: notenwert),
            LernThema(id: "mu3-noten", fach: .musik, titel: "Noten lesen", emoji: "🎵",
                      beschreibung: "c, d, e, f, g, a, h im Violinschlüssel", klasse: 3,
                      tipp: "Die unterste Linie ist das e. Das c hat eine eigene kleine Hilfslinie.",
                      erzeuge: noteLesen),
            LernThema(id: "mu3-familien", fach: .musik, titel: "Instrumentenfamilien", emoji: "🎻",
                      beschreibung: "Streichen, zupfen, blasen, schlagen, Tasten", klasse: 3, erzeuge: familie),
            LernThema(id: "mu4-takt", fach: .musik, titel: "Takt", emoji: "🥢",
                      beschreibung: "Wie viele Noten passen in einen Takt?", klasse: 4,
                      tipp: "Im 3/4-Takt passen 3 Viertelnoten in einen Takt.", erzeuge: takt),
            LernThema(id: "mu4-begriffe", fach: .musik, titel: "piano, forte und mehr", emoji: "🎚️",
                      beschreibung: "Wie laut und wie schnell?", klasse: 4, erzeuge: begriff),
            LernThema(id: "mu4-komponisten", fach: .musik, titel: "Berühmte Komponisten", emoji: "🎹",
                      beschreibung: "Wer hat das komponiert?", klasse: 4, erzeuge: komponist),
            LernThema(id: "mu1-hochtief", fach: .musik, titel: "Hoch oder tief?", emoji: "🐦",
                      beschreibung: "Zwei Töne anhören und vergleichen", klasse: 1,
                      tipp: "Ein hoher Ton klingt wie ein Vogel, ein tiefer wie ein Bär.", erzeuge: hochTief),
            LernThema(id: "mu3-tonleiter", fach: .musik, titel: "Die Tonleiter", emoji: "🪜",
                      beschreibung: "c, d, e, f, g, a, h, c", klasse: 3,
                      tipp: "Die Tonleiter geht c, d, e, f, g, a, h und dann wieder c.", erzeuge: tonleiter),
            LernThema(id: "mu4-stimmen", fach: .musik, titel: "Singstimmen", emoji: "🎤",
                      beschreibung: "Sopran, Alt, Tenor und Bass", klasse: 4, erzeuge: stimmen)
        ]
    }

    static func hochTief() -> LernAufgabe {
        var a = Lern.eins(Noten.alle)
        var b = Lern.eins(Noten.alle)
        while abs((Noten.stufe[a] ?? 0) - (Noten.stufe[b] ?? 0)) < 3 {
            a = Lern.eins(Noten.alle)
            b = Lern.eins(Noten.alle)
        }
        let ersterHoeher = (Noten.stufe[a] ?? 0) > (Noten.stufe[b] ?? 0)
        let fragHoeher = Lern.wahr(0.5)
        let richtig = (ersterHoeher == fragHoeher) ? "Ton 1" : "Ton 2"
        return LernAufgabe(art: "wahl", frage: fragHoeher ? "Hör dir beide Töne an. Welcher ist höher?"
                                                          : "Hör dir beide Töne an. Welcher ist tiefer?",
                           antwort: richtig, erklaerung: "\(richtig) klingt \(fragHoeher ? "höher" : "tiefer").",
                           optionen: ["Ton 1", "Ton 2"], bild: "toene:\(a)|\(b)")
    }

    static let leiter = ["c", "d", "e", "f", "g", "a", "h"]

    static func tonleiter() -> LernAufgabe {
        if Lern.wahr(0.1) {
            return Lern.zahl("Wie viele Töne hat die Tonleiter von c bis zum nächsten c?", "", 8,
                             erklaerung: "c, d, e, f, g, a, h, c: das sind 8 Töne.")
        }
        let i = Lern.z(0...6)
        if Lern.wahr(0.5) {
            let richtig = leiter[(i + 1) % 7]
            return Lern.wahl(frage: "Welcher Ton kommt danach?", rechnung: "\(leiter[i]), ?", richtig: richtig,
                             falsch: leiter, erklaerung: "Nach \(leiter[i]) kommt \(richtig).")
        }
        let richtig = leiter[(i + 6) % 7]
        return Lern.wahl(frage: "Welcher Ton kommt davor?", rechnung: "?, \(leiter[i])", richtig: richtig,
                         falsch: leiter, erklaerung: "Vor \(leiter[i]) kommt \(richtig).")
    }

    static let stimmlagen: [(String, String)] = [
        ("Sopran", "die hohe Frauenstimme"), ("Alt", "die tiefe Frauenstimme"),
        ("Tenor", "die hohe Männerstimme"), ("Bass", "die tiefe Männerstimme")
    ]

    static func stimmen() -> LernAufgabe {
        switch Lern.z(0...2) {
        case 0:
            let (name, text) = Lern.eins(stimmlagen)
            return Lern.wahl(frage: "Wie heißt \(text)?", richtig: name, falsch: stimmlagen.map { $0.0 },
                             erklaerung: "\(name) ist \(text).")
        case 1:
            let (name, text) = Lern.eins(stimmlagen)
            return Lern.wahl(frage: "Was ist ein \(name)?", richtig: text, falsch: stimmlagen.map { $0.1 },
                             erklaerung: "\(name) ist \(text).")
        default:
            let hoch = Lern.wahr(0.5)
            return Lern.wahl(frage: hoch ? "Welche Stimme singt am höchsten?" : "Welche Stimme singt am tiefsten?",
                             richtig: hoch ? "Sopran" : "Bass", falsch: stimmlagen.map { $0.0 },
                             erklaerung: hoch ? "Der Sopran singt am höchsten." : "Der Bass singt am tiefsten.")
        }
    }

    static let instrumente: [(String, String)] = [
        ("🥁", "Trommel"), ("🎻", "Geige"), ("🎺", "Trompete"), ("🎹", "Klavier"), ("🎸", "Gitarre"),
        ("🪈", "Flöte"), ("🎷", "Saxofon"), ("🪗", "Akkordeon"), ("🔔", "Glocke"), ("🪇", "Rassel")
    ]

    static func instrument() -> LernAufgabe {
        let (bild, name) = Lern.eins(instrumente)
        return Lern.wahl(frage: "Wie heißt das Instrument?", richtig: name, falsch: instrumente.map { $0.1 },
                         bild: "emoji:\(bild)", erklaerung: "Das Instrument heißt \(name).")
    }

    static let geraeusche: [(String, String)] = [
        ("Eine Maus piepst.", "leise"), ("Ein Gewitter donnert.", "laut"), ("Ein Flugzeug startet.", "laut"),
        ("Jemand flüstert.", "leise"), ("Eine Feder fällt zu Boden.", "leise"),
        ("Ein Feuerwehrauto fährt mit Sirene.", "laut"), ("Der Wecker klingelt.", "laut"),
        ("Ein Baby schläft und atmet.", "leise"), ("Blätter rascheln im Wind.", "leise"),
        ("Ein Presslufthammer hämmert.", "laut"), ("Eine Katze schnurrt.", "leise"),
        ("Die Kirchenglocken läuten.", "laut"), ("Ein Löwe brüllt.", "laut"), ("Schnee fällt.", "leise")
    ]

    static func lautLeise() -> LernAufgabe {
        let (satz, richtig) = Lern.eins(geraeusche)
        return LernAufgabe(art: "wahl", frage: "Ist das laut oder leise?", rechnung: satz, antwort: richtig,
                           erklaerung: "Das ist \(richtig).", optionen: ["laut", "leise"])
    }

    static let notenNamen = ["ganze": "ganze Note", "halbe": "halbe Note", "viertel": "Viertelnote", "achtel": "Achtelnote"]

    static func notenwert() -> LernAufgabe {
        let alleNamen = ["ganze Note", "halbe Note", "Viertelnote", "Achtelnote"]
        switch Lern.z(0...3) {
        case 0:
            let w = Lern.eins(["ganze", "halbe", "viertel", "achtel"])
            let name = notenNamen[w] ?? ""
            return LernAufgabe(art: "wahl", frage: "Wie heißt diese Note?", antwort: name,
                               erklaerung: "Das ist eine \(name).", optionen: alleNamen, bild: "notenwert:\(w)")
        case 1:
            let w = Lern.eins([("ganze", 4), ("halbe", 2), ("viertel", 1)])
            let name = notenNamen[w.0] ?? ""
            return Lern.zahl("Wie viele Schläge dauert diese Note?", "", w.1,
                             erklaerung: "Eine \(name) dauert \(w.1) \(w.1 == 1 ? "Schlag" : "Schläge").")
                .mitBild("notenwert:\(w.0)")
        case 2:
            let f = Lern.eins([("Wie viele Viertelnoten dauern so lang wie eine halbe Note?", 2),
                               ("Wie viele Viertelnoten dauern so lang wie eine ganze Note?", 4),
                               ("Wie viele halbe Noten dauern so lang wie eine ganze Note?", 2),
                               ("Wie viele Achtelnoten dauern so lang wie eine Viertelnote?", 2)])
            return Lern.zahl(f.0, "", f.1, erklaerung: "Richtig sind \(f.1).")
        default:
            let f = Lern.eins([("Zwei Viertelnoten dauern so lang wie eine ...", "halbe Note"),
                               ("Zwei halbe Noten dauern so lang wie eine ...", "ganze Note"),
                               ("Zwei Achtelnoten dauern so lang wie eine ...", "Viertelnote")])
            return LernAufgabe(art: "wahl", frage: f.0, antwort: f.1, erklaerung: "\(f.0.dropLast(4)) \(f.1).",
                               optionen: alleNamen)
        }
    }

    static func noteLesen() -> LernAufgabe {
        let note = Lern.eins(Noten.alle)
        let name = Noten.name[note] ?? ""
        let andere = ["c", "d", "e", "f", "g", "a", "h"]
        return Lern.wahl(frage: "Wie heißt die Note?", richtig: name, falsch: andere, bild: "note:\(note)",
                         erklaerung: "Das ist ein \(name).")
    }

    static let familien: [(String, String)] = [
        ("Geige", "Streichinstrument"), ("Cello", "Streichinstrument"), ("Kontrabass", "Streichinstrument"),
        ("Bratsche", "Streichinstrument"), ("Gitarre", "Zupfinstrument"), ("Harfe", "Zupfinstrument"),
        ("Trompete", "Blasinstrument"), ("Posaune", "Blasinstrument"), ("Tuba", "Blasinstrument"),
        ("Blockflöte", "Blasinstrument"), ("Klarinette", "Blasinstrument"), ("Querflöte", "Blasinstrument"),
        ("Trommel", "Schlaginstrument"), ("Pauke", "Schlaginstrument"), ("Xylofon", "Schlaginstrument"),
        ("Becken", "Schlaginstrument"), ("Triangel", "Schlaginstrument"),
        ("Klavier", "Tasteninstrument"), ("Orgel", "Tasteninstrument")
    ]

    static func familie() -> LernAufgabe {
        let (instrument, art) = Lern.eins(familien)
        let alle = ["Streichinstrument", "Zupfinstrument", "Blasinstrument", "Schlaginstrument", "Tasteninstrument"]
        return Lern.wahl(frage: "Zu welcher Familie gehört das Instrument?", rechnung: instrument,
                         richtig: art, falsch: alle, erklaerung: "\(instrument) ist ein \(art).")
    }

    static func takt() -> LernAufgabe {
        let t = Lern.z(2...4)
        switch Lern.z(0...3) {
        case 0:
            return Lern.zahl("Wie viele Viertelnoten passen in einen \(t)/4-Takt?", "", t,
                             erklaerung: "In einen \(t)/4-Takt passen \(t) Viertelnoten.")
        case 1:
            return Lern.zahl("Wie viele Achtelnoten passen in einen \(t)/4-Takt?", "", 2 * t,
                             erklaerung: "Eine Viertelnote sind 2 Achtelnoten. \(t) · 2 = \(2 * t)")
        case 2:
            return Lern.zahl("Im \(t)/4-Takt steht schon eine Viertelnote. Wie viele Viertelnoten fehlen noch?", "", t - 1,
                             erklaerung: "\(t) - 1 = \(t - 1)")
        default:
            let tt = max(t, 3)
            return Lern.zahl("Im \(tt)/4-Takt steht schon eine halbe Note. Wie viele Viertelnoten fehlen noch?", "", tt - 2,
                             erklaerung: "Eine halbe Note sind 2 Viertel. \(tt) - 2 = \(tt - 2)")
        }
    }

    static let begriffe: [(String, String)] = [
        ("piano", "leise"), ("forte", "laut"), ("pianissimo", "sehr leise"), ("fortissimo", "sehr laut"),
        ("crescendo", "lauter werden"), ("decrescendo", "leiser werden"), ("allegro", "schnell und fröhlich"),
        ("adagio", "langsam"), ("presto", "sehr schnell")
    ]

    static func begriff() -> LernAufgabe {
        let (wort, bedeutung) = Lern.eins(begriffe)
        if Lern.wahr(0.5) {
            return Lern.wahl(frage: "Was bedeutet das in der Musik?", rechnung: wort, richtig: bedeutung,
                             falsch: begriffe.map { $0.1 }, erklaerung: "\(wort) heißt \(bedeutung).")
        }
        return Lern.wahl(frage: "Welches Wort steht in den Noten dafür?", rechnung: bedeutung, richtig: wort,
                         falsch: begriffe.map { $0.0 }, erklaerung: "\(bedeutung) heißt in der Musik \(wort).")
    }

    static let werke: [(String, String)] = [
        ("Die Zauberflöte", "Mozart"), ("Eine kleine Nachtmusik", "Mozart"), ("Für Elise", "Beethoven"),
        ("die Melodie der Ode an die Freude", "Beethoven"), ("Die vier Jahreszeiten", "Vivaldi"),
        ("Der Nussknacker", "Tschaikowsky"), ("Schwanensee", "Tschaikowsky"), ("Peter und der Wolf", "Prokofjew"),
        ("Karneval der Tiere", "Saint-Saëns"), ("Die Moldau", "Smetana"),
        ("In der Halle des Bergkönigs", "Grieg"), ("Die Wassermusik", "Händel"),
        ("die Oper Hänsel und Gretel", "Humperdinck")
    ]

    static func komponist() -> LernAufgabe {
        let (werk, wer) = Lern.eins(werke)
        return Lern.wahl(frage: "Wer hat das komponiert?", rechnung: werk, richtig: wer,
                         falsch: werke.map { $0.1 }, erklaerung: "\(werk): von \(wer).")
    }
}

// MARK: Kunst
// Klasse 1 und 2: Farben, Grundfarben, Formen, Farben mischen
// Klasse 3 und 4: Farbkreis, warme und kalte Farben, Techniken, Künstlerinnen und Künstler

enum LehrplanKunst {
    static var themen: [LernThema] {
        [
            LernThema(id: "ku1-farben", fach: .kunst, titel: "Farben und Grundfarben", emoji: "🖍️",
                      beschreibung: "Rot, Gelb und Blau sind die Grundfarben", klasse: 1, erzeuge: grundfarben),
            LernThema(id: "ku1-formen", fach: .kunst, titel: "Formen", emoji: "🔺",
                      beschreibung: "Kreis, Dreieck, Quadrat und mehr", klasse: 1, erzeuge: formen),
            LernThema(id: "ku2-mischen", fach: .kunst, titel: "Farben mischen", emoji: "🎨",
                      beschreibung: "Aus zwei Farben wird eine neue", klasse: 2,
                      tipp: "Blau und Gelb ergibt Grün. Mit Weiß wird eine Farbe heller.", erzeuge: mischen),
            LernThema(id: "ku3-farbkreis", fach: .kunst, titel: "Farbkreis", emoji: "🌈",
                      beschreibung: "Warme, kalte und Gegenfarben", klasse: 3,
                      tipp: "Gegenfarben liegen sich im Farbkreis gegenüber: Rot und Grün, Blau und Orange, Gelb und Violett.",
                      erzeuge: farbkreis),
            LernThema(id: "ku3-techniken", fach: .kunst, titel: "Techniken und Bildarten", emoji: "✂️",
                      beschreibung: "Collage, Aquarell, Porträt ...", klasse: 3, erzeuge: technik),
            LernThema(id: "ku4-kuenstler", fach: .kunst, titel: "Berühmte Künstler", emoji: "🖼️",
                      beschreibung: "Wer hat das gemacht?", klasse: 4, erzeuge: kuenstler),
            LernThema(id: "ku2-helldunkel", fach: .kunst, titel: "Heller und dunkler", emoji: "🌗",
                      beschreibung: "Farben mit Weiß und Schwarz mischen", klasse: 2, erzeuge: hellDunkel),
            LernThema(id: "ku1-werkzeuge", fach: .kunst, titel: "Malwerkzeuge", emoji: "🖌️",
                      beschreibung: "Pinsel, Schere, Lineal und mehr", klasse: 1, erzeuge: werkzeug),
            LernThema(id: "ku4-bildaufbau", fach: .kunst, titel: "Bildaufbau", emoji: "🏞️",
                      beschreibung: "Vordergrund, Hintergrund und Formate", klasse: 4, erzeuge: bildaufbau)
        ]
    }

    static func hellDunkel() -> LernAufgabe {
        let code = Lern.eins(["rot", "blau", "gruen", "violett", "orange", "braun"])
        let heller = Lern.wahr(0.5)
        return LernAufgabe(art: "wahl", frage: "Womit machst du \(n(code)) \(heller ? "heller" : "dunkler")?",
                           antwort: heller ? "Weiß" : "Schwarz",
                           erklaerung: heller ? "Mit Weiß wird eine Farbe heller." : "Mit Schwarz wird eine Farbe dunkler.",
                           optionen: ["Weiß", "Schwarz"], bild: "farbe:\(code)")
    }

    static let werkzeuge: [(String, String)] = [
        ("🖌️", "Pinsel"), ("✂️", "Schere"), ("🖍️", "Wachsmalstift"), ("✏️", "Bleistift"),
        ("📏", "Lineal"), ("🧽", "Schwamm"), ("🎨", "Farbpalette")
    ]

    static func werkzeug() -> LernAufgabe {
        if Lern.wahr(0.5) {
            let (bild, name) = Lern.eins(werkzeuge)
            return Lern.wahl(frage: "Wie heißt das?", richtig: name, falsch: werkzeuge.map { $0.1 },
                             bild: "emoji:\(bild)", erklaerung: "Das ist ein\(name == "Schere" || name == "Farbpalette" ? "e" : "") \(name).")
        }
        let f = Lern.eins([("Womit schneidest du Papier?", "Schere"), ("Womit malst du mit Wasserfarben?", "Pinsel"),
                           ("Womit ziehst du gerade Linien?", "Lineal"), ("Worauf mischst du Farben?", "Farbpalette"),
                           ("Womit wischst du Farbe vom Tisch?", "Schwamm")])
        return Lern.wahl(frage: f.0, richtig: f.1, falsch: werkzeuge.map { $0.1 }, erklaerung: "Dafür brauchst du: \(f.1).")
    }

    static let aufbauFragen: [(String, String, [String])] = [
        ("Was ganz vorne im Bild ist, liegt im ...", "Vordergrund", ["Hintergrund", "Mittelgrund"]),
        ("Was ganz hinten im Bild ist, liegt im ...", "Hintergrund", ["Vordergrund", "Mittelgrund"]),
        ("Was zwischen vorne und hinten liegt, ist der ...", "Mittelgrund", ["Vordergrund", "Hintergrund"]),
        ("Wie malt man Dinge, die weit weg sind?", "kleiner", ["größer", "genauso groß"]),
        ("Wie wirken Farben in der Ferne oft?", "heller und blasser", ["dunkler und kräftiger", "ganz schwarz"]),
        ("Ein Bild, das breiter als hoch ist, hat ein ...", "Querformat", ["Hochformat", "Rundformat"]),
        ("Ein Bild, das höher als breit ist, hat ein ...", "Hochformat", ["Querformat", "Rundformat"]),
        ("Wo ist bei einem Landschaftsbild meist der Himmel?", "oben", ["unten", "in der Mitte"]),
        ("Die Linie, an der Himmel und Erde sich treffen, heißt ...", "Horizont", ["Rahmen", "Kante"]),
        ("Was ist bei einem Porträt die Hauptsache?", "ein Mensch", ["eine Landschaft", "eine Vase"])
    ]

    static func bildaufbau() -> LernAufgabe {
        let (frage, richtig, falsch) = Lern.eins(aufbauFragen)
        return Lern.wahl(frage: frage, richtig: richtig, falsch: falsch, erklaerung: "Richtig ist: \(richtig).")
    }

    static let farbNamen: [String: String] = ["rot": "Rot", "gelb": "Gelb", "blau": "Blau", "gruen": "Grün",
                                               "orange": "Orange", "violett": "Violett", "braun": "Braun",
                                               "rosa": "Rosa", "schwarz": "Schwarz", "weiss": "Weiß",
                                               "hellblau": "Hellblau", "grau": "Grau", "tuerkis": "Türkis"]

    static func n(_ code: String) -> String { farbNamen[code] ?? code }

    static func grundfarben() -> LernAufgabe {
        let grund = ["Rot", "Gelb", "Blau"]
        let gemischt = ["Grün", "Orange", "Violett", "Braun"]
        switch Lern.z(0...2) {
        case 0:
            return Lern.wahl(frage: "Welche Farbe ist eine Grundfarbe?", richtig: Lern.eins(grund), falsch: gemischt,
                             erklaerung: "Die Grundfarben sind Rot, Gelb und Blau.")
        case 1:
            return Lern.wahl(frage: "Welche Farbe ist keine Grundfarbe?", richtig: Lern.eins(gemischt), falsch: grund,
                             erklaerung: "Die Grundfarben sind Rot, Gelb und Blau. Alle anderen kann man mischen.")
        default:
            let code = Lern.eins(["rot", "gelb", "blau", "gruen", "orange", "violett", "braun", "rosa", "schwarz", "weiss"])
            return Lern.wahl(frage: "Welche Farbe siehst du?", richtig: n(code),
                             falsch: ["Rot", "Gelb", "Blau", "Grün", "Orange", "Violett", "Braun", "Rosa", "Schwarz", "Weiß"],
                             bild: "farbe:\(code)", erklaerung: "Das ist \(n(code)).")
        }
    }

    static func formen() -> LernAufgabe {
        let namen = ["kreis": "Kreis", "dreieck": "Dreieck", "quadrat": "Quadrat", "rechteck": "Rechteck",
                     "oval": "Oval", "stern": "Stern"]
        if Lern.wahr(0.5) {
            let f = Lern.eins(["kreis", "dreieck", "quadrat", "rechteck", "oval", "stern"])
            let name = namen[f] ?? ""
            return Lern.wahl(frage: "Wie heißt die Form?", richtig: name, falsch: Array(namen.values),
                             bild: "form:\(f)", erklaerung: "Das ist ein \(name).")
        }
        let f = Lern.eins([("Wie viele Ecken hat ein Dreieck?", 3, "dreieck"),
                           ("Wie viele Ecken hat ein Quadrat?", 4, "quadrat"),
                           ("Wie viele Ecken hat ein Rechteck?", 4, "rechteck"),
                           ("Wie viele Ecken hat ein Kreis?", 0, "kreis"),
                           ("Wie viele Seiten hat ein Dreieck?", 3, "dreieck"),
                           ("Wie viele Seiten hat ein Quadrat?", 4, "quadrat"),
                           ("Wie viele Zacken hat der Stern?", 5, "stern")])
        return Lern.zahl(f.0, "", f.1, erklaerung: "Richtig sind \(f.1).").mitBild("form:\(f.2)")
    }

    static let mischungen: [(String, String, String)] = [
        ("blau", "gelb", "Grün"), ("rot", "gelb", "Orange"), ("rot", "blau", "Violett"),
        ("rot", "weiss", "Rosa"), ("blau", "weiss", "Hellblau"), ("schwarz", "weiss", "Grau")
    ]

    static func mischen() -> LernAufgabe {
        let m = Lern.eins(mischungen)
        let tausch = Lern.wahr(0.5)
        let a = tausch ? m.1 : m.0
        let b = tausch ? m.0 : m.1
        return Lern.wahl(frage: "Welche Farbe entsteht, wenn du die beiden mischst?", richtig: m.2,
                         falsch: mischungen.map { $0.2 } + ["Braun"], bild: "mischen:\(a)+\(b)",
                         erklaerung: "\(n(a)) und \(n(b)) ergibt \(m.2).")
    }

    static func farbkreis() -> LernAufgabe {
        if Lern.wahr(0.5) {
            let f = Lern.eins([("rot", "warm"), ("orange", "warm"), ("gelb", "warm"),
                               ("blau", "kalt"), ("tuerkis", "kalt"), ("hellblau", "kalt")])
            return LernAufgabe(art: "wahl", frage: "Wirkt diese Farbe warm oder kalt?", antwort: f.1,
                               erklaerung: f.1 == "warm" ? "\(n(f.0)) erinnert an Sonne und Feuer: warm."
                                                         : "\(n(f.0)) erinnert an Wasser und Eis: kalt.",
                               optionen: ["warm", "kalt"], bild: "farbe:\(f.0)")
        }
        let paare = [("Rot", "Grün"), ("Blau", "Orange"), ("Gelb", "Violett")]
        let p = Lern.eins(paare)
        let umgekehrt = Lern.wahr(0.5)
        let von = umgekehrt ? p.1 : p.0
        let zu = umgekehrt ? p.0 : p.1
        return Lern.wahl(frage: "Welche Farbe liegt im Farbkreis gegenüber?", rechnung: von, richtig: zu,
                         falsch: ["Rot", "Grün", "Blau", "Orange", "Gelb", "Violett"].filter { $0 != von },
                         erklaerung: "\(von) und \(zu) sind Gegenfarben.")
    }

    static let techniken: [(String, String)] = [
        ("Collage", "Ein Bild aus aufgeklebten Papierstücken"),
        ("Aquarell", "Ein Bild mit Wasserfarben, die durchscheinen"),
        ("Mosaik", "Ein Bild aus vielen kleinen Steinchen"),
        ("Frottage", "Eine Struktur mit dem Stift durchreiben"),
        ("Druck", "Farbe mit einem Stempel aufs Papier bringen"),
        ("Skulptur", "Eine Figur aus Stein, Holz oder Ton"),
        ("Porträt", "Ein Bild von einem Menschen"),
        ("Selbstporträt", "Ein Bild, auf dem man sich selbst malt"),
        ("Stillleben", "Ein Bild von Dingen wie Obst und Vasen"),
        ("Landschaftsbild", "Ein Bild von Wiesen, Bergen und Himmel")
    ]

    static func technik() -> LernAufgabe {
        let (name, text) = Lern.eins(techniken)
        if Lern.wahr(0.5) {
            return Lern.wahl(frage: "Wie nennt man das?", rechnung: text, richtig: name,
                             falsch: techniken.map { $0.0 }, erklaerung: "\(text): \(name).")
        }
        return Lern.wahl(frage: "Was ist das?", rechnung: name, richtig: text,
                         falsch: techniken.map { $0.1 }, erklaerung: "\(name): \(text).")
    }

    static let kunstwerke: [(String, String)] = [
        ("Wer malte die Mona Lisa?", "Leonardo da Vinci"),
        ("Wer malte die Sonnenblumen und die Sternennacht?", "Vincent van Gogh"),
        ("Wer malte viele Bilder von Seerosen in seinem Garten?", "Claude Monet"),
        ("Wer malte den Feldhasen?", "Albrecht Dürer"),
        ("Wer baute bunte Häuser fast ohne gerade Linien?", "Friedensreich Hundertwasser"),
        ("Wer malte Gesichter gleichzeitig von vorn und von der Seite?", "Pablo Picasso"),
        ("Wer malte bunte Kreise und Linien und dachte dabei an Musik?", "Wassily Kandinsky"),
        ("Wer malte das Bild Burg und Sonne aus bunten Formen?", "Paul Klee"),
        ("Wer malte viele Selbstporträts mit Blumen im Haar?", "Frida Kahlo"),
        ("Wer schnitt für seine Bilder bunte Formen aus Papier aus?", "Henri Matisse"),
        ("Wer malte das goldene Bild Der Kuss?", "Gustav Klimt"),
        ("Wer baute die großen, bunten Frauenfiguren Nanas?", "Niki de Saint Phalle")
    ]

    static func kuenstler() -> LernAufgabe {
        let (frage, wer) = Lern.eins(kunstwerke)
        return Lern.wahl(frage: "Wer war das?", rechnung: frage, richtig: wer, falsch: kunstwerke.map { $0.1 },
                         erklaerung: "Das war \(wer).")
    }
}

extension LernAufgabe {
    func mitBild(_ code: String) -> LernAufgabe {
        var a = self
        a.bild = code
        return a
    }
}
