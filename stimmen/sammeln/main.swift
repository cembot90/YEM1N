import Foundation

// Sammelt alle Sätze, die die App mit fester Stimme vorlesen kann,
// und schreibt sie als "Name<Tab>Text" nach stimmen/saetze/<sprache>.tsv.

var saetze: [String: [String: String]] = ["de": [:], "tr": [:]]

func merke(_ text: String, _ sprache: String) {
    let t = VorleseText.gesprochen(text)
    guard t.count >= 2, t.count <= 600, t.contains(where: { $0.isLetter }) else { return }
    saetze[sprache, default: [:]][VorleseText.aufnahme(t, sprache: sprache)] = t
}

// 1. Vorschule: jede Spielart oft genug erzeugen, bis keine neuen Sätze mehr kommen
for art in VorschulArt.allCases where art != .mix && art != .memory {
    for stufe in 1...3 {
        var ohneNeu = 0
        var runde = 0
        while ohneNeu < 1500 && runde < 60000 {
            runde += 1
            let vorher = saetze["de"]!.count + saetze["tr"]!.count
            let f = VorschulGenerator.eine(art, stufe: stufe)
            merke(f.text.de, "de")
            if let tr = f.text.tr { merke(tr, "tr") }
            ohneNeu = (saetze["de"]!.count + saetze["tr"]!.count == vorher) ? ohneNeu + 1 : 0
        }
    }
}

// 2. Feste Sätze aus den Dateien (Olli, das Tier, Lob in der Vorschule)
for (sprache, liste) in FesteSaetze.alle {
    for t in liste { merke(t, sprache) }
}

let ziel = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
for (sprache, liste) in saetze {
    let zeilen = liste.sorted { $0.value < $1.value }.map { "\($0.key)\t\($0.value)" }
    try! (zeilen.joined(separator: "\n") + "\n").write(toFile: "\(ziel)/\(sprache).tsv", atomically: true, encoding: .utf8)
    print("\(sprache): \(liste.count) Sätze, \(liste.values.reduce(0) { $0 + $1.count }) Zeichen")
}
