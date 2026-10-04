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
}
