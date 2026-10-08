import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeNavigationTests: XCTestCase {
    func testTapGestureAcceptsSmallMovementButRejectsSwipesAndReturnTrips() {
        var gesture = SceneTapGesture<Int>()
        let target = CGPoint(x: 400, y: 300)
        XCTAssertNil(gesture.end(1, at: target), "A release without a press is not a tap.")
        gesture.begin(1, at: target)
        gesture.move(1, to: CGPoint(x: 404, y: 302))
        XCTAssertEqual(gesture.end(1, at: CGPoint(x: 405, y: 303)), CGPoint(x: 405, y: 303))

        gesture.begin(2, at: target)
        // A fast swipe may arrive without an intermediate touchesMoved callback.
        XCTAssertNil(gesture.end(2, at: CGPoint(x: 600, y: 300)))
        gesture.begin(3, at: target)
        gesture.move(3, to: CGPoint(x: 600, y: 300))
        gesture.move(3, to: target)
        XCTAssertNil(gesture.end(3, at: target), "Returning to the start must not turn a swipe into an answer.")

        gesture.begin(4, at: target)
        XCTAssertEqual(gesture.end(4, at: target), target, "A swipe must not disable the next deliberate tap.")
    }

    func testExtraContactsCannotStealOrRepeatATap() {
        var gesture = SceneTapGesture<Int>()
        let target = CGPoint(x: 400, y: 300)
        gesture.begin(1, at: target)
        gesture.begin(2, at: CGPoint(x: 900, y: 600))
        gesture.move(2, to: .zero)
        XCTAssertNil(gesture.end(2, at: .zero))
        XCTAssertEqual(gesture.end(1, at: target), target)
        XCTAssertNil(gesture.end(1, at: target), "One contact must dispatch only once.")
        XCTAssertNil(gesture.end(2, at: target), "A previously ignored contact must stay ignored.")
    }

    func testCancelledAndAbandonedTapsCannotActivateOnRelease() {
        var gesture = SceneTapGesture<Int>()
        let target = CGPoint(x: 400, y: 300)
        gesture.begin(1, at: target)
        gesture.cancel(2)
        XCTAssertEqual(gesture.end(1, at: target), target)
        gesture.begin(3, at: target)
        gesture.cancel(3)
        XCTAssertNil(gesture.end(3, at: target))
        gesture.begin(4, at: target)
        gesture.reset() // Leaving a scene clears its unfinished gesture.
        XCTAssertNil(gesture.end(4, at: target))
        gesture.begin(5, at: target)
        XCTAssertEqual(gesture.end(5, at: target), target)
    }

    private func waitUntil(_ condition: @escaping () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(5)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 25_000_000)
        }
        XCTAssertTrue(condition(), "Story Tree travel did not finish.")
    }

    private func makeState() throws -> AppState {
        try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
    }

    func testOneTapWalksAndEntersEveryWorld() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let cases: [(CGPoint, AppState.World)] = [
            (CGPoint(x: 835, y: 535), .mathCastle),
            (CGPoint(x: 705, y: 585), .scienceLab),
            (CGPoint(x: 505, y: 515), .puzzlePalace),
            (CGPoint(x: 150, y: 430), .wordGarden)
        ]
        for (beacon, world) in cases {
            let state = try makeState()
            let scene = StoryTreeScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)
            // Start at the opposite end so every entrance exercises live travel.
            if world == .wordGarden { scene.valkyrie.position = CGPoint(x: 795, y: 450) }
            scene.handleTap(at: beacon)
            let action = scene.valkyrie.action(forKey: "travel")
            scene.handleTap(at: beacon)
            XCTAssertTrue(scene.valkyrie.action(forKey: "travel") === action,
                          "Repeated entrance taps must not restart travel.")
            try await waitUntil { state.world == world }
            XCTAssertNil(scene.childNode(withName: "decorativeAttentionCue"))
            scene.willLeave()
        }
    }

    func testRedirectingAndLeavingCancelThePreviousEntrance() async throws {
        let state = try makeState()
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        scene.handleTap(at: CGPoint(x: 505, y: 515))
        try await waitUntil { state.world == .puzzlePalace }
        XCTAssertEqual(state.world, .puzzlePalace)

        state.travel(to: .storyTree)
        scene.valkyrie.position = CGPoint(x: 190, y: 170)
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        scene.willLeave()
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        scene.handleTap(at: CGPoint(x: 705, y: 585))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertEqual(state.world, .storyTree)
    }

    func testPathTapLandsBetweenWaypointsAndCancelsWorldSelection() async throws {
        let state = try makeState()
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        scene.valkyrie.position = CGPoint(x: 650, y: 450)
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        scene.walkIfValid(CGPoint(x: 625, y: 450))
        try await waitUntil { scene.valkyrie.action(forKey: "travel") == nil }
        XCTAssertEqual(scene.valkyrie.position.x, 625, accuracy: 1)
        XCTAssertEqual(scene.valkyrie.position.y, 450, accuracy: 1)
        XCTAssertEqual(state.world, .storyTree)
        XCTAssertTrue(scene.isOnPath(scene.pip.position))
    }

    func testMotionToggleStopsBeaconAndRewardPulsesAndResetsForeground() throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = try store.loadProfile()
        _ = profile.unlockStoryReward(.moonLantern)
        try store.save(profile: profile, adventure: MathAdventure(continuingLearner: true),
                       sound: true, reducedMotion: false, world: "storyTree")
        let state = try AppState(context: ModelContext(container))
        let scene = StoryTreeScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        let castle = try XCTUnwrap(scene.childNode(withName: "castle"))
        let halo = try XCTUnwrap(castle.children.first {
            ($0.userData?["decorativeMotionRole"] as? String) == "pulse"
        })
        let lantern = try XCTUnwrap(scene.childNode(withName: "moonLantern"))
        let glow = try XCTUnwrap(lantern.children.first {
            ($0.userData?["decorativeMotionRole"] as? String) == "pulse"
        })
        let foreground = try XCTUnwrap(scene.childNode(withName: "foregroundLeft"))
        foreground.position = CGPoint(x: 78, y: 83)
        foreground.zRotation = 0.02
        scene.reducedMotion = true
        XCTAssertNil(halo.action(forKey: "ambientPulse"))
        XCTAssertNil(glow.action(forKey: "ambientPulse"))
        XCTAssertEqual(halo.alpha, 1)
        XCTAssertEqual(foreground.position, CGPoint(x: 75, y: 80))
        XCTAssertEqual(foreground.zRotation, 0)
        scene.reducedMotion = false
        XCTAssertNotNil(halo.action(forKey: "ambientPulse"))
        XCTAssertNotNil(glow.action(forKey: "ambientPulse"))
    }
    func testWorldHUDUsesDistinctEmblemsAndKeepsTitlesInsideTheirPlates() throws {
        let state = try makeState()
        let cases: [(AppState.World, String, (AppState) -> AdventureScene)] = [
            (.storyTree, "✦", { StoryTreeScene(state: $0) }),
            (.mathCastle, "◆", { MathCastleScene(state: $0) }),
            (.wordGarden, "✿", { WordGardenScene(state: $0) }),
            (.sunmillCrossing, "✿", { WordGardenScene(state: $0) }),
            (.storyHollow, "✿", { WordGardenScene(state: $0) }),
            (.scienceLab, "⚗", { ScienceLabScene(state: $0) }),
            (.scienceWeatherTower, "⚗", { WeatherTowerScene(state: $0) }),
            (.scienceCreatureGrove, "⚗", { CreatureGroveScene(state: $0) }),
            (.puzzlePalace, "◈", { PuzzlePalaceScene(state: $0) }),
            (.memoryBridge, "◈", { PuzzlePalaceScene(state: $0) }),
            (.stopGoOrbs, "◈", { PuzzlePalaceScene(state: $0) }),
            (.sortingPedestal, "◈", { PuzzlePalaceScene(state: $0) }),
            (.resortVault, "◈", { PuzzlePalaceScene(state: $0) }),
            (.mirrorHall, "◈", { PuzzlePalaceScene(state: $0) }),
            (.pathTiles, "◈", { PuzzlePalaceScene(state: $0) }),
            (.commandGears, "◈", { PuzzlePalaceScene(state: $0) }),
            (.bugLantern, "◈", { PuzzlePalaceScene(state: $0) }),
            (.bugLanternRepair, "◈", { PuzzlePalaceScene(state: $0) })
        ]
        for (world, symbol, makeScene) in cases {
            state.travel(to: world)
            let scene = makeScene(state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())
            let emblem = try XCTUnwrap(scene.childNode(withName: "decorativeWorldEmblem"))
            XCTAssertEqual(emblem.children.compactMap { ($0 as? SKLabelNode)?.text }.first, symbol)
            let title = try XCTUnwrap(scene.childNode(withName: "worldTitle"))
            let plate = try XCTUnwrap(scene.childNode(withName: "worldTitleBackdrop"))
            XCTAssertTrue(plate.calculateAccumulatedFrame().contains(title.calculateAccumulatedFrame()),
                          "\(world) title must fit in its themed plate.")
            XCTAssertTrue(plate.calculateAccumulatedFrame().contains(emblem.calculateAccumulatedFrame()),
                          "\(world) emblem must fit in its themed plate.")
            XCTAssertFalse(emblem.calculateAccumulatedFrame().intersects(title.calculateAccumulatedFrame()),
                           "\(world) emblem must not cover its title text.")
            XCTAssertFalse(emblem.calculateAccumulatedFrame().intersects(scene.layout.interactionStage))
            XCTAssertNotEqual(scene.targetName(at: emblem.position), "decorativeWorldEmblem")
            scene.willLeave()
        }
    }

    func testPuzzleAndScienceHomeControlsClearlyReturnToStoryTree() throws {
        func firstLabelText(in node: SKNode) -> String? {
            if let label = node as? SKLabelNode, let text = label.text {
                return text
            }
            for child in node.children {
                if let text = firstLabelText(in: child) {
                    return text
                }
            }
            return nil
        }

        let state = try makeState()
        let cases: [(AppState.World, String, (AppState) -> AdventureScene)] = [
            (.puzzlePalace, "home", { PuzzlePalaceScene(state: $0) }),
            (.scienceLab, "scienceHome", { ScienceLabScene(state: $0) }),
            (.scienceWeatherTower, "scienceWeatherHome", { WeatherTowerScene(state: $0) }),
            (.scienceCreatureGrove, "scienceGroveHome", { CreatureGroveScene(state: $0) })
        ]

        for (world, controlName, makeScene) in cases {
            state.travel(to: world)
            let scene = makeScene(state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())
            let home = try XCTUnwrap(scene.childNode(withName: controlName))
            XCTAssertEqual(firstLabelText(in: home), "⌂")
            XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().width, 60)
            XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().height, 60)
            scene.willLeave()
        }
    }

    func testGreenhouseVisuallyPrioritizesTheCurrentExperimentStep() throws {
        let state = try makeState()
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
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

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        XCTAssertEqual(scene.greenhouseStage, .inspected)
        XCTAssertEqual(valve.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(prism.alpha, 0.5)

        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(scene.greenhouseStage, .watered)
        XCTAssertEqual(prism.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(gate.alpha, 0.5)

        scene.valkyrie.position = CGPoint(x: 850, y: 185)
        scene.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertEqual(scene.greenhouseStage, .lit)
        XCTAssertFalse(scene.greenhouseComplete)
        XCTAssertLessThan(gate.alpha, 0.5)

        // Fresh Science v2 playthroughs now finish three physical
        // Greenhouse field-study checks before the route opens.
        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        scene.valkyrie.position = CGPoint(x: 850, y: 185)
        scene.handleTap(at: CGPoint(x: 940, y: 245))

        XCTAssertTrue(scene.greenhouseComplete)
        XCTAssertEqual(gate.alpha, 1.0, accuracy: 0.001)
    }

    func testWeatherTowerVisuallyPrioritizesTheCurrentObservationStep() throws {
        let state = try makeState()
        state.travel(to: .scienceWeatherTower)
        let scene = WeatherTowerScene(state: state)
        scene.reducedMotion = true
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

        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        XCTAssertEqual(scene.weatherStage, .morningObserved)
        XCTAssertEqual(afternoon.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(forecast.alpha, 0.5)

        scene.valkyrie.position = CGPoint(x: 605, y: 180)
        scene.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(scene.weatherStage, .afternoonObserved)
        XCTAssertEqual(forecast.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(gate.alpha, 0.5)

        scene.valkyrie.position = CGPoint(x: 825, y: 180)
        scene.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertEqual(scene.weatherStage, .complete)
        XCTAssertFalse(scene.creatureRouteOpen)
        XCTAssertLessThan(gate.alpha, 0.5)

        // Retention checks reuse the morning flag and forecast vane before
        // Creature Grove becomes the active route.
        scene.valkyrie.position = CGPoint(x: 370, y: 180)
        scene.handleTap(at: CGPoint(x: 470, y: 305))
        scene.valkyrie.position = CGPoint(x: 825, y: 180)
        scene.handleTap(at: CGPoint(x: 985, y: 282))

        XCTAssertTrue(scene.creatureRouteOpen)
        XCTAssertEqual(gate.alpha, 1.0, accuracy: 0.001)
    }

    func testCreatureGroveRevealsOneEvidenceStepAtATime() throws {
        let state = try makeState()
        state.travel(to: .scienceCreatureGrove)
        let scene = CreatureGroveScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let habitat = try XCTUnwrap(scene.childNode(withName: "scienceHabitatPond"))
        let feet = try XCTUnwrap(scene.childNode(withName: "scienceWebbedFeet"))
        let compare = try XCTUnwrap(scene.childNode(withName: "scienceCompareBoard"))
        let finale = try XCTUnwrap(scene.childNode(withName: "scienceGroveFinale"))

        XCTAssertEqual(scene.groveStage, .arrive)
        XCTAssertLessThan(habitat.alpha, 0.01)
        XCTAssertLessThan(feet.alpha, 0.01)
        XCTAssertLessThan(compare.alpha, 0.01)
        XCTAssertLessThan(finale.alpha, 0.01)

        scene.valkyrie.position = CGPoint(x: 240, y: 180)
        scene.handleTap(at: CGPoint(x: 335, y: 235))
        XCTAssertEqual(scene.groveStage, .animalObserved)
        XCTAssertEqual(habitat.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(feet.alpha, 0.01)

        scene.valkyrie.position = CGPoint(x: 520, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(scene.groveStage, .habitatMatched)
        XCTAssertEqual(feet.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(compare.alpha, 0.01)

        scene.valkyrie.position = CGPoint(x: 760, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        XCTAssertEqual(scene.groveStage, .bodyPartObserved)
        XCTAssertEqual(compare.alpha, 1.0, accuracy: 0.001)
        XCTAssertLessThan(finale.alpha, 0.01)

        scene.valkyrie.position = CGPoint(x: 900, y: 180)
        scene.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertEqual(scene.groveStage, .complete)
        XCTAssertFalse(scene.groveRestored)
        XCTAssertLessThan(finale.alpha, 0.01)

        // Complete the three physical field-study checks that now sit
        // between the main habitat comparison and the restored-grove finale.
        scene.valkyrie.position = CGPoint(x: 520, y: 180)
        scene.handleTap(at: CGPoint(x: 528, y: 270))
        scene.valkyrie.position = CGPoint(x: 760, y: 180)
        scene.handleTap(at: CGPoint(x: 840, y: 290))
        scene.valkyrie.position = CGPoint(x: 900, y: 180)
        scene.handleTap(at: CGPoint(x: 975, y: 285))

        XCTAssertTrue(scene.groveRestored)
        XCTAssertEqual(finale.alpha, 1.0, accuracy: 0.001)
    }

    func testPuzzleAndScienceUseExtraVerticalSpaceOnFourByThreeIPad() throws {
        let state = try makeState()
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let cases: [(AppState.World, String, (AppState) -> AdventureScene)] = [
            (.puzzlePalace, "home", { PuzzlePalaceScene(state: $0) }),
            (.scienceLab, "scienceHome", { ScienceLabScene(state: $0) }),
            (.scienceWeatherTower, "scienceWeatherHome", { WeatherTowerScene(state: $0) }),
            (.scienceCreatureGrove, "scienceGroveHome", { CreatureGroveScene(state: $0) })
        ]

        for (world, homeName, makeScene) in cases {
            state.travel(to: world)
            let scene = makeScene(state)
            scene.reducedMotion = true
            scene.didMove(to: view)
            XCTAssertEqual(scene.size.width, 1280, accuracy: 0.001)
            XCTAssertEqual(scene.size.height, 960, accuracy: 0.001)
            XCTAssertEqual(scene.verticalViewportInset, 120, accuracy: 0.001)

            let title = try XCTUnwrap(scene.childNode(withName: "worldTitle"))
            let home = try XCTUnwrap(scene.childNode(withName: homeName))
            XCTAssertGreaterThan(title.position.y, 720)
            XCTAssertGreaterThan(home.position.y, 720)
            XCTAssertLessThan(scene.instruction.position.y, 0)
            XCTAssertEqual(scene.valkyrie.position.y, 175, accuracy: 0.001)

            scene.willLeave()
        }

        state.travel(to: .scienceLab)
        let greenhouse = ScienceLabScene(state: state)
        greenhouse.reducedMotion = true
        greenhouse.didMove(to: view)
        let greenhouseArt = try XCTUnwrap(
            greenhouse.childNode(withName: "scienceGreenhouseBackdropHD") as? SKSpriteNode
        )
        XCTAssertEqual(greenhouseArt.size, CGSize(width: 1280, height: 960))
        greenhouse.willLeave()

        state.travel(to: .scienceWeatherTower)
        let weather = WeatherTowerScene(state: state)
        weather.reducedMotion = true
        weather.didMove(to: view)
        let weatherArt = try XCTUnwrap(
            weather.childNode(withName: "//weatherBackdropRetina") as? SKSpriteNode
        )
        XCTAssertEqual(weatherArt.size, CGSize(width: 1280, height: 720))
        weather.willLeave()

        state.travel(to: .scienceCreatureGrove)
        let grove = CreatureGroveScene(state: state)
        grove.reducedMotion = true
        grove.didMove(to: view)
        let groveArt = try XCTUnwrap(
            grove.childNode(withName: "creatureGroveBackdropHD") as? SKSpriteNode
        )
        XCTAssertEqual(groveArt.size, CGSize(width: 1280, height: 960))
        grove.willLeave()
    }

    func testPuzzleAndScienceKeepOriginalCanvasOnSixteenByNine() throws {
        let state = try makeState()
        state.travel(to: .scienceLab)
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView(frame: CGRect(x: 0, y: 0, width: 1280, height: 720)))
        defer { scene.willLeave() }

        XCTAssertEqual(scene.size, CGSize(width: 1280, height: 720))
        XCTAssertEqual(scene.verticalViewportInset, 0, accuracy: 0.001)
        XCTAssertEqual(scene.childNode(withName: "worldTitle")?.position.y, 672)
        XCTAssertEqual(scene.instruction.position.y, 46)
    }

    func testPrototypeWorldAtlasIsNotCompositedIntoProductionPuzzleOrScienceScenes() throws {
        let state = try makeState()

        state.travel(to: .puzzlePalace)
        let puzzle = PuzzlePalaceScene(state: state)
        puzzle.reducedMotion = true
        puzzle.didMove(to: SKView())
        XCTAssertNil(puzzle.childNode(withName: "puzzleLegacyMatte"))
        XCTAssertNotNil(puzzle.childNode(withName: "puzzleRoomIdentity"))
        puzzle.willLeave()

        state.travel(to: .scienceLab)
        let greenhouse = ScienceLabScene(state: state)
        greenhouse.reducedMotion = true
        greenhouse.didMove(to: SKView())
        XCTAssertNil(greenhouse.childNode(withName: "scienceLegacyMatte"))
        greenhouse.willLeave()
    }

    func testEveryPuzzlePalaceRoomBuildsAFinishedNativeIdentityLayer() throws {
        let state = try makeState()
        let worlds: [AppState.World] = [
            .puzzlePalace,
            .memoryBridge,
            .stopGoOrbs,
            .sortingPedestal,
            .resortVault,
            .mirrorHall,
            .pathTiles,
            .commandGears,
            .bugLantern,
            .bugLanternRepair
        ]

        for world in worlds {
            state.travel(to: world)
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())
            XCTAssertNotNil(
                scene.childNode(withName: "puzzleRoomIdentity"),
                "\(world) must not fall back to a skeleton/prototype room."
            )
            XCTAssertNil(scene.childNode(withName: "puzzleLegacyMatte"))
            scene.willLeave()
        }
    }

    func testLaterScienceRoomsHaveCrispNativeEnvironmentIdentityLayers() throws {
        let state = try makeState()

        state.travel(to: .scienceWeatherTower)
        let weather = WeatherTowerScene(state: state)
        weather.reducedMotion = true
        weather.didMove(to: SKView())
        XCTAssertNotNil(weather.childNode(withName: "weatherFarLandscape"))
        let painting = try XCTUnwrap(weather.childNode(withName: "//weatherBackdropRetina"))
        XCTAssertEqual(painting.alpha, 1.0, accuracy: 0.001)
        XCTAssertEqual(painting.userData?["sourceAsset"] as? String, "WeatherTowerIllustratedV2")
        weather.willLeave()

        state.travel(to: .scienceCreatureGrove)
        let grove = CreatureGroveScene(state: state)
        grove.reducedMotion = true
        grove.didMove(to: SKView())
        XCTAssertNotNil(grove.childNode(withName: "creatureGroveNativeCanopy"))
        grove.willLeave()
    }

    func testScienceGuidanceKeepsItsTargetWhenMotionPreferenceChanges() throws {
        let state = try makeState()
        state.travel(to: .scienceLab)
        let scene = ScienceLabScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        let original = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        let position = original.position
        scene.reducedMotion = true
        let calm = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        XCTAssertEqual(calm.position, position)
        XCTAssertTrue(calm.children.allSatisfy { !$0.hasActions() })
        XCTAssertTrue(scene.milo.reducedMotion)
        scene.reducedMotion = false
        let animated = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        XCTAssertEqual(animated.position, position)
        XCTAssertTrue(animated.children.contains { $0.hasActions() })
        XCTAssertFalse(scene.milo.reducedMotion)
        XCTAssertEqual(scene.targetName(at: position), "scienceSeedBench")
    }

    func testSceneMotionTogglePreservesValkyrieAndPipPoseDeadlines() throws {
        let scene = StoryTreeScene(state: try makeState())
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        scene.valkyrie.pose(.interact)
        scene.pip.pose(.celebrate)
        let valkyrieDeadline = try XCTUnwrap(scene.valkyrie.action(forKey: "operation"))
        let pipDeadline = try XCTUnwrap(scene.pip.action(forKey: "operation"))
        for reduced in [true, false] {
            scene.reducedMotion = reduced
            XCTAssertTrue(scene.valkyrie.action(forKey: "operation") === valkyrieDeadline)
            XCTAssertTrue(scene.pip.action(forKey: "operation") === pipDeadline)
        }
    }

    func testInterruptedCompanionReactionResetsAuraWithoutMovingTheActor() throws {
        let companions: [CharacterNode] = [LumiNode(), MiloNode(), TikoNode()]
        for actor in companions {
            actor.position = CGPoint(x: 480, y: 180)
            actor.face(toward: CGPoint(x: 200, y: 180))
            let aura = try XCTUnwrap(actor.childNode(withName: "companionPresence"))
            aura.setScale(1.18)
            aura.run(.repeatForever(.scale(to: 1.2, duration: 0.3)), withKey: "presencePulse")
            actor.bodyNode.position.y = 3
            actor.bodyNode.zRotation = 0.02
            actor.pose(.react)
            XCTAssertEqual(actor.position, CGPoint(x: 480, y: 180))
            XCTAssertEqual(actor.bodyNode.position, .zero)
            XCTAssertEqual(actor.bodyNode.zRotation, 0)
            XCTAssertLessThan(actor.bodyNode.xScale, 0)
            XCTAssertEqual(aura.xScale, 1)
            XCTAssertNil(aura.action(forKey: "presencePulse"))
            actor.reducedMotion = true
            XCTAssertFalse(actor.bodyNode.hasActions())
            XCTAssertNotNil(actor.action(forKey: "operation"))
            actor.cancelTravel()
        }
    }

    func testCharacterGroundingPreservesFootPositionAcrossMotionPreferences() throws {
        let actors: [CharacterNode] = [ValkyrieNode(), PipNode(), LumiNode(), MiloNode(), TikoNode()]
        for actor in actors {
            actor.position = CGPoint(x: 420, y: 180)
            let shadow = try XCTUnwrap(actor.childNode(withName: "characterGroundShadow"))
            XCTAssertFalse(shadow.children.isEmpty)
            actor.pose(.celebrate)
            XCTAssertEqual(actor.position, CGPoint(x: 420, y: 180))
            actor.reducedMotion = true
            XCTAssertFalse(actor.bodyNode.hasActions())
            actor.pose(.idle)
            XCTAssertEqual(actor.position, CGPoint(x: 420, y: 180))
            XCTAssertEqual(shadow.xScale, 1, accuracy: 0.001)
            XCTAssertEqual(actor.bodyNode.position, .zero)
            XCTAssertEqual(actor.bodyNode.zRotation, 0, accuracy: 0.001)
        }
    }

    func testSuccessBurstDoesNotInterceptAnOpenedRoute() throws {
        let scene = AdventureScene(state: try makeState())
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        let point = CGPoint(x: 640, y: 360)
        scene.worldControl("Route", name: "routeUnderBurst", at: point)
        scene.successFeedback(at: point)
        XCTAssertNotNil(scene.childNode(withName: "successBurst"))
        XCTAssertEqual(scene.targetName(at: point), "routeUnderBurst")
    }

    func testLiveMotionTogglePreservesCompanionTravelAndInteractionDeadlines() throws {
        let milo = MiloNode()
        milo.walk(to: CGPoint(x: 400, y: 180)) {}
        let travel = try XCTUnwrap(milo.action(forKey: "travel"))
        XCTAssertNotNil(milo.bodyNode.action(forKey: "pose"))
        milo.reducedMotion = true
        XCTAssertTrue(milo.action(forKey: "travel") === travel)
        XCTAssertNil(milo.bodyNode.action(forKey: "pose"))
        milo.reducedMotion = false
        XCTAssertNotNil(milo.bodyNode.action(forKey: "pose"))
        XCTAssertTrue(milo.action(forKey: "travel") === travel)
        milo.cancelTravel()

        let lumi = LumiNode()
        lumi.reach(to: CGPoint(x: 200, y: 220), reducedMotion: false) {}
        let ability = try XCTUnwrap(lumi.action(forKey: "lumiReach"))
        let deadline = try XCTUnwrap(lumi.action(forKey: "operation"))
        lumi.reducedMotion = true
        XCTAssertTrue(lumi.action(forKey: "lumiReach") === ability)
        XCTAssertTrue(lumi.action(forKey: "operation") === deadline)
        let aura = try XCTUnwrap(lumi.childNode(withName: "companionPresence"))
        XCTAssertNil(aura.action(forKey: "presencePulse"))
        XCTAssertEqual(aura.xScale, 1)
        XCTAssertEqual(lumi.bodyNode.position, .zero)
        XCTAssertFalse(lumi.bodyNode.hasActions())
        lumi.reducedMotion = false
        XCTAssertTrue(lumi.action(forKey: "operation") === deadline)
        lumi.removeAllActions()

        let tiko = TikoNode()
        tiko.operateRune(at: CGPoint(x: 500, y: 250), reducedMotion: false) {}
        let runeAbility = try XCTUnwrap(tiko.action(forKey: "tikoRuneHop"))
        tiko.reducedMotion = true
        XCTAssertTrue(tiko.action(forKey: "tikoRuneHop") === runeAbility)
        XCTAssertNil(tiko.bodyNode.action(forKey: "tikoRuneFocus"))
        tiko.removeAllActions()
    }

}
