import Foundation
import CoreGraphics
import Testing
@testable import YEM1N

// Elfmeterschießen und Einhorn-Flug: Die Regeln müssen fair sein.
// Ein Kind soll treffen können, und das Einhorn darf nicht gemein sein.

@MainActor
struct ElfmeterRegelnTests {
    typealias R = ElfmeterRegeln

    @Test func geradeNachObenWischenZieltInsTor() {
        let ziel = R.ziel(wisch: CGVector(dx: 0, dy: 300))
        #expect(R.istImTor(ziel))
        #expect(abs(ziel.x - R.torMitte) < 1)
    }

    @Test func zuWeitZurSeiteIstDaneben() {
        let ziel = R.ziel(wisch: CGVector(dx: 260, dy: 300))
        #expect(!R.istImTor(ziel))
        let (e, _) = R.ergebnis(ziel: ziel, torwartX: R.torMitte, flugzeit: 0.6, level: 1, zufall: 0.9)
        #expect(e == .daneben)
    }

    @Test func mittigeSchuesseHaeltDerTorwart() {
        let ziel = CGPoint(x: R.torMitte + 20, y: R.torUnten + 60)
        let (e, _) = R.ergebnis(ziel: ziel, torwartX: R.torMitte, flugzeit: 0.6, level: 1, zufall: 0.9)
        #expect(e == .gehalten)
    }

    @Test func obenInDenWinkelKlapptAmAnfang() {
        let ziel = CGPoint(x: R.torRechts - 40, y: R.torOben - 30)
        #expect(R.istWinkel(ziel))
        let (e, _) = R.ergebnis(ziel: ziel, torwartX: R.torMitte, flugzeit: 0.5, level: 1, zufall: 0.9)
        #expect(e == .tor(winkel: true))
    }

    @Test func verschaetzterTorwartSpringtInDieFalscheEcke() {
        let ziel = CGPoint(x: R.torLinks + 80, y: R.torUnten + 40)
        let (e, torwartZiel) = R.ergebnis(ziel: ziel, torwartX: R.torMitte, flugzeit: 0.8, level: 1, zufall: 0.0)
        #expect(torwartZiel > R.torMitte)
        #expect(e == .tor(winkel: false))
    }

    @Test func derTorwartWirdMitJedemLevelBesser() {
        #expect(R.tempo(level: 5) > R.tempo(level: 1))
        #expect(R.reaktion(level: 5) < R.reaktion(level: 1))
        #expect(R.falscheEckeChance(level: 5) < R.falscheEckeChance(level: 1))
        #expect(R.sprungHoehe(level: 30) < R.torOben)
    }

    @Test func punkteUndLevel() {
        #expect(R.punkte(winkel: false, serie: 1) == 1)
        #expect(R.punkte(winkel: true, serie: 1) == 3)
        #expect(R.punkte(winkel: true, serie: 3) == 4)
        #expect(R.level(tore: 0) == 1)
        #expect(R.level(tore: 4) == 1)
        #expect(R.level(tore: 5) == 2)
    }

    @Test func schnellesWischenGibtSchnellenSchuss() {
        #expect(R.flugzeit(wischTempo: 3000) < R.flugzeit(wischTempo: 300))
        #expect(R.flugzeit(wischTempo: 99999) >= 0.42)
        #expect(R.flugzeit(wischTempo: 0) <= 0.85)
    }
}

@MainActor
struct EinhornRegelnTests {
    typealias R = EinhornRegeln

    @Test func sterneUndRegenboegenBringenPunkte() {
        let erst = R.fange(.stern, punkte: 0, leben: 3)
        #expect(erst.punkte == 1 && erst.leben == 3)
        let dann = R.fange(.regenbogen, punkte: 5, leben: 3)
        #expect(dann.punkte == 8 && dann.leben == 3)
    }

    @Test func gewitterKostetEinLebenAberNieWenigerAlsNull() {
        let erst = R.fange(.gewitter, punkte: 4, leben: 2)
        #expect(erst.punkte == 4 && erst.leben == 1)
        let dann = R.fange(.gewitter, punkte: 4, leben: 0)
        #expect(dann.punkte == 4 && dann.leben == 0)
    }

    @Test func herzenFuellenHoechstensBisZumMaximum() {
        let erst = R.fange(.herz, punkte: 0, leben: 2)
        #expect(erst.punkte == 0 && erst.leben == 3)
        let dann = R.fange(.herz, punkte: 0, leben: 3)
        #expect(dann.punkte == 0 && dann.leben == 3)
    }

    @Test func herzenGibtEsNurWennEinLebenFehlt() {
        for i in 0..<100 {
            let z = Double(i) / 100
            #expect(R.naechstes(zufall: z, level: 1, leben: R.maxLeben) != .herz)
        }
    }

    @Test func amAnfangSindGewitterSelten() {
        #expect(R.gewitterAnteil(level: 1) <= 0.15)
        #expect(R.gewitterAnteil(level: 50) <= 0.32)
        #expect(R.naechstes(zufall: 0.5, level: 1, leben: 3) == .stern)
    }

    @Test func esWirdLangsamSchneller() {
        #expect(R.tempo(level: 3) > R.tempo(level: 1))
        #expect(R.tempo(level: 99) <= 460)
        #expect(R.abstand(level: 99) >= 0.7)
        #expect(R.level(punkte: 14) == 1)
        #expect(R.level(punkte: 15) == 2)
    }
}
