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
    private let flowerPoints = [
        CGPoint(x: 505, y: 245), CGPoint(x: 675, y: 280),
        CGPoint(x: 840, y: 240), CGPoint(x: 995, y: 285)
    ]

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.removeFromParent()
        encounter = state.nextLiteracyEncounter()
        valkyrie.position = CGPoint(x: 220, y: 175)
        lumi.position = CGPoint(x: 335, y: 190)
        lumi.reducedMotion = reducedMotion
        addChild(lumi)
        buildEncounter()
    }

    override func buildWorld() {
        if let atlas = ArtSystem.texture("V331WorldAtlas") {
            let wordTexture = SKTexture(rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5), in: atlas)
            let backdrop = SKSpriteNode(texture: wordTexture, color: .white, size: size)
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            addChild(backdrop)
        }

        let shade = ArtSystem.box(CGSize(width: 1280, height: 96), color: .black.withAlphaComponent(0.25), radius: 0)
        shade.strokeColor = .clear
        shade.position = CGPoint(x: 640, y: 42)
        shade.zPosition = 1990
        addChild(shade)

        let gate = SKShapeNode(rectOf: CGSize(width: 220, height: 310), cornerRadius: 100)
        gate.fillColor = UIColor(red: 0.18, green: 0.34, blue: 0.18, alpha: 0.22)
        gate.strokeColor = UIColor(red: 0.62, green: 0.42, blue: 0.22, alpha: 0.95)
        gate.lineWidth = 10
        gate.position = CGPoint(x: 1090, y: 370)
        gate.name = "flowerGate"
        gate.zPosition = 300
        addChild(gate)

        for x in [-55.0, 55.0] {
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

        let home = worldControl("⌂", name: "home", at: CGPoint(x: 52, y: 669), radius: 26)
        home.zPosition = 2100
    }

    private func buildEncounter() {
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
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
    }

    private func flowerNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()
        let hit = SKShapeNode(circleOfRadius: 52)
        hit.fillColor = UIColor(red: 0.95, green: 0.45 + CGFloat(index) * 0.05, blue: 0.70, alpha: 0.95)
        hit.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.50, alpha: 1)
        hit.lineWidth = 4
        hit.name = "flowerChoice"
        node.addChild(hit)
        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
            let petal = SKShapeNode(ellipseOf: CGSize(width: 58, height: 34))
            petal.fillColor = hit.fillColor
            petal.strokeColor = .clear
            petal.position = CGPoint(x: cos(angle) * 44, y: sin(angle) * 44)
            petal.zRotation = CGFloat(angle)
            petal.name = "flowerChoice"
            node.addChild(petal)
        }
        let label = ArtSystem.label(letter, size: 40)
        label.fontColor = UIColor(red: 0.34, green: 0.16, blue: 0.32, alpha: 1)
        label.name = "flowerChoice"
        node.addChild(label)
        let stem = SKShapeNode(rectOf: CGSize(width: 10, height: 88), cornerRadius: 5)
        stem.fillColor = UIColor(red: 0.19, green: 0.45, blue: 0.23, alpha: 1)
        stem.strokeColor = .clear
        stem.position.y = -92
        stem.zPosition = -1
        stem.name = "flowerChoice"
        node.addChild(stem)
        return node
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        handleTap(at: point)
    }

    func handleTap(at point: CGPoint) {
        let name = targetName(at: point)
        if name == "home" {
            state.travel(to: .storyTree)
            return
        }
        if name == "flowerChoice", let choice = choice(at: point), let flower = choice.node {
            guard !solved else { return }
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
        valkyrie.walk(to: destination) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.lumi.walk(to: CGPoint(x: destination.x - 60, y: destination.y + 15)) { [weak self] in
                guard let self else { return }
                self.lumi.reach(to: flower.position, reducedMotion: self.reducedMotion) {
                    self.resolve(choice: choice, flower: flower)
                }
            }
        }
    }

    private func resolve(choice: String, flower: SKNode) {
        attempts += 1
        if choice == encounter.answer {
            solved = true
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
                support: support,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            state.audio.play("success")
            valkyrie.pose(.celebrate)
            instruction.text = "The flower answered. Lumi woke the gate!"
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 1.2),
                .run { [weak self] in
                    guard let self else { return }
                    self.encounter = self.state.nextLiteracyEncounter()
                    self.buildEncounter()
                }
            ]), withKey: "nextLiteracyEncounter")
        } else {
            support = support == .independent ? .lightHint : .strongHint
            _ = state.recordLiteracy(
                encounter,
                outcome: .incorrect,
                support: support,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            valkyrie.pose(.react)
            flower.run(.sequence([
                .rotate(toAngle: -0.08, duration: reducedMotion ? 0 : 0.08),
                .rotate(toAngle: 0.08, duration: reducedMotion ? 0 : 0.08),
                .rotate(toAngle: 0, duration: reducedMotion ? 0 : 0.08)
            ]))
            instruction.text = support == .lightHint
                ? "Look closely at the letter on each flower."
                : "Lumi is narrowing it down. Match the shape exactly."
        }
    }

    override func update(_ currentTime: TimeInterval) {
        valkyrie.zPosition = 1000 - valkyrie.position.y
        lumi.zPosition = 1000 - lumi.position.y
    }

    override func willLeave() {
        lumi.cancelTravel()
        lumi.removeAllActions()
        super.willLeave()
    }
}
