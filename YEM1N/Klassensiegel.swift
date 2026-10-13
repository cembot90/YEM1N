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

    enum SchluesselStand: Equatable {
        case vertraut(Data)     // schon gemerkt, Cloud liefert denselben oder gerade keinen
        case neu(Data)          // zum ersten Mal geholt, wird jetzt gemerkt
        case fehlt              // weder gemerkt noch in der Cloud
        case gewechselt         // Cloud liefert einen anderen als den gemerkten

        var schluessel: Data? {
            switch self {
            case .vertraut(let d), .neu(let d): return d
            case .fehlt, .gewechselt: return nil
            }
        }
    }

    // Reine Entscheidung ohne Cloud, damit sie sich testen lässt
    static func bewerte(gemerkt: Data?, geholt: Data?) -> SchluesselStand {
        if let m = gemerkt {
            if let g = geholt, g != m { return .gewechselt }
            return .vertraut(m)
        }
        guard let g = geholt else { return .fehlt }
        return .neu(g)
    }

    // Der öffentliche Schlüssel wird beim ersten Mal gemerkt. Danach muss die Cloud denselben liefern.
    static func schluesselStand(_ code: String) async -> SchluesselStand {
        let feld = "klassenPin-" + code
        let geholt = await CloudDienst.ladeKlassenSchluessel(code)
        let gemerkt = UserDefaults.standard.string(forKey: feld).flatMap { Data(base64Encoded: $0) }
        let stand = bewerte(gemerkt: gemerkt, geholt: geholt)
        if case .neu(let g) = stand {
            UserDefaults.standard.set(g.base64EncodedString(), forKey: feld)
        }
        return stand
    }

    static func vertrauterSchluessel(_ code: String) async -> Data? {
        await schluesselStand(code).schluessel
    }

    // Admin-Gerät: passt der eigene Schlüssel zu dem in der Cloud? nil heißt: kein Admin oder Cloud nicht erreichbar
    static func adminPasstZurCloud(_ code: String) async -> Bool? {
        guard let k = privaterSchluessel(code),
              let wolke = await CloudDienst.ladeKlassenSchluessel(code) else { return nil }
        return k.publicKey.rawRepresentation == wolke
    }

    // Warum Pakete der Klasse abgelehnt wurden, in Worten für die Eltern
    enum Ablehnung: Hashable {
        case ohneUnterschrift, keinSchluessel, schluesselGewechselt, unterschriftFalsch

        var text: String {
            switch self {
            case .ohneUnterschrift:
                return "Das Paket hat keine Unterschrift. Der Admin der Klasse sollte es noch einmal an den Klassencode senden."
            case .keinSchluessel:
                return "In der Cloud liegt kein Schlüssel für diesen Klassencode. Der Admin der Klasse sollte ein Paket neu senden."
            case .schluesselGewechselt:
                return "Der Schlüssel der Klasse hat sich geändert. Klassencode in den Einstellungen entfernen und neu eintragen."
            case .unterschriftFalsch:
                return "Die Unterschrift passt nicht zum Schlüssel der Klasse. Der Admin der Klasse sollte das Paket neu senden."
            }
        }
    }
}
