import Foundation
import Testing
@testable import YEM1N

// Sprachauswahl, Italienisch und der Vokabel-Editor.

@MainActor
struct SprachAuswahlTests {

    private let alle = ["en", "tr", "it"]

    @Test func ohneWahlSindAlleSprachenAn() {
        #expect(SprachAuswahl.aktiv(roh: "", alle: alle) == alle)
        #expect(SprachAuswahl.aktiv(roh: "  ", alle: alle) == alle)
    }

    @Test func keineSpracheIstMoeglich() {
        #expect(SprachAuswahl.aktiv(roh: SprachAuswahl.keine, alle: alle).isEmpty)
    }

    @Test func dieWahlBleibtInDerReihenfolgeDesKatalogs() {
        #expect(SprachAuswahl.aktiv(roh: "it,en", alle: alle) == ["en", "it"])
        #expect(SprachAuswahl.aktiv(roh: "xx,tr", alle: alle) == ["tr"], "Unbekannte Codes fallen weg")
    }

    @Test func umschaltenSchaltetEineSpracheAus() {
        let neu = SprachAuswahl.umgeschaltet("tr", roh: "", alle: alle)
        #expect(SprachAuswahl.aktiv(roh: neu, alle: alle) == ["en", "it"])
        #expect(!SprachAuswahl.istAn("tr", roh: neu, alle: alle))
        #expect(SprachAuswahl.istAn("it", roh: neu, alle: alle))
    }

    @Test func umschaltenSchaltetWiederAn() {
        var roh = SprachAuswahl.umgeschaltet("en", roh: "", alle: alle)
        roh = SprachAuswahl.umgeschaltet("en", roh: roh, alle: alle)
        #expect(SprachAuswahl.aktiv(roh: roh, alle: alle) == alle)
    }

    @Test func dieLetzteSpracheAbwaehlenErgibtKeine() {
        var roh = SprachAuswahl.kodiert(["it"], alle: alle)
        roh = SprachAuswahl.umgeschaltet("it", roh: roh, alle: alle)
        #expect(roh == SprachAuswahl.keine)
        #expect(SprachAuswahl.aktiv(roh: roh, alle: alle).isEmpty)
        // und wieder anschalten
        roh = SprachAuswahl.umgeschaltet("tr", roh: roh, alle: alle)
        #expect(SprachAuswahl.aktiv(roh: roh, alle: alle) == ["tr"])
    }
}

@MainActor
struct ItalienischTests {

    private func katalog() throws -> SprachKatalog {
        try JSONDecoder().decode(SprachKatalog.self, from: Data(SprachKatalogDaten.json.utf8))
    }

    private func woerter() throws -> [Wort] {
        try katalog().themen.flatMap { $0.woerter }
    }

    @Test func italienischIstEineLernsprache() throws {
        let k = try katalog()
        #expect(k.lernsprachen.contains("it"))
        #expect(k.sprachen["it"]?.sprachcode == "it-IT")
        #expect(k.sprachen["it"]?.name == "Italienisch")
    }

    @Test func jedesWortHatEinItalienisch() throws {
        let ws = try woerter()
        #expect(ws.count >= 299)
        for w in ws {
            let it = w.texte["it"] ?? ""
            #expect(!it.trimmingCharacters(in: .whitespaces).isEmpty, "\(w.texte["de"] ?? "?") ohne Italienisch")
        }
    }

    @Test func italienischeWoerterSindEindeutig() throws {
        var gesehen: [String: String] = [:]
        for w in try woerter() {
            let k = SprachHelfer.norm(w.texte["it"] ?? "", "it")
            let de = w.texte["de"] ?? ""
            if let anderes = gesehen[k] {
                Issue.record("\"\(k)\" gehört zu \(de) und zu \(anderes)")
            }
            gesehen[k] = de
        }
    }

    @Test func keineGedankenstricheImKatalog() {
        #expect(!SprachKatalogDaten.json.contains("\u{2014}"))
        #expect(!SprachKatalogDaten.json.contains("\u{2013}"))
    }

    @Test func derArtikelIstBeimTippenEgal() {
        let hund = Wort.test(it: "il cane")
        #expect(SprachHelfer.pruefeTipp(hund, "il cane", "it") == .richtig)
        #expect(SprachHelfer.pruefeTipp(hund, "cane", "it") == .richtig)
        #expect(SprachHelfer.pruefeTipp(hund, "Il Cane", "it") == .richtig)
        #expect(SprachHelfer.pruefeTipp(hund, "gatto", "it") == .falsch)
    }

    @Test func derApostrophBeiVokalenFunktioniert() {
        let freund = Wort.test(it: "l'amico")
        #expect(SprachHelfer.pruefeTipp(freund, "l'amico", "it") == .richtig)
        #expect(SprachHelfer.pruefeTipp(freund, "l\u{2019}amico", "it") == .richtig, "Der schräge Apostroph zählt auch")
        #expect(SprachHelfer.pruefeTipp(freund, "amico", "it") == .richtig)
    }

    @Test func fehlendeAkzenteSindFastRichtig() {
        let montag = Wort.test(it: "lunedì", alt: ["lunedi"])
        #expect(SprachHelfer.pruefeTipp(montag, "lunedì", "it") == .richtig)
        #expect(SprachHelfer.pruefeTipp(montag, "lunedi", "it") == .richtig, "Als weitere Schreibweise erlaubt")
        let tee = Wort.test(it: "il tè")
        #expect(SprachHelfer.pruefeTipp(tee, "il te", "it") == .fast)
        #expect(SprachHelfer.pruefeTipp(tee, "tè", "it") == .richtig)
    }

    @Test func dieArtikelregelBetrifftNurItalienisch() {
        #expect(SprachHelfer.norm("la casa", "tr") == "la casa")
        #expect(SprachHelfer.norm("the house", "en") == "house")
        #expect(SprachHelfer.norm("la casa", "it") == "casa")
    }

    @Test func sonderzeichenTastenProSprache() {
        #expect(SprachHelfer.sonderzeichen("it").contains("è"))
        #expect(SprachHelfer.sonderzeichen("tr").contains("ş"))
        #expect(SprachHelfer.sonderzeichen("en").isEmpty)
    }

    @Test func hinweiseGeltenNurFuerIhreSprache() throws {
        let tante = try woerter().first { $0.texte["de"] == "die Tante" }
        let t = try #require(tante)
        #expect(t.hinweis(fuer: "tr")?.contains("teyze") == true)
        #expect(t.hinweis(fuer: "en") == nil, "Der türkische Hinweis erscheint nicht bei Englisch")
        #expect(t.hinweis(fuer: "it") == nil, "und nicht bei Italienisch")
        let onkel = try #require(try woerter().first { $0.texte["de"] == "der Onkel" })
        #expect(onkel.hinweis(fuer: "it")?.contains("lo") == true)
        #expect(onkel.hinweis(fuer: "tr")?.contains("dayı") == true)
    }

    @Test func einAllgemeinerHinweisGiltFuerAlle() throws {
        let json = #"{"de": "x", "en": "y", "tr": "z", "hinweis": "Für alle"}"#
        let w = try JSONDecoder().decode(Wort.self, from: Data(json.utf8))
        #expect(w.hinweis(fuer: "en") == "Für alle")
        #expect(w.hinweis(fuer: "it") == "Für alle")
    }

    @Test func derEditorBehaeltItalienischUndHinweise() throws {
        let k = try katalog()
        let thema = try #require(k.themen.first { $0.id == "familie" })
        let editor = EditorThema.aus(thema)
        let onkel = try #require(editor.woerter.first { $0.de == "der Onkel" })
        #expect(onkel.it == "lo zio")
        let dict = onkel.katalogDict()
        #expect(dict["it"] as? String == "lo zio")
        let hinweise = dict["hinweise"] as? [String: String]
        #expect(hinweise?["tr"]?.contains("dayı") == true)
        #expect(hinweise?["it"] != nil)
    }

    @Test func einEditorWortOhneItalienischBleibtOhne() {
        var w = EditorWort()
        w.de = "der Hund"; w.en = "dog"; w.tr = "köpek"
        #expect(w.katalogDict()["it"] == nil)
        #expect(w.gueltig, "Italienisch ist keine Pflicht")
    }

    @Test func alteEntwuerfeOhneItalienischLassenSichLesen() throws {
        let alt = #"{"id": "6F0E0C2E-7A58-4B45-8E8C-0C9B1B2D7E11", "emoji": "", "de": "Haus", "en": "house", "tr": "ev", "altEn": "", "altTr": "", "hinweis": ""}"#
        let w = try JSONDecoder().decode(EditorWort.self, from: Data(alt.utf8))
        #expect(w.de == "Haus")
        #expect(w.it.isEmpty)
        #expect(w.hinweise.isEmpty)
    }
}

extension Wort {
    /// Ein Testwort mit italienischer Übersetzung.
    static func test(it: String, alt: [String] = []) -> Wort {
        var d: [String: Any] = ["de": "x", "it": it]
        if !alt.isEmpty { d["alt"] = ["it": alt] }
        let daten = (try? JSONSerialization.data(withJSONObject: d)) ?? Data()
        guard let wort = try? JSONDecoder().decode(Wort.self, from: daten) else {
            preconditionFailure("Testwort lässt sich nicht lesen")
        }
        return wort
    }
}
