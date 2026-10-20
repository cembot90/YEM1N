import Foundation
import Testing
@testable import YEM1N

// Rechenweg in Schritten: Jeder Schritt muss stimmen, und am Ende muss genau
// die Lösung der Aufgabe herauskommen. Sonst gibt es lieber keinen Weg.

@MainActor
struct RechenwegTests {

    /// Jeder Schritt, der eine Rechnung ist, ergibt seine Antwort
    private func stimmt(_ w: RechenWeg, _ text: String) {
        for s in w.schritte {
            if let t = ErklaerBildPlan.term(s.rechnung), let wert = ErklaerBildPlan.wert(t) {
                #expect(wert == s.antwort, "\(text): \(s.rechnung) \(s.antwort)")
            }
            #expect(!s.hinweis.isEmpty && !s.rechnung.isEmpty)
            for t in [s.hinweis, s.rechnung] {
                #expect(!t.contains("\u{2013}") && !t.contains("\u{2014}"), "\(t)")
            }
        }
    }

    @Test func plusMitZehnerUndBisZumZehner() throws {
        let w = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "47 + 25 =", antwort: "72"))
        #expect(w.schritte.map(\.rechnung) == ["47 + 20 =", "67 + 3 =", "70 + 2 ="])
        #expect(w.schritte.map(\.antwort) == [67, 70, 72])
        #expect(w.antwort == "72" && w.antwort2 == nil)
        stimmt(w, "47 + 25")
    }

    @Test func minusUeberDenZehner() throws {
        let w = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "63 - 28 =", antwort: "35"))
        #expect(w.schritte.map(\.antwort) == [43, 40, 35])
        stimmt(w, "63 - 28")
    }

    @Test func malMitKernaufgabe() throws {
        let w = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "6 · 7 =", antwort: "42"))
        #expect(w.schritte.map(\.rechnung) == ["5 · 7 =", "35 + 7 ="])
        let neun = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "9 · 6 =", antwort: "54"))
        #expect(neun.schritte.map(\.rechnung) == ["10 · 6 =", "60 - 6 ="])
        // Getauscht: 7 · 4 wird zu 4 · 7
        let tausch = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "7 · 4 =", antwort: "28"))
        #expect(tausch.schritte.first?.hinweis.contains("Tausche") == true)
        let sieben = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "7 · 8 =", antwort: "56"))
        #expect(sieben.schritte.map(\.antwort) == [40, 16, 56])
        let gross = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "3 · 14 =", antwort: "42"))
        #expect(gross.schritte.map(\.antwort) == [30, 12, 42])
        // Kernaufgaben sind schon ein Schritt
        #expect(RechenWegPlan.weg(art: "zahl", rechnung: "5 · 7 =", antwort: "35") == nil)
        #expect(RechenWegPlan.weg(art: "zahl", rechnung: "10 · 4 =", antwort: "40") == nil)
    }

    @Test func geteiltZerlegt() throws {
        let w = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "42 : 6 =", antwort: "7"))
        #expect(w.schritte.map(\.antwort) == [30, 12, 2, 7])
        let zwei = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "84 : 4 =", antwort: "21"))
        #expect(zwei.schritte.map(\.antwort) == [80, 4, 1, 21])
        #expect(RechenWegPlan.weg(art: "zahl", rechnung: "15 : 5 =", antwort: "3") == nil)
    }

    @Test func tellenMitRest() throws {
        let w = try #require(RechenWegPlan.weg(art: "rest", rechnung: "58 : 4 =", antwort: "14", antwort2: "2"))
        #expect(w.antwort == "14" && w.antwort2 == "2")
        #expect(w.schritte.map(\.antwort) == [40, 18, 16, 4, 2, 14])
        stimmt(w, "58 : 4")
        let klein = try #require(RechenWegPlan.weg(art: "rest", rechnung: "23 : 5 =", antwort: "4", antwort2: "3"))
        #expect(klein.schritte.map(\.antwort) == [20, 4, 3])
        let passtNicht = try #require(RechenWegPlan.weg(art: "rest", rechnung: "42 : 4 =", antwort: "10", antwort2: "2"))
        #expect(passtNicht.schritte.last?.antwort == 2)
    }

    @Test func punktVorStrich() throws {
        let w = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "9 · 9 + 8 =", antwort: "89"))
        #expect(w.schritte.map(\.rechnung) == ["9 · 9 =", "81 + 8 ="])
        #expect(w.schritte.first?.hinweis.contains("Punkt vor Strich") == true)
        let strich = try #require(RechenWegPlan.weg(art: "zahl", rechnung: "30 - 4 · 5 =", antwort: "10"))
        #expect(strich.schritte.map(\.antwort) == [20, 10])
    }

    @Test func vergleichRechnetBeideSeiten() throws {
        let w = try #require(RechenWegPlan.weg(art: "vergleich", rechnung: "5 · 5  ?  9 · 7", antwort: "<"))
        #expect(w.schritte.map(\.antwort) == [25, 63])
        #expect(w.antwort == nil)
    }

    @Test func falscheLoesungOderWorteGebenKeinenWeg() {
        #expect(RechenWegPlan.weg(art: "zahl", rechnung: "47 + 25 =", antwort: "71") == nil)
        #expect(RechenWegPlan.weg(art: "zahl", rechnung: "Subtrahiere von 75 die Zahl 8.", antwort: "67") == nil)
        #expect(RechenWegPlan.weg(art: "rest", rechnung: "58 : 4 =", antwort: "14", antwort2: "3") == nil)
        #expect(RechenWegPlan.weg(art: "text", rechnung: "Hun?", antwort: "d") == nil)
    }

    @Test func vieleAufgabenRechnenRichtigBisZumEnde() {
        var mitWeg = 0
        for a in 1...100 {
            for b in 1...12 {
                for (z, e) in [("+", a + b), ("-", a - b), ("·", a * b)] where e >= 0 {
                    let text = "\(a) \(z) \(b) ="
                    if let w = RechenWegPlan.weg(art: "zahl", rechnung: text, antwort: String(e)) {
                        mitWeg += 1
                        stimmt(w, text)
                        #expect(w.schritte.last?.antwort == e, "\(text)")
                        #expect(w.schritte.count >= 2)
                    }
                }
                if b > 1 {
                    let text = "\(a) : \(b) ="
                    if a % b == 0, let w = RechenWegPlan.weg(art: "zahl", rechnung: text, antwort: String(a / b)) {
                        stimmt(w, text)
                        #expect(w.schritte.last?.antwort == a / b, "\(text)")
                    }
                    if b <= 10, let w = RechenWegPlan.weg(art: "rest", rechnung: text, antwort: String(a / b), antwort2: String(a % b)) {
                        stimmt(w, text)
                        #expect(w.antwort == String(a / b) && w.antwort2 == String(a % b))
                        #expect(w.schritte.contains { $0.antwort == a % b }, "\(text): kein Schritt für den Rest")
                    }
                }
            }
        }
        #expect(mitWeg > 500)
    }
}
