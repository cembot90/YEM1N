import Foundation
// Das Paket sherpa-onnx gibt es fest eingebaut (SherpaOnnx) und als eigene
// Bibliothek (SherpaOnnxShared). Die App nimmt die eigene Bibliothek, weil Apple
// die fest eingebaute Fassung beim Hochladen ablehnt (ITMS-90208).
#if canImport(SherpaOnnxShared)
import SherpaOnnxShared
#elseif canImport(SherpaOnnx)
import SherpaOnnx
#endif

// ============================================================
// MARK: - Gerätestimme: Sprache erzeugen
// ============================================================
//
// Rechnet aus Text die Tonspur mit einer Piper-Stimme über sherpa-onnx.
// Alles läuft auf dem Gerät in einer eigenen Warteschlange, damit die
// Oberfläche dabei nicht hängt. Ohne das Paket sherpa-onnx im Projekt
// gibt es keine Gerätestimme, dann liest die App mit den iOS-Stimmen vor.

nonisolated final class GeraeteStimmeMotor: @unchecked Sendable {
    static let shared = GeraeteStimmeMotor()

    /// Ist die Technik für Gerätestimmen in dieser App-Fassung eingebaut?
    static var eingebaut: Bool {
        #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
        return true
        #else
        return false
        #endif
    }

    struct Ton: Sendable {
        let proben: [Float]
        let rate: Int
    }

    private let schlange = DispatchQueue(label: "de.cemaras.yem1n.geraetestimme", qos: .userInitiated)
    #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
    /// Nur eine Stimme bleibt geladen, jede braucht gut 100 MB Arbeitsspeicher
    private var geladen: (id: String, tts: SherpaOnnxOfflineTtsWrapper)?
    #endif
    /// Zählt jede Benutzung. Wird die Stimme eine Weile nicht gebraucht, gibt sie den Speicher frei.
    private var nutzung = 0
    static let ruhezeit: Double = 120
    /// Im Sparmodus schon nach 30 Sekunden
    static var ruhezeitJetzt: Double {
        (UserDefaults.standard.bool(forKey: "sparmodus") || ProcessInfo.processInfo.isLowPowerModeEnabled) ? 30 : ruhezeit
    }

    /// Erzeugt die Tonspur. nil, wenn die Stimme fehlt oder nichts herauskam.
    func erzeuge(_ text: String, paket: GeraetePaket, sprecher: Int, tempo: Float,
                 wurzel: URL = StimmOrt.wurzel) async -> Ton? {
        await withCheckedContinuation { (fertig: CheckedContinuation<Ton?, Never>) in
            schlange.async {
                fertig.resume(returning: self.rechne(text, paket: paket, sprecher: sprecher,
                                                     tempo: tempo, wurzel: wurzel))
                self.spaeterFreigeben()
            }
        }
    }

    /// Lädt die Stimme schon vorher, damit der erste Satz ohne Wartezeit kommt.
    func vorbereiten(_ paket: GeraetePaket, wurzel: URL = StimmOrt.wurzel) {
        schlange.async {
            #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
            _ = self.motor(paket, wurzel: wurzel)
            #endif
            self.spaeterFreigeben()
        }
    }

    /// Gibt den Speicher frei, zum Beispiel wenn iOS knapp wird.
    func freigeben() {
        schlange.async {
            #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
            self.geladen = nil
            #endif
        }
    }

    /// Läuft in der Warteschlange. Kommt in der Ruhezeit kein neuer Satz, wird die Stimme entladen.
    private func spaeterFreigeben() {
        nutzung += 1
        let meine = nutzung
        schlange.asyncAfter(deadline: .now() + Self.ruhezeitJetzt) {
            guard self.nutzung == meine else { return }
            #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
            self.geladen = nil
            #endif
        }
    }

    private func rechne(_ text: String, paket: GeraetePaket, sprecher: Int, tempo: Float, wurzel: URL) -> Ton? {
        #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
        return autoreleasepool {
            guard let tts = motor(paket, wurzel: wurzel) else { return nil }
            let anzahl = max(Int(tts.numSpeakers), 1)
            let sid = sprecher < anzahl ? sprecher : 0
            let audio = tts.generate(text: text, sid: sid, speed: tempo)
            let proben = audio.samples
            guard !proben.isEmpty, audio.sampleRate > 0 else { return nil }
            return Ton(proben: proben, rate: Int(audio.sampleRate))
        }
        #else
        return nil
        #endif
    }

    #if canImport(SherpaOnnxShared) || canImport(SherpaOnnx)
    private func motor(_ paket: GeraetePaket, wurzel: URL) -> SherpaOnnxOfflineTtsWrapper? {
        if let g = geladen, g.id == paket.id { return g.tts }
        guard StimmOrt.installiert(paket, in: wurzel),
              StimmOrt.installiert(.aussprache, in: wurzel) else { return nil }
        geladen = nil
        let ordner = StimmOrt.ordner(paket, in: wurzel).path
        let aussprache = StimmOrt.ordner(.aussprache, in: wurzel).path
        return autoreleasepool {
            // Etwas mehr Zufall in Klang und Rhythmus als die Vorgabe (0,667 und 0,8),
            // dann betont die Stimme lebendiger und klingt weniger gleichförmig.
            let vits = sherpaOnnxOfflineTtsVitsModelConfig(
                model: ordner + "/stimme.onnx",
                lexicon: "",
                tokens: ordner + "/tokens.txt",
                dataDir: aussprache,
                noiseScale: 0.8,
                noiseScaleW: 1.0)
            let modell = sherpaOnnxOfflineTtsModelConfig(vits: vits, numThreads: 2, debug: 0, provider: "cpu")
            var einstellung = sherpaOnnxOfflineTtsConfig(model: modell)
            let tts = SherpaOnnxOfflineTtsWrapper(config: &einstellung)
            guard tts.tts != nil else { return nil }
            geladen = (paket.id, tts)
            return tts
        }
    }
    #endif
}
