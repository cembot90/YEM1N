import Foundation
import CryptoKit
import Security

// ============================================================
// MARK: - Schlüssel dieses Geräts (Secure Enclave)
// ============================================================
//
// Jedes Gerät hat ein eigenes Schlüsselpaar (P-256). Der private Teil liegt in der Secure Enclave und
// verlässt das Gerät nie. Der Familien-Dienst kennt nur den öffentlichen Teil und prüft damit jede Anfrage.
// Auf dem Simulator gibt es keine Secure Enclave, dort liegt der Schlüssel als Software-Schlüssel im Schlüsselbund.

/// Wo die Schlüsseldaten liegen. Im Alltag ist das der Schlüsselbund, Tests nehmen den Arbeitsspeicher.
nonisolated protocol SchluesselSpeicher: Sendable {
    func lese() -> Data?
    func schreibe(_ daten: Data) -> Bool
    func loesche()
}

/// Der Schlüsselbund des Geräts. Nur auf diesem Gerät, nie in Sicherungen oder auf neuen Geräten.
nonisolated struct SchluesselbundSpeicher: SchluesselSpeicher {
    static let dienst = "de.cemaras.yem1n.geraet"
    let konto: String

    private func basis() -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Self.dienst,
         kSecAttrAccount as String: konto]
    }

    func schreibe(_ daten: Data) -> Bool {
        SecItemDelete(basis() as CFDictionary)
        var neu = basis()
        neu[kSecValueData as String] = daten
        // Nach dem ersten Entsperren nutzbar, aber nur auf diesem Gerät.
        neu[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(neu as CFDictionary, nil) == errSecSuccess
    }

    func lese() -> Data? {
        var q = basis()
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var ergebnis: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ergebnis) == errSecSuccess else { return nil }
        return ergebnis as? Data
    }

    func loesche() { SecItemDelete(basis() as CFDictionary) }
}

nonisolated final class GeraetSchluessel: GeraetSignierer, @unchecked Sendable {
    /// Der Schlüssel der App. Tests nehmen einen eigenen Speicher, damit sie den echten nicht anfassen.
    static let shared = GeraetSchluessel(konto: "schluessel-v2")

    private let speicher: SchluesselSpeicher
    private let schloss = NSLock()
    private var zwischenspeicher: Schluessel?

    init(konto: String) { speicher = SchluesselbundSpeicher(konto: konto) }
    init(speicher: SchluesselSpeicher) { self.speicher = speicher }

    private enum Schluessel {
        case enclave(SecureEnclave.P256.Signing.PrivateKey)
        case software(P256.Signing.PrivateKey)

        var oeffentlich: P256.Signing.PublicKey {
            switch self {
            case .enclave(let k): return k.publicKey
            case .software(let k): return k.publicKey
            }
        }

        func signiere(_ daten: Data) -> [UInt8]? {
            switch self {
            case .enclave(let k): return (try? k.signature(for: daten)).map { [UInt8]($0.rawRepresentation) }
            case .software(let k): return (try? k.signature(for: daten)).map { [UInt8]($0.rawRepresentation) }
            }
        }
    }

    // Erstes Byte der gespeicherten Daten sagt, welche Art Schlüssel folgt.
    private static let kennzeichenEnclave: UInt8 = 1
    private static let kennzeichenSoftware: UInt8 = 2

    private func laden() -> Schluessel? {
        if let z = zwischenspeicher { return z }
        guard let d = speicher.lese(), let erstes = d.first else { return nil }
        let rest = d.dropFirst()
        let k: Schluessel?
        switch erstes {
        case Self.kennzeichenEnclave:
            k = (try? SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: Data(rest))).map { .enclave($0) }
        case Self.kennzeichenSoftware:
            k = (try? P256.Signing.PrivateKey(rawRepresentation: Data(rest))).map { .software($0) }
        default:
            k = nil
        }
        zwischenspeicher = k
        return k
    }

    // MARK: Schnittstelle

    /// Gibt es einen Schlüssel, den dieses Gerät benutzen kann?
    var vorhanden: Bool {
        schloss.lock(); defer { schloss.unlock() }
        return laden() != nil
    }

    /// "Secure Enclave" oder "Software" (zum Beispiel im Simulator), für die Anzeige in den Einstellungen.
    var art: String {
        schloss.lock(); defer { schloss.unlock() }
        switch laden() {
        case .enclave: return "Secure Enclave"
        case .software: return "Software"
        case nil: return "kein Schlüssel"
        }
    }

    func oeffentlich() -> [UInt8]? {
        schloss.lock(); defer { schloss.unlock() }
        guard let k = laden() else { return nil }
        let pub = [UInt8](k.oeffentlich.x963Representation)
        return pub.count == 65 && pub[0] == 4 ? pub : nil
    }

    func signieren(_ daten: [UInt8]) -> [UInt8]? {
        schloss.lock(); defer { schloss.unlock() }
        guard let k = laden() else { return nil }
        let sig = k.signiere(Data(daten))
        return sig?.count == 64 ? sig : nil
    }

    /// Legt ein neues Schlüsselpaar an und ersetzt ein altes. Gibt false zurück, wenn es nicht ging.
    @discardableResult
    func neuErzeugen() -> Bool {
        schloss.lock(); defer { schloss.unlock() }
        zwischenspeicher = nil
        speicher.loesche()
        if SecureEnclave.isAvailable {
            var fehler: Unmanaged<CFError>?
            if let zugriff = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                                                             .privateKeyUsage, &fehler),
               let k = try? SecureEnclave.P256.Signing.PrivateKey(accessControl: zugriff),
               speicher.schreibe(Data([Self.kennzeichenEnclave]) + k.dataRepresentation) {
                zwischenspeicher = .enclave(k)
                return true
            }
        }
        let k = P256.Signing.PrivateKey()
        guard speicher.schreibe(Data([Self.kennzeichenSoftware]) + k.rawRepresentation) else { return false }
        zwischenspeicher = .software(k)
        return true
    }

    /// Löscht den Schlüssel dieses Geräts. Danach kann es nichts mehr unterschreiben.
    func loeschen() {
        schloss.lock(); defer { schloss.unlock() }
        zwischenspeicher = nil
        speicher.loesche()
    }
}
