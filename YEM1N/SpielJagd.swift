import SwiftUI
import SpriteKit

// ============================================================
// MARK: - Münzjagd
// Ein Bildschirm, mehrere Plattformen. Alle Münzen einsammeln, dann
// kommt die nächste Ebene. Gegner fliegen herum und nehmen ein Leben.
// ============================================================

final class JagdSzene: SKScene, SpielSzene {

    var beiEnde: ((Int) -> Void)?

    private typealias B = JagdBalance

    static func neu() -> JagdSzene {
        let szene = JagdSzene(size: CGSize(width: B.breite, height: B.hoehe))
        szene.scaleMode = .aspectFit
        return szene
    }

    // MARK: Knoten

    private let spieler = SKSpriteNode(imageNamed: "held_bereit")
    private let welt = SKNode()
    private let punkteLabel = SKLabelNode(text: "0")
    private let ebeneLabel = SKLabelNode(text: "Ebene 1")
    private let infoLabel = SKLabelNode(text: "Sammle alle Münzen")
    private let untertitelLabel = SKLabelNode(text: "Tippen zum Start")
    private var lebenBilder: [SKSpriteNode] = []

    private let bereitBild = SKTexture(imageNamed: "held_bereit")
    private let sprungBild = SKTexture(imageNamed: "held_sprung")
    private var laufBilder: [SKTexture] = []

    // MARK: Zustand

    private struct Gegner {
        let knoten: SKSpriteNode
        var v: CGVector
        let tempo: CGFloat
        let jaeger: Bool
        var aktivRest: CGFloat
    }

    private var plattformen: [JagdPlattform] = []
    private var muenzen: [SKSpriteNode] = []
    private var markiert: SKSpriteNode?
    private var gegner: [Gegner] = []

    private var vy: CGFloat = 0
    private var amBoden = true
    /// Wert des Analogsticks von -1 (links) bis 1 (rechts).
    private var stickX: CGFloat = 0
    private var stickSprung = false
    private var tasteSprung = false
    private var haelt = false
    private var sprungNeu = false
    private weak var stickFinger: UITouch?
    private var stickMitte = CGPoint(x: 140, y: 110)
    private let stickRing = SKShapeNode(circleOfRadius: JagdStick.radius)
    private let stickKnopf = SKShapeNode(circleOfRadius: 34)
    private let sprungKnopf = SKShapeNode(circleOfRadius: 60)
    private let stickRuhe = CGPoint(x: 140, y: 110)
    private var leben = B.maxLeben
    private var unverwundbar: CGFloat = 0
    private var laeuft = false
    private var wartet = false
    private var vorbei = false
    private var punkte = 0
    private var ebene = 1
    private var vorigeZeit: TimeInterval = 0

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = true
        backgroundColor = UIColor(Theme.tiefNavy)
        SpielEffekte.sternenHimmel(in: self, groesse: size)
        SpielEffekte.kamera(in: self)
        laufBilder = ["held_lauf1", "held_lauf2"].map { SKTexture(imageNamed: $0) }

        let berg = SKSpriteNode(imageNamed: "huegel")
        berg.anchorPoint = CGPoint(x: 0.5, y: 0)
        berg.size = CGSize(width: B.breite * 1.1, height: B.breite * 0.55)
        berg.position = CGPoint(x: B.breite / 2, y: B.bodenOberkante - 10)
        berg.alpha = 0.16
        berg.zPosition = 0
        addChild(berg)

        welt.zPosition = 1
        addChild(welt)

        spieler.size = SpielHilfe.groesse(fuer: bereitBild, hoehe: B.spielerHoehe)
        spieler.zPosition = 10
        addChild(spieler)

        for _ in 0..<B.maxLeben {
            let herz = SKSpriteNode(imageNamed: "leben")
            herz.size = CGSize(width: 24, height: 32)
            herz.zPosition = 30
            addChild(herz)
            lebenBilder.append(herz)
        }

        SpielHilfe.beschrifte(punkteLabel, groesse: 30, farbe: UIColor(Theme.gelb), fett: true)
        punkteLabel.horizontalAlignmentMode = .left
        punkteLabel.verticalAlignmentMode = .top
        punkteLabel.position = CGPoint(x: 24, y: B.hoehe - 20)
        addChild(punkteLabel)

        SpielHilfe.beschrifte(ebeneLabel, groesse: 18, farbe: .white, fett: true)
        ebeneLabel.verticalAlignmentMode = .top
        ebeneLabel.position = CGPoint(x: B.breite / 2, y: B.hoehe - 24)
        addChild(ebeneLabel)

        SpielHilfe.beschrifte(infoLabel, groesse: 34, farbe: .white, fett: true)
        infoLabel.verticalAlignmentMode = .center
        infoLabel.position = CGPoint(x: B.breite / 2, y: B.hoehe * 0.58)
        addChild(infoLabel)

        SpielHilfe.beschrifte(untertitelLabel, groesse: 17, farbe: UIColor(Theme.gelb), fett: false)
        untertitelLabel.verticalAlignmentMode = .center
        untertitelLabel.position = CGPoint(x: B.breite / 2, y: B.hoehe * 0.58 - 38)
        addChild(untertitelLabel)

        for (i, herz) in lebenBilder.enumerated() {
            herz.position = CGPoint(x: 36 + CGFloat(i) * 30, y: B.hoehe - 70)
        }

        baueTasten()
        baueEbene()
        stelleSpielerAufStart()
        zeichneLeben()
    }

    /// Links ein Analogstick, der dort erscheint, wo der Finger aufsetzt. Rechts ein großer Sprungknopf.
    private func baueTasten() {
        stickRing.fillColor = UIColor.white.withAlphaComponent(0.12)
        stickRing.strokeColor = UIColor.white.withAlphaComponent(0.45)
        stickRing.lineWidth = 4
        stickRing.zPosition = 25
        stickRing.position = stickRuhe
        addChild(stickRing)

        stickKnopf.fillColor = UIColor(Theme.gelb)
        stickKnopf.strokeColor = UIColor.white.withAlphaComponent(0.8)
        stickKnopf.lineWidth = 3
        stickKnopf.zPosition = 26
        stickKnopf.position = stickRuhe
        addChild(stickKnopf)

        sprungKnopf.fillColor = UIColor.white.withAlphaComponent(0.14)
        sprungKnopf.strokeColor = UIColor.white.withAlphaComponent(0.5)
        sprungKnopf.lineWidth = 4
        sprungKnopf.zPosition = 25
        sprungKnopf.position = CGPoint(x: B.breite - 120, y: 110)
        addChild(sprungKnopf)
        let pfeil = SKLabelNode(text: "⬆︎")
        SpielHilfe.beschrifte(pfeil, groesse: 44, farbe: .white, fett: true)
        pfeil.verticalAlignmentMode = .center
        sprungKnopf.addChild(pfeil)
        zeigeStick(versatz: .zero, aktiv: false)
    }

    private func zeigeStick(versatz: CGVector, aktiv: Bool) {
        stickRing.position = stickMitte
        let k = JagdStick.knopf(versatz: versatz)
        stickKnopf.position = CGPoint(x: stickMitte.x + k.dx, y: stickMitte.y + k.dy)
        stickRing.alpha = aktiv ? 1 : 0.55
        stickKnopf.alpha = aktiv ? 1 : 0.6
    }

    private func zeichneLeben() {
        for (i, herz) in lebenBilder.enumerated() {
            herz.alpha = i < leben ? 1.0 : 0.18
        }
    }

    private func stelleSpielerAufStart() {
        spieler.position = CGPoint(x: B.breite / 2, y: B.bodenOberkante + B.spielerHoehe / 2)
        spieler.xScale = 1
        spieler.alpha = 1
        spieler.texture = bereitBild
        vy = 0
        amBoden = true
    }

    /// Baut Plattformen, Münzen und Gegner der aktuellen Ebene neu auf.
    private func baueEbene() {
        welt.removeAllChildren()
        gegner = []
        muenzen = []
        markiert = nil

        let aufbau = B.ebene(ebene)
        plattformen = aufbau.plattformen

        for p in [B.boden] + plattformen {
            let istBoden = p == B.boden
            let anzahl = max(1, Int((p.breite / 110).rounded(.up)))
            let teil = p.breite / CGFloat(anzahl)
            let hoehe: CGFloat = istBoden ? 56 : 30
            for i in 0..<anzahl {
                let kachel = SKSpriteNode(imageNamed: "boden")
                kachel.anchorPoint = CGPoint(x: 0, y: 1)
                kachel.size = CGSize(width: teil + 1, height: hoehe)
                kachel.position = CGPoint(x: p.links + CGFloat(i) * teil, y: p.y + 2)
                kachel.zPosition = 3
                welt.addChild(kachel)
            }
        }
        let sockel = SKSpriteNode(color: UIColor(Theme.navy), size: CGSize(width: B.breite, height: B.bodenOberkante - 54))
        sockel.anchorPoint = CGPoint(x: 0, y: 0)
        sockel.position = CGPoint(x: 0, y: 0)
        sockel.zPosition = 2
        welt.addChild(sockel)

        for ort in aufbau.muenzen {
            let m = SKSpriteNode(imageNamed: "muenze")
            m.size = CGSize(width: 34, height: 34)
            m.position = ort
            m.zPosition = 5
            welt.addChild(m)
            muenzen.append(m)
        }
        if let erste = muenzen.randomElement() { markiere(erste) }

        erzeugeGegner()
        ebeneLabel.text = "Ebene \(ebene)"
    }

    private func markiere(_ muenze: SKSpriteNode) {
        markiert = muenze
        let ring = SKShapeNode(circleOfRadius: 26)
        ring.strokeColor = UIColor(Theme.gelb)
        ring.lineWidth = 4
        ring.fillColor = .clear
        ring.zPosition = -1
        muenze.addChild(ring)
        muenze.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.35),
            SKAction.scale(to: 1.0, duration: 0.35)
        ])))
    }

    private func erzeugeGegner() {
        let anzahl = B.gegnerAnzahl(ebene: ebene)
        let tempo = B.gegnerTempo(ebene: ebene)
        let bilder = ["flieger_robo", "flieger_vogel", "hindernis_kugel"]
        for i in 0..<anzahl {
            let knoten = SKSpriteNode(imageNamed: bilder[i % bilder.count])
            let textur = knoten.texture ?? SKTexture(imageNamed: bilder[i % bilder.count])
            knoten.size = SpielHilfe.groesse(fuer: textur, hoehe: 46)
            let vonLinks = i % 2 == 0
            knoten.position = CGPoint(x: vonLinks ? 60 : B.breite - 60,
                                      y: B.hoehe - 100 - CGFloat(i) * 24)
            knoten.zPosition = 8
            knoten.alpha = 0.3
            welt.addChild(knoten)
            let richtung: CGFloat = vonLinks ? 1 : -1
            let v = CGVector(dx: richtung * tempo * 0.82, dy: -tempo * 0.57)
            let jaeger = ebene >= B.jaegerAbEbene && i == 0
            gegner.append(Gegner(knoten: knoten, v: v, tempo: tempo, jaeger: jaeger, aktivRest: 1.4))
        }
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if vorbei {
            neuStarten()
        } else if !laeuft && !wartet {
            laeuft = true
            infoLabel.text = ""
            untertitelLabel.text = ""
        }
        for t in touches where stickFinger == nil {
            let p = t.location(in: self)
            if p.x < B.breite * 0.45 {
                // Der Stick setzt sich dorthin, wo der Finger aufsetzt, ganz auf dem Bildschirm
                stickFinger = t
                stickMitte = CGPoint(x: min(max(p.x, JagdStick.radius + 10), B.breite * 0.45),
                                     y: min(max(p.y, JagdStick.radius + 10), B.hoehe * 0.6))
                zeigeStick(versatz: .zero, aktiv: true)
            }
        }
        lies(event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { lies(event) }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        loese(touches)
        lies(event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        loese(touches)
        lies(event)
    }

    /// Lässt der Finger den Stick los, springt der Knopf zurück in die Mitte.
    private func loese(_ touches: Set<UITouch>) {
        guard let f = stickFinger, touches.contains(f) else { return }
        stickFinger = nil
        stickMitte = stickRuhe
        zeigeStick(versatz: .zero, aktiv: false)
    }

    /// Liest alle Finger: der Stick links zum Laufen (und nach oben zum Springen), rechts der Sprungknopf.
    private func lies(_ event: UIEvent?) {
        var x: CGFloat = 0
        var stickHoch = false
        var taste = false
        for t in event?.allTouches ?? [] where t.phase != .ended && t.phase != .cancelled {
            let p = t.location(in: self)
            if let f = stickFinger, t === f {
                let versatz = CGVector(dx: p.x - stickMitte.x, dy: p.y - stickMitte.y)
                let wert = JagdStick.wert(versatz: versatz)
                x = wert.dx
                stickHoch = JagdStick.springt(wert)
                zeigeStick(versatz: versatz, aktiv: true)
            } else if p.x > B.breite * 0.55 {
                taste = true
            }
        }
        if stickFinger == nil { zeigeStick(versatz: .zero, aktiv: false) }
        stickX = x
        sprungKnopf.fillColor = UIColor.white.withAlphaComponent(taste ? 0.32 : 0.14)
        let j = taste || stickHoch
        if j && !haelt { sprungNeu = true }
        if !j && haelt && vy > 0 { vy *= 0.6 }
        haelt = j
        stickSprung = stickHoch
        tasteSprung = taste
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let dt: CGFloat = vorigeZeit == 0 ? 0 : min(CGFloat(currentTime - vorigeZeit), 1.0 / 30.0)
        vorigeZeit = currentTime
        guard laeuft, !vorbei, !wartet, dt > 0 else { return }
        bewegeSpieler(dt)
        bewegeGegner(dt)
        pruefe(dt)
    }

    private func landeplatz(x: CGFloat, alt: CGFloat, neu: CGFloat) -> JagdPlattform? {
        ([B.boden] + plattformen)
            .filter { x >= $0.links - 14 && x <= $0.rechts + 14 && alt >= $0.y - 2 && neu <= $0.y }
            .max { $0.y < $1.y }
    }

    private func stehtAuf(_ ort: CGPoint) -> Bool {
        let fuss = ort.y - B.spielerHoehe / 2
        return ([B.boden] + plattformen).contains {
            ort.x >= $0.links - 14 && ort.x <= $0.rechts + 14 && abs(fuss - $0.y) < 3
        }
    }

    private func bewegeSpieler(_ dt: CGFloat) {
        let richtung: CGFloat = stickX
        var pos = spieler.position
        let alteUnterkante = pos.y - B.spielerHoehe / 2
        pos.x = min(max(pos.x + richtung * B.laufTempo * dt, 28), B.breite - 28)
        if richtung != 0 {
            spieler.xScale = richtung > 0 ? abs(spieler.xScale) : -abs(spieler.xScale)
        }

        if sprungNeu {
            sprungNeu = false
            if amBoden {
                vy = B.sprungKraft
                amBoden = false
            }
        }

        if !amBoden {
            var g = B.schwerkraft
            if haelt && vy < 0 { g *= B.schwebFaktor }
            vy += g * dt
            if haelt && vy < B.schwebFallMax { vy = B.schwebFallMax }
            pos.y += vy * dt
            let neueUnterkante = pos.y - B.spielerHoehe / 2
            if vy <= 0, let p = landeplatz(x: pos.x, alt: alteUnterkante, neu: neueUnterkante) {
                pos.y = p.y + B.spielerHoehe / 2
                vy = 0
                amBoden = true
            }
        } else if !stehtAuf(pos) {
            amBoden = false
            vy = 0
        }
        spieler.position = pos
        zeigeBild(richtung)
    }

    private func zeigeBild(_ richtung: CGFloat) {
        if !amBoden {
            spieler.removeAction(forKey: "laufen")
            spieler.texture = sprungBild
        } else if richtung != 0 {
            if spieler.action(forKey: "laufen") == nil, laufBilder.count > 1 {
                spieler.run(SKAction.repeatForever(
                    SKAction.animate(with: laufBilder, timePerFrame: 0.12, resize: false, restore: false)
                ), withKey: "laufen")
            }
        } else {
            spieler.removeAction(forKey: "laufen")
            spieler.texture = bereitBild
        }
    }

    private func bewegeGegner(_ dt: CGFloat) {
        let unten = B.bodenOberkante + 28
        let oben = B.hoehe - 60
        for i in gegner.indices {
            var g = gegner[i]
            if g.aktivRest > 0 {
                g.aktivRest -= dt
                if g.aktivRest <= 0 { g.knoten.alpha = 1 }
            }
            if g.jaeger {
                let dx = spieler.position.x - g.knoten.position.x
                let dy = spieler.position.y - g.knoten.position.y
                let d = max(hypot(dx, dy), 1)
                let wunschX = dx / d * g.tempo * 0.8
                let wunschY = dy / d * g.tempo * 0.8
                let f = min(1, 1.2 * dt)
                g.v = CGVector(dx: g.v.dx + (wunschX - g.v.dx) * f,
                               dy: g.v.dy + (wunschY - g.v.dy) * f)
            }
            var p = g.knoten.position
            p.x += g.v.dx * dt
            p.y += g.v.dy * dt
            if p.x < 26 {
                p.x = 26
                g.v.dx = abs(g.v.dx)
            } else if p.x > B.breite - 26 {
                p.x = B.breite - 26
                g.v.dx = -abs(g.v.dx)
            }
            if p.y < unten {
                p.y = unten
                g.v.dy = abs(g.v.dy)
            } else if p.y > oben {
                p.y = oben
                g.v.dy = -abs(g.v.dy)
            }
            g.knoten.position = p
            g.knoten.xScale = g.v.dx >= 0 ? 1 : -1
            gegner[i] = g
        }
    }

    private func pruefe(_ dt: CGFloat) {
        if unverwundbar > 0 {
            unverwundbar -= dt
            spieler.alpha = Int(unverwundbar * 10) % 2 == 0 ? 0.35 : 1
            if unverwundbar <= 0 { spieler.alpha = 1 }
        } else {
            for g in gegner where g.aktivRest <= 0 {
                if abs(g.knoten.position.x - spieler.position.x) < 36
                    && abs(g.knoten.position.y - spieler.position.y) < 40 {
                    treffer()
                    break
                }
            }
        }
        if vorbei { return }

        for m in muenzen {
            if abs(m.position.x - spieler.position.x) < 36
                && abs(m.position.y - spieler.position.y) < 42 {
                sammle(m)
            }
        }
        punkteLabel.text = "\(punkte)"
        if muenzen.isEmpty { ebeneGeschafft() }
    }

    private func sammle(_ m: SKSpriteNode) {
        let leuchtend = m === markiert
        punkte += leuchtend ? B.punkteLeuchtend : B.punkteMuenze
        SpielHilfe.funkel(in: self, ort: m.position, text: leuchtend ? "+\(B.punkteLeuchtend)" : "✦")
        SpielEffekte.funken(in: self, ort: m.position, anzahl: leuchtend ? 36 : 16)
        Haptik.leicht()
        muenzen.removeAll { $0 === m }
        m.removeFromParent()
        if leuchtend {
            markiert = nil
            // Die nächste leuchtende Münze liegt in der Nähe der letzten.
            let naechste = muenzen.min {
                hypot($0.position.x - m.position.x, $0.position.y - m.position.y)
                    < hypot($1.position.x - m.position.x, $1.position.y - m.position.y)
            }
            if let n = naechste { markiere(n) }
        }
    }

    private func treffer() {
        leben -= 1
        zeichneLeben()
        SpielEffekte.blitz(in: self)
        SpielEffekte.wackeln(in: self)
        Haptik.fehler()
        unverwundbar = 1.6
        vy = 380
        amBoden = false
        if leben <= 0 { ende() }
    }

    private func ebeneGeschafft() {
        punkte += B.punkteEbene
        punkteLabel.text = "\(punkte)"
        wartet = true
        infoLabel.text = "Ebene \(ebene) geschafft!"
        SpielEffekte.konfetti(in: self, ort: CGPoint(x: B.breite / 2, y: B.hoehe * 0.45))
        Haptik.erfolg()
        untertitelLabel.text = "+\(B.punkteEbene) Punkte"
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.8),
            SKAction.run { [weak self] in
                guard let self, !self.vorbei else { return }
                self.ebene += 1
                self.baueEbene()
                self.stelleSpielerAufStart()
                self.unverwundbar = 1.0
                self.infoLabel.text = ""
                self.untertitelLabel.text = ""
                self.wartet = false
            }
        ]))
    }

    private func ende() {
        vorbei = true
        laeuft = false
        spieler.alpha = 1
        spieler.removeAction(forKey: "laufen")
        spieler.texture = SKTexture(imageNamed: "held_aua")
        infoLabel.text = "\(punkte) Punkte"
        untertitelLabel.text = "Ebene \(ebene). Tippen für noch einen Versuch"
        SpielEffekte.konfetti(in: self, ort: CGPoint(x: B.breite / 2, y: B.hoehe * 0.4), anzahl: 60)
        beiEnde?(punkte)
    }

    private func neuStarten() {
        removeAllActions()
        vorbei = false
        wartet = false
        leben = B.maxLeben
        punkte = 0
        ebene = 1
        unverwundbar = 1.0
        stickX = 0
        stickSprung = false
        tasteSprung = false
        stickFinger = nil
        stickMitte = stickRuhe
        zeigeStick(versatz: .zero, aktiv: false)
        haelt = false
        sprungNeu = false
        baueEbene()
        stelleSpielerAufStart()
        zeichneLeben()
        punkteLabel.text = "0"
        infoLabel.text = ""
        untertitelLabel.text = ""
        laeuft = true
    }
}

struct SpielJagdView: View {
    var body: some View {
        SpielHuelle(schluessel: "jagd", szene: JagdSzene.neu())
    }
}
