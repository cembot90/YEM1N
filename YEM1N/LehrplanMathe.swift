import Foundation

// ============================================================
// MARK: - Lernwelt Mathe, Klasse 1 bis 4
// ============================================================
//
// Klasse 1: Zahlen bis 20, Plus und Minus, Zerlegen, Nachbarzahlen
// Klasse 2: Zahlen bis 100, Zehner und Einer, Einmaleins, Geteilt, Geld, Uhr
// Klasse 3: Zahlen bis 1000, schriftlich Plus und Minus, Teilen mit Rest, Längen, Gewicht
// Klasse 4: Zahlen bis 1 Million, Runden, schriftlich Mal und Geteilt, Zeitspannen, Brüche bei Größen
// Unterschiede der Länder: Das ganze Einmaleins ist in Bayern und Hessen Ende Klasse 2
// verlangt, in NRW Ende Klasse 4 (dort hier in Klasse 3). Gewichte (g, kg) stehen in NRW
// erst bei Klasse 4.

enum LehrplanMathe {
    typealias A = LernAufgabe

    static var themen: [LernThema] {
        [
            // Klasse 1
            LernThema(id: "m1-plus10", fach: .mathe, titel: "Plus bis 10", emoji: "➕",
                      beschreibung: "Zwei Zahlen zusammenrechnen", klasse: 1, erzeuge: plus10),
            LernThema(id: "m1-minus10", fach: .mathe, titel: "Minus bis 10", emoji: "➖",
                      beschreibung: "Etwas wegnehmen", klasse: 1, erzeuge: minus10),
            LernThema(id: "m1-zerlegen", fach: .mathe, titel: "Zahlen zerlegen", emoji: "✂️",
                      beschreibung: "7 = 3 + ?", klasse: 1, erzeuge: zerlegen),
            LernThema(id: "m1-zwanzig", fach: .mathe, titel: "Plus und Minus bis 20", emoji: "🔟",
                      beschreibung: "Über den Zehner rechnen", klasse: 1,
                      tipp: "Rechne erst bis zur 10, dann weiter. 8 + 5: erst 8 + 2 = 10, dann noch 3.",
                      erzeuge: zwanzig),
            LernThema(id: "m1-nachbar", fach: .mathe, titel: "Nachbarzahlen", emoji: "🏘️",
                      beschreibung: "Welche Zahl kommt davor und danach?", klasse: 1, erzeuge: nachbarzahl),
            // Klasse 2
            LernThema(id: "m2-hundert", fach: .mathe, titel: "Plus und Minus bis 100", emoji: "💯",
                      beschreibung: "Mit Zehnern und Einern rechnen", klasse: 2,
                      tipp: "Rechne erst die Zehner, dann die Einer.", erzeuge: hundert),
            LernThema(id: "m2-stellen", fach: .mathe, titel: "Zehner und Einer", emoji: "🧱",
                      beschreibung: "Wie ist eine Zahl gebaut?", klasse: 2, erzeuge: zehnerEiner),
            LernThema(id: "m2-kern", fach: .mathe, titel: "Kernaufgaben Einmaleins", emoji: "⭐️",
                      beschreibung: "Mal 1, 2, 5, 10 und Quadratzahlen", klasse: 2, erzeuge: kern),
            LernThema(id: "m2-einmaleins", fach: .mathe, titel: "Das ganze Einmaleins", emoji: "✖️",
                      beschreibung: "Alle Reihen von 2 bis 10", klasse: 2, abweichend: [.nrw: 3],
                      tipp: "Nutze die Kernaufgaben: 9 · 8 ist 10 · 8 minus 8.", erzeuge: einmaleins),
            LernThema(id: "m2-geteilt", fach: .mathe, titel: "Geteilt mit Umkehraufgabe", emoji: "➗",
                      beschreibung: "Gerecht verteilen", klasse: 2, abweichend: [.nrw: 3], erzeuge: geteilt),
            LernThema(id: "m2-geld", fach: .mathe, titel: "Euro und Cent", emoji: "💶",
                      beschreibung: "Mit Geld rechnen", klasse: 2,
                      tipp: "1 € sind 100 ct.", erzeuge: geld),
            LernThema(id: "m2-uhr", fach: .mathe, titel: "Uhr und Minuten", emoji: "🕐",
                      beschreibung: "Stunden, halbe und Viertelstunden", klasse: 2,
                      tipp: "Eine Stunde hat 60 Minuten.", erzeuge: uhr),
            // Klasse 3
            LernThema(id: "m3-tausend", fach: .mathe, titel: "Rechnen bis 1000", emoji: "🔢",
                      beschreibung: "Mit Hundertern und Zehnern", klasse: 3, erzeuge: tausend),
            LernThema(id: "m3-schriftplus", fach: .mathe, titel: "Schriftlich addieren", emoji: "📝",
                      beschreibung: "Untereinander schreiben und rechnen", klasse: 3,
                      tipp: "Fang bei den Einern an. Ist es mehr als 9, schreib den Übertrag zur nächsten Stelle.",
                      erzeuge: schriftPlus),
            LernThema(id: "m3-schriftminus", fach: .mathe, titel: "Schriftlich subtrahieren", emoji: "📝",
                      beschreibung: "Untereinander schreiben und abziehen", klasse: 3,
                      tipp: "Fang bei den Einern an. Reicht es nicht, nimm dir einen Zehner von der nächsten Stelle.",
                      erzeuge: schriftMinus),
            LernThema(id: "m3-rest", fach: .mathe, titel: "Teilen mit Rest", emoji: "🍪",
                      beschreibung: "Was übrig bleibt, ist der Rest", klasse: 3,
                      tipp: "Der Rest ist immer kleiner als die Zahl, durch die du teilst.", erzeuge: rest),
            LernThema(id: "m3-laengen", fach: .mathe, titel: "Längen: m, cm und km", emoji: "📏",
                      beschreibung: "Umrechnen von Längen", klasse: 3,
                      tipp: "1 m sind 100 cm. 1 km sind 1000 m.", erzeuge: laengen),
            LernThema(id: "m3-gewicht", fach: .mathe, titel: "Gewicht: kg und g", emoji: "⚖️",
                      beschreibung: "Umrechnen von Gewichten", klasse: 3, abweichend: [.nrw: 4],
                      tipp: "1 kg sind 1000 g.", erzeuge: gewicht),
            // Klasse 4
            LernThema(id: "m4-million", fach: .mathe, titel: "Zahlen bis 1 Million", emoji: "🚀",
                      beschreibung: "Große Zahlen lesen und verstehen", klasse: 4, erzeuge: million),
            LernThema(id: "m4-runden", fach: .mathe, titel: "Runden", emoji: "🎯",
                      beschreibung: "Auf Zehner, Hunderter und Tausender", klasse: 4,
                      tipp: "Schau auf die Ziffer rechts daneben. Bei 0 bis 4 abrunden, bei 5 bis 9 aufrunden.",
                      erzeuge: runden),
            LernThema(id: "m4-schriftmal", fach: .mathe, titel: "Schriftlich multiplizieren", emoji: "✍️",
                      beschreibung: "Große Malaufgaben", klasse: 4,
                      tipp: "Rechne Stelle für Stelle von rechts und denk an den Übertrag.", erzeuge: schriftMal),
            LernThema(id: "m4-schriftgeteilt", fach: .mathe, titel: "Schriftlich dividieren", emoji: "✍️",
                      beschreibung: "Große Zahlen durch eine Ziffer teilen", klasse: 4,
                      tipp: "Teile Stelle für Stelle von links. Prüfe mit der Malaufgabe.", erzeuge: schriftGeteilt),
            LernThema(id: "m4-zeit", fach: .mathe, titel: "Zeitspannen", emoji: "⏱️",
                      beschreibung: "Wie lange dauert es?", klasse: 4,
                      tipp: "Rechne erst bis zur vollen Stunde, dann weiter.", erzeuge: zeitspanne),
            LernThema(id: "m4-brueche", fach: .mathe, titel: "Brüche bei Größen", emoji: "🍕",
                      beschreibung: "Halbe, Viertel und Dreiviertel", klasse: 4, erzeuge: brueche)
        ]
    }

    private static let rechne = "Rechne."

    // MARK: Klasse 1

    static func plus10() -> A {
        let a = Lern.z(1...9)
        let b = Lern.z(1...(10 - a))
        return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
    }

    static func minus10() -> A {
        let a = Lern.z(2...10)
        let b = Lern.z(1...a)
        return Lern.zahl(rechne, "\(a) - \(b) =", a - b, erklaerung: "\(a) - \(b) = \(a - b)")
    }

    static func zerlegen() -> A {
        let ganz = Lern.z(5...10)
        let teil = Lern.z(1...(ganz - 1))
        return Lern.zahl("Zerlege die Zahl. Was fehlt?", "\(ganz) = \(teil) + ?", ganz - teil,
                         erklaerung: "\(teil) und \(ganz - teil) sind zusammen \(ganz).")
    }

    static func zwanzig() -> A {
        if Lern.wahr(0.5) {
            let a = Lern.z(2...9)
            let b = Lern.z((11 - a)...9)
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b,
                             erklaerung: "\(a) + \(10 - a) = 10, dann noch \(a + b - 10) dazu: \(a + b)")
        }
        let a = Lern.z(11...18)
        let b = Lern.z((a % 10 + 1)...9)
        return Lern.zahl(rechne, "\(a) - \(b) =", a - b,
                         erklaerung: "\(a) - \(a - 10) = 10, dann noch \(b - (a - 10)) weg: \(a - b)")
    }

    static func nachbarzahl() -> A {
        let n = Lern.z(2...19)
        switch Lern.z(0...2) {
        case 0:
            return Lern.zahl("Welche Zahl kommt danach?", "\(n), ?", n + 1,
                             erklaerung: "Nach \(n) kommt \(n + 1).")
        case 1:
            return Lern.zahl("Welche Zahl kommt davor?", "?, \(n)", n - 1,
                             erklaerung: "Vor \(n) kommt \(n - 1).")
        default:
            let m = min(n, 18)
            return Lern.zahl("Welche Zahl liegt dazwischen?", "\(m - 1), ?, \(m + 1)", m,
                             erklaerung: "Zwischen \(m - 1) und \(m + 1) liegt \(m).")
        }
    }

    // MARK: Klasse 2

    static func hundert() -> A {
        switch Lern.z(0...3) {
        case 0:
            let a = Lern.z(2...8) * 10
            let b = Lern.z(1...(9 - a / 10)) * 10
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 1:
            let a = Lern.z(11...89)
            let b = Lern.z(2...(99 - a))
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 2:
            let a = Lern.z(20...99)
            let b = Lern.z(2...(a - 5))
            return Lern.zahl(rechne, "\(a) - \(b) =", a - b, erklaerung: "\(a) - \(b) = \(a - b)")
        default:
            let a = Lern.z(3...9) * 10
            let b = Lern.z(1...(a / 10 - 1)) * 10
            return Lern.zahl(rechne, "\(a) - \(b) =", a - b, erklaerung: "\(a) - \(b) = \(a - b)")
        }
    }

    static func zehnerEiner() -> A {
        let z = Lern.z(1...9)
        let e = Lern.z(0...9)
        let n = 10 * z + e
        switch Lern.z(0...2) {
        case 0:
            return Lern.zahl("Welche Zahl ist das?", "\(z) Zehner und \(e) Einer", n,
                             erklaerung: "\(z) Zehner sind \(10 * z), dazu \(e) Einer: \(n)")
        case 1:
            return Lern.zahl("Wie viele Zehner hat die Zahl?", "\(n)", z,
                             erklaerung: "\(n) = \(10 * z) + \(e). Das sind \(z) Zehner.")
        default:
            return Lern.zahl("Wie viele Einer hat die Zahl?", "\(n)", e,
                             erklaerung: "\(n) = \(10 * z) + \(e). Das sind \(e) Einer.")
        }
    }

    static func kern() -> A {
        if Lern.wahr(0.2) {
            let q = Lern.z(2...10)
            return Lern.zahl("Das ist eine Quadratzahl.", "\(q) · \(q) =", q * q,
                             erklaerung: "\(q) · \(q) = \(q * q)")
        }
        let k = Lern.eins([0, 1, 2, 5, 10])
        let n = Lern.z(1...10)
        let vorn = Lern.wahr(0.5)
        let r = vorn ? "\(k) · \(n) =" : "\(n) · \(k) ="
        let e = k == 0 ? "Mal 0 ist immer 0." : (vorn ? "\(k) · \(n)" : "\(n) · \(k)") + " = \(k * n)"
        return Lern.zahl("Das ist eine Kernaufgabe.", r, k * n, erklaerung: e)
    }

    static func einmaleins() -> A {
        let a = Lern.z(2...10)
        let b = Lern.z(2...10)
        return Lern.zahl(rechne, "\(a) · \(b) =", a * b, erklaerung: "\(a) · \(b) = \(a * b)")
    }

    static func geteilt() -> A {
        let t = Lern.z(2...10)
        let q = Lern.z(1...10)
        return Lern.zahl("Rechne und denk an die Umkehraufgabe.", "\(t * q) : \(t) =", q,
                         erklaerung: "\(t * q) : \(t) = \(q), denn \(q) · \(t) = \(t * q)",
                         hinweis: "Denn ___ · \(t) = \(t * q)")
    }

    static func geld() -> A {
        switch Lern.z(0...2) {
        case 0:
            let e = Lern.z(1...9)
            let c = Lern.z(1...19) * 5
            return Lern.zahl("Wie viel Cent sind das?", "\(e) € \(c) ct = ? ct", e * 100 + c,
                             erklaerung: "\(e) € sind \(e * 100) ct, dazu \(c) ct: \(e * 100 + c) ct")
        case 1:
            let c = Lern.z(1...19) * 5
            return Lern.zahl("Wie viel Cent fehlen bis 1 €?", "\(c) ct + ? ct = 1 €", 100 - c,
                             erklaerung: "1 € sind 100 ct. \(c) ct + \(100 - c) ct = 100 ct")
        default:
            let e = Lern.z(2...9)
            return Lern.zahl("Wie viel Cent sind das?", "\(e) € = ? ct", e * 100,
                             erklaerung: "1 € sind 100 ct, also sind \(e) € \(e * 100) ct.")
        }
    }

    static func uhr() -> A {
        switch Lern.z(0...3) {
        case 0:
            let teil = Lern.eins([("eine halbe Stunde", 30), ("eine Viertelstunde", 15),
                                  ("eine Dreiviertelstunde", 45), ("eine Stunde", 60)])
            return Lern.zahl("Wie viele Minuten sind das?", teil.0.prefix(1).uppercased() + teil.0.dropFirst(), teil.1,
                             erklaerung: "\(teil.0.prefix(1).uppercased() + teil.0.dropFirst()) hat \(teil.1) Minuten.")
        case 1:
            let m = Lern.z(1...11) * 5
            return Lern.zahl("Wie viele Minuten sind das?", "1 Stunde \(m) Minuten", 60 + m,
                             erklaerung: "60 Minuten + \(m) Minuten = \(60 + m) Minuten")
        case 2:
            let h = Lern.z(2...3)
            return Lern.zahl("Wie viele Minuten sind das?", "\(h) Stunden", 60 * h,
                             erklaerung: "\(h) · 60 Minuten = \(60 * h) Minuten")
        default:
            let von = Lern.z(7...15)
            let dauer = Lern.z(1...5)
            return Lern.zahl("Wie viele Stunden sind das?", "Von \(von) Uhr bis \(von + dauer) Uhr", dauer,
                             erklaerung: "Von \(von) bis \(von + dauer) Uhr sind es \(dauer) \(dauer == 1 ? "Stunde" : "Stunden").")
        }
    }

    // MARK: Klasse 3

    static func tausend() -> A {
        switch Lern.z(0...3) {
        case 0:
            let a = Lern.z(1...8) * 100
            let b = Lern.z(1...(9 - a / 100)) * 100
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 1:
            let a = Lern.z(10...80) * 10
            let b = Lern.z(1...(99 - a / 10)) * 10
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        case 2:
            let a = Lern.z(20...99) * 10
            let b = Lern.z(1...(a / 10 - 1)) * 10
            return Lern.zahl(rechne, "\(a) - \(b) =", a - b, erklaerung: "\(a) - \(b) = \(a - b)")
        default:
            let a = Lern.z(101...989)
            let b = Lern.z(2...9)
            return Lern.zahl(rechne, "\(a) + \(b) =", a + b, erklaerung: "\(a) + \(b) = \(a + b)")
        }
    }

    static func schriftPlus() -> A {
        let a = Lern.z(100...799)
        let b = Lern.z(100...(999 - a))
        return Lern.zahl("Rechne schriftlich.", "\(a) + \(b) =", a + b,
                         erklaerung: "\(a) + \(b) = \(a + b)",
                         hinweis: "Einer, dann Zehner, dann Hunderter.")
    }

    static func schriftMinus() -> A {
        let a = Lern.z(300...999)
        let b = Lern.z(100...(a - 50))
        return Lern.zahl("Rechne schriftlich.", "\(a) - \(b) =", a - b,
                         erklaerung: "\(a) - \(b) = \(a - b). Probe: \(a - b) + \(b) = \(a)",
                         hinweis: "Einer, dann Zehner, dann Hunderter.")
    }

    static func rest() -> A {
        var t = 2, q = 2, r = 1
        repeat {
            t = Lern.z(2...9)
            q = Lern.z(2...12)
            r = Lern.z(1...(t - 1))
        } while t * q + r > 100
        let n = t * q + r
        return LernAufgabe(art: "rest", frage: "Teile mit Rest. Rechne bis zum Ende.", rechnung: "\(n) : \(t) =",
                           antwort: String(q), antwort2: String(r),
                           erklaerung: "\(n) : \(t) = \(q) Rest \(r), denn \(q) · \(t) = \(q * t) und \(q * t) + \(r) = \(n)")
    }

    static func laengen() -> A {
        switch Lern.z(0...4) {
        case 0:
            let m = Lern.z(1...9)
            let cm = Lern.z(1...19) * 5
            return Lern.zahl("Wie viele Zentimeter sind das?", "\(m) m \(cm) cm = ? cm", m * 100 + cm,
                             erklaerung: "\(m) m sind \(m * 100) cm, dazu \(cm) cm: \(m * 100 + cm) cm")
        case 1:
            let m = Lern.z(2...9)
            return Lern.zahl("Wie viele Zentimeter sind das?", "\(m) m = ? cm", m * 100,
                             erklaerung: "1 m sind 100 cm, also \(m) m = \(m * 100) cm")
        case 2:
            let m = Lern.z(2...9)
            return Lern.zahl("Wie viele Meter sind das?", "\(m * 100) cm = ? m", m,
                             erklaerung: "100 cm sind 1 m, also \(m * 100) cm = \(m) m")
        case 3:
            let km = Lern.z(2...9)
            return Lern.zahl("Wie viele Meter sind das?", "\(km) km = ? m", km * 1000,
                             erklaerung: "1 km sind 1000 m, also \(km) km = \(km * 1000) m")
        default:
            let km = Lern.z(1...5)
            let m = Lern.z(1...9) * 100
            return Lern.zahl("Wie viele Meter sind das?", "\(km) km \(m) m = ? m", km * 1000 + m,
                             erklaerung: "\(km) km sind \(km * 1000) m, dazu \(m) m: \(km * 1000 + m) m")
        }
    }

    static func gewicht() -> A {
        switch Lern.z(0...3) {
        case 0:
            let kg = Lern.z(2...9)
            return Lern.zahl("Wie viele Gramm sind das?", "\(kg) kg = ? g", kg * 1000,
                             erklaerung: "1 kg sind 1000 g, also \(kg) kg = \(kg * 1000) g")
        case 1:
            let kg = Lern.z(1...5)
            let g = Lern.z(1...9) * 100
            return Lern.zahl("Wie viele Gramm sind das?", "\(kg) kg \(g) g = ? g", kg * 1000 + g,
                             erklaerung: "\(kg) kg sind \(kg * 1000) g, dazu \(g) g: \(kg * 1000 + g) g")
        case 2:
            let kg = Lern.z(2...9)
            return Lern.zahl("Wie viele Kilogramm sind das?", "\(kg * 1000) g = ? kg", kg,
                             erklaerung: "1000 g sind 1 kg, also \(kg * 1000) g = \(kg) kg")
        default:
            let g = Lern.z(1...9) * 100
            return Lern.zahl("Wie viel Gramm fehlen bis 1 kg?", "\(g) g + ? g = 1 kg", 1000 - g,
                             erklaerung: "1 kg sind 1000 g. \(g) g + \(1000 - g) g = 1000 g")
        }
    }

    // MARK: Klasse 4

    static func million() -> A {
        switch Lern.z(0...3) {
        case 0:
            let n = Lern.z(10...999) * 1000 - 1
            return Lern.zahl("Welche Zahl kommt danach?", "\(Lern.gross(n)), ?", n + 1,
                             erklaerung: "Nach \(Lern.gross(n)) kommt \(Lern.gross(n + 1)).")
        case 1:
            let n = Lern.z(10...999) * 1000
            return Lern.zahl("Welche Zahl kommt davor?", "?, \(Lern.gross(n))", n - 1,
                             erklaerung: "Vor \(Lern.gross(n)) kommt \(Lern.gross(n - 1)).")
        case 2:
            let n = Lern.z(100_000...999_999)
            let stelle = Lern.eins([("Hunderterstelle", 100), ("Tausenderstelle", 1000),
                                    ("Zehntausenderstelle", 10_000)])
            let ziffer = (n / stelle.1) % 10
            return Lern.zahl("Welche Ziffer steht an der \(stelle.0)?", Lern.gross(n), ziffer,
                             erklaerung: "In \(Lern.gross(n)) steht an der \(stelle.0) eine \(ziffer).")
        default:
            let n = Lern.z(100...9_000) * 100
            let plus = Lern.eins([1000, 10_000])
            return Lern.zahl(rechne, "\(Lern.gross(n)) + \(Lern.gross(plus)) =", n + plus,
                             erklaerung: "\(Lern.gross(n)) + \(Lern.gross(plus)) = \(Lern.gross(n + plus))")
        }
    }

    /// Kaufmännisch runden wie in der Schule: ab 5 aufrunden
    static func gerundet(_ n: Int, auf stelle: Int) -> Int {
        ((n + stelle / 2) / stelle) * stelle
    }

    static func runden() -> A {
        let ziel = Lern.eins([("Zehner", 10), ("Hunderter", 100), ("Tausender", 1000)])
        let n = Lern.z(1_001...99_999)
        let g = gerundet(n, auf: ziel.1)
        return Lern.zahl("Runde auf \(ziel.0).", Lern.gross(n), g,
                         erklaerung: "\(Lern.gross(n)) wird gerundet zu \(Lern.gross(g)).")
    }

    static func schriftMal() -> A {
        if Lern.wahr(0.6) {
            let a = Lern.z(101...999)
            let b = Lern.z(2...9)
            return Lern.zahl("Rechne schriftlich.", "\(a) · \(b) =", a * b,
                             erklaerung: "\(a) · \(b) = \(Lern.gross(a * b))")
        }
        let a = Lern.z(12...49)
        let b = Lern.z(12...29)
        return Lern.zahl("Rechne schriftlich.", "\(a) · \(b) =", a * b,
                         erklaerung: "\(a) · \(b) = \(a * 10 * (b / 10)) + \(a * (b % 10)) = \(a * b)")
    }

    static func schriftGeteilt() -> A {
        let t = Lern.z(2...9)
        let q = Lern.z(101...999)
        let n = t * q
        return Lern.zahl("Rechne schriftlich.", "\(n) : \(t) =", q,
                         erklaerung: "\(n) : \(t) = \(q). Probe: \(q) · \(t) = \(n)")
    }

    static func uhrzeit(_ minuten: Int) -> String {
        let h = (minuten / 60) % 24
        let m = minuten % 60
        return String(format: "%d:%02d", h, m)
    }

    static func zeitspanne() -> A {
        let start = Lern.z(7 * 12...16 * 12) * 5
        let dauer = Lern.z(4...30) * 5
        return Lern.zahl("Wie viele Minuten sind das?",
                         "Von \(uhrzeit(start)) Uhr bis \(uhrzeit(start + dauer)) Uhr", dauer,
                         erklaerung: "Von \(uhrzeit(start)) Uhr bis \(uhrzeit(start + dauer)) Uhr sind es \(dauer) Minuten.")
    }

    static let bruchListe: [(String, String, Int)] = [
        ("¼ Stunde", "min", 15), ("½ Stunde", "min", 30), ("¾ Stunde", "min", 45), ("1 ½ Stunden", "min", 90),
        ("½ kg", "g", 500), ("¼ kg", "g", 250), ("¾ kg", "g", 750), ("1 ½ kg", "g", 1500),
        ("½ m", "cm", 50), ("¼ m", "cm", 25), ("¾ m", "cm", 75),
        ("½ l", "ml", 500), ("¼ l", "ml", 250), ("1 ½ l", "ml", 1500),
        ("½ km", "m", 500), ("¼ km", "m", 250)
    ]

    static func brueche() -> A {
        let b = Lern.eins(bruchListe)
        return Lern.zahl("Rechne um.", "\(b.0) = ? \(b.1)", b.2,
                         erklaerung: "\(b.0) sind \(b.2) \(b.1).")
    }
}
