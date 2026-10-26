import SwiftUI

// ============================================================
// MARK: - Das Tor zum Bereich der Eltern
// ============================================================
//
// Gehört das Gerät zu keiner Familie oder ist es kein Eltern-Gerät, ist der Bereich offen: Es gibt nichts zu
// schützen. Sonst muss eine PIN festgelegt und eingegeben werden. Die PIN bleibt auf dem Gerät (nur als Hash).
// Nach der richtigen PIN ist der Bereich fünf Minuten offen.

struct PinTor<Inhalt: View>: View {
    private let familie = FamilienModell.shared
    @ViewBuilder var inhalt: () -> Inhalt

    var body: some View {
        if !familie.istEltern || familie.entsperrt {
            inhalt()
        } else if !familie.pinGesetzt {
            PinFestlegenAnsicht()
        } else {
            PinEingebenAnsicht()
        }
    }
}

/// Nur Ziffern, höchstens acht.
private func nurZiffern(_ text: String) -> String {
    String(text.filter(\.isNumber).prefix(8))
}

private struct PinSeite<Karte: View>: View {
    @ViewBuilder var karte: () -> Karte

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(spacing: 18) {
                    Text("🔒")
                        .font(.system(size: 54))
                        .padding(.top, 50)
                    karte()
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct PinFestlegenAnsicht: View {
    private let familie = FamilienModell.shared
    @State private var pin = ""
    @State private var noch = ""
    @State private var fehler = ""

    var body: some View {
        PinSeite {
            VStack(alignment: .leading, spacing: 12) {
                Text("Eltern-PIN festlegen")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Text("Dieser Bereich ist für Mama und Papa. Bitte legt jetzt eine PIN fest, die nur ihr kennt. Ohne sie kommen Kinder hier nicht hinein.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white)
                SecureField("Neue PIN (4 bis 8 Ziffern)", text: $pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: pin) { pin = nurZiffern(pin); fehler = "" }
                SecureField("PIN noch einmal", text: $noch)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: noch) { noch = nurZiffern(noch); fehler = "" }
                if !fehler.isEmpty {
                    Text(fehler).font(.footnote.weight(.semibold)).foregroundStyle(Theme.koralle)
                }
                Text("Die PIN bleibt auf diesem Gerät. Sie wird nicht an die Familie geschickt.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSanft)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glasKarte(radius: 26)

            GelberKnopf(titel: "PIN speichern") {
                if let f = familie.pinSetzen(pin, wiederholt: noch) {
                    fehler = f
                    Haptik.fehler()
                } else {
                    Haptik.erfolg()
                }
            }
            .disabled(pin.isEmpty || noch.isEmpty)
            .opacity(pin.isEmpty || noch.isEmpty ? 0.4 : 1)
        }
    }
}

private struct PinEingebenAnsicht: View {
    private let familie = FamilienModell.shared
    @State private var pin = ""
    @State private var fehler = ""
    @State private var zeigeVergessen = false
    @FocusState private var fokus: Bool

    var body: some View {
        PinSeite {
            VStack(alignment: .leading, spacing: 12) {
                Text("Eltern-PIN")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gelb)
                Text("Bitte gib die PIN ein, um den Bereich für Eltern zu öffnen.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white)
                SecureField("PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($fokus)
                    .padding(14)
                    .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: pin) { pin = nurZiffern(pin); fehler = "" }
                    .onSubmit { pruefen() }
                if !fehler.isEmpty {
                    Text(fehler).font(.footnote.weight(.semibold)).foregroundStyle(Theme.koralle)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glasKarte(radius: 26)

            GelberKnopf(titel: "Öffnen") { pruefen() }
                .disabled(pin.isEmpty)
                .opacity(pin.isEmpty ? 0.4 : 1)

            Button("PIN vergessen?") { zeigeVergessen = true }
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textSanft)
        }
        .onAppear { fokus = true }
        .confirmationDialog("PIN vergessen?", isPresented: $zeigeVergessen, titleVisibility: .visible) {
            Button("Dieses Gerät von der Familie trennen", role: .destructive) { familie.lokalVergessen() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Dieses Gerät verlässt dann die Familie. Danach verbindest du es mit dem QR-Code eines anderen Eltern-Geräts neu und legst eine neue PIN fest. Ist es dein einziges Eltern-Gerät, kommst du nicht mehr an die Daten der Familie.")
        }
    }

    private func pruefen() {
        if let f = familie.pinPruefen(pin) {
            fehler = f
            pin = ""
            Haptik.fehler()
        } else {
            pin = ""
            Haptik.erfolg()
        }
    }
}
