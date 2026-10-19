import Foundation

// ============================================================
// MARK: - Lernwelt Deutsch, Klasse 1 bis 4
// ============================================================
//
// Klasse 1: Anlaute, Silben, Reimwörter
// Klasse 2: der, die, das, Einzahl und Mehrzahl, ABC, Groß oder klein
// Klasse 3: Wortarten, Vergangenheit, Verlängern (d oder t), i oder ie
// Klasse 4: Die vier Fälle, das oder dass, Zeitformen
// Die Wörter kommen aus dem Grundwortschatz der Grundschule. Jedes Wort hier ist eindeutig:
// keine Wörter mit zwei möglichen Artikeln oder zwei richtigen Mehrzahlformen.

enum LehrplanDeutsch {
    typealias A = LernAufgabe

    static var themen: [LernThema] {
        [
            LernThema(id: "d1-anlaut", fach: .deutsch, titel: "Anlaute", emoji: "🍎",
                      beschreibung: "Mit welchem Buchstaben fängt das Wort an?", klasse: 1,
                      tipp: "Sprich das Wort langsam und hör auf den ersten Laut.", erzeuge: { anlaut() }),
            LernThema(id: "d1-silben", fach: .deutsch, titel: "Silben klatschen", emoji: "👏",
                      beschreibung: "Wie viele Silben hat das Wort?", klasse: 1,
                      tipp: "Sprich das Wort und klatsche bei jeder Silbe.", erzeuge: { silben() }),
            LernThema(id: "d1-reime", fach: .deutsch, titel: "Reimwörter", emoji: "🎶",
                      beschreibung: "Was reimt sich?", klasse: 1,
                      tipp: "Wörter reimen sich, wenn sie am Ende gleich klingen: Haus und Maus.", erzeuge: { reim() }),
            LernThema(id: "d2-artikel", fach: .deutsch, titel: "der, die oder das", emoji: "🏷️",
                      beschreibung: "Den richtigen Artikel finden", klasse: 2, erzeuge: { artikel() }),
            LernThema(id: "d2-mehrzahl", fach: .deutsch, titel: "Einzahl und Mehrzahl", emoji: "👯",
                      beschreibung: "Ein Hund, viele Hunde", klasse: 2, erzeuge: { mehrzahl() }),
            LernThema(id: "d2-abc", fach: .deutsch, titel: "Das ABC", emoji: "🔤",
                      beschreibung: "Buchstaben und Wörter ordnen", klasse: 2, erzeuge: { abc() }),
            LernThema(id: "d2-gross", fach: .deutsch, titel: "Groß oder klein?", emoji: "🔠",
                      beschreibung: "Nomen schreibt man groß", klasse: 2,
                      tipp: "Kannst du der, die oder das davor sagen, schreibst du das Wort groß.", erzeuge: { gross() }),
            LernThema(id: "d3-wortarten", fach: .deutsch, titel: "Wortarten", emoji: "🧩",
                      beschreibung: "Nomen, Verb oder Adjektiv?", klasse: 3,
                      tipp: "Nomen: der, die, das. Verb: ich ... Adjektiv: wie ist etwas?", erzeuge: { wortart() }),
            LernThema(id: "d3-vergangen", fach: .deutsch, titel: "Vergangenheit", emoji: "⏪",
                      beschreibung: "Was gestern war: er ging, sie lachte", klasse: 3, erzeuge: { vergangenheit() }),
            LernThema(id: "d3-verlaengern", fach: .deutsch, titel: "Verlängern: d oder t?", emoji: "↔️",
                      beschreibung: "Auch g oder k, b oder p", klasse: 3,
                      tipp: "Verlängere das Wort: Hund, die Hunde. Jetzt hörst du das d.", erzeuge: { verlaengern() }),
            LernThema(id: "d3-ie", fach: .deutsch, titel: "i oder ie?", emoji: "🐝",
                      beschreibung: "Lang oder kurz gesprochen", klasse: 3,
                      tipp: "Klingt das i lang, schreibst du meistens ie: Biene. Klingt es kurz, nur i: Kind.",
                      erzeuge: { ieOderI() }),
            LernThema(id: "d4-faelle", fach: .deutsch, titel: "Die vier Fälle", emoji: "❓",
                      beschreibung: "Wer, wessen, wem, wen?", klasse: 4,
                      tipp: "Frag nach dem Wort: Wer oder was? Wessen? Wem? Wen oder was?", erzeuge: { faelle() }),
            LernThema(id: "d4-dass", fach: .deutsch, titel: "das oder dass?", emoji: "🤔",
                      beschreibung: "Mit einem oder zwei s", klasse: 4,
                      tipp: "Kannst du dieses, jenes oder welches einsetzen, schreibst du das.", erzeuge: { dasDass() }),
            LernThema(id: "d4-zeitformen", fach: .deutsch, titel: "Zeitformen", emoji: "🕰️",
                      beschreibung: "Präsens, Präteritum, Perfekt, Futur", klasse: 4, erzeuge: { zeitform() })
        ]
    }

    // MARK: Wortlisten

    /// Bild, Wort. Nur Wörter, die mit einem einfachen Laut anfangen (kein Sch, Ei, Pf, Qu, St).
    static let anlaute: [(String, String)] = [
        ("🍎", "Apfel"), ("🐒", "Affe"), ("🚗", "Auto"), ("⚽", "Ball"), ("🍌", "Banane"), ("🐻", "Bär"),
        ("🐝", "Biene"), ("📕", "Buch"), ("🦆", "Ente"), ("🐘", "Elefant"), ("🐟", "Fisch"), ("🦊", "Fuchs"),
        ("🐸", "Frosch"), ("🦒", "Giraffe"), ("🎸", "Gitarre"), ("🥒", "Gurke"), ("🐶", "Hund"), ("🐰", "Hase"),
        ("🏠", "Haus"), ("🦔", "Igel"), ("🍰", "Kuchen"), ("🐄", "Kuh"), ("🧀", "Käse"), ("🦁", "Löwe"),
        ("🎈", "Luftballon"), ("🐭", "Maus"), ("🌙", "Mond"), ("🍉", "Melone"), ("👃", "Nase"), ("🐙", "Oktopus"),
        ("🍕", "Pizza"), ("🐧", "Pinguin"), ("🚀", "Rakete"), ("🌹", "Rose"), ("🌈", "Regenbogen"),
        ("☀️", "Sonne"), ("🍅", "Tomate"), ("🧸", "Teddy"), ("🌷", "Tulpe"), ("⌚", "Uhr"), ("☁️", "Wolke"),
        ("🍋", "Zitrone"), ("🦓", "Zebra"), ("🦷", "Zahn")
    ]

    /// Silben, mit Bindestrich getrennt, so wie man sie spricht und klatscht
    static let silbenWoerter = [
        "Ap-fel", "Ba-na-ne", "Ball", "Ro-se", "Ta-sche", "Ki-wi", "Me-lo-ne", "Ha-se", "Hund", "Kat-ze",
        "Scho-ko-la-de", "Te-le-fon", "Au-to", "Ra-ke-te", "Kro-ko-dil", "E-le-fant", "Son-ne", "Mond",
        "Blu-me", "Fisch", "Tisch", "Gi-raf-fe", "Ta-fel", "To-ma-te", "Ku-chen", "Brot", "Ka-mel",
        "Pin-gu-in", "Ze-bra", "Re-gen-bo-gen", "Kin-der-gar-ten", "Ka-rot-te", "Schmet-ter-ling", "Baum",
        "Pa-pa-gei", "Gur-ke", "Lö-we", "Am-pel", "Fahr-rad", "Le-se-buch"
    ]

    static let reimPaare: [(String, String)] = [
        ("Haus", "Maus"), ("Hand", "Sand"), ("Baum", "Traum"), ("Topf", "Kopf"), ("Hose", "Rose"),
        ("Kanne", "Tanne"), ("Bein", "Schwein"), ("Fisch", "Tisch"), ("Nase", "Hase"), ("Hund", "Mund"),
        ("Katze", "Tatze"), ("Sonne", "Tonne"), ("Wiese", "Riese"), ("Glas", "Gras"), ("Ball", "Stall"),
        ("Hecke", "Schnecke"), ("Kuchen", "suchen"), ("Maler", "Taler"), ("Rabe", "Gabe"), ("Zug", "Krug")
    ]

    struct Nomen {
        let artikel: String
        let wort: String
        let mehrzahl: String
    }

    static let nomen: [Nomen] = [
        Nomen(artikel: "der", wort: "Hund", mehrzahl: "Hunde"),
        Nomen(artikel: "die", wort: "Katze", mehrzahl: "Katzen"),
        Nomen(artikel: "das", wort: "Haus", mehrzahl: "Häuser"),
        Nomen(artikel: "der", wort: "Baum", mehrzahl: "Bäume"),
        Nomen(artikel: "die", wort: "Blume", mehrzahl: "Blumen"),
        Nomen(artikel: "das", wort: "Kind", mehrzahl: "Kinder"),
        Nomen(artikel: "der", wort: "Ball", mehrzahl: "Bälle"),
        Nomen(artikel: "die", wort: "Maus", mehrzahl: "Mäuse"),
        Nomen(artikel: "das", wort: "Buch", mehrzahl: "Bücher"),
        Nomen(artikel: "der", wort: "Tisch", mehrzahl: "Tische"),
        Nomen(artikel: "die", wort: "Tasche", mehrzahl: "Taschen"),
        Nomen(artikel: "das", wort: "Auto", mehrzahl: "Autos"),
        Nomen(artikel: "der", wort: "Vogel", mehrzahl: "Vögel"),
        Nomen(artikel: "die", wort: "Schule", mehrzahl: "Schulen"),
        Nomen(artikel: "das", wort: "Bett", mehrzahl: "Betten"),
        Nomen(artikel: "der", wort: "Apfel", mehrzahl: "Äpfel"),
        Nomen(artikel: "die", wort: "Uhr", mehrzahl: "Uhren"),
        Nomen(artikel: "das", wort: "Bild", mehrzahl: "Bilder"),
        Nomen(artikel: "der", wort: "Stuhl", mehrzahl: "Stühle"),
        Nomen(artikel: "die", wort: "Hand", mehrzahl: "Hände"),
        Nomen(artikel: "das", wort: "Ei", mehrzahl: "Eier"),
        Nomen(artikel: "der", wort: "Fisch", mehrzahl: "Fische"),
        Nomen(artikel: "die", wort: "Banane", mehrzahl: "Bananen"),
        Nomen(artikel: "das", wort: "Glas", mehrzahl: "Gläser"),
        Nomen(artikel: "der", wort: "Stift", mehrzahl: "Stifte"),
        Nomen(artikel: "die", wort: "Tür", mehrzahl: "Türen"),
        Nomen(artikel: "das", wort: "Fenster", mehrzahl: "Fenster"),
        Nomen(artikel: "der", wort: "Zug", mehrzahl: "Züge"),
        Nomen(artikel: "die", wort: "Kuh", mehrzahl: "Kühe"),
        Nomen(artikel: "das", wort: "Pferd", mehrzahl: "Pferde"),
        Nomen(artikel: "der", wort: "Hase", mehrzahl: "Hasen"),
        Nomen(artikel: "die", wort: "Nase", mehrzahl: "Nasen"),
        Nomen(artikel: "das", wort: "Schaf", mehrzahl: "Schafe"),
        Nomen(artikel: "der", wort: "Schuh", mehrzahl: "Schuhe"),
        Nomen(artikel: "die", wort: "Gabel", mehrzahl: "Gabeln"),
        Nomen(artikel: "das", wort: "Rad", mehrzahl: "Räder"),
        Nomen(artikel: "der", wort: "Bär", mehrzahl: "Bären"),
        Nomen(artikel: "die", wort: "Birne", mehrzahl: "Birnen"),
        Nomen(artikel: "das", wort: "Heft", mehrzahl: "Hefte"),
        Nomen(artikel: "der", wort: "Igel", mehrzahl: "Igel"),
        Nomen(artikel: "die", wort: "Ente", mehrzahl: "Enten"),
        Nomen(artikel: "das", wort: "Boot", mehrzahl: "Boote"),
        Nomen(artikel: "der", wort: "Löwe", mehrzahl: "Löwen"),
        Nomen(artikel: "die", wort: "Wolke", mehrzahl: "Wolken"),
        Nomen(artikel: "das", wort: "Spiel", mehrzahl: "Spiele"),
        Nomen(artikel: "der", wort: "Freund", mehrzahl: "Freunde"),
        Nomen(artikel: "die", wort: "Tomate", mehrzahl: "Tomaten"),
        Nomen(artikel: "das", wort: "Zimmer", mehrzahl: "Zimmer"),
        Nomen(artikel: "der", wort: "Teller", mehrzahl: "Teller"),
        Nomen(artikel: "die", wort: "Kerze", mehrzahl: "Kerzen"),
        Nomen(artikel: "das", wort: "Tier", mehrzahl: "Tiere"),
        Nomen(artikel: "der", wort: "Wurm", mehrzahl: "Würmer"),
        Nomen(artikel: "die", wort: "Brille", mehrzahl: "Brillen"),
        Nomen(artikel: "das", wort: "Dach", mehrzahl: "Dächer"),
        Nomen(artikel: "der", wort: "Hut", mehrzahl: "Hüte"),
        Nomen(artikel: "die", wort: "Lampe", mehrzahl: "Lampen"),
        Nomen(artikel: "der", wort: "Finger", mehrzahl: "Finger"),
        Nomen(artikel: "die", wort: "Frau", mehrzahl: "Frauen"),
        Nomen(artikel: "der", wort: "Mann", mehrzahl: "Männer")
    ]

    static let adjektive = [
        "groß", "klein", "schnell", "langsam", "laut", "leise", "rot", "blau", "schön", "lustig",
        "traurig", "warm", "kalt", "hell", "dunkel", "nett", "müde", "stark", "weich", "hart",
        "alt", "neu", "jung", "süß", "sauer", "nass", "trocken", "frech", "mutig", "wild"
    ]

    struct Verb {
        let infinitiv: String
        /// er-Form im Präsens, im Präteritum, Partizip, Hilfsverb "hat" oder "ist"
        let praesens: String
        let praeteritum: String
        let partizip: String
        let hilfsverb: String
        /// true, wenn das Präteritum mit -te gebildet wird (spielte)
        var schwach: Bool { praeteritum.hasSuffix("te") }
    }

    static let verben: [Verb] = [
        Verb(infinitiv: "spielen", praesens: "spielt", praeteritum: "spielte", partizip: "gespielt", hilfsverb: "hat"),
        Verb(infinitiv: "lachen", praesens: "lacht", praeteritum: "lachte", partizip: "gelacht", hilfsverb: "hat"),
        Verb(infinitiv: "malen", praesens: "malt", praeteritum: "malte", partizip: "gemalt", hilfsverb: "hat"),
        Verb(infinitiv: "kochen", praesens: "kocht", praeteritum: "kochte", partizip: "gekocht", hilfsverb: "hat"),
        Verb(infinitiv: "lernen", praesens: "lernt", praeteritum: "lernte", partizip: "gelernt", hilfsverb: "hat"),
        Verb(infinitiv: "tanzen", praesens: "tanzt", praeteritum: "tanzte", partizip: "getanzt", hilfsverb: "hat"),
        Verb(infinitiv: "bauen", praesens: "baut", praeteritum: "baute", partizip: "gebaut", hilfsverb: "hat"),
        Verb(infinitiv: "kaufen", praesens: "kauft", praeteritum: "kaufte", partizip: "gekauft", hilfsverb: "hat"),
        Verb(infinitiv: "fragen", praesens: "fragt", praeteritum: "fragte", partizip: "gefragt", hilfsverb: "hat"),
        Verb(infinitiv: "hüpfen", praesens: "hüpft", praeteritum: "hüpfte", partizip: "gehüpft", hilfsverb: "ist"),
        Verb(infinitiv: "gehen", praesens: "geht", praeteritum: "ging", partizip: "gegangen", hilfsverb: "ist"),
        Verb(infinitiv: "laufen", praesens: "läuft", praeteritum: "lief", partizip: "gelaufen", hilfsverb: "ist"),
        Verb(infinitiv: "fahren", praesens: "fährt", praeteritum: "fuhr", partizip: "gefahren", hilfsverb: "ist"),
        Verb(infinitiv: "springen", praesens: "springt", praeteritum: "sprang", partizip: "gesprungen", hilfsverb: "ist"),
        Verb(infinitiv: "kommen", praesens: "kommt", praeteritum: "kam", partizip: "gekommen", hilfsverb: "ist"),
        Verb(infinitiv: "fliegen", praesens: "fliegt", praeteritum: "flog", partizip: "geflogen", hilfsverb: "ist"),
        Verb(infinitiv: "fallen", praesens: "fällt", praeteritum: "fiel", partizip: "gefallen", hilfsverb: "ist"),
        Verb(infinitiv: "schlafen", praesens: "schläft", praeteritum: "schlief", partizip: "geschlafen", hilfsverb: "hat"),
        Verb(infinitiv: "essen", praesens: "isst", praeteritum: "aß", partizip: "gegessen", hilfsverb: "hat"),
        Verb(infinitiv: "trinken", praesens: "trinkt", praeteritum: "trank", partizip: "getrunken", hilfsverb: "hat"),
        Verb(infinitiv: "lesen", praesens: "liest", praeteritum: "las", partizip: "gelesen", hilfsverb: "hat"),
        Verb(infinitiv: "schreiben", praesens: "schreibt", praeteritum: "schrieb", partizip: "geschrieben", hilfsverb: "hat"),
        Verb(infinitiv: "sehen", praesens: "sieht", praeteritum: "sah", partizip: "gesehen", hilfsverb: "hat"),
        Verb(infinitiv: "singen", praesens: "singt", praeteritum: "sang", partizip: "gesungen", hilfsverb: "hat"),
        Verb(infinitiv: "finden", praesens: "findet", praeteritum: "fand", partizip: "gefunden", hilfsverb: "hat"),
        Verb(infinitiv: "rufen", praesens: "ruft", praeteritum: "rief", partizip: "gerufen", hilfsverb: "hat"),
        Verb(infinitiv: "helfen", praesens: "hilft", praeteritum: "half", partizip: "geholfen", hilfsverb: "hat"),
        Verb(infinitiv: "geben", praesens: "gibt", praeteritum: "gab", partizip: "gegeben", hilfsverb: "hat"),
        Verb(infinitiv: "nehmen", praesens: "nimmt", praeteritum: "nahm", partizip: "genommen", hilfsverb: "hat"),
        Verb(infinitiv: "werfen", praesens: "wirft", praeteritum: "warf", partizip: "geworfen", hilfsverb: "hat"),
        Verb(infinitiv: "bringen", praesens: "bringt", praeteritum: "brachte", partizip: "gebracht", hilfsverb: "hat"),
        Verb(infinitiv: "denken", praesens: "denkt", praeteritum: "dachte", partizip: "gedacht", hilfsverb: "hat")
    ]

    /// Wort mit Lücke, richtiger Buchstabe, der andere Buchstabe, verlängerte Form
    static let verlaengerWoerter: [(String, String, String, String)] = [
        ("Hun?", "d", "t", "die Hunde"), ("Kin?", "d", "t", "die Kinder"), ("Lan?", "d", "t", "die Länder"),
        ("Han?", "d", "t", "die Hände"), ("Wal?", "d", "t", "die Wälder"),
        ("Bil?", "d", "t", "die Bilder"), ("Mun?", "d", "t", "die Münder"), ("Fel?", "d", "t", "die Felder"),
        ("Freun?", "d", "t", "die Freunde"), ("Pfer?", "d", "t", "die Pferde"), ("Klei?", "d", "t", "die Kleider"),
        ("Hu?", "t", "d", "die Hüte"), ("Bro?", "t", "d", "die Brote"), ("Zel?", "t", "d", "die Zelte"),
        ("Hef?", "t", "d", "die Hefte"), ("Gas?", "t", "d", "die Gäste"), ("Stif?", "t", "d", "die Stifte"),
        ("Nes?", "t", "d", "die Nester"),
        ("Ber?", "g", "k", "die Berge"), ("Zwer?", "g", "k", "die Zwerge"), ("Zu?", "g", "k", "die Züge"),
        ("Ta?", "g", "k", "die Tage"), ("We?", "g", "k", "die Wege"), ("Flu?", "g", "k", "die Flüge"),
        ("Schran?", "k", "g", "die Schränke"), ("Geschen?", "k", "g", "die Geschenke"),
        ("Kor?", "b", "p", "die Körbe"), ("Die?", "b", "p", "die Diebe"), ("Kal?", "b", "p", "die Kälber"),
        ("Sie?", "b", "p", "die Siebe"),
        ("run?", "d", "t", "runde"), ("wil?", "d", "t", "wilde"), ("gesun?", "d", "t", "gesunde"),
        ("lau?", "t", "d", "laute"), ("bun?", "t", "d", "bunte"), ("klu?", "g", "k", "kluge"),
        ("star?", "k", "g", "starke"), ("gel?", "b", "p", "gelbe")
    ]

    /// Wort mit Lücke, richtig "ie" oder "i", ganzes Wort
    static let ieWoerter: [(String, String, String)] = [
        ("B?ne", "ie", "Biene"), ("T?r", "ie", "Tier"), ("Sp?l", "ie", "Spiel"),
        ("W?se", "ie", "Wiese"), ("Br?f", "ie", "Brief"), ("R?se", "ie", "Riese"), ("Z?ge", "ie", "Ziege"),
        ("fl?gen", "ie", "fliegen"), ("s?ben", "ie", "sieben"), ("l?b", "ie", "lieb"), ("D?b", "ie", "Dieb"),
        ("K?nd", "i", "Kind"), ("F?sch", "i", "Fisch"), ("T?sch", "i", "Tisch"), ("W?nd", "i", "Wind"),
        ("R?ng", "i", "Ring"), ("K?ste", "i", "Kiste"), ("M?lch", "i", "Milch"), ("B?ld", "i", "Bild"),
        ("L?ppe", "i", "Lippe"), ("F?lm", "i", "Film"), ("S?lber", "i", "Silber"), ("K?rsche", "i", "Kirsche")
    ]

    /// Satz, markierter Teil, Fall 1 bis 4
    static let fallSaetze: [(String, String, Int)] = [
        ("Der Hund bellt laut.", "Der Hund", 1), ("Der Lehrer erklärt die Aufgabe.", "Der Lehrer", 1),
        ("Mein Bruder spielt Fußball.", "Mein Bruder", 1), ("Der Ball rollt ins Tor.", "Der Ball", 1),
        ("Der Vogel singt im Baum.", "Der Vogel", 1), ("Am Morgen scheint die Sonne.", "die Sonne", 1),
        ("Das Fell des Hundes ist weich.", "des Hundes", 2), ("Die Tasche des Lehrers ist schwer.", "des Lehrers", 2),
        ("Das Dach des Hauses ist rot.", "des Hauses", 2), ("Die Farbe des Balles ist blau.", "des Balles", 2),
        ("Der Schwanz der Katze ist lang.", "der Katze", 2),
        ("Ich helfe dem Opa.", "dem Opa", 3), ("Lena gibt dem Hund einen Knochen.", "dem Hund", 3),
        ("Wir danken dem Lehrer.", "dem Lehrer", 3), ("Tom schenkt seiner Schwester ein Buch.", "seiner Schwester", 3),
        ("Das Fahrrad gehört dem Nachbarn.", "dem Nachbarn", 3), ("Mia winkt ihrer Freundin.", "ihrer Freundin", 3),
        ("Ich sehe den Vogel.", "den Vogel", 4), ("Ben wirft den Ball.", "den Ball", 4),
        ("Wir besuchen den Zoo.", "den Zoo", 4), ("Die Katze fängt eine Maus.", "eine Maus", 4),
        ("Lena liest ein Buch.", "ein Buch", 4), ("Mama kauft einen Kuchen.", "einen Kuchen", 4),
        ("Der Hund sucht seinen Knochen.", "seinen Knochen", 4)
    ]

    static let fallNamen = [1: "1. Fall: Wer oder was?", 2: "2. Fall: Wessen?",
                            3: "3. Fall: Wem?", 4: "4. Fall: Wen oder was?"]

    /// Satz mit Lücke (___), richtig "das" oder "dass"
    static let dassSaetze: [(String, String)] = [
        ("Ich weiß, ___ du gut rechnen kannst.", "dass"), ("Mama sagt, ___ wir bald essen.", "dass"),
        ("Ich hoffe, ___ es morgen schneit.", "dass"), ("Tom freut sich, ___ die Ferien beginnen.", "dass"),
        ("Es ist schön, ___ du da bist.", "dass"), ("Ich glaube, ___ der Bus gleich kommt.", "dass"),
        ("Wir wissen, ___ Katzen gern schlafen.", "dass"), ("Lena merkt, ___ es regnet.", "dass"),
        ("Ben findet, ___ Mathe Spaß macht.", "dass"), ("Papa erzählt, ___ er früher Fußball gespielt hat.", "dass"),
        ("Ich lese ___ Buch über Dinos.", "das"), ("Wo ist ___ Fahrrad von Ali?", "das"),
        ("Siehst du ___ Haus dort drüben?", "das"), ("Mia hat ein Bild, ___ sie selbst gemalt hat.", "das"),
        ("Ich mag ___ Lied sehr.", "das"), ("Das Spiel, ___ wir spielen, ist lustig.", "das"),
        ("Gib mir bitte ___ Heft.", "das"), ("Wir füttern ___ Kaninchen.", "das"),
        ("Das Mädchen, ___ dort steht, heißt Ida.", "das"), ("Ich finde ___ Wetter heute toll.", "das")
    ]

    // MARK: Klasse 1

    static func anlaut() -> A {
        let (bild, wort) = Lern.eins(anlaute)
        let richtig = String(wort.prefix(1))
        let andere = anlaute.map { String($0.1.prefix(1)) }
        return Lern.wahl(frage: "Mit welchem Buchstaben fängt das Wort an?", richtig: richtig,
                         falsch: andere, bild: "wort:\(bild)|\(wort)",
                         erklaerung: "\(wort) fängt mit \(richtig) an.")
    }

    static func silbenZahl(_ w: String) -> Int { w.components(separatedBy: "-").count }

    static func silben() -> A {
        let w = Lern.eins(silbenWoerter)
        let ganz = w.replacingOccurrences(of: "-", with: "")
        let n = silbenZahl(w)
        return Lern.zahl("Wie viele Silben hat das Wort? Klatsche mit!", ganz, n,
                         erklaerung: "\(w): \(n) \(n == 1 ? "Silbe" : "Silben")")
    }

    /// Wörter reimen sich hier, wenn die letzten drei Buchstaben gleich sind.
    static func reimtSich(_ a: String, _ b: String) -> Bool {
        a.lowercased().suffix(3) == b.lowercased().suffix(3)
    }

    static func reim() -> A {
        let (a, b) = Lern.eins(reimPaare)
        let falsch = reimPaare.flatMap { [$0.0, $0.1] }.filter { $0 != a && $0 != b && !reimtSich($0, a) }
        return Lern.wahl(frage: "Was reimt sich auf das Wort?", rechnung: a, richtig: b, falsch: falsch,
                         erklaerung: "\(a) und \(b) reimen sich.")
    }

    // MARK: Klasse 2

    static func artikel() -> A {
        let n = Lern.eins(nomen)
        return LernAufgabe(art: "wahl", frage: "Welcher Artikel passt?", rechnung: "? \(n.wort)",
                           antwort: n.artikel, erklaerung: "\(n.artikel) \(n.wort)",
                           optionen: ["der", "die", "das"])
    }

    static func umlaut(_ w: String) -> String {
        // Bei eu, ei und ie gibt es keinen sinnvollen Umlaut
        if w.contains("eu") || w.contains("ei") || w.contains("ie") { return w }
        for (alt, neu) in [("au", "äu"), ("a", "ä"), ("o", "ö"), ("u", "ü")] {
            if let r = w.range(of: alt, options: .backwards) {
                return w.replacingCharacters(in: r, with: neu)
            }
        }
        return w
    }

    /// Falsche Mehrzahlformen, die es nicht gibt
    static func falscheMehrzahl(_ n: Nomen) -> [String] {
        let w = n.wort
        let u = umlaut(w)
        let kandidaten = [w + "e", w + "er", w + "s", u + "e", u + "er",
                          w.hasSuffix("e") ? w + "n" : w + "en", w]
        return kandidaten.filter { $0 != n.mehrzahl && !$0.contains("ee") }
    }

    static func mehrzahl() -> A {
        let n = Lern.eins(nomen)
        return Lern.wahl(frage: "Wie heißt die Mehrzahl?", rechnung: "\(n.artikel) \(n.wort), die ?",
                         richtig: n.mehrzahl, falsch: falscheMehrzahl(n),
                         erklaerung: "\(n.artikel) \(n.wort), die \(n.mehrzahl)")
    }

    static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map { String($0) }

    static func abc() -> A {
        if Lern.wahr(0.5) {
            let i = Lern.z(1...24)
            let nach = Lern.wahr(0.5)
            let richtig = alphabet[nach ? i + 1 : i - 1]
            let falsch = alphabet.filter { $0 != richtig && $0 != alphabet[i] }
            return Lern.wahl(frage: nach ? "Welcher Buchstabe kommt danach?" : "Welcher Buchstabe kommt davor?",
                             rechnung: nach ? "\(alphabet[i]), ?" : "?, \(alphabet[i])",
                             richtig: richtig, falsch: falsch,
                             erklaerung: nach ? "Nach \(alphabet[i]) kommt \(richtig)." : "Vor \(alphabet[i]) kommt \(richtig).")
        }
        // Drei Wörter mit verschiedenen Anfangsbuchstaben: welches steht zuerst im ABC?
        var woerter: [String] = []
        for n in nomen.shuffled() where !woerter.contains(where: { $0.prefix(1) == n.wort.prefix(1) }) && woerter.count < 3 {
            woerter.append(n.wort)
        }
        let erstes = woerter.min { abcIndex($0) < abcIndex($1) } ?? woerter[0]
        return LernAufgabe(art: "wahl", frage: "Welches Wort steht im ABC zuerst?",
                           antwort: erstes, erklaerung: "\(erstes) fängt mit \(erstes.prefix(1)) an. Das kommt im ABC zuerst.",
                           optionen: woerter.shuffled())
    }

    /// Stelle des ersten Buchstabens im ABC. Ä zählt wie A.
    static func abcIndex(_ w: String) -> Int {
        let erster = String(w.prefix(1)).uppercased()
            .replacingOccurrences(of: "Ä", with: "A")
            .replacingOccurrences(of: "Ö", with: "O")
            .replacingOccurrences(of: "Ü", with: "U")
        return alphabet.firstIndex(of: erster) ?? 99
    }

    static func gross() -> A {
        let n = Lern.eins(nomen)
        let andere = (adjektive + verben.map { $0.infinitiv }).shuffled().prefix(2)
        let optionen = ([n.wort.lowercased()] + andere).shuffled()
        return LernAufgabe(art: "wahl", frage: "Ein Wort schreibt man groß. Welches?",
                           antwort: n.wort.lowercased(),
                           erklaerung: "\(n.wort) ist ein Nomen: \(n.artikel) \(n.wort). Nomen schreibt man groß.",
                           optionen: optionen)
    }

    // MARK: Klasse 3

    static func wortart() -> A {
        let optionen = ["Nomen", "Verb", "Adjektiv"]
        switch Lern.z(0...2) {
        case 0:
            let n = Lern.eins(nomen)
            return LernAufgabe(art: "wahl", frage: "Welche Wortart ist das?", rechnung: n.wort, antwort: "Nomen",
                               erklaerung: "\(n.artikel) \(n.wort): ein Nomen, mit Artikel und groß geschrieben.",
                               optionen: optionen)
        case 1:
            let v = Lern.eins(verben)
            return LernAufgabe(art: "wahl", frage: "Welche Wortart ist das?", rechnung: v.infinitiv, antwort: "Verb",
                               erklaerung: "\(v.infinitiv): ein Verb. Man kann es tun: er \(v.praesens).",
                               optionen: optionen)
        default:
            let a = Lern.eins(adjektive)
            return LernAufgabe(art: "wahl", frage: "Welche Wortart ist das?", rechnung: a, antwort: "Adjektiv",
                               erklaerung: "\(a): ein Adjektiv. Es sagt, wie etwas ist.",
                               optionen: optionen)
        }
    }

    /// Ein Präteritum mit -te, das es bei starken Verben nicht gibt: gehte
    static func falschSchwach(_ v: Verb) -> String {
        String(v.infinitiv.dropLast(2)) + "te"
    }

    static func vergangenheit() -> A {
        let v = Lern.eins(verben)
        let falsch = v.schwach ? [v.praesens, v.partizip] : [v.praesens, falschSchwach(v), v.partizip]
        return Lern.wahl(frage: "Wie heißt die Vergangenheit?",
                         rechnung: "Heute: er \(v.praesens).\nGestern: er ?",
                         richtig: v.praeteritum, falsch: falsch,
                         erklaerung: "Heute er \(v.praesens), gestern er \(v.praeteritum).")
    }

    static func verlaengern() -> A {
        let (luecke, richtig, falsch, lang) = Lern.eins(verlaengerWoerter)
        let ganz = luecke.replacingOccurrences(of: "?", with: richtig)
        return LernAufgabe(art: "wahl", frage: "Welcher Buchstabe fehlt? Verlängere das Wort.",
                           rechnung: luecke, antwort: richtig,
                           erklaerung: "\(lang), also \(ganz).",
                           optionen: [richtig, falsch].shuffled())
    }

    static func ieOderI() -> A {
        let (luecke, richtig, ganz) = Lern.eins(ieWoerter)
        return LernAufgabe(art: "wahl", frage: "i oder ie?", rechnung: luecke, antwort: richtig,
                           erklaerung: richtig == "ie" ? "\(ganz): das i klingt lang." : "\(ganz): das i klingt kurz.",
                           optionen: ["i", "ie"])
    }

    // MARK: Klasse 4

    static func faelle() -> A {
        let (satz, teil, fall) = Lern.eins(fallSaetze)
        let optionen = [1, 2, 3, 4].compactMap { fallNamen[$0] }
        let richtig = fallNamen[fall] ?? ""
        return LernAufgabe(art: "wahl", frage: "In welchem Fall steht „\(teil)“?", rechnung: satz,
                           antwort: richtig, erklaerung: "„\(teil)“ steht im \(richtig)",
                           optionen: optionen)
    }

    static func dasDass() -> A {
        let (satz, richtig) = Lern.eins(dassSaetze)
        let ganz = satz.replacingOccurrences(of: "___", with: richtig)
        return LernAufgabe(art: "wahl", frage: "das oder dass?", rechnung: satz, antwort: richtig,
                           erklaerung: richtig == "das"
                               ? "\(ganz) Hier passt auch dieses oder welches."
                               : "\(ganz) Dieses oder welches passt hier nicht.",
                           optionen: ["das", "dass"])
    }

    /// wir-Form im Präteritum: ging wird gingen, spielte wird spielten
    static func wirPraeteritum(_ v: Verb) -> String {
        v.praeteritum.hasSuffix("e") ? v.praeteritum + "n" : v.praeteritum + "en"
    }

    static func zeitform() -> A {
        let v = Lern.eins(verben)
        let wir = Lern.wahr(0.5)
        let zeit = Lern.z(0...3)
        let satz: String
        if wir {
            let hilf = v.hilfsverb == "ist" ? "sind" : "haben"
            satz = ["Wir \(v.infinitiv).", "Wir \(wirPraeteritum(v)).",
                    "Wir \(hilf) \(v.partizip).", "Wir werden \(v.infinitiv)."][zeit]
        } else {
            satz = ["Er \(v.praesens).", "Er \(v.praeteritum).",
                    "Er \(v.hilfsverb) \(v.partizip).", "Er wird \(v.infinitiv)."][zeit]
        }
        let namen = ["Präsens (Gegenwart)", "Präteritum (Vergangenheit)",
                     "Perfekt (Vergangenheit)", "Futur (Zukunft)"]
        return LernAufgabe(art: "wahl", frage: "In welcher Zeitform steht der Satz?", rechnung: satz,
                           antwort: namen[zeit], erklaerung: "„\(satz)“ steht im \(namen[zeit]).",
                           optionen: namen)
    }
}
