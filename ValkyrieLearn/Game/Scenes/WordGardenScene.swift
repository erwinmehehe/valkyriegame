import SpriteKit
import LearningCore

@MainActor final class WordGardenScene: AdventureScene {
    private enum Place: Equatable {
        case flowerGate
        case sunmillCrossing
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

    private let flowerPoints = [
        CGPoint(x: 505, y: 245), CGPoint(x: 675, y: 280),
        CGPoint(x: 840, y: 240), CGPoint(x: 995, y: 285)
    ]
    private let sunmillChoicePoints = [
        CGPoint(x: 540, y: 205), CGPoint(x: 690, y: 255),
        CGPoint(x: 845, y: 210), CGPoint(x: 995, y: 260)
    ]

    override var worldTitle: String {
        switch place {
        case .flowerGate: return "Word Garden · Flower Gate"
        case .sunmillCrossing: return "Word Garden · Sunmill Crossing"
        }
    }

    override var walkable: CGRect {
        CGRect(x: 105, y: 128, width: 1020, height: 155)
    }

    override init(state: AppState) {
        place = state.world == .sunmillCrossing ? .sunmillCrossing : .flowerGate
        super.init(state: state)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.removeFromParent()
        valkyrie.setScale(0.5)
        lumi.setScale(0.65)

        switch place {
        case .flowerGate:
            valkyrie.position = CGPoint(x: 220, y: 175)
            lumi.position = CGPoint(x: 335, y: 190)
        case .sunmillCrossing:
            valkyrie.position = CGPoint(x: 190, y: 175)
            lumi.position = CGPoint(x: 300, y: 190)
        }

        lumi.reducedMotion = reducedMotion
        addChild(lumi)

        switch place {
        case .flowerGate: configureFlowerGate()
        case .sunmillCrossing: configureSunmill()
        }
    }

    override func buildWorld() {
        if let atlas = ArtSystem.texture("V331WorldAtlas") {
            let wordTexture = SKTexture(
                rect: CGRect(x: 0, y: 0.5, width: 0.5, height: 0.5),
                in: atlas
            )
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

        let home = worldControl("⌂", name: "home", at: CGPoint(x: 52, y: 669), radius: 26)
        home.zPosition = 2100

        switch place {
        case .flowerGate:
            buildFlowerGateLandmark()
            buildSoundFlowers()
        case .sunmillCrossing:
            buildSunmillLandmark()
            let back = hotspot(
                "← Flower Gate",
                name: "flowerGateBack",
                at: CGPoint(x: 1110, y: 665),
                size: CGSize(width: 205, height: 52)
            )
            back.zPosition = 2050
        }
    }

    private func buildFlowerGateLandmark() {
        let gate = SKShapeNode(rectOf: CGSize(width: 150, height: 260), cornerRadius: 65)
        gate.fillColor = UIColor(red: 0.18, green: 0.34, blue: 0.18, alpha: 0.22)
        gate.strokeColor = UIColor(red: 0.62, green: 0.42, blue: 0.22, alpha: 0.95)
        gate.lineWidth = 10
        gate.position = CGPoint(x: 1160, y: 400)
        gate.name = "flowerGate"
        gate.zPosition = 300
        addChild(gate)

        for (index, x) in [CGFloat(-40), CGFloat(40)].enumerated() {
            let vine = SKShapeNode(rectOf: CGSize(width: 18, height: 210), cornerRadius: 9)
            vine.fillColor = UIColor(red: 0.22, green: 0.48, blue: 0.22, alpha: 1)
            vine.strokeColor = .clear
            vine.position = CGPoint(x: x, y: -20)
            vine.name = "gateVine\(index)"
            gate.addChild(vine)
        }

        let star = ArtSystem.label("✦", size: 42)
        star.name = "gateStar"
        star.position = CGPoint(x: 0, y: 55)
        gate.addChild(star)
    }

    private func buildSunmillLandmark() {
        let water = SKShapeNode(rectOf: CGSize(width: 980, height: 86), cornerRadius: 43)
        water.fillColor = UIColor(red: 0.25, green: 0.76, blue: 0.92, alpha: 0.24)
        water.strokeColor = UIColor(red: 0.60, green: 0.94, blue: 1, alpha: 0.55)
        water.lineWidth = 5
        water.position = CGPoint(x: 700, y: 185)
        water.zRotation = -0.035
        water.name = "sunmillWater"
        water.zPosition = 90
        addChild(water)

        let wheel = SKNode()
        wheel.position = CGPoint(x: 330, y: 430)
        wheel.name = "sunmillWheel"
        wheel.zPosition = 420

        let rim = SKShapeNode(circleOfRadius: 103)
        rim.fillColor = UIColor(red: 0.35, green: 0.22, blue: 0.10, alpha: 0.45)
        rim.strokeColor = UIColor(red: 0.82, green: 0.60, blue: 0.30, alpha: 1)
        rim.lineWidth = 10
        rim.name = "sunmillWheel"
        wheel.addChild(rim)

        for quarter in 0..<4 {
            let arm = SKNode()
            arm.zRotation = CGFloat(quarter) * .pi / 2
            arm.name = "sunmillWheel"

            let paddle = ArtSystem.box(
                CGSize(width: 28, height: 150),
                color: UIColor(red: 0.73, green: 0.50, blue: 0.25, alpha: 1),
                radius: 8
            )
            paddle.position.y = 75
            paddle.name = "sunmillWheel"
            arm.addChild(paddle)
            wheel.addChild(arm)
        }

        let hub = SKShapeNode(circleOfRadius: 42)
        hub.fillColor = UIColor(red: 0.97, green: 0.72, blue: 0.22, alpha: 1)
        hub.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.52, alpha: 1)
        hub.lineWidth = 5
        hub.name = "sunmillWheel"
        wheel.addChild(hub)

        let sun = ArtSystem.label("☀", size: 43)
        sun.fontColor = UIColor(red: 0.45, green: 0.25, blue: 0.08, alpha: 1)
        sun.name = "sunmillWheel"
        wheel.addChild(sun)

        addChild(wheel)

        let bridge = SKNode()
        bridge.position = CGPoint(x: 915, y: 205)
        bridge.zRotation = -0.18
        bridge.name = "sunmillBridge"
        bridge.zPosition = 350
        for index in 0..<7 {
            let plank = ArtSystem.box(
                CGSize(width: 62, height: 58),
                color: UIColor(red: 0.48, green: 0.31, blue: 0.16, alpha: 1),
                radius: 7
            )
            plank.position.x = CGFloat(index - 3) * 55
            plank.name = "sunmillBridge"
            bridge.addChild(plank)
        }
        bridge.isHidden = true
        addChild(bridge)
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
            instruction.text = "Flower Gate still needs three independent rune matches before this crossing can turn."
            addPrompt("Return to Flower Gate and wake all three vines.")
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
        instruction.text = encounter.prompt
        addPrompt(encounter.prompt)

        for (index, choice) in encounter.choices.enumerated() {
            let leaf = sunmillChoiceNode(letter: choice, index: index)
            leaf.position = sunmillChoicePoints[index]
            leaf.name = "sunmillChoice"
            leaf.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(leaf)
        }

        showTargetRune()
    }

    private func resetAttemptState() {
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        acceptingChoices = false
        targetRune?.removeFromParent()
        targetRune = nil
        removeAction(forKey: "wordGardenPreview")
    }

    private func addPrompt(_ text: String) {
        childNode(withName: "questionPrompt")?.removeFromParent()
        let prompt = ArtSystem.label(text, size: 25)
        prompt.name = "questionPrompt"
        prompt.position = CGPoint(x: 660, y: 610)
        prompt.preferredMaxLayoutWidth = 850
        prompt.numberOfLines = 2
        prompt.zPosition = 2000
        addChild(prompt)
    }

    private func showTargetRune(retryMessage: String? = nil) {
        guard let encounter else { return }
        acceptingChoices = false
        targetRune?.removeFromParent()

        let rune = SKShapeNode(circleOfRadius: 54)
        switch place {
        case .flowerGate:
            rune.fillColor = UIColor(red: 0.39, green: 0.25, blue: 0.56, alpha: 0.94)
            rune.position = CGPoint(x: 640, y: 500)
        case .sunmillCrossing:
            rune.fillColor = UIColor(red: 0.92, green: 0.67, blue: 0.21, alpha: 0.96)
            rune.position = CGPoint(x: 330, y: 430)
        }
        rune.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1)
        rune.lineWidth = 4
        rune.glowWidth = 10
        rune.zPosition = 2010
        rune.name = "targetRune"

        let glyph = ArtSystem.label(encounter.answer, size: 52)
        glyph.fontColor = place == .flowerGate
            ? UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1)
            : UIColor(red: 0.32, green: 0.18, blue: 0.08, alpha: 1)
        rune.addChild(glyph)
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
                    self.instruction.text = self.place == .flowerGate
                        ? "Which flower matches the rune you saw?"
                        : "Which leaf matches the mill-rune you saw?"
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
            .filter { $0.name == "flowerChoice" || $0.name == "sunmillChoice" }
            .forEach { $0.removeFromParent() }
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

    private func sunmillChoiceNode(letter: String, index: Int) -> SKNode {
        let node = SKNode()

        let leaf = SKShapeNode(ellipseOf: CGSize(width: 108, height: 76))
        leaf.fillColor = UIColor(
            red: 0.52,
            green: 0.72 + CGFloat(index) * 0.035,
            blue: 0.38,
            alpha: 0.97
        )
        leaf.strokeColor = UIColor(red: 0.92, green: 0.85, blue: 0.46, alpha: 1)
        leaf.lineWidth = 4
        leaf.zRotation = index.isMultiple(of: 2) ? -0.12 : 0.12
        leaf.name = "sunmillChoice"
        node.addChild(leaf)

        let label = ArtSystem.label(letter, size: 42)
        label.fontColor = UIColor(red: 0.22, green: 0.16, blue: 0.12, alpha: 1)
        label.name = "sunmillChoice"
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
        if interactionInFlight && targetName(at: point) != "home" { return }
        let name = targetName(at: point)

        switch name {
        case "home":
            willLeave()
            state.travel(to: .storyTree)

        case "flowerGateBack":
            state.travel(to: .wordGarden)

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
            water.alpha = 0.45 + CGFloat(count) * 0.14
            water.glowWidth = state.sunmillComplete ? 14 : CGFloat(count) * 3
        }

        if state.sunmillComplete {
            childNode(withName: "sunmillBridge")?.isHidden = false
        }
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

        instruction.text = "The Sunmill is turning. The bridge toward Story Hollow is awake."
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
        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.hasLeftScene else { return }
            self.state.audio.play("footstep")
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
