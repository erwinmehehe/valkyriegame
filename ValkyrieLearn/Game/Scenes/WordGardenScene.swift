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
        gate.fillColor = UIColor(red: 0.18, green: 0.34, blue: 0.18, alpha: 0.22)
        gate.strokeColor = UIColor(red: 0.62, green: 0.42, blue: 0.22, alpha: 0.95)
        gate.lineWidth = 10
        gate.position = CGPoint(x: 1160, y: 400)
        gate.name = "flowerGate"
        gate.zPosition = 300
        addChild(gate)

        let vineOffsets: [CGFloat] = [-40, 40]
        for x in vineOffsets {
            let vine = SKShapeNode(rectOf: CGSize(width: 18, height: 210), cornerRadius: 9)
            vine.fillColor = UIColor(red: 0.22, green: 0.48, blue: 0.22, alpha: 1)
            vine.strokeColor = .clear
            vine.position = CGPoint(x: x, y: -20)
            gate.addChild(vine)
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

        let rune = SKShapeNode(circleOfRadius: 54)
        rune.fillColor = UIColor(red: 0.39, green: 0.25, blue: 0.56, alpha: 0.94)
        rune.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
        rune.lineWidth = 4
        rune.glowWidth = 10
        rune.position = CGPoint(x: 640, y: 500)
        rune.zPosition = 2010
        rune.name = "targetRune"

        let glyph = ArtSystem.label(encounter.answer, size: 52)
        glyph.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
        rune.addChild(glyph)
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

        let stone = SKShapeNode(rectOf: CGSize(width: 96, height: 58), cornerRadius: 22)
        stone.fillColor = UIColor(red: 0.34, green: 0.29, blue: 0.45, alpha: 0.98)
        stone.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.39, alpha: 0.95)
        stone.lineWidth = 4
        stone.position.y = -52
        stone.name = "flowerChoice"
        node.addChild(stone)

        let label = ArtSystem.label(letter, size: 36)
        label.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
        label.position.y = -52
        label.name = "flowerChoice"
        node.addChild(label)

        let hit = SKShapeNode(circleOfRadius: 44)
        hit.fillColor = UIColor(red: 0.95, green: 0.45 + CGFloat(index) * 0.05, blue: 0.70, alpha: 0.94)
        hit.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.50, alpha: 1)
        hit.lineWidth = 3
        hit.position.y = 28
        hit.name = "flowerChoice"
        node.addChild(hit)

        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
            let petal = SKShapeNode(ellipseOf: CGSize(width: 48, height: 28))
            petal.fillColor = hit.fillColor
            petal.strokeColor = .clear
            petal.position = CGPoint(
                x: CGFloat(cos(angle)) * 37,
                y: 28 + CGFloat(sin(angle)) * 37
            )
            petal.zRotation = CGFloat(angle)
            petal.name = "flowerChoice"
            node.addChild(petal)
        }

        let stem = SKShapeNode(rectOf: CGSize(width: 9, height: 54), cornerRadius: 4)
        stem.fillColor = UIColor(red: 0.19, green: 0.45, blue: 0.23, alpha: 1)
        stem.strokeColor = .clear
        stem.position.y = -10
        stem.zPosition = -1
        stem.name = "flowerChoice"
        node.addChild(stem)
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

            let center = SKShapeNode(circleOfRadius: 19)
            center.fillColor = UIColor(red: 1.0, green: 0.82, blue: 0.32, alpha: 0.95)
            center.strokeColor = .clear
            center.name = "soundFlower"
            flower.addChild(center)

            for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 3) {
                let petal = SKShapeNode(ellipseOf: CGSize(width: 50, height: 28))
                petal.fillColor = UIColor(
                    red: 0.86,
                    green: 0.42 + CGFloat(index) * 0.08,
                    blue: 0.78,
                    alpha: 0.94
                )
                petal.strokeColor = .clear
                petal.position = CGPoint(
                    x: CGFloat(cos(angle)) * 34,
                    y: CGFloat(sin(angle)) * 34
                )
                petal.zRotation = CGFloat(angle)
                petal.name = "soundFlower"
                flower.addChild(petal)
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
