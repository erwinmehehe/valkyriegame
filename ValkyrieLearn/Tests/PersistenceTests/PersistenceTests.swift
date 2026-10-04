import XCTest
import SwiftData
import LearningCore
@testable import ValkyrieLearn

@MainActor final class PersistenceTests: XCTestCase {
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
        let state = try AppState(context: ModelContext(container))
        state.startWorkshop(MathFoundation.workshopExamples[1])
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
        let state = try AppState(context: ModelContext(container))
        state.startWorkshop(MathFoundation.workshopExamples[1]) // 4 + 3
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
    func testUnsupportedProfileDoesNotResetProgress() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = LearnerProfile(); profile.schemaVersion = 99
        store.snapshot.profileData = try JSONEncoder().encode(profile); try store.context.save()
        XCTAssertThrowsError(try store.loadProfile())
        XCTAssertEqual(try JSONDecoder().decode(LearnerProfile.self, from: store.snapshot.profileData).schemaVersion, 99)
    }
}
