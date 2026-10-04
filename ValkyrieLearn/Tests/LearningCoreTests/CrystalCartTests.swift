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
        let unsupported = LearningEncounter(id: "future", skillID: MathSkills.subtraction,
            operation: .subtraction, initialQuantity: 5, targetQuantity: 2, prompt: "Future")
        XCTAssertThrowsError(try CrystalCartModel(encounter: unsupported))
    }

    func testNumberBondMachineProducesEvidence() throws {
        let encounter = MathCastleEncounterCatalog.numberBondMachine[1]
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
        XCTAssertEqual(model.submit()?.outcome, .correct)
        XCTAssertFalse(model.increment())
        XCTAssertFalse(model.decrement())
    }

    func testMathCastleEncounterCatalogIsSupportedUniqueAndSmall() {
        let encounters = MathCastleEncounterCatalog.all

        XCTAssertGreaterThan(encounters.count, MathFoundation.encounters.count)
        XCTAssertLessThan(encounters.count, 40)
        XCTAssertEqual(Set(encounters.map(\.id)).count, encounters.count)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, encounters.count)
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

}
