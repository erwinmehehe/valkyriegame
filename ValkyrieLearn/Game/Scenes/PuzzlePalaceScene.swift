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
    // Read-only current encounter for native simulator acceptance tests.
    // Tests must operate what the child actually sees, never a second adaptive
    // selection that can disagree with the currently displayed room.
    var nativeReviewActiveEncounter: Any? {
        switch place {
        case .runeGate: return encounter
        case .memoryBridge: return memoryEncounter
        case .stopGoOrbs: return inhibitionEncounter
        case .sortingPedestal: return sortEncounter
        case .resortVault: return resortEncounter
        case .mirrorHall: return orientationEncounter
        case .pathTiles: return pathEncounter
        case .commandGears: return sequenceEncounter
        case .bugLantern: return bugEncounter
        case .bugLanternRepair: return repairEncounter
        }
    }

    private var lastPalaceKineticReducedMotion: Bool?
    private var routeTransitionPending = false
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
        CGPoint(x: 575, y: 225),
        CGPoint(x: 755, y: 205),
        CGPoint(x: 935, y: 225)
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
        prepareAdaptiveLandscapeCanvas(for: view)
        super.didMove(to: view)
        applyPuzzleHUDPolish()
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
        syncPalaceKinetics()

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
                restoreCompletedPathTiles()
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

    private var palaceFocusPoint: CGPoint {
        switch place {
        case .runeGate: return CGPoint(x: 820, y: 330)
        case .memoryBridge: return CGPoint(x: 700, y: 310)
        case .stopGoOrbs: return CGPoint(x: 760, y: 315)
        case .sortingPedestal, .resortVault: return CGPoint(x: 760, y: 335)
        case .mirrorHall: return CGPoint(x: 765, y: 390)
        case .pathTiles: return CGPoint(x: 760, y: 305)
        case .commandGears: return CGPoint(x: 760, y: 320)
        case .bugLantern, .bugLanternRepair: return CGPoint(x: 760, y: 355)
        }
    }

    private func syncPalaceKinetics() {
        lastPalaceKineticReducedMotion = reducedMotion

        var crystalIndex = 0
        enumerateChildNodes(withName: "//*") { [self] node, _ in
            guard let name = node.name else { return }

            if name == "puzzleCrystalFixture" {
                node.removeAction(forKey: "palaceCrystalFloat")
                node.zRotation = 0
                guard !reducedMotion else {
                    node.alpha = min(1, max(0.74, node.alpha))
                    return
                }

                let direction: CGFloat = crystalIndex.isMultiple(of: 2) ? 1 : -1
                let phase = Double(crystalIndex % 4) * 0.18
                node.run(
                    .repeatForever(
                        .sequence([
                            .wait(forDuration: phase),
                            .group([
                                .moveBy(x: direction * 1.6, y: 4, duration: 1.8),
                                .fadeAlpha(to: 0.72, duration: 1.8)
                            ]),
                            .group([
                                .moveBy(x: direction * -1.6, y: -4, duration: 1.8),
                                .fadeAlpha(to: 0.92, duration: 1.8)
                            ])
                        ])
                    ),
                    withKey: "palaceCrystalFloat"
                )
                crystalIndex += 1
            }

            if name.hasPrefix("puzzleAlcoveGlow") {
                node.removeAction(forKey: "palaceAlcoveBreath")
                node.alpha = 1
                guard !reducedMotion else { return }
                node.run(
                    .repeatForever(
                        .sequence([
                            .fadeAlpha(to: 0.48, duration: 1.35),
                            .fadeAlpha(to: 1.0, duration: 1.35)
                        ])
                    ),
                    withKey: "palaceAlcoveBreath"
                )
            }
        }

        for name in ["puzzleFloorSeal", "puzzleStageInlay"] {
            guard let node = childNode(withName: name) else { continue }
            node.removeAction(forKey: "palaceRoomBreath")
            node.alpha = 1
            guard !reducedMotion else { continue }
            node.run(
                .repeatForever(
                    .sequence([
                        .fadeAlpha(to: 0.62, duration: 1.7),
                        .fadeAlpha(to: 1.0, duration: 1.7)
                    ])
                ),
                withKey: "palaceRoomBreath"
            )
        }

        if !reducedMotion {
            focusMoment(on: palaceFocusPoint, hold: 0.56)
        }
    }

    private func applyPuzzleHUDPolish() {
        childNode(withName: "worldTitleBackdrop")?.removeFromParent()
        childNode(withName: "worldTitle")?.removeFromParent()

        let title = ArtSystem.label(worldTitle, size: 20)
        title.fontName = "Georgia-Bold"
        title.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.82, alpha: 1)
        title.horizontalAlignmentMode = .left
        // Wide letters in Memory Bridge and Command Gears exceed a character-count estimate.
        // Reserve the emblem gutter and fit the actual glyphs into the compact plaque.
        if title.frame.width > 338 {
            title.fontSize *= 338 / title.frame.width
        }
        let titleWidth = min(CGFloat(400), max(CGFloat(355), title.frame.width + 60))
        let titlePlate = ArtSystem.plaque(
            CGSize(width: titleWidth, height: 42),
            fill: UIColor(red: 0.045, green: 0.055, blue: 0.13, alpha: 0.90),
            stroke: UIColor(red: 0.72, green: 0.58, blue: 0.98, alpha: 0.54),
            radius: 15
        )
        titlePlate.position = CGPoint(x: 100 + titleWidth / 2, y: 672 + verticalViewportInset)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)

        title.position = CGPoint(x: 140, y: 672 + verticalViewportInset)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        if let emblem = childNode(withName: "decorativeWorldEmblem") {
            emblem.position = CGPoint(x: 121, y: 672 + verticalViewportInset)
            emblem.setScale(0.72)
        }

        if let instructionBackdrop = childNode(withName: "instructionBackdrop") {
            instructionBackdrop.xScale = 0.65
            instructionBackdrop.yScale = 0.80
            instructionBackdrop.position = CGPoint(x: 735, y: 46 - verticalViewportInset)
            instructionBackdrop.alpha = 0.90
        }

        instruction.position = CGPoint(x: 735, y: 46 - verticalViewportInset)
        instruction.fontName = "AvenirNext-Medium"
        instruction.fontSize = 18
        instruction.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.84, alpha: 1)
        instruction.preferredMaxLayoutWidth = 620
        instruction.numberOfLines = 2
    }

    private func buildPuzzleHomeControl() {
        let root = SKNode()
        root.name = "home"
        root.position = CGPoint(x: 52, y: 672 + verticalViewportInset)
        root.zPosition = 2100

        let medallion = ArtSystem.medallion(
            radius: 22,
            fill: UIColor(red: 0.05, green: 0.055, blue: 0.14, alpha: 0.94),
            stroke: UIColor(red: 0.72, green: 0.58, blue: 0.98, alpha: 0.50),
            glow: reducedMotion ? 0 : 1
        )
        medallion.name = "home"
        medallion.addChild(ArtSystem.label("⌂", size: 18))
        root.addChild(medallion)

        let hit = SKShapeNode(circleOfRadius: 30)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = "home"
        hit.zPosition = 2
        root.addChild(hit)

        makeAccessible(root, label: "Return to Story Tree")
        addChild(root)
    }

    override func buildWorld() {
        buildNativePalaceBackdrop()

        for (height, y) in [
            (CGFloat(62), CGFloat(684) + verticalViewportInset),
            (CGFloat(96), CGFloat(42) - verticalViewportInset)
        ] {
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

        buildPuzzleHomeControl()

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
        let accent: UIColor
        switch place {
        case .runeGate:
            accent = UIColor(red: 0.72, green: 0.58, blue: 0.98, alpha: 1)
        case .memoryBridge:
            accent = UIColor(red: 0.48, green: 0.72, blue: 1.0, alpha: 1)
        case .stopGoOrbs:
            accent = UIColor(red: 0.72, green: 0.48, blue: 0.88, alpha: 1)
        case .sortingPedestal, .resortVault:
            accent = UIColor(red: 0.48, green: 0.82, blue: 0.82, alpha: 1)
        case .mirrorHall:
            accent = UIColor(red: 0.55, green: 0.82, blue: 1.0, alpha: 1)
        case .pathTiles:
            accent = UIColor(red: 0.52, green: 0.78, blue: 0.92, alpha: 1)
        case .commandGears:
            accent = UIColor(red: 0.88, green: 0.66, blue: 0.30, alpha: 1)
        case .bugLantern, .bugLanternRepair:
            accent = UIColor(red: 0.76, green: 0.55, blue: 0.92, alpha: 1)
        }

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

        let hall = ArtSystem.box(
            CGSize(width: 1080, height: 430),
            color: UIColor(red: 0.09, green: 0.08, blue: 0.20, alpha: 0.78),
            radius: 66
        )
        hall.strokeColor = accent.withAlphaComponent(0.54)
        hall.lineWidth = 4
        hall.position = CGPoint(x: 690, y: 390)
        hall.zPosition = -215
        hall.name = "puzzleArchitecture"
        if place == .runeGate {
            hall.alpha = 0.05
            hall.strokeColor = .clear
        }
        addChild(hall)

        if place != .runeGate {
            let upperVault = ArtSystem.box(
                CGSize(width: 980, height: 96),
                color: UIColor(red: 0.075, green: 0.07, blue: 0.17, alpha: 0.80),
                radius: 44
            )
            upperVault.strokeColor = .clear
            upperVault.position = CGPoint(x: 690, y: 606)
            upperVault.zPosition = -208
            upperVault.name = "puzzleUpperVault"
            addChild(upperVault)

            let cornice = ArtSystem.box(
                CGSize(width: 1030, height: 22),
                color: UIColor(red: 0.18, green: 0.14, blue: 0.28, alpha: 0.98),
                radius: 11
            )
            cornice.strokeColor = UIColor(red: 0.84, green: 0.65, blue: 0.31, alpha: 0.68)
            cornice.lineWidth = 3
            cornice.position = CGPoint(x: 690, y: 586)
            cornice.zPosition = -192
            cornice.name = "puzzleVaultCornice"
            addChild(cornice)

            let ribRotations: [CGFloat] = [-0.16, -0.08, 0, 0.08, 0.16]
            for (index, x) in [CGFloat(260), 475, 690, 905, 1120].enumerated() {
                let rib = ArtSystem.box(
                    CGSize(width: 13, height: 120),
                    color: UIColor(red: 0.24, green: 0.20, blue: 0.34, alpha: 0.82),
                    radius: 6
                )
                rib.strokeColor = accent.withAlphaComponent(0.34)
                rib.lineWidth = 2
                rib.position = CGPoint(x: x, y: 636)
                rib.zRotation = ribRotations[index]
                rib.zPosition = -200
                rib.name = "puzzleVaultRib\(index)"
                addChild(rib)

                let ribGem = SKShapeNode(circleOfRadius: 8)
                ribGem.fillColor = accent.withAlphaComponent(0.72)
                ribGem.strokeColor = UIColor(red: 0.94, green: 0.78, blue: 0.38, alpha: 0.72)
                ribGem.lineWidth = 2
                ribGem.position = CGPoint(x: x, y: 584)
                ribGem.zPosition = -189
                ribGem.name = "decorativePuzzleVaultGem"
                addChild(ribGem)
            }
        }

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

        if place != .runeGate {
            let seal = SKShapeNode(ellipseOf: CGSize(width: 330, height: 94))
            seal.fillColor = UIColor(red: 0.12, green: 0.09, blue: 0.20, alpha: 0.26)
            seal.strokeColor = accent.withAlphaComponent(0.42)
            seal.lineWidth = 5
            seal.position = CGPoint(x: 690, y: 104)
            seal.zPosition = -132
            seal.name = "puzzleFloorSeal"
            addChild(seal)

            let sealInner = SKShapeNode(ellipseOf: CGSize(width: 220, height: 60))
            sealInner.fillColor = .clear
            sealInner.strokeColor = UIColor(red: 0.88, green: 0.68, blue: 0.30, alpha: 0.38)
            sealInner.lineWidth = 3
            sealInner.zPosition = 1
            seal.addChild(sealInner)

            let sealCore = SKShapeNode(circleOfRadius: 13)
            sealCore.fillColor = accent.withAlphaComponent(0.52)
            sealCore.strokeColor = UIColor(red: 0.96, green: 0.80, blue: 0.40, alpha: 0.64)
            sealCore.lineWidth = 2
            sealCore.zPosition = 2
            seal.addChild(sealCore)
        }

        for x in [CGFloat(205), 405, 605, 805, 1005, 1205] {
            let pillar = ArtSystem.box(
                CGSize(width: 46, height: 350),
                color: UIColor(red: 0.12, green: 0.11, blue: 0.24, alpha: 1),
                radius: 12
            )
            pillar.strokeColor = accent.withAlphaComponent(0.38)
            pillar.lineWidth = 2
            pillar.position = CGPoint(x: x, y: 405)
            pillar.zPosition = -195
            pillar.name = "puzzlePillar"
            if place != .runeGate {
                addChild(pillar)
            }

            if place != .runeGate {
                let cap = SKShapeNode(circleOfRadius: 31)
                cap.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.38, alpha: 1)
                cap.strokeColor = UIColor(red: 0.86, green: 0.67, blue: 0.32, alpha: 0.88)
                cap.lineWidth = 4
                cap.position = CGPoint(x: x, y: 565)
                cap.zPosition = -190
                cap.name = "decorativePuzzlePillarCap"
                addChild(cap)
            }
        }

        for (index, x) in [CGFloat(320), 690, 1060].enumerated() {
            let arch = SKShapeNode(
                rectOf: CGSize(width: 235, height: 285),
                cornerRadius: 108
            )
            arch.fillColor = UIColor(red: 0.065, green: 0.075, blue: 0.16, alpha: 0.84)
            arch.strokeColor = accent.withAlphaComponent(0.58)
            arch.lineWidth = 4
            arch.position = CGPoint(x: x, y: 410)
            arch.zPosition = -185
            arch.name = "puzzleAlcove\(index)"
            if place != .runeGate {
                addChild(arch)
            }

            let glow = SKShapeNode(ellipseOf: CGSize(width: 150, height: 190))
            glow.fillColor = accent.withAlphaComponent(0.075)
            glow.strokeColor = accent.withAlphaComponent(0.16)
            glow.lineWidth = 2
            glow.position = CGPoint(x: 0, y: 2)
            glow.zPosition = -2
            glow.name = "puzzleAlcoveGlow\(index)"
            arch.addChild(glow)

            let inner = SKShapeNode(
                rectOf: CGSize(width: 177, height: 225),
                cornerRadius: 84
            )
            inner.fillColor = UIColor(red: 0.10, green: 0.14, blue: 0.27, alpha: 0.88)
            inner.strokeColor = accent.withAlphaComponent(0.56)
            inner.lineWidth = 4
            inner.name = "puzzleAlcoveInner\(index)"
            arch.addChild(inner)

            let keystone = SKShapeNode(circleOfRadius: 10)
            keystone.fillColor = UIColor(red: 0.88, green: 0.68, blue: 0.31, alpha: 0.92)
            keystone.strokeColor = accent.withAlphaComponent(0.72)
            keystone.lineWidth = 2
            keystone.position = CGPoint(x: 0, y: 137)
            keystone.zPosition = 2
            keystone.name = "decorativePuzzleKeystone"
            arch.addChild(keystone)

            let plinth = ArtSystem.box(
                CGSize(width: 202, height: 18),
                color: UIColor(red: 0.24, green: 0.18, blue: 0.34, alpha: 0.96),
                radius: 7
            )
            plinth.strokeColor = UIColor(red: 0.82, green: 0.63, blue: 0.31, alpha: 0.58)
            plinth.lineWidth = 2
            plinth.position = CGPoint(x: 0, y: -151)
            plinth.zPosition = 2
            plinth.name = "puzzleAlcovePlinth\(index)"
            arch.addChild(plinth)
        }

        if place != .runeGate {
            for (index, point) in [
                CGPoint(x: 255, y: 545),
                CGPoint(x: 505, y: 515),
                CGPoint(x: 875, y: 515),
                CGPoint(x: 1125, y: 545)
            ].enumerated() {
                let mount = SKShapeNode(circleOfRadius: 25)
                mount.fillColor = UIColor(red: 0.13, green: 0.11, blue: 0.24, alpha: 0.96)
                mount.strokeColor = UIColor(red: 0.84, green: 0.65, blue: 0.31, alpha: 0.72)
                mount.lineWidth = 3
                mount.position = CGPoint(x: point.x, y: point.y - 22)
                mount.zPosition = -171
                mount.name = "puzzleCrystalSconce\(index)"
                addChild(mount)

                let halo = SKShapeNode(circleOfRadius: 34)
                halo.fillColor = accent.withAlphaComponent(0.055)
                halo.strokeColor = accent.withAlphaComponent(0.18)
                halo.lineWidth = 2
                halo.position = point
                halo.zPosition = -170
                halo.name = "decorativePuzzleCrystalHalo"
                addChild(halo)

                if let crystal = ArtSystem.sprite(
                    "Crystal",
                    size: CGSize(width: 66, height: 96)
                ) {
                    crystal.position = point
                    crystal.zPosition = -168
                    crystal.alpha = index.isMultiple(of: 2) ? 0.88 : 0.74
                    crystal.name = "puzzleCrystalFixture"
                    addChild(crystal)
                }
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
        if place != .runeGate {
            addChild(dais)

            let daisInset = ArtSystem.box(
                CGSize(width: 520, height: 12),
                color: accent.withAlphaComponent(0.18),
                radius: 6
            )
            daisInset.strokeColor = accent.withAlphaComponent(0.34)
            daisInset.lineWidth = 2
            daisInset.position = CGPoint(x: 775, y: 236)
            daisInset.zPosition = -102
            daisInset.name = "puzzleStageInlay"
            addChild(daisInset)
        }

        buildPalaceRoomIdentity(accent: accent)
        buildIllustratedPalaceRoom()
    }

    private var illustratedRoomAsset: String {
        switch place {
        case .runeGate: return "PuzzleRuneGateIllustratedV2"
        case .memoryBridge: return "PuzzleMemoryBridgeIllustratedV2"
        case .stopGoOrbs: return "PuzzleStopGoOrbsIllustratedV2"
        case .sortingPedestal: return "PuzzleSortingPedestalIllustratedV2"
        case .resortVault: return "PuzzleResortVaultIllustratedV2"
        case .mirrorHall: return "PuzzleMirrorHallIllustratedV2"
        case .pathTiles: return "PuzzlePathTilesIllustratedV2"
        case .commandGears: return "PuzzleCommandGearsIllustratedV2"
        case .bugLantern: return "PuzzleBugLanternIllustratedV2"
        case .bugLanternRepair: return "PuzzleBugLanternRepairIllustratedV2"
        }
    }

    private func buildIllustratedPalaceRoom() {
        guard let texture = ArtSystem.texture(illustratedRoomAsset) else { return }
        // The 4:3 iPad has a taller scene than the 16:9 design canvas.
        // Aspect-fill the illustration into the extended viewport rather than
        // leaving black letterbox bands above and below a beautiful room.
        // Keep native challenge objects at their authored, unchanged positions.
        let paintingHeight = max(designCanvasSize.height, size.height)
        let paintingWidth = paintingHeight * designCanvasSize.width / designCanvasSize.height
        let painting = SKSpriteNode(
            texture: texture,
            size: CGSize(width: paintingWidth, height: paintingHeight)
        )
        painting.position = CGPoint(x: 640, y: 360)
        painting.zPosition = -250
        painting.name = "puzzleIllustratedBackdrop"
        painting.isUserInteractionEnabled = false
        painting.userData = NSMutableDictionary(dictionary: [
            "sourceAsset": illustratedRoomAsset,
            "sourcePixels": ArtSystem.pixelSize(illustratedRoomAsset)?.width ?? 0,
            "aspectFilledForIPad": true
        ])
        addChild(painting)

        // Illustration supplies masonry and depth. Native lights and physical
        // puzzle mechanics remain separate so they can react to the child.
        // The approved painting already contains the complete room. Legacy
        // synthetic architecture and floating crystal decorations made a second,
        // visibly disconnected room above it. Retain nodes for older native
        // structure/regression checks, but never draw the duplicate decoration.
        let paintedScenery: Set<String> = [
            "puzzleArchitecture", "puzzleUpperVault", "puzzleVaultCornice",
            "puzzleFloor", "puzzleFloorTexture", "puzzlePillar",
            "decorativePuzzlePillarCap", "puzzleRoomIdentity",
            "puzzleStageDais", "puzzleStageInlay", "puzzleFloorSeal",
            "puzzleCrystalFixture", "decorativePuzzleCrystalHalo",
            "decorativePuzzleVaultGem", "decorativePuzzleKeystone"
        ]
        for node in children {
            guard let name = node.name else { continue }
            if paintedScenery.contains(name) || name.hasPrefix("puzzleAlcove")
                || name.hasPrefix("puzzleVaultRib")
                || name.hasPrefix("puzzleCrystalSconce") {
                node.isHidden = true
            }
        }
    }

    /// Crisp, room-specific architecture layered behind the learning mechanic.
    /// Every Puzzle Palace stop shares one visual language, but no longer looks
    /// like the same prototype room with a different activity dropped on top.
    private func buildPalaceRoomIdentity(accent: UIColor) {
        let root = SKNode()
        root.name = "puzzleRoomIdentity"
        root.zPosition = -165
        root.isUserInteractionEnabled = false

        let motifs: [String]
        switch place {
        case .runeGate: motifs = ["✦", "◇", "◈"]
        case .memoryBridge: motifs = ["Ⅰ", "Ⅱ", "Ⅲ"]
        case .stopGoOrbs: motifs = ["●", "✦", "●"]
        case .sortingPedestal: motifs = ["○", "◇", "○"]
        case .resortVault: motifs = ["↻", "◇", "↺"]
        case .mirrorHall: motifs = ["◁", "◇", "▷"]
        case .pathTiles: motifs = ["↑", "→", "↑"]
        case .commandGears: motifs = ["◆", "↻", "◇"]
        case .bugLantern: motifs = ["!", "◇", "?"]
        case .bugLanternRepair: motifs = ["↔", "◆", "↻"]
        }

        let farPortal = SKShapeNode(
            rectOf: CGSize(width: 760, height: 270),
            cornerRadius: 126
        )
        farPortal.position = CGPoint(x: 700, y: 420)
        farPortal.fillColor = UIColor(red: 0.035, green: 0.035, blue: 0.095, alpha: 0.72)
        farPortal.strokeColor = accent.withAlphaComponent(0.34)
        farPortal.lineWidth = 5
        farPortal.name = "puzzleRoomFarPortal"
        root.addChild(farPortal)

        let portalGlow = SKShapeNode(ellipseOf: CGSize(width: 600, height: 190))
        portalGlow.fillColor = accent.withAlphaComponent(0.055)
        portalGlow.strokeColor = accent.withAlphaComponent(0.12)
        portalGlow.lineWidth = 3
        portalGlow.position.y = -4
        portalGlow.name = "decorativePuzzleRoomGlow"
        portalGlow.userData = NSMutableDictionary(dictionary: [
            "decorativeMotionRole": "pulse"
        ])
        farPortal.addChild(portalGlow)

        for (index, x) in [CGFloat(-220), 0, 220].enumerated() {
            let medallion = ArtSystem.medallion(
                radius: index == 1 ? 38 : 29,
                fill: UIColor(red: 0.08, green: 0.065, blue: 0.16, alpha: 0.94),
                stroke: accent.withAlphaComponent(index == 1 ? 0.70 : 0.42),
                glow: reducedMotion ? 0 : (index == 1 ? 3 : 1)
            )
            medallion.position = CGPoint(x: x, y: 66 + (index == 1 ? 18 : 0))
            medallion.name = "decorativePuzzleRoomMotif"
            let mark = ArtSystem.label(motifs[index], size: index == 1 ? 30 : 22)
            mark.fontColor = UIColor(red: 1.0, green: 0.87, blue: 0.48, alpha: 0.90)
            medallion.addChild(mark)
            farPortal.addChild(medallion)
        }

        // Side buttresses stay behind Valkyrie but create a foreground-to-midground
        // read that the old flat contact-sheet artwork never had.
        for (index, x) in [CGFloat(70), 1210].enumerated() {
            let buttress = ArtSystem.panel(
                CGSize(width: 112, height: 430),
                fill: UIColor(red: 0.075, green: 0.065, blue: 0.16, alpha: 0.96),
                stroke: accent.withAlphaComponent(0.36),
                radius: 38,
                lineWidth: 3,
                shadowAlpha: 0.24
            )
            buttress.position = CGPoint(x: x, y: 354)
            buttress.zRotation = index == 0 ? -0.035 : 0.035
            buttress.name = "puzzleRoomButtress"
            root.addChild(buttress)

            if let crystal = ArtSystem.sprite("Crystal", size: CGSize(width: 58, height: 86)) {
                crystal.position = CGPoint(x: x, y: 505)
                crystal.alpha = 0.76
                crystal.name = "decorativePuzzleRoomCrystal"
                root.addChild(crystal)
            }
        }

        for (index, x) in [CGFloat(260), 480, 700, 920, 1140].enumerated() {
            let lamp = SKShapeNode(circleOfRadius: index == 2 ? 9 : 6)
            lamp.fillColor = accent.withAlphaComponent(index == 2 ? 0.78 : 0.52)
            lamp.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.42, alpha: 0.68)
            lamp.lineWidth = 1.5
            lamp.glowWidth = reducedMotion ? 0 : CGFloat(index == 2 ? 8 : 4)
            lamp.position = CGPoint(x: x, y: 610 - CGFloat(abs(index - 2)) * 12)
            lamp.name = "decorativePuzzleRoomLamp"
            root.addChild(lamp)
        }

        // Each room gets one unmistakable architectural signature.
        switch place {
        case .runeGate:
            for x in stride(from: CGFloat(370), through: CGFloat(1010), by: CGFloat(128)) {
                let rune = ArtSystem.label("◇", size: 26)
                rune.position = CGPoint(x: x, y: 520 + sin(x / 90) * 18)
                rune.fontColor = accent.withAlphaComponent(0.48)
                rune.name = "decorativeRuneHallGlyph"
                root.addChild(rune)
            }

        case .memoryBridge:
            for y in stride(from: CGFloat(330), through: CGFloat(555), by: CGFloat(54)) {
                for x in [CGFloat(330), 1080] {
                    let bead = SKShapeNode(circleOfRadius: 8)
                    bead.position = CGPoint(x: x, y: y)
                    bead.fillColor = accent.withAlphaComponent(0.48)
                    bead.strokeColor = .clear
                    bead.name = "decorativeMemoryLantern"
                    root.addChild(bead)
                }
            }
            for y in [CGFloat(300), 350] {
                let mist = SKShapeNode(ellipseOf: CGSize(width: 760, height: 72))
                mist.position = CGPoint(x: 700, y: y)
                mist.fillColor = UIColor(red: 0.42, green: 0.52, blue: 0.86, alpha: 0.035)
                mist.strokeColor = .clear
                mist.name = "decorativeMemoryMist"
                root.addChild(mist)
            }

        case .stopGoOrbs:
            for y in [CGFloat(340), 430, 520] {
                let conduit = ArtSystem.box(
                    CGSize(width: 760, height: 6),
                    color: accent.withAlphaComponent(0.18),
                    radius: 3
                )
                conduit.position = CGPoint(x: 700, y: y)
                conduit.strokeColor = .clear
                conduit.name = "decorativeStopGoConduit"
                root.addChild(conduit)
            }

        case .sortingPedestal, .resortVault:
            for x in [CGFloat(390), 700, 1010] {
                let shelf = ArtSystem.panel(
                    CGSize(width: 180, height: 72),
                    fill: UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 0.72),
                    stroke: accent.withAlphaComponent(0.30),
                    radius: 24,
                    lineWidth: 2,
                    shadowAlpha: 0.12
                )
                shelf.position = CGPoint(x: x, y: 470)
                shelf.name = "decorativeSortingGallery"
                root.addChild(shelf)
            }

        case .mirrorHall:
            for x in [CGFloat(330), 500, 900, 1070] {
                let shard = SKShapeNode(
                    rectOf: CGSize(width: 54, height: 220),
                    cornerRadius: 25
                )
                shard.position = CGPoint(x: x, y: 440)
                shard.zRotation = x < 700 ? -0.10 : 0.10
                shard.fillColor = UIColor(red: 0.58, green: 0.86, blue: 1.0, alpha: 0.055)
                shard.strokeColor = accent.withAlphaComponent(0.30)
                shard.lineWidth = 2
                shard.name = "decorativeMirrorShard"
                root.addChild(shard)
            }

        case .pathTiles:
            for x in stride(from: CGFloat(360), through: CGFloat(1040), by: CGFloat(85)) {
                let guide = ArtSystem.box(
                    CGSize(width: 2, height: 260),
                    color: accent.withAlphaComponent(0.12),
                    radius: 1
                )
                guide.position = CGPoint(x: x, y: 410)
                guide.zRotation = (x - 700) * 0.00045
                guide.strokeColor = .clear
                guide.name = "decorativePathGuide"
                root.addChild(guide)
            }

        case .commandGears:
            for (index, x) in [CGFloat(350), 520, 880, 1050].enumerated() {
                let gear = ArtSystem.gear(radius: index.isMultiple(of: 2) ? 31 : 24)
                gear.position = CGPoint(x: x, y: 455 + CGFloat(index % 2) * 70)
                gear.setScale(0.9)
                gear.alpha = 0.42
                gear.name = "decorativeCommandGear"
                root.addChild(gear)
            }

        case .bugLantern, .bugLanternRepair:
            let cablePath = CGMutablePath()
            cablePath.move(to: CGPoint(x: 300, y: 520))
            cablePath.addCurve(
                to: CGPoint(x: 1100, y: 390),
                control1: CGPoint(x: 470, y: 310),
                control2: CGPoint(x: 880, y: 610)
            )
            let cable = SKShapeNode(path: cablePath)
            cable.strokeColor = accent.withAlphaComponent(0.30)
            cable.lineWidth = 8
            cable.name = "decorativeDiagnosticCable"
            root.addChild(cable)

            for x in [CGFloat(420), 700, 980] {
                let status = SKShapeNode(circleOfRadius: 10)
                status.position = CGPoint(x: x, y: 505)
                status.fillColor = accent.withAlphaComponent(0.62)
                status.strokeColor = UIColor(red: 1.0, green: 0.78, blue: 0.34, alpha: 0.62)
                status.lineWidth = 2
                status.name = "decorativeDiagnosticLamp"
                root.addChild(status)
            }
        }

        addChild(root)
    }

    // Sample actual floor stone from an existing Palace painting. Every movable
    // tile keeps native hit testing and semantics; the painting itself is untouched.
    private lazy var palaceStoneTexture: SKTexture? = {
        guard let painting = ArtSystem.texture("PuzzleRuneGateIllustratedV2") else { return nil }
        return SKTexture(
            rect: CGRect(x: 0.31, y: 0.055, width: 0.22, height: 0.18),
            in: painting
        )
    }()

    private func carvedPalaceStone(_ size: CGSize, radius: CGFloat) -> SKShapeNode {
        let face = SKShapeNode(rectOf: size, cornerRadius: radius)
        face.fillColor = UIColor(red: 0.67, green: 0.57, blue: 0.70, alpha: 1)
        face.fillTexture = palaceStoneTexture
        face.strokeColor = UIColor(red: 0.97, green: 0.79, blue: 0.49, alpha: 0.95)
        face.lineWidth = 3
        return face
    }

    // One set of stone-and-brass tools is reused across the palace. These are
    // physical SpriteKit shapes, not text-only UI floating above the paintings.
    private func palaceCog(
        radius: CGFloat,
        teeth: Int,
        fill: UIColor,
        stroke: UIColor
    ) -> SKShapeNode {
        let path = CGMutablePath()
        for index in 0..<(teeth * 4) {
            let angle = CGFloat(index) * .pi / CGFloat(teeth * 2)
            let outer = index % 4 == 0 || index % 4 == 1
            let distance = outer ? radius : radius * 0.87
            let point = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        let cog = SKShapeNode(path: path)
        cog.fillColor = fill
        cog.fillTexture = palaceStoneTexture
        cog.strokeColor = stroke
        cog.lineWidth = 3

        // A recessed central bearing makes the silhouette read as an installed
        // clockwork part rather than a flat on-screen command icon.
        let bearing = SKShapeNode(circleOfRadius: radius * 0.68)
        bearing.fillColor = UIColor(red: 0.12, green: 0.09, blue: 0.17, alpha: 0.44)
        bearing.strokeColor = stroke.withAlphaComponent(0.48)
        bearing.lineWidth = 2
        bearing.name = "decorativeCogBearing"
        cog.addChild(bearing)
        return cog
    }

    // The approved 16:9 painting is aspect-filled on a 4:3 iPad.
    // Follow its doorway when fitting native lock pieces on either surface.
    private func paintedDoorPoint(_ point: CGPoint) -> CGPoint {
        let scale = max(1, size.height / designCanvasSize.height)
        return CGPoint(
            x: 640 + (point.x - 640) * scale,
            y: 360 + (point.y - 360) * scale
        )
    }

    private func buildRuneGate() {
        // Follow the doorway in the painted background instead of drawing a
        // second, oversized purple cartoon portal to its right.
        let arch = SKShapeNode(
            rectOf: CGSize(width: 168, height: 238),
            cornerRadius: 74
        )
        arch.fillColor = .clear
        arch.strokeColor = UIColor(red: 0.88, green: 0.70, blue: 0.37, alpha: 0.035)
        arch.lineWidth = 5
        arch.position = paintedDoorPoint(CGPoint(x: 949, y: 489))
        arch.name = "puzzleGate"
        arch.zPosition = 360
        addChild(arch)

        // An actual opening is revealed on solving the final lock. The
        // illustrated (closed) door underneath is then occluded by the passage.
        let passage = SKShapeNode(
            rectOf: CGSize(width: 32, height: 153),
            cornerRadius: 15
        )
        passage.position.y = -11
        passage.fillColor = UIColor(red: 1, green: 0.84, blue: 0.53, alpha: 0.82)
        passage.strokeColor = UIColor(red: 1, green: 0.92, blue: 0.64, alpha: 0.68)
        passage.lineWidth = 4
        passage.alpha = 0
        passage.name = "puzzleGateOpening"
        passage.zPosition = -2
        arch.addChild(passage)

        let door = SKShapeNode(
            rectOf: CGSize(width: 134, height: 188),
            cornerRadius: 56
        )
        door.fillColor = .clear
        door.strokeColor = UIColor(red: 0.84, green: 0.62, blue: 0.37, alpha: 0.045)
        door.lineWidth = 2
        door.position.y = -11
        door.name = "puzzleGateDoor"
        arch.addChild(door)

        // Brass hinges and the actual lock make the affordance part of the
        // illustrated door. These pieces retreat with the door when it opens.
        for y in [CGFloat(-58), 60] {
            let hinge = SKShapeNode(rectOf: CGSize(width: 116, height: 6), cornerRadius: 3)
            hinge.fillColor = UIColor(red: 0.48, green: 0.34, blue: 0.20, alpha: 0.72)
            hinge.strokeColor = UIColor(red: 0.83, green: 0.66, blue: 0.37, alpha: 0.86)
            hinge.lineWidth = 1.5
            hinge.position.y = y
            hinge.name = "decorativeRuneDoorHinge"
            door.addChild(hinge)
        }

        let lock = palaceCog(
            radius: 25, teeth: 8,
            fill: UIColor(red: 0.29, green: 0.21, blue: 0.24, alpha: 0.96),
            stroke: UIColor(red: 0.86, green: 0.70, blue: 0.43, alpha: 1)
        )
        lock.name = "puzzleGateLock"
        lock.zPosition = 3
        lock.position.y = -14
        door.addChild(lock)

        let keyhole = SKShapeNode(circleOfRadius: 10)
        keyhole.fillColor = UIColor(red: 0.10, green: 0.075, blue: 0.14, alpha: 1)
        keyhole.strokeColor = UIColor(red: 0.98, green: 0.81, blue: 0.48, alpha: 0.82)
        keyhole.lineWidth = 2
        keyhole.name = "puzzleGateKeyhole"
        lock.addChild(keyhole)

        let crown = SKShapeNode(path: {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 15))
            path.addLine(to: CGPoint(x: -12, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -15))
            path.addLine(to: CGPoint(x: 12, y: 0))
            path.closeSubpath()
            return path
        }())
        crown.position.y = 91
        crown.fillColor = UIColor(red: 0.78, green: 0.57, blue: 0.26, alpha: 0.98)
        crown.strokeColor = UIColor(red: 0.98, green: 0.85, blue: 0.51, alpha: 0.98)
        crown.lineWidth = 2
        crown.name = "puzzleGateCrest"
        arch.addChild(crown)

        let threshold = SKShapeNode(ellipseOf: CGSize(width: 152, height: 19))
        threshold.fillColor = UIColor(red: 0.30, green: 0.18, blue: 0.14, alpha: 0.28)
        threshold.strokeColor = UIColor(red: 0.87, green: 0.69, blue: 0.39, alpha: 0.65)
        threshold.lineWidth = 2
        threshold.position = paintedDoorPoint(CGPoint(x: 949, y: 262))
        threshold.name = "decorativeRuneGateThreshold"
        threshold.zPosition = 345
        addChild(threshold)
    }

    private func buildRunePath() {
        let pathRoot = SKNode()
        pathRoot.name = "runePath"
        pathRoot.zPosition = 120
        pathRoot.isUserInteractionEnabled = false

        let steppingPoints = [
            CGPoint(x: 845, y: 175),
            CGPoint(x: 915, y: 185),
            CGPoint(x: 980, y: 198),
            CGPoint(x: 1035, y: 218)
        ]
        for (index, point) in steppingPoints.enumerated() {
            let stone = SKShapeNode(ellipseOf: CGSize(width: 58, height: 26))
            stone.fillColor = UIColor(red: 0.24, green: 0.19, blue: 0.34, alpha: 0.54)
            stone.strokeColor = UIColor(red: 0.66, green: 0.55, blue: 0.88, alpha: 0.34)
            stone.lineWidth = 2
            stone.position = point
            stone.zRotation = index.isMultiple(of: 2) ? 0.04 : -0.05
            pathRoot.addChild(stone)
        }
        addChild(pathRoot)

        for index in 0..<PuzzlePalaceEncounterCatalog.runeGate.count {
            let light = ArtSystem.medallion(
                radius: 11,
                fill: UIColor(red: 0.20, green: 0.16, blue: 0.31, alpha: 0.88),
                stroke: UIColor(red: 0.66, green: 0.56, blue: 0.92, alpha: 0.56)
            )
            light.position = CGPoint(x: 1035 + CGFloat(index) * 32, y: 530)
            light.name = "runeProgress\(index)"
            light.zPosition = 410
            addChild(light)
        }
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
        // Keep the lock centered on the actual 4:3 painted door rather than
        // leaving the lower row hanging over the stairs.
        board.position = paintedDoorPoint(CGPoint(x: 949, y: 489))
        board.position.y -= 11
        board.zPosition = 720
        addChild(board)

        // Four engraved lock recesses sit INSIDE the painted door rather than
        // stretching beyond its arch like a horizontal answer menu. Read in
        // ordinary row order: top-left, top-right, bottom-left, bottom-right.
        let housing = SKShapeNode(
            rectOf: CGSize(width: 161, height: 164), cornerRadius: 24
        )
        housing.fillColor = UIColor(red: 0.18, green: 0.12, blue: 0.23, alpha: 0.29)
        housing.strokeColor = UIColor(red: 0.90, green: 0.72, blue: 0.44, alpha: 0.77)
        housing.lineWidth = 3
        housing.name = "runeLockHousing"
        housing.zPosition = -3
        board.addChild(housing)

        let engravedTrail = CGMutablePath()
        engravedTrail.move(to: CGPoint(x: -40, y: 38))
        engravedTrail.addLine(to: CGPoint(x: 40, y: 38))
        engravedTrail.addLine(to: CGPoint(x: -40, y: -38))
        engravedTrail.addLine(to: CGPoint(x: 40, y: -38))
        let inlay = SKShapeNode(path: engravedTrail)
        inlay.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 0.45, alpha: 0.56)
        inlay.lineWidth = 5
        inlay.name = "decorativeRuneCircuit"
        inlay.zPosition = -2
        board.addChild(inlay)

        let lockSlots = [
            CGPoint(x: -40, y: 38), CGPoint(x: 40, y: 38),
            CGPoint(x: -40, y: -38), CGPoint(x: 40, y: -38)
        ]
        for (index, rune) in encounter.fixedRunes.enumerated() {
            let stone = runeStone(rune, name: "fixedRune")
            stone.position = lockSlots[index]
            board.addChild(stone)
        }

        let socket = runeSocket()
        socket.position = lockSlots[3]
        socket.name = "runeSocket"
        board.addChild(socket)

        for (index, choice) in encounter.choices.enumerated() {
            let pedestal = runeChoice(choice, index: index)
            pedestal.position = choicePoints[index]
            pedestal.name = "runeChoice"
            pedestal.userData = NSMutableDictionary(dictionary: ["choice": choice])
            addChild(pedestal)
            registerInteraction(pedestal, clearance: 12)
        }

        showAttentionCue(
            at: CGPoint(x: 755, y: 142),
            tint: UIColor(red: 0.76, green: 0.65, blue: 1.0, alpha: 1),
            width: 150
        )
    }

    private func runeStone(_ rune: String, name: String) -> SKShapeNode {
        let stone = carvedPalaceStone(CGSize(width: 62, height: 68), radius: 14)
        stone.name = name

        let inset = SKShapeNode(
            rectOf: CGSize(width: 49, height: 55),
            cornerRadius: 12
        )
        inset.fillColor = UIColor(red: 0.22, green: 0.14, blue: 0.28, alpha: 0.36)
        inset.strokeColor = UIColor(red: 0.94, green: 0.76, blue: 0.48, alpha: 0.78)
        inset.lineWidth = 2
        inset.name = name
        stone.addChild(inset)

        let glyph = ArtSystem.label(rune, size: 30)
        glyph.fontColor = UIColor(red: 1.0, green: 0.85, blue: 0.52, alpha: 1)
        glyph.name = name
        stone.addChild(glyph)
        return stone
    }

    private func runeSocket() -> SKShapeNode {
        let socket = SKShapeNode(
            rectOf: CGSize(width: 62, height: 68),
            cornerRadius: 16
        )
        socket.fillColor = UIColor(red: 0.11, green: 0.08, blue: 0.14, alpha: 1)
        socket.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 0.40, alpha: 0.96)
        socket.lineWidth = 4
        socket.name = "runeSocket"

        let inlay = SKShapeNode(
            rectOf: CGSize(width: 48, height: 54),
            cornerRadius: 11
        )
        inlay.fillColor = UIColor(red: 0.075, green: 0.055, blue: 0.10, alpha: 1)
        inlay.strokeColor = UIColor(red: 0.48, green: 0.34, blue: 0.28, alpha: 0.86)
        inlay.lineWidth = 2
        inlay.name = "runeSocketInlay"
        socket.addChild(inlay)

        let mark = ArtSystem.label("?", size: 29)
        mark.fontColor = UIColor(red: 0.99, green: 0.83, blue: 0.54, alpha: 1)
        mark.name = "runeSocketMark"
        socket.addChild(mark)
        return socket
    }

    private func runeChoice(_ rune: String, index: Int) -> SKShapeNode {
        let stone = runeStone(rune, name: "runeChoice")
        stone.setScale(1.19)
        stone.fillColor = UIColor(red: 0.80, green: 0.71, blue: 0.76, alpha: 1)

        // The selectable piece rests on a low stone plinth at floor level.
        let ledge = SKShapeNode(
            rectOf: CGSize(width: 94, height: 21),
            cornerRadius: 7
        )
        ledge.position.y = -50
        ledge.fillColor = UIColor(red: 0.29, green: 0.22, blue: 0.22, alpha: 0.98)
        ledge.strokeColor = UIColor(red: 0.88, green: 0.70, blue: 0.44, alpha: 0.85)
        ledge.lineWidth = 2
        ledge.name = "runeChoice"
        stone.addChild(ledge)

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 114, height: 22))
        shadow.fillColor = UIColor(red: 0.13, green: 0.075, blue: 0.11, alpha: 0.31)
        shadow.strokeColor = .clear
        shadow.position.y = -66
        shadow.zPosition = -2
        shadow.name = "runeChoice"
        stone.addChild(shadow)

        makeAccessible(stone, label: "Place the \(rune) rune in the palace lock")
        return stone
    }

    private func clearRuneObjects() {
        childNode(withName: "runeBoard")?.removeFromParent()
        children.filter { $0.name == "runeChoice" }.forEach { $0.removeFromParent() }
        clearAttentionCue()
    }

    private func buildMemoryBridgeWorld() {
        // A broken crossing in the palace floor, not four UI rectangles in
        // front of the waterfall. The four stones form one continuous deck.
        let voidPath = CGMutablePath()
        voidPath.move(to: CGPoint(x: 393, y: 294))
        voidPath.addLine(to: CGPoint(x: 478, y: 376))
        voidPath.addLine(to: CGPoint(x: 1054, y: 376))
        voidPath.addLine(to: CGPoint(x: 1126, y: 294))
        voidPath.addLine(to: CGPoint(x: 1056, y: 211))
        voidPath.addLine(to: CGPoint(x: 465, y: 211))
        voidPath.closeSubpath()
        let chasm = SKShapeNode(path: voidPath)
        chasm.fillColor = UIColor(red: 0.11, green: 0.10, blue: 0.26, alpha: 0.73)
        chasm.strokeColor = UIColor(red: 0.74, green: 0.62, blue: 0.77, alpha: 0.85)
        chasm.lineWidth = 6
        chasm.name = "memoryChasm"
        chasm.zPosition = 235
        addChild(chasm)

        let depth = SKShapeNode(ellipseOf: CGSize(width: 535, height: 73))
        depth.position = CGPoint(x: 760, y: 264)
        depth.fillColor = UIColor(red: 0.28, green: 0.19, blue: 0.41, alpha: 0.27)
        depth.strokeColor = .clear
        depth.name = "memoryChasmDepth"
        depth.zPosition = 237
        addChild(depth)

        for index in 0..<4 {
            let plank = carvedPalaceStone(
                CGSize(width: 161, height: 107), radius: 12
            )
            plank.strokeColor = UIColor(red: 0.91, green: 0.77, blue: 0.58, alpha: 0.95)
            plank.lineWidth = 4
            plank.position = CGPoint(x: 532 + CGFloat(index) * 151, y: 278)
            plank.yScale = 0.58
            plank.alpha = 0.48
            plank.name = "memoryBridgePlank\(index)"
            plank.zPosition = 270
            addChild(plank)

            let lip = SKShapeNode(
                rectOf: CGSize(width: 145, height: 13), cornerRadius: 3
            )
            lip.fillColor = UIColor(red: 0.19, green: 0.14, blue: 0.24, alpha: 1)
            lip.strokeColor = UIColor(red: 0.81, green: 0.66, blue: 0.43, alpha: 0.91)
            lip.lineWidth = 2
            lip.position.y = -43
            lip.name = "memoryPlankFrontEdge"
            plank.addChild(lip)

            let inset = SKShapeNode(
                rectOf: CGSize(width: 140, height: 69), cornerRadius: 9
            )
            inset.fillColor = UIColor(red: 0.25, green: 0.19, blue: 0.33, alpha: 0.32)
            inset.strokeColor = UIColor(red: 0.97, green: 0.82, blue: 0.58, alpha: 0.86)
            inset.lineWidth = 2
            inset.position.y = 6
            inset.name = "memoryPlankCarvedStone"
            plank.addChild(inset)

            for x in [CGFloat(-50), 50] {
                let bolt = SKShapeNode(circleOfRadius: 5)
                bolt.position = CGPoint(x: x, y: 3)
                bolt.fillColor = UIColor(red: 0.92, green: 0.77, blue: 0.48, alpha: 1)
                bolt.strokeColor = UIColor(red: 0.31, green: 0.22, blue: 0.25, alpha: 1)
                bolt.lineWidth = 1
                bolt.name = "memoryPlankBolt"
                plank.addChild(bolt)
            }
        }

        for x in [CGFloat(420), CGFloat(1100)] {
            let bank = SKShapeNode(
                rectOf: CGSize(width: 76, height: 131), cornerRadius: 13
            )
            bank.fillColor = UIColor(red: 0.62, green: 0.56, blue: 0.67, alpha: 0.98)
            bank.fillTexture = palaceStoneTexture
            bank.strokeColor = UIColor(red: 0.92, green: 0.76, blue: 0.48, alpha: 1)
            bank.lineWidth = 4
            bank.position = CGPoint(x: x, y: 289)
            bank.zPosition = 265
            bank.name = "memoryBridgeBank"
            addChild(bank)
        }

        for index in 0..<PuzzlePalaceEncounterCatalog.memoryBridge.count {
            let light = ArtSystem.medallion(
                radius: 13,
                fill: UIColor(red: 0.20, green: 0.14, blue: 0.32, alpha: 0.96),
                stroke: UIColor(red: 0.79, green: 0.63, blue: 0.46, alpha: 0.72)
            )
            light.position = CGPoint(x: 1010 + CGFloat(index) * 58, y: 555)
            light.name = "memoryProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }
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
        // These physical rune controls must render above the newly raised
        // 3D bridge deck and chasm. Otherwise SpriteKit hit-testing selects
        // the stone scenery and a child's input is silently ignored.
        root.zPosition = 900
        root.userData = NSMutableDictionary(dictionary: ["symbol": symbol])
        let runeName = ["★": "star", "☾": "moon", "◆": "diamond", "●": "circle"][symbol]
            ?? "symbol"
        makeAccessible(root, label: "Memory rune: \(runeName)")

        let stone = carvedPalaceStone(CGSize(width: 91, height: 89), radius: 19)
        stone.fillColor = UIColor(
            red: 0.73 + CGFloat(index) * 0.015,
            green: 0.65,
            blue: 0.79,
            alpha: 1
        )
        stone.name = "memoryPad"
        root.addChild(stone)

        let glyph = ArtSystem.label(symbol, size: 37)
        glyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.48, alpha: 1)
        glyph.name = "memoryPad"
        root.addChild(glyph)

        let foot = carvedPalaceStone(CGSize(width: 104, height: 17), radius: 5)
        foot.fillColor = UIColor(red: 0.48, green: 0.38, blue: 0.54, alpha: 1)
        foot.position.y = -55
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
            let rejectedPad = SKShapeNode(ellipseOf: CGSize(width: 98, height: 96))
            rejectedPad.name = "memoryRejectedRune"
            rejectedPad.fillColor = UIColor(red: 0.74, green: 0.18, blue: 0.16, alpha: 0.35)
            rejectedPad.strokeColor = UIColor(red: 1, green: 0.56, blue: 0.38, alpha: 1)
            rejectedPad.lineWidth = 6
            rejectedPad.zPosition = 9
            node.addChild(rejectedPad)
            rejectedPad.run(.sequence([
                .wait(forDuration: 0.65),
                .removeFromParent()
            ]), withKey: "memoryRejected")
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
        clearAttentionCue()
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
            .wait(forDuration: reducedMotion ? 0.75 : 1.15),
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
            plank.position.y = 278
            plank.yScale = 0.58
            plank.alpha = 0.48
            plank.strokeColor = UIColor(red: 0.65, green: 0.54, blue: 0.71, alpha: 0.68)
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
            plank.position.y = 292
            plank.yScale = 1
        } else {
            plank.run(.group([
                .moveTo(y: 292, duration: 0.25),
                .scaleY(to: 1, duration: 0.25)
            ]), withKey: "raiseBridgeStone")
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
            plank.position.y = 292
            plank.yScale = 1
            plank.alpha = 1
            plank.fillColor = UIColor(red: 0.75, green: 0.69, blue: 0.78, alpha: 1)
            plank.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.36, alpha: 1)
            plank.glowWidth = 8
        }

        if let chasm = childNode(withName: "memoryChasm") as? SKShapeNode {
            chasm.strokeColor = UIColor(red: 0.84, green: 0.68, blue: 0.46, alpha: 1)
            chasm.glowWidth = reducedMotion ? 0 : 2
            chasm.name = "memoryBridgeRestored"
        }
        // Long side rails make the four touching stones read as a single
        // crossing. Kept non-interactive so existing touch routing is stable.
        if childNode(withName: "memoryBridgeJoinedRail") == nil {
            let joined = SKNode()
            joined.name = "memoryBridgeJoinedRail"
            joined.zPosition = 281
            for y in [CGFloat(352), 231] {
                let rail = SKShapeNode(
                    rectOf: CGSize(width: 605, height: 10),
                    cornerRadius: 5
                )
                rail.fillColor = UIColor(red: 0.68, green: 0.48, blue: 0.27, alpha: 1)
                rail.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.46, alpha: 1)
                rail.lineWidth = 2
                rail.position = CGPoint(x: 758, y: y)
                rail.name = "memoryDeckRailing"
                joined.addChild(rail)
            }
            addChild(joined)
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
            CGSize(width: 560, height: 20),
            fill: UIColor(red: 0.38, green: 0.27, blue: 0.23, alpha: 0.83),
            stroke: UIColor(red: 0.89, green: 0.69, blue: 0.45, alpha: 0.82),
            radius: 9,
            lineWidth: 2,
            shadowAlpha: 0.18
        )
        upperRail.position = CGPoint(x: 755, y: 402)
        upperRail.name = "stopGoRail"
        upperRail.zPosition = 180
        addChild(upperRail)

        let lowerRail = ArtSystem.panel(
            CGSize(width: 560, height: 20),
            fill: UIColor(red: 0.31, green: 0.22, blue: 0.25, alpha: 0.86),
            stroke: UIColor(red: 0.76, green: 0.57, blue: 0.40, alpha: 0.78),
            radius: 9,
            lineWidth: 2,
            shadowAlpha: 0.14
        )
        lowerRail.position = CGPoint(x: 755, y: 328)
        lowerRail.zPosition = 179
        addChild(lowerRail)

        for (index, x) in [CGFloat(610), 755, 900].enumerated() {
            let brace = ArtSystem.panel(
                CGSize(width: 42, height: 68),
                fill: UIColor(red: 0.16, green: 0.12, blue: 0.28, alpha: 0.94),
                stroke: UIColor(red: 0.56, green: 0.45, blue: 0.80, alpha: 0.66),
                radius: 12,
                lineWidth: 2,
                shadowAlpha: 0.18
            )
            brace.position = CGPoint(x: x, y: 365)
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

        let halo = SKShapeNode(circleOfRadius: 85)
        halo.fillColor = UIColor(red: 0.25, green: 0.15, blue: 0.31, alpha: 0.12)
        halo.strokeColor = UIColor(red: 0.89, green: 0.68, blue: 0.48, alpha: 0.40)
        halo.lineWidth = 2
        halo.name = "stopGoOrbHalo"
        halo.zPosition = -2
        orbRoot.addChild(halo)

        // The active signal is a mounted brass-and-glass lantern mechanism,
        // not a giant purple tap button pasted on the background.
        let ring = ArtSystem.medallion(
            radius: 70,
            fill: UIColor(red: 0.37, green: 0.25, blue: 0.29, alpha: 0.92),
            stroke: UIColor(red: 0.96, green: 0.77, blue: 0.49, alpha: 0.96),
            glow: reducedMotion ? 0 : 2
        )
        ring.name = "stopGoOrb"
        orbRoot.addChild(ring)

        let core = ArtSystem.medallion(
            radius: 46,
            fill: UIColor(red: 0.63, green: 0.48, blue: 0.70, alpha: 0.95),
            stroke: UIColor(red: 1.0, green: 0.90, blue: 0.68, alpha: 0.96)
        )
        core.name = "stopGoOrbCore"
        orbRoot.addChild(core)

        // Small captive brass studs give the mechanism a raised frame, while
        // the lock bar makes HOLD vs GO a physical state even without color
        // and with accessibility Reduced Motion enabled.
        for angle in stride(from: 0, through: 300, by: 60) {
            let radians = CGFloat(angle) * .pi / 180
            let stud = SKShapeNode(circleOfRadius: 5)
            stud.position = CGPoint(x: cos(radians) * 60, y: sin(radians) * 60)
            stud.fillColor = UIColor(red: 0.96, green: 0.78, blue: 0.49, alpha: 1)
            stud.strokeColor = UIColor(red: 0.36, green: 0.25, blue: 0.24, alpha: 1)
            stud.lineWidth = 1.5
            stud.name = "decorativeStopGoStud"
            stud.zPosition = 2
            orbRoot.addChild(stud)
        }

        let glyph = ArtSystem.label("Ⅱ", size: 42)
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.58, alpha: 1)
        glyph.name = "stopGoOrbGlyph"
        glyph.zPosition = 3
        orbRoot.addChild(glyph)

        let shutter = SKShapeNode(rectOf: CGSize(width: 102, height: 13), cornerRadius: 6)
        shutter.fillColor = UIColor(red: 0.72, green: 0.48, blue: 0.29, alpha: 1)
        shutter.strokeColor = UIColor(red: 1, green: 0.86, blue: 0.58, alpha: 1)
        shutter.lineWidth = 2
        shutter.position = CGPoint(x: 0, y: -23)
        shutter.name = "decorativeStopGoShutter"
        shutter.zPosition = 4
        orbRoot.addChild(shutter)
        makeAccessible(orbRoot, label: "Brass orb signal. Wait on HOLD; tap on GO.")
        addChild(orbRoot)

        let barrier = SKShapeNode(rectOf: CGSize(width: 82, height: 204), cornerRadius: 38)
        barrier.fillColor = UIColor(red: 0.09, green: 0.065, blue: 0.18, alpha: 0.62)
        barrier.strokeColor = UIColor(red: 0.62, green: 0.50, blue: 0.88, alpha: 0.62)
        barrier.lineWidth = 4
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
            light.position = CGPoint(x: 700 + CGFloat(index) * 55, y: 552)
            light.name = "stopGoProgress\(index)"
            light.zPosition = 520
            addChild(light)
        }

        // The single lower guidance plaque provides the spoken/visual cue.
        // Avoid duplicate tiny text floating on the painted Palace floor.

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
        // A new rhythm starts with the physical latch closed, even if the
        // previous correct GO left it retracted for its success celebration.
        updateStopGoOrb(.hold)
        instruction.text = inhibitionEncounter.prompt
        showAttentionCue(
            at: CGPoint(x: 755, y: 365),
            tint: UIColor(red: 0.78, green: 0.58, blue: 0.98, alpha: 1),
            width: 175
        )
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
                ? "HOLD — wait. Keep hands off the signal."
                : "HOLD — wait for the star."
            let duration: TimeInterval
            if reducedMotion {
                // Keep the reduced-motion interaction deterministic on slower
                // simulators: HOLD still has a clear wait, but GO has a wider
                // stable tap window without changing the signal sequence.
                switch support {
                case .independent: duration = 0.75
                case .lightHint: duration = 0.90
                case .strongHint, .demonstration: duration = 1.05
                }
            } else {
                switch support {
                case .independent: duration = 0.95
                case .lightHint: duration = 1.15
                case .strongHint, .demonstration: duration = 1.35
                }
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
            instruction.text = "GO — tap the glowing star signal!"
            tiko.pose(.interact)
        }
    }

    private func updateStopGoOrb(_ signal: PuzzleGateSignal) {
        guard let root = childNode(withName: "stopGoOrb"),
              let core = root.childNode(withName: "stopGoOrbCore") as? SKShapeNode,
              let glyph = root.childNode(withName: "stopGoOrbGlyph") as? SKLabelNode,
              let halo = root.childNode(withName: "stopGoOrbHalo") as? SKShapeNode else {
            return
        }

        root.accessibilityLabel = signal == .hold
            ? "HOLD double-bar signal. Wait. The barrier is closed."
            : "GO star signal. Tap the brass orb to open the barrier."

        if let shutter = root.childNode(withName: "decorativeStopGoShutter") as? SKShapeNode {
            shutter.removeAction(forKey: "shutterSlide")
            let isHeld = signal == .hold
            let scale: CGFloat = isHeld ? 1.0 : 0.12
            let x: CGFloat = isHeld ? 0 : 53
            if reducedMotion {
                shutter.xScale = scale
                shutter.position.x = x
            } else {
                shutter.run(.group([
                    .scaleX(to: scale, duration: 0.22),
                    .moveTo(x: x, duration: 0.22)
                ]), withKey: "shutterSlide")
            }
        }
        if let barrier = childNode(withName: "stopGoBarrier") as? SKShapeNode {
            let held = signal == .hold
            barrier.strokeColor = held
                ? UIColor(red: 0.91, green: 0.54, blue: 0.65, alpha: 0.90)
                : UIColor(red: 0.66, green: 0.94, blue: 0.74, alpha: 0.95)
            // HOLD blocks the way; GO *arms* the latch, but does not open it.
            // A child must tap the star for the barrier to physically retract.
            barrier.removeAction(forKey: "stopGoBarrierRelease")
            barrier.xScale = 1
            barrier.alpha = 0.95
            barrier.fillColor = held
                ? UIColor(red: 0.35, green: 0.14, blue: 0.22, alpha: 0.91)
                : UIColor(red: 0.13, green: 0.39, blue: 0.28, alpha: 0.72)
        }

        switch signal {
        case .hold:
            core.fillColor = UIColor(red: 0.43, green: 0.19, blue: 0.31, alpha: 1)
            core.strokeColor = UIColor(red: 0.95, green: 0.65, blue: 0.73, alpha: 1)
            core.glowWidth = 3
            halo.strokeColor = UIColor(red: 0.95, green: 0.65, blue: 0.73, alpha: 0.30)
            halo.glowWidth = 0
            glyph.text = "Ⅱ"
            glyph.fontColor = UIColor(red: 1.0, green: 0.87, blue: 0.72, alpha: 1)
        case .go:
            core.fillColor = UIColor(red: 0.24, green: 0.48, blue: 0.31, alpha: 1)
            core.strokeColor = UIColor(red: 0.68, green: 1.0, blue: 0.72, alpha: 1)
            core.glowWidth = 14
            halo.strokeColor = UIColor(red: 0.68, green: 1.0, blue: 0.72, alpha: 0.62)
            halo.glowWidth = reducedMotion ? 0 : 9
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

    private func releaseStopGoBarrier() {
        guard let barrier = childNode(withName: "stopGoBarrier") as? SKShapeNode else {
            return
        }
        barrier.removeAction(forKey: "stopGoBarrierRelease")
        barrier.fillColor = UIColor(red: 0.13, green: 0.39, blue: 0.28, alpha: 0.72)
        barrier.strokeColor = UIColor(red: 0.66, green: 0.94, blue: 0.74, alpha: 0.95)
        barrier.alpha = 0.56
        if reducedMotion {
            // The physical outcome remains visible without any movement.
            barrier.xScale = 0.24
        } else {
            barrier.run(.scaleX(to: 0.24, duration: 0.28),
                        withKey: "stopGoBarrierRelease")
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
            errorFeedback()
            valkyrie.pose(.react)
            tiko.pose(.react)
            shakeStopGoOrb()
            instruction.text = support == .lightHint
                ? "That was a HOLD signal. Tiko will replay the sequence."
                : "Wait through the double-bar signals. Touch only the star."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.70 : 0.95),
                .run { [weak self] in self?.presentStopGoSignal() }
            ]), withKey: "stopGoRetry")

        case .go:
            guard stopGoAcceptingTap else { return }
            stopGoAcceptingTap = false
            removeAction(forKey: "stopGoSignal")
            selectionFeedback()
            valkyrie.pose(.interact)
            tiko.pose(.interact)
            pulseStopGoOrb()
            releaseStopGoBarrier()
            instruction.text = "The latch opened! Watch for the next signal."
            stopGoIndex += 1
            run(.sequence([
                // Let the child see the result before the next HOLD closes it.
                .wait(forDuration: reducedMotion ? 0.30 : 0.65),
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
        clearAttentionCue()
        let attemptSupport = support

        _ = state.recordPuzzle(
            inhibitionEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshStopGoProgress(animated: true)
        successFeedback(at: CGPoint(x: 755, y: 365))
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
            .wait(forDuration: reducedMotion ? 1.30 : 1.50),
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
            if let shutter = root.childNode(withName: "decorativeStopGoShutter") as? SKShapeNode {
                shutter.removeAction(forKey: "shutterSlide")
                shutter.xScale = 0.12
                shutter.position.x = 53
            }
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

    // Reuse only approved painted stone as a surface material. The actual
    // obstacle, movable tokens and assessment remain live native SpriteKit.
    private lazy var sortingMasonryTexture: SKTexture? = {
        guard let painting = ArtSystem.texture("PuzzleSortingPedestalIllustratedV2") else { return nil }
        return SKTexture(
            rect: CGRect(x: 0.05, y: 0.065, width: 0.20, height: 0.19), in: painting
        )
    }()

    private func sortingCarvedSlab(_ size: CGSize, radius: CGFloat = 14) -> SKShapeNode {
        let slab = SKShapeNode(rectOf: size, cornerRadius: radius)
        slab.fillColor = UIColor(red: 0.63, green: 0.68, blue: 0.70, alpha: 1)
        slab.fillTexture = sortingMasonryTexture
        slab.strokeColor = UIColor(red: 0.86, green: 0.75, blue: 0.49, alpha: 1)
        slab.lineWidth = 3
        return slab
    }

    private func buildSortingWorld() {
        let floor = SKShapeNode(ellipseOf: CGSize(width: 790, height: 230))
        floor.fillColor = UIColor(red: 0.09, green: 0.18, blue: 0.22, alpha: 0.035)
        floor.strokeColor = UIColor(red: 0.83, green: 0.73, blue: 0.55, alpha: 0.08)
        floor.lineWidth = 4
        floor.position = CGPoint(x: 750, y: 365)
        floor.name = "sortingFloor"
        floor.zPosition = 120
        addChild(floor)

        let runeRing = SKShapeNode(ellipseOf: CGSize(width: 650, height: 168))
        runeRing.fillColor = .clear
        runeRing.strokeColor = UIColor(red: 0.83, green: 0.73, blue: 0.55, alpha: 0.09)
        runeRing.lineWidth = 2
        runeRing.position = CGPoint(x: 750, y: 365)
        runeRing.zPosition = 121
        addChild(runeRing)

        buildSortPedestal(at: CGPoint(x: 530, y: 355), name: "sortLeftPedestal")
        buildSortPedestal(at: CGPoint(x: 970, y: 355), name: "sortRightPedestal")

        let dial = sortingCarvedSlab(CGSize(width: 186, height: 64), radius: 20)
        dial.fillColor = UIColor(red: 0.52, green: 0.64, blue: 0.67, alpha: 1)
        dial.glowWidth = reducedMotion ? 0 : 1
        dial.position = CGPoint(x: 750, y: 515)
        dial.name = "sortingRuleDial"
        dial.zPosition = 560
        addChild(dial)

        let ruleGlyph = ArtSystem.label("●  ▲", size: 28)
        ruleGlyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1)
        ruleGlyph.name = "sortingRuleGlyph"
        dial.addChild(ruleGlyph)

        let stage = sortingCarvedSlab(CGSize(width: 170, height: 32), radius: 14)
        stage.fillColor = UIColor(red: 0.46, green: 0.55, blue: 0.56, alpha: 1)
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
        // One floor-anchored receiving alcove for both sorting rooms.
        // Keep original names/coordinates so evidence and touch routing stay intact.
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 420

        let groundShadow = SKShapeNode(ellipseOf: CGSize(width: 220, height: 28))
        groundShadow.position.y = -132
        groundShadow.fillColor = UIColor(red: 0.055, green: 0.075, blue: 0.10, alpha: 0.33)
        groundShadow.strokeColor = .clear
        groundShadow.name = "decorativeSortingFootShadow"
        groundShadow.zPosition = -4
        root.addChild(groundShadow)

        let foot = sortingCarvedSlab(CGSize(width: 202, height: 30), radius: 9)
        foot.position.y = -118
        foot.name = name
        foot.zPosition = -3
        root.addChild(foot)

        let pillar = sortingCarvedSlab(CGSize(width: 142, height: 104), radius: 15)
        pillar.position.y = -64
        pillar.fillColor = UIColor(red: 0.48, green: 0.55, blue: 0.62, alpha: 1)
        pillar.name = name
        pillar.zPosition = -2
        root.addChild(pillar)

        for x in [CGFloat(-51), 51] {
            let inlay = SKShapeNode(rectOf: CGSize(width: 7, height: 75), cornerRadius: 3)
            inlay.position = CGPoint(x: x, y: -70)
            inlay.fillColor = UIColor(red: 0.80, green: 0.63, blue: 0.38, alpha: 0.68)
            inlay.strokeColor = .clear
            inlay.name = "decorativeSortingBrassInlay"
            inlay.zPosition = -1
            root.addChild(inlay)
        }

        let bowl = sortingCarvedSlab(CGSize(width: 205, height: 88), radius: 27)
        bowl.position.y = 7
        bowl.name = name
        root.addChild(bowl)

        let recess = SKShapeNode(ellipseOf: CGSize(width: 166, height: 60))
        recess.position.y = 12
        recess.fillColor = UIColor(red: 0.08, green: 0.22, blue: 0.29, alpha: 0.93)
        recess.strokeColor = UIColor(red: 0.93, green: 0.78, blue: 0.52, alpha: 0.94)
        recess.lineWidth = 3
        recess.name = name
        recess.zPosition = 1
        root.addChild(recess)

        let glyph = ArtSystem.label("◇", size: 42)
        glyph.name = name + "Glyph"
        glyph.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.64, alpha: 1)
        glyph.position.y = 15
        glyph.zPosition = 2
        root.addChild(glyph)

        let side = name.contains("Left") ? "left" : "right"
        makeAccessible(root, label: "Place the sorting stone in the \(side) alcove")
        addChild(root)
        registerInteraction(root, clearance: 12)
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
        showAttentionCue(
            at: CGPoint(x: 755, y: 225),
            tint: UIColor(red: 0.52, green: 0.88, blue: 0.90, alpha: 1),
            width: 250
        )

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
            left.accessibilityLabel = "Left alcove: round stones"
            right.accessibilityLabel = "Right alcove: pointed stones"
        case .marks:
            dialGlyph.text = "•  ••"
            leftGlyph.text = "•"
            rightGlyph.text = "••"
            left.accessibilityLabel = "Left alcove: one mark"
            right.accessibilityLabel = "Right alcove: two marks"
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

        let stone = sortingCarvedSlab(CGSize(width: 94, height: 94), radius: 22)
        stone.fillColor = UIColor(red: 0.56, green: 0.62, blue: 0.69, alpha: 1)
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

    // A wrong answer must be seen entering and being rejected by the actual
    // carved alcove, rather than only flashing a hint below the painting.
    // This is visual feedback only: assessment and retry state are unchanged.
    private func showRejectedSortingPlacement(
        token: SKNode?, pedestalName: String, destination: CGPoint
    ) {
        guard let token, let pedestal = childNode(withName: pedestalName) else { return }
        let origin = token.position
        let rejection = SKShapeNode(ellipseOf: CGSize(width: 176, height: 68))
        rejection.name = "sortingRejectedAlcove"
        rejection.position = CGPoint(x: 0, y: 12)
        rejection.fillColor = UIColor(red: 0.68, green: 0.17, blue: 0.15, alpha: 0.28)
        rejection.strokeColor = UIColor(red: 1.0, green: 0.61, blue: 0.40, alpha: 1)
        rejection.lineWidth = 6
        rejection.zPosition = 12
        pedestal.addChild(rejection)

        // Reduced Motion removes transitions, not the visible rejected state.
        let travelDuration: TimeInterval = reducedMotion ? 0 : 0.18
        token.run(.sequence([
            .move(to: destination, duration: travelDuration),
            .wait(forDuration: 0.40),
            .move(to: origin, duration: travelDuration)
        ]), withKey: "wrongAlcoveReturn")
        rejection.run(.sequence([
            .wait(forDuration: reducedMotion ? 0.50 : 0.85),
            .removeFromParent()
        ]), withKey: "wrongAlcoveFlash")
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
            showRejectedSortingPlacement(
                token: childNode(withName: "sortingObject"),
                pedestalName: bucket == .left ? "sortLeftPedestal" : "sortRightPedestal",
                destination: CGPoint(x: bucket == .left ? 530 : 970, y: 355)
            )
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
            errorFeedback()
            valkyrie.pose(.react)
            tiko.pose(.react)
            highlightSortingDimension(rule)
            instruction.text = support == .lightHint
                ? sortingHint(for: rule)
                : "Tiko is pointing to the active rule. Ignore the other feature and try again."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.62 : 0.88),
                .run { [weak self] in
                    self?.sortAcceptingInput = true
                }
            ]), withKey: "sortRetry")
            return
        }

        let destination = bucket == .left
            ? CGPoint(x: 530, y: 355)
            : CGPoint(x: 970, y: 355)
        selectionFeedback()
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
            .wait(forDuration: reducedMotion ? 0.55 : 0.75),
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
                dial?.strokeColor = UIColor(red: 0.86, green: 0.75, blue: 0.49, alpha: 1)
            }
        ]), withKey: "sortHintGlow")
    }

    private func completeSortingEncounter() {
        guard let sortEncounter else { return }
        sortAcceptingInput = false
        attempts += 1
        solved = true
        clearAttentionCue()
        let attemptSupport = support

        _ = state.recordPuzzle(
            sortEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshSortingProgress(animated: true)
        successFeedback(at: CGPoint(x: 755, y: 225))
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
            .wait(forDuration: reducedMotion ? 0.75 : 1.15),
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
        vault.fillColor = UIColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 0.035)
        vault.strokeColor = UIColor(red: 0.85, green: 0.73, blue: 0.53, alpha: 0.15)
        vault.lineWidth = 6
        vault.position = CGPoint(x: 755, y: 395)
        vault.name = "resortVault"
        vault.zPosition = 115
        addChild(vault)

        buildSortPedestal(at: CGPoint(x: 475, y: 300), name: "resortLeftPedestal")
        buildSortPedestal(at: CGPoint(x: 1035, y: 300), name: "resortRightPedestal")

        // The rule machine is floor-anchored between its two receiving alcoves.
        // It must not float over the approved painted vault door.
        for receiverX in [CGFloat(475), 1035] {
            let trackPath = CGMutablePath()
            trackPath.move(to: CGPoint(x: 755, y: 258))
            trackPath.addLine(to: CGPoint(x: (755 + receiverX) / 2, y: 240))
            trackPath.addLine(to: CGPoint(x: receiverX, y: 295))
            let track = SKShapeNode(path: trackPath)
            track.name = "decorativeResortDriveTrack"
            track.strokeColor = UIColor(red: 0.74, green: 0.60, blue: 0.42, alpha: 0.82)
            track.lineWidth = 10
            track.lineCap = .round
            track.zPosition = 365
            addChild(track)
        }
        let consoleBase = sortingCarvedSlab(CGSize(width: 236, height: 100), radius: 28)
        consoleBase.position = CGPoint(x: 755, y: 255)
        consoleBase.name = "resortRuleConsoleBase"
        consoleBase.zPosition = 405
        addChild(consoleBase)

        // Each alcove has captive sliding brass shutters. They physically
        // reconfigure when the rule changes; the symbols remain the child's
        // category guide, rather than decorative answer hints.
        for name in ["resortLeftPedestal", "resortRightPedestal"] {
            guard let pedestal = childNode(withName: name) else { continue }
            for (side, sign) in [("Left", CGFloat(-1)), ("Right", CGFloat(1))] {
                let shutter = sortingCarvedSlab(CGSize(width: 15, height: 65), radius: 6)
                shutter.fillColor = UIColor(red: 0.79, green: 0.65, blue: 0.42, alpha: 1)
                shutter.position = CGPoint(x: sign * 83, y: 12)
                shutter.name = name + "RuleGate" + side
                shutter.zPosition = 3
                pedestal.addChild(shutter)
            }
        }

        let dial = sortingCarvedSlab(CGSize(width: 186, height: 64), radius: 20)
        dial.fillColor = UIColor(red: 0.54, green: 0.62, blue: 0.69, alpha: 1)
        dial.lineWidth = 4
        dial.position = CGPoint(x: 755, y: 277)
        dial.name = "resortRuleDial"
        dial.zPosition = 580
        addChild(dial)

        let glyph = ArtSystem.label("●  ▲", size: 29)
        glyph.fontColor = UIColor(red: 1.0, green: 0.88, blue: 0.50, alpha: 1)
        glyph.name = "resortRuleGlyph"
        dial.addChild(glyph)

        let passLabel = ArtSystem.label("FIRST SORT", size: 19)
        passLabel.fontColor = UIColor(red: 0.88, green: 0.81, blue: 1.0, alpha: 1)
        passLabel.position = CGPoint(x: 755, y: 187)
        passLabel.name = "resortPassLabel"
        passLabel.zPosition = 590
        addChild(passLabel)

        let door = SKShapeNode(rectOf: CGSize(width: 105, height: 245), cornerRadius: 34)
        door.fillColor = UIColor(red: 0.15, green: 0.20, blue: 0.28, alpha: 0.14)
        door.strokeColor = UIColor(red: 0.82, green: 0.67, blue: 0.48, alpha: 0.66)
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
        showAttentionCue(
            at: CGPoint(x: 755, y: 395),
            tint: UIColor(red: 0.52, green: 0.88, blue: 0.90, alpha: 1),
            width: 280
        )
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
            left.accessibilityLabel = "Left alcove: round stones"
            right.accessibilityLabel = "Right alcove: pointed stones"
        case .marks:
            dialGlyph.text = "•  ••"
            leftGlyph.text = "•"
            rightGlyph.text = "••"
            left.accessibilityLabel = "Left alcove: one mark"
            right.accessibilityLabel = "Right alcove: two marks"
        }

        // Move the actual receiver shutters into different mechanical detents
        // on a rule switch. Reduced Motion presents the same stable states
        // instantly, never hiding the changed sorting criterion.
        let shutterOffset: CGFloat = rule == .shape ? 83 : 61
        for name in ["resortLeftPedestal", "resortRightPedestal"] {
            guard let pedestal = childNode(withName: name) else { continue }
            for (side, sign) in [("Left", CGFloat(-1)), ("Right", CGFloat(1))] {
                guard let shutter = pedestal.childNode(withName: name + "RuleGate" + side) else {
                    continue
                }
                shutter.removeAction(forKey: "resortRuleShift")
                let destination = sign * shutterOffset
                if reducedMotion {
                    shutter.position.x = destination
                } else {
                    shutter.run(.moveTo(x: destination, duration: 0.32),
                                withKey: "resortRuleShift")
                }
            }
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
            showRejectedSortingPlacement(
                token: childNode(withName: "resortToken\(resortObjectIndex)"),
                pedestalName: bucket == .left ? "resortLeftPedestal" : "resortRightPedestal",
                destination: CGPoint(x: bucket == .left ? 475 : 1035, y: 320)
            )
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
            errorFeedback()
            valkyrie.pose(.react)
            tiko.pose(.react)
            highlightResortRule(rule)
            instruction.text = support == .lightHint
                ? sortingHint(for: rule)
                : "The set stayed the same, but the RULE changed. Follow only the glowing rule."
            run(.sequence([
                .wait(forDuration: reducedMotion ? 0.62 : 0.88),
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
        selectionFeedback()
        valkyrie.pose(.interact)
        tiko.pose(.interact)
        token.run(.move(to: destination, duration: reducedMotion ? 0 : 0.24))
        token.setScale(0.72)

        resortObjectIndex += 1
        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.55 : 0.75),
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
        clearAttentionCue()
        let attemptSupport = support
        _ = state.recordPuzzle(
            resortEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        refreshResortProgress(animated: true)
        successFeedback(at: CGPoint(x: 755, y: 395))
        valkyrie.pose(.celebrate)
        tiko.pose(.celebrate)

        if state.puzzleResortComplete {
            restoreResortVault()
            return
        }

        instruction.text = attemptSupport == .independent
            ? "Same stones, new rule—both sorts held. Another vault set is waking."
            : "That re-sort is stable. Try the next vault set independently."

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.75 : 1.15),
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
                dial?.strokeColor = UIColor(red: 0.86, green: 0.75, blue: 0.49, alpha: 1)
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

        // An axle ties each choice mirror to its floor pedestal. The mirror,
        // arrow, shape, and accessible hit target remain the same live node.
        let pivotShaft = SKShapeNode(
            rectOf: CGSize(width: 18, height: 60), cornerRadius: 7
        )
        pivotShaft.position = CGPoint(x: 0, y: -108)
        pivotShaft.fillColor = UIColor(red: 0.49, green: 0.34, blue: 0.25, alpha: 1)
        pivotShaft.strokeColor = UIColor(red: 0.95, green: 0.76, blue: 0.45, alpha: 1)
        pivotShaft.lineWidth = 2
        pivotShaft.name = "decorativeMirrorPivotShaft"
        pivotShaft.zPosition = -3
        mirror.addChild(pivotShaft)

        let pivot = SKShapeNode(circleOfRadius: 11)
        pivot.position = CGPoint(x: 0, y: -85)
        pivot.fillColor = UIColor(red: 0.25, green: 0.23, blue: 0.33, alpha: 1)
        pivot.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.51, alpha: 1)
        pivot.lineWidth = 3
        pivot.name = "decorativeMirrorPivotAxle"
        mirror.addChild(pivot)

        let innerGlass = SKShapeNode(ellipseOf: CGSize(width: 116, height: 148))
        innerGlass.fillColor = UIColor(red: 0.38, green: 0.69, blue: 0.92, alpha: 0.11)
        innerGlass.strokeColor = UIColor(white: 1.0, alpha: 0.24)
        innerGlass.lineWidth = 2
        // The captive reflective pane pivots inside the stationary brass frame.
        // Keep the scored arrow/shape fixed so a tilt never gives away or
        // changes the underlying orientation/rotation answer.
        innerGlass.name = "decorativeMirrorTurningPane"
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
        showRestoredMirrorFixtures()
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

    // Restored Palace rooms retain the three actual pivot mirrors rather than
    // presenting an empty rail after the scene clears answer choices.
    private func showRestoredMirrorFixtures() {
        for (index, point) in mirrorChoicePoints.enumerated() {
            guard childNode(withName: "restoredMirrorFixture\(index)") == nil else { continue }
            let mirror = SKShapeNode(ellipseOf: CGSize(width: 142, height: 176))
            decorateMirrorGlass(mirror)
            mirror.position = point
            mirror.name = "restoredMirrorFixture\(index)"
            mirror.zPosition = 650
            mirror.strokeColor = UIColor(red: 0.58, green: 0.90, blue: 0.87, alpha: 1)
            mirror.glowWidth = reducedMotion ? 0 : 6
            mirror.isUserInteractionEnabled = false

            let star = ArtSystem.label("✦", size: 46)
            star.fontColor = UIColor(red: 0.92, green: 0.98, blue: 0.82, alpha: 1)
            star.name = "decorativeRestoredMirrorGlyph"
            mirror.addChild(star)
            addChild(mirror)
        }
        if let center = childNode(withName: "restoredMirrorFixture1") as? SKShapeNode {
            reflectChosenMirror(center, aligned: true)
        }
    }

    private func buildMirrorHallWorld() {
        // Keep the source palace artwork visible. The live objects are architectural
        // fixtures layered into the room, not a modal card floating over it.
        let floorRail = SKShapeNode(rectOf: CGSize(width: 720, height: 14), cornerRadius: 7)
        floorRail.fillColor = UIColor(red: 0.37, green: 0.26, blue: 0.25, alpha: 0.78)
        floorRail.strokeColor = UIColor(red: 0.84, green: 0.66, blue: 0.43, alpha: 0.72)
        floorRail.lineWidth = 2
        floorRail.position = CGPoint(x: 765, y: 282)
        floorRail.zPosition = 115
        floorRail.name = "mirrorHallRail"
        addChild(floorRail)

        buildMirrorHallConceptAccents()
        buildMirrorMachinery()

        // The source lens is suspended from the painted central arch,
        // replacing an oversized floating quiz disk.
        let suspension = SKShapeNode(
            rectOf: CGSize(width: 12, height: 70), cornerRadius: 6
        )
        suspension.position = CGPoint(x: 765, y: 639)
        suspension.fillColor = UIColor(red: 0.52, green: 0.37, blue: 0.29, alpha: 0.95)
        suspension.strokeColor = UIColor(red: 0.95, green: 0.77, blue: 0.48, alpha: 0.92)
        suspension.lineWidth = 2
        suspension.zPosition = 592
        suspension.name = "mirrorBeaconMount"
        addChild(suspension)

        let beacon = SKShapeNode(circleOfRadius: 38)
        beacon.fillColor = UIColor(red: 0.31, green: 0.25, blue: 0.30, alpha: 0.98)
        beacon.strokeColor = UIColor(red: 0.94, green: 0.74, blue: 0.47, alpha: 1)
        beacon.lineWidth = 5
        beacon.position = CGPoint(x: 765, y: 565)
        beacon.name = "mirrorBeacon"
        beacon.zPosition = 600
        addChild(beacon)

        let glass = SKShapeNode(circleOfRadius: 27)
        glass.fillColor = UIColor(red: 0.31, green: 0.53, blue: 0.70, alpha: 0.88)
        glass.strokeColor = UIColor(red: 0.73, green: 0.86, blue: 1, alpha: 0.95)
        glass.lineWidth = 2
        glass.name = "decorativeMirrorSourceLens"
        beacon.addChild(glass)

        let glyph = ArtSystem.label("↑", size: 38)
        glyph.name = "mirrorBeaconGlyph"
        glyph.fontColor = UIColor(red: 0.98, green: 0.96, blue: 0.78, alpha: 1)
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
            focusPool.fillColor = UIColor(red: 0.31, green: 0.24, blue: 0.27, alpha: 0.18)
            focusPool.strokeColor = UIColor(red: 0.84, green: 0.69, blue: 0.48, alpha: 0.28)
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
        showAttentionCue(
            at: CGPoint(x: 765, y: 390),
            tint: UIColor(red: 0.58, green: 0.86, blue: 1.0, alpha: 1),
            width: 300
        )
        tiko.pose(.interact)
    }

    private func resetRejectedMirrorFeedback(except selected: SKShapeNode) {
        // A retry should not leave an unrelated mirror marked red after the
        // child repairs the light route. The glass and stationary frame reset,
        // but the previously recorded incorrect/assisted evidence does not.
        for node in children {
            guard node !== selected,
                  let mirror = node as? SKShapeNode,
                  mirror.name == "mirrorOrientationChoice" || mirror.name == "mirrorRotationChoice" else {
                continue
            }
            mirror.strokeColor = UIColor(red: 0.92, green: 0.70, blue: 0.30, alpha: 0.90)
            mirror.glowWidth = 0
            guard let pane = mirror.childNode(withName: "decorativeMirrorTurningPane") as? SKShapeNode else {
                continue
            }
            pane.removeAction(forKey: "mirrorPanePivot")
            pane.strokeColor = UIColor(white: 1.0, alpha: 0.24)
            if reducedMotion {
                pane.xScale = 1
                pane.zRotation = 0
            } else {
                pane.run(.group([
                    .scaleX(to: 1, duration: 0.22),
                    .rotate(toAngle: 0, duration: 0.22)
                ]), withKey: "mirrorPanePivot")
            }
        }
    }

    private func reflectChosenMirror(_ mirror: SKShapeNode, aligned: Bool) {
        // Move only the captive glass: the outer fixture, scored direction,
        // accessible hit frame and character path remain anchored.
        if let pane = mirror.childNode(withName: "decorativeMirrorTurningPane") as? SKShapeNode {
            pane.removeAction(forKey: "mirrorPanePivot")
            pane.strokeColor = aligned
                ? UIColor(red: 0.45, green: 0.94, blue: 0.83, alpha: 1)
                : UIColor(red: 1.0, green: 0.58, blue: 0.44, alpha: 1)
            let tilt: CGFloat = aligned ? -.pi / 18 : .pi / 10
            let facing: CGFloat = aligned ? 0.92 : 0.62
            if reducedMotion {
                pane.xScale = facing
                pane.zRotation = tilt
            } else {
                pane.run(.group([
                    .scaleX(to: facing, duration: 0.22),
                    .rotate(toAngle: tilt, duration: 0.22)
                ]), withKey: "mirrorPanePivot")
            }
        }
        // A reflection appears only AFTER the child's answer is scored.
        // No ray reveals which mirror matches the target in advance.
        childNode(withName: "mirrorActiveRay")?.removeFromParent()
        childNode(withName: "mirrorActiveImpact")?.removeFromParent()

        let impactPoint = aligned
            ? CGPoint(x: mirror.position.x, y: 252)
            : CGPoint(
                x: mirror.position.x + (mirror.position.x < 765 ? -75 : 75),
                y: 306
            )
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 765, y: 528))
        path.addLine(to: CGPoint(x: mirror.position.x, y: mirror.position.y + 77))
        path.addLine(to: impactPoint)

        let reflectedRay = SKShapeNode(path: path)
        reflectedRay.name = "mirrorActiveRay"
        reflectedRay.strokeColor = aligned
            ? UIColor(red: 0.78, green: 0.94, blue: 1, alpha: 1)
            : UIColor(red: 0.94, green: 0.57, blue: 0.40, alpha: 1)
        reflectedRay.lineWidth = 8
        reflectedRay.glowWidth = reducedMotion ? 0 : 4
        reflectedRay.zPosition = 638
        reflectedRay.alpha = reducedMotion ? 1 : 0
        addChild(reflectedRay)

        let impact = SKShapeNode(circleOfRadius: aligned ? 17 : 11)
        impact.name = "mirrorActiveImpact"
        impact.position = impactPoint
        impact.fillColor = aligned
            ? UIColor(red: 0.32, green: 0.82, blue: 0.78, alpha: 1)
            : UIColor(red: 0.78, green: 0.34, blue: 0.30, alpha: 1)
        impact.strokeColor = UIColor(red: 0.97, green: 0.83, blue: 0.55, alpha: 1)
        impact.lineWidth = 3
        impact.zPosition = 639
        impact.alpha = reducedMotion ? 1 : 0
        addChild(impact)

        if !reducedMotion {
            reflectedRay.run(.fadeIn(withDuration: 0.22))
            impact.run(.fadeIn(withDuration: 0.22))
        }
        if aligned,
           let index = mirrorChoicePoints.firstIndex(where: {
               abs($0.x - mirror.position.x) < 1
           }),
           let receiver = childNode(withName: "mirrorReceiver\(index)") as? SKShapeNode {
            receiver.fillColor = UIColor(red: 0.32, green: 0.82, blue: 0.78, alpha: 1)
            receiver.glowWidth = reducedMotion ? 0 : 9
        }
    }

    private func clearMirrorChoices() {
        childNode(withName: "mirrorActiveRay")?.removeFromParent()
        childNode(withName: "mirrorActiveImpact")?.removeFromParent()
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
            reflectChosenMirror(node, aligned: false)
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

        clearAttentionCue()
        _ = state.recordPuzzle(
            orientationEncounter,
            outcome: .correct,
            support: attemptSupport,
            attempts: attempts,
            responseTime: Date().timeIntervalSince(startedAt)
        )
        resetRejectedMirrorFeedback(except: node)
        reflectChosenMirror(node, aligned: true)
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
            focusPool.fillColor = UIColor(red: 0.31, green: 0.24, blue: 0.27, alpha: 0.18)
            focusPool.strokeColor = UIColor(red: 0.84, green: 0.69, blue: 0.48, alpha: 0.28)
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
        showAttentionCue(
            at: CGPoint(x: 765, y: 390),
            tint: UIColor(red: 0.58, green: 0.86, blue: 1.0, alpha: 1),
            width: 300
        )
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
            reflectChosenMirror(node, aligned: false)
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
        clearAttentionCue()
        resetRejectedMirrorFeedback(except: node)
        node.strokeColor = .systemGreen
        node.glowWidth = 16
        refreshMirrorRotationProgress()
        // Restoration updates all receiver lamps. Apply the current successful
        // reflection *afterwards*, including for a correct hinted attempt.
        reflectChosenMirror(node, aligned: true)
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
        // The map is now an in-world stone crossing on the floor rather than
        // a blue classroom grid hanging over a painted palace wall.
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 500, height: 296))
        shadow.fillColor = UIColor(red: 0.07, green: 0.055, blue: 0.13, alpha: 0.27)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 760, y: 288)
        shadow.zPosition = 96
        shadow.name = "pathFloorShadow"
        addChild(shadow)

        let chamber = SKShapeNode(ellipseOf: CGSize(width: 448, height: 278))
        chamber.fillColor = UIColor(red: 0.20, green: 0.17, blue: 0.27, alpha: 0.38)
        chamber.strokeColor = UIColor(red: 0.76, green: 0.59, blue: 0.39, alpha: 0.68)
        chamber.lineWidth = 4
        chamber.position = CGPoint(x: 760, y: 295)
        chamber.name = "pathTilesChamber"
        chamber.zPosition = 100
        addChild(chamber)

        let stoneRim = SKShapeNode(ellipseOf: CGSize(width: 412, height: 246))
        stoneRim.fillColor = .clear
        stoneRim.strokeColor = UIColor(red: 0.97, green: 0.81, blue: 0.55, alpha: 0.25)
        stoneRim.lineWidth = 3
        stoneRim.position = CGPoint(x: 760, y: 298)
        stoneRim.name = "pathFloorStoneRim"
        stoneRim.zPosition = 105
        addChild(stoneRim)

        let title = ArtSystem.label("HELP TIKO CROSS", size: 20)
        title.fontColor = UIColor(red: 1, green: 0.91, blue: 0.72, alpha: 0.96)
        title.name = "pathTilesTitle"
        title.position = CGPoint(x: 760, y: 504)
        title.zPosition = 800
        addChild(title)

        // Carved progress studs are mounted beside the real floor crossing.
        for index in 0..<PuzzlePalaceEncounterCatalog.pathTileFamilies.count {
            let stud = SKShapeNode(circleOfRadius: 12)
            stud.fillColor = UIColor(red: 0.29, green: 0.21, blue: 0.23, alpha: 1)
            stud.strokeColor = UIColor(red: 0.91, green: 0.74, blue: 0.47, alpha: 0.95)
            stud.lineWidth = 3
            stud.position = CGPoint(x: 690 + CGFloat(index) * 70, y: 475)
            stud.name = "pathProgress\(index)"
            stud.zPosition = 820
            addChild(stud)
        }

        let routeHeader = ArtSystem.label("PICK A STONE TRAIL", size: 16)
        routeHeader.fontColor = UIColor(red: 1, green: 0.88, blue: 0.60, alpha: 0.97)
        routeHeader.position = CGPoint(x: 1090, y: 393)
        routeHeader.zPosition = 820
        routeHeader.name = "pathTrailHeader"
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

        let shadow = SKShapeNode(ellipseOf: CGSize(width: 293, height: 26))
        shadow.position.y = -31
        shadow.fillColor = UIColor(red: 0.08, green: 0.05, blue: 0.11, alpha: 0.29)
        shadow.strokeColor = .clear
        shadow.zPosition = -2
        shadow.name = name
        root.addChild(shadow)

        // Each route is a linked collection of sculpted stone pieces on a low
        // workbench, not an A/B/C answer button in a translucent rectangle.
        let bench = SKShapeNode(
            rectOf: CGSize(width: 286, height: 70), cornerRadius: 16
        )
        bench.fillColor = UIColor(red: 0.42, green: 0.32, blue: 0.33, alpha: 0.96)
        bench.strokeColor = UIColor(red: 0.92, green: 0.72, blue: 0.43, alpha: 1)
        bench.lineWidth = 3
        bench.name = name
        root.addChild(bench)

        let inset = SKShapeNode(
            rectOf: CGSize(width: 270, height: 55), cornerRadius: 11
        )
        inset.fillColor = UIColor(red: 0.21, green: 0.17, blue: 0.26, alpha: 0.95)
        inset.strokeColor = UIColor(red: 0.60, green: 0.49, blue: 0.42, alpha: 0.85)
        inset.lineWidth = 2
        inset.name = name
        bench.addChild(inset)

        let crest = ArtSystem.label(["✦", "◆", "◈"][index], size: 20)
        crest.fontColor = UIColor(red: 1, green: 0.85, blue: 0.55, alpha: 1)
        crest.position = CGPoint(x: -125, y: 0)
        crest.name = name
        root.addChild(crest)

        let spacing: CGFloat = directions.count > 5 ? 34 : 39
        let startX = -CGFloat(directions.count - 1) * spacing / 2 + 13
        for (step, direction) in directions.enumerated() {
            let slate = SKShapeNode(
                rectOf: CGSize(width: 31, height: 38), cornerRadius: 7
            )
            slate.position = CGPoint(x: startX + CGFloat(step) * spacing, y: 0)
            slate.fillColor = UIColor(red: 0.51, green: 0.43, blue: 0.52, alpha: 1)
            slate.strokeColor = UIColor(red: 0.91, green: 0.75, blue: 0.51, alpha: 0.98)
            slate.lineWidth = 2
            slate.name = name
            root.addChild(slate)

            let engravedArrow = ArtSystem.label(direction.glyph, size: 20)
            engravedArrow.fontColor = UIColor(red: 0.13, green: 0.10, blue: 0.19, alpha: 1)
            engravedArrow.name = name
            slate.addChild(engravedArrow)
        }

        makeAccessible(root, label: "Route option \(index + 1): try stone trail")
        addChild(root)
        registerInteraction(root, clearance: 16)
        return root
    }

    private func clearPathTilesChoices(preserveGrid: Bool = false) {
        for index in 0..<3 {
            childNode(withName: "pathChoice\(index)")?.removeFromParent()
        }
        if !preserveGrid {
            childNode(withName: "pathGrid")?.removeFromParent()
        }
    }

    private func buildPathTilesEncounter(resetSupport: Bool = true) {
        guard let pathEncounter else { return }
        clearPathTilesChoices()
        attempts = 0
        if resetSupport { support = .independent }
        startedAt = Date()
        solved = false

        // Tiko ends a successful route on top of the map. Return the
        // companion to the walkable lane before a new map becomes tappable,
        // otherwise he obscures the next challenge's actual tiles.
        let companionStart = CGPoint(x: 305, y: 190)
        // A failed safe-prefix scout can stop on the lower row (inside the
        // actor-lane Y range) but still be over the stone puzzle. Return Tiko
        // whenever he left his companion station, not only above the lane.
        if tiko.position.y > walkable.maxY || tiko.position.x > 420 {
            pathAcceptingInput = false
            if reducedMotion {
                tiko.position = companionStart
                pathAcceptingInput = true
            } else {
                tiko.run(.sequence([
                    .fadeOut(withDuration: 0.12),
                    .run { [weak self] in
                        guard let self else { return }
                        self.tiko.position = companionStart
                        // The new map is safe to tap as soon as Tiko has left
                        // the floor stones. Do not reject a fast child's next
                        // choice while an unrelated fade-in finishes.
                        self.pathAcceptingInput = true
                    },
                    .fadeIn(withDuration: 0.12)
                ]), withKey: "pathCompanionReset")
            }
        } else {
            pathAcceptingInput = true
        }

        let grid = SKNode()
        grid.name = "pathGrid"
        grid.position = CGPoint(x: 760, y: 294)
        grid.zPosition = 500
        addChild(grid)

        let tileSize: CGFloat = 66
        let originX = -CGFloat(pathEncounter.gridWidth - 1) * tileSize / 2
        let originY = -CGFloat(pathEncounter.gridHeight - 1) * tileSize / 2

        for y in 0..<pathEncounter.gridHeight {
            for x in 0..<pathEncounter.gridWidth {
                let tile = PuzzleTile(x: x, y: y)
                let square = SKShapeNode(
                    rectOf: CGSize(width: 58, height: 58),
                    cornerRadius: 12
                )
                square.position = CGPoint(
                    x: originX + CGFloat(x) * tileSize,
                    y: originY + CGFloat(y) * tileSize
                )
                square.name = "pathStone\(x)_\(y)"
                square.lineWidth = 3
                square.strokeColor = UIColor(red: 0.85, green: 0.69, blue: 0.48, alpha: 0.91)
                square.fillColor = UIColor(red: 0.45, green: 0.38, blue: 0.49, alpha: 1)

                let bevel = SKShapeNode(
                    rectOf: CGSize(width: 49, height: 46),
                    cornerRadius: 9
                )
                bevel.position.y = 3
                bevel.name = "pathStoneBevel"
                bevel.fillColor = UIColor(red: 0.53, green: 0.46, blue: 0.57, alpha: 1)
                bevel.strokeColor = UIColor(red: 0.76, green: 0.64, blue: 0.57, alpha: 0.83)
                bevel.lineWidth = 2
                square.addChild(bevel)

                if pathEncounter.blocked.contains(tile) {
                    square.fillColor = UIColor(red: 0.14, green: 0.12, blue: 0.17, alpha: 1)
                    bevel.fillColor = UIColor(red: 0.19, green: 0.14, blue: 0.23, alpha: 1)
                    let crack = CGMutablePath()
                    crack.move(to: CGPoint(x: -18, y: 19))
                    crack.addLine(to: CGPoint(x: -4, y: 4))
                    crack.addLine(to: CGPoint(x: 7, y: 11))
                    crack.addLine(to: CGPoint(x: 18, y: -18))
                    let brokenStone = SKShapeNode(path: crack)
                    brokenStone.strokeColor = UIColor(red: 0.83, green: 0.53, blue: 0.43, alpha: 0.96)
                    brokenStone.lineWidth = 4
                    brokenStone.name = "pathBrokenStone"
                    square.addChild(brokenStone)
                } else if tile == pathEncounter.start {
                    square.strokeColor = UIColor(red: 0.88, green: 0.78, blue: 0.58, alpha: 1)
                    let symbol = ArtSystem.label("◉", size: 27)
                    symbol.fontColor = UIColor(red: 0.98, green: 0.92, blue: 0.71, alpha: 1)
                    symbol.name = "pathStartingStone"
                    square.addChild(symbol)
                } else if tile == pathEncounter.goal {
                    square.strokeColor = UIColor(red: 1, green: 0.83, blue: 0.49, alpha: 1)
                    let symbol = ArtSystem.label("★", size: 31)
                    symbol.fontColor = UIColor(red: 1, green: 0.88, blue: 0.57, alpha: 1)
                    symbol.name = "pathDestinationStone"
                    square.addChild(symbol)
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

        instruction.text = "Choose a safe stone trail. Watch Tiko cross."
        showAttentionCue(
            at: CGPoint(x: 760, y: 294),
            tint: UIColor(red: 0.95, green: 0.76, blue: 0.48, alpha: 1),
            width: 320
        )
        tiko.pose(.interact)
    }

    private func revealAttemptedStoneTrail(
        _ route: [PuzzleTile],
        encounter: PuzzlePathEncounter,
        valid: Bool
    ) {
        guard let grid = childNode(withName: "pathGrid") else { return }
        grid.childNode(withName: "pathRouteTrace")?.removeFromParent()

        // Light travels between the actual floor stones. Raising each safe
        // stone's bevel makes the chosen route legible as a physical walkway,
        // including with Reduced Motion and without relying on glow effects.
        let tracedPath = CGMutablePath()
        var hasTrace = false
        for tile in route {
            guard encounter.isInBounds(tile),
                  let stone = grid.childNode(withName: "pathStone\(tile.x)_\(tile.y)") as? SKShapeNode
            else { break }
            if hasTrace {
                tracedPath.addLine(to: stone.position)
            } else {
                tracedPath.move(to: stone.position)
                hasTrace = true
            }

            let broken = encounter.blocked.contains(tile)
            stone.strokeColor = broken
                ? UIColor(red: 0.99, green: 0.51, blue: 0.40, alpha: 1)
                : UIColor(red: 1, green: 0.86, blue: 0.50, alpha: 1)
            stone.glowWidth = !broken && !reducedMotion ? 5 : 0
            if let bevel = stone.childNode(withName: "pathStoneBevel") as? SKShapeNode {
                bevel.position.y = broken ? -5 : 9
                bevel.fillColor = broken
                    ? UIColor(red: 0.31, green: 0.17, blue: 0.19, alpha: 1)
                    : UIColor(red: 0.78, green: 0.67, blue: 0.49, alpha: 1)
            }
            if broken { break }
        }

        guard hasTrace else { return }
        let trace = SKShapeNode(path: tracedPath)
        trace.name = "pathRouteTrace"
        trace.lineWidth = 10
        trace.strokeColor = valid
            ? UIColor(red: 1.0, green: 0.81, blue: 0.45, alpha: 1)
            : UIColor(red: 0.92, green: 0.46, blue: 0.38, alpha: 1)
        trace.glowWidth = valid && !reducedMotion ? 5 : 0
        // Keep the trace between the slabs, below the engraved start/goal symbols.
        trace.zPosition = -1
        grid.addChild(trace)
    }

    private func animateStoppedPathScout(
        along safeTiles: [PuzzleTile],
        encounter: PuzzlePathEncounter,
        hint: String,
        completion: @escaping () -> Void
    ) {
        let tileSize: CGFloat = 66
        let originX = 760 - CGFloat(encounter.gridWidth - 1) * tileSize / 2
        let originY = 294 - CGFloat(encounter.gridHeight - 1) * tileSize / 2
        // Walk only the unique, in-bounds, unbroken prefix. Tiko cannot
        // advance onto a wrong route's cracked stone or step off the board.
        let steps: [SKAction] = safeTiles.enumerated().map { index, tile in
            .move(
                to: CGPoint(x: originX + CGFloat(tile.x) * tileSize,
                            y: originY + CGFloat(tile.y) * tileSize),
                duration: reducedMotion ? 0 : (index == 0 ? 0.23 : 0.18)
            )
        }
        tiko.removeAction(forKey: "pathFailedScout")
        tiko.run(.sequence(steps + [
            .run { [weak self] in
                guard let self else { return }
                self.tiko.pose(.react)
                self.instruction.text = hint
                if let grid = self.childNode(withName: "pathGrid"),
                   let lastSafe = safeTiles.last {
                    grid.childNode(withName: "pathSafeStopMarker")?.removeFromParent()
                    let marker = SKShapeNode(circleOfRadius: 19)
                    marker.name = "pathSafeStopMarker"
                    marker.fillColor = UIColor(red: 0.40, green: 0.24, blue: 0.18, alpha: 1)
                    marker.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.52, alpha: 1)
                    marker.lineWidth = 4
                    marker.position = CGPoint(
                        x: originX + CGFloat(lastSafe.x) * tileSize - grid.position.x,
                        y: originY + CGFloat(lastSafe.y) * tileSize - grid.position.y + 32
                    )
                    marker.zPosition = 22
                    let stopGlyph = ArtSystem.label("Ⅱ", size: 22)
                    stopGlyph.name = "pathSafeStopGlyph"
                    stopGlyph.fontColor = UIColor(red: 1, green: 0.92, blue: 0.67, alpha: 1)
                    marker.addChild(stopGlyph)
                    grid.addChild(marker)
                }
            },
            // The failed plan stays visible long enough to understand before
            // the new map replaces it; neither mode grants success evidence.
            .wait(forDuration: reducedMotion ? 0.72 : 0.88),
            .run(completion)
        ]), withKey: "pathFailedScout")
    }

    private func resolvePathChoice(_ index: Int) {
        guard place == .pathTiles, pathAcceptingInput, let activeEncounter = pathEncounter,
              activeEncounter.choices.indices.contains(index) else { return }
        pathAcceptingInput = false
        attempts += 1
        let attemptSupport = support
        let correct = activeEncounter.isValidChoice(index)
        let attemptedRoute = activeEncounter.route(for: index)
        revealAttemptedStoneTrail(attemptedRoute, encounter: activeEncounter, valid: correct)

        _ = state.recordPuzzle(activeEncounter, outcome: correct ? .correct : .incorrect,
                               support: attemptSupport, attempts: attempts,
                               responseTime: Date().timeIntervalSince(startedAt))

        guard correct else {
            support = support == .independent ? .lightHint : .strongHint
            let safeTiles = activeEncounter.traversablePrefix(for: index)
            let firstUnsafe = attemptedRoute.dropFirst(safeTiles.count).first
            let hint: String
            if let firstUnsafe, activeEncounter.blocked.contains(firstUnsafe) {
                hint = support == .lightHint
                    ? "Tiko stopped before a cracked stone. Find another path."
                    : "Follow each step from the round stone. Keep clear of cracked stones."
            } else if let firstUnsafe, !activeEncounter.isInBounds(firstUnsafe) {
                hint = "That trail leaves the floor. Find a path that stays on the stones."
            } else if firstUnsafe != nil {
                hint = "That trail doubles back. Try a route with no repeated stones."
            } else {
                hint = "Tiko stopped short of the star. Find a trail that reaches the goal."
            }
            valkyrie.pose(.react)
            // Wait for Tiko's physical stop and the visible stop marker
            // before showing another map. Wrong attempts remain incorrect,
            // and the next attempt remains assisted.
            pathEncounter = state.nextPuzzlePathTilesEncounter()
            animateStoppedPathScout(along: safeTiles, encounter: activeEncounter, hint: hint) { [weak self] in
                self?.buildPathTilesEncounter(resetSupport: false)
            }
            return
        }

        solved = true

        clearAttentionCue()
        let route = activeEncounter.route(for: index)
        animateTikoAlongPath(route, encounter: activeEncounter)
        refreshPathTilesProgress(animated: true)
    }

    private func animateTikoAlongPath(_ route: [PuzzleTile], encounter: PuzzlePathEncounter) {
        let tileSize: CGFloat = 66
        let originX = 760 - CGFloat(encounter.gridWidth - 1) * tileSize / 2
        let originY = 294 - CGFloat(encounter.gridHeight - 1) * tileSize / 2
        // Start on the first stone rather than gliding straight from Tiko's
        // side lane to the second tile, then cross every chosen step.
        let actions: [SKAction] = route.enumerated().map { index, tile in
            .move(to: CGPoint(x: originX + CGFloat(tile.x) * tileSize,
                              y: originY + CGFloat(tile.y) * tileSize),
                  duration: reducedMotion ? 0 : (index == 0 ? 0.28 : 0.18))
        }
        tiko.run(.sequence(actions + [
            .run { [weak self] in
                guard let self else { return }
                self.successFeedback()
                self.focusMoment(on: CGPoint(x: 760, y: 294))
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

    // Recover the last independently solved route from saved learning evidence.
    // This is presentation-only; it records no additional mastery.
    private func restoreCompletedPathTiles() {
        let completed = state.profile.progress(for: PuzzleSkills.pathPlanning).evidence
            .last(where: { $0.outcome == .correct && $0.supportLevel == .independent })
        let authoredRoutes = PuzzlePalaceEncounterCatalog.pathTileFamilies.flatMap { $0 }
        guard let showcase = authoredRoutes.first(where: { $0.id == completed?.encounterID })
                ?? authoredRoutes.first else {
            finishPathTiles()
            return
        }

        pathEncounter = showcase
        buildPathTilesEncounter()
        if let safe = showcase.choices.indices.first(where: { showcase.isValidChoice($0) }) {
            revealAttemptedStoneTrail(showcase.route(for: safe),
                                     encounter: showcase, valid: true)
        }
        solved = true
        finishPathTiles()
    }

    private func finishPathTiles() {
        pathAcceptingInput = false
        clearAttentionCue()
        // A completed route remains physically visible on revisits.
        clearPathTilesChoices(preserveGrid: true)
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
            let socket = palaceCog(
                radius: 53, teeth: 12,
                fill: UIColor(red: 0.37, green: 0.27, blue: 0.25, alpha: 1),
                stroke: UIColor(red: 0.91, green: 0.71, blue: 0.42, alpha: 1)
            )
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
        if let driveRail = childNode(withName: "commandRail") as? SKShapeNode {
            driveRail.fillColor = UIColor(red: 0.42, green: 0.31, blue: 0.18, alpha: 0.96)
            driveRail.strokeColor = UIColor(red: 0.88, green: 0.69, blue: 0.34, alpha: 0.88)
        }
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
        showAttentionCue(
            at: CGPoint(x: 760, y: 330),
            tint: UIColor(red: 0.96, green: 0.72, blue: 0.34, alpha: 1),
            width: 330
        )
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
            let bearing = SKShapeNode(circleOfRadius: 34)
            bearing.fillColor = UIColor(red: 0.13, green: 0.11, blue: 0.20, alpha: 0.96)
            bearing.strokeColor = UIColor(red: 0.76, green: 0.59, blue: 0.39, alpha: 0.88)
            bearing.lineWidth = 3
            bearing.name = socket.name
            socket.addChild(bearing)
            if commandSteps.indices.contains(index) {
                let step = commandSteps[index]
                socket.fillColor = UIColor(red: 0.18, green: 0.34, blue: 0.42, alpha: 1)
                socket.strokeColor = UIColor(red: 0.82, green: 0.68, blue: 0.36, alpha: 1)
                let glyph = ArtSystem.label(step.glyph, size: 30)
                glyph.name = socket.name
                socket.addChild(glyph)
                let tiny = ArtSystem.label(step.title, size: 14)
                tiny.position.y = -63
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
            instruction.text = "Place three gears, then pull RUN."
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
                self.clearAttentionCue()
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
                    .wait(forDuration: self.reducedMotion ? 0.60 : 0.85),
                    .run { [weak self] in self?.buildCommandGearsEncounter(resetSupport: false) }
                ]))
            }
        }
    }

    private func animateCommandExecution(correct: Bool, completion: @escaping () -> Void) {
        let sockets = (0..<3).compactMap { childNode(withName: "commandSocket\($0)") as? SKShapeNode }
        // A stalled chain must be recognizable even without animation.
        if let driveRail = childNode(withName: "commandRail") as? SKShapeNode {
            driveRail.fillColor = correct
                ? UIColor(red: 0.17, green: 0.43, blue: 0.31, alpha: 1)
                : UIColor(red: 0.51, green: 0.18, blue: 0.17, alpha: 1)
            driveRail.strokeColor = correct
                ? UIColor(red: 0.70, green: 0.99, blue: 0.72, alpha: 1)
                : UIColor(red: 1.0, green: 0.55, blue: 0.35, alpha: 1)
        }
        if reducedMotion {
            sockets.forEach { socket in
                socket.strokeColor = correct ? .systemGreen : .systemRed
                socket.glowWidth = 0
            }
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
            // Each command is a bolted machine cassette seated in the
            // clockwork rail, not a floating dark quiz card.
            let plate = ArtSystem.panel(
                CGSize(width: 154, height: 120),
                fill: UIColor(red: 0.30, green: 0.23, blue: 0.26, alpha: 0.98),
                stroke: UIColor(red: 0.92, green: 0.74, blue: 0.45, alpha: 0.98),
                radius: 15,
                lineWidth: 4,
                shadowAlpha: 0.26,
                innerHighlight: UIColor(red: 0.91, green: 0.77, blue: 0.51, alpha: 0.10)
            )
            plate.position = CGPoint(x: xs[index], y: 355)
            plate.name = "bugStep\(index)"
            plate.zPosition = 850
            plate.userData = NSMutableDictionary(dictionary: ["stepIndex": index])

            for x in [CGFloat(-61), 61] {
                let fastener = SKShapeNode(circleOfRadius: 5)
                fastener.position = CGPoint(x: x, y: -50)
                fastener.fillColor = UIColor(red: 0.96, green: 0.77, blue: 0.48, alpha: 1)
                fastener.strokeColor = UIColor(red: 0.25, green: 0.19, blue: 0.19, alpha: 1)
                fastener.lineWidth = 1.5
                fastener.name = "decorativeBugCassetteBolt"
                plate.addChild(fastener)
            }

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
        showAttentionCue(
            at: CGPoint(x: 760, y: 355),
            tint: UIColor(red: 0.82, green: 0.60, blue: 0.98, alpha: 1),
            width: 360
        )
        tiko.pose(.interact)
    }

    private func markBugMachineInspection(step index: Int, confirmedBreak: Bool) {
        // Show which physical cassette Tiko is inspecting. This runs only
        // AFTER a child makes a choice, so diagnosis is never leaked beforehand.
        // The selected cassette either sinks into a jammed rail or lifts back
        // out for another look; the lamp changes even in Reduced Motion.
        for step in 0..<3 {
            if let socket = childNode(withName: "bugStepSocket\(step)") as? SKShapeNode {
                let visited = step <= index
                socket.strokeColor = visited
                    ? UIColor(red: 0.95, green: 0.75, blue: 0.44, alpha: 1)
                    : UIColor(red: 0.48, green: 0.42, blue: 0.53, alpha: 0.6)
            }
            if step < 2 {
                childNode(withName: "bugFlowArrow\(step)")?.alpha = step < index ? 1 : 0.35
            }
        }

        if let cassette = childNode(withName: "bugStep\(index)") {
            cassette.removeAction(forKey: "bugCassetteInspection")
            let destination: CGFloat = confirmedBreak ? 341 : 367
            if reducedMotion {
                cassette.position.y = destination
            } else {
                cassette.run(.moveTo(y: destination, duration: 0.18),
                             withKey: "bugCassetteInspection")
            }
        }
        if let core = childNode(withName: "//bugLanternCore") as? SKShapeNode {
            core.fillColor = confirmedBreak
                ? UIColor(red: 0.70, green: 0.29, blue: 0.23, alpha: 1)
                : UIColor(red: 0.39, green: 0.24, blue: 0.29, alpha: 1)
            core.glowWidth = confirmedBreak && !reducedMotion ? 5 : 0
        }
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
        markBugMachineInspection(step: index, confirmedBreak: correct)

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
                .wait(forDuration: reducedMotion ? 0.60 : 0.85),
                .run { [weak self] in self?.buildBugLanternEncounter(resetSupport: false) }
            ]))
            return
        }

        bugIdentifiedIndex = index
        node.strokeColor = .systemRed
        node.glowWidth = 13
        selectionFeedback()
        instruction.text = "Watch Tiko try the plan. Find where it jams."
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
        // Installing the replacement restores the cassette to its original
        // rail height after the jammed component has visibly sunk.
        let targetPosition = CGPoint(x: brokenPlate.position.x, y: 355)
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

            self.clearAttentionCue()
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

    private lazy var repairWorkshopStoneTexture: SKTexture? = {
        // Stone tones are derived from this room's *already approved*
        // illustration; nothing is replaced, upscaled or baked into scenery.
        guard let art = ArtSystem.texture("PuzzleBugLanternRepairIllustratedV2") else {
            return nil
        }
        return SKTexture(
            rect: CGRect(x: 0.17, y: 0.10, width: 0.13, height: 0.15), in: art
        )
    }()

    private func repairCarvedOutline(width: CGFloat, height: CGFloat) -> CGPath {
        let halfWidth = width / 2
        let halfHeight = height / 2
        let cut: CGFloat = min(14, min(halfWidth, halfHeight) * 0.35)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -halfWidth + cut, y: halfHeight))
        path.addLine(to: CGPoint(x: halfWidth - cut, y: halfHeight))
        path.addLine(to: CGPoint(x: halfWidth, y: halfHeight - cut))
        path.addLine(to: CGPoint(x: halfWidth, y: -halfHeight + cut))
        path.addLine(to: CGPoint(x: halfWidth - cut, y: -halfHeight))
        path.addLine(to: CGPoint(x: -halfWidth + cut, y: -halfHeight))
        path.addLine(to: CGPoint(x: -halfWidth, y: -halfHeight + cut))
        path.addLine(to: CGPoint(x: -halfWidth, y: halfHeight - cut))
        path.closeSubpath()
        return path
    }

    private func buildBugRepairWorld() {
        // Clockwork workshop: the rail, drive shaft and four gear sockets are
        // physically connected. Keep the illustrated wall and forge visible.
        let drive = CGMutablePath()
        drive.move(to: CGPoint(x: 760, y: 487))
        drive.addLine(to: CGPoint(x: 760, y: 367))
        let shaft = SKShapeNode(path: drive)
        shaft.strokeColor = UIColor(red: 0.33, green: 0.22, blue: 0.18, alpha: 1)
        shaft.lineWidth = 20
        shaft.name = "repairDriveShaft"
        shaft.zPosition = 690
        addChild(shaft)

        let shaftInlay = SKShapeNode(path: drive)
        shaftInlay.strokeColor = UIColor(red: 0.86, green: 0.65, blue: 0.37, alpha: 0.98)
        shaftInlay.lineWidth = 7
        shaftInlay.name = "repairDriveShaftInlay"
        shaftInlay.zPosition = 691
        addChild(shaftInlay)

        let rail = SKShapeNode(
            rectOf: CGSize(width: 780, height: 22),
            cornerRadius: 11
        )
        rail.fillColor = UIColor(red: 0.36, green: 0.25, blue: 0.20, alpha: 0.88)
        rail.strokeColor = UIColor(red: 0.80, green: 0.58, blue: 0.35, alpha: 1)
        rail.lineWidth = 4
        rail.position = CGPoint(x: 760, y: 355)
        rail.name = "repairRail"
        rail.zPosition = 760
        addChild(rail)

        // Workshop sockets sit on narrow installed floor posts, never as
        // unsupported HUD cogs pasted over the illustrated tool wall.
        let benchFoot = SKShapeNode(
            rectOf: CGSize(width: 775, height: 22), cornerRadius: 9
        )
        benchFoot.name = "decorativeRepairBenchFoot"
        benchFoot.position = CGPoint(x: 760, y: 296)
        benchFoot.fillColor = UIColor(red: 0.29, green: 0.20, blue: 0.26, alpha: 0.88)
        benchFoot.strokeColor = UIColor(red: 0.72, green: 0.53, blue: 0.35, alpha: 0.96)
        benchFoot.lineWidth = 3
        benchFoot.zPosition = 729
        addChild(benchFoot)

        // A thin real conduit connects every socket to the center flywheel.
        // These stage indicators are not hints: they are inert until TEST.
        let powerBusPath = CGMutablePath()
        powerBusPath.move(to: CGPoint(x: 485, y: 422))
        powerBusPath.addLine(to: CGPoint(x: 1025, y: 422))
        powerBusPath.move(to: CGPoint(x: 760, y: 422))
        powerBusPath.addLine(to: CGPoint(x: 760, y: 489))
        let powerBus = SKShapeNode(path: powerBusPath)
        powerBus.name = "decorativeRepairPowerBus"
        powerBus.strokeColor = UIColor(red: 0.68, green: 0.47, blue: 0.31, alpha: 0.78)
        powerBus.lineWidth = 6
        powerBus.lineCap = .round
        powerBus.zPosition = 660
        addChild(powerBus)

        let xs: [CGFloat] = [485, 665, 845, 1025]
        for (index, x) in xs.enumerated() {
            let post = SKShapeNode(
                rectOf: CGSize(width: 18, height: 74), cornerRadius: 6
            )
            post.name = "decorativeRepairSocketPost\(index)"
            post.position = CGPoint(x: x, y: 325)
            post.fillColor = UIColor(red: 0.46, green: 0.31, blue: 0.30, alpha: 1)
            post.strokeColor = UIColor(red: 0.85, green: 0.64, blue: 0.41, alpha: 1)
            post.lineWidth = 3
            post.zPosition = 731
            addChild(post)

            let foot = SKShapeNode(path: repairCarvedOutline(width: 76, height: 18))
            foot.name = "decorativeRepairSocketFoot\(index)"
            foot.position = CGPoint(x: x, y: 294)
            foot.fillColor = UIColor(red: 0.45, green: 0.32, blue: 0.36, alpha: 1)
            foot.fillTexture = repairWorkshopStoneTexture
            foot.strokeColor = UIColor(red: 0.92, green: 0.71, blue: 0.46, alpha: 0.95)
            foot.lineWidth = 2
            foot.zPosition = 734
            addChild(foot)

            let conduitStem = SKShapeNode(
                rectOf: CGSize(width: 8, height: 25), cornerRadius: 3
            )
            conduitStem.name = "decorativeRepairIndicatorStem\(index)"
            conduitStem.position = CGPoint(x: x, y: 407)
            conduitStem.fillColor = UIColor(red: 0.68, green: 0.49, blue: 0.34, alpha: 0.96)
            conduitStem.strokeColor = UIColor(red: 0.87, green: 0.67, blue: 0.43, alpha: 1)
            conduitStem.lineWidth = 1.5
            conduitStem.zPosition = 692
            addChild(conduitStem)

            let indicatorMount = SKShapeNode(circleOfRadius: 13)
            indicatorMount.name = "decorativeRepairStageMount\(index)"
            indicatorMount.position = CGPoint(x: x, y: 423)
            indicatorMount.fillColor = UIColor(red: 0.26, green: 0.19, blue: 0.25, alpha: 1)
            indicatorMount.strokeColor = UIColor(red: 0.94, green: 0.74, blue: 0.47, alpha: 1)
            indicatorMount.lineWidth = 2.5
            indicatorMount.zPosition = 797
            addChild(indicatorMount)

            let lens = SKShapeNode(circleOfRadius: 7)
            lens.name = "decorativeRepairStageLens\(index)"
            lens.fillColor = UIColor(red: 0.22, green: 0.18, blue: 0.24, alpha: 1)
            lens.strokeColor = UIColor(red: 0.72, green: 0.53, blue: 0.38, alpha: 1)
            lens.lineWidth = 1.3
            lens.zPosition = 2
            indicatorMount.addChild(lens)

            let housing = palaceCog(
                radius: 67, teeth: 12,
                fill: UIColor(red: 0.43, green: 0.31, blue: 0.23, alpha: 1),
                stroke: UIColor(red: 0.82, green: 0.62, blue: 0.38, alpha: 1)
            )
            housing.position = CGPoint(x: x, y: 355)
            housing.name = "repairSocketBase\(index)"
            housing.zPosition = 785
            addChild(housing)

            let axle = SKShapeNode(circleOfRadius: 38)
            axle.fillColor = UIColor(red: 0.24, green: 0.18, blue: 0.19, alpha: 1)
            axle.strokeColor = UIColor(red: 0.67, green: 0.50, blue: 0.32, alpha: 0.9)
            axle.lineWidth = 3
            axle.name = "repairSocketAxle"
            housing.addChild(axle)

            // Two captive brass clasps visibly loosen when a gear is lifted.
            // They stay behind the actual scored repairStep touch target.
            for (suffix, sign) in [("Left", CGFloat(-1)), ("Right", CGFloat(1))] {
                let clasp = SKShapeNode(
                    rectOf: CGSize(width: 10, height: 34), cornerRadius: 3
                )
                clasp.name = "decorativeRepairSocketClasp\(suffix)"
                clasp.position = CGPoint(x: sign * 55, y: 3)
                clasp.fillColor = UIColor(red: 0.78, green: 0.56, blue: 0.34, alpha: 1)
                clasp.strokeColor = UIColor(red: 1, green: 0.80, blue: 0.48, alpha: 1)
                clasp.lineWidth = 2
                clasp.zPosition = 5
                housing.addChild(clasp)
            }
        }

        // An airy carved metal frame replaces the old solid dark rectangle.
        // The approved stained-glass window and tool wall show through.
        let engine = SKShapeNode(
            path: repairCarvedOutline(width: 206, height: 122)
        )
        engine.fillColor = UIColor(red: 0.29, green: 0.21, blue: 0.30, alpha: 0.37)
        engine.fillTexture = repairWorkshopStoneTexture
        engine.strokeColor = UIColor(red: 0.94, green: 0.76, blue: 0.48, alpha: 0.99)
        engine.lineWidth = 5
        engine.position = CGPoint(x: 760, y: 535)
        engine.name = "repairLanternFixture"
        engine.zPosition = 650
        addChild(engine)

        let flywheelBezel = SKShapeNode(circleOfRadius: 55)
        flywheelBezel.name = "decorativeRepairFlywheelBezel"
        flywheelBezel.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.27, alpha: 0.62)
        flywheelBezel.strokeColor = UIColor(red: 0.97, green: 0.80, blue: 0.52, alpha: 0.95)
        flywheelBezel.lineWidth = 5
        flywheelBezel.zPosition = 1
        engine.addChild(flywheelBezel)

        // The clutch is the *physical reason* the failed machine stalls.
        // It slides inward only AFTER TEST on a wrong repair selection.
        let clutch = SKShapeNode(
            rectOf: CGSize(width: 24, height: 49), cornerRadius: 6
        )
        clutch.name = "decorativeRepairClutch"
        clutch.position = CGPoint(x: 76, y: 0)
        clutch.fillColor = UIColor(red: 0.69, green: 0.48, blue: 0.32, alpha: 1)
        clutch.strokeColor = UIColor(red: 0.98, green: 0.80, blue: 0.49, alpha: 1)
        clutch.lineWidth = 3
        clutch.zPosition = 8
        engine.addChild(clutch)

        let clutchPin = SKShapeNode(circleOfRadius: 7)
        clutchPin.name = "decorativeRepairClutchPin"
        clutchPin.position.y = 13
        clutchPin.fillColor = UIColor(red: 0.32, green: 0.22, blue: 0.27, alpha: 1)
        clutchPin.strokeColor = UIColor(red: 1, green: 0.87, blue: 0.59, alpha: 1)
        clutchPin.lineWidth = 2
        clutch.addChild(clutchPin)

        for x in [CGFloat(-82), 82] {
            let rivet = SKShapeNode(circleOfRadius: 7)
            rivet.position = CGPoint(x: x, y: 0)
            rivet.fillColor = UIColor(red: 0.93, green: 0.77, blue: 0.48, alpha: 1)
            rivet.strokeColor = UIColor(red: 0.28, green: 0.19, blue: 0.16, alpha: 1)
            rivet.lineWidth = 2
            rivet.name = "repairFixtureRivet"
            engine.addChild(rivet)
        }

        let core = SKShapeNode(circleOfRadius: 47)
        core.fillColor = UIColor(red: 0.21, green: 0.16, blue: 0.25, alpha: 0.90)
        core.strokeColor = UIColor(red: 0.92, green: 0.72, blue: 0.47, alpha: 1)
        core.lineWidth = 3
        core.name = "repairLanternCore"
        engine.addChild(core)

        let rotor = palaceCog(
            radius: 32, teeth: 10,
            fill: UIColor(red: 0.55, green: 0.37, blue: 0.22, alpha: 1),
            stroke: UIColor(red: 0.94, green: 0.75, blue: 0.45, alpha: 1)
        )
        rotor.name = "repairMachineRotor"
        core.addChild(rotor)

        let hub = SKShapeNode(circleOfRadius: 12)
        hub.fillColor = UIColor(red: 0.10, green: 0.09, blue: 0.15, alpha: 1)
        hub.strokeColor = UIColor(red: 0.97, green: 0.78, blue: 0.43, alpha: 1)
        hub.lineWidth = 3
        hub.name = "repairMachineHub"
        rotor.addChild(hub)

        // One small inscription is mounted on the existing architecture,
        // rather than free-floating in the painted stained-glass window.
        let workshopPlaque = SKShapeNode(
            path: repairCarvedOutline(width: 353, height: 38)
        )
        workshopPlaque.name = "decorativeRepairWorkshopPlaque"
        workshopPlaque.position = CGPoint(x: 760, y: 628)
        workshopPlaque.fillColor = UIColor(red: 0.27, green: 0.20, blue: 0.30, alpha: 0.73)
        workshopPlaque.fillTexture = repairWorkshopStoneTexture
        workshopPlaque.strokeColor = UIColor(red: 0.84, green: 0.66, blue: 0.44, alpha: 0.85)
        workshopPlaque.lineWidth = 2
        workshopPlaque.zPosition = 815
        addChild(workshopPlaque)

        let cuePlate = SKShapeNode(
            path: repairCarvedOutline(width: 306, height: 36)
        )
        cuePlate.name = "decorativeRepairCuePlate"
        cuePlate.position = CGPoint(x: 760, y: 457)
        cuePlate.fillColor = UIColor(red: 0.30, green: 0.23, blue: 0.31, alpha: 0.78)
        cuePlate.fillTexture = repairWorkshopStoneTexture
        cuePlate.strokeColor = UIColor(red: 0.91, green: 0.70, blue: 0.45, alpha: 0.80)
        cuePlate.lineWidth = 2
        cuePlate.zPosition = 798
        addChild(cuePlate)

        let title = ArtSystem.label("TIKO'S CLOCKWORK WORKSHOP", size: 20)
        title.fontName = "Georgia-Bold"
        title.fontColor = UIColor(red: 1, green: 0.93, blue: 0.76, alpha: 1)
        title.position = CGPoint(x: 760, y: 627)
        title.name = "bugRepairTitle"
        title.zPosition = 820
        addChild(title)

        let cue = ArtSystem.label("Find the two misplaced gears.", size: 17)
        cue.fontColor = UIColor(red: 1, green: 0.94, blue: 0.80, alpha: 0.98)
        cue.position = CGPoint(x: 760, y: 457)
        cue.name = "repairCue"
        cue.zPosition = 820
        addChild(cue)

        for index in 0..<PuzzlePalaceEncounterCatalog.bugRepairFamilies.count {
            let lamp = SKShapeNode(circleOfRadius: 10)
            lamp.fillColor = UIColor(red: 0.20, green: 0.14, blue: 0.18, alpha: 1)
            lamp.strokeColor = UIColor(red: 0.82, green: 0.64, blue: 0.38, alpha: 0.88)
            lamp.lineWidth = 2
            lamp.position = CGPoint(x: 1090 + CGFloat(index) * 34, y: 535)
            lamp.name = "repairProgress\(index)"
            lamp.zPosition = 820
            addChild(lamp)
        }

        // A grounded pull lever replaces the old floating checkmark icon.
        // Hit node names remain "repairFix" for stable native interaction APIs.
        let lever = SKNode()
        lever.position = CGPoint(x: 1145, y: 300)
        lever.name = "repairFix"
        lever.zPosition = 920

        let leverBase = SKShapeNode(
            rectOf: CGSize(width: 88, height: 110),
            cornerRadius: 18
        )
        leverBase.fillColor = UIColor(red: 0.29, green: 0.20, blue: 0.17, alpha: 1)
        leverBase.strokeColor = UIColor(red: 0.95, green: 0.74, blue: 0.41, alpha: 1)
        leverBase.lineWidth = 4
        leverBase.name = "repairFix"
        lever.addChild(leverBase)

        let leverStem = SKShapeNode(
            rectOf: CGSize(width: 14, height: 43),
            cornerRadius: 7
        )
        leverStem.position.y = 12
        leverStem.fillColor = UIColor(red: 0.76, green: 0.54, blue: 0.30, alpha: 1)
        leverStem.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 0.43, alpha: 1)
        leverStem.lineWidth = 2
        leverStem.name = "repairFix"
        lever.addChild(leverStem)

        let handle = SKShapeNode(circleOfRadius: 17)
        handle.position.y = 32
        handle.fillColor = UIColor(red: 0.94, green: 0.71, blue: 0.38, alpha: 1)
        handle.strokeColor = UIColor(red: 1, green: 0.91, blue: 0.67, alpha: 1)
        handle.lineWidth = 3
        handle.name = "repairFix"
        lever.addChild(handle)

        let leverLabel = ArtSystem.label("TEST", size: 16)
        leverLabel.fontName = "AvenirNext-DemiBold"
        leverLabel.fontColor = UIColor(red: 1, green: 0.94, blue: 0.80, alpha: 1)
        leverLabel.position.y = -34
        leverLabel.name = "repairFix"
        lever.addChild(leverLabel)

        makeAccessible(lever, label: "Pull the workshop lever to test the repaired plan")
        addChild(lever)
        registerInteraction(lever, clearance: 12)

        let reset = worldGear("↺", name: "repairReset",
                              at: CGPoint(x: 1145, y: 427), radius: 28,
                              accessibilityLabel: "Clear selected gears")
        reset.zPosition = 920

        let back = worldControl("‹", name: "bugLanternBack",
                                at: CGPoint(x: 1180, y: 665), radius: 30,
                                accessibilityLabel: "Back to Bug Lantern")
        back.zPosition = 2050
    }

    private func setRepairMachinePowered(_ powered: Bool) {
        let bronze = UIColor(red: 0.76, green: 0.55, blue: 0.31, alpha: 1)
        let gold = UIColor(red: 1.0, green: 0.82, blue: 0.43, alpha: 1)
        if let core = childNode(withName: "//repairLanternCore") as? SKShapeNode {
            core.fillColor = powered
                ? UIColor(red: 0.46, green: 0.33, blue: 0.19, alpha: 1)
                : UIColor(red: 0.15, green: 0.14, blue: 0.23, alpha: 1)
            core.glowWidth = powered && !reducedMotion ? 8 : 0
        }
        if let rail = childNode(withName: "repairRail") as? SKShapeNode {
            rail.strokeColor = powered ? gold : bronze
        }
        for index in 0..<4 {
            if let housing = childNode(withName: "repairSocketBase\(index)") as? SKShapeNode {
                housing.strokeColor = powered ? gold : bronze
            }
        }
        if !powered, let rotor = childNode(withName: "//repairMachineRotor") {
            rotor.removeAction(forKey: "repairRotor")
            rotor.zRotation = 0
        }
        if powered, !reducedMotion,
           let rotor = childNode(withName: "//repairMachineRotor") {
            rotor.removeAction(forKey: "repairRotor")
            rotor.run(.rotate(byAngle: .pi * 2, duration: 0.8), withKey: "repairRotor")
        }
    }

    private func showRepairMachineMiss() {
        if let rail = childNode(withName: "repairRail") as? SKShapeNode {
            rail.strokeColor = UIColor(red: 1, green: 0.51, blue: 0.36, alpha: 1)
        }
        if let core = childNode(withName: "//repairLanternCore") as? SKShapeNode {
            core.fillColor = UIColor(red: 0.62, green: 0.19, blue: 0.16, alpha: 1)
        }
        guard let rotor = childNode(withName: "//repairMachineRotor") else { return }
        rotor.removeAction(forKey: "repairRotor")
        if reducedMotion {
            rotor.zRotation = -.pi / 10 // Stalled gear remains visibly off-axis.
        } else {
            rotor.run(.sequence([
                .rotate(byAngle: -.pi / 10, duration: 0.16),
                .rotate(byAngle: .pi / 10, duration: 0.16)
            ]), withKey: "repairRotor")
        }
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
        setRepairMachinePowered(false)

        let xs: [CGFloat] = [485, 665, 845, 1025]
        for (index, step) in repairEncounter.presented.enumerated() {
            // Physically removable brass gears on the shared machine shaft.
            // Preserve step IDs, positions and accessibility for all tests and
            // for the existing evidence/scaffold flow.
            // Smaller, carved working gears leave the painted workshop visible.
            // Diameter remains over 110 scene points (more than 60 iPad points
            // at the supported 4:3 / 16:9 landscape scales).
            let plate = palaceCog(
                radius: 57, teeth: 11,
                fill: UIColor(red: 0.61, green: 0.44, blue: 0.29, alpha: 1),
                stroke: UIColor(red: 0.96, green: 0.77, blue: 0.48, alpha: 1)
            )
            plate.position = CGPoint(x: xs[index], y: 355)
            plate.name = "repairStep\(index)"
            plate.zPosition = 850
            plate.userData = NSMutableDictionary(dictionary: ["stepIndex": index])

            let bezel = SKShapeNode(circleOfRadius: 45)
            bezel.fillColor = UIColor(red: 0.56, green: 0.40, blue: 0.26, alpha: 1)
            bezel.strokeColor = UIColor(red: 0.99, green: 0.83, blue: 0.55, alpha: 1)
            bezel.lineWidth = 4
            bezel.name = plate.name
            plate.addChild(bezel)

            let center = SKShapeNode(circleOfRadius: 35)
            center.fillColor = UIColor(red: 0.30, green: 0.23, blue: 0.22, alpha: 1)
            center.strokeColor = UIColor(red: 0.90, green: 0.70, blue: 0.44, alpha: 1)
            center.lineWidth = 3
            center.name = plate.name
            plate.addChild(center)

            let number = ArtSystem.label("\(index + 1)", size: 15)
            number.fontName = "AvenirNext-DemiBold"
            number.fontColor = UIColor(red: 0.97, green: 0.77, blue: 0.47, alpha: 1)
            number.position = CGPoint(x: -28, y: 31)
            number.name = plate.name
            plate.addChild(number)

            let commandGlyph = ArtSystem.label(step.glyph, size: 31)
            commandGlyph.fontColor = UIColor(red: 1.0, green: 0.93, blue: 0.77, alpha: 1)
            commandGlyph.position.y = 2
            commandGlyph.name = plate.name
            plate.addChild(commandGlyph)

            makeAccessible(plate, label: "Gear \(index + 1): \(step.title)")
            addChild(plate)
            registerInteraction(plate, clearance: 12)

            let label = ArtSystem.label(step.title, size: 14)
            label.fontName = "AvenirNext-DemiBold"
            label.fontColor = UIColor(red: 1.0, green: 0.93, blue: 0.75, alpha: 1)
            label.position = CGPoint(x: xs[index], y: 277)
            label.name = "repairStepLabel\(index)"
            label.zPosition = 850
            addChild(label)
        }

        renderRepairSelection()
        instruction.text = repairEncounter.prompt
        showAttentionCue(
            at: CGPoint(x: 760, y: 355),
            tint: UIColor(red: 0.94, green: 0.72, blue: 0.42, alpha: 1),
            width: 385
        )
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
            ? "Pull the TEST lever and watch the clockwork."
            : "Choose one more gear to swap."
    }

    private func renderRepairSelection() {
        for index in 0..<4 {
            guard let plate = childNode(withName: "repairStep\(index)") as? SKShapeNode else { continue }
            let selected = repairSelection.contains(index)
            plate.strokeColor = selected
                ? UIColor(red: 1.0, green: 0.86, blue: 0.49, alpha: 1)
                : UIColor(red: 0.90, green: 0.70, blue: 0.41, alpha: 1)
            plate.glowWidth = selected && !reducedMotion ? 4 : 0
            // Lift a selected gear out of its socket. A physical displacement
            // communicates selection without relying on a neon halo or scale.
            // Reset from the authored rail position, not the last animation,
            // so rapid taps and Reduced Motion remain deterministic.
            let restingY: CGFloat = 355
            let targetY = restingY + (selected ? 18 : 0)
            plate.removeAction(forKey: "repairGearLift")
            if reducedMotion {
                plate.position.y = targetY
            } else {
                plate.run(.moveTo(y: targetY, duration: 0.14), withKey: "repairGearLift")
            }
            plate.setScale(1)
            if let socket = childNode(withName: "repairSocketBase\(index)") as? SKShapeNode {
                socket.strokeColor = selected
                    ? UIColor(red: 1.0, green: 0.86, blue: 0.49, alpha: 1)
                    : UIColor(red: 0.76, green: 0.55, blue: 0.31, alpha: 1)
            }
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
            instruction.text = "Tap two gears to swap. Then pull TEST."
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

        // Physically execute the child's proposed swap even when it is wrong.
        // The mechanism then stalls and resets without awarding mastery.
        animateRepairSwap(selected) { [weak self] in
            guard let self else { return }
            if correct {
                self.solved = true
                self.clearAttentionCue()
                self.successFeedback()
                self.valkyrie.pose(.celebrate)
                self.tiko.pose(.celebrate)
                self.setRepairMachinePowered(true)
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
                self.showRepairMachineMiss()
                self.support = self.support == .independent ? .lightHint : .strongHint
                self.valkyrie.pose(.react)
                self.tiko.pose(.react)
                self.instruction.text = self.support == .lightHint
                    ? "Read from first to last. Which two commands make the plan happen out of order?"
                    : "Find the first impossible transition, then look for the command that belongs there."
                self.repairEncounter = self.state.nextPuzzleBugRepairEncounter()
                self.run(.sequence([
                    .wait(forDuration: self.reducedMotion ? 0.60 : 0.85),
                    .run { [weak self] in self?.buildBugRepairEncounter(resetSupport: false) }
                ]))
            }
        }
    }

    private func animateRepairSwap(
        _ indices: [Int],
        completion: @escaping () -> Void
    ) {
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

    private func installCompletedRepairGears() {
        // The final restored machine should not display four empty sockets.
        // Leave stable in-world gears installed on every revisit.
        for index in 0..<4 {
            guard let socket = childNode(withName: "repairSocketBase\(index)") as? SKShapeNode,
                  socket.childNode(withName: "repairCompletedGear\(index)") == nil else { continue }

            let installed = palaceCog(
                radius: 40, teeth: 10,
                fill: UIColor(red: 0.66, green: 0.45, blue: 0.27, alpha: 1),
                stroke: UIColor(red: 0.99, green: 0.82, blue: 0.50, alpha: 1)
            )
            installed.name = "repairCompletedGear\(index)"
            installed.zPosition = 3
            socket.addChild(installed)

            let rivet = SKShapeNode(circleOfRadius: 13)
            rivet.fillColor = UIColor(red: 0.22, green: 0.17, blue: 0.17, alpha: 1)
            rivet.strokeColor = UIColor(red: 0.97, green: 0.78, blue: 0.44, alpha: 1)
            rivet.lineWidth = 3
            rivet.name = "repairCompletedRivet"
            installed.addChild(rivet)
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
        setRepairMachinePowered(true)
        installCompletedRepairGears()
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
        guard let point = completedTap(in: touches) else { return }
        handleTap(at: point)
    }

    /// An unlocked palace route is a single-tap journey: the child does not
    /// have to guess that a second tap at the doorway is required.
    /// Ignore subsequent scenery taps while the transition walk is underway.
    private func followUnlockedRoute(to world: AppState.World, at destination: CGPoint, prompt: String) {
        guard !routeTransitionPending else { return }
        routeTransitionPending = true
        let enter = { [weak self] in
            guard let self else { return }
            self.state.travel(to: world)
        }
        if isNear(destination) {
            enter()
        } else {
            instruction.text = prompt
            travel(to: destination, then: enter)
        }
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
        // The unlocked Mirror Hall door sits near the Re-sort Vault's right
        // pedestal. Route activation takes precedence inside its visible 60pt
        // button, otherwise the pedestal steals a legitimate navigation tap.
        let mirrorDoor = childNode(withName: "mirrorHallRoute")
        let mirrorDoorTapped = place == .resortVault
            && state.puzzleMirrorHallAvailable
            && mirrorDoor != nil
            && hypot(point.x - mirrorDoor!.position.x,
                     point.y - mirrorDoor!.position.y) <= 40
        let target = mirrorDoorTapped ? "mirrorHallRoute"
            : place == .resortVault
                ? (resortPedestalTarget(at: point) ?? targetName(at: point))
                : targetName(at: point)

        // Let Home cancel the journey, but never restart the same route or
        // interrupt its arrival callback with a stray floor or puzzle tap.
        if routeTransitionPending && target != "home" { return }

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
            followUnlockedRoute(
                to: .memoryBridge, at: CGPoint(x: 1005, y: 175),
                prompt: "Walk through the opened Rune Gate to Memory Bridge."
            )

        case "memoryPad":
            guard place == .memoryBridge,
                  let choice = memoryChoice(at: point) else { return }
            approachMemoryPad(choice.node, symbol: choice.symbol)

        case "stopGoRoute":
            guard place == .memoryBridge, state.puzzleStopGoAvailable else { return }
            followUnlockedRoute(
                to: .stopGoOrbs, at: CGPoint(x: 1000, y: 175),
                prompt: "Cross Memory Bridge to the orb chamber."
            )

        case "memoryBridgeBack":
            state.travel(to: .memoryBridge)

        case "stopGoOrb", "stopGoOrbCore", "stopGoOrbGlyph":
            handleStopGoOrbTap()

        case "sortingPedestalRoute":
            guard place == .stopGoOrbs, state.puzzleSortingAvailable else { return }
            followUnlockedRoute(
                to: .sortingPedestal, at: CGPoint(x: 1000, y: 175),
                prompt: "Pass the stabilized orb barrier to the Sorting Pedestal."
            )

        case "stopGoBack":
            state.travel(to: .stopGoOrbs)

        case "sortLeftPedestal", "sortLeftPedestalGlyph":
            handleSortPedestal(.left)

        case "sortRightPedestal", "sortRightPedestalGlyph":
            handleSortPedestal(.right)

        case "resortVaultRoute":
            guard place == .sortingPedestal, state.puzzleResortAvailable else { return }
            followUnlockedRoute(
                to: .resortVault, at: CGPoint(x: 1000, y: 175),
                prompt: "Follow Tiko through the stable pedestals to the Re-sort Vault."
            )

        case "sortingBack":
            state.travel(to: .sortingPedestal)

        case "resortLeftPedestal", "resortLeftPedestalGlyph":
            handleResortPedestal(.left)

        case "resortRightPedestal", "resortRightPedestalGlyph":
            handleResortPedestal(.right)

        case "mirrorHallRoute":
            guard place == .resortVault, state.puzzleMirrorHallAvailable else { return }
            followUnlockedRoute(
                to: .mirrorHall, at: CGPoint(x: 1000, y: 175),
                prompt: "Follow Tiko through the stable vault into Mirror Hall."
            )

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
            clearAttentionCue()
            pulse(node)
            seatCarvedRune(from: node, value: value)
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: attemptSupport,
                attempts: attempts,
                responseTime: Date().timeIntervalSince(startedAt)
            )
            refreshRuneGateProgress(animated: true)
            successFeedback(at: CGPoint(x: 970, y: 405))
            valkyrie.pose(.celebrate)

            if state.puzzleRuneGateComplete {
                openRuneGate()
                return
            }

            instruction.text = attemptSupport == .independent
                ? "That seal is awake. Tiko found the next rune lock."
                : "Tiko helped with that seal. Try the next rune lock independently."

            run(
                .sequence([
                    .wait(forDuration: reducedMotion ? 0.75 : 1.15),
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
            errorFeedback()
            valkyrie.pose(.react)
            nudge(node)
            // The carved lock visibly refuses the wrong stone, even with Reduced Motion.
            if let socket = childNode(withName: "//runeSocket") as? SKShapeNode {
                socket.strokeColor = UIColor(red: 1, green: 0.48, blue: 0.35, alpha: 1)
                socket.fillColor = UIColor(red: 0.43, green: 0.15, blue: 0.15, alpha: 1)
                socket.run(.sequence([
                    .wait(forDuration: 0.65),
                    .run { [weak socket] in
                        socket?.strokeColor = UIColor(red: 0.96, green: 0.76, blue: 0.40, alpha: 0.96)
                        socket?.fillColor = UIColor(red: 0.11, green: 0.08, blue: 0.14, alpha: 1)
                    }
                ]), withKey: "runeRejected")
            }
            showPatternHint()
            instruction.text = support == .lightHint
                ? "Look for the two-rune beat that repeats."
                : "Tiko lit matching positions. Follow the repeating pair, then try again."
            runeAcceptingInput = true
        }
    }

    private func seatCarvedRune(from selected: SKNode, value: String) {
        guard let socket = childNode(withName: "//runeSocket") else {
            fillSocket(with: value)
            return
        }
        guard !reducedMotion else {
            fillSocket(with: value)
            return
        }

        let destination = socket.parent?.convert(socket.position, to: self) ?? socket.position
        let travelingStone = runeStone(value, name: "decorativeRuneInTransit")
        travelingStone.position = selected.position
        travelingStone.setScale(1.19)
        travelingStone.zPosition = 1800
        selected.isHidden = true
        addChild(travelingStone)

        // The piece physically travels from its floor plinth into the door.
        // Save/evidence stays synchronous; visuals never decide correctness.
        travelingStone.run(.sequence([
            .group([
                .move(to: destination, duration: 0.32),
                .scale(to: 1, duration: 0.32)
            ]),
            .run { [weak self] in self?.fillSocket(with: value) },
            .removeFromParent()
        ]), withKey: "seatRune")
    }

    private func fillSocket(with rune: String) {
        guard let socket = childNode(withName: "//runeSocket") as? SKShapeNode else { return }
        childNode(withName: "//runeSocketMark")?.removeFromParent()
        let glyph = ArtSystem.label(rune, size: 43)
        glyph.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.50, alpha: 1)
        glyph.name = "runeSocketMark"
        socket.addChild(glyph)
        socket.strokeColor = UIColor(red: 0.98, green: 0.82, blue: 0.43, alpha: 1)
        socket.fillColor = UIColor(red: 0.42, green: 0.29, blue: 0.18, alpha: 1)
        socket.glowWidth = reducedMotion ? 0 : 8
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

        if let crest = childNode(withName: "//puzzleGateCrest") as? SKShapeNode {
            crest.alpha = min(1, 0.55 + CGFloat(count) * 0.15)
            crest.glowWidth = reducedMotion ? 0 : CGFloat(count) * 4
        }
    }

    /// The approved painting stays intact when locked. Once earned, a real
    /// painted-world opening and two sliding leaves replace the closed door.
    /// The overlay is a sibling of puzzleGate: regression tests intentionally
    /// keep that interactive lock compact.
    private func revealPaintedRuneDoors() {
        guard childNode(withName: "runeDoorPassage") == nil,
              let gate = childNode(withName: "puzzleGate") else { return }

        let doorway = SKNode()
        doorway.position = gate.position
        doorway.zPosition = 355
        doorway.name = "runeDoorPassage"
        addChild(doorway)

        let openingPath = CGMutablePath()
        openingPath.move(to: CGPoint(x: -94, y: -126))
        openingPath.addLine(to: CGPoint(x: -94, y: 35))
        openingPath.addCurve(
            to: CGPoint(x: 94, y: 35),
            control1: CGPoint(x: -94, y: 156),
            control2: CGPoint(x: 94, y: 156)
        )
        openingPath.addLine(to: CGPoint(x: 94, y: -126))
        openingPath.closeSubpath()
        let opening = SKShapeNode(path: openingPath)
        opening.fillColor = UIColor(red: 0.055, green: 0.040, blue: 0.13, alpha: 1)
        opening.strokeColor = UIColor(red: 0.93, green: 0.73, blue: 0.41, alpha: 0.93)
        opening.lineWidth = 6
        opening.name = "runeDoorOpenInterior"
        doorway.addChild(opening)

        // Depth and light, not a thin gold seam on top of closed painted doors.
        let distanceLight = SKShapeNode(ellipseOf: CGSize(width: 104, height: 192))
        distanceLight.position = CGPoint(x: 0, y: -16)
        distanceLight.fillColor = UIColor(red: 0.44, green: 0.30, blue: 0.67, alpha: 0.40)
        distanceLight.strokeColor = UIColor(red: 0.91, green: 0.70, blue: 0.45, alpha: 0.35)
        distanceLight.lineWidth = 3
        distanceLight.name = "runeDoorDistanceLight"
        opening.addChild(distanceLight)

        let star = SKShapeNode(circleOfRadius: 12)
        star.fillColor = UIColor(red: 1, green: 0.89, blue: 0.64, alpha: 1)
        star.strokeColor = UIColor(red: 1, green: 0.94, blue: 0.74, alpha: 1)
        star.lineWidth = 2
        star.position = CGPoint(x: 0, y: 34)
        star.glowWidth = reducedMotion ? 0 : 11
        star.name = "runeDoorDestination"
        opening.addChild(star)

        // Capture the authentic door material from the approved scene. A pair
        // of matching texture leaves parts to reveal the passage. Cropping
        // is from the existing asset; no new character or environment repaint.
        if let painting = childNode(withName: "puzzleIllustratedBackdrop") as? SKSpriteNode,
           let texture = painting.texture {
            let cropWidth: CGFloat = 188
            let cropHeight: CGFloat = 254
            let leftEdge = painting.position.x - painting.size.width / 2
            let bottomEdge = painting.position.y - painting.size.height / 2
            let artworkX = (gate.position.x - cropWidth / 2 - leftEdge) / painting.size.width
            let artworkY = (gate.position.y - cropHeight / 2 - bottomEdge) / painting.size.height
            for half in 0..<2 {
                let rect = CGRect(
                    x: artworkX + CGFloat(half) * cropWidth / (2 * painting.size.width),
                    y: artworkY,
                    width: cropWidth / (2 * painting.size.width),
                    height: cropHeight / painting.size.height
                )
                let leaf = SKSpriteNode(
                    texture: SKTexture(rect: rect, in: texture),
                    size: CGSize(width: cropWidth / 2, height: cropHeight)
                )
                leaf.position = CGPoint(x: half == 0 ? -47 : 47, y: 0)
                leaf.zPosition = 3
                leaf.name = "runeDoorLeaf\(half)"
                doorway.addChild(leaf)

                // A physical door is open in the completed screenshot even
                // when restored from saved progress with Reduced Motion on.
                let direction: CGFloat = half == 0 ? -1 : 1
                if reducedMotion {
                    leaf.position.x += direction * 98
                } else {
                    leaf.run(.moveBy(x: direction * 98, y: 0, duration: 0.60),
                             withKey: "runeDoorSlide")
                }
            }
        }

        // A clear navigable threshold connects the light to the floor route.
        let sill = SKShapeNode(ellipseOf: CGSize(width: 212, height: 24))
        sill.position.y = -131
        sill.fillColor = UIColor(red: 0.67, green: 0.47, blue: 0.24, alpha: 0.79)
        sill.strokeColor = UIColor(red: 0.96, green: 0.81, blue: 0.51, alpha: 1)
        sill.lineWidth = 3
        sill.name = "runeDoorSill"
        doorway.addChild(sill)
    }

    private func openRuneGate() {
        runeAcceptingInput = false
        removeAction(forKey: "nextPuzzleRune")
        clearRuneObjects()
        refreshRuneGateProgress(animated: true)

        if let gate = childNode(withName: "puzzleGate") as? SKShapeNode {
            gate.strokeColor = UIColor(red: 0.95, green: 0.78, blue: 0.35, alpha: 0.045)
            gate.glowWidth = 16
        }
        if let passage = childNode(withName: "//puzzleGateOpening") as? SKShapeNode {
            passage.alpha = 0  // The actual opening is the stone-framed passage.
        }
        revealPaintedRuneDoors()
        if let door = childNode(withName: "//puzzleGateDoor") as? SKShapeNode {
            door.run(
                .group([
                    .scaleX(to: 0.18, duration: reducedMotion ? 0 : 0.55),
                    .fadeAlpha(to: 0.28, duration: reducedMotion ? 0 : 0.55)
                ]),
                withKey: "gateOpen"
            )
        }
        if let path = childNode(withName: "runePath") {
            // runePath is a container SKNode, not an SKShapeNode. Light its
            // actual stone children instead of silently failing the cast.
            for stone in path.children.compactMap({ $0 as? SKShapeNode }) {
                stone.fillColor = UIColor(red: 0.56, green: 0.38, blue: 0.18, alpha: 0.85)
                stone.strokeColor = UIColor(red: 0.98, green: 0.79, blue: 0.36, alpha: 1)
                stone.glowWidth = reducedMotion ? 0 : 8
                stone.userData = NSMutableDictionary(dictionary: [
                    "runePathPowered": true
                ])
            }
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

        if lastPalaceKineticReducedMotion != reducedMotion {
            syncPalaceKinetics()
        }
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
