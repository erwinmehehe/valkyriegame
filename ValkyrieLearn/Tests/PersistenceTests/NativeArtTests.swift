import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeArtTests: XCTestCase {
    func testFlowerGateUsesSourceResolutionAndKeepsActorAndChoicesClear() throws {
        let atlas = try XCTUnwrap(ArtSystem.texture("WordGardenSourceAtlas"))
        XCTAssertGreaterThanOrEqual(atlas.size().width, 1600)
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = WordGardenScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        scene.update(0)
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        let gate = try XCTUnwrap(scene.childNode(withName: "flowerGate"))
        let gateFrame = gate.calculateAccumulatedFrame()
        for flower in scene.children where flower.name == "flowerChoice" {
            XCTAssertFalse(gateFrame.intersects(flower.calculateAccumulatedFrame()))
        }
    }

    func testGlobalPolishLayoutKeepsHUDOutOfTheLearningStage() throws {
        let layout = AdventureSceneLayout(size: CGSize(width: 1280, height: 720))
        XCTAssertFalse(layout.topHUD.intersects(layout.interactionStage))
        XCTAssertFalse(layout.instructionZone.intersects(layout.interactionStage))
        XCTAssertGreaterThanOrEqual(layout.actorLane.height, 120)

        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        for name in ["wordGarden", "puzzlePalace", "castle", "scienceLab"] {
            let node = try XCTUnwrap(scene.childNode(withName: name))
            let frame = node.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 60, "\(name) touch target is too narrow.")
            XCTAssertGreaterThanOrEqual(frame.height, 60, "\(name) touch target is too short.")
            XCTAssertTrue(node.isAccessibilityElement, "\(name) must expose an accessibility label.")
            XCTAssertFalse((node.accessibilityLabel ?? "").isEmpty)
        }
    }

    func testApprovedArtIsPackagedAndEveryActorPoseResolves() async throws {
        for name in ["StarlightIsles", "MathCastle", "CrystalCart", "Crystal", "IslesForegroundLeft", "CastleForegroundRight", "BridgeOakPlank", "BridgeGreenPlank", "BridgeTimber", "BridgeWorkOrder", "BridgeChannel", "BridgeDial", "V331WorldAtlas", "Lumi", "Tiko", "StoryBloom"] {
            XCTAssertNotNil(ArtSystem.texture(name), "Missing bundled image: \(name)")
        }
        for character in ["Valkyrie", "Pip"] {
            for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
                XCTAssertFalse(ArtSystem.frames(character: character, pose: pose).isEmpty, "Missing \(character) \(pose)")
            }
        }
        XCTAssertEqual(ArtSystem.frames(character: "Valkyrie", pose: .walk).count, 2)
        for character in ["Lumi", "Tiko"] {
            for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
                XCTAssertFalse(ArtSystem.frames(character: character, pose: pose).isEmpty)
            }
        }
        let lumi = LumiNode()
        lumi.pose(.interact)
        XCTAssertFalse(lumi.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first?.isHidden ?? true)
        let tiko = TikoNode()
        tiko.pose(.interact)
        XCTAssertFalse(tiko.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first?.isHidden ?? true)
        let actor = ValkyrieNode()
        for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
            actor.pose(pose)
            let sprite = try XCTUnwrap(actor.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first)
            XCTAssertFalse(sprite.isHidden)
            XCTAssertEqual(sprite.anchorPoint, CGPoint(x: 0.5, y: 0))
            XCTAssertEqual(sprite.size.height, 300)
            XCTAssertFalse(actor.children.compactMap { $0 as? SKLabelNode }.contains { !$0.isHidden })
        }
    }

    func testActorKeepsFacingWhenItStopsAndReducedMotionRemovesAmbientActions() async throws {
        let actor = ValkyrieNode(); actor.position = CGPoint(x: 500, y: 175)
        actor.walk(to: CGPoint(x: 200, y: 175)) {}
        XCTAssertLessThan(actor.bodyNode.xScale, 0)
        actor.cancelTravel()
        XCTAssertLessThan(actor.bodyNode.xScale, 0)
        actor.face(toward: CGPoint(x: 820, y: 310)); actor.pose(.interact)
        XCTAssertGreaterThan(actor.bodyNode.xScale, 0)
        actor.reducedMotion = true; actor.pose(.idle)
        XCTAssertNil(actor.bodyNode.action(forKey: "pose"))
        XCTAssertNil(actor.action(forKey: "travel"))
    }

    func testMathArtKeepsLiveCartInputAndPowerReaction() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        // SKActions only advance while SpriteKit presents the scene. A manual
        // didMove call on a temporary SKView cannot exercise route timing.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = MathCastleScene(state: state)
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
        scene.update(0) // Exercise real actor depth, not the initial z = 0 state.
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 390, y: 605)), "wind")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 52, y: 669)), "home")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 595, y: 235)), "supply")
        XCTAssertTrue(scene.childNode(withName: "next")?.isHidden == false) // Free workshop exit.
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        let target = try XCTUnwrap(state.runtime?.encounter.targetQuantity)
        for _ in 0..<target { scene.handleTap(at: CGPoint(x: 595, y: 235)) }
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(state.runtime?.completed == true)
        let powerLight = try XCTUnwrap(scene.childNode(withName: "castlePowerLight") as? SKShapeNode)
        XCTAssertEqual(powerLight.glowWidth, 16)
        let portal = try XCTUnwrap(scene.childNode(withName: "challengeGate") as? SKShapeNode)
        XCTAssertEqual(portal.glowWidth, 4, "Ordinary work powers the castle route but must not fake Challenge Gate readiness.")

        let bridge = try XCTUnwrap(scene.childNode(withName: "physicalRouteBridge"))
        XCTAssertNotNil(bridge.action(forKey: "routeOpen"))
        let beacon = try XCTUnwrap(scene.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertNotNil(beacon.action(forKey: "routeReady"))
        XCTAssertNotNil(scene.pip.action(forKey: "travel"))

        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNil(
            scene.valkyrie.action(forKey: "travel"),
            "Do not let the child run onto the route while the physical bridge is still unfolding."
        )

        // A paused renderer must keep the route unavailable even after more
        // wall-clock time than the normal opening duration has passed.
        view.isPaused = true
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(beacon.glowWidth, 0)
        XCTAssertLessThan(bridge.xScale, 1)
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        view.isPaused = false

        // Wait for rendered readiness with a bounded deadline, rather than
        // assuming the simulator delivered a fixed number of frames.
        let deadline = Date().addingTimeInterval(5)
        while beacon.glowWidth != 18 && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertEqual(beacon.glowWidth, 18)
        XCTAssertEqual(bridge.xScale, 1, accuracy: 0.001)
        XCTAssertEqual(bridge.alpha, 1, accuracy: 0.001)
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNotNil(
            scene.valkyrie.action(forKey: "travel"),
            "Once the bridge is visibly ready, the next action should become physical route traversal."
        )
        scene.willLeave()
    }

    func testStoryTreeIgnoresTheChasmAndRoutesCastleEntryThroughThePaintedPath() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state); scene.didMove(to: SKView())
        XCTAssertFalse(scene.isOnPath(CGPoint(x: 1000, y: 200)))
        scene.handleTap(at: CGPoint(x: 1000, y: 200))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertTrue(scene.isOnPath(CGPoint(x: 285, y: 235)))
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        XCTAssertNotNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertEqual(state.world, .storyTree)
        scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 795, y: 450)
        scene.update(0)
        let landmark = try XCTUnwrap(scene.childNode(withName: "castle"))
        XCTAssertFalse(landmark is SKShapeNode, "Story Tree destinations should be landmark assemblies, not generic button boxes.")
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        XCTAssertEqual(state.world, .mathCastle)
        scene.willLeave()
    }

    func testWordGardenProgressesFlowerGateToSunmillToStoryHollowWithDistinctReward() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        let story = StoryTreeScene(state: state)
        story.didMove(to: SKView())
        story.valkyrie.position = CGPoint(x: 190, y: 170)
        story.handleTap(at: CGPoint(x: 150, y: 255))
        XCTAssertEqual(state.world, .wordGarden)
        story.willLeave()

        let flower = WordGardenScene(state: state)
        flower.didMove(to: SKView())
        XCTAssertNotNil(flower.childNode(withName: "flowerGate"))
        XCTAssertNotNil(flower.childNode(withName: "questionPrompt"))
        XCTAssertNotNil(flower.childNode(withName: "targetRune"))
        XCTAssertEqual(flower.children.filter { $0.name == "flowerChoice" }.count, 4)
        XCTAssertEqual(flower.children.filter { $0.name == "soundFlower" }.count, 3)
        XCTAssertNil(flower.childNode(withName: "sunmillRoute"))
        XCTAssertEqual(state.nextLiteracyEncounter().skillID, LiteracySkills.visualLetterMatch)
        flower.willLeave()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.flowerGateComplete)
        XCTAssertTrue(state.sunmillAvailable)

        state.travel(to: .wordGarden)
        let awakeGate = WordGardenScene(state: state)
        awakeGate.didMove(to: SKView())
        XCTAssertNotNil(awakeGate.childNode(withName: "sunmillRoute"))
        awakeGate.valkyrie.position = CGPoint(x: 945, y: 175)
        awakeGate.handleTap(at: CGPoint(x: 995, y: 165))
        XCTAssertEqual(state.world, .sunmillCrossing)
        awakeGate.willLeave()

        let sunmill = WordGardenScene(state: state)
        sunmill.didMove(to: SKView())
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillWheel"))
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillWater"))
        XCTAssertNotNil(sunmill.childNode(withName: "targetRune"))
        XCTAssertTrue(sunmill.childNode(withName: "sunmillBridge")?.isHidden == true)
        XCTAssertEqual(sunmill.children.filter { $0.name == "sunmillChoice" }.count, 4)
        XCTAssertEqual(
            state.nextSunmillEncounter()?.mechanicID,
            WordGardenMechanicID.sunmillPair
        )
        sunmill.willLeave()

        for encounter in WordGardenEncounterCatalog.sunmillVisualShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.sunmillComplete)
        XCTAssertTrue(state.storyHollowAvailable)

        let awakeSunmill = WordGardenScene(state: state)
        awakeSunmill.didMove(to: SKView())
        XCTAssertFalse(awakeSunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true)
        XCTAssertNotNil(awakeSunmill.childNode(withName: "storyHollowRoute"))
        awakeSunmill.valkyrie.position = CGPoint(x: 1015, y: 175)
        awakeSunmill.handleTap(at: CGPoint(x: 1010, y: 165))
        XCTAssertEqual(state.world, .storyHollow)
        awakeSunmill.willLeave()

        let hollow = WordGardenScene(state: state)
        hollow.didMove(to: SKView())
        XCTAssertNotNil(hollow.childNode(withName: "storyHollow"))
        XCTAssertNotNil(hollow.childNode(withName: "wordSeed"))
        XCTAssertNotNil(hollow.childNode(withName: "storySequencePreview"))
        XCTAssertEqual(hollow.children.filter { $0.name == "storyHollowChoice" }.count, 4)
        XCTAssertEqual(
            state.nextStoryHollowEncounter()?.skillID,
            LiteracySkills.visualPrintSequence
        )
        hollow.willLeave()

        for encounter in WordGardenEncounterCatalog.storyHollowSequence {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        XCTAssertTrue(state.storyHollowComplete)
        XCTAssertTrue(state.hasStoryReward(.wordGardenLantern))
        XCTAssertFalse(
            state.hasStoryReward(.moonLantern),
            "Word Garden completion must not unlock Math Castle's reward."
        )
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(state.profile.progress(for: LiteracySkills.decodeCVC).state, .new)

        let restoredHollow = WordGardenScene(state: state)
        restoredHollow.didMove(to: SKView())
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyBloom"))
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyTreeReturn"))
        restoredHollow.handleTap(at: CGPoint(x: 1005, y: 165))
        XCTAssertEqual(state.world, .storyTree)
        restoredHollow.willLeave()

        let restoredState = try AppState(context: ModelContext(container))
        XCTAssertTrue(restoredState.hasStoryReward(.wordGardenLantern))
        XCTAssertFalse(restoredState.hasStoryReward(.moonLantern))
        XCTAssertEqual(restoredState.world, .storyTree)

        let restoredTree = StoryTreeScene(state: restoredState)
        restoredTree.didMove(to: SKView())
        XCTAssertNotNil(restoredTree.childNode(withName: "wordGardenLantern"))
        XCTAssertNil(restoredTree.childNode(withName: "moonLantern"))
        restoredTree.willLeave()
    }

    func testPuzzlePalaceRuneGateRoutesFromStoryTreeAndPersistsEvidence() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        let story = StoryTreeScene(state: state)
        story.didMove(to: SKView())
        XCTAssertNotNil(story.childNode(withName: "puzzlePalace"))
        story.valkyrie.position = CGPoint(x: 580, y: 450)
        story.handleTap(at: CGPoint(x: 505, y: 515))
        XCTAssertEqual(state.world, .puzzlePalace)
        story.willLeave()

        let palace = PuzzlePalaceScene(state: state)
        palace.reducedMotion = true
        palace.didMove(to: SKView())
        XCTAssertNotNil(palace.childNode(withName: "puzzleGate"))
        XCTAssertNotNil(palace.childNode(withName: "runeBoard"))
        XCTAssertNotNil(palace.childNode(withName: "//runeSocket"))
        XCTAssertEqual(palace.children.filter { $0.name == "runeChoice" }.count, 3)
        XCTAssertEqual(
            state.nextPuzzleEncounter().skillID,
            PuzzleSkills.visualPatternContinue
        )
        XCTAssertFalse(state.puzzleRuneGateComplete)

        let first = state.nextPuzzleEncounter()
        _ = state.recordPuzzle(
            first,
            outcome: .correct,
            support: .independent,
            attempts: 1,
            responseTime: 1
        )
        XCTAssertEqual(
            PuzzlePalaceDirector.runeGateIndependentSuccessCount(profile: state.profile),
            1
        )
        palace.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .puzzlePalace)
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.visualPatternContinue).evidence.count,
            1
        )
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.visualSequenceMemory).state,
            .new
        )

        for encounter in PuzzlePalaceEncounterCatalog.runeGate.dropFirst() {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleRuneGateComplete)

        let openPalace = PuzzlePalaceScene(state: restored)
        openPalace.reducedMotion = true
        openPalace.didMove(to: SKView())
        XCTAssertEqual(openPalace.children.filter { $0.name == "runeChoice" }.count, 0)
        let gate = try XCTUnwrap(openPalace.childNode(withName: "puzzleGate") as? SKShapeNode)
        XCTAssertEqual(gate.glowWidth, 16)
        XCTAssertNotNil(openPalace.childNode(withName: "memoryBridgeRoute"))
        openPalace.valkyrie.position = CGPoint(x: 1005, y: 175)
        openPalace.handleTap(at: CGPoint(x: 1005, y: 165))
        XCTAssertEqual(restored.world, .memoryBridge)
        openPalace.willLeave()

        let memory = PuzzlePalaceScene(state: restored)
        memory.reducedMotion = true
        memory.didMove(to: SKView())
        XCTAssertNotNil(memory.childNode(withName: "memoryChasm"))
        XCTAssertEqual(memory.children.filter { $0.name == "memoryPad" }.count, 4)
        XCTAssertEqual(
            restored.nextPuzzleMemoryEncounter()?.skillID,
            PuzzleSkills.visualSequenceMemory
        )
        XCTAssertFalse(restored.puzzleMemoryBridgeComplete)
        memory.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleMemoryBridgeComplete)

        let restoredMemory = PuzzlePalaceScene(state: restored)
        restoredMemory.reducedMotion = true
        restoredMemory.didMove(to: SKView())
        XCTAssertNotNil(restoredMemory.childNode(withName: "memoryBridgeRestored"))
        XCTAssertEqual(restoredMemory.children.filter { $0.name == "memoryPad" }.count, 0)
        XCTAssertNotNil(restoredMemory.childNode(withName: "stopGoRoute"))
        restoredMemory.valkyrie.position = CGPoint(x: 1000, y: 175)
        restoredMemory.handleTap(at: CGPoint(x: 1000, y: 165))
        XCTAssertEqual(restored.world, .stopGoOrbs)
        restoredMemory.willLeave()

        let stopGo = PuzzlePalaceScene(state: restored)
        stopGo.reducedMotion = true
        stopGo.didMove(to: SKView())
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoOrb"))
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoBarrier"))
        XCTAssertEqual(
            restored.nextPuzzleStopGoEncounter()?.skillID,
            PuzzleSkills.responseInhibition
        )
        XCTAssertFalse(restored.puzzleStopGoComplete)
        stopGo.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleStopGoComplete)

        let restoredStopGo = PuzzlePalaceScene(state: restored)
        restoredStopGo.reducedMotion = true
        restoredStopGo.didMove(to: SKView())
        XCTAssertNotNil(restoredStopGo.childNode(withName: "stopGoBarrierOpen"))
        XCTAssertNotNil(restoredStopGo.childNode(withName: "sortingPedestalRoute"))
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.ruleSwitching).state,
            .new
        )
        restoredStopGo.valkyrie.position = CGPoint(x: 1000, y: 175)
        restoredStopGo.handleTap(at: CGPoint(x: 1000, y: 165))
        XCTAssertEqual(restored.world, .sortingPedestal)
        restoredStopGo.willLeave()

        let sorting = PuzzlePalaceScene(state: restored)
        sorting.reducedMotion = true
        sorting.didMove(to: SKView())
        XCTAssertNotNil(sorting.childNode(withName: "sortingRuleDial"))
        XCTAssertNotNil(sorting.childNode(withName: "sortLeftPedestal"))
        XCTAssertNotNil(sorting.childNode(withName: "sortRightPedestal"))
        XCTAssertEqual(
            restored.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.singleRuleSort
        )
        XCTAssertFalse(restored.puzzleSortingFoundationComplete)
        sorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleSortingFoundationComplete)
        XCTAssertEqual(
            restored.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.ruleSwitching
        )

        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleRuleSwitchingComplete)
        XCTAssertTrue(restored.puzzleSortingPedestalComplete)
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .new
        )

        let stableSorting = PuzzlePalaceScene(state: restored)
        stableSorting.reducedMotion = true
        stableSorting.didMove(to: SKView())
        let dial = try XCTUnwrap(
            stableSorting.childNode(withName: "sortingRuleDial") as? SKShapeNode
        )
        XCTAssertEqual(dial.glowWidth, 14)
        stableSorting.handleTap(at: CGPoint(x: 52, y: 669))
        XCTAssertEqual(restored.world, .storyTree)
        stableSorting.willLeave()
    }

    func testFlowerGateCompletionStopsPreviewOnRestore() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            state.recordLiteracy(encounter, outcome: .correct, support: .independent,
                                 attempts: 1, responseTime: 1)
        }
        let garden = WordGardenScene(state: state)
        garden.didMove(to: SKView())
        XCTAssertNil(garden.action(forKey: "wordGardenPreview"))
        XCTAssertTrue(garden.childNode(withName: "targetRune") == nil || garden.childNode(withName: "targetRune")?.isHidden == true)
        garden.handleTap(at: CGPoint(x: 675, y: 228))
        XCTAssertNil(garden.action(forKey: "wordGardenPreview"))
        XCTAssertEqual(state.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.count, 3)
        garden.willLeave()
    }

    func testFlowerGateRepeatedTapsAndExitCannotRecordStaleEvidence() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.travel(to: .wordGarden)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view; window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let garden = WordGardenScene(state: state)
        view.presentScene(garden)
        try await Task.sleep(for: .seconds(1.5))
        garden.handleTap(at: CGPoint(x: 675, y: 228))
        let firstTravel = garden.valkyrie.action(forKey: "travel")
        XCTAssertNotNil(firstTravel)
        garden.handleTap(at: CGPoint(x: 505, y: 193))
        XCTAssertTrue(garden.valkyrie.action(forKey: "travel") === firstTravel)
        garden.handleTap(at: CGPoint(x: 52, y: 669))
        XCTAssertEqual(state.world, .storyTree)
        try await Task.sleep(for: .seconds(2))
        XCTAssertTrue(state.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.isEmpty)
    }

    func testRuneGateIgnoresRapidSecondChoiceWhileActorsResolveFirstChoice() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true
        state.travel(to: .puzzlePalace)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = state.nextPuzzleEncounter()
        scene.handleTap(at: CGPoint(x: 770, y: 235))
        scene.handleTap(at: CGPoint(x: 575, y: 255))
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let evidence = state.profile
            .progress(for: PuzzleSkills.visualPatternContinue)
            .evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
    }

    func testMemoryBridgeCanBeCompletedThroughLiveRunePadInteraction() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        state.travel(to: .memoryBridge)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = try XCTUnwrap(state.nextPuzzleMemoryEncounter())
        try await Task.sleep(nanoseconds: 2_400_000_000)
        for point in [
            CGPoint(x: 505, y: 210),
            CGPoint(x: 665, y: 250),
            CGPoint(x: 825, y: 210)
        ] {
            scene.handleTap(at: point)
            try await Task.sleep(nanoseconds: 350_000_000)
        }
        try await Task.sleep(nanoseconds: 500_000_000)

        let evidence = state.profile.progress(for: PuzzleSkills.visualSequenceMemory).evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
    }

    func testStopGoOrbsRejectHoldTapAndAcceptLiveGoTiming() async throws {
        func prepareState() throws -> AppState {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            state.reducedMotion = true
            for encounter in PuzzlePalaceEncounterCatalog.runeGate {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            state.travel(to: .stopGoOrbs)
            return state
        }

        do {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let state = try prepareState()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            try await Task.sleep(nanoseconds: 350_000_000)
            scene.handleTap(at: CGPoint(x: 755, y: 365))
            try await Task.sleep(nanoseconds: 350_000_000)

            let evidence = state.profile.progress(for: PuzzleSkills.responseInhibition).evidence
            XCTAssertEqual(evidence.count, 1)
            XCTAssertEqual(evidence.first?.outcome, .incorrect)
            XCTAssertEqual(evidence.first?.supportLevel, .independent)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        do {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let state = try prepareState()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            let encounter = try XCTUnwrap(state.nextPuzzleStopGoEncounter())
            try await Task.sleep(nanoseconds: 1_350_000_000)
            scene.handleTap(at: CGPoint(x: 755, y: 365))
            try await Task.sleep(nanoseconds: 1_250_000_000)
            scene.handleTap(at: CGPoint(x: 755, y: 365))
            try await Task.sleep(nanoseconds: 500_000_000)

            let evidence = state.profile.progress(for: PuzzleSkills.responseInhibition).evidence
            XCTAssertEqual(evidence.count, 1)
            XCTAssertEqual(evidence.first?.encounterID, encounter.id)
            XCTAssertEqual(evidence.first?.outcome, .correct)
            XCTAssertEqual(evidence.first?.supportLevel, .independent)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
    }

    func testSortingPedestalRunsStableAndSwitchingRulesThroughLivePedestals() async throws {
        func prepareState(includeFoundation: Bool) throws -> AppState {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            state.reducedMotion = true
            for encounter in PuzzlePalaceEncounterCatalog.runeGate {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            if includeFoundation {
                for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
                    _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
                }
            }
            state.travel(to: .sortingPedestal)
            return state
        }

        func run(_ points: [CGPoint], state: AppState) async throws {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            try await Task.sleep(nanoseconds: 350_000_000)
            for point in points {
                scene.handleTap(at: point)
                try await Task.sleep(nanoseconds: 250_000_000)
            }
            try await Task.sleep(nanoseconds: 450_000_000)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let left = CGPoint(x: 530, y: 355)
        let right = CGPoint(x: 970, y: 355)

        let foundationState = try prepareState(includeFoundation: false)
        let foundationEncounter = try XCTUnwrap(foundationState.nextPuzzleSortingEncounter())
        XCTAssertEqual(foundationEncounter.skillID, PuzzleSkills.singleRuleSort)
        try await run([left, right, left, right], state: foundationState)
        let foundationEvidence = foundationState.profile
            .progress(for: PuzzleSkills.singleRuleSort)
            .evidence
        XCTAssertEqual(foundationEvidence.count, 1)
        XCTAssertEqual(foundationEvidence.first?.encounterID, foundationEncounter.id)
        XCTAssertEqual(foundationEvidence.first?.supportLevel, .independent)

        let switchState = try prepareState(includeFoundation: true)
        let switchEncounter = try XCTUnwrap(switchState.nextPuzzleSortingEncounter())
        XCTAssertEqual(switchEncounter.skillID, PuzzleSkills.ruleSwitching)
        try await run([left, right, right, left], state: switchState)
        let switchEvidence = switchState.profile
            .progress(for: PuzzleSkills.ruleSwitching)
            .evidence
        XCTAssertEqual(switchEvidence.count, 1)
        XCTAssertEqual(switchEvidence.first?.encounterID, switchEncounter.id)
        XCTAssertEqual(switchEvidence.first?.supportLevel, .independent)
    }

    func testMirrorHallRecordsSpatialOrientationThroughLiveMirrorChoice() async throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleMirrorHallAvailable)
        state.travel(to: .mirrorHall)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = try XCTUnwrap(state.nextPuzzleMirrorHallEncounter())
        let choice = try XCTUnwrap(
            scene.children
                .compactMap { $0 as? SKShapeNode }
                .first {
                    $0.name == "mirrorOrientationChoice"
                        && ($0.userData?["direction"] as? String) == encounter.target.rawValue
                }
        )
        scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
        scene.handleTap(at: choice.position)

        let evidence = state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).state, .new)
    }

    private func finishMirrorPracticeIfNeeded(_ scene: PuzzlePalaceScene) throws {
        if let dial = scene.childNode(withName: "mirrorPracticeDial") {
            scene.valkyrie.position = CGPoint(x: 580, y: 175)
            scene.handleTap(at: dial.position)
            let ready = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeContinue"))
            scene.handleTap(at: ready.position)
        }
    }

    func testMirrorApproachSurvivesStrayFloorAndRepeatedTaps() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        let dial = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeDial"))
        scene.handleTap(at: dial.position)
        scene.handleTap(at: CGPoint(x: 140, y: 145))
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let ready = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeContinue"))
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        scene.handleTap(at: ready.position)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let index = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
            $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == index
        })
        scene.handleTap(at: choice.position)
        scene.handleTap(at: CGPoint(x: 140, y: 145))
        scene.handleTap(at: choice.position)
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.first?.outcome, .correct)
        XCTAssertNotNil(scene.childNode(withName: "mirrorNext"))
    }

    func testMirrorPracticeIsUnscoredAndSuccessWaitsForChild() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        XCTAssertNotNil(scene.childNode(withName: "mirrorPracticeDial"))
        XCTAssertFalse(scene.children.contains { $0.name == "mirrorRotationChoice" })
        try finishMirrorPracticeIfNeeded(scene)
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let index = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
            $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == index
        })
        scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
        scene.handleTap(at: choice.position)
        let next = try XCTUnwrap(scene.childNode(withName: "mirrorNext"))
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
        XCTAssertEqual(scene.childNode(withName: "mirrorBeam0")?.alpha, 1)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNotNil(scene.childNode(withName: "mirrorNext"))
        XCTAssertEqual(choice.parent, scene)
        scene.handleTap(at: next.position)
        XCTAssertNil(scene.childNode(withName: "mirrorNext"))
        XCTAssertNil(choice.parent)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
    }

    func testMirrorRotationLiveChoicesKeepHintedEvidenceSeparate() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        try finishMirrorPracticeIfNeeded(scene)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let options = scene.children.compactMap { $0 as? SKShapeNode }
            .filter { $0.name == "mirrorRotationChoice" }
        XCTAssertEqual(options.count, 3)
        XCTAssertNotNil(scene.childNode(withName: "mirrorRotationSource"))
        let correctIndex = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let wrong = try XCTUnwrap(options.first { ($0.userData?["choiceIndex"] as? Int) != correctIndex })
        scene.valkyrie.position = CGPoint(x: wrong.position.x - 180, y: 175)
        scene.handleTap(at: wrong.position)
        scene.valkyrie.position = CGPoint(x: wrong.position.x - 180, y: 175)
        scene.handleTap(at: wrong.position)
        let correct = try XCTUnwrap(options.first { ($0.userData?["choiceIndex"] as? Int) == correctIndex })
        scene.valkyrie.position = CGPoint(x: correct.position.x - 180, y: 175)
        scene.handleTap(at: correct.position)
        let evidence = state.profile.progress(for: PuzzleSkills.mentalRotation).evidence
        XCTAssertEqual(evidence.map(\.outcome), [.incorrect, .incorrect, .correct])
        XCTAssertEqual(evidence.map(\.supportLevel), [.independent, .lightHint, .demonstration])
        XCTAssertEqual(evidence.last?.attempts, 3)
        let retry = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        XCTAssertNotEqual(retry.id, encounter.id)
        XCTAssertNotEqual(retry.answer, encounter.answer)
        XCTAssertNotEqual(retry.choices.firstIndex(of: retry.answer), correctIndex)
        XCTAssertEqual(PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: state.profile), 0)
        XCTAssertFalse(state.puzzleMirrorRotationComplete)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count, 3)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
    }

    func testMirrorRotationIndependentCompletionRestoresFromLocalSave() async throws {
        let context = ModelContext(try LearningStore.container(inMemory: true))
        let state = try AppState(context: context)
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)
            try finishMirrorPracticeIfNeeded(scene)
            XCTAssertEqual(state.nextPuzzleMirrorRotationEncounter()?.id, encounter.id)
            let correctIndex = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
            let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
                $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == correctIndex
            })
            scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
            scene.handleTap(at: choice.position)
            scene.willLeave()
        }
        XCTAssertTrue(state.puzzleMirrorRotationComplete)
        let restored = try AppState(context: context)
        XCTAssertTrue(restored.puzzleMirrorRotationComplete)
        XCTAssertEqual(restored.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 3)
        XCTAssertEqual(restored.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        restored.travel(to: .mirrorHall)
        let completeScene = PuzzlePalaceScene(state: restored)
        view.presentScene(completeScene)
        XCTAssertFalse(completeScene.children.contains { $0.name == "mirrorRotationChoice" })
        completeScene.willLeave()
    }

    func testRenderedNativeSceneReviewAttachments() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view; window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        let home = StoryTreeScene(state: state); home.reducedMotion = true
        view.presentScene(home)
        try await capture(home, in: view, name: "Story-Tree-native")
        home.handleTap(at: CGPoint(x: 835, y: 535))
        // Exercise the painted waypoint route before the arrival capture.
        try await Task.sleep(nanoseconds: 3_000_000_000)
        XCTAssertTrue(home.isNear(CGPoint(x: 795, y: 450)))
        try await capture(home, in: view, name: "Story-Tree-native-castle-arrival")
        home.willLeave()

        state.travel(to: .wordGarden)
        let garden = WordGardenScene(state: state)
        garden.reducedMotion = true
        view.presentScene(garden)
        try await capture(garden, in: view, name: "Word-Garden-native-flower-gate")
        // Review the playable choice state as well as the brief rune preview.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(garden.childNode(withName: "targetRune")?.isHidden == true)
        try await capture(garden, in: view, name: "Word-Garden-native-flower-choices")
        garden.willLeave()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        state.travel(to: .sunmillCrossing)
        let sunmill = WordGardenScene(state: state)
        sunmill.reducedMotion = true
        view.presentScene(sunmill)
        try await capture(sunmill, in: view, name: "Word-Garden-native-sunmill")
        sunmill.willLeave()

        for encounter in WordGardenEncounterCatalog.sunmillVisualShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let awakeSunmill = WordGardenScene(state: state)
        awakeSunmill.reducedMotion = true
        view.presentScene(awakeSunmill)
        try await capture(awakeSunmill, in: view, name: "Word-Garden-native-sunmill-awake")
        XCTAssertFalse(awakeSunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true)
        XCTAssertNotNil(awakeSunmill.childNode(withName: "storyHollowRoute"))
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
        awakeSunmill.willLeave()

        state.travel(to: .storyHollow)
        let hollow = WordGardenScene(state: state)
        hollow.reducedMotion = true
        view.presentScene(hollow)
        try await capture(hollow, in: view, name: "Word-Garden-native-story-hollow")
        hollow.willLeave()

        for encounter in WordGardenEncounterCatalog.storyHollowSequence {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let restoredHollow = WordGardenScene(state: state)
        restoredHollow.reducedMotion = true
        view.presentScene(restoredHollow)
        try await capture(
            restoredHollow,
            in: view,
            name: "Word-Garden-native-story-hollow-restored"
        )
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyBloom"))
        XCTAssertTrue(state.hasStoryReward(.wordGardenLantern))
        restoredHollow.willLeave()

        state.travel(to: .storyTree)
        let rewardTree = StoryTreeScene(state: state)
        rewardTree.reducedMotion = true
        view.presentScene(rewardTree)
        try await capture(
            rewardTree,
            in: view,
            name: "Story-Tree-native-word-garden-lantern"
        )
        XCTAssertNotNil(rewardTree.childNode(withName: "wordGardenLantern"))
        rewardTree.willLeave()

        state.travel(to: .scienceLab)
        let science = ScienceLabScene(state: state); science.reducedMotion = true
        view.presentScene(science)
        science.valkyrie.position = CGPoint(x: 565, y: 185)
        science.handleTap(at: CGPoint(x: 685, y: 235))
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-dry")
        science.valkyrie.position = CGPoint(x: 500, y: 180)
        science.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(science.greenhouseStage, .watered)
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-sprout")
        science.valkyrie.position = CGPoint(x: 850, y: 185)
        science.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertTrue(science.greenhouseComplete)
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-complete")
        science.willLeave()

        let weather = WeatherTowerScene(state: state); weather.reducedMotion = true
        view.presentScene(weather)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-arrival")
        weather.valkyrie.position = CGPoint(x: 370, y: 180)
        weather.handleTap(at: CGPoint(x: 470, y: 305))
        weather.valkyrie.position = CGPoint(x: 605, y: 180)
        weather.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(weather.weatherStage, .afternoonObserved)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-compared")
        weather.valkyrie.position = CGPoint(x: 825, y: 180)
        weather.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertTrue(weather.creatureRouteOpen)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-route-open")
        weather.willLeave()

        let grove = CreatureGroveScene(state: state); grove.reducedMotion = true
        view.presentScene(grove)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-arrival")
        grove.valkyrie.position = CGPoint(x: 245, y: 180)
        grove.handleTap(at: CGPoint(x: 335, y: 270))
        grove.valkyrie.position = CGPoint(x: 610, y: 180)
        grove.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(grove.groveStage, .habitatMatched)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-habitat")
        grove.valkyrie.position = CGPoint(x: 750, y: 180)
        grove.handleTap(at: CGPoint(x: 840, y: 290))
        XCTAssertEqual(grove.groveStage, .bodyPartObserved)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-body-part")
        grove.valkyrie.position = CGPoint(x: 920, y: 180)
        grove.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertTrue(grove.groveRestored)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-restored")
        grove.willLeave()

        state.travel(to: .puzzlePalace)
        let palace = PuzzlePalaceScene(state: state)
        palace.reducedMotion = true
        view.presentScene(palace)
        try await capture(palace, in: view, name: "Puzzle-Palace-native-rune-gate")
        palace.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let openPalace = PuzzlePalaceScene(state: state)
        openPalace.reducedMotion = true
        view.presentScene(openPalace)
        try await capture(
            openPalace,
            in: view,
            name: "Puzzle-Palace-native-rune-gate-open"
        )
        XCTAssertTrue(state.puzzleRuneGateComplete)
        XCTAssertEqual(openPalace.children.filter { $0.name == "runeChoice" }.count, 0)
        XCTAssertNotNil(openPalace.childNode(withName: "memoryBridgeRoute"))
        openPalace.willLeave()

        state.travel(to: .memoryBridge)
        let memoryBridge = PuzzlePalaceScene(state: state)
        memoryBridge.reducedMotion = true
        view.presentScene(memoryBridge)
        try await capture(
            memoryBridge,
            in: view,
            name: "Puzzle-Palace-native-memory-bridge"
        )
        XCTAssertNotNil(memoryBridge.childNode(withName: "memoryChasm"))
        XCTAssertEqual(memoryBridge.children.filter { $0.name == "memoryPad" }.count, 4)
        memoryBridge.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let restoredMemoryBridge = PuzzlePalaceScene(state: state)
        restoredMemoryBridge.reducedMotion = true
        view.presentScene(restoredMemoryBridge)
        try await capture(
            restoredMemoryBridge,
            in: view,
            name: "Puzzle-Palace-native-memory-bridge-restored"
        )
        XCTAssertTrue(state.puzzleMemoryBridgeComplete)
        XCTAssertNotNil(restoredMemoryBridge.childNode(withName: "memoryBridgeRestored"))
        XCTAssertNotNil(restoredMemoryBridge.childNode(withName: "stopGoRoute"))
        restoredMemoryBridge.willLeave()

        state.travel(to: .stopGoOrbs)
        let stopGo = PuzzlePalaceScene(state: state)
        stopGo.reducedMotion = true
        view.presentScene(stopGo)
        try await capture(
            stopGo,
            in: view,
            name: "Puzzle-Palace-native-stop-go-orbs"
        )
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoOrb"))
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoBarrier"))
        stopGo.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let stableStopGo = PuzzlePalaceScene(state: state)
        stableStopGo.reducedMotion = true
        view.presentScene(stableStopGo)
        try await capture(
            stableStopGo,
            in: view,
            name: "Puzzle-Palace-native-stop-go-orbs-stable"
        )
        XCTAssertTrue(state.puzzleStopGoComplete)
        XCTAssertNotNil(stableStopGo.childNode(withName: "stopGoBarrierOpen"))
        XCTAssertNotNil(stableStopGo.childNode(withName: "sortingPedestalRoute"))
        stableStopGo.willLeave()

        state.travel(to: .sortingPedestal)
        let sorting = PuzzlePalaceScene(state: state)
        sorting.reducedMotion = true
        view.presentScene(sorting)
        try await capture(
            sorting,
            in: view,
            name: "Puzzle-Palace-native-sorting-pedestal"
        )
        XCTAssertNotNil(sorting.childNode(withName: "sortingRuleDial"))
        XCTAssertEqual(
            state.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.singleRuleSort
        )
        sorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let switching = PuzzlePalaceScene(state: state)
        switching.reducedMotion = true
        view.presentScene(switching)
        try await capture(
            switching,
            in: view,
            name: "Puzzle-Palace-native-sorting-rule-switch"
        )
        XCTAssertTrue(state.puzzleSortingFoundationComplete)
        XCTAssertEqual(
            state.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.ruleSwitching
        )
        switching.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let stableSorting = PuzzlePalaceScene(state: state)
        stableSorting.reducedMotion = true
        view.presentScene(stableSorting)
        try await capture(
            stableSorting,
            in: view,
            name: "Puzzle-Palace-native-sorting-pedestal-stable"
        )
        XCTAssertTrue(state.puzzleSortingPedestalComplete)
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .new
        )
        stableSorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        state.travel(to: .mirrorHall)
        let mirrorHall = PuzzlePalaceScene(state: state)
        mirrorHall.reducedMotion = true
        view.presentScene(mirrorHall)
        try await capture(
            mirrorHall,
            in: view,
            name: "Puzzle-Palace-native-mirror-hall"
        )
        XCTAssertTrue(state.puzzleMirrorHallAvailable)
        XCTAssertNil(mirrorHall.childNode(withName: "mirrorHallChamber"),
                     "Mirror Hall should reveal the palace artwork instead of covering it with a modal panel.")
        XCTAssertNotNil(mirrorHall.childNode(withName: "mirrorHallRail"))
        XCTAssertNotNil(mirrorHall.childNode(withName: "mirrorBeacon"))
        let orientationChoices = mirrorHall.children.filter { $0.name == "mirrorOrientationChoice" }
        XCTAssertEqual(orientationChoices.count, 3)
        let actorFrame = mirrorHall.valkyrie.calculateAccumulatedFrame().insetBy(dx: 8, dy: 8)
        for choice in orientationChoices {
            XCTAssertFalse(
                actorFrame.intersects(choice.calculateAccumulatedFrame()),
                "Valkyrie must never obscure a scored mirror choice."
            )
        }
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.mentalRotation).state,
            .new
        )
        mirrorHall.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        let rotationHall = PuzzlePalaceScene(state: state)
        rotationHall.reducedMotion = true
        view.presentScene(rotationHall)
        try await capture(rotationHall, in: view, name: "Puzzle-Palace-native-turn-practice")
        try finishMirrorPracticeIfNeeded(rotationHall)
        try await capture(rotationHall, in: view, name: "Puzzle-Palace-native-mental-rotation")
        let rotationChoices = rotationHall.children.filter { $0.name == "mirrorRotationChoice" }
        XCTAssertEqual(rotationChoices.count, 3)
        let rotationActorFrame = rotationHall.valkyrie.calculateAccumulatedFrame().insetBy(dx: 8, dy: 8)
        for choice in rotationChoices {
            XCTAssertFalse(
                rotationActorFrame.intersects(choice.calculateAccumulatedFrame()),
                "Mental rotation answers must remain visually unobstructed."
            )
        }
        XCTAssertNil(rotationHall.childNode(withName: "rotationQuarterMark0"),
                     "The independent task should use one turn cue, not redundant quarter-dot UI.")
        rotationHall.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        XCTAssertTrue(state.puzzlePathTilesAvailable)
        state.travel(to: .pathTiles)
        let pathTiles = PuzzlePalaceScene(state: state)
        pathTiles.reducedMotion = true
        view.presentScene(pathTiles)
        try await capture(pathTiles, in: view, name: "Puzzle-Palace-native-path-tiles")
        XCTAssertNotNil(pathTiles.childNode(withName: "pathTilesChamber"))
        XCTAssertNotNil(pathTiles.childNode(withName: "pathGrid"))
        XCTAssertEqual(
            pathTiles.children.filter { $0.name?.hasPrefix("pathChoice") == true }.count,
            3
        )
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        pathTiles.willLeave()

        state.travel(to: .mathCastle)
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let castle = MathCastleScene(state: state); castle.reducedMotion = true
        view.presentScene(castle)
        castle.valkyrie.position = CGPoint(x: 490, y: 175); castle.pip.position = CGPoint(x: 385, y: 187)
        castle.handleTap(at: CGPoint(x: 830, y: 265))
        try await capture(castle, in: view, name: "Math-Castle-native-cart")
        for _ in 0..<(state.runtime?.encounter.targetQuantity ?? 0) { castle.handleTap(at: CGPoint(x: 595, y: 235)) }
        castle.handleTap(at: CGPoint(x: 1120, y: 250))
        let reducedBridge = try XCTUnwrap(castle.childNode(withName: "physicalRouteBridge"))
        XCTAssertEqual(reducedBridge.xScale, 1, accuracy: 0.001)
        XCTAssertNil(reducedBridge.action(forKey: "routeOpen"))
        let reducedBeacon = try XCTUnwrap(castle.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertEqual(reducedBeacon.glowWidth, 18)
        try await capture(castle, in: view, name: "Math-Castle-native-powered")
        let cartOrder = state.runtime?.encounter.id
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(castle.crossingBridge)
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await waitForBridgeTravel(castle)
        XCTAssertTrue(castle.isNear(CGPoint(x: 1110, y: 400), radius: 55))
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await capture(castle, in: view, name: "Math-Castle-native-cart-route-landing")
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(castle.crossingBridge)
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await waitForBridgeTravel(castle)
        XCTAssertTrue(castle.isNear(CGPoint(x: 490, y: 175)))
        XCTAssertNotEqual(state.runtime?.encounter.id, cartOrder)
        castle.willLeave()
        let bridgeState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        bridgeState.reducedMotion = true
        XCTAssertTrue(bridgeState.startWorkshop(MathCastleEncounterCatalog.missingNumberBridge[0]))
        let bridge = MathCastleScene(state: bridgeState); bridge.reducedMotion = true
        view.presentScene(bridge)
        bridge.valkyrie.position = CGPoint(x: 490, y: 175)
        bridge.handleTap(at: CGPoint(x: 965, y: 330))
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-gaps")
        for _ in 0..<4 { bridge.drop(origin: "missingSupply", at: CGPoint(x: 884, y: 220)) }
        bridge.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(bridgeState.runtime?.completed == true)
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-repaired")
        let repairedID = bridgeState.runtime?.encounter.id
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        bridge.handleTap(at: CGPoint(x: 1200, y: 430)) // Ignore repeated taps in transit.
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID)
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 1110, y: 400), radius: 55))
        XCTAssertGreaterThan(bridge.pip.position.x, 1000)
        XCTAssertGreaterThan(bridge.pip.position.y, 240)
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID, "Arrival must preserve the solved bridge")
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-landing")
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID, "Keep the deck beneath the actors during the return")
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 490, y: 175)))
        XCTAssertNotEqual(bridgeState.runtime?.encounter.id, repairedID)
        bridge.willLeave()
        for (index, name) in [(0, "Math-Castle-native-scale-unequal"), (2, "Math-Castle-native-scale-equal-selected")] {
            // Visual fixtures use fresh sessions so engagement breaks in the preceding
            // bridge journey cannot refuse the requested scale encounter.
            let scaleState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            scaleState.reducedMotion = true
            XCTAssertTrue(scaleState.startWorkshop(MathCastleEncounterCatalog.balanceScale[index]))
            let scale = MathCastleScene(state: scaleState); scale.reducedMotion = true
            view.presentScene(scale)
            scale.valkyrie.position = CGPoint(x: 490, y: 175); scale.pip.position = CGPoint(x: 385, y: 187)
            scale.handleTap(at: CGPoint(x: 820, y: 350))
            if index == 2 { scale.handleTap(at: CGPoint(x: 820, y: 195)) }
            guard case .balanceScale(let model)? = scaleState.runtime else {
                XCTFail("Scale capture must render the requested mechanic"); continue
            }
            XCTAssertEqual(model.selected, index == 2 ? .equal : nil)
            try await capture(scale, in: view, name: name)
            scale.willLeave()
        }
        for (capacity, name) in [(false, "Math-Castle-native-bond"), (true, "Math-Castle-native-bond-capacity")] {
            let bondState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            bondState.reducedMotion = true
            let encounter = capacity ? LearningEncounter(id: "bond-visual-capacity", skillID: MathSkills.bonds10,
                mechanicID: MathMechanicID.numberBondMachine, operation: .numberBond,
                initialQuantity: 19, targetQuantity: 20, prompt: "Inspect the crystal chambers")
                : MathCastleEncounterCatalog.numberBondMachine[0]
            XCTAssertTrue(bondState.startWorkshop(encounter))
            let bond = MathCastleScene(state: bondState); bond.reducedMotion = true
            view.presentScene(bond)
            bond.valkyrie.position = CGPoint(x: 490, y: 175); bond.pip.position = CGPoint(x: 385, y: 187)
            bond.handleTap(at: CGPoint(x: 820, y: 392))
            if !capacity { try await capture(bond, in: view, name: name + "-empty") }
            for _ in 0..<(capacity ? 20 : encounter.targetQuantity - encounter.initialQuantity) {
                bond.drop(origin: "bondSupply", at: CGPoint(x: 925, y: 280))
            }
            guard case .numberBond(let model)? = bondState.runtime else {
                XCTFail("Bond capture must render the requested mechanic"); continue
            }
            XCTAssertEqual(model.selectedPart, capacity ? 20 : model.correctMissingPart)
            try await capture(bond, in: view, name: name + "-filled")
            bond.willLeave()
        }
    }

    private func waitForBridgeTravel(_ scene: MathCastleScene) async throws {
        let deadline = Date().addingTimeInterval(10)
        while scene.crossingBridge && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(scene.crossingBridge, "Bridge route did not finish within ten seconds")
    }

    private func capture(_ scene: AdventureScene, in view: SKView, name: String) async throws {
        // Let SpriteKit render an actual frame on the simulator, not a mock composition.
        try await Task.sleep(nanoseconds: 300_000_000)
        let texture = try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: scene.size)))
        let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testMathQuestionRendersAboveManipulativeAndFeedbackStaysBelow() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let encounter = MathCastleEncounterCatalog.numberBondMachine[0]
        XCTAssertTrue(state.startWorkshop(encounter))

        let scene = MathCastleScene(state: state)
        scene.didMove(to: SKView())
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 925, y: 280))

        let prompt = try XCTUnwrap(scene.childNode(withName: "questionPrompt") as? SKLabelNode)
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)

        XCTAssertFalse(prompt.isHidden)
        XCTAssertTrue(prompt.text?.contains(encounter.prompt) == true)
        XCTAssertGreaterThan(prompt.position.y, 500)
        XCTAssertLessThan(feedback.position.y, 100)
        XCTAssertGreaterThan(prompt.position.y, feedback.position.y)

        scene.willLeave()
    }


    func testWordGardenVisualEvidencePersistsWithoutCreatingSpokenLetterMastery() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .wordGarden)

        let encounter = state.nextLiteracyEncounter()
        let wrong = try XCTUnwrap(encounter.choices.first { $0 != encounter.answer })
        let first = state.recordLiteracy(
            encounter,
            outcome: .incorrect,
            support: .independent,
            attempts: 1,
            responseTime: 1.4
        )
        XCTAssertEqual(first.supportLevel, .independent)

        let corrected = state.recordLiteracy(
            encounter,
            outcome: .correct,
            support: .lightHint,
            attempts: 2,
            responseTime: 2.8
        )
        XCTAssertEqual(corrected.outcome, .correct)
        XCTAssertTrue(state.profile.usedFingerprints.contains(encounter.fingerprint))

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .wordGarden)
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.count,
            2
        )
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.visualLetterMatch).state,
            .learning
        )
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertNotEqual(wrong, encounter.answer)
    }

    func testIncorrectMathAnswerKeepsPhysicalRouteClosed() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let encounter = MathCastleEncounterCatalog.balanceScale[0]
        XCTAssertTrue(state.startWorkshop(encounter))

        let scene = MathCastleScene(state: state)
        scene.didMove(to: SKView())
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))

        // 5 vs 8: left is deliberately incorrect.
        scene.handleTap(at: CGPoint(x: 670, y: 265))
        scene.handleTap(at: CGPoint(x: 1120, y: 250))

        XCTAssertFalse(state.runtime?.completed == true)
        let bridge = try XCTUnwrap(scene.childNode(withName: "physicalRouteBridge"))
        XCTAssertEqual(bridge.xScale, 0.06, accuracy: 0.001)
        XCTAssertNil(bridge.action(forKey: "routeOpen"))

        let beacon = try XCTUnwrap(scene.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertEqual(beacon.glowWidth, 0)
        scene.willLeave()
    }


    func testLandscapeIPadAspectFitKeepsTheDesignCanvasFullyVisible() {
        let layout = AdventureSceneLayout(size: CGSize(width: 1280, height: 720))
        let landscapeSurfaces = [
            CGSize(width: 1024, height: 768),   // classic 4:3 iPad
            CGSize(width: 1180, height: 820),   // modern 10.9-inch class
            CGSize(width: 1366, height: 1024),  // large 4:3 class
            CGSize(width: 1280, height: 720)    // screenshot/reference surface
        ]

        for surface in landscapeSurfaces {
            let frame = layout.fittedFrame(in: surface)
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertGreaterThanOrEqual(frame.minX, -0.001)
            XCTAssertGreaterThanOrEqual(frame.minY, -0.001)
            XCTAssertLessThanOrEqual(frame.maxX, surface.width + 0.001)
            XCTAssertLessThanOrEqual(frame.maxY, surface.height + 0.001)
            XCTAssertEqual(frame.width / frame.height, 1280.0 / 720.0, accuracy: 0.001)
        }
    }

    func testReducedMotionSuppressesDecorativeEntranceAndLandmarkPulsing() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        XCTAssertFalse(scene.valkyrie.hasActions())
        XCTAssertFalse(scene.pip.hasActions())
        let castle = try XCTUnwrap(scene.childNode(withName: "castle"))
        let halo = try XCTUnwrap(castle.children.compactMap { $0 as? SKShapeNode }.first)
        XCTAssertFalse(halo.hasActions(), "Reduced motion must disable landmark pulsing.")
    }

    func testSharedHUDAndPromptTextStayInsideSafeDesignBounds() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let title = try XCTUnwrap(scene.childNode(withName: "worldTitle") as? SKLabelNode)
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)
        XCTAssertTrue(CGRect(origin: .zero, size: scene.size).contains(title.position))
        XCTAssertTrue(CGRect(origin: .zero, size: scene.size).contains(feedback.position))
        XCTAssertLessThanOrEqual(feedback.preferredMaxLayoutWidth, scene.layout.instructionZone.width)

        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        let prompt = try XCTUnwrap(scene.childNode(withName: "questionPrompt") as? SKLabelNode)
        XCTAssertEqual(prompt.numberOfLines, 2)
        XCTAssertLessThanOrEqual(prompt.preferredMaxLayoutWidth, 440)
    }

}
