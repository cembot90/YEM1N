import Foundation
import Testing
@testable import YEM1N

// Das Haustier ist der Grund, die App gern zu öffnen. Es darf nie ungerecht
// sein: kein Tod, kein Verlust, und Spicken bringt keinen Vorteil.

@MainActor
struct HaustierTests {

    private var kal: Calendar {
        var k = Calendar(identifier: .gregorian)
        k.timeZone = TimeZone(identifier: "UTC") ?? TimeZone.current
        return k
    }

    private var start: Date {
        kal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 12)) ?? Date.now
    }

    private func stunden(_ n: Double, nach d: Date? = nil) -> Date {
        (d ?? start).addingTimeInterval(n * 3600)
    }

    private func baby(satt: Double = 80, laune: Double = 80) -> Haustier {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        h.xp = 5
        h.satt = satt
        h.laune = laune
        return h
    }

    private func leererSpeicher(_ name: String) -> UserDefaults {
        let speicher = UserDefaults(suiteName: name) ?? UserDefaults.standard
        speicher.removePersistentDomain(forName: name)
        return speicher
    }

    // MARK: Stufen

    @Test func stufenWachsenMitDenPunkten() {
        #expect(HaustierStufe.fuer(xp: 0) == .ei)
        #expect(HaustierStufe.fuer(xp: 1) == .baby)
        #expect(HaustierStufe.fuer(xp: 59) == .baby)
        #expect(HaustierStufe.fuer(xp: 60) == .kind)
        #expect(HaustierStufe.fuer(xp: 249) == .kind)
        #expect(HaustierStufe.fuer(xp: 250) == .gross)
        #expect(HaustierStufe.fuer(xp: 699) == .gross)
        #expect(HaustierStufe.fuer(xp: 700) == .meister)
        #expect(HaustierStufe.fuer(xp: 99_999) == .meister)
    }

    @Test func fortschrittLiegtZwischenNullUndEins() {
        var h = baby()
        h.xp = 1
        #expect(h.fortschritt == 0)
        h.xp = 30
        #expect(h.fortschritt > 0 && h.fortschritt < 1)
        h.xp = 5000
        #expect(h.fortschritt == 1)
    }

    // MARK: Zeit vergeht

    @Test func dasEiHatKeinenHunger() {
        var h = Haustier(name: "Pip", art: "hund", jetzt: start)
        h.aktualisiere(jetzt: stunden(48))
        #expect(h.satt == 80)
        #expect(h.laune == 80)
        #expect(h.zuletzt == stunden(48))
    }

    @Test func hungerUndLauneSinkenLangsam() {
        var h = baby()
        h.aktualisiere(jetzt: stunden(10))
        #expect(abs(h.satt - 55) < 0.001)
        #expect(abs(h.laune - 68) < 0.001)
        #expect(h.stimmung == .zufrieden, "Satt 55 ist nicht mehr ganz froh, aber noch lange nicht hungrig")
    }

    @Test func nachEinemTagOhneUebenIstDasTierNochNichtHungrig() {
        var h = baby()
        h.aktualisiere(jetzt: stunden(18))
        #expect(h.stimmung != .hungrig, "Ein Tag Pause darf nicht bestrafen")
    }

    @Test func nachLangerPauseIstDasTierHungrig() {
        var h = baby()
        h.aktualisiere(jetzt: stunden(30))
        #expect(abs(h.satt - 5) < 0.001)
        #expect(h.stimmung == .hungrig)
    }

    @Test func werteFallenNieUnterNull() {
        var h = baby()
        h.aktualisiere(jetzt: stunden(5000))
        #expect(h.satt == 0)
        #expect(h.laune == 0)
        #expect(h.xp == 5, "Wachstum geht nie verloren")
        #expect(h.stufe == .baby)
    }

    @Test func eineZurueckgestellteUhrVerdirbtNichts() {
        var h = baby()
        h.aktualisiere(jetzt: stunden(-5))
        #expect(h.satt == 80)
        #expect(h.zuletzt == stunden(-5))
    }

    // MARK: Üben macht satt

    @Test func dieErsteRundeLaesstDasEiSchluepfen() {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        let e = h.lernrunde(richtig: 8, gesamt: 10, angesehen: 0, jetzt: start)
        #expect(e.geschluepft)
        #expect(!e.aufgestiegen)
        #expect(h.stufe == .baby)
        #expect(h.xp == 8 + 2 * 2, "8 von 10 sind zwei Sterne")
        #expect(h.satt == 100)
        #expect(abs(h.laune - 90) < 0.001)
    }

    @Test func selbstEineRundeOhneRichtigeAufgabeBringtEinenPunkt() {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        h.lernrunde(richtig: 0, gesamt: 10, angesehen: 3, jetzt: start)
        #expect(h.xp == 1)
        #expect(h.stufe == .baby)
    }

    @Test func spickenKostetDenSternbonus() {
        var ehrlich = baby()
        var spicker = baby()
        ehrlich.lernrunde(richtig: 10, gesamt: 10, angesehen: 0, jetzt: start)
        spicker.lernrunde(richtig: 10, gesamt: 10, angesehen: 2, jetzt: start)
        #expect(ehrlich.xp == 5 + 10 + 6)
        #expect(spicker.xp == 5 + 10)
        #expect(spicker.xp < ehrlich.xp)
    }

    @Test func eineGuteRundeLaesstDasTierAufsteigen() {
        var h = baby()
        h.xp = 55
        let e = h.lernrunde(richtig: 10, gesamt: 10, angesehen: 0, jetzt: start)
        #expect(e.aufgestiegen)
        #expect(!e.geschluepft)
        #expect(e.stufe == .kind)
        #expect(e.text(fuer: h).contains("Kind"))
    }

    @Test func dieRundeRechnetErstDieZeitUndFuettertDann() {
        var h = baby(satt: 80, laune: 80)
        h.lernrunde(richtig: 5, gesamt: 10, angesehen: 0, jetzt: stunden(40))
        // Nach 40 Stunden war das Tier bei 0, die Runde gibt 30
        #expect(abs(h.satt - 30) < 0.001)
    }

    // MARK: Mit Münzen versorgen

    @Test func leckerliKostetMuenzenUndSaettigt() {
        var h = baby(satt: 40)
        var bezahlt = 0
        let ok = h.leckerli { preis in
            bezahlt += preis
            return true
        }
        #expect(ok)
        #expect(bezahlt == Haustier.leckerliPreis)
        #expect(abs(h.satt - 65) < 0.001)
    }

    @Test func einSattesTierBekommtKeinLeckerliUndNichtsWirdBezahlt() {
        var h = baby(satt: 96)
        var bezahlt = 0
        let ok = h.leckerli { preis in
            bezahlt += preis
            return true
        }
        #expect(!ok)
        #expect(bezahlt == 0)
    }

    @Test func ohneGenugMuenzenGibtEsNichts() {
        var h = baby(satt: 40, laune: 40)
        let ergebnis1 = h.leckerli { _ in false }
        #expect(!ergebnis1)
        let ergebnis2 = h.spielen { _ in false }
        #expect(!ergebnis2)
        #expect(h.satt == 40)
        #expect(h.laune == 40)
    }

    @Test func dasEiBrauchtWederLeckerliNochSpielzeug() {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        let ergebnis3 = h.leckerli { _ in true }
        #expect(!ergebnis3)
        let ergebnis4 = h.spielen { _ in true }
        #expect(!ergebnis4)
    }

    @Test func spielenHebtDieLaune() {
        var h = baby(laune: 20)
        let ergebnis5 = h.spielen { _ in true }
        #expect(ergebnis5)
        #expect(abs(h.laune - 50) < 0.001)
    }

    // MARK: Hüte

    @Test func einHutWirdGekauftUndAufgesetzt() {
        var h = baby()
        var bezahlt = 0
        let ergebnis6 = h.kaufe(hut: "krone") { bezahlt += $0; return true }
        #expect(ergebnis6)
        #expect(bezahlt == 80)
        #expect(h.hut == "krone")
        #expect(h.huete == ["krone"])
        let ergebnis7 = h.kaufe(hut: "krone") { _ in true }
        #expect(!ergebnis7, "Doppelt kaufen ist unnötig")
    }

    @Test func ohneMuenzenKeinHutUndUnbekannteHuetenGibtEsNicht() {
        var h = baby()
        let ergebnis8 = h.kaufe(hut: "brille") { _ in false }
        #expect(!ergebnis8)
        let ergebnis9 = h.kaufe(hut: "gibtEsNicht") { _ in true }
        #expect(!ergebnis9)
        #expect(h.huete.isEmpty)
        #expect(h.hut == "")
    }

    @Test func nurGekaufteHuetenKoennenGetragenWerden() {
        var h = baby()
        h.trage(hut: "krone")
        #expect(h.hut == "")
        h.kaufe(hut: "brille") { _ in true }
        h.trage(hut: "")
        #expect(h.hut == "")
        h.trage(hut: "brille")
        #expect(h.hut == "brille")
    }

    @Test func dasEiKannKeinenHutKaufen() {
        var h = Haustier(name: "Pip", art: "katze", jetzt: start)
        let ergebnis10 = h.kaufe(hut: "brille") { _ in true }
        #expect(!ergebnis10)
    }

    // MARK: Tagesgeschenk

    @Test func dasGeschenkGibtEsEinmalProTag() {
        var h = baby()
        #expect(h.geschenkOffen(jetzt: start, kalender: kal))
        let ergebnis11 = h.holeGeschenk(jetzt: start, kalender: kal)
        #expect(ergebnis11 == Haustier.geschenkMuenzen)
        #expect(!h.geschenkOffen(jetzt: start, kalender: kal))
        let ergebnis12 = h.holeGeschenk(jetzt: start, kalender: kal)
        #expect(ergebnis12 == 0)
        let morgen = stunden(24)
        let ergebnis13 = h.holeGeschenk(jetzt: morgen, kalender: kal)
        #expect(ergebnis13 == Haustier.geschenkMuenzen)
    }

    // MARK: Speichern

    @Test func dasTierUeberlebtDasSpeichern() {
        var h = baby()
        h.kaufe(hut: "kappe") { _ in true }
        h.xp = 123
        let zurueck = HaustierSpeicher.dekodiere(HaustierSpeicher.kodiere(h))
        #expect(zurueck == h)
    }

    @Test func fehlendeFelderMachenDasTierNichtKaputt() {
        let json = Data(#"{"name":"Mia","art":"hund"}"#.utf8)
        let h = HaustierSpeicher.dekodiere(json)
        #expect(h?.name == "Mia")
        #expect(h?.art == "hund")
        #expect(h?.xp == 0)
        #expect(h?.satt == 80)
    }

    @Test func leereDatenGebenKeinTier() {
        #expect(HaustierSpeicher.dekodiere(Data()) == nil)
        #expect(HaustierSpeicher.dekodiere(Data("kaputt".utf8)) == nil)
    }

    @Test func ladenSichernEntfernen() {
        let speicher = leererSpeicher("haustier-test-speicher")
        #expect(HaustierSpeicher.laden(speicher: speicher) == nil)
        HaustierSpeicher.sichern(baby(), speicher: speicher)
        #expect(HaustierSpeicher.laden(speicher: speicher)?.name == "Pip")
        HaustierSpeicher.entfernen(speicher: speicher)
        #expect(HaustierSpeicher.laden(speicher: speicher) == nil)
    }

    @Test func namenWerdenSauber() {
        #expect(Haustier(name: "", art: "katze").name == "Pip")
        #expect(Haustier(name: "   ", art: "katze").name == "Pip")
        #expect(Haustier(name: "  Luna  ", art: "katze").name == "Luna")
        #expect(Haustier(name: "EinSehrSehrLangerHaustierName", art: "katze").name.count == Haustier.namenslaenge)
    }

    @Test func jedeArtHatEinEigenesBild() {
        let emojis = HaustierArt.alle.map { $0.emoji }
        #expect(Set(emojis).count == emojis.count)
        #expect(HaustierArt.finde("gibtEsNicht").id == HaustierArt.alle[0].id)
        let ids = HaustierHut.alle.map { $0.id }
        #expect(Set(ids).count == ids.count)
    }

    // MARK: Anbindung an die Runden

    @Test func ohneHaustierPassiertNichts() {
        let speicher = leererSpeicher("haustier-test-dienst-leer")
        let text = HaustierDienst.rundeGeschafft(richtig: 10, gesamt: 10, angesehen: 0,
                                                 speicher: speicher, jetzt: start, erinnern: false)
        #expect(text == nil)
        #expect(HaustierSpeicher.laden(speicher: speicher) == nil)
    }

    @Test func eineRundeFuettertDasGespeicherteTier() {
        let speicher = leererSpeicher("haustier-test-dienst")
        HaustierSpeicher.sichern(Haustier(name: "Luna", art: "katze", jetzt: start), speicher: speicher)
        let text = HaustierDienst.rundeGeschafft(richtig: 10, gesamt: 10, angesehen: 0,
                                                 speicher: speicher, jetzt: start, erinnern: false)
        #expect(text?.contains("Luna") == true)
        #expect(HaustierSpeicher.laden(speicher: speicher)?.stufe == .baby)
    }

    @Test func dasTabSymbolMeldetSichNurWennNoetig() {
        #expect(HaustierDienst.braucheAufmerksamkeit(Data(), jetzt: start), "Noch kein Tier: Einladung zum Aussuchen")
        let frischesEi = HaustierSpeicher.kodiere(Haustier(name: "Pip", art: "katze", jetzt: start))
        #expect(!HaustierDienst.braucheAufmerksamkeit(frischesEi, jetzt: stunden(100)))
        #expect(!HaustierDienst.braucheAufmerksamkeit(HaustierSpeicher.kodiere(baby()), jetzt: start))
        #expect(HaustierDienst.braucheAufmerksamkeit(HaustierSpeicher.kodiere(baby(satt: 10)), jetzt: start))
    }

    // MARK: Erinnerung

    @Test func dieErinnerungKommtAmSpaetenNachmittag() {
        // Satt 80: Hunger in 20 Stunden, also morgen früh. Erinnert wird morgen um 17 Uhr.
        let z = HaustierErinnerung.zeitpunkt(fuer: baby(), jetzt: start, kalender: kal)
        #expect(kal.component(.day, from: z) == 8)
        #expect(kal.component(.hour, from: z) == HaustierErinnerung.uhrzeit)
    }

    @Test func einHungrigesTierErinnertNochHeute() {
        let z = HaustierErinnerung.zeitpunkt(fuer: baby(satt: 10), jetzt: start, kalender: kal)
        #expect(kal.component(.day, from: z) == 7)
        #expect(kal.component(.hour, from: z) == HaustierErinnerung.uhrzeit)
    }

    @Test func dasEiErinnertErstNachEinemTag() {
        let ei = Haustier(name: "Pip", art: "katze", jetzt: start)
        let z = HaustierErinnerung.zeitpunkt(fuer: ei, jetzt: start, kalender: kal)
        #expect(z > stunden(20))
        #expect(kal.component(.hour, from: z) == HaustierErinnerung.uhrzeit)
    }

    @Test func dieErinnerungLiegtImmerInDerZukunft() {
        for satt in stride(from: 0.0, through: 100.0, by: 10.0) {
            let z = HaustierErinnerung.zeitpunkt(fuer: baby(satt: satt), jetzt: start, kalender: kal)
            #expect(z > start)
        }
    }
}
