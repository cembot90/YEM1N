import Foundation

// ============================================================
// MARK: - Lernwelt Deutsch, weitere Themen
// ============================================================
//
// Klasse 1: Wörter lesen, fehlende Buchstaben, große und kleine Buchstaben
// Klasse 2: Satzzeichen, Gegenteile, doppelte Mitlaute, zusammengesetzte Nomen
// Klasse 3: Satzarten, ä und äu ableiten, s, ss oder ß, Wortfamilien, Wortfelder, Steigern
// Klasse 4: Subjekt und Prädikat, Pronomen, Wörter trennen, Wortarten
// Jede Liste ist so gewählt, dass es genau eine richtige Antwort gibt.
// Wörter, bei denen auch eine andere Schreibung ein echtes Wort wäre (Wende und Wände,
// Rassen und Rasen, Geste und Gäste), stehen bewusst nicht drin.

enum LehrplanDeutschMehr {
    typealias A = LernAufgabe

    static var themen: [LernThema] {
        [
            LernThema(id: "d1-lesen", fach: .deutsch, titel: "Wörter lesen", emoji: "👀",
                      beschreibung: "Welches Bild passt zum Wort?", klasse: 1, erzeuge: { woerterLesen() }),
            LernThema(id: "d1-luecke", fach: .deutsch, titel: "Welcher Buchstabe fehlt?", emoji: "🔍",
                      beschreibung: "a, e, i, o oder u?", klasse: 1,
                      tipp: "Hör dir das Wort an und sprich es langsam mit.", erzeuge: { vokalLuecke() }),
            LernThema(id: "d1-buchstaben", fach: .deutsch, titel: "Groß und klein", emoji: "🔡",
                      beschreibung: "A und a gehören zusammen", klasse: 1, erzeuge: { buchstabenPaare() }),
            LernThema(id: "d2-satzzeichen", fach: .deutsch, titel: "Punkt, Fragezeichen, Ausrufezeichen", emoji: "❗",
                      beschreibung: "Welches Zeichen kommt ans Ende?", klasse: 2,
                      tipp: "Fragen enden mit ?, Ausrufe und Aufforderungen mit !, alle anderen Sätze mit einem Punkt.",
                      erzeuge: { satzzeichen() }),
            LernThema(id: "d2-gegenteil", fach: .deutsch, titel: "Gegenteile", emoji: "🔄",
                      beschreibung: "groß und klein, hell und dunkel", klasse: 2, erzeuge: { gegenteil() }),
            LernThema(id: "d2-doppelt", fach: .deutsch, titel: "Doppelte Mitlaute", emoji: "👥",
                      beschreibung: "Sonne mit nn, Hose mit s", klasse: 2,
                      tipp: "Klingt der Selbstlaut davor kurz, kommt oft ein doppelter Mitlaut: Sonne. Klingt er lang, nur einer: Hose.",
                      erzeuge: { doppelt() }),
            LernThema(id: "d2-zusammen", fach: .deutsch, titel: "Zusammengesetzte Nomen", emoji: "🔗",
                      beschreibung: "Haus + Tür = Haustür", klasse: 2,
                      tipp: "Das letzte Wort bestimmt den Artikel: die Tür, also die Haustür.", erzeuge: { zusammengesetzt() }),
            LernThema(id: "d3-satzarten", fach: .deutsch, titel: "Satzarten", emoji: "💬",
                      beschreibung: "Aussage, Frage oder Aufforderung?", klasse: 3, erzeuge: { satzart() }),
            LernThema(id: "d3-ableiten", fach: .deutsch, titel: "ä oder e, äu oder eu?", emoji: "🌳",
                      beschreibung: "Ableiten: Baum, also Bäume", klasse: 3,
                      tipp: "Suche ein verwandtes Wort mit a oder au: Hände kommt von Hand.", erzeuge: { ableiten() }),
            LernThema(id: "d3-sss", fach: .deutsch, titel: "s, ss oder ß?", emoji: "🐍",
                      beschreibung: "Fuß, Fluss und Hase", klasse: 3,
                      tipp: "Nach kurzem Selbstlaut ss: Fluss. Nach langem Selbstlaut oder ei, au ß: Fuß, heiß. Weich gesprochen s: Hase.",
                      erzeuge: { sss() }),
            LernThema(id: "d3-wortfamilie", fach: .deutsch, titel: "Wortfamilien", emoji: "👨‍👩‍👧‍👦",
                      beschreibung: "Welches Wort gehört nicht dazu?", klasse: 3,
                      tipp: "Wörter einer Familie haben den gleichen Wortstamm: fahren, Fahrer, Fahrrad.", erzeuge: { wortfamilie() }),
            LernThema(id: "d3-wortfeld", fach: .deutsch, titel: "Wortfelder", emoji: "🌾",
                      beschreibung: "Andere Wörter für sagen, gehen, sehen", klasse: 3, erzeuge: { wortfeld() }),
            LernThema(id: "d3-steigern", fach: .deutsch, titel: "Adjektive steigern", emoji: "📈",
                      beschreibung: "groß, größer, am größten", klasse: 3, erzeuge: { steigern() }),
            LernThema(id: "d4-satzglieder", fach: .deutsch, titel: "Subjekt und Prädikat", emoji: "🧱",
                      beschreibung: "Wer tut etwas? Was tut er?", klasse: 4,
                      tipp: "Das Subjekt findest du mit Wer oder was?, das Prädikat mit Was tut er?", erzeuge: { satzglied() }),
            LernThema(id: "d4-pronomen", fach: .deutsch, titel: "Pronomen", emoji: "👉",
                      beschreibung: "er, sie, es, wir statt Nomen", klasse: 4, erzeuge: { pronomen() }),
            LernThema(id: "d4-trennen", fach: .deutsch, titel: "Wörter trennen", emoji: "✂️",
                      beschreibung: "Nach Silben trennen", klasse: 4,
                      tipp: "Trenne nach Sprechsilben. ck bleibt zusammen: Zu-cker. Zwei gleiche Mitlaute werden getrennt: Was-ser.",
                      erzeuge: { trennen() }),
            LernThema(id: "d4-wortarten", fach: .deutsch, titel: "Alle Wortarten", emoji: "🗂️",
                      beschreibung: "Auch Artikel, Pronomen und Präpositionen", klasse: 4, erzeuge: { wortartenAlle() })
        ]
    }

    // MARK: Klasse 1

    static func woerterLesen() -> A {
        let (bild, wort) = Lern.eins(LehrplanDeutsch.anlaute)
        return Lern.wahl(frage: "Lies das Wort. Welches Bild passt?", rechnung: wort, richtig: bild,
                         falsch: LehrplanDeutsch.anlaute.map { $0.0 }, erklaerung: "\(wort): \(bild)")
    }

    static let vokale: [Character] = ["a", "e", "i", "o", "u"]

    /// Stellen im Wort mit einem einzelnen Selbstlaut, nicht ei, au, ie oder Ähnliches
    static func vokalStellen(_ wort: String) -> [Int] {
        let z = Array(wort)
        var stellen: [Int] = []
        for i in 1..<z.count where vokale.contains(z[i]) {
            let davor = i > 0 && vokale.contains(Character(z[i - 1].lowercased()))
            let danach = i + 1 < z.count && vokale.contains(z[i + 1])
            if !davor && !danach { stellen.append(i) }
        }
        return stellen
    }

    static func vokalLuecke() -> A {
        var eintrag = Lern.eins(LehrplanDeutsch.anlaute)
        while vokalStellen(eintrag.1).isEmpty { eintrag = Lern.eins(LehrplanDeutsch.anlaute) }
        let (bild, wort) = eintrag
        let i = Lern.eins(vokalStellen(wort))
        var z = Array(wort)
        let richtig = String(z[i])
        z[i] = "?"
        return Lern.wahl(frage: "Welcher Buchstabe fehlt?", rechnung: String(z), richtig: richtig,
                         falsch: vokale.map(String.init), bild: "wort:\(bild)|\(wort)",
                         erklaerung: "Richtig geschrieben: \(wort)")
    }

    /// Buchstaben, die leicht verwechselt werden
    static let aehnlich: [String: [String]] = [
        "a": ["o", "e"], "b": ["d", "p"], "c": ["e", "o"], "d": ["b", "q"], "e": ["a", "c"], "f": ["t", "k"],
        "g": ["q", "j"], "h": ["n", "k"], "i": ["l", "j"], "j": ["i", "g"], "k": ["h", "x"], "l": ["i", "t"],
        "m": ["n", "w"], "n": ["m", "h"], "o": ["a", "c"], "p": ["q", "b"], "q": ["p", "g"], "r": ["n", "v"],
        "s": ["z", "c"], "t": ["f", "l"], "u": ["n", "v"], "v": ["w", "u"], "w": ["m", "v"], "x": ["k", "z"],
        "y": ["v", "j"], "z": ["s", "x"]
    ]

    static func buchstabenPaare() -> A {
        let klein = Lern.eins(Array(aehnlich.keys))
        let gross = klein.uppercased()
        let falsch = aehnlich[klein] ?? []
        if Lern.wahr(0.5) {
            return Lern.wahl(frage: "Welcher kleine Buchstabe gehört zu diesem großen?", rechnung: gross,
                             richtig: klein, falsch: falsch, erklaerung: "\(gross) und \(klein) gehören zusammen.")
        }
        return Lern.wahl(frage: "Welcher große Buchstabe gehört zu diesem kleinen?", rechnung: klein,
                         richtig: gross, falsch: falsch.map { $0.uppercased() },
                         erklaerung: "\(klein) und \(gross) gehören zusammen.")
    }

    // MARK: Klasse 2

    static let saetzeOhneZeichen: [(String, String)] = [
        ("Wie heißt du", "?"), ("Ich gehe in die Schule", "."), ("Pass auf", "!"), ("Hast du einen Hund", "?"),
        ("Der Ball ist rot", "."), ("Komm schnell her", "!"), ("Wo wohnst du", "?"), ("Heute scheint die Sonne", "."),
        ("Magst du Eis", "?"), ("Mia malt ein Bild", "."), ("Sei bitte leise", "!"), ("Wann beginnt die Pause", "?"),
        ("Mein Bruder ist sieben Jahre alt", "."), ("Kannst du schwimmen", "?"), ("Wir spielen im Garten", "."),
        ("Räum bitte dein Zimmer auf", "!"), ("Was isst du gern", "?"), ("Die Katze schläft auf dem Sofa", "."),
        ("Halt, stopp", "!"), ("Gib mir bitte den Stift", "!")
    ]

    static func satzzeichen() -> A {
        let (satz, zeichen) = Lern.eins(saetzeOhneZeichen)
        let namen = [".": "Punkt", "?": "Fragezeichen", "!": "Ausrufezeichen"]
        return LernAufgabe(art: "wahl", frage: "Welches Zeichen gehört ans Ende?", rechnung: satz + " ___",
                           antwort: zeichen, erklaerung: "\(satz)\(zeichen) Hier gehört ein \(namen[zeichen] ?? "") hin.",
                           optionen: [".", "?", "!"])
    }

    static let gegenteile: [(String, String)] = [
        ("groß", "klein"), ("hell", "dunkel"), ("laut", "leise"), ("schnell", "langsam"), ("warm", "kalt"),
        ("nass", "trocken"), ("hart", "weich"), ("dick", "dünn"), ("lang", "kurz"), ("voll", "leer"),
        ("schwer", "leicht"), ("süß", "sauer"), ("früh", "spät"), ("oben", "unten"), ("fröhlich", "traurig"),
        ("viel", "wenig"), ("hoch", "tief"), ("sauber", "schmutzig")
    ]

    static func gegenteil() -> A {
        let p = Lern.eins(gegenteile)
        let umgekehrt = Lern.wahr(0.5)
        let wort = umgekehrt ? p.1 : p.0
        let richtig = umgekehrt ? p.0 : p.1
        let falsch = gegenteile.flatMap { [$0.0, $0.1] }.filter { $0 != wort && $0 != richtig }
        return Lern.wahl(frage: "Was ist das Gegenteil?", rechnung: wort, richtig: richtig, falsch: falsch,
                         erklaerung: "Das Gegenteil von \(wort) ist \(richtig).")
    }

    /// Lückenwort, einfacher Mitlaut, doppelter Mitlaut, richtig, ganzes Wort
    static let doppeltWoerter: [(String, String, String, String, String)] = [
        ("So?e", "n", "nn", "nn", "Sonne"), ("Ka?e", "n", "nn", "nn", "Kanne"), ("Pu?e", "p", "pp", "pp", "Puppe"),
        ("Su?e", "p", "pp", "pp", "Suppe"), ("Te?er", "l", "ll", "ll", "Teller"), ("Mu?er", "t", "tt", "tt", "Mutter"),
        ("Bu?er", "t", "tt", "tt", "Butter"), ("Wa?er", "s", "ss", "ss", "Wasser"), ("Ta?e", "s", "ss", "ss", "Tasse"),
        ("Hi?el", "m", "mm", "mm", "Himmel"), ("Zi?er", "m", "mm", "mm", "Zimmer"), ("Ko?er", "f", "ff", "ff", "Koffer"),
        ("A?e", "f", "ff", "ff", "Affe"), ("Bri?e", "l", "ll", "ll", "Brille"), ("So?er", "m", "mm", "mm", "Sommer"),
        ("Ha?e", "s", "ss", "s", "Hase"), ("Ho?e", "s", "ss", "s", "Hose"), ("Ta?el", "f", "ff", "f", "Tafel"),
        ("O?en", "f", "ff", "f", "Ofen"), ("To?ate", "m", "mm", "m", "Tomate"), ("Ga?el", "b", "bb", "b", "Gabel"),
        ("E?el", "s", "ss", "s", "Esel"), ("Ki?o", "n", "nn", "n", "Kino"), ("Na?e", "s", "ss", "s", "Nase")
    ]

    static func doppelt() -> A {
        let (luecke, einfach, doppel, richtig, ganz) = Lern.eins(doppeltWoerter)
        let kurz = richtig == doppel
        return LernAufgabe(art: "wahl", frage: "Ein Mitlaut oder zwei?", rechnung: luecke, antwort: richtig,
                           erklaerung: kurz ? "\(ganz): Der Selbstlaut davor klingt kurz." : "\(ganz): Der Selbstlaut davor klingt lang.",
                           optionen: [einfach, doppel])
    }

    /// Erstes Wort, zweites Wort, zusammengesetztes Wort, Artikel
    static let komposita: [(String, String, String, String)] = [
        ("Haus", "Tür", "Haustür", "die"), ("Schnee", "Mann", "Schneemann", "der"), ("Apfel", "Baum", "Apfelbaum", "der"),
        ("Sonne", "Blume", "Sonnenblume", "die"), ("Hand", "Schuh", "Handschuh", "der"), ("Fuß", "Ball", "Fußball", "der"),
        ("Zahn", "Bürste", "Zahnbürste", "die"), ("Blume", "Topf", "Blumentopf", "der"), ("Regen", "Schirm", "Regenschirm", "der"),
        ("Bett", "Decke", "Bettdecke", "die"), ("Wasser", "Glas", "Wasserglas", "das"), ("Spiel", "Zeug", "Spielzeug", "das"),
        ("Eis", "Bär", "Eisbär", "der"), ("Tisch", "Decke", "Tischdecke", "die"), ("Schule", "Tasche", "Schultasche", "die"),
        ("Garten", "Haus", "Gartenhaus", "das"), ("Kinder", "Zimmer", "Kinderzimmer", "das"), ("Auto", "Bahn", "Autobahn", "die"),
        ("Feuer", "Wehr", "Feuerwehr", "die"), ("Buch", "Seite", "Buchseite", "die")
    ]

    static func zusammengesetzt() -> A {
        let (a, b, ganz, artikel) = Lern.eins(komposita)
        return LernAufgabe(art: "wahl", frage: "Welcher Artikel passt zum neuen Wort?", rechnung: "\(a) + \(b) = \(ganz)",
                           antwort: artikel, erklaerung: "Das letzte Wort bestimmt den Artikel: \(artikel) \(b), also \(artikel) \(ganz).",
                           optionen: ["der", "die", "das"])
    }

    // MARK: Klasse 3

    static let satzartListe: [(String, String)] = [
        ("Der Hund schläft im Körbchen.", "Aussagesatz"), ("Heute regnet es.", "Aussagesatz"),
        ("Ich habe zwei Schwestern.", "Aussagesatz"), ("Im Sommer fahren wir ans Meer.", "Aussagesatz"),
        ("Wann beginnt die Pause?", "Fragesatz"), ("Hast du deine Hausaufgaben gemacht?", "Fragesatz"),
        ("Wie spät ist es?", "Fragesatz"), ("Kommst du morgen mit?", "Fragesatz"),
        ("Komm bitte her!", "Aufforderungssatz"), ("Mach das Fenster zu!", "Aufforderungssatz"),
        ("Hör mir bitte zu!", "Aufforderungssatz"), ("Räum deine Sachen auf!", "Aufforderungssatz"),
        ("Wo ist mein Turnbeutel?", "Fragesatz"), ("Die Blumen blühen schon.", "Aussagesatz"),
        ("Gib mir bitte das Salz!", "Aufforderungssatz")
    ]

    static func satzart() -> A {
        let (satz, art) = Lern.eins(satzartListe)
        return LernAufgabe(art: "wahl", frage: "Welche Satzart ist das?", rechnung: satz, antwort: art,
                           erklaerung: "„\(satz)“ ist ein \(art).",
                           optionen: ["Aussagesatz", "Fragesatz", "Aufforderungssatz"])
    }

    /// Lückenwort, richtig, falsch, verwandtes Wort oder Hinweis
    static let ableitWoerter: [(String, String, String, String)] = [
        ("B?me", "äu", "eu", "der Baum"), ("H?ser", "äu", "eu", "das Haus"), ("tr?men", "äu", "eu", "der Traum"),
        ("M?se", "äu", "eu", "die Maus"), ("Z?ne", "äu", "eu", "der Zaun"), ("R?ber", "äu", "eu", "der Raub"),
        ("h?te", "eu", "äu", "Es gibt kein verwandtes Wort mit au."),
        ("F?er", "eu", "äu", "Es gibt kein verwandtes Wort mit au."),
        ("Fr?nd", "eu", "äu", "Es gibt kein verwandtes Wort mit au."),
        ("t?er", "eu", "äu", "Es gibt kein verwandtes Wort mit au."),
        ("Kr?z", "eu", "äu", "Es gibt kein verwandtes Wort mit au."),
        ("H?nde", "ä", "e", "die Hand"), ("z?hlen", "ä", "e", "die Zahl"), ("B?cker", "ä", "e", "backen"),
        ("Bl?tter", "ä", "e", "das Blatt"), ("D?cher", "ä", "e", "das Dach"), ("st?rker", "ä", "e", "stark"),
        ("F?lder", "e", "ä", "das Feld"), ("N?st", "e", "ä", "Es gibt kein verwandtes Wort mit a."),
        ("B?tt", "e", "ä", "Es gibt kein verwandtes Wort mit a."), ("l?ben", "e", "ä", "Es gibt kein verwandtes Wort mit a.")
    ]

    static func ableiten() -> A {
        let (luecke, richtig, falsch, hilfe) = Lern.eins(ableitWoerter)
        let ganz = luecke.replacingOccurrences(of: "?", with: richtig)
        let erklaerung = hilfe.hasPrefix("Es gibt") ? "\(ganz). \(hilfe) Darum \(richtig)." : "\(ganz) kommt von \(hilfe)."
        return LernAufgabe(art: "wahl", frage: "Welche Buchstaben fehlen?", rechnung: luecke, antwort: richtig,
                           erklaerung: erklaerung, optionen: [richtig, falsch].sorted())
    }

    /// Lückenwort, richtig, Begründung
    static let sssWoerter: [(String, String, String)] = [
        ("Fu?", "ß", "der Fuß: das u klingt lang."), ("Flu?", "ss", "der Fluss: das u klingt kurz."),
        ("Ha?e", "s", "der Hase: das s klingt weich."), ("Gru?", "ß", "der Gruß: das u klingt lang."),
        ("Ku?", "ss", "der Kuss: das u klingt kurz."), ("Stra?e", "ß", "die Straße: das a klingt lang."),
        ("Wa?er", "ss", "das Wasser: das a klingt kurz."), ("Ta?e", "ss", "die Tasse: das a klingt kurz."),
        ("drau?en", "ß", "draußen: nach au kommt ß."), ("Spa?", "ß", "der Spaß: das a klingt lang."),
        ("Na?e", "s", "die Nase: das s klingt weich."), ("Me?er", "ss", "das Messer: das e klingt kurz."),
        ("Klö?e", "ß", "die Klöße: das ö klingt lang."), ("gro?", "ß", "groß: das o klingt lang."),
        ("Schlo?", "ss", "das Schloss: das o klingt kurz."), ("hei?", "ß", "heiß: nach ei kommt ß."),
        ("Glä?er", "s", "die Gläser: das s klingt weich."), ("wei?", "ß", "weiß: nach ei kommt ß."),
        ("Gra?", "s", "das Gras: verlängere zu die Gräser, dann hörst du ein weiches s.")
    ]

    static func sss() -> A {
        let (luecke, richtig, warum) = Lern.eins(sssWoerter)
        return LernAufgabe(art: "wahl", frage: "s, ss oder ß?", rechnung: luecke, antwort: richtig,
                           erklaerung: warum, optionen: ["s", "ss", "ß"])
    }

    /// Stamm, drei Wörter der Familie
    static let familien: [(String, [String])] = [
        ("fahren", ["Fahrrad", "Fahrer", "Fahrt"]), ("spielen", ["Spielplatz", "Spieler", "Spielzeug"]),
        ("Haus", ["Häuschen", "Hausaufgabe", "Haustür"]), ("backen", ["Bäcker", "Backofen", "Gebäck"]),
        ("schlafen", ["Schlafanzug", "schläfrig", "Schlafzimmer"]), ("lesen", ["Leser", "Lesebuch", "Lesezeichen"]),
        ("fliegen", ["Flieger", "Flugzeug", "Flughafen"]), ("trinken", ["Getränk", "Trinkflasche", "Trinkhalm"]),
        ("rechnen", ["Rechnung", "Rechenheft", "Rechner"]), ("malen", ["Maler", "Malkasten", "Gemälde"])
    ]

    static func wortfamilie() -> A {
        let i = Lern.z(0...(familien.count - 1))
        var j = Lern.z(0...(familien.count - 1))
        while j == i { j = Lern.z(0...(familien.count - 1)) }
        let (stamm, woerter) = familien[i]
        let fremd = Lern.eins(familien[j].1)
        return LernAufgabe(art: "wahl", frage: "Welches Wort gehört nicht zur Wortfamilie \(stamm)?",
                           antwort: fremd,
                           erklaerung: "\(fremd) gehört zu \(familien[j].0). Die anderen kommen von \(stamm).",
                           optionen: (woerter + [fremd]).shuffled())
    }

    static let wortfelder: [(String, [String])] = [
        ("sagen", ["flüstern", "rufen", "schreien", "erzählen", "antworten", "murmeln", "brüllen"]),
        ("gehen", ["rennen", "schleichen", "hüpfen", "wandern", "spazieren", "stolpern", "schlendern"]),
        ("sehen", ["schauen", "gucken", "beobachten", "betrachten", "starren", "blicken"])
    ]

    static func wortfeld() -> A {
        let i = Lern.z(0...2)
        let (feld, woerter) = wortfelder[i]
        let richtig = Lern.eins(woerter)
        let falsch = wortfelder.enumerated().filter { $0.offset != i }.flatMap { $0.element.1 }
        return Lern.wahl(frage: "Welches Wort gehört zum Wortfeld \(feld)?", richtig: richtig, falsch: falsch,
                         erklaerung: "\(richtig) ist eine Art zu \(feld).")
    }

    /// Grundform, Vergleichsform, Höchstform
    static let steigerung: [(String, String, String)] = [
        ("klein", "kleiner", "am kleinsten"), ("groß", "größer", "am größten"), ("schnell", "schneller", "am schnellsten"),
        ("alt", "älter", "am ältesten"), ("jung", "jünger", "am jüngsten"), ("lang", "länger", "am längsten"),
        ("kurz", "kürzer", "am kürzesten"), ("warm", "wärmer", "am wärmsten"), ("kalt", "kälter", "am kältesten"),
        ("hoch", "höher", "am höchsten"), ("gut", "besser", "am besten"), ("viel", "mehr", "am meisten"),
        ("laut", "lauter", "am lautesten"), ("schön", "schöner", "am schönsten"), ("stark", "stärker", "am stärksten"),
        ("hell", "heller", "am hellsten"), ("süß", "süßer", "am süßesten"), ("nah", "näher", "am nächsten")
    ]

    static func steigern() -> A {
        let (grund, mehr, meist) = Lern.eins(steigerung)
        if Lern.wahr(0.5) {
            return Lern.wahl(frage: "Wie heißt die Vergleichsform?", rechnung: "\(grund), ?",
                             richtig: mehr, falsch: [grund + "er", "mehr " + grund, grund + "ster"],
                             erklaerung: "\(grund), \(mehr), \(meist)")
        }
        return Lern.wahl(frage: "Wie heißt die Höchstform?", rechnung: "\(grund), \(mehr), ?",
                         richtig: meist, falsch: ["am " + grund + "sten", "am " + mehr + "sten", "am meisten " + grund],
                         erklaerung: "\(grund), \(mehr), \(meist)")
    }

    // MARK: Klasse 4

    /// Satz, Subjekt, Prädikat. Das Subjekt ist hier immer ein einzelnes Wort.
    static let gliederSaetze: [(String, String, String)] = [
        ("Ben spielt Fußball.", "Ben", "spielt"), ("Mia liest ein Buch.", "Mia", "liest"),
        ("Tom isst einen Apfel.", "Tom", "isst"), ("Wir singen ein Lied.", "Wir", "singen"),
        ("Lena malt ein Bild.", "Lena", "malt"), ("Ali baut eine Burg.", "Ali", "baut"),
        ("Jonas fährt Fahrrad.", "Jonas", "fährt"), ("Ida schreibt einen Brief.", "Ida", "schreibt"),
        ("Emil wirft den Ball.", "Emil", "wirft"), ("Nele kocht Suppe.", "Nele", "kocht"),
        ("Sara füttert die Hasen.", "Sara", "füttert"), ("Opa erzählt eine Geschichte.", "Opa", "erzählt"),
        ("Morgen besucht Jule ihre Oma.", "Jule", "besucht"), ("Im Garten spielt Luis.", "Luis", "spielt")
    ]

    static func woerter(_ satz: String) -> [String] {
        var liste: [String] = []
        for w in satz.split(separator: " ").map({ $0.trimmingCharacters(in: CharacterSet(charactersIn: ".!?,")) })
        where !w.isEmpty && !liste.contains(w) {
            liste.append(w)
        }
        return liste
    }

    static func satzglied() -> A {
        let (satz, subjekt, praedikat) = Lern.eins(gliederSaetze)
        let teile = woerter(satz)
        if Lern.wahr(0.5) {
            return LernAufgabe(art: "wahl", frage: "Welches Wort ist das Subjekt? Frag: Wer oder was?", rechnung: satz,
                               antwort: subjekt, erklaerung: "Wer \(praedikat)? \(subjekt). Das ist das Subjekt.",
                               optionen: teile)
        }
        return LernAufgabe(art: "wahl", frage: "Welches Wort ist das Prädikat? Frag: Was tut jemand?", rechnung: satz,
                           antwort: praedikat, erklaerung: "Was tut \(subjekt)? \(subjekt) \(praedikat). Das ist das Prädikat.",
                           optionen: teile)
    }

    static let pronomenSaetze: [(String, String, String)] = [
        ("Tom spielt.", "___ spielt Fußball.", "Er"), ("Das Pferd läuft.", "___ ist schnell.", "Es"),
        ("Mia und Ben lachen.", "___ sind froh.", "Sie"), ("Der Hund bellt.", "___ ist laut.", "Er"),
        ("Die Blume blüht.", "___ ist rot.", "Sie"), ("Das Baby schläft.", "___ ist müde.", "Es"),
        ("Ali und ich spielen.", "___ haben Spaß.", "Wir"), ("Die Kinder rennen.", "___ sind schnell.", "Sie"),
        ("Der Ball rollt.", "___ ist rund.", "Er"), ("Das Auto ist neu.", "___ glänzt.", "Es"),
        ("Oma backt.", "___ backt einen Kuchen.", "Sie"), ("Mein Bruder und ich lesen.", "___ lesen ein Buch.", "Wir")
    ]

    static func pronomen() -> A {
        let (eins, zwei, richtig) = Lern.eins(pronomenSaetze)
        return LernAufgabe(art: "wahl", frage: "Welches Pronomen passt?", rechnung: "\(eins)\n\(zwei)",
                           antwort: richtig, erklaerung: "\(eins) \(zwei.replacingOccurrences(of: "___", with: richtig))",
                           optionen: ["Er", "Sie", "Es", "Wir"])
    }

    /// Richtig getrennt, mit Bindestrich
    static let trennWoerter = [
        "Fens-ter", "Schwes-ter", "Ham-mer", "Kat-ze", "Zu-cker", "Was-ser", "Blu-men", "Kis-te", "Mon-tag",
        "Ta-fel", "Gar-ten", "Wol-ke", "Ap-fel", "Kin-der", "Te-le-fon", "Ba-na-ne", "Ka-rot-te", "Hand-schuh",
        "Pin-sel", "Tel-ler", "Fahr-rad", "Mut-ter"
    ]

    /// Falsche Trennungen: ein Strich rutscht um einen Buchstaben nach links oder rechts
    static func falscheTrennungen(_ richtig: String) -> [String] {
        let wort = richtig.replacingOccurrences(of: "-", with: "")
        var stellen: [Int] = []
        var i = 0
        for ch in richtig {
            if ch == "-" { stellen.append(i) } else { i += 1 }
        }
        var ergebnis: [String] = []
        for (k, s) in stellen.enumerated() {
            for d in [-1, 1] {
                var neu = stellen
                neu[k] = s + d
                guard neu.allSatisfy({ $0 >= 1 && $0 < wort.count }), Set(neu).count == neu.count,
                      neu == neu.sorted() else { continue }
                var z = Array(wort)
                for p in neu.sorted(by: >) { z.insert("-", at: p) }
                let text = String(z)
                if text != richtig && !ergebnis.contains(text) { ergebnis.append(text) }
            }
        }
        return ergebnis
    }

    static func trennen() -> A {
        let richtig = Lern.eins(trennWoerter)
        let wort = richtig.replacingOccurrences(of: "-", with: "")
        return Lern.wahl(frage: "Wie trennt man das Wort richtig?", rechnung: wort, richtig: richtig,
                         falsch: falscheTrennungen(richtig), erklaerung: "Richtig getrennt: \(richtig)")
    }

    static let artikelWoerter = ["der", "die", "das", "ein", "eine"]
    static let pronomenWoerter = ["ich", "du", "er", "sie", "es", "wir", "ihr"]
    static let praepositionen = ["auf", "unter", "neben", "hinter", "vor", "in", "über", "zwischen", "mit"]

    static func wortartenAlle() -> A {
        let arten = ["Nomen", "Verb", "Adjektiv", "Artikel", "Pronomen", "Präposition"]
        let wahl = Lern.z(0...5)
        let wort: String
        switch wahl {
        case 0: wort = Lern.eins(LehrplanDeutsch.nomen).wort
        case 1: wort = Lern.eins(LehrplanDeutsch.verben).infinitiv
        case 2: wort = Lern.eins(LehrplanDeutsch.adjektive)
        case 3: wort = Lern.eins(artikelWoerter)
        case 4: wort = Lern.eins(pronomenWoerter)
        default: wort = Lern.eins(praepositionen)
        }
        // "die" und "sie" können auch anders gebraucht werden, hier sind sie eindeutig zugeordnet
        return Lern.wahl(frage: "Welche Wortart ist das?", rechnung: wort, richtig: arten[wahl], falsch: arten,
                         anzahl: 4, erklaerung: "\(wort) ist ein\(arten[wahl] == "Präposition" ? "e" : "") \(arten[wahl]).")
    }
}
