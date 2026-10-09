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
    private var lastKineticReducedMotion: Bool?
    private var lastKineticCompletionKey = ""
    private var livingGardenMode = false
    private var livingGardenStage: SKNode?
    private var gardenSelectedSeed: LumiSeed?
    private var gardenSelectedCare: LumiGardenCare?
    private let gardenPlotPoints = [
        CGPoint(x: 550, y: 360), CGPoint(x: 775, y: 360), CGPoint(x: 1000, y: 360)
    ]
    private let gardenSeedPoints = [
        CGPoint(x: 485, y: 535), CGPoint(x: 705, y: 535), CGPoint(x: 925, y: 535)
    ]
    private let gardenToolPoints = [
        CGPoint(x: 495, y: 160), CGPoint(x: 705, y: 160), CGPoint(x: 915, y: 160)
    ]

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
        let usesJourneyScale = place == .sunmillCrossing || place == .storyHollow
        valkyrie.setScale(usesJourneyScale ? 0.58 : 0.5)
        lumi.setScale(usesJourneyScale ? 0.90 : 0.82)

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

        if place == .sunmillCrossing || place == .storyHollow {
            applyWordGardenJourneyHUDPolish()
        }

        switch place {
        case .flowerGate: configureFlowerGate()
        case .sunmillCrossing: configureSunmill()
        case .storyHollow: configureStoryHollow()
        }

        syncWordGardenKinetics()
    }

    private var wordGardenKineticCompletionKey: String {
        "\(place)-\(state.flowerGateComplete)-\(state.sunmillComplete)"
    }

    private func syncWordGardenKinetics() {
        lastKineticReducedMotion = reducedMotion
        lastKineticCompletionKey = wordGardenKineticCompletionKey

        let livingNames: Set<String> = [
            "flowerChoice",
            "soundFlower",
            "sunmillChoice",
            "storyHollowChoice"
        ]

        for node in children {
            guard let name = node.name, livingNames.contains(name) else { continue }
            node.removeAction(forKey: "gardenSway")
            node.zRotation = 0
        }

        childNode(withName: "sunmillWheel")?
            .removeAction(forKey: "ambientSunmillSpin")
        childNode(withName: "//sunmillHubGlow")?
            .removeAction(forKey: "ambientSunmillGlow")
        childNode(withName: "sunmillWater")?
            .removeAction(forKey: "ambientWaterShimmer")
        childNode(withName: "sunmillLightPath")?
            .removeAction(forKey: "ambientLightShimmer")

        guard !reducedMotion else { return }

        let livingNodes = children.filter {
            guard let name = $0.name else { return false }
            return livingNames.contains(name)
        }

        for (index, node) in livingNodes.enumerated() {
            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let duration = 1.8 + Double(index % 4) * 0.18
            node.run(
                .repeatForever(
                    .sequence([
                        .group([
                            .rotate(byAngle: direction * 0.018, duration: duration),
                            .moveBy(x: direction * 2.0, y: 2.5, duration: duration)
                        ]),
                        .group([
                            .rotate(byAngle: direction * -0.036, duration: duration * 2),
                            .moveBy(x: direction * -4.0, y: -2.0, duration: duration * 2)
                        ]),
                        .group([
                            .rotate(byAngle: direction * 0.018, duration: duration),
                            .moveBy(x: direction * 2.0, y: -0.5, duration: duration)
                        ])
                    ])
                ),
                withKey: "gardenSway"
            )
        }

        if let hubGlow = childNode(withName: "//sunmillHubGlow") {
            hubGlow.run(
                .repeatForever(
                    .sequence([
                        .fadeAlpha(to: 0.48, duration: 0.9),
                        .fadeAlpha(to: 1.0, duration: 0.9)
                    ])
                ),
                withKey: "ambientSunmillGlow"
            )
        }

        childNode(withName: "sunmillWater")?.run(
            .repeatForever(
                .sequence([
                    .fadeAlpha(to: 0.62, duration: 1.15),
                    .fadeAlpha(to: 1.0, duration: 1.15)
                ])
            ),
            withKey: "ambientWaterShimmer"
        )

        childNode(withName: "sunmillLightPath")?.run(
            .repeatForever(
                .sequence([
                    .fadeAlpha(to: 0.50, duration: 0.82),
                    .fadeAlpha(to: 1.0, duration: 0.82)
                ])
            ),
            withKey: "ambientLightShimmer"
        )

        if state.sunmillComplete {
            childNode(withName: "sunmillWheel")?.run(
                .repeatForever(
                    .rotate(byAngle: -.pi * 2, duration: 9.5)
                ),
                withKey: "ambientSunmillSpin"
            )
        }
    }

    private func applyWordGardenJourneyHUDPolish() {
        if let instructionBackdrop = childNode(withName: "instructionBackdrop") {
            instructionBackdrop.xScale = 0.70
            instructionBackdrop.position = CGPoint(x: 755, y: 48)
            instructionBackdrop.alpha = 0.72
        }
        instruction.position = CGPoint(x: 755, y: 48)
        instruction.fontSize = 19
        instruction.preferredMaxLayoutWidth = 720
        instruction.numberOfLines = 2
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
                cacheKey: wordGardenTextureCacheKey,
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
                "sourceCrop": wordGardenBackdropKey
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
            buildLivingGardenBeacon()
        case .sunmillCrossing:
            buildSunmillLandmark()
            let back = worldControl(
                "‹",
                name: "flowerGateBack",
                at: CGPoint(x: 1215, y: 669),
                radius: 27,
                accessibilityLabel: "Back to Flower Gate"
            )
            back.zPosition = 2050
        case .storyHollow:
            buildStoryHollowLandmark()
            let back = worldControl(
                "‹",
                name: "sunmillBack",
                at: CGPoint(x: 1215, y: 669),
                radius: 27,
                accessibilityLabel: "Back to Sunmill Crossing"
            )
            back.zPosition = 2050
        }
    }

    private var wordGardenBackdropKey: String {
        switch place {
        case .flowerGate:
            return "word-garden-flower-gate"
        case .sunmillCrossing:
            return "word-garden-sunmill"
        case .storyHollow:
            return "word-garden-story-hollow"
        }
    }

    private var wordGardenTextureCacheKey: String {
        switch place {
        case .flowerGate, .sunmillCrossing:
            return "word-garden-upper-crop"
        case .storyHollow:
            return "word-garden-lower-crop"
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
        // The crossing is a physical machine in the garden, not a quiz overlay.
        // Water, mill, choices and bridge all share one visual cause-and-effect path.
        let waterPath = CGMutablePath()
        waterPath.move(to: CGPoint(x: 455, y: 185))
        waterPath.addCurve(
            to: CGPoint(x: 1195, y: 215),
            control1: CGPoint(x: 670, y: 150),
            control2: CGPoint(x: 955, y: 250)
        )
        let water = SKShapeNode(path: waterPath)
        water.fillColor = .clear
        // Painted water carries the detail; a narrow animated current is enough.
        water.strokeColor = UIColor(red: 0.42, green: 0.82, blue: 0.96, alpha: 0.18)
        water.lineWidth = 30
        water.glowWidth = 2
        water.name = "sunmillWater"
        water.zPosition = 92
        addChild(water)

        let bank = SKShapeNode(ellipseOf: CGSize(width: 650, height: 150))
        bank.position = CGPoint(x: 775, y: 230)
        bank.fillColor = UIColor(red: 0.10, green: 0.24, blue: 0.13, alpha: 0.06)
        bank.strokeColor = UIColor(red: 0.58, green: 0.76, blue: 0.34, alpha: 0.16)
        bank.lineWidth = 3
        bank.name = "decorativeSunmillChoiceBank"
        bank.zPosition = 260
        addChild(bank)

        let vinePath = CGMutablePath()
        vinePath.move(to: CGPoint(x: 485, y: 168))
        vinePath.addCurve(
            to: CGPoint(x: 1060, y: 185),
            control1: CGPoint(x: 620, y: 205),
            control2: CGPoint(x: 880, y: 125)
        )
        let vine = SKShapeNode(path: vinePath)
        vine.strokeColor = UIColor(red: 0.34, green: 0.54, blue: 0.20, alpha: 0.92)
        vine.lineWidth = 10
        vine.name = "decorativeSunmillChoiceVine"
        vine.zPosition = 275
        addChild(vine)

        let tower = ArtSystem.box(
            CGSize(width: 56, height: 245),
            color: UIColor(red: 0.48, green: 0.31, blue: 0.15, alpha: 0.96),
            radius: 16
        )
        tower.position = CGPoint(x: 330, y: 305)
        tower.name = "sunmillTower"
        tower.zPosition = 390
        if let texture = ArtSystem.texture("BridgeTimber") {
            tower.fillColor = .white
            tower.fillTexture = texture
            tower.strokeColor = .clear
        }
        addChild(tower)

        let wheel = SKNode()
        wheel.position = CGPoint(x: 330, y: 430)
        wheel.name = "sunmillWheel"
        wheel.zPosition = 420

        let outerGlow = SKShapeNode(circleOfRadius: 128)
        outerGlow.fillColor = UIColor(red: 1.0, green: 0.66, blue: 0.30, alpha: 0.06)
        outerGlow.strokeColor = UIColor(red: 1.0, green: 0.75, blue: 0.34, alpha: 0.24)
        outerGlow.lineWidth = 3
        outerGlow.glowWidth = reducedMotion ? 0 : 7
        outerGlow.name = "sunmillWheel"
        outerGlow.alpha = 0.45
        wheel.addChild(outerGlow)

        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4
            let petal = SKShapeNode(ellipseOf: CGSize(width: 54, height: 102))
            petal.position = CGPoint(
                x: sin(angle) * 118,
                y: cos(angle) * 118
            )
            petal.zRotation = -angle
            petal.fillColor = UIColor(red: 0.98, green: 0.48, blue: 0.66, alpha: 0.72)
            petal.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.48, alpha: 0.72)
            petal.lineWidth = 3
            petal.name = "sunmillWheel"
            petal.alpha = 0.72
            wheel.addChild(petal)
        }

        let rim = SKShapeNode(circleOfRadius: 101)
        rim.fillColor = UIColor(red: 0.28, green: 0.18, blue: 0.08, alpha: 0.58)
        rim.strokeColor = UIColor(red: 0.88, green: 0.64, blue: 0.30, alpha: 1)
        rim.lineWidth = 9
        rim.name = "sunmillWheel"
        wheel.addChild(rim)

        for quarter in 0..<4 {
            let arm = SKNode()
            arm.zRotation = CGFloat(quarter) * .pi / 2
            arm.name = "sunmillWheel"

            let paddle = ArtSystem.box(
                CGSize(width: 24, height: 136),
                color: UIColor(red: 0.73, green: 0.50, blue: 0.25, alpha: 1),
                radius: 8
            )
            if let texture = ArtSystem.texture("BridgeTimber") {
                paddle.fillColor = .white
                paddle.fillTexture = texture
                paddle.strokeColor = .clear
            }
            paddle.position.y = 68
            paddle.name = "sunmillWheel"
            arm.addChild(paddle)
            wheel.addChild(arm)
        }

        let hub = SKShapeNode(circleOfRadius: 47)
        hub.fillColor = UIColor(red: 0.98, green: 0.73, blue: 0.24, alpha: 1)
        hub.strokeColor = UIColor(red: 1, green: 0.92, blue: 0.58, alpha: 1)
        hub.lineWidth = 5
        hub.name = "sunmillWheel"
        wheel.addChild(hub)

        let hubGlow = SKShapeNode(circleOfRadius: 60)
        hubGlow.fillColor = .clear
        hubGlow.strokeColor = UIColor(red: 1.0, green: 0.83, blue: 0.36, alpha: 0.42)
        hubGlow.lineWidth = 3
        hubGlow.glowWidth = reducedMotion ? 0 : 8
        hubGlow.name = "sunmillHubGlow"
        hubGlow.zPosition = -1
        wheel.addChild(hubGlow)

        let sun = ArtSystem.label("☀", size: 40)
        sun.fontColor = UIColor(red: 0.45, green: 0.25, blue: 0.08, alpha: 0.92)
        sun.name = "sunmillWheel"
        wheel.addChild(sun)
        addChild(wheel)

        let currentPath = CGMutablePath()
        currentPath.move(to: CGPoint(x: 405, y: 365))
        currentPath.addCurve(
            to: CGPoint(x: 785, y: 238),
            control1: CGPoint(x: 520, y: 350),
            control2: CGPoint(x: 650, y: 255)
        )
        let current = SKShapeNode(path: currentPath)
        current.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.36, alpha: 0.58)
        current.lineWidth = 8
        current.glowWidth = reducedMotion ? 0 : 5
        current.name = "sunmillLightPath"
        current.zPosition = 300
        addChild(current)

        let bridge = SKNode()
        bridge.position = CGPoint(x: 925, y: 205)
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
                plank.fillColor = .white
                plank.fillTexture = texture
                plank.strokeColor = .clear
            }
            plank.position.x = CGFloat(index - 3) * 55
            plank.alpha = 0.16
            plank.name = "sunmillBridgePlank\(index)"
            bridge.addChild(plank)
        }

        for x in [CGFloat(-180), CGFloat(180)] {
            let support = ArtSystem.box(
                CGSize(width: 16, height: 64),
                color: .brown,
                radius: 3
            )
            support.position = CGPoint(x: x, y: -28)
            support.zPosition = -1
            support.alpha = 0.34
            if let texture = ArtSystem.texture("BridgeTimber") {
                support.fillColor = .white
                support.fillTexture = texture
                support.strokeColor = .clear
            }
            support.name = "sunmillBridgeSupport"
            bridge.addChild(support)
        }

        let railPath = CGMutablePath()
        railPath.move(to: CGPoint(x: -180, y: 24))
        railPath.addQuadCurve(
            to: CGPoint(x: 180, y: 24),
            control: CGPoint(x: 0, y: 8)
        )
        let rail = SKShapeNode(path: railPath)
        rail.strokeColor = UIColor(red: 0.78, green: 0.66, blue: 0.39, alpha: 1)
        rail.lineWidth = 4
        rail.alpha = 0.18
        rail.name = "sunmillBridgeRail"
        bridge.addChild(rail)

        // Keep the sleeping bridge visible as a destination. Learning restores it
        // plank by plank instead of teleporting a completed bridge into the scene.
        bridge.isHidden = false
        addChild(bridge)
    }

    private func buildStoryHollowLandmark() {
        // Story Hollow is a living memory tree. The permanent branch, seed and
        // root network carry the sequence challenge so the lesson belongs to
        // the environment instead of floating over the painting.
        let rootNetwork = SKNode()
        rootNetwork.name = "storyRootNetwork"
        rootNetwork.zPosition = 285
        addChild(rootNetwork)

        let groundRootsPath = CGMutablePath()
        groundRootsPath.move(to: CGPoint(x: 455, y: 155))
        groundRootsPath.addCurve(
            to: CGPoint(x: 1065, y: 165),
            control1: CGPoint(x: 610, y: 120),
            control2: CGPoint(x: 880, y: 205)
        )
        groundRootsPath.move(to: CGPoint(x: 620, y: 160))
        groundRootsPath.addCurve(
            to: CGPoint(x: 1125, y: 205),
            control1: CGPoint(x: 760, y: 210),
            control2: CGPoint(x: 990, y: 130)
        )
        let groundRoots = SKShapeNode(path: groundRootsPath)
        groundRoots.strokeColor = UIColor(red: 0.34, green: 0.24, blue: 0.13, alpha: 0.58)
        groundRoots.lineWidth = 9
        groundRoots.name = "decorativeStoryGroundRoots"
        rootNetwork.addChild(groundRoots)

        let memoryBranchPath = CGMutablePath()
        memoryBranchPath.move(to: CGPoint(x: 1090, y: 480))
        memoryBranchPath.addCurve(
            to: CGPoint(x: 690, y: 455),
            control1: CGPoint(x: 990, y: 520),
            control2: CGPoint(x: 835, y: 425)
        )
        let memoryBranch = SKShapeNode(path: memoryBranchPath)
        memoryBranch.strokeColor = UIColor(red: 0.38, green: 0.27, blue: 0.14, alpha: 0.88)
        memoryBranch.lineWidth = 12
        memoryBranch.name = "storyMemoryBranch"
        memoryBranch.zPosition = 470
        addChild(memoryBranch)

        let archPath = CGMutablePath()
        archPath.move(to: CGPoint(x: 910, y: 190))
        archPath.addLine(to: CGPoint(x: 910, y: 345))
        archPath.addQuadCurve(
            to: CGPoint(x: 1035, y: 548),
            control: CGPoint(x: 910, y: 505)
        )
        archPath.addQuadCurve(
            to: CGPoint(x: 1160, y: 345),
            control: CGPoint(x: 1160, y: 505)
        )
        archPath.addLine(to: CGPoint(x: 1160, y: 190))
        archPath.closeSubpath()

        let hollow = SKShapeNode(path: archPath)
        hollow.fillColor = UIColor(red: 0.12, green: 0.08, blue: 0.12, alpha: 0.08)
        hollow.strokeColor = UIColor(red: 0.38, green: 0.25, blue: 0.13, alpha: 0.88)
        hollow.lineWidth = 11
        hollow.name = "storyHollow"
        hollow.zPosition = 330
        addChild(hollow)

        let openingPath = CGMutablePath()
        openingPath.move(to: CGPoint(x: 955, y: 205))
        openingPath.addLine(to: CGPoint(x: 955, y: 345))
        openingPath.addQuadCurve(
            to: CGPoint(x: 1035, y: 472),
            control: CGPoint(x: 955, y: 445)
        )
        openingPath.addQuadCurve(
            to: CGPoint(x: 1115, y: 345),
            control: CGPoint(x: 1115, y: 445)
        )
        openingPath.addLine(to: CGPoint(x: 1115, y: 205))
        openingPath.closeSubpath()

        let inner = SKShapeNode(path: openingPath)
        inner.fillColor = UIColor(red: 0.06, green: 0.055, blue: 0.11, alpha: 0.28)
        inner.strokeColor = UIColor(red: 0.57, green: 0.42, blue: 0.23, alpha: 0.58)
        inner.lineWidth = 4
        inner.name = "storyHollow"
        inner.zPosition = 1
        hollow.addChild(inner)

        let doorGlow = SKShapeNode(path: openingPath)
        doorGlow.fillColor = .clear
        doorGlow.strokeColor = UIColor(red: 0.87, green: 0.71, blue: 1.0, alpha: 0.34)
        doorGlow.lineWidth = 5
        doorGlow.glowWidth = reducedMotion ? 0 : 4
        doorGlow.alpha = 0.22
        doorGlow.name = "storyHollowDoorGlow"
        doorGlow.zPosition = 345
        addChild(doorGlow)

        let hollowVinePath = CGMutablePath()
        hollowVinePath.move(to: CGPoint(x: 925, y: 205))
        hollowVinePath.addCurve(
            to: CGPoint(x: 1035, y: 535),
            control1: CGPoint(x: 915, y: 390),
            control2: CGPoint(x: 945, y: 520)
        )
        hollowVinePath.addCurve(
            to: CGPoint(x: 1145, y: 205),
            control1: CGPoint(x: 1125, y: 520),
            control2: CGPoint(x: 1155, y: 390)
        )
        let hollowVine = SKShapeNode(path: hollowVinePath)
        hollowVine.fillColor = .clear
        hollowVine.strokeColor = UIColor(red: 0.35, green: 0.58, blue: 0.24, alpha: 0.82)
        hollowVine.lineWidth = 7
        hollowVine.name = "storyHollowVine"
        hollowVine.zPosition = 365
        addChild(hollowVine)

        for (index, point) in [
            CGPoint(x: 938, y: 355),
            CGPoint(x: 980, y: 485),
            CGPoint(x: 1090, y: 485),
            CGPoint(x: 1130, y: 350)
        ].enumerated() {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: 30, height: 14))
            leaf.position = point
            leaf.zRotation = index < 2 ? 0.55 : -0.55
            leaf.fillColor = UIColor(red: 0.47, green: 0.68, blue: 0.30, alpha: 0.78)
            leaf.strokeColor = UIColor(red: 0.81, green: 0.77, blue: 0.35, alpha: 0.28)
            leaf.lineWidth = 1.5
            leaf.name = "decorativeStoryHollowLeaf"
            leaf.zPosition = 370
            addChild(leaf)
        }

        for (index, x) in [CGFloat(936), CGFloat(1134)].enumerated() {
            let trunk = SKShapeNode(rectOf: CGSize(width: 34, height: 270), cornerRadius: 15)
            trunk.position = CGPoint(x: x, y: 325)
            trunk.zRotation = index == 0 ? -0.035 : 0.035
            trunk.fillColor = UIColor(red: 0.31, green: 0.21, blue: 0.12, alpha: 0.82)
            trunk.strokeColor = UIColor(red: 0.43, green: 0.56, blue: 0.24, alpha: 0.56)
            trunk.lineWidth = 3
            trunk.name = "decorativeStoryTrunk"
            trunk.zPosition = 350
            addChild(trunk)
        }

        let moon = ArtSystem.label("☾", size: 46)
        moon.fontColor = UIColor(red: 0.90, green: 0.82, blue: 1.0, alpha: 0.92)
        moon.position = CGPoint(x: 1035, y: 392)
        moon.name = "hollowMoon"
        moon.zPosition = 380
        addChild(moon)

        let seed = SKShapeNode(ellipseOf: CGSize(width: 48, height: 64))
        seed.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.32, alpha: 0.78)
        seed.strokeColor = UIColor(red: 1.0, green: 0.96, blue: 0.64, alpha: 1)
        seed.lineWidth = 4
        seed.glowWidth = 3
        seed.position = CGPoint(x: 825, y: 270)
        seed.zRotation = -0.16
        seed.name = "wordSeed"
        seed.zPosition = 505
        addChild(seed)

        let stem = SKShapeNode(rectOf: CGSize(width: 11, height: 105), cornerRadius: 5)
        stem.fillColor = UIColor(red: 0.26, green: 0.50, blue: 0.27, alpha: 1)
        stem.strokeColor = .clear
        stem.position = CGPoint(x: 825, y: 210)
        stem.name = "storyStem"
        stem.zPosition = 300
        addChild(stem)

        let slotPoints = [
            CGPoint(x: 820, y: 444),
            CGPoint(x: 925, y: 468),
            CGPoint(x: 1025, y: 450)
        ]

        for (index, point) in slotPoints.enumerated() {
            let socketPath = CGMutablePath()
            socketPath.move(to: CGPoint(x: 0, y: 33))
            socketPath.addCurve(
                to: CGPoint(x: 31, y: -3),
                control1: CGPoint(x: 24, y: 23),
                control2: CGPoint(x: 34, y: 10)
            )
            socketPath.addCurve(
                to: CGPoint(x: 0, y: -29),
                control1: CGPoint(x: 30, y: -20),
                control2: CGPoint(x: 15, y: -29)
            )
            socketPath.addCurve(
                to: CGPoint(x: -31, y: -3),
                control1: CGPoint(x: -15, y: -29),
                control2: CGPoint(x: -30, y: -20)
            )
            socketPath.addCurve(
                to: CGPoint(x: 0, y: 33),
                control1: CGPoint(x: -34, y: 10),
                control2: CGPoint(x: -24, y: 23)
            )
            socketPath.closeSubpath()
            let socket = SKShapeNode(path: socketPath)
            socket.fillColor = UIColor(red: 0.30, green: 0.22, blue: 0.38, alpha: 0.88)
            socket.strokeColor = UIColor(red: 0.75, green: 0.63, blue: 0.36, alpha: 0.72)
            socket.lineWidth = 3
            socket.position = point
            socket.zRotation = index == 1 ? 0.08 : (index == 0 ? -0.10 : 0.04)
            socket.name = "storySlot\(index)"
            socket.zPosition = 525
            addChild(socket)

            let glyph = ArtSystem.label("·", size: 34)
            glyph.fontColor = UIColor(red: 0.92, green: 0.86, blue: 0.72, alpha: 0.9)
            glyph.name = "storySlotGlyph\(index)"
            socket.addChild(glyph)

            let sprout = SKShapeNode(ellipseOf: CGSize(width: 26, height: 12))
            sprout.position = CGPoint(x: point.x - 18, y: point.y + 34)
            sprout.zRotation = -0.42 + CGFloat(index) * 0.36
            sprout.fillColor = UIColor(red: 0.48, green: 0.67, blue: 0.29, alpha: 0.72)
            sprout.strokeColor = .clear
            sprout.name = "decorativeStoryBranchLeaf"
            sprout.zPosition = 510
            addChild(sprout)

            let glowPath = CGMutablePath()
            glowPath.move(to: CGPoint(x: 825, y: 260))
            glowPath.addCurve(
                to: point,
                control1: CGPoint(x: 835 + CGFloat(index) * 30, y: 315),
                control2: CGPoint(x: point.x - 58, y: 395)
            )
            let rootGlow = SKShapeNode(path: glowPath)
            rootGlow.fillColor = .clear
            rootGlow.strokeColor = UIColor(red: 0.94, green: 0.72, blue: 0.34, alpha: 0.82)
            rootGlow.lineWidth = 7
            rootGlow.glowWidth = reducedMotion ? 0 : 4
            rootGlow.alpha = 0.10
            rootGlow.name = "storyRootGlow\(index)"
            rootGlow.zPosition = 430
            addChild(rootGlow)
        }

        for index in 0..<5 {
            let bloom = SKShapeNode(ellipseOf: CGSize(width: 34, height: 18))
            let angle = CGFloat(index) * 0.74 - 1.4
            bloom.position = CGPoint(
                x: 1028 + cos(angle) * 142,
                y: 474 + sin(angle) * 68
            )
            bloom.zRotation = angle
            bloom.fillColor = UIColor(red: 0.98, green: 0.57, blue: 0.74, alpha: 0.70)
            bloom.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.46, alpha: 0.42)
            bloom.lineWidth = 2
            bloom.alpha = 0.12
            bloom.name = "storyCanopyBloom\(index)"
            bloom.zPosition = 455
            addChild(bloom)
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
            instruction.text = "Return to Flower Gate and wake all three vines before the Sunmill can turn."
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
        // Keep the painted crossing open and readable. The persistent lower
        // guidance plaque is the single instruction surface in this room.
        instruction.text = "Wake the crossing: remember the glowing mill-rune."

        for (index, choice) in encounter.choices.enumerated() {
            let leaf = sunmillChoiceNode(letter: choice, index: index)
            leaf.position = sunmillChoicePoints[index]
            leaf.name = "sunmillChoice"
            leaf.zPosition = 620
            leaf.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(leaf)
        }

        showTargetRune()
    }


    private func configureStoryHollow() {
        refreshStoryHollowProgress()

        guard state.storyHollowAvailable else {
            instruction.text = "Return to Sunmill Crossing and wake the bridge before the memory tree can open."
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
        // Story Hollow uses the persistent lower guidance plaque and the tree's
        // own memory branch as the sequence display.
        instruction.text = "Watch the memory branch. Then restore the missing seed-rune."

        for (index, choice) in encounter.choices.enumerated() {
            let runeSeed = storyHollowChoiceNode(letter: choice, index: index)
            runeSeed.position = storyHollowChoicePoints[index]
            runeSeed.name = "storyHollowChoice"
            runeSeed.zPosition = 620
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
        clearAttentionCue()
        removeAction(forKey: "wordGardenPreview")
    }

    private func addPrompt(_ text: String) {
        childNode(withName: "questionPrompt")?.removeFromParent()
        let prompt = ArtSystem.label(text, size: 25)
        prompt.name = "questionPrompt"
        prompt.position = CGPoint(x: 660, y: 610)
        prompt.preferredMaxLayoutWidth = 820
        prompt.numberOfLines = 2
        prompt.fontColor = UIColor(red: 1.0, green: 0.98, blue: 0.91, alpha: 1)
        prompt.zPosition = 2000

        let plate = ArtSystem.panel(
            CGSize(width: 900, height: 76),
            fill: UIColor(red: 0.035, green: 0.045, blue: 0.075, alpha: 0.68),
            stroke: UIColor(white: 1.0, alpha: 0.12),
            radius: 24,
            lineWidth: 1.5,
            shadowAlpha: 0.24
        )
        plate.name = "questionPromptBackdrop"
        plate.zPosition = -2
        prompt.addChild(plate)

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
            rune = SKShapeNode(circleOfRadius: 47)
            rune.fillColor = UIColor(red: 0.98, green: 0.74, blue: 0.24, alpha: 0.90)
            rune.position = CGPoint(x: 330, y: 430)
            rune.lineWidth = 4
            rune.glowWidth = 7
            glyphSize = 48
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
                    self.showAttentionCue(
                        at: CGPoint(x: 755, y: 165),
                        tint: UIColor(red: 1.0, green: 0.66, blue: 0.84, alpha: 1),
                        width: 190
                    )
                    self.instruction.text = self.place == .flowerGate
                        ? "Which flower matches the rune you saw?"
                        : "Tap the matching leaf to turn the Sunmill."
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
        preview.zPosition = 548

        let branchGlowPath = CGMutablePath()
        branchGlowPath.move(to: CGPoint(x: 1090, y: 480))
        branchGlowPath.addCurve(
            to: CGPoint(x: 690, y: 455),
            control1: CGPoint(x: 990, y: 520),
            control2: CGPoint(x: 835, y: 425)
        )
        let branchGlow = SKShapeNode(path: branchGlowPath)
        branchGlow.strokeColor = UIColor(red: 1.0, green: 0.78, blue: 0.38, alpha: 0.62)
        branchGlow.lineWidth = 4
        branchGlow.glowWidth = reducedMotion ? 0 : 6
        branchGlow.name = "storySequencePreview"
        preview.addChild(branchGlow)

        let activePattern = WordGardenEncounterCatalog.storyHollowPattern(for: encounter)
        for (index, glyphValue) in activePattern.enumerated() {
            if let socket = childNode(withName: "storySlot\(index)") as? SKShapeNode {
                socket.fillColor = UIColor(red: 0.36, green: 0.25, blue: 0.48, alpha: 0.98)
                socket.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.38, alpha: 1)
                socket.glowWidth = reducedMotion ? 0 : 8
            }
            if let glyph = childNode(withName: "//storySlotGlyph\(index)") as? SKLabelNode {
                glyph.text = glyphValue
                glyph.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 1)
            }
        }

        addChild(preview)
        targetRune = preview
        instruction.text = retryMessage ?? "Watch the tree remember its three seed-runes."

        let targetIndex = WordGardenEncounterCatalog.storyHollowPosition(for: encounter)
        let positionName = ["first", "middle", "last"][targetIndex]

        run(
            .sequence([
                .wait(forDuration: reducedMotion ? 0.35 : 1.35),
                .run { [weak self, weak preview] in
                    guard let self, !self.hasLeftScene else { return }
                    preview?.removeFromParent()
                    if self.targetRune === preview {
                        self.targetRune = nil
                    }
                    self.refreshStoryHollowProgress()
                    self.acceptingChoices = true
                    self.showAttentionCue(
                        at: CGPoint(x: 760, y: 165),
                        tint: UIColor(red: 0.88, green: 0.70, blue: 1.0, alpha: 1),
                        width: 190
                    )
                    self.instruction.text = "Restore the \(positionName) seed-rune from the roots."
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

        let stemPath = CGMutablePath()
        stemPath.move(to: CGPoint(x: 0, y: -58))
        stemPath.addCurve(
            to: CGPoint(x: 0, y: -8),
            control1: CGPoint(x: index.isMultiple(of: 2) ? -12 : 12, y: -44),
            control2: CGPoint(x: index.isMultiple(of: 2) ? 8 : -8, y: -22)
        )
        let stem = SKShapeNode(path: stemPath)
        stem.strokeColor = UIColor(red: 0.30, green: 0.50, blue: 0.19, alpha: 1)
        stem.lineWidth = 8
        stem.name = "decorativeSunmillChoiceStem"
        stem.zPosition = -2
        node.addChild(stem)

        let socket = SKShapeNode(circleOfRadius: 17)
        socket.position = CGPoint(x: 0, y: -61)
        socket.fillColor = UIColor(red: 0.82, green: 0.58, blue: 0.23, alpha: 0.92)
        socket.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.44, alpha: 0.78)
        socket.lineWidth = 3
        socket.name = "decorativeSunmillChoiceSocket"
        socket.zPosition = -1
        node.addChild(socket)

        let leafPath = CGMutablePath()
        leafPath.move(to: CGPoint(x: -55, y: -18))
        leafPath.addCurve(
            to: CGPoint(x: 55, y: 18),
            control1: CGPoint(x: -44, y: 46),
            control2: CGPoint(x: 30, y: 46)
        )
        leafPath.addCurve(
            to: CGPoint(x: -55, y: -18),
            control1: CGPoint(x: 44, y: -46),
            control2: CGPoint(x: -30, y: -46)
        )
        leafPath.closeSubpath()

        let leaf = SKShapeNode(path: leafPath)
        leaf.fillColor = UIColor(red: 0.47, green: 0.74, blue: 0.34, alpha: 0.98)
        leaf.strokeColor = UIColor(red: 0.88, green: 0.84, blue: 0.42, alpha: 0.94)
        leaf.lineWidth = 4
        leaf.zRotation = index.isMultiple(of: 2) ? -0.10 : 0.10
        leaf.name = "sunmillChoice"
        leaf.glowWidth = 2
        node.addChild(leaf)

        let veinPath = CGMutablePath()
        veinPath.move(to: CGPoint(x: -36, y: -8))
        veinPath.addLine(to: CGPoint(x: 35, y: 9))
        let vein = SKShapeNode(path: veinPath)
        vein.strokeColor = UIColor(red: 0.30, green: 0.51, blue: 0.20, alpha: 0.62)
        vein.lineWidth = 2
        vein.name = "sunmillChoice"
        node.addChild(vein)

        let label = ArtSystem.label(letter, size: 42)
        label.fontColor = UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 1)
        label.name = "sunmillChoice"
        node.addChild(label)

        return node
    }

    private func storyHollowChoiceNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()

        let rootPath = CGMutablePath()
        rootPath.move(to: CGPoint(x: 0, y: -62))
        rootPath.addCurve(
            to: CGPoint(x: 0, y: -16),
            control1: CGPoint(x: index.isMultiple(of: 2) ? -16 : 16, y: -48),
            control2: CGPoint(x: index.isMultiple(of: 2) ? 10 : -10, y: -30)
        )
        let root = SKShapeNode(path: rootPath)
        root.strokeColor = UIColor(red: 0.29, green: 0.47, blue: 0.24, alpha: 0.95)
        root.lineWidth = 10
        root.name = "decorativeStoryChoiceRoot"
        root.zPosition = -2
        node.addChild(root)

        let rootKnot = SKShapeNode(circleOfRadius: 15)
        rootKnot.position = CGPoint(x: 0, y: -62)
        rootKnot.fillColor = UIColor(red: 0.42, green: 0.30, blue: 0.17, alpha: 0.92)
        rootKnot.strokeColor = UIColor(red: 0.66, green: 0.54, blue: 0.28, alpha: 0.74)
        rootKnot.lineWidth = 3
        rootKnot.name = "decorativeStoryChoiceRootKnot"
        rootKnot.zPosition = -1
        node.addChild(rootKnot)

        let seedPath = CGMutablePath()
        seedPath.move(to: CGPoint(x: 0, y: 46))
        seedPath.addCurve(
            to: CGPoint(x: 54, y: -5),
            control1: CGPoint(x: 38, y: 33),
            control2: CGPoint(x: 58, y: 14)
        )
        seedPath.addCurve(
            to: CGPoint(x: 0, y: -39),
            control1: CGPoint(x: 48, y: -29),
            control2: CGPoint(x: 24, y: -42)
        )
        seedPath.addCurve(
            to: CGPoint(x: -54, y: -5),
            control1: CGPoint(x: -24, y: -42),
            control2: CGPoint(x: -48, y: -29)
        )
        seedPath.addCurve(
            to: CGPoint(x: 0, y: 46),
            control1: CGPoint(x: -58, y: 14),
            control2: CGPoint(x: -38, y: 33)
        )
        seedPath.closeSubpath()

        let seedStone = SKShapeNode(path: seedPath)
        seedStone.fillColor = UIColor(red: 0.35, green: 0.27, blue: 0.44, alpha: 0.96)
        seedStone.strokeColor = UIColor(red: 0.82, green: 0.66, blue: 0.34, alpha: 0.88)
        seedStone.lineWidth = 4
        seedStone.glowWidth = 2
        seedStone.zRotation = index.isMultiple(of: 2) ? -0.07 : 0.07
        seedStone.name = "storyHollowChoice"
        node.addChild(seedStone)

        let innerSeed = SKShapeNode(ellipseOf: CGSize(width: 68, height: 42))
        innerSeed.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.34, alpha: 0.30)
        innerSeed.strokeColor = UIColor(red: 0.98, green: 0.82, blue: 0.47, alpha: 0.12)
        innerSeed.lineWidth = 1.5
        innerSeed.position.y = -3
        innerSeed.name = "storyHollowChoice"
        node.addChild(innerSeed)

        let glyph = ArtSystem.label(letter, size: 40)
        glyph.fontColor = UIColor(red: 1.0, green: 0.94, blue: 0.79, alpha: 1)
        glyph.name = "storyHollowChoice"
        node.addChild(glyph)

        let sprout = SKShapeNode(ellipseOf: CGSize(width: 32, height: 15))
        sprout.position = CGPoint(x: index.isMultiple(of: 2) ? -34 : 34, y: 38)
        sprout.zRotation = index.isMultiple(of: 2) ? 0.58 : -0.58
        sprout.fillColor = UIColor(red: 0.49, green: 0.70, blue: 0.31, alpha: 0.90)
        sprout.strokeColor = UIColor(red: 0.82, green: 0.82, blue: 0.39, alpha: 0.38)
        sprout.lineWidth = 2
        sprout.name = "decorativeStoryChoiceSprout"
        node.addChild(sprout)

        return node
    }


    // MARK: - Lumi's living seed patch (free creative play, not a literacy score)

    private func buildLivingGardenBeacon() {
        let root = SKNode()
        root.name = "livingGardenBeacon"
        root.position = CGPoint(x: 475, y: 465)
        root.zPosition = 850
        let bed = ArtSystem.box(
            CGSize(width: 122, height: 52),
            color: UIColor(red: 0.33, green: 0.24, blue: 0.16, alpha: 0.96),
            radius: 15
        )
        bed.name = root.name
        bed.strokeColor = UIColor(red: 0.87, green: 0.75, blue: 0.41, alpha: 0.95)
        bed.lineWidth = 3
        root.addChild(bed)
        let sprout = ArtSystem.label("❀", size: 38)
        sprout.name = root.name
        sprout.position.y = 10
        sprout.fontColor = UIColor(red: 0.71, green: 0.94, blue: 0.52, alpha: 1)
        root.addChild(sprout)
        let sign = ArtSystem.label("SEED PATCH", size: 13)
        sign.name = root.name
        sign.position.y = -18
        sign.fontColor = .white
        root.addChild(sign)
        makeAccessible(root, label: "Lumi's living seed patch",
                       hint: "Explore planting, rain, sunlight, shade, and different flowers.")
        addChild(root)
    }

    private func enterLivingGarden() {
        guard place == .flowerGate, !livingGardenMode, !interactionInFlight else { return }
        removeAction(forKey: "wordGardenPreview")
        removeAction(forKey: "nextLiteracyEncounter")
        clearQuestionAndChoices()
        livingGardenMode = true
        gardenSelectedSeed = nil
        gardenSelectedCare = nil
        childNode(withName: "livingGardenBeacon")?.isHidden = true
        renderLivingGarden()
        instruction.text = "Choose a seed, then plant it. Try rain, sunlight, or shade."
    }

    private func exitLivingGarden() {
        guard livingGardenMode else { return }
        livingGardenMode = false
        gardenSelectedSeed = nil
        gardenSelectedCare = nil
        livingGardenStage?.removeFromParent()
        livingGardenStage = nil
        childNode(withName: "livingGardenBeacon")?.isHidden = false
        // Resume the ordinary, unscored-interrupted encounter from the start.
        if state.flowerGateComplete {
            activateFlowerGate()
            showSunmillRoute()
        } else {
            encounter = state.nextLiteracyEncounter()
            buildFlowerEncounter()
        }
    }

    private func gardenIndex(at point: CGPoint, among choices: [CGPoint]) -> Int? {
        choices.indices.first { hypot(point.x - choices[$0].x,
                                      point.y - choices[$0].y) <= 57 }
    }

    private func renderLivingGarden() {
        livingGardenStage?.removeFromParent()
        let root = SKNode()
        root.name = "livingGardenStage"
        root.zPosition = 1300
        addChild(root)
        livingGardenStage = root
        let seedNames = ["STARBLOOM", "RAINVINE", "SHADEFERN"]
        let seedMarks = ["✦", "≈", "☾"]
        let seedTints: [UIColor] = [
            UIColor(red: 0.98, green: 0.76, blue: 0.31, alpha: 1),
            UIColor(red: 0.44, green: 0.82, blue: 0.98, alpha: 1),
            UIColor(red: 0.70, green: 0.87, blue: 0.61, alpha: 1)
        ]

        // Seeds rest in a timber nursery rack; no floating answer buttons.
        for (index, point) in gardenSeedPoints.enumerated() {
            let seed = LumiSeed(rawValue: index)!
            let selected = gardenSelectedSeed == seed
            let tray = SKNode()
            tray.name = "livingSeed\(index)"
            tray.position = point
            let timber = ArtSystem.box(
                CGSize(width: 138, height: 68),
                color: UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 0.97),
                radius: 12
            )
            timber.name = tray.name
            timber.strokeColor = seedTints[index]
            timber.lineWidth = selected ? 6 : 2
            timber.glowWidth = selected && !reducedMotion ? 10 : 0
            tray.addChild(timber)

            let seedMark = ArtSystem.label(seedMarks[index], size: 31)
            seedMark.name = tray.name
            seedMark.position.y = 10
            seedMark.fontColor = seedTints[index]
            tray.addChild(seedMark)

            let label = ArtSystem.label(seedNames[index], size: 12)
            label.name = tray.name
            label.position.y = -23
            label.fontColor = .white
            tray.addChild(label)
            makeAccessible(tray, label: "Select \(seedNames[index]) seed",
                           hint: "Then tap a pot to plant it.")
            root.addChild(tray)
        }

        let toolNames = ["RAIN", "SUNLIGHT", "SHADE"]
        let toolGlyphs = ["☂", "☀", "☾"]
        let careModes: [LumiGardenCare] = [.water, .sun, .shade]
        for (index, point) in gardenToolPoints.enumerated() {
            let selected = gardenSelectedCare == careModes[index]
            let control = SKNode()
            control.name = "livingCare\(index)"
            control.position = point
            let stone = ArtSystem.box(
                CGSize(width: 124, height: 58),
                color: UIColor(red: 0.25, green: 0.30, blue: 0.22, alpha: 0.96),
                radius: 16
            )
            stone.name = control.name
            stone.strokeColor = selected
                ? UIColor(red: 1.0, green: 0.87, blue: 0.39, alpha: 1)
                : UIColor(red: 0.57, green: 0.75, blue: 0.47, alpha: 0.82)
            stone.lineWidth = selected ? 5 : 2
            control.addChild(stone)
            let mark = ArtSystem.label(toolGlyphs[index], size: 27)
            mark.name = control.name
            mark.position.y = 9
            mark.fontColor = .white
            control.addChild(mark)
            let label = ArtSystem.label(toolNames[index], size: 12)
            label.name = control.name
            label.position.y = -17
            label.fontColor = UIColor(red: 0.96, green: 0.91, blue: 0.72, alpha: 1)
            control.addChild(label)
            makeAccessible(control, label: "Use \(toolNames[index].lowercased())",
                           hint: "Choose this tool, then touch a planted pot.")
            root.addChild(control)
        }

        let garden = state.lumiLivingGarden
        for (index, point) in gardenPlotPoints.enumerated() {
            let plot = SKNode()
            plot.name = "livingPlot\(index)"
            plot.position = point
            let shadow = SKShapeNode(ellipseOf: CGSize(width: 143, height: 24))
            shadow.fillColor = UIColor(red: 0.09, green: 0.13, blue: 0.10, alpha: 0.45)
            shadow.strokeColor = .clear
            shadow.position.y = -75
            plot.addChild(shadow)

            let pot = ArtSystem.box(
                CGSize(width: 110, height: 78),
                color: UIColor(red: 0.50, green: 0.27, blue: 0.16, alpha: 1),
                radius: 16
            )
            pot.name = plot.name
            pot.position.y = -37
            pot.strokeColor = UIColor(red: 0.88, green: 0.60, blue: 0.32, alpha: 1)
            pot.lineWidth = 3
            plot.addChild(pot)

            let soil = SKShapeNode(ellipseOf: CGSize(width: 112, height: 24))
            soil.name = plot.name
            soil.position.y = 0
            soil.fillColor = UIColor(red: 0.26, green: 0.18, blue: 0.12, alpha: 1)
            soil.strokeColor = UIColor(red: 0.81, green: 0.58, blue: 0.29, alpha: 1)
            soil.lineWidth = 2
            plot.addChild(soil)

            if let living = garden.plot(at: index) {
                let tint = seedTints[living.seed.rawValue]
                if living.growthStage == 0 {
                    let seed = SKShapeNode(ellipseOf: CGSize(width: 22, height: 15))
                    seed.name = plot.name
                    seed.fillColor = tint
                    seed.strokeColor = .white
                    seed.position.y = 5
                    plot.addChild(seed)
                } else {
                    let stalk = SKShapeNode(rectOf: CGSize(width: 10, height: 81), cornerRadius: 5)
                    stalk.name = plot.name
                    stalk.position.y = 43
                    stalk.fillColor = UIColor(red: 0.31, green: 0.72, blue: 0.35, alpha: 1)
                    stalk.strokeColor = .clear
                    plot.addChild(stalk)

                    for direction in [-1.0, 1.0] {
                        let leaf = SKShapeNode(ellipseOf: CGSize(width: 41, height: 19))
                        leaf.name = plot.name
                        leaf.position = CGPoint(x: CGFloat(direction) * 21, y: 44)
                        leaf.zRotation = CGFloat(direction) * 0.43
                        leaf.fillColor = UIColor(red: 0.42, green: 0.80, blue: 0.38, alpha: 1)
                        leaf.strokeColor = .clear
                        plot.addChild(leaf)
                    }

                    if living.isBlooming {
                        for petal in 0..<6 {
                            let angle = CGFloat(petal) * .pi / 3
                            let bloom = SKShapeNode(ellipseOf: CGSize(width: 24, height: 41))
                            bloom.name = plot.name
                            bloom.position = CGPoint(x: sin(angle) * 30,
                                                     y: 94 + cos(angle) * 30)
                            bloom.zRotation = -angle
                            bloom.fillColor = tint
                            bloom.strokeColor = UIColor.white.withAlphaComponent(0.80)
                            bloom.lineWidth = 1.5
                            plot.addChild(bloom)
                        }
                        let center = SKShapeNode(circleOfRadius: 18)
                        center.name = plot.name
                        center.position.y = 94
                        center.fillColor = UIColor(red: 1, green: 0.91, blue: 0.43, alpha: 1)
                        center.strokeColor = .white
                        center.lineWidth = 2
                        center.glowWidth = reducedMotion ? 0 : 7
                        plot.addChild(center)
                    } else if living.seed == .shadefern && living.sunlight {
                        let curled = ArtSystem.label("☾", size: 22)
                        curled.name = plot.name
                        curled.position.y = 105
                        curled.fontColor = tint
                        plot.addChild(curled)
                    } else {
                        let bud = SKShapeNode(circleOfRadius: 16)
                        bud.name = plot.name
                        bud.position.y = 86
                        bud.fillColor = tint.withAlphaComponent(0.76)
                        bud.strokeColor = .white
                        plot.addChild(bud)
                    }
                }
                makeAccessible(plot, label: "Plot \(index + 1), \(seedNames[living.seed.rawValue]), " +
                    (living.isBlooming ? "flowering" : "growing"),
                    hint: "Tap after selecting rain, sun, shade, or a new seed.")
            } else {
                let plus = ArtSystem.label("✧", size: 36)
                plus.name = plot.name
                plus.position.y = 17
                plus.fontColor = UIColor(red: 0.94, green: 0.83, blue: 0.63, alpha: 1)
                plot.addChild(plus)
                makeAccessible(plot, label: "Empty garden pot \(index + 1)",
                               hint: "Choose a seed first, then tap this pot.")
            }
            root.addChild(plot)
        }

        let exit = SKShapeNode(circleOfRadius: 33)
        exit.name = "livingGardenExit"
        exit.position = CGPoint(x: 1170, y: 628)
        exit.fillColor = UIColor(red: 0.28, green: 0.23, blue: 0.16, alpha: 0.97)
        exit.strokeColor = UIColor(red: 0.95, green: 0.77, blue: 0.42, alpha: 1)
        exit.lineWidth = 3
        let arrow = ArtSystem.label("‹", size: 33)
        arrow.name = exit.name
        exit.addChild(arrow)
        makeAccessible(exit, label: "Return to Flower Gate")
        root.addChild(exit)
    }

    private func handleLivingGardenTap(at point: CGPoint) {
        if hypot(point.x - 1170, point.y - 628) <= 47 {
            exitLivingGarden()
            return
        }
        if let index = gardenIndex(at: point, among: gardenSeedPoints),
           let seed = LumiSeed(rawValue: index) {
            gardenSelectedSeed = seed
            gardenSelectedCare = nil
            state.audio.play("crystal")
            instruction.text = "Choose a pot for your seed. Every plant has different needs."
            renderLivingGarden()
            return
        }
        if let index = gardenIndex(at: point, among: gardenToolPoints) {
            let careModes: [LumiGardenCare] = [.water, .sun, .shade]
            gardenSelectedCare = careModes[index]
            gardenSelectedSeed = nil
            instruction.text = "Now tap a planted pot. See how your plant responds."
            renderLivingGarden()
            return
        }
        guard let index = gardenIndex(at: point, among: gardenPlotPoints) else {
            instruction.text = "Try a seed, a weather tool, or a garden pot."
            return
        }
        let bloomsBefore = state.lumiLivingGarden.bloomingCount
        let changed: Bool
        if let seed = gardenSelectedSeed {
            changed = state.plantLumiSeed(seed, at: index)
            instruction.text = changed ? "A new seed is planted. Choose rain, sun, or shade."
                : "That seed is already growing here. Try a different seed."
        } else if let care = gardenSelectedCare {
            changed = state.tendLumiGarden(care, at: index)
            if changed {
                let plot = state.lumiLivingGarden.plot(at: index)
                instruction.text = plot?.isBlooming == true
                    ? "It bloomed! Try another seed or change the weather."
                    : care == .sun && plot?.seed == .shadefern
                        ? "The fern curled in the sunlight. Can shade help it?"
                        : "The plant changed! What will happen if you try another tool?"
            } else {
                instruction.text = "Nothing new happened. Try another tool or another seed."
            }
        } else {
            instruction.text = "Choose a seed or a weather tool before tapping a pot."
            return
        }

        guard changed else { return }
        state.audio.play(state.lumiLivingGarden.bloomingCount > bloomsBefore ? "success" : "crystal")
        if state.lumiLivingGarden.bloomingCount > bloomsBefore {
            lumi.pose(.react)
            valkyrie.pose(.celebrate)
            successFeedback(at: gardenPlotPoints[index])
            if bloomsBefore == 0 {
                instruction.text = "Lumi's first bloom! You earned a living flower for Story Tree."
            }
        } else {
            lumi.pose(.react)
            valkyrie.pose(.interact)
        }
        renderLivingGarden()
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
        guard let point = completedTap(in: touches) else { return }
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
        focusMoment(on: node.position, hold: 0.62)
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
        focusMoment(on: node.position, hold: 0.62)
        interactionInFlight = true
        let destination = CGPoint(x: max(170, node.position.x - 105), y: 175)
        valkyrie.walk(to: destination) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
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
            animateStoryMemoryTransfer(from: node)
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
        let total = max(1, WordGardenEncounterCatalog.sunmillVisualShapes.count)
        let ratio = min(1, CGFloat(count) / CGFloat(total))
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
            water.alpha = 0.32 + ratio * 0.48
            water.glowWidth = state.sunmillComplete ? 13 : ratio * 7
        }

        if let current = childNode(withName: "sunmillLightPath") as? SKShapeNode {
            current.alpha = 0.20 + ratio * 0.75
            current.glowWidth = reducedMotion ? 0 : 4 + ratio * 8
        }

        if let hubGlow = childNode(withName: "//sunmillHubGlow") as? SKShapeNode {
            hubGlow.alpha = 0.42 + ratio * 0.58
            hubGlow.setScale(0.92 + ratio * 0.13)
        }

        let revealedPlanks = Int(ceil(ratio * 7))
        for index in 0..<7 {
            guard let plank = childNode(withName: "//sunmillBridgePlank\(index)") else { continue }
            let restored = index < revealedPlanks
            let targetAlpha: CGFloat = restored ? 1.0 : 0.16
            if animated && !reducedMotion {
                plank.run(.fadeAlpha(to: targetAlpha, duration: 0.32))
            } else {
                plank.alpha = targetAlpha
            }
        }

        if let rail = childNode(withName: "//sunmillBridgeRail") {
            rail.alpha = 0.18 + ratio * 0.82
        }
        for support in children.flatMap({ $0.children }).filter({ $0.name == "sunmillBridgeSupport" }) {
            support.alpha = 0.34 + ratio * 0.66
        }

        childNode(withName: "sunmillBridge")?.isHidden = false
    }

    private func showStoryHollowRoute() {
        guard state.storyHollowAvailable,
              childNode(withName: "storyHollowRoute") == nil else { return }
        let route = destinationMarker(
            "Story Hollow",
            symbol: "☾",
            name: "storyHollowRoute",
            at: CGPoint(x: 1095, y: 300),
            tint: UIColor(red: 0.88, green: 0.70, blue: 1.0, alpha: 1),
            width: 150,
            plaqueOffsetY: -55
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

    private func animateStoryMemoryTransfer(from node: SKNode) {
        guard !reducedMotion else { return }

        let mote = SKShapeNode(circleOfRadius: 8)
        mote.position = node.position
        mote.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.38, alpha: 1)
        mote.strokeColor = UIColor(red: 0.95, green: 0.76, blue: 1.0, alpha: 0.90)
        mote.lineWidth = 2
        mote.glowWidth = 10
        mote.name = "storyMemoryTransfer"
        mote.zPosition = 900
        addChild(mote)

        let path = CGMutablePath()
        path.move(to: node.position)
        path.addCurve(
            to: CGPoint(x: 825, y: 270),
            control1: CGPoint(x: node.position.x, y: node.position.y + 70),
            control2: CGPoint(x: 825, y: 205)
        )
        path.addCurve(
            to: CGPoint(x: 1035, y: 430),
            control1: CGPoint(x: 760, y: 345),
            control2: CGPoint(x: 910, y: 390)
        )

        mote.run(.sequence([
            .follow(path, asOffset: false, orientToPath: false, duration: 0.62),
            .group([
                .scale(to: 1.8, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
    }

    private func refreshStoryHollowProgress() {
        let count = WordGardenDirector.independentSuccessCount(
            for: WordGardenEncounterCatalog.storyHollowSequence,
            profile: state.profile
        )
        let total = max(1, WordGardenEncounterCatalog.storyHollowSequence.count)
        let ratio = min(1, CGFloat(count) / CGFloat(total))

        if let seed = childNode(withName: "wordSeed") as? SKShapeNode {
            seed.setScale(0.78 + ratio * 0.42)
            seed.alpha = 0.64 + ratio * 0.36
            seed.glowWidth = 3 + ratio * 13
        }

        childNode(withName: "storyStem")?.yScale = 0.48 + ratio * 0.52

        let visibleMemory = WordGardenEncounterCatalog.storyHollowVisiblePatternProgress(
            independentCount: count
        )
        for index in 0..<WordGardenEncounterCatalog.storyHollowPatternLength {
            let filled = index < visibleMemory.filledCount

            if let rootGlow = childNode(withName: "storyRootGlow\(index)") as? SKShapeNode {
                rootGlow.alpha = filled ? 0.92 : 0.10
                rootGlow.glowWidth = reducedMotion ? 0 : (filled ? 10 : 3)
            }

            if let socket = childNode(withName: "storySlot\(index)") as? SKShapeNode {
                socket.fillColor = filled
                    ? UIColor(red: 0.35, green: 0.25, blue: 0.47, alpha: 0.98)
                    : UIColor(red: 0.23, green: 0.18, blue: 0.30, alpha: 0.92)
                socket.strokeColor = filled
                    ? UIColor(red: 0.98, green: 0.79, blue: 0.38, alpha: 1)
                    : UIColor(red: 0.69, green: 0.62, blue: 0.40, alpha: 0.72)
                socket.glowWidth = reducedMotion ? 0 : (filled ? 9 : 0)
            }

            if let glyph = childNode(withName: "//storySlotGlyph\(index)") as? SKLabelNode {
                glyph.text = filled ? visibleMemory.pattern[index] : "·"
                glyph.fontColor = filled
                    ? UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 1)
                    : UIColor(red: 0.92, green: 0.86, blue: 0.72, alpha: 0.9)
            }
        }

        if let doorGlow = childNode(withName: "storyHollowDoorGlow") as? SKShapeNode {
            doorGlow.alpha = 0.22 + ratio * 0.78
            doorGlow.glowWidth = reducedMotion ? 0 : 4 + ratio * 12
        }

        if let branch = childNode(withName: "storyMemoryBranch") as? SKShapeNode {
            branch.strokeColor = UIColor(
                red: 0.38 + ratio * 0.08,
                green: 0.27 + ratio * 0.25,
                blue: 0.14 + ratio * 0.08,
                alpha: 0.92
            )
            branch.glowWidth = reducedMotion ? 0 : ratio * 6
        }

        let visibleBlooms = Int(ceil(ratio * 5))
        for index in 0..<5 {
            let bloom = childNode(withName: "storyCanopyBloom\(index)")
            bloom?.alpha = index < visibleBlooms ? 0.86 : 0.12
            if index < visibleBlooms {
                bloom?.setScale(0.88 + ratio * 0.18)
            }
        }
    }

    private func activateStoryHollow() {
        removeAction(forKey: "wordGardenPreview")
        clearQuestionAndChoices()
        refreshStoryHollowProgress()

        if let hollow = childNode(withName: "storyHollow") as? SKShapeNode {
            hollow.strokeColor = UIColor(red: 0.56, green: 0.77, blue: 0.36, alpha: 1)
            hollow.glowWidth = reducedMotion ? 0 : 16
        }

        if let doorGlow = childNode(withName: "storyHollowDoorGlow") as? SKShapeNode {
            doorGlow.alpha = 1
            doorGlow.strokeColor = UIColor(red: 0.88, green: 0.72, blue: 1.0, alpha: 0.96)
            doorGlow.glowWidth = reducedMotion ? 0 : 18
        }

        childNode(withName: "//hollowMoon")?.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.28, duration: 0.2),
            .scale(to: 1.0, duration: reducedMotion ? 0 : 0.2)
        ]))

        if childNode(withName: "storyBloom") == nil {
            let bloomRoot = SKNode()
            bloomRoot.position = CGPoint(x: 825, y: 338)
            bloomRoot.name = "storyBloom"
            bloomRoot.zPosition = 640

            if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 116, height: 116)) {
                bloom.name = "storyBloom"
                bloomRoot.addChild(bloom)
            } else {
                let bloom = ArtSystem.label("✿", size: 74)
                bloom.fontColor = UIColor(red: 1.0, green: 0.66, blue: 0.81, alpha: 1)
                bloom.name = "storyBloom"
                bloomRoot.addChild(bloom)
            }
            addChild(bloomRoot)
        }

        if childNode(withName: "storyTreeReturn") == nil {
            let returnMarker = destinationMarker(
                "Story Tree",
                symbol: "✦",
                name: "storyTreeReturn",
                at: CGPoint(x: 1090, y: 195),
                tint: UIColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 1),
                width: 138,
                plaqueOffsetY: -52
            )
            returnMarker.zPosition = 840
        }

        instruction.text = state.hasStoryReward(.wordGardenLantern)
            ? "The memory tree is awake. Follow its lantern home to the Story Tree."
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

        if lastKineticReducedMotion != reducedMotion
            || lastKineticCompletionKey != wordGardenKineticCompletionKey {
            syncWordGardenKinetics()
        }
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
