import SwiftUI
import Foundation

// ============================================================
// MARK: - Erklärbilder von Olli
// ============================================================
//
// Nach einem Fehler oder beim Lösung zeigen kann das Kind auf "Zeig es mir" tippen.
// Olli zeigt die Rechnung dann als Bild, Schritt für Schritt:
//   Mal          Punktefeld, Reihe für Reihe
//   Nachbar      erst die Kernaufgabe, dann eine Reihe mehr oder weniger
//   Geteilt      Kekse werden gerecht auf Teller verteilt, was übrig bleibt ist der Rest
//   Plus, Minus  Sprünge auf dem Zahlenstrahl, zuerst bis zum Zehner
//   Mehrere      Rechenweg Zeile für Zeile, Punkt vor Strich
//   Vergleich    beide Seiten ausrechnen, dann vergleichen
// Das Bild entsteht nur aus der Rechnung selbst und wird gegen die Lösung geprüft.
// Passt etwas nicht zusammen, gibt es kein Bild. Ein falsches Bild wäre schlimmer als keins.

struct ErklaerBild: Equatable {
    enum Art: Equatable {
        case punkte(reihen: Int, spalten: Int)
        /// kern Reihen sind bekannt, reihen ist die gesuchte Aufgabe (eine mehr oder weniger)
        case nachbar(kern: Int, reihen: Int, spalten: Int)
        case teller(gesamt: Int, teller: Int, jeder: Int, rest: Int)
        /// schritte mit Vorzeichen: +3 springt nach rechts, -5 nach links
        case spruenge(start: Int, schritte: [Int])
        case rechenweg([String])
    }

    let art: Art
    let saetze: [String]
}

enum ErklaerBildPlan {

    // MARK: Eingang

    static func bild(art: String, rechnung: String, erklaerung: String,
                     antwort: String, antwort2: String) -> ErklaerBild? {
        switch art {
        case "vergleich":
            return vergleich(rechnung: rechnung, antwort: antwort)
        case "rest":
            guard let q = zahl(antwort), let r = zahl(antwort2),
                  let t = ausdruck(in: [rechnung, erklaerung]),
                  t.zahlen.count == 2, t.zeichen == [":"] else { return nil }
            let a = t.zahlen[0], b = t.zahlen[1]
            guard b > 0, a / b == q, a % b == r else { return nil }
            return teller(gesamt: a, teller: b)
        case "zahl":
            guard let soll = zahl(antwort),
                  let t = ausdruck(in: [rechnung, erklaerung]),
                  let ist = wert(t), ist == soll else { return nil }
            return passendesBild(t)
        default:
            return nil
        }
    }

    // MARK: Rechnung lesen

    struct Term: Equatable {
        var zahlen: [Int]
        /// "+", "-", "·" oder ":"
        var zeichen: [String]

        var text: String {
            var s = String(zahlen.first ?? 0)
            for (i, z) in zeichen.enumerated() where i + 1 < zahlen.count {
                s += " \(z) \(zahlen[i + 1])"
            }
            return s
        }
    }

    private static func zahl(_ s: String) -> Int? {
        Int(s.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Liest "75 - 8 =" oder "75 - 8 = 67" als Rechnung. Text mit Wörtern ist keine Rechnung.
    static func term(_ roh: String) -> Term? {
        let vorn = roh.components(separatedBy: "=").first ?? roh
        guard let teile = try? MatheRechner.zerlege(vorn), !teile.isEmpty else { return nil }
        var zahlen: [Int] = []
        var zeichen: [String] = []
        var erwarteZahl = true
        for t in teile {
            switch t {
            case .zahl(let n):
                guard erwarteZahl else { return nil }
                zahlen.append(n)
                erwarteZahl = false
            case .op(let o):
                guard !erwarteZahl else { return nil }
                switch o {
                case "+": zeichen.append("+")
                case "-": zeichen.append("-")
                case "*": zeichen.append("·")
                default: zeichen.append(":")
                }
                erwarteZahl = true
            case .auf, .zu:
                return nil
            }
        }
        guard !erwarteZahl, !zeichen.isEmpty else { return nil }
        return Term(zahlen: zahlen, zeichen: zeichen)
    }

    /// Die erste der Texte, die eine Rechnung ist. Bei Wortaufgaben steht sie in der Erklärung.
    static func ausdruck(in texte: [String]) -> Term? {
        for t in texte {
            if let r = term(t) { return r }
        }
        return nil
    }

    /// Ein Rechenschritt: erst Mal und Geteilt von links, dann Plus und Minus von links.
    /// nil, wenn etwas nicht aufgeht oder negativ wird. In der Grundschule gibt es das nicht.
    static func schritt(_ t: Term) -> (neu: Term, satz: String, punkt: Bool)? {
        guard !t.zeichen.isEmpty else { return nil }
        let punktStelle = t.zeichen.firstIndex { $0 == "·" || $0 == ":" }
        let i = punktStelle ?? 0
        let a = t.zahlen[i], b = t.zahlen[i + 1], z = t.zeichen[i]
        let e: Int
        switch z {
        case "+": e = a + b
        case "-":
            guard a >= b else { return nil }
            e = a - b
        case "·":
            let (p, zuViel) = a.multipliedReportingOverflow(by: b)
            guard !zuViel, p <= 1_000_000 else { return nil }
            e = p
        default:
            guard b != 0, a % b == 0 else { return nil }
            e = a / b
        }
        var neu = t
        neu.zahlen.replaceSubrange(i...(i + 1), with: [e])
        neu.zeichen.remove(at: i)
        return (neu, "\(a) \(z) \(b) = \(e)", punktStelle != nil)
    }

    static func wert(_ t: Term) -> Int? {
        var x = t
        while !x.zeichen.isEmpty {
            guard let s = schritt(x) else { return nil }
            x = s.neu
        }
        return x.zahlen.first
    }

    // MARK: Bilder

    private static func passendesBild(_ t: Term) -> ErklaerBild? {
        if t.zeichen.count == 1 {
            let a = t.zahlen[0], b = t.zahlen[1]
            switch t.zeichen[0] {
            case "·": return malBild(a, b)
            case ":":
                guard b > 0 else { return nil }
                return teller(gesamt: a, teller: b)
            case "+": return spruengeBild(von: a, plus: true, um: b)
            default: return spruengeBild(von: a, plus: false, um: b)
            }
        }
        return rechenweg(t)
    }

    static let reihenWort = [1: "Einer", 2: "Zweier", 3: "Dreier", 4: "Vierer", 5: "Fünfer",
                             6: "Sechser", 7: "Siebener", 8: "Achter", 9: "Neuner", 10: "Zehner"]

    /// Nachbaraufgaben: 3 neben 2, 4 und 6 neben 5, 9 neben 10
    static func kern(zu reihen: Int) -> Int? {
        switch reihen {
        case 3: return 2
        case 4, 6: return 5
        case 9: return 10
        default: return nil
        }
    }

    static func malBild(_ a: Int, _ b: Int) -> ErklaerBild? {
        guard (1...10).contains(a), (1...10).contains(b) else { return nil }
        if let k = kern(zu: a) {
            let mehr = a > k
            return ErklaerBild(
                art: .nachbar(kern: k, reihen: a, spalten: b),
                saetze: [
                    "Die Kernaufgabe kennst du: \(k) · \(b) = \(k * b).",
                    mehr ? "Eine Reihe mehr: \(k * b) + \(b) = \(a * b)."
                         : "Eine Reihe weniger: \(k * b) - \(b) = \(a * b).",
                    "Also ist \(a) · \(b) = \(a * b)."
                ])
        }
        let liste = (1...a).map { String($0 * b) }.joined(separator: ", ")
        var saetze = ["\(a) · \(b) heißt: \(a) \(a == 1 ? "Reihe" : "Reihen") mit je \(b) \(b == 1 ? "Punkt" : "Punkten")."]
        if a > 1, let wort = reihenWort[b] {
            saetze.append("Zähle in \(wort)schritten: \(liste).")
        }
        saetze.append("Zusammen sind es \(a * b).")
        return ErklaerBild(art: .punkte(reihen: a, spalten: b), saetze: saetze)
    }

    static func teller(gesamt a: Int, teller b: Int) -> ErklaerBild? {
        guard (2...10).contains(b), a >= 0 else { return nil }
        let q = a / b, r = a % b
        guard q <= 25 else { return nil }
        var saetze = ["Verteile \(a) Kekse gerecht auf \(b) Teller.",
                      "Jeder Teller bekommt \(q) \(q == 1 ? "Keks" : "Kekse")."]
        if r > 0 {
            saetze.append(r == 1 ? "1 Keks bleibt übrig. Das ist der Rest."
                                 : "\(r) Kekse bleiben übrig. Das ist der Rest.")
            saetze.append("\(a) : \(b) = \(q) Rest \(r)")
        } else {
            saetze.append("Es bleibt nichts übrig. \(a) : \(b) = \(q)")
        }
        return ErklaerBild(art: .teller(gesamt: a, teller: b, jeder: q, rest: r), saetze: saetze)
    }

    /// Erst die Hunderter, dann die Zehner, dann die Einer. Die Einer gehen zuerst bis zum
    /// nächsten Zehner, wenn sie darüber hinausgehen.
    static func spruenge(von a: Int, plus: Bool, um b: Int) -> [Int] {
        var teile: [Int] = []
        var x = a
        var rest = b
        for stelle in [100, 10] {
            let teil = (rest / stelle) * stelle
            if teil > 0 {
                teile.append(teil)
                x += plus ? teil : -teil
                rest -= teil
            }
        }
        if rest > 0 {
            let bisZehner = plus ? (10 - x % 10) % 10 : x % 10
            if bisZehner > 0 && rest > bisZehner {
                teile += [bisZehner, rest - bisZehner]
            } else {
                teile.append(rest)
            }
        }
        return teile.map { plus ? $0 : -$0 }
    }

    static func spruengeBild(von a: Int, plus: Bool, um b: Int) -> ErklaerBild? {
        guard b > 0, a >= 0 else { return nil }
        let ziel = plus ? a + b : a - b
        guard (0...1000).contains(ziel), a <= 1000 else { return nil }
        let schritte = spruenge(von: a, plus: plus, um: b)
        guard schritte.count <= 5 else { return nil }
        var saetze = ["Rechne in Sprüngen auf dem Zahlenstrahl."]
        var x = a
        var zumZehner = false
        for (i, s) in schritte.enumerated() {
            let neu = x + s
            saetze.append("\(x) \(s > 0 ? "+" : "-") \(abs(s)) = \(neu)")
            if neu % 10 == 0 && abs(s) < 10 && i < schritte.count - 1 { zumZehner = true }
            x = neu
        }
        if zumZehner { saetze.insert("Zuerst bis zum Zehner, dann weiter.", at: 1) }
        return ErklaerBild(art: .spruenge(start: a, schritte: schritte), saetze: saetze)
    }

    static func rechenweg(_ t: Term) -> ErklaerBild? {
        var x = t
        var zeilen = [t.text]
        var saetze: [String] = []
        let gemischt = t.zeichen.contains { $0 == "·" || $0 == ":" }
            && t.zeichen.contains { $0 == "+" || $0 == "-" }
        if gemischt { saetze.append("Punkt vor Strich: Mal und Geteilt kommen zuerst.") }
        while !x.zeichen.isEmpty {
            guard let s = schritt(x) else { return nil }
            saetze.append((saetze.count <= (gemischt ? 1 : 0) ? "Zuerst: " : "Dann: ") + s.satz)
            x = s.neu
            zeilen.append(x.text)
        }
        return ErklaerBild(art: .rechenweg(zeilen), saetze: saetze)
    }

    static func vergleich(rechnung: String, antwort: String) -> ErklaerBild? {
        let seiten = rechnung.components(separatedBy: "?")
        guard seiten.count == 2 else { return nil }
        func seite(_ s: String) -> (text: String, wert: Int, rechnen: Bool)? {
            let roh = s.trimmingCharacters(in: .whitespaces)
            if let n = Int(roh) { return (roh, n, false) }
            guard let t = term(roh), let w = wert(t) else { return nil }
            return (t.text, w, true)
        }
        guard let l = seite(seiten[0]), let r = seite(seiten[1]), l.rechnen || r.rechnen else { return nil }
        let zeichen = l.wert < r.wert ? "<" : (l.wert > r.wert ? ">" : "=")
        guard zeichen == antwort.trimmingCharacters(in: .whitespaces) else { return nil }
        let wort = zeichen == "<" ? "kleiner als" : (zeichen == ">" ? "größer als" : "genauso groß wie")
        return ErklaerBild(
            art: .rechenweg(["\(l.text)  ?  \(r.text)",
                             "\(l.wert)  ?  \(r.wert)",
                             "\(l.wert)  \(zeichen)  \(r.wert)"]),
            saetze: ["Rechne zuerst beide Seiten aus.",
                     "\(l.wert) ist \(wort) \(r.wert).",
                     "Darum gehört \(zeichen) in die Mitte."])
    }

    /// Wie viele Schritte das Bild hat. Danach steht es fertig da.
    static func schrittZahl(_ art: ErklaerBild.Art) -> Int {
        switch art {
        case .punkte(let r, _): return r
        case .nachbar: return 2
        case .teller(_, _, let j, let rest): return j + (rest > 0 ? 1 : 0)
        case .spruenge(_, let s): return s.count
        case .rechenweg(let z): return max(z.count - 1, 1)
        }
    }
}

// MARK: - Knopf "Zeig es mir" und das Bild

struct ErklaerBildKnopf: View {
    let bild: ErklaerBild
    @State private var offen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if offen {
                ErklaerBildView(bild: bild)
                    .transition(.scale(scale: 0.9, anchor: .top).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { offen = true }
                    Haptik.leicht()
                } label: {
                    HStack(spacing: 8) {
                        Text("🦉")
                        Text("Zeig es mir als Bild")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                    .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }
}

struct ErklaerBildView: View {
    let bild: ErklaerBild
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var schritt = 0

    private var fertig: Int { ErklaerBildPlan.schrittZahl(bild.art) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                switch bild.art {
                case .punkte(let r, let s):
                    punkteBild(reihen: r, spalten: s, kern: nil)
                case .nachbar(let k, let r, let s):
                    punkteBild(reihen: r, spalten: s, kern: k)
                case .teller(_, let t, let j, let rest):
                    tellerBild(teller: t, jeder: j, rest: rest)
                case .spruenge(let start, let s):
                    ZahlenstrahlBild(start: start, schritte: s, sichtbar: schritt)
                        .frame(height: 120)
                case .rechenweg(let zeilen):
                    rechenwegBild(zeilen)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(alignment: .top, spacing: 10) {
                Text("🦉").font(.system(size: 28))
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(bild.saetze.enumerated()), id: \.offset) { _, satz in
                        Text(satz)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Color.white)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 16) {
                        Button {
                            Sprecher.shared.sprich(sprechText, code: "de-DE")
                        } label: {
                            Label("Vorlesen", systemImage: "speaker.wave.2.fill")
                        }
                        Button {
                            Task { await abspielen() }
                        } label: {
                            Label("Nochmal", systemImage: "arrow.counterclockwise")
                        }
                    }
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.gelb)
                    .padding(.top, 2)
                }
            }
        }
        .task { await abspielen() }
    }

    private var sprechText: String {
        bild.saetze.joined(separator: " ")
            .replacingOccurrences(of: " · ", with: " mal ")
            .replacingOccurrences(of: " : ", with: " geteilt durch ")
            .replacingOccurrences(of: " - ", with: " minus ")
            .replacingOccurrences(of: " + ", with: " plus ")
            .replacingOccurrences(of: " = ", with: " gleich ")
            .replacingOccurrences(of: "<", with: "kleiner")
            .replacingOccurrences(of: ">", with: "größer")
    }

    private func abspielen() async {
        if ruhig {
            schritt = fertig
            return
        }
        schritt = 0
        // Bei vielen Schritten geht es schneller, damit niemand lange warten muss
        let pause = fertig > 12 ? 160 : (fertig > 6 ? 300 : 650)
        for i in 1...max(fertig, 1) {
            do { try await Task.sleep(for: .milliseconds(pause)) } catch { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { schritt = i }
        }
    }

    // MARK: Punktefeld

    private func punktGroesse(_ spalten: Int, _ reihen: Int) -> CGFloat {
        (reihen > 6 || spalten > 8) ? 11 : 15
    }

    @ViewBuilder
    private func punkteBild(reihen: Int, spalten: Int, kern: Int?) -> some View {
        let g = punktGroesse(spalten, max(reihen, kern ?? 0))
        let alle = max(reihen, kern ?? 0)
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<alle, id: \.self) { i in
                let rolle = reihenRolle(i, reihen: reihen, kern: kern)
                HStack(spacing: 4) {
                    ForEach(0..<spalten, id: \.self) { _ in
                        Circle()
                            .fill(rolle.farbe.gradient)
                            .frame(width: g, height: g)
                    }
                    Text(rolle.weg ? "weg" : String((i + 1) * spalten))
                        .font(.system(.caption, design: .rounded).weight(.heavy))
                        .foregroundStyle(rolle.farbe)
                        .frame(minWidth: 30, alignment: .leading)
                        .padding(.leading, 6)
                }
                .overlay {
                    if rolle.weg {
                        Capsule().fill(Theme.koralle).frame(height: 2.5)
                    }
                }
                .opacity(rolle.sichtbar ? (rolle.weg ? 0.45 : 1) : 0)
                .scaleEffect(rolle.sichtbar ? 1 : 0.6, anchor: .leading)
            }
        }
    }

    private struct ReihenRolle {
        var farbe: Color
        var sichtbar: Bool
        var weg = false
    }

    private func reihenRolle(_ i: Int, reihen: Int, kern: Int?) -> ReihenRolle {
        guard let k = kern else {
            return ReihenRolle(farbe: Theme.gelb, sichtbar: i < schritt)
        }
        // Schritt 1: die Kernaufgabe. Schritt 2: eine Reihe dazu oder weg.
        if i < k {
            let weg = reihen < k && i == k - 1 && schritt >= 2
            return ReihenRolle(farbe: weg ? Theme.koralle : Theme.gelb, sichtbar: schritt >= 1, weg: weg)
        }
        return ReihenRolle(farbe: Theme.mint, sichtbar: schritt >= 2)
    }

    // MARK: Teller mit Keksen

    private func tellerBild(teller: Int, jeder: Int, rest: Int) -> some View {
        let gelegt = min(schritt, jeder)
        let restDa = rest > 0 && schritt > jeder
        let keks: CGFloat = jeder > 12 ? 7 : 10
        let spalten = jeder > 16 ? 5 : (jeder > 9 ? 4 : 3)
        return VStack(spacing: 10) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
                ForEach(0..<teller, id: \.self) { _ in
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .overlay(Circle().stroke(Theme.himmel.opacity(0.6), lineWidth: 3))
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(keks), spacing: 2), count: spalten),
                                  spacing: 2) {
                            ForEach(0..<gelegt, id: \.self) { _ in
                                Circle()
                                    .fill(Color(red: 0.78, green: 0.52, blue: 0.27))
                                    .frame(width: keks, height: keks)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .frame(width: CGFloat(spalten) * (keks + 2))
                    }
                    .frame(width: 64, height: 64)
                }
            }
            if rest > 0 {
                HStack(spacing: 6) {
                    Text("Rest:")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.koralle)
                    ForEach(0..<rest, id: \.self) { _ in
                        Circle()
                            .fill(Color(red: 0.78, green: 0.52, blue: 0.27))
                            .frame(width: 13, height: 13)
                            .overlay(Circle().stroke(Theme.koralle, lineWidth: 2))
                    }
                }
                .opacity(restDa ? 1 : 0)
                .scaleEffect(restDa ? 1 : 0.6)
            }
        }
    }

    // MARK: Rechenweg

    private func rechenwegBild(_ zeilen: [String]) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(zeilen.enumerated()), id: \.offset) { i, zeile in
                let da = i <= schritt
                let letzte = i == zeilen.count - 1
                VStack(spacing: 2) {
                    if i > 0 {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 13, weight: .heavy))
                            .foregroundStyle(Theme.textSanft)
                    }
                    Text(zeile)
                        .font(.system(size: letzte ? 30 : 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(letzte ? Theme.gelb : Color.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .opacity(da ? 1 : 0)
                .offset(y: da ? 0 : 8)
            }
        }
    }
}

// MARK: - Zahlenstrahl mit Sprüngen

struct ZahlenstrahlBild: View {
    let start: Int
    let schritte: [Int]
    let sichtbar: Int

    var body: some View {
        Canvas { ctx, groesse in
            let n = max(schritte.count, 1)
            let rand: CGFloat = 26
            let breite = groesse.width - 2 * rand
            let linieY = groesse.height - 34
            // Alle Punkte gleich weit auseinander, das ist für Kinder am klarsten
            let rechts = schritte.reduce(0, +) >= 0
            func x(_ i: Int) -> CGFloat {
                let anteil = CGFloat(i) / CGFloat(n)
                return rechts ? rand + anteil * breite : groesse.width - rand - anteil * breite
            }
            var linie = Path()
            linie.move(to: CGPoint(x: 8, y: linieY))
            linie.addLine(to: CGPoint(x: groesse.width - 8, y: linieY))
            ctx.stroke(linie, with: .color(Color.white.opacity(0.7)), lineWidth: 2.5)

            var wert = start
            ctx.draw(Text(String(start)).font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white),
                     at: CGPoint(x: x(0), y: linieY + 16))
            strich(ctx, x(0), linieY)
            for (i, s) in schritte.enumerated() where i < sichtbar {
                let von = x(i), bis = x(i + 1)
                wert += s
                var bogen = Path()
                bogen.move(to: CGPoint(x: von, y: linieY))
                bogen.addQuadCurve(to: CGPoint(x: bis, y: linieY),
                                   control: CGPoint(x: (von + bis) / 2, y: linieY - 62))
                let farbe = s > 0 ? Theme.mint : Theme.koralle
                ctx.stroke(bogen, with: .color(farbe), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                // kleine Pfeilspitze am Ende
                var spitze = Path()
                let richtung: CGFloat = bis > von ? -1 : 1
                spitze.move(to: CGPoint(x: bis + richtung * 9, y: linieY - 10))
                spitze.addLine(to: CGPoint(x: bis, y: linieY))
                spitze.addLine(to: CGPoint(x: bis + richtung * 1, y: linieY - 13))
                ctx.stroke(spitze, with: .color(farbe), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                ctx.draw(Text(s > 0 ? "+\(s)" : "-\(abs(s))")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundStyle(farbe),
                         at: CGPoint(x: (von + bis) / 2, y: linieY - 44))
                strich(ctx, bis, linieY)
                let letzter = i == schritte.count - 1
                ctx.draw(Text(String(wert))
                            .font(.system(size: letzter ? 17 : 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(letzter ? Theme.gelb : Color.white),
                         at: CGPoint(x: bis, y: linieY + 16))
            }
        }
    }

    private func strich(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: x, y: y - 7))
        p.addLine(to: CGPoint(x: x, y: y + 7))
        ctx.stroke(p, with: .color(Color.white), lineWidth: 2)
    }
}
