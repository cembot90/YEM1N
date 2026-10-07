import Foundation
import CoreGraphics
import Testing
@testable import YEM1N

// Die Schwierigkeitskurve des Zahlenlaufs. Ein Spiel, das unfair wird,
// macht keinen Spaß mehr und das Kind hört auf zu üben.

@MainActor
struct LaufBalanceTests {

    private var stufen: [Int] { Array(1...LaufBalance.hoechsteStufe) }

    @Test func dieStufeSteigtMitDenPunkten() {
        #expect(LaufBalance.stufe(punkte: 0) == 1)
        #expect(LaufBalance.stufe(punkte: LaufBalance.punkteProStufe - 1) == 1)
        #expect(LaufBalance.stufe(punkte: LaufBalance.punkteProStufe) == 2)
        var vorher = 0
        for punkte in stride(from: 0, through: 5000, by: 25) {
            let jetzt = LaufBalance.stufe(punkte: punkte)
            #expect(jetzt >= vorher, "Die Stufe ist bei \(punkte) Punkten gesunken")
            vorher = jetzt
        }
    }

    @Test func dieStufeHatEinEnde() {
        #expect(LaufBalance.stufe(punkte: 1_000_000) == LaufBalance.hoechsteStufe)
        #expect(LaufBalance.stufe(punkte: -50) == 1, "Auch bei Unsinn bleibt es bei Stufe 1")
    }

    @Test func esWirdSchnellerAberNichtEndlos() {
        var vorher: CGFloat = 0
        for stufe in stufen {
            let jetzt = LaufBalance.tempo(stufe: stufe)
            #expect(jetzt > vorher, "Stufe \(stufe) ist nicht schneller als die davor")
            vorher = jetzt
        }
        #expect(LaufBalance.tempo(stufe: LaufBalance.hoechsteStufe) <= 800,
                "Schneller als das kann ein Kind nicht mehr reagieren")
        // Außerhalb der Stufen bleibt es bei den Randwerten
        #expect(LaufBalance.tempo(stufe: 0) == LaufBalance.tempo(stufe: 1))
        #expect(LaufBalance.tempo(stufe: 99) == LaufBalance.tempo(stufe: LaufBalance.hoechsteStufe))
    }

    @Test func dieAbstaendeWerdenEngerBleibenAberSinnvoll() {
        var vorher = LaufBalance.abstand(stufe: 1)
        for stufe in stufen.dropFirst() {
            let jetzt = LaufBalance.abstand(stufe: stufe)
            #expect(jetzt.lowerBound <= vorher.lowerBound)
            #expect(jetzt.upperBound <= vorher.upperBound)
            vorher = jetzt
        }
        for stufe in stufen {
            let bereich = LaufBalance.abstand(stufe: stufe)
            #expect(bereich.lowerBound > 0)
            #expect(bereich.lowerBound < bereich.upperBound,
                    "Stufe \(stufe) hat einen leeren Bereich")
        }
    }

    @Test func esBleibtImmerGenugZeitZumReagieren() {
        for stufe in stufen {
            let zeit = LaufBalance.zeitZwischenHindernissen(stufe: stufe)
            #expect(zeit >= LaufBalance.kuerzesteReaktion,
                    "Auf Stufe \(stufe) bleiben nur \(zeit) Sekunden")
        }
    }

    @Test func dieErstenStufenSindRuhig() {
        // Stufe 1 soll zum Hineinfinden einladen
        #expect(LaufBalance.zeitZwischenHindernissen(stufe: 1) > 1.0)
        // Und am Anfang fliegt noch nichts herum
        #expect(LaufBalance.fliegerAnteil(stufe: 1) == 0)
        #expect(LaufBalance.fliegerAbStufe >= 2)
    }

    @Test func fliegerKommenDazuUebernehmenAberNicht() {
        var vorher: Double = -1
        for stufe in stufen {
            let anteil = LaufBalance.fliegerAnteil(stufe: stufe)
            #expect(anteil >= 0 && anteil <= 0.5,
                    "Stufe \(stufe) hätte \(anteil) Flieger, das ist zu viel")
            #expect(anteil >= vorher)
            vorher = anteil
        }
        #expect(LaufBalance.fliegerAnteil(stufe: LaufBalance.fliegerAbStufe) > 0)
    }
}
