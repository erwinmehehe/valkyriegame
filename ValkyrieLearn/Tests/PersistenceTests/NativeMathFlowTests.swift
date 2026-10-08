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
        let comparison = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.compareLength).first?.encounter
        )
        let units = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.nonstandardMeasure).first?.encounter
        )
        let sorting = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.classifyObjects).first?.encounter
        )
        let pictureGraph = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.pictureGraph).first?.encounter
        )
        let clock = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.clockHour).first?.encounter
        )
        let routines = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.timeDayparts).first?.encounter
        )
        let pesos = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.coinValues).first?.encounter
        )
        let grouping = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.equalGroups).first?.encounter
        )
        let reasoning = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.chooseStrategy).first?.encounter
        )
        let estimate = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.estimate10).first?.encounter
        )
        let countOn = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.countOn10).first?.encounter
        )
        let difference = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.findDifference10).first?.encounter
        )
        let rover = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.positionalLanguage).first?.encounter
        )
        let cases: [(LearningEncounter, CGPoint, CGPoint, String)] = [
            (MathFoundation.workshopExamples[0], CGPoint(x: 830, y: 265), CGPoint(x: 595, y: 235), "1 crystal in the cart."),
            (MathCastleEncounterCatalog.balanceScale[0], CGPoint(x: 670, y: 286), CGPoint(x: 670, y: 286), "Left pan selected."),
            (MathCastleEncounterCatalog.numberBondMachine[0], CGPoint(x: 925, y: 280), CGPoint(x: 555, y: 280), "1 crystal in the open part."),
            (MathCastleEncounterCatalog.tenFrameGate[0], CGPoint(x: 820, y: 344), CGPoint(x: 550, y: 310), "1 light placed."),
            (MathCastleEncounterCatalog.missingNumberBridge[0], CGPoint(x: 965, y: 330), CGPoint(x: 550, y: 335), "1 plank added."),
            (placeValue, CGPoint(x: 820, y: 310), CGPoint(x: 642, y: 192), "1 tens and 0 ones make 10."),
            (pattern, CGPoint(x: 820, y: 310), CGPoint(x: 660, y: 188), "A shape fills the pattern gap."),
            (shape, CGPoint(x: 820, y: 310), CGPoint(x: 662, y: 290), "Shape option 1 selected."),
            (comparison, CGPoint(x: 820, y: 310), CGPoint(x: 665, y: 190), "Left measurement selected."),
            (units, CGPoint(x: 820, y: 310), CGPoint(x: 914, y: 190), "1 equal-size measurement units placed."),
            (sorting, CGPoint(x: 820, y: 310), CGPoint(x: 662, y: 189), "1 of 5 objects sorted."),
            (pictureGraph, CGPoint(x: 820, y: 310), CGPoint(x: 662, y: 189), "1 picture tile placed in the graph."),
            (clock, CGPoint(x: 820, y: 310), CGPoint(x: 981, y: 264), "Clock hands now show 1:00."),
            (routines, CGPoint(x: 820, y: 310), CGPoint(x: 645, y: 192), "1 of 4 daily events sorted."),
            (pesos, CGPoint(x: 820, y: 310), CGPoint(x: 746, y: 245), "₱1 in selected teaching coins."),
            (grouping, CGPoint(x: 820, y: 310), CGPoint(x: 740, y: 189), "1 of 2 garden seeds placed."),
            (reasoning, CGPoint(x: 820, y: 310), CGPoint(x: 700, y: 319), "0 steps using counting on."),
            (estimate, CGPoint(x: 820, y: 310), CGPoint(x: 663, y: 188), "Fireflies flashed. Estimate dial is on 5."),
            (countOn, CGPoint(x: 820, y: 310), CGPoint(x: 922, y: 188), "1 of 1 jumps placed. Marker at 2.",
            (difference, CGPoint(x: 820, y: 310), CGPoint(x: 636, y: 190), "1 pairs matched. 0 leftovers collected."),
            (rover, CGPoint(x: 820, y: 310), CGPoint(x: 918, y: 190), "Rover moved 1 step on the grid.")
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


    func testShapeForgeCompositionUsesTwoRealNativeTrianglePlacements() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.composeShapes).first?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profileBefore = state.profile

        scene.handleTap(at: CGPoint(x: 655, y: 188)) // first half: orientation 0
        XCTAssertEqual(
            scene.instruction.text,
            "1 of 2 triangle halves placed. Pull Pip's lever when you're ready."
        )
        scene.handleTap(at: CGPoint(x: 875, y: 188)) // second half: orientation 2
        XCTAssertEqual(
            scene.instruction.text,
            "2 of 2 triangle halves placed. Pull Pip's lever when you're ready."
        )
        guard case .shapeForge(let model)? = state.runtime else {
            return XCTFail("Shape Forge runtime disappeared")
        }
        XCTAssertEqual(model.placedHalfTurns, [0, 2])
        XCTAssertFalse(model.completed, "Placement alone must not submit or award mastery")
        XCTAssertEqual(state.profile, profileBefore)
    }

    func testShapeForgeMirroringRequiresThreeNativeCells() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.symmetry).first?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profileBefore = state.profile

        scene.handleTap(at: CGPoint(x: 923, y: 343)) // row 0 -> circle
        scene.handleTap(at: CGPoint(x: 923, y: 289)) // row 1 -> circle
        scene.handleTap(at: CGPoint(x: 923, y: 235)) // row 2 -> circle
        scene.handleTap(at: CGPoint(x: 923, y: 235)) // row 2 -> square
        XCTAssertEqual(
            scene.instruction.text,
            "3 of 3 mirror cells filled. Pull Pip's lever when you're ready."
        )
        guard case .shapeForge(let model)? = state.runtime else {
            return XCTFail("Mirror runtime disappeared")
        }
        XCTAssertEqual(model.mirrorCells, [1, 1, 2])
        XCTAssertEqual(model.symmetryReference.map(\.rawValue), [1, 1, 2])
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, profileBefore)
    }


    func testMeasurementWorkshopNativeUnitPlacementPersistsAndDoesNotAutoScore() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.nonstandardMeasure)
                .first(where: { $0.encounter.targetQuantity == 4 })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = state.profile

        scene.handleTap(at: CGPoint(x: 914, y: 190))
        scene.handleTap(at: CGPoint(x: 914, y: 190))
        scene.handleTap(at: CGPoint(x: 914, y: 190))
        scene.handleTap(at: CGPoint(x: 726, y: 190)) // undo
        guard case .measurementWorkshop(let model)? = state.runtime else {
            return XCTFail("Measurement model not active")
        }
        XCTAssertEqual(model.placedUnits, 2)
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, before)
        XCTAssertEqual(
            scene.instruction.text,
            "2 equal-size measurement units placed. Pull Pip's lever when you're ready."
        )
    }


    func testDataBoardNativeSortingAndUndoAreIndependentUnscoredActions() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.classifyObjects).first?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = state.profile

        scene.handleTap(at: CGPoint(x: 662, y: 189))
        scene.handleTap(at: CGPoint(x: 820, y: 189))
        scene.handleTap(at: CGPoint(x: 1050, y: 363))
        guard case .dataBoard(let model)? = state.runtime else {
            return XCTFail("Expected native Data Board sorting runtime")
        }
        XCTAssertEqual(model.sortedBins, [1])
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, before)
        XCTAssertEqual(
            scene.instruction.text,
            "1 of 5 objects sorted. Pull Pip's lever when you're ready."
        )
    }

    func testDataBoardNativePictureGraphUsesThreeColumnTouchControls() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.pictureGraph).first?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = state.profile

        scene.handleTap(at: CGPoint(x: 662, y: 189))
        scene.handleTap(at: CGPoint(x: 820, y: 189))
        scene.handleTap(at: CGPoint(x: 978, y: 189))
        scene.handleTap(at: CGPoint(x: 1050, y: 361))
        guard case .dataBoard(let model)? = state.runtime else {
            return XCTFail("Expected native picture graph runtime")
        }
        XCTAssertEqual(model.graphTiles, [1, 1, 0])
        XCTAssertEqual(model.graphPlacementHistory, [1, 2])
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, before)
        XCTAssertEqual(
            scene.instruction.text,
            "2 picture tiles placed in the graph. Pull Pip's lever when you're ready."
        )
    }


    func testClockMarketNativeHourMinuteButtonsAndMoneyUndoWithoutPrematureScoring() throws {
        let clock = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.clockFiveMinutes)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 35 })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(clock))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = state.profile
        scene.handleTap(at: CGPoint(x: 981, y: 264))  // hour + 1
        scene.handleTap(at: CGPoint(x: 981, y: 185))  // minute + 5
        guard case .clockMarket(let clockModel)? = state.runtime else {
            return XCTFail("Missing Clock Market hands")
        }
        XCTAssertEqual(clockModel.hour, 1)
        XCTAssertEqual(clockModel.minute, 5)
        XCTAssertEqual(clockModel.handMoves, 2)
        XCTAssertFalse(clockModel.completed)
        XCTAssertEqual(state.profile, before)
        XCTAssertEqual(
            scene.instruction.text,
            "Clock hands now show 1:05. Pull Pip's lever when you're ready."
        )

        let market = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.coinValues)
                .first(where: { $0.encounter.context == "market.money.grade2"
                    && $0.encounter.targetQuantity == 21 })?.encounter
        )
        let marketState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        XCTAssertTrue(marketState.startWorkshop(market))
        let marketScene = MathCastleScene(state: marketState)
        marketScene.reducedMotion = true
        marketScene.didMove(to: SKView())
        defer { marketScene.willLeave() }
        marketScene.valkyrie.position = CGPoint(x: 490, y: 175)
        marketScene.handleTap(at: CGPoint(x: 820, y: 310))
        let marketBefore = marketState.profile
        marketScene.handleTap(at: CGPoint(x: 985, y: 245)) // ₱20
        marketScene.handleTap(at: CGPoint(x: 768, y: 245)) // ₱5
        marketScene.handleTap(at: CGPoint(x: 1042, y: 370)) // undo
        guard case .clockMarket(let moneyModel)? = marketState.runtime else {
            return XCTFail("Missing Philippine peso runtime")
        }
        XCTAssertEqual(moneyModel.coins, [20])
        XCTAssertEqual(moneyModel.totalPesos, 20)
        XCTAssertFalse(moneyModel.completed)
        XCTAssertEqual(marketState.profile, marketBefore)
    }


    func testGroupingGardenNativeBasketsAndUndoPreserveUnscoredWork() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.equalSharing)
                .first(where: { $0.encounter.initialQuantity == 2
                    && $0.encounter.targetQuantity == 2 })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profile = state.profile

        scene.handleTap(at: CGPoint(x: 740, y: 189)) // basket one
        scene.handleTap(at: CGPoint(x: 900, y: 189)) // basket two
        scene.handleTap(at: CGPoint(x: 1049, y: 372)) // undo last seed
        guard case .groupingGarden(let model)? = state.runtime else {
            return XCTFail("Grouping Garden runtime not active")
        }
        XCTAssertEqual(model.groups, [1, 0])
        XCTAssertEqual(model.unitsPlaced, 1)
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, profile)
        XCTAssertEqual(
            scene.instruction.text,
            "1 of 4 garden seeds placed. Pull Pip's lever when you're ready."
        )
    }

    func testGroupingGardenNativeFractionCutRequiresActualDividerMove() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.halves)
                .first(where: { $0.encounter.initialQuantity == 4
                    && $0.encounter.context == "garden.halves.row" })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profile = state.profile

        scene.handleTap(at: CGPoint(x: 767, y: 188)) // move to boundary two
        scene.handleTap(at: CGPoint(x: 873, y: 188)) // place divider
        guard case .groupingGarden(let model)? = state.runtime else {
            return XCTFail("Fraction cuts not active")
        }
        XCTAssertEqual(model.selectedBoundary, 2)
        XCTAssertEqual(model.cuts, [2])
        XCTAssertFalse(model.completed, "Cut placement alone cannot score")
        XCTAssertEqual(state.profile, profile)
        XCTAssertEqual(
            scene.instruction.text,
            "1 of 1 fraction cuts placed. Pull Pip's lever when you're ready."
        )
    }

    func testGroupingGardenNativeRepeatedAdditionMovesRealJumps() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.repeatedAddition)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 4 })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profile = state.profile

        scene.handleTap(at: CGPoint(x: 730, y: 188))
        scene.handleTap(at: CGPoint(x: 730, y: 188))
        scene.handleTap(at: CGPoint(x: 910, y: 188))
        guard case .groupingGarden(let model)? = state.runtime else {
            return XCTFail("Grouping jumps not active")
        }
        XCTAssertEqual(model.jumps, 1)
        XCTAssertEqual(model.currentJumpTotal, 4)
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, profile)
        XCTAssertEqual(
            scene.instruction.text,
            "1 jump makes a total of 4. Pull Pip's lever when you're ready."
        )
    }


    func testReasoningStudioNativeStrategyTapsRequireVisibleSteps() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.chooseStrategy).first?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profile = state.profile

        scene.handleTap(at: CGPoint(x: 700, y: 319)) // choose count-on
        scene.handleTap(at: CGPoint(x: 728, y: 187)) // add visible jump
        guard case .reasoningStudio(let model)? = state.runtime else {
            return XCTFail("Reasoning Studio runtime not active")
        }
        XCTAssertEqual(model.chosenStrategy, .countOn)
        XCTAssertEqual(model.strategySteps, 1)
        XCTAssertFalse(model.completed)
        XCTAssertEqual(state.profile, profile)
        XCTAssertEqual(
            scene.instruction.text,
            "1 step using counting on. Pull Pip's lever when you're ready."
        )
    }

    func testReasoningStudioNativeTwoStepConfirmAndResetDoNotScore() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.multiStep)
                .first(where: { $0.encounter.initialQuantity == 5
                    && $0.encounter.targetQuantity == 22
                    && $0.encounter.context == "studio.steps.addSubtract" })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(encounter))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profile = state.profile

        scene.handleTap(at: CGPoint(x: 944, y: 188)) // +1
        scene.handleTap(at: CGPoint(x: 820, y: 188)) // check first step
        scene.handleTap(at: CGPoint(x: 696, y: 188)) // -1
        scene.handleTap(at: CGPoint(x: 820, y: 188)) // check second step
        guard case .reasoningStudio(let built)? = state.runtime else {
            return XCTFail("Reasoning Studio disappeared")
        }
        XCTAssertEqual(built.observedIntermediate, 6)
        XCTAssertEqual(built.observedFinal, 5)
        XCTAssertFalse(built.completed)
        XCTAssertEqual(state.profile, profile)

        scene.handleTap(at: CGPoint(x: 1044, y: 364)) // reset both stages
        guard case .reasoningStudio(let cleared)? = state.runtime else {
            return XCTFail("Reasoning Studio reset failed")
        }
        XCTAssertNil(cleared.observedIntermediate)
        XCTAssertNil(cleared.observedFinal)
        XCTAssertEqual(cleared.workingValue, 5)
        XCTAssertEqual(state.profile, profile)
    }


    func testNumberTrailNativeFlashRequiresObservationAndCountOnUsesRealUndo() throws {
        let flash = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.estimate10).first?.encounter
        )
        let flashState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(flashState.startWorkshop(flash))
        let flashScene = MathCastleScene(state: flashState)
        flashScene.reducedMotion = true
        flashScene.didMove(to: SKView())
        defer { flashScene.willLeave() }
        flashScene.valkyrie.position = CGPoint(x: 490, y: 175)
        flashScene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = flashState.profile
        flashScene.handleTap(at: CGPoint(x: 663, y: 188))
        flashScene.handleTap(at: CGPoint(x: 837, y: 188)) // dial − 1
        guard case .numberTrail(let estimateModel)? = flashState.runtime else {
            return XCTFail("Expected estimate encounter")
        }
        XCTAssertTrue(estimateModel.flashObserved)
        XCTAssertEqual(estimateModel.dialValue, 4)
        XCTAssertNil(estimateModel.lockedEstimate)
        XCTAssertNil(estimateModel.lockedEstimate, "A flash alone cannot select an estimate")
        XCTAssertEqual(flashState.profile, before)

        let line = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.countOn10)
                .first(where: { $0.encounter.initialQuantity == 4
                    && $0.encounter.targetQuantity == 3 })?.encounter
        )
        let lineState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(lineState.startWorkshop(line))
        let scene = MathCastleScene(state: lineState)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let profileBefore = lineState.profile
        scene.handleTap(at: CGPoint(x: 922, y: 188))
        scene.handleTap(at: CGPoint(x: 922, y: 188))
        scene.handleTap(at: CGPoint(x: 718, y: 188))
        guard case .numberTrail(let countModel)? = lineState.runtime else {
            return XCTFail("Expected count-on runtime")
        }
        XCTAssertEqual(countModel.jumps, 1)
        XCTAssertEqual(countModel.markerNumber, 5)
        XCTAssertFalse(countModel.completed)
        XCTAssertEqual(lineState.profile, profileBefore)
        XCTAssertEqual(
            scene.instruction.text,
            "1 of 3 jumps placed. Marker at 5. Pull Pip's lever when you're ready."
        )
    }


    func testDifferenceBridgeAndMapRoverRequireNativeTouchBeforeScoring() throws {
        let difference = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.findDifference10)
                .first(where: { $0.encounter.initialQuantity == 7
                    && $0.encounter.targetQuantity == 3 })?.encounter
        )
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(difference))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))
        let before = state.profile
        scene.handleTap(at: CGPoint(x: 636, y: 190)) // first matching pair
        scene.handleTap(at: CGPoint(x: 636, y: 190)) // second
        scene.handleTap(at: CGPoint(x: 760, y: 190)) // undo pair
        guard case .differenceBridge(let result)? = state.runtime else {
            return XCTFail("Difference Bridge not active")
        }
        XCTAssertEqual(result.matchedPairs, 1)
        XCTAssertEqual(result.collectedLeftovers, 0)
        XCTAssertFalse(result.completed)
        XCTAssertEqual(state.profile, before)

        let position = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.positionalLanguage)
                .first(where: { $0.encounter.initialQuantity == 0
                    && $0.encounter.targetQuantity == 1 })?.encounter
        )
        let roverState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        XCTAssertTrue(roverState.startWorkshop(position))
        let roverScene = MathCastleScene(state: roverState)
        roverScene.reducedMotion = true
        roverScene.didMove(to: SKView())
        defer { roverScene.willLeave() }
        roverScene.valkyrie.position = CGPoint(x: 490, y: 175)
        roverScene.handleTap(at: CGPoint(x: 820, y: 310))
        let roverBefore = roverState.profile
        roverScene.handleTap(at: CGPoint(x: 918, y: 190)) // right
        roverScene.handleTap(at: CGPoint(x: 1016, y: 190)) // undo
        guard case .routeExplorer(let route)? = roverState.runtime else {
            return XCTFail("Route Explorer not active")
        }
        XCTAssertEqual(route.visitedCells, [0])
        XCTAssertEqual(route.movesTaken, 0)
        XCTAssertFalse(route.completed)
        XCTAssertEqual(roverState.profile, roverBefore)
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
        let sorting = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.classifyObjects).first?.encounter
        )
        let pictureGraph = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.pictureGraph).first?.encounter
        )
        let clock = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.clockHour).first?.encounter
        )
        let routines = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.timeDayparts).first?.encounter
        )
        let pesos = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.coinValues).first?.encounter
        )
        let grouping = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.equalGroups).first?.encounter
        )
        let reasoning = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.chooseStrategy).first?.encounter
        )
        let estimate = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.estimate10).first?.encounter
        )
        let countOn = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.countOn10).first?.encounter
        )
        let difference = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.findDifference10).first?.encounter
        )
        let rover = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.positionalLanguage).first?.encounter
        )
        let examples = [MathFoundation.workshopExamples[0], MathCastleEncounterCatalog.balanceScale[0],
            MathCastleEncounterCatalog.numberBondMachine[0], MathCastleEncounterCatalog.tenFrameGate[0],
            MathCastleEncounterCatalog.missingNumberBridge[0], placeValue, pattern, shape, sorting, pictureGraph, clock, routines, pesos, grouping, reasoning, estimate, countOn, difference, rover]
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
