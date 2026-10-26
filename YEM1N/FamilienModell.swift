import Foundation
import Observation

// ============================================================
// MARK: - Die Familie dieses Geräts
// ============================================================
//
// Wer gehört dazu, welche Geräte warten, und alles, was über den Familien-Dienst geht
// (Protokoll 2, siehe cloud/PROTOKOLL-V2.md). Die Zustände sind für die Oberfläche lesbar.
// Die Funktionen laufen auf dem Hauptthread, das Warten auf das Netz geschieht im Client.

@MainActor
@Observable
final class FamilienModell {
    static let shared = FamilienModell()

    // MARK: Zustand

    /// nil, solange das Gerät zu keiner Familie gehört.
    private(set) var zugang: FamilienZugang?
    /// Die Geräte der Familie (nur für Eltern gefüllt).
    private(set) var geraete: [FamilienGeraet] = []
    /// Die letzte Einladung, solange sie noch gilt.
    private(set) var einladung: FamilienEinladung?
    var meldung = ""
    private(set) var beschaeftigt = false

    /// Das Gerät gehört zur Familie und ist freigegeben. Nur dann gehen Nachrichten hin und her.
    var aktiv: Bool { zugang?.aktiv == true }
    var wartet: Bool { zugang?.wartet == true }
    var abgelehnt: Bool { zugang?.status == "abgelehnt" }
    var istEltern: Bool { zugang.map { $0.aktiv && $0.istEltern } ?? false }
    var istKind: Bool { zugang.map { $0.aktiv && !$0.istEltern } ?? false }

    @ObservationIgnored private let vorgaben: UserDefaults
    @ObservationIgnored private let client: FamilienClient
    @ObservationIgnored private let schluessel: GeraetSchluessel

    static let zugangSchluessel = "familieZugang"
    private static let versatzSchluessel = "familieVersatz"
    private static let pinSalz = "elternPinSalz"
    private static let pinHash = "elternPinHash"
    private static let pinFehler = "elternPinFehler"
    private static let pinSperreBis = "elternPinSperreBis"
    private static let pushTokenSchluessel = "apnsToken"
    private static let pushAngemeldetSchluessel = "apnsAngemeldet"

    init(vorgaben: UserDefaults = .standard,
         schluessel: GeraetSchluessel = .shared,
         leitung: FamilienLeitung = FamilienNetz.shared) {
        self.vorgaben = vorgaben
        self.schluessel = schluessel
        self.client = FamilienClient(leitung: leitung, signierer: schluessel)
        self.pinGesetzt = !(vorgaben.string(forKey: Self.pinHash) ?? "").isEmpty
        if let d = vorgaben.data(forKey: Self.zugangSchluessel),
           let z = try? JSONDecoder().decode(FamilienZugang.self, from: d) {
            if schluessel.vorhanden {
                self.zugang = z
            } else {
                // Zum Beispiel nach dem Wechsel auf ein neues iPhone: Der Schlüssel bleibt im alten Gerät.
                vergessenOhneNetz()
                self.meldung = "Dieses Gerät muss neu mit der Familie verbunden werden."
            }
        }
        let v = Int64(vorgaben.integer(forKey: Self.versatzSchluessel))
        if v != 0 {
            let c = client
            Task { await c.versatzSetzen(v) }
        }
    }

    // MARK: Speichern

    private func setzeZugang(_ z: FamilienZugang?) {
        zugang = z
        if let z, let d = try? JSONEncoder().encode(z) {
            vorgaben.set(d, forKey: Self.zugangSchluessel)
        } else {
            vorgaben.removeObject(forKey: Self.zugangSchluessel)
            // Ohne Familie gibt es nichts zu schützen, die PIN fällt mit weg.
            pinLoeschen()
            vorgaben.removeObject(forKey: Self.pushAngemeldetSchluessel)
        }
    }

    private func vergessenOhneNetz() {
        vorgaben.removeObject(forKey: Self.zugangSchluessel)
        pinLoeschen()
        vorgaben.removeObject(forKey: Self.pushAngemeldetSchluessel)
    }

    /// Die Familie ist weg oder dieses Gerät wurde entfernt: alles vergessen, auch den Schlüssel.
    private func vergessen(_ text: String) {
        setzeZugang(nil)
        schluessel.loeschen()
        geraete = []
        einladung = nil
        meldung = text
    }

    private func versatzMerken() async {
        let v = await client.versatz
        if vorgaben.integer(forKey: Self.versatzSchluessel) != Int(v) {
            vorgaben.set(Int(v), forKey: Self.versatzSchluessel)
        }
    }

    private func signiert(_ pfad: String, _ objekt: [String: Any] = [:]) async -> FamilienAntwort {
        guard let z = zugang else { return FamilienAntwort(status: -3, json: nil) }
        let a = await client.signiert(z, pfad: pfad, body: FamilienJson.schreibe(objekt))
        await versatzMerken()
        return a
    }

    // MARK: Eltern-PIN

    /// Gibt es auf diesem Gerät eine Eltern-PIN?
    private(set) var pinGesetzt: Bool = false
    @ObservationIgnored private var entsperrtBis: Date = .distantPast
    /// Zählt hoch, wenn die Entsperrung abläuft, damit die Oberfläche neu zeichnet.
    private(set) var ablaufZaehler = 0
    @ObservationIgnored private var ablaufAufgabe: Task<Void, Never>?

    /// Der Bereich der Eltern ist gerade offen (nach der richtigen PIN, kurze Zeit).
    var entsperrt: Bool {
        _ = ablaufZaehler
        return Date.now < entsperrtBis
    }

    private func entsperren() {
        entsperrtBis = Date.now.addingTimeInterval(ElternPin.offenSekunden)
        ablaufAufgabe?.cancel()
        ablaufAufgabe = Task { [weak self] in
            try? await Task.sleep(for: .seconds(ElternPin.offenSekunden + 0.5))
            guard !Task.isCancelled else { return }
            self?.ablaufZaehler += 1
        }
        ablaufZaehler += 1
    }

    /// Schließt den Bereich der Eltern sofort wieder.
    func sperren() {
        entsperrtBis = .distantPast
        ablaufAufgabe?.cancel()
        ablaufZaehler += 1
    }

    /// Wer im Bereich der Eltern etwas tut (zum Beispiel den Reiter wechselt), hält ihn weitere fünf Minuten offen.
    func verlaengern() {
        if entsperrt { entsperren() }
    }

    /// Prüft beim Zurückkehren in die App, ob die Zeit schon um ist.
    func ablaufPruefen() {
        if !entsperrt { ablaufZaehler += 1 }
    }

    /// Legt die PIN fest und öffnet den Bereich. Gibt einen Fehlertext zurück oder nil.
    func pinSetzen(_ pin: String, wiederholt: String) -> String? {
        if !ElternPin.gueltig(pin) { return "Die PIN besteht aus 4 bis 8 Ziffern." }
        if pin != wiederholt { return "Die beiden PINs sind nicht gleich." }
        if ElternPin.zuLeicht(pin) { return "Bitte keine PIN wie 1234 oder 0000. Das erraten Kinder schnell." }
        var zufall = [UInt8](repeating: 0, count: 16)
        for i in zufall.indices { zufall[i] = UInt8.random(in: 0...255) }
        let salz = ElternPin.salz(zufall)
        vorgaben.set(salz, forKey: Self.pinSalz)
        vorgaben.set(ElternPin.hash(pin, salz: salz), forKey: Self.pinHash)
        vorgaben.set(0, forKey: Self.pinFehler)
        vorgaben.set(0.0, forKey: Self.pinSperreBis)
        pinGesetzt = true
        entsperren()
        return nil
    }

    /// Prüft die PIN. Gibt einen Text für die Oberfläche zurück oder nil, wenn sie stimmt (dann ist der Bereich offen).
    func pinPruefen(_ pin: String) -> String? {
        let jetzt = Date.now.timeIntervalSince1970
        let sperreBis = vorgaben.double(forKey: Self.pinSperreBis)
        if jetzt < sperreBis { return ElternPin.sperreText(sperreBis - jetzt) }
        let salz = vorgaben.string(forKey: Self.pinSalz) ?? ""
        let hash = vorgaben.string(forKey: Self.pinHash) ?? ""
        if ElternPin.stimmt(pin, salz: salz, hash: hash) {
            vorgaben.set(0, forKey: Self.pinFehler)
            entsperren()
            return nil
        }
        let fehler = vorgaben.integer(forKey: Self.pinFehler) + 1
        vorgaben.set(fehler, forKey: Self.pinFehler)
        let warten = ElternPin.sperreSekunden(fehler)
        if warten > 0 {
            vorgaben.set(jetzt + warten, forKey: Self.pinSperreBis)
            return "Falsche PIN. " + ElternPin.sperreText(warten)
        }
        return "Falsche PIN."
    }

    private func pinLoeschen() {
        for k in [Self.pinSalz, Self.pinHash, Self.pinFehler, Self.pinSperreBis] { vorgaben.removeObject(forKey: k) }
        pinGesetzt = false
        entsperrtBis = .distantPast
    }

    // MARK: Familie anlegen und beitreten

    /// Legt eine neue Familie an. Dieses Gerät wird das erste Eltern-Gerät. Gibt einen Fehlertext zurück oder nil.
    func anlegen(name: String) async -> String? {
        beschaeftigt = true
        defer { beschaeftigt = false }
        guard schluessel.neuErzeugen() else { return FamilienProtokoll.fehlertext(-1) }
        let a = await client.anlegen(name: name)
        await versatzMerken()
        if !a.ok || a.text("familie").isEmpty {
            schluessel.loeschen()
            return a.fehler
        }
        setzeZugang(FamilienZugang(familie: a.text("familie"), geraet: a.text("geraet"), name: name,
                                   rolle: "eltern", status: "aktiv"))
        meldung = ""
        return nil
    }

    /// Tritt einer Familie mit dem Text aus dem QR-Code bei. Danach wartet das Gerät auf die Freigabe der Eltern.
    /// [erwarteteRolle] ist "eltern" oder "kind", wenn schon klar ist, was dieses Gerät sein soll.
    func koppeln(qrText: String, name: String, erwarteteRolle: String? = nil) async -> String? {
        guard let (familie, token) = FamilienProtokoll.qrLesen(qrText) else {
            return "Das ist kein QR-Code zum Verbinden. Bitte auf dem Gerät der Eltern einen neuen anzeigen."
        }
        beschaeftigt = true
        defer { beschaeftigt = false }
        guard schluessel.neuErzeugen() else { return FamilienProtokoll.fehlertext(-1) }
        let a = await client.koppeln(familie: familie, token: token, name: name)
        await versatzMerken()
        if !a.ok || a.text("geraet").isEmpty {
            schluessel.loeschen()
            if a.status == 403 { return "Dieser QR-Code gilt nicht mehr. Bitte auf dem Gerät der Eltern einen neuen anzeigen." }
            return a.fehler
        }
        let rolle = a.text("rolle").isEmpty ? "kind" : a.text("rolle")
        let z = FamilienZugang(familie: familie, geraet: a.text("geraet"), name: name, rolle: rolle,
                               status: a.text("status").isEmpty ? "wartet" : a.text("status"))
        setzeZugang(z)
        if let erwartet = erwarteteRolle, erwartet != rolle {
            // Falscher Einladungstyp: gleich wieder austreten, damit nichts Falsches wartet.
            _ = await verlassen(eintraegeLoeschen: false)
            return erwartet == "eltern"
                ? "Dieser QR-Code ist für ein Kind-Gerät. Bitte auf dem Gerät der Eltern eine Einladung für ein Eltern-Gerät anzeigen."
                : "Dieser QR-Code ist für ein Eltern-Gerät. Bitte auf dem Gerät der Eltern eine Einladung für ein Kind anzeigen."
        }
        meldung = ""
        return nil
    }

    /// Fragt den Stand dieses Geräts ab (wartet, aktiv, abgelehnt). Gibt true zurück, wenn sich etwas geändert hat.
    @discardableResult
    func statusPruefen() async -> Bool {
        guard let z = zugang else { return false }
        let a = await signiert(FamilienProtokoll.pfadStatus)
        if a.status == 401 || a.status == 404 {
            vergessen("Dieses Gerät gehört nicht mehr zur Familie. Bitte neu verbinden.")
            return true
        }
        guard a.ok else { return false }
        let neu = a.text("status").isEmpty ? z.status : a.text("status")
        let rolle = a.text("rolle").isEmpty ? z.rolle : a.text("rolle")
        if neu == z.status && rolle == z.rolle { return false }
        var n = z
        n.status = neu
        n.rolle = rolle
        setzeZugang(n)
        return true
    }

    // MARK: Eltern: Einladung und Geräte

    func einladungErzeugen(rolle: String) async -> String? {
        guard let z = zugang else { return FamilienProtokoll.fehlertext(401) }
        beschaeftigt = true
        defer { beschaeftigt = false }
        let a = await signiert(FamilienProtokoll.pfadEinladung, ["rolle": rolle])
        guard a.ok else {
            return a.status == 429 ? "Es gibt schon fünf offene Einladungen. Bitte ein paar Minuten warten." : a.fehler
        }
        einladung = FamilienEinladung(familie: z.familie, rolle: rolle, token: a.text("token"), bis: a.zahl("bis"))
        return nil
    }

    func einladungSchliessen() { einladung = nil }

    @discardableResult
    func geraeteLaden() async -> Bool {
        guard istEltern else { return false }
        let a = await signiert(FamilienProtokoll.pfadGeraete)
        guard a.ok, let j = a.json else {
            if a.status == 401 || a.status == 404 { await statusPruefen() }
            return false
        }
        geraete = FamilienProtokoll.geraete(j)
        return true
    }

    private func geraetAktion(_ pfad: String, _ id: String) async -> String? {
        beschaeftigt = true
        defer { beschaeftigt = false }
        let a = await signiert(pfad, ["geraet": id])
        guard a.ok else { return a.status == 409 ? "Das Gerät wartet nicht mehr auf eine Freigabe." : a.fehler }
        await geraeteLaden()
        return nil
    }

    func erlauben(_ id: String) async -> String? { await geraetAktion(FamilienProtokoll.pfadErlauben, id) }
    func ablehnen(_ id: String) async -> String? { await geraetAktion(FamilienProtokoll.pfadAblehnen, id) }
    func entfernen(_ id: String) async -> String? { await geraetAktion(FamilienProtokoll.pfadEntfernen, id) }

    // MARK: Verlassen und löschen

    /// Dieses Gerät verlässt die Familie. Ein Kind kann seine Einträge mitnehmen (löschen lassen).
    /// Ein Gerät, das noch wartet oder abgelehnt wurde, geht immer: der Dienst räumt solche Geräte selbst auf.
    func verlassen(eintraegeLoeschen: Bool) async -> String? {
        let nochNichtAktiv = zugang?.aktiv == false
        beschaeftigt = true
        defer { beschaeftigt = false }
        await pushAbmelden()
        let a = await signiert(FamilienProtokoll.pfadAustreten, ["eintraegeLoeschen": eintraegeLoeschen])
        if !a.ok && !nochNichtAktiv && a.status != 401 && a.status != 404 {
            return a.status == 409
                ? "Das ist das letzte Eltern-Gerät. Löscht stattdessen die ganze Familie."
                : a.fehler
        }
        vergessen("")
        return nil
    }

    /// Löscht die ganze Familie mit allen Einträgen. Nur Eltern.
    func familieLoeschen() async -> String? {
        beschaeftigt = true
        defer { beschaeftigt = false }
        let a = await signiert(FamilienProtokoll.pfadLoeschen, ["bestaetigung": "LOESCHEN"])
        if !a.ok && a.status != 404 { return a.fehler }
        vergessen("")
        return nil
    }

    /// Nur auf diesem Gerät vergessen (zum Beispiel beim Widerruf der Einwilligung). Die Familie bleibt bestehen.
    func lokalVergessen() { vergessen("") }

    /// Prüft die Verbindung und gibt einen Satz für die Oberfläche zurück.
    func verbindungTesten() async -> String {
        guard zugang != nil else { return "Dieses Gerät gehört zu keiner Familie." }
        let a = await signiert(FamilienProtokoll.pfadStatus)
        if a.keineVerbindung { return "Keine Verbindung zum Familien-Dienst. Bist du online?" }
        if a.status == 401 || a.status == 404 {
            await statusPruefen()
            return meldung.isEmpty ? a.fehler : meldung
        }
        guard a.ok else { return a.fehler }
        switch a.text("status") {
        case "aktiv": return "Die Verbindung steht. Dieses Gerät ist freigegeben."
        case "wartet": return "Die Verbindung steht. Dieses Gerät wartet noch auf die Freigabe der Eltern."
        default: return "Die Verbindung steht. Die Eltern haben dieses Gerät nicht freigegeben."
        }
    }

    // MARK: Nachrichten

    /// Legt einen Eintrag ab. [body] kommt aus `FamilienProtokoll`.
    func senden(_ body: [String: Any]) async -> FamilienAntwort {
        guard aktiv else { return FamilienAntwort(status: -3, json: nil) }
        return await signiert(FamilienProtokoll.pfadSenden, body)
    }

    /// Liest alle Einträge einer Art, in höchstens [maxSeiten] Seiten. nil, wenn schon die erste Seite fehlt.
    func lesen(_ typ: String, maxSeiten: Int = 5) async -> [FamilienEintrag]? {
        guard aktiv else { return nil }
        var seit: Int64 = 0
        var alle: [FamilienEintrag] = []
        for seite in 0..<maxSeiten {
            let a = await signiert(FamilienProtokoll.pfadLesen, FamilienProtokoll.lesen(typ, seit: seit, limit: 200))
            guard a.ok, let j = a.json else { return seite == 0 ? nil : alle }
            alle += FamilienProtokoll.eintraege(j)
            guard let weiter = FamilienProtokoll.weiterAb(j) else { break }
            seit = weiter
        }
        return alle
    }

    // MARK: Mitteilungen

    /// Merkt sich die Kennung von Apple. Ist das Gerät in der Familie, geht sie gleich an den Dienst.
    func pushTokenMerken(_ hex: String) {
        vorgaben.set(hex, forKey: Self.pushTokenSchluessel)
        vorgaben.removeObject(forKey: Self.pushAngemeldetSchluessel)
        Task { await pushAnmelden() }
    }

    /// Die Kennung dieses Geräts ist beim Dienst angemeldet.
    var pushAngemeldet: Bool { !(vorgaben.string(forKey: Self.pushAngemeldetSchluessel) ?? "").isEmpty }

    static var pushUmgebung: String {
        #if DEBUG
        return "sandbox"
        #else
        return "production"
        #endif
    }

    /// Meldet die Kennung dieses Geräts beim Dienst an, wenn das noch nicht geschehen ist.
    func pushAnmelden() async {
        guard aktiv, let token = vorgaben.string(forKey: Self.pushTokenSchluessel), !token.isEmpty else { return }
        let marke = token + "|" + Self.pushUmgebung + "|" + (zugang?.geraet ?? "")
        if vorgaben.string(forKey: Self.pushAngemeldetSchluessel) == marke { return }
        let a = await signiert(FamilienProtokoll.pfadPush, FamilienProtokoll.pushAnmelden(token: token, umgebung: Self.pushUmgebung))
        if a.ok { vorgaben.set(marke, forKey: Self.pushAngemeldetSchluessel) }
    }

    func pushAbmelden() async {
        guard aktiv else { return }
        _ = await signiert(FamilienProtokoll.pfadPush, FamilienProtokoll.pushAbmelden())
        vorgaben.removeObject(forKey: Self.pushAngemeldetSchluessel)
    }
}
