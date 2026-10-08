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

    func testMathCastleEncounterCatalogIsSupportedUniqueAndProductionScale() {
        let encounters = MathCastleEncounterCatalog.all
        let seedCatalog =
            MathFoundation.encounters
            + MathCastleEncounterCatalog.prerequisites
            + MathCastleEncounterCatalog.balanceScale
            + MathCastleEncounterCatalog.numberBondMachine
            + MathCastleEncounterCatalog.tenFrameGate
            + MathCastleEncounterCatalog.missingNumberBridge
            + MathCastleEncounterCatalog.reasoningDepth

        XCTAssertLessThan(seedCatalog.count, 50)
        XCTAssertEqual(encounters.count, 2116)
        XCTAssertEqual(
            encounters.count,
            seedCatalog.count + MathProductionQuestionBank.encounters.count
        )
        XCTAssertEqual(Set(encounters.map(\.id)).count, encounters.count)

        // Legacy foundation intentionally contains a few different skill IDs that
        // render the same math surface. EngagementDirector blocks those repeats at
        // runtime. The production bank itself has stricter fingerprint uniqueness.
        let newSeedMechanics =
            MathCastleEncounterCatalog.prerequisites
            + MathCastleEncounterCatalog.balanceScale
            + MathCastleEncounterCatalog.numberBondMachine
            + MathCastleEncounterCatalog.tenFrameGate
            + MathCastleEncounterCatalog.missingNumberBridge
        XCTAssertEqual(
            Set(newSeedMechanics.map(\.fingerprint)).count,
            newSeedMechanics.count
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


    func testPlaceValueFactoryBuildAndCompareModelsProduceObservableEvidence() throws {
        let build = LearningEncounter(
            id: "place-build-42",
            skillID: MathSkills.buildTwoDigit,
            mechanicID: MathMechanicID.placeValueFactory,
            representation: .concrete,
            operation: .quantityMatching,
            initialQuantity: 0,
            targetQuantity: 42,
            prompt: "Build 42."
        )
        var buildModel = try PlaceValueFactoryModel(encounter: build)
        XCTAssertEqual(buildModel.expectedTens, 4)
        XCTAssertEqual(buildModel.expectedOnes, 2)
        for _ in 0..<4 { XCTAssertTrue(buildModel.addTen()) }
        for _ in 0..<2 { XCTAssertTrue(buildModel.addOne()) }
        XCTAssertEqual(buildModel.builtNumber, 42)
        XCTAssertEqual(try XCTUnwrap(buildModel.submit()).outcome, .correct)

        let compare = LearningEncounter(
            id: "place-compare-47-39",
            skillID: MathSkills.compareTwoDigit,
            mechanicID: MathMechanicID.placeValueFactory,
            representation: .reasoning,
            operation: .comparison,
            initialQuantity: 47,
            targetQuantity: 39,
            prompt: "Which is greater?"
        )
        var compareModel = try PlaceValueFactoryModel(encounter: compare)
        XCTAssertEqual(compareModel.correctChoice, .left)
        compareModel.choose(.left)
        XCTAssertEqual(try XCTUnwrap(compareModel.submit()).outcome, .correct)

        let order = LearningEncounter(
            id: "place-order-47-39",
            skillID: MathSkills.orderTwoDigit,
            mechanicID: MathMechanicID.placeValueFactory,
            representation: .reasoning,
            operation: .comparison,
            initialQuantity: 47,
            targetQuantity: 39,
            prompt: "Which comes first?"
        )
        var orderModel = try PlaceValueFactoryModel(encounter: order)
        XCTAssertEqual(orderModel.correctChoice, .right)
        orderModel.choose(.right)
        XCTAssertEqual(try XCTUnwrap(orderModel.submit()).outcome, .correct)
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

    func testFreshLearnerCanReachAllTwelveMechanicsThroughRealEligibleEvidence() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        var now = Date(timeIntervalSince1970: 1000)
        var seenMechanics = Set<String>()
        // Replan after each real response; never seed skill readiness by hand.
        for _ in 0..<180 {
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
            case .placeValueFactory(let model):
                if model.isComparison {
                    runtime.chooseComparison(model.correctChoice)
                } else {
                    XCTAssertTrue(runtime.adjustPlaceValue(
                        tensDelta: model.expectedTens,
                        onesDelta: model.expectedOnes
                    ))
                }
            case .patternLoom(let model):
                if model.isCreation {
                    let unit: [Int]
                    switch model.family {
                    case .ab: unit = [1, 2]
                    case .aab: unit = [1, 1, 2]
                    case .abc: unit = [1, 2, 3]
                    }
                    for index in 0..<model.slotCount {
                        XCTAssertTrue(runtime.choosePatternSymbol(unit[index % unit.count]))
                    }
                } else {
                    XCTAssertTrue(runtime.choosePatternSymbol(model.correctSymbol))
                }
            case .shapeForge(let model):
                switch model.task {
                case .rotate:
                    let forward = (model.targetOrientation - model.currentOrientation + 4) % 4
                    for _ in 0..<forward {
                        XCTAssertTrue(runtime.rotateShape(1))
                    }
                case .compose:
                    for turns in model.requiredHalfTurns {
                        XCTAssertTrue(runtime.placeShapeHalf(turns))
                    }
                case .symmetry:
                    for (row, shape) in model.symmetryReference.enumerated() {
                        for _ in 0..<shape.rawValue {
                            XCTAssertTrue(runtime.cycleMirrorCell(row))
                        }
                    }
                case .recognize, .attributes:
                    XCTAssertTrue(runtime.chooseShapeOption(try XCTUnwrap(model.correctOption)))
                }
            case .measurementWorkshop(let model):
                if model.isUnitMeasurement {
                    for _ in 0..<model.targetUnitCount {
                        XCTAssertTrue(runtime.placeMeasureUnit())
                    }
                } else {
                    runtime.chooseComparison(model.correctChoice)
                }
            case .dataBoard(let model):
                if model.isSorting {
                    let attribute = try XCTUnwrap(model.sortingAttribute)
                    for token in model.sortingTokens {
                        XCTAssertTrue(runtime.sortDataObject(into: token.category(for: attribute)))
                    }
                } else {
                    for (index, count) in model.graphSourceCounts.enumerated() {
                        for _ in 0..<count {
                            XCTAssertTrue(runtime.addPicture(to: index + 1))
                        }
                    }
                }
            case .clockMarket(let model):
                if model.isClock {
                    let hourMoves = model.targetHour == 12 ? 12 : model.targetHour
                    for _ in 0..<hourMoves {
                        XCTAssertTrue(runtime.adjustClockHour(1))
                    }
                    if model.task != .hour {
                        let step = model.task == .halfHour ? 30 : 5
                        for _ in 0..<(model.targetMinute / step) {
                            XCTAssertTrue(runtime.adjustClockMinute(1))
                        }
                    }
                } else if model.isRoutines {
                    for card in model.routineCards {
                        XCTAssertTrue(runtime.placeDailyRoutine(card.daypart))
                    }
                } else {
                    var remaining = model.targetPesos
                    for coin in model.allowedCoins.reversed() {
                        while remaining >= coin {
                            XCTAssertTrue(runtime.addPesoCoin(coin))
                            remaining -= coin
                        }
                    }
                    XCTAssertEqual(remaining, 0)
                }
            case .groupingGarden(let model):
                if model.activity.targetCells > 0 {
                    XCTAssertTrue(runtime.chooseGardenFraction(0))
                } else {
                    for group in 0..<model.activity.groupCount {
                        for _ in 0..<model.activity.itemsPerGroup {
                            XCTAssertTrue(runtime.placeGroupCounter(in: group))
                        }
                    }
                    if model.task == .repeatedAddition {
                        for _ in 0..<model.activity.totalItems {
                            XCTAssertTrue(runtime.adjustGardenSum(1))
                        }
                    }
                }
            }
            let evidence = try XCTUnwrap(runtime.submit(at: now))
            XCTAssertEqual(evidence.outcome, .correct)
            MasteryEngine().record(evidence, in: &profile)
            seenMechanics.insert(encounter.mechanicID)
            now = now.addingTimeInterval(31)
        }
        // Prerequisite-gated stretch activities are covered by the dedicated
        // eligible-stretch test; this fresh learner loop checks core access.
        XCTAssertEqual(
            seenMechanics,
            MathMechanicID.adaptiveSet.subtracting([MathMechanicID.groupingGarden])
        )
        XCTAssertGreaterThanOrEqual(profile.progress(for: MathSkills.bonds10).state.readiness,
                                    SkillState.developing.readiness)
        XCTAssertTrue(graph.isEligible(MathSkills.missing, for: profile))
    }

}
