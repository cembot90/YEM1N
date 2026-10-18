import SwiftUI
import AVFoundation
import Foundation

// ============================================================
// MARK: - Antworten zum Antippen und kleine Bilder über der Aufgabe
// ============================================================
//
// Für Deutsch, Englisch, Musik und Kunst tippt das Kind die Antwort an, statt sie zu
// schreiben. Über der Aufgabe kann ein kleines Bild stehen. Der Code dafür steht in
// Aufgabe.bild als "art:wert":
//   wort:🍎|Apfel     großes Bild, der Lautsprecher sagt das Wort
//   emoji:🥁          großes Bild
//   englisch:dog      Knopf, der das englische Wort vorliest
//   note:g1           Notenzeile mit einer Note, dazu der echte Ton
//   notenwert:halbe   eine einzelne Note (ganze, halbe, viertel, achtel)
//   form:dreieck      eine Form (kreis, dreieck, quadrat, rechteck, oval, stern)
//   mischen:blau+gelb zwei Farbkleckse, die gemischt werden
//   farbe:orange      ein Farbfeld
//   strichliste:7     Striche in Fünferbündeln
//   rechteck:5x3      Rechteck aus Kästchen, 5 breit und 3 hoch
//   uhr:8:30          Uhr mit Zeigern
//   toene:c1|g1       zwei Töne zum Anhören und Vergleichen

struct WahlKnoepfe: View {
    let optionen: [String]
    var beiWahl: (String) -> Void

    private var kurz: Bool { optionen.count <= 3 && optionen.allSatisfy { $0.count <= 9 } }

    var body: some View {
        Group {
            if kurz {
                HStack(spacing: 12) {
                    ForEach(optionen, id: \.self) { knopf($0) }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(optionen, id: \.self) { knopf($0) }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private func knopf(_ o: String) -> some View {
        Button { beiWahl(o) } label: {
            Text(o)
                .font(.system(size: kurz ? 26 : 20, weight: .heavy, design: .rounded))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: kurz ? 68 : 56)
                .background(Color.white.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(TastenStil())
    }
}

struct AufgabenBild: View {
    let code: String

    private var teile: (art: String, wert: String) {
        guard let i = code.firstIndex(of: ":") else { return (code, "") }
        return (String(code[..<i]), String(code[code.index(after: i)...]))
    }

    var body: some View {
        let t = teile
        switch t.art {
        case "wort":
            let stuecke = t.wert.components(separatedBy: "|")
            VStack(spacing: 8) {
                Text(stuecke.first ?? "").font(.system(size: 76))
                if stuecke.count > 1 {
                    vorlesen(stuecke[1], sprache: "de-DE", titel: "Wort anhören")
                }
            }
        case "emoji":
            Text(t.wert).font(.system(size: 76))
        case "englisch":
            vorlesen(t.wert, sprache: "en-GB", titel: "Auf Englisch anhören")
        case "note":
            VStack(spacing: 8) {
                NotenZeile(note: t.wert)
                    .frame(width: 220, height: 120)
                Button {
                    TonGeber.shared.spiele(note: t.wert)
                } label: {
                    Label("Ton anhören", systemImage: "music.note")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.navy)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Theme.gelb, in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        case "notenwert":
            NotenwertBild(wert: t.wert)
                .frame(width: 90, height: 110)
        case "form":
            FormBild(form: t.wert)
                .frame(width: 130, height: 110)
        case "mischen":
            let farben = t.wert.components(separatedBy: "+")
            HStack(spacing: 12) {
                klecks(farben.first ?? "")
                Text("+").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Color.white)
                klecks(farben.count > 1 ? farben[1] : "")
                Text("=").font(.system(size: 34, weight: .black, design: .rounded)).foregroundStyle(Color.white)
                Text("?")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.navy)
                    .frame(width: 58, height: 58)
                    .background(Color.white.opacity(0.85), in: Circle())
            }
        case "farbe":
            klecks(t.wert)
                .scaleEffect(1.3)
                .padding(10)
        case "strichliste":
            StrichlisteBild(anzahl: Int(t.wert) ?? 0)
                .frame(height: 70)
        case "rechteck":
            let masse = t.wert.components(separatedBy: "x").compactMap { Int($0) }
            KaestchenRechteck(breite: masse.first ?? 1, hoehe: masse.count > 1 ? masse[1] : 1)
        case "uhr":
            let zeit = t.wert.components(separatedBy: ":").compactMap { Int($0) }
            UhrBild(stunde: zeit.first ?? 12, minute: zeit.count > 1 ? zeit[1] : 0)
                .frame(width: 150, height: 150)
        case "toene":
            let zwei = t.wert.components(separatedBy: "|")
            HStack(spacing: 14) {
                tonKnopf("Ton 1", note: zwei.first ?? "")
                tonKnopf("Ton 2", note: zwei.count > 1 ? zwei[1] : "")
            }
        default:
            EmptyView()
        }
    }

    private func klecks(_ name: String) -> some View {
        Circle()
            .fill(Malfarbe.farbe(name))
            .frame(width: 58, height: 58)
            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 2))
            .shadow(color: Malfarbe.farbe(name).opacity(0.5), radius: 8)
            .accessibilityLabel(Malfarbe.name(name))
    }

    private func tonKnopf(_ titel: String, note: String) -> some View {
        Button {
            TonGeber.shared.spiele(note: note)
        } label: {
            Label(titel, systemImage: "play.fill")
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .padding(.vertical, 12)
                .padding(.horizontal, 18)
                .background(Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    private func vorlesen(_ text: String, sprache: String, titel: String) -> some View {
        Button {
            Sprecher.shared.sprich(text, code: sprache)
        } label: {
            Label(titel, systemImage: "speaker.wave.2.fill")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
    }
}

/// Die Farben aus dem Malkasten
enum Malfarbe {
    static func farbe(_ name: String) -> Color {
        switch name {
        case "rot": return Color(red: 0.90, green: 0.15, blue: 0.15)
        case "gelb": return Color(red: 1.0, green: 0.85, blue: 0.10)
        case "blau": return Color(red: 0.12, green: 0.35, blue: 0.90)
        case "gruen": return Color(red: 0.15, green: 0.65, blue: 0.25)
        case "orange": return Color(red: 1.0, green: 0.55, blue: 0.10)
        case "violett": return Color(red: 0.55, green: 0.25, blue: 0.75)
        case "weiss": return Color.white
        case "schwarz": return Color(red: 0.08, green: 0.08, blue: 0.08)
        case "rosa": return Color(red: 1.0, green: 0.70, blue: 0.80)
        case "hellblau": return Color(red: 0.55, green: 0.78, blue: 1.0)
        case "grau": return Color(red: 0.55, green: 0.55, blue: 0.58)
        case "braun": return Color(red: 0.50, green: 0.30, blue: 0.15)
        case "tuerkis": return Color(red: 0.10, green: 0.75, blue: 0.75)
        default: return Color.gray
        }
    }

    static func name(_ name: String) -> String {
        switch name {
        case "gruen": return "Grün"
        case "weiss": return "Weiß"
        case "tuerkis": return "Türkis"
        default: return name.prefix(1).uppercased() + name.dropFirst()
        }
    }
}

// MARK: - Noten

enum Noten {
    /// Position auf der Notenzeile: 0 ist die unterste Linie (e'), jeder Schritt eine halbe Linie höher
    static let stufe: [String: Int] = ["c1": -2, "d1": -1, "e1": 0, "f1": 1, "g1": 2, "a1": 3,
                                       "h1": 4, "c2": 5, "d2": 6, "e2": 7, "f2": 8]
    /// Wie die Note im Unterricht heißt
    static let name: [String: String] = ["c1": "c", "d1": "d", "e1": "e", "f1": "f", "g1": "g", "a1": "a",
                                         "h1": "h", "c2": "c", "d2": "d", "e2": "e", "f2": "f"]
    static let frequenz: [String: Double] = ["c1": 261.63, "d1": 293.66, "e1": 329.63, "f1": 349.23,
                                             "g1": 392.00, "a1": 440.00, "h1": 493.88, "c2": 523.25,
                                             "d2": 587.33, "e2": 659.26, "f2": 698.46]
    static let alle = ["c1", "d1", "e1", "f1", "g1", "a1", "h1", "c2", "d2", "e2", "f2"]
}

struct NotenZeile: View {
    let note: String

    var body: some View {
        Canvas { ctx, groesse in
            let abstand: CGFloat = 13
            let unten = groesse.height / 2 + 2 * abstand
            let links: CGFloat = 10
            let rechts = groesse.width - 10
            for i in 0..<5 {
                var linie = Path()
                let y = unten - CGFloat(i) * abstand
                linie.move(to: CGPoint(x: links, y: y))
                linie.addLine(to: CGPoint(x: rechts, y: y))
                ctx.stroke(linie, with: .color(Color.white.opacity(0.85)), lineWidth: 1.6)
            }
            ctx.draw(Text("Violinschlüssel")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textSanft),
                     at: CGPoint(x: links + 44, y: unten + 26))
            let s = Noten.stufe[note] ?? 0
            let x = groesse.width * 0.62
            let y = unten - CGFloat(s) * abstand / 2
            // Hilfslinie für das c'
            if s <= -2 {
                var hilf = Path()
                hilf.move(to: CGPoint(x: x - 16, y: unten + abstand))
                hilf.addLine(to: CGPoint(x: x + 16, y: unten + abstand))
                ctx.stroke(hilf, with: .color(Color.white.opacity(0.85)), lineWidth: 1.6)
            }
            let kopf = CGRect(x: x - 9, y: y - 6.5, width: 18, height: 13)
            ctx.fill(Path(ellipseIn: kopf), with: .color(Theme.gelb))
            var hals = Path()
            if s < 4 {
                hals.move(to: CGPoint(x: x + 8, y: y))
                hals.addLine(to: CGPoint(x: x + 8, y: y - 40))
            } else {
                hals.move(to: CGPoint(x: x - 8, y: y))
                hals.addLine(to: CGPoint(x: x - 8, y: y + 40))
            }
            ctx.stroke(hals, with: .color(Theme.gelb), lineWidth: 2.4)
        }
        .accessibilityLabel("Eine Note auf der Notenzeile")
    }
}

struct NotenwertBild: View {
    /// ganze, halbe, viertel oder achtel
    let wert: String

    var body: some View {
        Canvas { ctx, groesse in
            let x = groesse.width / 2 - 6
            let y = groesse.height - 22
            let kopf = CGRect(x: x - 12, y: y - 9, width: 24, height: 18)
            let voll = wert == "viertel" || wert == "achtel"
            if voll {
                ctx.fill(Path(ellipseIn: kopf), with: .color(Theme.gelb))
            } else {
                ctx.stroke(Path(ellipseIn: kopf), with: .color(Theme.gelb), lineWidth: 3.5)
            }
            guard wert != "ganze" else { return }
            var hals = Path()
            hals.move(to: CGPoint(x: x + 11, y: y - 2))
            hals.addLine(to: CGPoint(x: x + 11, y: y - 68))
            ctx.stroke(hals, with: .color(Theme.gelb), lineWidth: 3)
            if wert == "achtel" {
                var fahne = Path()
                fahne.move(to: CGPoint(x: x + 11, y: y - 68))
                fahne.addCurve(to: CGPoint(x: x + 26, y: y - 30),
                               control1: CGPoint(x: x + 16, y: y - 52),
                               control2: CGPoint(x: x + 32, y: y - 46))
                ctx.stroke(fahne, with: .color(Theme.gelb), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
        }
        .accessibilityLabel("Eine Note")
    }
}

// MARK: - Strichliste, Kästchen und Uhr

/// Striche wie an der Tafel: vier senkrecht, der fünfte quer darüber
struct StrichlisteBild: View {
    let anzahl: Int

    var body: some View {
        Canvas { ctx, groesse in
            let hoehe: CGFloat = 46
            let oben = (groesse.height - hoehe) / 2
            let abstand: CGFloat = 10
            let buendelBreite = 4 * abstand + 18
            let buendel = (anzahl + 4) / 5
            let gesamt = CGFloat(buendel) * buendelBreite
            var x = max(8, (groesse.width - gesamt) / 2)
            var rest = anzahl
            while rest > 0 {
                let hier = min(rest, 5)
                let senkrecht = min(hier, 4)
                for i in 0..<senkrecht {
                    var p = Path()
                    let px = x + CGFloat(i) * abstand
                    p.move(to: CGPoint(x: px, y: oben))
                    p.addLine(to: CGPoint(x: px, y: oben + hoehe))
                    ctx.stroke(p, with: .color(Theme.gelb), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                }
                if hier == 5 {
                    var quer = Path()
                    quer.move(to: CGPoint(x: x - 6, y: oben + hoehe - 6))
                    quer.addLine(to: CGPoint(x: x + 3 * abstand + 6, y: oben + 6))
                    ctx.stroke(quer, with: .color(Theme.gelb), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                }
                x += buendelBreite
                rest -= hier
            }
        }
        .accessibilityLabel("Eine Strichliste")
    }
}

/// Ein Rechteck aus gleich großen Kästchen
struct KaestchenRechteck: View {
    let breite: Int
    let hoehe: Int

    var body: some View {
        let seite: CGFloat = breite > 8 || hoehe > 6 ? 18 : 24
        VStack(spacing: 2) {
            ForEach(0..<max(hoehe, 1), id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<max(breite, 1), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Theme.gelb.opacity(0.85))
                            .frame(width: seite, height: seite)
                    }
                }
            }
        }
        .padding(4)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white, lineWidth: 2))
        .accessibilityLabel("Ein Rechteck aus \(breite) mal \(hoehe) Kästchen")
    }
}

/// Eine Uhr mit Stunden- und Minutenzeiger
struct UhrBild: View {
    let stunde: Int
    let minute: Int

    var body: some View {
        Canvas { ctx, groesse in
            let r = min(groesse.width, groesse.height) / 2 - 4
            let m = CGPoint(x: groesse.width / 2, y: groesse.height / 2)
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - r, y: m.y - r, width: 2 * r, height: 2 * r)),
                     with: .color(Color.white))
            ctx.stroke(Path(ellipseIn: CGRect(x: m.x - r, y: m.y - r, width: 2 * r, height: 2 * r)),
                       with: .color(Theme.gelb), lineWidth: 4)
            for i in 0..<12 {
                let w = Double(i) * .pi / 6
                var strich = Path()
                strich.move(to: CGPoint(x: m.x + CGFloat(sin(w)) * (r - 4), y: m.y - CGFloat(cos(w)) * (r - 4)))
                strich.addLine(to: CGPoint(x: m.x + CGFloat(sin(w)) * (r - 12), y: m.y - CGFloat(cos(w)) * (r - 12)))
                ctx.stroke(strich, with: .color(Color.black.opacity(0.75)), lineWidth: i % 3 == 0 ? 3 : 1.5)
                let zahl = i == 0 ? 12 : i
                ctx.draw(Text("\(zahl)").font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black),
                         at: CGPoint(x: m.x + CGFloat(sin(w)) * (r - 24), y: m.y - CGFloat(cos(w)) * (r - 24)))
            }
            let minutenWinkel = Double(minute) / 60 * 2 * .pi
            let stundenWinkel = (Double(stunde % 12) + Double(minute) / 60) / 12 * 2 * .pi
            var lang = Path()
            lang.move(to: m)
            lang.addLine(to: CGPoint(x: m.x + CGFloat(sin(minutenWinkel)) * (r - 16),
                                     y: m.y - CGFloat(cos(minutenWinkel)) * (r - 16)))
            ctx.stroke(lang, with: .color(Color(red: 0.1, green: 0.3, blue: 0.8)),
                       style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            var kurz = Path()
            kurz.move(to: m)
            kurz.addLine(to: CGPoint(x: m.x + CGFloat(sin(stundenWinkel)) * (r * 0.5),
                                     y: m.y - CGFloat(cos(stundenWinkel)) * (r * 0.5)))
            ctx.stroke(kurz, with: .color(Color(red: 0.85, green: 0.15, blue: 0.15)),
                       style: StrokeStyle(lineWidth: 6, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: m.x - 5, y: m.y - 5, width: 10, height: 10)), with: .color(Color.black))
        }
        .accessibilityLabel("Eine Uhr")
    }
}

// MARK: - Formen

struct FormBild: View {
    let form: String

    var body: some View {
        Group {
            switch form {
            case "kreis": Circle().fill(Theme.gelb).frame(width: 100, height: 100)
            case "quadrat": Rectangle().fill(Theme.gelb).frame(width: 96, height: 96)
            case "rechteck": Rectangle().fill(Theme.gelb).frame(width: 126, height: 76)
            case "oval": Ellipse().fill(Theme.gelb).frame(width: 126, height: 80)
            case "dreieck": Dreieck().fill(Theme.gelb).frame(width: 110, height: 96)
            case "stern": Stern().fill(Theme.gelb).frame(width: 106, height: 106)
            default: EmptyView()
            }
        }
        .accessibilityLabel("Eine Form")
    }
}

struct Dreieck: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct Stern: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let mitte = CGPoint(x: r.midX, y: r.midY)
        let aussen = min(r.width, r.height) / 2
        let innen = aussen * 0.42
        for i in 0..<10 {
            let winkel = Double(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? aussen : innen
            let punkt = CGPoint(x: mitte.x + CGFloat(cos(winkel)) * radius,
                                y: mitte.y + CGFloat(sin(winkel)) * radius)
            if i == 0 { p.move(to: punkt) } else { p.addLine(to: punkt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Ein echter Ton zur Note

final class TonGeber {
    static let shared = TonGeber()

    private let motor = AVAudioEngine()
    private let spieler = AVAudioPlayerNode()
    private var bereit = false
    private let rate = 44_100.0

    func spiele(note: String) {
        guard let f = Noten.frequenz[note] else { return }
        spiele(frequenz: f)
    }

    /// Ein weicher Ton wie von einem Glockenspiel: schnell an, langsam aus.
    func spiele(frequenz: Double, dauer: Double = 1.2) {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else { return }
        let sitzung = AVAudioSession.sharedInstance()
        if sitzung.category != .playback {
            try? sitzung.setCategory(.playback, mode: .default, options: [.duckOthers])
        }
        try? sitzung.setActive(true)
        if !bereit {
            motor.attach(spieler)
            motor.connect(spieler, to: motor.mainMixerNode, format: format)
            bereit = true
        }
        if !motor.isRunning {
            do { try motor.start() } catch { return }
        }
        let anzahl = AVAudioFrameCount(rate * dauer)
        guard let puffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: anzahl),
              let kanal = puffer.floatChannelData?[0] else { return }
        puffer.frameLength = anzahl
        for i in 0..<Int(anzahl) {
            let t = Double(i) / rate
            let an = min(t / 0.015, 1)
            let aus = exp(-3.2 * t)
            let welle = sin(2 * .pi * frequenz * t) + 0.25 * sin(4 * .pi * frequenz * t)
            kanal[i] = Float(0.32 * an * aus * welle)
        }
        spieler.stop()
        spieler.scheduleBuffer(puffer, at: nil)
        spieler.play()
    }
}
