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
    private let moonLanternSlots = [
        CGPoint(x: 295, y: 500),
        CGPoint(x: 390, y: 555),
        CGPoint(x: 485, y: 500)
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

        let gardenSign = hotspot(
            "← Word Garden",
            name: "wordGarden",
            at: CGPoint(x: 205, y: 165),
            size: CGSize(width: 210, height: 56)
        )
        gardenSign.zPosition = 820

        let sign = hotspot(
            "Math Castle →",
            name: "castle",
            at: CGPoint(x: 795, y: 445),
            size: CGSize(width: 210, height: 56)
        )
        // Arrival feet are at y = 450 (actor depth 550); keep the sign behind them.
        sign.zPosition = 540
        let post = ArtSystem.box(
            CGSize(width: 15, height: 95),
            color: .init(red: 0.39, green: 0.24, blue: 0.12, alpha: 1),
            radius: 3
        )
        post.position.y = -64
        post.zPosition = -1
        sign.addChild(post)

        let scienceSign = hotspot(
            "Science Lab →",
            name: "scienceLab",
            at: CGPoint(x: 580, y: 515),
            size: CGSize(width: 205, height: 54)
        )
        scienceSign.zPosition = 535
        let sciencePost = ArtSystem.box(
            CGSize(width: 14, height: 88),
            color: .init(red: 0.24, green: 0.39, blue: 0.25, alpha: 1),
            radius: 3
        )
        sciencePost.position.y = -60
        sciencePost.zPosition = -1
        scienceSign.addChild(sciencePost)

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

        instruction.text = state.hasStoryReward(.moonLantern)
            ? "The Story Tree grew a Moon Lantern. Math Castle and Science Lab paths are open."
            : "The Story Tree is waiting for its starlight. Math Castle and Science Lab are ready to explore."
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
                instruction.text = "Walk back to the garden path, then tap the sign to enter."
                travel(to: destination)
            }

        case "castle":
            let destination = CGPoint(x: 795, y: 450)
            if isNear(destination) {
                state.travel(to: .mathCastle)
            } else {
                instruction.text = "Walk to the castle sign, then tap it to enter."
                travel(to: destination)
            }

        case "scienceLab":
            let destination = CGPoint(x: 580, y: 450)
            if isNear(destination) {
                state.enterScienceLab()
            } else {
                instruction.text = "Walk to the Science Lab sign, then tap it to enter the Greenhouse."
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

        default:
            walkIfValid(point)
        }
    }
}
