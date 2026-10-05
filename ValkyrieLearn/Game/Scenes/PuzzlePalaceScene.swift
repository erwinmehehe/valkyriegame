import SpriteKit
import LearningCore

// MARK: - Puzzle Palace v2 · Rune Gate

@MainActor final class PuzzlePalaceScene: AdventureScene {
    private enum Place {
        case runeGate
        case memoryBridge
    }

    private let place: Place
    override var worldTitle: String {
        switch place {
        case .runeGate: return "Puzzle Palace · Rune Gate"
        case .memoryBridge: return "Puzzle Palace · Memory Bridge"
        }
    }
    override var walkable: CGRect { CGRect(x: 105, y: 128, width: 1030, height: 160) }

    let tiko = TikoNode()
    private var encounter: PuzzleEncounter?
    private var memoryEncounter: PuzzleMemoryEncounter?
    private var attempts = 0
    private var support: SupportLevel = .independent
    private var startedAt = Date()
    private var solved = false
    private var memoryInput: [String] = []
    private var memoryAcceptingInput = false
    private let choicePoints = [
        CGPoint(x: 575, y: 255),
        CGPoint(x: 770, y: 235),
        CGPoint(x: 965, y: 255)
    ]
    private let memoryPadPoints = [
        CGPoint(x: 505, y: 210),
        CGPoint(x: 665, y: 250),
        CGPoint(x: 825, y: 210),
        CGPoint(x: 985, y: 250)
    ]

    override init(state: AppState) {
        place = state.world == .memoryBridge ? .memoryBridge : .runeGate
        super.init(state: state)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.removeFromParent()
        switch place {
        case .runeGate:
            valkyrie.position = CGPoint(x: 190, y: 175)
            tiko.position = CGPoint(x: 325, y: 190)
        case .memoryBridge:
            valkyrie.position = CGPoint(x: 175, y: 175)
            tiko.position = CGPoint(x: 295, y: 190)
        }
        tiko.reducedMotion = reducedMotion
        addChild(tiko)

        switch place {
        case .runeGate:
            if state.puzzleRuneGateComplete {
                openRuneGate()
            } else {
                encounter = state.nextPuzzleEncounter()
                buildRuneEncounter()
            }
        case .memoryBridge:
            guard state.puzzleMemoryBridgeAvailable else {
                instruction.text = "The Rune Gate must open before Memory Bridge."
                return
            }
            if state.puzzleMemoryBridgeComplete {
                restoreMemoryBridge()
            } else {
                memoryEncounter = state.nextPuzzleMemoryEncounter()
                buildMemoryEncounter()
            }
        }
    }

    override func buildWorld() {
        if let atlas = ArtSystem.texture("V331WorldAtlas") {
            // v3.31 2×2 environment atlas: Puzzle Palace is the lower-right quadrant.
            let puzzleTexture = SKTexture(
                rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
                in: atlas
            )
            let backdrop = SKSpriteNode(texture: puzzleTexture, color: .white, size: size)
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            addChild(backdrop)
        }

        for (height, y) in [(CGFloat(62), CGFloat(684)), (CGFloat(96), CGFloat(42))] {
            let shade = ArtSystem.box(
                CGSize(width: 1280, height: height),
                color: .black.withAlphaComponent(0.29),
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
        case .runeGate:
            buildRuneGate()
            buildRunePath()
            refreshRuneGateProgress(animated: false)
        case .memoryBridge:
            buildMemoryBridgeWorld()
            refreshMemoryBridgeProgress(animated: false)
        }
    }

    private func buildRuneGate() {
        let arch = SKShapeNode(rectOf: CGSize(width: 220, height: 315), cornerRadius: 105)
        arch.fillColor = UIColor(red: 0.20, green: 0.15, blue: 0.34, alpha: 0.72)
        arch.strokeColor = UIColor(red: 0.63, green: 0.52, blue: 0.92, alpha: 1)
        arch.lineWidth = 11
        arch.position = CGPoint(x: 1090, y: 390)
        arch.name = "puzzleGate"
        arch.zPosition = 360
        addChild(arch)

        let door = SKShapeNode(rectOf: CGSize(width: 145, height: 225), cornerRadius: 66)
        door.fillColor = UIColor(red: 0.10, green: 0.08, blue: 0.18, alpha: 0.96)
        door.strokeColor = UIColor(red: 0.49, green: 0.41, blue: 0.74, alpha: 0.95)
        door.lineWidth = 5
        door.position.y = -24
        door.name = "puzzleGateDoor"
        arch.addChild(door)

        let crest = ArtSystem.label("◈", size: 48)
        crest.fontColor = UIColor(red: 0.90, green: 0.82, blue: 1.0, alpha: 1)
        crest.position.y = 88
        crest.name = "puzzleGateCrest"
        arch.addChild(crest)
    }

    private func buildRunePath() {
        for index in 0..<PuzzlePalaceEncounterCatalog.runeGate.count {
            let light = SKShapeNode(circleOfRadius: 18)
            light.fillColor = UIColor(red: 0.28, green: 0.22, blue: 0.40, alpha: 0.94)
            light.strokeColor = UIColor(red: 0.63, green: 0.52, blue: 0.92, alpha: 0.80)
            light.lineWidth = 3
            light.position = CGPoint(x: 845 + CGFloat(index) * 72, y: 150 + CGFloat(index) * 18)
            light.name = "runeProgress\(index)"
            light.zPosition = 410
            addChild(light)
        }

        let path = SKShapeNode(rectOf: CGSize(width: 370, height: 58), cornerRadius: 25)
        path.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.31, alpha: 0.52)
        path.strokeColor = UIColor(red: 0.58, green: 0.48, blue: 0.82, alpha: 0.55)
        path.lineWidth = 4
        path.position = CGPoint(x: 900, y: 165)
        path.zRotation = 0.05
        path.name = "runePath"
        path.zPosition = 120
        addChild(path)
    }

    private func buildRuneEncounter() {
        guard let encounter else { return }
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        clearRuneObjects()

        instruction.text = encounter.prompt

        let board = SKNode()
        board.name = "runeBoard"
        board.position = CGPoint(x: 690, y: 455)
        board.zPosition = 720
        addChild(board)

        let rail = ArtSystem.box(
            CGSize(width: 590, height: 112),
            color: UIColor(red: 0.19, green: 0.14, blue: 0.29, alpha: 0.80),
            radius: 26
        )
        rail.strokeColor = UIColor(red: 0.58, green: 0.48, blue: 0.82, alpha: 0.85)
        rail.lineWidth = 5
        rail.name = "runeBoard"
        board.addChild(rail)

        for (index, rune) in encounter.fixedRunes.enumerated() {
            let stone = runeStone(rune, name: "fixedRune")
            stone.position = CGPoint(x: CGFloat(index - 1) * 125 - 65, y: 0)
            board.addChild(stone)
        }

        let socket = runeSocket()
        socket.position = CGPoint(x: 185, y: 0)
        socket.name = "runeSocket"
        board.addChild(socket)

        for (index, choice) in encounter.choices.enumerated() {
            let pedestal = runeChoice(choice, index: index)
            pedestal.position = choicePoints[index]
            pedestal.name = "runeChoice"
            pedestal.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(pedestal)
        }
    }

    private func runeStone(_ rune: String, name: String) -> SKNode {
        let stone = SKShapeNode(rectOf: CGSize(width: 90, height: 82), cornerRadius: 20)
        stone.fillColor = UIColor(red: 0.29, green: 0.22, blue: 0.43, alpha: 0.98)
        stone.strokeColor = UIColor(red: 0.76, green: 0.65, blue: 0.98, alpha: 1)
        stone.lineWidth = 4
        stone.name = name

        let glyph = ArtSystem.label(rune, size: 43)
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.55, alpha: 1)
        glyph.name = name
        stone.addChild(glyph)
        return stone
    }

    private func runeSocket() -> SKNode {
        let socket = SKShapeNode(rectOf: CGSize(width: 90, height: 82), cornerRadius: 20)
        socket.fillColor = UIColor(red: 0.10, green: 0.08, blue: 0.18, alpha: 0.82)
        socket.strokeColor = UIColor(red: 0.75, green: 0.68, blue: 0.90, alpha: 0.78)
        socket.lineWidth = 4
        socket.glowWidth = 5
        socket.name = "runeSocket"

        let mark = ArtSystem.label("?", size: 39)
        mark.fontColor = UIColor(red: 0.86, green: 0.81, blue: 0.96, alpha: 1)
        mark.name = "runeSocketMark"
        socket.addChild(mark)
        return socket
    }

    private func runeChoice(_ rune: String, index: Int) -> SKNode {
        let node = SKNode()

        let pedestal = SKShapeNode(ellipseOf: CGSize(width: 126, height: 66))
        pedestal.fillColor = UIColor(
            red: 0.31 + CGFloat(index) * 0.025,
            green: 0.23,
            blue: 0.44,
            alpha: 0.97
        )
        pedestal.strokeColor = UIColor(red: 0.75, green: 0.63, blue: 0.97, alpha: 1)
        pedestal.lineWidth = 4
        pedestal.name = "runeChoice"
        node.addChild(pedestal)

        let glyph = ArtSystem.label(rune, size: 43)
        glyph.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1)
        glyph.name = "runeChoice"
        node.addChild(glyph)

        let base = ArtSystem.box(
            CGSize(width: 96, height: 22),
            color: UIColor(red: 0.22, green: 0.17, blue: 0.31, alpha: 1),
            radius: 8
        )
        base.position.y = -46
        base.name = "runeChoice"
        base.zPosition = -1
        node.addChild(base)
        return node
    }

    private func clearRuneObjects() {
        childNode(withName: "runeBoard")?.removeFromParent()
        children.filter { $0.name == "runeChoice" }.forEach { $0.removeFromParent() }
    }

    private func buildMemoryBridgeWorld() {
        let chasm = SKShapeNode(rectOf: CGSize(width: 720, height: 235), cornerRadius: 62)
        chasm.fillColor = UIColor(red: 0.035, green: 0.025, blue: 0.085, alpha: 0.88)
        chasm.strokeColor = UIColor(red: 0.35, green: 0.28, blue: 0.56, alpha: 0.72)
        chasm.lineWidth = 6
        chasm.position = CGPoint(x: 760, y: 405)
        chasm.name = "memoryChasm"
        chasm.zPosition = 110
        addChild(chasm)

        let mist = ArtSystem.label("✦    ·    ✦    ·    ✦", size: 31)
        mist.fontColor = UIColor(red: 0.58, green: 0.48, blue: 0.82, alpha: 0.42)
        mist.position = CGPoint(x: 760, y: 405)
        mist.name = "memoryChasmMist"
        mist.zPosition = 120
        addChild(mist)

        for index in 0..<4 {
            let plank = SKShapeNode(rectOf: CGSize(width: 118, height: 66), cornerRadius: 16)
            plank.fillColor = UIColor(red: 0.24, green: 0.18, blue: 0.36, alpha: 0.68)
            plank.strokeColor = UIColor(red: 0.48, green: 0.39, blue: 0.70, alpha: 0.62)
            plank.lineWidth = 4
            plank.position = CGPoint(x: 545 + CGFloat(index) * 145, y: 375)
            plank.yScale = 0.58
            plank.alpha = 0.48
            plank.name = "memoryBridgePlank\(index)"
            plank.zPosition = 270
            addChild(plank)
        }

        for index in 0..<PuzzlePalaceEncounterCatalog.memoryBridge.count {
            let light = SKShapeNode(circleOfRadius: 17)
            light.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.strokeColor = UIColor(red: 0.65, green: 0.55, blue: 0.92, alpha: 0.82)
            light.lineWidth = 3
            light.position = CGPoint(x: 1010 + CGFloat(index) * 58, y: 555)
            light.name = "memoryProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let startMarker = ArtSystem.label("Tiko", size: 20)
        startMarker.fontColor = UIColor(red: 0.88, green: 0.80, blue: 1.0, alpha: 1)
        startMarker.position = CGPoint(x: 345, y: 355)
        startMarker.zPosition = 320
        addChild(startMarker)
    }

    private func buildMemoryEncounter() {
        guard let memoryEncounter else { return }
        removeAction(forKey: "memoryPreview")
        clearMemoryPads()
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        memoryInput = []
        memoryAcceptingInput = false
        resetAttemptPlanks()

        for (index, symbol) in memoryEncounter.choices.enumerated() {
            let pad = memoryPad(symbol, index: index)
            pad.position = memoryPadPoints[index]
            addChild(pad)
        }

        instruction.text = memoryEncounter.prompt
        previewMemorySequence()
    }

    private func memoryPad(_ symbol: String, index: Int) -> SKNode {
        let root = SKNode()
        root.name = "memoryPad"
        root.userData = NSMutableDictionary(dictionary: ["symbol": symbol])

        let stone = SKShapeNode(circleOfRadius: 47)
        stone.fillColor = UIColor(
            red: 0.24 + CGFloat(index) * 0.025,
            green: 0.18,
            blue: 0.37,
            alpha: 0.98
        )
        stone.strokeColor = UIColor(red: 0.70, green: 0.60, blue: 0.96, alpha: 1)
        stone.lineWidth = 4
        stone.name = "memoryPad"
        root.addChild(stone)

        let glyph = ArtSystem.label(symbol, size: 39)
        glyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 1)
        glyph.name = "memoryPad"
        root.addChild(glyph)

        let foot = ArtSystem.box(
            CGSize(width: 72, height: 18),
            color: UIColor(red: 0.18, green: 0.13, blue: 0.28, alpha: 1),
            radius: 7
        )
        foot.position.y = -56
        foot.name = "memoryPad"
        foot.zPosition = -1
        root.addChild(foot)
        return root
    }

    private func clearMemoryPads() {
        children.filter { $0.name == "memoryPad" }.forEach { $0.removeFromParent() }
    }

    private func previewMemorySequence() {
        guard let memoryEncounter else { return }
        memoryAcceptingInput = false
        instruction.text = "Watch Tiko wake the bridge runes. Hold the order in your mind."

        let onDuration = reducedMotion ? 0.42 : 0.56
        let gap = reducedMotion ? 0.16 : 0.22
        var actions: [SKAction] = [.wait(forDuration: 0.18)]

        for symbol in memoryEncounter.sequence {
            actions.append(.run { [weak self] in
                guard let self else { return }
                self.setMemoryPad(symbol, highlighted: true)
                self.tiko.pose(.interact)
            })
            actions.append(.wait(forDuration: onDuration))
            actions.append(.run { [weak self] in
                self?.setMemoryPad(symbol, highlighted: false)
            })
            actions.append(.wait(forDuration: gap))
        }

        actions.append(.run { [weak self] in
            guard let self else { return }
            self.memoryAcceptingInput = true
            self.startedAt = Date()
            self.instruction.text = "Now repeat Tiko's rune order to raise the bridge."
        })
        run(.sequence(actions), withKey: "memoryPreview")
    }

    private func setMemoryPad(_ symbol: String, highlighted: Bool) {
        guard let pad = children.first(where: {
            $0.name == "memoryPad" && ($0.userData?["symbol"] as? String) == symbol
        }) else { return }
        guard let stone = pad.children.compactMap({ $0 as? SKShapeNode }).first else { return }
        stone.fillColor = highlighted
            ? UIColor(red: 0.91, green: 0.66, blue: 0.24, alpha: 1)
            : UIColor(red: 0.26, green: 0.19, blue: 0.39, alpha: 0.98)
        stone.glowWidth = highlighted ? 16 : 0
        if highlighted && !reducedMotion {
            pad.run(.sequence([
                .scale(to: 1.12, duration: 0.10),
                .scale(to: 1.0, duration: 0.14)
            ]))
        }
    }

    private func memoryChoice(at point: CGPoint) -> (node: SKNode, symbol: String)? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == "memoryPad",
                   let symbol = current.userData?["symbol"] as? String {
                    return (current, symbol)
                }
                node = current.parent
            }
        }
        return nil
    }

    private func approachMemoryPad(_ node: SKNode, symbol: String) {
        guard memoryAcceptingInput else { return }
        memoryAcceptingInput = false
        let destination = CGPoint(x: max(165, node.position.x - 80), y: 175)
        valkyrie.walk(to: destination) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.resolveMemoryTap(symbol, node: node)
        }
        tiko.walk(to: CGPoint(x: max(100, destination.x - 82), y: 190)) {}
    }

    private func resolveMemoryTap(_ symbol: String, node: SKNode) {
        guard let memoryEncounter, memoryInput.count < memoryEncounter.sequence.count else {
            memoryAcceptingInput = true
            return
        }

        let expected = memoryEncounter.sequence[memoryInput.count]
        guard symbol == expected else {
            attempts += 1
            let attemptSupport = support
            _ = state.recordPuzzle(
                memoryEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            memoryInput = []
            resetAttemptPlanks()
            valkyrie.pose(.react)
            nudge(node)
            tiko.pose(.react)
            instruction.text = support == .lightHint
                ? "The bridge forgot that order. Tiko will replay it once."
                : "Tiko will replay the sequence slowly. Watch each rune, then try again."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.18 : 0.55),
                .run { [weak self] in self?.previewMemorySequence() }
            ]), withKey: "memoryRetry")
            return
        }

        memoryInput.append(symbol)
        setMemoryPad(symbol, highlighted: true)
        run(.sequence([
            .wait(forDuration: 0.14),
            .run { [weak self] in self?.setMemoryPad(symbol, highlighted: false) }
        ]))
        raiseMemoryPlank(memoryInput.count - 1)

        guard memoryInput.count == memoryEncounter.sequence.count else {
            memoryAcceptingInput = true
            return
        }

        attempts += 1
        solved = true
        let attemptSupport = support
        _ = state.recordPuzzle(
            memoryEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshMemoryBridgeProgress(animated: true)
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        if state.puzzleMemoryBridgeComplete {
            restoreMemoryBridge()
            return
        }

        instruction.text = attemptSupport == .independent
            ? "The bridge remembered that path. Tiko found another memory lock."
            : "That bridge path is stable. Try the next memory independently."

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.22 : 0.95),
            .run { [weak self] in
                guard let self else { return }
                self.memoryEncounter = self.state.nextPuzzleMemoryEncounter()
                self.buildMemoryEncounter()
            }
        ]), withKey: "nextMemoryBridge")
    }

    private func resetAttemptPlanks() {
        for index in 0..<4 {
            guard let plank = childNode(withName: "memoryBridgePlank\(index)") as? SKShapeNode else {
                continue
            }
            plank.removeAllActions()
            plank.yScale = 0.58
            plank.alpha = 0.48
            plank.strokeColor = UIColor(red: 0.48, green: 0.39, blue: 0.70, alpha: 0.62)
            plank.glowWidth = 0
        }
    }

    private func raiseMemoryPlank(_ index: Int) {
        guard let plank = childNode(withName: "memoryBridgePlank\(index)") as? SKShapeNode else {
            return
        }
        plank.alpha = 1
        plank.strokeColor = UIColor(red: 0.96, green: 0.75, blue: 0.34, alpha: 1)
        plank.glowWidth = 8
        if reducedMotion {
            plank.yScale = 1
        } else {
            plank.run(.scaleY(to: 1, duration: 0.22))
        }
    }

    private func refreshMemoryBridgeProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.memoryBridgeIndependentSuccessCount(
            profile: state.profile
        )
        for index in 0..<PuzzlePalaceEncounterCatalog.memoryBridge.count {
            guard let light = childNode(withName: "memoryProgress\(index)") as? SKShapeNode else {
                continue
            }
            let active = index < count
            light.fillColor = active
                ? UIColor(red: 0.97, green: 0.74, blue: 0.31, alpha: 1)
                : UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.glowWidth = active ? 10 : 0
            if active && animated && !reducedMotion {
                light.run(.sequence([
                    .scale(to: 1.25, duration: 0.15),
                    .scale(to: 1.0, duration: 0.18)
                ]))
            }
        }
    }

    private func restoreMemoryBridge() {
        removeAction(forKey: "memoryPreview")
        removeAction(forKey: "memoryRetry")
        removeAction(forKey: "nextMemoryBridge")
        memoryAcceptingInput = false
        clearMemoryPads()
        refreshMemoryBridgeProgress(animated: true)

        for index in 0..<4 {
            guard let plank = childNode(withName: "memoryBridgePlank\(index)") as? SKShapeNode else {
                continue
            }
            plank.yScale = 1
            plank.alpha = 1
            plank.fillColor = UIColor(red: 0.34, green: 0.27, blue: 0.45, alpha: 0.98)
            plank.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.36, alpha: 1)
            plank.glowWidth = 8
        }

        if let chasm = childNode(withName: "memoryChasm") as? SKShapeNode {
            chasm.strokeColor = UIColor(red: 0.72, green: 0.62, blue: 0.96, alpha: 0.92)
            chasm.glowWidth = 9
            chasm.name = "memoryBridgeRestored"
        }

        tiko.pose(.celebrate)
        instruction.text = "Memory Bridge is restored. The deeper palace chamber remains sealed for the next adventure."
    }

    private func showMemoryBridgeRoute() {
        guard state.puzzleMemoryBridgeAvailable,
              childNode(withName: "memoryBridgeRoute") == nil else { return }
        let route = hotspot(
            "Memory Bridge →",
            name: "memoryBridgeRoute",
            at: CGPoint(x: 1005, y: 165),
            size: CGSize(width: 205, height: 58)
        )
        route.zPosition = 830
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        handleTap(at: point)
    }

    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "home":
            state.travel(to: .storyTree)

        case "runeChoice":
            guard place == .runeGate,
                  !solved,
                  let choice = choice(at: point),
                  let node = choice.node else { return }
            approachRune(node, value: choice.value)

        case "memoryBridgeRoute":
            guard place == .runeGate, state.puzzleMemoryBridgeAvailable else { return }
            let destination = CGPoint(x: 1005, y: 175)
            if isNear(destination) {
                state.travel(to: .memoryBridge)
            } else {
                instruction.text = "Walk through the opened Rune Gate to Memory Bridge."
                travel(to: destination)
            }

        case "memoryPad":
            guard place == .memoryBridge,
                  let choice = memoryChoice(at: point) else { return }
            approachMemoryPad(choice.node, symbol: choice.symbol)

        default:
            walkIfValid(point)
        }
    }

    private func choice(at point: CGPoint) -> (node: SKNode?, value: String)? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == "runeChoice",
                   let value = current.userData?["choice"] as? String {
                    return (current, value)
                }
                node = current.parent
            }
        }
        return nil
    }

    private func approachRune(_ node: SKNode, value: String) {
        let destination = CGPoint(x: max(170, node.position.x - 92), y: 175)
        valkyrie.walk(to: destination) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
            self.valkyrie.pose(.interact)
            self.tiko.walk(
                to: CGPoint(x: destination.x - 72, y: destination.y + 15)
            ) { [weak self] in
                guard let self else { return }
                let socketPosition = self.childNode(withName: "//runeSocket")
                    .map { $0.parent?.convert($0.position, to: self) ?? CGPoint(x: 875, y: 455) }
                    ?? CGPoint(x: 875, y: 455)
                self.tiko.operateRune(
                    at: socketPosition,
                    reducedMotion: self.reducedMotion
                ) { [weak self] in
                    self?.resolveRune(value, node: node)
                }
            }
        }
    }

    private func resolveRune(_ value: String, node: SKNode) {
        guard let encounter else { return }
        attempts += 1
        let attemptSupport = support

        if value == encounter.answer {
            solved = true
            pulse(node)
            fillSocket(with: value)
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            refreshRuneGateProgress(animated: true)
            state.audio.play("success")
            valkyrie.pose(.celebrate)

            if state.puzzleRuneGateComplete {
                openRuneGate()
                return
            }

            instruction.text = attemptSupport == .independent
                ? "That seal is awake. Tiko found the next rune lock."
                : "Tiko helped with that seal. Solve the same pattern independently next."

            run(
                .sequence([
                    .wait(forDuration: reducedMotion ? 0.2 : 1.0),
                    .run { [weak self] in
                        guard let self else { return }
                        self.encounter = self.state.nextPuzzleEncounter()
                        self.buildRuneEncounter()
                    }
                ]),
                withKey: "nextPuzzleRune"
            )
        } else {
            _ = state.recordPuzzle(
                encounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            nudge(node)
            showPatternHint()
            instruction.text = support == .lightHint
                ? "Look for the two-rune beat that repeats."
                : "Tiko lit matching positions. Follow the repeating pair, then try again."
        }
    }

    private func fillSocket(with rune: String) {
        guard let socket = childNode(withName: "//runeSocket") as? SKShapeNode else { return }
        childNode(withName: "//runeSocketMark")?.removeFromParent()
        let glyph = ArtSystem.label(rune, size: 43)
        glyph.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1)
        glyph.name = "runeSocketMark"
        socket.addChild(glyph)
        socket.strokeColor = .systemGreen
        socket.glowWidth = 12
    }

    private func showPatternHint() {
        guard let board = childNode(withName: "runeBoard") else { return }
        let fixed = board.children.filter { $0.name == "fixedRune" }
        for (index, node) in fixed.enumerated() {
            guard let shape = node as? SKShapeNode else { continue }
            shape.glowWidth = index.isMultiple(of: 2) ? 11 : 4
            shape.strokeColor = index.isMultiple(of: 2)
                ? UIColor(red: 1.0, green: 0.78, blue: 0.35, alpha: 1)
                : UIColor(red: 0.73, green: 0.63, blue: 0.96, alpha: 1)
        }
        tiko.pose(.react)
    }

    private func refreshRuneGateProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.runeGateIndependentSuccessCount(
            profile: state.profile
        )

        for index in 0..<PuzzlePalaceEncounterCatalog.runeGate.count {
            guard let light = childNode(withName: "runeProgress\(index)") as? SKShapeNode else {
                continue
            }
            let active = index < count
            light.fillColor = active
                ? UIColor(red: 0.96, green: 0.72, blue: 0.28, alpha: 1)
                : UIColor(red: 0.28, green: 0.22, blue: 0.40, alpha: 0.94)
            light.glowWidth = active ? 10 : 0
            if active && animated && !reducedMotion {
                light.run(.sequence([
                    .scale(to: 1.28, duration: 0.16),
                    .scale(to: 1.0, duration: 0.20)
                ]))
            }
        }

        if let crest = childNode(withName: "//puzzleGateCrest") as? SKLabelNode {
            crest.alpha = 0.55 + CGFloat(count) * 0.15
        }
    }

    private func openRuneGate() {
        removeAction(forKey: "nextPuzzleRune")
        clearRuneObjects()
        refreshRuneGateProgress(animated: true)

        if let gate = childNode(withName: "puzzleGate") as? SKShapeNode {
            gate.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1)
            gate.glowWidth = 16
        }
        if let door = childNode(withName: "//puzzleGateDoor") as? SKShapeNode {
            door.run(
                .group([
                    .scaleX(to: 0.18, duration: reducedMotion ? 0 : 0.55),
                    .fadeAlpha(to: 0.28, duration: reducedMotion ? 0 : 0.55)
                ]),
                withKey: "gateOpen"
            )
        }
        if let path = childNode(withName: "runePath") as? SKShapeNode {
            path.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.36, alpha: 1)
            path.glowWidth = 12
        }

        tiko.pose(.celebrate)
        showMemoryBridgeRoute()
        instruction.text = "The Rune Gate is open. Follow Tiko to Memory Bridge."
    }

    private func pulse(_ node: SKNode) {
        node.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.15, duration: 0.15),
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

    private func travelWithTiko(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let point = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )
        valkyrie.walk(to: point) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
            action?()
        }
        tiko.walk(to: CGPoint(x: max(100, point.x - 92), y: point.y + 12)) {}
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        travelWithTiko(to: destination, then: action)
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        tiko.reducedMotion = reducedMotion
        tiko.zPosition = 1000 - tiko.position.y
    }

    override func willLeave() {
        tiko.cancelTravel()
        tiko.removeAllActions()
        super.willLeave()
    }
}

