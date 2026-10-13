import Foundation

// ============================================================
// MARK: - Fehler-Analyse
// ============================================================
//
// Erkennt typische Denkfehler aus Rechnung, Eingabe und Lösung.
// Das macht ausschließlich der Code, damit nichts Falsches als Grund genannt wird.
// Die KI (KIText.swift) darf die Sätze danach höchstens schöner formulieren.
// Benutzt vom Erklär-Freund auf dem Kind-Gerät und vom Elternbericht.

enum FehlerMuster: String, CaseIterable {
    // Teilen mit Rest
    case restZuGross, restFalsch, geteiltZuViel
    // Rechnen
    case plusStattMal, malStattPlus, plusStattMinus, minusStattPlus, malStattGeteilt
    case malReiheZuViel, malReiheZuWenig, geteiltDaneben
    case punktVorStrich, zifferDreher, zehnerDaneben, knappDaneben
    // Größer oder kleiner
    case vergleichUmgedreht, gleichUebersehen, nichtGleich
    // Rechtschreibung
    case grossKlein, hartWeich, aeStattE, doppelterMitlaut, ieStattI, einBuchstabe

    /// Kurze Beschreibung für die Eltern, so dass sie hinter dem Namen stehen kann:
    /// "Yemin hört beim Teilen mit Rest zu früh auf."
    var elternText: String {
        switch self {
        case .restZuGross: return "hört beim Teilen mit Rest zu früh auf, der Rest ist dann zu groß"
        case .restFalsch: return "hat beim Teilen mit Rest das Ergebnis richtig, aber den Rest nicht genau ausgerechnet"
        case .geteiltZuViel: return "nimmt beim Teilen eine zu große Zahl"
        case .plusStattMal, .malStattPlus, .plusStattMinus, .minusStattPlus, .malStattGeteilt:
            return "verwechselt manchmal die Rechenzeichen"
        case .malReiheZuViel, .malReiheZuWenig:
            return "nimmt beim Malrechnen eine Reihe zu viel oder zu wenig"
        case .geteiltDaneben: return "liegt beim Geteilt daneben und prüft nicht mit der Umkehraufgabe"
        case .punktVorStrich: return "rechnet von links nach rechts statt Punkt vor Strich"
        case .zifferDreher: return "vertauscht manchmal die Ziffern einer Zahl"
        case .zehnerDaneben: return "verrechnet sich bei den Zehnern"
        case .knappDaneben: return "liegt oft nur um 1 daneben, eher Flüchtigkeit"
        case .vergleichUmgedreht: return "verwechselt die Zeichen < und >"
        case .gleichUebersehen, .nichtGleich: return "erkennt nicht sicher, wann beide Seiten gleich sind"
        case .grossKlein: return "achtet nicht immer auf groß und klein"
        case .hartWeich: return "verwechselt d und t, g und k oder b und p"
        case .aeStattE: return "verwechselt e und ä"
        case .doppelterMitlaut: return "vergisst doppelte Mitlaute wie in Sonne"
        case .ieStattI: return "schreibt i statt ie"
        case .einBuchstabe: return "macht Flüchtigkeitsfehler bei einzelnen Buchstaben"
        }
    }

    /// Ein praktischer Tipp für zu Hause, wenn es einen gibt.
    var elternTipp: String? {
        switch self {
        case .restZuGross: return "Gemeinsam prüfen: Ist der Rest kleiner als die Zahl, durch die geteilt wird? Wenn nicht, passt sie noch einmal hinein."
        case .restFalsch: return "Den Rest mit einer Malaufgabe prüfen: Ergebnis mal Teiler, dann bis zur Ausgangszahl auffüllen."
        case .malReiheZuViel, .malReiheZuWenig: return "Die Einmaleins-Reihe laut zählen, dabei an den Fingern mitzählen, wie viele es sind."
        case .geteiltDaneben, .geteiltZuViel: return "Nach jeder Geteilt-Aufgabe die Umkehraufgabe sagen lassen: Ergebnis mal Teiler."
        case .punktVorStrich: return "Einen Bogen unter die Mal- oder Geteiltaufgabe malen und die zuerst ausrechnen."
        case .vergleichUmgedreht: return "Merkhilfe: Das Krokodil frisst immer die größere Zahl, das offene Maul zeigt zu ihr."
        case .hartWeich: return "Das Wort verlängern: der Hund, die Hunde. Dann hört man, ob d oder t."
        case .aeStattE: return "Ein verwandtes Wort mit a suchen: Äpfel kommt von Apfel."
        case .doppelterMitlaut: return "Das Wort langsam klatschen. Nach einem kurzen Selbstlaut folgen oft zwei gleiche Mitlaute."
        case .ieStattI: return "Lang gesprochenes i schreibt man meistens ie, wie in Biene."
        case .zifferDreher: return "Zahlen erst laut sagen, dann schreiben: siebenundsechzig, also zuerst die 6."
        default: return nil
        }
    }
}

struct FehlerBefund: Equatable {
    let muster: FehlerMuster
    /// Kindgerechte Erklärung, ohne KI. Stimmt immer, weil sie aus den Zahlen der Aufgabe gebaut ist.
    let satz: String
}

/// Eine einfache Rechnung ohne Klammern, zum Beispiel 9 · 9 + 8.
struct Rechenausdruck: Equatable {
    let zahlen: [Int]
    /// "+", "-", "*" oder "/", eins weniger als Zahlen
    let zeichen: [Character]

    /// Mit Punkt vor Strich, so wie es richtig ist. nil bei Teilen durch 0.
    var wert: Int? { Self.rechne(zahlen, zeichen, punktZuerst: true) }
    /// Stur von links nach rechts, der typische Fehler.
    var linksNachRechts: Int? { Self.rechne(zahlen, zeichen, punktZuerst: false) }

    private static func rechne(_ z: [Int], _ op: [Character], punktZuerst: Bool) -> Int? {
        guard z.count == op.count + 1, !z.isEmpty else { return nil }
        func an(_ a: Int, _ o: Character, _ b: Int) -> Int? {
            switch o {
            case "+": return a + b
            case "-": return a - b
            case "*": return a * b
            case "/": return b == 0 ? nil : a / b
            default: return nil
            }
        }
        if !punktZuerst {
            var w = z[0]
            for (i, o) in op.enumerated() {
                guard let n = an(w, o, z[i + 1]) else { return nil }
                w = n
            }
            return w
        }
        // Erst alle Punktrechnungen zusammenfassen, dann Strich
        var werte = [z[0]]
        var striche: [Character] = []
        for (i, o) in op.enumerated() {
            if o == "*" || o == "/" {
                guard let letzter = werte.popLast(), let n = an(letzter, o, z[i + 1]) else { return nil }
                werte.append(n)
            } else {
                striche.append(o)
                werte.append(z[i + 1])
            }
        }
        var w = werte[0]
        for (i, o) in striche.enumerated() {
            guard let n = an(w, o, werte[i + 1]) else { return nil }
            w = n
        }
        return w
    }

    /// Liest "7 · 8 =" oder "58 : 4 = 14 R 2" (nur bis zum Gleichzeichen).
    /// Wörter, Klammern oder leere Texte ergeben nil.
    static func lies(_ text: String) -> Rechenausdruck? {
        let ersteZeile = text.split(whereSeparator: { $0.isNewline }).first.map(String.init) ?? ""
        let links = ersteZeile.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            .first.map(String.init) ?? ""
        guard !links.trimmingCharacters(in: .whitespaces).isEmpty,
              let tokens = try? MatheRechner.zerlege(links) else { return nil }
        var zahlen: [Int] = []
        var zeichen: [Character] = []
        for (i, t) in tokens.enumerated() {
            switch t {
            case .zahl(let n):
                guard i % 2 == 0 else { return nil }
                zahlen.append(n)
            case .op(let o):
                guard i % 2 == 1 else { return nil }
                zeichen.append(o)
            default:
                return nil
            }
        }
        guard zahlen.count >= 2, zahlen.count == zeichen.count + 1 else { return nil }
        return Rechenausdruck(zahlen: zahlen, zeichen: zeichen)
    }
}

enum FehlerAnalyse {

    // MARK: Einstieg (Kind-Gerät)

    /// Sucht den Grund für eine falsche Antwort. nil, wenn kein bekanntes Muster passt.
    /// - Parameters:
    ///   - erklaerung: die Erklärung aus dem JSON, zum Beispiel "75 - 8 = 67". Hilft bei Wortaufgaben.
    ///   - eingabe2: der eingegebene Rest bei Teilen mit Rest
    static func befund(art: String, rechnung: String, erklaerung: String,
                       antwort: String, antwort2: String,
                       eingabe: String, eingabe2: String = "") -> FehlerBefund? {
        let ausdruck = Rechenausdruck.lies(rechnung) ?? Rechenausdruck.lies(erklaerung)
        switch art {
        case "rest":
            guard let q = Int(antwort), let r = Int(antwort2),
                  let qi = Int(eingabe.trimmingCharacters(in: .whitespaces)),
                  let ri = Int(eingabe2.trimmingCharacters(in: .whitespaces)) else { return nil }
            return rest(ausdruck, q: q, r: r, qi: qi, ri: ri)
        case "vergleich":
            return vergleich(soll: antwort, ist: eingabe, erklaerung: erklaerung)
        case "text":
            return text(soll: antwort, ist: eingabe)
        case "mauer":
            return nil
        default:
            guard let soll = Int(antwort), let ist = Int(eingabe.trimmingCharacters(in: .whitespaces)) else { return nil }
            return zahl(ausdruck, soll: soll, ist: ist)
        }
    }

    // MARK: Einstieg (Eltern-Gerät)

    /// Dasselbe für einen Eintrag aus dem Antwort-Protokoll. Dort ist die Art nicht gespeichert,
    /// sie ergibt sich aus der Lösung.
    static func befund(detail d: AntwortDetail) -> FehlerBefund? {
        guard d.stand == AntwortStand.falsch else { return nil }
        if d.rechnung.hasPrefix("Zahlenmauer") { return nil }
        let teile = d.loesung.components(separatedBy: " Rest ")
        if teile.count == 2 {
            let ein = d.eingabe.components(separatedBy: " Rest ")
            guard ein.count == 2 else { return nil }
            return befund(art: "rest", rechnung: d.rechnung, erklaerung: "",
                          antwort: teile[0], antwort2: teile[1],
                          eingabe: ein[0], eingabe2: ein[1])
        }
        if ["<", ">", "="].contains(d.loesung) {
            return befund(art: "vergleich", rechnung: d.rechnung, erklaerung: "",
                          antwort: d.loesung, antwort2: "", eingabe: d.eingabe)
        }
        if Int(d.loesung) != nil {
            return befund(art: "zahl", rechnung: d.rechnung, erklaerung: "",
                          antwort: d.loesung, antwort2: "", eingabe: d.eingabe)
        }
        return befund(art: "text", rechnung: d.rechnung, erklaerung: "",
                      antwort: d.loesung, antwort2: "", eingabe: d.eingabe)
    }

    // MARK: Teilen mit Rest

    private static func rest(_ a: Rechenausdruck?, q: Int, r: Int, qi: Int, ri: Int) -> FehlerBefund? {
        guard !(qi == q && ri == r) else { return nil }
        let dividend = a?.zahlen.count == 2 && a?.zeichen.first == "/" ? a?.zahlen[0] : nil
        let teiler = a?.zahlen.count == 2 && a?.zeichen.first == "/" ? a?.zahlen[1] : nil
        guard let n = dividend, let t = teiler, t > 0 else { return nil }
        let richtig = "\(n) : \(t) = \(q) Rest \(r)"
        if ri >= t, qi < q {
            var s = "Dein Rest \(ri) ist nicht kleiner als \(t). Dann passt die \(t) noch hinein."
            if qi == 10 { s += " Du bist bei 10 stehen geblieben." }
            s += " Teile weiter, bis der Rest kleiner ist als \(t): \(richtig)."
            return FehlerBefund(muster: .restZuGross, satz: s)
        }
        if qi == q {
            return FehlerBefund(muster: .restFalsch,
                                satz: "Das Ergebnis \(q) stimmt. Jetzt der Rest: \(q) · \(t) = \(q * t). Bis \(n) fehlen noch \(r). Also \(richtig).")
        }
        if qi * t > n {
            return FehlerBefund(muster: .geteiltZuViel,
                                satz: "\(qi) · \(t) = \(qi * t), das ist schon mehr als \(n). Nimm eine kleinere Zahl. Richtig ist \(richtig).")
        }
        return nil
    }

    // MARK: Rechnen

    private static func zahl(_ a: Rechenausdruck?, soll: Int, ist: Int) -> FehlerBefund? {
        guard soll != ist else { return nil }
        if let a, a.zahlen.count == 2, let op = a.zeichen.first {
            let x = a.zahlen[0], y = a.zahlen[1]
            let richtig = "\(x) \(zeichenText(op)) \(y) = \(soll)"
            switch op {
            case "*":
                if ist == x + y {
                    return FehlerBefund(muster: .plusStattMal,
                                        satz: "Du hast plus gerechnet. Der Punkt heißt mal: \(richtig).")
                }
                for (reihe, anzahl) in [(y, x), (x, y)] where reihe > 0 {
                    if ist == soll + reihe {
                        return FehlerBefund(muster: .malReiheZuViel,
                                            satz: "Du hast eine \(reihe) zu viel genommen. \(anzahl) mal die \(reihe) sind \(soll). Also \(richtig).")
                    }
                    if ist == soll - reihe {
                        return FehlerBefund(muster: .malReiheZuWenig,
                                            satz: "Dir fehlt noch eine \(reihe). \(anzahl) mal die \(reihe) sind \(soll). Also \(richtig).")
                    }
                }
            case "/":
                if ist == x * y {
                    return FehlerBefund(muster: .malStattGeteilt,
                                        satz: "Du hast mal gerechnet. Der Doppelpunkt heißt geteilt: \(richtig).")
                }
                if ist > 0, y > 0 {
                    return FehlerBefund(muster: .geteiltDaneben,
                                        satz: "Prüf es mit der Umkehraufgabe: \(ist) · \(y) = \(ist * y), das ist nicht \(x). Aber \(soll) · \(y) = \(x). Also \(richtig).")
                }
            case "+":
                if ist == x - y {
                    return FehlerBefund(muster: .minusStattPlus,
                                        satz: "Du hast minus gerechnet. Hier steht plus: \(richtig).")
                }
                if ist == x * y {
                    return FehlerBefund(muster: .malStattPlus,
                                        satz: "Du hast mal gerechnet. Hier steht plus: \(richtig).")
                }
            case "-":
                if ist == x + y {
                    return FehlerBefund(muster: .plusStattMinus,
                                        satz: "Du hast plus gerechnet. Hier steht minus: \(richtig).")
                }
            default:
                break
            }
        }
        if let a, a.zahlen.count >= 3, let falsch = a.linksNachRechts, falsch == ist, falsch != soll {
            return FehlerBefund(muster: .punktVorStrich,
                                satz: "Du hast von links nach rechts gerechnet. Es gilt Punkt vor Strich: Rechne zuerst mal oder geteilt, dann plus oder minus. Dann kommt \(soll) heraus.")
        }
        if istZifferDreher(soll, ist) {
            return FehlerBefund(muster: .zifferDreher,
                                satz: "Fast! Du hast die Ziffern vertauscht. Richtig ist \(soll), nicht \(ist).")
        }
        if abs(soll - ist) == 10 {
            return FehlerBefund(muster: .zehnerDaneben,
                                satz: "Die Einer stimmen, aber bei den Zehnern bist du um 10 daneben. Richtig ist \(soll).")
        }
        if abs(soll - ist) == 1 {
            return FehlerBefund(muster: .knappDaneben,
                                satz: "Ganz knapp! Du bist nur um 1 daneben. Richtig ist \(soll).")
        }
        return nil
    }

    static func istZifferDreher(_ a: Int, _ b: Int) -> Bool {
        guard a != b, a >= 10, b >= 10 else { return false }
        return String(String(a).reversed()) == String(b)
    }

    private static func zeichenText(_ o: Character) -> String {
        switch o {
        case "*": return "·"
        case "/": return ":"
        default: return String(o)
        }
    }

    // MARK: Größer oder kleiner

    private static func vergleich(soll: String, ist: String, erklaerung: String) -> FehlerBefund? {
        guard soll != ist, ["<", ">", "="].contains(ist) else { return nil }
        let beleg = erklaerung.isEmpty ? "" : " Richtig ist: \(erklaerung)."
        if soll == "=" {
            return FehlerBefund(muster: .gleichUebersehen,
                                satz: "Rechne beide Seiten aus. Sie sind genau gleich groß, deshalb gehört = in die Mitte.\(beleg)")
        }
        if ist == "=" {
            return FehlerBefund(muster: .nichtGleich,
                                satz: "Rechne beide Seiten aus. Sie sind nicht gleich groß.\(beleg)")
        }
        return FehlerBefund(muster: .vergleichUmgedreht,
                            satz: "Das Zeichen ist umgedreht. Die Spitze zeigt immer zur kleineren Zahl, die offene Seite zur größeren.\(beleg)")
    }

    // MARK: Rechtschreibung

    private static func text(soll rohSoll: String, ist rohIst: String) -> FehlerBefund? {
        let soll = rohSoll.trimmingCharacters(in: .whitespaces)
        let ist = rohIst.trimmingCharacters(in: .whitespaces)
        guard !soll.isEmpty, !ist.isEmpty, soll != ist else { return nil }
        if soll.lowercased() == ist.lowercased() {
            let gross = soll.first?.isUppercase == true && ist.first?.isUppercase == false
            let satz = gross
                ? "Fast! Das schreibt man groß: \(soll)."
                : "Fast! Achte auf groß und klein. Richtig ist: \(soll)."
            return FehlerBefund(muster: .grossKlein, satz: satz)
        }
        let s = Array(soll.lowercased()), i = Array(ist.lowercased())
        // Ein Buchstabe ausgetauscht
        if s.count == i.count {
            let unterschiede = zip(s, i).enumerated().filter { $0.element.0 != $0.element.1 }
            if unterschiede.count == 1, let u = unterschiede.first {
                let paar = Set([u.element.0, u.element.1])
                if [Set<Character>(["d", "t"]), Set<Character>(["g", "k"]), Set<Character>(["b", "p"])].contains(paar) {
                    return FehlerBefund(muster: .hartWeich,
                                        satz: "Am Wortende klingen \(u.element.0) und \(u.element.1) fast gleich. Verlängere das Wort, dann hörst du es. Richtig ist: \(soll).")
                }
                if paar == Set<Character>(["e", "ä"]) {
                    return FehlerBefund(muster: .aeStattE,
                                        satz: "Suche ein verwandtes Wort mit a, dann weißt du, ob ä oder e. Richtig ist: \(soll).")
                }
                if soll.count >= 3 {
                    return FehlerBefund(muster: .einBuchstabe,
                                        satz: "Fast! Nur ein Buchstabe ist anders. Richtig ist: \(soll).")
                }
            }
        }
        // Ein Buchstabe fehlt
        if s.count == i.count + 1 {
            for k in s.indices {
                var kurz = s
                kurz.remove(at: k)
                guard kurz == i else { continue }
                if k > 0, s[k] == s[k - 1] || (k + 1 < s.count && s[k] == s[k + 1]) {
                    return FehlerBefund(muster: .doppelterMitlaut,
                                        satz: "Hier kommt ein Buchstabe doppelt. Nach einem kurz gesprochenen Selbstlaut folgen oft zwei gleiche Mitlaute. Richtig ist: \(soll).")
                }
                if s[k] == "e", k > 0, s[k - 1] == "i" {
                    return FehlerBefund(muster: .ieStattI,
                                        satz: "Das i klingt hier lang. Lang gesprochenes i schreibt man meistens ie. Richtig ist: \(soll).")
                }
                if soll.count >= 3 {
                    return FehlerBefund(muster: .einBuchstabe,
                                        satz: "Fast! Da fehlt nur ein Buchstabe. Richtig ist: \(soll).")
                }
            }
        }
        return nil
    }
}
