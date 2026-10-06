import SpriteKit
import LearningCore

// MARK: - Puzzle Palace v2 · Rune Gate

@MainActor final class PuzzlePalaceScene: AdventureScene {
    private enum Place: Equatable {
        case runeGate
        case memoryBridge
        case stopGoOrbs
        case sortingPedestal
        case resortVault
        case mirrorHall
        case pathTiles
    }

    private let place: Place
    override var worldTitle: String {
        switch place {
        case .runeGate: return "Puzzle Palace · Rune Gate"
        case .memoryBridge: return "Puzzle Palace · Memory Bridge"
        case .stopGoOrbs: return "Puzzle Palace · Stop/Go Orbs"
        case .sortingPedestal: return "Puzzle Palace · Sorting Pedestal"
        case .resortVault: return "Puzzle Palace · Re-sort Vault"
        case .mirrorHall: return "Puzzle Palace · Mirror Hall"
        case .pathTiles: return "Puzzle Palace · Path Tiles"
        }
    }
    override var walkable: CGRect { CGRect(x: 105, y: 128, width: 1030, height: 160) }
    override var interactionSafeZone: CGRect {
        switch place {
        case .mirrorHall: return CGRect(x: 410, y: 265, width: 700, height: 360)
        case .pathTiles: return CGRect(x: 430, y: 250, width: 760, height: 350)
        default: return CGRect(x: 430, y: 250, width: 720, height: 330)
        }
    }
    override var actorLane: CGRect { CGRect(x: 120, y: 140, width: 1000, height: 85) }

    let tiko = TikoNode()
    private var encounter: PuzzleEncounter?
    private var memoryEncounter: PuzzleMemoryEncounter?
    private var attempts = 0
    private var support: SupportLevel = .independent
    private var startedAt = Date()
    private var solved = false
    private var runeAcceptingInput = false
    private var memoryInput: [String] = []
    private var memoryAcceptingInput = false
    private var inhibitionEncounter: PuzzleInhibitionEncounter?
    private var stopGoIndex = 0
    private var stopGoAcceptingTap = false
    private var stopGoCurrentSignal: PuzzleGateSignal?
    private var sortEncounter: PuzzleSortEncounter?
    private var sortTrialIndex = 0
    private var sortAcceptingInput = false
    private var resortEncounter: PuzzleResortEncounter?
    private var resortPass = 0
    private var resortObjectIndex = 0
    private var resortAcceptingInput = false
    private var orientationEncounter: PuzzleOrientationEncounter?
    private var rotationEncounter: PuzzleRotationEncounter?
    private var pathEncounter: PuzzlePathEncounter?
    private var pathAcceptingInput = false
    private var mirrorAcceptingInput = false
    private var mirrorPracticeReady = false
    private var mirrorPracticeBusy = false
    private var mirrorApproaching = false
    private let mirrorChoicePoints = [
        CGPoint(x: 515, y: 350),
        CGPoint(x: 760, y: 365),
        CGPoint(x: 1005, y: 350)
    ]
    private let resortStartPositions = [
        CGPoint(x: 535, y: 395),
        CGPoint(x: 680, y: 410),
        CGPoint(x: 825, y: 395),
        CGPoint(x: 970, y: 410)
    ]
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
        switch state.world {
        case .memoryBridge:
            place = .memoryBridge
        case .stopGoOrbs:
            place = .stopGoOrbs
        case .sortingPedestal:
            place = .sortingPedestal
        case .resortVault:
            place = .resortVault
        case .mirrorHall:
            place = .mirrorHall
        case .pathTiles:
            place = .pathTiles
        default:
            place = .runeGate
        }
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
        case .stopGoOrbs:
            valkyrie.position = CGPoint(x: 185, y: 175)
            tiko.position = CGPoint(x: 305, y: 190)
        case .sortingPedestal:
            valkyrie.position = CGPoint(x: 185, y: 175)
            tiko.position = CGPoint(x: 300, y: 190)
        case .resortVault:
            valkyrie.position = CGPoint(x: 180, y: 175)
            tiko.position = CGPoint(x: 295, y: 190)
        case .mirrorHall:
            valkyrie.position = CGPoint(x: 180, y: 175)
            tiko.position = CGPoint(x: 305, y: 190)
        case .pathTiles:
            valkyrie.position = CGPoint(x: 180, y: 175)
            tiko.position = CGPoint(x: 305, y: 190)
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
        case .stopGoOrbs:
            guard state.puzzleStopGoAvailable else {
                instruction.text = "Memory Bridge must be restored before the orb chamber opens."
                return
            }
            if state.puzzleStopGoComplete {
                restoreStopGoOrbs()
            } else {
                inhibitionEncounter = state.nextPuzzleStopGoEncounter()
                buildStopGoEncounter()
            }
        case .sortingPedestal:
            guard state.puzzleSortingAvailable else {
                instruction.text = "The Stop/Go chamber must be stabilized before the Sorting Pedestal."
                return
            }
            if state.puzzleSortingPedestalComplete {
                restoreSortingPedestal()
            } else {
                sortEncounter = state.nextPuzzleSortingEncounter()
                buildSortingEncounter()
            }
        case .resortVault:
            guard state.puzzleResortAvailable else {
                instruction.text = "Sorting Pedestal must be stable before the Re-sort Vault opens."
                return
            }
            if state.puzzleResortComplete {
                restoreResortVault()
            } else {
                resortEncounter = state.nextPuzzleResortEncounter()
                buildResortEncounter()
            }
        case .mirrorHall:
            state.audio.play("palace_ambience", channel: .ambience, looping: true)
            guard state.puzzleMirrorHallAvailable else {
                instruction.text = "The Re-sort Vault must be stable before Mirror Hall opens."
                return
            }
            if state.puzzleMirrorHallComplete {
                restoreMirrorHall()
            } else {
                orientationEncounter = state.nextPuzzleMirrorHallEncounter()
                buildMirrorHallEncounter()
            }
        case .pathTiles:
            state.audio.play("palace_ambience", channel: .ambience, looping: true)
            guard state.puzzlePathTilesAvailable else {
                instruction.text = "Restore every Mirror Hall beam before Path Tiles opens."
                return
            }
            if state.puzzlePathTilesComplete {
                finishPathTiles()
            } else {
                pathEncounter = state.nextPuzzlePathTilesEncounter()
                buildPathTilesEncounter()
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
        case .stopGoOrbs:
            buildStopGoWorld()
            refreshStopGoProgress(animated: false)
        case .sortingPedestal:
            buildSortingWorld()
            refreshSortingProgress(animated: false)
        case .resortVault:
            buildResortWorld()
            refreshResortProgress(animated: false)
        case .mirrorHall:
            buildMirrorHallWorld()
            refreshMirrorHallProgress(animated: false)
        case .pathTiles:
            buildPathTilesWorld()
            refreshPathTilesProgress(animated: false)
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
        runeAcceptingInput = true
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
        showStopGoRoute()
        instruction.text = "Memory Bridge is restored. Cross to the Stop/Go Orb chamber."
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


    private func showStopGoRoute() {
        guard state.puzzleStopGoAvailable,
              childNode(withName: "stopGoRoute") == nil else { return }
        let route = hotspot(
            "Stop/Go Orbs →",
            name: "stopGoRoute",
            at: CGPoint(x: 1000, y: 165),
            size: CGSize(width: 205, height: 58)
        )
        route.zPosition = 835
    }

    private func buildStopGoWorld() {
        let rail = SKShapeNode(rectOf: CGSize(width: 710, height: 96), cornerRadius: 42)
        rail.fillColor = UIColor(red: 0.11, green: 0.09, blue: 0.20, alpha: 0.80)
        rail.strokeColor = UIColor(red: 0.53, green: 0.43, blue: 0.78, alpha: 0.84)
        rail.lineWidth = 6
        rail.position = CGPoint(x: 755, y: 365)
        rail.name = "stopGoRail"
        rail.zPosition = 180
        addChild(rail)

        for index in 0..<5 {
            let brace = SKShapeNode(rectOf: CGSize(width: 52, height: 82), cornerRadius: 13)
            brace.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.32, alpha: 0.95)
            brace.strokeColor = UIColor(red: 0.55, green: 0.45, blue: 0.80, alpha: 0.72)
            brace.lineWidth = 3
            brace.position = CGPoint(x: 505 + CGFloat(index) * 125, y: 365)
            brace.name = "stopGoBrace"
            brace.zPosition = 190
            addChild(brace)
        }

        let orbRoot = SKNode()
        orbRoot.name = "stopGoOrb"
        orbRoot.position = CGPoint(x: 755, y: 365)
        orbRoot.zPosition = 620

        let ring = SKShapeNode(circleOfRadius: 83)
        ring.fillColor = UIColor(red: 0.21, green: 0.16, blue: 0.34, alpha: 0.96)
        ring.strokeColor = UIColor(red: 0.70, green: 0.58, blue: 0.96, alpha: 1)
        ring.lineWidth = 8
        ring.name = "stopGoOrb"
        orbRoot.addChild(ring)

        let core = SKShapeNode(circleOfRadius: 49)
        core.fillColor = UIColor(red: 0.32, green: 0.25, blue: 0.46, alpha: 1)
        core.strokeColor = UIColor(red: 0.92, green: 0.82, blue: 1.0, alpha: 0.94)
        core.lineWidth = 4
        core.name = "stopGoOrbCore"
        orbRoot.addChild(core)

        let glyph = ArtSystem.label("Ⅱ", size: 45)
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.58, alpha: 1)
        glyph.name = "stopGoOrbGlyph"
        orbRoot.addChild(glyph)

        addChild(orbRoot)

        let barrier = SKShapeNode(rectOf: CGSize(width: 105, height: 260), cornerRadius: 38)
        barrier.fillColor = UIColor(red: 0.14, green: 0.10, blue: 0.23, alpha: 0.92)
        barrier.strokeColor = UIColor(red: 0.58, green: 0.47, blue: 0.86, alpha: 0.90)
        barrier.lineWidth = 7
        barrier.position = CGPoint(x: 1095, y: 385)
        barrier.name = "stopGoBarrier"
        barrier.zPosition = 350
        addChild(barrier)

        for index in 0..<PuzzlePalaceEncounterCatalog.stopGoOrbs.count {
            let light = SKShapeNode(circleOfRadius: 17)
            light.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.strokeColor = UIColor(red: 0.65, green: 0.55, blue: 0.92, alpha: 0.82)
            light.lineWidth = 3
            light.position = CGPoint(x: 970 + CGFloat(index) * 57, y: 555)
            light.name = "stopGoProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let back = hotspot(
            "← Memory Bridge",
            name: "memoryBridgeBack",
            at: CGPoint(x: 1090, y: 665),
            size: CGSize(width: 210, height: 52)
        )
        back.zPosition = 2050
    }

    private func buildStopGoEncounter() {
        guard let inhibitionEncounter else { return }
        removeAction(forKey: "stopGoSignal")
        removeAction(forKey: "stopGoRetry")
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        stopGoIndex = 0
        stopGoAcceptingTap = false
        stopGoCurrentSignal = nil
        instruction.text = inhibitionEncounter.prompt
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.20 : 0.55),
            .run { [weak self] in
                self?.presentStopGoSignal()
            }
        ]), withKey: "stopGoRetry")
    }

    private func presentStopGoSignal() {
        guard let inhibitionEncounter,
              stopGoIndex < inhibitionEncounter.signals.count else {
            completeStopGoSequence()
            return
        }

        let signal = inhibitionEncounter.signals[stopGoIndex]
        stopGoCurrentSignal = signal
        stopGoAcceptingTap = signal == .go
        updateStopGoOrb(signal)

        switch signal {
        case .hold:
            instruction.text = support == .independent
                ? "HOLD — keep your hands off the orb until it changes."
                : "HOLD — Tiko is guarding the orb. Wait for the star."
            let duration: TimeInterval
            switch support {
            case .independent: duration = 0.95
            case .lightHint: duration = 1.15
            case .strongHint, .demonstration: duration = 1.35
            }
            run(.sequence([
                .wait(forDuration: duration),
                .run { [weak self] in
                    guard let self,
                          self.stopGoCurrentSignal == .hold else { return }
                    self.stopGoIndex += 1
                    self.presentStopGoSignal()
                }
            ]), withKey: "stopGoSignal")

        case .go:
            instruction.text = "GO — tap the star orb to let the palace current through."
            tiko.pose(.interact)
        }
    }

    private func updateStopGoOrb(_ signal: PuzzleGateSignal) {
        guard let root = childNode(withName: "stopGoOrb"),
              let core = root.childNode(withName: "stopGoOrbCore") as? SKShapeNode,
              let glyph = root.childNode(withName: "stopGoOrbGlyph") as? SKLabelNode else {
            return
        }

        switch signal {
        case .hold:
            core.fillColor = UIColor(red: 0.43, green: 0.19, blue: 0.31, alpha: 1)
            core.strokeColor = UIColor(red: 0.95, green: 0.65, blue: 0.73, alpha: 1)
            core.glowWidth = 3
            glyph.text = "Ⅱ"
            glyph.fontColor = UIColor(red: 1.0, green: 0.87, blue: 0.72, alpha: 1)
        case .go:
            core.fillColor = UIColor(red: 0.24, green: 0.48, blue: 0.31, alpha: 1)
            core.strokeColor = UIColor(red: 0.68, green: 1.0, blue: 0.72, alpha: 1)
            core.glowWidth = 14
            glyph.text = "✦"
            glyph.fontColor = UIColor(red: 1.0, green: 0.93, blue: 0.48, alpha: 1)
            if !reducedMotion {
                root.run(.sequence([
                    .scale(to: 1.10, duration: 0.12),
                    .scale(to: 1.0, duration: 0.15)
                ]))
            }
        }
    }

    private func handleStopGoOrbTap() {
        guard place == .stopGoOrbs,
              let inhibitionEncounter,
              !solved,
              let signal = stopGoCurrentSignal else { return }

        switch signal {
        case .hold:
            removeAction(forKey: "stopGoSignal")
            attempts += 1
            let attemptSupport = support
            _ = state.recordPuzzle(
                inhibitionEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            stopGoIndex = 0
            stopGoAcceptingTap = false
            stopGoCurrentSignal = nil
            valkyrie.pose(.react)
            tiko.pose(.react)
            shakeStopGoOrb()
            instruction.text = support == .lightHint
                ? "That was a HOLD signal. Tiko will replay the sequence."
                : "Wait through the double-bar signals. Touch only the star."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.22 : 0.65),
                .run { [weak self] in self?.presentStopGoSignal() }
            ]), withKey: "stopGoRetry")

        case .go:
            guard stopGoAcceptingTap else { return }
            stopGoAcceptingTap = false
            removeAction(forKey: "stopGoSignal")
            valkyrie.pose(.interact)
            tiko.pose(.interact)
            pulseStopGoOrb()
            stopGoIndex += 1
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.12 : 0.30),
                .run { [weak self] in self?.presentStopGoSignal() }
            ]), withKey: "stopGoSignal")
        }
    }

    private func completeStopGoSequence() {
        guard let inhibitionEncounter else { return }
        stopGoAcceptingTap = false
        stopGoCurrentSignal = nil
        attempts += 1
        solved = true
        let attemptSupport = support

        _ = state.recordPuzzle(
            inhibitionEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshStopGoProgress(animated: true)
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        if state.puzzleStopGoComplete {
            restoreStopGoOrbs()
            return
        }

        instruction.text = attemptSupport == .independent
            ? "You held back at the lock signals. The next orb rhythm is waking."
            : "That orb is stable. Now try the rhythm independently."

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.24 : 0.95),
            .run { [weak self] in
                guard let self else { return }
                self.inhibitionEncounter = self.state.nextPuzzleStopGoEncounter()
                self.buildStopGoEncounter()
            }
        ]), withKey: "nextStopGo")
    }

    private func refreshStopGoProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.stopGoIndependentSuccessCount(
            profile: state.profile
        )
        for index in 0..<PuzzlePalaceEncounterCatalog.stopGoOrbs.count {
            guard let light = childNode(withName: "stopGoProgress\(index)") as? SKShapeNode else {
                continue
            }
            let active = index < count
            light.fillColor = active
                ? UIColor(red: 0.95, green: 0.72, blue: 0.29, alpha: 1)
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

    private func restoreStopGoOrbs() {
        removeAction(forKey: "stopGoSignal")
        removeAction(forKey: "stopGoRetry")
        removeAction(forKey: "nextStopGo")
        stopGoAcceptingTap = false
        stopGoCurrentSignal = nil
        refreshStopGoProgress(animated: true)

        if let root = childNode(withName: "stopGoOrb"),
           let core = root.childNode(withName: "stopGoOrbCore") as? SKShapeNode,
           let glyph = root.childNode(withName: "stopGoOrbGlyph") as? SKLabelNode {
            core.fillColor = UIColor(red: 0.31, green: 0.54, blue: 0.38, alpha: 1)
            core.strokeColor = UIColor(red: 0.75, green: 1.0, blue: 0.78, alpha: 1)
            core.glowWidth = 15
            glyph.text = "✦"
        }

        if let barrier = childNode(withName: "stopGoBarrier") as? SKShapeNode {
            barrier.fillColor = UIColor(red: 0.16, green: 0.12, blue: 0.25, alpha: 0.42)
            barrier.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1)
            barrier.glowWidth = 12
            barrier.xScale = 0.24
            barrier.alpha = 0.45
            barrier.name = "stopGoBarrierOpen"
        }

        showSortingPedestalRoute()
        instruction.text = "The Stop/Go chamber is stable. Follow Tiko to the Sorting Pedestal."
    }

    private func pulseStopGoOrb() {
        guard let orb = childNode(withName: "stopGoOrb") else { return }
        orb.run(.sequence([
            .scale(to: reducedMotion ? 1.0 : 1.14, duration: 0.12),
            .scale(to: 1.0, duration: reducedMotion ? 0 : 0.16)
        ]))
    }

    private func shakeStopGoOrb() {
        guard let orb = childNode(withName: "stopGoOrb") else { return }
        orb.run(.sequence([
            .moveBy(x: reducedMotion ? 0 : -10, y: 0, duration: 0.07),
            .moveBy(x: reducedMotion ? 0 : 20, y: 0, duration: 0.10),
            .moveBy(x: reducedMotion ? 0 : -10, y: 0, duration: 0.07)
        ]))
    }


    private func showSortingPedestalRoute() {
        guard state.puzzleSortingAvailable,
              childNode(withName: "sortingPedestalRoute") == nil else { return }
        let route = hotspot(
            "Sorting Pedestal →",
            name: "sortingPedestalRoute",
            at: CGPoint(x: 1000, y: 165),
            size: CGSize(width: 225, height: 58)
        )
        route.zPosition = 840
    }

    private func buildSortingWorld() {
        let floor = SKShapeNode(rectOf: CGSize(width: 780, height: 245), cornerRadius: 54)
        floor.fillColor = UIColor(red: 0.10, green: 0.08, blue: 0.19, alpha: 0.70)
        floor.strokeColor = UIColor(red: 0.50, green: 0.41, blue: 0.76, alpha: 0.72)
        floor.lineWidth = 6
        floor.position = CGPoint(x: 750, y: 365)
        floor.name = "sortingFloor"
        floor.zPosition = 120
        addChild(floor)

        buildSortPedestal(
            at: CGPoint(x: 530, y: 355),
            name: "sortLeftPedestal"
        )
        buildSortPedestal(
            at: CGPoint(x: 970, y: 355),
            name: "sortRightPedestal"
        )

        let dial = SKShapeNode(circleOfRadius: 72)
        dial.fillColor = UIColor(red: 0.20, green: 0.15, blue: 0.32, alpha: 0.98)
        dial.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 1)
        dial.lineWidth = 6
        dial.position = CGPoint(x: 750, y: 515)
        dial.name = "sortingRuleDial"
        dial.zPosition = 560
        addChild(dial)

        let ruleGlyph = ArtSystem.label("●  ▲", size: 28)
        ruleGlyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1)
        ruleGlyph.name = "sortingRuleGlyph"
        dial.addChild(ruleGlyph)

        let stage = ArtSystem.box(
            CGSize(width: 160, height: 42),
            color: UIColor(red: 0.18, green: 0.13, blue: 0.28, alpha: 0.90),
            radius: 16
        )
        stage.position = CGPoint(x: 750, y: 430)
        stage.name = "sortingObjectStage"
        stage.zPosition = 430
        addChild(stage)

        for index in 0..<3 {
            let light = SKShapeNode(circleOfRadius: 16)
            light.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.strokeColor = UIColor(red: 0.65, green: 0.55, blue: 0.92, alpha: 0.82)
            light.lineWidth = 3
            light.position = CGPoint(x: 1010 + CGFloat(index) * 55, y: 555)
            light.name = "sortingProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        for index in 0..<3 {
            let light = SKShapeNode(circleOfRadius: 13)
            light.fillColor = UIColor(red: 0.24, green: 0.18, blue: 0.36, alpha: 0.92)
            light.strokeColor = UIColor(red: 0.56, green: 0.47, blue: 0.82, alpha: 0.78)
            light.lineWidth = 3
            light.position = CGPoint(x: 1010 + CGFloat(index) * 55, y: 515)
            light.name = "switchProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let back = hotspot(
            "← Stop/Go Orbs",
            name: "stopGoBack",
            at: CGPoint(x: 1090, y: 665),
            size: CGSize(width: 205, height: 52)
        )
        back.zPosition = 2050
    }

    private func buildSortPedestal(at point: CGPoint, name: String) {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 420

        let bowl = SKShapeNode(ellipseOf: CGSize(width: 185, height: 82))
        bowl.fillColor = UIColor(red: 0.28, green: 0.21, blue: 0.40, alpha: 0.98)
        bowl.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 1)
        bowl.lineWidth = 5
        bowl.name = name
        root.addChild(bowl)

        let stem = ArtSystem.box(
            CGSize(width: 82, height: 100),
            color: UIColor(red: 0.18, green: 0.13, blue: 0.28, alpha: 1),
            radius: 16
        )
        stem.position.y = -80
        stem.name = name
        stem.zPosition = -1
        root.addChild(stem)

        let glyph = ArtSystem.label("?", size: 42)
        glyph.name = name + "Glyph"
        glyph.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.56, alpha: 1)
        root.addChild(glyph)

        addChild(root)
    }

    private func buildSortingEncounter() {
        guard let sortEncounter else { return }
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        sortTrialIndex = 0
        sortAcceptingInput = false
        childNode(withName: "sortingObject")?.removeFromParent()
        instruction.text = sortEncounter.prompt

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.16 : 0.45),
            .run { [weak self] in self?.presentSortTrial() }
        ]), withKey: "sortStart")
    }

    private func presentSortTrial() {
        guard let sortEncounter,
              sortTrialIndex < sortEncounter.objects.count else {
            completeSortingEncounter()
            return
        }

        childNode(withName: "sortingObject")?.removeFromParent()
        let rule = sortEncounter.rules[sortTrialIndex]
        let object = sortEncounter.objects[sortTrialIndex]
        updateSortingRule(rule)

        let token = sortingObjectNode(object)
        token.position = CGPoint(x: 750, y: 385)
        token.name = "sortingObject"
        token.zPosition = 650
        addChild(token)

        sortAcceptingInput = true
        instruction.text = sortEncounter.skillID == PuzzleSkills.ruleSwitching
            ? "The dial can change. Use the glowing rule for this stone."
            : sortEncounter.prompt
    }

    private func updateSortingRule(_ rule: PuzzleSortRule) {
        guard let left = childNode(withName: "sortLeftPedestal"),
              let right = childNode(withName: "sortRightPedestal"),
              let dial = childNode(withName: "sortingRuleDial"),
              let dialGlyph = dial.childNode(withName: "sortingRuleGlyph") as? SKLabelNode,
              let leftGlyph = left.childNode(withName: "sortLeftPedestalGlyph") as? SKLabelNode,
              let rightGlyph = right.childNode(withName: "sortRightPedestalGlyph") as? SKLabelNode else {
            return
        }

        switch rule {
        case .shape:
            dialGlyph.text = "●  ▲"
            leftGlyph.text = "●"
            rightGlyph.text = "▲"
        case .marks:
            dialGlyph.text = "•  ••"
            leftGlyph.text = "•"
            rightGlyph.text = "••"
        }

        if !reducedMotion {
            dial.run(.sequence([
                .rotate(byAngle: .pi / 10, duration: 0.12),
                .rotate(byAngle: -.pi / 10, duration: 0.12)
            ]))
        }
        tiko.pose(.interact)
    }

    private func sortingObjectNode(_ object: PuzzleSortObject) -> SKNode {
        let root = SKNode()

        let stone = SKShapeNode(circleOfRadius: 48)
        stone.fillColor = UIColor(red: 0.34, green: 0.27, blue: 0.46, alpha: 1)
        stone.strokeColor = UIColor(red: 0.88, green: 0.73, blue: 0.38, alpha: 1)
        stone.lineWidth = 5
        stone.name = "sortingObject"
        root.addChild(stone)

        let shape = ArtSystem.label(object.glyph, size: 39)
        shape.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.60, alpha: 1)
        shape.position.y = 8
        shape.name = "sortingObject"
        root.addChild(shape)

        let marks = ArtSystem.label(object.marks, size: 19)
        marks.fontColor = UIColor(red: 0.86, green: 0.78, blue: 1.0, alpha: 1)
        marks.position.y = -27
        marks.name = "sortingObject"
        root.addChild(marks)

        return root
    }

    private func handleSortPedestal(_ bucket: PuzzleSortBucket) {
        guard place == .sortingPedestal,
              sortAcceptingInput,
              let sortEncounter,
              sortTrialIndex < sortEncounter.objects.count else { return }

        sortAcceptingInput = false
        let object = sortEncounter.objects[sortTrialIndex]
        let rule = sortEncounter.rules[sortTrialIndex]
        let expected = object.bucket(for: rule)

        guard bucket == expected else {
            attempts += 1
            let attemptSupport = support
            _ = state.recordPuzzle(
                sortEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            tiko.pose(.react)
            highlightSortingDimension(rule)
            instruction.text = support == .lightHint
                ? sortingHint(for: rule)
                : "Tiko is pointing to the active rule. Ignore the other feature and try again."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.16 : 0.55),
                .run { [weak self] in
                    self?.sortAcceptingInput = true
                }
            ]), withKey: "sortRetry")
            return
        }

        let destination = bucket == .left
            ? CGPoint(x: 530, y: 355)
            : CGPoint(x: 970, y: 355)
        valkyrie.pose(.interact)
        tiko.pose(.interact)

        if let token = childNode(withName: "sortingObject") {
            token.run(.group([
                .move(to: destination, duration: reducedMotion ? 0 : 0.24),
                .scale(to: 0.72, duration: reducedMotion ? 0 : 0.24),
                .fadeAlpha(to: 0.35, duration: reducedMotion ? 0 : 0.24)
            ]))
        }

        sortTrialIndex += 1
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.10 : 0.32),
            .run { [weak self] in self?.presentSortTrial() }
        ]), withKey: "sortNext")
    }

    private func sortingHint(for rule: PuzzleSortRule) -> String {
        switch rule {
        case .shape:
            return "Use only the SHAPE cue: round goes left, pointed goes right."
        case .marks:
            return "Use only the MARKS cue: one mark goes left, two marks go right."
        }
    }

    private func highlightSortingDimension(_ rule: PuzzleSortRule) {
        guard let dial = childNode(withName: "sortingRuleDial") as? SKShapeNode else { return }
        dial.glowWidth = 16
        dial.strokeColor = rule == .shape
            ? UIColor(red: 0.96, green: 0.76, blue: 0.35, alpha: 1)
            : UIColor(red: 0.70, green: 0.84, blue: 1.0, alpha: 1)
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.12 : 0.55),
            .run { [weak dial] in
                dial?.glowWidth = 0
                dial?.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 1)
            }
        ]), withKey: "sortHintGlow")
    }

    private func completeSortingEncounter() {
        guard let sortEncounter else { return }
        sortAcceptingInput = false
        attempts += 1
        solved = true
        let attemptSupport = support

        _ = state.recordPuzzle(
            sortEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshSortingProgress(animated: true)
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        if state.puzzleSortingPedestalComplete {
            restoreSortingPedestal()
            return
        }

        let wasFoundation = sortEncounter.skillID == PuzzleSkills.singleRuleSort
        if wasFoundation && state.puzzleSortingFoundationComplete {
            instruction.text = "The stable sorts are secure. Tiko turned the dial—now the rule can change."
        } else {
            instruction.text = attemptSupport == .independent
                ? "That sorting run is stable. The pedestal is preparing the next rule."
                : "That run is stable. Try the next one independently."
        }

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.22 : 0.95),
            .run { [weak self] in
                guard let self else { return }
                self.sortEncounter = self.state.nextPuzzleSortingEncounter()
                self.buildSortingEncounter()
            }
        ]), withKey: "nextSortEncounter")
    }

    private func refreshSortingProgress(animated: Bool) {
        let foundation = PuzzlePalaceDirector.independentSortSuccessCount(
            for: PuzzlePalaceEncounterCatalog.sortingFoundation,
            skill: PuzzleSkills.singleRuleSort,
            profile: state.profile
        )
        let switching = PuzzlePalaceDirector.independentSortSuccessCount(
            for: PuzzlePalaceEncounterCatalog.ruleSwitching,
            skill: PuzzleSkills.ruleSwitching,
            profile: state.profile
        )

        for index in 0..<3 {
            if let light = childNode(withName: "sortingProgress\(index)") as? SKShapeNode {
                let active = index < foundation
                light.fillColor = active
                    ? UIColor(red: 0.95, green: 0.72, blue: 0.29, alpha: 1)
                    : UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
                light.glowWidth = active ? 9 : 0
                if active && animated && !reducedMotion {
                    light.run(.sequence([
                        .scale(to: 1.20, duration: 0.14),
                        .scale(to: 1.0, duration: 0.18)
                    ]))
                }
            }
            if let light = childNode(withName: "switchProgress\(index)") as? SKShapeNode {
                let active = index < switching
                light.fillColor = active
                    ? UIColor(red: 0.58, green: 0.81, blue: 0.96, alpha: 1)
                    : UIColor(red: 0.24, green: 0.18, blue: 0.36, alpha: 0.92)
                light.glowWidth = active ? 8 : 0
            }
        }
    }

    private func restoreSortingPedestal() {
        removeAction(forKey: "sortStart")
        removeAction(forKey: "sortRetry")
        removeAction(forKey: "sortNext")
        removeAction(forKey: "nextSortEncounter")
        sortAcceptingInput = false
        childNode(withName: "sortingObject")?.removeFromParent()
        refreshSortingProgress(animated: true)

        if let dial = childNode(withName: "sortingRuleDial") as? SKShapeNode {
            dial.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1)
            dial.glowWidth = 14
        }
        for name in ["sortLeftPedestal", "sortRightPedestal"] {
            if let root = childNode(withName: name),
               let bowl = root.children.compactMap({ $0 as? SKShapeNode }).first {
                bowl.strokeColor = UIColor(red: 0.72, green: 0.92, blue: 0.54, alpha: 1)
                bowl.glowWidth = 10
            }
        }

        showResortVaultRoute()
        instruction.text = "Sorting Pedestal is stable. Tiko found the Re-sort Vault."
    }

    private func showResortVaultRoute() {
        guard state.puzzleResortAvailable,
              childNode(withName: "resortVaultRoute") == nil else { return }
        let route = hotspot(
            "Re-sort Vault →",
            name: "resortVaultRoute",
            at: CGPoint(x: 1000, y: 165),
            size: CGSize(width: 205, height: 58)
        )
        route.zPosition = 845
    }

    private func buildResortWorld() {
        let vault = SKShapeNode(rectOf: CGSize(width: 830, height: 285), cornerRadius: 58)
        vault.fillColor = UIColor(red: 0.09, green: 0.07, blue: 0.17, alpha: 0.78)
        vault.strokeColor = UIColor(red: 0.50, green: 0.41, blue: 0.76, alpha: 0.78)
        vault.lineWidth = 6
        vault.position = CGPoint(x: 755, y: 395)
        vault.name = "resortVault"
        vault.zPosition = 115
        addChild(vault)

        buildSortPedestal(at: CGPoint(x: 475, y: 300), name: "resortLeftPedestal")
        buildSortPedestal(at: CGPoint(x: 1035, y: 300), name: "resortRightPedestal")

        let dial = SKShapeNode(circleOfRadius: 76)
        dial.fillColor = UIColor(red: 0.19, green: 0.14, blue: 0.31, alpha: 0.98)
        dial.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 1)
        dial.lineWidth = 7
        dial.position = CGPoint(x: 755, y: 535)
        dial.name = "resortRuleDial"
        dial.zPosition = 580
        addChild(dial)

        let glyph = ArtSystem.label("●  ▲", size: 29)
        glyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1)
        glyph.name = "resortRuleGlyph"
        dial.addChild(glyph)

        let passLabel = ArtSystem.label("FIRST SORT", size: 19)
        passLabel.fontColor = UIColor(red: 0.88, green: 0.81, blue: 1.0, alpha: 1)
        passLabel.position = CGPoint(x: 755, y: 615)
        passLabel.name = "resortPassLabel"
        passLabel.zPosition = 590
        addChild(passLabel)

        let door = SKShapeNode(rectOf: CGSize(width: 105, height: 245), cornerRadius: 34)
        door.fillColor = UIColor(red: 0.13, green: 0.10, blue: 0.22, alpha: 0.94)
        door.strokeColor = UIColor(red: 0.56, green: 0.46, blue: 0.82, alpha: 0.90)
        door.lineWidth = 7
        door.position = CGPoint(x: 1135, y: 415)
        door.name = "resortDoor"
        door.zPosition = 360
        addChild(door)

        for index in 0..<PuzzlePalaceEncounterCatalog.changedRuleResort.count {
            let light = SKShapeNode(circleOfRadius: 17)
            light.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.strokeColor = UIColor(red: 0.65, green: 0.55, blue: 0.92, alpha: 0.82)
            light.lineWidth = 3
            light.position = CGPoint(x: 970 + CGFloat(index) * 58, y: 575)
            light.name = "resortProgress\(index)"
            light.zPosition = 600
            addChild(light)
        }

        let back = hotspot(
            "← Sorting Pedestal",
            name: "sortingBack",
            at: CGPoint(x: 1080, y: 665),
            size: CGSize(width: 220, height: 52)
        )
        back.zPosition = 2050
    }

    private func buildResortEncounter() {
        guard let resortEncounter else { return }
        removeAction(forKey: "resortNext")
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        resortPass = 0
        resortObjectIndex = 0
        resortAcceptingInput = false
        clearResortTokens()

        for (index, object) in resortEncounter.objects.enumerated() {
            let token = sortingObjectNode(object)
            token.name = "resortToken\(index)"
            token.position = resortStartPositions[index]
            token.zPosition = 650
            addChild(token)
        }

        updateResortRule(resortEncounter.initialRule)
        instruction.text = resortEncounter.prompt
        presentResortObject()
    }

    private func clearResortTokens() {
        for index in 0..<8 {
            childNode(withName: "resortToken\(index)")?.removeFromParent()
        }
    }

    private func currentResortRule() -> PuzzleSortRule? {
        guard let resortEncounter else { return nil }
        return resortPass == 0 ? resortEncounter.initialRule : resortEncounter.changedRule
    }

    private func updateResortRule(_ rule: PuzzleSortRule) {
        guard let left = childNode(withName: "resortLeftPedestal"),
              let right = childNode(withName: "resortRightPedestal"),
              let dial = childNode(withName: "resortRuleDial"),
              let dialGlyph = dial.childNode(withName: "resortRuleGlyph") as? SKLabelNode,
              let leftGlyph = left.childNode(withName: "resortLeftPedestalGlyph") as? SKLabelNode,
              let rightGlyph = right.childNode(withName: "resortRightPedestalGlyph") as? SKLabelNode else {
            return
        }

        switch rule {
        case .shape:
            dialGlyph.text = "●  ▲"
            leftGlyph.text = "●"
            rightGlyph.text = "▲"
        case .marks:
            dialGlyph.text = "•  ••"
            leftGlyph.text = "•"
            rightGlyph.text = "••"
        }

        if let label = childNode(withName: "resortPassLabel") as? SKLabelNode {
            label.text = resortPass == 0 ? "FIRST SORT" : "SAME SET · NEW RULE"
        }
        if !reducedMotion {
            dial.run(.sequence([
                .rotate(byAngle: .pi / 8, duration: 0.14),
                .rotate(byAngle: -.pi / 8, duration: 0.14)
            ]))
        }
        tiko.pose(.interact)
    }

    private func presentResortObject() {
        guard let resortEncounter,
              resortObjectIndex < resortEncounter.objects.count else {
            finishResortPass()
            return
        }

        resortAcceptingInput = true
        for index in 0..<resortEncounter.objects.count {
            guard let token = childNode(withName: "resortToken\(index)") else { continue }
            let active = index == resortObjectIndex
            token.alpha = active ? 1.0 : max(token.alpha, 0.48)
            token.setScale(active ? 1.12 : 0.82)
        }

        instruction.text = resortPass == 0
            ? "Sort the highlighted stone using the first rule."
            : "The rule changed. Re-sort this SAME stone set using the new rule."
    }

    private func handleResortPedestal(_ bucket: PuzzleSortBucket) {
        guard place == .resortVault,
              resortAcceptingInput,
              let resortEncounter,
              let rule = currentResortRule(),
              resortObjectIndex < resortEncounter.objects.count else { return }

        resortAcceptingInput = false
        let object = resortEncounter.objects[resortObjectIndex]
        let expected = object.bucket(for: rule)

        guard bucket == expected else {
            attempts += 1
            let attemptSupport = support
            _ = state.recordPuzzle(
                resortEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            tiko.pose(.react)
            highlightResortRule(rule)
            instruction.text = support == .lightHint
                ? sortingHint(for: rule)
                : "The set stayed the same, but the RULE changed. Follow only the glowing rule."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.16 : 0.55),
                .run { [weak self] in self?.resortAcceptingInput = true }
            ]), withKey: "resortRetry")
            return
        }

        guard let token = childNode(withName: "resortToken\(resortObjectIndex)") else {
            resortAcceptingInput = true
            return
        }
        let sideX: CGFloat = bucket == .left ? 475 : 1035
        let offset = CGFloat(resortObjectIndex % 2) * 34 - 17
        let destination = CGPoint(x: sideX + offset, y: 335 + CGFloat(resortObjectIndex / 2) * 38)
        valkyrie.pose(.interact)
        tiko.pose(.interact)
        token.run(.move(to: destination, duration: reducedMotion ? 0 : 0.24))
        token.setScale(0.72)

        resortObjectIndex += 1
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.10 : 0.30),
            .run { [weak self] in self?.presentResortObject() }
        ]), withKey: "resortNext")
    }

    private func finishResortPass() {
        guard let resortEncounter else { return }
        resortAcceptingInput = false

        if resortPass == 0 {
            resortPass = 1
            resortObjectIndex = 0
            updateResortRule(resortEncounter.changedRule)
            instruction.text = "The vault flipped the rule. Tiko is returning the SAME stones to center."

            for index in 0..<resortEncounter.objects.count {
                guard let token = childNode(withName: "resortToken\(index)") else { continue }
                token.run(.move(to: resortStartPositions[index], duration: reducedMotion ? 0 : 0.38))
                token.setScale(0.82)
                token.alpha = 1
            }

            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.16 : 0.62),
                .run { [weak self] in self?.presentResortObject() }
            ]), withKey: "resortNext")
            return
        }

        attempts += 1
        solved = true
        let attemptSupport = support
        _ = state.recordPuzzle(
            resortEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshResortProgress(animated: true)
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        if state.puzzleResortComplete {
            restoreResortVault()
            return
        }

        instruction.text = attemptSupport == .independent
            ? "Same stones, new rule—both sorts held. Another vault set is waking."
            : "That re-sort is stable. Repeat this same-set rule change independently."

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.22 : 0.95),
            .run { [weak self] in
                guard let self else { return }
                self.resortEncounter = self.state.nextPuzzleResortEncounter()
                self.buildResortEncounter()
            }
        ]), withKey: "nextResortEncounter")
    }

    private func highlightResortRule(_ rule: PuzzleSortRule) {
        guard let dial = childNode(withName: "resortRuleDial") as? SKShapeNode else { return }
        dial.glowWidth = 17
        dial.strokeColor = rule == .shape
            ? UIColor(red: 0.96, green: 0.76, blue: 0.35, alpha: 1)
            : UIColor(red: 0.66, green: 0.85, blue: 1.0, alpha: 1)
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.12 : 0.55),
            .run { [weak dial] in
                dial?.glowWidth = 0
                dial?.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 1)
            }
        ]), withKey: "resortHintGlow")
    }

    private func refreshResortProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.changedRuleResortIndependentSuccessCount(
            profile: state.profile
        )
        for index in 0..<PuzzlePalaceEncounterCatalog.changedRuleResort.count {
            guard let light = childNode(withName: "resortProgress\(index)") as? SKShapeNode else {
                continue
            }
            let active = index < count
            light.fillColor = active
                ? UIColor(red: 0.95, green: 0.72, blue: 0.29, alpha: 1)
                : UIColor(red: 0.25, green: 0.19, blue: 0.38, alpha: 0.96)
            light.glowWidth = active ? 10 : 0
            if active && animated && !reducedMotion {
                light.run(.sequence([
                    .scale(to: 1.22, duration: 0.14),
                    .scale(to: 1.0, duration: 0.18)
                ]))
            }
        }
    }

    private func restoreResortVault() {
        removeAction(forKey: "resortRetry")
        removeAction(forKey: "resortNext")
        removeAction(forKey: "nextResortEncounter")
        removeAction(forKey: "nextMirrorOrientation")
        removeAction(forKey: "nextMirrorRotation")
        resortAcceptingInput = false
        refreshResortProgress(animated: true)

        if let label = childNode(withName: "resortPassLabel") as? SKLabelNode {
            label.text = "VAULT STABLE"
        }
        if let dial = childNode(withName: "resortRuleDial") as? SKShapeNode {
            dial.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1)
            dial.glowWidth = 15
        }
        if let door = childNode(withName: "resortDoor") as? SKShapeNode {
            door.fillColor = UIColor(red: 0.15, green: 0.12, blue: 0.25, alpha: 0.42)
            door.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 1)
            door.glowWidth = 12
            door.xScale = 0.24
            door.alpha = 0.45
            door.name = "resortDoorOpen"
        }

        showMirrorHallRoute()
        instruction.text = "Re-sort Vault is stable. Tiko found the Mirror Hall."
    }

    private func showMirrorHallRoute() {
        guard state.puzzleMirrorHallAvailable,
              childNode(withName: "mirrorHallRoute") == nil else { return }
        let route = hotspot(
            "Mirror Hall →",
            name: "mirrorHallRoute",
            at: CGPoint(x: 1000, y: 165),
            size: CGSize(width: 190, height: 58)
        )
        route.zPosition = 845
    }

    private func decorateMirrorGlass(_ mirror: SKShapeNode) {
        let shine = SKShapeNode(rectOf: CGSize(width: 8, height: 84), cornerRadius: 4)
        shine.fillColor = .white.withAlphaComponent(0.16)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -54, y: 8)
        shine.zRotation = -0.15
        mirror.addChild(shine)
        let finial = SKShapeNode(circleOfRadius: 8)
        finial.fillColor = UIColor(red: 0.84, green: 0.71, blue: 0.43, alpha: 1)
        finial.strokeColor = .clear
        finial.position.y = 88
        mirror.addChild(finial)
    }

    private func buildMirrorMachinery() {
        for (index, point) in mirrorChoicePoints.enumerated() {
            let pedestal = SKShapeNode(rectOf: CGSize(width: 165, height: 32), cornerRadius: 8)
            pedestal.fillColor = UIColor(red: 0.33, green: 0.29, blue: 0.27, alpha: 1)
            pedestal.strokeColor = UIColor(red: 0.69, green: 0.58, blue: 0.38, alpha: 1)
            pedestal.lineWidth = 3
            pedestal.position = CGPoint(x: point.x, y: 231)
            pedestal.zPosition = 130
            pedestal.name = "mirrorPedestal\(index)"
            addChild(pedestal)
            let stem = SKShapeNode(rectOf: CGSize(width: 24, height: 62), cornerRadius: 5)
            stem.fillColor = pedestal.strokeColor
            stem.strokeColor = .clear
            stem.position = CGPoint(x: point.x, y: 260)
            stem.zPosition = 130
            addChild(stem)
            let receiver = SKShapeNode(circleOfRadius: 12)
            receiver.position = CGPoint(x: point.x, y: 230)
            receiver.fillColor = .darkGray
            receiver.strokeColor = .white.withAlphaComponent(0.6)
            receiver.name = "mirrorReceiver\(index)"
            receiver.zPosition = 140
            addChild(receiver)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 760, y: 470))
            path.addLine(to: CGPoint(x: point.x, y: 420))
            path.addLine(to: CGPoint(x: point.x, y: 245))
            let beam = SKShapeNode(path: path)
            beam.strokeColor = UIColor(red: 0.59, green: 0.93, blue: 1, alpha: 1)
            beam.lineWidth = 6
            beam.glowWidth = 8
            beam.name = "mirrorBeam\(index)"
            beam.zPosition = 120
            beam.alpha = 0.08
            addChild(beam)
        }
        let gear = ArtSystem.gear(radius: 37, symbol: "✦")
        gear.position = CGPoint(x: 1170, y: 485)
        gear.name = "mirrorRestorationGear"
        gear.zPosition = 150
        addChild(gear)
        powerMirrorMachinery(count: PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: state.profile))
    }

    private func powerMirrorMachinery(count: Int) {
        for index in 0..<3 {
            let powered = index < count
            childNode(withName: "mirrorBeam\(index)")?.alpha = powered ? 1 : 0.08
            if let receiver = childNode(withName: "mirrorReceiver\(index)") as? SKShapeNode {
                receiver.fillColor = powered ? .systemTeal : .darkGray
                receiver.glowWidth = powered ? 10 : 0
            }
        }
        if count == 3, let gear = childNode(withName: "mirrorRestorationGear"),
           gear.action(forKey: "restoredSpin") == nil, !reducedMotion {
            gear.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 15)), withKey: "restoredSpin")
        }
    }

    /// The curved track communicates magnitude without showing a scored shape's answer.
    private func buildVisualTurnCue(quarterTurns: Int) {
        childNode(withName: "mirrorTurnCue")?.removeFromParent()
        let cue = SKNode()
        cue.name = "mirrorTurnCue"
        cue.position = CGPoint(x: 760, y: 535)
        cue.zPosition = 625
        let end = CGFloat.pi / 2 - CGFloat(quarterTurns) * .pi / 2
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: 87, startAngle: .pi / 2, endAngle: end, clockwise: true)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = .systemYellow
        arc.lineWidth = 5
        cue.addChild(arc)
        let endpoint = CGPoint(x: cos(end) * 87, y: sin(end) * 87)
        let tangent = CGPoint(x: sin(end), y: -cos(end))
        let arrowPath = CGMutablePath()
        arrowPath.move(to: endpoint)
        arrowPath.addLine(to: CGPoint(x: endpoint.x - tangent.x * 17 - tangent.y * 8,
                                     y: endpoint.y - tangent.y * 17 + tangent.x * 8))
        arrowPath.addLine(to: CGPoint(x: endpoint.x - tangent.x * 17 + tangent.y * 8,
                                     y: endpoint.y - tangent.y * 17 - tangent.x * 8))
        arrowPath.closeSubpath()
        let arrow = SKShapeNode(path: arrowPath)
        arrow.fillColor = .systemYellow
        arrow.strokeColor = .clear
        cue.addChild(arrow)
        addChild(cue)
    }

    private func buildMirrorTurnPractice() {
        guard childNode(withName: "mirrorPracticeDial") == nil else { return }
        clearMirrorChoices()
        mirrorAcceptingInput = false
        childNode(withName: "//mirrorBeaconGlyph")?.isHidden = true
        if let title = childNode(withName: "mirrorHallTitle") as? SKLabelNode { title.text = "TRY A TURN WITH TIKO" }
        let arrow = ArtSystem.label("↑", size: 68)
        arrow.name = "mirrorPracticeArrow"
        arrow.position = CGPoint(x: 760, y: 535)
        arrow.zPosition = 610
        addChild(arrow)
        buildVisualTurnCue(quarterTurns: 1)
        let dial = worldGear("↻", name: "mirrorPracticeDial", at: CGPoint(x: 760, y: 440), radius: 43)
        dial.zPosition = 660
        instruction.text = "Tap the turning wheel. Watch Tiko's arrow turn."
    }

    private func turnPracticeDial() {
        guard !mirrorPracticeBusy, !mirrorPracticeReady,
              let arrow = childNode(withName: "mirrorPracticeArrow") else { return }
        mirrorPracticeBusy = true
        let destination = CGPoint(x: 580, y: 175)
        let turn = { [weak self, weak arrow] in
            guard let self, let arrow else { return }
            self.mirrorApproaching = false
            self.valkyrie.pose(.interact)
            self.tiko.face(toward: CGPoint(x: 760, y: 440))
            self.tiko.pose(.interact)
            self.state.audio.play("mirror_turn")
            let ready = { [weak self] in
                guard let self else { return }
                self.mirrorPracticeReady = true
                self.instruction.text = "Up became right. Tap the lantern to try the mirrors."
                let next = self.hotspot("→", name: "mirrorPracticeContinue", at: CGPoint(x: 1135, y: 165),
                                        size: CGSize(width: 110, height: 66))
                next.zPosition = 1500
            }
            if self.reducedMotion { arrow.zRotation = -.pi / 2; ready() }
            else { arrow.run(.sequence([.rotate(toAngle: -.pi / 2, duration: 1.1), .run(ready)])) }
        }
        if isNear(destination) { turn() }
        else {
            mirrorApproaching = true
            travel(to: destination, then: turn)
        }
    }

    private func clearMirrorPractice() {
        for name in ["mirrorPracticeDial", "mirrorPracticeArrow", "mirrorPracticeContinue"] {
            childNode(withName: name)?.removeFromParent()
        }
    }

    private func approachMirror(_ node: SKShapeNode, then operation: @escaping () -> Void) {
        guard mirrorAcceptingInput, !solved else { return }
        // Park beside the fixture, not in front of it. 220pt keeps Valkyrie's
        // rendered body clear of the 148pt mirror while preserving immediate taps
        // for a child who is already standing at the interaction station.
        let desired = CGPoint(x: node.position.x - 220, y: 175)
        let destination = actorSafeDestination(
            near: desired,
            avoiding: node.calculateAccumulatedFrame().insetBy(dx: -45, dy: -40)
        )
        let operate = { [weak self, weak node] in
            guard let self, let node, node.parent === self else { return }
            self.mirrorApproaching = false
            self.mirrorAcceptingInput = true
            self.valkyrie.face(toward: node.position)
            self.valkyrie.pose(.interact)
            self.tiko.face(toward: node.position)
            self.tiko.pose(.interact)
            self.state.audio.play("mirror_click")
            operation()
        }
        if isNear(destination) { operate() }
        else {
            mirrorAcceptingInput = false
            mirrorApproaching = true
            instruction.text = "Valkyrie and Tiko are checking this mirror."
            travel(to: destination, then: operate)
        }
    }

    private func addMirrorNextLantern() {
        guard childNode(withName: "mirrorNext") == nil else { return }
        let next = hotspot("→", name: "mirrorNext", at: CGPoint(x: 1135, y: 165),
                           size: CGSize(width: 110, height: 66))
        next.zPosition = 1500
    }

    private func finishMirrorRestoration() {
        mirrorAcceptingInput = false
        clearMirrorChoices()
        childNode(withName: "mirrorRotationSource")?.removeFromParent()
        childNode(withName: "mirrorTurnCue")?.removeFromParent()
        for index in 0..<4 { childNode(withName: "rotationQuarterMark\(index)")?.removeFromParent() }
        powerMirrorMachinery(count: 3)
        if let title = childNode(withName: "mirrorHallTitle") as? SKLabelNode { title.text = "THE PALACE LIGHT SHINES AGAIN" }
        if let glyph = childNode(withName: "//mirrorBeaconGlyph") as? SKLabelNode {
            glyph.isHidden = false
            glyph.text = "✦"
        }
        if childNode(withName: "mirrorRestoredHome") == nil {
            let home = hotspot("⌂", name: "mirrorRestoredHome", at: CGPoint(x: 1060, y: 165),
                               size: CGSize(width: 95, height: 66))
            home.zPosition = 1500
        }
        if state.puzzlePathTilesAvailable && childNode(withName: "pathTilesRoute") == nil {
            let route = hotspot("Path Tiles →", name: "pathTilesRoute", at: CGPoint(x: 1170, y: 165),
                                size: CGSize(width: 150, height: 66))
            route.zPosition = 1500
        }
        instruction.text = "The hall is restored. Tiko found a planning floor beyond the mirrors."
    }

    private func buildMirrorHallWorld() {
        // Keep the palace art visible. The old translucent rounded rectangle read like
        // a modal overlay; a low floor rail now anchors the machinery instead.
        let rail = SKShapeNode(rectOf: CGSize(width: 770, height: 20), cornerRadius: 8)
        rail.fillColor = UIColor(red: 0.25, green: 0.22, blue: 0.30, alpha: 0.78)
        rail.strokeColor = UIColor(red: 0.72, green: 0.61, blue: 0.40, alpha: 0.68)
        rail.lineWidth = 2
        rail.position = CGPoint(x: 760, y: 235)
        rail.name = "mirrorHallChamber"
        rail.zPosition = 112
        addChild(rail)
        buildMirrorMachinery()

        let beacon = SKShapeNode(circleOfRadius: 70)
        beacon.fillColor = UIColor(red: 0.16, green: 0.19, blue: 0.34, alpha: 0.98)
        beacon.strokeColor = UIColor(red: 0.64, green: 0.82, blue: 1.0, alpha: 1)
        beacon.lineWidth = 7
        beacon.position = CGPoint(x: 760, y: 535)
        beacon.name = "mirrorBeacon"
        beacon.zPosition = 600
        addChild(beacon)

        let glyph = ArtSystem.label("↑", size: 62)
        glyph.name = "mirrorBeaconGlyph"
        glyph.fontColor = UIColor(red: 0.92, green: 0.97, blue: 1.0, alpha: 1)
        beacon.addChild(glyph)

        let title = ArtSystem.label("FOLLOW TIKO'S LIGHT", size: 18)
        title.fontColor = UIColor(red: 0.83, green: 0.90, blue: 1.0, alpha: 1)
        title.position = CGPoint(x: 760, y: 640)
        title.name = "mirrorHallTitle"
        title.zPosition = 610
        addChild(title)

        for index in 0..<PuzzlePalaceEncounterCatalog.mirrorHallOrientation.count {
            let light = SKShapeNode(circleOfRadius: 16)
            light.fillColor = UIColor(red: 0.20, green: 0.24, blue: 0.38, alpha: 0.96)
            light.strokeColor = UIColor(red: 0.58, green: 0.73, blue: 0.96, alpha: 0.84)
            light.lineWidth = 3
            light.position = CGPoint(x: 1170, y: 485 - CGFloat(index) * 34)
            light.name = "mirrorProgress\(index)"
            light.zPosition = 620
            light.alpha = 0.01
            addChild(light)
        }

        let back = landmark(
            "Re-sort Vault",
            symbol: "‹",
            name: "resortVaultBack",
            at: CGPoint(x: 1050, y: 665),
            accent: UIColor(red: 0.64, green: 0.52, blue: 0.94, alpha: 1),
            width: 150
        )
        back.zPosition = 2050
    }

    private func buildMirrorHallEncounter() {
        guard let orientationEncounter else { return }
        removeAction(forKey: "nextMirrorOrientation")
        clearMirrorChoices()
        attempts = 0
        support = .independent
        startedAt = Date()
        solved = false
        mirrorAcceptingInput = true

        if let glyph = childNode(withName: "//mirrorBeaconGlyph") as? SKLabelNode {
            glyph.text = orientationEncounter.target.glyph
        }

        for (index, direction) in orientationEncounter.choices.enumerated() {
            let mirror = SKShapeNode(rectOf: CGSize(width: 148, height: 178), cornerRadius: 34)
            mirror.fillColor = UIColor(red: 0.13, green: 0.28, blue: 0.38, alpha: 0.82)
            mirror.strokeColor = UIColor(red: 0.84, green: 0.71, blue: 0.43, alpha: 1)
            mirror.lineWidth = 8
            decorateMirrorGlass(mirror)
            mirror.position = mirrorChoicePoints[index]
            mirror.name = "mirrorOrientationChoice"
            mirror.userData = NSMutableDictionary(dictionary: ["direction": direction.rawValue])
            mirror.zPosition = 650
            mirror.isAccessibilityElement = true
            mirror.accessibilityLabel = "Mirror pointing \(direction.rawValue)"

            let arrow = ArtSystem.label(direction.glyph, size: 58)
            arrow.fontColor = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1)
            mirror.addChild(arrow)
            addChild(mirror)
        }

        instruction.text = orientationEncounter.prompt
        tiko.pose(.interact)
    }

    private func clearMirrorChoices() {
        children.filter { $0.name == "mirrorOrientationChoice" || $0.name == "mirrorRotationChoice" }.forEach { $0.removeFromParent() }
    }

    private func mirrorChoice(at point: CGPoint) -> (node: SKShapeNode, direction: PuzzleOrientation)? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if current.name == "mirrorOrientationChoice",
                   let raw = current.userData?["direction"] as? String,
                   let direction = PuzzleOrientation(rawValue: raw),
                   let shape = current as? SKShapeNode {
                    return (shape, direction)
                }
                node = current.parent
            }
        }
        return nil
    }

    private func resolveMirrorChoice(_ direction: PuzzleOrientation, node: SKShapeNode) {
        guard place == .mirrorHall,
              mirrorAcceptingInput,
              let orientationEncounter else { return }

        mirrorAcceptingInput = false
        attempts += 1
        let attemptSupport = support

        guard direction == orientationEncounter.target else {
            _ = state.recordPuzzle(
                orientationEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            support = support == .independent ? .lightHint : .strongHint
            node.strokeColor = .systemRed
            nudge(node)
            valkyrie.pose(.react)
            tiko.pose(.react)
            if let beacon = childNode(withName: "mirrorBeacon") as? SKShapeNode {
                beacon.glowWidth = support == .lightHint ? 10 : 18
            }
            instruction.text = support == .lightHint
                ? "Keep Tiko's arrow direction fixed. Find the mirror pointing exactly the same way."
                : "Ignore where the mirror sits. Compare only the arrow direction, then try again."
            mirrorAcceptingInput = true
            return
        }

        solved = true
        _ = state.recordPuzzle(
            orientationEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        node.strokeColor = .systemGreen
        node.glowWidth = 16
        refreshMirrorHallProgress(animated: true)
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        instruction.text = state.puzzleMirrorHallComplete
            ? "The directions are aligned. Tap the lantern to try turning shapes."
            : "That mirror aligned. Tap the next lantern when you're ready."
        addMirrorNextLantern()
    }

    private func refreshMirrorHallProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.mirrorHallIndependentSuccessCount(
            profile: state.profile
        )
        for index in 0..<PuzzlePalaceEncounterCatalog.mirrorHallOrientation.count {
            guard let light = childNode(withName: "mirrorProgress\(index)") as? SKShapeNode else {
                continue
            }
            let active = index < count
            light.fillColor = active
                ? UIColor(red: 0.39, green: 0.84, blue: 0.98, alpha: 1)
                : UIColor(red: 0.20, green: 0.24, blue: 0.38, alpha: 0.96)
            light.glowWidth = active ? 10 : 0
            if active && animated && !reducedMotion {
                light.run(.sequence([
                    .scale(to: 1.24, duration: 0.14),
                    .scale(to: 1.0, duration: 0.18)
                ]))
            }
        }
    }

    private func restoreMirrorHall() {
        removeAction(forKey: "nextMirrorOrientation")
        mirrorAcceptingInput = false
        clearMirrorChoices()
        childNode(withName: "mirrorNext")?.removeFromParent()
        refreshMirrorHallProgress(animated: true)

        if let beacon = childNode(withName: "mirrorBeacon") as? SKShapeNode {
            beacon.strokeColor = UIColor(red: 0.38, green: 0.91, blue: 0.99, alpha: 1)
            beacon.glowWidth = 18
        }
        if let glyph = childNode(withName: "//mirrorBeaconGlyph") as? SKLabelNode {
            glyph.text = "✦"
        }
        if state.puzzleMirrorRotationComplete {
            finishMirrorRestoration()
        } else {
            rotationEncounter = state.nextPuzzleMirrorRotationEncounter()
            buildMirrorRotationEncounter()
        }
    }

    private func tileShapeNode(_ shape: PuzzleTileShape, tileSize: CGFloat) -> SKNode {
        let group = SKNode()
        let width = CGFloat(shape.cells.map(\.x).max()! + 1) * tileSize
        let height = CGFloat(shape.cells.map(\.y).max()! + 1) * tileSize
        for cell in shape.cells {
            let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 3)
            tile.fillColor = UIColor(red: 0.84, green: 0.94, blue: 1, alpha: 1)
            tile.strokeColor = UIColor(red: 0.38, green: 0.72, blue: 0.98, alpha: 1)
            tile.lineWidth = 2
            tile.position = CGPoint(x: (CGFloat(cell.x) + 0.5) * tileSize - width / 2,
                                    y: (CGFloat(cell.y) + 0.5) * tileSize - height / 2)
            group.addChild(tile)
        }
        return group
    }

    private func buildMirrorRotationEncounter() {
        guard let rotationEncounter else { return }
        if !mirrorPracticeReady && state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty {
            buildMirrorTurnPractice()
            return
        }
        childNode(withName: "mirrorNext")?.removeFromParent()
        clearMirrorChoices()
        childNode(withName: "mirrorRotationSource")?.removeFromParent()
        childNode(withName: "//mirrorBeaconGlyph")?.isHidden = true
        if let beacon = childNode(withName: "mirrorBeacon") as? SKShapeNode {
            beacon.glowWidth = 0
        }
        attempts = 0
        support = .independent
        startedAt = Date()
        mirrorAcceptingInput = true
        solved = false
        let source = tileShapeNode(rotationEncounter.source, tileSize: 28)
        source.position = CGPoint(x: 760, y: 535)
        source.zPosition = 610
        source.name = "mirrorRotationSource"
        addChild(source)
        if let title = childNode(withName: "mirrorHallTitle") as? SKLabelNode {
            title.text = "TURN THE WHOLE SHAPE"
        }
        // Keep the scored cue minimal: one curved direction/magnitude arrow around
        // the source shape. Extra quarter-dot HUD markers are deliberately omitted.
        for index in 0..<4 {
            childNode(withName: "rotationQuarterMark\(index)")?.removeFromParent()
        }
        for (index, shape) in rotationEncounter.choices.enumerated() {
            let mirror = SKShapeNode(rectOf: CGSize(width: 148, height: 178), cornerRadius: 34)
            mirror.fillColor = UIColor(red: 0.13, green: 0.28, blue: 0.38, alpha: 0.82)
            mirror.strokeColor = UIColor(red: 0.84, green: 0.71, blue: 0.43, alpha: 1)
            mirror.lineWidth = 8
            decorateMirrorGlass(mirror)
            mirror.position = mirrorChoicePoints[index]
            mirror.zPosition = 650
            mirror.name = "mirrorRotationChoice"
            mirror.userData = NSMutableDictionary(dictionary: ["choiceIndex": index])
            mirror.isAccessibilityElement = true
            mirror.accessibilityLabel = "Rotated shape choice \(index + 1)"
            mirror.addChild(tileShapeNode(shape, tileSize: 30))
            addChild(mirror)
        }
        instruction.text = "Turn the whole shape in your mind. Choose the matching mirror."
        buildVisualTurnCue(quarterTurns: rotationEncounter.quarterTurns)
        refreshMirrorRotationProgress()
        tiko.pose(.interact)
    }

    private func resolveMirrorRotationChoice(_ index: Int, node: SKShapeNode) {
        guard place == .mirrorHall, mirrorAcceptingInput, let rotationEncounter,
              rotationEncounter.choices.indices.contains(index) else { return }
        mirrorAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let correct = rotationEncounter.choices[index] == rotationEncounter.answer
        _ = state.recordPuzzle(rotationEncounter, outcome: correct ? .correct : .incorrect,
                               support: attemptSupport, attempts: attempts,
                               responseTime: Date().timeIntervalSince(startedAt))
        guard correct else {
            support = support == .independent ? .lightHint : .demonstration
            tactileFeedback(success: false)
            node.strokeColor = .systemRed
            nudge(node)
            tiko.pose(.react)
            valkyrie.pose(.react)
            if support == .lightHint {
                instruction.text = "Follow the curved arrow. Turn the whole shape; keep its arms joined."
            } else {
                instruction.text = "Watch Tiko turn it. Now find that shape in a mirror."
                state.audio.play("mirror_turn")
                if let source = childNode(withName: "mirrorRotationSource") {
                    source.removeAllActions()
                    source.zRotation = 0
                    source.run(.rotate(toAngle: -CGFloat(rotationEncounter.quarterTurns) * .pi / 2,
                                       duration: reducedMotion ? 0 : 1.1))
                }
            }
            mirrorAcceptingInput = true
            return
        }
        solved = true
        tactileFeedback(success: true)
        node.strokeColor = .systemGreen
        node.glowWidth = 16
        refreshMirrorRotationProgress()
        state.audio.play("success")
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)
        if state.puzzleMirrorRotationComplete {
            finishMirrorRestoration()
        } else {
            instruction.text = attemptSupport == .independent
                ? "A beam is shining! Tap the next lantern when you're ready."
                : "You did it together. Tap the lantern to try a different turn."
            addMirrorNextLantern()
        }
    }

    private func refreshMirrorRotationProgress() {
        let count = PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: state.profile)
        powerMirrorMachinery(count: count)
        for index in 0..<PuzzlePalaceEncounterCatalog.mirrorHallRotation.count {
            guard let light = childNode(withName: "mirrorProgress\(index)") as? SKShapeNode else { continue }
            light.fillColor = index < count ? .systemGreen : UIColor(red: 0.20, green: 0.24, blue: 0.38, alpha: 1)
            light.glowWidth = index < count ? 10 : 0
        }
    }


    private func buildPathTilesWorld() {
        let chamber = SKShapeNode(rectOf: CGSize(width: 860, height: 360), cornerRadius: 54)
        chamber.fillColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.24)
        chamber.strokeColor = UIColor(red: 0.44, green: 0.82, blue: 0.92, alpha: 0.55)
        chamber.lineWidth = 6
        chamber.position = CGPoint(x: 760, y: 400)
        chamber.name = "pathTilesChamber"
        chamber.zPosition = 100
        addChild(chamber)

        let title = ArtSystem.label("PATH TILES", size: 34)
        title.name = "pathTilesTitle"
        title.position = CGPoint(x: 760, y: 610)
        title.zPosition = 800
        addChild(title)

        for index in 0..<PuzzlePalaceEncounterCatalog.pathTileFamilies.count {
            let light = SKShapeNode(circleOfRadius: 15)
            light.fillColor = UIColor(red: 0.18, green: 0.24, blue: 0.34, alpha: 1)
            light.strokeColor = UIColor(red: 0.44, green: 0.82, blue: 0.92, alpha: 0.8)
            light.lineWidth = 3
            light.position = CGPoint(x: 680 + CGFloat(index) * 80, y: 565)
            light.name = "pathProgress\(index)"
            light.zPosition = 820
            addChild(light)
        }

        let back = hotspot("← Mirror Hall", name: "mirrorHallBack", at: CGPoint(x: 170, y: 665),
                           size: CGSize(width: 180, height: 52))
        back.zPosition = 2050
    }

    private func clearPathTilesChoices() {
        for index in 0..<3 {
            childNode(withName: "pathChoice\(index)")?.removeFromParent()
        }
        childNode(withName: "pathGrid")?.removeFromParent()
    }

    private func buildPathTilesEncounter(resetSupport: Bool = true) {
        guard let pathEncounter else { return }
        clearPathTilesChoices()
        attempts = 0
        if resetSupport { support = .independent }
        startedAt = Date()
        solved = false
        pathAcceptingInput = true

        let grid = SKNode()
        grid.name = "pathGrid"
        grid.position = CGPoint(x: 760, y: 420)
        grid.zPosition = 500
        addChild(grid)

        let tileSize: CGFloat = 66
        let originX = -CGFloat(pathEncounter.gridWidth - 1) * tileSize / 2
        let originY = -CGFloat(pathEncounter.gridHeight - 1) * tileSize / 2

        for y in 0..<pathEncounter.gridHeight {
            for x in 0..<pathEncounter.gridWidth {
                let tile = PuzzleTile(x: x, y: y)
                let square = SKShapeNode(rectOf: CGSize(width: 58, height: 58), cornerRadius: 10)
                square.position = CGPoint(x: originX + CGFloat(x) * tileSize,
                                          y: originY + CGFloat(y) * tileSize)
                square.lineWidth = 3
                square.strokeColor = UIColor(red: 0.45, green: 0.72, blue: 0.86, alpha: 0.75)
                if pathEncounter.blocked.contains(tile) {
                    square.fillColor = UIColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1)
                    let glyph = ArtSystem.label("✕", size: 24)
                    glyph.fontColor = .systemRed
                    square.addChild(glyph)
                } else {
                    square.fillColor = UIColor(red: 0.15, green: 0.28, blue: 0.38, alpha: 0.96)
                }
                if tile == pathEncounter.start {
                    square.fillColor = UIColor(red: 0.21, green: 0.55, blue: 0.78, alpha: 1)
                    let glyph = ArtSystem.label("T", size: 25)
                    square.addChild(glyph)
                } else if tile == pathEncounter.goal {
                    square.fillColor = UIColor(red: 0.70, green: 0.52, blue: 0.16, alpha: 1)
                    let glyph = ArtSystem.label("★", size: 28)
                    square.addChild(glyph)
                }
                grid.addChild(square)
            }
        }

        let choiceYs: [CGFloat] = [300, 225, 150]
        for index in 0..<pathEncounter.choices.count {
            let arrows = pathEncounter.choices[index].map(\.glyph).joined(separator: " ")
            let choice = hotspot(arrows, name: "pathChoice\(index)",
                                 at: CGPoint(x: 1085, y: choiceYs[index]),
                                 size: CGSize(width: 260, height: 58))
            choice.userData = NSMutableDictionary(dictionary: ["choiceIndex": index])
            choice.zPosition = 900
        }

        instruction.text = pathEncounter.prompt
        tiko.pose(.interact)
    }

    private func resolvePathChoice(_ index: Int) {
        guard place == .pathTiles, pathAcceptingInput, let activeEncounter = pathEncounter,
              activeEncounter.choices.indices.contains(index) else { return }
        pathAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let correct = activeEncounter.isValidChoice(index)

        _ = state.recordPuzzle(activeEncounter, outcome: correct ? .correct : .incorrect,
                               support: attemptSupport, attempts: attempts,
                               responseTime: Date().timeIntervalSince(startedAt))

        guard correct else {
            tactileFeedback(success: false)
            support = support == .independent ? .lightHint : .strongHint
            instruction.text = support == .lightHint
                ? "Trace the whole route with your eyes first. A dark tile means the plan cannot work."
                : "Start at T, look all the way to ★, and reject any route that crosses ✕."
            tiko.pose(.react)
            valkyrie.pose(.react)
            pathEncounter = state.nextPuzzlePathTilesEncounter()
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0 : 0.45),
                .run { [weak self] in self?.buildPathTilesEncounter(resetSupport: false) }
            ]))
            return
        }

        solved = true
        tactileFeedback(success: true)
        let route = activeEncounter.route(for: index)
        animateTikoAlongPath(route, encounter: activeEncounter)
        refreshPathTilesProgress(animated: true)
    }

    private func animateTikoAlongPath(_ route: [PuzzleTile], encounter: PuzzlePathEncounter) {
        let tileSize: CGFloat = 66
        let originX = 760 - CGFloat(encounter.gridWidth - 1) * tileSize / 2
        let originY = 420 - CGFloat(encounter.gridHeight - 1) * tileSize / 2
        let actions: [SKAction] = route.dropFirst().map { tile in
            .move(to: CGPoint(x: originX + CGFloat(tile.x) * tileSize,
                              y: originY + CGFloat(tile.y) * tileSize),
                  duration: reducedMotion ? 0 : 0.18)
        }
        tiko.run(.sequence(actions + [
            .run { [weak self] in
                guard let self else { return }
                self.state.audio.play("success")
                self.tiko.pose(.celebrate)
                self.valkyrie.pose(.celebrate)
                if self.state.puzzlePathTilesComplete {
                    self.finishPathTiles()
                } else {
                    self.instruction.text = "That plan worked. Tap the next tile map."
                    if self.childNode(withName: "pathNext") == nil {
                        let next = self.hotspot("→", name: "pathNext",
                                                at: CGPoint(x: 1160, y: 95),
                                                size: CGSize(width: 105, height: 58))
                        next.zPosition = 1500
                    }
                }
            }
        ]))
    }

    private func refreshPathTilesProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.pathTilesIndependentSuccessCount(profile: state.profile)
        for index in 0..<PuzzlePalaceEncounterCatalog.pathTileFamilies.count {
            guard let light = childNode(withName: "pathProgress\(index)") as? SKShapeNode else { continue }
            light.fillColor = index < count ? .systemGreen : UIColor(red: 0.18, green: 0.24, blue: 0.34, alpha: 1)
            light.glowWidth = index < count ? 9 : 0
            if animated && index == max(0, count - 1) && !reducedMotion {
                light.run(.sequence([.scale(to: 1.2, duration: 0.12), .scale(to: 1.0, duration: 0.16)]))
            }
        }
    }

    private func finishPathTiles() {
        pathAcceptingInput = false
        clearPathTilesChoices()
        childNode(withName: "pathNext")?.removeFromParent()
        refreshPathTilesProgress(animated: true)
        if let title = childNode(withName: "pathTilesTitle") as? SKLabelNode {
            title.text = "PATH PLANNING RESTORED"
        }
        if childNode(withName: "pathTilesHome") == nil {
            let home = hotspot("⌂ Story Tree", name: "pathTilesHome",
                               at: CGPoint(x: 1085, y: 180),
                               size: CGSize(width: 220, height: 62))
            home.zPosition = 1500
        }
        instruction.text = "Tiko can see a safe route before moving. The next chamber can build on this planning skill."
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        handleTap(at: point)
    }

    private func resortPedestalTarget(at point: CGPoint) -> String? {
        let pedestalNames: Set<String> = [
            "resortLeftPedestal",
            "resortLeftPedestalGlyph",
            "resortRightPedestal",
            "resortRightPedestalGlyph"
        ]
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if let name = current.name, pedestalNames.contains(name) {
                    return name
                }
                node = current.parent
            }
        }
        return nil
    }

    func handleTap(at point: CGPoint) {
        let target = place == .resortVault
            ? (resortPedestalTarget(at: point) ?? targetName(at: point))
            : targetName(at: point)

        // A stray floor tap must not cancel the walk that will unlock this interaction.
        if place == .mirrorHall && mirrorApproaching
            && target != "home" && target != "resortVaultBack" { return }

        switch target {
        case "home":
            state.travel(to: .storyTree)

        case "runeChoice":
            guard place == .runeGate,
                  runeAcceptingInput,
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

        case "stopGoRoute":
            guard place == .memoryBridge, state.puzzleStopGoAvailable else { return }
            let destination = CGPoint(x: 1000, y: 175)
            if isNear(destination) {
                state.travel(to: .stopGoOrbs)
            } else {
                instruction.text = "Cross Memory Bridge to the orb chamber."
                travel(to: destination)
            }

        case "memoryBridgeBack":
            state.travel(to: .memoryBridge)

        case "stopGoOrb", "stopGoOrbCore", "stopGoOrbGlyph":
            handleStopGoOrbTap()

        case "sortingPedestalRoute":
            guard place == .stopGoOrbs, state.puzzleSortingAvailable else { return }
            let destination = CGPoint(x: 1000, y: 175)
            if isNear(destination) {
                state.travel(to: .sortingPedestal)
            } else {
                instruction.text = "Pass the stabilized orb barrier to the Sorting Pedestal."
                travel(to: destination)
            }

        case "stopGoBack":
            state.travel(to: .stopGoOrbs)

        case "sortLeftPedestal", "sortLeftPedestalGlyph":
            handleSortPedestal(.left)

        case "sortRightPedestal", "sortRightPedestalGlyph":
            handleSortPedestal(.right)

        case "resortVaultRoute":
            guard place == .sortingPedestal, state.puzzleResortAvailable else { return }
            let destination = CGPoint(x: 1000, y: 175)
            if isNear(destination) {
                state.travel(to: .resortVault)
            } else {
                instruction.text = "Follow Tiko through the stable pedestals to the Re-sort Vault."
                travel(to: destination)
            }

        case "sortingBack":
            state.travel(to: .sortingPedestal)

        case "resortLeftPedestal", "resortLeftPedestalGlyph":
            handleResortPedestal(.left)

        case "resortRightPedestal", "resortRightPedestalGlyph":
            handleResortPedestal(.right)

        case "mirrorHallRoute":
            guard place == .resortVault, state.puzzleMirrorHallAvailable else { return }
            let destination = CGPoint(x: 1000, y: 175)
            if isNear(destination) {
                state.travel(to: .mirrorHall)
            } else {
                instruction.text = "Follow Tiko through the stable vault into Mirror Hall."
                travel(to: destination)
            }

        case "resortVaultBack":
            state.travel(to: .resortVault)

        case "mirrorPracticeDial":
            turnPracticeDial()

        case "mirrorPracticeContinue":
            guard mirrorPracticeReady else { return }
            clearMirrorPractice()
            buildMirrorRotationEncounter()

        case "mirrorNext":
            guard solved, !state.puzzleMirrorRotationComplete else { return }
            childNode(withName: "mirrorNext")?.removeFromParent()
            if rotationEncounter != nil {
                rotationEncounter = state.nextPuzzleMirrorRotationEncounter()
                buildMirrorRotationEncounter()
            } else if state.puzzleMirrorHallComplete {
                restoreMirrorHall()
            } else {
                orientationEncounter = state.nextPuzzleMirrorHallEncounter()
                buildMirrorHallEncounter()
            }

        case "mirrorRestoredHome":
            state.travel(to: .storyTree)

        case "pathTilesRoute":
            guard place == .mirrorHall, state.puzzlePathTilesAvailable else { return }
            state.travel(to: .pathTiles)

        case "mirrorHallBack":
            state.travel(to: .mirrorHall)

        case "pathTilesHome":
            state.travel(to: .storyTree)

        case "pathNext":
            guard place == .pathTiles, solved, !state.puzzlePathTilesComplete else { return }
            childNode(withName: "pathNext")?.removeFromParent()
            pathEncounter = state.nextPuzzlePathTilesEncounter()
            buildPathTilesEncounter()

        case let name? where name.hasPrefix("pathChoice"):
            guard place == .pathTiles,
                  let index = Int(name.replacingOccurrences(of: "pathChoice", with: "")) else { return }
            resolvePathChoice(index)

        case "mirrorRotationChoice":
            guard place == .mirrorHall else { return }
            for hit in nodes(at: point) {
                var candidate: SKNode? = hit
                while let current = candidate {
                    if current.name == "mirrorRotationChoice",
                       let index = current.userData?["choiceIndex"] as? Int,
                       let shape = current as? SKShapeNode {
                        approachMirror(shape) { [weak self, weak shape] in
                            guard let self, let shape else { return }
                            self.resolveMirrorRotationChoice(index, node: shape)
                        }
                        return
                    }
                    candidate = current.parent
                }
            }

        case "mirrorOrientationChoice":
            guard place == .mirrorHall,
                  let choice = mirrorChoice(at: point) else { return }
            approachMirror(choice.node) { [weak self] in
                self?.resolveMirrorChoice(choice.direction, node: choice.node)
            }

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
        guard runeAcceptingInput, !solved else { return }
        runeAcceptingInput = false
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
        guard let encounter, !solved else { return }
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
            runeAcceptingInput = true
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
        runeAcceptingInput = false
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
        if place == .mirrorHall { state.audio.stop(channel: .ambience) }
        removeAction(forKey: "stopGoSignal")
        removeAction(forKey: "stopGoRetry")
        removeAction(forKey: "nextStopGo")
        removeAction(forKey: "sortStart")
        removeAction(forKey: "sortRetry")
        removeAction(forKey: "sortNext")
        removeAction(forKey: "nextSortEncounter")
        removeAction(forKey: "resortRetry")
        removeAction(forKey: "resortNext")
        removeAction(forKey: "nextResortEncounter")
        removeAction(forKey: "nextMirrorOrientation")
        removeAction(forKey: "nextMirrorRotation")
        tiko.cancelTravel()
        tiko.removeAllActions()
        super.willLeave()
    }
}

