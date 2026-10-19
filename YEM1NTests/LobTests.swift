import Foundation
import Testing
@testable import YEM1N

// Lob und Mutmacher: genug Abwechslung, Namen richtig eingesetzt, Serien zur rechten Zeit.

@MainActor
struct LobTests {

    static var alleListen: [[LobText]] {
        [Lob.richtig, Lob.mitName, Lob.nachFehler, Lob.nochmal, Lob.endePerfekt, Lob.endeGut, Lob.endeGeuebt]
    }

    @Test func genugAbwechslung() {
        #expect(Lob.richtig.count >= 20)
        #expect(Lob.nochmal.count >= 8)
        #expect(Lob.daneben.count >= 6)
        for liste in Self.alleListen {
            #expect(Set(liste.map(\.de)).count == liste.count, "doppelte Sätze")
            #expect(liste.allSatisfy { !$0.de.isEmpty && !$0.tr.isEmpty && !$0.en.isEmpty })
            #expect(Set(liste.map(\.en)).count == liste.count, "doppelte Sätze auf Englisch")
        }
    }

    @Test func nieZweimalHintereinanderDasselbe() {
        Abwechslung.vergessen()
        var vorher = ""
        for _ in 0..<300 {
            let t = Lob.fuerRichtig(serie: 1, nachFehler: false, name: "", zufall: 0.9).de
            #expect(t != vorher, "\(t)")
            vorher = t
        }
    }

    @Test func innerhalbKurzerZeitKeineWiederholung() {
        Abwechslung.vergessen()
        // Die letzten sechs sind gesperrt, also sind sieben Züge immer verschieden
        let sieben = (0..<7).map { _ in Abwechslung.index("probe", anzahl: 20) }
        #expect(Set(sieben).count == 7)
    }

    @Test func nameWirdEingesetztOderSauberWeggelassen() {
        #expect(Lob.einsetzen("Super, {name}!", "Yemin") == "Super, Yemin!")
        #expect(Lob.einsetzen("Super, {name}!", "") == "Super!")
        #expect(Lob.einsetzen("{name}, du bist spitze!", "") == "Du bist spitze!")
        #expect(Lob.einsetzen("Aferin {name}!", "") == "Aferin!")
        #expect(Lob.vorname("Evîn Aras") == "Evîn")
        #expect(Lob.vorname("jonas") == "Jonas")
        #expect(Lob.vorname("JONAS") == "Jonas")
        #expect(Lob.vorname("LeAnn") == "LeAnn")
        #expect(Lob.vorname("") == "")
        for liste in Self.alleListen {
            for t in liste {
                let ohne = Lob.mitNamen(t, "")
                #expect(!ohne.de.contains("{") && !ohne.tr.contains("{") && !ohne.en.contains("{"), "\(t.de)")
                #expect(!ohne.en.contains(" !") && !ohne.en.contains(",!"), "\(ohne.en)")
                #expect(!ohne.de.contains(" !") && !ohne.de.contains(",!"), "\(ohne.de)")
            }
        }
    }

    @Test func mitNamenKommtDerName() {
        let t = Lob.fuerRichtig(serie: 1, nachFehler: false, name: "Yemin Aras", zufall: 0.1)
        #expect(t.de.contains("Yemin") && !t.de.contains("Aras"))
    }

    @Test func serienZurRechtenZeit() {
        #expect(Lob.serienLob(2) == nil)
        #expect(Lob.serienLob(3) != nil)
        #expect(Lob.serienLob(4) == nil)
        #expect(Lob.serienLob(5) != nil)
        #expect(Lob.serienLob(10) != nil)
        #expect(Lob.serienLob(20)?.de.contains("20") == true)
        #expect(Lob.fuerRichtig(serie: 3, nachFehler: false, name: "").de.contains("Drei"))
    }

    @Test func nachEinemFehlerGibtEsMutmacherLob() {
        let t = Lob.fuerRichtig(serie: 0, nachFehler: true, name: "")
        #expect(Lob.nachFehler.contains(t))
    }

    @Test func dasEndePasstZurRunde() {
        #expect(Lob.endePerfekt.map { Lob.mitNamen($0, "").de }
            .contains(Lob.fuerEnde(richtig: 10, gesamt: 10, name: "").de))
        #expect(Lob.endeGut.map { Lob.mitNamen($0, "").de }
            .contains(Lob.fuerEnde(richtig: 8, gesamt: 10, name: "").de))
        #expect(Lob.endeGeuebt.map { Lob.mitNamen($0, "").de }
            .contains(Lob.fuerEnde(richtig: 3, gesamt: 10, name: "").de))
        #expect(Lob.endeGeuebt.map { Lob.mitNamen($0, "").de }
            .contains(Lob.fuerEnde(richtig: 0, gesamt: 0, name: "").de))
    }

    @Test func jedeSpracheHatIhrenSatz() {
        let t = LobText(de: "Super!", tr: "Süper!", en: "Great!")
        #expect(t.text("de") == "Super!")
        #expect(t.text("tr") == "Süper!")
        #expect(t.text("en") == "Great!")
        #expect(t.text("it") == "Super!")
        #expect(Lob.mitNamen(LobText(de: "Toll, {name}!", tr: "Aferin {name}!", en: "Well done, {name}!"), "Mia").en
                == "Well done, Mia!")
        #expect(Lob.serienLob(25)?.en.contains("25") == true)
    }

    @Test func keineGedankenstriche() {
        let alle = Self.alleListen.flatMap { $0 }.flatMap { [$0.de, $0.tr, $0.en] } + Lob.daneben
        for t in alle {
            #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"), "\(t)")
        }
    }
}
