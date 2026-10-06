import Foundation
import Testing
@testable import YEM1N

// Familiencode, Klassencode und die QR-Codes dazu.
// Ein falsch gelesener Code heißt: Das Kind kommt nicht in die Familie.

@MainActor
struct CodesTests {

    // MARK: Familiencode

    @Test func neueCodesSindImmerGueltig() {
        for _ in 0..<500 {
            let code = Familiencode.neu()
            #expect(code.count == 11, "falsche Länge: \(code)")
            #expect(Array(code)[5] == "-", "Bindestrich fehlt: \(code)")
            #expect(Familiencode.istGueltig(code), "ungültig: \(code)")
            #expect(Familiencode.bereinigt(code) == code, "Bereinigen verändert den Code: \(code)")
        }
    }

    @Test func verwechselbareBuchstabenKommenNichtVor() {
        // I und O fehlen absichtlich, damit niemand 1 und l oder 0 und O verwechselt
        for _ in 0..<500 {
            let code = Familiencode.neu()
            #expect(!code.contains("I"), "I im Code: \(code)")
            #expect(!code.contains("O"), "O im Code: \(code)")
            #expect(!code.contains("0"), "Null im Code: \(code)")
            #expect(!code.contains("1"), "Eins im Code: \(code)")
        }
    }

    @Test func bereinigenRaeumtTippfehlerAuf() {
        #expect(Familiencode.bereinigt("abcde fghjk") == "ABCDE-FGHJK")
        #expect(Familiencode.bereinigt("ABCDEFGHJK") == "ABCDE-FGHJK")
        #expect(Familiencode.bereinigt("ABCDE-FGHJK-XYZ") == "ABCDE-FGHJK")
        #expect(Familiencode.bereinigt("") == "")
        #expect(Familiencode.bereinigt("ABC") == "ABC")
    }

    @Test func unvollstaendigeCodesSindUngueltig() {
        #expect(!Familiencode.istGueltig(""))
        #expect(!Familiencode.istGueltig("ABCDE"))
        #expect(!Familiencode.istGueltig("ABCDE-FGHJ"))
        #expect(Familiencode.istGueltig("ABCDE-FGHJK"))
    }

    // MARK: QR-Code

    @Test func qrCodeHinUndZurueck() {
        for art in ["familie", "klasse"] {
            let code = Familiencode.neu()
            let inhalt = QRPaket.inhalt(art: art, code: code)
            let gelesen = QRPaket.lese(inhalt)
            #expect(gelesen?.art == art, "Art ging verloren: \(inhalt)")
            #expect(gelesen?.code == code, "Code ging verloren: \(inhalt)")
        }
    }

    @Test func fremdeUndKaputteCodesWerdenAbgelehnt() {
        #expect(QRPaket.lese("") == nil)
        #expect(QRPaket.lese("Hallo") == nil)
        #expect(QRPaket.lese("https://example.com") == nil)
        #expect(QRPaket.lese("yem1n://familie") == nil)
        #expect(QRPaket.lese("yem1n://familie/ABC") == nil)
        #expect(QRPaket.lese("yem1n://unsinn/ABCDE-FGHJK") == nil)
        #expect(QRPaket.lese("yem1n://familie/ABCDE-FGHJK/extra") == nil)
    }

    @Test func leerzeichenUndGrossschreibungStoerenNicht() {
        let gelesen = QRPaket.lese("  YEM1N://FAMILIE/abcde-fghjk  ")
        #expect(gelesen?.art == "familie")
        #expect(gelesen?.code == "ABCDE-FGHJK")
    }

    @Test func zuJedemCodeGibtEsEinBild() {
        let inhalt = QRPaket.inhalt(art: "familie", code: Familiencode.neu())
        #expect(QRPaket.bild(inhalt) != nil, "QR-Bild konnte nicht erzeugt werden")
    }
}
