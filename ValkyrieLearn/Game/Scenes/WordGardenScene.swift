import SpriteKit
import LearningCore

@MainActor final class WordGardenScene: AdventureScene {
    override var worldTitle: String { "Word Garden · Flower Gate" }
    override var walkable: CGRect { CGRect(x: 105, y: 128, width: 1020, height: 145) }

    private let lumi = LumiNode()
    private var encounter: LiteracyEncounter!
    private var attempts = 0
    private var support: SupportLevel = .independent
    private var startedAt = Date()
    private var solved = false
    private var acceptingChoices = false
    private var interactionInFlight = false
    private var hasLeftScene = false
    private var targetRune: SKNode?
    private let flowerPoints = [
        CGPoint(x: 505, y: 245), CGPoint(x: 675, y: 280),
        CGPoint(x: 840, y: 240), CGPoint(x: 995, y: 285)
    ]

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.removeFromParent()
        encounter = state.nextLiteracyEncounter()
        valkyrie.setScale(0.5)
        lumi.setScale(0.65)
        valkyrie.position = CGPoint(x: 220, y: 175)
        lumi.position = CGPoint(x: 335, y: 190)
        lumi.reducedMotion = reducedMotion
        addChild(lumi)
        buildEncounter()
        if flowerGateComplete { finishFlowerGate() }
    }

    override func buildWorld() {
        // The embedded 320x180 preview atlas cannot support a full iPad scene.
        // Use the original approved source; inset the crop to avoid grid seams.
        if let atlas = ArtSystem.texture("WordGardenSourceAtlas") {
            let wordTexture = SKTexture(rect: CGRect(x: 0, y: 0.502, width: 0.499, height: 0.498), in: atlas)
            wordTexture.filteringMode = .linear
            let backdrop = SKSpriteNode(texture: wordTexture, color: .white, size: size)
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            addChild(backdrop)
        }

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

        let gate = SKShapeNode(rectOf: CGSize(width: 150, height: 260), cornerRadius: 65)
        gate.fillColor = .clear
        gate.strokeColor = .clear
        gate.lineWidth = 10
        gate.position = CGPoint(x: 1160, y: 400)
        gate.name = "flowerGate"
        gate.zPosition = 300
        addChild(gate)

        // Timber supports and winding vines give the destination a physical frame.
        for x in [CGFloat(-62), CGFloat(62)] {
            if let post = ArtSystem.sprite("BridgeTimber", size: CGSize(width: 18, height: 230)) {
                post.position = CGPoint(x: x, y: -10)
                gate.addChild(post)
            }
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: -120))
            path.addCurve(to: CGPoint(x: x * 0.7, y: 110),
                          control1: CGPoint(x: x - 16, y: -35),
                          control2: CGPoint(x: x + 16, y: 45))
            let vine = SKShapeNode(path: path)
            vine.strokeColor = UIColor(red: 0.25, green: 0.43, blue: 0.20, alpha: 1)
            vine.lineWidth = 6
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

        buildSoundFlowers()

        let home = worldControl("⌂", name: "home", at: CGPoint(x: 52, y: 669), radius: 26)
        home.zPosition = 2100
    }

    private var flowerGateComplete: Bool {
        let completed = Set(state.profile.progress(for: LiteracySkills.visualLetterMatch).evidence
            .filter { $0.outcome == .correct }.map(\.encounterID))
        return WordGardenEncounterCatalog.visualLetterShapes.allSatisfy { completed.contains($0.id) }
    }

    private func finishFlowerGate() {
        solved = true
        acceptingChoices = false
        removeAction(forKey: "wordGardenPreview")
        removeAction(forKey: "nextLiteracyEncounter")
        targetRune?.isHidden = true
        (childNode(withName: "flowerGate") as? SKShapeNode)?.glowWidth = 16
        childNode(withName: "questionPrompt")?.isHidden = true
        instruction.text = "You explored all three flower runes. Enjoy the Sound Flowers, or return to Story Tree."
    }

    private func buildEncounter() {
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        acceptingChoices = false
        targetRune?.removeFromParent()
        targetRune = nil
        instruction.text = encounter.prompt

        childNode(withName: "questionPrompt")?.removeFromParent()
        let prompt = ArtSystem.label(encounter.prompt, size: 25)
        prompt.name = "questionPrompt"
        prompt.position = CGPoint(x: 640, y: 610)
        prompt.preferredMaxLayoutWidth = 850
        prompt.numberOfLines = 2
        prompt.zPosition = 2000
        addChild(prompt)

        enumerateChildNodes(withName: "flowerChoice") { node, _ in node.removeFromParent() }
        for (index, choice) in encounter.choices.enumerated() {
            let flower = flowerNode(letter: choice, index: index)
            flower.position = flowerPoints[index]
            flower.name = "flowerChoice"
            flower.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(flower)
        }
        showTargetRune()
    }

    private func showTargetRune(retryMessage: String? = nil) {
        acceptingChoices = false
        targetRune?.removeFromParent()

        let rune = SKShapeNode(rectOf: CGSize(width: 100, height: 42), cornerRadius: 8)
        rune.fillColor = .white
        rune.fillTexture = ArtSystem.texture("BridgeWorkOrder")
        rune.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
        rune.lineWidth = 2
        rune.glowWidth = 3
        rune.position = CGPoint(x: 1160, y: 430)
        rune.zPosition = 2010
        rune.name = "targetRune"

        let glyph = ArtSystem.label(encounter.answer, size: 30)
        glyph.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
        rune.addChild(glyph)
        for x in [CGFloat(-35), CGFloat(35)] {
            let ropePath = CGMutablePath()
            ropePath.move(to: CGPoint(x: x, y: 20))
            ropePath.addLine(to: CGPoint(x: x, y: 75))
            let rope = SKShapeNode(path: ropePath)
            rope.strokeColor = UIColor(red: 0.56, green: 0.40, blue: 0.22, alpha: 1)
            rope.lineWidth = 3
            rune.addChild(rope)
        }
        addChild(rune)
        targetRune = rune

        instruction.text = retryMessage ?? encounter.prompt
        removeAction(forKey: "wordGardenPreview")
        run(
            .sequence([
                .wait(forDuration: 1.15),
                .run { [weak self, weak rune] in
                    rune?.isHidden = true
                    self?.acceptingChoices = true
                    self?.instruction.text = "Which flower matches the rune you saw?"
                }
            ]),
            withKey: "wordGardenPreview"
        )
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
        let name = targetName(at: point)
        if name == "home" {
            willLeave()
            state.travel(to: .storyTree)
            return
        }
        guard !interactionInFlight else { return }
        if name == "soundFlower", let flower = soundFlower(at: point) {
            interactionInFlight = true
            let destination = CGPoint(x: max(170, flower.position.x - 80), y: 180)
            valkyrie.walk(to: destination) { [weak self, weak flower] in
                guard let self, let flower, !self.hasLeftScene else { return }
                self.interactionInFlight = false
                self.activateSoundFlower(flower)
            }
            return
        }
        if name == "flowerChoice", let choice = choice(at: point), let flower = choice.node {
            guard !solved, acceptingChoices else {
                instruction.text = solved
                    ? "The gate is already awake."
                    : "Watch the glowing rune first."
                return
            }
            let approach = CGPoint(x: max(170, flower.position.x - 105), y: 175)
            travelToFlower(approach, flower: flower, choice: choice.value)
            return
        }
        walkIfValid(point)
    }

    private func choice(at point: CGPoint) -> (node: SKNode?, value: String)? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == "flowerChoice",
                   let value = current.userData?["choice"] as? String {
                    return (current, value)
                }
                node = current.parent
            }
        }
        return nil
    }

    private func travelToFlower(_ destination: CGPoint, flower: SKNode, choice: String) {
        interactionInFlight = true
        valkyrie.walk(to: destination) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.lumi.walk(to: CGPoint(x: destination.x - 60, y: destination.y + 15)) { [weak self] in
                guard let self, !self.hasLeftScene else { return }
                self.lumi.reach(to: flower.position, reducedMotion: self.reducedMotion) {
                    self.resolve(choice: choice, flower: flower)
                }
            }
        }
    }

    private func resolve(choice: String, flower: SKNode) {
        guard !hasLeftScene, interactionInFlight, !solved else { return }
        interactionInFlight = false
        attempts += 1
        let attemptSupport = support
        if choice == encounter.answer {
            solved = true
            acceptingChoices = false
            flower.run(.sequence([.scale(to: 1.18, duration: reducedMotion ? 0 : 0.18), .scale(to: 1.0, duration: reducedMotion ? 0 : 0.18)]))
            if let gate = childNode(withName: "flowerGate") as? SKShapeNode {
                gate.strokeColor = .systemGreen
                gate.glowWidth = 16
                gate.run(.sequence([
                    .scaleY(to: 1.06, duration: reducedMotion ? 0 : 0.2),
                    .scaleY(to: 1.0, duration: reducedMotion ? 0 : 0.2)
                ]))
            }
            childNode(withName: "//gateStar")?.run(.sequence([
                .scale(to: 1.35, duration: reducedMotion ? 0 : 0.2),
                .scale(to: 1.0, duration: reducedMotion ? 0 : 0.2)
            ]))
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            state.audio.play("success")
            valkyrie.pose(.celebrate)
            instruction.text = "The flower answered. Lumi woke the gate!"
            if flowerGateComplete {
                finishFlowerGate()
                return
            }
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 1.2),
                .run { [weak self] in
                    guard let self, !self.hasLeftScene else { return }
                    self.encounter = self.state.nextLiteracyEncounter()
                    self.buildEncounter()
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
            flower.run(.sequence([
                .rotate(toAngle: -0.08, duration: reducedMotion ? 0 : 0.08),
                .rotate(toAngle: 0.08, duration: reducedMotion ? 0 : 0.08),
                .rotate(toAngle: 0, duration: reducedMotion ? 0 : 0.08)
            ]))
            let hint = support == .lightHint
                ? "Look closely at the shape on each flower."
                : "Lumi is narrowing it down. Match the rune shape exactly."
            showTargetRune(retryMessage: hint)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        valkyrie.zPosition = 1000 - valkyrie.position.y
        lumi.zPosition = 1000 - lumi.position.y
    }

    override func willLeave() {
        hasLeftScene = true
        interactionInFlight = false
        removeAction(forKey: "nextLiteracyEncounter")
        removeAction(forKey: "wordGardenPreview")
        targetRune?.removeFromParent()
        lumi.cancelTravel()
        lumi.removeAllActions()
        super.willLeave()
    }
}
