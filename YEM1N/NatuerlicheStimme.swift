import SwiftUI
import UIKit
import AVFoundation
import CryptoKit

// ============================================================
// MARK: - Natürliche Stimmen: die Gerätestimme
// ============================================================
//
// Reihenfolge beim Vorlesen:
// 1. Die Gerätestimme (Thorsten, Fahrettin oder Cori), wenn sie geladen ist.
// 2. Sonst wie bisher die iOS-Stimme.
// Alles läuft auf dem Gerät. Nur das einmalige Laden einer Gerätestimme braucht Internet.

enum NatuerlicheStimme {
    static let key = "natuerlicheStimme"

    static var an: Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }

    /// Normales Tempo. Langsamer klang lustlos.
    static let tempo: Float = 1.0
    /// Für Lob: etwas heller und schneller abgespielt
    static let froh: Float = 1.07
}

// MARK: - Abspielen

/// Spielt die Tonspuren der Gerätestimme ab. Für das Haustier läuft
/// der Ton etwas schneller, dann klingt es hell und klein. Normal geht der Ton
/// unverändert durch, ohne Effekt, damit nichts hallt oder blechern klingt.
final class StimmAbspieler {
    static let shared = StimmAbspieler()

    private let engine = AVAudioEngine()
    private let spieler = AVAudioPlayerNode()
    private let hoehe = AVAudioUnitVarispeed()
    private var format: AVAudioFormat?

    init() {
        engine.attach(spieler)
        engine.attach(hoehe)
        // Kopfhörer ab, Anruf vorbei: iOS baut die Verbindungen neu, dann neu verbinden
        NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.format = nil }
        }
    }

    private func bereit(fuer f: AVAudioFormat) -> Bool {
        if let format, format == f, engine.isRunning { return true }
        spieler.stop()
        engine.stop()
        engine.disconnectNodeOutput(spieler)
        engine.disconnectNodeOutput(hoehe)
        engine.connect(spieler, to: hoehe, format: f)
        engine.connect(hoehe, to: engine.mainMixerNode, format: f)
        engine.prepare()
        do {
            try engine.start()
        } catch {
            format = nil
            return false
        }
        format = f
        return true
    }

    private func stelle(_ tonhoehe: Float) {
        let t = min(max(tonhoehe, 0.5), 2.0)
        // Höher und schneller zugleich, wie ein schneller abgespieltes Band
        hoehe.rate = t
        hoehe.bypass = abs(t - 1) < 0.01
    }

    @discardableResult
    func spiele(_ puffer: AVAudioPCMBuffer, tonhoehe: Float) -> Bool {
        guard bereit(fuer: puffer.format) else { return false }
        stelle(tonhoehe)
        spieler.stop()
        spieler.scheduleBuffer(puffer, completionHandler: nil)
        spieler.play()
        return true
    }

    func still() {
        if engine.isRunning { spieler.stop() }
    }

    static func puffer(_ ton: GeraeteStimmeMotor.Ton) -> AVAudioPCMBuffer? {
        guard !ton.proben.isEmpty,
              let f = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(ton.rate),
                                    channels: 1, interleaved: false),
              let p = AVAudioPCMBuffer(pcmFormat: f, frameCapacity: AVAudioFrameCount(ton.proben.count)),
              let ziel = p.floatChannelData?[0] else { return nil }
        ton.proben.withUnsafeBufferPointer { quelle in
            if let anfang = quelle.baseAddress { ziel.update(from: anfang, count: quelle.count) }
        }
        p.frameLength = AVAudioFrameCount(ton.proben.count)
        return p
    }
}

// MARK: - Vorlesen mit der Gerätestimme

/// Merkt sich die letzten Sätze, damit der Lautsprecher-Knopf beim zweiten Mal sofort spricht.
final class GeraeteVorleser {
    static let shared = GeraeteVorleser()

    private var zwischen: [String: AVAudioPCMBuffer] = [:]
    private var reihenfolge: [String] = []
    private let behalten = 40

    /// true, wenn gesprochen wurde oder nicht mehr gesprochen werden soll.
    /// false, wenn die Gerätestimme nichts liefern konnte.
    func sprich(_ text: String, paket: GeraetePaket, stimmung: SprechStimmung, tonhoehe: Float,
                nochGueltig: @escaping () -> Bool) async -> Bool {
        let satz = VorleseText.gesprochen(text)
        guard !satz.isEmpty else { return true }
        let sprecher = paket.sprecher(stimmung)
        let schluessel = paket.id + "|\(sprecher)|" + satz
        if let p = zwischen[schluessel] {
            return nochGueltig() ? StimmAbspieler.shared.spiele(p, tonhoehe: tonhoehe) : true
        }
        guard let ton = await GeraeteStimmeMotor.shared.erzeuge(satz, paket: paket, sprecher: sprecher,
                                                                tempo: NatuerlicheStimme.tempo),
              let p = StimmAbspieler.puffer(ton) else { return false }
        merke(schluessel, p)
        guard nochGueltig() else { return true }
        return StimmAbspieler.shared.spiele(p, tonhoehe: tonhoehe)
    }

    func vergiss() {
        zwischen.removeAll()
        reihenfolge.removeAll()
    }

    private func merke(_ k: String, _ p: AVAudioPCMBuffer) {
        if zwischen[k] == nil { reihenfolge.append(k) }
        zwischen[k] = p
        while reihenfolge.count > behalten {
            zwischen[reihenfolge.removeFirst()] = nil
        }
    }
}

// MARK: - Laden der Gerätestimmen

/// Meldet beim Laden, wie weit es ist.
nonisolated final class LadeBote: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    private let melde: @Sendable (Double) -> Void
    private var beobachter: NSKeyValueObservation?
    private var zuletzt = -1.0

    init(melde: @escaping @Sendable (Double) -> Void) {
        self.melde = melde
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        beobachter = task.progress.observe(\.fractionCompleted, options: [.new]) { [weak self] p, _ in
            guard let self else { return }
            let wert = p.fractionCompleted
            if wert - self.zuletzt >= 0.01 || wert >= 1 {
                self.zuletzt = wert
                self.melde(wert)
            }
        }
    }
}

@Observable
final class GeraeteStimmen {
    static let shared = GeraeteStimmen()

    enum Zustand: Equatable {
        case fehlt
        case laedt(Double)
        case prueft
        case fertig
        case fehler(String)
    }

    private(set) var zustaende: [String: Zustand] = [:]
    @ObservationIgnored private var aufgaben: [String: Task<Void, Never>] = [:]

    init() {
        StimmOrt.aufraeumen()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main
        ) { _ in
            GeraeteStimmeMotor.shared.freigeben()
            MainActor.assumeIsolated { GeraeteVorleser.shared.vergiss() }
        }
    }

    func zustand(_ p: GeraetePaket) -> Zustand {
        if let z = zustaende[p.id] { return z }
        return StimmOrt.installiert(p) ? .fertig : .fehlt
    }

    /// Die geladene Gerätestimme für eine Sprache, wenn sie bereit ist.
    func bereit(_ sprache: String) -> GeraetePaket? {
        guard GeraeteStimmeMotor.eingebaut,
              let p = GeraetePaket.fuer(sprache: sprache),
              aufgaben[p.id] == nil,
              StimmOrt.installiert(p),
              StimmOrt.installiert(.aussprache) else { return nil }
        return p
    }

    func laden(_ p: GeraetePaket) {
        guard aufgaben[p.id] == nil else { return }
        zustaende[p.id] = .laedt(0)
        aufgaben[p.id] = Task {
            do {
                if !StimmOrt.installiert(.aussprache) {
                    try await hole(.aussprache, anzeige: p)
                }
                try await hole(p, anzeige: p)
                zustaende[p.id] = .fertig
                GeraeteStimmeMotor.shared.vorbereiten(p)
            } catch {
                zustaende[p.id] = Task.isCancelled ? .fehlt : .fehler(Self.text(error))
            }
            aufgaben[p.id] = nil
        }
    }

    /// Neuer Stand beim Laden, nur solange noch geladen wird
    func melde(_ id: String, _ anteil: Double) {
        guard case .laedt = zustaende[id] ?? .fehlt else { return }
        zustaende[id] = .laedt(anteil)
    }

    func abbrechen(_ p: GeraetePaket) {
        aufgaben[p.id]?.cancel()
    }

    func loeschen(_ p: GeraetePaket) {
        GeraeteStimmeMotor.shared.freigeben()
        GeraeteVorleser.shared.vergiss()
        StimmOrt.entfernen(p)
        // Ohne Stimme braucht es auch die Aussprachedaten nicht mehr
        if !GeraetePaket.stimmen.contains(where: { StimmOrt.installiert($0) }) {
            StimmOrt.entfernen(.aussprache)
        }
        zustaende[p.id] = .fehlt
    }

    private func hole(_ p: GeraetePaket, anzeige: GeraetePaket) async throws {
        guard let url = p.url else { throw TarAuspacker.Fehler(text: "Die Adresse der Stimme fehlt.") }
        let id = anzeige.id
        let zeigtFortschritt = p.id == anzeige.id
        let bote = LadeBote { anteil in
            guard zeigtFortschritt else { return }
            Task { @MainActor in
                GeraeteStimmen.shared.melde(id, anteil)
            }
        }
        let (datei, antwort) = try await URLSession.shared.download(from: url, delegate: bote)
        if let http = antwort as? HTTPURLResponse, http.statusCode != 200 {
            try? FileManager.default.removeItem(at: datei)
            throw TarAuspacker.Fehler(text: "Der Server hat die Stimme nicht geliefert (Fehler \(http.statusCode)).")
        }
        // Gleich an einen eigenen Platz, die geladene Datei räumt iOS sonst bald weg
        let eigene = FileManager.default.temporaryDirectory.appendingPathComponent(p.id + ".tar")
        try? FileManager.default.removeItem(at: eigene)
        try FileManager.default.moveItem(at: datei, to: eigene)
        if zeigtFortschritt { zustaende[id] = .prueft }
        try await Task.detached(priority: .userInitiated) {
            defer { try? FileManager.default.removeItem(at: eigene) }
            try GeraeteStimmen.pruefe(eigene, p)
            try StimmOrt.einrichten(p, aus: eigene)
        }.value
    }

    /// Stimmt die Datei Byte für Byte? Größe und SHA-256 stehen fest im Paket.
    nonisolated static func pruefe(_ datei: URL, _ p: GeraetePaket) throws {
        let werte = try FileManager.default.attributesOfItem(atPath: datei.path)
        let groesse = (werte[.size] as? NSNumber)?.intValue ?? -1
        guard groesse == p.bytes else {
            throw TarAuspacker.Fehler(text: "Die Stimme ist nicht vollständig angekommen. Bitte noch einmal laden.")
        }
        let lesen = try FileHandle(forReadingFrom: datei)
        defer { try? lesen.close() }
        var summe = SHA256()
        while let stueck = try lesen.read(upToCount: 1 << 20), !stueck.isEmpty {
            summe.update(data: stueck)
        }
        let hex = summe.finalize().map { String(format: "%02x", $0) }.joined()
        guard hex == p.sha256 else {
            throw TarAuspacker.Fehler(text: "Die geladene Stimme ist beschädigt. Bitte noch einmal laden.")
        }
    }

    private static func text(_ fehler: Error) -> String {
        if let f = fehler as? TarAuspacker.Fehler { return f.text }
        if let u = fehler as? URLError {
            switch u.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "Kein Internet. Bitte im WLAN noch einmal versuchen."
            case .timedOut:
                return "Das Laden hat zu lange gedauert. Bitte noch einmal versuchen."
            default:
                return "Laden hat nicht geklappt. Bitte später noch einmal versuchen."
            }
        }
        return "Laden hat nicht geklappt: \(fehler.localizedDescription)"
    }
}

// MARK: - Abschnitt in den Vorlese-Stimmen

struct NatuerlicheStimmenAbschnitt: View {
    let hintergrund: Color
    @AppStorage(NatuerlicheStimme.key) private var an = true
    private let stimmen = GeraeteStimmen.shared

    var body: some View {
        Section {
            Toggle(isOn: $an) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Natürliche Stimmen").foregroundStyle(Color.white)
                    Text("Gerätestimme statt der iOS-Stimme, wenn sie geladen ist")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
            }
            .tint(Theme.gelb)

            if an {
                if GeraeteStimmeMotor.eingebaut {
                    ForEach(GeraetePaket.stimmen) { p in
                        zeile(p)
                    }
                } else {
                    Text("Gerätestimmen sind in dieser App-Fassung noch nicht eingebaut.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                }
            }
        } header: {
            Text("Natürliche Stimmen")
        } footer: {
            Text("Die Gerätestimme liest Vorschule, Mathe, Lernwelt, Sprachen, Olli und das Haustier vor, auch ohne Internet. Jede Sprache hat ihre eigene Stimme. Sie wird einmal von GitHub geladen, am besten im WLAN. Dabei werden keine Daten aus der App gesendet.")
        }
        .listRowBackground(hintergrund)
    }

    private func flagge(_ p: GeraetePaket) -> String {
        switch p.sprache {
        case "tr": return "🇹🇷"
        case "en": return "🇬🇧"
        default: return "🇩🇪"
        }
    }

    private func untertitel(_ p: GeraetePaket, _ z: GeraeteStimmen.Zustand) -> String {
        let sprache: String
        switch p.sprache {
        case "tr": sprache = "Türkisch"
        case "en": sprache = "Englisch"
        default: sprache = "Deutsch"
        }
        switch z {
        case .fehlt: return "\(sprache) · \(p.megabyte) MB laden"
        case .laedt(let a): return "Lädt \(Int(a * 100)) %"
        case .prueft: return "Wird eingerichtet ..."
        case .fertig: return "\(sprache) · Geladen, liest offline"
        case .fehler(let t): return t
        }
    }

    private func farbe(_ z: GeraeteStimmen.Zustand) -> Color {
        switch z {
        case .fertig: return .green
        case .fehler: return .red
        default: return Theme.textSanft
        }
    }

    @ViewBuilder
    private func zeile(_ p: GeraetePaket) -> some View {
        let z = stimmen.zustand(p)
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(flagge(p)) \(p.name)").foregroundStyle(Color.white)
                Text(untertitel(p, z))
                    .font(.footnote)
                    .foregroundStyle(farbe(z))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            switch z {
            case .fehlt, .fehler:
                Button("Laden") { stimmen.laden(p) }
                    .buttonStyle(.borderless)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.gelb)
            case .laedt(let anteil):
                ProgressView(value: anteil)
                    .tint(Theme.gelb)
                    .frame(width: 70)
                Button {
                    stimmen.abbrechen(p)
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textSanft)
                }
                .buttonStyle(.borderless)
            case .prueft:
                ProgressView().tint(Theme.gelb)
            case .fertig:
                Button {
                    Sprecher.shared.probeGeraet(p)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.gelb)
                }
                .buttonStyle(.borderless)
                Button {
                    stimmen.loeschen(p)
                } label: {
                    Image(systemName: "trash").foregroundStyle(Color.red)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
