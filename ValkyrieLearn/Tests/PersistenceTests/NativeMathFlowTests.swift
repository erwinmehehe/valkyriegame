import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeMathFlowTests: XCTestCase {
    func testEveryMachineAcknowledgesTheVisibleEditWithoutCheckingTheAnswer() throws {
        let placeValue = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.placeValue).first?.encounter
        )
        let pattern = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.patternAB).first?.encounter
        )
        let shape = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.recognizeShapes).first?.encounter
        )
        let cases: [(LearningEncounter, CGPoint, CGPoint, String)] = [
            (MathFoundation.workshopExamples[0], CGPoint(x: 830, y: 265), CGPoint(x: 595, y: 235), "1 crystal in the cart."),
            (MathCastleEncounterCatalog.balanceScale[0], CGPoint(x: 670, y: 286), CGPoint(x: 670, y: 286), "Left pan selected."),
            (MathCastleEncounterCatalog.numberBondMachine[0], CGPoint(x: 925, y: 280), CGPoint(x: 555, y: 280), "1 crystal in the open part."),
            (MathCastleEncounterCatalog.tenFrameGate[0], CGPoint(x: 820, y: 344), CGPoint(x: 550, y: 310), "1 light placed."),
            (MathCastleEncounterCatalog.missingNumberBridge[0], CGPoint(x: 965, y: 330), CGPoint(x: 550, y: 335), "1 plank added."),
            (placeValue, CGPoint(x: 820, y: 310), CGPoint(x: 642, y: 192), "1 tens and 0 ones make 10."),
            (pattern, CGPoint(x: 820, y: 310), CGPoint(x: 660, y: 188), "A shape fills the pattern gap."),
            (shape, CGPoint(x: 820, y: 310), CGPoint(x: 662, y: 290), "Shape option 1 selected.")
        ]
        for (encounter, machine, input, message) in cases {
            let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            XCTAssertTrue(state.startWorkshop(encounter))
            let scene = MathCastleScene(state: state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())
            scene.valkyrie.position = CGPoint(x: 490, y: 175)
            scene.handleTap(at: machine)
            let profile = state.profile
            scene.handleTap(at: input)
            XCTAssertEqual(scene.instruction.text, message + " Pull Pip's lever when you're ready.")
            XCTAssertNotNil(scene.pip.action(forKey: "operation"))
            XCTAssertFalse(scene.pip.bodyNode.hasActions())
            XCTAssertFalse(state.runtime?.completed == true)
            XCTAssertEqual(state.runtime?.support, .independent)
            XCTAssertEqual(state.profile, profile, "Acknowledging an edit must not award learning evidence.")
            scene.willLeave()
        }
    }

    func testCartLimitDoesNotReplayPipReactionAndDragFeedbackMatchesTapFeedback() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let scene = MathCastleScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        for _ in 0..<12 { scene.handleTap(at: CGPoint(x: 595, y: 235)) }
        let runtime = state.runtime
        let reaction = try XCTUnwrap(scene.pip.action(forKey: "operation"))
        scene.handleTap(at: CGPoint(x: 595, y: 235))
        XCTAssertEqual(state.runtime, runtime)
        XCTAssertTrue(scene.pip.action(forKey: "operation") === reaction)
        XCTAssertEqual(scene.instruction.text, "No change yet. Try another move, or pull Pip's lever.")
        scene.drop(origin: "supply", at: CGPoint(x: 830, y: 265))
        XCTAssertEqual(state.runtime, runtime)
        XCTAssertTrue(scene.pip.action(forKey: "operation") === reaction)
        scene.drop(origin: "cartCrystal", at: CGPoint(x: 595, y: 235))
        XCTAssertEqual(scene.instruction.text, "11 crystals in the cart. Pull Pip's lever when you're ready.")
        scene.handleTap(at: CGPoint(x: 595, y: 235))
        XCTAssertEqual(scene.instruction.text, "12 crystals in the cart. Pull Pip's lever when you're ready.")
    }

    func testRetryLightIsVisibleWithoutMotionAndCannotDimAQuickSuccess() throws {
        for reduced in [false, true] {
            let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
            let scene = MathCastleScene(state: state)
            scene.reducedMotion = reduced
            scene.didMove(to: SKView())
            scene.valkyrie.position = CGPoint(x: 490, y: 175)
            scene.handleTap(at: CGPoint(x: 830, y: 265))
            scene.handleTap(at: CGPoint(x: 1120, y: 250))
            let light = try XCTUnwrap(scene.childNode(withName: "castlePowerLight") as? SKShapeNode)
            XCTAssertEqual(light.glowWidth, 5)
            XCTAssertNotNil(light.action(forKey: "gentleRetry"))
            let target = try XCTUnwrap(state.runtime?.encounter.targetQuantity)
            for _ in 0..<target { scene.handleTap(at: CGPoint(x: 595, y: 235)) }
            scene.handleTap(at: CGPoint(x: 1120, y: 250))
            XCTAssertTrue(state.runtime?.completed == true)
            XCTAssertEqual(light.glowWidth, 16)
            XCTAssertEqual(light.alpha, 1)
            XCTAssertNil(light.action(forKey: "gentleRetry"))
            XCTAssertNil(light.action(forKey: "inputPulse"))
            let completed = state.runtime
            scene.handleTap(at: CGPoint(x: 1120, y: 250))
            XCTAssertEqual(state.runtime, completed, "Feedback must not make a solved machine submit twice.")
            scene.willLeave()
        }
    }

    func testEveryMechanicRestoresWithSupportAndWorldAcrossContexts() async throws {
        let placeValue = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.placeValue).first?.encounter
        )
        let pattern = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.patternAB).first?.encounter
        )
        let shape = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.recognizeShapes).first?.encounter
        )
        let examples = [MathFoundation.workshopExamples[0], MathCastleEncounterCatalog.balanceScale[0],
            MathCastleEncounterCatalog.numberBondMachine[0], MathCastleEncounterCatalog.tenFrameGate[0],
            MathCastleEncounterCatalog.missingNumberBridge[0], placeValue, pattern, shape]
        for encounter in examples {
            let container = try LearningStore.container(inMemory: true)
            let state = try AppState(context: ModelContext(container))
            XCTAssertTrue(state.startWorkshop(encounter))
            state.beginInteraction(); state.addCrystal(); state.chooseComparison(.right)
            _ = state.scaffold(); state.travel(to: .mathCastle)
            let before = state.adventure
            let restored = try AppState(context: ModelContext(container))
            XCTAssertEqual(restored.adventure, before)
            XCTAssertEqual(restored.profile, state.profile)
            XCTAssertEqual(restored.world, .mathCastle)
            XCTAssertTrue(restored.workshop)
            XCTAssertEqual(restored.runtime?.support, .lightHint)
            XCTAssertEqual(restored.prepareNext(), .encounter(encounter))
            XCTAssertEqual(restored.adventure, before)
        }
    }
    func testLegacyCartSaveUpgradesWithoutDiscardingWorkOrSupport() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var cart = try CrystalCartModel(encounter: MathFoundation.workshopExamples[1])
        cart.add(); cart.apply(ScaffoldingEngine().next(after: .independent))
        let profile = try store.loadProfile()
        try store.save(profile: profile, cart: cart, workshop: true, sound: false,
                       reducedMotion: true, world: "mathCastle")
        let state = try AppState(context: ModelContext(container))
        XCTAssertEqual(state.cart, cart)
        XCTAssertTrue(state.adventure.placementComplete)
        XCTAssertTrue(state.workshop)
        state.persist() // Write the new tagged envelope into the existing V1 store.
        let reopened = try AppState(context: ModelContext(container))
        XCTAssertEqual(reopened.cart, cart)
        XCTAssertFalse(reopened.soundEnabled)
        XCTAssertTrue(reopened.reducedMotion)
        XCTAssertEqual(reopened.profile, profile)
    }
    func testPlacementCompletionSurvivesReturnAndNeverAwardsDuplicateEvidence() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let first = state.prepareNext()
        XCTAssertTrue(state.isPlacement)
        state.chooseComparison(.right)
        XCTAssertEqual(state.submit()?.outcome, .correct)
        state.travel(to: .storyTree)
        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.prepareNext(), first)
        XCTAssertTrue(restored.runtime?.completed == true)
        XCTAssertEqual(restored.adventure.placement.completedProbeCount, 1)
        XCTAssertNil(restored.submit())
        XCTAssertTrue(
            restored.profile.progress(for: MathSkills.compare).evidence.isEmpty,
            "Hidden placement is diagnostic and must not create mastery evidence."
        )
        XCTAssertTrue(
            restored.profile.placementReadySkillIDs?.contains(MathSkills.compare) == true,
            "Independent placement success should survive restore as provisional readiness."
        )
        XCTAssertTrue(restored.advanceEncounter())
        XCTAssertNotEqual(restored.prepareNext(), first)
    }
    func testUnknownAdventureVersionFailsWithoutResettingSavedData() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container)); _ = state.prepareNext()
        let store = try LearningStore(context: ModelContext(container))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(store.snapshot.cartData)) as? [String: Any])
        object["mathAdventureVersion"] = 99
        let data = try JSONSerialization.data(withJSONObject: object)
        store.snapshot.cartData = data; try store.context.save()
        XCTAssertThrowsError(try AppState(context: ModelContext(container)))
        let unchanged = try LearningStore(context: ModelContext(container))
        XCTAssertEqual(unchanged.snapshot.cartData, data)
    }
    func testFiveLiveSceneStationsRouteThroughTheApproachGate() async throws {
        let examples = [MathFoundation.workshopExamples[0], MathCastleEncounterCatalog.balanceScale[0],
            MathCastleEncounterCatalog.numberBondMachine[0], MathCastleEncounterCatalog.tenFrameGate[0],
            MathCastleEncounterCatalog.missingNumberBridge[0]]
        let points = [CGPoint(x: 830, y: 265), CGPoint(x: 670, y: 286), CGPoint(x: 925, y: 280),
                      CGPoint(x: 820, y: 344), CGPoint(x: 965, y: 330)]
        for (encounter, point) in zip(examples, points) {
            let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            XCTAssertTrue(state.startWorkshop(encounter))
            let scene = MathCastleScene(state: state)
            scene.didMove(to: SKView())
            XCTAssertNotNil(scene.targetName(at: point))
            scene.handleTap(at: point)
            XCTAssertFalse(state.interactionStarted, "A distant tap must move Valkyrie before manipulation")
            scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
            scene.valkyrie.position = CGPoint(x: 490, y: 175)
            scene.handleTap(at: point)
            XCTAssertTrue(state.interactionStarted)
            XCTAssertEqual(state.runtime?.encounter.id, encounter.id)
            scene.willLeave()
        }
    }
    func testUnengagedQuickLookDoesNotExposeReferenceOrAllowInput() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let encounter = try XCTUnwrap(MathCastleEncounterCatalog.prerequisites.first { $0.context == "quickLook" })
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state); scene.didMove(to: SKView())
        XCTAssertFalse(state.previewVisible)
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 820, y: 344)), "tenFrameCell")
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 344))
        XCTAssertTrue(state.previewVisible)
        scene.handleTap(at: CGPoint(x: 550, y: 310)) // Supply while reference is showing.
        if case .tenFrame(let model) = state.runtime { XCTAssertEqual(model.filled, 0) }
        else { XCTFail("Expected a ten-frame runtime") }
        scene.willLeave()
    }

    func testChallengeGateSessionRestoresThroughVersionedAdventureSave() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))

        var profile = try store.loadProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        let graph = try MathSkills.graph()
        var adventure = MathAdventure(continuingLearner: true)
        XCTAssertTrue(adventure.beginChallengeGate(profile: profile, graph: graph))
        XCTAssertEqual(adventure.challengeGateSession?.completedCount, 0)

        try store.save(
            profile: profile,
            adventure: adventure,
            sound: true,
            reducedMotion: false,
            world: "mathCastle"
        )

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.challengeGateStatus, .active)
        XCTAssertEqual(restored.challengeGateCompletedCount, 0)
        XCTAssertFalse(restored.hasStoryReward(.moonLantern))

        guard case .encounter(let encounter) = restored.prepareNext() else {
            return XCTFail("Expected restored Challenge Gate encounter")
        }
        XCTAssertEqual(encounter.context, "challengeGate")
    }

    func testBridgePlankInputRequiresArrivalAndAllowsOvershootRecoveryAndRestore() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let encounter = MathCastleEncounterCatalog.missingNumberBridge[0]
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state); scene.didMove(to: SKView())
        let supply = CGPoint(x: 550, y: 335)
        let gap = CGPoint(x: 884, y: 220) // First missing plank after six fixed planks.
        scene.drop(origin: "missingSupply", at: gap)
        if case .missingBridge(let model) = state.runtime { XCTAssertEqual(model.selectedNumber, 0) }
        else { return XCTFail("Expected bridge") }
        scene.handleTap(at: supply)
        XCTAssertFalse(state.interactionStarted)
        scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: supply) // Engage, without adding a plank on this tap.
        XCTAssertTrue(state.interactionStarted)
        scene.drop(origin: "missingSupply", at: CGPoint(x: 1200, y: 600))
        for _ in 0..<5 { scene.drop(origin: "missingSupply", at: gap) }
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertFalse(state.runtime?.completed == true, "One extra plank must not be silently corrected")
        scene.drop(origin: "missingPlank", at: supply)
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(state.runtime?.completed == true)
        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.runtime, state.runtime)
        if case .missingBridge(let model) = restored.runtime {
            XCTAssertEqual(model.selectedNumber, 4)
            XCTAssertEqual(model.support, .lightHint)
        } else { XCTFail("Expected persisted bridge") }
        scene.drop(origin: "missingSupply", at: gap)
        XCTAssertEqual(restored.runtime, state.runtime, "Solved bridge must reject further manipulation")
        scene.willLeave()
    }

    func testBridgeShowsFixedGapsAndOverflowWithoutCoveringFeedback() async throws {
        let encounter = MathCastleEncounterCatalog.missingNumberBridge[0]
        var model = try MissingNumberBridgeModel(encounter: encounter)
        let bridge = MissingNumberBridgeMechanic(); bridge.render(model)
        XCTAssertEqual(bridge.nodes(at: CGPoint(x: -224, y: -90)).first?.name, "missingFixed")
        XCTAssertEqual(bridge.nodes(at: CGPoint(x: 64, y: -90)).first?.name, "missingSlot")
        XCTAssertTrue(bridge.receives(CGPoint(x: 64, y: -90)))
        XCTAssertFalse(bridge.receives(CGPoint(x: 0, y: 140)))
        model.setNumber(20); bridge.render(model)
        XCTAssertNotNil(bridge.childNode(withName: "//missingPlank"))
        XCTAssertGreaterThanOrEqual(bridge.calculateAccumulatedFrame().minY + 310, 86)
        model.setNumber(model.correctNumber); XCTAssertEqual(model.submit()?.outcome, .correct)
        bridge.render(model)
        let repaired = try XCTUnwrap(bridge.childNode(withName: "//missingPlank") as? SKShapeNode)
        XCTAssertEqual(repaired.glowWidth, 0, "Repaired timber should settle without a persistent tile glow.")
    }

    func testBridgeRouteLocksUntilRepairAndHomeCancelsCrossingWithoutNewEvidence() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathCastleEncounterCatalog.missingNumberBridge[0]))
        let scene = MathCastleScene(state: state); scene.didMove(to: SKView())
        let route = try XCTUnwrap(scene.childNode(withName: "bridgeRoute"))
        XCTAssertTrue(route.isHidden)
        scene.handleTap(at: CGPoint(x: 1040, y: 244))
        XCTAssertFalse(scene.crossingBridge)
        scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 965, y: 330))
        for _ in 0..<4 { scene.drop(origin: "missingSupply", at: CGPoint(x: 884, y: 220)) }
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertFalse(route.isHidden)
        let solvedRuntime = state.runtime
        let evidenceBefore = state.profile
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(scene.crossingBridge)
        XCTAssertNotNil(scene.valkyrie.action(forKey: "travel"))
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertEqual(state.runtime, solvedRuntime)
        scene.handleTap(at: CGPoint(x: 52, y: 669))
        XCTAssertFalse(scene.crossingBridge)
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertNil(scene.pip.action(forKey: "travel"))
        XCTAssertEqual(state.world, .storyTree)
        XCTAssertEqual(state.runtime, solvedRuntime)
        XCTAssertEqual(state.profile, evidenceBefore, "Exploration must not award extra learning evidence")
        scene.willLeave()
    }

}
