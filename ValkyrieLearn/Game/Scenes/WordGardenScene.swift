import SpriteKit
import LearningCore

@MainActor final class WordGardenScene: AdventureScene {
    private enum Place: Equatable {
        case flowerGate
        case sunmillCrossing
        case storyHollow
    }

    private let place: Place
    private let lumi = LumiNode()
    private var hasLeftScene = false
    private var interactionInFlight = false
    private var encounter: LiteracyEncounter?
    private var attempts = 0
    private var support: SupportLevel = .independent
    private var startedAt = Date()
    private var solved = false
    private var acceptingChoices = false
    private var targetRune: SKNode?

    private let flowerPoints = [
        CGPoint(x: 505, y: 245), CGPoint(x: 675, y: 280),
        CGPoint(x: 840, y: 240), CGPoint(x: 995, y: 285)
    ]
    private let sunmillChoicePoints = [
        CGPoint(x: 540, y: 205), CGPoint(x: 690, y: 255),
        CGPoint(x: 845, y: 210), CGPoint(x: 995, y: 260)
    ]
    private let storyHollowChoicePoints = [
        CGPoint(x: 500, y: 205), CGPoint(x: 650, y: 255),
        CGPoint(x: 805, y: 205), CGPoint(x: 960, y: 255)
    ]

    override var worldTitle: String {
        switch place {
        case .flowerGate: return "Word Garden · Flower Gate"
        case .sunmillCrossing: return "Word Garden · Sunmill Crossing"
        case .storyHollow: return "Word Garden · Story Hollow"
        }
    }

    override var walkable: CGRect {
        CGRect(x: 105, y: 128, width: 1020, height: 155)
    }

    override init(state: AppState) {
        switch state.world {
        case .sunmillCrossing:
            place = .sunmillCrossing
        case .storyHollow:
            place = .storyHollow
        default:
            place = .flowerGate
        }
        super.init(state: state)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.removeFromParent()
        valkyrie.setScale(0.5)
        lumi.setScale(0.82)

        switch place {
        case .flowerGate:
            valkyrie.position = CGPoint(x: 220, y: 175)
            lumi.position = CGPoint(x: 335, y: 190)
        case .sunmillCrossing:
            valkyrie.position = CGPoint(x: 190, y: 175)
            lumi.position = CGPoint(x: 300, y: 190)
        case .storyHollow:
            valkyrie.position = CGPoint(x: 185, y: 175)
            lumi.position = CGPoint(x: 290, y: 190)
        }

        lumi.reducedMotion = reducedMotion
        addChild(lumi)

        switch place {
        case .flowerGate: configureFlowerGate()
        case .sunmillCrossing: configureSunmill()
        case .storyHollow: configureStoryHollow()
        }
    }

    override func buildWorld() {
        if let atlas = ArtSystem.texture("WordGardenSourceAtlas") {
            let crop = place == .storyHollow
                ? CGRect(x: 0, y: 0, width: 0.499, height: 0.498)
                : CGRect(x: 0, y: 0.502, width: 0.499, height: 0.498)
            let sourceTexture = SKTexture(
                rect: crop,
                in: atlas
            )
            sourceTexture.filteringMode = .linear

            let preparedTexture = ArtSystem.retinaEnhancedTexture(
                sourceTexture,
                cacheKey: wordGardenBackdropCacheKey,
                targetPoints: size,
                sharpness: place == .storyHollow ? 0.20 : 0.22
            ) ?? sourceTexture
            let backdrop = SKSpriteNode(
                texture: preparedTexture,
                color: .white,
                size: size
            )
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            backdrop.name = "wordGardenBackdrop"
            backdrop.userData = NSMutableDictionary(dictionary: [
                "retinaPrepared": true,
                "sourceAsset": "WordGardenSourceAtlas",
                "sourceCrop": wordGardenBackdropCacheKey
            ])
            addChild(backdrop)
        }

        buildWordGardenFidelityAccents()

        for (height, y) in [(CGFloat(62), CGFloat(684)), (CGFloat(96), CGFloat(42))] {
            let shade = ArtSystem.box(
                CGSize(width: 1280, height: height),
                color: .black.withAlphaComponent(0.25),
                radius: 0
            )
            shade.strokeColor = .clear
            shade.position = CGPoint(x: 640, y: y)
            shade.zPosition = 1990
            addChild(shade)
        }

        let home = worldControl("⌂", name: "home", at: CGPoint(x: 52, y: 669), radius: 26)
        home.zPosition = 2100

        switch place {
        case .flowerGate:
            buildFlowerGateLandmark()
            buildSoundFlowers()
        case .sunmillCrossing:
            buildSunmillLandmark()
            let back = hotspot(
                "← Flower Gate",
                name: "flowerGateBack",
                at: CGPoint(x: 1110, y: 665),
                size: CGSize(width: 205, height: 52)
            )
            back.zPosition = 2050
        case .storyHollow:
            buildStoryHollowLandmark()
            let back = hotspot(
                "← Sunmill",
                name: "sunmillBack",
                at: CGPoint(x: 1110, y: 665),
                size: CGSize(width: 185, height: 52)
            )
            back.zPosition = 2050
        }
    }

    private var wordGardenBackdropCacheKey: String {
        switch place {
        case .flowerGate:
            return "word-garden-flower-gate"
        case .sunmillCrossing:
            return "word-garden-sunmill"
        case .storyHollow:
            return "word-garden-story-hollow"
        }
    }

    /// Device-resolution accents reinforce edges already present in the painting.
    /// They deliberately stay behind the live learning objects and never own input.
    private func buildWordGardenFidelityAccents() {
        let root = SKNode()
        root.name = "wordGardenRetinaAccents"
        root.zPosition = -72

        switch place {
        case .flowerGate:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 90, y: 170))
            path.addCurve(
                to: CGPoint(x: 1185, y: 178),
                control1: CGPoint(x: 420, y: 150),
                control2: CGPoint(x: 850, y: 195)
            )
            let pathRim = SKShapeNode(path: path)
            pathRim.name = "wordGardenPathRim"
            pathRim.strokeColor = UIColor(
                red: 0.95,
                green: 0.88,
                blue: 0.56,
                alpha: 0.15
            )
            pathRim.lineWidth = 2
            root.addChild(pathRim)

            let petalPoints = [
                CGPoint(x: 1020, y: 520),
                CGPoint(x: 1085, y: 555),
                CGPoint(x: 1140, y: 505),
                CGPoint(x: 1200, y: 545)
            ]
            for (index, point) in petalPoints.enumerated() {
                let petal = SKShapeNode(
                    ellipseOf: CGSize(width: 8, height: 4)
                )
                petal.position = point
                petal.zRotation = index.isMultiple(of: 2) ? 0.55 : -0.45
                petal.fillColor = UIColor(
                    red: 1.0,
                    green: 0.70,
                    blue: 0.84,
                    alpha: 0.32
                )
                petal.strokeColor = .clear
                petal.name = "wordGardenPetalGlint"
                root.addChild(petal)
            }

        case .sunmillCrossing:
            let waterPath = CGMutablePath()
            waterPath.move(to: CGPoint(x: 255, y: 198))
            waterPath.addCurve(
                to: CGPoint(x: 1180, y: 186),
                control1: CGPoint(x: 520, y: 212),
                control2: CGPoint(x: 880, y: 166)
            )
            let waterRim = SKShapeNode(path: waterPath)
            waterRim.name = "sunmillWaterRim"
            waterRim.strokeColor = UIColor(
                red: 0.72,
                green: 0.95,
                blue: 1.0,
                alpha: 0.20
            )
            waterRim.lineWidth = 2
            waterRim.glowWidth = reducedMotion ? 0 : 1
            root.addChild(waterRim)

            for point in [
                CGPoint(x: 475, y: 500),
                CGPoint(x: 565, y: 535),
                CGPoint(x: 690, y: 510)
            ] {
                let glint = SKShapeNode(circleOfRadius: 2)
                glint.position = point
                glint.fillColor = UIColor(
                    red: 1.0,
                    green: 0.91,
                    blue: 0.54,
                    alpha: 0.32
                )
                glint.strokeColor = .clear
                glint.glowWidth = reducedMotion ? 0 : 2
                glint.name = "sunmillSkyGlint"
                root.addChild(glint)
            }

        case .storyHollow:
            let hollowRim = SKShapeNode(
                ellipseOf: CGSize(width: 245, height: 315)
            )
            hollowRim.position = CGPoint(x: 1045, y: 365)
            hollowRim.fillColor = .clear
            hollowRim.strokeColor = UIColor(
                red: 0.72,
                green: 0.82,
                blue: 0.48,
                alpha: 0.12
            )
            hollowRim.lineWidth = 2
            hollowRim.name = "storyHollowRim"
            root.addChild(hollowRim)

            for point in [
                CGPoint(x: 360, y: 575),
                CGPoint(x: 510, y: 615),
                CGPoint(x: 680, y: 580),
                CGPoint(x: 835, y: 620)
            ] {
                let glint = SKShapeNode(circleOfRadius: 1.8)
                glint.position = point
                glint.fillColor = UIColor(
                    red: 0.93,
                    green: 0.88,
                    blue: 1.0,
                    alpha: 0.28
                )
                glint.strokeColor = .clear
                glint.glowWidth = reducedMotion ? 0 : 2
                glint.name = "storyHollowCanopyGlint"
                root.addChild(glint)
            }
        }

        addChild(root)
    }

    private func buildFlowerGateLandmark() {
        let gate = SKShapeNode(rectOf: CGSize(width: 150, height: 260), cornerRadius: 65)
        gate.fillColor = .clear
        gate.strokeColor = .clear
        gate.lineWidth = 10
        gate.position = CGPoint(x: 1160, y: 400)
        gate.name = "flowerGate"
        gate.zPosition = 300
        addChild(gate)

        for (index, x) in [CGFloat(-62), CGFloat(62)].enumerated() {
            if let post = ArtSystem.sprite("BridgeTimber", size: CGSize(width: 18, height: 230)) {
                post.position = CGPoint(x: x, y: -10)
                gate.addChild(post)
            }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -120))
            path.addCurve(
                to: CGPoint(x: x * 0.7, y: 110),
                control1: CGPoint(x: x - 16, y: -35),
                control2: CGPoint(x: x + 16, y: 45)
            )
            let vine = SKShapeNode(path: path)
            vine.strokeColor = UIColor(red: 0.25, green: 0.43, blue: 0.20, alpha: 1)
            vine.lineWidth = 6
            vine.name = "gateVine\(index)"
            gate.addChild(vine)
            for y in [CGFloat(-90), CGFloat(-35), CGFloat(20), CGFloat(75)] {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 26, height: 12))
                leaf.fillColor = UIColor(red: 0.36, green: 0.53, blue: 0.24, alpha: 1)
                leaf.strokeColor = UIColor(red: 0.22, green: 0.36, blue: 0.16, alpha: 1)
                leaf.lineWidth = 1
                leaf.position = CGPoint(x: x, y: y)
                leaf.zRotation = x < 0 ? 0.65 : -0.65
                gate.addChild(leaf)
            }
        }

        if let beam = ArtSystem.sprite("BridgeTimber", size: CGSize(width: 18, height: 150)) {
            beam.zRotation = .pi / 2
            beam.position.y = 108
            gate.addChild(beam)
        }

        let star = ArtSystem.label("✦", size: 42)
        star.name = "gateStar"
        star.position = CGPoint(x: 0, y: 55)
        gate.addChild(star)
    }

    private func buildSunmillLandmark() {
        let water = SKShapeNode(rectOf: CGSize(width: 980, height: 86), cornerRadius: 43)
        water.fillColor = UIColor(red: 0.25, green: 0.76, blue: 0.92, alpha: 0.24)
        water.strokeColor = UIColor(red: 0.60, green: 0.94, blue: 1, alpha: 0.55)
        water.lineWidth = 5
        water.position = CGPoint(x: 700, y: 185)
        water.zRotation = -0.035
        water.name = "sunmillWater"
        water.zPosition = 90
        addChild(water)

        let wheel = SKNode()
        wheel.position = CGPoint(x: 330, y: 430)
        wheel.name = "sunmillWheel"
        wheel.zPosition = 420

        let rim = SKShapeNode(circleOfRadius: 103)
        rim.fillColor = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 0.45)
        rim.strokeColor = UIColor(red: 0.82, green: 0.60, blue: 0.30, alpha: 1)
        rim.lineWidth = 10
        rim.name = "sunmillWheel"
        wheel.addChild(rim)

        for quarter in 0..<4 {
            let arm = SKNode()
            arm.zRotation = CGFloat(quarter) * .pi / 2
            arm.name = "sunmillWheel"

            let paddle = ArtSystem.box(
                CGSize(width: 28, height: 150),
                color: UIColor(red: 0.73, green: 0.50, blue: 0.25, alpha: 1),
                radius: 8
            )
            if let texture = ArtSystem.texture("BridgeTimber") {
                paddle.fillColor = .white; paddle.fillTexture = texture; paddle.strokeColor = .clear
            }
            paddle.position.y = 75
            paddle.name = "sunmillWheel"
            arm.addChild(paddle)
            wheel.addChild(arm)
        }

        let hub = SKShapeNode(circleOfRadius: 42)
        hub.fillColor = UIColor(red: 0.97, green: 0.72, blue: 0.22, alpha: 1)
        hub.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.52, alpha: 1)
        hub.lineWidth = 5
        if let texture = ArtSystem.texture("BridgeDial") {
            hub.fillColor = .white; hub.fillTexture = texture; hub.strokeColor = .clear
        }
        hub.name = "sunmillWheel"
        wheel.addChild(hub)

        let sun = ArtSystem.label("☀", size: 43)
        sun.fontColor = UIColor(red: 0.45, green: 0.25, blue: 0.08, alpha: 1)
        sun.name = "sunmillWheel"
        wheel.addChild(sun)

        addChild(wheel)

        let bridge = SKNode()
        bridge.position = CGPoint(x: 915, y: 205)
        bridge.zRotation = -0.18
        bridge.name = "sunmillBridge"
        bridge.zPosition = 350
        for index in 0..<7 {
            let plank = ArtSystem.box(
                CGSize(width: 52, height: 22),
                color: UIColor(red: 0.48, green: 0.31, blue: 0.16, alpha: 1),
                radius: 7
            )
            if let texture = ArtSystem.texture("BridgeOakPlank") {
                plank.fillColor = .white; plank.fillTexture = texture; plank.strokeColor = .clear
            }
            plank.position.x = CGFloat(index - 3) * 55
            plank.name = "sunmillBridge"
            bridge.addChild(plank)
        }
        for x in [CGFloat(-180), CGFloat(180)] {
            let support = ArtSystem.box(CGSize(width: 16, height: 64), color: .brown, radius: 3)
            support.position = CGPoint(x: x, y: -28)
            support.zPosition = -1
            if let texture = ArtSystem.texture("BridgeTimber") {
                support.fillColor = .white; support.fillTexture = texture; support.strokeColor = .clear
            }
            bridge.addChild(support)
        }
        let railPath = CGMutablePath()
        railPath.move(to: CGPoint(x: -180, y: 24))
        railPath.addQuadCurve(to: CGPoint(x: 180, y: 24), control: CGPoint(x: 0, y: 8))
        let rail = SKShapeNode(path: railPath)
        rail.strokeColor = UIColor(red: 0.78, green: 0.66, blue: 0.39, alpha: 1)
        rail.lineWidth = 4
        bridge.addChild(rail)
        bridge.isHidden = true
        addChild(bridge)
    }

    private func buildStoryHollowLandmark() {
        let hollow = SKShapeNode(rectOf: CGSize(width: 250, height: 320), cornerRadius: 115)
        hollow.fillColor = UIColor(red: 0.20, green: 0.12, blue: 0.19, alpha: 0.72)
        hollow.strokeColor = UIColor(red: 0.36, green: 0.49, blue: 0.25, alpha: 0.95)
        hollow.lineWidth = 11
        hollow.position = CGPoint(x: 1045, y: 365)
        hollow.name = "storyHollow"
        hollow.zPosition = 320
        addChild(hollow)

        let inner = SKShapeNode(rectOf: CGSize(width: 145, height: 215), cornerRadius: 68)
        inner.fillColor = UIColor(red: 0.08, green: 0.07, blue: 0.13, alpha: 0.96)
        inner.strokeColor = UIColor(red: 0.57, green: 0.42, blue: 0.23, alpha: 0.82)
        inner.lineWidth = 5
        inner.position.y = -15
        inner.name = "storyHollow"
        hollow.addChild(inner)

        let moon = ArtSystem.label("☾", size: 46)
        moon.fontColor = UIColor(red: 0.90, green: 0.82, blue: 1.0, alpha: 0.92)
        moon.position.y = 72
        moon.name = "hollowMoon"
        hollow.addChild(moon)

        let seed = SKShapeNode(circleOfRadius: 22)
        seed.fillColor = UIColor(red: 1.0, green: 0.86, blue: 0.36, alpha: 0.82)
        seed.strokeColor = UIColor(red: 1.0, green: 0.96, blue: 0.64, alpha: 1)
        seed.lineWidth = 4
        seed.glowWidth = 3
        seed.position = CGPoint(x: 705, y: 235)
        seed.name = "wordSeed"
        seed.zPosition = 500
        addChild(seed)

        let stem = SKShapeNode(rectOf: CGSize(width: 11, height: 92), cornerRadius: 5)
        stem.fillColor = UIColor(red: 0.26, green: 0.50, blue: 0.27, alpha: 1)
        stem.strokeColor = .clear
        stem.position = CGPoint(x: 705, y: 182)
        stem.name = "storyStem"
        stem.zPosition = 250
        addChild(stem)

        for index in 0..<WordGardenEncounterCatalog.storyHollowPattern.count {
            let socket = SKShapeNode(circleOfRadius: 28)
            socket.fillColor = UIColor(red: 0.21, green: 0.18, blue: 0.29, alpha: 0.94)
            socket.strokeColor = UIColor(red: 0.71, green: 0.61, blue: 0.40, alpha: 0.75)
            socket.lineWidth = 3
            socket.position = CGPoint(x: 585 + CGFloat(index) * 120, y: 345)
            socket.name = "storySlot\(index)"
            socket.zPosition = 520
            addChild(socket)

            let glyph = ArtSystem.label("·", size: 34)
            glyph.fontColor = UIColor(red: 0.92, green: 0.86, blue: 0.72, alpha: 0.9)
            glyph.name = "storySlotGlyph\(index)"
            socket.addChild(glyph)
        }
    }

    private func configureFlowerGate() {
        refreshFlowerGateProgress()

        guard !state.flowerGateComplete else {
            activateFlowerGate()
            showSunmillRoute()
            return
        }

        encounter = state.nextLiteracyEncounter()
        buildFlowerEncounter()
    }

    private func buildFlowerEncounter() {
        guard let encounter else { return }
        resetAttemptState()
        clearQuestionAndChoices()
        instruction.text = encounter.prompt
        addPrompt(encounter.prompt)

        for (index, choice) in encounter.choices.enumerated() {
            let flower = flowerNode(letter: choice, index: index)
            flower.position = flowerPoints[index]
            flower.name = "flowerChoice"
            flower.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(flower)
        }

        showTargetRune()
    }

    private func configureSunmill() {
        refreshSunmillProgress(animated: false)

        guard state.sunmillAvailable else {
            instruction.text = "Flower Gate still needs three independent rune matches before this crossing can turn."
            addPrompt("Return to Flower Gate and wake all three vines.")
            return
        }

        guard !state.sunmillComplete else {
            activateSunmillCrossing()
            return
        }

        encounter = state.nextSunmillEncounter()
        buildSunmillEncounter()
    }

    private func buildSunmillEncounter() {
        guard let encounter else { return }
        resetAttemptState()
        clearQuestionAndChoices()
        instruction.text = encounter.prompt
        addPrompt(encounter.prompt)

        for (index, choice) in encounter.choices.enumerated() {
            let leaf = sunmillChoiceNode(letter: choice, index: index)
            leaf.position = sunmillChoicePoints[index]
            leaf.name = "sunmillChoice"
            leaf.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(leaf)
        }

        showTargetRune()
    }


    private func configureStoryHollow() {
        refreshStoryHollowProgress()

        guard state.storyHollowAvailable else {
            instruction.text = "The Sunmill bridge is still sleeping."
            addPrompt("Return to Sunmill Crossing and wake the bridge first.")
            return
        }

        guard !state.storyHollowComplete else {
            activateStoryHollow()
            return
        }

        encounter = state.nextStoryHollowEncounter()
        buildStoryHollowEncounter()
    }

    private func buildStoryHollowEncounter() {
        guard let encounter else { return }
        resetAttemptState()
        clearQuestionAndChoices()
        instruction.text = encounter.prompt
        addPrompt(encounter.prompt)

        for (index, choice) in encounter.choices.enumerated() {
            let runeSeed = storyHollowChoiceNode(letter: choice, index: index)
            runeSeed.position = storyHollowChoicePoints[index]
            runeSeed.name = "storyHollowChoice"
            runeSeed.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(runeSeed)
        }

        showStorySequencePreview()
    }

    private func resetAttemptState() {
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        acceptingChoices = false
        targetRune?.removeFromParent()
        targetRune = nil
        removeAction(forKey: "wordGardenPreview")
    }

    private func addPrompt(_ text: String) {
        childNode(withName: "questionPrompt")?.removeFromParent()
        let prompt = ArtSystem.label(text, size: 25)
        prompt.name = "questionPrompt"
        prompt.position = CGPoint(x: 660, y: 610)
        prompt.preferredMaxLayoutWidth = 850
        prompt.numberOfLines = 2
        prompt.zPosition = 2000
        addChild(prompt)
    }

    private func showTargetRune(retryMessage: String? = nil) {
        guard let encounter else { return }
        acceptingChoices = false
        targetRune?.removeFromParent()

        let rune: SKShapeNode
        let glyphSize: CGFloat
        switch place {
        case .flowerGate:
            rune = SKShapeNode(rectOf: CGSize(width: 100, height: 42), cornerRadius: 8)
            rune.fillColor = .white
            rune.fillTexture = ArtSystem.texture("BridgeWorkOrder")
            rune.position = CGPoint(x: 1160, y: 430)
            rune.lineWidth = 2
            rune.glowWidth = 3
            glyphSize = 30
        case .sunmillCrossing:
            rune = SKShapeNode(circleOfRadius: 54)
            rune.fillColor = UIColor(red: 0.92, green: 0.67, blue: 0.21, alpha: 0.96)
            rune.position = CGPoint(x: 330, y: 430)
            rune.lineWidth = 4
            rune.glowWidth = 10
            glyphSize = 52
        case .storyHollow:
            rune = SKShapeNode(circleOfRadius: 54)
            rune.fillColor = UIColor(red: 0.44, green: 0.31, blue: 0.58, alpha: 0.96)
            rune.position = CGPoint(x: 760, y: 465)
            rune.lineWidth = 4
            rune.glowWidth = 10
            glyphSize = 52
        }
        rune.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
        rune.zPosition = 2010
        rune.name = "targetRune"

        let glyph = ArtSystem.label(encounter.answer, size: glyphSize)
        glyph.fontColor = place == .flowerGate
            ? UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
            : UIColor(red: 0.32, green: 0.18, blue: 0.08, alpha: 1)
        rune.addChild(glyph)
        if place == .flowerGate {
            for x in [CGFloat(-35), CGFloat(35)] {
                let ropePath = CGMutablePath()
                ropePath.move(to: CGPoint(x: x, y: 20))
                ropePath.addLine(to: CGPoint(x: x, y: 75))
                let rope = SKShapeNode(path: ropePath)
                rope.strokeColor = UIColor(red: 0.56, green: 0.40, blue: 0.22, alpha: 1)
                rope.lineWidth = 3
                rune.addChild(rope)
            }
        }
        addChild(rune)
        targetRune = rune

        instruction.text = retryMessage ?? encounter.prompt
        run(
            .sequence([
                .wait(forDuration: 1.15),
                .run { [weak self, weak rune] in
                    guard let self, !self.hasLeftScene else { return }
                    rune?.isHidden = true
                    self.acceptingChoices = true
                    self.instruction.text = self.place == .flowerGate
                        ? "Which flower matches the rune you saw?"
                        : "Which leaf matches the mill-rune you saw?"
                }
            ]),
            withKey: "wordGardenPreview"
        )
    }

    private func showStorySequencePreview(retryMessage: String? = nil) {
        guard let encounter else { return }
        acceptingChoices = false
        targetRune?.removeFromParent()

        let preview = SKNode()
        preview.name = "storySequencePreview"
        preview.position = CGPoint(x: 755, y: 470)
        preview.zPosition = 2010

        let vine = ArtSystem.box(
            CGSize(width: 285, height: 8),
            color: UIColor(red: 0.33, green: 0.55, blue: 0.29, alpha: 0.92),
            radius: 4
        )
        vine.name = "storySequencePreview"
        preview.addChild(vine)

        for (index, glyphValue) in WordGardenEncounterCatalog.storyHollowPattern.enumerated() {
            let bud = SKShapeNode(circleOfRadius: 39)
            bud.fillColor = UIColor(red: 0.33, green: 0.23, blue: 0.43, alpha: 0.97)
            bud.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.38, alpha: 1)
            bud.lineWidth = 4
            bud.glowWidth = 6
            bud.position.x = CGFloat(index - 1) * 105
            bud.name = "storySequencePreview"

            let glyph = ArtSystem.label(glyphValue, size: 38)
            glyph.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 1)
            glyph.name = "storySequencePreview"
            bud.addChild(glyph)
            preview.addChild(bud)
        }

        addChild(preview)
        targetRune = preview
        instruction.text = retryMessage ?? encounter.prompt

        let targetIndex = WordGardenEncounterCatalog.storyHollowSequence.firstIndex {
            $0.id == encounter.id
        } ?? 0
        let positionName = ["first", "middle", "last"][min(targetIndex, 2)]

        run(
            .sequence([
                .wait(forDuration: 1.35),
                .run { [weak self, weak preview] in
                    guard let self else { return }
                    preview?.isHidden = true
                    self.acceptingChoices = true
                    self.instruction.text = "Restore the \(positionName) seed-rune."
                }
            ]),
            withKey: "wordGardenPreview"
        )
    }

    private func clearQuestionAndChoices() {
        childNode(withName: "questionPrompt")?.removeFromParent()
        targetRune?.removeFromParent()
        targetRune = nil
        children
            .filter {
                $0.name == "flowerChoice"
                    || $0.name == "sunmillChoice"
                    || $0.name == "storyHollowChoice"
                    || $0.name == "storySequencePreview"
            }
            .forEach { $0.removeFromParent() }
    }

    private func flowerNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()
        if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 130, height: 130)) {
            bloom.name = "flowerChoice"
            node.addChild(bloom)
        }
        // The rune belongs to the illuminated flower, not a floating answer tile.
        let label = ArtSystem.label(letter, size: 36)
        label.fontColor = UIColor(red: 0.27, green: 0.14, blue: 0.07, alpha: 1)
        label.position.y = 30
        label.name = "flowerChoice"
        node.addChild(label)
        return node
    }

    private func sunmillChoiceNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()

        let leafPath = CGMutablePath()
        leafPath.move(to: CGPoint(x: -54, y: -18))
        leafPath.addCurve(to: CGPoint(x: 54, y: 18), control1: CGPoint(x: -44, y: 46), control2: CGPoint(x: 30, y: 46))
        leafPath.addCurve(to: CGPoint(x: -54, y: -18), control1: CGPoint(x: 44, y: -46), control2: CGPoint(x: -30, y: -46))
        leafPath.closeSubpath()
        let leaf = SKShapeNode(path: leafPath)
        leaf.fillColor = UIColor(
            red: 0.52,
            green: 0.72 + CGFloat(index) * 0.035,
            blue: 0.38,
            alpha: 0.97
        )
        leaf.strokeColor = UIColor(red: 0.92, green: 0.85, blue: 0.46, alpha: 1)
        leaf.lineWidth = 4
        leaf.zRotation = index.isMultiple(of: 2) ? -0.12 : 0.12
        leaf.name = "sunmillChoice"
        node.addChild(leaf)

        let label = ArtSystem.label(letter, size: 42)
        label.fontColor = UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1)
        label.name = "sunmillChoice"
        node.addChild(label)

        return node
    }

    private func storyHollowChoiceNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()

        let seedStone = SKShapeNode(ellipseOf: CGSize(width: 104, height: 72))
        seedStone.fillColor = UIColor(
            red: 0.38 + CGFloat(index) * 0.025,
            green: 0.29,
            blue: 0.47,
            alpha: 0.97
        )
        seedStone.strokeColor = UIColor(red: 0.86, green: 0.68, blue: 0.35, alpha: 1)
        seedStone.lineWidth = 4
        seedStone.name = "storyHollowChoice"
        node.addChild(seedStone)

        let glyph = ArtSystem.label(letter, size: 40)
        glyph.fontColor = UIColor(red: 1.0, green: 0.94, blue: 0.79, alpha: 1)
        glyph.name = "storyHollowChoice"
        node.addChild(glyph)

        let root = SKShapeNode(rectOf: CGSize(width: 8, height: 34), cornerRadius: 4)
        root.fillColor = UIColor(red: 0.31, green: 0.48, blue: 0.26, alpha: 1)
        root.strokeColor = .clear
        root.position.y = -49
        root.zPosition = -1
        root.name = "storyHollowChoice"
        node.addChild(root)

        return node
    }

    private func buildSoundFlowers() {
        let points = [
            CGPoint(x: 255, y: 340),
            CGPoint(x: 350, y: 385),
            CGPoint(x: 435, y: 330)
        ]

        for (index, point) in points.enumerated() {
            let flower = SKNode()
            flower.name = "soundFlower"
            flower.position = point
            flower.zPosition = 340
            flower.userData = NSMutableDictionary(dictionary: ["soundIndex": index])

            if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 88, height: 88)) {
                bloom.name = "soundFlower"
                flower.addChild(bloom)
            }

            addChild(flower)
        }
    }

    private func soundFlower(at point: CGPoint) -> SKNode? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == "soundFlower",
                   current.userData?["soundIndex"] != nil {
                    return current
                }
                node = current.parent
            }
        }
        return nil
    }

    private func activateSoundFlower(_ flower: SKNode) {
        flower.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.12, duration: 0.16),
            .scale(to: 1.0, duration: 0.20)
        ]))
        state.audio.play("crystal")
        lumi.pose(.react)
        instruction.text = "A Sound Flower answers with a gentle chime. Its spoken word-song is still sleeping."
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        handleTap(at: point)
    }

    func handleTap(at point: CGPoint) {
        guard !hasLeftScene else { return }
        if interactionInFlight && targetName(at: point) != "home" { return }
        let name = targetName(at: point)

        switch name {
        case "home":
            willLeave()
            state.travel(to: .storyTree)

        case "flowerGateBack":
            state.travel(to: .wordGarden)

        case "sunmillBack":
            state.travel(to: .sunmillCrossing)

        case "sunmillRoute":
            guard state.sunmillAvailable else { return }
            let destination = CGPoint(x: 945, y: 175)
            if isNear(destination, radius: 100) {
                state.travel(to: .sunmillCrossing)
            } else {
                instruction.text = "Follow the garden path to Sunmill Crossing."
                travelWithLumi(to: destination) { [weak self] in
                    self?.state.travel(to: .sunmillCrossing)
                }
            }

        case "storyHollowRoute":
            guard state.storyHollowAvailable else { return }
            let destination = CGPoint(x: 1015, y: 175)
            if isNear(destination, radius: 100) {
                state.travel(to: .storyHollow)
            } else {
                instruction.text = "Cross the awakened bridge toward Story Hollow."
                travelWithLumi(to: destination) { [weak self] in
                    self?.state.travel(to: .storyHollow)
                }
            }

        case "storyTreeReturn":
            state.travel(to: .storyTree)

        case "soundFlower":
            guard place == .flowerGate, let flower = soundFlower(at: point) else { return }
            let destination = CGPoint(x: max(170, flower.position.x - 80), y: 180)
            travelWithLumi(to: destination) { [weak self, weak flower] in
                guard let self, let flower else { return }
                self.activateSoundFlower(flower)
            }

        case "flowerChoice":
            guard place == .flowerGate,
                  !solved,
                  acceptingChoices,
                  let choice = choice(at: point, named: "flowerChoice"),
                  let node = choice.node else {
                if place == .flowerGate && !solved && !acceptingChoices {
                    instruction.text = "Watch the glowing rune first."
                }
                return
            }
            approachChoice(node, value: choice.value, sunmill: false)

        case "sunmillChoice":
            guard place == .sunmillCrossing,
                  !solved,
                  acceptingChoices,
                  let choice = choice(at: point, named: "sunmillChoice"),
                  let node = choice.node else {
                if place == .sunmillCrossing && !solved && !acceptingChoices {
                    instruction.text = "Watch the glowing mill-rune first."
                }
                return
            }
            approachChoice(node, value: choice.value, sunmill: true)

        case "storyHollowChoice":
            guard place == .storyHollow,
                  !solved,
                  acceptingChoices,
                  let choice = choice(at: point, named: "storyHollowChoice"),
                  let node = choice.node else {
                if place == .storyHollow && !solved && !acceptingChoices {
                    instruction.text = "Watch the three seed-runes first."
                }
                return
            }
            approachStoryHollowChoice(node, value: choice.value)

        default:
            walkIfValid(point)
        }
    }

    private func choice(
        at point: CGPoint,
        named name: String
    ) -> (node: SKNode?, value: String)? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == name,
                   let value = current.userData?["choice"] as? String {
                    return (current, value)
                }
                node = current.parent
            }
        }
        return nil
    }

    private func approachChoice(_ node: SKNode, value: String, sunmill: Bool) {
        interactionInFlight = true
        let destination = CGPoint(x: max(170, node.position.x - 105), y: 175)
        valkyrie.walk(to: destination) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.lumi.walk(
                to: CGPoint(x: destination.x - 60, y: destination.y + 15)
            ) { [weak self] in
                guard let self, !self.hasLeftScene else { return }
                self.lumi.reach(to: node.position, reducedMotion: self.reducedMotion) {
                    if sunmill {
                        self.resolveSunmill(choice: value, node: node)
                    } else {
                        self.resolveFlower(choice: value, node: node)
                    }
                }
            }
        }
    }

    private func approachStoryHollowChoice(_ node: SKNode, value: String) {
        let destination = CGPoint(x: max(170, node.position.x - 105), y: 175)
        valkyrie.walk(to: destination) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.lumi.walk(
                to: CGPoint(x: destination.x - 60, y: destination.y + 15)
            ) { [weak self] in
                guard let self else { return }
                self.lumi.reach(to: node.position, reducedMotion: self.reducedMotion) {
                    self.resolveStoryHollow(choice: value, node: node)
                }
            }
        }
    }

    private func resolveFlower(choice: String, node: SKNode) {
        guard !hasLeftScene, interactionInFlight, !solved else { return }
        interactionInFlight = false
        guard let encounter else { return }
        attempts += 1
        let attemptSupport = support

        if choice == encounter.answer {
            solved = true
            acceptingChoices = false
            pulse(node)
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            refreshFlowerGateProgress()
            state.audio.play("success")
            valkyrie.pose(.celebrate)

            if state.flowerGateComplete {
                activateFlowerGate()
                showSunmillRoute()
                return
            }

            instruction.text = attemptSupport == .independent
                ? "The rune matched. Another vine is waking."
                : "Lumi helped with that rune. Try it once more on your own."

            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 1.0),
                .run { [weak self] in
                    guard let self, !self.hasLeftScene else { return }
                    self.encounter = self.state.nextLiteracyEncounter()
                    self.buildFlowerEncounter()
                }
            ]), withKey: "nextLiteracyEncounter")
        } else {
            _ = state.recordLiteracy(
                encounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            nudge(node)
            let hint = support == .lightHint
                ? "Look closely at the shape on each flower."
                : "Lumi is narrowing it down. Match the rune shape exactly."
            showTargetRune(retryMessage: hint)
        }
    }

    private func resolveSunmill(choice: String, node: SKNode) {
        guard !hasLeftScene, interactionInFlight, !solved else { return }
        interactionInFlight = false
        guard let encounter else { return }
        attempts += 1
        let attemptSupport = support

        if choice == encounter.answer {
            solved = true
            acceptingChoices = false
            pulse(node)
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            refreshSunmillProgress(animated: true)
            state.audio.play("success")
            valkyrie.pose(.celebrate)

            if state.sunmillComplete {
                activateSunmillCrossing()
                return
            }

            instruction.text = attemptSupport == .independent
                ? "The Sunmill turned. Remember the next shape."
                : "Lumi helped with that turn. Try the shape again on your own."

            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 1.0),
                .run { [weak self] in
                    guard let self, !self.hasLeftScene else { return }
                    self.encounter = self.state.nextSunmillEncounter()
                    self.buildSunmillEncounter()
                }
            ]), withKey: "nextLiteracyEncounter")
        } else {
            _ = state.recordLiteracy(
                encounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            nudge(node)
            let hint = support == .lightHint
                ? "Look closely at each curve and line."
                : "Lumi will show the mill-rune again. Match its shape exactly."
            showTargetRune(retryMessage: hint)
        }
    }

    private func resolveStoryHollow(choice: String, node: SKNode) {
        guard let encounter else { return }
        attempts += 1
        let attemptSupport = support

        if choice == encounter.answer {
            solved = true
            acceptingChoices = false
            pulse(node)
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            refreshStoryHollowProgress()
            state.audio.play("success")
            valkyrie.pose(.celebrate)

            if state.storyHollowComplete {
                activateStoryHollow()
                return
            }

            instruction.text = attemptSupport == .independent
                ? "The seed remembered that place. Restore the next rune."
                : "Lumi helped with that place. Try the same rune again on your own."

            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 1.0),
                .run { [weak self] in
                    guard let self else { return }
                    self.encounter = self.state.nextStoryHollowEncounter()
                    self.buildStoryHollowEncounter()
                }
            ]), withKey: "nextLiteracyEncounter")
        } else {
            _ = state.recordLiteracy(
                encounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            nudge(node)
            let hint = support == .lightHint
                ? "Think about where that shape sat on the vine."
                : "Lumi will show the whole three-rune pattern again."
            showStorySequencePreview(retryMessage: hint)
        }
    }

    private func refreshFlowerGateProgress() {
        let count = WordGardenDirector.independentSuccessCount(
            for: WordGardenEncounterCatalog.visualLetterShapes,
            profile: state.profile
        )

        if let gate = childNode(withName: "flowerGate") as? SKShapeNode {
            gate.glowWidth = CGFloat(count) * 4
        }
        childNode(withName: "//gateStar")?.setScale(1 + CGFloat(count) * 0.08)
        childNode(withName: "//gateVine0")?.yScale = 0.55 + CGFloat(count) * 0.15
        childNode(withName: "//gateVine1")?.yScale = 0.55 + CGFloat(count) * 0.15
    }

    private func activateFlowerGate() {
        removeAction(forKey: "wordGardenPreview")
        clearQuestionAndChoices()

        if let gate = childNode(withName: "flowerGate") as? SKShapeNode {
            gate.strokeColor = .systemGreen
            gate.glowWidth = 16
        }
        childNode(withName: "//gateStar")?.setScale(1.28)
        childNode(withName: "//gateVine0")?.yScale = 1
        childNode(withName: "//gateVine1")?.yScale = 1
        instruction.text = "The Flower Gate is awake. Follow Lumi to Sunmill Crossing."
    }

    private func showSunmillRoute() {
        guard childNode(withName: "sunmillRoute") == nil else { return }
        let route = hotspot(
            "Sunmill Crossing →",
            name: "sunmillRoute",
            at: CGPoint(x: 995, y: 165),
            size: CGSize(width: 245, height: 58)
        )
        route.zPosition = 820
    }

    private func refreshSunmillProgress(animated: Bool) {
        let count = WordGardenDirector.independentSuccessCount(
            for: WordGardenEncounterCatalog.sunmillVisualShapes,
            profile: state.profile
        )
        let target = -CGFloat(count) * (2 * .pi / 3)

        if let wheel = childNode(withName: "sunmillWheel") {
            if animated && !reducedMotion {
                wheel.run(
                    .rotate(toAngle: target, duration: 0.55, shortestUnitArc: true),
                    withKey: "sunmillTurn"
                )
            } else {
                wheel.zRotation = target
            }
        }

        if let water = childNode(withName: "sunmillWater") as? SKShapeNode {
            water.alpha = 0.45 + CGFloat(count) * 0.14
            water.glowWidth = state.sunmillComplete ? 14 : CGFloat(count) * 3
        }

        if state.sunmillComplete {
            childNode(withName: "sunmillBridge")?.isHidden = false
        }
    }

    private func showStoryHollowRoute() {
        guard state.storyHollowAvailable,
              childNode(withName: "storyHollowRoute") == nil else { return }
        let route = hotspot(
            "Story Hollow →",
            name: "storyHollowRoute",
            at: CGPoint(x: 1010, y: 165),
            size: CGSize(width: 215, height: 58)
        )
        route.zPosition = 830
    }

    private func activateSunmillCrossing() {
        removeAction(forKey: "wordGardenPreview")
        clearQuestionAndChoices()
        refreshSunmillProgress(animated: true)
        childNode(withName: "sunmillBridge")?.isHidden = false

        if let water = childNode(withName: "sunmillWater") as? SKShapeNode {
            water.alpha = 0.88
            water.glowWidth = 14
        }

        showStoryHollowRoute()
        instruction.text = "The Sunmill is turning. Cross the bridge to Story Hollow."
    }

    private func refreshStoryHollowProgress() {
        let count = WordGardenDirector.independentSuccessCount(
            for: WordGardenEncounterCatalog.storyHollowSequence,
            profile: state.profile
        )
        let ratio = CGFloat(count) / CGFloat(
            max(1, WordGardenEncounterCatalog.storyHollowSequence.count)
        )

        if let seed = childNode(withName: "wordSeed") as? SKShapeNode {
            seed.setScale(0.72 + ratio * 0.72)
            seed.alpha = 0.58 + ratio * 0.42
            seed.glowWidth = 3 + ratio * 14
        }

        childNode(withName: "storyStem")?.yScale = 0.45 + ratio * 0.55

        for index in 0..<WordGardenEncounterCatalog.storyHollowPattern.count {
            let filled = index < count
            if let socket = childNode(withName: "storySlot\(index)") as? SKShapeNode {
                socket.strokeColor = filled
                    ? UIColor(red: 0.98, green: 0.79, blue: 0.38, alpha: 1)
                    : UIColor(red: 0.71, green: 0.61, blue: 0.40, alpha: 0.75)
                socket.glowWidth = filled ? 8 : 0
            }
            if let glyph = childNode(withName: "//storySlotGlyph\(index)") as? SKLabelNode {
                glyph.text = filled
                    ? WordGardenEncounterCatalog.storyHollowPattern[index]
                    : "·"
            }
        }
    }

    private func activateStoryHollow() {
        removeAction(forKey: "wordGardenPreview")
        clearQuestionAndChoices()
        refreshStoryHollowProgress()

        if let hollow = childNode(withName: "storyHollow") as? SKShapeNode {
            hollow.strokeColor = UIColor(red: 0.56, green: 0.77, blue: 0.36, alpha: 1)
            hollow.glowWidth = 16
        }
        childNode(withName: "//hollowMoon")?.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.28, duration: 0.2),
            .scale(to: 1.0, duration: reducedMotion ? 0 : 0.2)
        ]))

        if childNode(withName: "storyBloom") == nil {
            let bloom = ArtSystem.label("✿", size: 70)
            bloom.fontColor = UIColor(red: 1.0, green: 0.66, blue: 0.81, alpha: 1)
            bloom.position = CGPoint(x: 705, y: 315)
            bloom.name = "storyBloom"
            bloom.zPosition = 620
            addChild(bloom)
        }

        if childNode(withName: "storyTreeReturn") == nil {
            let lantern = hotspot(
                "Story Tree ✦",
                name: "storyTreeReturn",
                at: CGPoint(x: 1005, y: 165),
                size: CGSize(width: 190, height: 58)
            )
            lantern.zPosition = 840
        }

        instruction.text = state.hasStoryReward(.wordGardenLantern)
            ? "Story Hollow is awake. The Word Garden lantern is waiting at the Story Tree."
            : "Story Hollow is awake."
    }

    private func pulse(_ node: SKNode) {
        node.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.16, duration: 0.16),
            .scale(to: 1.0, duration: reducedMotion ? 0 : 0.18)
        ]))
    }

    private func nudge(_ node: SKNode) {
        node.run(.sequence([
            .rotate(toAngle: -0.08, duration: reducedMotion ? 0 : 0.08),
            .rotate(toAngle: 0.08, duration: reducedMotion ? 0 : 0.08),
            .rotate(toAngle: 0, duration: reducedMotion ? 0 : 0.08)
        ]))
    }

    private func travelWithLumi(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let point = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )
        state.audio.play("footstep")
        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
            action?()
        }
        lumi.walk(to: CGPoint(x: max(100, point.x - 90), y: point.y + 12)) {}
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        travelWithLumi(to: destination, then: action)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        lumi.reducedMotion = reducedMotion
        lumi.zPosition = 1000 - lumi.position.y
    }

    override func willLeave() {
        hasLeftScene = true
        interactionInFlight = false
        removeAction(forKey: "nextLiteracyEncounter")
        removeAction(forKey: "nextSunmillEncounter")
        removeAction(forKey: "wordGardenPreview")
        targetRune?.removeFromParent()
        lumi.cancelTravel()
        lumi.removeAllActions()
        super.willLeave()
    }
}
