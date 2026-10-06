import Foundation
import Testing
@testable import YEM1N

// Die Generatoren erzeugen die Aufgaben, die das Kind sieht.
// Hier wird jede erzeugte Aufgabe nachgerechnet.

@MainActor
struct MatheGeneratorTests {

    /// Wie viele Aufgaben je Vorlage geprüft werden.
    static let proVorlage = 150

    // MARK: Aufbau einer Klassenarbeit

    @Test func eineArbeitHatAlleUebungenInDerRichtigenGroesse() {
        let arbeit = MatheGenerator.neueArbeit(titel: "Testarbeit",
                                               klasse: "Klasse 3",
                                               fach: "Mathe",
                                               ausschluss: [])
        #expect(arbeit.uebungen.count == MatheGenerator.vorlagen.count)
        for (uebung, vorlage) in zip(arbeit.uebungen, MatheGenerator.vorlagen) {
            #expect(uebung.titel == vorlage.name)
            #expect(uebung.gruppe == vorlage.gruppe)
            #expect(uebung.aufgaben.count == vorlage.anzahl,
                    "\(vorlage.name) hat \(uebung.aufgaben.count) statt \(vorlage.anzahl) Aufgaben")
        }
    }

    @Test func innerhalbEinerArbeitGibtEsKeineDoppelteAufgabe() {
        let arbeit = MatheGenerator.neueArbeit(titel: "Testarbeit",
                                               klasse: "Klasse 3",
                                               fach: "Mathe",
                                               ausschluss: [])
        var gesehen = Set<String>()
        var gesamt = 0
        for uebung in arbeit.uebungen {
            for aufgabe in uebung.aufgaben {
                gesamt += 1
                let schluessel = MatheGenerator.schluessel(aufgabe)
                #expect(!gesehen.contains(schluessel), "doppelt: \(schluessel)")
                gesehen.insert(schluessel)
            }
        }
        #expect(gesehen.count == gesamt)
    }

    @Test func bereitsVorhandeneAufgabenKommenNichtNochEinmal() {
        let erste = MatheGenerator.neueArbeit(titel: "Nr. 1", klasse: "Klasse 3", fach: "Mathe", ausschluss: [])
        var sperre = Set<String>()
        for uebung in erste.uebungen {
            for aufgabe in uebung.aufgaben { sperre.insert(MatheGenerator.schluessel(aufgabe)) }
        }
        let zweite = MatheGenerator.neueArbeit(titel: "Nr. 2", klasse: "Klasse 3", fach: "Mathe", ausschluss: sperre)
        for uebung in zweite.uebungen {
            for aufgabe in uebung.aufgaben {
                let schluessel = MatheGenerator.schluessel(aufgabe)
                #expect(!sperre.contains(schluessel), "kam schon in Nr. 1 vor: \(schluessel)")
            }
        }
    }

    // MARK: Jede einzelne Aufgabe

    @Test func jedeErzeugteAufgabeIstRichtig() {
        for vorlage in MatheGenerator.vorlagen {
            for _ in 0..<Self.proVorlage {
                pruefe(vorlage.mach(), vorlage: vorlage.id)
            }
        }
    }

    private func pruefe(_ a: MatheAufgabe, vorlage: String) {
        #expect(!a.frage.isEmpty, "\(vorlage): Frage fehlt")

        switch a.art {
        case "mauer":
            pruefeMauer(a)
            return
        case "rest":
            pruefeRest(a)
            return
        case "vergleich":
            pruefeVergleich(a)
            return
        default:
            break
        }

        // Alle übrigen Aufgaben sind vom Typ "zahl" mit ganzzahliger Antwort
        #expect(a.art == "zahl", "\(vorlage): unbekannte Art \(a.art)")
        guard let antwort = Int(a.antwort) else {
            Issue.record("\(vorlage): Antwort „\(a.antwort)“ ist keine ganze Zahl (\(a.rechnung))")
            return
        }
        #expect((0...999).contains(antwort), "\(vorlage): Antwort \(antwort) liegt außerhalb von 0 bis 999")

        // Reine Rechenaufgaben werden nachgerechnet
        let hatBuchstaben = a.rechnung.contains { $0.isLetter }
        if !hatBuchstaben, let wert = try? MatheRechner.werte(a.rechnung) {
            #expect(wert == antwort, "\(vorlage): \(a.rechnung) ergibt \(wert), angegeben ist \(antwort)")
        }

        switch vorlage {
        case "minuswort":
            let n = zahlen(aus: a.rechnung)
            #expect(n.count == 2, "\(vorlage): \(a.rechnung)")
            if n.count == 2 { #expect(antwort == n[0] - n[1], "\(a.rechnung) → \(antwort)") }
        case "malwort":
            let n = zahlen(aus: a.rechnung)
            #expect(n.count >= 2, "\(vorlage): \(a.rechnung)")
            if n.count >= 2 { #expect(antwort == n.reduce(1, *), "\(a.rechnung) → \(antwort)") }
        case "kern":
            let n = zahlen(aus: a.rechnung)
            #expect(n.count == 2 && [1, 2, 5, 10].contains(n[0]), "Kernaufgabe ohne Kernzahl: \(a.rechnung)")
        case "raetsel":
            pruefeRaetsel(a)
        case "sach":
            pruefeErklaerung(a)
        default:
            break
        }
    }

    /// Bei Sachaufgaben steht die Rechnung nur in der Erklärung, zum Beispiel "75 + 12 = 87".
    private func pruefeErklaerung(_ a: MatheAufgabe) {
        let teile = a.erklaerung.components(separatedBy: " = ")
        guard teile.count == 2, let soll = Int(teile[1]) else {
            Issue.record("Erklärung ohne Ergebnis: \(a.erklaerung)")
            return
        }
        guard let wert = try? MatheRechner.werte(teile[0]) else {
            Issue.record("Erklärung nicht rechenbar: \(a.erklaerung)")
            return
        }
        #expect(wert == soll, "Erklärung stimmt nicht: \(a.erklaerung)")
        #expect(String(soll) == a.antwort, "Erklärung und Antwort passen nicht: \(a.erklaerung) / \(a.antwort)")
    }

    // MARK: Einzelne Arten

    private func pruefeRest(_ a: MatheAufgabe) {
        let n = zahlen(aus: a.rechnung)
        guard n.count == 2, let q = Int(a.antwort), let r = Int(a.antwort2) else {
            Issue.record("Teilen mit Rest unverständlich: \(a.rechnung) → \(a.antwort) R \(a.antwort2)")
            return
        }
        let dividend = n[0]
        let teiler = n[1]
        #expect(teiler > 0, "Teiler 0 bei \(a.rechnung)")
        #expect(dividend <= 100, "Dividend \(dividend) ist größer als 100")
        #expect(r >= 0 && r < teiler, "Rest \(r) passt nicht zum Teiler \(teiler)")
        #expect(q * teiler + r == dividend, "\(a.rechnung) → \(q) R \(r) stimmt nicht")
    }

    private func pruefeVergleich(_ a: MatheAufgabe) {
        let teile = a.rechnung.components(separatedBy: "  ?  ")
        guard teile.count == 2 else {
            Issue.record("Vergleich ohne zwei Seiten: \(a.rechnung)")
            return
        }
        guard let links = try? MatheRechner.werte(teile[0]),
              let rechts = try? MatheRechner.werte(teile[1]) else {
            Issue.record("Vergleich nicht rechenbar: \(a.rechnung)")
            return
        }
        let soll = links > rechts ? ">" : (links < rechts ? "<" : "=")
        #expect(a.antwort == soll, "\(a.rechnung): \(links) \(a.antwort) \(rechts) ist falsch")
    }

    private func pruefeMauer(_ a: MatheAufgabe) {
        guard a.reihen.count == 4, a.reihen[0].count == 4 else {
            Issue.record("Mauer hat die falsche Form: \(a.reihen)")
            return
        }
        for stein in a.reihen[0] {
            #expect((3...15).contains(stein), "Grundstein \(stein) liegt außerhalb von 3 bis 15")
        }
        for i in 1..<a.reihen.count {
            let unten = a.reihen[i - 1]
            let oben = a.reihen[i]
            #expect(oben.count == unten.count - 1, "Reihe \(i) hat die falsche Länge")
            for j in 0..<oben.count where j + 1 < unten.count {
                #expect(oben[j] == unten[j] + unten[j + 1],
                        "Mauer stimmt nicht: \(unten[j]) + \(unten[j + 1]) ist nicht \(oben[j])")
            }
        }
        #expect((a.reihen.last?.first ?? 0) <= 100, "Mauerspitze größer als 100: \(a.reihen)")
    }

    private func pruefeRaetsel(_ a: MatheAufgabe) {
        let zeilen = a.rechnung.components(separatedBy: "\n")
        guard zeilen.count == 3, let ziel = Int(a.antwort) else {
            Issue.record("Rätsel unverständlich: \(a.rechnung)")
            return
        }
        let ungerade = zeilen[0].contains("ungerade")
        var vielfaches = 0
        for k in 1...10 {
            let wort = MatheGenerator.zahlwort(k)
            if !wort.isEmpty && zeilen[1].contains(wort + "zahl") { vielfaches = k }
        }
        let grenzen = zahlen(aus: zeilen[2])
        guard vielfaches > 0, grenzen.count == 2, grenzen[0] < grenzen[1] else {
            Issue.record("Rätsel ohne klare Bedingungen: \(a.rechnung)")
            return
        }
        let treffer = ((grenzen[0] + 1)..<grenzen[1]).filter {
            $0 % vielfaches == 0 && (($0 % 2 == 1) == ungerade)
        }
        #expect(treffer == [ziel], "Rätsel nicht eindeutig: \(a.rechnung) → \(treffer), angegeben \(ziel)")
    }
}
