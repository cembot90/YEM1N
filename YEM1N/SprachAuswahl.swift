import SwiftUI

// ============================================================
// MARK: - Welche Sprachen lernt dieses Gerät?
// ============================================================

/// Nicht jedes Kind will jede Sprache lernen. Gespeichert wird ein Text:
/// leer = noch nie gewählt (dann sind alle Sprachen an), "-" = keine,
/// sonst die Sprachcodes mit Komma, zum Beispiel "en,it".
enum SprachAuswahl {
    static let schluessel = "sprachWahl"
    static let keine = "-"

    /// Die Sprachen, die gerade gelernt werden, in der Reihenfolge des Katalogs.
    static func aktiv(roh: String, alle: [String]) -> [String] {
        let t = roh.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return alle }
        if t == keine { return [] }
        let gewaehlt = Set(t.split(separator: ",").map { String($0) })
        return alle.filter { gewaehlt.contains($0) }
    }

    /// Schaltet eine Sprache an oder aus und gibt den neuen Text zurück.
    static func umgeschaltet(_ code: String, roh: String, alle: [String]) -> String {
        var jetzt = aktiv(roh: roh, alle: alle)
        if let i = jetzt.firstIndex(of: code) {
            jetzt.remove(at: i)
        } else {
            jetzt.append(code)
        }
        return kodiert(jetzt, alle: alle)
    }

    static func kodiert(_ codes: [String], alle: [String]) -> String {
        let gueltig = alle.filter { codes.contains($0) }
        if gueltig.isEmpty { return keine }
        return gueltig.joined(separator: ",")
    }

    static func istAn(_ code: String, roh: String, alle: [String]) -> Bool {
        aktiv(roh: roh, alle: alle).contains(code)
    }
}

/// Auswahl als große Schalter, im Einrichtungsassistenten.
struct SprachWahlChips: View {
    @AppStorage(SprachAuswahl.schluessel) private var wahl = ""
    private let store = SprachKatalogStore.shared

    var body: some View {
        let alle = store.katalog.lernsprachen
        VStack(spacing: 10) {
            ForEach(alle, id: \.self) { code in
                let info = store.sprache(code)
                let an = SprachAuswahl.istAn(code, roh: wahl, alle: alle)
                Button {
                    wahl = SprachAuswahl.umgeschaltet(code, roh: wahl, alle: alle)
                } label: {
                    HStack(spacing: 10) {
                        Text(info.flagge).font(.title2)
                        Text(info.name)
                            .font(.system(.headline, design: .rounded).weight(.heavy))
                        Spacer()
                        Image(systemName: an ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                    }
                    .foregroundStyle(an ? Theme.navy : Color.white)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(an ? Theme.gelb : Color.white.opacity(0.10), in: Capsule())
                }
                .buttonStyle(TastenStil())
            }
        }
    }
}

/// Auswahl als Schalter-Liste, in den Einstellungen.
struct SprachWahlSchalter: View {
    @AppStorage(SprachAuswahl.schluessel) private var wahl = ""
    private let store = SprachKatalogStore.shared

    var body: some View {
        let alle = store.katalog.lernsprachen
        ForEach(alle, id: \.self) { code in
            let info = store.sprache(code)
            Toggle("\(info.flagge) \(info.name)", isOn: Binding(
                get: { SprachAuswahl.istAn(code, roh: wahl, alle: alle) },
                set: { _ in wahl = SprachAuswahl.umgeschaltet(code, roh: wahl, alle: alle) }
            ))
        }
    }
}
