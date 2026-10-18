import Foundation
import Testing
@testable import YEM1N

// Beim Duell rechnen zwei gegeneinander, jeder auf seiner Stufe.
// Jede Aufgabe muss stimmen, die Wertung muss fair sein und die Herausforderungen
// über die Familien-Cloud müssen bei den richtigen Leuten ankommen.

@MainActor
struct DuellTests {

    // MARK: Aufgaben

    @Test(arguments: DuellStufe.allCases)
    func jedeAufgabeStimmt(stufe: DuellStufe) throws {
        for _ in 0..<60 {
            let liste = DuellRegeln.aufgaben(stufe)
            #expect(liste.count == DuellRegeln.anzahl)
            #expect(Set(liste.map { $0.rechnung }).count == liste.count, "Keine Aufgabe doppelt")
            for a in liste {
                #expect(try MatheRechner.werte(a.rechnung) == a.antwort, "\(a.rechnung)")
                #expect((1...999).contains(a.antwort), "\(a.rechnung) = \(a.antwort) passt nicht in drei Felder")
            }
        }
    }

    @Test func klasseEinsBleibtImZahlenraumBisZwanzig() {
        for _ in 0..<80 {
            for a in DuellRegeln.aufgaben(.klasse1) {
                #expect(a.antwort <= 20)
                #expect(zahlen(aus: a.rechnung).allSatisfy { $0 <= 20 }, "\(a.rechnung)")
                #expect(a.rechnung.contains("+") || a.rechnung.contains("-"))
            }
        }
    }

    @Test func klasseZweiBleibtBisHundert() {
        for _ in 0..<80 {
            for a in DuellRegeln.aufgaben(.klasse2) {
                #expect(a.antwort <= 100, "\(a.rechnung)")
                #expect(!a.rechnung.contains(":"), "Geteilt kommt erst in Klasse 3")
            }
        }
    }

    @Test func dieStufePasstZurKlasseImProfil() {
        #expect(DuellStufe.passend(zuKlasse: "Vorschule") == .klasse1)
        #expect(DuellStufe.passend(zuKlasse: "Klasse 1") == .klasse1)
        #expect(DuellStufe.passend(zuKlasse: "Klasse 2") == .klasse2)
        #expect(DuellStufe.passend(zuKlasse: "Klasse 3") == .klasse3)
        #expect(DuellStufe.passend(zuKlasse: "Klasse 4") == .klasse4)
        #expect(DuellStufe.passend(zuKlasse: "") == .klasse3)
    }

    // MARK: Ein Durchgang

    @Test func eineFalscheAntwortKostetDreiSekunden() {
        var lauf = DuellLauf(aufgaben: [DuellAufgabe(rechnung: "7 · 8", antwort: 56),
                                        DuellAufgabe(rechnung: "3 + 4", antwort: 7)])
        #expect(lauf.antworte("") == nil, "Ohne Eingabe passiert nichts")
        #expect(lauf.index == 0)
        #expect(lauf.antworte("54") == false)
        #expect(lauf.strafe == 3)
        #expect(lauf.antworte("7") == true)
        #expect(lauf.fertig)
        #expect(lauf.antworte("7") == nil, "Nach der letzten Aufgabe zählt nichts mehr")
        #expect(lauf.stand(sekunden: 20) == DuellStand(richtig: 1, falsch: 1, sekunden: 23))
    }

    // MARK: Wertung

    @Test func mehrRichtigeGewinnenAuchWennLangsamer() {
        let schnell = DuellStand(richtig: 8, falsch: 2, sekunden: 30)
        let gruendlich = DuellStand(richtig: 9, falsch: 1, sekunden: 60)
        #expect(DuellRegeln.sieger(schnell, gruendlich) == 1)
        #expect(DuellRegeln.sieger(gruendlich, schnell) == 0)
    }

    @Test func beiGleichVielenRichtigenZaehltDieZeit() {
        let a = DuellStand(richtig: 9, falsch: 1, sekunden: 41.2)
        let b = DuellStand(richtig: 9, falsch: 1, sekunden: 44.0)
        #expect(DuellRegeln.sieger(a, b) == 0)
        #expect(DuellRegeln.sieger(b, a) == 1)
        let fastGleich = DuellStand(richtig: 9, falsch: 1, sekunden: 41.25)
        #expect(DuellRegeln.sieger(a, fastGleich) == nil, "Unter einer Zehntelsekunde ist es unentschieden")
    }

    @Test func zeitenStehenMitKomma() {
        #expect(DuellRegeln.zeitText(48.25) == "48,3 s")
        #expect(DuellRegeln.zeitText(48.24) == "48,2 s")
        #expect(DuellRegeln.zeitText(0) == "0,0 s")
        #expect(DuellRegeln.zeitText(-1) == "0,0 s")
        #expect(DuellRegeln.standText(DuellStand(richtig: 9, falsch: 1, sekunden: 50)) == "9 von 10 richtig in 50,0 s")
    }

    // MARK: Herausforderungen in der Familie

    private let jetzt = Date(timeIntervalSince1970: 2_000_000_000)

    private func duell(_ id: String, von geraet: String, vorTagen: Double = 0,
                       richtig: Int = 9) -> DuellHerausforderung {
        DuellHerausforderung(id: id, von: geraet == "papa" ? "Papa" : "Yemin", vonGeraet: geraet,
                             vonStufe: .profi, vonStand: DuellStand(richtig: richtig, falsch: 10 - richtig, sekunden: 50),
                             anStufe: .klasse3, aufgaben: DuellRegeln.aufgaben(.klasse3),
                             zeitpunkt: jetzt.addingTimeInterval(-vorTagen * 86400))
    }

    private func antwort(_ id: String, von geraet: String, richtig: Int = 10, vorTagen: Double = 0) -> DuellAntwort {
        DuellAntwort(duellID: id, name: geraet == "papa" ? "Papa" : "Yemin", geraet: geraet,
                     stand: DuellStand(richtig: richtig, falsch: 10 - richtig, sekunden: 55),
                     zeitpunkt: jetzt.addingTimeInterval(-vorTagen * 86400))
    }

    @Test func offenSindNurFremdeUndNochNichtAngenommeneHerausforderungen() {
        let duelle = [duell("a", von: "papa", vorTagen: 1),
                      duell("b", von: "papa", vorTagen: 0),
                      duell("c", von: "yemin"),
                      duell("alt", von: "papa", vorTagen: 20)]
        let antworten = [antwort("a", von: "yemin")]
        let offen = DuellPost.offen(duelle, antworten, geraet: "yemin", jetzt: jetzt)
        #expect(offen.map { $0.id } == ["b"], "a ist beantwortet, c ist die eigene, alt ist abgelaufen")
    }

    @Test func eigeneHerausforderungenWartenBisJemandAntwortet() {
        let duelle = [duell("a", von: "papa"), duell("b", von: "papa", vorTagen: 1)]
        let antworten = [antwort("a", von: "yemin")]
        #expect(DuellPost.wartend(duelle, antworten, geraet: "papa", jetzt: jetzt).map { $0.id } == ["b"])
        #expect(DuellPost.wartend(duelle, antworten, geraet: "yemin", jetzt: jetzt).isEmpty)
    }

    @Test func entschiedeneDuelleNennenDenSieger() {
        let duelle = [duell("a", von: "papa", richtig: 9), duell("b", von: "papa", richtig: 10)]
        let antworten = [antwort("a", von: "yemin", richtig: 10, vorTagen: 1),
                         antwort("b", von: "yemin", richtig: 8, vorTagen: 0),
                         antwort("weg", von: "yemin")]
        let liste = DuellPost.entschieden(duelle, antworten)
        #expect(liste.map { $0.duell.id } == ["b", "a"], "Neueste zuerst, Antworten ohne Duell fallen weg")
        #expect(liste[0].siegerName == "Papa")
        #expect(liste[1].siegerName == "Yemin")
    }

    @Test func herausforderungenUeberstehenDenWegDurchDieCloud() throws {
        let d = duell("x", von: "papa")
        let text = try #require(DuellPost.text(d))
        #expect(DuellPost.lies(text, als: DuellHerausforderung.self) == d)
        #expect(DuellPost.lies("kaputt", als: DuellHerausforderung.self) == nil)
    }

    @Test func dasGeraetBehaeltSeineKennung() {
        let name = "duell-test-\(UUID().uuidString)"
        let speicher = UserDefaults(suiteName: name) ?? .standard
        speicher.removePersistentDomain(forName: name)
        let erste = DuellPost.geraet(speicher: speicher)
        #expect(!erste.isEmpty)
        #expect(DuellPost.geraet(speicher: speicher) == erste)
    }

    @Test func duellMitteilungenFuehrenZumDuell() {
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: "Duell-ABCDE-12345") == "duell")
        #expect(MitteilungsZiel.bereich(ziel: nil, kennung: "x", abo: "DuellAntwort-ABCDE-12345") == "duell")
    }
}
