import Foundation
import SwiftData
import Testing
@testable import YEM1N

// Die Lernwelt erzeugt alle Aufgaben selbst. Hier wird jedes Thema viele Male
// durchgespielt: Jede Rechnung muss stimmen, jede Antwort zum Antippen muss unter den
// Knöpfen stehen, und kein Text darf einen Gedankenstrich enthalten.

@MainActor
struct LehrplanTests {

    static let runden = 25

    private func texte(_ a: LernAufgabe) -> [String] {
        [a.frage, a.rechnung, a.antwort, a.antwort2, a.hinweis, a.erklaerung, a.bild] + a.optionen
    }

    // MARK: Alle Themen

    @Test func jedesThemaHatEineEindeutigeKennung() {
        let ids = Lernwelt.themen.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    @Test func jedesFachHatThemenInMehrerenKlassen() {
        for fach in LehrFach.allCases {
            let klassen = Set(Lernwelt.themen.filter { $0.fach == fach }.map { $0.klasse })
            #expect(klassen.count >= 2, "\(fach.name) hat nur Themen in \(klassen)")
        }
        for k in 1...4 {
            #expect(!Lernwelt.themenFuer(.mathe, klasse: k, land: .hessen).isEmpty)
            #expect(!Lernwelt.themenFuer(.deutsch, klasse: k, land: .bayern).isEmpty)
        }
    }

    @Test func jedesThemaLiefertZehnVerschiedeneAufgaben() {
        for t in Lernwelt.themen {
            for _ in 0..<3 {
                let liste = Lernwelt.aufgaben(t)
                #expect(liste.count == Lernwelt.anzahl, "\(t.id) liefert nur \(liste.count) Aufgaben")
                #expect(Set(liste.map { $0.schluessel }).count == liste.count, "\(t.id) hat doppelte Aufgaben")
            }
        }
    }

    @Test func antwortenZumAntippenStehenAlleUnterDenKnoepfen() {
        for t in Lernwelt.themen {
            for _ in 0..<Self.runden {
                let a = t.erzeuge()
                guard a.art == "wahl" else { continue }
                #expect(a.optionen.contains(a.antwort), "\(t.id): \(a.antwort) fehlt in \(a.optionen)")
                #expect(a.optionen.count >= 2, "\(t.id): zu wenig Knöpfe")
                #expect(Set(a.optionen).count == a.optionen.count, "\(t.id): doppelter Knopf \(a.optionen)")
                #expect(a.optionen.allSatisfy { !$0.isEmpty && !$0.contains("\n") })
            }
        }
    }

    @Test func zahlenAntwortenPassenInsFeld() {
        for t in Lernwelt.themen {
            for _ in 0..<Self.runden {
                let a = t.erzeuge()
                guard a.art == "zahl" || a.art == "rest" else { continue }
                let n = Int(a.antwort)
                #expect(n != nil && (n ?? -1) >= 0, "\(t.id): \(a.antwort)")
                #expect(a.antwort.count <= 7, "\(t.id): \(a.antwort) ist zu lang")
                if a.art == "rest" { #expect(Int(a.antwort2) != nil) }
            }
        }
    }

    /// Reine Rechnungen wie "47 + 8 =" rechnet der Rechner der App nach.
    @Test func jedeRechnungStimmt() throws {
        let rechenzeichen = CharacterSet(charactersIn: "0123456789 +-·:=")
        for t in Lernwelt.themen where t.fach == .mathe {
            for _ in 0..<60 {
                let a = t.erzeuge()
                guard a.rechnung.hasSuffix("="),
                      a.rechnung.unicodeScalars.allSatisfy({ rechenzeichen.contains($0) }) else { continue }
                if a.art == "rest" {
                    let z = zahlen(aus: a.rechnung)
                    let q = try #require(Int(a.antwort))
                    let r = try #require(Int(a.antwort2))
                    #expect(z.count == 2 && z[0] / z[1] == q && z[0] % z[1] == r, "\(a.rechnung) \(q) Rest \(r)")
                    #expect(r < z[1], "Der Rest muss kleiner als der Teiler sein")
                } else {
                    #expect(try MatheRechner.werte(a.rechnung.replacingOccurrences(of: " ", with: "")) == Int(a.antwort), "\(t.id): \(a.rechnung) \(a.antwort)")
                }
            }
        }
    }

    @Test func keineGedankenstricheInDenAufgaben() {
        for t in Lernwelt.themen {
            for text in [t.titel, t.beschreibung, t.tipp] {
                #expect(!text.contains("\u{2013}") && !text.contains("\u{2014}"), "\(t.id): \(text)")
            }
            for _ in 0..<10 {
                for text in texte(t.erzeuge()) {
                    #expect(!text.contains("\u{2013}") && !text.contains("\u{2014}"), "\(t.id): \(text)")
                }
            }
        }
    }

    // MARK: Klasse und Bundesland

    @Test func dieKlasseAusDemProfil() {
        #expect(Lernwelt.klasse(aus: "Klasse 3") == 3)
        #expect(Lernwelt.klasse(aus: "Vorschule") == 1)
        #expect(Lernwelt.klasse(aus: "") == nil)
        #expect(Lernwelt.klassenReihenfolge(eigene: 3) == [3, 1, 2, 4])
        #expect(Lernwelt.klassenReihenfolge(eigene: nil) == [1, 2, 3, 4])
    }

    @Test func bundeslaenderSetzenManchesInEineAndereKlasse() throws {
        let einmaleins = try #require(Lernwelt.themen.first { $0.id == "m2-einmaleins" })
        #expect(einmaleins.klasse(in: .hessen) == 2)
        #expect(einmaleins.klasse(in: .bayern) == 2)
        #expect(einmaleins.klasse(in: .nrw) == 3)
        #expect(Bundesland.aus("") == .hessen)
        #expect(Bundesland.aus("nrw") == .nrw)
    }

    @Test func englischStehtAbKlasseDreiImLehrplan() {
        for t in Lernwelt.themen where t.fach == .englisch {
            #expect(t.lehrplan == (t.klasse >= 3), "\(t.id)")
        }
    }

    // MARK: Mathe

    @Test func rundenWieInDerSchule() {
        #expect(LehrplanMathe.gerundet(3476, auf: 100) == 3500)
        #expect(LehrplanMathe.gerundet(3450, auf: 100) == 3500)
        #expect(LehrplanMathe.gerundet(3449, auf: 100) == 3400)
        #expect(LehrplanMathe.gerundet(45_500, auf: 1000) == 46_000)
        #expect(LehrplanMathe.gerundet(14, auf: 10) == 10)
    }

    @Test func grosseZahlenMitAbstand() {
        #expect(Lern.gross(345_678) == "345 678")
        #expect(Lern.gross(10_000) == "10 000")
        #expect(Lern.gross(9_999) == "9999")
        #expect(Lern.gross(1_000_000) == "1 000 000")
    }

    @Test func uhrzeitenStimmen() {
        #expect(LehrplanMathe.uhrzeit(9 * 60 + 5) == "9:05")
        #expect(LehrplanMathe.uhrzeit(14 * 60 + 45) == "14:45")
    }

    // MARK: Deutsch

    @Test func jedesNomenHatEinenArtikel() {
        for n in LehrplanDeutsch.nomen {
            #expect(["der", "die", "das"].contains(n.artikel), n.wort)
            #expect(n.wort.first?.isUppercase == true, n.wort)
            #expect(!LehrplanDeutsch.falscheMehrzahl(n).contains(n.mehrzahl), "\(n.wort): richtige Mehrzahl unter den falschen")
            #expect(LehrplanDeutsch.falscheMehrzahl(n).count >= 2, "\(n.wort): zu wenig falsche Formen")
        }
        #expect(Set(LehrplanDeutsch.nomen.map { $0.wort }).count == LehrplanDeutsch.nomen.count)
    }

    @Test func silbenWerdenGezaehlt() {
        #expect(LehrplanDeutsch.silbenZahl("Ba-na-ne") == 3)
        #expect(LehrplanDeutsch.silbenZahl("Ball") == 1)
        #expect(LehrplanDeutsch.silbenZahl("Scho-ko-la-de") == 4)
    }

    @Test func reimpaareReimenSichWirklich() {
        for (a, b) in LehrplanDeutsch.reimPaare {
            #expect(a.suffix(2).lowercased() == b.suffix(2).lowercased(), "\(a) und \(b)")
        }
    }

    @Test func lueckenwoerterHabenGenauEineLuecke() {
        for (luecke, richtig, falsch, lang) in LehrplanDeutsch.verlaengerWoerter {
            #expect(luecke.filter { $0 == "?" }.count == 1, luecke)
            #expect(richtig != falsch)
            let ganz = luecke.replacingOccurrences(of: "?", with: richtig)
            // In der verlängerten Form hört man den Buchstaben
            let stamm = String(ganz.dropLast()).lowercased()
            let lang2 = lang.lowercased().replacingOccurrences(of: "ä", with: "a")
                .replacingOccurrences(of: "ö", with: "o").replacingOccurrences(of: "ü", with: "u")
            let stamm2 = stamm.replacingOccurrences(of: "ä", with: "a")
                .replacingOccurrences(of: "ö", with: "o").replacingOccurrences(of: "ü", with: "u")
            #expect(lang2.contains(stamm2 + richtig), "\(ganz) und \(lang)")
        }
        for (luecke, richtig, ganz) in LehrplanDeutsch.ieWoerter {
            #expect(luecke.replacingOccurrences(of: "?", with: richtig) == ganz)
        }
        for (satz, _) in LehrplanDeutsch.dassSaetze {
            #expect(satz.components(separatedBy: "___").count == 2, satz)
        }
        for (satz, teil, fall) in LehrplanDeutsch.fallSaetze {
            #expect(satz.contains(teil), satz)
            #expect((1...4).contains(fall))
        }
    }

    @Test func dieVergangenheitIstNieUnterDenFalschen() {
        for v in LehrplanDeutsch.verben {
            #expect(v.praeteritum != v.praesens && v.praeteritum != v.partizip)
            if !v.schwach { #expect(LehrplanDeutsch.falschSchwach(v) != v.praeteritum) }
            #expect(["hat", "ist"].contains(v.hilfsverb))
        }
        #expect(LehrplanDeutsch.wirPraeteritum(LehrplanDeutsch.verben[0]) == "spielten")
        let gehen = LehrplanDeutsch.verben.first { $0.infinitiv == "gehen" }
        #expect(gehen.map { LehrplanDeutsch.wirPraeteritum($0) } == "gingen")
    }

    // MARK: Musik und Kunst

    @Test func jedeNoteHatNamenUndTon() {
        for n in Noten.alle {
            #expect(Noten.name[n] != nil && Noten.frequenz[n] != nil && Noten.stufe[n] != nil, n)
        }
        #expect(Noten.name["h1"] == "h", "Im Deutschen heißt die Note h, nicht b")
    }

    @Test func farbenMischenWieImMalkasten() {
        let m = Dictionary(uniqueKeysWithValues: LehrplanKunst.mischungen.map { ($0.0 + "+" + $0.1, $0.2) })
        #expect(m["blau+gelb"] == "Grün")
        #expect(m["rot+gelb"] == "Orange")
        #expect(m["rot+blau"] == "Violett")
    }

    // MARK: Weitere Themen

    @Test func zahlenmauernStimmenSteinFuerStein() {
        for id in ["m2-mauer", "m3-mauer"] {
            guard let t = Lernwelt.themen.first(where: { $0.id == id }) else {
                Issue.record("\(id) fehlt")
                continue
            }
            for _ in 0..<40 {
                let a = t.erzeuge()
                #expect(a.art == "mauer")
                for i in 1..<a.reihen.count {
                    for j in 0..<a.reihen[i].count {
                        #expect(a.reihen[i][j] == a.reihen[i - 1][j] + a.reihen[i - 1][j + 1])
                    }
                }
                let spitze = a.reihen.last?.first ?? 0
                #expect(spitze <= (id == "m2-mauer" ? 100 : 999), "\(id): Spitze \(spitze)")
            }
        }
    }

    @Test func vergleicheHabenDasRichtigeZeichen() {
        #expect(Lern.vergleich("3 + 4", 7, "9", 9).antwort == "<")
        #expect(Lern.vergleich("12", 12, "8", 8).antwort == ">")
        #expect(Lern.vergleich("2 · 6", 12, "3 · 4", 12).antwort == "=")
        for t in Lernwelt.themen {
            for _ in 0..<10 {
                let a = t.erzeuge()
                guard a.art == "vergleich" else { continue }
                #expect(["<", ">", "="].contains(a.antwort))
                #expect(a.rechnung.components(separatedBy: "  ?  ").count == 2, a.rechnung)
            }
        }
    }

    @Test func falscheTrennungenSindNieDieRichtige() {
        for w in LehrplanDeutschMehr.trennWoerter {
            let falsch = LehrplanDeutschMehr.falscheTrennungen(w)
            #expect(!falsch.isEmpty, w)
            #expect(!falsch.contains(w), w)
            for f in falsch {
                #expect(f.replacingOccurrences(of: "-", with: "") == w.replacingOccurrences(of: "-", with: ""))
            }
        }
        #expect(LehrplanDeutschMehr.falscheTrennungen("Zu-cker").contains("Zuc-ker"))
    }

    @Test func lueckenErgebenDasGanzeWort() {
        for (luecke, _, _, richtig, ganz) in LehrplanDeutschMehr.doppeltWoerter {
            #expect(luecke.replacingOccurrences(of: "?", with: richtig) == ganz, ganz)
        }
        for (luecke, richtig, _) in LehrplanDeutschMehr.sssWoerter {
            #expect(luecke.filter { $0 == "?" }.count == 1)
            #expect(["s", "ss", "ß"].contains(richtig))
        }
        for (luecke, richtig, falsch, _) in LehrplanDeutschMehr.ableitWoerter {
            #expect(luecke.filter { $0 == "?" }.count == 1)
            #expect(richtig != falsch)
        }
        for (_, b, ganz, artikel) in LehrplanDeutschMehr.komposita {
            #expect(ganz.lowercased().hasSuffix(b.lowercased()), ganz)
            #expect(["der", "die", "das"].contains(artikel))
        }
    }

    @Test func selbstlauteWerdenRichtigGefunden() {
        #expect(LehrplanDeutschMehr.vokalStellen("Hund") == [1])
        #expect(LehrplanDeutschMehr.vokalStellen("Haus").isEmpty, "au ist ein Doppellaut")
        #expect(LehrplanDeutschMehr.vokalStellen("Tomate") == [1, 3, 5])
    }

    @Test func satzgliederStehenImSatz() {
        for (satz, subjekt, praedikat) in LehrplanDeutschMehr.gliederSaetze {
            let w = LehrplanDeutschMehr.woerter(satz)
            #expect(w.contains(subjekt) && w.contains(praedikat), satz)
        }
    }

    @Test func leseFragenHabenEineEindeutigeAntwort() {
        for texte in [LehrplanLesen.klasse1, LehrplanLesen.klasse2, LehrplanLesen.klasse3, LehrplanLesen.klasse4] {
            for t in texte {
                #expect(!t.fragen.isEmpty, t.titel)
                for (frage, richtig, falsch) in t.fragen {
                    #expect(!falsch.contains(richtig), frage)
                    #expect(falsch.count >= 2, frage)
                }
            }
        }
    }

    @Test func steigerungenSindNieUnterDenFalschen() {
        for _ in 0..<80 {
            let a = LehrplanDeutschMehr.steigern()
            #expect(a.optionen.filter { $0 == a.antwort }.count == 1)
        }
    }

    // MARK: Speichern als Übung

    @Test func eineFertigeUebungBekommtNeueAufgabenUndBehaeltDieSterne() throws {
        let container = try ModelContainer(for: Klassenarbeit.self, Uebung.self, Aufgabe.self,
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let t = try #require(Lernwelt.themen.first { $0.id == "d2-artikel" })
        let u = Lernwelt.uebung(fuer: t, land: .hessen, vorhandene: [], in: context)
        try context.save()
        #expect(u.aufgaben.count == Lernwelt.anzahl)
        #expect(u.arbeit?.spezial == Lernwelt.spezial)
        #expect(u.arbeit?.klasse == "Klasse 2")
        #expect(u.aufgaben.allSatisfy { $0.art == "wahl" && $0.optionenListe.contains($0.antwort) })

        // Angefangen: dieselbe Übung geht weiter
        u.sortierteAufgaben.first?.richtig = true
        var alle = try context.fetch(FetchDescriptor<Klassenarbeit>())
        #expect(Lernwelt.uebung(fuer: t, land: .hessen, vorhandene: alle, in: context) === u)

        // Fertig: neue Aufgaben, Sterne bleiben
        u.aufgaben.forEach { $0.richtig = true }
        u.sterne = 3
        u.beste = 10
        alle = try context.fetch(FetchDescriptor<Klassenarbeit>())
        let neu = Lernwelt.uebung(fuer: t, land: .hessen, vorhandene: alle, in: context)
        try context.save()
        #expect(neu !== u)
        #expect(neu.sterne == 3 && neu.beste == 10)
        #expect(neu.aufgaben.allSatisfy { $0.richtig == nil })
    }
}
