import SwiftUI

// ============================================================
// MARK: - Eule Olli
// Olli passt auf das Ei auf und erklärt beim ersten Besuch Schritt für Schritt,
// wie das Haustier bis zum Meister wächst. Danach gibt sie Tipps, die gerade
// passen. Auf dem Eltern-Gerät erklärt sie, was die Eltern beitragen können.
// Das Tier selbst sagt beim Antippen etwas zu seiner Laune.
// Alles bleibt auf dem Gerät, es wird nichts übertragen.
// ============================================================

enum Eule {
    static let name = "Olli"
    static let bild = "🦉"
    /// Merker auf dem Kind-Gerät: Die Einführung wurde schon gezeigt.
    static let einfuehrungKey = "euleEinfuehrung"
    /// Merker auf dem Eltern-Gerät.
    static let elternEinfuehrungKey = "euleEinfuehrungEltern"
    /// Ab so wenigen fehlenden Punkten erinnert Olli an die nächste Stufe.
    static let naheGrenze = 15
    /// Schalter: Olli und das Tier sprechen von selbst laut. Der Lautsprecher-Knopf
    /// in der Sprechblase liest trotzdem vor.
    static let tonKey = "haustierTon"

    // MARK: Einführung für das Kind

    static func einfuehrung(fuer h: Haustier) -> [String] {
        let n = h.name
        let anfang: [String]
        if h.stufe == .ei {
            anfang = [
                "Hallo, ich bin Olli, die Eule! Ich passe auf das Ei von \(n) auf, bis es schlüpft.",
                "Das Ei schlüpft, sobald du eine Runde übst. Egal ob Mathe, Deutsch, Sprachen oder Vorschule."
            ]
        } else {
            anfang = [
                "Hallo, ich bin Olli, die Eule! Ab jetzt passe ich zusammen mit dir auf \(n) auf.",
                "Jede Runde, die du übst, macht \(n) satt und froh. Egal ob Mathe, Deutsch, Sprachen oder Vorschule."
            ]
        }
        return anfang + [
            "Für jede richtige Aufgabe bekommt \(n) einen Punkt, für jeden Stern zwei. So wächst es: Baby, Kind, Großes Tier und am Ende Meister.",
            "Mein Geheimtipp: Probier jede Aufgabe erst selbst. Wer die Lösung anschaut, bekommt keine Sternpunkte.",
            "Übst du länger nicht, bekommt \(n) Hunger und wird traurig. Aber keine Sorge, es läuft nie weg. Eine Runde macht es wieder froh.",
            "Mit deinen Münzen kannst du \(n) verwöhnen: mit Leckerli, Spielen und Hüten. Und jeden Tag wartet hier ein kleines Geschenk.",
            "Ab 20 Uhr schläft \(n), ab 7 Uhr ist es wieder wach. Hast du eine Frage? Tipp einfach auf mich. Los geht's!"
        ]
    }

    // MARK: Einführung für die Eltern

    static let elternEinfuehrung: [String] = [
        "Hallo, ich bin Olli, die Eule! Hier siehst du das Haustier deines Kindes, so wie es gerade ist.",
        "Satt wird es und wachsen kann es nur, wenn dein Kind übt. Jede richtige Aufgabe und jeder Stern bringen es dem Meister näher.",
        "Du kannst jeden Tag gratis ein Leckerli und ein Spiel schenken. Dein Kind bekommt eine Mitteilung, sobald es die App öffnet.",
        "Hat das Tier Hunger oder ist es traurig, ist das ein guter Anlass für eine gemeinsame Runde. Es läuft nie weg und verliert nie sein Wachstum.",
        "Ab 20 Uhr schläft es. Zum Aktualisieren ziehst du die Seite nach unten. Tipp auf mich, wenn du einen Tipp möchtest."
    ]

    // MARK: Tipps für das Kind

    /// Alle Tipps, die gerade passen: zuerst die zur Lage, dann allgemeine.
    static func tipps(fuer h: Haustier, muenzen: Int, familie: Bool,
                      jetzt: Date = Date.now, kalender: Calendar = .current) -> [String] {
        let alle = lageTipps(fuer: h, muenzen: muenzen, jetzt: jetzt, kalender: kalender)
            + allgemeineTipps(fuer: h, familie: familie)
        return ohneDoppelte(alle)
    }

    /// Der wichtigste Tipp zur Lage, oder nil, wenn gerade nichts Besonderes ist.
    static func wichtigerTipp(fuer h: Haustier, muenzen: Int,
                              jetzt: Date = Date.now, kalender: Calendar = .current) -> String? {
        lageTipps(fuer: h, muenzen: muenzen, jetzt: jetzt, kalender: kalender).first
    }

    static func lageTipps(fuer h: Haustier, muenzen: Int,
                          jetzt: Date = Date.now, kalender: Calendar = .current) -> [String] {
        let n = h.name
        var t: [String] = []
        let geschenk = "Hol dir dein Tagesgeschenk ab: \(Haustier.geschenkMuenzen) Münzen warten auf dich."
        if h.stufe == .ei {
            t.append("Übe eine Runde, dann schlüpft \(n). Ich bin schon ganz gespannt!")
            if h.geschenkOffen(jetzt: jetzt, kalender: kalender) { t.append(geschenk) }
            return t
        }
        if HaustierZeit.schlaeft(jetzt, kalender: kalender) {
            t.append("Pssst, \(n) schläft. Ab 7 Uhr ist es wieder wach. Üben kannst du trotzdem, dann ist es morgen satt.")
        }
        switch h.stimmung {
        case .hungrig:
            t.append("\(n) hat Hunger. Eine Runde üben macht es satt, ganz ohne Münzen.")
        case .traurig:
            t.append("\(n) ist ein bisschen traurig. Eine Runde üben oder zusammen spielen hilft.")
        default:
            break
        }
        if h.geschenkOffen(jetzt: jetzt, kalender: kalender) { t.append(geschenk) }
        if let weiter = h.stufe.naechste {
            let rest = weiter.schwelle - h.xp
            if rest > 0 && rest <= naheGrenze {
                t.append("Nur noch \(rest) Punkte bis zur Stufe \(weiter.name)! Das schaffst du bald.")
            }
        }
        if let hut = guenstigsterHut(fuer: h, muenzen: muenzen) {
            t.append("Du hast genug Münzen für einen neuen Look: \(hut.emoji) \(hut.name) für \(hut.preis) Münzen.")
        }
        return t
    }

    static func allgemeineTipps(fuer h: Haustier, familie: Bool) -> [String] {
        let n = h.name
        var t = [
            "Drei Sterne bringen die meisten Punkte. Lies jede Aufgabe ganz genau.",
            "Probier es erst selbst. Wer die Lösung anschaut, bekommt keine Sternpunkte.",
            "Jede Runde zählt, auch in Deutsch, in den Sprachen und in der Vorschule.",
            "Jeden Tag ein bisschen üben ist besser als einmal ganz viel."
        ]
        if h.stufe == .ei {
            t.append("Für jede richtige Aufgabe gibt es einen Punkt. Schon mit dem ersten Punkt schlüpft \(n).")
        } else {
            t.append("Tipp auf \(n), dann hüpft es und schaut dich an.")
            t.append("Zieh mit dem Finger zur Seite, dann dreht sich \(n).")
            t.append("Satt wird \(n) auch gratis, wenn du übst. Deine Münzen sind für Extras.")
            if let weiter = h.stufe.naechste {
                t.append("\(n) hat schon \(h.xp) Punkte. Ab \(weiter.schwelle) Punkten kommt die Stufe \(weiter.name).")
            } else {
                t.append("\(n) ist ein Meister! Du hast so viel geübt. Ich bin stolz auf dich.")
            }
        }
        if familie {
            t.append("Deine Eltern sehen \(n) auch und können ihm jeden Tag ein Leckerli schenken.")
        }
        return t
    }

    /// Der günstigste Hut, den das Kind noch nicht hat und sich leisten kann.
    static func guenstigsterHut(fuer h: Haustier, muenzen: Int) -> HaustierHut? {
        HaustierHut.alle
            .filter { !h.huete.contains($0.id) && $0.preis <= muenzen }
            .min { $0.preis < $1.preis }
    }

    // MARK: Tipps für die Eltern

    static func elternTipps(fuer h: Haustier?, leckerliFrei: Bool, spielFrei: Bool,
                            jetzt: Date = Date.now, kalender: Calendar = .current) -> [String] {
        let alle = elternLageTipps(fuer: h, leckerliFrei: leckerliFrei, spielFrei: spielFrei,
                                   jetzt: jetzt, kalender: kalender) + [
            "Lob dein Kind für jede Runde. Das freut es mehr als jedes Leckerli.",
            "Das Tier läuft nie weg und verliert nie sein Wachstum, auch nicht nach den Ferien.",
            "Ein Leckerli von dir ersetzt kein Üben. Groß wird das Tier nur durch die Runden deines Kindes.",
            "Wie dein Kind übt, siehst du im Reiter Übersicht."
        ]
        return ohneDoppelte(alle)
    }

    static func elternLageTipps(fuer h: Haustier?, leckerliFrei: Bool, spielFrei: Bool,
                                jetzt: Date = Date.now, kalender: Calendar = .current) -> [String] {
        guard let h else { return [] }
        let n = h.name
        if h.stufe == .ei {
            return ["Das Ei schlüpft mit der ersten Runde deines Kindes. Vielleicht übt ihr heute zusammen?"]
        }
        var t: [String] = []
        if HaustierZeit.schlaeft(jetzt, kalender: kalender) {
            t.append("\(n) schläft gerade. Ab 7 Uhr ist es wieder wach.")
        }
        switch h.stimmung {
        case .hungrig:
            t.append("\(n) hat Hunger. Eine Runde deines Kindes macht es satt, ein Leckerli von dir hilft auch.")
        case .traurig:
            t.append("\(n) ist traurig. Ein Spiel von dir hebt die Laune.")
        default:
            break
        }
        if leckerliFrei && spielFrei {
            t.append("Heute hast du noch ein Leckerli und ein Spiel frei.")
        } else if leckerliFrei {
            t.append("Heute hast du noch ein Leckerli frei.")
        } else if spielFrei {
            t.append("Heute hast du noch ein Spiel frei.")
        }
        return t
    }

    // MARK: Hilfen

    private static func ohneDoppelte(_ liste: [String]) -> [String] {
        var gesehen = Set<String>()
        return liste.filter { gesehen.insert($0).inserted }
    }

    /// Text zum Vorlesen: Emojis fallen weg, sonst liest die Stimme ihre Namen vor.
    static func sprechbar(_ text: String) -> String {
        let ohne = text.unicodeScalars.filter { s in
            let bild = s.properties.isEmoji && s.value > 0x7F
            return !bild && s.value != 0xFE0F && s.value != 0x200D
        }
        let roh = String(String.UnicodeScalarView(ohne))
        return roh.split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Die Stimme des Tiers

enum TierStimme {
    /// Etwas höher als die Eule, damit man hört, wer spricht.
    static let tonhoehe: Float = 1.3

    /// Was das Tier beim Antippen sagt. `nummer` zählt mit, damit nicht immer dasselbe kommt.
    static func antippen(_ h: Haustier, schlaeft: Bool, nummer: Int) -> String {
        let liste: [String]
        if h.stufe == .ei {
            liste = ["Klopf, klopf! Bald bin ich da.",
                     "Hier drin ist es warm und kuschelig.",
                     "Ich höre dich! Üb eine Runde, dann komme ich raus."]
        } else if schlaeft {
            liste = ["Zzz ... nur noch fünf Minuten ...",
                     "Schnarch ... Zzz ...",
                     "Mmh ... ich träume von dir ... Zzz ..."]
        } else {
            switch h.stimmung {
            case .froh:
                liste = ["Hihi, das kitzelt!", "Ich hab dich lieb!", "Heute ist ein super Tag!", "Nochmal hüpfen!"]
            case .zufrieden:
                liste = ["Schön, dass du da bist.", "Üben wir gleich zusammen?", "Mir geht es gut. Und dir?"]
            case .hungrig:
                liste = ["Mein Bauch knurrt ...", "Hast du was zu essen für mich?", "Eine Runde üben macht mich satt!"]
            case .traurig:
                liste = ["Spielst du mit mir?", "Ich hab dich vermisst.", "Bleibst du noch ein bisschen?"]
            }
        }
        return liste[abs(nummer) % liste.count]
    }

    /// Was das Tier von sich aus sagt, wenn gerade niemand getippt hat.
    static func vonSelbst(_ h: Haustier, schlaeft: Bool) -> String {
        if h.stufe != .ei && schlaeft { return "Zzz ... Um 7 Uhr bin ich wieder wach." }
        return h.spruch
    }
}

// MARK: - Sprechblase

/// Eine Sprechblase für Olli oder das Tier. Der Text erscheint Buchstabe für Buchstabe,
/// Antippen zeigt ihn sofort ganz. Bei der Einführung gibt es Punkte und "Weiter".
struct SprechBlase: View {
    let bild: String
    let wer: String
    let text: String
    var tonhoehe: Float = 1.0
    /// Mit Lautsprecher-Knopf zum Vorlesen
    var vorlesen = true
    /// Die Spitze zeigt nach links oben (zur Eule) oder in die Mitte (zum Tier).
    var spitzeLinks = false
    /// Ohne Spitze, wenn niemand darüber steht, der spricht.
    var mitSpitze = true
    var schritt: Int? = nil
    var schritte = 0
    var weiter: (() -> Void)? = nil
    var ueberspringen: (() -> Void)? = nil
    var schliessen: (() -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var ruhig
    @State private var sichtbar = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            kopf
            ZStack(alignment: .topLeading) {
                // Der volle Text hält den Platz frei, damit beim Schreiben nichts springt
                Text(text).opacity(0)
                Text(String(text.prefix(sichtbar)))
            }
            .font(.system(.body, design: .rounded).weight(.semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onTapGesture { sichtbar = text.count }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(text)
            if let schritt, let weiter {
                fuss(schritt: schritt, weiter: weiter)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(0.26))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.gelb.opacity(0.35), lineWidth: 1.5)
        )
        .overlay(alignment: spitzeLinks ? .topLeading : .top) {
            if mitSpitze {
                BlasenSpitze()
                    .fill(Color.black.opacity(0.26))
                    .frame(width: 22, height: 12)
                    .offset(x: spitzeLinks ? 34 : 0, y: -12)
                    .accessibilityHidden(true)
            }
        }
        .task(id: text) { await schreiben() }
    }

    private var kopf: some View {
        HStack(spacing: 8) {
            Text(bild).font(.system(size: 26))
            Text(wer)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
                .lineLimit(1)
            Spacer(minLength: 0)
            if vorlesen {
                Button {
                    Sprecher.shared.sprich(Eule.sprechbar(text), code: "de-DE", tonhoehe: tonhoehe)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 34, height: 34)
                        .background(Theme.gelb, in: Circle())
                }
                .buttonStyle(TastenStil())
                .accessibilityLabel("Vorlesen")
            }
            if let schliessen {
                Button(action: schliessen) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Color.white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.16), in: Circle())
                }
                .buttonStyle(TastenStil())
                .accessibilityLabel("Schließen")
            }
        }
    }

    private func fuss(schritt: Int, weiter: @escaping () -> Void) -> some View {
        let letzter = schritt >= schritte - 1
        return HStack(spacing: 12) {
            // Die Punkte zeigen, wie weit die Einführung schon ist
            HStack(spacing: 5) {
                ForEach(0..<max(schritte, 1), id: \.self) { i in
                    Circle()
                        .fill(i == schritt ? Theme.gelb : Color.white.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Schritt \(schritt + 1) von \(schritte)")
            Spacer(minLength: 0)
            if let ueberspringen, !letzter {
                Button("Überspringen", action: ueberspringen)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.textSanft)
            }
            Button(action: weiter) {
                Text(letzter ? "Los geht's!" : "Weiter")
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.navy)
                    .padding(.horizontal, 18)
                    .frame(minHeight: 40)
                    .background(Theme.gelb, in: Capsule())
            }
            .buttonStyle(TastenStil())
        }
    }

    private func schreiben() async {
        let alle = text.count
        if ruhig {
            sichtbar = alle
            return
        }
        sichtbar = 0
        while sichtbar < alle {
            do { try await Task.sleep(for: .milliseconds(18)) } catch { return }
            sichtbar = min(alle, sichtbar + 1)
        }
    }
}

/// Kleines Dreieck oben an der Sprechblase.
struct BlasenSpitze: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Kleiner Knopf unter der Bühne, damit man Olli auch ohne Tippen auf die Eule findet.
struct FragOlliKnopf: View {
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Label("Frag Olli", systemImage: "questionmark.bubble.fill")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Theme.gelb.opacity(0.15), in: Capsule())
        }
        .buttonStyle(TastenStil())
        .accessibilityHint("Die Eule Olli gibt dir einen Tipp für dein Haustier.")
    }
}
