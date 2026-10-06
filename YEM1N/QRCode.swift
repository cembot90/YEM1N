import SwiftUI
import SwiftData
import UIKit
import UniformTypeIdentifiers
import CloudKit
import AVFoundation
import UserNotifications
import PencilKit
import CryptoKit
import Security
import WebKit
import CoreImage.CIFilterBuiltins

// ============================================================
// MARK: - QR-Codes und PDF-Bericht
// ============================================================

enum QRPaket {
    static func inhalt(art: String, code: String) -> String {
        "yem1n://\(art)/\(code)"
    }

    // Liefert Art ("familie" oder "klasse") und bereinigten Code, sonst nil
    static func lese(_ text: String) -> (art: String, code: String)? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let vorsatz = "yem1n://"
        guard t.lowercased().hasPrefix(vorsatz) else { return nil }
        let rest = String(t.dropFirst(vorsatz.count))
        let teile = rest.split(separator: "/").map(String.init)
        guard teile.count == 2 else { return nil }
        let art = teile[0].lowercased()
        guard art == "familie" || art == "klasse" else { return nil }
        let code = Familiencode.bereinigt(teile[1])
        guard Familiencode.istGueltig(code) else { return nil }
        return (art, code)
    }

    static func bild(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let ci = filter.outputImage else { return nil }
        let gross = ci.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = CIContext().createCGImage(gross, from: gross.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

struct QRAnzeigeSheet: View {
    let titel: String
    let art: String
    let code: String
    let hinweis: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                HintergrundView()
                ScrollView {
                    VStack(spacing: 18) {
                        if let bild = QRPaket.bild(QRPaket.inhalt(art: art, code: code)) {
                            Image(uiImage: bild)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .padding(16)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .frame(maxWidth: 300)
                        }
                        Text(code)
                            .font(.system(.title2, design: .monospaced).weight(.bold))
                            .foregroundStyle(Theme.gelb)
                        Text(hinweis)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Theme.textSanft)
                            .padding(.horizontal, 12)
                    }
                    .padding(24)
                }
            }
            .navigationTitle(titel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

struct QRKameraAnsicht: UIViewControllerRepresentable {
    // Gibt true zurück, wenn der Code angenommen wurde
    let onCode: (String) -> Bool

    func makeUIViewController(context: Context) -> QRKameraController {
        let c = QRKameraController()
        c.onCode = onCode
        return c
    }

    func updateUIViewController(_ vc: QRKameraController, context: Context) {}
}

final class QRKameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Bool)?
    private let session = AVCaptureSession()
    private var vorschau: AVCaptureVideoPreviewLayer?
    private var fertig = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        AVCaptureDevice.requestAccess(for: .video) { [weak self] erlaubt in
            DispatchQueue.main.async {
                if erlaubt { self?.starte() }
            }
        }
    }

    private func starte() {
        guard let geraet = AVCaptureDevice.default(for: .video),
              let eingang = try? AVCaptureDeviceInput(device: geraet),
              session.canAddInput(eingang) else { return }
        session.addInput(eingang)
        let ausgang = AVCaptureMetadataOutput()
        guard session.canAddOutput(ausgang) else { return }
        session.addOutput(ausgang)
        ausgang.setMetadataObjectsDelegate(self, queue: .main)
        ausgang.metadataObjectTypes = [.qr]
        let ebene = AVCaptureVideoPreviewLayer(session: session)
        ebene.videoGravity = .resizeAspectFill
        ebene.frame = view.bounds
        view.layer.addSublayer(ebene)
        vorschau = ebene
        let sitzung = session
        DispatchQueue.global(qos: .userInitiated).async { sitzung.startRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        vorschau?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !fertig,
              let objekt = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let text = objekt.stringValue else { return }
        if onCode?(text) == true { fertig = true }
    }
}

struct QRScanSheet: View {
    let onErgebnis: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var fehler = ""

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                QRKameraAnsicht { text in
                    if let p = QRPaket.lese(text) {
                        onErgebnis(p.art, p.code)
                        dismiss()
                        return true
                    }
                    fehler = "Das ist kein YEM1N-Code. Versuche es noch einmal."
                    return false
                }
                .ignoresSafeArea()
                Text(fehler.isEmpty ? "Halte die Kamera auf den QR-Code." : fehler)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.navy)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Theme.gelb, in: Capsule())
                    .padding(.bottom, 30)
            }
            .navigationTitle("QR-Code scannen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

struct QRScanKnopf: View {
    let onErgebnis: (String, String) -> Void
    @State private var zeige = false

    var body: some View {
        Button { zeige = true } label: {
            Label("QR-Code scannen", systemImage: "qrcode.viewfinder")
        }
        .sheet(isPresented: $zeige) { QRScanSheet(onErgebnis: onErgebnis) }
    }
}

enum BerichtPDF {
    static func erstellen(_ text: String) -> URL? {
        let seite = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: seite)
        let navy = UIColor(red: 0, green: 0.125, blue: 0.357, alpha: 1)
        let gelb = UIColor(red: 1, green: 0.93, blue: 0, alpha: 1)
        let zeilen = Array(text.components(separatedBy: "\n").dropFirst())
        let datum = Date.now.formatted(date: .long, time: .omitted)
        let daten = renderer.pdfData { ctx in
            var y: CGFloat = 0
            func neueSeite() {
                ctx.beginPage()
                navy.setFill()
                UIBezierPath(rect: CGRect(x: 0, y: 0, width: 595, height: 96)).fill()
                let logo: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 34, weight: .black),
                    .foregroundColor: gelb]
                ("YEM1N" as NSString).draw(at: CGPoint(x: 40, y: 20), withAttributes: logo)
                let unter: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                    .foregroundColor: UIColor.white]
                (("Wochenbericht, " + datum) as NSString).draw(at: CGPoint(x: 40, y: 62), withAttributes: unter)
                y = 124
            }
            neueSeite()
            for zeile in zeilen {
                if zeile.isEmpty {
                    y += 10
                    continue
                }
                let fett = zeile.hasPrefix("⭐")
                let attribute: [NSAttributedString.Key: Any] = [
                    .font: fett ? UIFont.systemFont(ofSize: 20, weight: .heavy) : UIFont.systemFont(ofSize: 14),
                    .foregroundColor: fett ? navy : UIColor.black]
                let box = (zeile as NSString).boundingRect(
                    with: CGSize(width: 515, height: 2000),
                    options: .usesLineFragmentOrigin,
                    attributes: attribute,
                    context: nil)
                let hoehe = ceil(box.height)
                if y + hoehe > 800 { neueSeite() }
                (zeile as NSString).draw(in: CGRect(x: 40, y: y, width: 515, height: hoehe),
                                         withAttributes: attribute)
                y += hoehe + (fett ? 8 : 5)
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("YEM1N-Wochenbericht.pdf")
        do {
            try daten.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
