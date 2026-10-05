import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeScienceFlowTests: XCTestCase {
    func testStoryTreeScienceSignRoutesToGreenhouseWorld() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state)
        scene.didMove(to: SKView())

        XCTAssertEqual(scene.targetName(at: CGPoint(x: 580, y: 515)), "scienceLab")

        scene.valkyrie.position = CGPoint(x: 580, y: 450)
        scene.handleTap(at: CGPoint(x: 580, y: 515))

        XCTAssertEqual(state.world, .scienceLab)
        scene.willLeave()
    }

    func testGreenhouseRequiresObservationBeforeChangingConditions() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(scene.greenhouseStage, .arrive)
        XCTAssertFalse(scene.greenhouseComplete)

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        XCTAssertEqual(scene.greenhouseStage, .inspected)

        scene.willLeave()
    }

    func testGreenhouseInvestigationUsesWaterThenLightAndOpensWeatherRoute() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        XCTAssertEqual(scene.greenhouseStage, .inspected)

        scene.valkyrie.position = CGPoint(x: 850, y: 185)
        scene.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertEqual(
            scene.greenhouseStage,
            .inspected,
            "Light should not skip the dry-soil observation and water test."
        )

        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(scene.greenhouseStage, .watered)
        XCTAssertFalse(scene.greenhouseComplete)

        scene.valkyrie.position = CGPoint(x: 850, y: 185)
        scene.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertEqual(scene.greenhouseStage, .lit)
        XCTAssertTrue(scene.greenhouseComplete)
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 1145, y: 190)), "scienceWeatherGate")

        scene.willLeave()
    }

    func testScienceWorldSelectionSurvivesRestore() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceLab)

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .scienceLab)
    }

    func testScienceHomeReturnsWithoutMutatingMathAdventure() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let before = state.adventure
        state.travel(to: .scienceLab)

        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())
        scene.handleTap(at: CGPoint(x: 55, y: 665))

        XCTAssertEqual(state.world, .storyTree)
        XCTAssertEqual(state.adventure, before)
        scene.willLeave()
    }

    func testGreenhouseStagePersistsAcrossSceneRecreation() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(scene.greenhouseStage, .watered)
        scene.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.scienceAdventure.greenhouseStage, .watered)
        XCTAssertFalse(restored.scienceAdventure.greenhouseComplete)
    }

    func testGreenhouseWritesScienceEvidenceAndPlacementReadiness() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))

        XCTAssertFalse(state.profile.progress(for: ScienceSkills.noticeDetails).evidence.isEmpty)
        XCTAssertFalse(state.profile.progress(for: ScienceSkills.plantNeeds).evidence.isEmpty)
        XCTAssertTrue(state.profile.placementReadySkillIDs?.contains(ScienceSkills.plantNeeds) == true)
        scene.willLeave()
    }

}
