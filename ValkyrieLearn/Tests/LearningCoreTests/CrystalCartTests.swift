import XCTest
@testable import LearningCore

final class CrystalCartTests: XCTestCase {
    func testCountingAdditionAndMissingAddend() throws {
        for encounter in MathFoundation.workshopExamples {
            var cart = try CrystalCartModel(encounter: encounter)
            XCTAssertEqual(cart.quantity, encounter.initialQuantity)
            XCTAssertFalse(cart.remove())
            for _ in encounter.initialQuantity..<encounter.targetQuantity { XCTAssertTrue(cart.add()) }
            let result = cart.submit()
            XCTAssertEqual(result?.outcome, .correct)
            XCTAssertEqual(result?.supportLevel, .independent)
            XCTAssertFalse(cart.add()); XCTAssertFalse(cart.remove()); XCTAssertNil(cart.submit())
        }
    }
    func testWrongAttemptThenHintProducesAssistedEvidence() throws {
        var cart = try CrystalCartModel(encounter: MathFoundation.workshopExamples[1])
        XCTAssertEqual(cart.submit()?.outcome, .incorrect)
        let scaffold = ScaffoldingEngine().next(after: cart.support); cart.apply(scaffold)
        for _ in 0..<3 { cart.add() }
        let result = cart.submit()
        XCTAssertEqual(result?.outcome, .correct); XCTAssertEqual(result?.attempts, 2)
        XCTAssertEqual(result?.supportLevel, .lightHint); XCTAssertEqual(result?.easySuccess, false)
    }
    func testScaffoldEscalationNeverReturnsToIndependent() throws {
        var cart = try CrystalCartModel(encounter: MathFoundation.encounters[0])
        for expected in [SupportLevel.lightHint, .strongHint, .demonstration, .demonstration] {
            cart.apply(ScaffoldingEngine().next(after: cart.support)); XCTAssertEqual(cart.support, expected)
        }
        cart.apply(ScaffoldingEngine().next(after: .independent)); XCTAssertEqual(cart.support, .demonstration)
    }
    func testCapacityCorrectionAndUnsupportedOperations() throws {
        var cart = try CrystalCartModel(encounter: MathFoundation.encounters[0])
        for _ in 0..<12 { XCTAssertTrue(cart.add()) }; XCTAssertFalse(cart.add())
        for _ in 0..<5 { cart.remove() }; XCTAssertEqual(cart.quantity, 7)
        XCTAssertEqual(cart.submit()?.outcome, .correct)
        let unsupported = LearningEncounter(id: "future", skillID: MathSkills.equalGroups,
            operation: .equalGroups, initialQuantity: 0, targetQuantity: 6, prompt: "Make equal groups.")
        XCTAssertThrowsError(try CrystalCartModel(encounter: unsupported)) { error in
            guard case CrystalCartModel.CartError.unsupportedOperation = error else {
                return XCTFail("Expected unsupported operation, got \(error)")
            }
        }
    }

    func testNumberBondMachineProducesEvidence() throws {
        let encounter = MathCastleEncounterCatalog.numberBondMachine[2]
        var model = try NumberBondMachineModel(encounter: encounter, at: Date(timeIntervalSince1970: 100))

        XCTAssertEqual(model.knownPart, 6)
        XCTAssertEqual(model.whole, 10)
        XCTAssertEqual(model.correctMissingPart, 4)

        model.setPart(3)
        XCTAssertEqual(model.submit(at: Date(timeIntervalSince1970: 110))?.outcome, .incorrect)
        XCTAssertFalse(model.completed)

        model.apply(ScaffoldingEngine().next(after: .independent))
        model.setPart(4)
        let evidence = model.submit(at: Date(timeIntervalSince1970: 120))

        XCTAssertEqual(evidence?.outcome, .correct)
        XCTAssertEqual(evidence?.supportLevel, .lightHint)
        XCTAssertEqual(evidence?.attempts, 2)
        XCTAssertFalse(evidence?.easySuccess ?? true)
        XCTAssertTrue(model.completed)
    }

    func testTenFrameGateSupportsConcretePictorialPractice() throws {
        let encounter = MathCastleEncounterCatalog.tenFrameGate[1]
        var model = try TenFrameModel(encounter: encounter, at: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(model.filled, 4)
        for _ in 0..<5 { XCTAssertTrue(model.addCounter()) }
        XCTAssertEqual(model.filled, 9)

        let evidence = model.submit(at: Date(timeIntervalSince1970: 215))
        XCTAssertEqual(evidence?.outcome, .correct)
        XCTAssertEqual(evidence?.representation, .pictorial)
        XCTAssertEqual(evidence?.mechanicID, MathMechanicID.tenFrameGate)
        XCTAssertTrue(evidence?.easySuccess ?? false)
    }

    func testBalanceScaleSupportsLeftRightAndEqualComparisons() throws {
        for (encounter, expected) in zip(
            MathCastleEncounterCatalog.balanceScale,
            [ComparisonChoice.right, .left, .equal]
        ) {
            var model = try BalanceScaleModel(encounter: encounter)
            XCTAssertEqual(model.correctChoice, expected)
            XCTAssertNil(model.submit())
            model.choose(expected)
            XCTAssertEqual(model.submit()?.outcome, .correct)
        }
    }

    func testMissingNumberBridgeCapturesMissingPartReasoning() throws {
        let encounter = MathCastleEncounterCatalog.missingNumberBridge[0]
        var model = try MissingNumberBridgeModel(encounter: encounter)

        XCTAssertEqual(model.correctNumber, 4)
        for _ in 0..<4 { XCTAssertTrue(model.increment()) }
        XCTAssertEqual(model.selectedNumber, 4)
        let evidence = try XCTUnwrap(model.submit())
        XCTAssertEqual(evidence.outcome, .correct)
        XCTAssertEqual(evidence.representation, .concrete, "Building a visible span must not claim symbolic-only transfer")
        XCTAssertFalse(model.increment())
        XCTAssertFalse(model.decrement())
    }

    func testMathCastleEncounterCatalogIsSupportedUniqueAndSmall() {
        let encounters = MathCastleEncounterCatalog.all

        XCTAssertGreaterThan(encounters.count, MathFoundation.encounters.count)
        XCTAssertLessThan(encounters.count, 50)
        XCTAssertEqual(Set(encounters.map(\.id)).count, encounters.count)

        // Legacy foundation intentionally contains a few different skill IDs that
        // render the same math surface. EngagementDirector blocks those repeats at
        // runtime. New native mechanics themselves must not introduce duplicates.
        let newMechanics =
            MathCastleEncounterCatalog.prerequisites
            + MathCastleEncounterCatalog.balanceScale
            + MathCastleEncounterCatalog.numberBondMachine
            + MathCastleEncounterCatalog.tenFrameGate
            + MathCastleEncounterCatalog.missingNumberBridge
        XCTAssertEqual(
            Set(newMechanics.map(\.fingerprint)).count,
            newMechanics.count
        )
        XCTAssertTrue(encounters.allSatisfy(MathManipulativeSupport.supports))
        XCTAssertTrue(MathMechanicID.adaptiveSet.isSuperset(
            of: Set(encounters.map(\.mechanicID))
        ))
    }

    func testMathCastleSessionPlanUsesMultipleMechanicsWhenLearnerIsReady() throws {
        var profile = LearnerProfile()

        for skill in [
            MathSkills.quantity,
            MathSkills.counting,
            MathSkills.cardinality10,
            MathSkills.subitizing,
            MathSkills.compare,
            MathSkills.addition,
            MathSkills.compose5,
            MathSkills.decompose5,
            MathSkills.bonds5,
            MathSkills.compose10,
            MathSkills.decompose10,
            MathSkills.bonds10
        ] {
            profile.skills[skill.rawValue] = SkillProgress(state: .developing)
        }

        let plan = try MathCastleEncounterCatalog.sessionPlan(
            for: profile,
            encounterCount: 10,
            now: Date(timeIntervalSince1970: 1_700_000_000),
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 3)
        )

        XCTAssertGreaterThan(plan.encounterCount, 0)
        XCTAssertGreaterThanOrEqual(Set(plan.encounters.map { $0.encounter.mechanicID }).count, 2)
        XCTAssertEqual(
            Set(plan.encounters.map { $0.encounter.fingerprint }).count,
            plan.encounterCount
        )
    }


    func testUnifiedMathMechanicRuntimeRoutesActions() throws {
        let bondEncounter = MathCastleEncounterCatalog.numberBondMachine[0]
        var bond = try MathMechanicRuntime(
            encounter: bondEncounter,
            at: Date(timeIntervalSince1970: 500)
        )
        bond.setValue(3)
        XCTAssertEqual(
            bond.submit(at: Date(timeIntervalSince1970: 510))?.outcome,
            .correct
        )
        XCTAssertTrue(bond.completed)

        let scaleEncounter = MathCastleEncounterCatalog.balanceScale[0]
        var scale = try MathMechanicRuntime(encounter: scaleEncounter)
        XCTAssertFalse(scale.increment())
        scale.chooseComparison(.right)
        XCTAssertEqual(scale.submit()?.outcome, .correct)

        let frameEncounter = MathCastleEncounterCatalog.tenFrameGate[0]
        var frame = try MathMechanicRuntime(encounter: frameEncounter)
        for _ in 0..<7 { XCTAssertTrue(frame.increment()) }
        XCTAssertEqual(frame.submit()?.outcome, .correct)

        let bridgeEncounter = MathCastleEncounterCatalog.missingNumberBridge[0]
        var bridge = try MathMechanicRuntime(encounter: bridgeEncounter)
        bridge.setValue(4)
        XCTAssertEqual(bridge.submit()?.outcome, .correct)
    }

    func testUnifiedRuntimeRejectsUnknownMechanic() {
        let encounter = LearningEncounter(
            id: "unknown-runtime",
            skillID: MathSkills.quantity,
            mechanicID: "notARealMechanic",
            operation: .counting,
            initialQuantity: 0,
            targetQuantity: 4,
            prompt: "Unsupported"
        )

        XCTAssertThrowsError(try MathMechanicRuntime(encounter: encounter))
    }

    func testSessionPlanCursorAdvancesThroughExplorationAndEncounterBeats() {
        let encounter = MathFoundation.encounters[0]
        let planned = PlannedSessionEncounter(lane: .learning, encounter: encounter)
        let plan = SessionPlan(
            beats: [.encounter(planned), .explorationBreak],
            requestedEncounterCount: 1,
            desiredLaneCounts: [.learning: 1, .review: 0, .stretch: 0, .confidence: 0],
            actualLaneCounts: [.learning: 1, .review: 0, .stretch: 0, .confidence: 0]
        )

        var cursor = SessionPlanCursor(plan: plan)
        XCTAssertEqual(cursor.remainingBeatCount, 2)
        XCTAssertFalse(cursor.isComplete)

        XCTAssertEqual(cursor.advance(), .encounter(planned))
        XCTAssertEqual(cursor.remainingBeatCount, 1)
        XCTAssertEqual(cursor.advance(), .explorationBreak)
        XCTAssertTrue(cursor.isComplete)
        XCTAssertNil(cursor.current)
        XCTAssertNil(cursor.advance())
    }

    func testFixedAnswersDoNotClaimExplanationOrAlternativeSplitEvidence() throws {
        let equal = MathCastleEncounterCatalog.balanceScale[2]
        XCTAssertEqual(equal.skillID, MathSkills.compare)
        XCTAssertEqual(equal.representation, .concrete)
        var scale = try BalanceScaleModel(encounter: equal)
        scale.choose(.equal)
        XCTAssertFalse(try XCTUnwrap(scale.submit()).transferContext)
        let split = MathCastleEncounterCatalog.numberBondMachine[3]
        XCTAssertEqual(split.skillID, MathSkills.bonds10)
        XCTAssertEqual(split.representation, .concrete)
        var bond = try NumberBondMachineModel(encounter: split)
        bond.setPart(7)
        XCTAssertFalse(try XCTUnwrap(bond.submit()).transferContext)
    }

    func testQuickLookRejectsConstructionUntilReferenceHasHidden() throws {
        let encounter = try XCTUnwrap(MathCastleEncounterCatalog.prerequisites.first {
            $0.context == "quickLook"
        })
        let start = Date(timeIntervalSince1970: 500)
        var model = try TenFrameModel(encounter: encounter, at: start)
        XCTAssertTrue(model.previewIsVisible(at: start))
        XCTAssertFalse(model.addCounter(at: start))
        XCTAssertFalse(model.removeCounter(at: start))
        XCTAssertNil(model.submit(at: start))
        XCTAssertEqual(model.attempts, 0)
        let after = start.addingTimeInterval(model.previewDuration)
        XCTAssertFalse(model.previewIsVisible(at: after))
        for _ in 0..<encounter.targetQuantity { XCTAssertTrue(model.addCounter(at: after)) }
        XCTAssertEqual(model.submit(at: after)?.outcome, .correct)
    }

    func testFreshLearnerCanReachAllFiveMechanicsThroughRealEligibleEvidence() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        var now = Date(timeIntervalSince1970: 1000)
        var seenMechanics = Set<String>()
        // Replan after each real response; never seed skill readiness by hand.
        for _ in 0..<60 {
            let plan = try MathCastleEncounterCatalog.sessionPlan(for: profile,
                encounterCount: 1, now: now)
            guard let item = plan.encounters.first else { break }
            let encounter = item.encounter
            XCTAssertTrue(graph.isEligible(encounter.skillID, for: profile))
            for beat in plan.beats {
                if case .explorationBreak = beat {
                    profile.recordActivity(ActivityRecord(fingerprint: "walk-\(now)",
                        mechanicID: "exploration", timestamp: now))
                }
            }
            XCTAssertFalse(profile.usedFingerprints.contains(encounter.fingerprint))
            profile.begin(encounter, at: now)
            var runtime = try MathMechanicRuntime(encounter: encounter,
                at: now.addingTimeInterval(-30))
            switch runtime {
            case .crystalCart:
                if encounter.operation == .subtraction {
                    for _ in encounter.targetQuantity..<encounter.initialQuantity {
                        XCTAssertTrue(runtime.decrement())
                    }
                } else {
                    for _ in encounter.initialQuantity..<encounter.targetQuantity {
                        XCTAssertTrue(runtime.increment())
                    }
                }
            case .balanceScale(let model): runtime.chooseComparison(model.correctChoice)
            case .numberBond(let model): runtime.setValue(model.correctMissingPart)
            case .tenFrame(let model):
                for _ in model.filled..<encounter.targetQuantity {
                    XCTAssertTrue(runtime.increment())
                }
            case .missingBridge(let model): runtime.setValue(model.correctNumber)
            }
            let evidence = try XCTUnwrap(runtime.submit(at: now))
            XCTAssertEqual(evidence.outcome, .correct)
            MasteryEngine().record(evidence, in: &profile)
            seenMechanics.insert(encounter.mechanicID)
            now = now.addingTimeInterval(31)
        }
        XCTAssertEqual(seenMechanics, MathMechanicID.adaptiveSet)
        XCTAssertGreaterThanOrEqual(profile.progress(for: MathSkills.bonds10).state.readiness,
                                    SkillState.developing.readiness)
        XCTAssertTrue(graph.isEligible(MathSkills.missing, for: profile))
    }

}
