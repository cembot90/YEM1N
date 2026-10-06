import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security
import WebKit
import CoreImage.CIFilterBuiltins

// ============================================================
// MARK: - Klassencode absichern (digitale Unterschrift)
// ============================================================

enum KlassenFehler: LocalizedError {
    case keinSchluessel

    var errorDescription: String? {
        "Auf diesem Gerät fehlt der Admin-Schlüssel für diesen Klassencode. Nur das Gerät, das den Klassencode angelegt hat, darf Pakete an die Klasse senden."
    }
}

enum Schluesselbund {
    private static let dienst = "de.cemaras.yem1n.klasse"

    static func speichere(_ daten: Data, konto: String) {
        let basis: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto
        ]
        SecItemDelete(basis as CFDictionary)
        var neu = basis
        neu[kSecValueData as String] = daten
        neu[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(neu as CFDictionary, nil)
    }

    static func lese(konto: String) -> Data? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: dienst,
            kSecAttrAccount as String: konto,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var ergebnis: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &ergebnis) == errSecSuccess else { return nil }
        return ergebnis as? Data
    }
}

enum Klassensiegel {
    static func konto(_ code: String) -> String { "klassenkey-" + code }

    static func privaterSchluessel(_ code: String) -> Curve25519.Signing.PrivateKey? {
        guard let d = Schluesselbund.lese(konto: konto(code)) else { return nil }
        return try? Curve25519.Signing.PrivateKey(rawRepresentation: d)
    }

    static func istAdmin(_ code: String) -> Bool { privaterSchluessel(code) != nil }

    private static func nachricht(_ code: String, _ json: String) -> Data {
        Data((code + "|" + json).utf8)
    }

    static func signiere(code: String, json: String) -> String? {
        guard let k = privaterSchluessel(code),
              let sig = try? k.signature(for: nachricht(code, json)) else { return nil }
        return sig.base64EncodedString()
    }

    static func pruefe(code: String, json: String, sig: String, oeffentlich: Data) -> Bool {
        guard let sd = Data(base64Encoded: sig),
              let pk = try? Curve25519.Signing.PublicKey(rawRepresentation: oeffentlich) else { return false }
        return pk.isValidSignature(sd, for: nachricht(code, json))
    }

    // Der öffentliche Schlüssel wird beim ersten Mal gemerkt. Danach muss die Cloud denselben liefern.
    static func vertrauterSchluessel(_ code: String) async -> Data? {
        let feld = "klassenPin-" + code
        let geholt = await CloudDienst.ladeKlassenSchluessel(code)
        if let b64 = UserDefaults.standard.string(forKey: feld), let gemerkt = Data(base64Encoded: b64) {
            if let g = geholt, g != gemerkt { return nil }
            return gemerkt
        }
        guard let g = geholt else { return nil }
        UserDefaults.standard.set(g.base64EncodedString(), forKey: feld)
        return g
    }
}
