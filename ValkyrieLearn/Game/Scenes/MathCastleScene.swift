import SpriteKit
import LearningCore

@MainActor final class MathCastleScene: AdventureScene {
    private var mechanic: SKNode?
    private var renderedEncounterID: String?
    private let station = CGPoint(x: 490, y: 175)
    // Optional, unscored physical adventure. The learned math encounter stays in
    // LearningCore; this separate world state lives in the saved learner profile.
    private var bridgeQuestMode = false
    private var bridgeQuestBusy = false
    private var bridgeQuestSelectedCrystal: Int?
    private var bridgeQuestDraggedCrystal: Int?
    private var bridgeQuestSelectedSocket: Int?
    private var bridgeQuestStage: SKNode?
    // Ground the collectibles on plinths beside the broken span. The earlier
    // version floated circular quiz-looking inputs over the castle skyline.
    private let bridgeCrystalPoints = [
        CGPoint(x: 330, y: 306),
        CGPoint(x: 468, y: 306),
        CGPoint(x: 605, y: 306)
    ]
    private let bridgeInventoryPoints = [
        CGPoint(x: 360, y: 130),
        CGPoint(x: 490, y: 130),
        CGPoint(x: 620, y: 130)
    ]
    private let bridgeSocketPoints = [
        CGPoint(x: 760, y: 302),
        CGPoint(x: 905, y: 302),
        CGPoint(x: 1050, y: 302)
    ]
    private let bridgeCrystalTints: [UIColor] = [
        UIColor(red: 0.46, green: 0.86, blue: 1.0, alpha: 1),
        UIColor(red: 0.97, green: 0.79, blue: 0.43, alpha: 1),
        UIColor(red: 0.79, green: 0.62, blue: 1.0, alpha: 1)
    ]

    // Physical load-testing mini-game: a child can keep investigating
    // after rescuing the firefly. This does not generate learning evidence.
    private var bridgeSelectedLoad: BridgeTestLoad = .supplyCart
    private var bridgeTrialResult: BridgeTestResult?
    private let bridgeBracePoints = [
        CGPoint(x: 760, y: 184),
        CGPoint(x: 905, y: 184),
        CGPoint(x: 1050, y: 184)
    ]
    // The rescued firefly and supply cart stand on existing stone plinths,
    // and the lever is mounted at the bridge's foot, not floating in the sky.
    private let bridgeLoadChoicePoints = [
        CGPoint(x: 468, y: 306), // light firefly on middle courtyard plinth
        CGPoint(x: 605, y: 306)  // supply cart on right courtyard plinth
    ]
    private let bridgeTestLeverPoint = CGPoint(x: 1150, y: 270)

    private var activeTouch: UITouch?
    private var dragOrigin: String?
    private var startPoint = CGPoint.zero
    private var ghost: SKShapeNode?
    private var didDrag = false
    private var engaged = false
    private var lastPreviewVisible = false
    private var selection: EncounterSelection?
    private var gate: SKNode?
    private var nextGear: SKNode?
    private var lever: SKNode?
    private var powerLight: SKShapeNode?
    private var routeLights: [SKShapeNode] = []
    private var challengeRunes: [SKShapeNode] = []
    private var wasPowered = false
    private var initialBuildComplete = false
    private var physicalBridge: SKNode?
    private var powerConduit: SKShapeNode?
    private var destinationBeacon: SKShapeNode?
    private var starlightOrb: SKShapeNode?
    private var environmentGears: [SKNode] = []
    private var lastKineticReducedMotion: Bool?
    private var routeReady = false
    private var routeDestination: CGPoint { bridgePath.last! }
    private let routeEnergyPoints = [
        CGPoint(x: 890, y: 330),
        CGPoint(x: 965, y: 350),
        CGPoint(x: 1035, y: 380),
        CGPoint(x: 1090, y: 420)
    ]
    private let bridgeRouteNode = SKNode()
    private(set) var crossingBridge = false
    private var hasLeftScene = false
    private let bridgePath = [
        CGPoint(x: 490, y: 175), CGPoint(x: 560, y: 200),
        CGPoint(x: 596, y: 244), CGPoint(x: 692, y: 244),
        CGPoint(x: 788, y: 244), CGPoint(x: 884, y: 244),
        CGPoint(x: 980, y: 244),
        CGPoint(x: 1040, y: 244), CGPoint(x: 1080, y: 286),
        CGPoint(x: 1110, y: 350), CGPoint(x: 1110, y: 400)
    ]
    private var bridgeQuestAllowsPassage: Bool {
        !state.starlightBridgeQuest.discovered || state.starlightBridgeQuest.isComplete
    }

    private var repairedBridge: Bool {
        state.runtime?.encounter.mechanicID == MathMechanicID.missingNumberBridge
            && state.runtime?.completed == true
    }
    private let questionPlate = SKShapeNode(
        rectOf: CGSize(width: 470, height: 92),
        cornerRadius: 15
    )
    private let questionHeading = ArtSystem.label("PIP'S WORK ORDER", size: 13)
    private let questionLabel = ArtSystem.label("", size: 23)
    private var workshopIndices = [0, 0, 0, 0, 0]

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        // The v3.31 reference keeps the protagonist inside the world composition
        // instead of letting the character dominate the learning object.
        valkyrie.setScale(0.58)
        pip.setScale(0.72)
        polishMathCastleHUD()
        syncCastleKinetics()
        initialBuildComplete = true
    }

    private func polishMathCastleHUD() {
        childNode(withName: "worldTitleBackdrop")?.removeFromParent()
        childNode(withName: "worldTitle")?.removeFromParent()

        let titlePlate = ArtSystem.plaque(
            CGSize(width: 230, height: 42),
            fill: UIColor(red: 0.045, green: 0.065, blue: 0.13, alpha: 0.88),
            stroke: UIColor(red: 0.90, green: 0.70, blue: 0.32, alpha: 0.58),
            radius: 15
        )
        titlePlate.position = CGPoint(x: 205, y: 672)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)

        let title = ArtSystem.label(worldTitle, size: 22)
        title.fontName = "Georgia-Bold"
        title.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 140, y: 672)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        // Fit the shared world identity into the castle's compact title plaque.
        if let emblem = childNode(withName: "decorativeWorldEmblem") {
            emblem.position = CGPoint(x: 111, y: 672)
            emblem.setScale(0.72)
        }

        childNode(withName: "topVignette")?.alpha = 0.48

        if let feedbackPlate = childNode(withName: "instructionBackdrop") {
            feedbackPlate.xScale = 0.69
            feedbackPlate.yScale = 0.80
            feedbackPlate.position = CGPoint(x: 640, y: 44)
        }
        instruction.position = CGPoint(x: 640, y: 44)
        instruction.fontName = "AvenirNext-Medium"
        instruction.fontSize = 18
        instruction.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.84, alpha: 1)
        instruction.preferredMaxLayoutWidth = 600
    }

    private func addCompactHomeControl() {
        let root = SKNode()
        root.name = "home"
        root.position = CGPoint(x: 52, y: 672)
        root.zPosition = 2000

        let medallion = ArtSystem.medallion(
            radius: 22,
            fill: UIColor(red: 0.05, green: 0.06, blue: 0.14, alpha: 0.92),
            stroke: UIColor(red: 0.90, green: 0.70, blue: 0.32, alpha: 0.52),
            glow: reducedMotion ? 0 : 1
        )
        medallion.name = "home"
        medallion.addChild(ArtSystem.label("‹", size: 22))
        root.addChild(medallion)

        // Keep a child-friendly 60pt hit target without making the back control
        // visually compete with the world title.
        let hit = SKShapeNode(circleOfRadius: 30)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = "home"
        hit.zPosition = 2
        root.addChild(hit)

        makeAccessible(root, label: "Back")
        addChild(root)
    }

    private func addCompactWorkshopGear(
        _ symbol: String,
        name: String,
        at point: CGPoint,
        accessibilityLabel: String
    ) {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 750

        // Keep the icon upright while the brass rim rotates independently.
        // This makes the workshop feel mechanical without sacrificing symbol readability.
        let gear = ArtSystem.gear(radius: 22, symbol: "")
        gear.name = "workshopRim_\(name)"
        gear.alpha = 0.86
        root.addChild(gear)

        let icon = ArtSystem.label(symbol, size: 18)
        icon.name = name
        icon.fontColor = UIColor(red: 0.95, green: 0.95, blue: 0.92, alpha: 1)
        icon.zPosition = 3
        root.addChild(icon)

        let hit = SKShapeNode(circleOfRadius: 30)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = name
        hit.zPosition = 2
        root.addChild(hit)

        makeAccessible(root, label: accessibilityLabel)
        registerInteraction(root, clearance: 14)
        addChild(root)
    }

    override func buildWorld() {
        super.buildWorld()
        prepareCastleIllustrationForRetina()
        buildCastleFidelityAccents()

        addCompactHomeControl()
        // Keep the approved painted courtyard, but prepare enough physical pixels
        // for the Retina surface before SpriteKit composites live gameplay over it.
        if let floor = ArtSystem.retinaEnhancedSprite(
            "CastleCourtyard",
            size: CGSize(width: 1280, height: 250),
            sharpness: 0.24
        ) {
            floor.position = CGPoint(x: 640, y: 125)
            floor.zPosition = -80
            floor.name = "castleCourtyardRetina"
            addChild(floor)
        }

        // Ground the active mechanic on a low-perspective workshop dais instead of
        // a translucent modal panel. The ellipse follows the painted courtyard and
        // makes every manipulative feel physically installed in the castle.
        let workZone = SKShapeNode(ellipseOf: CGSize(width: 650, height: 150))
        workZone.fillColor = UIColor(red: 0.07, green: 0.11, blue: 0.18, alpha: 0.16)
        workZone.strokeColor = UIColor(red: 0.91, green: 0.70, blue: 0.30, alpha: 0.34)
        workZone.lineWidth = 3
        workZone.position = CGPoint(x: 820, y: 246)
        workZone.zPosition = 5
        workZone.name = "mathWorkZone"
        addChild(workZone)

        let workZoneCore = SKShapeNode(ellipseOf: CGSize(width: 540, height: 104))
        workZoneCore.fillColor = UIColor(red: 0.08, green: 0.21, blue: 0.28, alpha: 0.08)
        workZoneCore.strokeColor = UIColor(red: 0.47, green: 0.84, blue: 0.93, alpha: 0.20)
        workZoneCore.lineWidth = 2
        workZoneCore.position = CGPoint(x: 820, y: 246)
        workZoneCore.zPosition = 6
        workZoneCore.name = "mathWorkZoneCore"
        addChild(workZoneCore)

        let workZoneRail = ArtSystem.box(
            CGSize(width: 500, height: 7),
            color: UIColor(red: 0.91, green: 0.70, blue: 0.30, alpha: 0.42),
            radius: 3
        )
        workZoneRail.position = CGPoint(x: 820, y: 205)
        workZoneRail.strokeColor = .clear
        workZoneRail.zPosition = 7
        workZoneRail.name = "mathWorkZoneRail"
        addChild(workZoneRail)

        // Compress the workshop selector into an in-world instrument rail. Keep
        // the original centers and 60pt hit areas so this is a visual simplification,
        // not an interaction change.
        let rackBacking = ArtSystem.plaque(
            CGSize(width: 390, height: 56),
            fill: UIColor(red: 0.055, green: 0.085, blue: 0.14, alpha: 0.38),
            stroke: UIColor(red: 0.87, green: 0.66, blue: 0.29, alpha: 0.30),
            radius: 18
        )
        rackBacking.position = CGPoint(x: 300, y: 548)
        rackBacking.zPosition = 28
        rackBacking.alpha = 0.58
        rackBacking.name = "workshopRackBacking"
        addChild(rackBacking)

        let rack = ArtSystem.box(
            CGSize(width: 374, height: 10),
            color: .init(red: 0.55, green: 0.34, blue: 0.13, alpha: 1),
            radius: 3
        )
        if let texture = ArtSystem.texture("BridgeOakPlank") {
            rack.fillColor = .white
            rack.fillTexture = texture
            rack.strokeColor = .clear
        }
        rack.position = CGPoint(x: 300, y: 519)
        rack.zPosition = 30
        rack.alpha = 0.62
        rack.name = "workshopRack"
        addChild(rack)

        for x in [128, 472] {
            let post = ArtSystem.box(
                CGSize(width: 11, height: 78),
                color: .init(red: 0.55, green: 0.34, blue: 0.13, alpha: 1),
                radius: 3
            )
            if let texture = ArtSystem.texture("BridgeTimber") {
                post.fillColor = .white
                post.fillTexture = texture
                post.strokeColor = .clear
            }
            post.position = CGPoint(x: x, y: 505)
            post.zPosition = 29
            post.alpha = 0.48
            post.name = "workshopRack"
            addChild(post)
        }

        for (index, symbol) in ["◆", "⚖", "◉", "▦", "↔"].enumerated() {
            addCompactWorkshopGear(
                symbol,
                name: "workshop\(index)",
                at: CGPoint(x: 140 + index * 80, y: 548),
                accessibilityLabel: "Pip's workshop: \(MathWorkshopCatalog.stationNames[index])"
            )
        }
        addCompactWorkshopGear(
            "↻",
            name: "wind",
            at: CGPoint(x: 300, y: 615),
            accessibilityLabel: "Wind Pip's workshop gear"
        )

        // Keep the active prompt readable, but treat it like a compact hanging
        // work order instead of a full-width HUD banner.
        questionPlate.position = CGPoint(x: 800, y: 618)
        if let texture = ArtSystem.texture("BridgeWorkOrder") {
            questionPlate.fillColor = .white
            questionPlate.fillTexture = texture
            questionPlate.strokeColor = .clear
        } else {
            questionPlate.fillColor = UIColor(red: 0.34, green: 0.20, blue: 0.09, alpha: 0.96)
            questionPlate.strokeColor = UIColor(red: 0.95, green: 0.72, blue: 0.29, alpha: 0.95)
        }
        questionPlate.lineWidth = 2
        questionPlate.zPosition = 1995
        questionPlate.name = "questionPromptPlate"
        questionPlate.isHidden = true
        addChild(questionPlate)

        for x in [565.0, 1035.0] {
            let hanger = ArtSystem.box(
                CGSize(width: 9, height: 44),
                color: .init(red: 0.39, green: 0.27, blue: 0.15, alpha: 1),
                radius: 2
            )
            if let texture = ArtSystem.texture("BridgeTimber") {
                hanger.fillColor = .white
                hanger.fillTexture = texture
                hanger.strokeColor = .clear
            }
            hanger.position = CGPoint(x: x, y: 683)
            hanger.zPosition = 1994
            hanger.name = "questionPromptHanger"
            hanger.isHidden = true
            addChild(hanger)
        }

        questionHeading.position = CGPoint(x: 800, y: 643)
        questionHeading.fontName = "AvenirNext-Bold"
        questionHeading.fontSize = 14
        questionHeading.fontColor = UIColor(red: 1.0, green: 0.84, blue: 0.46, alpha: 1)
        questionHeading.zPosition = 2001
        questionHeading.name = "questionPromptHeading"
        questionHeading.isHidden = true
        addChild(questionHeading)

        questionLabel.position = CGPoint(x: 600, y: 610)
        questionLabel.horizontalAlignmentMode = .left
        questionLabel.fontName = "AvenirNext-Medium"
        questionLabel.preferredMaxLayoutWidth = 400
        questionLabel.fontSize = 18
        questionLabel.numberOfLines = 2
        questionLabel.fontColor = UIColor(red: 1.0, green: 0.97, blue: 0.86, alpha: 1)
        questionLabel.zPosition = 2000
        questionLabel.name = "questionPrompt"
        questionLabel.isHidden = true
        addChild(questionLabel)

        pip.name = "help"
        nextGear = worldGear("→", name: "next", at: CGPoint(x: 1200, y: 430), radius: 34)
        lever = makeLever()

        let workflow = SKShapeNode()
        let workflowPath = CGMutablePath()
        workflowPath.move(to: CGPoint(x: 600, y: 205))
        workflowPath.addCurve(
            to: CGPoint(x: 1080, y: 238),
            control1: CGPoint(x: 735, y: 180),
            control2: CGPoint(x: 930, y: 205)
        )
        workflow.path = workflowPath
        workflow.strokeColor = UIColor(red: 0.76, green: 0.64, blue: 0.38, alpha: 0.34)
        workflow.lineWidth = 5
        workflow.glowWidth = 2
        workflow.zPosition = 20
        workflow.name = "workOrderFlow"
        addChild(workflow)

        let powerMount = ArtSystem.gear(radius: 34)
        powerMount.position = CGPoint(x: 1105, y: 352)
        powerMount.zPosition = 39
        powerMount.name = "castlePowerMount"
        addChild(powerMount)

        let light = SKShapeNode(circleOfRadius: 17)
        light.position = CGPoint(x: 1105, y: 352); light.zPosition = 40; light.lineWidth = 2
        light.name = "castlePowerLight"
        light.fillColor = .init(red: 0.14, green: 0.18, blue: 0.29, alpha: 1)
        light.strokeColor = .init(red: 0.95, green: 0.71, blue: 0.32, alpha: 1)
        addChild(light); powerLight = light
        let portal = SKShapeNode(ellipseOf: CGSize(width: 115, height: 170))
        portal.position = CGPoint(x: 1125, y: 567); portal.zPosition = 25; portal.name = "challengeGate"
        portal.fillColor = .init(red: 0.33, green: 0.73, blue: 1, alpha: 0.08)
        portal.strokeColor = .init(red: 0.56, green: 0.87, blue: 1, alpha: 0.2); portal.glowWidth = 8
        addChild(portal); gate = portal

        for index in 0..<ChallengeGateCatalog.challengeCount {
            let rune = SKShapeNode(circleOfRadius: 10)
            rune.position = CGPoint(x: 1090 + CGFloat(index) * 35, y: 505)
            rune.zPosition = 40
            rune.fillColor = .darkGray
            rune.strokeColor = UIColor(red: 1, green: 0.78, blue: 0.35, alpha: 0.9)
            rune.lineWidth = 2
            rune.name = "challengeGate"
            addChild(rune)
            challengeRunes.append(rune)
        }

        buildBridgeRoute()
        buildPhysicalProgression()
        updateChallengeGateAppearance()
        openOrder()
        buildBridgeQuestBeacon()
        if state.starlightBridgeQuest.discovered && !state.starlightBridgeQuest.isComplete {
            instruction.text = "The bridge needs starlight. Tap the blue beacon to continue the rescue."
        } else if !state.starlightBridgeQuest.discovered {
            instruction.text = "Pip heard the bridge crack! Tap the blue beacon to investigate."
        }
    }

    /// Use the detailed versioned painting; cached compositing does not add source detail.
    private func prepareCastleIllustrationForRetina() {
        if let backdrop = childNode(withName: "worldBackdrop") as? SKSpriteNode,
           let texture = ArtSystem.retinaEnhancedTexture(
                "MathCastleIllustratedV2",
                targetPoints: size,
                sharpness: 0.30
           ) {
            backdrop.texture = texture
            backdrop.userData = NSMutableDictionary(dictionary: [
                "retinaPrepared": true,
                "sourceAsset": "MathCastleIllustratedV2",
                "sourcePixels": ArtSystem.pixelSize("MathCastleIllustratedV2")?.width ?? 0
            ])
        }

        for side in ["Left", "Right"] {
            guard let foreground = childNode(
                withName: "foreground" + side
            ) as? SKSpriteNode else { continue }
            let asset = "CastleForeground" + side
            if let texture = ArtSystem.retinaEnhancedTexture(
                asset,
                targetPoints: foreground.size,
                sharpness: 0.24
            ) {
                foreground.texture = texture
            }
        }
    }

    /// A few low-contrast native accents give the painted scene crisp visual
    /// anchors at device resolution while leaving the illustration dominant.
    private func buildCastleFidelityAccents() {
        let root = SKNode()
        root.name = "castleRetinaAccents"
        root.zPosition = -70

        let floorPath = CGMutablePath()
        floorPath.move(to: CGPoint(x: 55, y: 176))
        floorPath.addCurve(
            to: CGPoint(x: 1225, y: 176),
            control1: CGPoint(x: 390, y: 154),
            control2: CGPoint(x: 875, y: 192)
        )
        let floorRim = SKShapeNode(path: floorPath)
        floorRim.name = "castleFloorRim"
        floorRim.strokeColor = UIColor(
            red: 1.0,
            green: 0.78,
            blue: 0.34,
            alpha: 0.18
        )
        floorRim.lineWidth = 2
        floorRim.glowWidth = 1
        root.addChild(floorRim)

        let gateRim = SKShapeNode(
            ellipseOf: CGSize(width: 150, height: 214)
        )
        gateRim.name = "castleGateRim"
        gateRim.position = CGPoint(x: 1125, y: 565)
        gateRim.fillColor = .clear
        gateRim.strokeColor = UIColor(
            red: 0.78,
            green: 0.90,
            blue: 1.0,
            alpha: 0.16
        )
        gateRim.lineWidth = 2
        gateRim.glowWidth = reducedMotion ? 0 : 2
        root.addChild(gateRim)

        let skyGlints = [
            CGPoint(x: 255, y: 610),
            CGPoint(x: 455, y: 570),
            CGPoint(x: 650, y: 620),
            CGPoint(x: 805, y: 565),
            CGPoint(x: 985, y: 615),
            CGPoint(x: 1180, y: 595)
        ]
        for (index, point) in skyGlints.enumerated() {
            let glint = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 2.2 : 1.6)
            glint.position = point
            glint.fillColor = UIColor(
                red: 0.90,
                green: 0.95,
                blue: 1.0,
                alpha: 0.34
            )
            glint.strokeColor = .clear
            glint.glowWidth = reducedMotion ? 0 : 2
            glint.name = "castleSkyGlint"
            glint.userData = NSMutableDictionary(dictionary: [
                "decorativeMotionRole": "pulse"
            ])
            root.addChild(glint)
        }

        // Two light native chain runs sit over chains already suggested by the
        // painting. Their tiny pendulum motion makes the castle feel mechanical
        // without turning the learning surface into a carnival.
        for (index, anchor) in [
            CGPoint(x: 382, y: 604),
            CGPoint(x: 1036, y: 575)
        ].enumerated() {
            let chain = SKNode()
            chain.name = "castleAmbientChain\(index)"
            chain.position = anchor
            chain.zPosition = 1
            chain.alpha = 0.34

            for linkIndex in 0..<7 {
                let link = SKShapeNode(ellipseOf: CGSize(width: 10, height: 17))
                link.position = CGPoint(x: 0, y: CGFloat(linkIndex) * -15)
                link.strokeColor = UIColor(
                    red: 0.72,
                    green: 0.56,
                    blue: 0.30,
                    alpha: 0.82
                )
                link.fillColor = .clear
                link.lineWidth = 2
                link.name = "decorativeCastleChainLink"
                chain.addChild(link)
            }

            root.addChild(chain)
        }

        addChild(root)
    }

    private func syncCastleKinetics() {
        lastKineticReducedMotion = reducedMotion

        let powerMount = childNode(withName: "castlePowerMount")
        powerMount?.removeAction(forKey: "ambientSpin")
        if reducedMotion { powerMount?.removeAction(forKey: "powerSurge") }
        powerMount?.zRotation = 0

        let workshopNames = [
            "workshop0", "workshop1", "workshop2", "workshop3", "workshop4", "wind"
        ]
        for (index, name) in workshopNames.enumerated() {
            guard let rim = childNode(withName: "//workshopRim_\(name)") else { continue }
            rim.removeAction(forKey: "ambientWorkshopSpin")
            if reducedMotion { rim.removeAction(forKey: "workshopTapSurge") }
            rim.zRotation = 0
            guard !reducedMotion else { continue }

            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            let duration = name == "wind"
                ? 5.6
                : 8.0 + Double(index % 3) * 1.25
            rim.run(
                .repeatForever(
                    .rotate(byAngle: direction * .pi * 2, duration: duration)
                ),
                withKey: "ambientWorkshopSpin"
            )
        }

        for (index, gear) in environmentGears.enumerated() {
            gear.removeAction(forKey: "ambientSpin")
            if reducedMotion {
                gear.removeAction(forKey: "powerSurge")
                gear.removeAction(forKey: "poweredSpin")
                gear.zRotation = 0
            } else {
                let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                let duration = 7.2 + Double(index) * 1.4
                gear.run(
                    .repeatForever(
                        .rotate(byAngle: direction * .pi * 2, duration: duration)
                    ),
                    withKey: "ambientSpin"
                )
            }
        }

        if !reducedMotion {
            powerMount?.run(
                .repeatForever(
                    .rotate(byAngle: -.pi * 2, duration: 11.0)
                ),
                withKey: "ambientSpin"
            )
        }

        for index in 0..<2 {
            guard let chain = childNode(
                withName: "//castleAmbientChain\(index)"
            ) else { continue }
            chain.removeAction(forKey: "ambientChainSway")
            chain.zRotation = 0
            guard !reducedMotion else { continue }

            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            chain.run(
                .repeatForever(
                    .sequence([
                        .rotate(
                            byAngle: direction * 0.026,
                            duration: 2.2 + Double(index) * 0.3
                        ),
                        .rotate(
                            byAngle: direction * -0.052,
                            duration: 4.4 + Double(index) * 0.4
                        ),
                        .rotate(
                            byAngle: direction * 0.026,
                            duration: 2.2 + Double(index) * 0.3
                        )
                    ])
                ),
                withKey: "ambientChainSway"
            )
        }
    }

    private func playWorkshopGearSurge(named name: String) {
        guard !reducedMotion,
              let rim = childNode(withName: "//workshopRim_\(name)") else { return }

        rim.removeAction(forKey: "workshopTapSurge")
        let direction: CGFloat = ["workshop1", "workshop3"].contains(name) ? -1 : 1
        rim.run(
            .rotate(byAngle: direction * .pi * 0.85, duration: 0.28),
            withKey: "workshopTapSurge"
        )
    }

    private func setActiveMachineKinetics(_ active: Bool) {
        guard let mechanic else {
            resetCamera(duration: 0.28)
            return
        }

        mechanic.removeAction(forKey: "activeMachineBreath")
        childNode(withName: "mathWorkZoneCore")?
            .removeAction(forKey: "activeMachineBreath")
        // Stopping a loop mid-frame must also restore its static presentation.
        mechanic.setScale(1)
        childNode(withName: "mathWorkZoneCore")?.alpha = 1

        if active {
            focusCamera(on: CGPoint(x: 820, y: 310), duration: 0.34)

            guard !reducedMotion else { return }
            mechanic.run(
                .repeatForever(
                    .sequence([
                        .scale(to: 1.018, duration: 0.72),
                        .scale(to: 1.0, duration: 0.72)
                    ])
                ),
                withKey: "activeMachineBreath"
            )

            childNode(withName: "mathWorkZoneCore")?.run(
                .repeatForever(
                    .sequence([
                        .fadeAlpha(to: 0.56, duration: 0.78),
                        .fadeAlpha(to: 1.0, duration: 0.78)
                    ])
                ),
                withKey: "activeMachineBreath"
            )
        } else {
            mechanic.setScale(1)
            childNode(withName: "mathWorkZoneCore")?.alpha = 1
            resetCamera(duration: 0.30)
        }
    }

    private func playCastlePowerSurge() {
        guard !reducedMotion else { return }

        childNode(withName: "castlePowerMount")?.removeAction(forKey: "powerSurge")
        childNode(withName: "castlePowerMount")?.run(
            .sequence([
                .rotate(byAngle: -.pi * 1.25, duration: 0.42),
                .rotate(byAngle: -.pi * 0.65, duration: 0.46)
            ]),
            withKey: "powerSurge"
        )

        for (index, gear) in environmentGears.enumerated() {
            gear.removeAction(forKey: "powerSurge")
            let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
            gear.run(
                .rotate(
                    byAngle: direction * .pi * 1.8,
                    duration: 0.62
                ),
                withKey: "powerSurge"
            )
        }

        for index in 0..<2 {
            childNode(withName: "//castleAmbientChain\(index)")?.run(
                .sequence([
                    .rotate(
                        byAngle: index.isMultiple(of: 2) ? 0.055 : -0.055,
                        duration: 0.16
                    ),
                    .rotate(
                        byAngle: index.isMultiple(of: 2) ? -0.075 : 0.075,
                        duration: 0.24
                    )
                ]),
                withKey: "powerSurge"
            )
        }
    }

    private func buildBridgeRoute() {
        bridgeRouteNode.name = "bridgeRoute"
        bridgeRouteNode.zPosition = 450
        bridgeRouteNode.isHidden = true
        // The landing joins the live plank deck to a short stair leading to the
        // next-order gear. Actors follow these same surfaces, rather than a
        // straight line through the painted machinery.
        for (x, top, width) in [(550.0, 204.0, 100.0), (582, 240, 64),
                                  (1040, 244, 140), (1060, 265, 90),
                                  (1080, 286, 84), (1095, 318, 80),
                                  (1110, 350, 80), (1110, 375, 80),
                                  (1110, 400, 100)] {
            let tread = ArtSystem.box(CGSize(width: width, height: 16),
                color: .init(red: 0.49, green: 0.33, blue: 0.17, alpha: 1), radius: 3)
            tread.position = CGPoint(x: x, y: top - 8)
            tread.strokeColor = .init(red: 0.94, green: 0.73, blue: 0.32, alpha: 1)
            tread.fillColor = .white
            tread.fillTexture = ArtSystem.texture("BridgeOakPlank")
            tread.strokeColor = .clear
            bridgeRouteNode.addChild(tread)
            let support = ArtSystem.box(CGSize(width: 12, height: max(20, top - 155)),
                color: .init(red: 0.31, green: 0.23, blue: 0.17, alpha: 1), radius: 2)
            support.position = CGPoint(x: x, y: 155 + (top - 155) / 2)
            support.fillColor = .white
            support.fillTexture = ArtSystem.texture("BridgeTimber")
            support.strokeColor = .clear
            support.zPosition = -1
            bridgeRouteNode.addChild(support)
        }
        addChild(bridgeRouteNode)
    }

    private func followBridge(_ points: [CGPoint], completion: @escaping () -> Void) {
        guard !hasLeftScene else { return }
        guard let first = points.first else { completion(); return }
        let behind = valkyrie.position
        pip.walk(to: behind) {}
        valkyrie.walk(to: first) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
            self.state.audio.play("footstep")
            self.followBridge(Array(points.dropFirst()), completion: completion)
        }
    }

    private func crossBridge() {
        guard state.runtime?.completed == true, repairedBridge || routeReady,
              bridgeQuestAllowsPassage, !crossingBridge, !hasLeftScene else { return }
        clearDrag(); engaged = false; showQuestion(nil)
        crossingBridge = true
        if !repairedBridge, let machine = mechanic {
            machine.run(.sequence([.fadeOut(withDuration: reducedMotion ? 0 : 0.2), .hide()]), withKey: "routeClear")
        }
        instruction.text = "The bridge is repaired! Valkyrie and Pip can cross to the next work order."
        followBridge(bridgePath) { [weak self] in
            guard let self else { return }
            self.crossingBridge = false
            self.instruction.text = "We reached Pip's work-order landing! Tap the arrow to bring the next order back."
        }
    }

    private func returnAcrossBridge(advance: Bool) {
        guard state.runtime?.completed == true, repairedBridge || routeReady,
              bridgeQuestAllowsPassage, !crossingBridge, !hasLeftScene else { return }
        crossingBridge = true
        instruction.text = "Pip is bringing the work order back across the bridge."
        followBridge(Array(bridgePath.reversed())) { [weak self] in
            guard let self else { return }
            self.crossingBridge = false
            if advance {
                self.state.advanceEncounter(); self.openOrder()
            } else {
                self.mechanic?.isHidden = false; self.mechanic?.alpha = 1
                self.instruction.text = "Back in the courtyard. You can explore or cross the repaired bridge again."
            }
        }
    }


    // MARK: - The Broken Starlight Bridge: non-academic adventure gameplay

    private func bridgeQuestCrystal(
        _ id: Int, name: String, at point: CGPoint, radius: CGFloat = 35
    ) -> SKNode {
        let node = SKNode()
        node.name = name
        node.position = point
        let tint = bridgeCrystalTints[id]
        let halo = SKShapeNode(circleOfRadius: radius)
        halo.name = name
        halo.fillColor = tint.withAlphaComponent(0.13)
        halo.strokeColor = tint.withAlphaComponent(0.88)
        halo.lineWidth = 3
        halo.glowWidth = reducedMotion ? 0 : 6
        node.addChild(halo)

        let diamond = CGMutablePath()
        diamond.move(to: CGPoint(x: 0, y: radius * 0.70))
        diamond.addLine(to: CGPoint(x: radius * 0.53, y: 0))
        diamond.addLine(to: CGPoint(x: 0, y: -radius * 0.70))
        diamond.addLine(to: CGPoint(x: -radius * 0.53, y: 0))
        diamond.closeSubpath()
        let crystal = SKShapeNode(path: diamond)
        crystal.name = name
        crystal.fillColor = tint
        crystal.strokeColor = .white
        crystal.lineWidth = 2
        crystal.glowWidth = reducedMotion ? 0 : 5
        node.addChild(crystal)

        // At least a 68pt interactive surface even for an inventory token.
        let hit = SKShapeNode(circleOfRadius: max(34, radius))
        hit.name = name
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.zPosition = 3
        node.addChild(hit)
        return node
    }

    private func buildBridgeQuestBeacon() {
        childNode(withName: "starlightQuestBeacon")?.removeFromParent()
        let finished = state.starlightBridgeQuest.isComplete
        let root = SKNode()
        root.name = "starlightQuestBeacon"
        root.position = CGPoint(x: 555, y: 460)
        root.zPosition = 1250

        let ring = SKShapeNode(circleOfRadius: 40)
        ring.name = root.name
        ring.fillColor = UIColor(red: 0.06, green: 0.18, blue: 0.30, alpha: 0.93)
        ring.strokeColor = UIColor(red: 0.58, green: 0.89, blue: 1, alpha: 1)
        ring.lineWidth = 4
        ring.glowWidth = reducedMotion ? 0 : 11
        root.addChild(ring)

        let star = ArtSystem.label(finished ? "✦" : "✧", size: 37)
        star.name = root.name
        star.fontColor = .white
        root.addChild(star)

        let sign = ArtSystem.plaque(
            CGSize(width: 146, height: 30),
            fill: UIColor(red: 0.05, green: 0.10, blue: 0.20, alpha: 0.96),
            stroke: UIColor(red: 0.58, green: 0.89, blue: 1, alpha: 0.92),
            radius: 10
        )
        sign.position.y = -58
        sign.name = root.name
        root.addChild(sign)
        let title = ArtSystem.label(finished ? "BRIDGE STAR" : "SAVE THE BRIDGE", size: 13)
        title.name = root.name
        title.fontColor = .white
        sign.addChild(title)

        makeAccessible(root, label: finished ? "Explore the restored bridge" : "Rescue the broken Starlight Bridge",
                       hint: "Tap to explore, collect crystals, and restore the bridge.")
        addChild(root)
    }

    private func setBridgeQuestControlsHidden(_ hidden: Bool) {
        mechanic?.isHidden = hidden
        lever?.isHidden = hidden
        nextGear?.isHidden = hidden
        gate?.isHidden = hidden
        questionPlate.isHidden = hidden
        questionHeading.isHidden = hidden
        questionLabel.isHidden = hidden
        for node in children where
            (node.name?.hasPrefix("workshop") == true)
            || node.name == "wind"
            || node.name == "workOrderFlow"
            || node.name == "questionPromptHanger" {
            node.isHidden = hidden
        }
        childNode(withName: "starlightQuestBeacon")?.isHidden = hidden
    }

    private func enterBridgeQuest() {
        guard !crossingBridge, !hasLeftScene else { return }
        _ = state.discoverStarlightBridge()
        // An unfinished repair pauses the old ready route. Completing the
        // crystal lattice will allow the existing adaptive machine to energize it.
        if !state.starlightBridgeQuest.isComplete, state.runtime?.completed == true {
            resetPhysicalProgression()
            wasPowered = false
            bridgeRouteNode.isHidden = true
        }
        bridgeQuestMode = true
        bridgeQuestBusy = false
        bridgeQuestSelectedCrystal = nil
        bridgeQuestSelectedSocket = nil
        bridgeTrialResult = nil
        clearDrag()
        engaged = false
        setActiveMachineKinetics(false)
        showQuestion(nil)
        setBridgeQuestControlsHidden(true)
        rebuildBridgeQuestStage()
        if state.starlightBridgeQuest.isComplete {
            instruction.text = "Try different loads or tap two glowing sockets to change the lights."
        } else {
            instruction.text = "A firefly is stranded! Find crystals to repair its bridge."
        }
    }

    private func leaveBridgeQuest() {
        guard bridgeQuestMode else { return }
        bridgeQuestMode = false
        if bridgeQuestBusy {
            valkyrie.cancelTravel()
            pip.cancelTravel()
        }
        bridgeQuestBusy = false
        bridgeQuestSelectedCrystal = nil
        bridgeQuestSelectedSocket = nil
        bridgeQuestDraggedCrystal = nil
        clearDrag()
        bridgeQuestStage?.removeAllActions()
        bridgeQuestStage?.removeFromParent()
        bridgeQuestStage = nil
        setBridgeQuestControlsHidden(false)
        refresh()
        buildBridgeQuestBeacon()
        if state.starlightBridgeQuest.isComplete {
            if state.runtime?.completed == true && !routeReady
                && physicalBridge?.action(forKey: "routeOpen") == nil {
                openPhysicalProgression(animated: true)
                bridgeRouteNode.isHidden = false
            }
            instruction.text = state.runtime?.completed == true
                ? "The bridge is alive! Cross it, or visit Story Tree to move your new charm."
                : "Your crystals are connected! Help Pip power the bridge, or visit Story Tree."
        } else {
            instruction.text = "Your crystal progress is safe. Tap the blue star whenever you're ready."
        }
    }

    private func rebuildBridgeQuestStage() {
        bridgeQuestStage?.removeFromParent()
        let quest = state.starlightBridgeQuest
        let stage = SKNode()
        stage.name = "starlightQuestStage"
        stage.zPosition = 1350
        addChild(stage)
        bridgeQuestStage = stage

        // These are physical objects sitting on the courtyard and the bridge,
        // not translucent quiz buttons floating in front of the painted sky.
        for (index, point) in bridgeCrystalPoints.enumerated() {
            let foot = SKShapeNode(ellipseOf: CGSize(width: 107, height: 19))
            foot.position = CGPoint(x: point.x, y: point.y - 86)
            foot.fillColor = UIColor(red: 0.04, green: 0.07, blue: 0.14, alpha: 0.43)
            foot.strokeColor = .clear
            foot.name = "decorativeCrystalPedestalFoot\(index)"
            stage.addChild(foot)

            let plinth = ArtSystem.box(
                CGSize(width: 82, height: 44),
                color: UIColor(red: 0.32, green: 0.29, blue: 0.42, alpha: 0.95),
                radius: 12
            )
            plinth.position = CGPoint(x: point.x, y: point.y - 63)
            plinth.strokeColor = bridgeCrystalTints[index].withAlphaComponent(0.72)
            plinth.lineWidth = 3
            plinth.name = "decorativeCrystalPedestal\(index)"
            stage.addChild(plinth)

            let rim = ArtSystem.box(
                CGSize(width: 100, height: 10),
                color: UIColor(red: 0.85, green: 0.72, blue: 0.46, alpha: 0.96),
                radius: 4
            )
            rim.position = CGPoint(x: point.x, y: point.y - 40)
            rim.strokeColor = .clear
            rim.name = "decorativeCrystalPedestalRim\(index)"
            stage.addChild(rim)
        }

        // Short supports keep the sockets rooted to the damaged physical span.
        for (index, point) in bridgeSocketPoints.enumerated() {
            let support = ArtSystem.box(
                CGSize(width: 16, height: 77),
                color: UIColor(red: 0.28, green: 0.22, blue: 0.18, alpha: 0.94),
                radius: 5
            )
            support.position = CGPoint(x: point.x, y: point.y - 74)
            support.strokeColor = UIColor(red: 0.84, green: 0.67, blue: 0.39, alpha: 0.83)
            support.lineWidth = 2
            support.name = "decorativeBridgeSocketSupport\(index)"
            stage.addChild(support)
        }

        // Native bridge spans, visibly separated into three broken sections.
        for (socket, location) in bridgeSocketPoints.enumerated() {
            let installed = quest.installedCrystals[socket]
            let plank = ArtSystem.box(
                CGSize(width: 118, height: 18),
                color: installed == nil
                    ? UIColor(red: 0.18, green: 0.22, blue: 0.32, alpha: 0.88)
                    : UIColor(red: 0.72, green: 0.53, blue: 0.27, alpha: 0.96),
                radius: 5
            )
            plank.position = CGPoint(x: location.x, y: 240)
            plank.strokeColor = installed == nil
                ? UIColor(red: 0.73, green: 0.44, blue: 0.37, alpha: 1)
                : UIColor(red: 0.88, green: 0.95, blue: 1, alpha: 1)
            plank.lineWidth = 3
            plank.glowWidth = installed == nil || reducedMotion ? 0 : 8
            plank.name = "decorativeBridgeQuestPlank"
            stage.addChild(plank)

            let socketNode = SKShapeNode(circleOfRadius: 42)
            socketNode.name = "bridgeQuestSocket\(socket)"
            socketNode.position = location
            socketNode.fillColor = installed == nil
                ? UIColor(red: 0.08, green: 0.13, blue: 0.24, alpha: 0.94)
                : bridgeCrystalTints[installed!].withAlphaComponent(0.22)
            socketNode.strokeColor = installed == nil
                ? UIColor(red: 0.69, green: 0.78, blue: 0.89, alpha: 0.94)
                : bridgeCrystalTints[installed!]
            socketNode.lineWidth = bridgeQuestSelectedSocket == socket ? 8 : 4
            socketNode.glowWidth = installed == nil || reducedMotion ? 0
                : bridgeQuestSelectedSocket == socket ? 18 : 8
            stage.addChild(socketNode)
            makeAccessible(socketNode, label: installed == nil
                ? "Empty bridge socket \(socket + 1)"
                : "Powered bridge socket \(socket + 1)")
            if let installed {
                let gem = bridgeQuestCrystal(installed, name: socketNode.name!,
                                             at: .zero, radius: 26)
                socketNode.addChild(gem)
            } else {
                let glyph = ArtSystem.label("◇", size: 34)
                glyph.name = socketNode.name
                glyph.fontColor = UIColor(red: 0.78, green: 0.92, blue: 1, alpha: 1)
                socketNode.addChild(glyph)
            }
        }

        for id in 0..<StarlightBridgeQuest.crystalCount where
            !quest.collectedCrystals.contains(id) {
            let node = bridgeQuestCrystal(id, name: "bridgeQuestCache\(id)",
                                          at: bridgeCrystalPoints[id])
            makeAccessible(node, label: "Hidden starlight crystal \(id + 1)",
                           hint: "Tap to let Valkyrie and Pip collect this crystal.")
            stage.addChild(node)
        }

        for id in quest.availableCrystals {
            let node = bridgeQuestCrystal(id, name: "bridgeQuestInventory\(id)",
                                          at: bridgeInventoryPoints[id], radius: 31)
            if bridgeQuestSelectedCrystal == id,
               let halo = node.children.first as? SKShapeNode {
                halo.lineWidth = 6
                halo.glowWidth = reducedMotion ? 0 : 18
            }
            makeAccessible(node, label: "Carried crystal \(id + 1)",
                           hint: "Tap to select, then tap any empty socket, or drag into a socket.")
            stage.addChild(node)
        }

        let exit = SKShapeNode(circleOfRadius: 34)
        exit.name = "bridgeQuestExit"
        exit.position = CGPoint(x: 1170, y: 625)
        exit.zPosition = 6
        exit.fillColor = UIColor(red: 0.09, green: 0.13, blue: 0.23, alpha: 0.96)
        exit.strokeColor = UIColor(red: 0.87, green: 0.73, blue: 0.42, alpha: 1)
        exit.lineWidth = 3
        let back = ArtSystem.label("‹", size: 32)
        back.name = "bridgeQuestExit"
        exit.addChild(back)
        makeAccessible(exit, label: "Return to Pip's workshop")
        stage.addChild(exit)

        // A compact engraved counter is part of the bridge machinery,
        // not another floating quiz panel covering the scenery.
        let sign = ArtSystem.plaque(
            CGSize(width: 260, height: 43),
            fill: UIColor(red: 0.09, green: 0.13, blue: 0.23, alpha: 0.92),
            stroke: UIColor(red: 0.90, green: 0.72, blue: 0.37, alpha: 0.91),
            radius: 11
        )
        sign.name = "bridgeQuestProgressSign"
        sign.position = CGPoint(x: 902, y: 408)

        let stand = ArtSystem.box(
            CGSize(width: 12, height: 65),
            color: UIColor(red: 0.46, green: 0.31, blue: 0.17, alpha: 1),
            radius: 3
        )
        stand.name = "decorativeBridgeQuestSignPost"
        stand.position = CGPoint(x: 902, y: 366)
        stand.strokeColor = .clear
        stage.addChild(stand)
        stage.addChild(sign)

        let status = ArtSystem.label(
            quest.hasDeliveredSupplies ? "CART DELIVERED" :
                quest.isComplete ? "BRIDGE RESTORED" :
                    "BRIDGE LIGHT   \(quest.installedCount) / \(StarlightBridgeQuest.crystalCount)",
            size: 16
        )
        status.name = "bridgeQuestStatus"
        status.fontName = "Georgia-Bold"
        status.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 1)
        sign.addChild(status)

        addBridgeFirefly(to: stage, rescued: quest.isComplete)
        if quest.isComplete {
            buildBridgeLoadWorkshop(on: stage, quest: quest)
        }

        if quest.isComplete {
            let star = ArtSystem.label("✦", size: 70)
            star.name = "bridgeQuestVictory"
            star.fontColor = UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 1)
            star.position = CGPoint(x: 850, y: 450)
            stage.addChild(star)
            if !reducedMotion {
                star.run(.repeatForever(.sequence([
                    .scale(to: 1.16, duration: 0.75),
                    .scale(to: 1, duration: 0.75)
                ])), withKey: "bridgeVictoryPulse")
            }
        }
        // A second, optional discovery survives the rescue. It can also be
        // found when a child revisits the repaired bridge on another day.
        if quest.collectedCrystals.count >= 2 {
            let surprise = ArtSystem.label(quest.hasFoundHiddenStar ? "✦" : "✧", size: 39)
            surprise.position = CGPoint(x: 1055, y: 460)
            surprise.name = "bridgeQuestSecret"
            surprise.fontColor = quest.hasFoundHiddenStar
                ? UIColor(red: 1.0, green: 0.83, blue: 0.38, alpha: 1)
                : UIColor(red: 0.93, green: 0.94, blue: 1, alpha: 1)
            stage.addChild(surprise)
            makeAccessible(surprise, label: quest.hasFoundHiddenStar
                ? "Discovered hidden star" : "A secret star, not needed to rescue the firefly")
        }
    }

    private func addBridgeFirefly(to stage: SKNode, rescued: Bool) {
        // A small animated light creature gives the repair a purpose beyond
        // filling three sockets. It is scenery, not a replacement for Pip.
        let root = SKNode()
        root.name = "bridgeQuestFirefly"
        root.position = rescued
            ? CGPoint(x: 350, y: 383) : CGPoint(x: 1150, y: 368)
        root.zPosition = 16

        let glow = SKShapeNode(circleOfRadius: 20)
        glow.name = root.name
        glow.fillColor = UIColor(red: 1, green: 0.90, blue: 0.43, alpha: 0.30)
        glow.strokeColor = UIColor(red: 1, green: 0.95, blue: 0.68, alpha: 1)
        glow.lineWidth = 2
        glow.glowWidth = reducedMotion ? 0 : 18
        root.addChild(glow)

        for direction in [-1.0, 1.0] {
            let wing = SKShapeNode(ellipseOf: CGSize(width: 19, height: 35))
            wing.position = CGPoint(x: direction * 18, y: 12)
            wing.zRotation = direction * 0.48
            wing.fillColor = UIColor(red: 0.83, green: 0.97, blue: 1, alpha: 0.50)
            wing.strokeColor = .white
            wing.lineWidth = 1
            wing.name = root.name
            root.addChild(wing)
        }

        let spark = ArtSystem.label("✦", size: 24)
        spark.fontColor = UIColor(red: 1.0, green: 0.99, blue: 0.76, alpha: 1)
        spark.name = root.name
        root.addChild(spark)

        makeAccessible(root, label: rescued ? "Rescued firefly" : "A firefly stranded across the bridge",
                       hint: "The bridge crystals can make a path for this little light.")
        stage.addChild(root)
        if !reducedMotion {
            root.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 11, duration: 0.8),
                .moveBy(x: 0, y: -11, duration: 0.8)
            ])), withKey: "fireflyHover")
        }
    }

    // MARK: - Pip's Bridge Load Laboratory

    private func buildBridgeLoadWorkshop(on stage: SKNode, quest: StarlightBridgeQuest) {
        // Three structural supports follow the three in-world deck planks.
        // Tap a timber brace to remove/reuse it; only two can be installed.
        for (span, position) in bridgeBracePoints.enumerated() {
            let braced = quest.braces.contains(span)
            let support = SKNode()
            support.name = "bridgeLoadBrace\(span)"
            support.position = position
            support.zPosition = 16

            let woodenFoot = ArtSystem.box(
                CGSize(width: 82, height: 15),
                color: UIColor(red: 0.39, green: 0.27, blue: 0.18, alpha: 0.95),
                radius: 4
            )
            woodenFoot.name = support.name
            woodenFoot.position.y = -19
            woodenFoot.strokeColor = braced
                ? UIColor(red: 1, green: 0.81, blue: 0.38, alpha: 1)
                : UIColor(red: 0.66, green: 0.58, blue: 0.46, alpha: 0.56)
            woodenFoot.lineWidth = 2
            support.addChild(woodenFoot)

            // Keep a generous touch surface without painting a quiz-like
            // circular button over the castle floor.
            let hit = SKShapeNode(circleOfRadius: 37)
            hit.name = support.name
            hit.fillColor = .clear
            hit.strokeColor = .clear
            hit.zPosition = 3
            support.addChild(hit)

            let beamPath = CGMutablePath()
            beamPath.move(to: CGPoint(x: -26, y: -12))
            beamPath.addLine(to: CGPoint(x: 0, y: 23))
            beamPath.addLine(to: CGPoint(x: 26, y: -12))
            let beams = SKShapeNode(path: beamPath)
            beams.name = support.name
            beams.lineWidth = braced ? 9 : 3
            beams.strokeColor = braced
                ? UIColor(red: 0.89, green: 0.66, blue: 0.33, alpha: 1)
                : UIColor(red: 0.69, green: 0.65, blue: 0.60, alpha: 0.40)
            beams.glowWidth = braced && !reducedMotion ? 5 : 0
            support.addChild(beams)

            makeAccessible(
                support,
                label: braced ? "Remove the brace from bridge span \(span + 1)"
                    : "Place a reusable brace under bridge span \(span + 1)",
                hint: "Tap to change the bridge structure, then test its strength."
            )
            stage.addChild(support)
        }

        // Choose which real-world traveler uses the bridge, without asking
        // the child to pick a "correct answer" from a panel.
        for (index, load) in BridgeTestLoad.allCases.enumerated() {
            let choice = SKNode()
            choice.name = "bridgeTestLoad\(index)"
            choice.position = bridgeLoadChoicePoints[index]
            choice.zPosition = 18

            // The load stands on the *existing* plinth. A narrow glimmer on
            // its base indicates selection; no floating option card or circle.
            let illuminatedBase = SKShapeNode(ellipseOf: CGSize(width: 94, height: 16))
            illuminatedBase.position.y = -31
            illuminatedBase.name = choice.name
            illuminatedBase.fillColor = bridgeSelectedLoad == load
                ? UIColor(red: 1, green: 0.78, blue: 0.34, alpha: 0.42)
                : UIColor(red: 0.25, green: 0.23, blue: 0.29, alpha: 0.40)
            illuminatedBase.strokeColor = bridgeSelectedLoad == load
                ? UIColor(red: 1, green: 0.92, blue: 0.55, alpha: 0.95)
                : UIColor(red: 0.63, green: 0.62, blue: 0.65, alpha: 0.40)
            illuminatedBase.lineWidth = bridgeSelectedLoad == load ? 4 : 2
            choice.addChild(illuminatedBase)

            if load == .firefly {
                for side in [CGFloat(-1), CGFloat(1)] {
                    let wing = SKShapeNode(ellipseOf: CGSize(width: 20, height: 32))
                    wing.name = choice.name
                    wing.position = CGPoint(x: side * 18, y: 13)
                    wing.zRotation = side * 0.41
                    wing.fillColor = UIColor(red: 0.86, green: 0.97, blue: 1, alpha: 0.58)
                    wing.strokeColor = .white.withAlphaComponent(0.8)
                    choice.addChild(wing)
                }
                let light = ArtSystem.label("✦", size: 35)
                light.name = choice.name
                light.fontColor = UIColor(red: 1, green: 0.94, blue: 0.56, alpha: 1)
                light.position.y = 7
                choice.addChild(light)
            } else {
                let cargo = ArtSystem.box(
                    CGSize(width: 48, height: 26),
                    color: UIColor(red: 0.66, green: 0.46, blue: 0.22, alpha: 1),
                    radius: 6
                )
                cargo.name = choice.name
                cargo.position.y = 5
                choice.addChild(cargo)
                for wheelX in [-20.0, 20.0] {
                    let wheel = SKShapeNode(circleOfRadius: 8)
                    wheel.name = choice.name
                    wheel.position = CGPoint(x: wheelX, y: -16)
                    wheel.fillColor = UIColor(red: 0.14, green: 0.17, blue: 0.23, alpha: 1)
                    wheel.strokeColor = .white.withAlphaComponent(0.6)
                    wheel.lineWidth = 2
                    choice.addChild(wheel)
                }
            }

            let label = ArtSystem.label(load == .firefly ? "FIREFLY" : "SUPPLY CART", size: 12)
            label.name = choice.name
            label.position.y = -59
            label.fontColor = UIColor(red: 1, green: 0.95, blue: 0.77, alpha: 1)
            choice.addChild(label)
            makeAccessible(choice, label: load == .firefly
                ? "Choose light firefly for bridge test" : "Choose heavy supply cart for bridge test",
                hint: "Tap a traveler, then pull the trial lever.")
            stage.addChild(choice)
        }

        // A physical lever, rather than a quiz submit button, triggers the trial.
        let lever = SKNode()
        lever.name = "bridgeTestLever"
        lever.position = bridgeTestLeverPoint
        lever.zPosition = 20
        let foot = ArtSystem.box(
            CGSize(width: 110, height: 26),
            color: UIColor(red: 0.51, green: 0.34, blue: 0.19, alpha: 1),
            radius: 7
        )
        foot.position.y = -29
        foot.name = lever.name
        lever.addChild(foot)
        let shaft = ArtSystem.box(
            CGSize(width: 12, height: 59),
            color: UIColor(red: 0.85, green: 0.71, blue: 0.40, alpha: 1),
            radius: 5
        )
        shaft.name = lever.name
        shaft.position.y = 10
        shaft.zRotation = -0.26
        lever.addChild(shaft)
        let handle = SKShapeNode(circleOfRadius: 23)
        handle.name = lever.name
        handle.position = CGPoint(x: 10, y: 40)
        handle.fillColor = UIColor(red: 0.54, green: 0.90, blue: 0.91, alpha: 1)
        handle.strokeColor = .white
        handle.lineWidth = 3
        lever.addChild(handle)
        let label = ArtSystem.label("TEST", size: 15)
        label.name = lever.name
        label.position.y = -60
        label.fontColor = .white
        lever.addChild(label)
        let tap = SKShapeNode(circleOfRadius: 37)
        tap.name = lever.name
        tap.fillColor = .clear
        tap.strokeColor = .clear
        tap.position.y = 18
        tap.zPosition = 3
        lever.addChild(tap)
        makeAccessible(lever, label: "Pull Pip's bridge load test lever",
                       hint: "See whether the selected load can cross the supported bridge.")
        stage.addChild(lever)

        let braces = ArtSystem.label("BRACES  \(quest.braces.count) / 2", size: 17)
        braces.name = "bridgeTestBraceCounter"
        braces.position = CGPoint(x: 908, y: 112)
        braces.fontColor = UIColor(red: 0.99, green: 0.90, blue: 0.65, alpha: 1)
        stage.addChild(braces)

        if quest.hasDeliveredSupplies {
            // Small brass gear mounted on the bridge's existing status plaque
            // rather than gold lettering floating on the bright sky.
            let delivered = ArtSystem.label("⚙", size: 24)
            delivered.name = "bridgeTestSuppliesDelivered"
            delivered.position = CGPoint(x: 1009, y: 408)
            delivered.fontColor = UIColor(red: 1, green: 0.85, blue: 0.38, alpha: 1)
            stage.addChild(delivered)
        }

        // Failure is a physical bending span and a stopped traveler, not a
        // punitive red answer panel. Keep the evidence visible for reflection.
        if let result = bridgeTrialResult {
            let traveler = SKNode()
            traveler.name = "bridgeTestTraveler"
            traveler.zPosition = 36
            if bridgeSelectedLoad == .firefly {
                let spark = ArtSystem.label("✦", size: 38)
                spark.fontColor = UIColor(red: 1, green: 0.97, blue: 0.49, alpha: 1)
                traveler.addChild(spark)
            } else {
                let cargo = ArtSystem.box(
                    CGSize(width: 56, height: 29),
                    color: UIColor(red: 0.64, green: 0.41, blue: 0.19, alpha: 1),
                    radius: 6
                )
                cargo.position.y = 8
                cargo.strokeColor = UIColor(red: 0.94, green: 0.81, blue: 0.44, alpha: 1)
                cargo.lineWidth = 3
                traveler.addChild(cargo)
                for x in [CGFloat(-21), CGFloat(21)] {
                    let wheel = SKShapeNode(circleOfRadius: 8)
                    wheel.position = CGPoint(x: x, y: -15)
                    wheel.fillColor = UIColor(red: 0.14, green: 0.15, blue: 0.20, alpha: 1)
                    wheel.strokeColor = .white
                    wheel.lineWidth = 2
                    traveler.addChild(wheel)
                }
            }

            let endX: CGFloat
            switch result {
            case .crossed:
                endX = 1150
            case .stoppedAt(let weak):
                endX = bridgeSocketPoints[weak].x
                // Crack the actual timber at the stressed section instead
                // of displaying a round red wrong-answer marker.
                let crack = CGMutablePath()
                crack.move(to: CGPoint(x: -33, y: -5))
                crack.addLine(to: CGPoint(x: -14, y: 8))
                crack.addLine(to: CGPoint(x: -3, y: -9))
                crack.addLine(to: CGPoint(x: 15, y: 10))
                crack.addLine(to: CGPoint(x: 32, y: -6))
                let bent = SKShapeNode(path: crack)
                bent.name = "bridgeTestWeakSpan\(weak)"
                bent.position = CGPoint(x: bridgeSocketPoints[weak].x, y: 240)
                bent.strokeColor = UIColor(red: 1, green: 0.52, blue: 0.24, alpha: 1)
                bent.lineWidth = 7
                bent.glowWidth = reducedMotion ? 0 : 10
                stage.addChild(bent)
                if !reducedMotion {
                    bent.run(.sequence([
                        .moveBy(x: -4, y: -5, duration: 0.11),
                        .moveBy(x: 7, y: 8, duration: 0.17),
                        .moveBy(x: -3, y: -3, duration: 0.13)
                    ]), withKey: "bridgeBend")
                }
            }
            let dest = CGPoint(x: endX, y: 356)
            traveler.position = reducedMotion ? dest : CGPoint(x: 685, y: 356)
            stage.addChild(traveler)
            if !reducedMotion {
                traveler.run(.move(to: dest, duration: result == .crossed ? 1.25 : 0.78),
                             withKey: "bridgeLoadTravel")
            }
        }
    }

    private func handleBridgeLoadTap(at point: CGPoint) -> Bool {
        guard state.starlightBridgeQuest.isComplete else { return false }

        if let index = bridgeQuestIndex(near: point, points: bridgeBracePoints) {
            guard state.toggleStarlightBridgeBrace(index) else {
                instruction.text = "Only two braces! Tap a fitted one to move it."
                return true
            }
            bridgeTrialResult = nil
            pip.operate(reducedMotion: reducedMotion)
            state.audio.play("gear")
            rebuildBridgeQuestStage()
            instruction.text = "Brace moved. Test the light firefly or the heavier supply cart."
            return true
        }

        if let index = bridgeQuestIndex(near: point, points: bridgeLoadChoicePoints) {
            bridgeSelectedLoad = BridgeTestLoad.allCases[index]
            bridgeTrialResult = nil
            selectionFeedback()
            rebuildBridgeQuestStage()
            instruction.text = bridgeSelectedLoad == .firefly
                ? "Light firefly ready. Pull TEST and watch the bridge!"
                : "Heavy supply cart ready. Place braces, then pull TEST."
            return true
        }

        if hypot(point.x - bridgeTestLeverPoint.x, point.y - bridgeTestLeverPoint.y) < 49 {
            guard let outcome = state.testStarlightBridge(with: bridgeSelectedLoad) else {
                return true
            }
            bridgeTrialResult = outcome
            pip.pose(.react)
            if outcome == .crossed {
                state.audio.play("success")
            } else {
                state.audio.play("gear")
            }
            rebuildBridgeQuestStage()
            switch outcome {
            case .crossed:
                if bridgeSelectedLoad == .supplyCart {
                    valkyrie.pose(.celebrate)
                    instruction.text = "Supplies delivered! Try moving the braces and test again."
                } else {
                    instruction.text = "Firefly crossed! Will a heavy cart make it too?"
                }
            case .stoppedAt(let weak):
                instruction.text = "Bridge bent at span \(weak + 1)! Move a brace below it and retry."
            }
            return true
        }
        return false
    }

    private func bridgeQuestIndex(near point: CGPoint, points: [CGPoint]) -> Int? {
        points.indices.first {
            hypot(point.x - points[$0].x, point.y - points[$0].y) <= 51
        }
    }

    private func handleBridgeQuestTap(at point: CGPoint) {
        if hypot(point.x - 1170, point.y - 625) <= 43 {
            leaveBridgeQuest()
            return
        }
        guard !bridgeQuestBusy else { return }
        let quest = state.starlightBridgeQuest
        if handleBridgeLoadTap(at: point) { return }
        if !quest.isComplete,
           hypot(point.x - 1150, point.y - 368) < 43 {
            pip.pose(.react)
            instruction.text = "That little firefly is stranded! Three crystals will build a way home."
            return
        }
        if let source = bridgeQuestIndex(near: point, points: bridgeCrystalPoints),
           !quest.collectedCrystals.contains(source) {
            bridgeQuestBusy = true
            instruction.text = "Valkyrie and Pip are hunting for the lost crystal..."
            let target = CGPoint(x: bridgeCrystalPoints[source].x - 48, y: 175)
            travel(to: target) { [weak self] in
                guard let self, self.bridgeQuestMode, !self.hasLeftScene else { return }
                self.bridgeQuestBusy = false
                guard self.state.collectStarlightCrystal(source) else { return }
                self.bridgeQuestSelectedCrystal = source
                self.state.audio.play("crystal")
                self.selectionFeedback()
                self.valkyrie.pose(.interact)
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.rebuildBridgeQuestStage()
                let count = self.state.starlightBridgeQuest.collectedCrystals.count
                self.instruction.text = count == 1
                    ? "Found one! Look around for more light, or place this crystal into a socket."
                    : count == 2
                        ? "A tiny hidden star woke up! You can choose where the crystals go."
                        : "All three are safe. Tap a crystal below, then choose its bridge socket."
                self.playStarlightBurst(at: self.bridgeCrystalPoints[source])
            }
            return
        }
        if let inventory = bridgeQuestIndex(near: point, points: bridgeInventoryPoints),
           quest.availableCrystals.contains(inventory) {
            bridgeQuestSelectedCrystal = inventory
            selectionFeedback()
            rebuildBridgeQuestStage()
            instruction.text = "Choose any empty socket to power a part of the bridge."
            return
        }
        if let socket = bridgeQuestIndex(near: point, points: bridgeSocketPoints) {
            if quest.isComplete {
                if let first = bridgeQuestSelectedSocket {
                    bridgeQuestSelectedSocket = nil
                    if state.swapStarlightBridgeCrystals(first, socket) {
                        // A prior load trial no longer describes the new lighting
                        // arrangement. The braces and earned reward remain intact.
                        bridgeTrialResult = nil
                        state.audio.play("crystal")
                        playStarlightBurst(at: bridgeSocketPoints[socket])
                        pip.pose(.celebrate)
                        instruction.text = "You changed the bridge lights! Try another combination."
                    } else {
                        instruction.text = "Choose two different crystals to swap their colors."
                    }
                } else {
                    bridgeQuestSelectedSocket = socket
                    instruction.text = "Choose another glowing socket to swap the bridge lights."
                }
                rebuildBridgeQuestStage()
                return
            }
            guard quest.installedCrystals[socket] == nil else {
                instruction.text = "That bridge section already glows. Choose an empty one."
                return
            }
            guard let crystal = bridgeQuestSelectedCrystal ?? quest.availableCrystals.first else {
                instruction.text = "Find a glowing crystal first. Search the three stone caches."
                return
            }
            installBridgeQuestCrystal(crystal, socket: socket)
            return
        }
        if quest.collectedCrystals.count >= 2,
           hypot(point.x - 1055, point.y - 460) < 48 {
            if state.discoverHiddenStarlightStar() {
                pip.pose(.celebrate)
                valkyrie.pose(.react)
                state.audio.play("success")
                playStarlightBurst(at: CGPoint(x: 1055, y: 460))
                rebuildBridgeQuestStage()
                instruction.text = "You found a secret! It will shine beside your Story Tree charm."
            } else {
                instruction.text = "You already found Pip's hidden star. Look what you built!"
            }
            return
        }
        instruction.text = "Explore the glowing crystals, or tap the return arrow at the top right."
    }

    private func installBridgeQuestCrystal(_ crystal: Int, socket: Int) {
        guard bridgeQuestMode, !bridgeQuestBusy else { return }
        bridgeQuestBusy = true
        let target = CGPoint(x: bridgeSocketPoints[socket].x - 60, y: 175)
        instruction.text = "Watch this crystal wake a piece of the bridge!"
        travel(to: target) { [weak self] in
            guard let self, self.bridgeQuestMode, !self.hasLeftScene else { return }
            self.bridgeQuestBusy = false
            guard self.state.installStarlightCrystal(crystal, into: socket) else { return }
            self.bridgeQuestSelectedCrystal = self.state.starlightBridgeQuest.availableCrystals.first
            self.selectionFeedback()
            self.state.audio.play("gear")
            self.playStarlightBurst(at: self.bridgeSocketPoints[socket])
            self.pip.pose(.celebrate)
            self.rebuildBridgeQuestStage()
            let quest = self.state.starlightBridgeQuest
            if quest.isComplete {
                self.successFeedback(at: CGPoint(x: 850, y: 395))
                self.instruction.text = "Firefly rescued! Your bridge charm waits at Story Tree."
            } else {
                self.instruction.text = "A new part of the bridge shines! \(StarlightBridgeQuest.crystalCount - quest.installedCount) to go."
            }
        }
    }

    private func makeLever() -> SKNode {
        let node = SKNode(); node.name = "submit"; node.position = CGPoint(x: 1120, y: 250); node.zPosition = 760
        let base = ArtSystem.box(CGSize(width: 90, height: 32), color: .init(red: 0.47, green: 0.3, blue: 0.14, alpha: 1), radius: 6)
        if let texture = ArtSystem.texture("BridgeWorkOrder") { base.fillColor = .white; base.fillTexture = texture }
        base.position.y = -45; node.addChild(base)
        let arm = ArtSystem.box(CGSize(width: 14, height: 80), color: .init(red: 0.93, green: 0.74, blue: 0.35, alpha: 1), radius: 6)
        if let texture = ArtSystem.texture("BridgeTimber") { arm.fillColor = .white; arm.fillTexture = texture }
        arm.zRotation = -.pi / 8; arm.position.y = -5; node.addChild(arm)
        let handle = SKShapeNode(circleOfRadius: 27)
        handle.position = CGPoint(x: 15, y: 32); handle.fillColor = .init(red: 0.38, green: 0.71, blue: 0.72, alpha: 1)
        handle.strokeColor = .init(red: 1, green: 0.82, blue: 0.44, alpha: 1); handle.lineWidth = 3; node.addChild(handle)
        if let face = ArtSystem.sprite("BridgeDial", size: CGSize(width: 54, height: 54)) {
            handle.fillColor = .clear; handle.strokeColor = .clear
            handle.addChild(face)
        }

        let checkPlate = ArtSystem.plaque(
            CGSize(width: 88, height: 28),
            fill: UIColor(red: 0.13, green: 0.11, blue: 0.17, alpha: 0.92),
            stroke: UIColor(red: 0.92, green: 0.71, blue: 0.32, alpha: 0.80),
            radius: 12
        )
        checkPlate.position = CGPoint(x: 0, y: -70)
        checkPlate.name = "submit"
        node.addChild(checkPlate)

        let checkLabel = ArtSystem.label("CHECK", size: 13)
        checkLabel.fontName = "AvenirNext-Bold"
        checkLabel.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.70, alpha: 1)
        checkLabel.name = "submit"
        checkPlate.addChild(checkLabel)

        // Touch area stays large even where the lever's silhouette is narrow.
        let hit = ArtSystem.box(CGSize(width: 150, height: 110), color: .clear, radius: 0); hit.name = "submit"; node.addChild(hit)
        makeAccessible(node, label: "Pull Pip's golden lever", hint: "Checks the current work order.")
        addChild(node)
        registerInteraction(node, clearance: 16)
        return node
    }

    /// Recreates the v3.31 Math Castle cause-and-effect loop in native SpriteKit:
    /// solve the embedded machine -> energy travels through the room -> bridge opens
    /// -> the destination becomes physically reachable.
    private func buildPhysicalProgression() {
        let conduitPath = CGMutablePath()
        conduitPath.move(to: routeEnergyPoints[0])
        routeEnergyPoints.dropFirst().forEach { conduitPath.addLine(to: $0) }
        let conduit = SKShapeNode(path: conduitPath)
        conduit.name = "castlePowerConduit"
        conduit.zPosition = 17
        conduit.strokeColor = UIColor(red: 0.45, green: 0.52, blue: 0.62, alpha: 0.38)
        conduit.lineWidth = 6
        conduit.glowWidth = 0
        addChild(conduit)
        powerConduit = conduit

        // Ordinary solved machines open a deck at the same height as the
        // current illustrated bridge and share its tested landing/stair path.
        let bridgeRoot = SKNode()
        bridgeRoot.name = "physicalRouteBridge"
        bridgeRoot.position = CGPoint(x: 1040, y: 236)
        bridgeRoot.zPosition = 450
        for index in 0..<10 {
            let plank = ArtSystem.box(CGSize(width: 44, height: 16), color: .brown, radius: 3)
            if let texture = ArtSystem.texture("BridgeOakPlank") {
                plank.fillColor = .white; plank.fillTexture = texture; plank.strokeColor = .clear
            }
            plank.position.x = -22 - CGFloat(index) * 44
            bridgeRoot.addChild(plank)
        }
        bridgeRoot.xScale = 0.06; bridgeRoot.alpha = 0.18
        addChild(bridgeRoot); physicalBridge = bridgeRoot

        let beacon = SKShapeNode(circleOfRadius: 54)
        beacon.name = "routeDestinationBeacon"
        beacon.position = CGPoint(x: 1200, y: 430)
        beacon.zPosition = 730
        beacon.fillColor = UIColor(red: 1, green: 0.83, blue: 0.32, alpha: 0.06)
        beacon.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.38, alpha: 0.35)
        beacon.lineWidth = 3
        beacon.glowWidth = 0
        addChild(beacon)
        destinationBeacon = beacon

        let orb = SKShapeNode(circleOfRadius: 11)
        orb.name = "routeStarlightOrb"
        orb.position = routeEnergyPoints[0]
        orb.zPosition = 830
        orb.fillColor = UIColor(red: 0.80, green: 0.96, blue: 1, alpha: 1)
        orb.strokeColor = .white
        orb.lineWidth = 2
        orb.glowWidth = 10
        orb.isHidden = true
        addChild(orb)
        starlightOrb = orb

        for (index, point) in [CGPoint(x: 995, y: 315), CGPoint(x: 1045, y: 338)].enumerated() {
            let gear = ArtSystem.gear(radius: index == 0 ? 18 : 14)
            gear.name = "environmentGear\(index)"
            gear.position = point
            gear.zPosition = 18
            gear.alpha = 0.72
            addChild(gear)
            environmentGears.append(gear)
        }

        resetPhysicalProgression()
    }

    private func resetPhysicalProgression() {
        routeReady = false
        physicalBridge?.removeAllActions()
        physicalBridge?.xScale = 0.06
        physicalBridge?.alpha = 0.18
        physicalBridge?.isHidden = state.runtime?.encounter.mechanicID == MathMechanicID.missingNumberBridge

        powerConduit?.removeAllActions()
        powerConduit?.strokeColor = UIColor(red: 0.45, green: 0.52, blue: 0.62, alpha: 0.38)
        powerConduit?.glowWidth = 0

        destinationBeacon?.removeAllActions()
        destinationBeacon?.alpha = 0.35
        destinationBeacon?.glowWidth = 0
        nextGear?.removeAction(forKey: "routeReadyPulse")
        nextGear?.setScale(1)

        starlightOrb?.removeAllActions()
        starlightOrb?.isHidden = true
        starlightOrb?.position = routeEnergyPoints[0]

        environmentGears.forEach {
            $0.removeAction(forKey: "poweredSpin")
            $0.speed = 1
        }

        for lamp in routeLights {
            lamp.removeAllActions()
            lamp.fillColor = UIColor(red: 0.34, green: 0.31, blue: 0.37, alpha: 1)
            lamp.glowWidth = 0
            lamp.setScale(1)
        }
    }

    private func openPhysicalProgression(animated: Bool = true) {
        guard bridgeQuestAllowsPassage, let bridge = physicalBridge else { return }

        bridge.isHidden = repairedBridge
        if !animated || reducedMotion || repairedBridge {
            bridge.xScale = 1
            bridge.alpha = 1
            routeReady = true
            powerConduit?.strokeColor = UIColor(red: 0.73, green: 0.93, blue: 1, alpha: 0.95)
            powerConduit?.glowWidth = 6
            destinationBeacon?.alpha = 1
            destinationBeacon?.glowWidth = 18
            for lamp in routeLights {
                lamp.fillColor = UIColor(red: 1, green: 0.86, blue: 0.4, alpha: 1)
                lamp.glowWidth = 6
            }
            return
        }

        powerConduit?.strokeColor = UIColor(red: 0.73, green: 0.93, blue: 1, alpha: 0.95)
        powerConduit?.glowWidth = 5

        for (index, lamp) in routeLights.enumerated() {
            let delay = Double(index) * 0.11
            lamp.run(.sequence([
                .wait(forDuration: delay),
                .run {
                    lamp.fillColor = UIColor(red: 1, green: 0.86, blue: 0.4, alpha: 1)
                    lamp.glowWidth = 7
                },
                .scale(to: 1.28, duration: 0.09),
                .scale(to: 1, duration: 0.14)
            ]), withKey: "powerArrival")
        }

        if let orb = starlightOrb {
            orb.isHidden = false
            orb.alpha = 1
            orb.position = routeEnergyPoints[0]
            let travel = routeEnergyPoints.dropFirst().map {
                SKAction.move(to: $0, duration: 0.16)
            }
            orb.run(.sequence(travel + [
                .group([
                    .fadeOut(withDuration: 0.22),
                    .scale(to: 1.7, duration: 0.22)
                ]),
                .run { orb.isHidden = true; orb.setScale(1); orb.alpha = 1 }
            ]), withKey: "routeTravel")
        }

        for (index, gear) in environmentGears.enumerated() {
            let angle = CGFloat.pi * (index.isMultiple(of: 2) ? 2.4 : -2.4)
            gear.run(.rotate(byAngle: angle, duration: 0.95), withKey: "poweredSpin")
        }

        let unfold = SKAction.scaleX(to: 1, duration: 1.05)
        unfold.timingMode = .easeOut
        // Readiness follows the actual bridge action, not an independent timer.
        // Pausing or cancelling the unfolding must never open traversal early.
        bridge.run(.sequence([
            .group([
                unfold,
                .fadeAlpha(to: 1, duration: 0.38)
            ]),
            .run { [weak self] in
                guard let self else { return }
                self.routeReady = true
                self.destinationBeacon?.alpha = 1
                self.destinationBeacon?.glowWidth = 18
                self.playStarlightBurst(at: self.routeDestination)
            }
        ]), withKey: "routeOpen")

        destinationBeacon?.run(.sequence([
            .wait(forDuration: 1.05),
            .scale(to: 1.12, duration: 0.18),
            .scale(to: 1, duration: 0.22)
        ]), withKey: "routeReady")

        nextGear?.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.65),
            .scale(to: 1, duration: 0.65)
        ])), withKey: "routeReadyPulse")
    }

    private func playStarlightBurst(at point: CGPoint) {
        guard !reducedMotion else { return }

        for index in 0..<9 {
            let spark = ArtSystem.label(index.isMultiple(of: 3) ? "✦" : "·", size: index.isMultiple(of: 3) ? 19 : 25)
            spark.position = point
            spark.zPosition = 900
            spark.fontColor = UIColor(
                red: index.isMultiple(of: 2) ? 1.0 : 0.72,
                green: 0.88,
                blue: 1.0,
                alpha: 1.0
            )
            addChild(spark)

            let angle = (CGFloat(index) / 9.0) * (.pi * 2)
            let distance: CGFloat = index.isMultiple(of: 2) ? 54 : 38
            spark.run(.sequence([
                .group([
                    .moveBy(
                        x: cos(angle) * distance,
                        y: sin(angle) * distance + 18,
                        duration: 0.55
                    ),
                    .fadeOut(withDuration: 0.55),
                    .scale(to: 0.55, duration: 0.55)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func playMechanicSuccessReaction() {
        (mechanic as? MathCastleReactiveMechanic)?.playSuccessReaction(reducedMotion: reducedMotion)
    }

    private func wakeMechanic() {
        guard !reducedMotion, let mechanic else { return }
        mechanic.removeAction(forKey: "wake")
        mechanic.run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1, duration: 0.18)
        ]), withKey: "wake")
    }

    private func playGentleRetryReaction() {
        if !reducedMotion, let mechanic {
            mechanic.removeAction(forKey: "retry")
            mechanic.run(.sequence([
                .moveBy(x: -6, y: 0, duration: 0.07),
                .moveBy(x: 12, y: 0, duration: 0.10),
                .moveBy(x: -6, y: 0, duration: 0.07)
            ]), withKey: "retry")
        }
        // A steady amber cue remains useful with Reduced Motion enabled.
        powerLight?.fillColor = UIColor(red: 0.88, green: 0.63, blue: 0.25, alpha: 1)
        powerLight?.glowWidth = 5
        powerLight?.run(.sequence([
            .wait(forDuration: 0.45),
            .run { [weak self] in
                guard let self, !self.wasPowered else { return }
                self.powerLight?.fillColor = UIColor(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
                self.powerLight?.glowWidth = 0
            }
        ]), withKey: "gentleRetry")
    }

    private func playManipulationReaction() {
        guard !reducedMotion else { return }

        for (index, gear) in environmentGears.enumerated() {
            let angle: CGFloat = index.isMultiple(of: 2) ? 0.16 : -0.13
            gear.run(.rotate(byAngle: angle, duration: 0.16), withKey: "inputTick")
        }

        powerLight?.run(.sequence([
            .fadeAlpha(to: 0.55, duration: 0.06),
            .fadeAlpha(to: 1, duration: 0.14)
        ]), withKey: "inputPulse")
    }

    private func updateChallengeGateAppearance() {
        let litCount: Int
        switch state.challengeGateStatus {
        case .locked:
            gate?.alpha = 0.45
            (gate as? SKShapeNode)?.strokeColor = .init(red: 0.56, green: 0.87, blue: 1, alpha: 0.18)
            (gate as? SKShapeNode)?.glowWidth = 4
            litCount = 0
        case .ready:
            gate?.alpha = 0.95
            (gate as? SKShapeNode)?.strokeColor = .init(red: 1, green: 0.82, blue: 0.40, alpha: 0.90)
            (gate as? SKShapeNode)?.glowWidth = 14
            litCount = 0
        case .active:
            gate?.alpha = 1.0
            (gate as? SKShapeNode)?.strokeColor = .init(red: 0.65, green: 0.91, blue: 1, alpha: 0.95)
            (gate as? SKShapeNode)?.glowWidth = 18
            litCount = state.challengeGateCompletedCount
        case .completed:
            gate?.alpha = 1.0
            (gate as? SKShapeNode)?.strokeColor = .init(red: 1, green: 0.86, blue: 0.38, alpha: 1)
            (gate as? SKShapeNode)?.glowWidth = 16
            litCount = ChallengeGateCatalog.challengeCount
        }

        for (index, rune) in challengeRunes.enumerated() {
            let lit = index < litCount
            rune.fillColor = lit ? .systemYellow : .darkGray
            rune.glowWidth = lit ? 7 : 0
            rune.setScale(lit ? 1.12 : 1.0)
        }
    }

    private func updatePower(_ powered: Bool) {
        // Old input/retry effects must never dim a newly powered machine.
        powerLight?.removeAction(forKey: "gentleRetry")
        powerLight?.removeAction(forKey: "inputPulse")
        powerLight?.alpha = 1
        nextGear?.isHidden = !(powered || state.workshop || state.runtime == nil)
            || (powered && !bridgeQuestAllowsPassage)

        if powered {
            powerLight?.fillColor = UIColor(red: 1, green: 0.86, blue: 0.38, alpha: 1)
            powerLight?.glowWidth = 16

            if !wasPowered {
                if initialBuildComplete {
                    playMechanicSuccessReaction()
                }
                if bridgeQuestAllowsPassage {
                    openPhysicalProgression(animated: initialBuildComplete)
                }
                if initialBuildComplete && !reducedMotion {
                    lever?.run(.sequence([
                        .rotate(toAngle: -0.18, duration: 0.16),
                        .rotate(toAngle: 0, duration: 0.22)
                    ]), withKey: "pull")
                }
            }
        } else {
            powerLight?.fillColor = UIColor(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
            powerLight?.glowWidth = 0
            if wasPowered || physicalBridge?.xScale != 0.06 {
                resetPhysicalProgression()
            }
        }

        wasPowered = powered
        bridgeRouteNode.isHidden = !powered || !bridgeQuestAllowsPassage
        // Keep walking actors in front of the completed deck and its equation.
        if repairedBridge { mechanic?.zPosition = 600 }
        updateChallengeGateAppearance()
    }

    private func showQuestion(_ text: String?) {
        let hangers = children.filter { $0.name == "questionPromptHanger" }
        guard let text, !text.isEmpty else {
            questionPlate.isHidden = true
            questionHeading.isHidden = true
            questionLabel.isHidden = true
            hangers.forEach { $0.isHidden = true }
            questionLabel.text = nil
            return
        }
        questionLabel.text = text
        let longPrompt = text.count > 52
        questionLabel.fontSize = longPrompt ? 17 : 18
        questionLabel.position.y = longPrompt ? 607 : 610
        questionPlate.isHidden = false
        questionHeading.isHidden = false
        questionLabel.isHidden = false
        hangers.forEach { $0.isHidden = false }
    }

    private func openOrder() {
        clearDrag(); engaged = false
        showQuestion(nil)
        selection = state.prepareNext()
        refresh()
        if state.runtime?.completed == true {
            instruction.text = completionMessage
        } else {
            switch selection {
            case .explorationBreak: instruction.text = "Let's explore! Wind Pip's gear or return to Story Tree."
            case .needsContent: instruction.text = "Pip has no new ready work orders. Explore, or try his workshop."
            default: instruction.text = "Walk to Pip's machine to begin the work order."
            }
        }
    }

    private var completionMessage: String {
        if !bridgeQuestAllowsPassage {
            return "Pip's machine has power! The bridge still needs its lost starlight crystals."
        }
        if repairedBridge { return "The gaps are filled! Tap the bridge or arrow to cross with Pip." }
        return state.workshop ? "You made it work! Try another station, or choose a new order."
            : "The castle route has power! Explore, or choose another work order."
    }

    private func refresh() {
        guard let runtime = state.runtime else {
            mechanic?.removeFromParent(); mechanic = nil; renderedEncounterID = nil
            children.filter {
                ($0.name?.hasPrefix("workshop") == true) || $0.name == "workshopRack" || $0.name == "wind"
            }.forEach {
                $0.isHidden = false
                $0.alpha = 0.72
            }
            childNode(withName: "next")?.isHidden = false
            lever?.isHidden = true
            updatePower(false)
            return
        }
        if renderedEncounterID != runtime.encounter.id || mechanic == nil {
            mechanic?.removeAllActions(); mechanic?.removeFromParent()
            if runtime.encounter.mechanicID == MathMechanicID.crystalCart {
                mechanic = CrystalCartMechanic()
            } else {
                mechanic = MathCastleMechanicFactory.makeNode(for: runtime.encounter)
                mechanic?.position = CGPoint(x: 820, y: 310)
            }
            if let mechanic { mechanic.zPosition = 815; addChild(mechanic) }
            renderedEncounterID = runtime.encounter.id
        }
        switch runtime {
        case .crystalCart(let model): (mechanic as? CrystalCartMechanic)?.render(model)
        case .balanceScale(let model): (mechanic as? BalanceScaleMechanic)?.render(model)
        case .numberBond(let model): (mechanic as? NumberBondMachineMechanic)?.render(model)
        case .tenFrame(let model): (mechanic as? TenFrameGateMechanic)?.render(model, allowPreview: engaged && state.previewVisible)
        case .missingBridge(let model): (mechanic as? MissingNumberBridgeMechanic)?.render(model)
        case .placeValueFactory(let model): (mechanic as? PlaceValueFactoryMechanic)?.render(model)
        case .patternLoom(let model): (mechanic as? PatternLoomMechanic)?.render(model)
        case .shapeForge(let model): (mechanic as? ShapeForgeMechanic)?.render(model)
        case .measurementWorkshop(let model): (mechanic as? MeasurementWorkshopMechanic)?.render(model)
        case .dataBoard(let model): (mechanic as? DataBoardMechanic)?.render(model)
        case .clockMarket(let model): (mechanic as? ClockMarketMechanic)?.render(model)
        case .groupingGarden(let model): (mechanic as? GroupingGardenMechanic)?.render(model)
        case .reasoningStudio(let model): (mechanic as? ReasoningStudioMechanic)?.render(model)
        case .numberTrail(let model): (mechanic as? NumberTrailMechanic)?.render(model)
        case .differenceBridge(let model): (mechanic as? DifferenceBridgeMechanic)?.render(model)
        case .routeExplorer(let model): (mechanic as? RouteExplorerMechanic)?.render(model)
        }
        lastPreviewVisible = state.previewVisible
        updatePower(runtime.completed)

        let secondaryHidden = !runtime.completed && (engaged || !state.workshop)
        children.filter {
            ($0.name?.hasPrefix("workshop") == true) || $0.name == "workshopRack" || $0.name == "wind"
        }.forEach {
            $0.alpha = secondaryHidden ? 0.18 : 0.72
            $0.isHidden = secondaryHidden
        }
        childNode(withName: "next")?.isHidden = (engaged && !runtime.completed)
            || (!runtime.completed && !state.workshop)
        lever?.isHidden = !engaged || runtime.completed
        if engaged {
            let isBridge = runtime.encounter.mechanicID == MathMechanicID.missingNumberBridge
            showQuestion(isBridge ? nil : (
                state.previewVisible
                    ? "Watch the lights. Remember how many you see."
                    : runtime.encounter.prompt
            ))
            instruction.text = state.previewVisible
                ? "Look closely. Pip will hide the lights in a moment."
                : (runtime.encounter.mechanicID == MathMechanicID.missingNumberBridge
                    ? "Pip needs \(runtime.encounter.targetQuantity) bridge planks. \(runtime.encounter.initialQuantity) are fixed. Fill the gaps, then pull his lever."
                    : "Build your answer, then pull Pip's golden lever.")
        } else {
            showQuestion(nil)
        }
    }

    private func canManipulate() -> Bool {
        engaged && isNear(station) && state.runtime?.completed == false && !state.previewVisible
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; startPoint = touch.location(in: self); didDrag = false
        if bridgeQuestMode {
            let quest = state.starlightBridgeQuest
            if let index = bridgeQuestIndex(near: startPoint, points: bridgeInventoryPoints),
               quest.availableCrystals.contains(index) {
                bridgeQuestDraggedCrystal = index
            }
            return
        }
        if canManipulate(), let name = targetName(at: startPoint),
           ["supply", "cartCrystal", "bondSupply", "bondToken", "tenFrameSupply", "tenFrameFilled", "missingSupply", "missingPlank"].contains(name) {
            dragOrigin = name
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        guard hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 else { return }
        didDrag = true
        if bridgeQuestMode {
            guard bridgeQuestDraggedCrystal != nil else { return }
            if ghost == nil {
                let sparkle = SKShapeNode(circleOfRadius: 28)
                sparkle.fillColor = UIColor(red: 0.77, green: 0.95, blue: 1, alpha: 0.82)
                sparkle.strokeColor = .white
                sparkle.lineWidth = 3
                sparkle.glowWidth = reducedMotion ? 0 : 10
                sparkle.name = "decorativeBridgeQuestGhost"
                sparkle.zPosition = 1900
                addChild(sparkle)
                ghost = sparkle
            }
            ghost?.position = point
            return
        }
        guard dragOrigin != nil else { return }
        if ghost == nil {
            ghost = dragOrigin == "missingSupply" || dragOrigin == "missingPlank"
                ? MissingNumberBridgeMechanic.plank() : CrystalCartMechanic.crystal()
            ghost?.zPosition = 1900
            if let ghost { addChild(ghost) }
        }
        ghost?.position = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 { didDrag = true }
        defer { clearDrag(); bridgeQuestDraggedCrystal = nil }
        if bridgeQuestMode {
            if didDrag {
                if let crystal = bridgeQuestDraggedCrystal,
                   let socket = bridgeQuestIndex(near: point, points: bridgeSocketPoints) {
                    installBridgeQuestCrystal(crystal, socket: socket)
                } else {
                    instruction.text = "Move a carried crystal into any empty bridge socket."
                }
                return
            }
            handleTap(at: point)
            return
        }
        if didDrag {
            if canManipulate(), let origin = dragOrigin { drop(origin: origin, at: point) }
            return
        }
        handleTap(at: point)
    }

    // Explicitly test knob centers in mechanic-local coordinates before generic
    // SpriteKit hit ancestry: illustrated trays can overlap visible controls.
    private func handleMechanicDirectControl(at point: CGPoint) -> Bool {
        guard let active = state.runtime, let mechanic else { return false }
        let local = mechanic.convert(point, from: self)
        if !canManipulate() {
            if CGRect(x: -265, y: -160, width: 530, height: 310).contains(local),
               [MathMechanicID.placeValueFactory, MathMechanicID.patternLoom, MathMechanicID.shapeForge, MathMechanicID.measurementWorkshop, MathMechanicID.dataBoard, MathMechanicID.clockMarket, MathMechanicID.groupingGarden, MathMechanicID.reasoningStudio, MathMechanicID.numberTrail, MathMechanicID.differenceBridge, MathMechanicID.routeExplorer]
                   .contains(active.encounter.mechanicID) {
                engageMachine()
                return true
            }
            return false
        }
        switch active {
        case .placeValueFactory(let model) where !model.isComparison:
            let controls: [(CGPoint, Int, Int)] = [
                (CGPoint(x: -178, y: -118), 1, 0),
                (CGPoint(x: -78, y: -118), -1, 0),
                (CGPoint(x: 78, y: -118), 0, 1),
                (CGPoint(x: 178, y: -118), 0, -1)
            ]
            for (center, tens, ones) in controls {
                if hypot(local.x - center.x, local.y - center.y) <= 36 {
                    manipulate { self.state.adjustPlaceValue(tensDelta: tens, onesDelta: ones) }
                    return true
                }
            }
        case .shapeForge(let model):
            switch model.task {
            case .rotate:
                for (x, delta) in [(CGFloat(-104), -1), (CGFloat(104), 1)] {
                    if hypot(local.x - x, local.y + 118) <= 40 {
                        manipulate { self.state.rotateShape(delta) }
                        return true
                    }
                }
            case .recognize, .attributes:
                let centerY: CGFloat = model.task == .attributes ? -104 : -20
                let spacing: CGFloat = model.task == .attributes ? 153 : 158
                for option in 1...3 {
                    let x = CGFloat(option - 2) * spacing
                    if hypot(local.x - x, local.y - centerY) <= 55 {
                        manipulate { self.state.chooseShapeOption(option) }
                        return true
                    }
                }
            case .compose:
                if hypot(local.x - 213, local.y - 24) <= 45 {
                    manipulate { self.state.undoShapeHalf() }
                    return true
                }
                for turns in 0...3 {
                    if hypot(local.x - (CGFloat(turns) * 110 - 165), local.y + 122) <= 37 {
                        manipulate { self.state.placeShapeHalf(turns) }
                        return true
                    }
                }
            case .symmetry:
                for row in 0..<3 {
                    let y = CGFloat(33 - row * 54)
                    if abs(local.x - 103) <= 46 && abs(local.y - y) <= 27 {
                        manipulate { self.state.cycleMirrorCell(row) }
                        return true
                    }
                }
            }
        case .differenceBridge(let model):
            let positions: [CGFloat] = [-184, -60, 60, 184]
            for (index, x) in positions.enumerated() where
                hypot(local.x - x, local.y + 120) <= 39 {
                if model.isDifference {
                    switch index {
                    case 0: manipulate { self.state.matchDifferencePair() }
                    case 1: manipulate { self.state.undoDifferencePair() }
                    case 2: manipulate { self.state.collectDifference() }
                    default: manipulate { self.state.undoDifferenceCollection() }
                    }
                } else {
                    switch index {
                    case 0: manipulate { self.state.addInverseCounter() }
                    case 1: manipulate { self.state.undoInverseCounter() }
                    case 2: manipulate { self.state.reverseInverseCounter() }
                    default: manipulate { self.state.undoInverseReverse() }
                    }
                }
                return true
            }
        case .routeExplorer:
            for (index, x) in [CGFloat(-196), -98, 0, 98, 196].enumerated()
                where hypot(local.x - x, local.y + 120) <= 37 {
                switch index {
                case 0: manipulate { self.state.moveOnMap(.north) }
                case 1: manipulate { self.state.moveOnMap(.south) }
                case 2: manipulate { self.state.moveOnMap(.west) }
                case 3: manipulate { self.state.moveOnMap(.east) }
                default: manipulate { self.state.undoMapMove() }
                }
                return true
            }
        case .numberTrail(let model):
            if model.isEstimate {
                for (x, operation) in [
                    (CGFloat(-157), 0),
                    (CGFloat(17), -1),
                    (CGFloat(108), 1),
                    (CGFloat(207), 2)
                ] {
                    if hypot(local.x - x, local.y + 122) <= 41 {
                        switch operation {
                        case 0: manipulate { self.state.revealTrailCollection() }
                        case -1, 1: manipulate { self.state.adjustTrailEstimate(operation) }
                        default: manipulate { self.state.lockTrailEstimate() }
                        }
                        return true
                    }
                }
            } else {
                if hypot(local.x + 102, local.y + 122) <= 40 {
                    manipulate { self.state.undoTrailJump() }
                    return true
                }
                if hypot(local.x - 102, local.y + 122) <= 40 {
                    manipulate { self.state.addTrailJump() }
                    return true
                }
            }
        case .reasoningStudio(let model):
            switch model.task {
            case .strategy:
                for (x, choice) in [
                    (CGFloat(-120), ReasoningStudioStrategy.countOn),
                    (CGFloat(120), ReasoningStudioStrategy.buildCounters)
                ] {
                    if hypot(local.x - x, local.y - 9) <= 39 {
                        manipulate { self.state.chooseReasoningStrategy(choice) }
                        return true
                    }
                }
                if hypot(local.x + 92, local.y + 123) <= 39 {
                    manipulate { self.state.addReasoningStep() }
                    return true
                }
                if hypot(local.x - 92, local.y + 123) <= 39 {
                    manipulate { self.state.undoReasoningStep() }
                    return true
                }
            case .differentWays:
                if hypot(local.x - 226, local.y - 51) <= 37 {
                    manipulate { self.state.undoReasoningPair() }
                    return true
                }
                for (x, left, delta) in [
                    (CGFloat(-192), true, 1), (CGFloat(-110), true, -1),
                    (CGFloat(110), false, 1), (CGFloat(192), false, -1)
                ] {
                    if hypot(local.x - x, local.y + 122) <= 36 {
                        manipulate { self.state.adjustReasoningPair(left: left, delta: delta) }
                        return true
                    }
                }
                if hypot(local.x, local.y + 122) <= 39 {
                    manipulate { self.state.saveReasoningPair() }
                    return true
                }
            case .multiStep:
                if hypot(local.x - 224, local.y - 54) <= 37 {
                    manipulate { self.state.resetReasoningStages() }
                    return true
                }
                if hypot(local.x + 124, local.y + 122) <= 40 {
                    manipulate { self.state.moveReasoningCounter(-1) }
                    return true
                }
                if hypot(local.x - 124, local.y + 122) <= 40 {
                    manipulate { self.state.moveReasoningCounter(1) }
                    return true
                }
                if hypot(local.x, local.y + 122) <= 40 {
                    manipulate { self.state.confirmReasoningStage() }
                    return true
                }
            }
        case .groupingGarden(let model):
            if model.isGroupPlacement {
                if hypot(local.x - 229, local.y - 62) <= 38 {
                    manipulate { self.state.undoGardenSeed() }
                    return true
                }
                let spacing: CGFloat = model.groupCount == 2 ? 160
                    : (model.groupCount == 3 ? 137 : 102)
                for index in 0..<model.groupCount {
                    let x = (CGFloat(index) - CGFloat(model.groupCount - 1) / 2) * spacing
                    if hypot(local.x - x, local.y + 121) <= 39 {
                        manipulate { self.state.placeGardenSeed(in: index + 1) }
                        return true
                    }
                }
            } else if model.isRepeatedAddition {
                if hypot(local.x + 90, local.y + 122) <= 40 {
                    manipulate { self.state.addGardenJump() }
                    return true
                }
                if hypot(local.x - 90, local.y + 122) <= 40 {
                    manipulate { self.state.undoGardenJump() }
                    return true
                }
            } else if model.isFractions {
                for (x, action) in [
                    (CGFloat(-159), "left"),
                    (CGFloat(-53), "right"),
                    (CGFloat(53), "place"),
                    (CGFloat(159), "undo")
                ] {
                    if hypot(local.x - x, local.y + 122) <= 39 {
                        switch action {
                        case "left":
                            manipulate { self.state.moveGardenCut(-1) }
                        case "right":
                            manipulate { self.state.moveGardenCut(1) }
                        case "place":
                            manipulate { self.state.placeGardenCut() }
                        default:
                            manipulate { self.state.undoGardenCut() }
                        }
                        return true
                    }
                }
            }
        case .clockMarket(let model):
            if model.isClock {
                for (x, y, hourDelta, minuteDelta) in [
                    (CGFloat(58), CGFloat(-46), -1, 0),
                    (CGFloat(161), CGFloat(-46), 1, 0),
                    (CGFloat(58), CGFloat(-125), 0, -1),
                    (CGFloat(161), CGFloat(-125), 0, 1)
                ] {
                    if hourDelta == 0 && model.task == .hour { continue }
                    if hypot(local.x - x, local.y - y) <= 38 {
                        if hourDelta != 0 {
                            manipulate { self.state.adjustClockHour(hourDelta) }
                        } else {
                            manipulate { self.state.adjustClockMinute(minuteDelta) }
                        }
                        return true
                    }
                }
            } else if model.isRoutines {
                if hypot(local.x - 225, local.y - 51) <= 37 {
                    manipulate { self.state.undoDailyRoutine() }
                    return true
                }
                for (index, daypart) in ClockMarketDaypart.allCases.enumerated() {
                    let x = CGFloat(index) * 117 - 175.5
                    if hypot(local.x - x, local.y + 118) <= 37 {
                        manipulate { self.state.placeDailyRoutine(daypart) }
                        return true
                    }
                }
            } else if model.isMoney {
                if hypot(local.x - 222, local.y - 60) <= 37 {
                    manipulate { self.state.undoPesoCoin() }
                    return true
                }
                let count = model.allowedCoins.count
                let spacing: CGFloat = count == 2 ? 148 : 104
                for (index, coin) in model.allowedCoins.enumerated() {
                    let x = CGFloat(index) * spacing - CGFloat(count - 1) * spacing / 2
                    if hypot(local.x - x, local.y + 65) <= 38 {
                        manipulate { self.state.addPesoCoin(coin) }
                        return true
                    }
                }
            }
        case .dataBoard(let model):
            if hypot(local.x - 230, local.y - (model.isSorting ? 53 : 51)) <= 41 {
                if model.isSorting {
                    manipulate { self.state.undoDataSort() }
                } else {
                    manipulate { self.state.undoPicture() }
                }
                return true
            }
            if abs(local.y + 121) <= 43 {
                for category in 1...3 {
                    let x = CGFloat(category - 2) * 158
                    if abs(local.x - x) <= 41 {
                        if model.isSorting {
                            manipulate { self.state.sortDataObject(into: category) }
                        } else {
                            manipulate { self.state.addPicture(to: category) }
                        }
                        return true
                    }
                }
            }
        case .measurementWorkshop(let model):
            guard abs(local.y + 120) <= 41 else { break }
            if model.isUnitMeasurement {
                if abs(local.x + 94) <= 41 {
                    manipulate { self.state.removeMeasureUnit() }
                    return true
                }
                if abs(local.x - 94) <= 41 {
                    manipulate { self.state.placeMeasureUnit() }
                    return true
                }
            } else {
                for (x, choice) in [
                    (CGFloat(-155), ComparisonChoice.left),
                    (CGFloat(0), ComparisonChoice.equal),
                    (CGFloat(155), ComparisonChoice.right)
                ] {
                    if abs(local.x - x) <= 40 {
                        manipulate { self.state.chooseComparison(choice) }
                        return true
                    }
                }
            }
        case .patternLoom:
            let controls: [(CGPoint, Int)] = [
                (CGPoint(x: -160, y: -122), 1),
                (CGPoint(x: -10, y: -122), 2),
                (CGPoint(x: 140, y: -122), 3),
                (CGPoint(x: 229, y: -122), 0)
            ]
            for (center, symbol) in controls {
                if hypot(local.x - center.x, local.y - center.y) <= 36 {
                    if symbol == 0 {
                        manipulate { self.state.undoPatternSymbol() }
                    } else {
                        manipulate { self.state.choosePatternSymbol(symbol) }
                    }
                    return true
                }
            }
        default:
            break
        }
        return false
    }

    // Shared by native touches and hosted interaction tests.
    func handleTap(at point: CGPoint) {
        if bridgeQuestMode {
            if targetName(at: point) == "home" {
                valkyrie.cancelTravel()
                pip.cancelTravel()
                state.travel(to: .storyTree)
            } else {
                handleBridgeQuestTap(at: point)
            }
            return
        }
        let target = targetName(at: point)
        if target == "starlightQuestBeacon" {
            enterBridgeQuest()
            return
        }
        if handleMechanicDirectControl(at: point) { return }
        if crossingBridge {
            if target == "home" {
                valkyrie.cancelTravel(); pip.cancelTravel(); crossingBridge = false
                state.travel(to: .storyTree)
            }
            return
        }
        if state.runtime?.completed == true, repairedBridge || routeReady, ["physicalRouteBridge", "missingFixed", "missingPlank", "missingSlot", "missingSupply",
                            "missingBridge", "missingAnswer", "missingPlus", "missingMinus", "bridgeRoute"].contains(target ?? "") {
            if valkyrie.position.y > 240 { returnAcrossBridge(advance: false) }
            else { crossBridge() }
            return
        }
        // An elevated destination can only be left along the repaired path.
        if state.runtime?.completed == true, repairedBridge || routeReady, valkyrie.position.y > 240, target != "home", target != "next", target != "routeDestinationBeacon" {
            returnAcrossBridge(advance: false)
            return
        }
        switch target {
        case "home": state.travel(to: .storyTree)
        case "supply", "bondSupply", "bondSelected", "tenFrameSupply", "tenFrameCell", "missingPlus", "missingSupply", "missingSlot":
            manipulate { self.state.addCrystal() }
        case "cartCrystal", "bondToken", "tenFrameFilled", "missingMinus", "missingPlank":
            manipulate { self.state.removeCrystal() }
        case "placeTensPlus": manipulate { self.state.adjustPlaceValue(tensDelta: 1) }
        case "placeTensMinus": manipulate { self.state.adjustPlaceValue(tensDelta: -1) }
        case "placeOnesPlus": manipulate { self.state.adjustPlaceValue(onesDelta: 1) }
        case "placeOnesMinus": manipulate { self.state.adjustPlaceValue(onesDelta: -1) }
        case "loomSymbol1": manipulate { self.state.choosePatternSymbol(1) }
        case "loomSymbol2": manipulate { self.state.choosePatternSymbol(2) }
        case "loomSymbol3": manipulate { self.state.choosePatternSymbol(3) }
        case "loomUndo": manipulate { self.state.undoPatternSymbol() }
        case "forgeChoice1": manipulate { self.state.chooseShapeOption(1) }
        case "forgeChoice2": manipulate { self.state.chooseShapeOption(2) }
        case "forgeChoice3": manipulate { self.state.chooseShapeOption(3) }
        case "forgeTurnLeft": manipulate { self.state.rotateShape(-1) }
        case "forgeTurnRight": manipulate { self.state.rotateShape(1) }
        case "forgeHalf0": manipulate { self.state.placeShapeHalf(0) }
        case "forgeHalf1": manipulate { self.state.placeShapeHalf(1) }
        case "forgeHalf2": manipulate { self.state.placeShapeHalf(2) }
        case "forgeHalf3": manipulate { self.state.placeShapeHalf(3) }
        case "forgeUndoHalf": manipulate { self.state.undoShapeHalf() }
        case "forgeMirror0": manipulate { self.state.cycleMirrorCell(0) }
        case "forgeMirror1": manipulate { self.state.cycleMirrorCell(1) }
        case "forgeMirror2": manipulate { self.state.cycleMirrorCell(2) }
        case "measureAdd": manipulate { self.state.placeMeasureUnit() }
        case "measureRemove": manipulate { self.state.removeMeasureUnit() }
        case "measureLeft": manipulate { self.state.chooseComparison(.left) }
        case "measureEqual": manipulate { self.state.chooseComparison(.equal) }
        case "measureRight": manipulate { self.state.chooseComparison(.right) }
        case "dataBin1": manipulate { self.state.sortDataObject(into: 1) }
        case "dataBin2": manipulate { self.state.sortDataObject(into: 2) }
        case "dataBin3": manipulate { self.state.sortDataObject(into: 3) }
        case "dataGraph1": manipulate { self.state.addPicture(to: 1) }
        case "dataGraph2": manipulate { self.state.addPicture(to: 2) }
        case "dataGraph3": manipulate { self.state.addPicture(to: 3) }
        case "clockHourMinus": manipulate { self.state.adjustClockHour(-1) }
        case "clockHourPlus": manipulate { self.state.adjustClockHour(1) }
        case "clockMinuteMinus": manipulate { self.state.adjustClockMinute(-1) }
        case "clockMinutePlus": manipulate { self.state.adjustClockMinute(1) }
        case "routinemorning": manipulate { self.state.placeDailyRoutine(.morning) }
        case "routineafternoon": manipulate { self.state.placeDailyRoutine(.afternoon) }
        case "routineevening": manipulate { self.state.placeDailyRoutine(.evening) }
        case "routinenight": manipulate { self.state.placeDailyRoutine(.night) }
        case "routineUndo": manipulate { self.state.undoDailyRoutine() }
        case "marketCoin1": manipulate { self.state.addPesoCoin(1) }
        case "marketCoin5": manipulate { self.state.addPesoCoin(5) }
        case "marketCoin10": manipulate { self.state.addPesoCoin(10) }
        case "marketCoin20": manipulate { self.state.addPesoCoin(20) }
        case "marketCoinUndo": manipulate { self.state.undoPesoCoin() }
        case "gardenBasket1": manipulate { self.state.placeGardenSeed(in: 1) }
        case "gardenBasket2": manipulate { self.state.placeGardenSeed(in: 2) }
        case "gardenBasket3": manipulate { self.state.placeGardenSeed(in: 3) }
        case "gardenBasket4": manipulate { self.state.placeGardenSeed(in: 4) }
        case "gardenBasket5": manipulate { self.state.placeGardenSeed(in: 5) }
        case "gardenUndoSeed": manipulate { self.state.undoGardenSeed() }
        case "gardenJumpAdd": manipulate { self.state.addGardenJump() }
        case "gardenJumpUndo": manipulate { self.state.undoGardenJump() }
        case "gardenCutLeft": manipulate { self.state.moveGardenCut(-1) }
        case "gardenCutRight": manipulate { self.state.moveGardenCut(1) }
        case "gardenCutPlace": manipulate { self.state.placeGardenCut() }
        case "gardenCutUndo": manipulate { self.state.undoGardenCut() }
        case "reasonCountOn": manipulate { self.state.chooseReasoningStrategy(.countOn) }
        case "reasonBuild": manipulate { self.state.chooseReasoningStrategy(.buildCounters) }
        case "reasonStepAdd": manipulate { self.state.addReasoningStep() }
        case "reasonStepUndo": manipulate { self.state.undoReasoningStep() }
        case "reasonPairLeftUp": manipulate { self.state.adjustReasoningPair(left: true, delta: 1) }
        case "reasonPairLeftDown": manipulate { self.state.adjustReasoningPair(left: true, delta: -1) }
        case "reasonPairRightUp": manipulate { self.state.adjustReasoningPair(left: false, delta: 1) }
        case "reasonPairRightDown": manipulate { self.state.adjustReasoningPair(left: false, delta: -1) }
        case "reasonPairSave": manipulate { self.state.saveReasoningPair() }
        case "reasonPairUndo": manipulate { self.state.undoReasoningPair() }
        case "reasonCounterMinus": manipulate { self.state.moveReasoningCounter(-1) }
        case "reasonCounterPlus": manipulate { self.state.moveReasoningCounter(1) }
        case "reasonConfirm": manipulate { self.state.confirmReasoningStage() }
        case "reasonReset": manipulate { self.state.resetReasoningStages() }
        case "trailFlash": manipulate { self.state.revealTrailCollection() }
        case "trailEstimateMinus": manipulate { self.state.adjustTrailEstimate(-1) }
        case "trailEstimatePlus": manipulate { self.state.adjustTrailEstimate(1) }
        case "trailEstimateLock": manipulate { self.state.lockTrailEstimate() }
        case "trailUndoJump": manipulate { self.state.undoTrailJump() }
        case "trailAddJump": manipulate { self.state.addTrailJump() }
        case "diffMatch": manipulate { self.state.matchDifferencePair() }
        case "diffUndoMatch": manipulate { self.state.undoDifferencePair() }
        case "diffCollect": manipulate { self.state.collectDifference() }
        case "diffUndoCollect": manipulate { self.state.undoDifferenceCollection() }
        case "inverseAdd": manipulate { self.state.addInverseCounter() }
        case "inverseUndoAdd": manipulate { self.state.undoInverseCounter() }
        case "inverseTake": manipulate { self.state.reverseInverseCounter() }
        case "inverseUndoTake": manipulate { self.state.undoInverseReverse() }
        case "mapNorth": manipulate { self.state.moveOnMap(.north) }
        case "mapSouth": manipulate { self.state.moveOnMap(.south) }
        case "mapWest": manipulate { self.state.moveOnMap(.west) }
        case "mapEast": manipulate { self.state.moveOnMap(.east) }
        case "mapUndo": manipulate { self.state.undoMapMove() }
        case "dataUndo":
            if case .dataBoard(let model)? = state.runtime, model.isSorting {
                manipulate { self.state.undoDataSort() }
            } else {
                manipulate { self.state.undoPicture() }
            }
        case "scaleLeft", "placeLeft": manipulate { self.state.chooseComparison(.left) }
        case "scaleRight", "placeRight": manipulate { self.state.chooseComparison(.right) }
        case "scaleEqual", "placeEqual": manipulate { self.state.chooseComparison(.equal) }
        case "submit": submit()
        case "help":
            if canManipulate() { showScaffold() } else { engageMachine() }
        case "wind":
            playWorkshopGearSurge(named: "wind")
            engaged = false
            setActiveMachineKinetics(false)
            travel(to: CGPoint(x: 380, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration(); self.state.audio.play("gear")
                self.instruction.text = "Pip's gears hum! Explore or choose a new work order."
            }
        case "next", "routeDestinationBeacon":
            guard bridgeQuestAllowsPassage || state.runtime?.completed != true else {
                instruction.text = "The bridge needs crystals! Tap the blue star and finish its sockets."
                return
            }
            guard state.runtime == nil || state.runtime?.completed == true || state.workshop else {
                instruction.text = "Finish Pip's work order first. You can explore and come back."
                return
            }

            if state.runtime?.completed == true {
                guard routeReady || repairedBridge else {
                    instruction.text = "Watch the starlight finish opening the bridge."
                    return
                }
                if isNear(bridgePath.last!, radius: 55) { returnAcrossBridge(advance: true) }
                else { crossBridge() }
            } else {
                state.advanceEncounter(); openOrder()
            }
        case "workshop0": playWorkshopGearSurge(named: "workshop0"); workshop(0)
        case "workshop1": playWorkshopGearSurge(named: "workshop1"); workshop(1)
        case "workshop2": playWorkshopGearSurge(named: "workshop2"); workshop(2)
        case "workshop3": playWorkshopGearSurge(named: "workshop3"); workshop(3)
        case "workshop4": playWorkshopGearSurge(named: "workshop4"); workshop(4)
        case "challengeGate":
            openChallengeGate()
        case "cart", "fixedCrystal", "bondMachine", "bondKnown", "bondFixed", "tenFrameFixed", "tenFramePreview", "missingBridge", "missingAnswer", "missingFixed", "scaleBeam",
             "placeTensBuilt", "placeOnesBuilt",
             MathMechanicID.balanceScale, MathMechanicID.numberBondMachine, MathMechanicID.tenFrameGate, MathMechanicID.missingNumberBridge, MathMechanicID.placeValueFactory, MathMechanicID.patternLoom, MathMechanicID.shapeForge, MathMechanicID.measurementWorkshop, MathMechanicID.dataBoard, MathMechanicID.clockMarket, MathMechanicID.groupingGarden, MathMechanicID.reasoningStudio, MathMechanicID.numberTrail, MathMechanicID.differenceBridge, MathMechanicID.routeExplorer:
            engageMachine()
        default:
            if walkable.contains(point) {
                engaged = false
                setActiveMachineKinetics(false)
                walkIfValid(point)
            }
        }
    }

    private func manipulate(_ action: () -> Void) {
        guard canManipulate() else { engageMachine(); return }
        let before = state.runtime
        action()
        finishManipulation(from: before)
    }

    private func finishManipulation(from before: MathMechanicRuntime?) {
        guard let runtime = state.runtime, runtime != before else {
            instruction.text = "No change yet. Try another move, or pull Pip's lever."
            return
        }
        selectionFeedback()
        refresh()
        playManipulationReaction()
        valkyrie.pose(.interact)
        pip.face(toward: CGPoint(x: 820, y: 310))
        pip.pose(.react)
        state.audio.play("crystal")
        let change: String
        switch runtime {
        case .crystalCart(let model):
            change = "\(model.quantity) \(model.quantity == 1 ? "crystal" : "crystals") in the cart."
        case .numberBond(let model):
            change = "\(model.selectedPart) \(model.selectedPart == 1 ? "crystal" : "crystals") in the open part."
        case .tenFrame(let model):
            change = "\(model.filled) \(model.filled == 1 ? "light" : "lights") placed."
        case .missingBridge(let model):
            change = "\(model.selectedNumber) \(model.selectedNumber == 1 ? "plank" : "planks") added."
        case .balanceScale(let model):
            switch model.selected {
            case .left: change = "Left pan selected."
            case .right: change = "Right pan selected."
            case .equal: change = "Equal gear selected."
            case nil: return
            }
        case .placeValueFactory(let model):
            if model.isComparison {
                switch model.selectedComparison {
                case .left: change = "Left number selected."
                case .right: change = "Right number selected."
                case .equal: change = "Equal selected."
                case nil: return
                }
            } else {
                change = "\(model.selectedTens) tens and \(model.selectedOnes) ones make \(model.builtNumber)."
            }
        case .patternLoom(let model):
            change = model.isCreation
                ? "\(model.selectedSymbols.count) of \(model.slotCount) pattern shapes placed."
                : "A shape fills the pattern gap."
        case .shapeForge(let model):
            switch model.task {
            case .rotate:
                change = "The triangle turned one quarter-turn."
            case .compose:
                change = "\(model.placedHalfTurns.count) of 2 triangle halves placed."
            case .symmetry:
                change = "\(model.mirrorCells.compactMap { $0 }.count) of 3 mirror cells filled."
            case .recognize, .attributes:
                change = "Shape option \(model.selectedOption ?? 0) selected."
            }
        case .measurementWorkshop(let model):
            if model.isUnitMeasurement {
                change = "\(model.placedUnits) equal-size measurement units placed."
            } else {
                switch model.selectedComparison {
                case .left: change = "Left measurement selected."
                case .right: change = "Right measurement selected."
                case .equal: change = "Equal measurements selected."
                case nil: return
                }
            }
        case .dataBoard(let model):
            if model.isSorting {
                change = "\(model.sortedBins.count) of 5 objects sorted."
            } else {
                let count = model.placedGraphTotal
                change = "\(count) \(count == 1 ? "picture tile" : "picture tiles") placed in the graph."
            }
        case .clockMarket(let model):
            if model.isClock {
                let minuteText = model.minute < 10 ? "0\(model.minute)" : "\(model.minute)"
                change = "Clock hands now show \(model.hour):\(minuteText)."
            } else if model.isRoutines {
                change = "\(model.routineBins.count) of 4 daily events sorted."
            } else {
                change = "₱\(model.totalPesos) in selected teaching coins."
            }
        case .groupingGarden(let model):
            if model.isGroupPlacement {
                change = "\(model.unitsPlaced) of \(model.targetTotal) garden seeds placed."
            } else if model.isRepeatedAddition {
                change = "\(model.jumps) \(model.jumps == 1 ? "jump" : "jumps") \(model.jumps == 1 ? "makes" : "make") a total of \(model.currentJumpTotal)."
            } else {
                change = "\(model.cuts.count) of \(model.groupCount - 1) fraction cuts placed."
            }
        case .numberTrail(let model):
            if model.isEstimate {
                if let guess = model.lockedEstimate {
                    change = "Estimate \(guess) locked after the brief flash."
                } else if model.flashObserved {
                    change = "Fireflies flashed. Estimate dial is on \(model.dialValue)."
                } else {
                    change = "Watch the brief firefly flash before you guess."
                }
            } else {
                change = "\(model.jumps) of \(model.requiredJumps) jumps placed. Marker at \(model.markerNumber)."
            }
        case .reasoningStudio(let model):
            switch model.task {
            case .strategy:
                if let strategy = model.chosenStrategy {
                    change = "\(model.strategySteps) \(model.strategySteps == 1 ? "step" : "steps") using \(strategy == .countOn ? "counting on" : "counter tiles")."
                } else {
                    change = "Choose a strategy and show the steps."
                }
            case .differentWays:
                change = "\(model.solutions.count) of 2 pairs saved. Draft: \(model.draftLeft) + \(model.draftRight)."
            case .multiStep:
                if let result = model.observedFinal {
                    change = "Both changes checked. Final number \(result)."
                } else if let first = model.observedIntermediate {
                    change = "First step checked at \(first). Number marker \(model.workingValue)."
                } else {
                    change = "Number marker now \(model.workingValue)."
                }
            }
        case .differenceBridge(let model):
            if model.isDifference {
                let pairWord = model.matchedPairs == 1 ? "pair" : "pairs"
                change = "\(model.matchedPairs) \(pairWord) matched. \(model.collectedLeftovers) leftovers collected."
            } else {
                change = "\(model.joinedCounters) counters added, then \(model.returnedCounters) taken back."
            }
        case .routeExplorer(let model):
            change = "Rover moved \(model.movesTaken) \(model.movesTaken == 1 ? "step" : "steps") on the grid."
        }
        // Describe only the child's visible edit; the lever still checks the answer.
        instruction.text = change + " Pull Pip's lever when you're ready."
    }

    func drop(origin: String, at point: CGPoint) {
        guard canManipulate() else { return }
        guard let mechanic else { return }
        let local = mechanic.convert(point, from: self)
        let before = state.runtime
        var changed = false
        switch origin {
        case "supply":
            if let cart = mechanic as? CrystalCartMechanic, cart.receives(local) { state.addCrystal(); changed = true }
        case "cartCrystal":
            if let cart = mechanic as? CrystalCartMechanic, cart.returnsToSupply(local) { state.removeCrystal(); changed = true }
        case "bondSupply":
            if CGRect(x: 30, y: -88, width: 150, height: 116).contains(local) { state.addCrystal(); changed = true }
        case "bondToken":
            if CGRect(x: -315, y: -80, width: 100, height: 100).contains(local) { state.removeCrystal(); changed = true }
        case "tenFrameSupply":
            if CGRect(x: -160, y: -62, width: 320, height: 128).contains(local) { state.addCrystal(); changed = true }
        case "tenFrameFilled":
            if CGRect(x: -320, y: -50, width: 100, height: 100).contains(local) { state.removeCrystal(); changed = true }
        case "missingSupply":
            if let bridge = mechanic as? MissingNumberBridgeMechanic, bridge.receives(local) { state.addCrystal(); changed = true }
        case "missingPlank":
            if let bridge = mechanic as? MissingNumberBridgeMechanic, bridge.returnsToSupply(local) { state.removeCrystal(); changed = true }
        default: break
        }
        if changed {
            finishManipulation(from: before)
        }
    }

    private func submit() {
        guard canManipulate() else { engageMachine(); return }
        let wasChallengeGate = state.challengeGateStatus == .active
        guard let evidence = state.submit() else {
            instruction.text = "Touch a scale pan, or the equal gear, before pulling Pip's lever."; return
        }
        refresh()
        updateChallengeGateAppearance()
        if evidence.outcome == .correct {
            successFeedback(at: CGPoint(x: 820, y: 310))
            setActiveMachineKinetics(false)
            playCastlePowerSurge()
            focusMoment(on: CGPoint(x: 1030, y: 300), hold: 0.72)
            pip.helpRoute(to: CGPoint(x: 975, y: 225), reducedMotion: reducedMotion)
            valkyrie.pose(.celebrate)
            showQuestion(nil)
            if wasChallengeGate && state.challengeGateStatus == .completed {
                instruction.text = "The final rune shines! Your Moon Lantern is waiting at Story Tree."
            } else if wasChallengeGate {
                instruction.text = "A Challenge Gate rune lights up. Follow the arrow for the next challenge."
            } else {
                instruction.text = completionMessage
            }
        } else {
            errorFeedback()
            valkyrie.pose(.react)
            showScaffold()
            playGentleRetryReaction()
        }
    }

    private func openChallengeGate() {
        switch state.challengeGateStatus {
        case .locked:
            instruction.text = "The Challenge Gate is still gathering starlight. Keep helping Pip with ready skills."

        case .ready:
            if let runtime = state.runtime, !runtime.completed {
                instruction.text = "Finish this work order before entering the Challenge Gate."
                return
            }
            if state.beginChallengeGate() {
                engaged = false
                renderedEncounterID = nil
                updateChallengeGateAppearance()
                openOrder()
            } else {
                instruction.text = "The Challenge Gate needs a little more readiness before it opens."
            }

        case .active:
            if state.runtime == nil || state.runtime?.completed == true {
                _ = state.advanceEncounter()
                openOrder()
            } else {
                instruction.text = "The Challenge Gate is already open. Finish the glowing machine."
                engageMachine()
            }

        case .completed:
            instruction.text = "The Challenge Gate is restored. Your Moon Lantern is waiting at Story Tree."
        }
    }

    private func workshop(_ index: Int) {
        if let runtime = state.runtime, !runtime.completed, !state.workshop {
            instruction.text = "Finish Pip's work order before opening his workshop."; return
        }
        let examples = MathWorkshopCatalog.choices(
            at: index,
            profile: state.profile,
            graph: state.graph
        )
        guard !examples.isEmpty else {
            instruction.text = "Pip has no new ready challenge at this station. Try another machine."
            return
        }
        // Try the next unused authored example; the learning layer owns repetition policy.
        for offset in 0..<examples.count {
            let next = (workshopIndices[index] + offset) % examples.count
            if state.startWorkshop(examples[next]) {
                workshopIndices[index] = (next + 1) % examples.count
                clearDrag()
                engaged = false
                setActiveMachineKinetics(false)
                renderedEncounterID = nil
                refresh()
                instruction.text = "Tap the machine to walk over and try it."
                return
            }
        }
        instruction.text = "Pip has no fresh example here. Try another station or wind his gear."
    }

    private func engageMachine() {
        guard state.runtime != nil, state.runtime?.completed == false else {
            instruction.text = "Choose a new order or a workshop station."; return
        }
        // One tap is enough: Valkyrie approaches and starts interacting.
        // Children should not have to repeat the same tap after an animation.
        let start = { [weak self] in
            guard let self, !self.hasLeftScene, !self.bridgeQuestMode,
                  self.state.runtime?.completed == false else { return }
            self.valkyrie.face(toward: CGPoint(x: 820, y: 310))
            self.pip.face(toward: CGPoint(x: 820, y: 310))
            self.state.beginInteraction()
            self.engaged = true
            self.wakeMechanic()
            self.setActiveMachineKinetics(true)
            self.refresh()
        }
        if isNear(station) {
            start()
        } else if valkyrie.action(forKey: "travel") == nil {
            engaged = false
            instruction.text = "Valkyrie is walking to Pip's machine. Watch what happens!"
            travel(to: station, then: start)
        }
    }

    private func showScaffold() {
        if let scaffold = state.scaffold() {
            pip.operate(reducedMotion: reducedMotion); refresh(); instruction.text = scaffold.cue
        }
    }

    private func clearDrag() {
        activeTouch = nil; dragOrigin = nil; ghost?.removeFromParent(); ghost = nil; didDrag = false
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            clearDrag()
            bridgeQuestDraggedCrystal = nil
        }
    }
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let height = max(0, min(1, (valkyrie.position.y - 240) / 160))
        valkyrie.setScale(0.5 * (1 - height * 0.12))
        let pipHeight = max(0, min(1, (pip.position.y - 240) / 160))
        pip.setScale(0.65 * (1 - pipHeight * 0.12))

        if lastKineticReducedMotion != reducedMotion {
            syncCastleKinetics()
            if engaged {
                setActiveMachineKinetics(true)
            }
        }

        if engaged, lastPreviewVisible != state.previewVisible { refresh() }
    }
    override func willLeave() {
        hasLeftScene = true
        crossingBridge = false
        setActiveMachineKinetics(false)
        clearDrag()
        super.willLeave()
    }
}
