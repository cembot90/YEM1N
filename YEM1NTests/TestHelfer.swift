import Foundation
import Testing
@testable import YEM1N

// Gemeinsame Helfer für alle Tests

/// Alle ganzen Zahlen aus einem Text, in der Reihenfolge ihres Auftretens.
/// "Subtrahiere von 75 die Zahl 8." ergibt [75, 8].
func zahlen(aus text: String) -> [Int] {
    var liste: [Int] = []
    var aktuell = ""
    for ch in text {
        if ch.isASCII && ch.isNumber {
            aktuell.append(ch)
        } else {
            if let n = Int(aktuell) { liste.append(n) }
            aktuell = ""
        }
    }
    if let n = Int(aktuell) { liste.append(n) }
    return liste
}

/// true, wenn der Rechner die Rechnung ablehnt.
func wirftFehler(_ rechnung: String) -> Bool {
    do {
        _ = try MatheRechner.werte(rechnung)
        return false
    } catch {
        return true
    }
}

/// Eine Runde, die vor so vielen Tagen stattgefunden hat.
func testRunde(vorTagen tage: Int,
               richtig: Int = 10,
               gesamt: Int = 10,
               angesehen: Int = 0,
               uebung: String = "Einmaleins",
               fach: String = "Mathe") -> RundenErgebnis {
    let tag = Calendar.current.date(byAdding: .day, value: -tage, to: Date.now) ?? Date.now
    return RundenErgebnis(klasse: "Klasse 3",
                          fach: fach,
                          arbeit: "Testarbeit",
                          uebung: uebung,
                          richtig: richtig,
                          gesamt: gesamt,
                          angesehen: angesehen,
                          zeitpunkt: tag,
                          quelle: "lokal")
}

/// Ein gültiges Aufgabenpaket als JSON-Text.
let testPaketJSON = """
{"klasse": "Klasse 3", "fach": "Mathe", "arbeit": "Testarbeit Nr. 1", "uebungen": [
  {"titel": "Einmaleins", "gruppe": "Mal und Geteilt", "symbol": "7·8", "aufgaben": [
    {"art": "zahl", "frage": "Rechne.", "rechnung": "7 · 8 =", "antwort": "56"},
    {"art": "rest", "frage": "Teile mit Rest.", "rechnung": "58 : 4 =", "antwort": "14", "antwort2": "2"}
  ]}
]}
"""
