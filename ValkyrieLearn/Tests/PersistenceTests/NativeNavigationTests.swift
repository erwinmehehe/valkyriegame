import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeNavigationTests: XCTestCase {
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
            (.scienceLab, "⚗", { ScienceLabScene(state: $0) }),
            (.puzzlePalace, "◈", { PuzzlePalaceScene(state: $0) })
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
            XCTAssertFalse(emblem.calculateAccumulatedFrame().intersects(scene.layout.interactionStage))
            XCTAssertNotEqual(scene.targetName(at: emblem.position), "decorativeWorldEmblem")
            scene.willLeave()
        }
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

}
