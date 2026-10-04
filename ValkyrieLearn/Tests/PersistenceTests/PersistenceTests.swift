import XCTest
import SwiftData
import LearningCore
@testable import ValkyrieLearn

@MainActor final class PersistenceTests: XCTestCase {
    private func unlockedState(in container: ModelContainer) throws -> AppState {
        let store = try LearningStore(context: ModelContext(container))
        let profile = try store.loadProfile()
        try store.save(
            profile: profile,
            mathAdventure: MathAdventureSaveState(placementComplete: true),
            workshop: false,
            sound: true,
            reducedMotion: false,
            world: "storyTree"
        )
        return try AppState(context: ModelContext(container))
    }

    private func challengeReadyState(in container: ModelContainer) throws -> AppState {
        let store = try LearningStore(context: ModelContext(container))
        var profile = try store.loadProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        try store.save(
            profile: profile,
            mathAdventure: MathAdventureSaveState(placementComplete: true),
            workshop: false,
            sound: true,
            reducedMotion: false,
            world: "mathCastle"
        )
        return try AppState(context: ModelContext(container))
    }

    private func solveActiveMath(_ state: AppState) throws {
        guard let runtime = state.activeMath else {
            return XCTFail("Expected an active Math mechanic")
        }

        switch runtime {
        case .crystalCart(let model):
            while model.encounter.operation == .subtraction
                    ? (state.cart?.quantity ?? model.quantity) > model.encounter.targetQuantity
                    : (state.cart?.quantity ?? model.quantity) < model.encounter.targetQuantity {
                if model.encounter.operation == .subtraction {
                    XCTAssertTrue(state.decrementActive())
                } else {
                    XCTAssertTrue(state.incrementActive())
                }
            }

        case .balanceScale(let model):
            state.chooseComparison(model.correctChoice)

        case .numberBond(let model):
            state.setActiveValue(model.correctMissingPart)

        case .tenFrame(let model):
            var remaining = model.encounter.targetQuantity - model.filled
            while remaining > 0 {
                XCTAssertTrue(state.incrementActive())
                remaining -= 1
            }

        case .missingBridge(let model):
            state.setActiveValue(model.correctNumber)
        }

        XCTAssertEqual(state.submit()?.outcome, .correct)
    }
    func testSwiftDataRoundTripAcrossContexts() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = try store.loadProfile()
        profile.begin(MathFoundation.encounters[0], at: Date())
        let evidence = LearningEvidence(encounterID: "saved", skillID: MathSkills.quantity,
            outcome: .correct, supportLevel: .strongHint)
        MasteryEngine().record(evidence, in: &profile)
        var cart = try CrystalCartModel(encounter: MathFoundation.encounters[0]); cart.add()
        try store.save(profile: profile, cart: cart, workshop: false, sound: false, reducedMotion: true, world: "mathCastle")
        let restored = try LearningStore(context: ModelContext(container))
        XCTAssertEqual(try restored.loadProfile(), profile)
        XCTAssertEqual(try restored.loadCart()?.quantity, 1)
        XCTAssertFalse(restored.snapshot.soundEnabled)
        XCTAssertTrue(restored.snapshot.reducedMotion)
        XCTAssertEqual(restored.snapshot.lastWorld, "mathCastle")
    }
    func testAppStateRestoresWorkshopWithoutAwardingMastery() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try unlockedState(in: container)
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[1]))
        for _ in 0..<3 { state.addCrystal() }
        XCTAssertEqual(state.submit()?.outcome, .correct)
        let restored = try AppState(context: ModelContext(container))
        XCTAssertTrue(restored.workshop)
        XCTAssertEqual(restored.profile.progress(for: MathSkills.addition).state, .new)
        XCTAssertTrue(restored.profile.progress(for: MathSkills.addition).evidence.isEmpty)
        XCTAssertTrue(restored.cart?.completed == true)
    }
    func testDemonstrationCorrectsOvershootAndPreservesAssistance() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try unlockedState(in: container)
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[1])) // 4 + 3
        for _ in 0..<4 { state.addCrystal() }
        XCTAssertEqual(state.cart?.quantity, 8)
        _ = state.scaffold(); _ = state.scaffold()
        let demonstration = state.scaffold()
        XCTAssertTrue(demonstration?.demonstratesStep == true)
        XCTAssertEqual(state.cart?.quantity, 7)
        XCTAssertEqual(state.cart?.support, .demonstration)
        XCTAssertEqual(state.submit()?.supportLevel, .demonstration)
        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.cart?.quantity, 7)
        XCTAssertEqual(restored.cart?.support, .demonstration)
    }
    func testWorkshopTracksRepetitionWithoutMasteryAndCannotDiscardScoredWork() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try unlockedState(in: container)
        let example = MathFoundation.workshopExamples[0]
        XCTAssertTrue(state.startWorkshop(example))
        for _ in 0..<7 { state.addCrystal() }; _ = state.submit()
        XCTAssertFalse(state.startWorkshop(example))
        XCTAssertEqual(state.profile.progress(for: example.skillID).state, .new)
        XCTAssertTrue(state.profile.usedFingerprints.contains(example.fingerprint))
        let scoredContainer = try LearningStore.container(inMemory: true)
        let scored = try unlockedState(in: scoredContainer)
        _ = scored.prepareNext()
        let before = scored.activeEncounter
        XCTAssertFalse(scored.startWorkshop(MathFoundation.workshopExamples[1]))
        XCTAssertEqual(scored.activeEncounter, before)
    }
    func testUnsupportedProfileDoesNotResetProgress() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = LearnerProfile(); profile.schemaVersion = 99
        store.snapshot.profileData = try JSONEncoder().encode(profile); try store.context.save()
        XCTAssertThrowsError(try store.loadProfile())
        XCTAssertEqual(try JSONDecoder().decode(LearnerProfile.self, from: store.snapshot.profileData).schemaVersion, 99)
    }

    func testHiddenPlacementRunsThroughPlayableNativeMechanics() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        guard case .encounter(let comparison) = state.prepareNext() else {
            return XCTFail("Expected hidden placement encounter")
        }
        XCTAssertEqual(comparison.mechanicID, MathMechanicID.balanceScale)
        XCTAssertFalse(state.placementComplete)

        state.chooseComparison(.right)
        XCTAssertEqual(state.submit()?.outcome, .correct)

        guard case .encounter(let subtraction) = state.prepareNext() else {
            return XCTFail("Expected subtraction probe after easy comparison")
        }
        XCTAssertEqual(subtraction.operation, .subtraction)
        XCTAssertEqual(subtraction.mechanicID, MathMechanicID.crystalCart)
        for _ in 0..<3 { XCTAssertTrue(state.decrementActive()) }
        XCTAssertEqual(state.submit()?.outcome, .correct)

        guard case .encounter(let bond) = state.prepareNext() else {
            return XCTFail("Expected number-bond probe")
        }
        XCTAssertEqual(bond.mechanicID, MathMechanicID.numberBondMachine)
        state.setActiveValue(4)
        XCTAssertEqual(state.submit()?.outcome, .correct)

        guard case .encounter(let missing) = state.prepareNext() else {
            return XCTFail("Expected missing-number probe")
        }
        XCTAssertEqual(missing.mechanicID, MathMechanicID.missingNumberBridge)
        state.setActiveValue(3)
        XCTAssertEqual(state.submit()?.outcome, .correct)

        XCTAssertTrue(state.placementComplete)
        XCTAssertNotEqual(state.profile.progress(for: MathSkills.bonds10).state, .mastered)
        XCTAssertTrue(state.profile.placementReadySkillIDs?.contains(MathSkills.bonds10) == true)

        let next = state.prepareNext()
        if case .needsContent = next {
            XCTFail("Adaptive Math Castle should continue after placement")
        }
    }

    func testPlacementSessionAndNonCartRuntimeRestoreAcrossRelaunch() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        guard case .encounter = state.prepareNext() else {
            return XCTFail("Expected first placement probe")
        }
        state.chooseComparison(.right)
        XCTAssertEqual(state.submit()?.outcome, .correct)

        let restored = try AppState(context: ModelContext(container))
        XCTAssertFalse(restored.placementComplete)
        XCTAssertEqual(restored.mathAdventure.placementSession?.highestIndependentBand, 2)

        guard case .encounter(let nextProbe) = restored.prepareNext() else {
            return XCTFail("Expected restored placement to continue")
        }
        XCTAssertEqual(nextProbe.operation, .subtraction)
    }

    func testUnifiedMathRuntimeRoundTripsThroughExistingSwiftDataBlob() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        let profile = try store.loadProfile()
        var runtime = try MathMechanicRuntime(
            encounter: MathCastleEncounterCatalog.numberBondMachine[0]
        )
        runtime.setValue(2)

        let mathState = MathAdventureSaveState(
            runtime: runtime,
            placementSession: PlacementEngine(probes: MathPlacement.playableProbes).begin(),
            placementComplete: false
        )

        try store.save(
            profile: profile,
            mathAdventure: mathState,
            workshop: false,
            sound: true,
            reducedMotion: false,
            world: "mathCastle"
        )

        let restored = try LearningStore(context: ModelContext(container))
        XCTAssertEqual(try restored.loadMathAdventure(), mathState)
    }

    func testLegacyCrystalCartBlobMigratesWithoutSwiftDataSchemaChange() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var legacy = try CrystalCartModel(encounter: MathFoundation.encounters[0])
        _ = legacy.add()

        store.snapshot.cartData = try JSONEncoder().encode(legacy)
        try store.context.save()

        let migrated = try LearningStore(context: ModelContext(container)).loadMathAdventure()
        guard case .crystalCart(let restored)? = migrated.runtime else {
            return XCTFail("Expected legacy cart to migrate into unified runtime")
        }
        XCTAssertEqual(restored.quantity, legacy.quantity)
        XCTAssertFalse(migrated.placementComplete)
    }

    func testAdaptiveSessionStartsWithSupportedRuntimeAfterPlacement() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try unlockedState(in: container)

        let selection = state.prepareNext()
        guard case .encounter(let encounter) = selection else {
            return XCTFail("Expected adaptive Math Castle encounter")
        }

        XCTAssertTrue(MathManipulativeSupport.supports(encounter))
        XCTAssertNotNil(state.activeMath)
    }


    func testChallengeGateCompletionUnlocksMovableMoonLanternAcrossRelaunch() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try challengeReadyState(in: container)

        XCTAssertEqual(state.challengeGateStatus, .ready)
        XCTAssertTrue(state.beginChallengeGate())
        XCTAssertEqual(state.challengeGateStatus, .active)

        for completed in 0..<ChallengeGateCatalog.challengeCount {
            guard case .encounter(let encounter) = state.prepareNext() else {
                return XCTFail("Expected Challenge Gate encounter \(completed + 1)")
            }
            XCTAssertEqual(encounter.context, "challengeGate")
            try solveActiveMath(state)

            if completed < ChallengeGateCatalog.challengeCount - 1 {
                XCTAssertEqual(state.challengeGateStatus, .active)
                XCTAssertEqual(state.challengeGateCompletedCount, completed + 1)
            }
        }

        XCTAssertEqual(state.challengeGateStatus, .completed)
        XCTAssertTrue(state.hasStoryReward(.moonLantern))
        XCTAssertEqual(state.storyRewardPlacement(.moonLantern), 0)

        XCTAssertEqual(
            state.cycleStoryRewardPlacement(.moonLantern, slotCount: 3),
            1
        )

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.challengeGateStatus, .completed)
        XCTAssertTrue(restored.hasStoryReward(.moonLantern))
        XCTAssertEqual(restored.storyRewardPlacement(.moonLantern), 1)
        XCTAssertFalse(restored.beginChallengeGate())
    }

    func testChallengeGateProgressRestoresMidRun() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try challengeReadyState(in: container)

        XCTAssertTrue(state.beginChallengeGate())
        guard case .encounter(let first) = state.prepareNext() else {
            return XCTFail("Expected first Challenge Gate encounter")
        }
        XCTAssertEqual(first.context, "challengeGate")
        try solveActiveMath(state)
        XCTAssertEqual(state.challengeGateCompletedCount, 1)

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.challengeGateStatus, .active)
        XCTAssertEqual(restored.challengeGateCompletedCount, 1)
        XCTAssertFalse(restored.hasStoryReward(.moonLantern))

        guard case .encounter(let second) = restored.prepareNext() else {
            return XCTFail("Expected Challenge Gate to resume at second encounter")
        }
        XCTAssertNotEqual(second.id, first.id)
        XCTAssertEqual(second.context, "challengeGate")
    }

    func testChallengeGateCannotInterruptActiveScoredEncounter() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try challengeReadyState(in: container)

        guard case .encounter = state.prepareNext() else {
            return XCTFail("Expected normal adaptive encounter")
        }
        XCTAssertNotNil(state.activeMath)
        XCTAssertFalse(state.beginChallengeGate())
        XCTAssertEqual(state.challengeGateStatus, .ready)
    }

}
