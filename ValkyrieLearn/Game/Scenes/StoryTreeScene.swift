import SpriteKit

@MainActor final class StoryTreeScene: AdventureScene {
    override var environment: ArtSystem.Environment { .isles }
    override var worldTitle: String { "Story Tree · The Lost Starlight" }
    override var walkable: CGRect { CGRect(x: 105, y: 120, width: 750, height: 370) }

    // Follow the painted foreground stair and upper bridge to the castle.
    private let route: [CGPoint] = [
        CGPoint(x: 190, y: 170),
        CGPoint(x: 285, y: 235),
        CGPoint(x: 385, y: 275),
        CGPoint(x: 430, y: 340),
        CGPoint(x: 475, y: 420),
        CGPoint(x: 580, y: 450),
        CGPoint(x: 690, y: 450),
        CGPoint(x: 795, y: 450)
    ]

    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false
    private var moonLanternNode: SKNode?
    private var wordGardenLanternNode: SKNode?
    private var puzzlePalaceLanternNode: SKNode?
    private let moonLanternSlots = [
        CGPoint(x: 295, y: 500),
        CGPoint(x: 390, y: 555),
        CGPoint(x: 485, y: 500)
    ]
    private let wordGardenLanternSlots = [
        CGPoint(x: 535, y: 535),
        CGPoint(x: 625, y: 505),
        CGPoint(x: 710, y: 540)
    ]
    private let puzzlePalaceLanternSlots = [
        CGPoint(x: 335, y: 455),
        CGPoint(x: 435, y: 485),
        CGPoint(x: 555, y: 470)
    ]

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        polishStoryTreeHUD()
        pip.position = CGPoint(x: 250, y: 210)
    }

    private func polishStoryTreeHUD() {
        childNode(withName: "worldTitleBackdrop")?.removeFromParent()
        childNode(withName: "worldTitle")?.removeFromParent()

        let titlePlate = ArtSystem.plaque(
            CGSize(width: 340, height: 42),
            fill: UIColor(red: 0.045, green: 0.065, blue: 0.13, alpha: 0.88),
            stroke: UIColor(red: 0.92, green: 0.72, blue: 0.34, alpha: 0.56),
            radius: 15
        )
        titlePlate.position = CGPoint(x: 258, y: 672)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)

        let title = ArtSystem.label(worldTitle, size: 20)
        title.fontName = "Georgia-Bold"
        title.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 103, y: 672)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        childNode(withName: "topVignette")?.alpha = 0.40

        if let feedbackPlate = childNode(withName: "instructionBackdrop") {
            feedbackPlate.xScale = 0.68
            feedbackPlate.yScale = 0.80
            feedbackPlate.position = CGPoint(x: 640, y: 44)
        }
        instruction.position = CGPoint(x: 640, y: 44)
        instruction.fontName = "AvenirNext-Medium"
        instruction.fontSize = 18
        instruction.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.84, alpha: 1)
        instruction.preferredMaxLayoutWidth = 610
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

    override func willLeave() {
        activeTouch = nil
        moved = false
        super.willLeave()
    }

    override func buildWorld() {
        super.buildWorld()
        prepareStoryTreeIllustrationForRetina()
        buildStoryTreeFidelityAccents()

        // World entrances are environmental beacons, not generic navigation buttons.
        // Keep them visually offset from the painted travel route so Valkyrie never
        // stands on top of a label while approaching a destination.
        _ = storyDestinationMarker(
            "Word Garden",
            symbol: "✿",
            name: "wordGarden",
            at: CGPoint(x: 150, y: 430),
            tint: UIColor(red: 0.95, green: 0.48, blue: 0.72, alpha: 1),
            width: 142,
            plaqueOffsetY: 68
        )

        _ = storyDestinationMarker(
            "Puzzle Palace",
            symbol: "◈",
            name: "puzzlePalace",
            at: CGPoint(x: 505, y: 515),
            tint: UIColor(red: 0.62, green: 0.50, blue: 0.94, alpha: 1),
            width: 156
        )

        _ = storyDestinationMarker(
            "Math Castle",
            symbol: "◆",
            name: "castle",
            at: CGPoint(x: 835, y: 535),
            tint: UIColor(red: 0.95, green: 0.70, blue: 0.28, alpha: 1),
            width: 148
        )

        _ = storyDestinationMarker(
            state.scienceAdventure.groveRestored ? "Science Lab ✦" : "Science Lab",
            symbol: "⚗",
            name: "scienceLab",
            at: CGPoint(x: 705, y: 585),
            tint: UIColor(red: 0.42, green: 0.82, blue: 0.61, alpha: 1),
            width: 152
        )

        buildPipWorkshopGear()

        let glow = SKShapeNode(circleOfRadius: 45)
        glow.fillColor = .init(red: 1, green: 0.82, blue: 0.3, alpha: 0.13)
        glow.strokeColor = .init(red: 1, green: 0.85, blue: 0.45, alpha: 0.5)
        glow.glowWidth = 14
        glow.position = CGPoint(x: 350, y: 405)
        glow.zPosition = 20
        glow.name = "storyLight"
        addChild(glow)

        if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 95, height: 100)) {
            bloom.position = CGPoint(x: 430, y: 330)
            bloom.name = "storyLight"
            bloom.zPosition = 815
            addChild(bloom)
        }

        pip.name = "pipWind"
        renderMoonLantern()
        renderWordGardenLantern()
        renderPuzzlePalaceLantern()

        let rewardCount = [
            state.hasStoryReward(.moonLantern),
            state.hasStoryReward(.wordGardenLantern),
            state.hasStoryReward(.puzzlePalaceLantern)
        ].filter { $0 }.count
        if rewardCount >= 2 {
            instruction.text = "Your lanterns are glowing. Choose where Valkyrie explores next."
        } else if state.hasStoryReward(.puzzlePalaceLantern) {
            instruction.text = "Tiko's Palace Lantern is home. Choose the next adventure."
        } else if state.hasStoryReward(.wordGardenLantern) {
            instruction.text = "The Flower Lantern is home. Choose the next adventure."
        } else if state.hasStoryReward(.moonLantern) {
            instruction.text = "The Moon Lantern is home. Choose the next adventure."
        } else {
            instruction.text = "The Story Tree needs starlight. Choose a world to explore."
        }

        // Story Tree movement is constrained to an authored painted route. The
        // destination beacons deliberately sit above that route, so generic
        // interaction avoidance must not push Valkyrie into the surrounding chasm.
        clearRegisteredInteractionZones()
    }

    @discardableResult
    private func storyDestinationMarker(
        _ title: String,
        symbol: String,
        name: String,
        at point: CGPoint,
        tint: UIColor,
        width: CGFloat,
        plaqueOffsetY: CGFloat = -54
    ) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 760

        let halo = SKShapeNode(circleOfRadius: 29)
        halo.fillColor = tint.withAlphaComponent(0.11)
        halo.strokeColor = tint.withAlphaComponent(0.58)
        halo.lineWidth = 2
        halo.glowWidth = reducedMotion ? 0 : 6
        halo.name = name
        halo.userData = NSMutableDictionary(dictionary: ["decorativeMotionRole": "pulse"])
        root.addChild(halo)

        let medallion = ArtSystem.medallion(
            radius: 23,
            fill: UIColor(red: 0.05, green: 0.07, blue: 0.13, alpha: 0.88),
            stroke: tint.withAlphaComponent(0.72),
            glow: 0
        )
        medallion.name = name
        root.addChild(medallion)

        let emblem = ArtSystem.label(symbol, size: 24)
        emblem.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.84, alpha: 1)
        emblem.name = name
        medallion.addChild(emblem)

        let plaque = ArtSystem.plaque(
            CGSize(width: max(126, width), height: 38),
            fill: UIColor(red: 0.045, green: 0.055, blue: 0.11, alpha: 0.86),
            stroke: tint.withAlphaComponent(0.52),
            radius: 13
        )
        plaque.position = CGPoint(x: 0, y: plaqueOffsetY)
        plaque.name = name
        plaque.userData = NSMutableDictionary(dictionary: ["destinationRole": "plaque"])
        root.addChild(plaque)

        let label = ArtSystem.label(title, size: 15)
        label.fontName = "Georgia-Bold"
        label.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1)
        label.name = name
        plaque.addChild(label)

        let hit = SKShapeNode(circleOfRadius: 32)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = name
        hit.zPosition = 3
        root.addChild(hit)

        makeAccessible(root, label: title)
        addChild(root)
        registerInteraction(root, clearance: 22)

        return root
    }

    private func buildPipWorkshopGear() {
        let root = SKNode()
        root.name = "pipWind"
        root.position = CGPoint(x: 315, y: 260)
        root.zPosition = 750

        let base = SKShapeNode(ellipseOf: CGSize(width: 74, height: 28))
        base.fillColor = UIColor(red: 0.16, green: 0.11, blue: 0.08, alpha: 0.56)
        base.strokeColor = UIColor(red: 0.86, green: 0.63, blue: 0.26, alpha: 0.30)
        base.lineWidth = 2
        base.position.y = -29
        base.name = "pipWind"
        root.addChild(base)

        let gear = ArtSystem.gear(radius: 25, symbol: "✦")
        gear.name = "pipWind"
        gear.zPosition = 1
        root.addChild(gear)

        let hit = SKShapeNode(circleOfRadius: 32)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = "pipWind"
        hit.zPosition = 3
        root.addChild(hit)

        makeAccessible(root, label: "Pip's workshop gear")
        addChild(root)
        registerInteraction(root, clearance: 18)
    }

    /// Preserve the approved Starlight Isles illustration while preparing a
    /// cached 2x raster for Retina presentation. The source remains the same art;
    /// this only prevents the 1x bitmap from being enlarged at final composition.
    private func prepareStoryTreeIllustrationForRetina() {
        if let backdrop = childNode(withName: "worldBackdrop") as? SKSpriteNode,
           let texture = ArtSystem.retinaEnhancedTexture(
                "StarlightIsles",
                targetPoints: size,
                sharpness: 0.26
           ) {
            backdrop.texture = texture
            backdrop.userData = NSMutableDictionary(dictionary: [
                "retinaPrepared": true,
                "sourceAsset": "StarlightIsles"
            ])
        }

        for side in ["Left", "Right"] {
            guard let foreground = childNode(
                withName: "foreground" + side
            ) as? SKSpriteNode else { continue }
            let asset = "IslesForeground" + side
            if let texture = ArtSystem.retinaEnhancedTexture(
                asset,
                targetPoints: foreground.size,
                sharpness: 0.22
            ) {
                foreground.texture = texture
            }
        }
    }

    /// Add quiet device-resolution accents at existing landmarks and along the
    /// authored painted route. These reinforce crispness without redrawing the
    /// world or changing any hit target, waypoint, or destination geometry.
    private func buildStoryTreeFidelityAccents() {
        let root = SKNode()
        root.name = "storyTreeRetinaAccents"
        root.zPosition = -70

        let bridgePath = CGMutablePath()
        bridgePath.move(to: CGPoint(x: 470, y: 452))
        bridgePath.addCurve(
            to: CGPoint(x: 805, y: 452),
            control1: CGPoint(x: 565, y: 463),
            control2: CGPoint(x: 705, y: 447)
        )
        let bridgeRim = SKShapeNode(path: bridgePath)
        bridgeRim.name = "storyBridgeRim"
        bridgeRim.strokeColor = UIColor(
            red: 1.0,
            green: 0.84,
            blue: 0.46,
            alpha: 0.14
        )
        bridgeRim.lineWidth = 2
        bridgeRim.glowWidth = reducedMotion ? 0 : 1
        root.addChild(bridgeRim)

        let routeSparkPoints = [
            route[1],
            route[3],
            route[5],
            route[7]
        ]
        for (index, point) in routeSparkPoints.enumerated() {
            let spark = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 2.2 : 1.7)
            spark.position = CGPoint(x: point.x, y: point.y + 15)
            spark.fillColor = UIColor(
                red: 1.0,
                green: 0.90,
                blue: 0.58,
                alpha: 0.32
            )
            spark.strokeColor = .clear
            spark.glowWidth = reducedMotion ? 0 : 2
            spark.name = "storyRouteSpark"
            root.addChild(spark)
        }

        let canopyGlints = [
            CGPoint(x: 248, y: 555),
            CGPoint(x: 350, y: 602),
            CGPoint(x: 462, y: 565),
            CGPoint(x: 612, y: 610),
            CGPoint(x: 748, y: 575),
            CGPoint(x: 880, y: 615)
        ]
        for (index, point) in canopyGlints.enumerated() {
            let glint = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 2.4 : 1.5)
            glint.position = point
            glint.fillColor = UIColor(
                red: 0.91,
                green: 0.95,
                blue: 1.0,
                alpha: 0.30
            )
            glint.strokeColor = .clear
            glint.glowWidth = reducedMotion ? 0 : 2
            glint.name = "storyCanopyGlint"
            root.addChild(glint)
        }

        addChild(root)
    }

    private func renderMoonLantern() {
        moonLanternNode?.removeFromParent()
        moonLanternNode = nil

        guard state.hasStoryReward(.moonLantern), !moonLanternSlots.isEmpty else { return }

        let slot = state.storyRewardPlacement(.moonLantern) % moonLanternSlots.count
        let lantern = SKNode()
        lantern.name = "moonLantern"
        lantern.position = moonLanternSlots[slot]
        lantern.zPosition = 900

        let glow = SKShapeNode(circleOfRadius: 48)
        glow.fillColor = UIColor(red: 1, green: 0.80, blue: 0.28, alpha: 0.16)
        glow.strokeColor = .clear
        glow.glowWidth = 10
        glow.name = "moonLantern"
        lantern.addChild(glow)

        let hanger = SKShapeNode(rectOf: CGSize(width: 5, height: 28), cornerRadius: 2)
        hanger.fillColor = UIColor(red: 0.77, green: 0.47, blue: 0.16, alpha: 1)
        hanger.strokeColor = .clear
        hanger.position = CGPoint(x: 0, y: 38)
        hanger.name = "moonLantern"
        lantern.addChild(hanger)

        let body = SKShapeNode(rectOf: CGSize(width: 52, height: 66), cornerRadius: 15)
        body.fillColor = UIColor(red: 0.23, green: 0.17, blue: 0.38, alpha: 0.95)
        body.strokeColor = UIColor(red: 1, green: 0.78, blue: 0.31, alpha: 1)
        body.lineWidth = 3
        body.name = "moonLantern"
        lantern.addChild(body)

        let moon = ArtSystem.label("☾", size: 32)
        moon.fontColor = UIColor(red: 1, green: 0.88, blue: 0.48, alpha: 1)
        moon.name = "moonLantern"
        lantern.addChild(moon)

        if !reducedMotion {
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.45, duration: 1.1),
                .fadeAlpha(to: 1.0, duration: 1.1)
            ])))
        }

        addChild(lantern)
        moonLanternNode = lantern
    }

    private func renderWordGardenLantern() {
        wordGardenLanternNode?.removeFromParent()
        wordGardenLanternNode = nil

        guard state.hasStoryReward(.wordGardenLantern),
              !wordGardenLanternSlots.isEmpty else { return }

        let slot = state.storyRewardPlacement(.wordGardenLantern)
            % wordGardenLanternSlots.count
        let lantern = SKNode()
        lantern.name = "wordGardenLantern"
        lantern.position = wordGardenLanternSlots[slot]
        lantern.zPosition = 900

        let glow = SKShapeNode(circleOfRadius: 48)
        glow.fillColor = UIColor(red: 0.95, green: 0.48, blue: 0.72, alpha: 0.17)
        glow.strokeColor = .clear
        glow.glowWidth = 10
        glow.name = "wordGardenLantern"
        lantern.addChild(glow)

        let hanger = SKShapeNode(rectOf: CGSize(width: 5, height: 28), cornerRadius: 2)
        hanger.fillColor = UIColor(red: 0.34, green: 0.55, blue: 0.28, alpha: 1)
        hanger.strokeColor = .clear
        hanger.position = CGPoint(x: 0, y: 38)
        hanger.name = "wordGardenLantern"
        lantern.addChild(hanger)

        let body = SKShapeNode(rectOf: CGSize(width: 56, height: 66), cornerRadius: 18)
        body.fillColor = UIColor(red: 0.22, green: 0.34, blue: 0.21, alpha: 0.96)
        body.strokeColor = UIColor(red: 1.0, green: 0.64, blue: 0.80, alpha: 1)
        body.lineWidth = 3
        body.name = "wordGardenLantern"
        lantern.addChild(body)

        let flower = ArtSystem.label("✿", size: 32)
        flower.fontColor = UIColor(red: 1.0, green: 0.76, blue: 0.88, alpha: 1)
        flower.name = "wordGardenLantern"
        lantern.addChild(flower)

        if !reducedMotion {
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.45, duration: 1.0),
                .fadeAlpha(to: 1.0, duration: 1.0)
            ])))
        }

        addChild(lantern)
        wordGardenLanternNode = lantern
    }

    private func renderPuzzlePalaceLantern() {
        puzzlePalaceLanternNode?.removeFromParent()
        puzzlePalaceLanternNode = nil

        guard state.hasStoryReward(.puzzlePalaceLantern),
              !puzzlePalaceLanternSlots.isEmpty else { return }

        let slot = state.storyRewardPlacement(.puzzlePalaceLantern)
            % puzzlePalaceLanternSlots.count
        let lantern = SKNode()
        lantern.name = "puzzlePalaceLantern"
        lantern.position = puzzlePalaceLanternSlots[slot]
        lantern.zPosition = 905

        let glow = SKShapeNode(circleOfRadius: 50)
        glow.fillColor = UIColor(red: 0.62, green: 0.50, blue: 0.94, alpha: 0.18)
        glow.strokeColor = .clear
        glow.glowWidth = 12
        glow.name = "puzzlePalaceLantern"
        lantern.addChild(glow)

        let hanger = SKShapeNode(rectOf: CGSize(width: 5, height: 28), cornerRadius: 2)
        hanger.fillColor = UIColor(red: 0.42, green: 0.35, blue: 0.61, alpha: 1)
        hanger.strokeColor = .clear
        hanger.position = CGPoint(x: 0, y: 38)
        hanger.name = "puzzlePalaceLantern"
        lantern.addChild(hanger)

        let body = SKShapeNode(rectOf: CGSize(width: 58, height: 66), cornerRadius: 18)
        body.fillColor = UIColor(red: 0.18, green: 0.15, blue: 0.34, alpha: 0.97)
        body.strokeColor = UIColor(red: 0.72, green: 0.62, blue: 1.0, alpha: 1)
        body.lineWidth = 3
        body.name = "puzzlePalaceLantern"
        lantern.addChild(body)

        let mark = ArtSystem.label("◈", size: 31)
        mark.fontColor = UIColor(red: 0.88, green: 0.82, blue: 1.0, alpha: 1)
        mark.name = "puzzlePalaceLantern"
        lantern.addChild(mark)

        if !reducedMotion {
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.42, duration: 1.05),
                .fadeAlpha(to: 1.0, duration: 1.05)
            ])))
        }

        addChild(lantern)
        puzzlePalaceLanternNode = lantern
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        defer {
            activeTouch = nil
            moved = false
        }

        let point = touch.location(in: self)
        guard !moved, hypot(point.x - touchStart.x, point.y - touchStart.y) <= 12 else {
            return
        }
        handleTap(at: point)
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let start = nearestWaypoint(to: valkyrie.position)
        let end = nearestWaypoint(to: destination)
        let indices = start <= end
            ? Array(start...end)
            : Array((end...start).reversed())
        follow(indices, forward: start <= end, completion: action)
    }

    private func follow(
        _ indices: [Int],
        forward: Bool,
        completion: (() -> Void)?
    ) {
        guard let first = indices.first else {
            completion?()
            return
        }

        super.travel(to: route[first]) { [weak self] in
            self?.follow(
                Array(indices.dropFirst()),
                forward: forward,
                completion: completion
            )
        }

        let behind = max(
            0,
            min(route.count - 1, first + (forward ? -1 : 1))
        )
        let point = behind == first
            ? CGPoint(x: route[first].x + 35, y: route[first].y + 25)
            : route[behind]
        pip.walk(to: point) {}
    }

    private func nearestWaypoint(to point: CGPoint) -> Int {
        route.indices.min {
            hypot(route[$0].x - point.x, route[$0].y - point.y)
                < hypot(route[$1].x - point.x, route[$1].y - point.y)
        } ?? 0
    }

    func isOnPath(_ point: CGPoint) -> Bool {
        for (a, b) in zip(route, route.dropFirst()) {
            let dx = b.x - a.x
            let dy = b.y - a.y
            let lengthSquared = dx * dx + dy * dy
            guard lengthSquared > 0 else { continue }

            let t = max(
                0,
                min(
                    1,
                    ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared
                )
            )
            if hypot(
                point.x - (a.x + t * dx),
                point.y - (a.y + t * dy)
            ) <= 38 {
                return true
            }
        }
        return false
    }

    override func walkIfValid(_ point: CGPoint) {
        if isOnPath(point) {
            travel(to: point)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let depth = max(0, min(1, (valkyrie.position.y - 170) / 280))
        valkyrie.setScale(1 - depth * 0.42)
        pip.setScale(1 - depth * 0.42)
    }

    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "wordGarden":
            selectionFeedback()
            let destination = CGPoint(x: 190, y: 170)
            if isNear(destination) {
                state.travel(to: .wordGarden)
            } else {
                instruction.text = "Follow the path to the garden light."
                travel(to: destination)
            }

        case "castle":
            selectionFeedback()
            let destination = CGPoint(x: 795, y: 450)
            if isNear(destination) {
                state.travel(to: .mathCastle)
            } else {
                instruction.text = "Follow the bridge toward the castle light."
                travel(to: destination)
            }

        case "scienceLab":
            selectionFeedback()
            let destination = CGPoint(x: 580, y: 450)
            if isNear(destination) {
                state.enterScienceLab()
            } else {
                instruction.text = "Follow the upper path toward Milo's green light."
                travel(to: destination)
            }

        case "puzzlePalace":
            selectionFeedback()
            let destination = CGPoint(x: 580, y: 450)
            if isNear(destination) {
                state.travel(to: .puzzlePalace)
            } else {
                instruction.text = "Follow the upper path toward Tiko's violet light."
                travel(to: destination)
            }

        case "pipWind":
            travel(to: CGPoint(x: 285, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration()
                self.instruction.text = "Pip's little gears are ready. Where shall we go?"
                self.state.audio.play("gear")
            }

        case "storyLight":
            travel(to: CGPoint(x: 385, y: 275)) { [weak self] in
                self?.valkyrie.pose(.interact)
                self?.instruction.text = "A little light. A big adventure. Pip is ready to help."
            }

        case "moonLantern":
            selectionFeedback()
            guard state.hasStoryReward(.moonLantern) else { return }
            _ = state.cycleStoryRewardPlacement(
                .moonLantern,
                slotCount: moonLanternSlots.count
            )
            renderMoonLantern()
            state.audio.play("success")
            valkyrie.pose(.interact)
            instruction.text = "The Moon Lantern found a new branch."

        case "wordGardenLantern":
            selectionFeedback()
            guard state.hasStoryReward(.wordGardenLantern) else { return }
            _ = state.cycleStoryRewardPlacement(
                .wordGardenLantern,
                slotCount: wordGardenLanternSlots.count
            )
            renderWordGardenLantern()
            state.audio.play("success")
            valkyrie.pose(.interact)
            instruction.text = "The Flower Lantern found a new branch."

        case "puzzlePalaceLantern":
            selectionFeedback()
            guard state.hasStoryReward(.puzzlePalaceLantern) else { return }
            _ = state.cycleStoryRewardPlacement(
                .puzzlePalaceLantern,
                slotCount: puzzlePalaceLanternSlots.count
            )
            renderPuzzlePalaceLantern()
            state.audio.play("success")
            valkyrie.pose(.interact)
            instruction.text = "Tiko's Palace Lantern found a new branch."

        default:
            walkIfValid(point)
        }
    }
}
