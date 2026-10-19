import SwiftUI

// ============================================================
// MARK: - Englisch für Kleine: Thema anhören, dann spielen
// ============================================================

struct EnglischThemaView: View {
    let thema: EnglischThema
    @State private var zuletzt: String?

    var body: some View {
        ZStack {
            HintergrundView()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeroKopf(kicker: "English", titel: thema.titel,
                             untertitel: "Erst anhören, dann spielen", bild: thema.emoji)

                    spielenKnopf

                    if thema != .gemischt {
                        Text("Hör zu und sprich nach")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.gelb)
                            .padding(.top, 8)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 12)], spacing: 12) {
                            ForEach(Array(thema.woerter.enumerated()), id: \.element) { i, w in
                                wortKarte(w)
                                    .einblenden(i)
                            }
                        }
                    }

                    Text("Für Eltern: Tippt die Bilder zusammen an und sprecht die Wörter nach. Danach sucht dein Kind im Spiel das Bild zum Wort. Am schönsten klingt es mit der Stimme Cori (Einstellungen, Vorlese-Stimmen).")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSanft)
                        .padding(.top, 4)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(thema.titel)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Sprecher.shared.sprich(thema.titelEn, code: "en-GB") }
    }

    private var spielenKnopf: some View {
        NavigationLink {
            VorschulRunde(art: .mix, englisch: thema)
        } label: {
            Label("Spielen", systemImage: "play.fill")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.navy)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.gelb, in: Capsule())
        }
        .buttonStyle(TastenStil())
    }

    private func wortKarte(_ w: EnglischWort) -> some View {
        let aktiv = zuletzt == w.en
        return Button {
            zuletzt = w.en
            Haptik.leicht()
            Sprecher.shared.sprich(VorschulEnglisch.anhoeren(w), code: "en-GB")
        } label: {
            VStack(spacing: 4) {
                Text(w.bild)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                Text(w.en)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(aktiv ? Theme.gelb : Color.white)
                Text(w.de)
                    .font(.caption)
                    .foregroundStyle(Theme.textSanft)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(6)
            .glasKarte(radius: 22)
            .scaleEffect(aktiv ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: aktiv)
        }
        .buttonStyle(TastenStil())
        .accessibilityLabel("\(w.en), \(w.de)")
    }
}
