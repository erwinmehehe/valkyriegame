import SpriteKit
import LearningCore

@MainActor final class CreatureGroveScene: AdventureScene {
    typealias GroveStage = ScienceGroveStage
    typealias HabitatChoice = ScienceHabitatChoice

    override var worldTitle: String { "Science Lab · Creature Grove" }
    override var walkable: CGRect { CGRect(x: 90, y: 135, width: 1100, height: 170) }

    let milo = MiloNode()
    var groveStage: GroveStage { state.scienceAdventure.groveStage }
    var selectedHabitat: HabitatChoice? { state.scienceAdventure.selectedHabitat }
    var groveRestored: Bool { state.scienceAdventure.groveRestored }

    private let duckPoint = CGPoint(x: 335, y: 235)
    private let habitatPoint = CGPoint(x: 610, y: 235)
    private let feetPoint = CGPoint(x: 840, y: 235)
    private let comparePoint = CGPoint(x: 1030, y: 235)
    private let finalePoint = CGPoint(x: 1150, y: 185)

    private var pondNode = SKNode()
    private var finaleNode = SKNode()
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.isHidden = true
        pip.position = CGPoint(x: -500, y: -500)

        valkyrie.position = CGPoint(x: 165, y: 175)
        valkyrie.setScale(0.5)
        milo.position = CGPoint(x: 245, y: 190)
        milo.reducedMotion = reducedMotion
        milo.setScale(0.82)
        addChild(milo)

        renderPond()
        renderFinale()
        refreshStagePresentation(animated: false)
        instruction.text = "Milo spotted a duck near the grove. Observe it before changing the habitat."
        refreshGuidanceCue()
    }

    override func buildWorld() {
        if let atlas = ArtSystem.texture("WordGardenSourceAtlas") {
            // Reuse only the high-resolution woodland/story-hollow quadrant.
            // The full source file is a multi-scene contact sheet.
            let groveTexture = SKTexture(
                rect: CGRect(x: 0, y: 0, width: 0.499, height: 0.498),
                in: atlas
            )
            groveTexture.filteringMode = .linear
            let preparedTexture = ArtSystem.retinaEnhancedTexture(
                groveTexture,
                cacheKey: "word-garden-lower-crop",
                targetPoints: size,
                sharpness: 0.20
            ) ?? groveTexture
            let backdrop = SKSpriteNode(
                texture: preparedTexture,
                color: UIColor(red: 0.58, green: 0.82, blue: 0.58, alpha: 1),
                size: size
            )
            backdrop.colorBlendFactor = 0.10
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -300
            backdrop.name = "creatureGroveBackdropHD"
            backdrop.userData = NSMutableDictionary(dictionary: [
                "retinaPrepared": true,
                "sourceAsset": "WordGardenSourceAtlas",
                "sourceCrop": "word-garden-lower-crop"
            ])
            addChild(backdrop)

            let shade = ArtSystem.box(
                size,
                color: UIColor(white: 0.02, alpha: 0.18),
                radius: 0
            )
            shade.strokeColor = .clear
            shade.position = CGPoint(x: 640, y: 360)
            shade.zPosition = -299
            addChild(shade)
        }

        let groveWash = ArtSystem.box(
            CGSize(width: 1280, height: 285),
            color: UIColor(red: 0.05, green: 0.18, blue: 0.09, alpha: 0.28),
            radius: 0
        )
        groveWash.strokeColor = .clear
        groveWash.position = CGPoint(x: 640, y: 130)
        groveWash.zPosition = -145
        addChild(groveWash)

        let path = ArtSystem.panel(
            CGSize(width: 1120, height: 108),
            fill: UIColor(red: 0.24, green: 0.21, blue: 0.15, alpha: 0.70),
            stroke: UIColor(red: 0.61, green: 0.56, blue: 0.36, alpha: 0.62),
            radius: 48,
            lineWidth: 3,
            shadowAlpha: 0.22,
            innerHighlight: UIColor(red: 0.78, green: 0.72, blue: 0.50, alpha: 0.04)
        )
        path.position = CGPoint(x: 640, y: 185)
        path.zPosition = 25
        path.name = "grovePath"
        addChild(path)

        for x in stride(from: CGFloat(160), through: CGFloat(1110), by: CGFloat(135)) {
            let steppingStone = SKShapeNode(ellipseOf: CGSize(width: 72, height: 22))
            steppingStone.fillColor = UIColor(red: 0.43, green: 0.39, blue: 0.28, alpha: 0.46)
            steppingStone.strokeColor = UIColor(red: 0.70, green: 0.65, blue: 0.44, alpha: 0.26)
            steppingStone.lineWidth = 1.5
            steppingStone.position = CGPoint(x: x, y: 205 + (Int(x) / 135 % 2 == 0 ? 7 : -4))
            steppingStone.zPosition = 29
            addChild(steppingStone)
        }

        // The high-resolution woodland crop already carries the grove canopy.
        // Avoid synthetic ellipse trees here; they flatten the painted environment
        // and compete with the actual habitat-learning objects.

        for (x, y) in [
            (CGFloat(385), CGFloat(520)),
            (CGFloat(515), CGFloat(585)),
            (CGFloat(875), CGFloat(530)),
            (CGFloat(1010), CGFloat(575))
        ] {
            let firefly = SKShapeNode(circleOfRadius: 5)
            firefly.fillColor = UIColor(red: 1.0, green: 0.88, blue: 0.34, alpha: 0.88)
            firefly.strokeColor = .clear
            firefly.glowWidth = reducedMotion ? 0 : 7
            firefly.position = CGPoint(x: x, y: y)
            firefly.zPosition = 80
            addChild(firefly)
            if !reducedMotion {
                firefly.run(.repeatForever(.sequence([
                    .moveBy(x: 8, y: 7, duration: 1.6),
                    .moveBy(x: -8, y: -7, duration: 1.6)
                ])))
            }
        }

        addDuckObservation()
        addHabitatChoices()
        addBodyPartStation()
        addHabitatComparison()
        addFinaleStone()

        _ = worldControl("⌂", name: "scienceGroveHome", at: CGPoint(x: 55, y: 665), radius: 30)
    }

    private func addDuckObservation() {
        let root = SKNode()
        root.position = duckPoint
        root.name = "scienceGroveDuck"
        root.zPosition = 520

        let rock = SKShapeNode(ellipseOf: CGSize(width: 185, height: 78))
        rock.fillColor = UIColor(red: 0.24, green: 0.20, blue: 0.14, alpha: 0.94)
        rock.strokeColor = UIColor(red: 0.58, green: 0.51, blue: 0.33, alpha: 0.86)
        rock.lineWidth = 3
        rock.position.y = 22
        rock.name = "scienceGroveDuck"
        root.addChild(rock)

        let waterHalo = SKShapeNode(ellipseOf: CGSize(width: 150, height: 34))
        waterHalo.fillColor = UIColor(red: 0.18, green: 0.55, blue: 0.61, alpha: 0.25)
        waterHalo.strokeColor = UIColor(red: 0.50, green: 0.82, blue: 0.78, alpha: 0.52)
        waterHalo.lineWidth = 2
        waterHalo.position.y = 1
        waterHalo.name = "scienceGroveDuck"
        root.addChild(waterHalo)

        let duck = ArtSystem.label("🦆", size: 58)
        duck.position = CGPoint(x: -18, y: 48)
        duck.name = "scienceGroveDuck"
        root.addChild(duck)

        let needs = ArtSystem.plaque(
            CGSize(width: 138, height: 30),
            fill: UIColor(red: 0.07, green: 0.16, blue: 0.12, alpha: 0.88),
            stroke: UIColor(red: 0.52, green: 0.72, blue: 0.47, alpha: 0.58),
            radius: 14
        )
        needs.position = CGPoint(x: 34, y: -30)
        needs.name = "scienceGroveDuck"
        root.addChild(needs)

        let needsLabel = ArtSystem.label("water · food · cover", size: 12)
        needsLabel.fontColor = UIColor(red: 0.90, green: 0.96, blue: 0.82, alpha: 1)
        needsLabel.name = "scienceGroveDuck"
        needs.addChild(needsLabel)

        addChild(root)
    }

    private func addHabitatChoices() {
        let title = ArtSystem.plaque(
            CGSize(width: 180, height: 34),
            fill: UIColor(red: 0.06, green: 0.18, blue: 0.13, alpha: 0.88),
            stroke: UIColor(red: 0.53, green: 0.75, blue: 0.48, alpha: 0.62),
            radius: 16
        )
        title.position = CGPoint(x: habitatPoint.x, y: habitatPoint.y + 120)
        title.zPosition = 520
        title.name = "scienceHabitatTitle"
        addChild(title)

        let titleLabel = ArtSystem.label("CHOOSE A HABITAT", size: 13)
        titleLabel.fontColor = UIColor(red: 0.93, green: 0.98, blue: 0.86, alpha: 1)
        title.addChild(titleLabel)

        let pond = ArtSystem.panel(
            CGSize(width: 150, height: 92),
            fill: UIColor(red: 0.09, green: 0.34, blue: 0.33, alpha: 0.95),
            stroke: UIColor(red: 0.55, green: 0.82, blue: 0.64, alpha: 0.94),
            radius: 24,
            lineWidth: 3,
            shadowAlpha: 0.28
        )
        pond.position = CGPoint(x: habitatPoint.x - 82, y: habitatPoint.y + 35)
        pond.name = "scienceHabitatPond"
        pond.zPosition = 520
        let pondIcon = ArtSystem.label("≈  ♒", size: 26)
        pondIcon.position.y = 18
        pondIcon.fontColor = UIColor(red: 0.66, green: 0.94, blue: 0.83, alpha: 1)
        pondIcon.name = "scienceHabitatPond"
        pond.addChild(pondIcon)
        let pondLabel = ArtSystem.label("pond + reeds", size: 14)
        pondLabel.position.y = -23
        pondLabel.name = "scienceHabitatPond"
        pond.addChild(pondLabel)
        addChild(pond)

        let ridge = ArtSystem.panel(
            CGSize(width: 150, height: 92),
            fill: UIColor(red: 0.36, green: 0.26, blue: 0.16, alpha: 0.95),
            stroke: UIColor(red: 0.76, green: 0.63, blue: 0.38, alpha: 0.92),
            radius: 24,
            lineWidth: 3,
            shadowAlpha: 0.28
        )
        ridge.position = CGPoint(x: habitatPoint.x + 82, y: habitatPoint.y + 35)
        ridge.name = "scienceHabitatRidge"
        ridge.zPosition = 520
        let ridgeIcon = ArtSystem.label("△  ·", size: 28)
        ridgeIcon.position.y = 18
        ridgeIcon.fontColor = UIColor(red: 0.94, green: 0.78, blue: 0.48, alpha: 1)
        ridgeIcon.name = "scienceHabitatRidge"
        ridge.addChild(ridgeIcon)
        let ridgeLabel = ArtSystem.label("dry bare ridge", size: 14)
        ridgeLabel.position.y = -23
        ridgeLabel.name = "scienceHabitatRidge"
        ridge.addChild(ridgeLabel)
        addChild(ridge)
    }

    private func addBodyPartStation() {
        let station = ArtSystem.medallion(
            radius: 64,
            fill: UIColor(red: 0.08, green: 0.22, blue: 0.18, alpha: 0.96),
            stroke: UIColor(red: 0.62, green: 0.82, blue: 0.52, alpha: 0.92),
            glow: reducedMotion ? 0 : 3
        )
        station.position = CGPoint(x: feetPoint.x, y: feetPoint.y + 55)
        station.name = "scienceWebbedFeet"
        station.zPosition = 520

        let glass = SKShapeNode(circleOfRadius: 38)
        glass.fillColor = UIColor(red: 0.35, green: 0.76, blue: 0.74, alpha: 0.14)
        glass.strokeColor = UIColor(red: 0.78, green: 0.94, blue: 0.86, alpha: 0.62)
        glass.lineWidth = 2
        glass.position.y = 8
        glass.name = "scienceWebbedFeet"
        station.addChild(glass)

        let icon = ArtSystem.label("🦆", size: 30)
        icon.position.y = 10
        icon.name = "scienceWebbedFeet"
        station.addChild(icon)

        let title = ArtSystem.label("WEBBED FEET", size: 13)
        title.position.y = 48
        title.fontColor = UIColor(red: 0.93, green: 0.98, blue: 0.84, alpha: 1)
        title.name = "scienceWebbedFeet"
        station.addChild(title)

        let motion = ArtSystem.label("push water", size: 12)
        motion.position.y = -43
        motion.fontColor = UIColor(red: 0.78, green: 0.90, blue: 0.78, alpha: 1)
        motion.name = "scienceWebbedFeet"
        station.addChild(motion)

        addChild(station)
    }

    private func addHabitatComparison() {
        let board = ArtSystem.panel(
            CGSize(width: 235, height: 150),
            fill: UIColor(red: 0.16, green: 0.14, blue: 0.09, alpha: 0.94),
            stroke: UIColor(red: 0.67, green: 0.58, blue: 0.35, alpha: 0.88),
            radius: 28,
            lineWidth: 3,
            shadowAlpha: 0.30
        )
        board.position = CGPoint(x: comparePoint.x, y: comparePoint.y + 62)
        board.name = "scienceCompareBoard"
        board.zPosition = 515

        let title = ArtSystem.label("WHICH PLACE MEETS MORE NEEDS?", size: 12)
        title.position.y = 52
        title.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.72, alpha: 1)
        board.addChild(title)

        let sheltered = ArtSystem.panel(
            CGSize(width: 92, height: 64),
            fill: UIColor(red: 0.10, green: 0.39, blue: 0.28, alpha: 0.97),
            stroke: UIColor(red: 0.58, green: 0.85, blue: 0.60, alpha: 0.92),
            radius: 18,
            lineWidth: 3,
            shadowAlpha: 0.18
        )
        sheltered.position = CGPoint(x: -55, y: -12)
        sheltered.name = "scienceCompareShelteredPond"
        let shelteredIcon = ArtSystem.label("≈", size: 25)
        shelteredIcon.position.y = 12
        shelteredIcon.name = "scienceCompareShelteredPond"
        sheltered.addChild(shelteredIcon)
        let shelteredLabel = ArtSystem.label("pond edge", size: 12)
        shelteredLabel.position.y = -18
        shelteredLabel.name = "scienceCompareShelteredPond"
        sheltered.addChild(shelteredLabel)
        board.addChild(sheltered)

        let exposed = ArtSystem.panel(
            CGSize(width: 92, height: 64),
            fill: UIColor(red: 0.39, green: 0.29, blue: 0.17, alpha: 0.97),
            stroke: UIColor(red: 0.76, green: 0.63, blue: 0.40, alpha: 0.90),
            radius: 18,
            lineWidth: 3,
            shadowAlpha: 0.18
        )
        exposed.position = CGPoint(x: 55, y: -12)
        exposed.name = "scienceCompareExposedRidge"
        let exposedIcon = ArtSystem.label("△", size: 24)
        exposedIcon.position.y = 12
        exposedIcon.name = "scienceCompareExposedRidge"
        exposed.addChild(exposedIcon)
        let exposedLabel = ArtSystem.label("bare ridge", size: 12)
        exposedLabel.position.y = -18
        exposedLabel.name = "scienceCompareExposedRidge"
        exposed.addChild(exposedLabel)
        board.addChild(exposed)

        addChild(board)
    }

    private func addFinaleStone() {
        let stone = ArtSystem.medallion(
            radius: 48,
            fill: UIColor(red: 0.12, green: 0.26, blue: 0.18, alpha: 0.96),
            stroke: groveRestored
                ? UIColor(red: 0.74, green: 0.94, blue: 0.56, alpha: 1)
                : UIColor(red: 0.50, green: 0.68, blue: 0.48, alpha: 0.82),
            glow: groveRestored && !reducedMotion ? 10 : 0
        )
        stone.position = finalePoint
        stone.name = "scienceGroveFinale"
        stone.zPosition = 540

        let label = ArtSystem.label(groveRestored ? "✦" : "◇", size: 34)
        label.fontColor = groveRestored
            ? UIColor(red: 1.0, green: 0.88, blue: 0.38, alpha: 1)
            : UIColor(red: 0.80, green: 0.87, blue: 0.74, alpha: 0.82)
        label.name = "scienceGroveFinale"
        stone.addChild(label)
        addChild(stone)
    }

    private func renderPond() {
        pondNode.removeFromParent()
        pondNode = SKNode()
        pondNode.position = CGPoint(x: 690, y: 400)
        pondNode.zPosition = 120

        let bank = SKShapeNode(ellipseOf: CGSize(width: 575, height: 168))
        bank.fillColor = UIColor(red: 0.20, green: 0.24, blue: 0.14, alpha: 0.64)
        bank.strokeColor = UIColor(red: 0.44, green: 0.52, blue: 0.27, alpha: 0.62)
        bank.lineWidth = 3
        bank.name = "grovePondBank"
        pondNode.addChild(bank)

        let shoreline = SKShapeNode(ellipseOf: CGSize(width: 552, height: 150))
        shoreline.fillColor = UIColor(red: 0.36, green: 0.43, blue: 0.22, alpha: 0.20)
        shoreline.strokeColor = UIColor(red: 0.58, green: 0.66, blue: 0.34, alpha: 0.38)
        shoreline.lineWidth = 2
        shoreline.name = "grovePondShoreline"
        pondNode.addChild(shoreline)

        let water = SKShapeNode(ellipseOf: CGSize(width: 520, height: 130))
        water.fillColor = groveRestored
            ? UIColor(red: 0.16, green: 0.58, blue: 0.64, alpha: 0.90)
            : UIColor(red: 0.16, green: 0.37, blue: 0.42, alpha: 0.72)
        water.strokeColor = groveRestored
            ? UIColor(red: 0.62, green: 0.91, blue: 0.82, alpha: 0.94)
            : UIColor(red: 0.42, green: 0.65, blue: 0.61, alpha: 0.72)
        water.lineWidth = 4
        water.position.y = 2
        pondNode.addChild(water)

        let reflection = SKShapeNode(ellipseOf: CGSize(width: 380, height: 44))
        reflection.fillColor = UIColor(red: 0.72, green: 0.93, blue: 0.91, alpha: groveRestored ? 0.14 : 0.08)
        reflection.strokeColor = .clear
        reflection.position = CGPoint(x: -40, y: 22)
        reflection.name = "grovePondReflection"
        pondNode.addChild(reflection)

        for (index, spec) in [
            (CGFloat(-125), CGFloat(18), CGFloat(118), CGFloat(24)),
            (CGFloat(30), CGFloat(-6), CGFloat(154), CGFloat(28)),
            (CGFloat(145), CGFloat(22), CGFloat(96), CGFloat(20))
        ].enumerated() {
            let ripple = SKShapeNode(ellipseOf: CGSize(width: spec.2, height: spec.3))
            ripple.fillColor = .clear
            ripple.strokeColor = UIColor(
                red: 0.70,
                green: 0.92,
                blue: 0.88,
                alpha: groveRestored ? 0.32 : 0.18
            )
            ripple.lineWidth = index == 1 ? 2.4 : 1.6
            ripple.position = CGPoint(x: spec.0, y: spec.1)
            ripple.name = "grovePondRipple"
            pondNode.addChild(ripple)
        }

        for (x, y) in [
            (CGFloat(-235), CGFloat(-32)),
            (CGFloat(-185), CGFloat(54)),
            (CGFloat(215), CGFloat(-24)),
            (CGFloat(175), CGFloat(52))
        ] {
            let stone = SKShapeNode(ellipseOf: CGSize(width: 52, height: 26))
            stone.fillColor = UIColor(red: 0.34, green: 0.34, blue: 0.25, alpha: 0.90)
            stone.strokeColor = UIColor(red: 0.59, green: 0.58, blue: 0.42, alpha: 0.55)
            stone.lineWidth = 2
            stone.position = CGPoint(x: x, y: y)
            pondNode.addChild(stone)
        }

        let reedColor = groveRestored
            ? UIColor(red: 0.32, green: 0.70, blue: 0.29, alpha: 1)
            : UIColor(red: 0.30, green: 0.47, blue: 0.26, alpha: 0.72)
        for x in stride(from: CGFloat(-230), through: CGFloat(230), by: CGFloat(70)) {
            for offset in [CGFloat(-6), 5] {
                let reed = ArtSystem.box(
                    CGSize(width: 5, height: 42 + CGFloat(Int(abs(x + offset)) % 22)),
                    color: reedColor,
                    radius: 2
                )
                reed.position = CGPoint(x: x + offset, y: 66)
                reed.zRotation = offset < 0 ? -0.06 : 0.05
                pondNode.addChild(reed)
            }
        }

        for (x, y) in [
            (CGFloat(-120), CGFloat(5)),
            (CGFloat(5), CGFloat(-18)),
            (CGFloat(120), CGFloat(12))
        ] {
            let pad = SKShapeNode(ellipseOf: CGSize(width: 46, height: 21))
            pad.fillColor = UIColor(red: 0.24, green: 0.58, blue: 0.28, alpha: groveRestored ? 0.90 : 0.58)
            pad.strokeColor = UIColor(red: 0.48, green: 0.78, blue: 0.42, alpha: 0.66)
            pad.lineWidth = 2
            pad.position = CGPoint(x: x, y: y)
            pondNode.addChild(pad)
        }

        if groveRestored {
            for (x, y) in [
                (CGFloat(-150), CGFloat(20)),
                (CGFloat(-30), CGFloat(-15)),
                (CGFloat(110), CGFloat(15)),
                (CGFloat(190), CGFloat(-5))
            ] {
                let glow = SKShapeNode(circleOfRadius: 7)
                glow.fillColor = UIColor(red: 1, green: 0.88, blue: 0.38, alpha: 0.95)
                glow.strokeColor = .clear
                glow.glowWidth = reducedMotion ? 0 : 8
                glow.position = CGPoint(x: x, y: y)
                pondNode.addChild(glow)
            }
        }

        addChild(pondNode)
    }

    private func renderFinale() {
        finaleNode.removeFromParent()
        finaleNode = SKNode()
        finaleNode.position = CGPoint(x: 640, y: 565)
        finaleNode.zPosition = 650

        guard groveRestored else {
            addChild(finaleNode)
            return
        }

        let halo = SKShapeNode(circleOfRadius: 58)
        halo.fillColor = UIColor(red: 0.75, green: 0.89, blue: 0.45, alpha: 0.12)
        halo.strokeColor = UIColor(red: 0.86, green: 0.96, blue: 0.52, alpha: 0.85)
        halo.lineWidth = 4
        halo.glowWidth = reducedMotion ? 0 : 14
        finaleNode.addChild(halo)

        let star = ArtSystem.label("✦", size: 46)
        star.fontColor = UIColor(red: 1, green: 0.88, blue: 0.38, alpha: 1)
        finaleNode.addChild(star)

        let text = ArtSystem.label("Science Lab restored", size: 20)
        text.position.y = -78
        finaleNode.addChild(text)

        addChild(finaleNode)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        touchStart = touch.location(in: self)
        moved = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if hypot(point.x - touchStart.x, point.y - touchStart.y) > 12 {
            moved = true
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            activeTouch = nil
            moved = false
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        defer {
            activeTouch = nil
            moved = false
        }

        let point = touch.location(in: self)
        guard !moved, hypot(point.x - touchStart.x, point.y - touchStart.y) <= 12 else { return }
        handleTap(at: point)
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let point = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )
        state.audio.play("footstep")
        valkyrie.walk(to: point) { [weak self] in
            guard self != nil else { return }
            action?()
        }
        milo.walk(to: CGPoint(x: max(110, point.x - 95), y: min(walkable.maxY, point.y + 18))) {}
    }

    override func walkIfValid(_ point: CGPoint) {
        if walkable.contains(point) { travel(to: point) }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        milo.zPosition = 1000 - milo.position.y
    }

    override func willLeave() {
        activeTouch = nil
        milo.cancelTravel()
        super.willLeave()
    }

    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "scienceGroveDuck":
            if isNear(duckPoint, radius: 135) {
                observeAnimal()
            } else {
                instruction.text = "Walk closer so Milo can observe the duck without guessing."
                travel(to: CGPoint(x: duckPoint.x - 95, y: 180))
            }

        case "scienceHabitatPond":
            if isNear(habitatPoint, radius: 180) {
                chooseHabitat(.pondEdge)
            } else {
                instruction.text = "Walk to the habitat stones before choosing."
                travel(to: CGPoint(x: habitatPoint.x - 90, y: 180))
            }

        case "scienceHabitatRidge":
            if isNear(habitatPoint, radius: 180) {
                chooseHabitat(.dryRidge)
            } else {
                instruction.text = "Walk to the habitat stones before choosing."
                travel(to: CGPoint(x: habitatPoint.x - 90, y: 180))
            }

        case "scienceWebbedFeet":
            if isNear(feetPoint, radius: 145) {
                inspectBodyPart()
            } else {
                instruction.text = "Walk closer so Milo can inspect the duck's feet."
                travel(to: CGPoint(x: feetPoint.x - 90, y: 180))
            }

        case "scienceCompareShelteredPond":
            if isNear(comparePoint, radius: 170) {
                compareHabitats(.pondEdge)
            } else {
                instruction.text = "Walk to the habitat comparison board first."
                travel(to: CGPoint(x: comparePoint.x - 110, y: 180))
            }

        case "scienceCompareExposedRidge":
            if isNear(comparePoint, radius: 170) {
                compareHabitats(.dryRidge)
            } else {
                instruction.text = "Walk to the habitat comparison board first."
                travel(to: CGPoint(x: comparePoint.x - 110, y: 180))
            }

        case "scienceGroveFinale":
            if groveRestored {
                valkyrie.pose(.celebrate)
                milo.inspect(reducedMotion: reducedMotion)
                instruction.text = "The grove is active again. Water, food, cover, body parts, and habitat evidence all worked together."
            } else {
                instruction.text = "The grove star is still dim. Finish the animal investigation first."
            }

        case "scienceGroveHome":
            state.travel(to: .storyTree)

        default:
            walkIfValid(point)
        }
    }

    private func observeAnimal() {
        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)

        state.scienceObserveAnimal()
        refreshStagePresentation(animated: true)
        instruction.text = "Milo observes that the duck uses water, finds food nearby, and needs places with cover. Which habitat offers those resources?"
        refreshGuidanceCue()
    }

    private func chooseHabitat(_ choice: HabitatChoice) {
        guard groveStage != .arrive else {
            instruction.text = "Observe the duck first so the habitat choice uses evidence."
            return
        }
        guard groveStage == .animalObserved || groveStage == .habitatMatched else {
            instruction.text = "The habitat match is already recorded. Inspect how the duck moves next."
            return
        }

        state.scienceChooseHabitat(choice)
        valkyrie.pose(.interact)
        refreshStagePresentation(animated: choice == .pondEdge)

        if choice == .pondEdge {
            state.audio.play("success")
            instruction.text = "The pond edge provides water, nearby food, and reed cover. Now inspect a body part that helps the duck use this habitat."
        } else {
            milo.inspect(reducedMotion: reducedMotion)
            instruction.text = "The bare ridge offers little water or cover. Compare that with the needs Milo observed."
        }
        refreshGuidanceCue()
    }

    private func inspectBodyPart() {
        guard groveStage == .habitatMatched || groveStage == .bodyPartObserved else {
            instruction.text = "Match the duck to a habitat before studying how its body helps there."
            return
        }

        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)
        state.scienceInspectBodyPart()
        refreshStagePresentation(animated: true)
        instruction.text = "The webbing spreads the foot's surface against the water. That can help the duck push water while swimming. Compare the habitats one more time."
        refreshGuidanceCue()
    }

    private func compareHabitats(_ choice: HabitatChoice) {
        guard groveStage == .bodyPartObserved || groveStage == .complete else {
            instruction.text = "Inspect the duck and its webbed feet before making the final habitat comparison."
            return
        }

        state.scienceCompareHabitat(choice)
        if choice == .pondEdge {
            renderPond()
            renderFinale()
            refreshStagePresentation(animated: true)
            state.audio.play("success")
            valkyrie.pose(.celebrate)
            instruction.text = "The pond edge meets more of the duck's observed needs. The grove responded to the evidence and came back to life."
        } else {
            milo.inspect(reducedMotion: reducedMotion)
            instruction.text = "The exposed ridge still lacks water and protective cover. Use the needs we observed, not just where the duck could stand."
        }
        refreshGuidanceCue()
    }

    private func refreshStagePresentation(animated: Bool) {
        let habitatNames = [
            "scienceHabitatTitle",
            "scienceHabitatPond",
            "scienceHabitatRidge"
        ]

        func setVisible(_ names: [String], _ visible: Bool) {
            for name in names {
                guard let node = childNode(withName: name) else { continue }
                node.removeAction(forKey: "groveStageReveal")
                guard visible else {
                    // Keep the authored hit target alive so an early tap still
                    // reaches the stage guard and explains what to do next.
                    // Alpha-only staging avoids turning an early tap into an
                    // unrelated walk command.
                    node.isHidden = false
                    node.alpha = 0.001
                    node.setScale(1)
                    continue
                }

                let wasVisuallyDormant = node.alpha < 0.01
                node.isHidden = false
                if wasVisuallyDormant && animated && !reducedMotion {
                    node.alpha = 0.001
                    node.setScale(0.94)
                    node.run(
                        .group([
                            .fadeAlpha(to: 1, duration: 0.22),
                            .scale(to: 1, duration: 0.22)
                        ]),
                        withKey: "groveStageReveal"
                    )
                } else {
                    node.alpha = 1
                    node.setScale(1)
                }
            }
        }

        let bodyName = ["scienceWebbedFeet"]
        let compareName = ["scienceCompareBoard"]
        let finaleName = ["scienceGroveFinale"]

        switch groveStage {
        case .arrive:
            setVisible(habitatNames, false)
            setVisible(bodyName, false)
            setVisible(compareName, false)
            setVisible(finaleName, false)

        case .animalObserved:
            setVisible(habitatNames, true)
            setVisible(bodyName, false)
            setVisible(compareName, false)
            setVisible(finaleName, false)

        case .habitatMatched:
            setVisible(habitatNames, false)
            setVisible(bodyName, true)
            setVisible(compareName, false)
            setVisible(finaleName, false)

        case .bodyPartObserved:
            setVisible(habitatNames, false)
            setVisible(bodyName, false)
            setVisible(compareName, true)
            setVisible(finaleName, false)

        case .complete:
            setVisible(habitatNames, false)
            setVisible(bodyName, false)
            setVisible(compareName, false)
            setVisible(finaleName, true)
        }
    }

    private func refreshGuidanceCue() {
        let tint = UIColor(red: 0.66, green: 0.91, blue: 0.52, alpha: 1)
        switch groveStage {
        case .arrive:
            showAttentionCue(at: duckPoint, tint: tint)
        case .animalObserved:
            showAttentionCue(at: habitatPoint, tint: tint, width: 154)
        case .habitatMatched:
            showAttentionCue(at: feetPoint, tint: tint)
        case .bodyPartObserved:
            showAttentionCue(at: comparePoint, tint: tint, width: 150)
        case .complete:
            showAttentionCue(at: finalePoint, tint: tint, width: 102)
        }
    }

}
