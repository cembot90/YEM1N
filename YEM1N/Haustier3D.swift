import SwiftUI
import SceneKit
import UIKit

// ============================================================
// MARK: - Haustier in 3D
// Das Tier wird aus weichen Grundformen gebaut (Kugeln, Kegel, Kapseln),
// es braucht also keine Modelldateien. Es atmet, blinzelt, schwebt leicht
// und hüpft beim Antippen. Mit dem Finger lässt es sich drehen.
// Die Animationen laufen ohne eigene Swift-Blöcke im Hintergrund, damit
// nichts außerhalb des Haupt-Threads passiert.
// ============================================================

/// Wie die Eule Olli auf der Bühne fliegt.
enum EulenFlug: Equatable {
    /// Keine Eule
    case aus
    /// Kreist über dem Ei und passt darauf auf
    case kreisen
    /// Schwebt neben dem geschlüpften Tier
    case schweben
}

/// Zeichnet nur, solange das Tier wirklich auf dem Bildschirm ist.
/// In einem anderen Reiter oder unter einer anderen Seite ruht es.
final class TierAnsicht: SCNView {
    override func didMoveToWindow() {
        super.didMoveToWindow()
        isPlaying = window != nil
    }
}

struct Haustier3DView: UIViewRepresentable {
    let art: String
    let stufe: HaustierStufe
    let stimmung: HaustierStimmung
    /// Kennung des Huts, zum Beispiel "krone", oder leer.
    var hut: String = ""
    /// Zählt hoch, wenn das Tier hüpfen soll.
    var stups: Int = 0
    /// Zählt hoch, wenn das Tier einen Freudentanz machen soll.
    var tanz: Int = 0
    /// Abends und nachts schläft das Tier mit geschlossenen Augen.
    var schlaeft: Bool = false
    /// Die Eule Olli: kreist über dem Ei oder schwebt neben dem Tier.
    var eule: EulenFlug = .aus
    /// Zählt hoch, wenn Olli etwas sagt. Sie nickt dann.
    var euleSpricht: Int = 0
    /// Wird aufgerufen, wenn jemand auf die Eule tippt.
    var beiEule: (() -> Void)? = nil
    /// Wird aufgerufen, wenn das Kind auf das Tier tippt.
    var beiTipp: (() -> Void)? = nil

    func makeCoordinator() -> Koordinator { Koordinator() }

    func makeUIView(context: Context) -> TierAnsicht {
        let ansicht = TierAnsicht(frame: .zero)
        ansicht.backgroundColor = .clear
        ansicht.isOpaque = false
        // Das Tier bewegt sich ruhig. 30 Bilder pro Sekunde und einfache Kantenglättung
        // sehen genauso aus, schonen aber Akku und ältere iPhones.
        ansicht.antialiasingMode = .multisampling2X
        ansicht.allowsCameraControl = false
        ansicht.autoenablesDefaultLighting = false
        ansicht.isPlaying = true
        ansicht.preferredFramesPerSecond = 30

        let szene = SCNScene()
        szene.background.contents = UIColor.clear
        Haustier3DBauer.licht(in: szene)
        szene.rootNode.addChildNode(Haustier3DBauer.kamera())
        szene.rootNode.addChildNode(context.coordinator.wurzel)
        // Die Eule hängt nicht am Tier, damit sie beim Drehen mit dem Finger ruhig bleibt
        szene.rootNode.addChildNode(context.coordinator.euleWurzel)
        ansicht.scene = szene

        let tipp = UITapGestureRecognizer(target: context.coordinator, action: #selector(Koordinator.getippt(_:)))
        let ziehen = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Koordinator.gezogen(_:)))
        // Nur waagrechtes Ziehen dreht das Tier, senkrecht scrollt die Seite weiter
        ziehen.delegate = context.coordinator
        ansicht.addGestureRecognizer(tipp)
        ansicht.addGestureRecognizer(ziehen)

        context.coordinator.stups = stups
        context.coordinator.tanz = tanz
        context.coordinator.beiTipp = beiTipp
        context.coordinator.beiEule = beiEule
        context.coordinator.euleSpricht = euleSpricht
        context.coordinator.zeige(art: art, stufe: stufe, stimmung: stimmung, hut: hut, schlaeft: schlaeft)
        context.coordinator.zeigeEule(eule)
        return ansicht
    }

    func updateUIView(_ ansicht: TierAnsicht, context: Context) {
        let k = context.coordinator
        k.beiTipp = beiTipp
        k.beiEule = beiEule
        k.zeige(art: art, stufe: stufe, stimmung: stimmung, hut: hut, schlaeft: schlaeft)
        k.zeigeEule(eule)
        if euleSpricht != k.euleSpricht {
            k.euleSpricht = euleSpricht
            k.euleNickt()
        }
        if stups != k.stups {
            k.stups = stups
            k.huepfe()
        }
        if tanz != k.tanz {
            k.tanz = tanz
            k.tanze()
        }
    }

    final class Koordinator: NSObject, UIGestureRecognizerDelegate {
        let wurzel = SCNNode()
        var tier: SCNNode?
        var schluessel = ""
        var stups = 0
        var tanz = 0
        var beiTipp: (() -> Void)?
        let euleWurzel = SCNNode()
        var euleFlug: EulenFlug = .aus
        var euleSpricht = 0
        var beiEule: (() -> Void)?
        private var startWinkel: Float = 0

        func zeigeEule(_ flug: EulenFlug) {
            guard flug != euleFlug else { return }
            euleFlug = flug
            for k in euleWurzel.childNodes { k.removeFromParentNode() }
            if flug != .aus { euleWurzel.addChildNode(Haustier3DBauer.eule(flug: flug)) }
        }

        /// Olli nickt, wenn sie etwas sagt.
        func euleNickt() {
            guard let modell = euleWurzel.childNode(withName: "eule", recursively: true) else { return }
            modell.removeAction(forKey: "nicken")
            modell.eulerAngles = SCNVector3(0, 0, 0)
            modell.scale = SCNVector3(1, 1, 1)
            modell.runAction(Haustier3DBauer.nicken(), forKey: "nicken")
        }

        /// true, wenn der Knoten zur Eule gehört.
        private func gehoertZurEule(_ knoten: SCNNode) -> Bool {
            var n: SCNNode? = knoten
            while let k = n {
                if k === euleWurzel { return true }
                n = k.parent
            }
            return false
        }

        func zeige(art: String, stufe: HaustierStufe, stimmung: HaustierStimmung, hut: String, schlaeft: Bool) {
            let neu = "\(art)|\(stufe.rawValue)|\(stimmung)|\(hut)|\(schlaeft)"
            guard neu != schluessel else { return }
            schluessel = neu
            tier?.removeFromParentNode()
            let knoten = Haustier3DBauer.tier(art: art, stufe: stufe, stimmung: stimmung, hut: hut,
                                              schlaeft: schlaeft)
            wurzel.addChildNode(knoten)
            tier = knoten
        }

        func huepfe() {
            // Während eines Sprungs keinen zweiten starten, sonst landet das Tier schief
            guard let tier, tier.action(forKey: "huepfen") == nil else { return }
            tier.runAction(Haustier3DBauer.sprung(), forKey: "huepfen")
        }

        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let p = g as? UIPanGestureRecognizer else { return true }
            let v = p.velocity(in: p.view)
            return abs(v.x) > abs(v.y)
        }

        func tanze() {
            guard let tier else { return }
            tier.removeAction(forKey: "huepfen")
            // Ein abgebrochener Sprung würde sonst Höhe, Drehung und Größe behalten
            tier.position = SCNVector3(0, 0, 0)
            tier.eulerAngles = SCNVector3(0, 0, 0)
            tier.scale = SCNVector3(1, 1, 1)
            tier.runAction(Haustier3DBauer.tanz(), forKey: "huepfen")
        }

        /// Der Kopf dreht sich kurz dorthin, wo der Finger getippt hat.
        func schaue(nach punkt: CGPoint, in groesse: CGSize) {
            guard let blick = tier?.childNode(withName: "blick", recursively: true),
                  groesse.width > 0, groesse.height > 0 else { return }
            let dx = Float((punkt.x / groesse.width) - 0.5) * 2
            let dy = Float((punkt.y / groesse.height) - 0.5) * 2
            blick.removeAction(forKey: "blick")
            let hin = SCNAction.rotateTo(x: CGFloat(dy * 0.35), y: CGFloat(dx * 0.6), z: 0,
                                         duration: 0.25, usesShortestUnitArc: true)
            hin.timingMode = .easeOut
            let zurueck = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.6, usesShortestUnitArc: true)
            zurueck.timingMode = .easeInEaseOut
            blick.runAction(.sequence([hin, .wait(duration: 1.4), zurueck]), forKey: "blick")
        }

        @objc func getippt(_ g: UITapGestureRecognizer) {
            guard let v = g.view else { return }
            let punkt = g.location(in: v)
            // Wer die Eule trifft, bekommt einen Tipp. Das Tier bleibt dann ruhig.
            if euleFlug != .aus, let ansicht = v as? SCNView,
               let vorne = ansicht.hitTest(punkt, options: nil).first,
               gehoertZurEule(vorne.node) {
                euleNickt()
                beiEule?()
                return
            }
            schaue(nach: punkt, in: v.bounds.size)
            huepfe()
            beiTipp?()
        }

        @objc func gezogen(_ g: UIPanGestureRecognizer) {
            switch g.state {
            case .began:
                wurzel.removeAction(forKey: "zurueck")
                startWinkel = wurzel.eulerAngles.y
            case .changed:
                let x = Float(g.translation(in: g.view).x)
                wurzel.eulerAngles.y = startWinkel + x * 0.012
            default:
                let zurueck = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.7, usesShortestUnitArc: true)
                zurueck.timingMode = .easeOut
                wurzel.runAction(zurueck, forKey: "zurueck")
            }
        }
    }
}

// MARK: - Tageszeit

enum HaustierZeit {
    /// Ab 20 Uhr schläft das Tier, ab 7 Uhr ist es wieder wach.
    static let schlafenAb = 20
    static let wachAb = 7
    /// Wird nach einer geschafften Runde gesetzt. Beim nächsten Besuch tanzt das Tier.
    static let freudeKey = "haustierFreude"

    static func schlaeft(_ datum: Date, kalender: Calendar = .current) -> Bool {
        let h = kalender.component(.hour, from: datum)
        return h >= schlafenAb || h < wachAb
    }
}

// MARK: - Bauplan

enum Haustier3DBauer {

    struct Farben {
        let fell: UIColor
        let bauch: UIColor
        let akzent: UIColor
    }

    static func farben(_ art: String) -> Farben {
        switch art {
        case "hund":
            return Farben(fell: UIColor(red: 0.82, green: 0.60, blue: 0.40, alpha: 1),
                          bauch: UIColor(red: 0.99, green: 0.91, blue: 0.80, alpha: 1),
                          akzent: UIColor(red: 0.52, green: 0.33, blue: 0.20, alpha: 1))
        case "hase":
            return Farben(fell: UIColor(red: 0.93, green: 0.93, blue: 0.97, alpha: 1),
                          bauch: UIColor.white,
                          akzent: UIColor(red: 1.0, green: 0.68, blue: 0.78, alpha: 1))
        case "fuchs":
            return Farben(fell: UIColor(red: 1.0, green: 0.48, blue: 0.16, alpha: 1),
                          bauch: UIColor.white,
                          akzent: UIColor(red: 0.25, green: 0.16, blue: 0.12, alpha: 1))
        case "drache":
            return Farben(fell: UIColor(red: 0.36, green: 0.80, blue: 0.47, alpha: 1),
                          bauch: UIColor(red: 0.98, green: 0.92, blue: 0.55, alpha: 1),
                          akzent: UIColor(red: 0.20, green: 0.58, blue: 0.38, alpha: 1))
        case "einhorn":
            return Farben(fell: UIColor(red: 0.99, green: 0.97, blue: 1.0, alpha: 1),
                          bauch: UIColor(red: 1.0, green: 0.90, blue: 0.96, alpha: 1),
                          akzent: UIColor(red: 1.0, green: 0.80, blue: 0.25, alpha: 1))
        default: // Katze
            return Farben(fell: UIColor(red: 1.0, green: 0.67, blue: 0.33, alpha: 1),
                          bauch: UIColor(red: 1.0, green: 0.92, blue: 0.78, alpha: 1),
                          akzent: UIColor(red: 1.0, green: 0.70, blue: 0.75, alpha: 1))
        }
    }

    // MARK: Szene

    static func kamera() -> SCNNode {
        let k = SCNCamera()
        k.fieldOfView = 32
        k.zNear = 0.1
        k.zFar = 50
        let n = SCNNode()
        n.camera = k
        n.position = SCNVector3(0, 0.5, 7.2)
        n.look(at: SCNVector3(0, 0.05, 0))
        return n
    }

    static func licht(in szene: SCNScene) {
        let umgebung = SCNLight()
        umgebung.type = .ambient
        umgebung.intensity = 520
        umgebung.color = UIColor(white: 0.95, alpha: 1)
        let u = SCNNode()
        u.light = umgebung
        szene.rootNode.addChildNode(u)

        let haupt = SCNLight()
        haupt.type = .directional
        haupt.intensity = 950
        let h = SCNNode()
        h.light = haupt
        h.eulerAngles = SCNVector3(-0.7, -0.5, 0)
        szene.rootNode.addChildNode(h)

        // Kantenlicht von hinten, gibt den weichen Glanz am Rand
        let kante = SCNLight()
        kante.type = .omni
        kante.intensity = 700
        kante.color = UIColor(red: 0.75, green: 0.85, blue: 1.0, alpha: 1)
        let r = SCNNode()
        r.light = kante
        r.position = SCNVector3(-2.5, 3, -3)
        szene.rootNode.addChildNode(r)
    }

    // MARK: Material und Formen

    static func material(_ farbe: UIColor, glanz: CGFloat = 0.35, leuchten: Bool = false) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = leuchten ? .constant : .blinn
        m.diffuse.contents = farbe
        m.specular.contents = UIColor(white: glanz, alpha: 1)
        m.shininess = 0.4
        return m
    }

    static func kugel(_ r: CGFloat, _ farbe: UIColor, _ pos: SCNVector3,
                      skala: SCNVector3 = SCNVector3(1, 1, 1), glanz: CGFloat = 0.35) -> SCNNode {
        let g = SCNSphere(radius: r)
        g.segmentCount = 40
        g.firstMaterial = material(farbe, glanz: glanz)
        let n = SCNNode(geometry: g)
        n.position = pos
        n.scale = skala
        return n
    }

    static func kegel(unten: CGFloat, hoehe: CGFloat, _ farbe: UIColor, _ pos: SCNVector3,
                      winkel: SCNVector3 = SCNVector3(0, 0, 0)) -> SCNNode {
        let g = SCNCone(topRadius: 0.01, bottomRadius: unten, height: hoehe)
        g.radialSegmentCount = 32
        g.firstMaterial = material(farbe)
        let n = SCNNode(geometry: g)
        n.position = pos
        n.eulerAngles = winkel
        return n
    }

    static func kapsel(radius: CGFloat, hoehe: CGFloat, _ farbe: UIColor, _ pos: SCNVector3,
                       winkel: SCNVector3 = SCNVector3(0, 0, 0)) -> SCNNode {
        let g = SCNCapsule(capRadius: radius, height: hoehe)
        g.radialSegmentCount = 32
        g.firstMaterial = material(farbe)
        let n = SCNNode(geometry: g)
        n.position = pos
        n.eulerAngles = winkel
        return n
    }

    // MARK: Das Tier

    static func groesse(_ stufe: HaustierStufe) -> Float {
        switch stufe {
        case .ei: return 0.9
        case .baby: return 0.74
        case .kind: return 0.86
        case .gross: return 0.98
        case .meister: return 1.06
        }
    }

    static func tier(art: String, stufe: HaustierStufe, stimmung: HaustierStimmung, hut: String,
                     schlaeft: Bool = false) -> SCNNode {
        let ganz = SCNNode()
        let s = groesse(stufe)
        ganz.addChildNode(schatten(breite: CGFloat(1.9 * s), y: -1.22 * s))

        let koerper = SCNNode()
        koerper.scale = SCNVector3(s, s, s)
        ganz.addChildNode(koerper)

        if stufe == .ei {
            koerper.addChildNode(ei(art: art))
            koerper.runAction(wackeln(), forKey: "wackeln")
            return ganz
        }

        let f = farben(art)
        let rumpf = SCNNode()
        koerper.addChildNode(rumpf)

        // Körper mit hellem Bauch, Arme und Füße
        rumpf.addChildNode(kugel(0.68, f.fell, SCNVector3(0, -0.45, 0), skala: SCNVector3(1, 0.92, 0.9)))
        rumpf.addChildNode(kugel(0.5, f.bauch, SCNVector3(0, -0.5, 0.3), skala: SCNVector3(1, 1, 0.6)))
        for x: Float in [-1, 1] {
            rumpf.addChildNode(kugel(0.17, f.fell, SCNVector3(0.62 * x, -0.38, 0.16)))
            rumpf.addChildNode(kugel(0.21, f.fell, SCNVector3(0.32 * x, -1.04, 0.22), skala: SCNVector3(1, 0.6, 1.25)))
        }
        rumpf.addChildNode(schwanz(art: art, f: f))
        if art == "drache" { fluegel(an: rumpf, f: f) }
        rumpf.addAnimation(atmen(), forKey: "atmen")

        // Kopf: Ohren, Gesicht, Hut. Der Blick-Knoten dreht den Kopf zum Finger,
        // der Kopf selbst neigt sich nebenbei von allein.
        let blick = SCNNode()
        blick.name = "blick"
        blick.position = SCNVector3(0, 0.55, 0)
        koerper.addChildNode(blick)
        let kopf = SCNNode()
        kopf.name = "kopf"
        blick.addChildNode(kopf)
        kopf.addChildNode(kugel(0.78, f.fell, SCNVector3(0, 0, 0), skala: SCNVector3(1.04, 0.96, 0.96)))
        ohren(an: kopf, art: art, f: f)
        gesicht(an: kopf, art: art, f: f, stimmung: stimmung, schlaeft: schlaeft)
        if let h = HaustierHut.finde(hut) { kopf.addChildNode(hutKnoten(h)) }

        if schlaeft {
            // Schlafend: Kopf leicht zur Seite, Zzz steigt auf
            kopf.eulerAngles = SCNVector3(0.12, 0, 0.22)
            kopf.addChildNode(zzz())
        } else {
            switch stimmung {
            case .traurig:
                kopf.eulerAngles = SCNVector3(0.18, 0, 0.08)
            case .hungrig:
                kopf.eulerAngles = SCNVector3(0.08, 0, -0.1)
            default:
                kopf.runAction(kopfNeigen(), forKey: "neigen")
            }
        }

        // Ganz sanftes Schweben, bei guter Laune hüpft es ab und zu von selbst
        koerper.runAction(schweben(), forKey: "schweben")
        if stimmung == .froh && !schlaeft { koerper.runAction(freudenHopser(), forKey: "freude") }
        if stufe == .meister { ganz.addChildNode(funkeln(hoehe: 1.65 * s)) }
        return ganz
    }

    static func ohren(an kopf: SCNNode, art: String, f: Farben) {
        switch art {
        case "hund":
            for x: Float in [-1, 1] {
                let o = kugel(0.3, f.akzent, SCNVector3(0.74 * x, -0.02, 0), skala: SCNVector3(0.55, 1.3, 0.4))
                o.eulerAngles = SCNVector3(0, 0, 0.32 * x)
                kopf.addChildNode(o)
            }
        case "hase":
            for x: Float in [-1, 1] {
                let o = kapsel(radius: 0.15, hoehe: 1.0, f.fell, SCNVector3(0.26 * x, 0.98, -0.05),
                               winkel: SCNVector3(0, 0, -0.16 * x))
                let innen = kapsel(radius: 0.08, hoehe: 0.7, f.akzent, SCNVector3(0, 0, 0.09))
                o.addChildNode(innen)
                o.addAnimation(ohrWackeln(versatz: x > 0 ? 0.4 : 0), forKey: "ohr")
                kopf.addChildNode(o)
            }
        case "drache":
            for x: Float in [-1, 1] {
                kopf.addChildNode(kegel(unten: 0.11, hoehe: 0.38, f.bauch, SCNVector3(0.32 * x, 0.72, -0.12),
                                        winkel: SCNVector3(-0.25, 0, -0.3 * x)))
            }
        case "einhorn":
            kopf.addChildNode(kegel(unten: 0.12, hoehe: 0.6, f.akzent, SCNVector3(0, 0.82, 0.28),
                                    winkel: SCNVector3(-0.35, 0, 0)))
            for x: Float in [-1, 1] {
                kopf.addChildNode(kegel(unten: 0.15, hoehe: 0.32, f.fell, SCNVector3(0.42 * x, 0.66, -0.08),
                                        winkel: SCNVector3(0, 0, -0.35 * x)))
            }
            let maehne = [UIColor(red: 1.0, green: 0.55, blue: 0.80, alpha: 1),
                          UIColor(red: 0.72, green: 0.58, blue: 1.0, alpha: 1),
                          UIColor(red: 0.45, green: 0.80, blue: 1.0, alpha: 1),
                          UIColor(red: 0.55, green: 0.92, blue: 0.70, alpha: 1)]
            for (i, farbe) in maehne.enumerated() {
                let y = 0.62 - Float(i) * 0.26
                kopf.addChildNode(kugel(0.2, farbe, SCNVector3(0.05, y, -0.62 - Float(i) * 0.04)))
            }
        default: // Katze und Fuchs mit spitzen Ohren
            let hoehe: CGFloat = art == "fuchs" ? 0.55 : 0.45
            for x: Float in [-1, 1] {
                let o = kegel(unten: 0.24, hoehe: hoehe, f.fell, SCNVector3(0.44 * x, 0.68, 0),
                              winkel: SCNVector3(0, 0, -0.38 * x))
                let innen = kegel(unten: 0.13, hoehe: hoehe * 0.65,
                                  art == "fuchs" ? f.akzent : UIColor(red: 1.0, green: 0.72, blue: 0.76, alpha: 1),
                                  SCNVector3(0, -0.04, 0.1))
                o.addChildNode(innen)
                if art == "katze" { o.addAnimation(ohrWackeln(versatz: x > 0 ? 0.6 : 0), forKey: "ohr") }
                kopf.addChildNode(o)
            }
        }
    }

    static func gesicht(an kopf: SCNNode, art: String, f: Farben, stimmung: HaustierStimmung,
                        schlaeft: Bool = false) {
        let dunkel = UIColor(red: 0.12, green: 0.10, blue: 0.16, alpha: 1)

        // Helle Schnauze bei Fuchs, Hund und Drache
        if art == "fuchs" || art == "hund" || art == "drache" {
            kopf.addChildNode(kugel(0.32, f.bauch, SCNVector3(0, -0.17, 0.56), skala: SCNVector3(1.15, 0.8, 0.8)))
        }

        // Augen mit Glanzpunkt, sie blinzeln
        let augen = SCNNode()
        augen.position = SCNVector3(0, 0.1, 0)
        kopf.addChildNode(augen)
        let lacht = stimmung == .froh
        for x: Float in [-1, 1] {
            // Schlafende Augen sind nur ein schmaler Strich
            let hoehe: Float = schlaeft ? 0.14 : (lacht ? 0.55 : 1.15)
            let auge = kugel(0.12, dunkel, SCNVector3(0.28 * x, 0, 0.66),
                             skala: SCNVector3(1, hoehe, 0.7), glanz: 0.9)
            if !schlaeft { auge.addChildNode(kugel(0.04, .white, SCNVector3(0.035, 0.05, 0.1), glanz: 0)) }
            augen.addChildNode(auge)
        }
        if !schlaeft { augen.addAnimation(blinzeln(), forKey: "blinzeln") }

        // Wangen
        for x: Float in [-1, 1] {
            let w = kugel(0.13, UIColor(red: 1.0, green: 0.55, blue: 0.62, alpha: 1),
                          SCNVector3(0.47 * x, -0.12, 0.55), skala: SCNVector3(1, 0.7, 0.4), glanz: 0)
            w.opacity = 0.75
            kopf.addChildNode(w)
        }

        // Nase
        kopf.addChildNode(kugel(0.07, art == "hase" || art == "katze" ? UIColor(red: 1.0, green: 0.5, blue: 0.6, alpha: 1) : dunkel,
                                SCNVector3(0, -0.08, 0.77), skala: SCNVector3(1.2, 0.85, 0.8), glanz: 0.8))

        // Mund je nach Stimmung
        switch stimmung {
        case .hungrig:
            kopf.addChildNode(kugel(0.1, dunkel, SCNVector3(0, -0.27, 0.71), skala: SCNVector3(1, 0.9, 0.4)))
        case .traurig:
            kopf.addChildNode(kapsel(radius: 0.025, hoehe: 0.16, dunkel, SCNVector3(0, -0.27, 0.72),
                                     winkel: SCNVector3(0, 0, Float.pi / 2)))
            // Eine kleine Träne
            let traene = kugel(0.05, UIColor(red: 0.55, green: 0.80, blue: 1.0, alpha: 1),
                               SCNVector3(0.3, -0.05, 0.7), skala: SCNVector3(0.8, 1.2, 0.8), glanz: 1)
            traene.addAnimation(traenenTropfen(), forKey: "traene")
            kopf.addChildNode(traene)
        default:
            // Lächeln aus zwei kleinen schrägen Strichen
            for x: Float in [-1, 1] {
                kopf.addChildNode(kapsel(radius: 0.024, hoehe: 0.13, dunkel, SCNVector3(0.055 * x, -0.25, 0.72),
                                         winkel: SCNVector3(0, 0, Float.pi / 2 + 0.55 * x)))
            }
        }
    }

    /// "💤" steigt langsam über dem Kopf auf und verblasst, immer wieder.
    static func zzz() -> SCNNode {
        let flaeche = SCNPlane(width: 0.5, height: 0.5)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = emojiBild("💤")
        m.isDoubleSided = true
        m.writesToDepthBuffer = false
        flaeche.firstMaterial = m
        let n = SCNNode(geometry: flaeche)
        n.position = SCNVector3(0.55, 0.75, 0.2)
        n.renderingOrder = 11
        let steigen = SCNAction.group([.moveBy(x: 0.15, y: 0.45, z: 0, duration: 2.2), .fadeOut(duration: 2.2)])
        let zurueck = SCNAction.group([.move(to: SCNVector3(0.55, 0.75, 0.2), duration: 0), .fadeIn(duration: 0.3)])
        n.runAction(.repeatForever(.sequence([steigen, zurueck])))
        return n
    }

    static func schwanz(art: String, f: Farben) -> SCNNode {
        switch art {
        case "fuchs":
            let s = kugel(0.34, f.fell, SCNVector3(0.35, -0.7, -0.72), skala: SCNVector3(0.7, 0.7, 1.45))
            s.eulerAngles = SCNVector3(0.5, 0.5, 0)
            s.addChildNode(kugel(0.17, .white, SCNVector3(0, 0, -0.27)))
            s.addAnimation(schwanzWedeln(), forKey: "wedeln")
            return s
        case "hase":
            return kugel(0.2, .white, SCNVector3(0, -0.72, -0.62))
        case "drache":
            let s = kegel(unten: 0.2, hoehe: 0.8, f.fell, SCNVector3(0.2, -0.85, -0.7),
                          winkel: SCNVector3(-1.2, 0.4, 0))
            s.addAnimation(schwanzWedeln(), forKey: "wedeln")
            return s
        case "einhorn":
            let s = kugel(0.22, UIColor(red: 1.0, green: 0.62, blue: 0.85, alpha: 1), SCNVector3(0, -0.6, -0.66),
                          skala: SCNVector3(0.8, 1.3, 0.8))
            s.addAnimation(schwanzWedeln(), forKey: "wedeln")
            return s
        default:
            let s = kapsel(radius: 0.09, hoehe: 0.85, art == "hund" ? f.akzent : f.fell, SCNVector3(0.2, -0.55, -0.7),
                           winkel: SCNVector3(-0.9, 0, -0.4))
            s.addAnimation(schwanzWedeln(), forKey: "wedeln")
            return s
        }
    }

    static func fluegel(an rumpf: SCNNode, f: Farben) {
        for x: Float in [-1, 1] {
            let fl = kugel(0.45, f.akzent, SCNVector3(0.7 * x, -0.1, -0.42), skala: SCNVector3(1, 0.62, 0.12))
            fl.eulerAngles = SCNVector3(0, 0.5 * x, 0.45 * x)
            fl.addAnimation(fluegelSchlag(x: x), forKey: "schlag")
            rumpf.addChildNode(fl)
        }
        for i in 0..<3 {
            rumpf.addChildNode(kegel(unten: 0.09, hoehe: 0.22, f.bauch,
                                     SCNVector3(0, 0.05 - Float(i) * 0.3, -0.6 + Float(i) * 0.02),
                                     winkel: SCNVector3(-0.9, 0, 0)))
        }
    }

    static func ei(art: String) -> SCNNode {
        let n = SCNNode()
        let schale = kugel(0.82, UIColor(red: 1.0, green: 0.97, blue: 0.88, alpha: 1), SCNVector3(0, -0.25, 0),
                           skala: SCNVector3(0.86, 1.1, 0.86), glanz: 0.6)
        n.addChildNode(schale)
        let punkte: [SCNVector3] = [SCNVector3(-0.32, 0.05, 0.6), SCNVector3(0.3, -0.35, 0.62),
                                    SCNVector3(0.05, 0.38, 0.62), SCNVector3(-0.15, -0.6, 0.6),
                                    SCNVector3(0.45, 0.2, 0.42)]
        for p in punkte {
            n.addChildNode(kugel(0.11, farben(art).fell, p, skala: SCNVector3(1, 1, 0.3), glanz: 0.2))
        }
        return n
    }

    static func hutKnoten(_ h: HaustierHut) -> SCNNode {
        let groesse: CGFloat
        let pos: SCNVector3
        switch h.id {
        case "brille":
            groesse = 0.85
            pos = SCNVector3(0, 0.12, 0.84)
        case "schleife":
            groesse = 0.55
            pos = SCNVector3(0.42, 0.62, 0.28)
        default:
            groesse = 0.95
            pos = SCNVector3(0, 0.86, 0.12)
        }
        let flaeche = SCNPlane(width: groesse, height: groesse)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = emojiBild(h.emoji)
        m.isDoubleSided = true
        m.writesToDepthBuffer = false
        flaeche.firstMaterial = m
        let n = SCNNode(geometry: flaeche)
        n.position = pos
        n.renderingOrder = 10
        return n
    }

    static func emojiBild(_ emoji: String) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let r = UIGraphicsImageRenderer(size: CGSize(width: 256, height: 256), format: format)
        return r.image { _ in
            let text = emoji as NSString
            let attr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 210)]
            let g = text.size(withAttributes: attr)
            text.draw(at: CGPoint(x: (256 - g.width) / 2, y: (256 - g.height) / 2), withAttributes: attr)
        }
    }

    static func schatten(breite: CGFloat, y: Float) -> SCNNode {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let bild = UIGraphicsImageRenderer(size: CGSize(width: 128, height: 128), format: format).image { ctx in
            let farben = [UIColor(white: 0, alpha: 0.45).cgColor, UIColor(white: 0, alpha: 0).cgColor] as CFArray
            if let verlauf = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: farben, locations: [0, 1]) {
                ctx.cgContext.drawRadialGradient(verlauf, startCenter: CGPoint(x: 64, y: 64), startRadius: 0,
                                                 endCenter: CGPoint(x: 64, y: 64), endRadius: 64, options: [])
            }
        }
        let flaeche = SCNPlane(width: breite, height: breite * 0.45)
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = bild
        m.writesToDepthBuffer = false
        flaeche.firstMaterial = m
        let n = SCNNode(geometry: flaeche)
        n.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        n.position = SCNVector3(0, y, 0.1)
        return n
    }

    /// Kleine goldene Funken, die um einen Meister kreisen.
    static func funkeln(hoehe: Float) -> SCNNode {
        let ring = SCNNode()
        ring.position = SCNVector3(0, hoehe, 0)
        for i in 0..<6 {
            let winkel = Float(i) / 6 * Float.pi * 2
            let g = SCNSphere(radius: 0.06)
            g.firstMaterial = material(UIColor(red: 1.0, green: 0.86, blue: 0.3, alpha: 1), leuchten: true)
            let funke = SCNNode(geometry: g)
            funke.position = SCNVector3(cos(winkel) * 0.75, 0, sin(winkel) * 0.75)
            ring.addChildNode(funke)
        }
        ring.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 6)))
        return ring
    }

    // MARK: Die Eule Olli

    /// Olli aus weichen Formen. Sie dreht ihr Gesicht immer zur Kamera und flattert.
    static func eule(flug: EulenFlug) -> SCNNode {
        let wurzel = SCNNode()
        // Hält die Position. Beim Kreisen dreht sich der Ring darüber.
        let halter = SCNNode()
        // Dreht das Gesicht zur Kamera, nur um die senkrechte Achse
        let ausrichten = SCNNode()
        let blick = SCNBillboardConstraint()
        blick.freeAxes = .Y
        ausrichten.constraints = [blick]
        halter.addChildNode(ausrichten)
        // Schaut sich ab und zu um
        let schauen = SCNNode()
        ausrichten.addChildNode(schauen)
        let modell = eulenModell()
        modell.name = "eule"
        schauen.addChildNode(modell)
        ausrichten.addChildNode(trefferFlaeche(radius: 0.5))

        let hoch = SCNAction.moveBy(x: 0, y: 0.12, z: 0, duration: 0.9)
        hoch.timingMode = .easeInEaseOut
        let runter = SCNAction.moveBy(x: 0, y: -0.12, z: 0, duration: 0.9)
        runter.timingMode = .easeInEaseOut
        halter.runAction(.repeatForever(.sequence([hoch, runter])), forKey: "schweben")

        switch flug {
        case .kreisen:
            // Ein großer, langsamer Kreis über dem Ei
            let ring = SCNNode()
            ring.position = SCNVector3(0, 1.15, 0)
            halter.position = SCNVector3(1.35, 0, 0)
            ring.addChildNode(halter)
            ring.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)), forKey: "kreisen")
            wurzel.addChildNode(ring)
        case .schweben, .aus:
            // Links oben neben dem Tier, so stört sie keinen Hut
            halter.position = SCNVector3(-1.5, 1.15, 0.2)
            wurzel.addChildNode(halter)
            schauen.runAction(umschauen(), forKey: "umschauen")
        }
        return wurzel
    }

    static func eulenModell() -> SCNNode {
        let braun = UIColor(red: 0.58, green: 0.40, blue: 0.27, alpha: 1)
        let dunkelBraun = UIColor(red: 0.42, green: 0.28, blue: 0.19, alpha: 1)
        let creme = UIColor(red: 0.99, green: 0.92, blue: 0.78, alpha: 1)
        let orange = UIColor(red: 1.0, green: 0.68, blue: 0.22, alpha: 1)
        let dunkel = UIColor(red: 0.12, green: 0.10, blue: 0.16, alpha: 1)

        let m = SCNNode()
        let figur = SCNNode()
        figur.scale = SCNVector3(0.72, 0.72, 0.72)
        m.addChildNode(figur)

        // Körper mit hellem Bauch
        figur.addChildNode(kugel(0.36, braun, SCNVector3(0, 0, 0), skala: SCNVector3(1, 1.12, 0.92)))
        figur.addChildNode(kugel(0.25, creme, SCNVector3(0, -0.1, 0.2), skala: SCNVector3(1, 1.1, 0.55)))
        // Zwei helle Augenscheiben, darin große dunkle Augen mit Glanzpunkt
        for x: Float in [-1, 1] {
            figur.addChildNode(kugel(0.15, creme, SCNVector3(0.14 * x, 0.14, 0.26), skala: SCNVector3(1, 1, 0.45)))
        }
        let augen = SCNNode()
        augen.position = SCNVector3(0, 0.14, 0)
        for x: Float in [-1, 1] {
            let auge = kugel(0.085, dunkel, SCNVector3(0.14 * x, 0, 0.32), skala: SCNVector3(1, 1, 0.6), glanz: 0.9)
            auge.addChildNode(kugel(0.03, .white, SCNVector3(0.025, 0.035, 0.05), glanz: 0))
            augen.addChildNode(auge)
        }
        augen.addAnimation(blinzeln(), forKey: "blinzeln")
        figur.addChildNode(augen)
        // Der Schnabel zeigt nach unten
        figur.addChildNode(kegel(unten: 0.055, hoehe: 0.14, orange, SCNVector3(0, 0.02, 0.36),
                                 winkel: SCNVector3(2.7, 0, 0)))
        // Federohren
        for x: Float in [-1, 1] {
            figur.addChildNode(kegel(unten: 0.08, hoehe: 0.2, dunkelBraun, SCNVector3(0.2 * x, 0.42, 0.02),
                                     winkel: SCNVector3(0, 0, -0.5 * x)))
        }
        // Flügel mit Gelenk an der Schulter, damit sie richtig auf und ab schlagen
        for x: Float in [-1, 1] {
            let gelenk = SCNNode()
            gelenk.position = SCNVector3(0.3 * x, 0.08, -0.02)
            gelenk.addChildNode(kugel(0.2, dunkelBraun, SCNVector3(0.14 * x, -0.1, 0), skala: SCNVector3(0.55, 1.1, 0.7)))
            gelenk.addAnimation(eulenFlattern(x: x), forKey: "flattern")
            figur.addChildNode(gelenk)
        }
        // Füße
        for x: Float in [-1, 1] {
            figur.addChildNode(kugel(0.06, orange, SCNVector3(0.1 * x, -0.4, 0.12), skala: SCNVector3(1.2, 0.6, 1.3)))
        }
        return m
    }

    /// Unsichtbare Kugel um die Eule, damit auch kleine Finger sie gut treffen.
    static func trefferFlaeche(radius: CGFloat) -> SCNNode {
        let g = SCNSphere(radius: radius)
        let m = SCNMaterial()
        m.colorBufferWriteMask = []
        m.writesToDepthBuffer = false
        g.firstMaterial = m
        return SCNNode(geometry: g)
    }

    /// Schnell flattern, kurz gleiten, wieder flattern.
    static func eulenFlattern(x: Float) -> CAAnimation {
        let a = CAKeyframeAnimation(keyPath: "eulerAngles.z")
        let oben = 0.75 * x
        a.values = [0, oben, 0, oben, 0, oben, 0, 0]
        a.keyTimes = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 1]
        a.duration = 1.4
        a.repeatCount = .infinity
        a.isAdditive = true
        a.timingFunctions = Array(repeating: CAMediaTimingFunction(name: .easeInEaseOut), count: 7)
        return a
    }

    static func umschauen() -> SCNAction {
        let links = SCNAction.rotateTo(x: 0, y: 0.45, z: 0.08, duration: 0.5, usesShortestUnitArc: true)
        links.timingMode = .easeInEaseOut
        let rechts = SCNAction.rotateTo(x: 0, y: -0.45, z: -0.08, duration: 0.7, usesShortestUnitArc: true)
        rechts.timingMode = .easeInEaseOut
        let mitte = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.5, usesShortestUnitArc: true)
        mitte.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([.wait(duration: 4, withRange: 3), links, .wait(duration: 0.5),
                                         rechts, .wait(duration: 0.5), mitte]))
    }

    /// Olli nickt zweimal und plustert sich kurz auf, wenn sie spricht.
    static func nicken() -> SCNAction {
        let vor = SCNAction.rotateBy(x: 0.22, y: 0, z: 0, duration: 0.12)
        vor.timingMode = .easeOut
        let zurueck = SCNAction.rotateBy(x: -0.22, y: 0, z: 0, duration: 0.14)
        zurueck.timingMode = .easeIn
        let nick = SCNAction.sequence([vor, zurueck])
        let plustern = SCNAction.sequence([.scale(to: 1.12, duration: 0.12), .scale(to: 1.0, duration: 0.2)])
        return .group([.sequence([nick, nick]), plustern])
    }

    // MARK: Bewegungen

    private static func vektor(_ x: Float, _ y: Float, _ z: Float) -> NSValue {
        NSValue(scnVector3: SCNVector3(x, y, z))
    }

    static func atmen() -> CAAnimation {
        let a = CABasicAnimation(keyPath: "scale")
        a.fromValue = vektor(1, 1, 1)
        a.toValue = vektor(1.035, 0.965, 1.035)
        a.duration = 1.5
        a.autoreverses = true
        a.repeatCount = .infinity
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return a
    }

    static func blinzeln() -> CAAnimation {
        let a = CAKeyframeAnimation(keyPath: "scale")
        a.values = [vektor(1, 1, 1), vektor(1, 1, 1), vektor(1, 0.08, 1), vektor(1, 1, 1), vektor(1, 1, 1)]
        a.keyTimes = [0, 0.9, 0.93, 0.96, 1]
        a.duration = 4.2
        a.repeatCount = .infinity
        return a
    }

    static func ohrWackeln(versatz: Double) -> CAAnimation {
        let a = CAKeyframeAnimation(keyPath: "eulerAngles.z")
        a.values = [0, 0, 0.18, -0.08, 0, 0]
        a.keyTimes = [0, 0.7, 0.76, 0.82, 0.88, 1]
        a.duration = 3.6
        a.repeatCount = .infinity
        a.isAdditive = true
        a.timeOffset = versatz
        return a
    }

    static func schwanzWedeln() -> CAAnimation {
        let a = CABasicAnimation(keyPath: "eulerAngles.y")
        a.fromValue = -0.25
        a.toValue = 0.25
        a.duration = 0.9
        a.autoreverses = true
        a.repeatCount = .infinity
        a.isAdditive = true
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return a
    }

    static func fluegelSchlag(x: Float) -> CAAnimation {
        let a = CABasicAnimation(keyPath: "eulerAngles.z")
        a.fromValue = 0
        a.toValue = 0.35 * x
        a.duration = 0.7
        a.autoreverses = true
        a.repeatCount = .infinity
        a.isAdditive = true
        a.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        return a
    }

    static func traenenTropfen() -> CAAnimation {
        let a = CABasicAnimation(keyPath: "position.y")
        a.fromValue = 0
        a.toValue = -0.35
        a.duration = 1.8
        a.repeatCount = .infinity
        a.isAdditive = true
        a.timingFunction = CAMediaTimingFunction(name: .easeIn)
        return a
    }

    static func schweben() -> SCNAction {
        let hoch = SCNAction.moveBy(x: 0, y: 0.06, z: 0, duration: 1.6)
        hoch.timingMode = .easeInEaseOut
        let runter = SCNAction.moveBy(x: 0, y: -0.06, z: 0, duration: 1.6)
        runter.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([hoch, runter]))
    }

    static func kopfNeigen() -> SCNAction {
        let links = SCNAction.rotateTo(x: 0, y: 0.18, z: 0.06, duration: 1.4, usesShortestUnitArc: true)
        links.timingMode = .easeInEaseOut
        let rechts = SCNAction.rotateTo(x: 0, y: -0.18, z: -0.06, duration: 1.4, usesShortestUnitArc: true)
        rechts.timingMode = .easeInEaseOut
        let mitte = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 1.0, usesShortestUnitArc: true)
        mitte.timingMode = .easeInEaseOut
        return .repeatForever(.sequence([.wait(duration: 2.5, withRange: 2), links, .wait(duration: 0.6),
                                         rechts, .wait(duration: 0.6), mitte]))
    }

    static func freudenHopser() -> SCNAction {
        .repeatForever(.sequence([.wait(duration: 5, withRange: 3), kleinerSprung(), kleinerSprung()]))
    }

    static func kleinerSprung() -> SCNAction {
        let hoch = SCNAction.moveBy(x: 0, y: 0.25, z: 0, duration: 0.16)
        hoch.timingMode = .easeOut
        let runter = SCNAction.moveBy(x: 0, y: -0.25, z: 0, duration: 0.18)
        runter.timingMode = .easeIn
        return .sequence([hoch, runter])
    }

    /// Großer Sprung mit Drehung, wenn das Kind tippt.
    static func sprung() -> SCNAction {
        let hoch = SCNAction.moveBy(x: 0, y: 0.75, z: 0, duration: 0.24)
        hoch.timingMode = .easeOut
        let runter = SCNAction.moveBy(x: 0, y: -0.75, z: 0, duration: 0.3)
        runter.timingMode = .easeIn
        let drehen = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.54)
        drehen.timingMode = .easeInEaseOut
        let quetschen = SCNAction.sequence([.scale(to: 1.08, duration: 0.08), .scale(to: 1.0, duration: 0.12)])
        return .sequence([.group([.sequence([hoch, runter]), drehen]), quetschen])
    }

    /// Freudentanz nach einer geschafften Runde: drehen, hüpfen, wackeln.
    static func tanz() -> SCNAction {
        let drehen = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 0.9)
        drehen.timingMode = .easeInEaseOut
        let links = SCNAction.rotateBy(x: 0, y: 0, z: 0.25, duration: 0.15)
        let rechts = SCNAction.rotateBy(x: 0, y: 0, z: -0.5, duration: 0.3)
        let mitte = SCNAction.rotateBy(x: 0, y: 0, z: 0.25, duration: 0.15)
        let schunkeln = SCNAction.sequence([links, rechts, mitte])
        return .sequence([.group([drehen, .sequence([kleinerSprung(), kleinerSprung(), kleinerSprung()])]),
                          schunkeln, schunkeln])
    }

    static func wackeln() -> SCNAction {
        let links = SCNAction.rotateTo(x: 0, y: 0, z: 0.16, duration: 0.18, usesShortestUnitArc: true)
        let rechts = SCNAction.rotateTo(x: 0, y: 0, z: -0.16, duration: 0.18, usesShortestUnitArc: true)
        let mitte = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.14, usesShortestUnitArc: true)
        return .repeatForever(.sequence([.wait(duration: 2.2, withRange: 1.5), links, rechts, links, mitte]))
    }
}
