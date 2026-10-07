import SwiftUI
import SpriteKit
import UIKit

// ============================================================
// MARK: - Zahlenlauf
// Grafiken: Jumper Pack von Kenney (www.kenney.nl), CC0
// ============================================================

enum SpielBild {
    static let held = ["held_lauf1", "held_lauf2"]
    static let heldSprung = "held_sprung"
    static let heldAua = "held_aua"
    static let bodenHindernisse = ["hindernis_kaktus", "hindernis_kugel", "hindernis_pilz"]
    static let flieger = ["flieger_robo", "flieger_vogel"]
    static let muenze = "muenze"
    static let feder = "feder"
    static let fluegel = "fluegel"
    static let leben = "leben"
    static let boden = "boden"
    static let huegel = "huegel"
}

final class LaufSzene: SKScene {

    /// Wird nach jedem Durchgang mit der Punktzahl aufgerufen.
    var beiEnde: ((Int) -> Void)?

    // MARK: Knoten

    private let spieler = SKSpriteNode(imageNamed: SpielBild.held[0])
    private let punkteLabel = SKLabelNode(text: "0")
    private let stufeLabel = SKLabelNode(text: "Stufe 1")
    private let infoLabel = SKLabelNode(text: "Tippen und losrennen")
    private let untertitelLabel = SKLabelNode(text: "Tippen zum Springen, zweites Tippen für den Doppelsprung")

    private var laufBilder: [SKTexture] = []
    private let sprungBild = SKTexture(imageNamed: SpielBild.heldSprung)
    private let auaBild = SKTexture(imageNamed: SpielBild.heldAua)

    private var bodenKacheln: [SKSpriteNode] = []
    private var huegel: [SKSpriteNode] = []
    private var lebenBilder: [SKSpriteNode] = []

    private enum Art { case hindernis, flieger, muenze, feder, fluegel }
    private struct Objekt {
        let knoten: SKSpriteNode
        let art: Art
    }
    private var objekte: [Objekt] = []

    // MARK: Zustand

    private var vy: CGFloat = 0
    private var amBoden = true
    private var spruenge = 0
    private var haltend = false
    private var leben = 3
    private var unverwundbarRest: CGFloat = 0
    private var fluegelRest: CGFloat = 0
    private var laeuft = false
    private var vorbei = false
    private var punkte = 0
    private var stufe = 1
    private var vorigeZeit: TimeInterval = 0
    private var bisHindernis: CGFloat = 500
    private var bisMuenze: CGFloat = 320
    private var bisFeder: CGFloat = 1600

    // MARK: Werte, die das Spielgefühl bestimmen

    private let schwerkraft: CGFloat = -2500
    private let haltFaktor: CGFloat = 0.42        // Beim Halten fällt der Hase langsamer
    private let sprungKraft: CGFloat = 830
    private let doppelKraft: CGFloat = 720
    private let federKraft: CGFloat = 1450
    private let maxLeben = 3

    private let spielerHoehe: CGFloat = 70
    private let hindernisHoehe: CGFloat = 58
    private let fliegerHoehe: CGFloat = 52
    private let muenzGroesse: CGFloat = 38
    private let federHoehe: CGFloat = 46
    private let fluegelGroesse: CGFloat = 44
    private let bodenHoehe: CGFloat = 56
    private let kachelBreite: CGFloat = 220

    private var bodenY: CGFloat { size.height * 0.24 }
    private var ruheY: CGFloat { bodenY + spielerHoehe / 2 }
    private var tempo: CGFloat { LaufBalance.tempo(stufe: stufe) }
    private var maxSpruenge: Int { fluegelRest > 0 ? 3 : 2 }

    // MARK: Aufbau

    override func didMove(to view: SKView) {
        backgroundColor = UIColor(Theme.tiefNavy)
        laufBilder = SpielBild.held.map { SKTexture(imageNamed: $0) }

        for _ in 0..<2 {
            let berg = SKSpriteNode(imageNamed: SpielBild.huegel)
            berg.anchorPoint = CGPoint(x: 0, y: 0)
            berg.alpha = 0.16
            berg.zPosition = 0
            addChild(berg)
            huegel.append(berg)
        }

        for _ in 0..<8 {
            let kachel = SKSpriteNode(imageNamed: SpielBild.boden)
            kachel.anchorPoint = CGPoint(x: 0, y: 1)
            kachel.size = CGSize(width: kachelBreite, height: bodenHoehe)
            kachel.zPosition = 2
            addChild(kachel)
            bodenKacheln.append(kachel)
        }

        spieler.size = groesse(fuer: laufBilder[0], hoehe: spielerHoehe)
        spieler.zPosition = 10
        addChild(spieler)
        starteLaufBild()

        for _ in 0..<maxLeben {
            let herz = SKSpriteNode(imageNamed: SpielBild.leben)
            herz.size = CGSize(width: 24, height: 32)
            herz.zPosition = 20
            addChild(herz)
            lebenBilder.append(herz)
        }

        beschrifte(punkteLabel, groesse: 30, farbe: UIColor(Theme.gelb), fett: true)
        punkteLabel.horizontalAlignmentMode = .left
        punkteLabel.verticalAlignmentMode = .top

        beschrifte(stufeLabel, groesse: 17, farbe: .white, fett: true)
        stufeLabel.horizontalAlignmentMode = .right
        stufeLabel.verticalAlignmentMode = .top

        beschrifte(infoLabel, groesse: 34, farbe: .white, fett: true)
        infoLabel.verticalAlignmentMode = .center

        beschrifte(untertitelLabel, groesse: 17, farbe: UIColor(Theme.gelb), fett: false)
        untertitelLabel.verticalAlignmentMode = .center

        ordneNeu()
        zeichneLeben()
    }

    private func beschrifte(_ label: SKLabelNode, groesse: CGFloat, farbe: UIColor, fett: Bool) {
        label.fontName = fett ? "AvenirNext-Heavy" : "AvenirNext-Medium"
        label.fontSize = groesse
        label.fontColor = farbe
        label.zPosition = 20
        if label.parent == nil { addChild(label) }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        ordneNeu()
    }

    /// Hält das Seitenverhältnis des Bildes bei vorgegebener Höhe.
    private func groesse(fuer bild: SKTexture, hoehe: CGFloat) -> CGSize {
        let roh = bild.size()
        guard roh.height > 0 else { return CGSize(width: hoehe, height: hoehe) }
        return CGSize(width: hoehe * roh.width / roh.height, height: hoehe)
    }

    private func ordneNeu() {
        guard size.width > 0, size.height > 0 else { return }

        for (i, berg) in huegel.enumerated() {
            let breite = max(size.width * 1.2, 600)
            berg.size = CGSize(width: breite, height: breite * 0.5)
            berg.position = CGPoint(x: CGFloat(i) * breite, y: bodenY - 10)
        }
        for (i, kachel) in bodenKacheln.enumerated() {
            kachel.position = CGPoint(x: CGFloat(i) * kachelBreite, y: bodenY)
        }
        spieler.position = CGPoint(x: size.width * 0.22,
                                   y: amBoden ? ruheY : max(spieler.position.y, ruheY))
        punkteLabel.position = CGPoint(x: 24, y: size.height - 24)
        stufeLabel.position = CGPoint(x: size.width - 24, y: size.height - 26)
        infoLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        untertitelLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62 - 38)
        for (i, herz) in lebenBilder.enumerated() {
            herz.position = CGPoint(x: 30 + CGFloat(i) * 30, y: size.height - 74)
        }
    }

    private func zeichneLeben() {
        for (i, herz) in lebenBilder.enumerated() {
            herz.alpha = i < leben ? 1.0 : 0.18
        }
    }

    private func starteLaufBild() {
        spieler.removeAction(forKey: "laufen")
        guard laufBilder.count > 1 else { return }
        spieler.run(SKAction.repeatForever(
            SKAction.animate(with: laufBilder, timePerFrame: 0.13, resize: false, restore: false)
        ), withKey: "laufen")
    }

    // MARK: Steuerung

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        haltend = true
        if vorbei {
            neuStarten()
        } else if !laeuft {
            laeuft = true
            infoLabel.text = ""
            untertitelLabel.text = ""
        } else {
            springen()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        loslassen()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        loslassen()
    }

    /// Kurz tippen heißt kleiner Sprung, Halten heißt hoher Sprung.
    private func loslassen() {
        haltend = false
        if vy > 0 { vy *= 0.55 }
    }

    private func springen() {
        guard spruenge < maxSpruenge else { return }
        vy = spruenge == 0 ? sprungKraft : doppelKraft
        spruenge += 1
        amBoden = false
        spieler.removeAction(forKey: "laufen")
        spieler.texture = sprungBild
        if spruenge > 1 { staub() }
    }

    private func staub() {
        let kreis = SKShapeNode(circleOfRadius: 9)
        kreis.fillColor = UIColor.white.withAlphaComponent(0.5)
        kreis.strokeColor = .clear
        kreis.zPosition = 9
        kreis.position = CGPoint(x: spieler.position.x, y: spieler.position.y - spielerHoehe / 2)
        addChild(kreis)
        kreis.run(SKAction.sequence([
            SKAction.group([SKAction.scale(to: 2.2, duration: 0.3),
                            SKAction.fadeOut(withDuration: 0.3)]),
            SKAction.removeFromParent()
        ]))
    }

    private func neuStarten() {
        for o in objekte { o.knoten.removeFromParent() }
        objekte = []
        punkte = 0
        stufe = 1
        leben = maxLeben
        vy = 0
        spruenge = 0
        amBoden = true
        vorbei = false
        laeuft = true
        unverwundbarRest = 0
        fluegelRest = 0
        bisHindernis = 500
        bisMuenze = 320
        bisFeder = 1600
        spieler.alpha = 1
        spieler.texture = laufBilder.first
        spieler.position = CGPoint(x: size.width * 0.22, y: ruheY)
        punkteLabel.text = "0"
        stufeLabel.text = "Stufe 1"
        infoLabel.text = ""
        untertitelLabel.text = ""
        zeichneLeben()
        starteLaufBild()
    }

    // MARK: Spielschleife

    override func update(_ currentTime: TimeInterval) {
        let roh = currentTime - vorigeZeit
        vorigeZeit = currentTime
        guard roh > 0 else { return }
        let dt = CGFloat(min(roh, 1.0 / 30.0))

        bewegeHuegel(dt)
        guard laeuft, !vorbei else { return }

        zaehleZeiten(dt)
        bewegeSpieler(dt)

        let strecke = tempo * dt
        bewegeBoden(strecke)
        setzeNachschub(strecke)
        bewegeUndPruefe(strecke)
        pruefeStufe()
    }

    private func zaehleZeiten(_ dt: CGFloat) {
        if unverwundbarRest > 0 {
            unverwundbarRest -= dt
            spieler.alpha = Int(unverwundbarRest * 12) % 2 == 0 ? 0.3 : 1.0
            if unverwundbarRest <= 0 { spieler.alpha = 1 }
        }
        if fluegelRest > 0 {
            fluegelRest -= dt
            if fluegelRest <= 0 { spieler.colorBlendFactor = 0 }
        }
    }

    private func bewegeSpieler(_ dt: CGFloat) {
        // Beim Halten wirkt die Schwerkraft schwächer, solange es aufwärts geht
        let g = (haltend && vy > 0) ? schwerkraft * haltFaktor : schwerkraft
        vy += g * dt
        spieler.position.y += vy * dt

        let decke = size.height - 40
        if spieler.position.y > decke {
            spieler.position.y = decke
            vy = min(vy, 0)
        }
        if spieler.position.y <= ruheY {
            spieler.position.y = ruheY
            vy = 0
            if !amBoden {
                amBoden = true
                spruenge = 0
                starteLaufBild()
            }
        }
    }

    private func bewegeHuegel(_ dt: CGFloat) {
        let breite = huegel.first?.size.width ?? size.width
        for berg in huegel {
            berg.position.x -= 46 * dt
            if berg.position.x <= -breite {
                berg.position.x += breite * CGFloat(huegel.count)
            }
        }
    }

    private func bewegeBoden(_ strecke: CGFloat) {
        let gesamt = kachelBreite * CGFloat(bodenKacheln.count)
        for kachel in bodenKacheln {
            kachel.position.x -= strecke
            if kachel.position.x <= -kachelBreite {
                kachel.position.x += gesamt
            }
        }
    }

    private func pruefeStufe() {
        let neu = LaufBalance.stufe(punkte: punkte)
        guard neu != stufe else { return }
        stufe = neu
        stufeLabel.text = "Stufe \(stufe)"
        stufeLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.5, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.25)
        ]))
    }

    // MARK: Nachschub

    private func setzeNachschub(_ strecke: CGFloat) {
        bisHindernis -= strecke
        if bisHindernis <= 0 {
            if Double.random(in: 0..<1) < LaufBalance.fliegerAnteil(stufe: stufe) {
                setzeFlieger()
            } else {
                setzeHindernis()
            }
            bisHindernis = CGFloat.random(in: LaufBalance.abstand(stufe: stufe))
        }
        bisMuenze -= strecke
        if bisMuenze <= 0 {
            setzeMuenzBogen()
            bisMuenze = CGFloat.random(in: 620...1000)
        }
        bisFeder -= strecke
        if bisFeder <= 0 {
            if stufe >= LaufBalance.federAbStufe { setzeFeder() }
            bisFeder = CGFloat.random(in: 1500...2600)
        }
    }

    private func setzeHindernis() {
        let name = SpielBild.bodenHindernisse.randomElement() ?? SpielBild.bodenHindernisse[0]
        let knoten = SKSpriteNode(imageNamed: name)
        knoten.size = groesse(fuer: knoten.texture ?? SKTexture(), hoehe: hindernisHoehe)
        knoten.zPosition = 5
        knoten.position = CGPoint(x: size.width + 80, y: bodenY + hindernisHoehe / 2)
        addChild(knoten)
        objekte.append(Objekt(knoten: knoten, art: .hindernis))
    }

    private func setzeFlieger() {
        let name = SpielBild.flieger.randomElement() ?? SpielBild.flieger[0]
        let knoten = SKSpriteNode(imageNamed: name)
        knoten.size = groesse(fuer: knoten.texture ?? SKTexture(), hoehe: fliegerHoehe)
        knoten.zPosition = 5
        let hoehe = CGFloat.random(in: 120...190)
        knoten.position = CGPoint(x: size.width + 80, y: bodenY + hoehe)
        knoten.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 18, duration: 0.6),
            SKAction.moveBy(x: 0, y: -18, duration: 0.6)
        ])))
        addChild(knoten)
        objekte.append(Objekt(knoten: knoten, art: .flieger))
    }

    private func setzeMuenzBogen() {
        let anzahl = 5
        for i in 0..<anzahl {
            let t = CGFloat(i)
            let knoten = SKSpriteNode(imageNamed: SpielBild.muenze)
            knoten.size = CGSize(width: muenzGroesse, height: muenzGroesse)
            knoten.zPosition = 5
            let bogen = sin(t / CGFloat(anzahl - 1) * .pi)
            knoten.position = CGPoint(x: size.width + 60 + t * 52,
                                      y: bodenY + 56 + bogen * 112)
            knoten.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.scaleX(to: 0.25, duration: 0.5),
                SKAction.scaleX(to: 1.0, duration: 0.5)
            ])))
            addChild(knoten)
            objekte.append(Objekt(knoten: knoten, art: .muenze))
        }
        // Gelegentlich hängen Flügel am Ende des Bogens
        if stufe >= LaufBalance.federAbStufe, Double.random(in: 0..<1) < 0.22 {
            let knoten = SKSpriteNode(imageNamed: SpielBild.fluegel)
            knoten.size = CGSize(width: fluegelGroesse, height: fluegelGroesse)
            knoten.zPosition = 6
            knoten.position = CGPoint(x: size.width + 60 + CGFloat(anzahl) * 52,
                                      y: bodenY + 140)
            knoten.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.rotate(byAngle: 0.25, duration: 0.4),
                SKAction.rotate(byAngle: -0.25, duration: 0.4)
            ])))
            addChild(knoten)
            objekte.append(Objekt(knoten: knoten, art: .fluegel))
        }
    }

    private func setzeFeder() {
        let knoten = SKSpriteNode(imageNamed: SpielBild.feder)
        knoten.size = groesse(fuer: knoten.texture ?? SKTexture(), hoehe: federHoehe)
        knoten.zPosition = 4
        knoten.position = CGPoint(x: size.width + 70, y: bodenY + federHoehe / 2)
        addChild(knoten)
        objekte.append(Objekt(knoten: knoten, art: .feder))
    }

    // MARK: Bewegen und Treffer prüfen

    private func bewegeUndPruefe(_ strecke: CGFloat) {
        var bleiben: [Objekt] = []
        for o in objekte {
            o.knoten.position.x -= strecke

            switch o.art {
            case .hindernis, .flieger:
                if unverwundbarRest <= 0, trifft(o.knoten, breite: 38, hoehe: 46) {
                    treffer(o.knoten)
                    continue
                }
                if o.knoten.position.x < -90 {
                    o.knoten.removeFromParent()
                    punkte += 2
                    continue
                }
            case .muenze:
                if trifft(o.knoten, breite: 36, hoehe: 40) {
                    punkte += 10
                    funkel(o.knoten.position)
                    o.knoten.removeFromParent()
                    continue
                }
            case .fluegel:
                if trifft(o.knoten, breite: 40, hoehe: 44) {
                    fluegelRest = 8
                    spieler.color = UIColor(Theme.gelb)
                    spieler.colorBlendFactor = 0.35
                    funkel(o.knoten.position)
                    o.knoten.removeFromParent()
                    continue
                }
            case .feder:
                if trifft(o.knoten, breite: 40, hoehe: 44), vy <= 0 {
                    vy = federKraft
                    spruenge = 1
                    amBoden = false
                    spieler.removeAction(forKey: "laufen")
                    spieler.texture = sprungBild
                    o.knoten.run(SKAction.sequence([
                        SKAction.scaleY(to: 0.5, duration: 0.06),
                        SKAction.scaleY(to: 1.0, duration: 0.12)
                    ]))
                }
            }

            if o.knoten.position.x < -120 {
                o.knoten.removeFromParent()
            } else {
                bleiben.append(o)
            }
        }
        objekte = bleiben
        punkteLabel.text = "\(punkte)"
    }

    private func treffer(_ knoten: SKSpriteNode) {
        knoten.removeFromParent()
        leben -= 1
        zeichneLeben()
        unverwundbarRest = 1.6
        spieler.texture = auaBild
        spieler.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.3),
            SKAction.run { [weak self] in
                guard let self, !self.vorbei else { return }
                if self.amBoden { self.starteLaufBild() } else { self.spieler.texture = self.sprungBild }
            }
        ]))
        if leben <= 0 { ende() }
    }

    private func funkel(_ ort: CGPoint) {
        let stern = SKLabelNode(text: "✦")
        stern.fontSize = 26
        stern.fontColor = UIColor(Theme.gelb)
        stern.position = ort
        stern.zPosition = 15
        addChild(stern)
        stern.run(SKAction.sequence([
            SKAction.group([SKAction.moveBy(x: 0, y: 36, duration: 0.4),
                            SKAction.fadeOut(withDuration: 0.4)]),
            SKAction.removeFromParent()
        ]))
    }

    private func trifft(_ knoten: SKNode, breite: CGFloat, hoehe: CGFloat) -> Bool {
        abs(knoten.position.x - spieler.position.x) < breite
            && abs(knoten.position.y - spieler.position.y) < hoehe
    }

    private func ende() {
        vorbei = true
        laeuft = false
        spieler.alpha = 1
        spieler.colorBlendFactor = 0
        spieler.removeAction(forKey: "laufen")
        spieler.texture = auaBild
        infoLabel.text = "\(punkte) Punkte"
        untertitelLabel.text = "Tippen für noch einen Versuch"
        beiEnde?(punkte)
    }
}

// MARK: - Die Hülle in SwiftUI

struct SpielLaufView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var szene: LaufSzene = {
        let neu = LaufSzene(size: CGSize(width: 1024, height: 576))
        neu.scaleMode = .resizeFill
        return neu
    }()
    @State private var bestwert = Muenzen.bestwert("lauf")
    @State private var rekord = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: szene)
                .ignoresSafeArea()

            VStack(alignment: .trailing, spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.navy)
                        .frame(width: 44, height: 44)
                        .background(Theme.gelb, in: Circle())
                }
                if bestwert > 0 {
                    Text(rekord ? "Neuer Rekord: \(bestwert)" : "Bestwert: \(bestwert)")
                        .font(.system(.footnote, design: .rounded).weight(.heavy))
                        .foregroundStyle(rekord ? Theme.navy : Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(rekord ? Theme.gelb : Color.black.opacity(0.35), in: Capsule())
                }
            }
            .padding(16)
        }
        .statusBarHidden()
        .onAppear {
            szene.beiEnde = { punkte in
                if Muenzen.merkeBestwert("lauf", punkte) {
                    bestwert = punkte
                    rekord = true
                } else {
                    rekord = false
                }
            }
        }
    }
}
