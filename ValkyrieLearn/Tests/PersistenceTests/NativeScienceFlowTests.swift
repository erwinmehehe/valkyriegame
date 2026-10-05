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
        scene.handleTap(at: CGPoint(x: 1145, y: 190))
        XCTAssertEqual(state.world, .storyTree, "Distant gate tap should approach before changing scenes.")
        scene.valkyrie.cancelTravel(); scene.milo.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 1070, y: 180)
        scene.handleTap(at: CGPoint(x: 1145, y: 190))
        XCTAssertEqual(state.world, .scienceWeatherTower)

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

    func testGreenhouseUsesV331ReferenceArtAndAdventureScale() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())

        XCTAssertNotNil(scene.childNode(withName: "scienceReferenceBackdrop"))
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        XCTAssertEqual(scene.valkyrie.yScale, 0.5, accuracy: 0.001)
        XCTAssertFalse(ArtSystem.frames(character: "Milo", pose: .idle).isEmpty)
        XCTAssertLessThan(scene.milo.calculateAccumulatedFrame().height, 160)

        scene.willLeave()
    }


    func testWeatherTowerRequiresTwoObservationsBeforeForecasting() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = WeatherTowerScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 825, y: 180)
        scene.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertEqual(scene.weatherStage, .arrive)
        XCTAssertNil(scene.selectedForecast)
        XCTAssertFalse(scene.creatureRouteOpen)

        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(
            scene.weatherStage,
            .arrive,
            "Afternoon observation should not replace the first comparison point."
        )

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        XCTAssertEqual(scene.weatherStage, .morningObserved)

        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)

        scene.willLeave()
    }

    func testWeatherTowerComparisonKeepsWrongForecastSafeAndRainPatternOpensRoute() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = WeatherTowerScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)

        scene.valkyrie.position = CGPoint(x: 825, y: 180)
        scene.handleTap(at: CGPoint(x: 875, y: 282))
        XCTAssertEqual(scene.selectedForecast, .sun)
        XCTAssertFalse(scene.creatureRouteOpen)
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)

        scene.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertEqual(scene.selectedForecast, .rain)
        XCTAssertTrue(scene.creatureRouteOpen)
        XCTAssertEqual(scene.weatherStage, .complete)
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 1140, y: 190)), "scienceCreatureGate")

        scene.willLeave()
    }

    func testWeatherTowerWorldSelectionSurvivesRestore() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceWeatherTower)

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .scienceWeatherTower)
    }

    func testWeatherTowerHomeReturnsWithoutMutatingMathAdventure() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let before = state.adventure
        state.travel(to: .scienceWeatherTower)

        let scene = WeatherTowerScene(state: state)
        scene.didMove(to: SKView())
        scene.handleTap(at: CGPoint(x: 55, y: 665))

        XCTAssertEqual(state.world, .storyTree)
        XCTAssertEqual(state.adventure, before)
        scene.willLeave()
    }

    func testWeatherTowerStageAndEvidencePersistAcrossRestore() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceWeatherTower)
        let scene = WeatherTowerScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)
        scene.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.scienceAdventure.weatherStage, .afternoonObserved)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.weatherObserve).evidence.isEmpty)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.weatherCompare).evidence.isEmpty)
    }

    func testWeatherForecastWritesPatternEvidenceAndPersistsOpenedRoute() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceWeatherTower)
        let scene = WeatherTowerScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        scene.valkyrie.position = CGPoint(x: 825, y: 180)
        scene.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertTrue(scene.creatureRouteOpen)
        scene.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertTrue(restored.scienceAdventure.creatureRouteOpen)
        XCTAssertEqual(restored.scienceAdventure.selectedForecast, .rain)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.weatherPattern).evidence.isEmpty)
    }


}
