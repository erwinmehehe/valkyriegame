import XCTest
import SwiftData
import SpriteKit
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
    func testWorkshopTracksRepetitionWithoutMasteryAndCannotDiscardScoredWork() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let example = MathFoundation.workshopExamples[0]
        XCTAssertTrue(state.startWorkshop(example))
        for _ in 0..<7 { state.addCrystal() }; _ = state.submit()
        XCTAssertFalse(state.startWorkshop(example))
        XCTAssertEqual(state.profile.progress(for: example.skillID).state, .new)
        XCTAssertTrue(state.profile.usedFingerprints.contains(example.fingerprint))
        let scored = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        _ = scored.prepareNext()
        let before = scored.cart?.encounter
        XCTAssertFalse(scored.startWorkshop(MathFoundation.workshopExamples[1]))
        XCTAssertEqual(scored.cart?.encounter, before)
    }
    func testUnsupportedProfileDoesNotResetProgress() async throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = LearnerProfile(); profile.schemaVersion = 99
        store.snapshot.profileData = try JSONEncoder().encode(profile); try store.context.save()
        XCTAssertThrowsError(try store.loadProfile())
        XCTAssertEqual(try JSONDecoder().decode(LearnerProfile.self, from: store.snapshot.profileData).schemaVersion, 99)
    }
    func testBalanceScaleShowsHeavierSideLowerAndResetsForEquality() async throws {
        let mechanic = BalanceScaleMechanic()
        let beam = try XCTUnwrap(mechanic.childNode(withName: "scaleBeam"))
        let left = try XCTUnwrap(mechanic.childNode(withName: "scaleLeft"))
        let right = try XCTUnwrap(mechanic.childNode(withName: "scaleRight"))
        for (leftQuantity, rightQuantity) in [(9, 6), (5, 8), (7, 7)] {
            let encounter = LearningEncounter(id: "scale-render", skillID: MathSkills.compare,
                mechanicID: MathMechanicID.balanceScale, operation: .comparison,
                initialQuantity: leftQuantity, targetQuantity: rightQuantity, prompt: "Compare")
            mechanic.render(try BalanceScaleModel(encounter: encounter))
            if leftQuantity > rightQuantity {
                XCTAssertLessThan(left.position.y, right.position.y)
                XCTAssertGreaterThan(beam.zRotation, 0)
            } else if leftQuantity < rightQuantity {
                XCTAssertGreaterThan(left.position.y, right.position.y)
                XCTAssertLessThan(beam.zRotation, 0)
            } else {
                XCTAssertEqual(left.position.y, right.position.y)
                XCTAssertEqual(beam.zRotation, 0)
            }
        }
    }
    func testBalanceScaleCrystalTapsResolveToTheirSideAfterTilt() async throws {
        let container = try LearningStore.container(inMemory: true)
        let scene = AdventureScene(state: try AppState(context: ModelContext(container)))
        let mechanic = BalanceScaleMechanic()
        mechanic.position = CGPoint(x: 640, y: 360)
        scene.addChild(mechanic)
        for encounter in MathCastleEncounterCatalog.balanceScale.prefix(2) {
            mechanic.render(try BalanceScaleModel(encounter: encounter))
            for side in ["scaleLeft", "scaleRight"] {
                let tokens = mechanic.children.flatMap { $0.children }.filter { $0.name == side }
                XCTAssertFalse(tokens.isEmpty)
                for token in tokens {
                    let point = token.convert(CGPoint.zero, to: scene)
                    XCTAssertEqual(scene.targetName(at: point), side)
                }
            }
        }
    }

    func testTenFrameQuickLookPreviewExpiresWithoutReplayingOnRender() async throws {
        let encounter = LearningEncounter(id: "quick-look-render", skillID: MathSkills.subitizing,
            mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
            operation: .quantityMatching, initialQuantity: 0, targetQuantity: 5,
            prompt: "How many lights flashed?", context: "quickLook")
        let mechanic = TenFrameGateMechanic()
        let current = try TenFrameModel(encounter: encounter)
        mechanic.render(current)
        let cells = try XCTUnwrap(mechanic.childNode(withName: "tenFrameCells")).children.compactMap { $0 as? SKShapeNode }
        XCTAssertEqual(cells.count, 10)
        // SpriteKit stores resolved colors; compare against the same rendering
        // conversion rather than UIColor's dynamic system-color identity.
        let reference = SKShapeNode()
        reference.fillColor = .systemTeal
        func isLit(_ cell: SKShapeNode) -> Bool {
            cell.fillColor.cgColor == reference.fillColor.cgColor
        }
        XCTAssertEqual(cells.filter(isLit).count, 5)
        XCTAssertTrue(cells.allSatisfy { $0.name == "tenFramePreview" })
        mechanic.render(current)
        XCTAssertEqual(cells.filter(isLit).count, 5)

        let expired = try TenFrameModel(encounter: encounter,
            at: Date().addingTimeInterval(-current.previewDuration - 1))
        mechanic.render(expired)
        XCTAssertEqual(cells.filter(isLit).count, 0)
        XCTAssertTrue(cells.allSatisfy { $0.name == "tenFrameCell" })
        mechanic.render(expired)
        XCTAssertEqual(cells.filter(isLit).count, 0)
        XCTAssertFalse(mechanic.hasActions())
    }

}
