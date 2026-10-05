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

        let gardenSign = hotspot(
            "Word Garden ↖",
            name: "wordGarden",
            at: CGPoint(x: 580, y: 515),
            size: CGSize(width: 205, height: 54)
        )
        gardenSign.zPosition = 535
        let gardenPost = ArtSystem.box(
            CGSize(width: 14, height: 82),
            color: .init(red: 0.34, green: 0.30, blue: 0.13, alpha: 1),
            radius: 3
        )
        gardenPost.position.y = -58
        gardenPost.zPosition = -1
        gardenSign.addChild(gardenPost)

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
            ? "The Story Tree grew a Moon Lantern. Choose Word Garden or Math Castle."
            : "Two paths are awake: Word Garden with Lumi, or Pip's Math Castle."
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
            let destination = CGPoint(x: 580, y: 450)
            if isNear(destination) {
                state.travel(to: .wordGarden)
            } else {
                instruction.text = "Follow the upper path to Lumi's Word Garden sign."
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


@MainActor final class WordGardenScene: AdventureScene {
    override var worldTitle: String { "Word Garden · Flower Gate" }
    override var walkable: CGRect { CGRect(x: 110, y: 120, width: 930, height: 115) }

    let lumi = LumiNode()
    private var currentEncounter: WordGardenEncounter?
    private var attempts = 0
    private var acceptingLetterInput = false
    private var gatePowered = false
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false
    private var targetRune: SKNode?
    private var gateGlow: SKShapeNode?
    private var flowerTouches = 0

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.isHidden = true
        valkyrie.position = CGPoint(x: 175, y: 158)
        valkyrie.setScale(0.58)

        lumi.position = CGPoint(x: 275, y: 225)
        lumi.zPosition = 860
        lumi.reducedMotion = reducedMotion
        lumi.hover()
        addChild(lumi)

        loadEncounter()
    }

    override func buildWorld() {
        if let backdrop = ArtSystem.sprite("StarlightIsles", size: size) {
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            backdrop.color = UIColor(red: 0.42, green: 0.88, blue: 0.54, alpha: 1)
            backdrop.colorBlendFactor = 0.18
            addChild(backdrop)
        } else {
            backgroundColor = UIColor(red: 0.20, green: 0.45, blue: 0.34, alpha: 1)
        }

        let meadow = ArtSystem.box(
            CGSize(width: 1280, height: 205),
            color: UIColor(red: 0.12, green: 0.31, blue: 0.18, alpha: 0.66),
            radius: 0
        )
        meadow.position = CGPoint(x: 640, y: 102)
        meadow.strokeColor = .clear
        meadow.zPosition = 60
        addChild(meadow)

        let path = SKShapeNode(rectOf: CGSize(width: 930, height: 88), cornerRadius: 42)
        path.fillColor = UIColor(red: 0.67, green: 0.51, blue: 0.29, alpha: 0.72)
        path.strokeColor = UIColor(red: 0.94, green: 0.81, blue: 0.47, alpha: 0.72)
        path.lineWidth = 4
        path.position = CGPoint(x: 570, y: 168)
        path.zPosition = 70
        addChild(path)

        for (x, y, scale) in [
            (CGFloat(115), CGFloat(275), CGFloat(0.86)),
            (CGFloat(220), CGFloat(330), CGFloat(0.68)),
            (CGFloat(835), CGFloat(320), CGFloat(0.72)),
            (CGFloat(930), CGFloat(285), CGFloat(0.65))
        ] {
            if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 100 * scale, height: 106 * scale)) {
                bloom.position = CGPoint(x: x, y: y)
                bloom.zPosition = 180
                addChild(bloom)
            }
        }

        buildFlowerGate()
        buildSoundFlowers()

        _ = worldControl("⌂", name: "home", at: CGPoint(x: 52, y: 669), radius: 31)
    }

    private func buildFlowerGate() {
        let arch = CGMutablePath()
        arch.move(to: CGPoint(x: -72, y: -112))
        arch.addLine(to: CGPoint(x: -72, y: 16))
        arch.addQuadCurve(
            to: CGPoint(x: 72, y: 16),
            control: CGPoint(x: 0, y: 138)
        )
        arch.addLine(to: CGPoint(x: 72, y: -112))

        let gate = SKShapeNode(path: arch)
        gate.strokeColor = UIColor(red: 0.25, green: 0.57, blue: 0.25, alpha: 1)
        gate.lineWidth = 17
        gate.lineCap = .round
        gate.position = CGPoint(x: 1060, y: 282)
        gate.zPosition = 210
        gate.name = "wordGate"
        addChild(gate)

        let inner = SKShapeNode(path: arch)
        inner.strokeColor = UIColor(red: 0.96, green: 0.73, blue: 0.30, alpha: 0.75)
        inner.lineWidth = 4
        inner.glowWidth = 5
        inner.name = "wordGate"
        gate.addChild(inner)

        for offset in [
            CGPoint(x: -72, y: 35),
            CGPoint(x: -48, y: 88),
            CGPoint(x: 0, y: 122),
            CGPoint(x: 48, y: 88),
            CGPoint(x: 72, y: 35)
        ] {
            if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 52, height: 55)) {
                bloom.position = offset
                bloom.setScale(0.72)
                bloom.name = "wordGate"
                gate.addChild(bloom)
            }
        }

        let glow = SKShapeNode(circleOfRadius: 66)
        glow.fillColor = UIColor(red: 1.0, green: 0.79, blue: 0.29, alpha: 0.04)
        glow.strokeColor = .clear
        glow.glowWidth = 18
        glow.position = CGPoint(x: 1060, y: 322)
        glow.zPosition = 195
        glow.alpha = 0.2
        glow.name = "wordGate"
        addChild(glow)
        gateGlow = glow

        let high = SKShapeNode(circleOfRadius: 35)
        high.fillColor = UIColor(red: 0.86, green: 0.43, blue: 0.75, alpha: 0.35)
        high.strokeColor = UIColor(red: 1, green: 0.86, blue: 0.43, alpha: 0.9)
        high.lineWidth = 3
        high.glowWidth = 8
        high.position = CGPoint(x: 1015, y: 475)
        high.zPosition = 260
        high.name = "lumiReach"
        let star = ArtSystem.label("✦", size: 28)
        star.name = "lumiReach"
        high.addChild(star)
        addChild(high)
    }

    private func buildSoundFlowers() {
        let points = [
            CGPoint(x: 360, y: 315),
            CGPoint(x: 520, y: 350),
            CGPoint(x: 690, y: 315)
        ]

        for (index, point) in points.enumerated() {
            let flower = SKNode()
            flower.position = point
            flower.zPosition = 300
            flower.name = "soundFlower:\(index)"

            if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 92, height: 98)) {
                bloom.name = flower.name
                flower.addChild(bloom)
            } else {
                let fallback = SKShapeNode(circleOfRadius: 42)
                fallback.fillColor = UIColor(red: 0.93, green: 0.42, blue: 0.66, alpha: 1)
                fallback.strokeColor = UIColor(red: 1, green: 0.85, blue: 0.42, alpha: 1)
                fallback.lineWidth = 3
                fallback.name = flower.name
                flower.addChild(fallback)
            }

            let center = SKShapeNode(circleOfRadius: 18)
            center.fillColor = UIColor(red: 1, green: 0.82, blue: 0.34, alpha: 0.88)
            center.strokeColor = .clear
            center.name = flower.name
            flower.addChild(center)
            addChild(flower)
        }
    }

    private func makeLetterStone(_ glyph: String, at point: CGPoint) -> SKNode {
        let stone = SKShapeNode(rectOf: CGSize(width: 122, height: 76), cornerRadius: 26)
        stone.fillColor = UIColor(red: 0.34, green: 0.29, blue: 0.45, alpha: 0.96)
        stone.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.39, alpha: 0.92)
        stone.lineWidth = 4
        stone.position = point
        stone.zPosition = 450
        stone.name = "letterStone:\(glyph)"

        let letter = ArtSystem.label(glyph, size: 40)
        letter.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
        letter.name = stone.name
        stone.addChild(letter)
        addChild(stone)
        return stone
    }

    func loadEncounter() {
        enumerateChildNodes(withName: "//letterStone:*") { node, _ in node.removeFromParent() }
        targetRune?.removeFromParent()
        targetRune = nil
        attempts = 0
        acceptingLetterInput = false
        gatePowered = false
        gateGlow?.alpha = 0.2

        guard let encounter = state.nextWordGardenEncounter() else {
            currentEncounter = nil
            instruction.text = "The letter stones are resting. Explore the flowers with Lumi."
            return
        }

        currentEncounter = encounter
        let stoneX: [CGFloat] = [470, 635, 800]
        for (choice, x) in zip(encounter.choices, stoneX) {
            _ = makeLetterStone(choice, at: CGPoint(x: x, y: 160))
        }
        showTargetRune()
    }

    private func showTargetRune() {
        guard let encounter = currentEncounter else { return }
        acceptingLetterInput = false
        targetRune?.removeFromParent()

        let target = SKShapeNode(circleOfRadius: 54)
        target.fillColor = UIColor(red: 0.39, green: 0.25, blue: 0.56, alpha: 0.92)
        target.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
        target.lineWidth = 4
        target.glowWidth = 10
        target.position = CGPoint(x: 635, y: 330)
        target.zPosition = 700
        target.name = "targetRune"

        let letter = ArtSystem.label(encounter.correctChoice, size: 52)
        letter.fontColor = UIColor(red: 1, green: 0.96, blue: 0.80, alpha: 1)
        target.addChild(letter)
        addChild(target)
        targetRune = target

        instruction.text = encounter.prompt

        run(
            .sequence([
                .wait(forDuration: 1.15),
                .run { [weak self, weak target] in
                    target?.isHidden = true
                    self?.acceptingLetterInput = true
                    self?.instruction.text = "Which letter stone matches the rune you saw?"
                }
            ]),
            withKey: "letterPreview"
        )
    }

    func chooseLetter(_ glyph: String) {
        guard acceptingLetterInput,
              !gatePowered,
              let encounter = currentEncounter,
              encounter.choices.contains(glyph) else { return }

        attempts += 1
        let evidence = state.recordWordGardenAttempt(
            encounter: encounter,
            choice: glyph,
            attempts: attempts
        )

        guard let stone = childNode(withName: "//letterStone:\(glyph)") as? SKShapeNode else { return }

        if evidence.outcome == .correct {
            acceptingLetterInput = false
            gatePowered = true
            stone.glowWidth = 16
            stone.fillColor = UIColor(red: 0.32, green: 0.56, blue: 0.28, alpha: 1)
            gateGlow?.alpha = 1.0
            valkyrie.pose(.celebrate)
            lumi.celebrate()
            state.audio.play("success")
            instruction.text = "The Flower Gate remembers that rune. Tap the glowing gate for another."
        } else {
            stone.run(.sequence([
                .rotate(toAngle: -0.08, duration: reducedMotion ? 0 : 0.10),
                .rotate(toAngle: 0.08, duration: reducedMotion ? 0 : 0.10),
                .rotate(toAngle: 0, duration: reducedMotion ? 0 : 0.12)
            ]))
            valkyrie.pose(.react)
            lumi.react()
            instruction.text = "That stone does not match. Watch the rune once more."
            showTargetRune()
        }
    }

    private func activateSoundFlower(_ name: String) {
        guard let flower = childNode(withName: "//\(name)") else { return }
        flowerTouches += 1
        flower.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.12, duration: 0.16),
            .scale(to: 1.0, duration: 0.20)
        ]))
        state.audio.play("crystal")
        lumi.react()
        instruction.text = flowerTouches >= 2
            ? "The Sound Flowers are awake, but their word-songs are still sleeping. Lumi can help with the high bloom."
            : "A Sound Flower answers with a gentle chime. Try another, or ask Lumi to reach the high bloom."
    }

    private func useLumiReach() {
        let bloomPoint = CGPoint(x: 1015, y: 475)
        instruction.text = "Lumi can reach what Valkyrie cannot."
        lumi.reach(to: bloomPoint, in: self) { [weak self] in
            guard let self else { return }
            self.state.audio.play("success")
            self.instruction.text = "Lumi woke the high bloom. The Flower Gate is listening."
        }
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
        if hypot(point.x - touchStart.x, point.y - touchStart.y) > 12 { moved = true }
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

    func handleTap(at point: CGPoint) {
        guard let name = targetName(at: point) else {
            walkIfValid(point)
            return
        }

        if name.hasPrefix("letterStone:") {
            let glyph = String(name.dropFirst("letterStone:".count))
            let approach = CGPoint(x: point.x, y: 165)
            travel(to: approach) { [weak self] in self?.chooseLetter(glyph) }
            return
        }

        if name.hasPrefix("soundFlower:") {
            let approach = CGPoint(x: point.x, y: 190)
            travel(to: approach) { [weak self] in self?.activateSoundFlower(name) }
            return
        }

        switch name {
        case "home":
            state.travel(to: .storyTree)

        case "lumiReach":
            travel(to: CGPoint(x: 900, y: 185)) { [weak self] in self?.useLumiReach() }

        case "wordGate":
            if gatePowered {
                loadEncounter()
            } else {
                instruction.text = "The Flower Gate needs a matching letter stone first."
            }

        default:
            walkIfValid(point)
        }
    }

    override func willLeave() {
        activeTouch = nil
        removeAction(forKey: "letterPreview")
        lumi.removeAllActions()
        super.willLeave()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        lumi.zPosition = 1005 - lumi.position.y
    }
}
