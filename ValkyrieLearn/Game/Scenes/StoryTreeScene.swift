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
        activeTouch = nil
        moved = false
        super.willLeave()
    }

    override func buildWorld() {
        super.buildWorld()

        // World entrances are environmental beacons, not generic navigation buttons.
        // Keep them visually offset from the painted travel route so Valkyrie never
        // stands on top of a label while approaching a destination.
        _ = destinationMarker(
            "Word Garden",
            symbol: "✿",
            name: "wordGarden",
            at: CGPoint(x: 150, y: 255),
            tint: UIColor(red: 0.95, green: 0.48, blue: 0.72, alpha: 1),
            width: 150
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

        if state.hasStoryReward(.moonLantern) && state.hasStoryReward(.wordGardenLantern) {
            instruction.text = "Your lanterns are glowing. Choose where Valkyrie explores next."
        } else if state.hasStoryReward(.wordGardenLantern) {
            instruction.text = "The Flower Lantern is home. Choose the next adventure."
        } else if state.hasStoryReward(.moonLantern) {
            instruction.text = "The Moon Lantern is home. Choose the next adventure."
        } else {
            instruction.text = "The Story Tree needs starlight. Choose a world to explore."
        }
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
            let destination = CGPoint(x: 190, y: 170)
            if isNear(destination) {
                state.travel(to: .wordGarden)
            } else {
                instruction.text = "Follow the path to the garden light."
                travel(to: destination)
            }

        case "castle":
            let destination = CGPoint(x: 795, y: 450)
            if isNear(destination) {
                state.travel(to: .mathCastle)
            } else {
                instruction.text = "Follow the bridge toward the castle light."
                travel(to: destination)
            }

        case "scienceLab":
            let destination = CGPoint(x: 580, y: 450)
            if isNear(destination) {
                state.enterScienceLab()
            } else {
                instruction.text = "Follow the upper path toward Milo's green light."
                travel(to: destination)
            }

        case "puzzlePalace":
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
            guard state.hasStoryReward(.wordGardenLantern) else { return }
            _ = state.cycleStoryRewardPlacement(
                .wordGardenLantern,
                slotCount: wordGardenLanternSlots.count
            )
            renderWordGardenLantern()
            state.audio.play("success")
            valkyrie.pose(.interact)
            instruction.text = "The Flower Lantern found a new branch."

        default:
            walkIfValid(point)
        }
    }
}
