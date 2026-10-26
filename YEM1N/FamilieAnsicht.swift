import SwiftUI
import UIKit

// ============================================================
// MARK: - Familie: verbinden, Geräte, Einladung
// ============================================================
//
// Eine Familie hat bei YEM1N ein eigenes, abgetrenntes Fach (Protokoll 2). Neue Geräte kommen nur mit einem
// QR-Code der Eltern dazu und müssen von einem Eltern-Gerät erlaubt werden. Der Prüfcode zeigt, ob es das richtige
// Gerät ist. Die Logik steckt in `FamilienModell`, hier ist nur die Oberfläche.

private func rolleText(_ rolle: String) -> String { rolle == "eltern" ? "Eltern" : "Kind" }

private struct FamilienKarte<Inhalt: View>: View {
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            inhalt()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glasKarte(radius: 24)
    }
}

private struct FamilienTitel: View {
    let text: String
    var farbe: Color = Theme.gelb

    var body: some View {
        Text(text)
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .foregroundStyle(farbe)
    }
}

private struct FamilienKnopf: View {
    let titel: String
    var gelb = true
    var aktiv = true
    let aktion: () -> Void

    var body: some View {
        Button(action: aktion) {
            Text(titel)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(gelb ? Theme.navy : Color.white)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(gelb ? Theme.gelb : Color.white.opacity(0.14), in: Capsule())
        }
        .buttonStyle(TastenStil())
        .disabled(!aktiv)
        .opacity(aktiv ? 1 : 0.5)
    }
}

// MARK: Die Seite in den Einstellungen

struct FamilieAnsicht: View {
    @AppStorage("modus") private var modus = ""
    @AppStorage("kindName") private var kindName = ""
    private let familie = FamilienModell.shared
    @State private var name = ""
    @State private var verlassenOffen = false
    @State private var eintraegeMitnehmen = false
    @State private var loeschenOffen = false
    @State private var entfernenZiel: FamilienGeraet?
    @State private var geladen = false
    @State private var kopiert = false

    private var eltern: Bool { modus == "eltern" }

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let z = familie.zugang {
                        if familie.abgelehnt {
                            abgelehnt
                        } else if z.wartet {
                            wartet(z)
                        } else {
                            verbunden(z)
                        }
                    } else {
                        Text("Hier verbindest du dieses Gerät mit deiner Familie. Dann gehen Joker, Duelle, Ergebnisse und das Haustier hin und her. Ohne Familie bleibt alles nur auf diesem Gerät.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSanft)
                        FamilieVerbindenKarten(eltern: eltern, name: $name)
                    }
                    if !familie.meldung.isEmpty {
                        Text(familie.meldung)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Theme.koralle)
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Familie")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !geladen else { return }
            geladen = true
            name = eltern ? CloudDienst.ichName() : kindName.trimmingCharacters(in: .whitespaces)
        }
        .task(id: familie.zugang?.status ?? "keine") { await beobachten() }
        .sheet(isPresented: Binding(get: { familie.einladung != nil },
                                    set: { if !$0 { familie.einladungSchliessen() } })) {
            if let e = familie.einladung {
                EinladungSheet(einladung: e)
                    .preferredColorScheme(.dark)
                    .tint(Theme.gelb)
            }
        }
        .confirmationDialog("Gerät aus der Familie nehmen?", isPresented: $verlassenOffen, titleVisibility: .visible) {
            Button("Ja, Gerät entfernen", role: .destructive) {
                Task { _ = await familie.verlassen(eintraegeLoeschen: eintraegeMitnehmen && !eltern) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Danach gehen von diesem Gerät keine Fragen und Ergebnisse mehr an die Familie. Zum Wiederverbinden braucht es einen neuen QR-Code und die Freigabe der Eltern.")
        }
        .confirmationDialog("Ganze Familie löschen?", isPresented: $loeschenOffen, titleVisibility: .visible) {
            Button("Ja, alles löschen", role: .destructive) {
                Task { _ = await familie.familieLoeschen() }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Alle Fragen, Antworten, Ergebnisse, Duelle und das Haustier werden aus dem Familien-Fach gelöscht. Alle Geräte der Familie werden entfernt. Das geht nicht rückgängig.")
        }
        .confirmationDialog(entfernenZiel.map { "\($0.name) entfernen?" } ?? "Gerät entfernen?",
                            isPresented: Binding(get: { entfernenZiel != nil },
                                                 set: { if !$0 { entfernenZiel = nil } }),
                            titleVisibility: .visible) {
            Button("Ja, entfernen", role: .destructive) {
                if let g = entfernenZiel { Task { _ = await familie.entfernen(g.id) } }
                entfernenZiel = nil
            }
            Button("Abbrechen", role: .cancel) { entfernenZiel = nil }
        } message: {
            Text("Das Gerät gehört dann nicht mehr zur Familie. Zum Wiederverbinden braucht es einen neuen QR-Code.")
        }
    }

    /// Solange die Seite offen ist: ein wartendes Gerät fragt nach seiner Freigabe, ein Eltern-Gerät lädt die Geräteliste.
    private func beobachten() async {
        while !Task.isCancelled {
            if familie.wartet {
                await familie.statusPruefen()
            } else if familie.istEltern {
                await familie.geraeteLaden()
            }
            try? await Task.sleep(for: .seconds(5))
        }
    }

    // MARK: Zustände

    private func wartet(_ z: FamilienZugang) -> some View {
        FamilienKarte {
            Text("Fast geschafft!")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gelb)
            Text("Dieses Gerät wartet darauf, dass Mama oder Papa es erlaubt.")
                .font(.subheadline)
                .foregroundStyle(Color.white)
            Text("Prüfcode")
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
            Text(z.pruefcode)
                .font(.system(size: 38, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)
            Text("Dieser Code steht auch auf dem Eltern-Gerät in der Liste. Die Eltern erlauben nur, wenn er gleich ist.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
            HStack(spacing: 10) {
                FamilienKnopf(titel: "Nachsehen", gelb: false) { Task { await familie.statusPruefen() } }
                FamilienKnopf(titel: "Abbrechen", gelb: false) { Task { _ = await familie.verlassen(eintraegeLoeschen: false) } }
            }
        }
    }

    private var abgelehnt: some View {
        FamilienKarte {
            Text("Nicht erlaubt")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.koralle)
            Text("Die Eltern haben dieses Gerät nicht erlaubt. Wenn das ein Versehen war, bitte sie um einen neuen QR-Code.")
                .font(.subheadline)
                .foregroundStyle(Color.white)
            FamilienKnopf(titel: "OK") { Task { _ = await familie.verlassen(eintraegeLoeschen: false) } }
        }
    }

    @ViewBuilder
    private func verbunden(_ z: FamilienZugang) -> some View {
        FamilienKarte {
            Text("Dieses Gerät")
                .font(.caption)
                .foregroundStyle(Theme.textSanft)
            Text(z.name)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.white)
            Text("\(rolleText(z.rolle)), Prüfcode \(z.pruefcode)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.mint)
            Text("Dieses Gerät gehört zur Familie. Fragen, Duelle und fertige Runden gehen nur an die Familie.")
                .font(.footnote)
                .foregroundStyle(Theme.textSanft)
        }
        if z.istEltern {
            geraeteKarte(z)
            einladenKarte
        }
        FamilienKarte {
            FamilienTitel(text: "Verlassen und löschen", farbe: Color.white)
            if !z.istEltern {
                Toggle("Meine Einträge in der Cloud auch löschen", isOn: $eintraegeMitnehmen)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .tint(Theme.gelb)
            }
            FamilienKnopf(titel: "Dieses Gerät aus der Familie nehmen", gelb: false, aktiv: !familie.beschaeftigt) {
                verlassenOffen = true
            }
            if z.istEltern {
                FamilienKnopf(titel: kopiert ? "Kennung kopiert" : "Familien-Kennung kopieren", gelb: false) {
                    UIPasteboard.general.string = z.familie
                    kopiert = true
                }
                Text("Die Kennung brauchst du nur, wenn du mir wegen einer Löschung schreibst und kein Eltern-Gerät mehr hast. Gib sie sonst niemandem.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
                FamilienKnopf(titel: "Ganze Familie löschen", gelb: false, aktiv: !familie.beschaeftigt) {
                    loeschenOffen = true
                }
                Text("Löscht alle Einträge im Familien-Fach und entfernt alle Geräte. Das geht nicht rückgängig.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
        }
    }

    private func geraeteKarte(_ z: FamilienZugang) -> some View {
        FamilienKarte {
            FamilienTitel(text: "Geräte der Familie")
            if familie.geraete.isEmpty {
                Text("Noch keine Geräte geladen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            ForEach(familie.geraete) { g in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(g.id == z.geraet ? "\(g.name) (dieses Gerät)" : g.name)
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Text(rolleText(g.rolle))
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Theme.mint)
                    }
                    Text("Prüfcode \(FamilienProtokoll.pruefcode(g.id))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSanft)
                    if g.status == "wartet" {
                        Text("Wartet auf deine Freigabe. Ist der Prüfcode auf dem neuen Gerät genau gleich?")
                            .font(.footnote)
                            .foregroundStyle(Color.white)
                        HStack(spacing: 10) {
                            FamilienKnopf(titel: "Erlauben", aktiv: !familie.beschaeftigt) {
                                Task { _ = await familie.erlauben(g.id) }
                            }
                            FamilienKnopf(titel: "Ablehnen", gelb: false, aktiv: !familie.beschaeftigt) {
                                Task { _ = await familie.ablehnen(g.id) }
                            }
                        }
                    } else if g.id != z.geraet {
                        Button("Entfernen") { entfernenZiel = g }
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.koralle)
                            .disabled(familie.beschaeftigt)
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            FamilienKnopf(titel: "Neu laden", gelb: false) { Task { await familie.geraeteLaden() } }
        }
    }

    private var einladenKarte: some View {
        FamilienKarte {
            FamilienTitel(text: "Gerät hinzufügen")
            Text("Das neue Gerät scannt einen QR-Code. Danach erscheint es oben in der Liste und du erlaubst es. Der QR-Code gilt 10 Minuten und nur für ein Gerät.")
                .font(.footnote)
                .foregroundStyle(Color.white)
            HStack(spacing: 10) {
                FamilienKnopf(titel: "📱 Kind-Gerät", aktiv: !familie.beschaeftigt) { einladen("kind") }
                FamilienKnopf(titel: "👨‍👩‍👧 Eltern-Gerät", aktiv: !familie.beschaeftigt) { einladen("eltern") }
            }
        }
    }

    private func einladen(_ rolle: String) {
        Task {
            if let f = await familie.einladungErzeugen(rolle: rolle) {
                familie.meldung = f
            } else {
                familie.meldung = ""
            }
        }
    }
}

// MARK: Verbinden (auch für die Einrichtung)

/// "Neue Familie anlegen" (nur Eltern) und "QR-Code scannen", mit Namensfeld.
struct FamilieVerbindenKarten: View {
    let eltern: Bool
    @Binding var name: String
    private let familie = FamilienModell.shared
    @State private var zeigeScan = false
    @State private var fehler = ""

    private var sauberer: String {
        let n = FamilienProtokoll.kuerze(name.trimmingCharacters(in: .whitespacesAndNewlines), 24)
        return n.isEmpty ? (eltern ? "Eltern" : "Kind") : n
    }

    var body: some View {
        VStack(spacing: 14) {
            FamilienKarte {
                FamilienTitel(text: "Name dieses Geräts")
                TextField(eltern ? "Zum Beispiel Mama oder Papa" : "Vorname des Kindes", text: $name)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(12)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                Text(eltern ? "Unter diesem Namen erscheinen deine Antworten auf Joker-Fragen."
                            : "Ein Vorname oder Spitzname reicht, bitte keinen Nachnamen.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            if eltern {
                FamilienKarte {
                    FamilienTitel(text: "Ich lege die Familie an")
                    Text("Dieses Gerät wird das erste Eltern-Gerät. Danach fügst du die anderen Geräte mit einem QR-Code hinzu.")
                        .font(.footnote)
                        .foregroundStyle(Color.white)
                    FamilienKnopf(titel: familie.beschaeftigt ? "Einen Moment ..." : "Neue Familie anlegen",
                                  aktiv: !familie.beschaeftigt) {
                        fehler = ""
                        Task { fehler = await familie.anlegen(name: sauberer) ?? "" }
                    }
                }
            }
            FamilienKarte {
                FamilienTitel(text: eltern ? "Meine Familie gibt es schon" : "Mit dem QR-Code verbinden")
                Text(eltern
                     ? "Auf einem anderen Eltern-Gerät steht unter Einstellungen > Familie > Gerät hinzufügen ein QR-Code. Scanne ihn hier. Danach muss das andere Eltern-Gerät dieses Gerät noch erlauben."
                     : "Deine Eltern zeigen dir auf ihrem Gerät unter Einstellungen > Familie > Gerät hinzufügen einen QR-Code. Scanne ihn hier. Danach müssen deine Eltern dein Gerät noch erlauben.")
                    .font(.footnote)
                    .foregroundStyle(Color.white)
                FamilienKnopf(titel: "📷 QR-Code scannen", gelb: false, aktiv: !familie.beschaeftigt) {
                    fehler = ""
                    zeigeScan = true
                }
            }
            if !fehler.isEmpty {
                Text(fehler)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.koralle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $zeigeScan) {
            QRScanSheet { art, code in
                guard art == "koppeln" else {
                    fehler = "Das ist kein QR-Code zum Verbinden mit der Familie."
                    return
                }
                Task {
                    fehler = await familie.koppeln(qrText: code, name: sauberer,
                                                   erwarteteRolle: eltern ? "eltern" : "kind") ?? ""
                }
            }
            .preferredColorScheme(.dark)
            .tint(Theme.gelb)
        }
    }
}

// MARK: QR-Code der Einladung

struct EinladungSheet: View {
    let einladung: FamilienEinladung
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 18) {
                        Text(einladung.rolle == "eltern" ? "Neues Eltern-Gerät" : "Neues Kind-Gerät")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                        if let bild = QRPaket.bild(einladung.qr) {
                            Image(uiImage: bild)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .padding(16)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .frame(maxWidth: 300)
                                .accessibilityLabel("QR-Code zum Verbinden")
                        }
                        Text("Auf dem neuen Gerät unter Einstellungen > Familie auf QR-Code scannen tippen. Der Code gilt 10 Minuten und nur einmal. Danach erlaubst du das Gerät in der Liste.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textSanft)
                        Text("Zeig den Code nur, wenn das neue Gerät direkt vor dir ist.")
                            .font(.footnote.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.himmel)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Einladung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
