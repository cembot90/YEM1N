import Foundation
import Testing
@testable import YEM1N

// Serien, Tagesziel und Abzeichen. Ein Kind merkt sofort,
// wenn hier etwas nicht stimmt.

@MainActor
struct ErfolgeTests {

    private func erreicht(_ id: String, _ liste: [RundenErgebnis], ziel: Int = 2) -> Bool {
        Erfolge.pokale(liste, ziel: ziel).first { $0.id == id }?.erreicht ?? false
    }

    // MARK: Serie

    @Test func serieZaehltAufeinanderfolgendeTage() {
        let runden = [testRunde(vorTagen: 0), testRunde(vorTagen: 1), testRunde(vorTagen: 2)]
        #expect(Erfolge.serie(runden) == 3)
    }

    @Test func mehrereRundenAmSelbenTagZaehlenNurEinmal() {
        let runden = [testRunde(vorTagen: 0), testRunde(vorTagen: 0), testRunde(vorTagen: 0)]
        #expect(Erfolge.serie(runden) == 1)
    }

    @Test func serieLaeuftAuchWeiterWennHeuteNochNichtsWar() {
        // Gestern und vorgestern geübt, heute noch nicht: Die Serie lebt noch.
        let runden = [testRunde(vorTagen: 1), testRunde(vorTagen: 2)]
        #expect(Erfolge.serie(runden) == 2)
    }

    @Test func eineLueckeBeendetDieSerie() {
        let runden = [testRunde(vorTagen: 0), testRunde(vorTagen: 2), testRunde(vorTagen: 3)]
        #expect(Erfolge.serie(runden) == 1)
    }

    @Test func ohneRundenGibtEsKeineSerie() {
        #expect(Erfolge.serie([]) == 0)
        #expect(Erfolge.besteSerie([]) == 0)
        #expect(Erfolge.rundenHeute([]) == 0)
    }

    @Test func altesUebenZaehltNichtMehrFuerDieAktuelleSerie() {
        let runden = [testRunde(vorTagen: 5), testRunde(vorTagen: 6)]
        #expect(Erfolge.serie(runden) == 0)
        #expect(Erfolge.besteSerie(runden) == 2)
    }

    @Test func besteSerieFindetDenLaengstenAbschnitt() {
        let runden = [testRunde(vorTagen: 0),
                      testRunde(vorTagen: 1),
                      testRunde(vorTagen: 5),
                      testRunde(vorTagen: 6),
                      testRunde(vorTagen: 7),
                      testRunde(vorTagen: 8)]
        #expect(Erfolge.besteSerie(runden) == 4)
        #expect(Erfolge.serie(runden) == 2)
    }

    // MARK: Tagesziel

    @Test func rundenHeuteUndZieltage() {
        let runden = [testRunde(vorTagen: 0),
                      testRunde(vorTagen: 0),
                      testRunde(vorTagen: 1)]
        #expect(Erfolge.rundenHeute(runden) == 2)
        #expect(Erfolge.zieltage(runden, ziel: 2) == 1)
        #expect(Erfolge.zieltage(runden, ziel: 1) == 2)
        #expect(Erfolge.zieltage(runden, ziel: 3) == 0)
    }

    // MARK: Abzeichen

    @Test func dasErsteAbzeichenGibtEsNachDerErstenRunde() {
        #expect(!erreicht("erste", []))
        #expect(erreicht("erste", [testRunde(vorTagen: 0)]))
    }

    @Test func abzeichenFuerEineFehlerfreieRunde() {
        let mitFehler = [testRunde(vorTagen: 0, richtig: 8, gesamt: 10)]
        #expect(!erreicht("fehlerfrei", mitFehler))

        let mitSpicken = [testRunde(vorTagen: 0, richtig: 10, gesamt: 10, angesehen: 2)]
        #expect(!erreicht("fehlerfrei", mitSpicken), "Mit angeschauter Lösung zählt es nicht")

        let sauber = [testRunde(vorTagen: 0, richtig: 10, gesamt: 10, angesehen: 0)]
        #expect(erreicht("fehlerfrei", sauber))
    }

    @Test func abzeichenFuerSiebenTageInFolge() {
        var runden: [RundenErgebnis] = []
        for tag in 0..<6 { runden.append(testRunde(vorTagen: tag)) }
        #expect(!erreicht("s7", runden))
        runden.append(testRunde(vorTagen: 6))
        #expect(erreicht("s7", runden))
    }

    @Test func meisterAbzeichenNurBeiVollerPunktzahl() {
        let halb = [testRunde(vorTagen: 0, richtig: 6, gesamt: 12, uebung: "Einmaleins")]
        #expect(!Erfolge.meister(halb, "Einmaleins"))

        let voll = [testRunde(vorTagen: 0, richtig: 12, gesamt: 12, uebung: "Einmaleins")]
        #expect(Erfolge.meister(voll, "Einmaleins"))
        #expect(erreicht("m_einmaleins", voll))
        #expect(!erreicht("m_kern", voll), "Ein anderes Abzeichen darf dadurch nicht aufgehen")
    }

    @Test func deutschAbzeichenNurFuerDeutsch() {
        let mathe = [testRunde(vorTagen: 0, richtig: 10, gesamt: 10, fach: "Mathe")]
        #expect(!erreicht("m_deutsch", mathe))

        let deutsch = [testRunde(vorTagen: 0, richtig: 10, gesamt: 10, fach: "Deutsch")]
        #expect(erreicht("m_deutsch", deutsch))
    }

    @Test func jedesAbzeichenHatEineEigeneKennung() {
        let liste = Erfolge.pokale([], ziel: 2)
        let kennungen = Set(liste.map { $0.id })
        #expect(kennungen.count == liste.count, "Zwei Abzeichen teilen sich eine Kennung")
        for pokal in liste {
            #expect(!pokal.titel.isEmpty)
            #expect(!pokal.emoji.isEmpty)
        }
    }

    @Test func ohneRundenIstKeinAbzeichenOffen() {
        for pokal in Erfolge.pokale([], ziel: 2) {
            #expect(!pokal.erreicht, "\(pokal.titel) gilt ohne eine einzige Runde als geschafft")
        }
    }
}
