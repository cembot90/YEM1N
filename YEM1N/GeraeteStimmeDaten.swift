import Foundation

// ============================================================
// MARK: - Gerätestimmen: Pakete, Speicherort, Auspacken
// ============================================================
//
// Die Gerätestimmen sind freie Piper-Stimmen (Lizenz CC0). Die App lädt sie
// auf Wunsch einmal von GitHub und liest danach ohne Internet damit vor.
// Diese Datei braucht nur Foundation, damit sie auch unter Linux geprüft werden kann.

/// Eine Stimme oder die Aussprachedaten, so wie sie zum Laden bereitliegen.
nonisolated struct GeraetePaket: Identifiable, Hashable, Sendable {
    let id: String
    /// "de" oder "tr", leer bei den Aussprachedaten
    let sprache: String
    let name: String
    /// Ordner nach dem Auspacken, so wie er im Paket steht
    let ordner: String
    let bytes: Int
    let sha256: String
    /// Nummern der Sprecher im Modell. Thorsten kann auch fröhlich und leise.
    let sprecherNormal: Int
    let sprecherFroh: Int
    let sprecherLeise: Int

    static let basis = "https://github.com/cembot90/YEM1N/releases/download/stimmen-1/"

    var url: URL? { URL(string: Self.basis + id + ".tar") }
    var megabyte: Int { (bytes + 500_000) / 1_000_000 }

    func sprecher(_ s: SprechStimmung) -> Int {
        switch s {
        case .normal: return sprecherNormal
        case .froh: return sprecherFroh
        case .leise: return sprecherLeise
        }
    }

    /// Wie die Stimmen ausgesprochen werden (espeak-ng, nur Deutsch, Türkisch, Englisch).
    /// Gehört zu jeder Stimme dazu und wird beim ersten Laden mitgeholt.
    static let aussprache = GeraetePaket(
        id: "espeak-1", sprache: "", name: "Aussprache", ordner: "espeak-ng-data",
        bytes: 1_228_800, sha256: "678402ce9945a6f2cbeb05050cfabfaf631c297a06ddc20eebdaad869f20aad0",
        sprecherNormal: 0, sprecherFroh: 0, sprecherLeise: 0)

    static let stimmen: [GeraetePaket] = [
        // Thorsten-Voice mit Gefühlen: 0 fröhlich, 4 neutral, 7 flüsternd
        GeraetePaket(id: "de-thorsten-1", sprache: "de", name: "Thorsten", ordner: "de-thorsten",
                     bytes: 76_707_840, sha256: "b6b0312098cc9b4fa80ff98226444cbd270a28a9dcfd5b56a71886b4932ca185",
                     sprecherNormal: 4, sprecherFroh: 0, sprecherLeise: 7),
        GeraetePaket(id: "tr-fahrettin-1", sprache: "tr", name: "Fahrettin", ordner: "tr-fahrettin",
                     bytes: 63_160_320, sha256: "f092809a87d8a1d1d15710963097c273d728550f73d3ff8abcf27d6141b3ad6d",
                     sprecherNormal: 0, sprecherFroh: 0, sprecherLeise: 0)
    ]

    static func fuer(sprache: String) -> GeraetePaket? {
        stimmen.first { $0.sprache == sprache }
    }
}

/// Wo die geladenen Stimmen auf dem Gerät liegen.
nonisolated enum StimmOrt {
    static var wurzel: URL {
        let basis = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return basis.appendingPathComponent("GeraeteStimmen", isDirectory: true)
    }

    static func ordner(_ p: GeraetePaket, in wurzel: URL = wurzel) -> URL {
        wurzel.appendingPathComponent(p.ordner, isDirectory: true)
    }

    /// Diese kleine Datei entsteht erst, wenn alles fertig ausgepackt ist.
    static func marke(_ p: GeraetePaket, in wurzel: URL = wurzel) -> URL {
        wurzel.appendingPathComponent(p.id + ".fertig")
    }

    static func installiert(_ p: GeraetePaket, in wurzel: URL = wurzel) -> Bool {
        FileManager.default.fileExists(atPath: marke(p, in: wurzel).path)
    }

    /// Packt ein geprüftes Paket aus und ersetzt eine ältere Fassung.
    static func einrichten(_ p: GeraetePaket, aus datei: URL, in wurzel: URL = wurzel) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: wurzel, withIntermediateDirectories: true)
        let zwischen = wurzel.appendingPathComponent("auspacken-" + p.id, isDirectory: true)
        try? fm.removeItem(at: zwischen)
        try fm.createDirectory(at: zwischen, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: zwischen) }
        _ = try TarAuspacker.auspacken(datei, nach: zwischen)
        let neu = zwischen.appendingPathComponent(p.ordner, isDirectory: true)
        guard fm.fileExists(atPath: neu.path) else {
            throw TarAuspacker.Fehler(text: "Im Paket fehlt der Ordner \(p.ordner).")
        }
        let ziel = ordner(p, in: wurzel)
        try? fm.removeItem(at: marke(p, in: wurzel))
        try? fm.removeItem(at: ziel)
        try fm.moveItem(at: neu, to: ziel)
        // Die Stimmen lassen sich jederzeit neu laden, sie gehören nicht ins Backup
        var werte = URLResourceValues()
        werte.isExcludedFromBackup = true
        var w = wurzel
        try? w.setResourceValues(werte)
        try Data().write(to: marke(p, in: wurzel))
    }

    static func entfernen(_ p: GeraetePaket, in wurzel: URL = wurzel) {
        try? FileManager.default.removeItem(at: marke(p, in: wurzel))
        try? FileManager.default.removeItem(at: ordner(p, in: wurzel))
    }
}

/// Liest ein einfaches tar-Archiv (ustar, ohne Kompression) Stück für Stück,
/// damit auch 80 MB nicht auf einmal in den Speicher müssen.
nonisolated enum TarAuspacker {
    struct Fehler: Error, LocalizedError {
        let text: String
        var errorDescription: String? { text }
    }

    @discardableResult
    static func auspacken(_ datei: URL, nach ziel: URL) throws -> Int {
        let fm = FileManager.default
        let lesen = try FileHandle(forReadingFrom: datei)
        defer { try? lesen.close() }
        var dateien = 0
        while true {
            guard let kopf = try lesen.read(upToCount: 512), kopf.count == 512 else { break }
            let b = [UInt8](kopf)
            if b.allSatisfy({ $0 == 0 }) { break }
            let name = pfad(b)
            let groesse = try zahl(b, von: 124, laenge: 12)
            let art = b[156]
            let rest = (512 - groesse % 512) % 512
            guard !name.isEmpty, sicher(name) else {
                throw Fehler(text: "Ungültiger Name im Paket: \(name)")
            }
            let url = ziel.appendingPathComponent(name)
            switch art {
            case UInt8(ascii: "5"):
                try fm.createDirectory(at: url, withIntermediateDirectories: true)
                try ueberspringe(lesen, groesse + rest)
            case UInt8(ascii: "0"), 0:
                try fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                _ = fm.createFile(atPath: url.path, contents: nil)
                let schreiben = try FileHandle(forWritingTo: url)
                var offen = groesse
                while offen > 0 {
                    let stueck = try lesen.read(upToCount: min(offen, 1 << 20)) ?? Data()
                    if stueck.isEmpty { try? schreiben.close(); throw Fehler(text: "Das Paket ist unvollständig.") }
                    try schreiben.write(contentsOf: stueck)
                    offen -= stueck.count
                }
                try schreiben.close()
                try ueberspringe(lesen, rest)
                dateien += 1
            default:
                // Verknüpfungen und Sonderdateien braucht keine Stimme
                try ueberspringe(lesen, groesse + rest)
            }
        }
        return dateien
    }

    /// Name aus dem Kopf, bei langen Pfaden mit dem Vorsatz aus dem ustar-Feld
    static func pfad(_ b: [UInt8]) -> String {
        func text(_ von: Int, _ laenge: Int) -> String {
            let teil = b[von..<(von + laenge)].prefix { $0 != 0 }
            return String(decoding: teil, as: UTF8.self)
        }
        let name = text(0, 100)
        let ustar = text(257, 5) == "ustar"
        let vorsatz = ustar ? text(345, 155) : ""
        let ganz = vorsatz.isEmpty ? name : vorsatz + "/" + name
        return ganz.hasSuffix("/") ? String(ganz.dropLast()) : ganz
    }

    /// Kein Pfad darf aus dem Zielordner herausführen
    static func sicher(_ name: String) -> Bool {
        !name.hasPrefix("/") && !name.split(separator: "/").contains("..")
    }

    static func zahl(_ b: [UInt8], von: Int, laenge: Int) throws -> Int {
        let teil = b[von..<(von + laenge)].filter { $0 != 0 && $0 != UInt8(ascii: " ") }
        guard let n = Int(String(decoding: teil, as: UTF8.self), radix: 8), n >= 0 else {
            throw Fehler(text: "Ungültige Größe im Paket.")
        }
        return n
    }

    private static func ueberspringe(_ h: FileHandle, _ n: Int) throws {
        guard n > 0 else { return }
        let stelle = try h.offset()
        try h.seek(toOffset: stelle + UInt64(n))
    }
}
