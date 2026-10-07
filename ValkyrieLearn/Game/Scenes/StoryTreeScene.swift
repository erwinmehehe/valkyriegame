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

    private var travelGeneration = 0
    private var pendingEntrance: String?
    private var hasLeft = false

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
        pip.position = CGPoint(x: 250, y: 210)
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
        hasLeft = true
        travelGeneration += 1
        pendingEntrance = nil
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
        _ = destinationMarker(
            "Word Garden",
            symbol: "✿",
            name: "wordGarden",
            at: CGPoint(x: 150, y: 430),
            tint: UIColor(red: 0.95, green: 0.48, blue: 0.72, alpha: 1),
            width: 150,
            plaqueOffsetY: 72
        )

        _ = destinationMarker(
            "Puzzle Palace",
            symbol: "◈",
            name: "puzzlePalace",
            at: CGPoint(x: 505, y: 515),
            tint: UIColor(red: 0.62, green: 0.50, blue: 0.94, alpha: 1),
            width: 168
        )

        _ = destinationMarker(
            "Math Castle",
            symbol: "◆",
            name: "castle",
            at: CGPoint(x: 835, y: 535),
            tint: UIColor(red: 0.95, green: 0.70, blue: 0.28, alpha: 1),
            width: 160
        )

        _ = destinationMarker(
            state.scienceAdventure.groveRestored ? "Science Lab ✦" : "Science Lab",
            symbol: "⚗",
            name: "scienceLab",
            at: CGPoint(x: 705, y: 585),
            tint: UIColor(red: 0.42, green: 0.82, blue: 0.61, alpha: 1),
            width: 164
        )

        _ = worldGear("✦", name: "pipWind", at: CGPoint(x: 315, y: 260), radius: 34)

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
        glow.userData = NSMutableDictionary(dictionary: ["decorativeMotionRole": "pulse"])
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
            ])), withKey: "ambientPulse")
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
        glow.userData = NSMutableDictionary(dictionary: ["decorativeMotionRole": "pulse"])
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
            ])), withKey: "ambientPulse")
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
        glow.userData = NSMutableDictionary(dictionary: ["decorativeMotionRole": "pulse"])
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
            ])), withKey: "ambientPulse")
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

    // Project taps onto the painted route rather than snapping to the nearest
    // waypoint. Reversing direction midway through a bridge should not overshoot.
    private func routeProjection(_ point: CGPoint) -> (point: CGPoint, progress: CGFloat) {
        var best = (point: route[0], progress: CGFloat.zero)
        var bestDistance = CGFloat.greatestFiniteMagnitude
        for index in 0..<(route.count - 1) {
            let a = route[index], b = route[index + 1]
            let dx = b.x - a.x, dy = b.y - a.y
            let lengthSquared = dx * dx + dy * dy
            guard lengthSquared > 0 else { continue }
            let t = max(0, min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / lengthSquared))
            let projected = CGPoint(x: a.x + t * dx, y: a.y + t * dy)
            let distance = hypot(point.x - projected.x, point.y - projected.y)
            if distance < bestDistance {
                bestDistance = distance
                best = (projected, CGFloat(index) + t)
            }
        }
        return best
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        guard !hasLeft else { return }
        travelGeneration += 1
        let generation = travelGeneration
        valkyrie.cancelTravel()
        pip.cancelTravel()
        let start = routeProjection(valkyrie.position)
        let end = routeProjection(destination)
        let forward = start.progress <= end.progress
        let between = route.indices.filter {
            CGFloat($0) > min(start.progress, end.progress)
                && CGFloat($0) < max(start.progress, end.progress)
        }
        var points = forward ? between.map { route[$0] } : between.reversed().map { route[$0] }
        if hypot(valkyrie.position.x - start.point.x, valkyrie.position.y - start.point.y) > 1 {
            points.insert(start.point, at: 0)
        }
        points.append(end.point)
        showAttentionCue(at: end.point, width: 70)
        follow(points, generation: generation, completion: action)
    }

    private func follow(_ points: [CGPoint], generation: Int, completion: (() -> Void)?) {
        guard !hasLeft, generation == travelGeneration else { return }
        guard let first = points.first else {
            clearAttentionCue()
            completion?()
            return
        }
        super.travel(to: first) { [weak self] in
            self?.follow(Array(points.dropFirst()), generation: generation, completion: completion)
        }
        // Keep Pip on the same traversable surface, behind Valkyrie's last step.
        pip.walk(to: routeProjection(valkyrie.position).point) {}
    }

    func isOnPath(_ point: CGPoint) -> Bool {
        let projected = routeProjection(point).point
        return hypot(point.x - projected.x, point.y - projected.y) <= 38
    }

    override func walkIfValid(_ point: CGPoint) {
        if isOnPath(point) {
            pendingEntrance = nil
            travel(to: point)
        }
    }

    private func enterWorld(
        named name: String,
        destination: CGPoint,
        instruction text: String,
        action: @escaping () -> Void
    ) {
        // Repeated taps on the selected beacon must not restart the journey.
        guard !hasLeft, pendingEntrance != name else { return }
        selectionFeedback()
        pendingEntrance = name
        instruction.text = text
        let enter = { [weak self] in
            guard let self, !self.hasLeft, self.pendingEntrance == name else { return }
            self.pendingEntrance = nil
            action()
        }
        if isNear(destination) {
            // Cancel any remaining companion action before changing worlds.
            travelGeneration += 1
            valkyrie.cancelTravel()
            pip.cancelTravel()
            clearAttentionCue()
            enter()
        } else {
            travel(to: destination, then: enter)
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
            enterWorld(named: "wordGarden", destination: CGPoint(x: 190, y: 170),
                       instruction: "Valkyrie is on her way to Word Garden.") { [weak self] in
                self?.state.travel(to: .wordGarden)
            }

        case "castle":
            enterWorld(named: "castle", destination: CGPoint(x: 795, y: 450),
                       instruction: "Across the bridge! Pip is coming to Math Castle.") { [weak self] in
                self?.state.travel(to: .mathCastle)
            }

        case "scienceLab":
            enterWorld(named: "scienceLab", destination: CGPoint(x: 580, y: 450),
                       instruction: "Follow the green light. Milo is waiting.") { [weak self] in
                self?.state.enterScienceLab()
            }

        case "puzzlePalace":
            enterWorld(named: "puzzlePalace", destination: CGPoint(x: 580, y: 450),
                       instruction: "Follow the violet light. Tiko is waiting.") { [weak self] in
                self?.state.travel(to: .puzzlePalace)
            }

        case "pipWind":
            pendingEntrance = nil
            travel(to: CGPoint(x: 285, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration()
                self.instruction.text = "Pip's little gears are ready. Where shall we go?"
                self.state.audio.play("gear")
            }

        case "storyLight":
            pendingEntrance = nil
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
