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

        XCTAssertEqual(scene.targetName(at: CGPoint(x: 705, y: 585)), "scienceLab")

        scene.valkyrie.position = CGPoint(x: 580, y: 450)
        scene.handleTap(at: CGPoint(x: 705, y: 585))

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

    func testGreenhouseUsesNativeSharpStageAndAdventureScale() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())

        XCTAssertNotNil(scene.childNode(withName: "scienceNativeBackdrop"))
        XCTAssertNotNil(scene.childNode(withName: "scienceGreenhouseFrame"))
        XCTAssertNotNil(scene.childNode(withName: "scienceGround"))
        XCTAssertNil(scene.childNode(withName: "scienceLegacyMatte"))
        XCTAssertNotNil(scene.childNode(withName: "scienceWaterBed"))
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        XCTAssertEqual(scene.valkyrie.yScale, 0.5, accuracy: 0.001)
        XCTAssertFalse(ArtSystem.frames(character: "Milo", pose: .idle).isEmpty)
        XCTAssertLessThan(scene.milo.calculateAccumulatedFrame().height, 160)

        scene.willLeave()
    }


    func testGreenhouseVisuallyPrioritizesTheCurrentExperimentStep() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let bench = try XCTUnwrap(scene.childNode(withName: "scienceSeedBench"))
        let valve = try XCTUnwrap(scene.childNode(withName: "scienceWaterValve"))
        let prism = try XCTUnwrap(scene.childNode(withName: "scienceSunPrism"))
        let gate = try XCTUnwrap(scene.childNode(withName: "scienceWeatherGate"))

        XCTAssertEqual(bench.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(valve.alpha, 0.5)
        XCTAssertLessThan(prism.alpha, valve.alpha)
        XCTAssertLessThan(gate.alpha, 0.5)
        XCTAssertNotNil(bench.action(forKey: "scienceFocusPulse"))

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        XCTAssertEqual(scene.greenhouseStage, .inspected)
        XCTAssertEqual(valve.alpha, 1.0, accuracy: 0.001)
        XCTAssertNotNil(valve.action(forKey: "scienceFocusPulse"))
        XCTAssertNotNil(valve.action(forKey: "scienceActiveSpin"))

        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(scene.greenhouseStage, .watered)
        XCTAssertEqual(prism.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(gate.alpha, 0.5)

        scene.reducedMotion = true
        scene.update(0)
        XCTAssertNil(prism.action(forKey: "scienceFocusPulse"))
        XCTAssertNil(valve.action(forKey: "scienceActiveSpin"))
        XCTAssertEqual(scene.camera?.position.x ?? 0, 640, accuracy: 0.001)
        XCTAssertEqual(scene.camera?.position.y ?? 0, 360, accuracy: 0.001)
    }

    func testWeatherTowerVisuallyPrioritizesTheCurrentObservationStep() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .scienceWeatherTower)
        let scene = WeatherTowerScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let morning = try XCTUnwrap(scene.childNode(withName: "scienceMorningWeather"))
        let afternoon = try XCTUnwrap(scene.childNode(withName: "scienceAfternoonWeather"))
        let forecast = try XCTUnwrap(scene.childNode(withName: "scienceForecastBase"))
        let gate = try XCTUnwrap(scene.childNode(withName: "scienceCreatureGate"))

        XCTAssertEqual(morning.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(afternoon.alpha, 0.5)
        XCTAssertLessThan(forecast.alpha, afternoon.alpha)
        XCTAssertLessThan(gate.alpha, 0.5)
        XCTAssertNotNil(morning.action(forKey: "scienceFocusPulse"))

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        XCTAssertEqual(scene.weatherStage, .morningObserved)
        XCTAssertEqual(afternoon.alpha, 1.0, accuracy: 0.001)
        XCTAssertNotNil(afternoon.action(forKey: "scienceFocusPulse"))

        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)
        XCTAssertEqual(forecast.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(gate.alpha, 0.5)

        scene.reducedMotion = true
        scene.update(0)
        XCTAssertNil(forecast.action(forKey: "scienceFocusPulse"))
        XCTAssertEqual(scene.camera?.position.x ?? 0, 640, accuracy: 0.001)
        XCTAssertEqual(scene.camera?.position.y ?? 0, 360, accuracy: 0.001)
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


    func testWeatherTowerComparisonKeepsWrongForecastSafeAndRainPatternOpensRouteCreatureContinuation() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.travel(to: .scienceWeatherTower)
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

        scene.handleTap(at: CGPoint(x: 1140, y: 190))
        XCTAssertEqual(state.world, .scienceWeatherTower, "Distant Creature Grove tap should approach first.")
        scene.valkyrie.cancelTravel(); scene.milo.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 1065, y: 180)
        scene.handleTap(at: CGPoint(x: 1140, y: 190))
        XCTAssertEqual(state.world, .scienceCreatureGrove)

        scene.willLeave()
    }

    func testCreatureGroveRequiresAnimalObservationBeforeHabitatChoice() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 520, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(scene.groveStage, .arrive)
        XCTAssertNil(scene.selectedHabitat)
        XCTAssertFalse(scene.groveRestored)

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        XCTAssertEqual(scene.groveStage, .animalObserved)

        scene.willLeave()
    }

    func testCreatureGroveRejectsBareRidgeAndMatchesPondEvidence() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        XCTAssertEqual(scene.groveStage, .animalObserved)

        scene.valkyrie.position = CGPoint(x: 610, y: 180)
        scene.handleTap(at: CGPoint(x: 692, y: 270))
        XCTAssertEqual(scene.selectedHabitat, .dryRidge)
        XCTAssertEqual(scene.groveStage, .animalObserved)

        scene.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(scene.selectedHabitat, .pondEdge)
        XCTAssertEqual(scene.groveStage, .habitatMatched)

        scene.willLeave()
    }

    func testCreatureGroveBodyPartEvidenceMustPrecedeFinalHabitatComparison() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        scene.valkyrie.position = CGPoint(x: 610, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(scene.groveStage, .habitatMatched)

        scene.valkyrie.position = CGPoint(x: 920, y: 180)
        scene.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertEqual(scene.groveStage, .habitatMatched)
        XCTAssertFalse(scene.groveRestored)

        scene.valkyrie.position = CGPoint(x: 750, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        XCTAssertEqual(scene.groveStage, .bodyPartObserved)

        scene.willLeave()
    }

    func testCreatureGroveComparisonRestoresEnvironmentAndCompletesScienceFinale() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        scene.valkyrie.position = CGPoint(x: 610, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        scene.valkyrie.position = CGPoint(x: 750, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        XCTAssertEqual(scene.groveStage, .bodyPartObserved)

        scene.valkyrie.position = CGPoint(x: 920, y: 180)
        scene.handleTap(at: CGPoint(x: 1085, y: 285))
        XCTAssertEqual(scene.groveStage, .bodyPartObserved)
        XCTAssertFalse(scene.groveRestored)

        scene.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertEqual(scene.groveStage, .complete)
        XCTAssertTrue(scene.groveRestored)
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 1150, y: 185)), "scienceGroveFinale")

        scene.handleTap(at: CGPoint(x: 1150, y: 185))
        XCTAssertTrue(scene.groveRestored)

        scene.willLeave()
    }

    func testCreatureGroveWorldSelectionSurvivesRestore() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceCreatureGrove)

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .scienceCreatureGrove)
    }

    func testCreatureGroveHomeReturnsWithoutMutatingMathAdventure() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        let before = state.adventure
        state.travel(to: .scienceCreatureGrove)

        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())
        scene.handleTap(at: CGPoint(x: 55, y: 665))

        XCTAssertEqual(state.world, .storyTree)
        XCTAssertEqual(state.adventure, before)
        scene.willLeave()
    }

    func testGreenhouseStagePersistsAcrossSceneRecreationCreatureContinuation() throws {
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
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.plantNeeds).evidence.isEmpty)
    }

    func testWeatherTowerStageAndEvidencePersistAcrossRestoreCreatureContinuation() throws {
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
        XCTAssertEqual(restored.scienceAdventure.weatherStage, .complete)
        XCTAssertTrue(restored.scienceAdventure.creatureRouteOpen)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.weatherCompare).evidence.isEmpty)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.weatherPattern).evidence.isEmpty)
    }

    func testCreatureGroveProgressAndEvidencePersistAcrossRestore() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceCreatureGrove)
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        scene.valkyrie.position = CGPoint(x: 610, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        scene.valkyrie.position = CGPoint(x: 750, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        scene.valkyrie.position = CGPoint(x: 920, y: 180)
        scene.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertTrue(scene.groveRestored)
        scene.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.scienceAdventure.groveStage, .complete)
        XCTAssertTrue(restored.scienceAdventure.groveRestored)
        XCTAssertEqual(restored.scienceAdventure.selectedHabitat, .pondEdge)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.animalNeeds).evidence.isEmpty)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.habitatMatch).evidence.isEmpty)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.bodyPartFunction).evidence.isEmpty)
        XCTAssertFalse(restored.profile.progress(for: ScienceSkills.compareHabitats).evidence.isEmpty)
    }

    func testScienceEntryResumesFurthestUnlockedWorld() throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .scienceCreatureGrove)
        let scene = CreatureGroveScene(state: state)
        scene.didMove(to: SKView())

        scene.valkyrie.position = CGPoint(x: 245, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 270))
        scene.valkyrie.position = CGPoint(x: 610, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        scene.valkyrie.position = CGPoint(x: 750, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        scene.valkyrie.position = CGPoint(x: 920, y: 180)
        scene.handleTap(at: CGPoint(x: 975, y: 285))
        scene.willLeave()

        state.travel(to: .storyTree)
        state.enterScienceLab()
        XCTAssertEqual(state.world, .scienceCreatureGrove)
    }


}
