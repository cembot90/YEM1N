import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security
import WebKit
import CoreImage.CIFilterBuiltins

// MARK: - Nachrichten an die Familie (Texte fürs Teilen-Menü)

// Alle Texte, die YEM1N an die Familie schickt (Teilen-Menü jetzt, später auch Mitteilungen).
// Aussehen und Wortlaut änderst du nur hier.

enum Nachricht {
    static let logo = "𝗬𝗘𝗠𝟭𝗡"
    static let linie = "━━━━━━━━━━━━━━"

    // MARK: Bausteine

    static func prozent(_ richtig: Int, _ gesamt: Int) -> Int {
        guard gesamt > 0 else { return 0 }
        return Int((Double(richtig) / Double(gesamt) * 100).rounded())
    }

    // Zehn Felder, gelb für richtig
    static func balken(_ richtig: Int, _ gesamt: Int) -> String {
        let laenge = 10
        guard gesamt > 0 else { return String(repeating: "⬜️", count: laenge) }
        let voll = min(laenge, max(0, Int((Double(richtig) / Double(gesamt) * Double(laenge)).rounded())))
        return String(repeating: "🟨", count: voll) + String(repeating: "⬜️", count: laenge - voll)
    }

    static func sterne(_ n: Int) -> String {
        let an = min(max(n, 0), 3)
        return String(repeating: "⭐️", count: an) + String(repeating: "▫️", count: 3 - an)
    }

    // Zuruf je nach Sternen
    static func zuruf(_ sterne: Int) -> String {
        switch sterne {
        case 3: return "TOOOR! Weltklasse, so macht man das! ⚽️🔥"
        case 2: return "Starker Spielzug! Nur noch ein bisschen Feinschliff. 💪"
        case 1: return "Anstoß geglückt. Gleich noch eine Runde, dann sitzt es! 🚀"
        default: return "Kein Ding. Gemeinsam anschauen, dann klappt es. 🤝"
        }
    }

    private static func jokerFuss() -> [String] {
        [
            linie,
            "💡 Gebt mir einen Tipp, aber verratet nicht die Lösung!",
            "⚡️ Wer zuerst hilft: +3 Punkte",
            "👍 Wenn der Tipp hilft: +2 Punkte"
        ]
    }

    // MARK: Mathe: Rundenergebnis

    static func ergebnisMathe(_ u: Uebung) -> String {
        let gut = u.richtigAnzahl
        let gesamt = u.aufgaben.count
        let n = sterneFuer(gut: gut, gesamt: gesamt)
        var z: [String] = []
        z.append("🏆 \(logo) · Runde geschafft!")
        z.append(linie)
        z.append("\(u.symbol) \(u.titel)")
        z.append("\(sterne(n))  \(gut) von \(gesamt) richtig")
        z.append("\(balken(gut, gesamt))  \(prozent(gut, gesamt)) %")
        z.append(linie)
        if let a = u.arbeit {
            z.append("📚 \(a.klasse) · \(a.fach) · \(a.titel)")
        }
        if u.angesehenAnzahl > 0 {
            z.append("👀 Lösung angeschaut: \(u.angesehenAnzahl)")
        }
        var fehler: [String] = []
        for a in u.sortierteAufgaben where a.richtig == false {
            if fehler.count >= 3 { break }
            fehler.append(kurz(a))
        }
        if !fehler.isEmpty {
            z.append("🔎 Noch üben: " + fehler.joined(separator: "  ·  "))
        }
        z.append("")
        z.append(zuruf(n))
        return z.joined(separator: "\n")
    }

    private static func kurz(_ a: Aufgabe) -> String {
        if a.art == "mauer" { return "Zahlenmauer" }
        let roh = a.rechnung.isEmpty ? a.frage : a.rechnung
        return String(roh.replacingOccurrences(of: "\n", with: " ").prefix(34))
    }

    // MARK: Sprachen: Rundenergebnis

    static func ergebnisSprache(thema: Thema, art: SprachArt, sprache: String,
                                richtig: Int, gesamt: Int, fehler: [Wort] = []) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let n = sterneFuer(gut: richtig, gesamt: gesamt)
        var z: [String] = []
        z.append("🏆 \(logo) · Sprachrunde geschafft!")
        z.append(linie)
        z.append("\(info.flagge) \(info.name) · \(thema.emoji) \(thema.titel)")
        z.append("🎮 \(art.titel)")
        z.append("\(sterne(n))  \(richtig) von \(gesamt) richtig")
        z.append("\(balken(richtig, gesamt))  \(prozent(richtig, gesamt)) %")
        z.append(linie)
        var liste: [String] = []
        for w in fehler {
            if liste.count >= 3 { break }
            let fremd = w.texte[sprache] ?? ""
            let de = w.texte["de"] ?? ""
            liste.append("\(fremd) = \(de)")
        }
        if !liste.isEmpty {
            z.append("🔎 Noch üben: " + liste.joined(separator: "  ·  "))
        }
        z.append("")
        z.append(zuruf(n))
        return z.joined(separator: "\n")
    }

    // MARK: Joker

    static func jokerMathe(_ a: Aufgabe) -> String {
        var z: [String] = []
        z.append("🃏🚨 \(logo) · JOKER!")
        z.append(linie)
        z.append("Ich komme nicht weiter und brauche eure Hilfe!")
        if let u = a.uebung {
            z.append("📚 Mathe · \(u.symbol) \(u.titel)")
        }
        z.append("")
        if !a.frage.isEmpty {
            z.append("📝 \(a.frage)")
        }
        z.append("❓ " + aufgabenText(a))
        z.append(contentsOf: jokerFuss())
        return z.joined(separator: "\n")
    }

    private static func aufgabenText(_ a: Aufgabe) -> String {
        if a.art == "mauer" {
            let basis = (a.reihen.first ?? []).map { String($0) }.joined(separator: " · ")
            return "Zahlenmauer, unterste Reihe: \(basis)"
        }
        return a.rechnung.replacingOccurrences(of: "\n", with: " ")
    }

    static func jokerSprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        var z: [String] = []
        z.append("🃏🚨 \(logo) · JOKER!")
        z.append(linie)
        z.append("Ich komme nicht weiter und brauche eure Hilfe!")
        z.append("\(info.flagge) \(info.name)")
        z.append("")
        z.append("❓ " + kern)
        z.append(contentsOf: jokerFuss())
        return z.joined(separator: "\n")
    }

    // Kurzfassung für die Cloud (das Postfach der Eltern zeigt nur die Aufgabe)
    static func jokerKurzMathe(_ a: Aufgabe) -> String {
        var z: [String] = []
        if let u = a.uebung {
            z.append("📚 Mathe · \(u.symbol) \(u.titel)")
        }
        if !a.frage.isEmpty {
            z.append("📝 \(a.frage)")
        }
        z.append("❓ " + aufgabenText(a))
        return z.joined(separator: "\n")
    }

    static func jokerKurzSprache(_ f: Frage, sprache: String) -> String {
        let info = SprachKatalogStore.shared.sprache(sprache)
        let de = f.wort.texte["de"] ?? ""
        let fremd = f.wort.texte[sprache] ?? ""
        let b = SprachHelfer.bild(f.wort)
        let kern: String
        switch f.typ {
        case .de2f, .tipp:
            kern = "Wie heißt „\(de)“ auf \(info.name)?"
        case .bild:
            kern = "Wie heißt \(b) auf \(info.name)?"
        case .f2de:
            kern = "Was bedeutet „\(fremd)“?"
        case .hoer:
            kern = "Ich habe „\(fremd)“ gehört. Was bedeutet das?"
        }
        return "\(info.flagge) \(info.name)\n❓ " + kern
    }

    // MARK: Sprachen: Lernbericht

    static func berichtSprache(_ c: String) -> String {
        let store = SprachKatalogStore.shared
        let stand = SprachStand.shared
        let info = store.sprache(c)
        let woerter = store.alleWoerter(c)
        let gelernt = woerter.filter { stand.gelernt($0, c) }.count

        var z: [String] = []
        z.append("📊 \(logo) · Lernbericht")
        z.append(linie)
        z.append("\(info.flagge) \(info.name)")
        z.append("🎯 \(gelernt) von \(woerter.count) Wörtern gelernt")
        z.append("\(balken(gelernt, woerter.count))  \(prozent(gelernt, woerter.count)) %")

        let letzte = Array(stand.verlauf.filter { $0.sp == c }.suffix(5).reversed())
        if !letzte.isEmpty {
            z.append(linie)
            z.append("🔥 Letzte Runden")
            for x in letzte {
                let datum = x.ts.formatted(.dateTime.day(.twoDigits).month(.twoDigits))
                let st = sterne(sterneFuer(gut: x.richtig, gesamt: x.gesamt))
                z.append("• \(datum)  \(x.thema)  \(x.richtig)/\(x.gesamt)  \(st)")
            }
        }

        var knifflig: [(String, Int)] = []
        for w in woerter {
            let f = stand.eintrag(w, c).f
            if f > 0 { knifflig.append((w.texte[c] ?? "", f)) }
        }
        knifflig.sort { $0.1 > $1.1 }
        if !knifflig.isEmpty {
            var teile: [String] = []
            for k in knifflig.prefix(3) { teile.append("\(k.0) (\(k.1)×)") }
            z.append(linie)
            z.append("🔎 Knifflig: " + teile.joined(separator: " · "))
        }
        z.append(linie)
        z.append("Dranbleiben, Champion! 💛💙")
        return z.joined(separator: "\n")
    }

    // MARK: Familiencode

    static func familiencode(_ code: String) -> String {
        [
            "🔐 \(logo) · Familiencode",
            linie,
            code,
            linie,
            "So verbindest du dein Gerät:",
            "1️⃣ App YEM1N öffnen",
            "2️⃣ „Kind“ oder „Eltern“ wählen",
            "3️⃣ Code eingeben",
            "",
            "Bitte nicht weitergeben, der Code gehört nur eurer Familie. 💛💙"
        ].joined(separator: "\n")
    }
}
