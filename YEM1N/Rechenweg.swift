import Foundation

// ============================================================
// MARK: - Rechenweg in Schritten
// ============================================================
//
// Das Kind rechnet eine Aufgabe nicht in einem Zug, sondern in kleinen Schritten,
// so wie im Heft: erst die Zehner, dann bis zum Zehner, dann der Rest.
// Jeder Schritt ist eine kleine Rechnung mit eigenem Feld. Am Ende steht das Ergebnis
// und kann in die Aufgabe übernommen werden.
//
//   Plus, Minus    Zehner, bis zum Zehner, Rest (wie die Sprünge am Zahlenstrahl)
//   Mal            Kernaufgabe und Nachbar, 7 = 5 + 2, 8 = 10 - 2, große Zahlen zerlegen
//   Geteilt        mit 5 · und 10 · zerlegen
//   Mit Rest       die passende Zahl der Reihe finden, dann den Rest
//   Mehrere        Punkt vor Strich, Schritt für Schritt
//   Vergleich      beide Seiten ausrechnen
// Der Weg entsteht nur aus der Rechnung selbst und wird gegen die Lösung geprüft.
// Passt etwas nicht, gibt es keinen Weg. Ein falscher Weg wäre schlimmer als keiner.
// Diese Datei braucht nur Foundation, damit pruefen/linux-tests.sh sie prüfen kann.

struct RechenSchritt: Equatable {
    /// Kurzer Satz, was in diesem Schritt passiert
    let hinweis: String
    /// Die kleine Rechnung, zum Beispiel "47 + 20 ="
    let rechnung: String
    let antwort: Int
}

struct RechenWeg: Equatable {
    let schritte: [RechenSchritt]
    /// Satz am Ende, zum Beispiel "Also ist 47 + 25 = 72."
    let schluss: String
    /// Was in die Aufgabe übernommen wird. nil beim Vergleichen, dort wählt das Kind das Zeichen.
    let antwort: String?
    let antwort2: String?
}

enum RechenWegPlan {
    typealias Plan = ErklaerBildPlan

    /// Der Rechenweg zu einer Aufgabe oder nil, wenn es keinen sinnvollen gibt.
    /// Wortaufgaben bekommen keinen, sonst würde der Weg die Rechnung verraten.
    static func weg(art: String, rechnung: String, antwort: String, antwort2: String = "") -> RechenWeg? {
        let soll = Int(antwort.trimmingCharacters(in: .whitespaces))
        switch art {
        case "zahl":
            guard let soll, let t = Plan.term(rechnung), Plan.wert(t) == soll else { return nil }
            return pruefe(zahlWeg(t), soll: soll)
        case "rest":
            guard let q = soll, let r = Int(antwort2.trimmingCharacters(in: .whitespaces)),
                  let t = Plan.term(rechnung), t.zeichen == [":"] else { return nil }
            let a = t.zahlen[0], b = t.zahlen[1]
            guard b > 1, a / b == q, a % b == r else { return nil }
            return restWeg(a, b)
        case "vergleich":
            return vergleichWeg(rechnung)
        default:
            return nil
        }
    }

    /// Mindestens zwei Schritte, sonst ist es kein Rechenweg. Und das Ende muss stimmen.
    private static func pruefe(_ w: RechenWeg?, soll: Int) -> RechenWeg? {
        guard let w, w.schritte.count >= 2, w.antwort == String(soll),
              w.schritte.last?.antwort == soll else { return nil }
        return w
    }

    private static func fertig(_ t: Plan.Term, _ schritte: [RechenSchritt], _ e: Int) -> RechenWeg {
        RechenWeg(schritte: schritte, schluss: "Also ist \(t.text) = \(e).", antwort: String(e), antwort2: nil)
    }

    // MARK: Eine oder mehrere Rechnungen

    static func zahlWeg(_ t: Plan.Term) -> RechenWeg? {
        if t.zeichen.count > 1 { return mehrereWeg(t) }
        let a = t.zahlen[0], b = t.zahlen[1]
        switch t.zeichen[0] {
        case "+": return plusMinusWeg(t, a, b, plus: true)
        case "-": return plusMinusWeg(t, a, b, plus: false)
        case "·": return malWeg(t, a, b)
        default: return geteiltWeg(t, a, b)
        }
    }

    static func plusMinusWeg(_ t: Plan.Term, _ a: Int, _ b: Int, plus: Bool) -> RechenWeg? {
        guard b > 0, plus || a >= b else { return nil }
        let teile = Plan.spruenge(von: a, plus: plus, um: b)
        var x = a
        var schritte: [RechenSchritt] = []
        for (i, s) in teile.enumerated() {
            let neu = x + s
            let betrag = abs(s)
            let hinweis: String
            if betrag % 100 == 0 { hinweis = "Erst die Hunderter." }
            else if betrag % 10 == 0 { hinweis = i == 0 ? "Erst die Zehner." : "Jetzt die Zehner." }
            else if neu % 10 == 0 && i < teile.count - 1 { hinweis = "Bis zum nächsten Zehner." }
            else { hinweis = i == teile.count - 1 && teile.count > 1 ? "Jetzt der Rest." : "Die Einer." }
            schritte.append(RechenSchritt(hinweis: hinweis, rechnung: "\(x) \(plus ? "+" : "-") \(betrag) =", antwort: neu))
            x = neu
        }
        return fertig(t, schritte, x)
    }

    static func malWeg(_ t: Plan.Term, _ a: Int, _ b: Int) -> RechenWeg? {
        let kern: Set<Int> = [1, 2, 5, 10]
        // Große Zahl zerlegen: 3 · 14 = 3 · 10 + 3 · 4
        if max(a, b) > 10 {
            guard min(a, b) <= 10, min(a, b) > 1 else { return nil }
            let klein = min(a, b), gross = max(a, b)
            let z = (gross / 10) * 10, e = gross % 10
            if e == 0 {
                // 3 · 40: erst 3 · 4, dann mal 10
                guard gross % 10 == 0, gross / 10 <= 10 else { return nil }
                let p = klein * (gross / 10)
                return fertig(t, [
                    RechenSchritt(hinweis: "Rechne erst ohne die Null.", rechnung: "\(klein) · \(gross / 10) =", antwort: p),
                    RechenSchritt(hinweis: "Jetzt mal 10, also eine Null dran.", rechnung: "\(p) · 10 =", antwort: p * 10)
                ], p * 10)
            }
            return fertig(t, [
                RechenSchritt(hinweis: "Zerlege \(gross) in \(z) und \(e). Erst die Zehner.", rechnung: "\(klein) · \(z) =", antwort: klein * z),
                RechenSchritt(hinweis: "Dann die Einer.", rechnung: "\(klein) · \(e) =", antwort: klein * e),
                RechenSchritt(hinweis: "Zusammenzählen.", rechnung: "\(klein * z) + \(klein * e) =", antwort: klein * gross)
            ], klein * gross)
        }
        guard a > 0, b > 0 else { return nil }
        // Kernaufgaben sind schon ein Schritt, dafür braucht es keinen Weg
        if kern.contains(a) || kern.contains(b) { return nil }
        // Nachbar einer Kernaufgabe: 6 · 7 = 5 · 7 + 7. Sonst tauschen: 7 · 6 = 6 · 7
        for (r, s, getauscht) in [(a, b, false), (b, a, true)] {
            guard let k = Plan.kern(zu: r) else { continue }
            let mehr = r > k
            var schritte: [RechenSchritt] = []
            let tausch = getauscht ? "Tausche: \(a) · \(b) ist dasselbe wie \(r) · \(s). " : ""
            schritte.append(RechenSchritt(hinweis: tausch + "Die Kernaufgabe kennst du.", rechnung: "\(k) · \(s) =", antwort: k * s))
            schritte.append(RechenSchritt(hinweis: mehr ? "Eine Reihe mehr: noch einmal \(s) dazu." : "Eine Reihe weniger: \(s) weg.",
                                          rechnung: "\(k * s) \(mehr ? "+" : "-") \(s) =", antwort: r * s))
            return fertig(t, schritte, a * b)
        }
        // 7 und 8 (zum Beispiel 7 · 8): 7 = 5 + 2 oder 8 = 10 - 2
        let r = a, s = b
        if r == 7 {
            return fertig(t, [
                RechenSchritt(hinweis: "7 ist 5 und 2. Erst 5 mal.", rechnung: "5 · \(s) =", antwort: 5 * s),
                RechenSchritt(hinweis: "Dann 2 mal.", rechnung: "2 · \(s) =", antwort: 2 * s),
                RechenSchritt(hinweis: "Zusammenzählen.", rechnung: "\(5 * s) + \(2 * s) =", antwort: 7 * s)
            ], 7 * s)
        }
        if r == 8 {
            return fertig(t, [
                RechenSchritt(hinweis: "8 ist 10 weniger 2. Erst 10 mal.", rechnung: "10 · \(s) =", antwort: 10 * s),
                RechenSchritt(hinweis: "Dann 2 mal.", rechnung: "2 · \(s) =", antwort: 2 * s),
                RechenSchritt(hinweis: "Abziehen.", rechnung: "\(10 * s) - \(2 * s) =", antwort: 8 * s)
            ], 8 * s)
        }
        return nil
    }

    static func geteiltWeg(_ t: Plan.Term, _ a: Int, _ b: Int) -> RechenWeg? {
        guard b > 1, a % b == 0 else { return nil }
        let q = a / b
        // Bis 5 und genau 10 sind schnell gesehen, dafür braucht es keinen Weg
        if q <= 5 || q == 10 { return nil }
        // 60 : 3: erst ohne die Null rechnen, dann die Null wieder dran
        if q % 10 == 0, a % 10 == 0 {
            return fertig(t, [
                RechenSchritt(hinweis: "Rechne erst ohne die Null.", rechnung: "\(a / 10) : \(b) =", antwort: q / 10),
                RechenSchritt(hinweis: "Jetzt die Null wieder dran, also mal 10.", rechnung: "\(q / 10) · 10 =", antwort: q)
            ], q)
        }
        let z: Int
        let hinweis: String
        if q < 10 {
            z = 5
            hinweis = "Fang mit 5 mal an."
        } else {
            z = (q / 10) * 10
            hinweis = "Fang mit \(z) mal an."
        }
        let teil = z * b, rest = a - teil, q2 = rest / b
        guard q2 <= 10 else { return nil }
        var schritte = [
            RechenSchritt(hinweis: hinweis, rechnung: "\(z) · \(b) =", antwort: teil),
            RechenSchritt(hinweis: "Wie viel ist noch übrig?", rechnung: "\(a) - \(teil) =", antwort: rest)
        ]
        if rest > 0 {
            schritte.append(RechenSchritt(hinweis: "Den Rest auch teilen.", rechnung: "\(rest) : \(b) =", antwort: q2))
            schritte.append(RechenSchritt(hinweis: "Zusammenzählen.", rechnung: "\(z) + \(q2) =", antwort: q))
        }
        return fertig(t, schritte, q)
    }

    static func mehrereWeg(_ t: Plan.Term) -> RechenWeg? {
        var x = t
        var schritte: [RechenSchritt] = []
        let gemischt = t.zeichen.contains { $0 == "·" || $0 == ":" }
            && t.zeichen.contains { $0 == "+" || $0 == "-" }
        while !x.zeichen.isEmpty {
            guard let s = Plan.schritt(x) else { return nil }
            let teile = s.satz.components(separatedBy: " = ")
            guard teile.count == 2, let e = Int(teile[1]) else { return nil }
            let hinweis: String
            if schritte.isEmpty {
                hinweis = gemischt ? "Punkt vor Strich: zuerst Mal und Geteilt." : "Von links nach rechts."
            } else {
                hinweis = "Dann weiter mit dem Ergebnis."
            }
            schritte.append(RechenSchritt(hinweis: hinweis, rechnung: teile[0] + " =", antwort: e))
            x = s.neu
        }
        guard let e = x.zahlen.first else { return nil }
        return fertig(t, schritte, e)
    }

    // MARK: Teilen mit Rest

    static func restWeg(_ a: Int, _ b: Int) -> RechenWeg? {
        let q = a / b, r = a % b
        guard (2...10).contains(b), q <= 30 else { return nil }
        var schritte: [RechenSchritt] = []
        var start = 0
        var uebrig = a
        if q >= 10 {
            start = (q / 10) * 10
            schritte.append(RechenSchritt(hinweis: "Fang mit \(start) mal an.", rechnung: "\(start) · \(b) =", antwort: start * b))
            uebrig = a - start * b
            schritte.append(RechenSchritt(hinweis: "Wie viel ist noch übrig?", rechnung: "\(a) - \(start * b) =", antwort: uebrig))
        }
        let q2 = uebrig / b
        if q2 == 0 {
            // 42 : 4: nach 10 · 4 bleiben 2, da passt keine 4 mehr hinein
            schritte.append(RechenSchritt(hinweis: "Die \(b) passt nicht mehr in \(uebrig). Was übrig ist, ist der Rest.",
                                          rechnung: "Rest =", antwort: r))
        } else {
            let reihe = (1...min(q2 + 1, 10)).map { String($0 * b) }.joined(separator: ", ")
            schritte.append(RechenSchritt(
                hinweis: "Zähle in \(b)er-Schritten: \(reihe). Welche Zahl passt gerade noch in \(uebrig)?",
                rechnung: "\(b)er-Reihe bis \(uebrig):", antwort: q2 * b))
            schritte.append(RechenSchritt(hinweis: "Wie oft ist das die \(b)?", rechnung: "\(q2 * b) : \(b) =", antwort: q2))
            schritte.append(RechenSchritt(hinweis: "Was bleibt übrig? Das ist der Rest.", rechnung: "\(uebrig) - \(q2 * b) =", antwort: r))
            if start > 0 {
                schritte.append(RechenSchritt(hinweis: "Zusammenzählen, wie oft es gepasst hat.", rechnung: "\(start) + \(q2) =", antwort: q))
            }
        }
        guard r < b else { return nil }
        return RechenWeg(schritte: schritte, schluss: "Also ist \(a) : \(b) = \(q) Rest \(r).",
                         antwort: String(q), antwort2: String(r))
    }

    // MARK: Vergleichen

    static func vergleichWeg(_ rechnung: String) -> RechenWeg? {
        let seiten = rechnung.components(separatedBy: "?")
        guard seiten.count == 2 else { return nil }
        var schritte: [RechenSchritt] = []
        var werte: [Int] = []
        for (i, s) in seiten.enumerated() {
            let roh = s.trimmingCharacters(in: .whitespaces)
            if let n = Int(roh) { werte.append(n); continue }
            guard let t = Plan.term(roh), let w = Plan.wert(t) else { return nil }
            schritte.append(RechenSchritt(hinweis: i == 0 ? "Rechne die linke Seite aus." : "Rechne die rechte Seite aus.",
                                          rechnung: t.text + " =", antwort: w))
            werte.append(w)
        }
        guard werte.count == 2, !schritte.isEmpty else { return nil }
        return RechenWeg(schritte: schritte,
                         schluss: "Jetzt vergleichen: \(werte[0]) und \(werte[1]). Wähle das Zeichen.",
                         antwort: nil, antwort2: nil)
    }
}
