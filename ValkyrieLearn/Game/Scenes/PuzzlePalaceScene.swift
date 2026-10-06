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
        case commandGears
        case bugLantern
        case bugLanternRepair
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
        case .commandGears: return "Puzzle Palace · Command Gears"
        case .bugLantern: return "Puzzle Palace · Bug Lantern"
        case .bugLanternRepair: return "Puzzle Palace · Repair Lab"
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
    private var sequenceEncounter: PuzzleSequenceEncounter?
    private var commandSteps: [PuzzleCommandStep] = []
    private var commandAcceptingInput = false
    private var bugEncounter: PuzzleBugEncounter?
    private var bugAcceptingInput = false
    private var bugIdentifiedIndex: Int?
    private var bugRepairReady = false
    private var repairEncounter: PuzzleRepairEncounter?
    private var repairSelection: [Int] = []
    private var repairAcceptingInput = false
    private var mirrorAcceptingInput = false
    private var mirrorPracticeReady = false
    private var mirrorPracticeBusy = false
    private var mirrorApproaching = false
    private let mirrorChoicePoints = [
        CGPoint(x: 525, y: 390),
        CGPoint(x: 765, y: 390),
        CGPoint(x: 1005, y: 390)
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
        case .commandGears:
            place = .commandGears
        case .bugLantern:
            place = .bugLantern
        case .bugLanternRepair:
            place = .bugLanternRepair
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
        valkyrie.setScale(0.56)
        tiko.setScale(0.92)
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
        case .commandGears:
            valkyrie.position = CGPoint(x: 180, y: 175)
            tiko.position = CGPoint(x: 305, y: 190)
        case .bugLantern:
            valkyrie.position = CGPoint(x: 180, y: 175)
            tiko.position = CGPoint(x: 305, y: 190)
        case .bugLanternRepair:
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
        case .commandGears:
            state.audio.play("palace_ambience", channel: .ambience, looping: true)
            guard state.puzzleCommandGearsAvailable else {
                instruction.text = "Restore Path Tiles planning before Tiko builds command chains."
                return
            }
            if state.puzzleCommandGearsComplete {
                finishCommandGears(celebrate: false)
            } else {
                sequenceEncounter = state.nextPuzzleCommandGearsEncounter()
                buildCommandGearsEncounter()
            }
        case .bugLantern:
            state.audio.play("palace_ambience", channel: .ambience, looping: true)
            guard state.puzzleBugLanternAvailable else {
                instruction.text = "Restore Command Gears before the Bug Lantern can inspect a plan."
                return
            }
            if state.puzzleBugLanternComplete {
                finishBugLantern(celebrate: false)
            } else {
                bugEncounter = state.nextPuzzleBugLanternEncounter()
                buildBugLanternEncounter()
            }
        case .bugLanternRepair:
            state.audio.play("palace_ambience", channel: .ambience, looping: true)
            guard state.puzzleBugRepairAvailable else {
                instruction.text = "Repair Lab needs Path Tiles planning, Command Gears sequencing, and the restored Bug Lantern."
                return
            }
            if state.puzzleBugRepairComplete {
                finishBugRepair()
            } else {
                repairEncounter = state.nextPuzzleBugRepairEncounter()
                buildBugRepairEncounter()
            }
        }
    }

    override func buildWorld() {
        buildNativePalaceBackdrop()

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
        case .commandGears:
            buildCommandGearsWorld()
            refreshCommandGearsProgress(animated: false)
        case .bugLantern:
            buildBugLanternWorld()
            refreshBugLanternProgress(animated: false)
        case .bugLanternRepair:
            buildBugRepairWorld()
            refreshBugRepairProgress(animated: false)
        }
    }


    private func buildNativePalaceBackdrop() {
        let base = ArtSystem.box(
            size,
            color: UIColor(red: 0.055, green: 0.055, blue: 0.13, alpha: 1),
            radius: 0
        )
        base.strokeColor = .clear
        base.position = CGPoint(x: 640, y: 360)
        base.zPosition = -260
        base.name = "puzzleNativeBackdrop"
        addChild(base)

        // Preserve the v3.31 palette as a distant matte only. The source quadrant is
        // 160x90 pixels, so it must never be the full-strength playable environment.
        if let atlas = ArtSystem.texture("V331WorldAtlas") {
            let puzzleTexture = SKTexture(
                rect: CGRect(x: 0.5, y: 0, width: 0.5, height: 0.5),
                in: atlas
            )
            puzzleTexture.filteringMode = .linear
            let matte = SKSpriteNode(texture: puzzleTexture, color: .white, size: size)
            matte.position = CGPoint(x: 640, y: 360)
            matte.zPosition = -250
            matte.alpha = 0.10
            matte.name = "puzzleLegacyMatte"
            addChild(matte)
        }

        let hall = ArtSystem.box(
            CGSize(width: 1080, height: 430),
            color: UIColor(red: 0.09, green: 0.08, blue: 0.20, alpha: 0.78),
            radius: 66
        )
        hall.strokeColor = UIColor(red: 0.52, green: 0.43, blue: 0.78, alpha: 0.72)
        hall.lineWidth = 4
        hall.position = CGPoint(x: 690, y: 390)
        hall.zPosition = -215
        hall.name = "puzzleArchitecture"
        addChild(hall)

        let floor = ArtSystem.box(
            CGSize(width: 1280, height: 205),
            color: UIColor(red: 0.13, green: 0.10, blue: 0.22, alpha: 0.98),
            radius: 0
        )
        floor.strokeColor = .clear
        floor.position = CGPoint(x: 640, y: 105)
        floor.zPosition = -145
        floor.name = "puzzleFloor"
        addChild(floor)

        if let courtyard = ArtSystem.sprite(
            "CastleCourtyard",
            size: CGSize(width: 1280, height: 235)
        ) {
            courtyard.position = CGPoint(x: 640, y: 118)
            courtyard.zPosition = -143
            courtyard.alpha = 0.78
            courtyard.color = UIColor(red: 0.55, green: 0.44, blue: 0.80, alpha: 1)
            courtyard.colorBlendFactor = 0.28
            courtyard.name = "puzzleFloorTexture"
            addChild(courtyard)
        }

        for x in stride(from: CGFloat(90), through: CGFloat(1190), by: CGFloat(140)) {
            let seam = ArtSystem.box(
                CGSize(width: 3, height: 195),
                color: UIColor(red: 0.36, green: 0.29, blue: 0.48, alpha: 0.10),
                radius: 1
            )
            seam.position = CGPoint(x: x, y: 108)
            seam.zPosition = -140
            addChild(seam)
        }
        for y in [CGFloat(55), CGFloat(110), CGFloat(165)] {
            let seam = ArtSystem.box(
                CGSize(width: 1260, height: 3),
                color: UIColor(red: 0.36, green: 0.29, blue: 0.48, alpha: 0.09),
                radius: 1
            )
            seam.position = CGPoint(x: 640, y: y)
            seam.zPosition = -140
            addChild(seam)
        }

        for x in [CGFloat(205), 405, 605, 805, 1005, 1205] {
            let pillar = ArtSystem.box(
                CGSize(width: 46, height: 350),
                color: UIColor(red: 0.12, green: 0.11, blue: 0.24, alpha: 1),
                radius: 12
            )
            pillar.strokeColor = UIColor(red: 0.55, green: 0.44, blue: 0.78, alpha: 0.58)
            pillar.lineWidth = 2
            pillar.position = CGPoint(x: x, y: 405)
            pillar.zPosition = -195
            pillar.name = "puzzlePillar"
            addChild(pillar)

            let cap = SKShapeNode(circleOfRadius: 31)
            cap.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.38, alpha: 1)
            cap.strokeColor = UIColor(red: 0.86, green: 0.67, blue: 0.32, alpha: 0.88)
            cap.lineWidth = 4
            cap.position = CGPoint(x: x, y: 565)
            cap.zPosition = -190
            addChild(cap)
        }

        for x in [CGFloat(320), 690, 1060] {
            let arch = SKShapeNode(
                rectOf: CGSize(width: 235, height: 285),
                cornerRadius: 108
            )
            arch.fillColor = UIColor(red: 0.07, green: 0.09, blue: 0.18, alpha: 0.72)
            arch.strokeColor = UIColor(red: 0.48, green: 0.67, blue: 0.88, alpha: 0.68)
            arch.lineWidth = 4
            arch.position = CGPoint(x: x, y: 410)
            arch.zPosition = -185
            addChild(arch)

            let inner = SKShapeNode(
                rectOf: CGSize(width: 177, height: 225),
                cornerRadius: 84
            )
            inner.fillColor = UIColor(red: 0.12, green: 0.18, blue: 0.31, alpha: 0.88)
            inner.strokeColor = UIColor(red: 0.67, green: 0.55, blue: 0.91, alpha: 0.78)
            inner.lineWidth = 4
            arch.addChild(inner)
        }

        for (index, point) in [
            CGPoint(x: 255, y: 545),
            CGPoint(x: 505, y: 515),
            CGPoint(x: 875, y: 515),
            CGPoint(x: 1125, y: 545)
        ].enumerated() {
            if let crystal = ArtSystem.sprite(
                "Crystal",
                size: CGSize(width: 66, height: 96)
            ) {
                crystal.position = point
                crystal.zPosition = -168
                crystal.alpha = index.isMultiple(of: 2) ? 0.82 : 0.66
                crystal.name = "puzzleCrystalFixture"
                addChild(crystal)
            }
        }

        let dais = ArtSystem.box(
            CGSize(width: 590, height: 58),
            color: UIColor(red: 0.20, green: 0.15, blue: 0.31, alpha: 0.96),
            radius: 24
        )
        dais.strokeColor = UIColor(red: 0.72, green: 0.57, blue: 0.30, alpha: 0.76)
        dais.lineWidth = 4
        dais.position = CGPoint(x: 775, y: 228)
        dais.zPosition = -105
        dais.name = "puzzleStageDais"
        addChild(dais)
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

        let rail = ArtSystem.panel(
            CGSize(width: 570, height: 38),
            fill: UIColor(red: 0.16, green: 0.11, blue: 0.25, alpha: 0.86),
            stroke: UIColor(red: 0.62, green: 0.50, blue: 0.86, alpha: 0.72),
            radius: 14,
            lineWidth: 3,
            shadowAlpha: 0.24
        )
        rail.position.y = -46
        rail.name = "runeBoard"
        board.addChild(rail)

        for x in [CGFloat(-190), CGFloat(-65), CGFloat(60), CGFloat(185)] {
            let bracket = ArtSystem.box(
                CGSize(width: 10, height: 44),
                color: UIColor(red: 0.50, green: 0.37, blue: 0.20, alpha: 0.82),
                radius: 4
            )
            bracket.position = CGPoint(x: x, y: -20)
            bracket.zPosition = -1
            board.addChild(bracket)
        }

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

        showAttentionCue(
            at: CGPoint(x: 770, y: 155),
            tint: UIColor(red: 0.76, green: 0.65, blue: 1.0, alpha: 1),
            width: 180
        )
    }

    private func runeStone(_ rune: String, name: String) -> SKNode {
        let stone = ArtSystem.panel(
            CGSize(width: 90, height: 82),
            fill: UIColor(red: 0.20, green: 0.15, blue: 0.34, alpha: 0.98),
            stroke: UIColor(red: 0.74, green: 0.62, blue: 0.96, alpha: 0.94),
            radius: 22,
            lineWidth: 4,
            shadowAlpha: 0.28,
            innerHighlight: UIColor(red: 0.86, green: 0.76, blue: 1.0, alpha: 0.12)
        )
        stone.name = name

        let jewel = SKShapeNode(circleOfRadius: 29)
        jewel.fillColor = UIColor(red: 0.28, green: 0.20, blue: 0.44, alpha: 0.72)
        jewel.strokeColor = UIColor(red: 0.90, green: 0.78, blue: 1.0, alpha: 0.32)
        jewel.lineWidth = 2
        jewel.name = name
        stone.addChild(jewel)

        let glyph = ArtSystem.label(rune, size: 41)
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.55, alpha: 1)
        glyph.name = name
        stone.addChild(glyph)
        return stone
    }

    private func runeSocket() -> SKNode {
        let socket = ArtSystem.panel(
            CGSize(width: 90, height: 82),
            fill: UIColor(red: 0.07, green: 0.055, blue: 0.14, alpha: 0.94),
            stroke: UIColor(red: 0.70, green: 0.62, blue: 0.90, alpha: 0.84),
            radius: 22,
            lineWidth: 4,
            shadowAlpha: 0.30
        )
        socket.glowWidth = 4
        socket.name = "runeSocket"

        let well = SKShapeNode(circleOfRadius: 29)
        well.fillColor = UIColor(red: 0.03, green: 0.025, blue: 0.08, alpha: 0.80)
        well.strokeColor = UIColor(red: 0.64, green: 0.57, blue: 0.84, alpha: 0.38)
        well.lineWidth = 2
        well.name = "runeSocket"
        socket.addChild(well)

        let mark = ArtSystem.label("?", size: 37)
        mark.fontColor = UIColor(red: 0.86, green: 0.81, blue: 0.96, alpha: 1)
        mark.name = "runeSocketMark"
        socket.addChild(mark)
        return socket
    }

    private func runeChoice(_ rune: String, index: Int) -> SKNode {
        let node = SKNode()

        let pedestal = SKShapeNode(ellipseOf: CGSize(width: 126, height: 66))
        pedestal.fillColor = UIColor(
            red: 0.22 + CGFloat(index) * 0.02,
            green: 0.16,
            blue: 0.36,
            alpha: 0.96
        )
        pedestal.strokeColor = UIColor(red: 0.76, green: 0.64, blue: 0.98, alpha: 0.94)
        pedestal.lineWidth = 4
        pedestal.name = "runeChoice"
        node.addChild(pedestal)

        let inset = SKShapeNode(ellipseOf: CGSize(width: 102, height: 46))
        inset.fillColor = UIColor(red: 0.34, green: 0.24, blue: 0.48, alpha: 0.40)
        inset.strokeColor = UIColor(white: 1, alpha: 0.12)
        inset.lineWidth = 1
        inset.name = "runeChoice"
        node.addChild(inset)

        let glyph = ArtSystem.label(rune, size: 41)
        glyph.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1)
        glyph.name = "runeChoice"
        node.addChild(glyph)

        let base = ArtSystem.panel(
            CGSize(width: 88, height: 24),
            fill: UIColor(red: 0.12, green: 0.09, blue: 0.22, alpha: 0.96),
            stroke: UIColor(red: 0.46, green: 0.36, blue: 0.68, alpha: 0.58),
            radius: 8,
            lineWidth: 2,
            shadowAlpha: 0.18
        )
        base.position.y = -47
        base.name = "runeChoice"
        base.zPosition = -1
        node.addChild(base)
        return node
    }

    private func clearRuneObjects() {
        childNode(withName: "runeBoard")?.removeFromParent()
        children.filter { $0.name == "runeChoice" }.forEach { $0.removeFromParent() }
        clearAttentionCue()
    }

    private func buildMemoryBridgeWorld() {
        let chasm = SKShapeNode(ellipseOf: CGSize(width: 735, height: 210))
        chasm.fillColor = UIColor(red: 0.025, green: 0.018, blue: 0.070, alpha: 0.52)
        chasm.strokeColor = UIColor(red: 0.40, green: 0.31, blue: 0.62, alpha: 0.50)
        chasm.lineWidth = 5
        chasm.position = CGPoint(x: 760, y: 405)
        chasm.name = "memoryChasm"
        chasm.zPosition = 110
        addChild(chasm)

        let innerVoid = SKShapeNode(ellipseOf: CGSize(width: 610, height: 150))
        innerVoid.fillColor = UIColor(red: 0.01, green: 0.008, blue: 0.04, alpha: 0.72)
        innerVoid.strokeColor = .clear
        innerVoid.position = CGPoint(x: 760, y: 405)
        innerVoid.zPosition = 112
        addChild(innerVoid)

        let mist = ArtSystem.label("✦     ·     ✦     ·     ✦", size: 27)
        mist.fontColor = UIColor(red: 0.66, green: 0.56, blue: 0.92, alpha: 0.34)
        mist.position = CGPoint(x: 760, y: 405)
        mist.name = "memoryChasmMist"
        mist.zPosition = 120
        addChild(mist)

        for index in 0..<4 {
            let plank = ArtSystem.panel(
                CGSize(width: 112, height: 58),
                fill: UIColor(red: 0.21, green: 0.15, blue: 0.34, alpha: 0.78),
                stroke: UIColor(red: 0.58, green: 0.47, blue: 0.82, alpha: 0.54),
                radius: 15,
                lineWidth: 3,
                shadowAlpha: 0.20
            )
            plank.position = CGPoint(x: 545 + CGFloat(index) * 145, y: 375)
            plank.yScale = 0.58
            plank.alpha = 0.55
            plank.name = "memoryBridgePlank\(index)"
            plank.zPosition = 270
            addChild(plank)
        }

        for x in [CGFloat(420), CGFloat(1100)] {
            let anchor = ArtSystem.medallion(
                radius: 28,
                fill: UIColor(red: 0.16, green: 0.11, blue: 0.28, alpha: 0.92),
                stroke: UIColor(red: 0.68, green: 0.56, blue: 0.92, alpha: 0.72),
                glow: reducedMotion ? 0 : 3
            )
            anchor.position = CGPoint(x: x, y: 395)
            anchor.zPosition = 275
            anchor.addChild(ArtSystem.label("◈", size: 24))
            addChild(anchor)
        }

        for index in 0..<PuzzlePalaceEncounterCatalog.memoryBridge.count {
            let light = ArtSystem.medallion(
                radius: 15,
                fill: UIColor(red: 0.20, green: 0.14, blue: 0.32, alpha: 0.96),
                stroke: UIColor(red: 0.66, green: 0.56, blue: 0.92, alpha: 0.72)
            )
            light.position = CGPoint(x: 1010 + CGFloat(index) * 58, y: 555)
            light.name = "memoryProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let startMarker = ArtSystem.plaque(
            CGSize(width: 82, height: 30),
            fill: UIColor(red: 0.09, green: 0.07, blue: 0.18, alpha: 0.86),
            stroke: UIColor(red: 0.66, green: 0.55, blue: 0.90, alpha: 0.56),
            radius: 14
        )
        startMarker.position = CGPoint(x: 345, y: 355)
        startMarker.zPosition = 320
        let markerLabel = ArtSystem.label("TIKO", size: 12)
        markerLabel.fontColor = UIColor(red: 0.88, green: 0.80, blue: 1.0, alpha: 1)
        startMarker.addChild(markerLabel)
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

        let stone = ArtSystem.medallion(
            radius: 47,
            fill: UIColor(
                red: 0.18 + CGFloat(index) * 0.02,
                green: 0.13,
                blue: 0.32,
                alpha: 0.98
            ),
            stroke: UIColor(red: 0.70, green: 0.60, blue: 0.96, alpha: 0.94)
        )
        stone.name = "memoryPad"
        root.addChild(stone)

        let glyph = ArtSystem.label(symbol, size: 37)
        glyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 1)
        glyph.name = "memoryPad"
        root.addChild(glyph)

        let foot = ArtSystem.panel(
            CGSize(width: 70, height: 20),
            fill: UIColor(red: 0.11, green: 0.08, blue: 0.20, alpha: 0.96),
            stroke: UIColor(red: 0.44, green: 0.35, blue: 0.66, alpha: 0.58),
            radius: 7,
            lineWidth: 2,
            shadowAlpha: 0.16
        )
        foot.position.y = -57
        foot.name = "memoryPad"
        foot.zPosition = -1
        root.addChild(foot)
        return root
    }

    private func clearMemoryPads() {
        children.filter { $0.name == "memoryPad" }.forEach { $0.removeFromParent() }
        clearAttentionCue()
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
            self.showAttentionCue(
                at: CGPoint(x: 745, y: 155),
                tint: UIColor(red: 0.76, green: 0.65, blue: 1.0, alpha: 1),
                width: 190
            )
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
        successFeedback()
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
        let route = worldGear("✦", name: "memoryBridgeRoute",
                              at: CGPoint(x: 1010, y: 175), radius: 34,
                              accessibilityLabel: "Continue to Memory Bridge")
        route.zPosition = 830
    }


    private func showStopGoRoute() {
        guard state.puzzleStopGoAvailable,
              childNode(withName: "stopGoRoute") == nil else { return }
        let route = worldGear("✦", name: "stopGoRoute",
                              at: CGPoint(x: 1010, y: 175), radius: 34,
                              accessibilityLabel: "Continue to Stop Go Orbs")
        route.zPosition = 835
    }

    private func buildStopGoWorld() {
        let upperRail = ArtSystem.panel(
            CGSize(width: 710, height: 24),
            fill: UIColor(red: 0.16, green: 0.11, blue: 0.25, alpha: 0.84),
            stroke: UIColor(red: 0.58, green: 0.47, blue: 0.82, alpha: 0.66),
            radius: 9,
            lineWidth: 2,
            shadowAlpha: 0.18
        )
        upperRail.position = CGPoint(x: 755, y: 402)
        upperRail.name = "stopGoRail"
        upperRail.zPosition = 180
        addChild(upperRail)

        let lowerRail = ArtSystem.panel(
            CGSize(width: 710, height: 24),
            fill: UIColor(red: 0.11, green: 0.08, blue: 0.20, alpha: 0.84),
            stroke: UIColor(red: 0.48, green: 0.39, blue: 0.72, alpha: 0.56),
            radius: 9,
            lineWidth: 2,
            shadowAlpha: 0.14
        )
        lowerRail.position = CGPoint(x: 755, y: 328)
        lowerRail.zPosition = 179
        addChild(lowerRail)

        for index in 0..<5 {
            let brace = ArtSystem.panel(
                CGSize(width: 46, height: 76),
                fill: UIColor(red: 0.16, green: 0.12, blue: 0.28, alpha: 0.94),
                stroke: UIColor(red: 0.56, green: 0.45, blue: 0.80, alpha: 0.66),
                radius: 12,
                lineWidth: 2,
                shadowAlpha: 0.18
            )
            brace.position = CGPoint(x: 505 + CGFloat(index) * 125, y: 365)
            brace.name = "stopGoBrace"
            brace.zPosition = 190
            addChild(brace)

            let rune = ArtSystem.label("◇", size: 17)
            rune.fontColor = UIColor(red: 0.76, green: 0.68, blue: 0.94, alpha: 0.56)
            brace.addChild(rune)
        }

        let orbRoot = SKNode()
        orbRoot.name = "stopGoOrb"
        orbRoot.position = CGPoint(x: 755, y: 365)
        orbRoot.zPosition = 620

        let ring = ArtSystem.medallion(
            radius: 83,
            fill: UIColor(red: 0.17, green: 0.12, blue: 0.30, alpha: 0.96),
            stroke: UIColor(red: 0.70, green: 0.58, blue: 0.96, alpha: 0.94),
            glow: reducedMotion ? 0 : 3
        )
        ring.name = "stopGoOrb"
        orbRoot.addChild(ring)

        let core = ArtSystem.medallion(
            radius: 49,
            fill: UIColor(red: 0.30, green: 0.22, blue: 0.44, alpha: 1),
            stroke: UIColor(red: 0.92, green: 0.82, blue: 1.0, alpha: 0.94)
        )
        core.name = "stopGoOrbCore"
        orbRoot.addChild(core)

        let glyph = ArtSystem.label("Ⅱ", size: 43)
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.58, alpha: 1)
        glyph.name = "stopGoOrbGlyph"
        orbRoot.addChild(glyph)
        addChild(orbRoot)

        let barrier = SKShapeNode(rectOf: CGSize(width: 98, height: 238), cornerRadius: 44)
        barrier.fillColor = UIColor(red: 0.09, green: 0.065, blue: 0.18, alpha: 0.76)
        barrier.strokeColor = UIColor(red: 0.62, green: 0.50, blue: 0.88, alpha: 0.76)
        barrier.lineWidth = 6
        barrier.position = CGPoint(x: 1095, y: 385)
        barrier.name = "stopGoBarrier"
        barrier.zPosition = 350
        addChild(barrier)

        let barrierRune = ArtSystem.label("◈", size: 30)
        barrierRune.fontColor = UIColor(red: 0.78, green: 0.68, blue: 1.0, alpha: 0.72)
        barrierRune.position = CGPoint(x: 1095, y: 385)
        barrierRune.zPosition = 355
        barrierRune.name = "stopGoBarrier"
        addChild(barrierRune)

        for index in 0..<PuzzlePalaceEncounterCatalog.stopGoOrbs.count {
            let light = ArtSystem.medallion(
                radius: 15,
                fill: UIColor(red: 0.20, green: 0.14, blue: 0.32, alpha: 0.96),
                stroke: UIColor(red: 0.66, green: 0.56, blue: 0.92, alpha: 0.72)
            )
            light.position = CGPoint(x: 970 + CGFloat(index) * 57, y: 555)
            light.name = "stopGoProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let back = worldControl("‹", name: "memoryBridgeBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Memory Bridge")
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
        let route = worldGear("✦", name: "sortingPedestalRoute",
                              at: CGPoint(x: 1010, y: 175), radius: 34,
                              accessibilityLabel: "Continue to Sorting Pedestal")
        route.zPosition = 840
    }

    private func buildSortingWorld() {
        let floor = SKShapeNode(ellipseOf: CGSize(width: 790, height: 230))
        floor.fillColor = UIColor(red: 0.07, green: 0.055, blue: 0.16, alpha: 0.48)
        floor.strokeColor = UIColor(red: 0.52, green: 0.42, blue: 0.78, alpha: 0.50)
        floor.lineWidth = 4
        floor.position = CGPoint(x: 750, y: 365)
        floor.name = "sortingFloor"
        floor.zPosition = 120
        addChild(floor)

        let runeRing = SKShapeNode(ellipseOf: CGSize(width: 650, height: 168))
        runeRing.fillColor = .clear
        runeRing.strokeColor = UIColor(red: 0.68, green: 0.55, blue: 0.90, alpha: 0.22)
        runeRing.lineWidth = 2
        runeRing.position = CGPoint(x: 750, y: 365)
        runeRing.zPosition = 121
        addChild(runeRing)

        buildSortPedestal(at: CGPoint(x: 530, y: 355), name: "sortLeftPedestal")
        buildSortPedestal(at: CGPoint(x: 970, y: 355), name: "sortRightPedestal")

        let dial = ArtSystem.medallion(
            radius: 72,
            fill: UIColor(red: 0.17, green: 0.12, blue: 0.29, alpha: 0.98),
            stroke: UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 0.94),
            glow: reducedMotion ? 0 : 3
        )
        dial.position = CGPoint(x: 750, y: 515)
        dial.name = "sortingRuleDial"
        dial.zPosition = 560
        addChild(dial)

        let ruleGlyph = ArtSystem.label("●  ▲", size: 28)
        ruleGlyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1)
        ruleGlyph.name = "sortingRuleGlyph"
        dial.addChild(ruleGlyph)

        let stage = ArtSystem.panel(
            CGSize(width: 156, height: 42),
            fill: UIColor(red: 0.12, green: 0.09, blue: 0.22, alpha: 0.86),
            stroke: UIColor(red: 0.48, green: 0.39, blue: 0.70, alpha: 0.52),
            radius: 16,
            lineWidth: 2,
            shadowAlpha: 0.18
        )
        stage.position = CGPoint(x: 750, y: 430)
        stage.name = "sortingObjectStage"
        stage.zPosition = 430
        addChild(stage)

        for index in 0..<3 {
            let light = ArtSystem.medallion(
                radius: 14,
                fill: UIColor(red: 0.20, green: 0.14, blue: 0.32, alpha: 0.96),
                stroke: UIColor(red: 0.66, green: 0.56, blue: 0.92, alpha: 0.72)
            )
            light.position = CGPoint(x: 1010 + CGFloat(index) * 55, y: 555)
            light.name = "sortingProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        for index in 0..<3 {
            let light = ArtSystem.medallion(
                radius: 11,
                fill: UIColor(red: 0.18, green: 0.13, blue: 0.28, alpha: 0.92),
                stroke: UIColor(red: 0.56, green: 0.47, blue: 0.82, alpha: 0.66)
            )
            light.position = CGPoint(x: 1010 + CGFloat(index) * 55, y: 515)
            light.name = "switchProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        let back = worldControl("‹", name: "stopGoBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Stop Go Orbs")
        back.zPosition = 2050
    }

    private func buildSortPedestal(at point: CGPoint, name: String) {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 420

        let bowl = SKShapeNode(ellipseOf: CGSize(width: 185, height: 82))
        bowl.fillColor = UIColor(red: 0.23, green: 0.16, blue: 0.38, alpha: 0.98)
        bowl.strokeColor = UIColor(red: 0.72, green: 0.59, blue: 0.96, alpha: 0.92)
        bowl.lineWidth = 5
        bowl.name = name
        root.addChild(bowl)

        let inset = SKShapeNode(ellipseOf: CGSize(width: 150, height: 56))
        inset.fillColor = UIColor(red: 0.31, green: 0.22, blue: 0.45, alpha: 0.34)
        inset.strokeColor = UIColor(white: 1, alpha: 0.10)
        inset.lineWidth = 1
        inset.name = name
        root.addChild(inset)

        let stem = ArtSystem.panel(
            CGSize(width: 72, height: 94),
            fill: UIColor(red: 0.12, green: 0.09, blue: 0.22, alpha: 0.98),
            stroke: UIColor(red: 0.46, green: 0.36, blue: 0.68, alpha: 0.58),
            radius: 16,
            lineWidth: 2,
            shadowAlpha: 0.18
        )
        stem.position.y = -78
        stem.name = name
        stem.zPosition = -1
        root.addChild(stem)

        let crest = ArtSystem.medallion(
            radius: 17,
            fill: UIColor(red: 0.20, green: 0.14, blue: 0.33, alpha: 0.96),
            stroke: UIColor(red: 0.68, green: 0.56, blue: 0.91, alpha: 0.72)
        )
        crest.position.y = -4
        crest.name = name
        stem.addChild(crest)

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
        let route = worldGear("✦", name: "resortVaultRoute",
                              at: CGPoint(x: 1010, y: 175), radius: 34,
                              accessibilityLabel: "Continue to Re-sort Vault")
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

        let back = worldControl("‹", name: "sortingBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Sorting Pedestal")
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
        let route = worldGear("✦", name: "mirrorHallRoute",
                              at: CGPoint(x: 1010, y: 175), radius: 34,
                              accessibilityLabel: "Continue to Mirror Hall")
        route.zPosition = 845
    }

    private func buildMirrorHallConceptAccents() {
        let root = SKNode()
        root.name = "decorativeMirrorHallConceptAccents"
        root.zPosition = 108
        root.isUserInteractionEnabled = false

        let compass = SKShapeNode(circleOfRadius: 76)
        compass.fillColor = UIColor(red: 0.18, green: 0.17, blue: 0.34, alpha: 0.10)
        compass.strokeColor = UIColor(red: 0.91, green: 0.70, blue: 0.30, alpha: 0.34)
        compass.lineWidth = 2
        compass.position = CGPoint(x: 765, y: 188)
        compass.name = "decorativeMirrorHallFloorCompass"
        root.addChild(compass)

        let innerCompass = SKShapeNode(circleOfRadius: 38)
        innerCompass.fillColor = .clear
        innerCompass.strokeColor = UIColor(red: 0.65, green: 0.80, blue: 1.0, alpha: 0.20)
        innerCompass.lineWidth = 1.5
        innerCompass.name = "decorativeMirrorHallFloorCompass"
        compass.addChild(innerCompass)

        for index in 0..<8 {
            let ray = SKShapeNode(rectOf: CGSize(width: 3, height: index.isMultiple(of: 2) ? 58 : 40), cornerRadius: 1.5)
            ray.fillColor = index.isMultiple(of: 2)
                ? UIColor(red: 0.96, green: 0.73, blue: 0.30, alpha: 0.34)
                : UIColor(red: 0.55, green: 0.72, blue: 0.98, alpha: 0.18)
            ray.strokeColor = .clear
            ray.position = CGPoint(x: 0, y: 38)
            ray.zRotation = CGFloat(index) * .pi / 4
            ray.name = "decorativeMirrorHallFloorCompass"
            compass.addChild(ray)
        }

        for (index, point) in mirrorChoicePoints.enumerated() {
            let arch = SKShapeNode(ellipseOf: CGSize(width: 182, height: 258))
            arch.fillColor = UIColor(red: 0.11, green: 0.12, blue: 0.28, alpha: 0.04)
            arch.strokeColor = UIColor(red: 0.48, green: 0.62, blue: 0.96, alpha: 0.12)
            arch.lineWidth = 3
            arch.position = CGPoint(x: point.x, y: point.y + 2)
            arch.name = "decorativeMirrorHallBackdropArch\(index)"
            root.addChild(arch)

            let pool = SKShapeNode(ellipseOf: CGSize(width: 172, height: 30))
            pool.fillColor = UIColor(red: 0.31, green: 0.44, blue: 0.86, alpha: 0.06)
            pool.strokeColor = UIColor(red: 0.84, green: 0.69, blue: 0.36, alpha: 0.16)
            pool.lineWidth = 1.5
            pool.position = CGPoint(x: point.x, y: 274)
            pool.name = "decorativeMirrorHallBackdropArch\(index)"
            root.addChild(pool)
        }

        let farGate = SKShapeNode(rectOf: CGSize(width: 132, height: 184), cornerRadius: 58)
        farGate.fillColor = UIColor(red: 0.08, green: 0.14, blue: 0.30, alpha: 0.18)
        farGate.strokeColor = UIColor(red: 0.55, green: 0.82, blue: 1.0, alpha: 0.34)
        farGate.lineWidth = 4
        farGate.position = CGPoint(x: 1140, y: 498)
        farGate.name = "decorativeMirrorHallFarGate"
        root.addChild(farGate)

        addChild(root)
    }

    private func decorateMirrorGlass(_ mirror: SKShapeNode) {
        mirror.fillColor = UIColor(red: 0.11, green: 0.22, blue: 0.39, alpha: 0.46)
        mirror.strokeColor = UIColor(red: 0.92, green: 0.70, blue: 0.30, alpha: 0.90)
        mirror.lineWidth = 5

        let innerGlass = SKShapeNode(ellipseOf: CGSize(width: 116, height: 148))
        innerGlass.fillColor = UIColor(red: 0.38, green: 0.69, blue: 0.92, alpha: 0.11)
        innerGlass.strokeColor = UIColor(white: 1.0, alpha: 0.24)
        innerGlass.lineWidth = 2
        innerGlass.name = "decorativeMirrorStationGlass"
        mirror.addChild(innerGlass)

        let shine = SKShapeNode(rectOf: CGSize(width: 10, height: 92), cornerRadius: 5)
        shine.fillColor = .white.withAlphaComponent(0.16)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -42, y: 10)
        shine.zRotation = -0.14
        shine.name = "decorativeMirrorStationGlass"
        mirror.addChild(shine)

        for x in [CGFloat(-77), CGFloat(77)] {
            let rail = SKShapeNode(rectOf: CGSize(width: 8, height: 124), cornerRadius: 4)
            rail.fillColor = UIColor(red: 0.78, green: 0.55, blue: 0.24, alpha: 0.82)
            rail.strokeColor = UIColor(red: 1.0, green: 0.83, blue: 0.45, alpha: 0.42)
            rail.lineWidth = 1
            rail.position = CGPoint(x: x, y: -4)
            rail.name = "decorativeMirrorStationFrame"
            mirror.addChild(rail)

            let jewel = SKShapeNode(circleOfRadius: 8)
            jewel.fillColor = UIColor(red: 0.36, green: 0.73, blue: 1.0, alpha: 0.96)
            jewel.strokeColor = UIColor(red: 0.95, green: 0.84, blue: 0.42, alpha: 0.96)
            jewel.lineWidth = 2
            jewel.position = CGPoint(x: x, y: 52)
            jewel.name = "decorativeMirrorStationFrame"
            mirror.addChild(jewel)
        }

        let crown = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 30))
            path.addLine(to: CGPoint(x: -20, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -30))
            path.addLine(to: CGPoint(x: 20, y: 0))
            path.closeSubpath()
            return path
        }())
        crown.position = CGPoint(x: 0, y: 116)
        crown.fillColor = UIColor(red: 0.48, green: 0.76, blue: 1.0, alpha: 0.84)
        crown.strokeColor = UIColor(red: 0.98, green: 0.76, blue: 0.34, alpha: 1)
        crown.lineWidth = 4
        crown.glowWidth = reducedMotion ? 0 : 5
        crown.name = "decorativeMirrorStationCrystal"
        mirror.addChild(crown)

        let control = ArtSystem.medallion(
            radius: 31,
            fill: UIColor(red: 0.08, green: 0.13, blue: 0.31, alpha: 0.96),
            stroke: UIColor(red: 0.91, green: 0.69, blue: 0.30, alpha: 0.94),
            glow: reducedMotion ? 0 : 3
        )
        control.position = CGPoint(x: 0, y: -112)
        control.name = "decorativeMirrorStationControl"
        mirror.addChild(control)

        let foot = SKShapeNode(ellipseOf: CGSize(width: 160, height: 28))
        foot.fillColor = UIColor(red: 0.24, green: 0.19, blue: 0.32, alpha: 0.94)
        foot.strokeColor = UIColor(red: 0.86, green: 0.65, blue: 0.30, alpha: 0.72)
        foot.lineWidth = 3
        foot.position = CGPoint(x: 0, y: -145)
        foot.name = "decorativeMirrorStationFoot"
        mirror.addChild(foot)
    }

    private func buildMirrorMachinery() {
        for (index, point) in mirrorChoicePoints.enumerated() {
            let pedestal = ArtSystem.panel(
                CGSize(width: 156, height: 34),
                fill: UIColor(red: 0.20, green: 0.16, blue: 0.26, alpha: 0.94),
                stroke: UIColor(red: 0.83, green: 0.62, blue: 0.28, alpha: 0.72),
                radius: 15,
                lineWidth: 2.5,
                shadowAlpha: 0.16,
                innerHighlight: UIColor(red: 0.80, green: 0.73, blue: 1.0, alpha: 0.05)
            )
            pedestal.position = CGPoint(x: point.x, y: 246)
            pedestal.zPosition = 128
            pedestal.name = "mirrorPedestal\(index)"
            addChild(pedestal)

            let receiver = SKShapeNode(circleOfRadius: 10)
            receiver.position = CGPoint(x: point.x, y: 246)
            receiver.fillColor = UIColor(red: 0.10, green: 0.16, blue: 0.26, alpha: 1)
            receiver.strokeColor = UIColor(red: 0.76, green: 0.82, blue: 1.0, alpha: 0.52)
            receiver.lineWidth = 2
            receiver.name = "mirrorReceiver\(index)"
            receiver.zPosition = 140
            addChild(receiver)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: 765, y: 520))
            path.addLine(to: CGPoint(x: point.x, y: 455))
            path.addLine(to: CGPoint(x: point.x, y: 260))
            let beam = SKShapeNode(path: path)
            beam.strokeColor = UIColor(red: 0.51, green: 0.83, blue: 1.0, alpha: 0.92)
            beam.lineWidth = 4
            beam.glowWidth = reducedMotion ? 0 : 7
            beam.name = "mirrorBeam\(index)"
            beam.zPosition = 120
            beam.alpha = 0.06
            addChild(beam)
        }

        let gear = ArtSystem.gear(radius: 33, symbol: "✦")
        gear.position = CGPoint(x: 1140, y: 498)
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
                let next = self.worldGear("✦", name: "mirrorPracticeContinue",
                                          at: CGPoint(x: 1150, y: 175), radius: 34,
                                          accessibilityLabel: "Try the mirrors")
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
        let destination = safeActorPoint(
            near: CGPoint(x: node.position.x - 235, y: 175),
            avoiding: [node.calculateAccumulatedFrame().insetBy(dx: -36, dy: -20)]
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
        let next = worldGear("✦", name: "mirrorNext", at: CGPoint(x: 1150, y: 175),
                             radius: 34, accessibilityLabel: "Next mirror")
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
            let home = worldControl("⌂", name: "mirrorRestoredHome",
                                    at: CGPoint(x: 1080, y: 175), radius: 30,
                                    accessibilityLabel: "Return to Story Tree")
            home.zPosition = 1500
        }
        if state.puzzlePathTilesAvailable && childNode(withName: "pathTilesRoute") == nil {
            let route = worldGear("→", name: "pathTilesRoute",
                                  at: CGPoint(x: 1170, y: 175), radius: 34,
                                  accessibilityLabel: "Continue to Path Tiles")
            route.zPosition = 1500
        }
        instruction.text = "The hall is restored. Tiko found a planning floor beyond the mirrors."
    }

    private func buildMirrorHallWorld() {
        // Keep the source palace artwork visible. The live objects are architectural
        // fixtures layered into the room, not a modal card floating over it.
        let floorRail = SKShapeNode(rectOf: CGSize(width: 780, height: 18), cornerRadius: 9)
        floorRail.fillColor = UIColor(red: 0.23, green: 0.18, blue: 0.34, alpha: 0.78)
        floorRail.strokeColor = UIColor(red: 0.61, green: 0.52, blue: 0.86, alpha: 0.60)
        floorRail.lineWidth = 2
        floorRail.position = CGPoint(x: 765, y: 282)
        floorRail.zPosition = 115
        floorRail.name = "mirrorHallRail"
        addChild(floorRail)

        buildMirrorHallConceptAccents()
        buildMirrorMachinery()

        let beacon = SKShapeNode(circleOfRadius: 58)
        beacon.fillColor = UIColor(red: 0.14, green: 0.18, blue: 0.31, alpha: 0.96)
        beacon.strokeColor = UIColor(red: 0.64, green: 0.82, blue: 1.0, alpha: 1)
        beacon.lineWidth = 6
        beacon.position = CGPoint(x: 765, y: 565)
        beacon.name = "mirrorBeacon"
        beacon.zPosition = 600
        addChild(beacon)

        let glyph = ArtSystem.label("↑", size: 54)
        glyph.name = "mirrorBeaconGlyph"
        glyph.fontColor = UIColor(red: 0.92, green: 0.97, blue: 1.0, alpha: 1)
        beacon.addChild(glyph)

        let titlePlate = ArtSystem.plaque(
            CGSize(width: 264, height: 38),
            fill: UIColor(red: 0.08, green: 0.09, blue: 0.19, alpha: 0.92),
            stroke: UIColor(red: 0.58, green: 0.73, blue: 0.98, alpha: 0.72),
            radius: 18
        )
        titlePlate.position = CGPoint(x: 765, y: 628)
        titlePlate.name = "mirrorHallTitlePlate"
        titlePlate.zPosition = 608
        addChild(titlePlate)

        let title = ArtSystem.label("FOLLOW TIKO'S LIGHT", size: 16)
        title.fontColor = UIColor(red: 0.90, green: 0.96, blue: 1.0, alpha: 1)
        title.position = CGPoint(x: 765, y: 628)
        title.name = "mirrorHallTitle"
        title.zPosition = 610
        addChild(title)

        for index in 0..<PuzzlePalaceEncounterCatalog.mirrorHallOrientation.count {
            let sconce = SKShapeNode(circleOfRadius: 14)
            sconce.fillColor = UIColor(red: 0.18, green: 0.22, blue: 0.35, alpha: 1)
            sconce.strokeColor = UIColor(red: 0.64, green: 0.79, blue: 0.98, alpha: 0.82)
            sconce.lineWidth = 3
            sconce.position = CGPoint(x: 713 + CGFloat(index) * 52, y: 590)
            sconce.name = "mirrorProgress\(index)"
            sconce.zPosition = 620
            addChild(sconce)

            let hook = SKShapeNode(rectOf: CGSize(width: 5, height: 25), cornerRadius: 2)
            hook.fillColor = UIColor(red: 0.58, green: 0.49, blue: 0.72, alpha: 0.8)
            hook.strokeColor = .clear
            hook.position = CGPoint(x: sconce.position.x, y: 620)
            hook.zPosition = 610
            addChild(hook)
        }

        let back = worldControl(
            "‹",
            name: "resortVaultBack",
            at: CGPoint(x: 1180, y: 665),
            radius: 30,
            accessibilityLabel: "Back to Re-sort Vault"
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
            let focusPool = SKShapeNode(ellipseOf: CGSize(width: 172, height: 34))
            focusPool.fillColor = UIColor(red: 0.20, green: 0.29, blue: 0.48, alpha: 0.26)
            focusPool.strokeColor = UIColor(red: 0.66, green: 0.73, blue: 0.98, alpha: 0.42)
            focusPool.lineWidth = 2
            focusPool.position = CGPoint(
                x: mirrorChoicePoints[index].x,
                y: mirrorChoicePoints[index].y - 108
            )
            focusPool.name = "mirrorChoicePool\(index)"
            focusPool.zPosition = 612
            addChild(focusPool)

            let mirror = SKShapeNode(ellipseOf: CGSize(width: 142, height: 176))
            mirror.fillColor = UIColor(red: 0.20, green: 0.34, blue: 0.43, alpha: 0.58)
            mirror.strokeColor = UIColor(red: 0.84, green: 0.71, blue: 0.43, alpha: 1)
            mirror.lineWidth = 7
            decorateMirrorGlass(mirror)
            mirror.position = mirrorChoicePoints[index]
            mirror.name = "mirrorOrientationChoice"
            mirror.userData = NSMutableDictionary(dictionary: ["direction": direction.rawValue])
            mirror.zPosition = 650

            let arrow = ArtSystem.label(direction.glyph, size: 58)
            arrow.fontColor = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 1)
            mirror.addChild(arrow)
            addChild(mirror)
            makeAccessible(mirror, label: "Mirror pointing \(direction.rawValue)")
            registerInteraction(mirror, clearance: 28)
        }

        instruction.text = orientationEncounter.prompt
        tiko.pose(.interact)
    }

    private func clearMirrorChoices() {
        children.filter {
            $0.name == "mirrorOrientationChoice"
                || $0.name == "mirrorRotationChoice"
                || ($0.name?.hasPrefix("mirrorChoicePool") ?? false)
        }.forEach { $0.removeFromParent() }
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
            errorFeedback()
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
        successFeedback()
        focusMoment(on: node.position)
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
        solved = false

        // Practice leaves Valkyrie near the center wheel. Re-stage her before
        // scored choices become active so her sprite can never cover mirror #1.
        let needsRestaging = valkyrie.position.x > 390
        mirrorAcceptingInput = !needsRestaging
        if needsRestaging {
            let actorTarget = CGPoint(x: 300, y: 175)
            let tikoTarget = CGPoint(x: 405, y: 190)
            if reducedMotion {
                valkyrie.position = actorTarget
                tiko.position = tikoTarget
                mirrorAcceptingInput = true
            } else {
                valkyrie.walk(to: actorTarget) { [weak self] in
                    self?.mirrorAcceptingInput = true
                }
                tiko.walk(to: tikoTarget) {}
            }
        }

        let source = tileShapeNode(rotationEncounter.source, tileSize: 28)
        source.position = CGPoint(x: 760, y: 535)
        source.zPosition = 610
        source.name = "mirrorRotationSource"
        addChild(source)
        if let title = childNode(withName: "mirrorHallTitle") as? SKLabelNode {
            title.text = "IMAGINE THE TURN"
        }
        // One curved cue communicates direction and magnitude. Avoid extra dots,
        // badges or labels that compete with the actual spatial reasoning task.
        for (index, shape) in rotationEncounter.choices.enumerated() {
            let focusPool = SKShapeNode(ellipseOf: CGSize(width: 172, height: 34))
            focusPool.fillColor = UIColor(red: 0.20, green: 0.29, blue: 0.48, alpha: 0.26)
            focusPool.strokeColor = UIColor(red: 0.66, green: 0.73, blue: 0.98, alpha: 0.42)
            focusPool.lineWidth = 2
            focusPool.position = CGPoint(
                x: mirrorChoicePoints[index].x,
                y: mirrorChoicePoints[index].y - 108
            )
            focusPool.name = "mirrorChoicePool\(index)"
            focusPool.zPosition = 612
            addChild(focusPool)

            let mirror = SKShapeNode(ellipseOf: CGSize(width: 142, height: 176))
            mirror.fillColor = UIColor(red: 0.20, green: 0.34, blue: 0.43, alpha: 0.58)
            mirror.strokeColor = UIColor(red: 0.84, green: 0.71, blue: 0.43, alpha: 1)
            mirror.lineWidth = 7
            decorateMirrorGlass(mirror)
            mirror.position = mirrorChoicePoints[index]
            mirror.zPosition = 650
            mirror.name = "mirrorRotationChoice"
            mirror.userData = NSMutableDictionary(dictionary: ["choiceIndex": index])
            mirror.addChild(tileShapeNode(shape, tileSize: 28))
            addChild(mirror)
            makeAccessible(mirror, label: "Rotated shape choice \(index + 1)")
            registerInteraction(mirror, clearance: 30)
        }
        instruction.text = "Imagine this turn. Tap the mirror with the matching shape."
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
        node.strokeColor = .systemGreen
        node.glowWidth = 16
        refreshMirrorRotationProgress()
        successFeedback()
        focusMoment(on: node.position)
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
        // A compact stone dais makes the grid feel like part of Puzzle Palace
        // instead of a full-screen modal panel.
        let daisShadow = SKShapeNode(
            rectOf: CGSize(width: 430, height: 300),
            cornerRadius: 32
        )
        daisShadow.fillColor = UIColor.black.withAlphaComponent(0.24)
        daisShadow.strokeColor = .clear
        daisShadow.position = CGPoint(x: 766, y: 392)
        daisShadow.zPosition = 96
        addChild(daisShadow)

        let chamber = SKShapeNode(
            rectOf: CGSize(width: 410, height: 282),
            cornerRadius: 26
        )
        chamber.fillColor = UIColor(red: 0.12, green: 0.16, blue: 0.24, alpha: 0.82)
        chamber.strokeColor = UIColor(red: 0.56, green: 0.76, blue: 0.82, alpha: 0.72)
        chamber.lineWidth = 3
        chamber.position = CGPoint(x: 760, y: 402)
        chamber.name = "pathTilesChamber"
        chamber.zPosition = 100
        addChild(chamber)

        let threshold = ArtSystem.box(
            CGSize(width: 360, height: 18),
            color: UIColor(red: 0.48, green: 0.38, blue: 0.22, alpha: 0.95),
            radius: 6
        )
        threshold.strokeColor = UIColor(red: 0.86, green: 0.70, blue: 0.36, alpha: 0.78)
        threshold.lineWidth = 2
        threshold.position = CGPoint(x: 760, y: 250)
        threshold.zPosition = 110
        addChild(threshold)

        let title = ArtSystem.label("PLAN THE PATH", size: 22)
        title.fontColor = UIColor(red: 0.92, green: 0.96, blue: 1.0, alpha: 0.96)
        title.name = "pathTilesTitle"
        title.position = CGPoint(x: 760, y: 575)
        title.zPosition = 800
        addChild(title)

        // Progress is mounted as palace lamps rather than floating HUD dots.
        for index in 0..<PuzzlePalaceEncounterCatalog.pathTileFamilies.count {
            let x = 690 + CGFloat(index) * 70

            let bracket = SKShapeNode(
                rectOf: CGSize(width: 8, height: 24),
                cornerRadius: 3
            )
            bracket.fillColor = UIColor(red: 0.58, green: 0.46, blue: 0.28, alpha: 0.95)
            bracket.strokeColor = .clear
            bracket.position = CGPoint(x: x, y: 548)
            bracket.zPosition = 815
            addChild(bracket)

            let light = SKShapeNode(circleOfRadius: 13)
            light.fillColor = UIColor(red: 0.18, green: 0.24, blue: 0.34, alpha: 1)
            light.strokeColor = UIColor(red: 0.56, green: 0.82, blue: 0.90, alpha: 0.88)
            light.lineWidth = 3
            light.position = CGPoint(x: x, y: 531)
            light.name = "pathProgress\(index)"
            light.zPosition = 820
            addChild(light)
        }

        let routeHeader = ArtSystem.label("CHOOSE A ROUTE", size: 16)
        routeHeader.fontColor = UIColor(red: 1.0, green: 0.87, blue: 0.52, alpha: 0.94)
        routeHeader.position = CGPoint(x: 1100, y: 390)
        routeHeader.zPosition = 820
        addChild(routeHeader)

        let back = worldControl("‹", name: "mirrorHallBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Mirror Hall")
        back.zPosition = 2050
    }

    @discardableResult
    private func addPathRouteChoice(
        _ directions: [PuzzleOrientation],
        index: Int,
        at point: CGPoint
    ) -> SKNode {
        let name = "pathChoice\(index)"
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 900
        root.userData = NSMutableDictionary(dictionary: ["choiceIndex": index])

        let rail = ArtSystem.box(
            CGSize(width: 285, height: 64),
            color: UIColor(red: 0.16, green: 0.13, blue: 0.23, alpha: 0.94),
            radius: 12
        )
        rail.strokeColor = UIColor(red: 0.78, green: 0.62, blue: 0.34, alpha: 0.86)
        rail.lineWidth = 2
        rail.name = name
        root.addChild(rail)

        let option = ArtSystem.label(["I", "II", "III"][index], size: 15)
        option.fontColor = UIColor(red: 1.0, green: 0.84, blue: 0.46, alpha: 1)
        option.position = CGPoint(x: -124, y: 0)
        option.name = name
        root.addChild(option)

        let spacing: CGFloat = 39
        let totalWidth = CGFloat(max(0, directions.count - 1)) * spacing
        let startX = -totalWidth / 2 + 12

        for (step, direction) in directions.enumerated() {
            let socket = SKShapeNode(circleOfRadius: 16)
            socket.fillColor = UIColor(red: 0.14, green: 0.25, blue: 0.34, alpha: 1)
            socket.strokeColor = UIColor(red: 0.48, green: 0.78, blue: 0.88, alpha: 0.82)
            socket.lineWidth = 2
            socket.position = CGPoint(x: startX + CGFloat(step) * spacing, y: 0)
            socket.name = name

            let glyph = ArtSystem.label(direction.glyph, size: 18)
            glyph.fontColor = .white
            glyph.name = name
            socket.addChild(glyph)
            root.addChild(socket)
        }

        makeAccessible(root, label: "Route option \(index + 1)")
        addChild(root)
        registerInteraction(root, clearance: 16)
        return root
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

        let choiceYs: [CGFloat] = [325, 245, 165]
        for index in 0..<pathEncounter.choices.count {
            _ = addPathRouteChoice(
                pathEncounter.choices[index],
                index: index,
                at: CGPoint(x: 1100, y: choiceYs[index])
            )
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
                self.successFeedback()
                self.focusMoment(on: CGPoint(x: 760, y: 420))
                self.tiko.pose(.celebrate)
                self.valkyrie.pose(.celebrate)
                if self.state.puzzlePathTilesComplete {
                    self.finishPathTiles()
                } else {
                    self.instruction.text = "That plan worked. Tap the next tile map."
                    if self.childNode(withName: "pathNext") == nil {
                        let next = self.worldGear("✦", name: "pathNext",
                                                 at: CGPoint(x: 1160, y: 145), radius: 34,
                                                 accessibilityLabel: "Next path map")
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
            let home = worldControl("⌂", name: "pathTilesHome",
                                    at: CGPoint(x: 1080, y: 175), radius: 31,
                                    accessibilityLabel: "Return to Story Tree")
            home.zPosition = 1500
        }
        if state.puzzleCommandGearsAvailable && childNode(withName: "commandGearsRoute") == nil {
            let route = worldGear("⚙", name: "commandGearsRoute",
                                  at: CGPoint(x: 1170, y: 175), radius: 35,
                                  accessibilityLabel: "Enter Command Gears")
            route.zPosition = 1500
        }
        instruction.text = "Path planning is restored. Tiko found a command engine deeper in the palace."
    }


    private func buildCommandGearsWorld() {
        let rail = ArtSystem.box(
            CGSize(width: 650, height: 22),
            color: UIColor(red: 0.42, green: 0.31, blue: 0.18, alpha: 0.96),
            radius: 7
        )
        rail.strokeColor = UIColor(red: 0.88, green: 0.69, blue: 0.34, alpha: 0.88)
        rail.lineWidth = 2
        rail.position = CGPoint(x: 760, y: 275)
        rail.name = "commandRail"
        rail.zPosition = 120
        addChild(rail)

        let title = ArtSystem.label("BUILD TIKO'S COMMAND CHAIN", size: 21)
        title.fontColor = UIColor(red: 0.94, green: 0.97, blue: 1.0, alpha: 0.97)
        title.position = CGPoint(x: 760, y: 585)
        title.name = "commandGearsTitle"
        title.zPosition = 820
        addChild(title)

        let sourceLabel = ArtSystem.label("COMMAND GEARS", size: 15)
        sourceLabel.fontColor = UIColor(red: 1.0, green: 0.86, blue: 0.50, alpha: 0.95)
        sourceLabel.position = CGPoint(x: 760, y: 515)
        sourceLabel.zPosition = 820
        addChild(sourceLabel)

        let socketXs: [CGFloat] = [585, 760, 935]
        for index in 0..<3 {
            let socket = SKShapeNode(circleOfRadius: 43)
            socket.fillColor = UIColor(red: 0.12, green: 0.15, blue: 0.24, alpha: 0.94)
            socket.strokeColor = UIColor(red: 0.54, green: 0.72, blue: 0.82, alpha: 0.78)
            socket.lineWidth = 4
            socket.position = CGPoint(x: socketXs[index], y: 285)
            socket.name = "commandSocket\(index)"
            socket.zPosition = 500
            let number = ArtSystem.label("\(index + 1)", size: 17)
            number.fontColor = UIColor(white: 1, alpha: 0.32)
            socket.addChild(number)
            addChild(socket)
        }

        for index in 0..<PuzzlePalaceEncounterCatalog.commandGearFamilies.count {
            let lamp = SKShapeNode(circleOfRadius: 12)
            lamp.fillColor = UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
            lamp.strokeColor = UIColor(red: 0.84, green: 0.66, blue: 0.34, alpha: 0.86)
            lamp.lineWidth = 3
            lamp.position = CGPoint(x: 1090 + CGFloat(index) * 38, y: 535)
            lamp.name = "commandProgress\(index)"
            lamp.zPosition = 820
            addChild(lamp)
        }

        let runGear = worldGear("▶", name: "commandRun",
                                at: CGPoint(x: 1100, y: 295), radius: 40,
                                accessibilityLabel: "Run command chain")
        runGear.zPosition = 900

        let resetGear = worldGear("↺", name: "commandReset",
                                  at: CGPoint(x: 1100, y: 390), radius: 31,
                                  accessibilityLabel: "Reset command chain")
        resetGear.zPosition = 900

        let back = worldControl("‹", name: "pathTilesBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Path Tiles")
        back.zPosition = 2050
    }

    private func clearCommandSourceGears() {
        for index in 0..<3 {
            childNode(withName: "commandSource\(index)")?.removeFromParent()
            childNode(withName: "commandSourceLabel\(index)")?.removeFromParent()
        }
    }

    private func buildCommandGearsEncounter(resetSupport: Bool = true) {
        guard let sequenceEncounter else { return }
        clearCommandSourceGears()
        commandSteps.removeAll()
        renderCommandSockets()
        attempts = 0
        if resetSupport { support = .independent }
        startedAt = Date()
        solved = false
        commandAcceptingInput = true

        let xs: [CGFloat] = [560, 760, 960]
        for (index, step) in sequenceEncounter.presented.enumerated() {
            let gear = worldGear(step.glyph, name: "commandSource\(index)",
                                 at: CGPoint(x: xs[index], y: 445), radius: 43,
                                 accessibilityLabel: step.title)
            gear.zPosition = 850
            gear.userData = NSMutableDictionary(dictionary: ["stepID": step.id])

            let label = ArtSystem.label(step.title, size: 14)
            label.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.68, alpha: 1)
            label.position = CGPoint(x: xs[index], y: 382)
            label.name = "commandSourceLabel\(index)"
            label.zPosition = 850
            addChild(label)
        }

        instruction.text = sequenceEncounter.prompt
        tiko.pose(.interact)
    }

    private func selectCommandGear(_ sourceIndex: Int) {
        guard place == .commandGears, commandAcceptingInput, !solved,
              let sequenceEncounter,
              sequenceEncounter.presented.indices.contains(sourceIndex) else { return }
        let step = sequenceEncounter.presented[sourceIndex]
        guard !commandSteps.contains(step), commandSteps.count < 3 else { return }
        commandSteps.append(step)
        selectionFeedback()
        renderCommandSockets()
        childNode(withName: "commandSource\(sourceIndex)")?.alpha = 0.30
        childNode(withName: "commandSourceLabel\(sourceIndex)")?.alpha = 0.42
        instruction.text = commandSteps.count == 3
            ? "Command chain ready. Tap RUN and watch Tiko test it."
            : "Choose what Tiko should do next."
    }

    private func resetCommandChain() {
        guard place == .commandGears, commandAcceptingInput else { return }
        commandSteps.removeAll()
        for index in 0..<3 {
            childNode(withName: "commandSource\(index)")?.alpha = 1
            childNode(withName: "commandSourceLabel\(index)")?.alpha = 1
        }
        renderCommandSockets()
        instruction.text = sequenceEncounter?.prompt ?? "Build Tiko's command chain."
        selectionFeedback()
    }

    private func renderCommandSockets() {
        for index in 0..<3 {
            guard let socket = childNode(withName: "commandSocket\(index)") as? SKShapeNode else { continue }
            socket.removeAllChildren()
            if commandSteps.indices.contains(index) {
                let step = commandSteps[index]
                socket.fillColor = UIColor(red: 0.18, green: 0.34, blue: 0.42, alpha: 1)
                socket.strokeColor = UIColor(red: 0.82, green: 0.68, blue: 0.36, alpha: 1)
                let glyph = ArtSystem.label(step.glyph, size: 30)
                glyph.name = socket.name
                socket.addChild(glyph)
                let tiny = ArtSystem.label(step.title, size: 9)
                tiny.position.y = -57
                tiny.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.67, alpha: 1)
                tiny.name = socket.name
                socket.addChild(tiny)
            } else {
                socket.fillColor = UIColor(red: 0.12, green: 0.15, blue: 0.24, alpha: 0.94)
                socket.strokeColor = UIColor(red: 0.54, green: 0.72, blue: 0.82, alpha: 0.78)
                let number = ArtSystem.label("\(index + 1)", size: 17)
                number.fontColor = UIColor(white: 1, alpha: 0.32)
                socket.addChild(number)
            }
        }
    }

    private func runCommandChain() {
        guard place == .commandGears, commandAcceptingInput, !solved,
              let activeEncounter = sequenceEncounter else { return }
        guard commandSteps.count == 3 else {
            instruction.text = "Fill all three command sockets before Tiko runs the chain."
            errorFeedback()
            return
        }

        commandAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let correct = activeEncounter.isCorrect(commandSteps)

        _ = state.recordPuzzle(
            activeEncounter,
            outcome: correct ? .correct : .incorrect,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )

        animateCommandExecution(correct: correct) { [weak self] in
            guard let self else { return }
            if correct {
                self.solved = true
                self.successFeedback()
                self.refreshCommandGearsProgress(animated: true)
                self.valkyrie.pose(.celebrate)
                self.tiko.pose(.celebrate)
                if self.state.puzzleCommandGearsComplete {
                    self.finishCommandGears(celebrate: self.state.puzzlePalaceComplete)
                } else {
                    self.instruction.text = attemptSupport == .independent
                        ? "That chain worked! Tap the lantern for another command machine."
                        : "You did it together. Try a fresh command machine next."
                    if self.childNode(withName: "commandNext") == nil {
                        let next = self.worldGear("✦", name: "commandNext",
                                                  at: CGPoint(x: 1170, y: 165), radius: 34,
                                                  accessibilityLabel: "Next command machine")
                        next.zPosition = 1500
                    }
                }
            } else {
                self.errorFeedback()
                self.support = self.support == .independent ? .lightHint : .strongHint
                self.valkyrie.pose(.react)
                self.tiko.pose(.react)
                self.instruction.text = self.support == .lightHint
                    ? "Think about what must happen before Tiko can use the last action."
                    : "Find the action that makes the next one possible. Build from first to last."
                self.sequenceEncounter = self.state.nextPuzzleCommandGearsEncounter()
                self.run(.sequence([
                    .wait(forDuration: self.reducedMotion ? 0 : 0.55),
                    .run { [weak self] in self?.buildCommandGearsEncounter(resetSupport: false) }
                ]))
            }
        }
    }

    private func animateCommandExecution(correct: Bool, completion: @escaping () -> Void) {
        let sockets = (0..<3).compactMap { childNode(withName: "commandSocket\($0)") as? SKShapeNode }
        if reducedMotion {
            sockets.forEach { $0.glowWidth = correct ? 6 : 0 }
            completion()
            return
        }

        var actions: [SKAction] = []
        for (index, socket) in sockets.enumerated() {
            actions += [
                .run {
                    socket.glowWidth = 10
                    socket.setScale(1.08)
                },
                .wait(forDuration: 0.20),
                .run {
                    socket.glowWidth = 0
                    socket.setScale(1)
                }
            ]
            if index < 2 { actions.append(.wait(forDuration: 0.06)) }
        }
        actions.append(.run(completion))
        run(.sequence(actions), withKey: "commandExecution")
    }

    private func refreshCommandGearsProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: state.profile)
        for index in 0..<PuzzlePalaceEncounterCatalog.commandGearFamilies.count {
            guard let lamp = childNode(withName: "commandProgress\(index)") as? SKShapeNode else { continue }
            let active = index < count
            lamp.fillColor = active ? .systemGreen : UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
            lamp.glowWidth = active ? 8 : 0
            if active && animated && !reducedMotion {
                lamp.run(.sequence([
                    .scale(to: 1.25, duration: 0.12),
                    .scale(to: 1.0, duration: 0.16)
                ]))
            }
        }
    }

    private func finishCommandGears(celebrate: Bool = false) {
        commandAcceptingInput = false
        clearCommandSourceGears()
        commandSteps.removeAll()
        renderCommandSockets()
        childNode(withName: "commandNext")?.removeFromParent()
        refreshCommandGearsProgress(animated: true)
        if let title = childNode(withName: "commandGearsTitle") as? SKLabelNode {
            title.text = "COMMAND ENGINE RESTORED"
        }
        for index in 0..<3 {
            if let socket = childNode(withName: "commandSocket\(index)") as? SKShapeNode {
                socket.fillColor = UIColor(red: 0.18, green: 0.42, blue: 0.33, alpha: 1)
                socket.glowWidth = 7
            }
        }
        if childNode(withName: "commandHome") == nil {
            let home = worldControl("⌂", name: "commandHome",
                                    at: CGPoint(x: 1075, y: 175), radius: 31,
                                    accessibilityLabel: "Return to Story Tree")
            home.zPosition = 1500
        }
        if state.puzzleBugLanternAvailable && childNode(withName: "bugLanternRoute") == nil {
            let route = worldGear("✹", name: "bugLanternRoute",
                                  at: CGPoint(x: 1170, y: 175), radius: 35,
                                  accessibilityLabel: "Enter Bug Lantern")
            route.zPosition = 1500
        }

        if state.puzzlePalaceComplete {
            renderPuzzlePalaceFinale(celebrate: celebrate)
            instruction.text = "The Palace is glowing again. Tiko's violet lantern is waiting at the Story Tree."
        } else {
            instruction.text = "The Command Engine is restored. The Bug Lantern is ready for debugging."
        }
    }

    private func buildBugLanternWorld() {
        let rail = ArtSystem.panel(
            CGSize(width: 690, height: 22),
            fill: UIColor(red: 0.30, green: 0.20, blue: 0.11, alpha: 0.90),
            stroke: UIColor(red: 0.88, green: 0.68, blue: 0.32, alpha: 0.78),
            radius: 8,
            lineWidth: 2,
            shadowAlpha: 0.20
        )
        rail.position = CGPoint(x: 760, y: 292)
        rail.name = "bugRail"
        rail.zPosition = 120
        addChild(rail)

        for x in [CGFloat(520), 660, 860, 1000] {
            let support = ArtSystem.box(
                CGSize(width: 8, height: 72),
                color: UIColor(red: 0.48, green: 0.34, blue: 0.18, alpha: 0.72),
                radius: 3
            )
            support.position = CGPoint(x: x, y: 328)
            support.zPosition = 118
            addChild(support)
        }

        let lanternFrame = ArtSystem.medallion(
            radius: 76,
            fill: UIColor(red: 0.15, green: 0.10, blue: 0.23, alpha: 0.98),
            stroke: UIColor(red: 0.93, green: 0.66, blue: 0.24, alpha: 0.92),
            glow: reducedMotion ? 0 : 4
        )
        lanternFrame.position = CGPoint(x: 760, y: 515)
        lanternFrame.name = "bugLanternFixture"
        lanternFrame.zPosition = 650
        addChild(lanternFrame)

        let lanternCore = ArtSystem.medallion(
            radius: 45,
            fill: UIColor(red: 0.92, green: 0.55, blue: 0.16, alpha: 0.94),
            stroke: UIColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 1),
            glow: 12
        )
        lanternCore.name = "bugLanternCore"
        lanternFrame.addChild(lanternCore)

        let bugGlyph = ArtSystem.label("✹", size: 34)
        bugGlyph.fontColor = UIColor(red: 0.23, green: 0.10, blue: 0.18, alpha: 1)
        bugGlyph.name = "bugLanternGlyph"
        lanternCore.addChild(bugGlyph)

        let titlePlate = ArtSystem.plaque(
            CGSize(width: 330, height: 42),
            fill: UIColor(red: 0.09, green: 0.08, blue: 0.18, alpha: 0.90),
            stroke: UIColor(red: 0.79, green: 0.61, blue: 0.30, alpha: 0.68),
            radius: 18
        )
        titlePlate.position = CGPoint(x: 760, y: 615)
        titlePlate.zPosition = 818
        addChild(titlePlate)

        let title = ArtSystem.label("FIND THE BROKEN COMMAND", size: 17)
        title.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.72, alpha: 0.98)
        title.position = CGPoint(x: 760, y: 615)
        title.name = "bugLanternTitle"
        title.zPosition = 820
        addChild(title)

        for index in 0..<3 {
            let socket = ArtSystem.panel(
                CGSize(width: 174, height: 126),
                fill: UIColor(red: 0.10, green: 0.09, blue: 0.20, alpha: 0.62),
                stroke: UIColor(red: 0.55, green: 0.46, blue: 0.78, alpha: 0.42),
                radius: 32,
                lineWidth: 2,
                shadowAlpha: 0.18,
                innerHighlight: UIColor(red: 0.84, green: 0.72, blue: 1.0, alpha: 0.06)
            )
            socket.position = CGPoint(x: [CGFloat(555), 760, 965][index], y: 355)
            socket.name = "bugStepSocket\(index)"
            socket.zPosition = 832
            addChild(socket)
        }

        for index in 0..<2 {
            let arrowPlate = ArtSystem.medallion(
                radius: 18,
                fill: UIColor(red: 0.12, green: 0.10, blue: 0.22, alpha: 0.96),
                stroke: UIColor(red: 0.86, green: 0.66, blue: 0.31, alpha: 0.82)
            )
            arrowPlate.position = CGPoint(x: index == 0 ? 658 : 863, y: 355)
            arrowPlate.name = "bugFlowArrow\(index)"
            arrowPlate.zPosition = 846

            let arrow = ArtSystem.label("→", size: 18)
            arrow.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.58, alpha: 1)
            arrowPlate.addChild(arrow)
            addChild(arrowPlate)
        }

        for index in 0..<PuzzlePalaceEncounterCatalog.bugLanternFamilies.count {
            let lamp = ArtSystem.medallion(
                radius: 11,
                fill: UIColor(red: 0.16, green: 0.19, blue: 0.27, alpha: 0.98),
                stroke: UIColor(red: 0.93, green: 0.66, blue: 0.24, alpha: 0.78)
            )
            lamp.position = CGPoint(x: 1090 + CGFloat(index) * 38, y: 535)
            lamp.name = "bugProgress\(index)"
            lamp.zPosition = 820
            addChild(lamp)
        }

        let back = worldControl("‹", name: "commandGearsBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Command Gears")
        back.zPosition = 2050
    }

    private func clearBugSteps() {
        for index in 0..<3 {
            childNode(withName: "bugStep\(index)")?.removeFromParent()
            childNode(withName: "bugStepLabel\(index)")?.removeFromParent()
        }
        childNode(withName: "bugReplacement")?.removeFromParent()
        bugIdentifiedIndex = nil
        bugRepairReady = false
    }

    private func buildBugLanternEncounter(resetSupport: Bool = true) {
        guard let bugEncounter else { return }
        clearBugSteps()
        attempts = 0
        if resetSupport { support = .independent }
        startedAt = Date()
        solved = false
        bugIdentifiedIndex = nil
        bugRepairReady = false
        bugAcceptingInput = true

        let xs: [CGFloat] = [555, 760, 965]
        for (index, step) in bugEncounter.shown.enumerated() {
            let plate = ArtSystem.panel(
                CGSize(width: 154, height: 120),
                fill: UIColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 0.97),
                stroke: UIColor(red: 0.52, green: 0.70, blue: 0.82, alpha: 0.76),
                radius: 28,
                lineWidth: 4,
                shadowAlpha: 0.28,
                innerHighlight: UIColor(red: 0.66, green: 0.82, blue: 0.94, alpha: 0.10)
            )
            plate.position = CGPoint(x: xs[index], y: 355)
            plate.name = "bugStep\(index)"
            plate.zPosition = 850
            plate.userData = NSMutableDictionary(dictionary: ["stepIndex": index])

            let number = ArtSystem.label("\(index + 1)", size: 13)
            number.fontColor = UIColor(white: 1, alpha: 0.40)
            number.position = CGPoint(x: -58, y: 35)
            number.name = plate.name
            plate.addChild(number)

            let glyph = ArtSystem.label(step.glyph, size: 35)
            glyph.fontColor = .white
            glyph.position.y = 17
            glyph.name = plate.name
            plate.addChild(glyph)

            let labelPlate = ArtSystem.plaque(
                CGSize(width: 126, height: 30),
                fill: UIColor(red: 0.07, green: 0.09, blue: 0.17, alpha: 0.94),
                stroke: UIColor(red: 0.66, green: 0.57, blue: 0.84, alpha: 0.45),
                radius: 12
            )
            labelPlate.position.y = -39
            labelPlate.name = plate.name
            plate.addChild(labelPlate)

            let label = ArtSystem.label(step.title, size: 11)
            label.fontColor = UIColor(red: 1.0, green: 0.92, blue: 0.72, alpha: 1)
            label.name = plate.name
            labelPlate.addChild(label)

            makeAccessible(plate, label: "Command \(index + 1): \(step.title)")
            addChild(plate)
            registerInteraction(plate, clearance: 18)
        }

        if let core = childNode(withName: "//bugLanternCore") as? SKShapeNode {
            core.fillColor = UIColor(red: 0.92, green: 0.55, blue: 0.16, alpha: 0.94)
            core.glowWidth = 12
        }
        instruction.text = bugEncounter.prompt
        tiko.pose(.interact)
    }

    private func resolveBugStep(_ index: Int) {
        guard place == .bugLantern, bugAcceptingInput, !solved,
              let activeEncounter = bugEncounter,
              activeEncounter.shown.indices.contains(index),
              let node = childNode(withName: "bugStep\(index)") as? SKShapeNode else { return }

        bugAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let correct = activeEncounter.isBrokenStep(index)

        guard correct else {
            _ = state.recordPuzzle(
                activeEncounter,
                outcome: .incorrect,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            node.strokeColor = .systemRed
            node.glowWidth = 7
            errorFeedback()
            support = support == .independent ? .lightHint : .strongHint
            valkyrie.pose(.react)
            tiko.pose(.react)
            instruction.text = support == .lightHint
                ? "Check what each command should make possible for the next one."
                : "Compare the three steps to the goal. Only one command does not belong."
            bugEncounter = state.nextPuzzleBugLanternEncounter()
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0 : 0.55),
                .run { [weak self] in self?.buildBugLanternEncounter(resetSupport: false) }
            ]))
            return
        }

        bugIdentifiedIndex = index
        node.strokeColor = .systemRed
        node.glowWidth = 13
        selectionFeedback()
        instruction.text = "You found the broken command. Watch Tiko run the plan and see where it fails."
        demonstrateBugFailure(at: index) { [weak self] in
            self?.buildBugReplacement()
        }
    }

    private func demonstrateBugFailure(at brokenIndex: Int, completion: @escaping () -> Void) {
        let xs: [CGFloat] = [555, 760, 965]
        let demonstrationY = CGFloat(205)
        tiko.removeAllActions()

        if reducedMotion {
            tiko.position = CGPoint(x: xs[brokenIndex], y: demonstrationY)
            tiko.pose(.react)
            completion()
            return
        }

        var actions: [SKAction] = []
        for index in 0...brokenIndex {
            actions.append(.run { [weak self] in self?.tiko.pose(.walk) })
            actions.append(.move(
                to: CGPoint(x: xs[index], y: demonstrationY),
                duration: 0.30
            ))
        }
        actions.append(.run { [weak self] in self?.tiko.pose(.react) })
        actions.append(.wait(forDuration: 0.35))
        actions.append(.run(completion))
        tiko.run(.sequence(actions))
    }

    private func buildBugReplacement() {
        guard place == .bugLantern, !solved,
              let activeEncounter = bugEncounter,
              let index = bugIdentifiedIndex else { return }

        childNode(withName: "bugReplacement")?.removeFromParent()
        let replacementStep = activeEncounter.intended[index]
        let plate = SKShapeNode(
            rectOf: CGSize(width: 184, height: 92),
            cornerRadius: 26
        )
        plate.fillColor = UIColor(red: 0.12, green: 0.25, blue: 0.22, alpha: 0.98)
        plate.strokeColor = UIColor(red: 0.45, green: 0.92, blue: 0.67, alpha: 0.96)
        plate.lineWidth = 5
        // Keep the replacement physically separate from Tiko's failed-step position
        // so diagnosis and repair remain visually distinct, including reduced motion.
        plate.position = CGPoint(x: 390, y: 205)
        plate.name = "bugReplacement"
        plate.zPosition = 1050

        let number = ArtSystem.label("\(index + 1)", size: 13)
        number.fontColor = UIColor(white: 1, alpha: 0.45)
        number.position = CGPoint(x: -70, y: 29)
        number.name = "bugReplacement"
        plate.addChild(number)

        let glyph = ArtSystem.label(replacementStep.glyph, size: 31)
        glyph.fontColor = .white
        glyph.position = CGPoint(x: -47, y: 0)
        glyph.name = "bugReplacement"
        plate.addChild(glyph)

        let title = ArtSystem.label(replacementStep.title, size: 12)
        title.fontColor = UIColor(red: 0.91, green: 1.0, blue: 0.91, alpha: 1)
        title.position = CGPoint(x: 32, y: -4)
        title.name = "bugReplacement"
        plate.addChild(title)

        makeAccessible(
            plate,
            label: "Replacement command: \(replacementStep.title). Install it in step \(index + 1)."
        )
        addChild(plate)
        registerInteraction(plate, clearance: 18)
        bugRepairReady = true
        instruction.text = "Tiko got stuck at step \(index + 1). Install \(replacementStep.title) to repair the plan."
    }

    private func installBugReplacement() {
        guard place == .bugLantern, bugRepairReady, !solved,
              let activeEncounter = bugEncounter,
              let index = bugIdentifiedIndex,
              let replacement = childNode(withName: "bugReplacement") as? SKShapeNode,
              let brokenPlate = childNode(withName: "bugStep\(index)") else { return }

        bugRepairReady = false
        let targetPosition = brokenPlate.position
        let externalLabel = childNode(withName: "bugStepLabel\(index)")
        let attemptSupport = support

        let completeRepair = { [weak self, weak replacement, weak brokenPlate, weak externalLabel] in
            guard let self, let replacement else { return }
            brokenPlate?.removeFromParent()
            externalLabel?.removeFromParent()
            replacement.position = targetPosition
            replacement.name = "bugStep\(index)"
            for child in replacement.children {
                child.name = replacement.name
            }
            replacement.strokeColor = .systemGreen
            replacement.glowWidth = 12
            self.makeAccessible(
                replacement,
                label: "Command \(index + 1): \(activeEncounter.intended[index].title), repaired"
            )

            _ = self.state.recordPuzzle(
                activeEncounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: self.attempts,
                responseTime: Date().timeIntervalSince(self.startedAt)
            )

            self.solved = true
            self.successFeedback()
            self.valkyrie.pose(.celebrate)
            self.tiko.pose(.celebrate)

            if let core = self.childNode(withName: "//bugLanternCore") as? SKShapeNode {
                core.fillColor = .systemGreen
                core.glowWidth = 18
            }

            self.refreshBugLanternProgress(animated: true)

            if self.state.puzzleBugLanternComplete {
                self.finishBugLantern(celebrate: true)
            } else {
                self.instruction.text = attemptSupport == .independent
                    ? "You found and fixed the bug. Try a fresh plan."
                    : "You repaired it with help. Try a fresh plan independently."
                if self.childNode(withName: "bugNext") == nil {
                    let next = self.worldGear(
                        "✹",
                        name: "bugNext",
                        at: CGPoint(x: 1170, y: 165),
                        radius: 34,
                        accessibilityLabel: "Next broken plan"
                    )
                    next.zPosition = 1500
                }
            }
        }

        if reducedMotion {
            replacement.position = targetPosition
            completeRepair()
        } else {
            replacement.run(.sequence([
                .move(to: targetPosition, duration: 0.30),
                .run(completeRepair)
            ]))
        }
    }

    private func refreshBugLanternProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.bugLanternIndependentSuccessCount(profile: state.profile)
        for index in 0..<PuzzlePalaceEncounterCatalog.bugLanternFamilies.count {
            guard let lamp = childNode(withName: "bugProgress\(index)") as? SKShapeNode else { continue }
            let active = index < count
            lamp.fillColor = active ? .systemGreen : UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
            lamp.glowWidth = active ? 8 : 0
            if active && animated && !reducedMotion {
                lamp.run(.sequence([
                    .scale(to: 1.25, duration: 0.12),
                    .scale(to: 1.0, duration: 0.16)
                ]))
            }
        }
    }

    private func finishBugLantern(celebrate: Bool = false) {
        bugAcceptingInput = false
        clearBugSteps()
        childNode(withName: "bugNext")?.removeFromParent()
        refreshBugLanternProgress(animated: true)

        if let title = childNode(withName: "bugLanternTitle") as? SKLabelNode {
            title.text = "BUG LANTERN RESTORED"
        }
        if let core = childNode(withName: "//bugLanternCore") as? SKShapeNode {
            core.fillColor = .systemGreen
            core.glowWidth = 18
        }

        if childNode(withName: "bugHome") == nil {
            let home = worldControl("⌂", name: "bugHome",
                                    at: CGPoint(x: 1075, y: 175), radius: 31,
                                    accessibilityLabel: "Return to Story Tree")
            home.zPosition = 1500
        }
        if state.puzzleBugRepairAvailable && childNode(withName: "bugRepairRoute") == nil {
            let route = worldGear("⇄", name: "bugRepairRoute",
                                  at: CGPoint(x: 1170, y: 175), radius: 35,
                                  accessibilityLabel: "Enter Bug Lantern Repair Lab")
            route.zPosition = 1500
        }
        if state.puzzlePalaceComplete {
            renderPuzzlePalaceFinale(celebrate: celebrate)
            instruction.text = "The Palace is glowing again. Tiko's violet lantern is waiting at the Story Tree."
        } else if state.puzzleBugRepairAvailable {
            instruction.text = "Single-step debugging is restored. Enter Repair Lab to fix a whole plan."
        } else {
            instruction.text = "Tiko can now diagnose and repair one broken command."
        }
    }

    private func buildBugRepairWorld() {
        let rail = ArtSystem.box(
            CGSize(width: 760, height: 24),
            color: UIColor(red: 0.34, green: 0.25, blue: 0.15, alpha: 0.96),
            radius: 8
        )
        rail.strokeColor = UIColor(red: 0.86, green: 0.67, blue: 0.32, alpha: 0.88)
        rail.lineWidth = 2
        rail.position = CGPoint(x: 760, y: 292)
        rail.name = "repairRail"
        rail.zPosition = 120
        addChild(rail)

        let lantern = SKShapeNode(circleOfRadius: 66)
        lantern.fillColor = UIColor(red: 0.14, green: 0.13, blue: 0.28, alpha: 0.98)
        lantern.strokeColor = UIColor(red: 0.64, green: 0.70, blue: 0.98, alpha: 0.96)
        lantern.lineWidth = 8
        lantern.position = CGPoint(x: 760, y: 535)
        lantern.name = "repairLanternFixture"
        lantern.zPosition = 650
        addChild(lantern)

        let core = SKShapeNode(circleOfRadius: 38)
        core.fillColor = UIColor(red: 0.42, green: 0.55, blue: 0.96, alpha: 0.96)
        core.strokeColor = UIColor(red: 0.86, green: 0.90, blue: 1.0, alpha: 1)
        core.lineWidth = 4
        core.glowWidth = 12
        core.name = "repairLanternCore"
        lantern.addChild(core)

        let glyph = ArtSystem.label("⇄", size: 30)
        glyph.fontColor = UIColor(red: 0.12, green: 0.12, blue: 0.28, alpha: 1)
        glyph.name = "repairLanternGlyph"
        core.addChild(glyph)

        let title = ArtSystem.label("REPAIR THE WHOLE PLAN", size: 21)
        title.fontColor = UIColor(red: 0.96, green: 0.97, blue: 1.0, alpha: 0.98)
        title.position = CGPoint(x: 760, y: 625)
        title.name = "bugRepairTitle"
        title.zPosition = 820
        addChild(title)

        let cue = ArtSystem.label("Pick two commands to swap, then tap FIX.", size: 15)
        cue.fontColor = UIColor(red: 0.90, green: 0.88, blue: 1.0, alpha: 0.88)
        cue.position = CGPoint(x: 760, y: 455)
        cue.name = "repairCue"
        cue.zPosition = 820
        addChild(cue)

        for index in 0..<PuzzlePalaceEncounterCatalog.bugRepairFamilies.count {
            let lamp = SKShapeNode(circleOfRadius: 12)
            lamp.fillColor = UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
            lamp.strokeColor = UIColor(red: 0.64, green: 0.70, blue: 0.98, alpha: 0.88)
            lamp.lineWidth = 3
            lamp.position = CGPoint(x: 1090 + CGFloat(index) * 38, y: 535)
            lamp.name = "repairProgress\(index)"
            lamp.zPosition = 820
            addChild(lamp)
        }

        let fix = worldGear("✓", name: "repairFix",
                            at: CGPoint(x: 1145, y: 300), radius: 40,
                            accessibilityLabel: "Fix selected command pair")
        fix.zPosition = 920

        let reset = worldGear("↺", name: "repairReset",
                              at: CGPoint(x: 1145, y: 395), radius: 31,
                              accessibilityLabel: "Clear repair selection")
        reset.zPosition = 920

        let back = worldControl("‹", name: "bugLanternBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Bug Lantern")
        back.zPosition = 2050
    }

    private func clearRepairSteps() {
        for index in 0..<4 {
            childNode(withName: "repairStep\(index)")?.removeFromParent()
            childNode(withName: "repairStepLabel\(index)")?.removeFromParent()
        }
    }

    private func buildBugRepairEncounter(resetSupport: Bool = true) {
        guard let repairEncounter else { return }
        clearRepairSteps()
        repairSelection.removeAll()
        attempts = 0
        if resetSupport { support = .independent }
        startedAt = Date()
        solved = false
        repairAcceptingInput = true

        let xs: [CGFloat] = [485, 665, 845, 1025]
        for (index, step) in repairEncounter.presented.enumerated() {
            let plate = SKShapeNode(
                rectOf: CGSize(width: 132, height: 104),
                cornerRadius: 24
            )
            plate.fillColor = UIColor(red: 0.12, green: 0.16, blue: 0.25, alpha: 0.98)
            plate.strokeColor = UIColor(red: 0.52, green: 0.70, blue: 0.82, alpha: 0.82)
            plate.lineWidth = 4
            plate.position = CGPoint(x: xs[index], y: 355)
            plate.name = "repairStep\(index)"
            plate.zPosition = 850
            plate.userData = NSMutableDictionary(dictionary: ["stepIndex": index])

            let number = ArtSystem.label("\(index + 1)", size: 13)
            number.fontColor = UIColor(white: 1, alpha: 0.40)
            number.position = CGPoint(x: -48, y: 34)
            number.name = plate.name
            plate.addChild(number)

            let commandGlyph = ArtSystem.label(step.glyph, size: 32)
            commandGlyph.fontColor = .white
            commandGlyph.position.y = 8
            commandGlyph.name = plate.name
            plate.addChild(commandGlyph)

            makeAccessible(plate, label: "Command \(index + 1): \(step.title)")
            addChild(plate)
            registerInteraction(plate, clearance: 16)

            let label = ArtSystem.label(step.title, size: 11)
            label.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.67, alpha: 1)
            label.position = CGPoint(x: xs[index], y: 280)
            label.name = "repairStepLabel\(index)"
            label.zPosition = 850
            addChild(label)
        }

        renderRepairSelection()
        instruction.text = repairEncounter.prompt
        tiko.pose(.interact)
    }

    private func toggleRepairStep(_ index: Int) {
        guard place == .bugLanternRepair, repairAcceptingInput, !solved,
              (0..<4).contains(index) else { return }

        if let existing = repairSelection.firstIndex(of: index) {
            repairSelection.remove(at: existing)
        } else if repairSelection.count < 2 {
            repairSelection.append(index)
        } else {
            repairSelection.removeFirst()
            repairSelection.append(index)
        }
        selectionFeedback()
        renderRepairSelection()
        instruction.text = repairSelection.count == 2
            ? "Two commands selected. Tap FIX to swap them."
            : "Select one more command that should trade places."
    }

    private func renderRepairSelection() {
        for index in 0..<4 {
            guard let plate = childNode(withName: "repairStep\(index)") as? SKShapeNode else { continue }
            let selected = repairSelection.contains(index)
            plate.strokeColor = selected
                ? UIColor(red: 0.52, green: 0.91, blue: 1.0, alpha: 1)
                : UIColor(red: 0.52, green: 0.70, blue: 0.82, alpha: 0.82)
            plate.glowWidth = selected ? 10 : 0
            plate.setScale(selected ? 1.04 : 1)
        }
    }

    private func resetRepairSelection() {
        guard place == .bugLanternRepair, repairAcceptingInput else { return }
        repairSelection.removeAll()
        renderRepairSelection()
        selectionFeedback()
        instruction.text = repairEncounter?.prompt ?? "Choose the two commands that should swap."
    }

    private func submitBugRepair() {
        guard place == .bugLanternRepair, repairAcceptingInput, !solved,
              let activeEncounter = repairEncounter else { return }
        guard repairSelection.count == 2 else {
            instruction.text = "Choose exactly two commands to swap first."
            errorFeedback()
            return
        }

        repairAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let selected = repairSelection
        let correct = activeEncounter.isCorrectSwap(selected)

        _ = state.recordPuzzle(
            activeEncounter,
            outcome: correct ? .correct : .incorrect,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )

        animateRepairSwap(selected, applySwap: correct) { [weak self] in
            guard let self else { return }
            if correct {
                self.solved = true
                self.successFeedback()
                self.valkyrie.pose(.celebrate)
                self.tiko.pose(.celebrate)
                if let core = self.childNode(withName: "//repairLanternCore") as? SKShapeNode {
                    core.fillColor = .systemGreen
                    core.glowWidth = 18
                }
                self.refreshBugRepairProgress(animated: true)

                if self.state.puzzleBugRepairComplete {
                    self.finishBugRepair()
                } else {
                    self.instruction.text = attemptSupport == .independent
                        ? "The whole plan works again. Tap the lantern for another repair."
                        : "You repaired it with help. Try a fresh plan independently."
                    if self.childNode(withName: "repairNext") == nil {
                        let next = self.worldGear("⇄", name: "repairNext",
                                                  at: CGPoint(x: 1170, y: 165), radius: 34,
                                                  accessibilityLabel: "Next repair plan")
                        next.zPosition = 1500
                    }
                }
            } else {
                self.errorFeedback()
                self.support = self.support == .independent ? .lightHint : .strongHint
                self.valkyrie.pose(.react)
                self.tiko.pose(.react)
                self.instruction.text = self.support == .lightHint
                    ? "Read from first to last. Which two commands make the plan happen out of order?"
                    : "Find the first impossible transition, then look for the command that belongs there."
                self.repairEncounter = self.state.nextPuzzleBugRepairEncounter()
                self.run(.sequence([
                    .wait(forDuration: self.reducedMotion ? 0 : 0.55),
                    .run { [weak self] in self?.buildBugRepairEncounter(resetSupport: false) }
                ]))
            }
        }
    }

    private func animateRepairSwap(
        _ indices: [Int],
        applySwap: Bool,
        completion: @escaping () -> Void
    ) {
        guard applySwap else {
            completion()
            return
        }
        guard indices.count == 2,
              let first = childNode(withName: "repairStep\(indices[0])"),
              let second = childNode(withName: "repairStep\(indices[1])") else {
            completion()
            return
        }

        let firstLabel = childNode(withName: "repairStepLabel\(indices[0])")
        let secondLabel = childNode(withName: "repairStepLabel\(indices[1])")
        let firstX = first.position.x
        let secondX = second.position.x
        let firstLabelX = firstLabel?.position.x
        let secondLabelX = secondLabel?.position.x

        if reducedMotion {
            first.position.x = secondX
            second.position.x = firstX
            if let firstLabel, let secondLabelX {
                firstLabel.position.x = secondLabelX
            }
            if let secondLabel, let firstLabelX {
                secondLabel.position.x = firstLabelX
            }
            completion()
            return
        }

        first.run(.moveTo(x: secondX, duration: 0.28))
        second.run(.sequence([
            .moveTo(x: firstX, duration: 0.28),
            .run(completion)
        ]))
        if let firstLabel, let secondLabelX {
            firstLabel.run(.moveTo(x: secondLabelX, duration: 0.28))
        }
        if let secondLabel, let firstLabelX {
            secondLabel.run(.moveTo(x: firstLabelX, duration: 0.28))
        }
    }

    private func refreshBugRepairProgress(animated: Bool) {
        let count = PuzzlePalaceDirector.bugRepairIndependentSuccessCount(profile: state.profile)
        for index in 0..<PuzzlePalaceEncounterCatalog.bugRepairFamilies.count {
            guard let lamp = childNode(withName: "repairProgress\(index)") as? SKShapeNode else { continue }
            let active = index < count
            lamp.fillColor = active ? .systemGreen : UIColor(red: 0.18, green: 0.22, blue: 0.31, alpha: 1)
            lamp.glowWidth = active ? 8 : 0
            if active && animated && !reducedMotion {
                lamp.run(.sequence([
                    .scale(to: 1.25, duration: 0.12),
                    .scale(to: 1.0, duration: 0.16)
                ]))
            }
        }
    }

    private func finishBugRepair() {
        repairAcceptingInput = false
        repairSelection.removeAll()
        clearRepairSteps()
        childNode(withName: "repairNext")?.removeFromParent()
        childNode(withName: "repairFix")?.removeFromParent()
        childNode(withName: "repairReset")?.removeFromParent()
        refreshBugRepairProgress(animated: true)
        if let title = childNode(withName: "bugRepairTitle") as? SKLabelNode {
            title.text = "PLAN REPAIR RESTORED"
        }
        if let cue = childNode(withName: "repairCue") as? SKLabelNode {
            cue.text = "All three plans are repaired."
        }
        if let core = childNode(withName: "//repairLanternCore") as? SKShapeNode {
            core.fillColor = .systemGreen
            core.glowWidth = 18
        }
        if childNode(withName: "repairHome") == nil {
            let home = worldControl("⌂", name: "repairHome",
                                    at: CGPoint(x: 1110, y: 175), radius: 31,
                                    accessibilityLabel: "Return to Story Tree")
            home.zPosition = 1500
        }

        if state.puzzlePalaceComplete {
            renderPuzzlePalaceFinale(celebrate: true)
            instruction.text = "The Palace is fully restored. Tiko can debug and repair complete plans."
        } else {
            instruction.text = "Tiko can now find and repair mistakes across a whole plan."
        }
    }

    private func renderPuzzlePalaceFinale(celebrate: Bool) {
        guard childNode(withName: "palaceFinaleLantern") == nil else { return }

        let root = SKNode()
        root.name = "palaceFinaleLantern"
        root.position = CGPoint(x: 975, y: 455)
        root.zPosition = 930

        let halo = SKShapeNode(circleOfRadius: 62)
        halo.fillColor = UIColor(red: 0.52, green: 0.40, blue: 0.92, alpha: 0.17)
        halo.strokeColor = UIColor(red: 0.78, green: 0.68, blue: 1.0, alpha: 0.92)
        halo.lineWidth = 2
        halo.glowWidth = 16
        root.addChild(halo)

        let cage = SKShapeNode(rectOf: CGSize(width: 68, height: 82), cornerRadius: 21)
        cage.fillColor = UIColor(red: 0.15, green: 0.13, blue: 0.31, alpha: 0.96)
        cage.strokeColor = UIColor(red: 0.78, green: 0.67, blue: 1.0, alpha: 1)
        cage.lineWidth = 4
        root.addChild(cage)

        let mark = ArtSystem.label("◈", size: 38)
        mark.fontColor = UIColor(red: 0.94, green: 0.89, blue: 1.0, alpha: 1)
        root.addChild(mark)
        addChild(root)

        if !reducedMotion {
            halo.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.50, duration: 0.85),
                .fadeAlpha(to: 1.0, duration: 0.85)
            ])))
        }

        guard celebrate else { return }
        tiko.pose(.celebrate)
        valkyrie.pose(.celebrate)
        focusMoment(on: root.position, hold: 0.75)
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

        case "commandGearsRoute":
            guard state.puzzleCommandGearsAvailable else { return }
            state.travel(to: .commandGears)

        case "bugLanternRoute":
            guard state.puzzleBugLanternAvailable else { return }
            state.travel(to: .bugLantern)

        case "commandGearsBack":
            state.travel(to: .commandGears)

        case "bugHome":
            state.travel(to: .storyTree)

        case "bugRepairRoute":
            guard state.puzzleBugRepairAvailable else { return }
            state.travel(to: .bugLanternRepair)

        case "bugLanternBack":
            state.travel(to: .bugLantern)

        case "repairHome":
            state.travel(to: .storyTree)

        case "repairFix":
            submitBugRepair()

        case "repairReset":
            resetRepairSelection()

        case "repairNext":
            guard place == .bugLanternRepair, solved, !state.puzzleBugRepairComplete else { return }
            childNode(withName: "repairNext")?.removeFromParent()
            repairEncounter = state.nextPuzzleBugRepairEncounter()
            buildBugRepairEncounter()

        case let name? where name.hasPrefix("repairStep"):
            guard place == .bugLanternRepair,
                  let index = Int(name.replacingOccurrences(of: "repairStep", with: "")) else { return }
            toggleRepairStep(index)

        case "bugReplacement":
            installBugReplacement()

        case "bugNext":
            guard place == .bugLantern, solved, !state.puzzleBugLanternComplete else { return }
            childNode(withName: "bugNext")?.removeFromParent()
            bugEncounter = state.nextPuzzleBugLanternEncounter()
            buildBugLanternEncounter()

        case let name? where name.hasPrefix("bugStep"):
            guard place == .bugLantern,
                  let index = Int(name.replacingOccurrences(of: "bugStep", with: "")) else { return }
            resolveBugStep(index)

        case "pathTilesBack":
            state.travel(to: .pathTiles)

        case "commandHome":
            state.travel(to: .storyTree)

        case "commandRun":
            runCommandChain()

        case "commandReset":
            resetCommandChain()

        case "commandNext":
            guard place == .commandGears, solved, !state.puzzleCommandGearsComplete else { return }
            childNode(withName: "commandNext")?.removeFromParent()
            sequenceEncounter = state.nextPuzzleCommandGearsEncounter()
            buildCommandGearsEncounter()

        case let name? where name.hasPrefix("commandSource"):
            guard place == .commandGears,
                  let index = Int(name.replacingOccurrences(of: "commandSource", with: "")) else { return }
            selectCommandGear(index)

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
        state.audio.play("footstep")
        valkyrie.walk(to: point) { [weak self] in
            guard self != nil else { return }
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
        state.audio.stop(channel: .ambience)
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

