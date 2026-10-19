import Foundation

// ============================================================
// MARK: - Lernwelt Mathe, weitere Themen
// ============================================================
//
// Sachaufgaben, Vergleichen, Verdoppeln, Zahlenmauern, Geometrie, Uhr, Daten und Zufall.
// Bayern (LehrplanPLUS 1/2) nennt Körperformen, Uhrzeit, Kombinieren und sicher, möglich,
// unmöglich schon für Klasse 1 und 2, NRW und Hessen ebenso bis Ende Klasse 2.
// Umfang und Flächeninhalt bestimmen steht in NRW bei Ende Klasse 4.

enum LehrplanMatheMehr {
    typealias A = LernAufgabe

    static var themen: [LernThema] {
        [
            // Klasse 1
            LernThema(id: "m1-verdoppeln", fach: .mathe, titel: "Verdoppeln und Halbieren", emoji: "👯",
                      beschreibung: "Doppelt so viel, halb so viel", klasse: 1,
                      tipp: "Verdoppeln heißt: die Zahl plus dieselbe Zahl. 6 + 6 = 12.", erzeuge: { verdoppeln20() }),
            LernThema(id: "m1-vergleich", fach: .mathe, titel: "Größer, kleiner, gleich", emoji: "🐊",
                      beschreibung: "<, > und = bis 20", klasse: 1,
                      tipp: "Das Krokodil frisst immer die größere Zahl: 9 > 4.", erzeuge: { vergleich20() }),
            LernThema(id: "m1-geld", fach: .mathe, titel: "Geld bis 20 €", emoji: "🪙",
                      beschreibung: "Münzen und Scheine zusammenzählen", klasse: 1, erzeuge: { geld20() }),
            LernThema(id: "m1-sach", fach: .mathe, titel: "Rechengeschichten", emoji: "📖",
                      beschreibung: "Kleine Geschichten zum Rechnen", klasse: 1, erzeuge: { sach20() }),
            LernThema(id: "m1-strich", fach: .mathe, titel: "Strichlisten", emoji: "✏️",
                      beschreibung: "Striche zählen, immer fünf zusammen", klasse: 1,
                      tipp: "Ein Bündel mit Querstrich sind 5. Zähle erst die Bündel: 5, 10, 15.", erzeuge: { strichliste() }),
            // Klasse 2
            LernThema(id: "m2-mauer", fach: .mathe, titel: "Zahlenmauern", emoji: "🧱",
                      beschreibung: "Zwei Steine ergeben den Stein darüber", klasse: 2, erzeuge: { mauer100() }),
            LernThema(id: "m2-ergaenzen", fach: .mathe, titel: "Ergänzen bis 100", emoji: "🧩",
                      beschreibung: "Wie viel fehlt noch?", klasse: 2,
                      tipp: "Erst bis zum nächsten Zehner, dann bis 100.", erzeuge: { ergaenzen() }),
            LernThema(id: "m2-verdoppeln", fach: .mathe, titel: "Verdoppeln und Halbieren bis 100", emoji: "👯",
                      beschreibung: "Mit Zehnern und Einern", klasse: 2, erzeuge: { verdoppeln100() }),
            LernThema(id: "m2-vergleich", fach: .mathe, titel: "Vergleichen bis 100", emoji: "🐊",
                      beschreibung: "Erst rechnen, dann vergleichen", klasse: 2, erzeuge: { vergleich100() }),
            LernThema(id: "m2-sach", fach: .mathe, titel: "Sachaufgaben bis 100", emoji: "🛒",
                      beschreibung: "Lesen, rechnen, antworten", klasse: 2,
                      tipp: "Lies genau: Was weißt du, was ist gesucht?", erzeuge: { sach100() }),
            LernThema(id: "m2-meter", fach: .mathe, titel: "Meter und Zentimeter", emoji: "📏",
                      beschreibung: "1 m sind 100 cm", klasse: 2, erzeuge: { meter() }),
            LernThema(id: "m2-koerper", fach: .mathe, titel: "Körper", emoji: "🎲",
                      beschreibung: "Würfel, Quader, Kugel und mehr", klasse: 2, erzeuge: { koerper() }),
            LernThema(id: "m2-uhrlesen", fach: .mathe, titel: "Die Uhr lesen", emoji: "🕰️",
                      beschreibung: "Volle, halbe und Viertelstunden", klasse: 2,
                      tipp: "Der kurze Zeiger zeigt die Stunde, der lange die Minuten.", erzeuge: { uhrLesen() }),
            LernThema(id: "m2-kombi", fach: .mathe, titel: "Kombinieren", emoji: "👕",
                      beschreibung: "Wie viele Möglichkeiten gibt es?", klasse: 2,
                      tipp: "Zu jedem T-Shirt passt jede Hose. Also T-Shirts mal Hosen.", erzeuge: { kombinieren2() }),
            LernThema(id: "m2-zufall", fach: .mathe, titel: "Sicher, möglich, unmöglich", emoji: "🎲",
                      beschreibung: "Kann das passieren?", klasse: 2, erzeuge: { zufall2() }),
            // Klasse 3
            LernThema(id: "m3-mauer", fach: .mathe, titel: "Zahlenmauern bis 1000", emoji: "🏰",
                      beschreibung: "Große Mauern mit vier Steinen unten", klasse: 3, erzeuge: { mauer1000() }),
            LernThema(id: "m3-halbschriftlich", fach: .mathe, titel: "Mal mit großen Zahlen", emoji: "🧮",
                      beschreibung: "13 · 6 in Schritten rechnen", klasse: 3,
                      tipp: "Zerlege die große Zahl: 13 · 6 = 10 · 6 + 3 · 6.", erzeuge: { halbschriftlich() }),
            LernThema(id: "m3-geldkomma", fach: .mathe, titel: "Euro mit Komma", emoji: "💶",
                      beschreibung: "3,45 € sind 345 ct", klasse: 3,
                      tipp: "Vor dem Komma stehen die Euro, dahinter die Cent.", erzeuge: { geldKomma() }),
            LernThema(id: "m3-ueberschlag", fach: .mathe, titel: "Überschlagen", emoji: "🔭",
                      beschreibung: "Ungefähr wie viel?", klasse: 3,
                      tipp: "Runde beide Zahlen auf Hunderter und rechne dann.", erzeuge: { ueberschlag() }),
            LernThema(id: "m3-nachbarn", fach: .mathe, titel: "Nachbarzehner und Nachbarhunderter", emoji: "🏘️",
                      beschreibung: "Zwischen welchen Zahlen liegt sie?", klasse: 3, erzeuge: { nachbarHunderter() }),
            LernThema(id: "m3-sach", fach: .mathe, titel: "Sachaufgaben bis 1000", emoji: "🚌",
                      beschreibung: "Mit Geld, Seiten und Plätzen", klasse: 3,
                      tipp: "Schreib dir auf: Was weiß ich? Was ist gesucht?", erzeuge: { sach1000() }),
            LernThema(id: "m3-kaestchen", fach: .mathe, titel: "Fläche und Umfang in Kästchen", emoji: "🟨",
                      beschreibung: "Kästchen zählen und Ränder messen", klasse: 3, abweichend: [.nrw: 4],
                      tipp: "Die Fläche sind alle Kästchen. Der Umfang ist der Weg einmal ganz außen herum.",
                      erzeuge: { kaestchen() }),
            LernThema(id: "m3-tabelle", fach: .mathe, titel: "Tabellen lesen", emoji: "📊",
                      beschreibung: "Daten finden und rechnen", klasse: 3, erzeuge: { tabelle() }),
            // Klasse 4
            LernThema(id: "m4-flaeche", fach: .mathe, titel: "Umfang und Fläche", emoji: "📐",
                      beschreibung: "Rechtecke in cm und cm²", klasse: 4,
                      tipp: "Fläche: Länge mal Breite. Umfang: alle vier Seiten zusammen.", erzeuge: { flaeche() }),
            LernThema(id: "m4-groessen", fach: .mathe, titel: "Größen umrechnen", emoji: "🧪",
                      beschreibung: "mm, km, ml, t, Sekunden", klasse: 4,
                      tipp: "1 cm = 10 mm, 1 l = 1000 ml, 1 t = 1000 kg, 1 min = 60 s.", erzeuge: { groessen() }),
            LernThema(id: "m4-vergleich", fach: .mathe, titel: "Große Zahlen vergleichen", emoji: "🐊",
                      beschreibung: "<, > und = bis 1 Million", klasse: 4,
                      tipp: "Vergleiche von links: zuerst die höchste Stelle.", erzeuge: { vergleichGross() }),
            LernThema(id: "m4-sach", fach: .mathe, titel: "Sachaufgaben mit großen Zahlen", emoji: "✈️",
                      beschreibung: "Auch mit zwei Rechenschritten", klasse: 4, erzeuge: { sachGross() }),
            LernThema(id: "m4-kombi", fach: .mathe, titel: "Kombinieren und Zählen", emoji: "🤝",
                      beschreibung: "Möglichkeiten geschickt zählen", klasse: 4, erzeuge: { kombinieren4() }),
            LernThema(id: "m4-zufall", fach: .mathe, titel: "Wahrscheinlichkeit", emoji: "🍀",
                      beschreibung: "Was ist wahrscheinlicher?", klasse: 4, erzeuge: { zufall4() })
        ]
    }

    // MARK: Namen und Dinge für Geschichten

    /// Name und ob "sie" oder "er"
    static let kinder: [(String, Bool)] = [
        ("Jule", true), ("Ali", false), ("Mia", true), ("Tom", false), ("Lena", true), ("Ben", false),
        ("Sara", true), ("Emil", false), ("Nele", true), ("Jonas", false), ("Ida", true), ("Luis", false)
    ]

    /// Mehrzahl der Dinge, die gesammelt werden
    static let dinge = ["Murmeln", "Sticker", "Bonbons", "Buntstifte", "Karten", "Muscheln", "Kekse", "Perlen"]

    static func kind() -> (name: String, pron: String, Pron: String) {
        let k = Lern.eins(kinder)
        return (k.0, k.1 ? "sie" : "er", k.1 ? "Sie" : "Er")
    }

    static func zweiKinder() -> (String, String) {
        let a = Lern.eins(kinder).0
        var b = Lern.eins(kinder).0
        while b == a { b = Lern.eins(kinder).0 }
        return (a, b)
    }

    static let lies = "Lies genau. Rechne und antworte."

    // MARK: Klasse 1

    static func verdoppeln20() -> A {
        if Lern.wahr(0.5) {
            let n = Lern.z(1...10)
            return Lern.zahl("Verdopple die Zahl.", "\(n)", 2 * n, erklaerung: "\(n) + \(n) = \(2 * n)")
        }
        let n = Lern.z(1...10) * 2
        return Lern.zahl("Halbiere die Zahl.", "\(n)", n / 2, erklaerung: "\(n / 2) + \(n / 2) = \(n), also ist die Hälfte \(n / 2).")
    }

    static func vergleich20() -> A {
        if Lern.wahr(0.5) {
            let a = Lern.z(0...20)
            var b = Lern.z(0...20)
            if Lern.wahr(0.15) { b = a }
            return Lern.vergleich(String(a), a, String(b), b)
        }
        let x = Lern.z(1...9)
        let y = Lern.z(1...(10 - x))
        let c = Lern.z(max(1, x + y - 2)...min(20, x + y + 2))
        return Lern.vergleich("\(x) + \(y)", x + y, String(c), c)
    }

    static func geld20() -> A {
        switch Lern.z(0...2) {
        case 0:
            let werte = [1, 2, 5, 10]
            var teile: [Int] = []
            repeat {
                teile = (0..<Lern.z(2...3)).map { _ in Lern.eins(werte) }
            } while teile.reduce(0, +) > 20
            let summe = teile.reduce(0, +)
            let text = teile.map { "\($0) €" }.joined(separator: " + ")
            return Lern.zahl("Wie viel Geld ist das?", "\(text) = ? €", summe,
                             erklaerung: teile.map(String.init).joined(separator: " + ") + " = \(summe)")
        case 1:
            let k = kind()
            let preis = Lern.z(2...18)
            return Lern.zahl(lies, "\(k.name) hat 20 €. Ein Spiel kostet \(preis) €. Wie viel Geld bleibt übrig?", 20 - preis,
                             erklaerung: "20 - \(preis) = \(20 - preis)")
        default:
            let a = Lern.z(2...9)
            let b = Lern.z(2...(20 - a))
            return Lern.zahl(lies, "Ein Ball kostet \(a) €, ein Buch \(b) €. Wie viel kostet beides zusammen?", a + b,
                             erklaerung: "\(a) + \(b) = \(a + b)")
        }
    }

    static func sach20() -> A {
        let k = kind()
        let ding = Lern.eins(dinge)
        switch Lern.z(0...2) {
        case 0:
            let a = Lern.z(2...12)
            let b = Lern.z(2...(20 - a))
            return Lern.zahl(lies, "\(k.name) hat \(a) \(ding). \(k.Pron) bekommt \(b) dazu. Wie viele \(ding) hat \(k.pron) jetzt?",
                             a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 1:
            let a = Lern.z(5...20)
            let b = Lern.z(2...(a - 2))
            return Lern.zahl(lies, "\(k.name) hat \(a) \(ding). \(k.Pron) verschenkt \(b). Wie viele \(ding) hat \(k.pron) noch?",
                             a - b, erklaerung: "\(a) - \(b) = \(a - b)")
        default:
            let (n1, n2) = zweiKinder()
            let a = Lern.z(2...14)
            let b = Lern.z((a + 2)...20)
            return Lern.zahl(lies, "\(n1) hat \(a) \(ding). \(n2) hat \(b) \(ding). Wie viele \(ding) hat \(n2) mehr?",
                             b - a, erklaerung: "\(b) - \(a) = \(b - a)")
        }
    }

    static func strichliste() -> A {
        let n = Lern.z(3...23)
        let ding = Lern.eins(["Vögel", "Autos", "Blumen", "Kinder", "Hunde"])
        return Lern.zahl("Wie viele \(ding) sind das? Zähle die Striche.", "", n,
                         erklaerung: "\(n / 5) Bündel mit je 5 und noch \(n % 5): \(n)")
            .mitBild("strichliste:\(n)")
    }

    // MARK: Klasse 2

    /// Eine Zahlenmauer aus den Steinen der untersten Reihe
    static func mauer(_ unten: [Int]) -> [[Int]] {
        var reihen = [unten]
        while let letzte = reihen.last, letzte.count > 1 {
            reihen.append(zip(letzte, letzte.dropFirst()).map { $0 + $1 })
        }
        return reihen
    }

    static func mauer100() -> A {
        var r: [[Int]] = []
        repeat {
            r = mauer([Lern.z(2...30), Lern.z(2...30), Lern.z(2...30)])
        } while (r.last?.first ?? 0) > 100
        return LernAufgabe(art: "mauer", frage: "Fülle die Mauer von unten nach oben.", antwort: "", reihen: r)
    }

    static func ergaenzen() -> A {
        if Lern.wahr(0.4) {
            let n = Lern.z(11...89)
            guard n % 10 != 0 else { return ergaenzen() }
            let ziel = (n / 10 + 1) * 10
            return Lern.zahl("Ergänze bis zum nächsten Zehner.", "\(n) + ? = \(ziel)", ziel - n,
                             erklaerung: "\(n) + \(ziel - n) = \(ziel)")
        }
        let n = Lern.z(11...95)
        return Lern.zahl("Ergänze bis 100.", "\(n) + ? = 100", 100 - n,
                         erklaerung: "\(n) + \(100 - n) = 100")
    }

    static func verdoppeln100() -> A {
        if Lern.wahr(0.5) {
            let n = Lern.z(11...50)
            return Lern.zahl("Verdopple die Zahl.", "\(n)", 2 * n,
                             erklaerung: "\(n) + \(n) = \(2 * n)")
        }
        let n = Lern.z(11...50) * 2
        return Lern.zahl("Halbiere die Zahl.", "\(n)", n / 2,
                         erklaerung: "Die Hälfte von \(n) ist \(n / 2), denn \(n / 2) + \(n / 2) = \(n).")
    }

    static func vergleich100() -> A {
        switch Lern.z(0...2) {
        case 0:
            let a = Lern.z(10...99)
            var b = Lern.z(10...99)
            if Lern.wahr(0.15) { b = a }
            return Lern.vergleich(String(a), a, String(b), b)
        case 1:
            let x = Lern.z(10...80)
            let y = Lern.z(2...(99 - x))
            let c = Lern.z(max(10, x + y - 5)...min(100, x + y + 5))
            return Lern.vergleich("\(x) + \(y)", x + y, String(c), c)
        default:
            let a = Lern.z(2...10), b = Lern.z(2...10)
            let c = Lern.z(2...10), d = Lern.z(2...10)
            return Lern.vergleich("\(a) · \(b)", a * b, "\(c) · \(d)", c * d)
        }
    }

    static func sach100() -> A {
        let k = kind()
        let ding = Lern.eins(dinge)
        switch Lern.z(0...4) {
        case 0:
            let a = Lern.z(20...70)
            let b = Lern.z(5...(99 - a))
            return Lern.zahl(lies, "\(k.name) hat \(a) \(ding). \(k.Pron) bekommt \(b) dazu. Wie viele \(ding) hat \(k.pron) jetzt?",
                             a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 1:
            let je = Lern.z(2...10)
            let tueten = Lern.z(2...10)
            return Lern.zahl(lies, "In einer Tüte sind \(je) \(ding). \(k.name) kauft \(tueten) Tüten. Wie viele \(ding) sind das?",
                             je * tueten, erklaerung: "\(tueten) · \(je) = \(je * tueten)")
        case 2:
            let kinder = Lern.z(2...10)
            let je = Lern.z(2...10)
            return Lern.zahl(lies, "\(k.name) verteilt \(kinder * je) \(ding) gerecht an \(kinder) Kinder. Wie viele bekommt jedes Kind?",
                             je, erklaerung: "\(kinder * je) : \(kinder) = \(je)")
        case 3:
            let ziel = Lern.z(5...10) * 10
            let schon = Lern.z(5...(ziel - 3))
            return Lern.zahl(lies, "\(k.name) möchte \(ziel) \(ding) sammeln. \(k.Pron) hat schon \(schon). Wie viele fehlen noch?",
                             ziel - schon, erklaerung: "\(ziel) - \(schon) = \(ziel - schon)")
        default:
            let a = Lern.z(30...99)
            let b = Lern.z(5...(a - 5))
            return Lern.zahl(lies, "Im Bus sitzen \(a) Kinder. An der Schule steigen \(b) aus. Wie viele Kinder sitzen noch im Bus?",
                             a - b, erklaerung: "\(a) - \(b) = \(a - b)")
        }
    }

    static func meter() -> A {
        switch Lern.z(0...2) {
        case 0:
            let cm = Lern.z(1...19) * 5
            return Lern.zahl("Wie viele Zentimeter sind das?", "1 m \(cm) cm = ? cm", 100 + cm,
                             erklaerung: "1 m sind 100 cm, dazu \(cm) cm: \(100 + cm) cm")
        case 1:
            let cm = Lern.z(1...19) * 5
            return Lern.zahl("Wie viele Zentimeter fehlen bis 1 m?", "\(cm) cm + ? cm = 1 m", 100 - cm,
                             erklaerung: "1 m sind 100 cm. \(cm) cm + \(100 - cm) cm = 100 cm")
        default:
            let a = Lern.z(10...60)
            let b = Lern.z(5...(99 - a))
            return Lern.zahl("Rechne mit Zentimetern.", "\(a) cm + \(b) cm = ? cm", a + b,
                             erklaerung: "\(a) + \(b) = \(a + b)")
        }
    }

    static let koerperListe: [(String, String, String)] = [
        ("Würfel", "der", "6 gleich große Quadrate als Flächen"),
        ("Quader", "der", "6 Rechtecke als Flächen, wie ein Schuhkarton"),
        ("Kugel", "die", "ganz rund, ohne Ecken und Kanten"),
        ("Zylinder", "der", "2 Kreise als Flächen, wie eine Dose"),
        ("Kegel", "der", "unten ein Kreis, oben eine Spitze, wie eine Eiswaffel"),
        ("Pyramide", "die", "unten ein Quadrat, dazu 4 Dreiecke, die oben spitz zusammenkommen")
    ]

    static func koerper() -> A {
        if Lern.wahr(0.4) {
            let f = Lern.eins([("Wie viele Ecken hat ein Würfel?", 8), ("Wie viele Kanten hat ein Würfel?", 12),
                               ("Wie viele Flächen hat ein Würfel?", 6), ("Wie viele Ecken hat ein Quader?", 8),
                               ("Wie viele Flächen hat ein Quader?", 6), ("Wie viele Ecken hat eine Kugel?", 0),
                               ("Wie viele Ecken hat eine Pyramide mit quadratischem Boden?", 5)])
            return Lern.zahl(f.0, "", f.1, erklaerung: "Richtig sind \(f.1).")
        }
        let (name, artikel, text) = Lern.eins(koerperListe)
        return Lern.wahl(frage: "Welcher Körper ist das?", rechnung: text, richtig: name,
                         falsch: koerperListe.map { $0.0 }, erklaerung: "Das ist \(artikel) \(name).")
    }

    static func zeitText(_ h: Int, _ m: Int) -> String { String(format: "%d:%02d Uhr", h, m) }

    static func uhrLesen() -> A {
        let h = Lern.z(1...12)
        let m = Lern.eins([0, 15, 30, 45])
        let richtig = zeitText(h, m)
        // Typische Verwechslungen: Zeiger vertauscht, eine Stunde daneben, halb und voll verwechselt
        let naechste = h % 12 + 1
        let vorige = (h + 10) % 12 + 1
        var falsch = [zeitText(naechste, m), zeitText(vorige, m), zeitText(h, (m + 30) % 60)]
        if m == 0 { falsch.append(zeitText(12, h * 5 % 60)) }
        return Lern.wahl(frage: "Wie spät ist es?", richtig: richtig, falsch: falsch, bild: "uhr:\(h):\(m)",
                         erklaerung: "Der kurze Zeiger zeigt die Stunde, der lange die Minuten: \(richtig).")
    }

    static func kombinieren2() -> A {
        let a = Lern.z(2...4)
        let b = Lern.z(2...4)
        let f = Lern.eins([("T-Shirts", "Hosen", "anziehen"), ("Sorten Eis", "Waffeln", "aussuchen"),
                           ("Mützen", "Schals", "anziehen")])
        return Lern.zahl(lies, "Im Schrank liegen \(a) \(f.0) und \(b) \(f.1). Wie viele verschiedene Paare kannst du \(f.2)?",
                         a * b, erklaerung: "Zu jedem der \(a) passen alle \(b): \(a) · \(b) = \(a * b)")
    }

    static let zufallFaelle2: [(String, String)] = [
        ("Im Beutel sind nur rote Kugeln. Du ziehst eine rote Kugel.", "sicher"),
        ("Im Beutel sind nur rote Kugeln. Du ziehst eine blaue Kugel.", "unmöglich"),
        ("Im Beutel sind rote und blaue Kugeln. Du ziehst eine blaue Kugel.", "möglich"),
        ("Du würfelst mit einem normalen Würfel eine 7.", "unmöglich"),
        ("Du würfelst mit einem normalen Würfel eine 6.", "möglich"),
        ("Du würfelst mit einem normalen Würfel eine Zahl kleiner als 7.", "sicher"),
        ("Nach dem Montag kommt der Dienstag.", "sicher"),
        ("Morgen regnet es.", "möglich"),
        ("Eine Münze zeigt Kopf.", "möglich"),
        ("Ein Hund fliegt allein zum Mond.", "unmöglich"),
        ("Du ziehst aus einem Beutel mit 5 grünen Kugeln eine grüne.", "sicher")
    ]

    static func zufall2() -> A {
        let (satz, richtig) = Lern.eins(zufallFaelle2)
        return LernAufgabe(art: "wahl", frage: "Ist das sicher, möglich oder unmöglich?", rechnung: satz,
                           antwort: richtig, erklaerung: "Das ist \(richtig).",
                           optionen: ["sicher", "möglich", "unmöglich"])
    }

    // MARK: Klasse 3

    static func mauer1000() -> A {
        var r: [[Int]] = []
        repeat {
            r = mauer([Lern.z(5...30) * 5, Lern.z(5...30) * 5, Lern.z(5...30) * 5, Lern.z(5...30) * 5])
        } while (r.last?.first ?? 0) > 999
        return LernAufgabe(art: "mauer", frage: "Fülle die Mauer von unten nach oben.", antwort: "", reihen: r)
    }

    static func halbschriftlich() -> A {
        let a = Lern.z(12...29)
        let b = Lern.z(3...9)
        let z = a / 10 * 10, e = a % 10
        return Lern.zahl("Rechne in Schritten.", "\(a) · \(b) =", a * b,
                         erklaerung: "\(z) · \(b) = \(z * b), \(e) · \(b) = \(e * b), zusammen \(a * b)",
                         hinweis: "\(z) · \(b) + \(e) · \(b)")
    }

    static func komma(_ cent: Int) -> String { String(format: "%d,%02d €", cent / 100, cent % 100) }

    static func geldKomma() -> A {
        switch Lern.z(0...2) {
        case 0:
            let c = Lern.z(101...999)
            return Lern.zahl("Wie viel Cent sind das?", "\(komma(c)) = ? ct", c,
                             erklaerung: "\(komma(c)) sind \(c / 100) € und \(c % 100) ct, also \(c) ct.")
        case 1:
            let c = Lern.z(5...99)
            return Lern.zahl("Wie viel Cent sind das?", "\(komma(c)) = ? ct", c,
                             erklaerung: "\(komma(c)) sind \(c) ct.")
        default:
            let schein = Lern.eins([5, 10])
            let preis = Lern.z(1...(schein * 20 - 1)) * 5
            let zurueck = schein * 100 - preis
            return Lern.zahl(lies, "Du zahlst mit \(schein) €. Es kostet \(komma(preis)). Wie viel Cent bekommst du zurück?",
                             zurueck, erklaerung: "\(schein * 100) ct - \(preis) ct = \(zurueck) ct")
        }
    }

    static func ueberschlag() -> A {
        let plus = Lern.wahr(0.6)
        let h1 = Lern.z(2...6), h2 = Lern.z(1...3)
        let a = h1 * 100 + Lern.z(-12...12)
        let b = h2 * 100 + Lern.z(-12...12)
        let ungefaehr = plus ? (h1 + h2) * 100 : (h1 - h2) * 100
        guard ungefaehr > 0 else { return ueberschlag() }
        let r = plus ? "\(a) + \(b)" : "\(a) - \(b)"
        let richtig = "etwa \(ungefaehr)"
        return Lern.wahl(frage: "Überschlage. Ungefähr wie viel ist das?", rechnung: r, richtig: richtig,
                         falsch: ["etwa \(ungefaehr + 100)", "etwa \(max(ungefaehr - 100, 100))", "etwa \(ungefaehr + 200)"],
                         erklaerung: "\(a) ist etwa \(h1 * 100), \(b) ist etwa \(h2 * 100). Also etwa \(ungefaehr). Genau: \(plus ? a + b : a - b)")
    }

    static func nachbarHunderter() -> A {
        let n = Lern.z(101...989)
        guard n % 10 != 0 else { return nachbarHunderter() }
        switch Lern.z(0...3) {
        case 0:
            return Lern.zahl("Welcher Zehner kommt davor?", "?, \(n)", n / 10 * 10,
                             erklaerung: "\(n) liegt zwischen \(n / 10 * 10) und \(n / 10 * 10 + 10).")
        case 1:
            return Lern.zahl("Welcher Zehner kommt danach?", "\(n), ?", n / 10 * 10 + 10,
                             erklaerung: "\(n) liegt zwischen \(n / 10 * 10) und \(n / 10 * 10 + 10).")
        case 2:
            return Lern.zahl("Welcher Hunderter kommt davor?", "?, \(n)", n / 100 * 100,
                             erklaerung: "\(n) liegt zwischen \(n / 100 * 100) und \(n / 100 * 100 + 100).")
        default:
            return Lern.zahl("Welcher Hunderter kommt danach?", "\(n), ?", n / 100 * 100 + 100,
                             erklaerung: "\(n) liegt zwischen \(n / 100 * 100) und \(n / 100 * 100 + 100).")
        }
    }

    static func sach1000() -> A {
        let k = kind()
        switch Lern.z(0...4) {
        case 0:
            let ziel = Lern.z(20...90) * 10
            let schon = Lern.z(10...(ziel / 10 - 2)) * 10
            return Lern.zahl(lies, "Die Klasse spart für einen Ausflug. Er kostet \(ziel) €. \(schon) € sind schon da. Wie viel Euro fehlen noch?",
                             ziel - schon, erklaerung: "\(ziel) - \(schon) = \(ziel - schon)")
        case 1:
            let reihen = Lern.z(8...15)
            let je = Lern.z(4...6)
            return Lern.zahl(lies, "Ein Bus hat \(reihen) Reihen mit je \(je) Plätzen. Wie viele Plätze hat der Bus?",
                             reihen * je, erklaerung: "\(reihen) · \(je) = \(reihen * je)")
        case 2:
            let alle = Lern.z(150...480)
            let maedchen = Lern.z(60...(alle - 60))
            return Lern.zahl(lies, "In der Schule sind \(alle) Kinder. \(maedchen) davon sind Mädchen. Wie viele Jungen sind es?",
                             alle - maedchen, erklaerung: "\(alle) - \(maedchen) = \(alle - maedchen)")
        case 3:
            let seiten = Lern.z(120...480)
            let gelesen = Lern.z(20...(seiten - 20))
            return Lern.zahl(lies, "Ein Buch hat \(seiten) Seiten. \(k.name) hat schon \(gelesen) Seiten gelesen. Wie viele Seiten fehlen noch?",
                             seiten - gelesen, erklaerung: "\(seiten) - \(gelesen) = \(seiten - gelesen)")
        default:
            let hefte = Lern.z(2...5)
            let preis = Lern.z(2...4)
            let stift = Lern.z(3...9)
            return Lern.zahl(lies, "\(k.name) kauft \(hefte) Hefte für je \(preis) € und einen Füller für \(stift) €. Wie viel Euro bezahlt \(k.pron)?",
                             hefte * preis + stift,
                             erklaerung: "\(hefte) · \(preis) = \(hefte * preis), dann \(hefte * preis) + \(stift) = \(hefte * preis + stift)")
        }
    }

    static func kaestchen() -> A {
        let b = Lern.z(2...8)
        let h = Lern.z(2...5)
        if Lern.wahr(0.5) {
            return Lern.zahl("Wie viele Kästchen hat die Fläche?", "", b * h,
                             erklaerung: "\(h) Reihen mit je \(b) Kästchen: \(h) · \(b) = \(b * h)")
                .mitBild("rechteck:\(b)x\(h)")
        }
        return Lern.zahl("Wie lang ist der Umfang in Kästchenlängen?", "", 2 * (b + h),
                         erklaerung: "\(b) + \(h) + \(b) + \(h) = \(2 * (b + h))")
            .mitBild("rechteck:\(b)x\(h)")
    }

    static func tabelle() -> A {
        let tiere = ["Hund", "Katze", "Pferd", "Hase"]
        let zahlen = tiere.map { _ in Lern.z(2...12) }
        let klasse = Lern.eins(["3a", "3b", "3c"])
        let text = "Lieblingstiere der Klasse \(klasse):\n" + zip(tiere, zahlen).map { "\($0): \($1)" }.joined(separator: "\n")
        switch Lern.z(0...2) {
        case 0:
            let i = Lern.z(0...3)
            var j = Lern.z(0...3)
            while j == i { j = Lern.z(0...3) }
            return Lern.zahl("Wie viele Kinder mögen \(tiere[i]) oder \(tiere[j]) am liebsten?", text, zahlen[i] + zahlen[j],
                             erklaerung: "\(zahlen[i]) + \(zahlen[j]) = \(zahlen[i] + zahlen[j])")
        case 1:
            let summe = zahlen.reduce(0, +)
            return Lern.zahl("Wie viele Kinder sind es zusammen?", text, summe,
                             erklaerung: zahlen.map(String.init).joined(separator: " + ") + " = \(summe)")
        default:
            let gross = zahlen.max() ?? 0
            let klein = zahlen.min() ?? 0
            return Lern.zahl("Wie viele Kinder sind es beim beliebtesten Tier mehr als beim am wenigsten beliebten?",
                             text, gross - klein, erklaerung: "\(gross) - \(klein) = \(gross - klein)")
        }
    }

    // MARK: Klasse 4

    static func flaeche() -> A {
        let l = Lern.z(3...15)
        let b = Lern.z(2...9)
        if Lern.wahr(0.5) {
            return Lern.zahl("Wie groß ist die Fläche in cm²?", "Ein Rechteck ist \(l) cm lang und \(b) cm breit.", l * b,
                             erklaerung: "\(l) · \(b) = \(l * b), also \(l * b) cm²")
        }
        return Lern.zahl("Wie lang ist der Umfang in cm?", "Ein Rechteck ist \(l) cm lang und \(b) cm breit.", 2 * (l + b),
                         erklaerung: "\(l) + \(b) + \(l) + \(b) = \(2 * (l + b)), also \(2 * (l + b)) cm")
    }

    static func groessen() -> A {
        switch Lern.z(0...5) {
        case 0:
            let cm = Lern.z(2...25)
            return Lern.zahl("Rechne um.", "\(cm) cm = ? mm", cm * 10, erklaerung: "1 cm sind 10 mm, also \(cm * 10) mm.")
        case 1:
            let l = Lern.z(2...9)
            return Lern.zahl("Rechne um.", "\(l) l = ? ml", l * 1000, erklaerung: "1 l sind 1000 ml, also \(l * 1000) ml.")
        case 2:
            let t = Lern.z(2...9)
            return Lern.zahl("Rechne um.", "\(t) t = ? kg", t * 1000, erklaerung: "1 t sind 1000 kg, also \(t * 1000) kg.")
        case 3:
            let min = Lern.z(2...5)
            return Lern.zahl("Rechne um.", "\(min) min = ? s", min * 60, erklaerung: "1 min sind 60 s, also \(min * 60) s.")
        case 4:
            let km = Lern.z(2...9)
            let m = Lern.z(1...9) * 100 + Lern.eins([0, 50])
            return Lern.zahl("Rechne um.", "\(km) km \(m) m = ? m", km * 1000 + m,
                             erklaerung: "\(km) km sind \(km * 1000) m, dazu \(m) m: \(km * 1000 + m) m")
        default:
            let kg = Lern.z(2...9)
            let g = Lern.z(1...19) * 50
            return Lern.zahl("Rechne um.", "\(kg) kg \(g) g = ? g", kg * 1000 + g,
                             erklaerung: "\(kg) kg sind \(kg * 1000) g, dazu \(g) g: \(kg * 1000 + g) g")
        }
    }

    static func vergleichGross() -> A {
        let a = Lern.z(10_000...999_999)
        let b: Int
        switch Lern.z(0...3) {
        case 0: b = a + Lern.eins([-1, 1]) * Lern.eins([10, 100, 1000, 9000])
        case 1:
            // Ziffern vertauscht, das ist die typische Falle
            var z = Array(String(a))
            let i = Lern.z(0...(z.count - 2))
            z.swapAt(i, i + 1)
            b = Int(String(z)) ?? a
        case 2: b = a
        default: b = Lern.z(10_000...999_999)
        }
        guard b >= 10_000, b <= 1_000_000 else { return vergleichGross() }
        return Lern.vergleich(Lern.gross(a), a, Lern.gross(b), b)
    }

    static func sachGross() -> A {
        switch Lern.z(0...4) {
        case 0:
            let km = Lern.z(150...950)
            return Lern.zahl(lies, "Ein Flugzeug fliegt \(km) km hin und \(km) km zurück. Wie viele km sind das zusammen?",
                             2 * km, erklaerung: "\(km) + \(km) = \(2 * km)")
        case 1:
            let a = Lern.z(1_200...9_800)
            let b = Lern.z(1_200...9_800)
            return Lern.zahl(lies, "Am Samstag kommen \(a) Menschen in den Zoo, am Sonntag \(b). Wie viele sind es zusammen?",
                             a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 2:
            let je = Lern.eins([6, 8, 12])
            let packungen = Lern.z(25...150)
            return Lern.zahl(lies, "Eine Bäckerei packt \(je * packungen) Kekse in Packungen mit je \(je) Keksen. Wie viele Packungen werden voll?",
                             packungen, erklaerung: "\(je * packungen) : \(je) = \(packungen)")
        case 3:
            let raten = Lern.eins([3, 4, 5, 6])
            let rate = Lern.z(40...180)
            return Lern.zahl(lies, "Ein Fahrrad kostet \(raten * rate) €. Die Familie zahlt in \(raten) gleich großen Raten. Wie viel Euro ist eine Rate?",
                             rate, erklaerung: "\(raten * rate) : \(raten) = \(rate)")
        default:
            let karten = Lern.z(3...6)
            let preis = Lern.z(7...12)
            let popcorn = Lern.z(4...9)
            return Lern.zahl(lies, "Mama kauft \(karten) Kinokarten für je \(preis) € und Popcorn für \(popcorn) €. Wie viel Euro bezahlt sie?",
                             karten * preis + popcorn,
                             erklaerung: "\(karten) · \(preis) = \(karten * preis), dann \(karten * preis) + \(popcorn) = \(karten * preis + popcorn)")
        }
    }

    static func kombinieren4() -> A {
        switch Lern.z(0...2) {
        case 0:
            let n = Lern.z(3...6)
            let schlaege = n * (n - 1) / 2
            return Lern.zahl(lies, "\(n) Kinder geben sich alle einmal die Hand. Wie viele Handschläge sind das?", schlaege,
                             erklaerung: "Das erste Kind gibt \(n - 1) Kindern die Hand, das nächste noch \(n - 2) und so weiter: \(schlaege)")
        case 1:
            let a = Lern.z(3...5), b = Lern.z(2...4), c = Lern.z(2...3)
            return Lern.zahl(lies, "Zum Frühstück gibt es \(a) Brotsorten, \(b) Aufstriche und \(c) Getränke. Wie viele verschiedene Frühstücke mit je einem davon gibt es?",
                             a * b * c, erklaerung: "\(a) · \(b) · \(c) = \(a * b * c)")
        default:
            let n = Lern.eins([3, 4])
            let anzahl = n == 3 ? 6 : 12
            let ziffern = n == 3 ? "1, 2 und 3" : "1, 2, 3 und 4"
            return Lern.zahl(lies, "Wie viele zweistellige Zahlen kannst du aus den Ziffern \(ziffern) bilden, wenn keine Ziffer doppelt vorkommt?",
                             anzahl, erklaerung: "Für die Zehnerstelle gibt es \(n) Möglichkeiten, für die Einerstelle noch \(n - 1): \(n) · \(n - 1) = \(anzahl)")
        }
    }

    static func zufall4() -> A {
        let rot = Lern.z(1...9)
        var blau = Lern.z(1...9)
        while blau == rot { blau = Lern.z(1...9) }
        if Lern.wahr(0.6) {
            let richtig = rot > blau ? "Rot" : "Blau"
            return LernAufgabe(art: "wahl", frage: "Welche Farbe ziehst du wahrscheinlicher?",
                               rechnung: "Im Beutel sind \(rot) rote und \(blau) blaue Kugeln.", antwort: richtig,
                               erklaerung: "Es gibt mehr \(richtig == "Rot" ? "rote" : "blaue") Kugeln, darum ist \(richtig) wahrscheinlicher.",
                               optionen: ["Rot", "Blau"])
        }
        let mehr = rot > blau ? "rote" : "blaue"
        let weniger = rot > blau ? "blaue" : "rote"
        let d = abs(rot - blau)
        return Lern.zahl("Wie viele \(weniger) Kugeln musst du dazulegen, damit beide Farben gleich wahrscheinlich sind?",
                         "Im Beutel sind \(rot) rote und \(blau) blaue Kugeln.", d,
                         erklaerung: "\(max(rot, blau)) - \(min(rot, blau)) = \(d). Mit \(d) dazu sind es gleich viele \(mehr) und \(weniger).")
    }
}
