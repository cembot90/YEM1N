import Foundation
import Testing
@testable import YEM1N

// Die Eule Olli erklärt das Haustier und gibt Tipps. Sie muss immer etwas
// Passendes sagen: zuerst das, was gerade wichtig ist, und nie etwas Falsches.

@MainActor
struct EuleTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return k
    }

    /// Mittag, das Tier ist wach
    private var mittag: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 12)) ?? Date.now
    }

    /// Abends, das Tier schläft
    private var abend: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 18, hour: 21)) ?? Date.now
    }

    /// Ein zufriedenes Tier ohne Besonderheiten: Geschenk abgeholt, weit weg von der nächsten Stufe.
    private func ruhigesTier(xp: Int = 100, satt: Double = 80, laune: Double = 80) -> Haustier {
        var h = Haustier(name: "Pip", art: "katze", jetzt: mittag)
        h.xp = xp
        h.satt = satt
        h.laune = laune
        h.geschenkTag = Haustier.tagKennung(mittag, kalender: kal)
        return h
    }

    private func ei() -> Haustier {
        var h = Haustier(name: "Pip", art: "katze", jetzt: mittag)
        h.geschenkTag = Haustier.tagKennung(mittag, kalender: kal)
        return h
    }

    private func tipps(_ h: Haustier, muenzen: Int = 0, jetzt: Date? = nil) -> [String] {
        Eule.tipps(fuer: h, muenzen: muenzen, familie: true, jetzt: jetzt ?? mittag, kalender: kal)
    }

    private func wichtig(_ h: Haustier, muenzen: Int = 0, jetzt: Date? = nil) -> String? {
        Eule.wichtigerTipp(fuer: h, muenzen: muenzen, jetzt: jetzt ?? mittag, kalender: kal)
    }

    // MARK: Einführung

    @Test func dieEinfuehrungErklaertDenWegZumMeister() {
        let schritte = Eule.einfuehrung(fuer: ei())
        #expect(schritte.count == 7)
        #expect(schritte[0].contains("Olli"))
        #expect(schritte[0].contains("Pip"))
        #expect(schritte.contains { $0.contains("schlüpft") })
        #expect(schritte.contains { $0.contains("Meister") })
        #expect(schritte.contains { $0.contains("läuft nie weg") })
        #expect(schritte.contains { $0.contains("Lösung") })
    }

    @Test func einGeschluepftesTierBekommtEinePassendeBegruessung() {
        let schritte = Eule.einfuehrung(fuer: ruhigesTier())
        #expect(schritte.count == 7)
        #expect(!schritte[0].contains("Ei"), "Das Tier ist schon geschlüpft")
    }

    @Test func dieElternLernenWasSieBeitragenKoennen() {
        let schritte = Eule.elternEinfuehrung
        #expect(schritte.count >= 4)
        #expect(schritte.contains { $0.contains("Leckerli") && $0.contains("Spiel") })
        #expect(schritte.contains { $0.contains("üben") || $0.contains("übt") })
    }

    // MARK: Tipps zur Lage

    @Test func beimEiGehtEsUmsSchluepfen() {
        let t = tipps(ei(), muenzen: 200)
        #expect(t.first?.contains("schlüpft") == true)
        #expect(!t.contains { $0.contains("Look") }, "Ein Ei kann noch keinen Hut tragen")
    }

    @Test func hungerKommtVorAllemAnderen() {
        let h = ruhigesTier(satt: 10)
        #expect(wichtig(h)?.contains("Hunger") == true)
    }

    @Test func einTraurigesTierBrauchtSpielOderUeben() {
        let h = ruhigesTier(satt: 80, laune: 10)
        #expect(wichtig(h)?.contains("traurig") == true)
    }

    @Test func abendsErklaertOlliDassDasTierSchlaeft() {
        let h = ruhigesTier()
        #expect(wichtig(h, jetzt: abend)?.contains("schläft") == true)
        #expect(wichtig(h, jetzt: mittag)?.contains("schläft") != true)
    }

    @Test func einOffenesGeschenkWirdErwaehnt() {
        var h = ruhigesTier()
        h.geschenkTag = ""
        #expect(wichtig(h)?.contains("Tagesgeschenk") == true)
    }

    @Test func kurzVorDerNaechstenStufeFeuertOlliAn() {
        let h = ruhigesTier(xp: 55)
        #expect(wichtig(h) == "Nur noch 5 Punkte bis zur Stufe Kind! Das schaffst du bald.")
        #expect(wichtig(ruhigesTier(xp: 30)) == nil, "Weit weg von der nächsten Stufe ist das noch kein Thema")
    }

    @Test func einHutWirdNurVorgeschlagenWennDieMuenzenReichen() {
        let h = ruhigesTier()
        #expect(wichtig(h, muenzen: 29) == nil)
        let tipp = wichtig(h, muenzen: 30)
        #expect(tipp?.contains("30 Münzen") == true)
        var mitBrille = h
        mitBrille.huete = ["brille", "schleife", "kappe"]
        #expect(wichtig(mitBrille, muenzen: 44) == nil, "Alle Hüte für 30 sind schon gekauft")
        #expect(wichtig(mitBrille, muenzen: 45)?.contains("45 Münzen") == true)
    }

    @Test func ohneBesonderheitenMeldetSichOlliNichtVonSelbst() {
        #expect(wichtig(ruhigesTier()) == nil)
        #expect(!tipps(ruhigesTier()).isEmpty, "Beim Antippen hat sie trotzdem immer etwas zu sagen")
    }

    @Test func derWichtigsteTippStehtAuchVorneInDerListe() {
        var h = ruhigesTier(satt: 10)
        h.geschenkTag = ""
        let liste = tipps(h, muenzen: 50)
        #expect(liste.first == wichtig(h, muenzen: 50))
        #expect(Set(liste).count == liste.count, "Kein Tipp doppelt")
    }

    @Test func einMeisterBekommtLob() {
        let h = ruhigesTier(xp: 800)
        #expect(tipps(h).contains { $0.contains("Meister") })
    }

    @Test func ohneFamiliencodeKeinTippZuDenEltern() {
        let mit = Eule.tipps(fuer: ruhigesTier(), muenzen: 0, familie: true, jetzt: mittag, kalender: kal)
        let ohne = Eule.tipps(fuer: ruhigesTier(), muenzen: 0, familie: false, jetzt: mittag, kalender: kal)
        #expect(mit.contains { $0.contains("Eltern") })
        #expect(!ohne.contains { $0.contains("Eltern") })
    }

    // MARK: Tipps für die Eltern

    @Test func elternWerdenAnFreieGeschenkeErinnert() {
        let h = ruhigesTier()
        let beide = Eule.elternLageTipps(fuer: h, leckerliFrei: true, spielFrei: true, jetzt: mittag, kalender: kal)
        #expect(beide.contains("Heute hast du noch ein Leckerli und ein Spiel frei."))
        let nichts = Eule.elternLageTipps(fuer: h, leckerliFrei: false, spielFrei: false, jetzt: mittag, kalender: kal)
        #expect(nichts.isEmpty)
        let eiTipps = Eule.elternLageTipps(fuer: ei(), leckerliFrei: true, spielFrei: true, jetzt: mittag, kalender: kal)
        #expect(eiTipps.count == 1, "Ein Ei kann man noch nicht füttern")
        #expect(eiTipps.first?.contains("schlüpft") == true)
    }

    @Test func elternTippsGibtEsAuchOhneTier() {
        let t = Eule.elternTipps(fuer: nil, leckerliFrei: true, spielFrei: true, jetzt: mittag, kalender: kal)
        #expect(!t.isEmpty)
    }

    // MARK: Die Stimme des Tiers

    @Test func dasTierSprichtPassendZurLaune() {
        let hungrig = ruhigesTier(satt: 10)
        let saetze = (0..<3).map { TierStimme.antippen(hungrig, schlaeft: false, nummer: $0) }
        #expect(saetze.contains { $0.contains("Bauch") || $0.contains("essen") || $0.contains("satt") })
        #expect(TierStimme.antippen(ruhigesTier(), schlaeft: true, nummer: 0).contains("Zzz"))
        #expect(TierStimme.antippen(ei(), schlaeft: false, nummer: 0).contains("Klopf"))
        #expect(TierStimme.antippen(ruhigesTier(), schlaeft: false, nummer: -5).isEmpty == false)
    }

    @Test func einSchlafendesTierSagtWannEsAufwacht() {
        #expect(TierStimme.vonSelbst(ruhigesTier(), schlaeft: true).contains("7 Uhr"))
        #expect(TierStimme.vonSelbst(ruhigesTier(), schlaeft: false) == ruhigesTier().spruch)
    }

    // MARK: Vorlesen und Schreibweise

    @Test func beimVorlesenFallenEmojisWeg() {
        #expect(Eule.sprechbar("Du hast genug Münzen für einen neuen Look: 🕶️ Sonnenbrille für 30 Münzen.")
                == "Du hast genug Münzen für einen neuen Look: Sonnenbrille für 30 Münzen.")
        #expect(Eule.sprechbar("Ab 20 Uhr schläft Pip. ❤️") == "Ab 20 Uhr schläft Pip.")
        #expect(Eule.sprechbar("Größer, Übung, 7 · 8") == "Größer, Übung, 7 · 8")
    }

    @Test func keineGedankenstricheInOllisTexten() {
        var alle = Eule.einfuehrung(fuer: ei()) + Eule.einfuehrung(fuer: ruhigesTier()) + Eule.elternEinfuehrung
        var h = ruhigesTier(xp: 55, satt: 10, laune: 10)
        h.geschenkTag = ""
        alle += tipps(h, muenzen: 100, jetzt: abend) + tipps(ei(), muenzen: 100)
        alle += Eule.elternTipps(fuer: h, leckerliFrei: true, spielFrei: false, jetzt: abend, kalender: kal)
        for stimmung in [ruhigesTier(), ruhigesTier(satt: 10), ruhigesTier(laune: 10), ruhigesTier(satt: 50, laune: 50)] {
            alle += (0..<4).map { TierStimme.antippen(stimmung, schlaeft: false, nummer: $0) }
        }
        for satz in alle {
            #expect(!satz.contains("\u{2013}") && !satz.contains("\u{2014}"), "\(satz)")
            #expect(!satz.isEmpty)
        }
    }
}
