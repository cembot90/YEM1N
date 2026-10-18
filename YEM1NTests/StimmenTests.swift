import Foundation
import Testing
@testable import YEM1N

// Natürliche Stimmen: Namen der Studio-Aufnahmen, Pakete der Gerätestimmen und das Auspacken.

@MainActor
struct StimmenTests {

    // MARK: Namen der Aufnahmen

    @Test func aufnahmeNameBleibtGleich() {
        // Derselbe Name entsteht beim Sammeln unter Linux. Ändert sich das hier,
        // findet die App keine einzige Studio-Aufnahme mehr.
        #expect(VorleseText.aufnahme("Wie viele siehst du?", sprache: "de-DE") == "studio_de_2a2252ee4d41a4d8")
        #expect(VorleseText.aufnahme("Wie viele siehst du?", sprache: "de")
                == VorleseText.aufnahme("Wie viele siehst du?", sprache: "de-DE"))
        #expect(VorleseText.aufnahme("Wie viele siehst du?", sprache: "tr")
                != VorleseText.aufnahme("Wie viele siehst du?", sprache: "de"))
    }

    @Test func bilderUndLeerzeichenZaehlenNicht() {
        #expect(VorleseText.gesprochen("🍎 Hallo  Welt! ❤️\n") == "Hallo Welt!")
        #expect(VorleseText.aufnahme("🦉 Super!", sprache: "de") == VorleseText.aufnahme("Super!", sprache: "de"))
        #expect(VorleseText.gesprochen("Es sind 7.") == "Es sind 7.")
    }

    @Test func aufgabeWirdInWortenGesprochen() {
        let t = VorleseText.aufgabe(frage: "Rechne", rechnung: "7 · 8 =")
        #expect(t.contains("7 mal 8"))
        #expect(t.contains("gleich"))
        #expect(!t.contains("·"))
    }

    // MARK: Pakete

    @Test func paketeSindVollstaendig() {
        let alle = [GeraetePaket.aussprache] + GeraetePaket.stimmen
        #expect(Set(alle.map(\.id)).count == alle.count)
        for p in alle {
            #expect(p.url != nil, "\(p.id)")
            #expect(p.sha256.count == 64 && p.sha256.allSatisfy(\.isHexDigit), "\(p.id)")
            #expect(p.bytes > 0 && p.bytes % 512 == 0, "\(p.id): tar ist immer ein Vielfaches von 512")
        }
        #expect(GeraetePaket.fuer(sprache: "de")?.name == "Thorsten")
        #expect(GeraetePaket.fuer(sprache: "tr")?.name == "Fahrettin")
        #expect(GeraetePaket.fuer(sprache: "en") == nil)
    }

    @Test func thorstenKannFroehlichUndLeise() {
        guard let p = GeraetePaket.fuer(sprache: "de") else {
            Issue.record("Thorsten fehlt")
            return
        }
        #expect(p.sprecher(.normal) == 4)
        #expect(p.sprecher(.froh) == 0)
        #expect(p.sprecher(.leise) == 7)
    }

    // MARK: Auspacken

    /// Baut ein kleines tar so, wie es packen.py macht.
    static func tar(_ eintraege: [(String, Data?)]) -> Data {
        var d = Data()
        for (name, inhalt) in eintraege {
            var kopf = [UInt8](repeating: 0, count: 512)
            func schreibe(_ s: String, _ an: Int) {
                for (i, b) in s.utf8.enumerated() { kopf[an + i] = b }
            }
            schreibe(name, 0)
            schreibe("0000644\0", 100)
            let groesse = inhalt?.count ?? 0
            schreibe(String(format: "%011o", groesse) + "\0", 124)
            kopf[156] = inhalt == nil ? UInt8(ascii: "5") : UInt8(ascii: "0")
            schreibe("ustar\0", 257)
            d.append(contentsOf: kopf)
            if let inhalt {
                d.append(inhalt)
                d.append(Data(count: (512 - inhalt.count % 512) % 512))
            }
        }
        d.append(Data(count: 1024))
        return d
    }

    static func ordner() -> URL {
        let u = FileManager.default.temporaryDirectory.appendingPathComponent("stimmen-test-" + UUID().uuidString)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    @Test func tarWirdAusgepackt() throws {
        let wurzel = Self.ordner()
        defer { try? FileManager.default.removeItem(at: wurzel) }
        let gross = Data((0..<1500).map { UInt8($0 % 251) })
        let datei = wurzel.appendingPathComponent("p.tar")
        try Self.tar([
            ("espeak-ng-data/", nil),
            ("espeak-ng-data/de_dict", Data("hallo".utf8)),
            ("espeak-ng-data/lang/gmw/de", gross)
        ]).write(to: datei)
        let ziel = wurzel.appendingPathComponent("aus")
        let n = try TarAuspacker.auspacken(datei, nach: ziel)
        #expect(n == 2)
        #expect(try Data(contentsOf: ziel.appendingPathComponent("espeak-ng-data/de_dict")) == Data("hallo".utf8))
        #expect(try Data(contentsOf: ziel.appendingPathComponent("espeak-ng-data/lang/gmw/de")) == gross)
    }

    @Test func tarDarfNichtAusDemOrdnerHeraus() throws {
        let wurzel = Self.ordner()
        defer { try? FileManager.default.removeItem(at: wurzel) }
        let datei = wurzel.appendingPathComponent("boese.tar")
        try Self.tar([("../weg.txt", Data("x".utf8))]).write(to: datei)
        #expect(throws: TarAuspacker.Fehler.self) {
            try TarAuspacker.auspacken(datei, nach: wurzel.appendingPathComponent("aus"))
        }
        #expect(!TarAuspacker.sicher("/etc/passwd"))
        #expect(TarAuspacker.sicher("de-thorsten/stimme.onnx"))
    }

    @Test func stimmeEinrichtenUndEntfernen() throws {
        let wurzel = Self.ordner()
        defer { try? FileManager.default.removeItem(at: wurzel) }
        guard let p = GeraetePaket.fuer(sprache: "tr") else { return }
        let datei = wurzel.appendingPathComponent("tr.tar")
        try Self.tar([
            (p.ordner + "/stimme.onnx", Data("modell".utf8)),
            (p.ordner + "/tokens.txt", Data("_ 0".utf8))
        ]).write(to: datei)
        #expect(!StimmOrt.installiert(p, in: wurzel))
        try StimmOrt.einrichten(p, aus: datei, in: wurzel)
        #expect(StimmOrt.installiert(p, in: wurzel))
        #expect(FileManager.default.fileExists(atPath: StimmOrt.ordner(p, in: wurzel).appendingPathComponent("tokens.txt").path))
        // Ein zweites Mal ersetzt die alte Fassung ohne Fehler
        try StimmOrt.einrichten(p, aus: datei, in: wurzel)
        StimmOrt.entfernen(p, in: wurzel)
        #expect(!StimmOrt.installiert(p, in: wurzel))
    }

    @Test func paketOhneOrdnerWirdAbgelehnt() throws {
        let wurzel = Self.ordner()
        defer { try? FileManager.default.removeItem(at: wurzel) }
        guard let p = GeraetePaket.fuer(sprache: "de") else { return }
        let datei = wurzel.appendingPathComponent("falsch.tar")
        try Self.tar([("etwas/anderes.txt", Data("x".utf8))]).write(to: datei)
        #expect(throws: TarAuspacker.Fehler.self) {
            try StimmOrt.einrichten(p, aus: datei, in: wurzel)
        }
        #expect(!StimmOrt.installiert(p, in: wurzel))
    }

    // MARK: Gesammelte Sätze

    @Test func vorschulSaetzeHabenEineAufnahmeName() {
        // Was die Vorschule sagt, muss denselben Namen ergeben wie beim Sammeln
        for _ in 0..<50 {
            let f = VorschulGenerator.eine(.zaehlen, stufe: 1)
            let name = VorleseText.aufnahme(f.text.de, sprache: "de-DE")
            #expect(name.hasPrefix("studio_de_") && name.count == "studio_de_".count + 16)
        }
    }
}
