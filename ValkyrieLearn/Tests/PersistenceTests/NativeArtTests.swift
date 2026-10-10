import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeArtTests: XCTestCase {
    private func waitUntil(
        timeout: TimeInterval = 2,
        _ condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 25_000_000)
        }
        _ = try XCTUnwrap(condition() ? true : nil, "Timed out waiting for a live SpriteKit result; do not label this frame as successful.")
    }

    func testWeatherTowerWindKiteRescueIsPhysicalRepeatableAndRestores() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let store = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(store))
        state.travel(to: .scienceWeatherTower)
        let originalSkills = state.profile.skills
        let originalScience = state.scienceAdventure

        let tower = WeatherTowerScene(state: state)
        tower.reducedMotion = true
        view.presentScene(tower)
        let beacon = try XCTUnwrap(tower.childNode(withName: "windRescueBeacon"))
        XCTAssertTrue(beacon.isAccessibilityElement)
        tower.handleTap(at: beacon.position)

        XCTAssertTrue(state.miloWindKiteRescue.explored)
        XCTAssertNotNil(tower.childNode(withName: "windRescueStage"))
        XCTAssertNotNil(tower.childNode(withName: "//windFan"))
        XCTAssertNotNil(tower.childNode(withName: "//windTrialCraft"))
        XCTAssertNotNil(tower.childNode(withName: "//windLostKite"))
        XCTAssertNotNil(tower.childNode(withName: "//windSail0"))
        XCTAssertNotNil(tower.childNode(withName: "//windPower2"))
        XCTAssertNotNil(tower.childNode(withName: "//windLaunchLever"))

        // Leaf with a gust travels partway; it doesn't free the kite.
        tower.handleTap(at: CGPoint(x: 880, y: 540))
        XCTAssertEqual(state.miloWindKiteRescue.strength, .gust)
        tower.handleTap(at: CGPoint(x: 1095, y: 195))
        XCTAssertEqual(state.miloWindKiteRescue.lastTrial?.travel, 122)
        XCTAssertFalse(state.miloWindKiteRescue.kiteRescued)
        let firstCraft = try XCTUnwrap(tower.childNode(withName: "//windTrialCraft"))
        XCTAssertEqual(firstCraft.position.x, 560 + CGFloat(122) * 2.55, accuracy: 0.5)
        XCTAssertEqual(state.profile.skills, originalSkills)
        XCTAssertEqual(state.scienceAdventure, originalScience)
        try await capture(tower, in: view, name: "Weather-Tower-Kite-Leaf-Gust-Test")

        // Changing only the sail to cloth carries the craft far enough.
        tower.handleTap(at: CGPoint(x: 405, y: 164))
        XCTAssertEqual(state.miloWindKiteRescue.sail, .cloth)
        XCTAssertNil(state.miloWindKiteRescue.lastTrial)
        tower.handleTap(at: CGPoint(x: 1095, y: 195))
        XCTAssertEqual(state.miloWindKiteRescue.lastTrial?.travel, 175)
        XCTAssertTrue(state.miloWindKiteRescue.kiteRescued)
        XCTAssertNotNil(tower.childNode(withName: "//windTrialReadout"))
        XCTAssertEqual(state.profile.skills, originalSkills)
        XCTAssertEqual(state.scienceAdventure, originalScience)
        try await capture(tower, in: view, name: "Weather-Tower-Rescued-Wind-Kite")

        // A calm second try remains meaningful and cannot undo the rescue.
        tower.handleTap(at: CGPoint(x: 420, y: 540))
        XCTAssertNil(state.miloWindKiteRescue.lastTrial)
        tower.handleTap(at: CGPoint(x: 1095, y: 195))
        XCTAssertEqual(state.miloWindKiteRescue.lastTrial?.travel, 0)
        XCTAssertTrue(state.miloWindKiteRescue.kiteRescued)

        tower.handleTap(at: CGPoint(x: 1160, y: 622))
        XCTAssertNil(tower.childNode(withName: "windRescueStage"))
        XCTAssertNotNil(tower.childNode(withName: "windRescueBeacon"))
        XCTAssertNotNil(tower.childNode(withName: "//windRescueBeacon"))
        let sign = try XCTUnwrap(
            tower.childNode(withName: "//windRescueBeacon")?
                .children.compactMap { $0 as? SKLabelNode }
                .first(where: { $0.text == "KITE HOME" })
        )
        XCTAssertEqual(sign.text, "KITE HOME")
        try await capture(tower, in: view, name: "Weather-Tower-Rescued-Kite-Courtyard")
        tower.willLeave()

        let restored = try AppState(context: ModelContext(store))
        XCTAssertEqual(restored.miloWindKiteRescue.trialsCompleted, 3)
        XCTAssertTrue(restored.miloWindKiteRescue.kiteRescued)
        XCTAssertEqual(restored.miloWindKiteRescue.sail, .cloth)
        XCTAssertEqual(restored.profile.skills, originalSkills)
        XCTAssertEqual(restored.scienceAdventure, originalScience)
    }

    func testMiloShadowWorkshopChangesProjectionAndSavesRescuedMoth() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let store = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(store))
        state.travel(to: .scienceLab)
        let evidence = state.profile.skills
        let scienceBefore = state.scienceAdventure

        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        let beacon = try XCTUnwrap(scene.childNode(withName: "shadowWorkshopBeacon"))
        XCTAssertTrue(beacon.isAccessibilityElement)
        scene.handleTap(at: beacon.position)
        XCTAssertTrue(state.miloShadowWorkshop.explored)
        XCTAssertNotNil(scene.childNode(withName: "shadowWorkshopStage"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowWorkshopWall"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowWorkshopPhysicalProp"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowWorkshopProjection"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowLampRail"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowHeightLever"))
        XCTAssertNotNil(scene.childNode(withName: "//shadowTestLever"))
        XCTAssertEqual(state.profile.skills, evidence)

        // Touch the rail: lamp left means its shadow moves right.
        scene.handleTap(at: CGPoint(x: 420, y: 603))
        XCTAssertEqual(state.miloShadowWorkshop.lampNotch, 0)
        XCTAssertEqual(state.miloShadowWorkshop.projection.direction, .right)
        let highShadow = state.miloShadowWorkshop.projection.scale
        try await capture(scene, in: view, name: "Science-Lab-Milo-Shadow-High-Light")

        // Lower the lamp: a larger silhouette appears on the physical wall.
        scene.handleTap(at: CGPoint(x: 1088, y: 535))
        XCTAssertEqual(state.miloShadowWorkshop.height, .low)
        XCTAssertGreaterThan(state.miloShadowWorkshop.projection.scale, highShadow)
        scene.handleTap(at: CGPoint(x: 1095, y: 262))
        XCTAssertEqual(state.miloShadowWorkshop.observations.count, 1)
        XCTAssertFalse(state.hasStoryReward(.miloShadowMoth))

        // Switch the actual cutout, raise the lamp and compare again.
        scene.handleTap(at: CGPoint(x: 808, y: 158))
        XCTAssertEqual(state.miloShadowWorkshop.prop, .star)
        scene.handleTap(at: CGPoint(x: 1088, y: 535))
        XCTAssertEqual(state.miloShadowWorkshop.height, .high)
        scene.handleTap(at: CGPoint(x: 1095, y: 262))
        XCTAssertTrue(state.miloShadowWorkshop.hasFoundMoth)
        XCTAssertTrue(state.hasStoryReward(.miloShadowMoth))
        XCTAssertNotNil(scene.childNode(withName: "//shadowWorkshopMoth"))
        XCTAssertEqual(state.profile.skills, evidence)
        XCTAssertEqual(state.scienceAdventure, scienceBefore)
        try await capture(scene, in: view, name: "Science-Lab-Milo-Shadow-Moth-Discovery")

        scene.handleTap(at: CGPoint(x: 1160, y: 622))
        XCTAssertNil(scene.childNode(withName: "shadowWorkshopStage"))
        XCTAssertNotNil(scene.childNode(withName: "shadowWorkshopBeacon"))
        scene.willLeave()

        let restored = try AppState(context: ModelContext(store))
        XCTAssertTrue(restored.hasStoryReward(.miloShadowMoth))
        XCTAssertEqual(restored.miloShadowWorkshop.observations.count, 2)
        XCTAssertEqual(restored.profile.skills, evidence)
        XCTAssertEqual(restored.scienceAdventure, scienceBefore)

        restored.travel(to: .storyTree)
        let tree = StoryTreeScene(state: restored)
        tree.reducedMotion = true
        view.presentScene(tree)
        let moth = try XCTUnwrap(tree.childNode(withName: "miloShadowMoth"))
        XCTAssertTrue(moth.isAccessibilityElement)
        XCTAssertEqual(moth.position, CGPoint(x: 350, y: 615),
                       "The rescued moth belongs in the canopy, not over the Science Lab button.")
        try await capture(tree, in: view, name: "Story-Tree-Milo-Shadow-Moth")
        tree.handleTap(at: moth.position)
        XCTAssertEqual(restored.storyRewardPlacement(.miloShadowMoth), 1)
        tree.willLeave()
        let saved = try AppState(context: ModelContext(store))
        XCTAssertEqual(saved.storyRewardPlacement(.miloShadowMoth), 1)
    }

    func testBridgeRescueExplorationRestoresAcrossLaunchAndPlacesTreeCharm() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .mathCastle)
        let initialMathEvidence = state.profile.skills

        let castle = MathCastleScene(state: state)
        castle.reducedMotion = true
        view.presentScene(castle)
        let beacon = try XCTUnwrap(castle.childNode(withName: "starlightQuestBeacon"))
        XCTAssertTrue(beacon.isAccessibilityElement)
        castle.handleTap(at: beacon.position)
        XCTAssertTrue(state.starlightBridgeQuest.discovered)
        XCTAssertNotNil(castle.childNode(withName: "starlightQuestStage"))
        XCTAssertNotNil(castle.childNode(withName: "//bridgeQuestCache0"))
        XCTAssertNotNil(castle.childNode(withName: "//bridgeQuestFirefly"))
        XCTAssertNotNil(castle.childNode(withName: "//bridgeQuestProgressSign"))
        for index in 0..<StarlightBridgeQuest.crystalCount {
            let cache = try XCTUnwrap(castle.childNode(withName: "//bridgeQuestCache\(index)"))
            let pedestal = try XCTUnwrap(castle.childNode(
                withName: "//decorativeCrystalPedestal\(index)"
            ))
            XCTAssertEqual(cache.position.x, pedestal.position.x, accuracy: 0.001)
            XCTAssertGreaterThan(cache.position.y, pedestal.position.y,
                                 "Crystal should sit on a physical pedestal, not in the sky.")
        }
        XCTAssertEqual(state.profile.skills, initialMathEvidence)
        try await capture(castle, in: view, name: "Math-Castle-Starlight-Bridge-Discovery")

        let caches: [CGPoint] = [
            CGPoint(x: 330, y: 306), CGPoint(x: 468, y: 306), CGPoint(x: 605, y: 306)
        ]
        for (index, point) in caches.enumerated() {
            castle.handleTap(at: point)
            try await waitUntil(timeout: 3) {
                state.starlightBridgeQuest.collectedCrystals.contains(index)
            }
        }
        XCTAssertEqual(state.starlightBridgeQuest.availableCrystals, [0, 1, 2])
        XCTAssertNotNil(castle.childNode(withName: "//bridgeQuestSecret"))
        castle.handleTap(at: CGPoint(x: 1055, y: 460))
        XCTAssertTrue(state.starlightBridgeQuest.hasFoundHiddenStar)
        XCTAssertEqual(state.profile.skills, initialMathEvidence,
                       "The optional hidden star cannot award mathematical mastery.")

        let inventory: [CGPoint] = [
            CGPoint(x: 360, y: 130), CGPoint(x: 490, y: 130), CGPoint(x: 620, y: 130)
        ]
        let sockets: [CGPoint] = [
            CGPoint(x: 760, y: 302), CGPoint(x: 905, y: 302), CGPoint(x: 1050, y: 302)
        ]
        for index in 0..<3 {
            castle.handleTap(at: inventory[index])
            castle.handleTap(at: sockets[(index + 1) % 3])
            try await waitUntil(timeout: 3) {
                state.starlightBridgeQuest.installedCount == index + 1
            }
        }

        XCTAssertTrue(state.starlightBridgeQuest.isComplete)
        XCTAssertTrue(state.hasStoryReward(.starlightBridgeCharm))
        XCTAssertEqual(state.profile.skills, initialMathEvidence,
                       "A fun physical bridge quest cannot manufacture Math mastery.")
        XCTAssertNotNil(castle.childNode(withName: "//bridgeQuestVictory"))
        try await capture(castle, in: view, name: "Math-Castle-Starlight-Bridge-Restored")

        // Native integration: color changes don't erase the structural
        // supports, replayable heavy-load results or mastered learning.
        let originalLights = state.starlightBridgeQuest.installedCrystals
        castle.handleTap(at: sockets[0])
        castle.handleTap(at: sockets[1])
        XCTAssertEqual(state.starlightBridgeQuest.installedCrystals[0], originalLights[1])
        XCTAssertEqual(state.starlightBridgeQuest.installedCrystals[1], originalLights[0])
        XCTAssertTrue(state.starlightBridgeQuest.isComplete)
        XCTAssertEqual(state.profile.skills, initialMathEvidence)
        try await capture(castle, in: view, name: "Math-Castle-Starlight-Bridge-Color-Experiment")

        castle.handleTap(at: CGPoint(x: 1170, y: 625))
        XCTAssertNil(castle.childNode(withName: "starlightQuestStage"))
        castle.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertTrue(restored.starlightBridgeQuest.isComplete)
        XCTAssertTrue(restored.starlightBridgeQuest.hasFoundHiddenStar)
        XCTAssertTrue(restored.hasStoryReward(.starlightBridgeCharm))
        XCTAssertEqual(restored.profile.skills, initialMathEvidence)

        restored.travel(to: .storyTree)
        let tree = StoryTreeScene(state: restored)
        tree.reducedMotion = true
        view.presentScene(tree)
        let charm = try XCTUnwrap(tree.childNode(withName: "starlightBridgeCharm"))
        XCTAssertTrue(charm.isAccessibilityElement)
        XCTAssertNotNil(tree.childNode(withName: "//starlightBridgeSecretStar"),
                        "The optional secret should visibly persist on the earned charm.")
        XCTAssertTrue((charm.accessibilityLabel ?? "").contains("hidden star"))
        XCTAssertEqual(charm.position, CGPoint(x: 240, y: 585),
                       "The reward should hang in the Story Tree canopy, not over distant Math Castle.")
        XCTAssertEqual(restored.storyRewardPlacement(.starlightBridgeCharm), 0)
        try await capture(tree, in: view, name: "Story-Tree-Starlight-Bridge-Charm")
        tree.handleTap(at: charm.position)
        XCTAssertEqual(restored.storyRewardPlacement(.starlightBridgeCharm), 1)
        XCTAssertNotEqual(
            try XCTUnwrap(tree.childNode(withName: "starlightBridgeCharm")).position,
            charm.position
        )
        tree.willLeave()
        let resumed = try AppState(context: ModelContext(container))
        XCTAssertEqual(resumed.storyRewardPlacement(.starlightBridgeCharm), 1)
    }

    func testBridgeLoadLabShowsFailuresRecoversAndSavesStoryTreeEngineeringGear() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let store = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(store))
        state.travel(to: .mathCastle)
        XCTAssertTrue(state.discoverStarlightBridge())
        for index in 0..<StarlightBridgeQuest.crystalCount {
            XCTAssertTrue(state.collectStarlightCrystal(index))
            XCTAssertTrue(state.installStarlightCrystal(index, into: index))
        }
        XCTAssertTrue(state.hasStoryReward(.starlightBridgeCharm))
        let originalSkills = state.profile.skills

        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        let beacon = try XCTUnwrap(scene.childNode(withName: "starlightQuestBeacon"))
        scene.handleTap(at: beacon.position)

        for index in 0..<3 {
            XCTAssertNotNil(scene.childNode(withName: "//bridgeLoadBrace\(index)"))
        }
        XCTAssertNotNil(scene.childNode(withName: "//bridgeTestLoad0"))
        XCTAssertNotNil(scene.childNode(withName: "//bridgeTestLoad1"))
        XCTAssertNotNil(scene.childNode(withName: "//bridgeTestLever"))
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName: "//bridgeTestLoad0")).position,
                       CGPoint(x: 468, y: 306),
                       "Experiment traveler must stand on the existing courtyard plinth.")
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName: "//bridgeTestLoad1")).position,
                       CGPoint(x: 605, y: 306))
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName: "//bridgeTestLever")).position,
                       CGPoint(x: 1150, y: 270),
                       "Bridge test lever must sit beside the physical span, not the skyline.")

        // The heavier cart tests the physical bridge, revealing the weakest span.
        scene.handleTap(at: CGPoint(x: 1150, y: 270))
        XCTAssertEqual(state.starlightBridgeQuest.trialsCompleted, 1)
        XCTAssertFalse(state.starlightBridgeQuest.hasDeliveredSupplies)
        let crackedPlank = try XCTUnwrap(
            scene.childNode(withName: "//bridgeTestWeakSpan0") as? SKShapeNode
        )
        XCTAssertNotNil(crackedPlank.path,
                        "The cart should crack a real timber span instead of showing a UI error circle.")
        XCTAssertEqual(crackedPlank.position, CGPoint(x: 760, y: 240))
        XCTAssertNotNil(scene.childNode(withName: "//bridgeTestTraveler"))
        XCTAssertEqual(state.profile.skills, originalSkills)
        try await capture(scene, in: view, name: "Math-Castle-Bridge-Load-Trial-Bends")

        // Reusable timber supports, not answers: children move two braces.
        scene.handleTap(at: CGPoint(x: 760, y: 184))
        scene.handleTap(at: CGPoint(x: 1050, y: 184))
        XCTAssertEqual(state.starlightBridgeQuest.braces, Set([0, 2]))
        scene.handleTap(at: CGPoint(x: 905, y: 184))
        XCTAssertEqual(state.starlightBridgeQuest.braces, Set([0, 2]),
                       "No extra support is created from an invalid third tap.")

        scene.handleTap(at: CGPoint(x: 1150, y: 270))
        XCTAssertEqual(state.starlightBridgeQuest.trialsCompleted, 2)
        XCTAssertTrue(state.starlightBridgeQuest.hasDeliveredSupplies)
        XCTAssertNil(scene.childNode(withName: "//bridgeTestWeakSpan0"))
        let deliveredGear = try XCTUnwrap(
            scene.childNode(withName: "//bridgeTestSuppliesDelivered")
        )
        XCTAssertEqual(deliveredGear.position, CGPoint(x: 1009, y: 408),
                       "Reward feedback belongs on the bridge sign, not floating in the sky.")
        XCTAssertEqual(
            (scene.childNode(withName: "//bridgeQuestStatus") as? SKLabelNode)?.text,
            "CART DELIVERED"
        )
        try await capture(scene, in: view, name: "Math-Castle-Bridge-Load-Trial-Supplies-Delivered")

        // A light firefly crosses without the braces, and experiments can
        // continue after the optional supplies achievement.
        scene.handleTap(at: CGPoint(x: 760, y: 184))
        scene.handleTap(at: CGPoint(x: 1050, y: 184))
        XCTAssertTrue(state.starlightBridgeQuest.braces.isEmpty)
        scene.handleTap(at: CGPoint(x: 468, y: 306))
        scene.handleTap(at: CGPoint(x: 1150, y: 270))
        XCTAssertEqual(state.starlightBridgeQuest.trialsCompleted, 3)
        XCTAssertNotNil(scene.childNode(withName: "//bridgeTestTraveler"))
        XCTAssertNil(scene.childNode(withName: "//bridgeTestWeakSpan0"))
        XCTAssertEqual(state.profile.skills, originalSkills)

        scene.handleTap(at: CGPoint(x: 1170, y: 625))
        XCTAssertNil(scene.childNode(withName: "starlightQuestStage"))
        scene.willLeave()

        let restored = try AppState(context: ModelContext(store))
        XCTAssertTrue(restored.starlightBridgeQuest.hasDeliveredSupplies)
        XCTAssertEqual(restored.starlightBridgeQuest.trialsCompleted, 3)
        XCTAssertTrue(restored.starlightBridgeQuest.braces.isEmpty)
        XCTAssertEqual(restored.profile.skills, originalSkills)

        restored.travel(to: .storyTree)
        let tree = StoryTreeScene(state: restored)
        tree.reducedMotion = true
        view.presentScene(tree)
        let charm = try XCTUnwrap(tree.childNode(withName: "starlightBridgeCharm"))
        XCTAssertNotNil(tree.childNode(withName: "//starlightBridgeSupplyGear"))
        XCTAssertTrue((charm.accessibilityLabel ?? "").contains("engineering gear"))
        try await capture(tree, in: view, name: "Story-Tree-Bridge-Engineering-Gear")
        tree.willLeave()
    }

    func testLumiLivingGardenPlantingBloomsSaveAndDecoratesStoryTree() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let view = SKView(frame: window.bounds)
        let controller = UIViewController()
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .wordGarden)
        let originalEvidence = state.profile.skills
        let scene = WordGardenScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)

        let beacon = try XCTUnwrap(scene.childNode(withName: "livingGardenBeacon"))
        XCTAssertTrue(beacon.isAccessibilityElement)
        scene.handleTap(at: beacon.position)
        XCTAssertNotNil(scene.childNode(withName: "livingGardenStage"))
        XCTAssertNotNil(scene.childNode(withName: "//livingPlot0"))
        XCTAssertNotNil(scene.childNode(withName: "//livingSeed0"))
        XCTAssertNotNil(scene.childNode(withName: "//livingCare0"))
        XCTAssertFalse(state.hasStoryReward(.lumiLivingBloom))

        // Choose the starflower, plant it, then experiment with rain and sun.
        scene.handleTap(at: CGPoint(x: 485, y: 535))
        scene.handleTap(at: CGPoint(x: 550, y: 360))
        XCTAssertEqual(state.lumiLivingGarden.plot(at: 0)?.seed, .starflower)
        scene.handleTap(at: CGPoint(x: 495, y: 160))
        scene.handleTap(at: CGPoint(x: 550, y: 360))
        XCTAssertEqual(state.lumiLivingGarden.bloomingCount, 0)
        scene.handleTap(at: CGPoint(x: 705, y: 160))
        scene.handleTap(at: CGPoint(x: 550, y: 360))
        XCTAssertEqual(state.lumiLivingGarden.bloomingCount, 1)
        XCTAssertTrue(state.hasStoryReward(.lumiLivingBloom))
        XCTAssertEqual(state.profile.skills, originalEvidence,
                       "Creative planting cannot award literacy mastery.")
        try await capture(scene, in: view, name: "Word-Garden-Lumi-Living-Patch-Bloom")

        // Caring with shade visibly closes a sun-loving blossom, then sunlight
        // opens it again without erasing the earned persistent reward.
        scene.handleTap(at: CGPoint(x: 915, y: 160))
        scene.handleTap(at: CGPoint(x: 550, y: 360))
        XCTAssertEqual(state.lumiLivingGarden.bloomingCount, 0)
        XCTAssertTrue(state.hasStoryReward(.lumiLivingBloom))
        scene.handleTap(at: CGPoint(x: 705, y: 160))
        scene.handleTap(at: CGPoint(x: 550, y: 360))
        XCTAssertEqual(state.lumiLivingGarden.bloomingCount, 1)

        scene.handleTap(at: CGPoint(x: 1170, y: 628))
        XCTAssertNil(scene.childNode(withName: "livingGardenStage"))
        XCTAssertNotNil(scene.childNode(withName: "livingGardenBeacon"))
        scene.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.lumiLivingGarden.bloomingCount, 1)
        XCTAssertEqual(restored.lumiLivingGarden.plot(at: 0)?.seed, .starflower)
        XCTAssertTrue(restored.hasStoryReward(.lumiLivingBloom))
        XCTAssertEqual(restored.profile.skills, originalEvidence)
        restored.travel(to: .storyTree)
        let tree = StoryTreeScene(state: restored)
        tree.reducedMotion = true
        view.presentScene(tree)
        let flower = try XCTUnwrap(tree.childNode(withName: "lumiLivingBloom"))
        XCTAssertTrue(flower.isAccessibilityElement)
        XCTAssertEqual(restored.storyRewardPlacement(.lumiLivingBloom), 0)
        try await capture(tree, in: view, name: "Story-Tree-Lumi-Living-Bloom")
        tree.handleTap(at: flower.position)
        XCTAssertEqual(restored.storyRewardPlacement(.lumiLivingBloom), 1)
        tree.willLeave()
    }

    func testFlowerGateUsesSourceResolutionAndKeepsActorAndChoicesClear() throws {
        let atlas = try XCTUnwrap(ArtSystem.texture("WordGardenSourceAtlas"))
        XCTAssertGreaterThanOrEqual(atlas.size().width, 1600)
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = WordGardenScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        scene.update(0)
        XCTAssertEqual(scene.valkyrie.xScale, 0.5, accuracy: 0.001)
        let gate = try XCTUnwrap(scene.childNode(withName: "flowerGate"))
        let gateFrame = gate.calculateAccumulatedFrame()
        for flower in scene.children where flower.name == "flowerChoice" {
            XCTAssertFalse(gateFrame.intersects(flower.calculateAccumulatedFrame()))
        }
    }

    func testGlobalPolishLayoutKeepsHUDOutOfTheLearningStage() throws {
        let layout = AdventureSceneLayout(size: CGSize(width: 1280, height: 720))
        XCTAssertFalse(layout.topHUD.intersects(layout.interactionStage))
        XCTAssertFalse(layout.instructionZone.intersects(layout.interactionStage))
        XCTAssertGreaterThanOrEqual(layout.actorLane.height, 120)

        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state)
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        for name in ["wordGarden", "puzzlePalace", "castle", "scienceLab"] {
            let node = try XCTUnwrap(scene.childNode(withName: name))
            let frame = node.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 60, "\(name) touch target is too narrow.")
            XCTAssertGreaterThanOrEqual(frame.height, 60, "\(name) touch target is too short.")
            XCTAssertTrue(node.isAccessibilityElement, "\(name) must expose an accessibility label.")
            XCTAssertFalse((node.accessibilityLabel ?? "").isEmpty)
        }

        let wordGarden = try XCTUnwrap(scene.childNode(withName: "wordGarden"))
        let wordGardenPlaque = try XCTUnwrap(wordGarden.children.first {
            ($0.userData?["destinationRole"] as? String) == "plaque"
        })
        let actorFrame = scene.valkyrie.calculateAccumulatedFrame().insetBy(dx: 18, dy: 12)
        XCTAssertFalse(
            actorFrame.intersects(wordGardenPlaque.calculateAccumulatedFrame()),
            "Opening Valkyrie pose must not cover the Word Garden label plaque."
        )
    }

    func testRasterQualityAndLegacyAtlasNeverOwnsThePlayableSurface() throws {
        XCTAssertEqual(ArtSystem.pixelSize("V331WorldAtlas"), CGSize(width: 320, height: 180))
        XCTAssertEqual(ArtSystem.pixelSize("StarlightIsles"), CGSize(width: 1280, height: 720))
        XCTAssertEqual(ArtSystem.pixelSize("MathCastle"), CGSize(width: 1280, height: 720))
        let starlightScale = try XCTUnwrap(
            ArtSystem.sourceScale(
                for: "StarlightIsles",
                targetPoints: CGSize(width: 1280, height: 720)
            )
        )
        XCTAssertEqual(starlightScale, CGFloat(1), accuracy: CGFloat(0.001))
        XCTAssertFalse(
            ArtSystem.isRetinaReady(
                "V331WorldAtlas",
                targetPoints: CGSize(width: 1280, height: 720)
            ),
            "The 320x180 legacy atlas must never be treated as Retina-ready fullscreen art."
        )

        let puzzleState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let puzzle = PuzzlePalaceScene(state: puzzleState)
        puzzle.reducedMotion = true
        puzzle.didMove(to: SKView())
        defer { puzzle.willLeave() }

        XCTAssertNil(puzzle.childNode(withName: "puzzleLegacyMatte"))
        XCTAssertNotNil(puzzle.childNode(withName: "puzzleNativeBackdrop"))
        XCTAssertNotNil(puzzle.childNode(withName: "puzzleArchitecture"))
        XCTAssertNotNil(puzzle.childNode(withName: "puzzleFloor"))
        XCTAssertNotNil(puzzle.childNode(withName: "puzzleFloorTexture"))
        XCTAssertNotNil(
            puzzle.childNode(withName: "puzzleGate"),
            "The polished Rune Gate remains native SpriteKit structure even without the old stage dais."
        )
        XCTAssertNil(
            puzzle.childNode(withName: "puzzleUpperVault"),
            "Rune Gate keeps its open portal composition instead of inheriting the denser shared hall."
        )

        let palaceDepthState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        palaceDepthState.travel(to: .sortingPedestal)
        let palaceDepth = PuzzlePalaceScene(state: palaceDepthState)
        palaceDepth.reducedMotion = true
        palaceDepth.didMove(to: SKView())
        defer { palaceDepth.willLeave() }

        XCTAssertNotNil(palaceDepth.childNode(withName: "puzzleUpperVault"))
        XCTAssertNotNil(palaceDepth.childNode(withName: "puzzleVaultCornice"))
        XCTAssertNotNil(palaceDepth.childNode(withName: "puzzleFloorSeal"))
        XCTAssertNotNil(palaceDepth.childNode(withName: "puzzleStageInlay"))
        XCTAssertEqual(
            palaceDepth.children.filter { $0.name?.hasPrefix("puzzleAlcove") == true }.count,
            3
        )
        XCTAssertEqual(
            palaceDepth.children.filter { $0.name?.hasPrefix("puzzleCrystalSconce") == true }.count,
            4
        )

        let scienceState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        scienceState.travel(to: .scienceLab)
        let science = ScienceLabScene(state: scienceState)
        science.reducedMotion = true
        science.didMove(to: SKView())
        defer { science.willLeave() }

        XCTAssertNil(science.childNode(withName: "scienceLegacyMatte"))
        XCTAssertNotNil(science.childNode(withName: "scienceNativeBackdrop"))
        XCTAssertNotNil(science.childNode(withName: "scienceGreenhouseFrame"))
        XCTAssertNotNil(science.childNode(withName: "scienceGround"))
        XCTAssertNotNil(science.childNode(withName: "scienceWaterBed"))
    }

    func testPuzzlePalaceArchitectureMovesWithoutCompetingWithReducedMotion() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .sortingPedestal)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let crystal = try XCTUnwrap(
            scene.children.first { $0.name == "puzzleCrystalFixture" }
        )
        let alcoveGlow = try XCTUnwrap(
            scene.childNode(withName: "//puzzleAlcoveGlow0")
        )
        let floorSeal = try XCTUnwrap(scene.childNode(withName: "puzzleFloorSeal"))

        XCTAssertNotNil(crystal.action(forKey: "palaceCrystalFloat"))
        XCTAssertNotNil(alcoveGlow.action(forKey: "palaceAlcoveBreath"))
        XCTAssertNotNil(floorSeal.action(forKey: "palaceRoomBreath"))
        XCTAssertNotNil(scene.camera?.action(forKey: "focus"))

        scene.reducedMotion = true
        scene.update(0)

        XCTAssertNil(crystal.action(forKey: "palaceCrystalFloat"))
        XCTAssertNil(alcoveGlow.action(forKey: "palaceAlcoveBreath"))
        XCTAssertNil(floorSeal.action(forKey: "palaceRoomBreath"))
        XCTAssertEqual(scene.camera?.position.x ?? 0, 640, accuracy: 0.001)
        XCTAssertEqual(scene.camera?.position.y ?? 0, 360, accuracy: 0.001)
    }

    func testCreatureGroveHabitatMotionRespectsReducedMotion() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .scienceCreatureGrove)

        let scene = CreatureGroveScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let reed = try XCTUnwrap(
            scene.childNode(withName: "//grovePondReed")
        )
        let ripple = try XCTUnwrap(
            scene.childNode(withName: "//grovePondRipple")
        )
        let reflection = try XCTUnwrap(
            scene.childNode(withName: "//grovePondReflection")
        )
        let water = try XCTUnwrap(
            scene.childNode(withName: "//grovePondWater")
        )

        XCTAssertNotNil(reed.action(forKey: "groveReedSway"))
        XCTAssertNotNil(ripple.action(forKey: "groveRipple"))
        XCTAssertNotNil(
            reflection.action(forKey: "groveReflectionShimmer")
        )
        XCTAssertNotNil(water.action(forKey: "groveWaterBreath"))

        scene.reducedMotion = true
        scene.update(0)

        XCTAssertNil(reed.action(forKey: "groveReedSway"))
        XCTAssertNil(ripple.action(forKey: "groveRipple"))
        XCTAssertNil(
            reflection.action(forKey: "groveReflectionShimmer")
        )
        XCTAssertNil(water.action(forKey: "groveWaterBreath"))
    }

    func testWordGardenAmbientMotionRespectsReducedMotion() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .wordGarden)

        let flowerScene = WordGardenScene(state: state)
        flowerScene.reducedMotion = false
        flowerScene.didMove(to: SKView())

        let flower = try XCTUnwrap(
            flowerScene.children.first { $0.name == "flowerChoice" }
        )
        XCTAssertNotNil(flower.action(forKey: "gardenSway"))

        flowerScene.reducedMotion = true
        flowerScene.update(0)
        XCTAssertNil(flower.action(forKey: "gardenSway"))
        flowerScene.willLeave()

        state.travel(to: .sunmillCrossing)
        let sunmill = WordGardenScene(state: state)
        sunmill.reducedMotion = false
        sunmill.didMove(to: SKView())

        let hubGlow = try XCTUnwrap(
            sunmill.childNode(withName: "//sunmillHubGlow")
        )
        let water = try XCTUnwrap(
            sunmill.childNode(withName: "sunmillWater")
        )
        let lightPath = try XCTUnwrap(
            sunmill.childNode(withName: "sunmillLightPath")
        )

        XCTAssertNotNil(hubGlow.action(forKey: "ambientSunmillGlow"))
        XCTAssertNotNil(water.action(forKey: "ambientWaterShimmer"))
        XCTAssertNotNil(lightPath.action(forKey: "ambientLightShimmer"))

        sunmill.reducedMotion = true
        sunmill.update(0)
        XCTAssertNil(hubGlow.action(forKey: "ambientSunmillGlow"))
        XCTAssertNil(water.action(forKey: "ambientWaterShimmer"))
        XCTAssertNil(lightPath.action(forKey: "ambientLightShimmer"))
        sunmill.willLeave()
    }

    func testWordGardenPreservesPaintedAtlasCropsWithRetinaPreparedRaster() throws {
        let atlas = try XCTUnwrap(ArtSystem.texture("WordGardenSourceAtlas"))
        XCTAssertGreaterThanOrEqual(atlas.size().width, 1600)

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let cases: [(AppState.World, String, String)] = [
            (.wordGarden, "word-garden-flower-gate", "wordGardenPathRim"),
            (.sunmillCrossing, "word-garden-sunmill", "sunmillWaterRim"),
            (.storyHollow, "word-garden-story-hollow", "storyHollowRim")
        ]

        for (world, cropKey, accentName) in cases {
            state.travel(to: world)
            let scene = WordGardenScene(state: state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())

            let backdrop = try XCTUnwrap(
                scene.childNode(withName: "wordGardenBackdrop") as? SKSpriteNode
            )
            XCTAssertEqual(
                backdrop.userData?["sourceAsset"] as? String,
                "WordGardenSourceAtlas"
            )
            XCTAssertEqual(
                backdrop.userData?["sourceCrop"] as? String,
                cropKey
            )
            XCTAssertEqual(
                backdrop.userData?["retinaPrepared"] as? Bool,
                true
            )

            let image = try XCTUnwrap(backdrop.texture?.cgImage())
            XCTAssertGreaterThanOrEqual(image.width, 2560)
            XCTAssertGreaterThanOrEqual(image.height, 1440)

            XCTAssertNotNil(scene.childNode(withName: "wordGardenRetinaAccents"))
            XCTAssertNotNil(scene.childNode(withName: "//" + accentName))
            if world == .sunmillCrossing || world == .storyHollow {
                XCTAssertNil(
                    scene.childNode(withName: "//questionPromptBackdrop"),
                    "Journey rooms should use one guidance surface instead of duplicating the prompt over the world."
                )
                if world == .sunmillCrossing {
                    XCTAssertNotNil(scene.childNode(withName: "sunmillLightPath"))
                    XCTAssertNotNil(scene.childNode(withName: "decorativeSunmillChoiceBank"))
                } else {
                    XCTAssertNotNil(scene.childNode(withName: "storyRootNetwork"))
                    XCTAssertNotNil(scene.childNode(withName: "storyMemoryBranch"))
                    XCTAssertNotNil(scene.childNode(withName: "storyHollowDoorGlow"))
                }
            } else {
                XCTAssertNil(
                    scene.childNode(withName: "//questionPromptBackdrop"),
                    "Flower Gate must not duplicate its readable lower prompt with a giant top panel."
                )
                XCTAssertNotNil(scene.childNode(withName: "instructionBackdrop"),
                                "Child-facing guidance retains its contrast surface.")
                let rune = try XCTUnwrap(scene.childNode(withName: "targetRune"))
                let glyph = try XCTUnwrap(rune.children.compactMap { $0 as? SKLabelNode }.first)
                let runeInk = try XCTUnwrap(glyph.fontColor)
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                XCTAssertTrue(runeInk.getRed(&red, green: &green, blue: &blue, alpha: &alpha))
                XCTAssertEqual(red, 0.24, accuracy: 0.005)
                XCTAssertEqual(green, 0.13, accuracy: 0.005)
                XCTAssertEqual(blue, 0.18, accuracy: 0.005)
                XCTAssertEqual(alpha, 1, accuracy: 0.005)
            }
            XCTAssertFalse(
                backdrop.isHidden,
                "Retina preparation must preserve the painted Word Garden environment."
            )
            scene.willLeave()
        }
    }

    func testScienceWorldsReuseRetinaPreparedIllustratedBackdrops() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )

        state.travel(to: .scienceLab)
        let greenhouse = ScienceLabScene(state: state)
        greenhouse.reducedMotion = true
        greenhouse.didMove(to: SKView())
        let greenhouseBackdrop = try XCTUnwrap(
            greenhouse.childNode(withName: "scienceGreenhouseBackdropHD") as? SKSpriteNode
        )
        XCTAssertEqual(
            greenhouseBackdrop.userData?["retinaPrepared"] as? Bool,
            true
        )
        XCTAssertEqual(
            greenhouseBackdrop.userData?["sourceCrop"] as? String,
            "word-garden-upper-crop"
        )
        let greenhouseImage = try XCTUnwrap(greenhouseBackdrop.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(greenhouseImage.width, 2560)
        XCTAssertGreaterThanOrEqual(greenhouseImage.height, 1440)
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceSeedBench"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceWaterValve"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceSunPrism"))
        greenhouse.willLeave()

        state.travel(to: .scienceWeatherTower)
        let weather = WeatherTowerScene(state: state)
        weather.reducedMotion = true
        weather.didMove(to: SKView())
        let weatherBackdrop = try XCTUnwrap(
            weather.childNode(withName: "//weatherBackdropRetina") as? SKSpriteNode
        )
        XCTAssertEqual(
            weatherBackdrop.userData?["retinaPrepared"] as? Bool,
            true
        )
        XCTAssertEqual(
            weatherBackdrop.userData?["sourceAsset"] as? String,
            "WeatherTowerIllustratedV2"
        )
        let weatherImage = try XCTUnwrap(weatherBackdrop.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(weatherImage.width, 2560)
        XCTAssertGreaterThanOrEqual(weatherImage.height, 1440)
        XCTAssertNotNil(weather.childNode(withName: "weatherTowerStructure"))
        XCTAssertNotNil(weather.childNode(withName: "scienceForecastBase"))
        XCTAssertNotNil(weather.childNode(withName: "scienceCreatureGate"))
        weather.willLeave()

        state.travel(to: .scienceCreatureGrove)
        let grove = CreatureGroveScene(state: state)
        grove.reducedMotion = true
        grove.didMove(to: SKView())
        let groveBackdrop = try XCTUnwrap(
            grove.childNode(withName: "creatureGroveBackdropHD") as? SKSpriteNode
        )
        XCTAssertEqual(
            groveBackdrop.userData?["retinaPrepared"] as? Bool,
            true
        )
        XCTAssertEqual(
            groveBackdrop.userData?["sourceCrop"] as? String,
            "word-garden-lower-crop"
        )
        let groveImage = try XCTUnwrap(groveBackdrop.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(groveImage.width, 2560)
        XCTAssertGreaterThanOrEqual(groveImage.height, 1440)
        XCTAssertNotNil(grove.childNode(withName: "scienceGroveDuck"))
        XCTAssertNotNil(grove.childNode(withName: "scienceHabitatPond"))
        XCTAssertNotNil(grove.childNode(withName: "scienceWebbedFeet"))
        grove.willLeave()
    }

    func testMathCastlePreservesIllustrationWithRetinaPreparedRaster() throws {
        XCTAssertFalse(
            ArtSystem.isRetinaReady(
                "MathCastle",
                targetPoints: CGSize(width: 1280, height: 720)
            ),
            "The approved Math Castle source is still 1x and needs the preparation path."
        )

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let backdrop = try XCTUnwrap(
            scene.childNode(withName: "worldBackdrop") as? SKSpriteNode
        )
        XCTAssertEqual(
            backdrop.userData?["sourceAsset"] as? String,
            "MathCastleIllustratedV2"
        )
        XCTAssertEqual(
            backdrop.userData?["retinaPrepared"] as? Bool,
            true
        )
        let backdropImage = try XCTUnwrap(backdrop.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(backdropImage.width, 2560)
        XCTAssertGreaterThanOrEqual(backdropImage.height, 1440)

        let courtyard = try XCTUnwrap(
            scene.childNode(withName: "castleCourtyardRetina") as? SKSpriteNode
        )
        let courtyardImage = try XCTUnwrap(courtyard.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(courtyardImage.width, 2560)
        XCTAssertGreaterThanOrEqual(courtyardImage.height, 500)

        XCTAssertNotNil(scene.childNode(withName: "castleRetinaAccents"))
        XCTAssertNotNil(scene.childNode(withName: "//castleFloorRim"))
        XCTAssertNotNil(scene.childNode(withName: "//castleGateRim"))
        XCTAssertFalse(
            scene.childNode(withName: "worldBackdrop")?.isHidden ?? true,
            "Retina preparation must preserve the illustrated castle instead of replacing it."
        )
    }

    func testStoryTreePreservesIllustrationWithRetinaPreparedRaster() throws {
        XCTAssertFalse(
            ArtSystem.isRetinaReady(
                "StarlightIsles",
                targetPoints: CGSize(width: 1280, height: 720)
            ),
            "The approved Starlight Isles source is still 1x and needs the preparation path."
        )

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let backdrop = try XCTUnwrap(
            scene.childNode(withName: "worldBackdrop") as? SKSpriteNode
        )
        XCTAssertEqual(
            backdrop.userData?["sourceAsset"] as? String,
            "StoryTreeIllustratedV2"
        )
        XCTAssertEqual(
            backdrop.userData?["retinaPrepared"] as? Bool,
            true
        )
        let backdropImage = try XCTUnwrap(backdrop.texture?.cgImage())
        XCTAssertGreaterThanOrEqual(backdropImage.width, 2560)
        XCTAssertGreaterThanOrEqual(backdropImage.height, 1440)

        for side in ["Left", "Right"] {
            let foreground = try XCTUnwrap(
                scene.childNode(withName: "foreground" + side) as? SKSpriteNode
            )
            let image = try XCTUnwrap(foreground.texture?.cgImage())
            XCTAssertGreaterThanOrEqual(image.width, 300)
            XCTAssertGreaterThanOrEqual(image.height, 320)
        }

        XCTAssertNotNil(scene.childNode(withName: "storyTreeRetinaAccents"))
        XCTAssertNotNil(scene.childNode(withName: "//storyBridgeRim"))
        XCTAssertNotNil(scene.childNode(withName: "//storyRouteSpark"))
        XCTAssertTrue(scene.isOnPath(CGPoint(x: 285, y: 235)))
        XCTAssertFalse(scene.isOnPath(CGPoint(x: 1000, y: 200)))
        XCTAssertFalse(
            backdrop.isHidden,
            "Retina preparation must preserve the illustrated Story Tree world."
        )
    }

    func testApprovedArtIsPackagedAndEveryActorPoseResolves() async throws {
        for name in ["StarlightIsles", "MathCastle", "CrystalCart", "Crystal", "IslesForegroundLeft", "CastleForegroundRight", "BridgeOakPlank", "BridgeGreenPlank", "BridgeTimber", "BridgeWorkOrder", "BridgeChannel", "BridgeDial", "V331WorldAtlas", "Lumi", "Milo", "Tiko", "StoryBloom"] {
            XCTAssertNotNil(ArtSystem.texture(name), "Missing bundled image: \(name)")
        }
        for character in ["Valkyrie", "Pip"] {
            for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
                XCTAssertFalse(ArtSystem.frames(character: character, pose: pose).isEmpty, "Missing \(character) \(pose)")
            }
        }
        XCTAssertEqual(ArtSystem.frames(character: "Valkyrie", pose: .walk).count, 2)
        for character in ["Lumi", "Tiko"] {
            for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
                XCTAssertFalse(ArtSystem.frames(character: character, pose: pose).isEmpty)
            }
        }
        let lumi = LumiNode()
        lumi.pose(.interact)
        XCTAssertFalse(lumi.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first?.isHidden ?? true)
        let tiko = TikoNode()
        tiko.pose(.interact)
        XCTAssertFalse(tiko.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first?.isHidden ?? true)
        let actor = ValkyrieNode()
        for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
            actor.pose(pose)
            let sprite = try XCTUnwrap(actor.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first)
            XCTAssertFalse(sprite.isHidden)
            XCTAssertEqual(sprite.anchorPoint, CGPoint(x: 0.5, y: 0))
            XCTAssertEqual(sprite.size.height, 300)
            XCTAssertFalse(actor.children.compactMap { $0 as? SKLabelNode }.contains { !$0.isHidden })
        }
    }

    func testCompanionPresentationPreservesSourceAspectAndReadablePresence() throws {
        let companions: [(String, CharacterNode, CGFloat)] = [
            ("Lumi", LumiNode(), 128),
            ("Milo", MiloNode(), 113),
            ("Tiko", TikoNode(), 130)
        ]

        for (asset, actor, expectedHeight) in companions {
            actor.pose(.idle)
            let sprite = try XCTUnwrap(
                actor.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first
            )
            let source = try XCTUnwrap(ArtSystem.texture(asset))
            XCTAssertGreaterThan(source.size().height, 0)
            XCTAssertEqual(
                sprite.size.width / sprite.size.height,
                source.size().width / source.size().height,
                accuracy: 0.001,
                "\(asset) must render at its source-art aspect ratio."
            )
            XCTAssertEqual(sprite.size.height, expectedHeight, accuracy: 0.001)
            XCTAssertNotNil(
                actor.childNode(withName: "companionPresence"),
                "\(asset) needs an in-world grounding treatment."
            )
            XCTAssertFalse(
                actor.children.compactMap { $0 as? SKLabelNode }.contains { !$0.isHidden },
                "\(asset) should never expose the engineering fallback label when art resolves."
            )
        }

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let garden = WordGardenScene(state: state)
        garden.reducedMotion = true
        garden.didMove(to: SKView())
        defer { garden.willLeave() }

        let lumi = try XCTUnwrap(garden.childNode(withName: "lumi"))
        XCTAssertGreaterThanOrEqual(
            lumi.calculateAccumulatedFrame().height,
            90,
            "Lumi must read as a companion, not a tiny decorative sticker."
        )
    }

    func testActorKeepsFacingWhenItStopsAndReducedMotionRemovesAmbientActions() async throws {
        let actor = ValkyrieNode(); actor.position = CGPoint(x: 500, y: 175)
        actor.walk(to: CGPoint(x: 200, y: 175)) {}
        XCTAssertLessThan(actor.bodyNode.xScale, 0)
        actor.cancelTravel()
        XCTAssertLessThan(actor.bodyNode.xScale, 0)
        actor.face(toward: CGPoint(x: 820, y: 310)); actor.pose(.interact)
        XCTAssertGreaterThan(actor.bodyNode.xScale, 0)
        actor.reducedMotion = true; actor.pose(.idle)
        XCTAssertNil(actor.bodyNode.action(forKey: "pose"))
        XCTAssertNil(actor.action(forKey: "travel"))
    }

    func testMathArtKeepsLiveCartInputAndPowerReaction() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        // SKActions only advance while SpriteKit presents the scene. A manual
        // didMove call on a temporary SKView cannot exercise route timing.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = MathCastleScene(state: state)
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
        scene.update(0) // Exercise real actor depth, not the initial z = 0 state.
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 300, y: 615)), "wind")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 52, y: 669)), "home")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 595, y: 235)), "supply")
        XCTAssertNotNil(scene.childNode(withName: "mathWorkZone"))
        XCTAssertNotNil(scene.childNode(withName: "//cartDropZone"))
        XCTAssertTrue(scene.childNode(withName: "next")?.isHidden == false) // Free workshop exit.
        XCTAssertTrue(scene.childNode(withName: "//submit")?.isHidden == true)
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        XCTAssertTrue(scene.childNode(withName: "workshopRackBacking")?.isHidden == true)
        XCTAssertTrue(scene.childNode(withName: "next")?.isHidden == true)
        XCTAssertTrue(scene.childNode(withName: "//submit")?.isHidden == false)
        let target = try XCTUnwrap(state.runtime?.encounter.targetQuantity)
        for _ in 0..<target { scene.handleTap(at: CGPoint(x: 595, y: 235)) }
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(state.runtime?.completed == true)
        XCTAssertTrue(scene.childNode(withName: "//submit")?.isHidden == true)
        XCTAssertTrue(scene.childNode(withName: "workshopRackBacking")?.isHidden == false)
        XCTAssertTrue(scene.childNode(withName: "next")?.isHidden == false)
        let powerLight = try XCTUnwrap(scene.childNode(withName: "castlePowerLight") as? SKShapeNode)
        XCTAssertEqual(powerLight.glowWidth, 16)
        let portal = try XCTUnwrap(scene.childNode(withName: "challengeGate") as? SKShapeNode)
        XCTAssertEqual(portal.glowWidth, 4, "Ordinary work powers the castle route but must not fake Challenge Gate readiness.")

        let bridge = try XCTUnwrap(scene.childNode(withName: "physicalRouteBridge"))
        XCTAssertNotNil(bridge.action(forKey: "routeOpen"))
        let beacon = try XCTUnwrap(scene.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertNotNil(beacon.action(forKey: "routeReady"))
        XCTAssertNotNil(scene.pip.action(forKey: "travel"))

        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNil(
            scene.valkyrie.action(forKey: "travel"),
            "Do not let the child run onto the route while the physical bridge is still unfolding."
        )

        // A paused renderer must keep the route unavailable even after more
        // wall-clock time than the normal opening duration has passed.
        view.isPaused = true
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(beacon.glowWidth, 0)
        XCTAssertLessThan(bridge.xScale, 1)
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        view.isPaused = false

        // Wait for rendered readiness with a bounded deadline, rather than
        // assuming the simulator delivered a fixed number of frames.
        let deadline = Date().addingTimeInterval(5)
        while beacon.glowWidth != 18 && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        XCTAssertEqual(beacon.glowWidth, 18)
        XCTAssertEqual(bridge.xScale, 1, accuracy: 0.001)
        XCTAssertEqual(bridge.alpha, 1, accuracy: 0.001)
        scene.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertNotNil(
            scene.valkyrie.action(forKey: "travel"),
            "Once the bridge is visibly ready, the next action should become physical route traversal."
        )
        scene.willLeave()
    }

    func testStoryTreeIgnoresTheChasmAndRoutesCastleEntryThroughThePaintedPath() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state); scene.didMove(to: SKView())
        XCTAssertFalse(scene.isOnPath(CGPoint(x: 1000, y: 200)))
        scene.handleTap(at: CGPoint(x: 1000, y: 200))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertTrue(scene.isOnPath(CGPoint(x: 285, y: 235)))
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        XCTAssertNotNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertEqual(state.world, .storyTree)
        scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 795, y: 450)
        scene.update(0)
        let landmark = try XCTUnwrap(scene.childNode(withName: "castle"))
        XCTAssertFalse(landmark is SKShapeNode, "Story Tree destinations should be landmark assemblies, not generic button boxes.")
        scene.handleTap(at: CGPoint(x: 835, y: 535))
        XCTAssertEqual(state.world, .mathCastle)
        scene.willLeave()
    }

    func testWordGardenProgressesFlowerGateToSunmillToStoryHollowWithDistinctReward() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        let story = StoryTreeScene(state: state)
        story.didMove(to: SKView())
        story.valkyrie.position = CGPoint(x: 190, y: 170)
        story.handleTap(at: CGPoint(x: 150, y: 430))
        XCTAssertEqual(state.world, .wordGarden)
        story.willLeave()

        let flower = WordGardenScene(state: state)
        flower.didMove(to: SKView())
        XCTAssertNotNil(flower.childNode(withName: "flowerGate"))
        XCTAssertNil(flower.childNode(withName: "questionPrompt"))
        XCTAssertEqual(flower.instruction.text, state.nextLiteracyEncounter().prompt)
        XCTAssertNotNil(flower.childNode(withName: "targetRune"))
        XCTAssertEqual(flower.children.filter { $0.name == "flowerChoice" }.count, 4)
        XCTAssertEqual(flower.children.filter { $0.name == "soundFlower" }.count, 3)
        XCTAssertNil(flower.childNode(withName: "sunmillRoute"))
        XCTAssertEqual(state.nextLiteracyEncounter().skillID, LiteracySkills.visualLetterMatch)
        flower.willLeave()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.flowerGateComplete)
        XCTAssertTrue(state.sunmillAvailable)

        state.travel(to: .wordGarden)
        let awakeGate = WordGardenScene(state: state)
        awakeGate.didMove(to: SKView())
        XCTAssertNotNil(awakeGate.childNode(withName: "sunmillRoute"))
        awakeGate.valkyrie.position = CGPoint(x: 945, y: 175)
        awakeGate.handleTap(at: CGPoint(x: 995, y: 165))
        XCTAssertEqual(state.world, .sunmillCrossing)
        awakeGate.willLeave()

        let sunmill = WordGardenScene(state: state)
        sunmill.didMove(to: SKView())
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillWheel"))
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillTower"))
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillWater"))
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillLightPath"))
        XCTAssertNotNil(sunmill.childNode(withName: "decorativeSunmillChoiceBank"))
        XCTAssertNotNil(sunmill.childNode(withName: "decorativeSunmillChoiceVine"))
        XCTAssertNotNil(sunmill.childNode(withName: "targetRune"))
        XCTAssertNil(
            sunmill.childNode(withName: "questionPrompt"),
            "Sunmill Crossing must not repeat the same learning prompt above and below the world."
        )
        XCTAssertFalse(
            sunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true,
            "The sleeping crossing should remain visible so learning visibly restores it."
        )
        let sleepingPlank = try XCTUnwrap(
            sunmill.childNode(withName: "//sunmillBridgePlank0")
        )
        XCTAssertLessThan(sleepingPlank.alpha, 0.25)
        XCTAssertEqual(sunmill.valkyrie.xScale, 0.58, accuracy: 0.001)
        let sunmillInstructionBackdrop = try XCTUnwrap(
            sunmill.childNode(withName: "instructionBackdrop")
        )
        XCTAssertLessThan(
            sunmillInstructionBackdrop.calculateAccumulatedFrame().width,
            800,
            "Sunmill guidance should stay compact enough to leave the painted world dominant."
        )

        let sunmillChoices = sunmill.children.filter { $0.name == "sunmillChoice" }
        XCTAssertEqual(sunmillChoices.count, 4)
        for choice in sunmillChoices {
            let frame = choice.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 100)
            XCTAssertGreaterThanOrEqual(frame.height, 100)
            XCTAssertNotNil(choice.childNode(withName: "decorativeSunmillChoiceStem"))
            XCTAssertNotNil(choice.childNode(withName: "decorativeSunmillChoiceSocket"))
            XCTAssertEqual(
                sunmill.targetName(at: choice.position),
                "sunmillChoice",
                "Physical leaf decoration must never steal the literacy tap."
            )
        }
        XCTAssertEqual(
            state.nextSunmillEncounter()?.mechanicID,
            WordGardenMechanicID.sunmillPair
        )
        sunmill.willLeave()

        for encounter in WordGardenEncounterCatalog.sunmillVisualShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.sunmillComplete)
        XCTAssertTrue(state.storyHollowAvailable)

        let awakeSunmill = WordGardenScene(state: state)
        awakeSunmill.didMove(to: SKView())
        XCTAssertFalse(awakeSunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true)
        XCTAssertGreaterThan(
            awakeSunmill.childNode(withName: "//sunmillBridgePlank6")?.alpha ?? 0,
            0.99,
            "Completing the Sunmill should physically restore the whole crossing."
        )
        XCTAssertGreaterThan(
            awakeSunmill.childNode(withName: "sunmillLightPath")?.alpha ?? 0,
            0.9
        )
        XCTAssertNotNil(awakeSunmill.childNode(withName: "storyHollowRoute"))
        awakeSunmill.valkyrie.position = CGPoint(x: 1015, y: 175)
        XCTAssertEqual(
            awakeSunmill.targetName(at: CGPoint(x: 1095, y: 300)),
            "storyHollowRoute"
        )
        awakeSunmill.handleTap(at: CGPoint(x: 1095, y: 300))
        XCTAssertEqual(state.world, .storyHollow)
        awakeSunmill.willLeave()

        let hollow = WordGardenScene(state: state)
        hollow.didMove(to: SKView())
        XCTAssertNotNil(hollow.childNode(withName: "storyHollow"))
        XCTAssertNotNil(hollow.childNode(withName: "wordSeed"))
        XCTAssertNotNil(hollow.childNode(withName: "storyRootNetwork"))
        XCTAssertNotNil(hollow.childNode(withName: "storyMemoryBranch"))
        XCTAssertNotNil(hollow.childNode(withName: "storyHollowDoorGlow"))
        XCTAssertNotNil(hollow.childNode(withName: "storySequencePreview"))
        XCTAssertNil(
            hollow.childNode(withName: "questionPrompt"),
            "Story Hollow must show its sequence on the memory tree instead of a duplicate floating prompt."
        )
        XCTAssertEqual(hollow.valkyrie.xScale, 0.58, accuracy: 0.001)
        let hollowInstructionBackdrop = try XCTUnwrap(
            hollow.childNode(withName: "instructionBackdrop")
        )
        XCTAssertLessThan(
            hollowInstructionBackdrop.calculateAccumulatedFrame().width,
            800,
            "Story Hollow guidance should stay compact enough to leave the painted world dominant."
        )

        let hollowChoices = hollow.children.filter { $0.name == "storyHollowChoice" }
        XCTAssertEqual(hollowChoices.count, 4)
        for choice in hollowChoices {
            let frame = choice.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 100)
            XCTAssertGreaterThanOrEqual(frame.height, 100)
            XCTAssertNotNil(choice.childNode(withName: "decorativeStoryChoiceRoot"))
            XCTAssertNotNil(choice.childNode(withName: "decorativeStoryChoiceRootKnot"))
            XCTAssertNotNil(choice.childNode(withName: "decorativeStoryChoiceSprout"))
            XCTAssertEqual(
                hollow.targetName(at: choice.position),
                "storyHollowChoice",
                "Root and sprout decoration must never steal the literacy tap."
            )
        }

        XCTAssertEqual(
            state.nextStoryHollowEncounter()?.skillID,
            LiteracySkills.visualPrintSequence
        )
        hollow.willLeave()

        for encounter in WordGardenEncounterCatalog.storyHollowSequence {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        XCTAssertTrue(state.storyHollowComplete)
        XCTAssertTrue(state.hasStoryReward(.wordGardenLantern))
        XCTAssertFalse(
            state.hasStoryReward(.moonLantern),
            "Word Garden completion must not unlock Math Castle's reward."
        )
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(state.profile.progress(for: LiteracySkills.decodeCVC).state, .new)

        let restoredHollow = WordGardenScene(state: state)
        restoredHollow.didMove(to: SKView())
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyBloom"))
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyTreeReturn"))
        XCTAssertGreaterThan(
            restoredHollow.childNode(withName: "storyHollowDoorGlow")?.alpha ?? 0,
            0.99
        )
        for index in 0..<WordGardenEncounterCatalog.storyHollowPattern.count {
            XCTAssertGreaterThan(
                restoredHollow.childNode(withName: "storyRootGlow\(index)")?.alpha ?? 0,
                0.9,
                "Each restored memory should remain visibly connected through the roots."
            )
        }
        XCTAssertEqual(
            restoredHollow.targetName(at: CGPoint(x: 1090, y: 195)),
            "storyTreeReturn"
        )
        restoredHollow.handleTap(at: CGPoint(x: 1090, y: 195))
        XCTAssertEqual(state.world, .storyTree)
        restoredHollow.willLeave()

        let restoredState = try AppState(context: ModelContext(container))
        XCTAssertTrue(restoredState.hasStoryReward(.wordGardenLantern))
        XCTAssertFalse(restoredState.hasStoryReward(.moonLantern))
        XCTAssertEqual(restoredState.world, .storyTree)

        let restoredTree = StoryTreeScene(state: restoredState)
        restoredTree.didMove(to: SKView())
        XCTAssertNotNil(restoredTree.childNode(withName: "wordGardenLantern"))
        XCTAssertNil(restoredTree.childNode(withName: "moonLantern"))
        restoredTree.willLeave()
    }


    func testTikoReturnsToTheWalkableLaneBetweenPathTileMaps() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let view = SKView(frame: window.bounds)
        let controller = UIViewController()
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation + PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        XCTAssertTrue(state.puzzlePathTilesAvailable)
        let puzzle = try XCTUnwrap(state.nextPuzzlePathTilesEncounter())
        let correctIndex = try XCTUnwrap(puzzle.choices.indices.first {
            puzzle.isValidChoice($0)
        })
        state.travel(to: .pathTiles)
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)

        let ys: [CGFloat] = [325, 245, 165]
        scene.handleTap(at: CGPoint(x: 1100, y: ys[correctIndex]))
        let trace = try XCTUnwrap(scene.childNode(withName: "//pathRouteTrace") as? SKShapeNode)
        XCTAssertNotNil(trace.path, "The chosen route must have a visible in-world connection.")
        XCTAssertEqual(trace.lineWidth, 10, accuracy: 0.001)
        let startingTile = try XCTUnwrap(puzzle.route(for: correctIndex).first)
        let startingStone = try XCTUnwrap(scene.childNode(
            withName: "//pathStone\(startingTile.x)_\(startingTile.y)"
        ))
        let raisedBevel = try XCTUnwrap(
            startingStone.childNode(withName: "pathStoneBevel") as? SKShapeNode
        )
        XCTAssertEqual(raisedBevel.position.y, 9, accuracy: 0.001,
                       "Safe stones should appear lifted even with Reduced Motion.")
        try await waitUntil(timeout: 4) { scene.childNode(withName: "pathNext") != nil }
        XCTAssertGreaterThan(scene.tiko.position.y, scene.walkable.maxY,
                             "Successful path demonstration should reach the map goal")
        scene.handleTap(at: CGPoint(x: 1160, y: 145))
        XCTAssertNotNil(scene.childNode(withName: "pathGrid"))
        XCTAssertLessThanOrEqual(scene.tiko.position.y, scene.walkable.maxY,
                                 "Tiko must not cover the next map after choosing Next")
        scene.willLeave()
    }

    func testPuzzlePalaceRouteSingleTapWalksIntoMemoryBridgeWithoutSecondTap() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let view = SKView(frame: window.bounds)
        let controller = UIViewController()
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }

        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        XCTAssertTrue(state.puzzleRuneGateComplete)
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        XCTAssertNotNil(scene.childNode(withName: "memoryBridgeRoute"))
        XCTAssertLessThan(scene.valkyrie.position.x, 300)

        // A single distant doorway tap should walk, then enter the next room.
        // Repeated doorway and stray floor taps cannot restart/cancel that walk.
        scene.handleTap(at: CGPoint(x: 1010, y: 175))
        XCTAssertEqual(state.world, .storyTree)
        scene.handleTap(at: CGPoint(x: 1010, y: 175))
        scene.handleTap(at: CGPoint(x: 500, y: 175))
        try await waitUntil(timeout: 5) { state.world == .memoryBridge }
        scene.willLeave()
    }

    func testEveryCompletedPalaceDoorwayMovesToTheNextRoom() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation + PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }

        let doorways: [(AppState.World, String, AppState.World)] = [
            (.puzzlePalace, "memoryBridgeRoute", .memoryBridge),
            (.memoryBridge, "stopGoRoute", .stopGoOrbs),
            (.stopGoOrbs, "sortingPedestalRoute", .sortingPedestal),
            (.sortingPedestal, "resortVaultRoute", .resortVault),
            (.resortVault, "mirrorHallRoute", .mirrorHall)
        ]
        for (origin, target, destination) in doorways {
            state.travel(to: origin)
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            scene.didMove(to: SKView())
            XCTAssertNotNil(scene.childNode(withName: target), "Missing unlocked doorway \(target)")
            scene.valkyrie.position = CGPoint(x: 1000, y: 175)
            scene.handleTap(at: CGPoint(x: 1010, y: 175))
            XCTAssertEqual(state.world, destination)
            scene.willLeave()
        }
    }

    func testPuzzlePalaceRuneGateRoutesFromStoryTreeAndPersistsEvidence() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))

        let story = StoryTreeScene(state: state)
        story.didMove(to: SKView())
        XCTAssertNotNil(story.childNode(withName: "puzzlePalace"))
        story.valkyrie.position = CGPoint(x: 580, y: 450)
        story.handleTap(at: CGPoint(x: 505, y: 515))
        XCTAssertEqual(state.world, .puzzlePalace)
        story.willLeave()

        let palace = PuzzlePalaceScene(state: state)
        palace.reducedMotion = true
        palace.didMove(to: SKView())
        XCTAssertNotNil(palace.childNode(withName: "puzzleGate"))
        XCTAssertNotNil(palace.childNode(withName: "runeBoard"))
        XCTAssertNotNil(palace.childNode(withName: "//runeSocket"))
        XCTAssertEqual(palace.children.filter { $0.name == "runeChoice" }.count, 3)
        XCTAssertEqual(
            state.nextPuzzleEncounter().skillID,
            PuzzleSkills.visualPatternContinue
        )
        XCTAssertFalse(state.puzzleRuneGateComplete)

        let first = state.nextPuzzleEncounter()
        _ = state.recordPuzzle(
            first,
            outcome: .correct,
            support: .independent,
            attempts: 1,
            responseTime: 1
        )
        XCTAssertEqual(
            PuzzlePalaceDirector.runeGateIndependentSuccessCount(profile: state.profile),
            1
        )
        palace.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .puzzlePalace)
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.visualPatternContinue).evidence.count,
            1
        )
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.visualSequenceMemory).state,
            .new
        )

        for encounter in PuzzlePalaceEncounterCatalog.runeGate.dropFirst() {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleRuneGateComplete)

        let openPalace = PuzzlePalaceScene(state: restored)
        openPalace.reducedMotion = true
        openPalace.didMove(to: SKView())
        XCTAssertEqual(openPalace.children.filter { $0.name == "runeChoice" }.count, 0)
        let gate = try XCTUnwrap(openPalace.childNode(withName: "puzzleGate") as? SKShapeNode)
        XCTAssertEqual(gate.glowWidth, 16)
        let crest = try XCTUnwrap(openPalace.childNode(withName: "//puzzleGateCrest") as? SKShapeNode)
        XCTAssertEqual(crest.alpha, 1, accuracy: 0.001,
                       "The Rune Gate's actual shape crest must respond to earned progress")
        let runePath = try XCTUnwrap(openPalace.childNode(withName: "runePath"))
        let stones = runePath.children.compactMap { $0 as? SKShapeNode }
        XCTAssertEqual(stones.count, 4)
        XCTAssertTrue(stones.allSatisfy {
            ($0.userData?["runePathPowered"] as? Bool) == true
                && $0.fillColor.cgColor.alpha > 0.75
                && $0.strokeColor.cgColor.alpha > 0.94
        }, "Opening the gate must power and brighten all four actual path stones")
        XCTAssertNotNil(openPalace.childNode(withName: "memoryBridgeRoute"))
        openPalace.valkyrie.position = CGPoint(x: 1005, y: 175)
        openPalace.handleTap(at: CGPoint(x: 1005, y: 165))
        XCTAssertEqual(restored.world, .memoryBridge)
        openPalace.willLeave()

        let memory = PuzzlePalaceScene(state: restored)
        memory.reducedMotion = true
        memory.didMove(to: SKView())
        XCTAssertNotNil(memory.childNode(withName: "memoryChasm"))
        XCTAssertEqual(memory.children.filter { $0.name == "memoryPad" }.count, 4)
        XCTAssertEqual(
            restored.nextPuzzleMemoryEncounter()?.skillID,
            PuzzleSkills.visualSequenceMemory
        )
        XCTAssertFalse(restored.puzzleMemoryBridgeComplete)
        memory.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleMemoryBridgeComplete)

        let restoredMemory = PuzzlePalaceScene(state: restored)
        restoredMemory.reducedMotion = true
        restoredMemory.didMove(to: SKView())
        XCTAssertNotNil(restoredMemory.childNode(withName: "memoryBridgeRestored"))
        XCTAssertEqual(restoredMemory.children.filter { $0.name == "memoryPad" }.count, 0)
        XCTAssertNotNil(restoredMemory.childNode(withName: "stopGoRoute"))
        restoredMemory.valkyrie.position = CGPoint(x: 1000, y: 175)
        restoredMemory.handleTap(at: CGPoint(x: 1000, y: 165))
        XCTAssertEqual(restored.world, .stopGoOrbs)
        restoredMemory.willLeave()

        let stopGo = PuzzlePalaceScene(state: restored)
        stopGo.reducedMotion = true
        stopGo.didMove(to: SKView())
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoOrb"))
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoBarrier"))
        XCTAssertEqual(
            restored.nextPuzzleStopGoEncounter()?.skillID,
            PuzzleSkills.responseInhibition
        )
        XCTAssertFalse(restored.puzzleStopGoComplete)
        stopGo.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleStopGoComplete)

        let restoredStopGo = PuzzlePalaceScene(state: restored)
        restoredStopGo.reducedMotion = true
        restoredStopGo.didMove(to: SKView())
        XCTAssertNotNil(restoredStopGo.childNode(withName: "stopGoBarrierOpen"))
        XCTAssertNotNil(restoredStopGo.childNode(withName: "sortingPedestalRoute"))
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.ruleSwitching).state,
            .new
        )
        restoredStopGo.valkyrie.position = CGPoint(x: 1000, y: 175)
        restoredStopGo.handleTap(at: CGPoint(x: 1000, y: 165))
        XCTAssertEqual(restored.world, .sortingPedestal)
        restoredStopGo.willLeave()

        let sorting = PuzzlePalaceScene(state: restored)
        sorting.reducedMotion = true
        sorting.didMove(to: SKView())
        XCTAssertNotNil(sorting.childNode(withName: "sortingRuleDial"))
        XCTAssertNotNil(sorting.childNode(withName: "sortLeftPedestal"))
        XCTAssertNotNil(sorting.childNode(withName: "sortRightPedestal"))
        XCTAssertEqual(
            restored.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.singleRuleSort
        )
        XCTAssertFalse(restored.puzzleSortingFoundationComplete)
        sorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleSortingFoundationComplete)
        XCTAssertEqual(
            restored.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.ruleSwitching
        )

        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = restored.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(restored.puzzleRuleSwitchingComplete)
        XCTAssertTrue(restored.puzzleSortingPedestalComplete)
        XCTAssertEqual(
            restored.profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .new
        )

        let stableSorting = PuzzlePalaceScene(state: restored)
        stableSorting.reducedMotion = true
        stableSorting.didMove(to: SKView())
        let dial = try XCTUnwrap(
            stableSorting.childNode(withName: "sortingRuleDial") as? SKShapeNode
        )
        XCTAssertEqual(dial.glowWidth, 14)
        stableSorting.handleTap(at: CGPoint(x: 52, y: 669))
        XCTAssertEqual(restored.world, .storyTree)
        stableSorting.willLeave()
    }

    func testFlowerGateCompletionStopsPreviewOnRestore() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            state.recordLiteracy(encounter, outcome: .correct, support: .independent,
                                 attempts: 1, responseTime: 1)
        }
        let garden = WordGardenScene(state: state)
        garden.didMove(to: SKView())
        XCTAssertNil(garden.action(forKey: "wordGardenPreview"))
        XCTAssertTrue(garden.childNode(withName: "targetRune") == nil || garden.childNode(withName: "targetRune")?.isHidden == true)
        garden.handleTap(at: CGPoint(x: 675, y: 228))
        XCTAssertNil(garden.action(forKey: "wordGardenPreview"))
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.count,
            WordGardenEncounterCatalog.visualLetterShapes.count
        )
        garden.willLeave()
    }

    func testFlowerGateRepeatedTapsAndExitCannotRecordStaleEvidence() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.travel(to: .wordGarden)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view; window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let garden = WordGardenScene(state: state)
        view.presentScene(garden)
        // Wait for the live preview state before approaching a current flower.
        try await waitUntil(timeout: 8) {
            garden.childNode(withName: "targetRune")?.isHidden == true
        }
        let flowers = garden.children.filter { $0.name == "flowerChoice" }
        XCTAssertGreaterThanOrEqual(flowers.count, 2)
        let firstFlower = try XCTUnwrap(flowers.first)
        let secondFlower = try XCTUnwrap(flowers.dropFirst().first)
        garden.handleTap(at: firstFlower.position)
        let firstTravel = garden.valkyrie.action(forKey: "travel")
        XCTAssertNotNil(firstTravel)
        garden.handleTap(at: secondFlower.position)
        XCTAssertTrue(garden.valkyrie.action(forKey: "travel") === firstTravel)
        garden.handleTap(at: CGPoint(x: 52, y: 669))
        XCTAssertEqual(state.world, .storyTree)
        try await Task.sleep(for: .seconds(2))
        XCTAssertTrue(state.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.isEmpty)
    }

    func testRuneGateIgnoresRapidSecondChoiceWhileActorsResolveFirstChoice() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true
        state.travel(to: .puzzlePalace)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = state.nextPuzzleEncounter()
        scene.handleTap(at: CGPoint(x: 770, y: 235))
        scene.handleTap(at: CGPoint(x: 575, y: 255))
        try await Task.sleep(nanoseconds: 1_500_000_000)

        let evidence = state.profile
            .progress(for: PuzzleSkills.visualPatternContinue)
            .evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
    }

    func testMemoryBridgeCanBeCompletedThroughLiveRunePadInteraction() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        state.travel(to: .memoryBridge)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = try XCTUnwrap(state.nextPuzzleMemoryEncounter())
        try await Task.sleep(nanoseconds: 2_400_000_000)
        let pads = scene.children.filter { $0.name == "memoryPad" }
        XCTAssertEqual(pads.count, encounter.choices.count)
        let bridge = try XCTUnwrap(scene.childNode(withName: "memoryChasm"))
        for pad in pads {
            XCTAssertGreaterThan(
                pad.zPosition, bridge.zPosition,
                "Interactive runes must be in front of the bridge masonry."
            )
            XCTAssertTrue(pad.isAccessibilityElement)
            XCTAssertTrue((pad.accessibilityLabel ?? "").hasPrefix("Memory rune:"))
        }
        for symbol in encounter.sequence {
            let pad = try XCTUnwrap(
                pads.first {
                    ($0.userData?["symbol"] as? String) == symbol
                }
            )
            scene.handleTap(at: pad.position)
            try await Task.sleep(nanoseconds: 450_000_000)
        }
        try await Task.sleep(nanoseconds: 500_000_000)

        let evidence = state.profile.progress(for: PuzzleSkills.visualSequenceMemory).evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
    }

    func testStopGoOrbsRejectHoldTapAndAcceptLiveGoTiming() async throws {
        func prepareState() throws -> AppState {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            for encounter in PuzzlePalaceEncounterCatalog.runeGate {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            state.travel(to: .stopGoOrbs)
            return state
        }

        // HOLD is a real blocked state. Tapping it records one incorrect
        // attempt and never opens the physical barrier.
        do {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let state = try prepareState()
            state.reducedMotion = true
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)
            let barrier = try XCTUnwrap(scene.childNode(withName: "stopGoBarrier") as? SKShapeNode)
            let glyph = try XCTUnwrap(scene.childNode(withName: "//stopGoOrbGlyph") as? SKLabelNode)

            try await waitUntil(timeout: 4) {
                glyph.text == "Ⅱ" && (scene.instruction.text ?? "").hasPrefix("HOLD")
            }
            XCTAssertEqual(barrier.xScale, 1, accuracy: 0.01)
            scene.handleTap(at: CGPoint(x: 755, y: 365))
            XCTAssertEqual(barrier.xScale, 1, accuracy: 0.01)
            let evidence = state.profile.progress(for: PuzzleSkills.responseInhibition).evidence
            XCTAssertEqual(evidence.count, 1)
            XCTAssertEqual(evidence.first?.outcome, .incorrect)
            XCTAssertEqual(evidence.first?.supportLevel, .independent)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        // Both motion modes must show a locked GO-ready state before any tap,
        // a physical release after the tap, and no premature or duplicate
        // mastery evidence while the rhythm is incomplete.
        for reducedMotion in [true, false] {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let state = try prepareState()
            state.reducedMotion = reducedMotion
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = reducedMotion
            view.presentScene(scene)
            let encounter = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleInhibitionEncounter)
            let barrier = try XCTUnwrap(scene.childNode(withName: "stopGoBarrier") as? SKShapeNode)
            let glyph = try XCTUnwrap(scene.childNode(withName: "//stopGoOrbGlyph") as? SKLabelNode)
            let goCount = encounter.signals.filter { $0 == .go }.count
            XCTAssertGreaterThan(goCount, 0)

            for index in 0..<goCount {
                try await waitUntil(timeout: 6) {
                    glyph.text == "✦" && (scene.instruction.text ?? "").hasPrefix("GO")
                }
                XCTAssertEqual(barrier.xScale, 1, accuracy: 0.01,
                               "Showing GO must not release the gate before the child taps.")
                XCTAssertTrue(state.profile.progress(for: PuzzleSkills.responseInhibition).evidence.isEmpty)
                scene.handleTap(at: CGPoint(x: 755, y: 365))
                try await waitUntil(timeout: 2) { barrier.xScale < 0.30 }
                XCTAssertTrue(state.profile.progress(for: PuzzleSkills.responseInhibition).evidence.isEmpty,
                              "Partial GO sequences must not create mastery evidence.")
                if index + 1 < goCount {
                    try await waitUntil(timeout: 6) {
                        glyph.text == "Ⅱ" && (scene.instruction.text ?? "").hasPrefix("HOLD")
                    }
                    XCTAssertEqual(barrier.xScale, 1, accuracy: 0.01,
                                   "The next HOLD must visibly lock the gate again.")
                }
            }

            try await waitUntil(timeout: 3) {
                state.profile.progress(for: PuzzleSkills.responseInhibition).evidence.count == 1
            }
            let evidence = state.profile.progress(for: PuzzleSkills.responseInhibition).evidence
            XCTAssertEqual(evidence.first?.encounterID, encounter.id)
            XCTAssertEqual(evidence.first?.outcome, .correct)
            XCTAssertEqual(evidence.first?.supportLevel, .independent)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
    }

    func testResortVaultPhysicallyChangesReceiversAndKeepsTwoPassEvidence() async throws {
        // Cover shape -> marks and marks -> shape using the actual room, not a
        // second encounter selection that might disagree with visible tokens.
        for reverse in [false, true] {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            state.reducedMotion = true
            for encounter in PuzzlePalaceEncounterCatalog.runeGate {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                       attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                       attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                       attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                       attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                       attempts: 1, responseTime: 1)
            }
            if reverse {
                _ = state.recordPuzzle(
                    PuzzlePalaceEncounterCatalog.changedRuleResort[0],
                    outcome: .correct, support: .independent,
                    attempts: 1, responseTime: 1
                )
            }
            XCTAssertTrue(state.puzzleResortAvailable)
            state.travel(to: .resortVault)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            let encounter = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleResortEncounter)
            XCTAssertNotEqual(encounter.initialRule, encounter.changedRule)
            let originalEvidenceCount = state.profile.progress(for: encounter.skillID).evidence.count
            let console = try XCTUnwrap(scene.childNode(withName: "resortRuleDial"))
            XCTAssertEqual(console.position.y, 277, accuracy: 0.01,
                           "The rule machine must be on the floor, not covering the painted vault door.")
            XCTAssertNotNil(scene.childNode(withName: "resortRuleConsoleBase"))

            let left = try XCTUnwrap(scene.childNode(withName: "resortLeftPedestal"))
            let right = try XCTUnwrap(scene.childNode(withName: "resortRightPedestal"))
            let leftGate = try XCTUnwrap(
                left.childNode(withName: "resortLeftPedestalRuleGateLeft")
            )
            let rightGate = try XCTUnwrap(
                right.childNode(withName: "resortRightPedestalRuleGateRight")
            )
            let originalDetent: CGFloat = encounter.initialRule == .shape ? 83 : 61
            let changedDetent: CGFloat = encounter.changedRule == .shape ? 83 : 61
            XCTAssertEqual(leftGate.position.x, -originalDetent, accuracy: 0.01)
            XCTAssertEqual(rightGate.position.x, originalDetent, accuracy: 0.01)

            for stone in encounter.objects {
                let bucket = stone.bucket(for: encounter.initialRule)
                scene.handleTap(at: CGPoint(x: bucket == .left ? 475 : 1035, y: 300))
                try await Task.sleep(nanoseconds: 670_000_000)
            }
            try await waitUntil(timeout: 3) {
                (scene.childNode(withName: "resortPassLabel") as? SKLabelNode)?.text
                    == "SAME SET · NEW RULE"
            }
            XCTAssertEqual(leftGate.position.x, -changedDetent, accuracy: 0.01)
            XCTAssertEqual(rightGate.position.x, changedDetent, accuracy: 0.01)
            XCTAssertNotEqual(originalDetent, changedDetent,
                              "Both rule systems must move the receiver shutters.")
            XCTAssertEqual(
                left.accessibilityLabel,
                encounter.changedRule == .shape
                    ? "Left alcove: round stones" : "Left alcove: one mark"
            )
            XCTAssertEqual(
                right.accessibilityLabel,
                encounter.changedRule == .shape
                    ? "Right alcove: pointed stones" : "Right alcove: two marks"
            )
            XCTAssertEqual(state.profile.progress(for: encounter.skillID).evidence.count,
                           originalEvidenceCount,
                           "Only completing both sorts can record a correct encounter.")
            try await capture(
                scene, in: view,
                name: reverse
                    ? "Puzzle-Palace-4x3-ResortVault-RuleSwitched-MarksToShape"
                    : "Puzzle-Palace-4x3-ResortVault-RuleSwitched-ShapeToMarks"
            )
            for stone in encounter.objects {
                let bucket = stone.bucket(for: encounter.changedRule)
                scene.handleTap(at: CGPoint(x: bucket == .left ? 475 : 1035, y: 300))
                try await Task.sleep(nanoseconds: 670_000_000)
            }
            try await waitUntil(timeout: 3) {
                state.profile.progress(for: encounter.skillID).evidence.count
                    == originalEvidenceCount + 1
            }
            let evidence = state.profile.progress(for: encounter.skillID).evidence
            XCTAssertEqual(evidence.last?.encounterID, encounter.id)
            XCTAssertEqual(evidence.last?.outcome, .correct)
            XCTAssertEqual(evidence.last?.supportLevel, .independent)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
    }

    func testSortingPedestalRunsStableAndSwitchingRulesThroughLivePedestals() async throws {
        func prepareState(includeFoundation: Bool) throws -> AppState {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            state.reducedMotion = true
            for encounter in PuzzlePalaceEncounterCatalog.runeGate {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
                _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
            }
            if includeFoundation {
                for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
                    _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent, attempts: 1, responseTime: 1)
                }
            }
            state.travel(to: .sortingPedestal)
            return state
        }

        func run(_ points: [CGPoint], state: AppState) async throws {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            try await Task.sleep(nanoseconds: 350_000_000)
            for point in points {
                scene.handleTap(at: point)
                try await Task.sleep(nanoseconds: 650_000_000)
            }
            try await Task.sleep(nanoseconds: 450_000_000)

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let left = CGPoint(x: 530, y: 355)
        let right = CGPoint(x: 970, y: 355)

        let foundationState = try prepareState(includeFoundation: false)
        let foundationEncounter = try XCTUnwrap(foundationState.nextPuzzleSortingEncounter())
        XCTAssertEqual(foundationEncounter.skillID, PuzzleSkills.singleRuleSort)
        try await run([left, right, left, right], state: foundationState)
        let foundationEvidence = foundationState.profile
            .progress(for: PuzzleSkills.singleRuleSort)
            .evidence
        XCTAssertEqual(foundationEvidence.count, 1)
        XCTAssertEqual(foundationEvidence.first?.encounterID, foundationEncounter.id)
        XCTAssertEqual(foundationEvidence.first?.supportLevel, .independent)

        let switchState = try prepareState(includeFoundation: true)
        let switchEncounter = try XCTUnwrap(switchState.nextPuzzleSortingEncounter())
        XCTAssertEqual(switchEncounter.skillID, PuzzleSkills.ruleSwitching)
        try await run([left, right, right, left], state: switchState)
        let switchEvidence = switchState.profile
            .progress(for: PuzzleSkills.ruleSwitching)
            .evidence
        XCTAssertEqual(switchEvidence.count, 1)
        XCTAssertEqual(switchEvidence.first?.encounterID, switchEncounter.id)
        XCTAssertEqual(switchEvidence.first?.supportLevel, .independent)
    }

    func testMirrorHallRejectedGlassPivotsThenClearsOnAssistedRepair() async throws {
        for motionReduced in [true, false] {
            let state = try AppState(
                context: ModelContext(try LearningStore.container(inMemory: true))
            )
            state.reducedMotion = motionReduced
            for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
                _ = state.recordPuzzle(encounter, outcome: .correct,
                                       support: .independent, attempts: 1, responseTime: 1)
            }
            XCTAssertTrue(state.puzzleMirrorHallAvailable)
            state.travel(to: .mirrorHall)

            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
            let controller = UIViewController()
            let view = SKView(frame: window.bounds)
            controller.view = view
            window.rootViewController = controller
            window.makeKeyAndVisible()
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = motionReduced
            view.presentScene(scene)

            let active = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleOrientationEncounter)
            let mirrors = scene.children.compactMap { $0 as? SKShapeNode }
                .filter { $0.name == "mirrorOrientationChoice" }
            let wrong = try XCTUnwrap(mirrors.first {
                ($0.userData?["direction"] as? String) != active.target.rawValue
            })
            let correct = try XCTUnwrap(mirrors.first {
                ($0.userData?["direction"] as? String) == active.target.rawValue
            })
            let wrongGlass = try XCTUnwrap(
                wrong.childNode(withName: "decorativeMirrorTurningPane") as? SKShapeNode
            )
            let correctGlass = try XCTUnwrap(
                correct.childNode(withName: "decorativeMirrorTurningPane") as? SKShapeNode
            )
            XCTAssertNil(scene.childNode(withName: "mirrorActiveRay"),
                         "An untouched mirror must not reveal the right answer.")
            XCTAssertEqual(wrongGlass.xScale, 1, accuracy: 0.01)
            XCTAssertEqual(scene.targetName(at: wrong.position), "mirrorOrientationChoice")

            scene.valkyrie.position = CGPoint(x: wrong.position.x - 235, y: 175)
            scene.handleTap(at: wrong.position)
            try await waitUntil(timeout: 5) {
                state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count == 1
            }
            try await waitUntil(timeout: 3) {
                abs(wrongGlass.xScale - 0.62) < 0.02
            }
            XCTAssertEqual(wrongGlass.zRotation, .pi / 10, accuracy: 0.02)
            let missedImpact = try XCTUnwrap(scene.childNode(withName: "mirrorActiveImpact"))
            XCTAssertEqual(missedImpact.position.y, 306, accuracy: 0.01)
            XCTAssertEqual(
                state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.first?.outcome,
                .incorrect
            )

            scene.valkyrie.position = CGPoint(x: correct.position.x - 235, y: 175)
            scene.handleTap(at: correct.position)
            try await waitUntil(timeout: 5) {
                state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count == 2
            }
            try await waitUntil(timeout: 3) {
                abs(wrongGlass.xScale - 1) < 0.02 && abs(correctGlass.xScale - 0.92) < 0.02
            }
            XCTAssertEqual(wrongGlass.zRotation, 0, accuracy: 0.02)
            XCTAssertNotEqual(wrong.strokeColor, .systemRed,
                              "A solved room cannot leave the earlier mirror falsely rejected.")
            XCTAssertEqual(correctGlass.zRotation, -.pi / 18, accuracy: 0.02)
            let repairedImpact = try XCTUnwrap(scene.childNode(withName: "mirrorActiveImpact"))
            XCTAssertEqual(repairedImpact.position.y, 252, accuracy: 0.01)
            XCTAssertEqual(repairedImpact.position.x, correct.position.x, accuracy: 0.01)
            XCTAssertNotNil(scene.childNode(withName: "mirrorActiveRay"))
            let evidence = state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence
            XCTAssertEqual(evidence.map(\.outcome), [.incorrect, .correct])
            XCTAssertEqual(evidence.map(\.supportLevel), [.independent, .lightHint])
            XCTAssertEqual(evidence.last?.encounterID, active.id)
            XCTAssertFalse(state.puzzleMirrorHallComplete,
                           "Assisted recovery cannot bypass the independent progression gate.")
            if motionReduced {
                try await capture(scene, in: view,
                                  name: "Puzzle-Palace-4x3-Mirror-Hall-Physical-Assisted-Repair")
            }

            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }
    }

    func testMirrorHallRecordsSpatialOrientationThroughLiveMirrorChoice() async throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleMirrorHallAvailable)
        state.travel(to: .mirrorHall)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        let encounter = try XCTUnwrap(state.nextPuzzleMirrorHallEncounter())
        let source = try XCTUnwrap(scene.childNode(withName: "mirrorBeacon") as? SKShapeNode)
        XCTAssertLessThan(source.frame.width, 100,
                          "The light source must be a mounted lens, not a huge floating quiz disk.")
        XCTAssertNotNil(scene.childNode(withName: "mirrorBeaconMount"))
        XCTAssertNotNil(source.childNode(withName: "decorativeMirrorSourceLens"))
        XCTAssertNil(scene.childNode(withName: "mirrorActiveRay"),
                     "No reflection may reveal the right choice before the child responds.")
        let choice = try XCTUnwrap(
            scene.children
                .compactMap { $0 as? SKShapeNode }
                .first {
                    $0.name == "mirrorOrientationChoice"
                        && ($0.userData?["direction"] as? String) == encounter.target.rawValue
                }
        )
        XCTAssertNotNil(choice.childNode(withName: "decorativeMirrorPivotShaft"),
                        "The scored mirror must be physically connected to its floor pedestal.")
        scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
        scene.handleTap(at: choice.position)
        try await waitUntil {
            state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count == 1
        }
        let ray = try XCTUnwrap(scene.childNode(withName: "mirrorActiveRay") as? SKShapeNode)
        let impact = try XCTUnwrap(scene.childNode(withName: "mirrorActiveImpact"))
        XCTAssertEqual(ray.lineWidth, 8, accuracy: 0.001)
        XCTAssertEqual(ray.alpha, 1, accuracy: 0.001,
                       "Reduced Motion still needs an immediately visible physical reflection.")
        XCTAssertEqual(impact.position.x, choice.position.x, accuracy: 0.001)
        XCTAssertEqual(impact.position.y, 252, accuracy: 0.001,
                       "A correct reflection should reach its actual floor receiver.")
        try await capture(scene, in: view, name: "Puzzle-Palace-Mirror-Hall-Reflected-Receiver")

        let evidence = state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence
        XCTAssertEqual(evidence.count, 1)
        XCTAssertEqual(evidence.first?.encounterID, encounter.id)
        XCTAssertEqual(evidence.first?.outcome, .correct)
        XCTAssertEqual(evidence.first?.supportLevel, .independent)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).state, .new)
    }

    private func finishMirrorPracticeIfNeeded(_ scene: PuzzlePalaceScene) throws {
        if let dial = scene.childNode(withName: "mirrorPracticeDial") {
            scene.valkyrie.position = CGPoint(x: 580, y: 175)
            scene.handleTap(at: dial.position)
            let ready = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeContinue"))
            scene.handleTap(at: ready.position)
        }
    }

    func testMirrorApproachSurvivesStrayFloorAndRepeatedTaps() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        let dial = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeDial"))
        scene.handleTap(at: dial.position)
        scene.handleTap(at: CGPoint(x: 140, y: 145))
        try await Task.sleep(nanoseconds: 1_200_000_000)
        let ready = try XCTUnwrap(scene.childNode(withName: "mirrorPracticeContinue"))
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        scene.handleTap(at: ready.position)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let index = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
            $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == index
        })
        scene.handleTap(at: choice.position)
        scene.handleTap(at: CGPoint(x: 140, y: 145))
        scene.handleTap(at: choice.position)
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.first?.outcome, .correct)
        XCTAssertNotNil(scene.childNode(withName: "mirrorNext"))
    }

    func testMirrorPracticeIsUnscoredAndSuccessWaitsForChild() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        XCTAssertNotNil(scene.childNode(withName: "mirrorPracticeDial"))
        XCTAssertFalse(scene.children.contains { $0.name == "mirrorRotationChoice" })
        try finishMirrorPracticeIfNeeded(scene)
        XCTAssertTrue(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.isEmpty)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let index = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
            $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == index
        })
        scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
        scene.handleTap(at: choice.position)
        let next = try XCTUnwrap(scene.childNode(withName: "mirrorNext"))
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
        XCTAssertEqual(scene.childNode(withName: "mirrorBeam0")?.alpha, 1)
        try await Task.sleep(nanoseconds: 1_200_000_000)
        XCTAssertNotNil(scene.childNode(withName: "mirrorNext"))
        XCTAssertEqual(choice.parent, scene)
        scene.handleTap(at: next.position)
        XCTAssertNil(scene.childNode(withName: "mirrorNext"))
        XCTAssertNil(choice.parent)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 1)
    }

    func testMirrorRotationLiveChoicesKeepHintedEvidenceSeparate() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }
        try finishMirrorPracticeIfNeeded(scene)
        let encounter = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        let options = scene.children.compactMap { $0 as? SKShapeNode }
            .filter { $0.name == "mirrorRotationChoice" }
        XCTAssertEqual(options.count, 3)
        XCTAssertNotNil(scene.childNode(withName: "mirrorRotationSource"))
        let correctIndex = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
        let wrong = try XCTUnwrap(options.first { ($0.userData?["choiceIndex"] as? Int) != correctIndex })
        scene.valkyrie.position = CGPoint(x: wrong.position.x - 180, y: 175)
        scene.handleTap(at: wrong.position)
        try await waitUntil {
            state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count == 1
        }
        let missImpact = try XCTUnwrap(scene.childNode(withName: "mirrorActiveImpact"))
        XCTAssertEqual(missImpact.position.y, 306, accuracy: 0.001,
                       "A wrong turn must cast a missed beam, not light the receiver.")
        XCTAssertEqual(missImpact.alpha, 1, accuracy: 0.001)
        try await capture(scene, in: view, name: "Puzzle-Palace-Mirror-Hall-Missed-Reflection")
        scene.valkyrie.position = CGPoint(x: wrong.position.x - 180, y: 175)
        scene.handleTap(at: wrong.position)
        try await waitUntil {
            state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count == 2
        }
        let correct = try XCTUnwrap(options.first { ($0.userData?["choiceIndex"] as? Int) == correctIndex })
        scene.valkyrie.position = CGPoint(x: correct.position.x - 180, y: 175)
        scene.handleTap(at: correct.position)
        try await waitUntil {
            state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count == 3
        }
        let repairedImpact = try XCTUnwrap(scene.childNode(withName: "mirrorActiveImpact"))
        XCTAssertEqual(repairedImpact.position.y, 252, accuracy: 0.001)
        let evidence = state.profile.progress(for: PuzzleSkills.mentalRotation).evidence
        XCTAssertEqual(evidence.map(\.outcome), [.incorrect, .incorrect, .correct])
        XCTAssertEqual(evidence.map(\.supportLevel), [.independent, .lightHint, .demonstration])
        XCTAssertEqual(evidence.last?.attempts, 3)
        let retry = try XCTUnwrap(state.nextPuzzleMirrorRotationEncounter())
        XCTAssertNotEqual(retry.id, encounter.id)
        XCTAssertNotEqual(retry.answer, encounter.answer)
        XCTAssertNotEqual(retry.choices.firstIndex(of: retry.answer), correctIndex)
        XCTAssertEqual(PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: state.profile), 0)
        XCTAssertFalse(state.puzzleMirrorRotationComplete)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count, 3)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
    }

    func testMirrorRotationIndependentCompletionRestoresFromLocalSave() async throws {
        let context = ModelContext(try LearningStore.container(inMemory: true))
        let state = try AppState(context: context)
        state.reducedMotion = true
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        state.travel(to: .mirrorHall)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)
            try finishMirrorPracticeIfNeeded(scene)
            XCTAssertEqual(state.nextPuzzleMirrorRotationEncounter()?.id, encounter.id)
            let correctIndex = try XCTUnwrap(encounter.choices.firstIndex(of: encounter.answer))
            let choice = try XCTUnwrap(scene.children.compactMap { $0 as? SKShapeNode }.first {
                $0.name == "mirrorRotationChoice" && ($0.userData?["choiceIndex"] as? Int) == correctIndex
            })
            let evidenceCount = state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count
            scene.valkyrie.position = CGPoint(x: choice.position.x - 180, y: 175)
            scene.handleTap(at: choice.position)
            try await waitUntil {
                state.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count == evidenceCount + 1
            }
            scene.willLeave()
        }
        XCTAssertTrue(state.puzzleMirrorRotationComplete)
        let restored = try AppState(context: context)
        XCTAssertTrue(restored.puzzleMirrorRotationComplete)
        XCTAssertEqual(restored.profile.progress(for: PuzzleSkills.mentalRotation).evidence.count, 3)
        XCTAssertEqual(restored.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        restored.travel(to: .mirrorHall)
        let completeScene = PuzzlePalaceScene(state: restored)
        view.presentScene(completeScene)
        XCTAssertFalse(completeScene.children.contains { $0.name == "mirrorRotationChoice" })
        completeScene.willLeave()
    }

    func testRenderedNativeSceneReviewAttachments() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1280, height: 720))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view; window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        state.reducedMotion = true
        let home = StoryTreeScene(state: state); home.reducedMotion = true
        view.presentScene(home)
        try await capture(home, in: view, name: "Story-Tree-native")
        home.handleTap(at: CGPoint(x: 835, y: 535))
        // Exercise the painted waypoint route before the arrival capture.
        // Wait on the actual SpriteKit arrival condition instead of assuming
        // a fixed wall-clock duration on a loaded macOS CI runner.
        try await waitUntil(timeout: 8) {
            home.isNear(CGPoint(x: 795, y: 450))
        }
        try await capture(home, in: view, name: "Story-Tree-native-castle-arrival")
        home.willLeave()

        state.travel(to: .wordGarden)
        let garden = WordGardenScene(state: state)
        garden.reducedMotion = true
        view.presentScene(garden)
        try await capture(garden, in: view, name: "Word-Garden-native-flower-gate")
        // Review the playable choice state as well as the brief rune preview.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(garden.childNode(withName: "targetRune")?.isHidden == true)
        try await capture(garden, in: view, name: "Word-Garden-native-flower-choices")
        garden.willLeave()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        state.travel(to: .sunmillCrossing)
        let sunmill = WordGardenScene(state: state)
        sunmill.reducedMotion = true
        view.presentScene(sunmill)
        try await capture(sunmill, in: view, name: "Word-Garden-native-sunmill")
        sunmill.willLeave()

        for encounter in WordGardenEncounterCatalog.sunmillVisualShapes {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let awakeSunmill = WordGardenScene(state: state)
        awakeSunmill.reducedMotion = true
        view.presentScene(awakeSunmill)
        try await capture(awakeSunmill, in: view, name: "Word-Garden-native-sunmill-awake")
        XCTAssertFalse(awakeSunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true)
        XCTAssertNotNil(awakeSunmill.childNode(withName: "storyHollowRoute"))
        XCTAssertEqual(
            state.profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
        awakeSunmill.willLeave()

        state.travel(to: .storyHollow)
        let hollow = WordGardenScene(state: state)
        hollow.reducedMotion = true
        view.presentScene(hollow)
        try await capture(hollow, in: view, name: "Word-Garden-native-story-hollow")
        hollow.willLeave()

        for encounter in WordGardenEncounterCatalog.storyHollowSequence {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let restoredHollow = WordGardenScene(state: state)
        restoredHollow.reducedMotion = true
        view.presentScene(restoredHollow)
        try await capture(
            restoredHollow,
            in: view,
            name: "Word-Garden-native-story-hollow-restored"
        )
        XCTAssertNotNil(restoredHollow.childNode(withName: "storyBloom"))
        XCTAssertTrue(state.hasStoryReward(.wordGardenLantern))
        restoredHollow.willLeave()

        state.travel(to: .storyTree)
        let rewardTree = StoryTreeScene(state: state)
        rewardTree.reducedMotion = true
        view.presentScene(rewardTree)
        try await capture(
            rewardTree,
            in: view,
            name: "Story-Tree-native-word-garden-lantern"
        )
        XCTAssertNotNil(rewardTree.childNode(withName: "wordGardenLantern"))
        rewardTree.willLeave()

        state.travel(to: .scienceLab)
        let science = ScienceLabScene(state: state); science.reducedMotion = true
        view.presentScene(science)
        science.valkyrie.position = CGPoint(x: 565, y: 185)
        science.handleTap(at: CGPoint(x: 685, y: 235))
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-dry")
        science.valkyrie.position = CGPoint(x: 500, y: 180)
        science.handleTap(at: CGPoint(x: 430, y: 220))
        XCTAssertEqual(science.greenhouseStage, .watered)
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-sprout")
        science.valkyrie.position = CGPoint(x: 850, y: 185)
        science.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertFalse(science.greenhouseComplete)
        science.valkyrie.position = CGPoint(x: 565, y: 185)
        science.handleTap(at: CGPoint(x: 685, y: 235))
        science.valkyrie.position = CGPoint(x: 500, y: 180)
        science.handleTap(at: CGPoint(x: 430, y: 220))
        science.valkyrie.position = CGPoint(x: 850, y: 185)
        science.handleTap(at: CGPoint(x: 940, y: 245))
        XCTAssertTrue(science.greenhouseComplete)
        try await capture(science, in: view, name: "Science-Lab-native-greenhouse-complete")
        science.willLeave()

        let weather = WeatherTowerScene(state: state); weather.reducedMotion = true
        view.presentScene(weather)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-arrival")
        weather.valkyrie.position = CGPoint(x: 370, y: 180)
        weather.handleTap(at: CGPoint(x: 470, y: 305))
        weather.valkyrie.position = CGPoint(x: 605, y: 180)
        weather.handleTap(at: CGPoint(x: 700, y: 305))
        XCTAssertEqual(weather.weatherStage, .afternoonObserved)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-compared")
        weather.valkyrie.position = CGPoint(x: 825, y: 180)
        weather.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertFalse(weather.creatureRouteOpen)
        weather.valkyrie.position = CGPoint(x: 370, y: 180)
        weather.handleTap(at: CGPoint(x: 470, y: 305))
        weather.valkyrie.position = CGPoint(x: 825, y: 180)
        weather.handleTap(at: CGPoint(x: 985, y: 282))
        XCTAssertTrue(weather.creatureRouteOpen)
        try await capture(weather, in: view, name: "Science-Lab-native-weather-route-open")
        weather.willLeave()

        let grove = CreatureGroveScene(state: state); grove.reducedMotion = true
        view.presentScene(grove)
        XCTAssertLessThan(grove.childNode(withName: "scienceHabitatPond")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(grove.childNode(withName: "scienceWebbedFeet")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(grove.childNode(withName: "scienceCompareBoard")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(grove.childNode(withName: "scienceGroveFinale")?.alpha ?? 1, 0.01)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-arrival")
        grove.valkyrie.position = CGPoint(x: 245, y: 180)
        grove.handleTap(at: CGPoint(x: 335, y: 270))
        XCTAssertGreaterThan(grove.childNode(withName: "scienceHabitatPond")?.alpha ?? 0, 0.99)
        XCTAssertGreaterThan(grove.childNode(withName: "scienceHabitatRidge")?.alpha ?? 0, 0.99)
        grove.valkyrie.position = CGPoint(x: 610, y: 180)
        grove.handleTap(at: CGPoint(x: 528, y: 270))
        XCTAssertEqual(grove.groveStage, .habitatMatched)
        XCTAssertLessThan(grove.childNode(withName: "scienceHabitatPond")?.alpha ?? 1, 0.01)
        XCTAssertGreaterThan(grove.childNode(withName: "scienceWebbedFeet")?.alpha ?? 0, 0.99)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-habitat")
        grove.valkyrie.position = CGPoint(x: 750, y: 180)
        grove.handleTap(at: CGPoint(x: 840, y: 290))
        XCTAssertEqual(grove.groveStage, .bodyPartObserved)
        XCTAssertLessThan(grove.childNode(withName: "scienceWebbedFeet")?.alpha ?? 1, 0.01)
        XCTAssertGreaterThan(grove.childNode(withName: "scienceCompareBoard")?.alpha ?? 0, 0.99)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-body-part")
        grove.valkyrie.position = CGPoint(x: 920, y: 180)
        grove.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertFalse(grove.groveRestored)
        grove.valkyrie.position = CGPoint(x: 610, y: 180)
        grove.handleTap(at: CGPoint(x: 528, y: 270))
        grove.valkyrie.position = CGPoint(x: 750, y: 180)
        grove.handleTap(at: CGPoint(x: 840, y: 290))
        grove.valkyrie.position = CGPoint(x: 920, y: 180)
        grove.handleTap(at: CGPoint(x: 975, y: 285))
        XCTAssertTrue(grove.groveRestored)
        XCTAssertLessThan(grove.childNode(withName: "scienceCompareBoard")?.alpha ?? 1, 0.01)
        XCTAssertGreaterThan(grove.childNode(withName: "scienceGroveFinale")?.alpha ?? 0, 0.99)
        try await capture(grove, in: view, name: "Science-Lab-native-creature-grove-restored")
        grove.willLeave()

        state.travel(to: .puzzlePalace)
        let palace = PuzzlePalaceScene(state: state)
        palace.reducedMotion = true
        view.presentScene(palace)
        try await capture(palace, in: view, name: "Puzzle-Palace-native-rune-gate")
        XCTAssertNil(
            palace.childNode(withName: "puzzleCrystalFixture"),
            "Rune Gate must not carry decorative crystal clutter from deeper palace rooms."
        )
        XCTAssertNil(
            palace.childNode(withName: "puzzlePillar"),
            "Rune Gate must not show the old synthetic pillar scaffolding."
        )
        XCTAssertNil(
            palace.childNode(withName: "puzzleStageDais"),
            "Rune Gate must keep the floor clear instead of layering another giant platform."
        )
        XCTAssertNotNil(palace.childNode(withName: "puzzleGate"))
        XCTAssertEqual(
            palace.valkyrie.xScale,
            0.56,
            accuracy: 0.001,
            "Rune Gate polish must not alter Valkyrie's native presentation."
        )
        palace.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let openPalace = PuzzlePalaceScene(state: state)
        openPalace.reducedMotion = true
        view.presentScene(openPalace)
        try await capture(
            openPalace,
            in: view,
            name: "Puzzle-Palace-native-rune-gate-open"
        )
        XCTAssertTrue(state.puzzleRuneGateComplete)
        XCTAssertEqual(openPalace.children.filter { $0.name == "runeChoice" }.count, 0)
        XCTAssertNotNil(openPalace.childNode(withName: "memoryBridgeRoute"))
        openPalace.willLeave()

        state.travel(to: .memoryBridge)
        let memoryBridge = PuzzlePalaceScene(state: state)
        memoryBridge.reducedMotion = true
        view.presentScene(memoryBridge)
        try await capture(
            memoryBridge,
            in: view,
            name: "Puzzle-Palace-native-memory-bridge"
        )
        XCTAssertNotNil(memoryBridge.childNode(withName: "memoryChasm"))
        XCTAssertEqual(memoryBridge.children.filter { $0.name == "memoryPad" }.count, 4)
        memoryBridge.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let restoredMemoryBridge = PuzzlePalaceScene(state: state)
        restoredMemoryBridge.reducedMotion = true
        view.presentScene(restoredMemoryBridge)
        try await capture(
            restoredMemoryBridge,
            in: view,
            name: "Puzzle-Palace-native-memory-bridge-restored"
        )
        XCTAssertTrue(state.puzzleMemoryBridgeComplete)
        XCTAssertNotNil(restoredMemoryBridge.childNode(withName: "memoryBridgeRestored"))
        XCTAssertNotNil(restoredMemoryBridge.childNode(withName: "stopGoRoute"))
        restoredMemoryBridge.willLeave()

        state.travel(to: .stopGoOrbs)
        let stopGo = PuzzlePalaceScene(state: state)
        stopGo.reducedMotion = true
        view.presentScene(stopGo)
        try await capture(
            stopGo,
            in: view,
            name: "Puzzle-Palace-native-stop-go-orbs"
        )
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoOrb"))
        XCTAssertNotNil(stopGo.childNode(withName: "//stopGoOrbHalo"))
        XCTAssertNotNil(stopGo.childNode(withName: "stopGoBarrier"))
        XCTAssertNil(stopGo.childNode(withName: "stopGoLegend"),
                     "The physical shutter replaces tiny redundant floor instructions.")
        XCTAssertNotNil(stopGo.childNode(withName: "//decorativeStopGoShutter"),
                        "The mounted signal must have a visible HOLD/GO shutter.")
        XCTAssertEqual(
            stopGo.children.filter { $0.name == "stopGoBrace" }.count,
            3,
            "Stop/Go chamber should keep the signal focus clear instead of filling the room with braces."
        )
        stopGo.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let stableStopGo = PuzzlePalaceScene(state: state)
        stableStopGo.reducedMotion = true
        view.presentScene(stableStopGo)
        try await capture(
            stableStopGo,
            in: view,
            name: "Puzzle-Palace-native-stop-go-orbs-stable"
        )
        XCTAssertTrue(state.puzzleStopGoComplete)
        XCTAssertNotNil(stableStopGo.childNode(withName: "stopGoBarrierOpen"))
        XCTAssertNotNil(stableStopGo.childNode(withName: "sortingPedestalRoute"))
        stableStopGo.willLeave()

        state.travel(to: .sortingPedestal)
        let sorting = PuzzlePalaceScene(state: state)
        sorting.reducedMotion = true
        view.presentScene(sorting)
        try await capture(
            sorting,
            in: view,
            name: "Puzzle-Palace-native-sorting-pedestal"
        )
        XCTAssertNotNil(sorting.childNode(withName: "sortingRuleDial"))
        XCTAssertEqual(
            state.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.singleRuleSort
        )
        sorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let switching = PuzzlePalaceScene(state: state)
        switching.reducedMotion = true
        view.presentScene(switching)
        try await capture(
            switching,
            in: view,
            name: "Puzzle-Palace-native-sorting-rule-switch"
        )
        XCTAssertTrue(state.puzzleSortingFoundationComplete)
        XCTAssertEqual(
            state.nextPuzzleSortingEncounter()?.skillID,
            PuzzleSkills.ruleSwitching
        )
        switching.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        let stableSorting = PuzzlePalaceScene(state: state)
        stableSorting.reducedMotion = true
        view.presentScene(stableSorting)
        try await capture(
            stableSorting,
            in: view,
            name: "Puzzle-Palace-native-sorting-pedestal-stable"
        )
        XCTAssertTrue(state.puzzleSortingPedestalComplete)
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .new
        )
        stableSorting.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }

        state.travel(to: .mirrorHall)
        let mirrorHall = PuzzlePalaceScene(state: state)
        mirrorHall.reducedMotion = true
        view.presentScene(mirrorHall)
        try await capture(
            mirrorHall,
            in: view,
            name: "Puzzle-Palace-native-mirror-hall"
        )
        XCTAssertTrue(state.puzzleMirrorHallAvailable)
        XCTAssertNil(mirrorHall.childNode(withName: "mirrorHallChamber"),
                     "Mirror Hall should reveal the palace artwork instead of covering it with a modal panel.")
        XCTAssertNotNil(mirrorHall.childNode(withName: "mirrorHallRail"))
        XCTAssertNotNil(mirrorHall.childNode(withName: "mirrorBeacon"))
        XCTAssertNotNil(mirrorHall.childNode(withName: "mirrorHallTitlePlate"))
        XCTAssertNotNil(mirrorHall.childNode(withName: "decorativeMirrorHallConceptAccents"))
        XCTAssertNotNil(mirrorHall.childNode(withName: "//decorativeMirrorHallFloorCompass"))
        let mirrorBackdropArch = try XCTUnwrap(
            mirrorHall.childNode(withName: "//decorativeMirrorHallBackdropArch0") as? SKShapeNode
        )
        XCTAssertLessThanOrEqual(
            mirrorBackdropArch.lineWidth,
            3,
            "Decorative Mirror Hall architecture must stay quieter than scored mirrors."
        )
        let orientationChoices = mirrorHall.children.filter { $0.name == "mirrorOrientationChoice" }
        XCTAssertEqual(orientationChoices.count, 3)
        let mirrorPools = mirrorHall.children.filter {
            $0.name?.hasPrefix("mirrorChoicePool") == true
        }
        XCTAssertEqual(mirrorPools.count, 3)
        let actorFrame = mirrorHall.valkyrie.calculateAccumulatedFrame().insetBy(dx: 8, dy: 8)
        for choice in orientationChoices {
            XCTAssertFalse(
                actorFrame.intersects(choice.calculateAccumulatedFrame()),
                "Valkyrie must never obscure a scored mirror choice."
            )
            XCTAssertNotNil(
                choice.childNode(withName: "//decorativeMirrorStationCrystal"),
                "Each scored mirror should read as a physical portal station."
            )
            XCTAssertEqual(
                mirrorHall.targetName(at: choice.position),
                "mirrorOrientationChoice",
                "Decorative portal art must never steal the mirror tap."
            )
        }
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.mentalRotation).state,
            .new
        )
        mirrorHall.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        let rotationHall = PuzzlePalaceScene(state: state)
        rotationHall.reducedMotion = true
        view.presentScene(rotationHall)
        try await capture(rotationHall, in: view, name: "Puzzle-Palace-native-turn-practice")
        try finishMirrorPracticeIfNeeded(rotationHall)
        try await capture(rotationHall, in: view, name: "Puzzle-Palace-native-mental-rotation")
        let rotationChoices = rotationHall.children.filter { $0.name == "mirrorRotationChoice" }
        XCTAssertEqual(rotationChoices.count, 3)
        let rotationActorFrame = rotationHall.valkyrie.calculateAccumulatedFrame().insetBy(dx: 8, dy: 8)
        for choice in rotationChoices {
            XCTAssertFalse(
                rotationActorFrame.intersects(choice.calculateAccumulatedFrame()),
                "Mental rotation answers must remain visually unobstructed."
            )
        }
        XCTAssertNil(rotationHall.childNode(withName: "rotationQuarterMark0"),
                     "The independent task should use one turn cue, not redundant quarter-dot UI.")
        rotationHall.willLeave()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            _ = state.recordPuzzle(encounter, outcome: .correct, support: .independent,
                                   attempts: 1, responseTime: 1)
        }
        XCTAssertTrue(state.puzzlePathTilesAvailable)
        state.travel(to: .pathTiles)
        let pathTiles = PuzzlePalaceScene(state: state)
        pathTiles.reducedMotion = true
        view.presentScene(pathTiles)
        try await capture(pathTiles, in: view, name: "Puzzle-Palace-native-path-tiles")
        let pathChamber = try XCTUnwrap(pathTiles.childNode(withName: "pathTilesChamber"))
        XCTAssertLessThan(
            pathChamber.calculateAccumulatedFrame().width,
            500,
            "Path Tiles should be a compact floor dais, not a full-screen modal frame."
        )
        XCTAssertNotNil(pathTiles.childNode(withName: "pathGrid"))
        let pathChoices = pathTiles.children.filter { $0.name?.hasPrefix("pathChoice") == true }
        XCTAssertEqual(pathChoices.count, 3)
        for choice in pathChoices {
            let frame = choice.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 280)
            XCTAssertGreaterThanOrEqual(frame.height, 60)
            XCTAssertTrue(choice.isAccessibilityElement)
            XCTAssertTrue((choice.accessibilityLabel ?? "").hasPrefix("Route option"))
        }
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        pathTiles.willLeave()

        XCTAssertFalse(state.puzzleCommandGearsAvailable)
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            _ = state.recordPuzzle(
                family[0],
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleCommandGearsAvailable)
        state.travel(to: .commandGears)
        let commandGears = PuzzlePalaceScene(state: state)
        commandGears.reducedMotion = true
        view.presentScene(commandGears)
        try await capture(commandGears, in: view, name: "Puzzle-Palace-native-command-gears")
        XCTAssertNotNil(commandGears.childNode(withName: "commandRail"))
        XCTAssertEqual(
            commandGears.children.filter { $0.name?.hasPrefix("commandSource") == true
                && !($0.name?.contains("Label") ?? false) }.count,
            3
        )
        for index in 0..<3 {
            let socket = try XCTUnwrap(commandGears.childNode(withName: "commandSocket\(index)"))
            XCTAssertGreaterThanOrEqual(socket.calculateAccumulatedFrame().width, 80)
            XCTAssertGreaterThanOrEqual(socket.calculateAccumulatedFrame().height, 80)
        }
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertNotEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)

        let commandEncounter = try XCTUnwrap(state.nextPuzzleCommandGearsEncounter())
        for step in commandEncounter.correctOrder {
            let index = try XCTUnwrap(commandEncounter.presented.firstIndex(of: step))
            let source = try XCTUnwrap(commandGears.childNode(withName: "commandSource\(index)"))
            commandGears.handleTap(at: source.position)
        }
        let runGear = try XCTUnwrap(commandGears.childNode(withName: "commandRun"))
        commandGears.handleTap(at: runGear.position)
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.actionSequencing).evidence.last?.outcome,
            .correct
        )
        XCTAssertNotEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSequence).state, .new)
        commandGears.willLeave()

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            _ = state.recordPuzzle(
                family[0],
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleBugLanternAvailable)
        state.travel(to: .bugLantern)
        let bugLantern = PuzzlePalaceScene(state: state)
        bugLantern.reducedMotion = true
        view.presentScene(bugLantern)
        try await capture(bugLantern, in: view, name: "Puzzle-Palace-native-bug-lantern")
        XCTAssertNotNil(bugLantern.childNode(withName: "bugLanternFixture"))
        XCTAssertNotNil(bugLantern.childNode(withName: "bugRail"))
        let bugSockets = bugLantern.children.filter {
            $0.name?.hasPrefix("bugStepSocket") == true
        }
        XCTAssertEqual(bugSockets.count, 3)
        let bugFlowArrows = bugLantern.children.filter {
            $0.name?.hasPrefix("bugFlowArrow") == true
        }
        XCTAssertEqual(bugFlowArrows.count, 2)
        let bugSteps = bugLantern.children.filter { $0.name?.hasPrefix("bugStep") == true
            && !($0.name?.contains("Label") ?? false)
            && !($0.name?.contains("Socket") ?? false) }
        XCTAssertEqual(bugSteps.count, 3)
        for step in bugSteps {
            XCTAssertGreaterThanOrEqual(step.calculateAccumulatedFrame().width, 150)
            XCTAssertGreaterThanOrEqual(step.calculateAccumulatedFrame().height, 100)
            XCTAssertTrue(step.isAccessibilityElement)
        }
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSequence).state, .new)

        let bugEncounter = try XCTUnwrap(state.nextPuzzleBugLanternEncounter())
        let brokenNode = try XCTUnwrap(
            bugLantern.childNode(withName: "bugStep\(bugEncounter.brokenIndex)")
        )
        let debugEvidenceBeforeRepair = state.profile.progress(for: PuzzleSkills.debugSingleStep).evidence.count
        bugLantern.handleTap(at: brokenNode.position)
        XCTAssertEqual(brokenNode.position.y, 341, accuracy: 0.001,
                       "Confirmed broken cassette must physically sink in its socket.")
        let inspectedSocket = try XCTUnwrap(
            bugLantern.childNode(withName: "bugStepSocket\(bugEncounter.brokenIndex)") as? SKShapeNode
        )
        // UIColor instances may compare unequal even when their extended-sRGB
        // components match. Compare actual rendered channel values instead.
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        XCTAssertTrue(inspectedSocket.strokeColor.getRed(
            &red, green: &green, blue: &blue, alpha: &alpha
        ))
        XCTAssertEqual(red, 0.95, accuracy: 0.002)
        XCTAssertEqual(green, 0.75, accuracy: 0.002)
        XCTAssertEqual(blue, 0.44, accuracy: 0.002)
        XCTAssertEqual(alpha, 1, accuracy: 0.002)
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.debugSingleStep).evidence.count,
            debugEvidenceBeforeRepair,
            "Identifying the broken step alone must not count as completed debugging evidence."
        )
        let replacement = try XCTUnwrap(bugLantern.childNode(withName: "bugReplacement"))
        XCTAssertEqual(bugLantern.tiko.position.x, brokenNode.position.x, accuracy: 0.001)
        XCTAssertEqual(bugLantern.tiko.position.y, 205, accuracy: 0.001)
        XCTAssertFalse(
            replacement.calculateAccumulatedFrame().intersects(
                bugLantern.tiko.calculateAccumulatedFrame()
            ),
            "Tiko's failure demonstration must stay visually separate from the replacement command."
        )
        XCTAssertEqual(
            replacement.accessibilityLabel,
            "Replacement command: \(bugEncounter.intended[bugEncounter.brokenIndex].title). Install it in step \(bugEncounter.brokenIndex + 1)."
        )
        bugLantern.handleTap(at: replacement.position)
        XCTAssertEqual(replacement.position.y, 355, accuracy: 0.001,
                       "Repaired cassette must seat flush with the drive rail.")
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.debugSingleStep).evidence.last?.outcome,
            .correct
        )
        XCTAssertNotEqual(state.profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSequence).state, .new)
        bugLantern.willLeave()

        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            _ = state.recordPuzzle(
                family[0],
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            _ = state.recordPuzzle(
                family[0],
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleBugRepairAvailable)
        state.travel(to: .bugLanternRepair)
        let repairLab = PuzzlePalaceScene(state: state)
        repairLab.reducedMotion = true
        view.presentScene(repairLab)
        try await capture(repairLab, in: view, name: "Puzzle-Palace-native-bug-repair")
        XCTAssertNotNil(repairLab.childNode(withName: "repairLanternFixture"))
        XCTAssertNotNil(repairLab.childNode(withName: "repairRail"))
        XCTAssertNotNil(repairLab.childNode(withName: "repairDriveShaft"),
                        "The clockwork engine must be visibly connected to the gear rail.")
        XCTAssertNotNil(repairLab.childNode(withName: "//repairMachineRotor"))
        let testLever = try XCTUnwrap(repairLab.childNode(withName: "repairFix"))
        XCTAssertTrue(testLever.isAccessibilityElement)
        XCTAssertGreaterThanOrEqual(testLever.calculateAccumulatedFrame().width, 80)
        for index in 0..<4 {
            let housing = try XCTUnwrap(repairLab.childNode(withName: "repairSocketBase\(index)"))
            XCTAssertGreaterThanOrEqual(housing.calculateAccumulatedFrame().width, 120,
                                        "Smaller socket housings still provide a generous iPad target.")
        }
        let repairSteps = repairLab.children.filter {
            $0.name?.hasPrefix("repairStep") == true
                && !($0.name?.contains("Label") ?? false)
        }
        XCTAssertEqual(repairSteps.count, 4)
        for step in repairSteps {
            XCTAssertGreaterThanOrEqual(step.calculateAccumulatedFrame().width, 110)
            XCTAssertGreaterThanOrEqual(step.calculateAccumulatedFrame().height, 110,
                                        "The 4:3 iPad gear must remain larger than a 60-point tap target.")
            XCTAssertTrue(step.isAccessibilityElement)
        }
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSequence).state, .new)

        let repairEncounter = try XCTUnwrap(state.nextPuzzleBugRepairEncounter())
        let firstRepairIndex = repairEncounter.swapIndices[0]
        let secondRepairIndex = repairEncounter.swapIndices[1]
        let firstRepairStep = try XCTUnwrap(
            repairLab.childNode(withName: "repairStep\(firstRepairIndex)")
        )
        let secondRepairStep = try XCTUnwrap(
            repairLab.childNode(withName: "repairStep\(secondRepairIndex)")
        )
        let firstRepairLabel = try XCTUnwrap(
            repairLab.childNode(withName: "repairStepLabel\(firstRepairIndex)")
        )
        let secondRepairLabel = try XCTUnwrap(
            repairLab.childNode(withName: "repairStepLabel\(secondRepairIndex)")
        )
        let firstStepX = firstRepairStep.position.x
        let secondStepX = secondRepairStep.position.x
        let firstLabelX = firstRepairLabel.position.x
        let secondLabelX = secondRepairLabel.position.x

        for index in repairEncounter.swapIndices {
            let step = try XCTUnwrap(repairLab.childNode(withName: "repairStep\(index)"))
            repairLab.handleTap(at: step.position)
            XCTAssertEqual(step.position.y, 373, accuracy: 0.001,
                           "Selected repair gears must lift physically from their sockets.")
            XCTAssertEqual(step.xScale, 1, accuracy: 0.001,
                           "Selection must not simply enlarge a flat answer icon.")
        }
        let fixGear = try XCTUnwrap(repairLab.childNode(withName: "repairFix"))
        repairLab.handleTap(at: fixGear.position)
        XCTAssertEqual(
            state.profile.progress(for: PuzzleSkills.debugSequence).evidence.last?.outcome,
            .correct
        )
        let poweredCore = try XCTUnwrap(
            repairLab.childNode(withName: "//repairLanternCore") as? SKShapeNode
        )
        XCTAssertGreaterThan(
            poweredCore.fillColor.cgColor.components?.first ?? 0, 0.3,
            "A repaired machine should physically power up, not merely show a checkmark."
        )
        XCTAssertEqual(firstRepairStep.position.x, secondStepX, accuracy: 0.001)
        XCTAssertEqual(secondRepairStep.position.x, firstStepX, accuracy: 0.001)
        XCTAssertEqual(firstRepairLabel.position.x, secondLabelX, accuracy: 0.001)
        XCTAssertEqual(secondRepairLabel.position.x, firstLabelX, accuracy: 0.001)
        repairLab.willLeave()

        for family in PuzzlePalaceEncounterCatalog.bugRepairFamilies {
            _ = state.recordPuzzle(
                family[0],
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        XCTAssertTrue(state.puzzleBugRepairComplete)
        state.travel(to: .bugLanternRepair)
        let restoredRepairLab = PuzzlePalaceScene(state: state)
        restoredRepairLab.reducedMotion = true
        view.presentScene(restoredRepairLab)
        XCTAssertNil(restoredRepairLab.childNode(withName: "repairFix"))
        XCTAssertNil(restoredRepairLab.childNode(withName: "repairReset"))
        XCTAssertNotNil(restoredRepairLab.childNode(withName: "repairHome"))
        XCTAssertNotNil(restoredRepairLab.childNode(withName: "//repairMachineRotor"))
        for index in 0..<4 {
            XCTAssertNotNil(
                restoredRepairLab.childNode(withName: "//repairCompletedGear\(index)"),
                "Each machine socket must be visibly repaired after restoring saved progress."
            )
        }
        try await capture(restoredRepairLab, in: view, name: "Puzzle-Palace-native-repair-clockwork-powered")
        restoredRepairLab.willLeave()

        state.travel(to: .mathCastle)
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let castle = MathCastleScene(state: state); castle.reducedMotion = true
        view.presentScene(castle)
        castle.valkyrie.position = CGPoint(x: 490, y: 175); castle.pip.position = CGPoint(x: 385, y: 187)
        castle.handleTap(at: CGPoint(x: 830, y: 265))
        try await capture(castle, in: view, name: "Math-Castle-native-cart")
        for _ in 0..<(state.runtime?.encounter.targetQuantity ?? 0) { castle.handleTap(at: CGPoint(x: 595, y: 235)) }
        castle.handleTap(at: CGPoint(x: 1120, y: 250))
        let reducedBridge = try XCTUnwrap(castle.childNode(withName: "physicalRouteBridge"))
        XCTAssertEqual(reducedBridge.xScale, 1, accuracy: 0.001)
        XCTAssertNil(reducedBridge.action(forKey: "routeOpen"))
        let reducedBeacon = try XCTUnwrap(castle.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertEqual(reducedBeacon.glowWidth, 18)
        try await capture(castle, in: view, name: "Math-Castle-native-powered")
        let cartOrder = state.runtime?.encounter.id
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(castle.crossingBridge)
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await waitForBridgeTravel(castle)
        XCTAssertTrue(castle.isNear(CGPoint(x: 1110, y: 400), radius: 55))
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await capture(castle, in: view, name: "Math-Castle-native-cart-route-landing")
        castle.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(castle.crossingBridge)
        XCTAssertEqual(state.runtime?.encounter.id, cartOrder)
        try await waitForBridgeTravel(castle)
        XCTAssertTrue(castle.isNear(CGPoint(x: 490, y: 175)))
        XCTAssertNotEqual(state.runtime?.encounter.id, cartOrder)
        castle.willLeave()
        let bridgeState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        bridgeState.reducedMotion = true
        XCTAssertTrue(bridgeState.startWorkshop(MathCastleEncounterCatalog.missingNumberBridge[0]))
        let bridge = MathCastleScene(state: bridgeState); bridge.reducedMotion = true
        view.presentScene(bridge)
        bridge.valkyrie.position = CGPoint(x: 490, y: 175)
        bridge.handleTap(at: CGPoint(x: 965, y: 330))
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-gaps")
        for _ in 0..<4 { bridge.drop(origin: "missingSupply", at: CGPoint(x: 884, y: 220)) }
        bridge.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(bridgeState.runtime?.completed == true)
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-repaired")
        let repairedID = bridgeState.runtime?.encounter.id
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        bridge.handleTap(at: CGPoint(x: 1200, y: 430)) // Ignore repeated taps in transit.
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID)
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 1110, y: 400), radius: 55))
        XCTAssertGreaterThan(bridge.pip.position.x, 1000)
        XCTAssertGreaterThan(bridge.pip.position.y, 240)
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID, "Arrival must preserve the solved bridge")
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-landing")
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        XCTAssertEqual(bridgeState.runtime?.encounter.id, repairedID, "Keep the deck beneath the actors during the return")
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 490, y: 175)))
        XCTAssertNotEqual(bridgeState.runtime?.encounter.id, repairedID)
        bridge.willLeave()
        for (index, name) in [(0, "Math-Castle-native-scale-unequal"), (2, "Math-Castle-native-scale-equal-selected")] {
            // Visual fixtures use fresh sessions so engagement breaks in the preceding
            // bridge journey cannot refuse the requested scale encounter.
            let scaleState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            scaleState.reducedMotion = true
            XCTAssertTrue(scaleState.startWorkshop(MathCastleEncounterCatalog.balanceScale[index]))
            let scale = MathCastleScene(state: scaleState); scale.reducedMotion = true
            view.presentScene(scale)
            scale.valkyrie.position = CGPoint(x: 490, y: 175); scale.pip.position = CGPoint(x: 385, y: 187)
            scale.handleTap(at: CGPoint(x: 820, y: 350))
            if index == 2 { scale.handleTap(at: CGPoint(x: 820, y: 195)) }
            guard case .balanceScale(let model)? = scaleState.runtime else {
                XCTFail("Scale capture must render the requested mechanic"); continue
            }
            XCTAssertEqual(model.selected, index == 2 ? .equal : nil)
            XCTAssertNotNil(scale.childNode(withName: "//scaleBase"))
            XCTAssertNotNil(scale.childNode(withName: "//scaleBeam"))
            try await capture(scale, in: view, name: name)
            scale.willLeave()
        }
        let tenFrameState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        tenFrameState.reducedMotion = true
        XCTAssertTrue(tenFrameState.startWorkshop(MathCastleEncounterCatalog.tenFrameGate[0]))
        let tenFrame = MathCastleScene(state: tenFrameState)
        tenFrame.reducedMotion = true
        view.presentScene(tenFrame)
        tenFrame.valkyrie.position = CGPoint(x: 490, y: 175)
        tenFrame.pip.position = CGPoint(x: 385, y: 187)
        tenFrame.handleTap(at: CGPoint(x: 820, y: 344))
        try await capture(tenFrame, in: view, name: "Math-Castle-native-ten-frame")
        tenFrame.willLeave()

        for (capacity, name) in [(false, "Math-Castle-native-bond"), (true, "Math-Castle-native-bond-capacity")] {
            let bondState = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
            bondState.reducedMotion = true
            let encounter = capacity ? LearningEncounter(id: "bond-visual-capacity", skillID: MathSkills.bonds10,
                mechanicID: MathMechanicID.numberBondMachine, operation: .numberBond,
                initialQuantity: 19, targetQuantity: 20, prompt: "Inspect the crystal chambers")
                : MathCastleEncounterCatalog.numberBondMachine[0]
            XCTAssertTrue(bondState.startWorkshop(encounter))
            let bond = MathCastleScene(state: bondState); bond.reducedMotion = true
            view.presentScene(bond)
            bond.valkyrie.position = CGPoint(x: 490, y: 175); bond.pip.position = CGPoint(x: 385, y: 187)
            bond.handleTap(at: CGPoint(x: 820, y: 392))
            if !capacity { try await capture(bond, in: view, name: name + "-empty") }
            for _ in 0..<(capacity ? 20 : encounter.targetQuantity - encounter.initialQuantity) {
                bond.drop(origin: "bondSupply", at: CGPoint(x: 925, y: 280))
            }
            guard case .numberBond(let model)? = bondState.runtime else {
                XCTFail("Bond capture must render the requested mechanic"); continue
            }
            XCTAssertEqual(model.selectedPart, capacity ? 20 : model.correctMissingPart)
            try await capture(bond, in: view, name: name + "-filled")
            bond.willLeave()
        }
    }

    private func waitForBridgeTravel(_ scene: MathCastleScene) async throws {
        let deadline = Date().addingTimeInterval(10)
        while scene.crossingBridge && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(scene.crossingBridge, "Bridge route did not finish within ten seconds")
    }


    // These actions operate the real SpriteKit nodes, not mocked-up states.
    // The visible 4:3 review set must show the mistake and its repair, in
    // addition to a playable initial room and a fresh restored scene.
    private func exercisePalaceVisualReview(
        _ world: AppState.World,
        scene: PuzzlePalaceScene,
        state: AppState,
        correct: Bool,
        frozenEncounter: Any
    ) async throws {
        let skill: SkillID
        switch world {
        case .puzzlePalace:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleEncounter)
            skill = active.skillID
            let choice = try XCTUnwrap(scene.children.first {
                $0.name == "runeChoice"
                && (($0.userData?["choice"] as? String) == active.answer) == correct
            })
            scene.valkyrie.position = CGPoint(x: max(170, choice.position.x - 92), y: 175)
            scene.handleTap(at: choice.position)

        case .memoryBridge:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleMemoryEncounter)
            skill = active.skillID
            try await waitUntil(timeout: 8) {
                scene.instruction.text == "Now repeat Tiko's rune order to raise the bridge."
            }
            let symbols = correct ? active.sequence : [
                try XCTUnwrap(active.choices.first { $0 != active.sequence[0] })
            ]
            for symbol in symbols {
                let pad = try XCTUnwrap(scene.children.first {
                    $0.name == "memoryPad"
                    && ($0.userData?["symbol"] as? String) == symbol
                })
                scene.valkyrie.position = CGPoint(x: max(165, pad.position.x - 80), y: 175)
                scene.handleTap(at: pad.position)
                try await Task.sleep(nanoseconds: 500_000_000)
            }

        case .stopGoOrbs:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleInhibitionEncounter)
            skill = active.skillID
            let glyph = try XCTUnwrap(
                scene.childNode(withName: "//stopGoOrbGlyph") as? SKLabelNode
            )
            if correct {
                for _ in active.signals.filter({ $0 == .go }) {
                    try await waitUntil(timeout: 8) {
                        glyph.text == "✦"
                            && (scene.instruction.text ?? "").hasPrefix("GO")
                    }
                    scene.handleTap(at: CGPoint(x: 755, y: 365))
                    try await Task.sleep(nanoseconds: 350_000_000)
                }
            } else {
                // The initial screenshot consumes much of the short HOLD
                // window. Do not sleep before tapping; demand a LIVE HOLD
                // instruction, not an old pause glyph during transition.
                try await waitUntil(timeout: 2) {
                    glyph.text == "Ⅱ"
                        && (scene.instruction.text ?? "").hasPrefix("HOLD")
                }
                scene.handleTap(at: CGPoint(x: 755, y: 365))
                // Keep the failed HOLD and closed barrier frozen until the incorrect frame is captured.
            }

        case .sortingPedestal:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleSortEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 650_000_000) }
            else { try await Task.sleep(nanoseconds: 220_000_000) }
            for index in (correct ? Array(active.objects.indices) : [0]) {
                let rightBucket = active.objects[index].bucket(for: active.rules[index])
                let bucket: PuzzleSortBucket = correct
                    ? rightBucket : (rightBucket == .left ? .right : .left)
                scene.handleTap(at: CGPoint(x: bucket == .left ? 530 : 970, y: 355))
                if correct { try await Task.sleep(nanoseconds: 660_000_000) }
            }

        case .resortVault:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleResortEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 650_000_000) }
            let rules = correct ? [active.initialRule, active.changedRule] : [active.initialRule]
            for rule in rules {
                for index in (correct ? Array(active.objects.indices) : [0]) {
                    let rightBucket = active.objects[index].bucket(for: rule)
                    let bucket: PuzzleSortBucket = correct
                        ? rightBucket : (rightBucket == .left ? .right : .left)
                    scene.handleTap(at: CGPoint(x: bucket == .left ? 475 : 1035, y: 300))
                    if correct { try await Task.sleep(nanoseconds: 660_000_000) }
                }
                if correct { try await Task.sleep(nanoseconds: 240_000_000) }
            }

        case .mirrorHall:
            let active = try XCTUnwrap(frozenEncounter as? PuzzleOrientationEncounter)
            skill = active.skillID
            let index = try XCTUnwrap(active.choices.indices.first {
                (active.choices[$0] == active.target) == correct
            })
            let mirror = try XCTUnwrap(
                scene.children.filter { $0.name == "mirrorOrientationChoice" }
                    .first { ($0.userData?["direction"] as? String) ==
                        active.choices[index].rawValue }
            )
            scene.valkyrie.position = CGPoint(x: mirror.position.x - 235, y: 175)
            scene.handleTap(at: mirror.position)

        case .pathTiles:
            let active = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzlePathEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 700_000_000) }
            let index = try XCTUnwrap(active.choices.indices.first {
                active.isValidChoice($0) == correct
            })
            let yValues: [CGFloat] = [325, 245, 165]
            scene.handleTap(at: CGPoint(x: 1100, y: yValues[index]))

        case .commandGears:
            let active = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleSequenceEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 650_000_000) }
            let right = active.correctOrder
            let plan = correct ? right : [right[1], right[0], right[2]]
            let xs: [CGFloat] = [560, 760, 960]
            for step in plan {
                let index = try XCTUnwrap(active.presented.firstIndex(of: step))
                scene.handleTap(at: CGPoint(x: xs[index], y: 445))
            }
            scene.handleTap(at: CGPoint(x: 1100, y: 295))

        case .bugLantern:
            let active = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleBugEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 650_000_000) }
            let index = correct ? active.brokenIndex : (active.brokenIndex + 1) % active.shown.count
            let broken = try XCTUnwrap(scene.childNode(withName: "bugStep\(index)"))
            scene.handleTap(at: broken.position)
            if correct {
                try await waitUntil(timeout: 8) {
                    scene.childNode(withName: "bugReplacement") != nil
                }
                let replacement = try XCTUnwrap(scene.childNode(withName: "bugReplacement"))
                scene.handleTap(at: replacement.position)
            }

        case .bugLanternRepair:
            let active = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleRepairEncounter)
            skill = active.skillID
            if correct { try await Task.sleep(nanoseconds: 650_000_000) }
            let indexes: [Int]
            if correct {
                indexes = active.swapIndices
            } else {
                indexes = active.isCorrectSwap([0, 1]) ? [0, 2] : [0, 1]
            }
            for index in indexes {
                let step = try XCTUnwrap(scene.childNode(withName: "repairStep\(index)"))
                scene.handleTap(at: step.position)
            }
            let lever = try XCTUnwrap(scene.childNode(withName: "repairFix"))
            scene.handleTap(at: lever.position)

        default:
            XCTFail("Not a Puzzle Palace review room")
            return
        }
        let result: Outcome = correct ? .correct : .incorrect
        print("Palace four-state live review: \(world) expecting \(result)")
        try await waitUntil(timeout: 10) {
            state.profile.progress(for: skill).evidence.last?.outcome == result
        }
        // Correct Rune/Stop-Go mechanics immediately update their physical state,
        // but their next-challenge timers can replace the result during screenshot export.
        if correct && (world == .puzzlePalace || world == .stopGoOrbs) {
            scene.speed = 0
        }
    }

    func testRepairLabWrongSwapPhysicallyStallsAndRetryRemainsAssisted() async throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.reducedMotion = true
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            _ = state.recordPuzzle(family[0], outcome: .correct,
                                   support: .independent, attempts: 1, responseTime: 1)
        }
        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            _ = state.recordPuzzle(family[0], outcome: .correct,
                                   support: .independent, attempts: 1, responseTime: 1)
        }
        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            _ = state.recordPuzzle(family[0], outcome: .correct,
                                   support: .independent, attempts: 1, responseTime: 1)
        }
        XCTAssertTrue(state.puzzleBugRepairAvailable)
        state.travel(to: .bugLanternRepair)

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer { scene.willLeave(); view.presentScene(nil); window.isHidden = true }

        let encounter = try XCTUnwrap(
            scene.nativeReviewActiveEncounter as? PuzzleRepairEncounter
        )
        let candidates = [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]
        let incorrectSwap = try XCTUnwrap(candidates.first { !encounter.isCorrectSwap($0) })
        let first = try XCTUnwrap(
            scene.childNode(withName: "repairStep\(incorrectSwap[0])")
        )
        let second = try XCTUnwrap(
            scene.childNode(withName: "repairStep\(incorrectSwap[1])")
        )
        XCTAssertGreaterThanOrEqual(first.calculateAccumulatedFrame().width, 110)
        let firstX = first.position.x
        let secondX = second.position.x

        scene.handleTap(at: first.position)
        scene.handleTap(at: second.position)
        let testLever = try XCTUnwrap(scene.childNode(withName: "repairFix"))
        scene.handleTap(at: testLever.position)

        // Incorrect assessment is recorded once, but the selected gears
        // still visibly change places and the rotor stalls on that outcome.
        XCTAssertEqual(first.position.x, secondX, accuracy: 0.01)
        XCTAssertEqual(second.position.x, firstX, accuracy: 0.01)
        let rotor = try XCTUnwrap(scene.childNode(withName: "//repairMachineRotor"))
        XCTAssertEqual(rotor.zRotation, -.pi / 10, accuracy: 0.01)
        let wrongEvidence = state.profile.progress(for: PuzzleSkills.debugSequence).evidence
        XCTAssertEqual(wrongEvidence.count, 1)
        XCTAssertEqual(wrongEvidence.last?.outcome, .incorrect)
        XCTAssertEqual(wrongEvidence.last?.supportLevel, .independent)

        scene.speed = 0
        try await capture(scene, in: view, name: "Puzzle-Palace-4x3-RepairLab-Wrong-Swap-Stalled")
        scene.speed = 1
        let previousFirstGear = scene.childNode(withName: "repairStep0")
        try await waitUntil(timeout: 3) {
            let freshGear = scene.childNode(withName: "repairStep0")
            return freshGear != nil
                && freshGear !== previousFirstGear
                && (scene.nativeReviewActiveEncounter as? PuzzleRepairEncounter)?.id != encounter.id
        }
        XCTAssertEqual(state.profile.progress(for: PuzzleSkills.debugSequence).evidence.count, 1,
                       "Retry must not create an extra correct outcome.")

        let retry = try XCTUnwrap(scene.nativeReviewActiveEncounter as? PuzzleRepairEncounter)
        for index in retry.swapIndices {
            let gear = try XCTUnwrap(scene.childNode(withName: "repairStep\(index)"))
            scene.handleTap(at: gear.position)
        }
        scene.handleTap(at: testLever.position)
        let outcomes = state.profile.progress(for: PuzzleSkills.debugSequence).evidence
        XCTAssertEqual(outcomes.count, 2)
        XCTAssertEqual(outcomes.last?.outcome, .correct)
        XCTAssertEqual(outcomes.last?.supportLevel, .lightHint,
                       "Correcting after a wrong try cannot be scored as independent mastery.")
    }

    func testIllustratedPalaceRoomsOnFourByThreeIPad() async throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true }
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let rooms: [(AppState.World, String)] = [
            (.puzzlePalace, "RuneGate"), (.memoryBridge, "MemoryBridge"),
            (.stopGoOrbs, "StopGoOrbs"), (.sortingPedestal, "SortingPedestal"),
            (.resortVault, "ResortVault"), (.mirrorHall, "MirrorHall"),
            (.pathTiles, "PathTiles"), (.commandGears, "CommandGears"),
            (.bugLantern, "BugLantern"), (.bugLanternRepair, "BugLanternRepair")
        ]
        for (world, name) in rooms {
            state.travel(to: world)
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)
            let painting = try XCTUnwrap(scene.childNode(withName: "puzzleIllustratedBackdrop") as? SKSpriteNode)
            XCTAssertEqual(painting.userData?["sourceAsset"] as? String, "Puzzle" + name + "IllustratedV2")
            let image = try XCTUnwrap(painting.texture?.cgImage())
            XCTAssertGreaterThan(image.width, 1280)
            XCTAssertGreaterThan(image.height, 720)
            XCTAssertEqual(scene.size, CGSize(width: 1280, height: 960))
            XCTAssertEqual(painting.size.height, scene.size.height)
            XCTAssertGreaterThanOrEqual(painting.size.width, scene.size.width)
            XCTAssertTrue(painting.userData?["aspectFilledForIPad"] as? Bool ?? false)
            XCTAssertFalse(painting.isUserInteractionEnabled)
            // The approved painting, not duplicate generated SpriteKit architecture,
            // supplies the finished environment in all ten rooms.
            for decoration in ["puzzleStageDais", "puzzleStageInlay", "puzzleFloorSeal",
                               "puzzleCrystalFixture", "puzzleRoomIdentity"] {
                if let syntheticDecoration = scene.childNode(withName: decoration) {
                    XCTAssertTrue(
                        syntheticDecoration.isHidden,
                        "\(name): redundant \(decoration) must not paint over the room."
                    )
                }
            }
            if world == .puzzlePalace {
                let gate = try XCTUnwrap(scene.childNode(withName: "puzzleGate") as? SKShapeNode)
                let paintingScale = max(1, scene.size.height / 720)
                XCTAssertEqual(
                    gate.position.x,
                    640 + (949 - 640) * paintingScale,
                    accuracy: 1
                )
                XCTAssertEqual(gate.fillColor.cgColor.alpha, 0, accuracy: 0.001)
                XCTAssertNotNil(scene.childNode(withName: "//puzzleGateLock"))
                XCTAssertNotNil(scene.childNode(withName: "//puzzleGateOpening"))
                XCTAssertNotNil(scene.childNode(withName: "//runeLockHousing"))
            }
            if world == .bugLanternRepair {
                XCTAssertNotNil(scene.childNode(withName: "repairDriveShaft"))
                XCTAssertNotNil(scene.childNode(withName: "//repairMachineRotor"))
                XCTAssertNotNil(scene.childNode(withName: "repairFix"))
            }
            // Keep the *scene's initial encounter* for retry validation.
            // The adaptive director may select a different future encounter
            // after an incorrect answer, while this scene still displays
            // its original runes, memory order, sorting rules or mirrors.
            // Lock onto the scene's actual encounter; querying AppState again
            // can pick a different adaptive challenge than the visible props.
            let frozenEncounter = try XCTUnwrap(
                scene.nativeReviewActiveEncounter,
                "\(name) should have a playable native encounter."
            )
            if world == .stopGoOrbs {
                let signal = try XCTUnwrap(scene.childNode(withName: "stopGoOrb"))
                XCTAssertTrue(signal.isAccessibilityElement)
                XCTAssertFalse((signal.accessibilityLabel ?? "").isEmpty)
                // The timed HOLD phase is intentionally shorter than the
                // screenshot exporter. Freeze the live SpriteKit signal while
                // capturing the initial frame and the deliberate wrong tap.
                try await waitUntil(timeout: 4) {
                    (scene.instruction.text ?? "").hasPrefix("HOLD")
                }
                scene.speed = 0
            }
            try await capture(scene, in: view, name: "Illustrated-Palace-4x3-" + name)
            try await exercisePalaceVisualReview(
                world, scene: scene, state: state, correct: false,
                frozenEncounter: frozenEncounter
            )
            try await capture(scene, in: view,
                              name: "Illustrated-Palace-4x3-" + name + "-Incorrect")
            if world == .stopGoOrbs { scene.speed = 1 }
            try await exercisePalaceVisualReview(
                world, scene: scene, state: state, correct: true,
                frozenEncounter: frozenEncounter
            )
            try await capture(scene, in: view,
                              name: "Illustrated-Palace-4x3-" + name + "-Successful")
            scene.willLeave()

            // Progression fixtures deliberately unlock the *next* room.
            // Earlier screenshots showed locked rooms with no playable controls.
            // Keep the capture itself native and use a fresh scene for save/restore.
            func complete<E>(_ encounters: [E], record: (E) -> Void) {
                encounters.forEach(record)
            }
            switch world {
            case .puzzlePalace:
                complete(PuzzlePalaceEncounterCatalog.runeGate) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .memoryBridge:
                complete(PuzzlePalaceEncounterCatalog.memoryBridge) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .stopGoOrbs:
                complete(PuzzlePalaceEncounterCatalog.stopGoOrbs) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .sortingPedestal:
                complete(PuzzlePalaceEncounterCatalog.sortingFoundation +
                         PuzzlePalaceEncounterCatalog.ruleSwitching) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .resortVault:
                complete(PuzzlePalaceEncounterCatalog.changedRuleResort) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .mirrorHall:
                complete(PuzzlePalaceEncounterCatalog.mirrorHallOrientation) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
                complete(PuzzlePalaceEncounterCatalog.mirrorHallRotation) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .pathTiles:
                complete(PuzzlePalaceEncounterCatalog.pathTileFamilies.map { $0[0] }) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .commandGears:
                complete(PuzzlePalaceEncounterCatalog.commandGearFamilies.map { $0[0] }) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .bugLantern:
                complete(PuzzlePalaceEncounterCatalog.bugLanternFamilies.map { $0[0] }) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            case .bugLanternRepair:
                complete(PuzzlePalaceEncounterCatalog.bugRepairFamilies.map { $0[0] }) {
                    _ = state.recordPuzzle($0, outcome: .correct, support: .independent,
                                           attempts: 1, responseTime: 1)
                }
            default:
                XCTFail("Unexpected Palace review room")
            }
            let restored = PuzzlePalaceScene(state: state)
            restored.reducedMotion = true
            view.presentScene(restored)
            if world == .pathTiles {
                XCTAssertNotNil(restored.childNode(withName: "pathGrid"),
                                "Saved safe crossing must still have floor stones.")
                XCTAssertNotNil(restored.childNode(withName: "//pathRouteTrace"),
                                "Saved safe route must remain visibly connected.")
                XCTAssertNil(restored.childNode(withName: "pathChoice0"),
                             "Completed room cannot reopen answer workbenches.")
            }
            if world == .mirrorHall {
                for index in 0..<3 {
                    XCTAssertNotNil(restored.childNode(withName: "restoredMirrorFixture\(index)"),
                                    "Completed Mirror Hall must retain physical mirrors.")
                }
                XCTAssertNotNil(restored.childNode(withName: "mirrorActiveRay"),
                                "Restored light should still reach its receiver.")
            }
            try await capture(restored, in: view,
                              name: "Illustrated-Palace-4x3-" + name + "-Restored")
            restored.willLeave()
        }

        // An actual open passage should replace the painted closed door after
        // restored progress, including on a 4:3 iPad and after a new scene.
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter, outcome: .correct, support: .independent,
                attempts: 1, responseTime: 1
            )
        }
        state.travel(to: .puzzlePalace)
        let opened = PuzzlePalaceScene(state: state)
        opened.reducedMotion = true
        view.presentScene(opened)
        // The restored opening is the carved passage behind the moving door.
        // The original narrow glow guide is intentionally hidden by the new art.
        let passage = try XCTUnwrap(
            opened.childNode(withName: "//runeDoorOpenInterior") as? SKShapeNode
        )
        XCTAssertFalse(passage.isHidden)
        XCTAssertEqual(passage.alpha, 1, accuracy: 0.001)
        XCTAssertNotNil(opened.childNode(withName: "runeDoorPassage"))
        XCTAssertNotNil(opened.childNode(withName: "memoryBridgeRoute"))
        try await capture(opened, in: view, name: "Illustrated-Palace-4x3-RuneGate-Open")
        opened.willLeave()
    }

    private func capture(_ scene: AdventureScene, in view: SKView, name: String) async throws {
        // Let SpriteKit render an actual frame on the simulator, not a mock composition.
        try await Task.sleep(nanoseconds: 300_000_000)
        let texture = try XCTUnwrap(view.texture(from: scene, crop: CGRect(x: 0, y: -scene.verticalViewportInset, width: scene.size.width, height: scene.size.height)))
        let image = UIImage(cgImage: texture.cgImage())
        // Keep a file copy as well: some xcresult exports omit successful-test attachments.
        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("NativeSceneReview", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try XCTUnwrap(image.pngData())
        try data.write(to: directory.appendingPathComponent(name + ".png"), options: .atomic)
        let attachment = XCTAttachment(image: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testMathCastleAmbientMachineryAndActiveFocusRespectReducedMotion() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let encounter = MathCastleEncounterCatalog.numberBondMachine[0]
        XCTAssertTrue(state.startWorkshop(encounter))

        let scene = MathCastleScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let chain0 = try XCTUnwrap(scene.childNode(withName: "//castleAmbientChain0"))
        let chain1 = try XCTUnwrap(scene.childNode(withName: "//castleAmbientChain1"))
        let powerMount = try XCTUnwrap(scene.childNode(withName: "castlePowerMount"))
        let workshopRim = try XCTUnwrap(
            scene.childNode(withName: "//workshopRim_workshop0")
        )

        XCTAssertNotNil(chain0.action(forKey: "ambientChainSway"))
        XCTAssertNotNil(chain1.action(forKey: "ambientChainSway"))
        XCTAssertNotNil(powerMount.action(forKey: "ambientSpin"))
        XCTAssertNotNil(workshopRim.action(forKey: "ambientWorkshopSpin"))

        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 925, y: 280))

        let machine = try XCTUnwrap(
            scene.childNode(withName: "//\(MathMechanicID.numberBondMachine)")
        )
        XCTAssertNotNil(machine.action(forKey: "activeMachineBreath"))
        XCTAssertNotNil(scene.camera?.action(forKey: "focus"))

        scene.reducedMotion = true
        scene.update(0)

        XCTAssertNil(chain0.action(forKey: "ambientChainSway"))
        XCTAssertNil(chain1.action(forKey: "ambientChainSway"))
        XCTAssertNil(powerMount.action(forKey: "ambientSpin"))
        XCTAssertNil(workshopRim.action(forKey: "ambientWorkshopSpin"))
        XCTAssertNil(machine.action(forKey: "activeMachineBreath"))
        XCTAssertEqual(scene.camera?.position.x ?? 0, 640, accuracy: 0.001)
        XCTAssertEqual(scene.camera?.position.y ?? 0, 360, accuracy: 0.001)
    }

    func testMathQuestionRendersAboveManipulativeAndFeedbackStaysBelow() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let encounter = MathCastleEncounterCatalog.numberBondMachine[0]
        XCTAssertTrue(state.startWorkshop(encounter))

        let scene = MathCastleScene(state: state)
        scene.didMove(to: SKView())
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 925, y: 280))

        let prompt = try XCTUnwrap(scene.childNode(withName: "questionPrompt") as? SKLabelNode)
        let heading = try XCTUnwrap(scene.childNode(withName: "questionPromptHeading") as? SKLabelNode)
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)

        XCTAssertFalse(prompt.isHidden)
        XCTAssertFalse(heading.isHidden)
        XCTAssertEqual(heading.text, "PIP'S WORK ORDER")
        XCTAssertEqual(heading.fontName, "AvenirNext-Bold")
        XCTAssertEqual(prompt.fontName, "AvenirNext-Medium")
        XCTAssertEqual(prompt.fontSize, encounter.prompt.count > 52 ? 17 : 18)
        XCTAssertTrue(prompt.text?.contains(encounter.prompt) == true)
        XCTAssertGreaterThan(prompt.position.y, 500)
        XCTAssertLessThan(feedback.position.y, 100)
        XCTAssertGreaterThan(prompt.position.y, feedback.position.y)
        XCTAssertLessThanOrEqual(prompt.preferredMaxLayoutWidth, 400)
        let promptPlate = try XCTUnwrap(scene.childNode(withName: "questionPromptPlate"))
        let promptFrame = prompt.calculateAccumulatedFrame()
        let plateFrame = promptPlate.calculateAccumulatedFrame()
        XCTAssertGreaterThan(promptFrame.minY, plateFrame.minY + 6)
        XCTAssertLessThan(promptFrame.maxY, plateFrame.maxY - 6)
        XCTAssertNotNil(scene.childNode(withName: "mathWorkZoneCore"))
        XCTAssertNotNil(scene.childNode(withName: "workshopRackBacking"))
        XCTAssertNotNil(scene.childNode(withName: "castlePowerMount"))
        XCTAssertNotNil(scene.childNode(withName: "//bondMachineBase"))
        XCTAssertNotNil(scene.childNode(withName: "//bondWholePlaque"))

        scene.willLeave()
    }


    func testWordGardenVisualEvidencePersistsWithoutCreatingSpokenLetterMastery() async throws {
        let container = try LearningStore.container(inMemory: true)
        let state = try AppState(context: ModelContext(container))
        state.travel(to: .wordGarden)

        let encounter = state.nextLiteracyEncounter()
        let wrong = try XCTUnwrap(encounter.choices.first { $0 != encounter.answer })
        let first = state.recordLiteracy(
            encounter,
            outcome: .incorrect,
            support: .independent,
            attempts: 1,
            responseTime: 1.4
        )
        XCTAssertEqual(first.supportLevel, .independent)

        let corrected = state.recordLiteracy(
            encounter,
            outcome: .correct,
            support: .lightHint,
            attempts: 2,
            responseTime: 2.8
        )
        XCTAssertEqual(corrected.outcome, .correct)
        XCTAssertTrue(state.profile.usedFingerprints.contains(encounter.fingerprint))

        let restored = try AppState(context: ModelContext(container))
        XCTAssertEqual(restored.world, .wordGarden)
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.visualLetterMatch).evidence.count,
            2
        )
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.visualLetterMatch).state,
            .learning
        )
        XCTAssertEqual(
            restored.profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertNotEqual(wrong, encounter.answer)
    }

    func testMathTenFrameUsesCrystalArtWithoutChangingCellTargets() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathCastleEncounterCatalog.tenFrameGate[0]))

        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let cells = try XCTUnwrap(scene.childNode(withName: "//tenFrameCells"))
        XCTAssertEqual(cells.children.count, 10)
        XCTAssertNotNil(scene.childNode(withName: "//tenFrameGateFrame"))
        XCTAssertNotNil(scene.childNode(withName: "//tenFrameGateInset"))
        XCTAssertNotNil(scene.childNode(withName: "//tenFrameRowDivider"))
        XCTAssertNotNil(scene.childNode(withName: "//tenFrameGateBadge"))

        for cell in cells.children {
            let shape = try XCTUnwrap(cell as? SKShapeNode)
            XCTAssertNotNil(
                shape.children.compactMap { $0 as? SKSpriteNode }.first,
                "Each ten-frame cell should render the shared crystal art."
            )
            XCTAssertTrue(
                ["tenFrameCell", "tenFrameFixed", "tenFrameFilled", "tenFramePreview"].contains(shape.name ?? "")
            )
        }

        let supply = try XCTUnwrap(scene.childNode(withName: "//tenFrameSupply"))
        XCTAssertGreaterThanOrEqual(supply.calculateAccumulatedFrame().width, 90)
        XCTAssertGreaterThanOrEqual(supply.calculateAccumulatedFrame().height, 90)
    }

    func testIncorrectMathAnswerKeepsPhysicalRouteClosed() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let encounter = MathCastleEncounterCatalog.balanceScale[0]
        XCTAssertTrue(state.startWorkshop(encounter))

        let scene = MathCastleScene(state: state)
        scene.didMove(to: SKView())
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 820, y: 310))

        // 5 vs 8: left is deliberately incorrect.
        scene.handleTap(at: CGPoint(x: 670, y: 265))
        scene.handleTap(at: CGPoint(x: 1120, y: 250))

        XCTAssertFalse(state.runtime?.completed == true)
        let bridge = try XCTUnwrap(scene.childNode(withName: "physicalRouteBridge"))
        XCTAssertEqual(bridge.xScale, 0.06, accuracy: 0.001)
        XCTAssertNil(bridge.action(forKey: "routeOpen"))

        let beacon = try XCTUnwrap(scene.childNode(withName: "routeDestinationBeacon") as? SKShapeNode)
        XCTAssertEqual(beacon.glowWidth, 0)
        scene.willLeave()
    }


    func testLandscapeIPadAspectFitKeepsTheDesignCanvasFullyVisible() {
        let layout = AdventureSceneLayout(size: CGSize(width: 1280, height: 720))
        let landscapeSurfaces = [
            CGSize(width: 1024, height: 768),   // classic 4:3 iPad
            CGSize(width: 1180, height: 820),   // modern 10.9-inch class
            CGSize(width: 1366, height: 1024),  // large 4:3 class
            CGSize(width: 1280, height: 720)    // screenshot/reference surface
        ]

        for surface in landscapeSurfaces {
            let frame = layout.fittedFrame(in: surface)
            XCTAssertGreaterThan(frame.width, 0)
            XCTAssertGreaterThan(frame.height, 0)
            XCTAssertGreaterThanOrEqual(frame.minX, -0.001)
            XCTAssertGreaterThanOrEqual(frame.minY, -0.001)
            XCTAssertLessThanOrEqual(frame.maxX, surface.width + 0.001)
            XCTAssertLessThanOrEqual(frame.maxY, surface.height + 0.001)
            XCTAssertEqual(frame.width / frame.height, 1280.0 / 720.0, accuracy: 0.001)
        }
    }

    func testReducedMotionSuppressesDecorativeEntranceAndLandmarkPulsing() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        XCTAssertFalse(scene.valkyrie.hasActions())
        XCTAssertFalse(scene.pip.hasActions())
        let castle = try XCTUnwrap(scene.childNode(withName: "castle"))
        let halo = try XCTUnwrap(castle.children.compactMap { $0 as? SKShapeNode }.first)
        XCTAssertFalse(halo.hasActions(), "Reduced motion must disable landmark pulsing.")
        XCTAssertNil(scene.childNode(withName: "decorativeAmbientLife"))
    }

    func testAmbientLifeAndSuccessBurstRespectReducedMotion() throws {
        let livelyState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let lively = StoryTreeScene(state: livelyState)
        lively.reducedMotion = false
        lively.didMove(to: SKView())
        defer { lively.willLeave() }

        let ambient = try XCTUnwrap(lively.childNode(withName: "decorativeAmbientLife"))
        XCTAssertGreaterThanOrEqual(ambient.children.count, 7)
        XCTAssertTrue(
            ambient.children.contains { $0.action(forKey: "ambientDrift") != nil },
            "Live worlds should have subtle environmental motion."
        )

        lively.successFeedback()
        let burst = try XCTUnwrap(lively.childNode(withName: "successBurst"))
        XCTAssertTrue(burst.hasActions())
        XCTAssertGreaterThanOrEqual(burst.children.count, 8)

        let calmState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let calm = StoryTreeScene(state: calmState)
        calm.reducedMotion = true
        calm.didMove(to: SKView())
        defer { calm.willLeave() }

        XCTAssertNil(calm.childNode(withName: "decorativeAmbientLife"))
        calm.successFeedback()
        XCTAssertNil(calm.childNode(withName: "successBurst"))
    }

    func testMathCastleMachineryFeelsAliveAndRespectsReducedMotion() throws {
        let livelyState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        XCTAssertTrue(livelyState.startWorkshop(MathFoundation.workshopExamples[0]))
        let lively = MathCastleScene(state: livelyState)
        lively.reducedMotion = false
        lively.didMove(to: SKView())
        defer { lively.willLeave() }

        let station = try XCTUnwrap(lively.childNode(withName: "workshop0"))
        let stationRim = try XCTUnwrap(station.childNode(withName: "workshopRim_workshop0"))
        let powerMount = try XCTUnwrap(lively.childNode(withName: "castlePowerMount"))
        let environmentGear = try XCTUnwrap(lively.childNode(withName: "environmentGear0"))
        XCTAssertNotNil(stationRim.action(forKey: "ambientWorkshopSpin"))
        XCTAssertNotNil(powerMount.action(forKey: "ambientSpin"))
        XCTAssertNotNil(environmentGear.action(forKey: "ambientSpin"))
        // The quantity icon is a sibling of the moving brass rim, so it stays readable.
        let icon = try XCTUnwrap(station.children.first { $0 is SKLabelNode })
        XCTAssertFalse(icon.hasActions())

        lively.handleTap(at: CGPoint(x: 140, y: 548))
        XCTAssertNotNil(stationRim.action(forKey: "workshopTapSurge"))
        lively.valkyrie.position = CGPoint(x: 490, y: 175)
        lively.handleTap(at: CGPoint(x: 830, y: 265))
        let core = try XCTUnwrap(lively.childNode(withName: "mathWorkZoneCore"))
        XCTAssertNotNil(lively.camera?.action(forKey: "focus"))
        XCTAssertNotNil(core.action(forKey: "activeMachineBreath"))

        // Model the intermediate frame at which a child changes the setting.
        core.alpha = 0.56
        lively.reducedMotion = true
        lively.update(1)
        XCTAssertNil(stationRim.action(forKey: "ambientWorkshopSpin"))
        XCTAssertNil(stationRim.action(forKey: "workshopTapSurge"))
        XCTAssertNil(powerMount.action(forKey: "ambientSpin"))
        XCTAssertNil(environmentGear.action(forKey: "ambientSpin"))
        XCTAssertNil(core.action(forKey: "activeMachineBreath"))
        XCTAssertEqual(core.alpha, 1, accuracy: 0.001)

        lively.reducedMotion = false
        lively.update(2)
        XCTAssertNotNil(stationRim.action(forKey: "ambientWorkshopSpin"))
        XCTAssertNotNil(core.action(forKey: "activeMachineBreath"))

        let calmState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        XCTAssertTrue(calmState.startWorkshop(MathFoundation.workshopExamples[0]))
        let calm = MathCastleScene(state: calmState)
        calm.reducedMotion = true
        calm.didMove(to: SKView())
        defer { calm.willLeave() }
        let calmRim = try XCTUnwrap(calm.childNode(withName: "//workshopRim_workshop0"))
        let calmPower = try XCTUnwrap(calm.childNode(withName: "castlePowerMount"))
        let calmGear = try XCTUnwrap(calm.childNode(withName: "environmentGear0"))
        XCTAssertNil(calmRim.action(forKey: "ambientWorkshopSpin"))
        XCTAssertNil(calmPower.action(forKey: "ambientSpin"))
        XCTAssertNil(calmGear.action(forKey: "ambientSpin"))
        calm.handleTap(at: CGPoint(x: 140, y: 548))
        XCTAssertNil(calmRim.action(forKey: "workshopTapSurge"))
        calm.valkyrie.position = CGPoint(x: 490, y: 175)
        calm.handleTap(at: CGPoint(x: 830, y: 265))
        XCTAssertNil(calm.camera?.action(forKey: "focus"))
        XCTAssertNil(calm.childNode(withName: "mathWorkZoneCore")?.action(forKey: "activeMachineBreath"))
    }

    func testSharedHUDAndPromptTextStayInsideSafeDesignBounds() throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let scene = MathCastleScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let title = try XCTUnwrap(scene.childNode(withName: "worldTitle") as? SKLabelNode)
        let titleBackdrop = try XCTUnwrap(scene.childNode(withName: "worldTitleBackdrop"))
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)
        let feedbackBackdrop = try XCTUnwrap(scene.childNode(withName: "instructionBackdrop"))
        XCTAssertTrue(CGRect(origin: .zero, size: scene.size).contains(title.position))
        XCTAssertTrue(CGRect(origin: .zero, size: scene.size).contains(feedback.position))
        XCTAssertEqual(title.fontName, "Georgia-Bold")
        XCTAssertLessThanOrEqual(titleBackdrop.calculateAccumulatedFrame().width, 250)
        XCTAssertEqual(feedback.fontName, "AvenirNext-Medium")
        XCTAssertLessThanOrEqual(feedback.fontSize, 18)
        XCTAssertLessThanOrEqual(feedback.preferredMaxLayoutWidth, 600)
        XCTAssertLessThanOrEqual(feedbackBackdrop.calculateAccumulatedFrame().width, 680)

        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        let prompt = try XCTUnwrap(scene.childNode(withName: "questionPrompt") as? SKLabelNode)
        XCTAssertEqual(prompt.numberOfLines, 2)
        XCTAssertLessThanOrEqual(prompt.preferredMaxLayoutWidth, 440)
    }

    func testStoryTreeHubUsesCompactDiegeticWayfinding() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let title = try XCTUnwrap(scene.childNode(withName: "worldTitle") as? SKLabelNode)
        let titleBackdrop = try XCTUnwrap(scene.childNode(withName: "worldTitleBackdrop"))
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)
        let feedbackBackdrop = try XCTUnwrap(scene.childNode(withName: "instructionBackdrop"))

        XCTAssertEqual(title.fontName, "Georgia-Bold")
        XCTAssertLessThanOrEqual(title.fontSize, 20)
        XCTAssertLessThanOrEqual(titleBackdrop.calculateAccumulatedFrame().width, 390)
        XCTAssertEqual(feedback.fontName, "AvenirNext-Medium")
        XCTAssertLessThanOrEqual(feedback.fontSize, 18)
        XCTAssertLessThanOrEqual(feedback.preferredMaxLayoutWidth, 610)
        XCTAssertLessThanOrEqual(feedbackBackdrop.calculateAccumulatedFrame().width, 670)

        for name in ["wordGarden", "puzzlePalace", "castle", "scienceLab"] {
            let marker = try XCTUnwrap(scene.childNode(withName: name))
            XCTAssertGreaterThanOrEqual(marker.calculateAccumulatedFrame().width, 60)
            XCTAssertGreaterThanOrEqual(marker.calculateAccumulatedFrame().height, 60)

            let pulse = try XCTUnwrap(
                marker.children.first {
                    ($0.userData?["decorativeMotionRole"] as? String) == "pulse"
                }
            )
            XCTAssertNil(pulse.action(forKey: "ambientPulse"))

            let plaque = try XCTUnwrap(
                marker.children.first {
                    ($0.userData?["destinationRole"] as? String) == "plaque"
                }
            )
            let label = try XCTUnwrap(
                plaque.children.compactMap { $0 as? SKLabelNode }.first
            )
            XCTAssertEqual(label.fontName, "Georgia-Bold")
            XCTAssertLessThanOrEqual(label.fontSize, 15)
        }

        let pipGear = try XCTUnwrap(scene.childNode(withName: "pipWind"))
        XCTAssertGreaterThanOrEqual(pipGear.calculateAccumulatedFrame().width, 64)
        XCTAssertGreaterThanOrEqual(pipGear.calculateAccumulatedFrame().height, 64)
    }

    func testStoryTreeLivingHubMotionRespectsReducedMotion() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = false
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let gardenRim = try XCTUnwrap(
            scene.childNode(withName: "//storyMarkerRim_wordGarden")
        )
        let gardenIcon = try XCTUnwrap(
            scene.childNode(withName: "//storyMarkerIcon_wordGarden")
        )
        let castleRim = try XCTUnwrap(
            scene.childNode(withName: "//storyMarkerRim_castle")
        )
        let pipGearRim = try XCTUnwrap(
            scene.childNode(withName: "//storyPipGearRim")
        )
        let pipGearRoot = try XCTUnwrap(scene.childNode(withName: "pipWind"))
        let pipGearIcon = try XCTUnwrap(
            pipGearRoot.children.compactMap { $0 as? SKLabelNode }
                .first { $0.text == "✦" }
        )

        XCTAssertFalse(gardenIcon.parent === gardenRim)
        XCTAssertFalse(pipGearIcon.parent === pipGearRim)
        let storyLight = try XCTUnwrap(scene.childNode(withName: "storyLight"))

        XCTAssertNotNil(gardenRim.action(forKey: "hubMarkerDrift"))
        XCTAssertNotNil(castleRim.action(forKey: "hubMarkerDrift"))
        XCTAssertNotNil(pipGearRim.action(forKey: "hubPipGearSpin"))
        XCTAssertNotNil(storyLight.action(forKey: "hubLightBreath"))

        scene.handleTap(at: CGPoint(x: 150, y: 430))
        XCTAssertNotNil(scene.camera?.action(forKey: "focus"))

        scene.reducedMotion = true
        scene.update(0)

        XCTAssertNil(gardenRim.action(forKey: "hubMarkerDrift"))
        XCTAssertNil(castleRim.action(forKey: "hubMarkerDrift"))
        XCTAssertNil(pipGearRim.action(forKey: "hubPipGearSpin"))
        XCTAssertNil(storyLight.action(forKey: "hubLightBreath"))
        XCTAssertEqual(scene.camera?.position.x ?? 0, 640, accuracy: 0.001)
        XCTAssertEqual(scene.camera?.position.y ?? 0, 360, accuracy: 0.001)
    }

    func testPuzzlePalaceLanternPersistsAndMovesOnStoryTree() throws {
        let container = try LearningStore.container(inMemory: true)
        let store = try LearningStore(context: ModelContext(container))
        var profile = try store.loadProfile()
        XCTAssertTrue(profile.unlockStoryReward(.puzzlePalaceLantern))
        try store.save(
            profile: profile,
            adventure: MathAdventure(continuingLearner: true),
            sound: true,
            reducedMotion: false,
            world: "storyTree"
        )

        let state = try AppState(context: ModelContext(container))
        XCTAssertTrue(state.hasStoryReward(.puzzlePalaceLantern))
        XCTAssertFalse(state.hasStoryReward(.moonLantern))
        XCTAssertFalse(state.hasStoryReward(.wordGardenLantern))

        let tree = StoryTreeScene(state: state)
        tree.reducedMotion = true
        tree.didMove(to: SKView())
        let lantern = try XCTUnwrap(tree.childNode(withName: "puzzlePalaceLantern"))
        let before = state.storyRewardPlacement(.puzzlePalaceLantern)
        tree.handleTap(at: lantern.position)
        XCTAssertNotEqual(state.storyRewardPlacement(.puzzlePalaceLantern), before)
        tree.willLeave()

        let restored = try AppState(context: ModelContext(container))
        XCTAssertTrue(restored.hasStoryReward(.puzzlePalaceLantern))
        XCTAssertEqual(
            restored.storyRewardPlacement(.puzzlePalaceLantern),
            state.storyRewardPlacement(.puzzlePalaceLantern)
        )

        let restoredTree = StoryTreeScene(state: restored)
        restoredTree.reducedMotion = true
        restoredTree.didMove(to: SKView())
        XCTAssertNotNil(restoredTree.childNode(withName: "puzzlePalaceLantern"))
        restoredTree.willLeave()
    }



    func testScienceAdventureScenesMeetProductionVisualStructure() throws {
        func assertCompactScienceHUD(
            _ scene: AdventureScene,
            homeName: String,
            maxTitleWidth: CGFloat
        ) throws {
            let title = try XCTUnwrap(scene.childNode(withName: "worldTitle") as? SKLabelNode)
            let titleBackdrop = try XCTUnwrap(scene.childNode(withName: "worldTitleBackdrop"))
            let guidance = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)
            let guidanceBackdrop = try XCTUnwrap(scene.childNode(withName: "instructionBackdrop"))
            let home = try XCTUnwrap(scene.childNode(withName: homeName))

            XCTAssertEqual(title.fontName, "Georgia-Bold")
            XCTAssertLessThanOrEqual(title.fontSize, 20)
            XCTAssertLessThanOrEqual(
                titleBackdrop.calculateAccumulatedFrame().width,
                maxTitleWidth
            )
            XCTAssertEqual(guidance.fontName, "AvenirNext-Medium")
            XCTAssertLessThanOrEqual(guidance.fontSize, 18)
            XCTAssertLessThanOrEqual(guidance.preferredMaxLayoutWidth, 620)
            XCTAssertLessThanOrEqual(
                guidanceBackdrop.calculateAccumulatedFrame().width,
                670
            )
            XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().width, 60)
            XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().height, 60)
        }

        let greenhouseState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        greenhouseState.travel(to: .scienceLab)
        let greenhouse = ScienceLabScene(state: greenhouseState)
        greenhouse.reducedMotion = true
        greenhouse.didMove(to: SKView())

        XCTAssertNotNil(greenhouse.childNode(withName: "scienceGreenhouseBackdropHD"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceGreenhouseFrame"))
        XCTAssertLessThan(greenhouse.childNode(withName: "scienceGreenhouseFrame")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(greenhouse.childNode(withName: "scienceGround")?.alpha ?? 1, 0.3)
        XCTAssertGreaterThan(greenhouse.childNode(withName: "scienceSeedBench")?.alpha ?? 0, 0.9)
        XCTAssertLessThan(greenhouse.childNode(withName: "scienceWaterTank")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(greenhouse.childNode(withName: "scienceSunPrism")?.alpha ?? 1, 0.01)
        XCTAssertNotNil(greenhouse.childNode(withName: "//scienceGreenhouseGlass"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//scienceGreenhouseRidge"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceSeedBench"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceWaterValve"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//scienceWaterGauge"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceWaterPipe"))
        XCTAssertNotNil(greenhouse.childNode(withName: "scienceSunPrism"))
        XCTAssertNotNil(greenhouse.childNode(withName: "sciencePrismBeam"))
        XCTAssertNotNil(greenhouse.childNode(withName: "decorativeScienceConceptAccents"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//decorativeScienceDome"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//decorativeScienceHangingPlanter0"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//decorativeSciencePlantCloche"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//decorativeScienceExperimentRail"))
        XCTAssertNotNil(greenhouse.childNode(withName: "//decorativeScienceObservationBoard"))
        XCTAssertEqual(
            greenhouse.targetName(at: CGPoint(x: 685, y: 235)),
            "scienceSeedBench",
            "Greenhouse concept decoration must not steal the seed-bench tap."
        )
        XCTAssertEqual(
            greenhouse.targetName(at: CGPoint(x: 430, y: 220)),
            "scienceWaterValve"
        )
        XCTAssertEqual(
            greenhouse.targetName(at: CGPoint(x: 940, y: 245)),
            "scienceSunPrism"
        )
        XCTAssertEqual(greenhouse.milo.xScale, 0.82, accuracy: 0.001)
        try assertCompactScienceHUD(
            greenhouse,
            homeName: "scienceHome",
            maxTitleWidth: 340
        )
        greenhouse.willLeave()

        let weatherState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        weatherState.travel(to: .scienceWeatherTower)
        let weather = WeatherTowerScene(state: weatherState)
        weather.reducedMotion = true
        weather.didMove(to: SKView())

        XCTAssertNotNil(weather.childNode(withName: "weatherBackdropHD"))
        XCTAssertNotNil(weather.childNode(withName: "weatherTowerStructure"))
        XCTAssertLessThan(weather.childNode(withName: "weatherTowerStructure")?.xScale ?? 1, 0.6)
        XCTAssertLessThan(weather.childNode(withName: "weatherTowerStructure")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(weather.childNode(withName: "weatherTerrace")?.alpha ?? 1, 0.3)
        XCTAssertGreaterThan(weather.childNode(withName: "scienceMorningWeather")?.alpha ?? 0, 0.9)
        XCTAssertLessThan(weather.childNode(withName: "scienceAfternoonWeather")?.alpha ?? 1, 0.01)
        XCTAssertLessThan(weather.childNode(withName: "scienceForecastBase")?.alpha ?? 1, 0.01)
        XCTAssertNotNil(weather.childNode(withName: "//weatherObservationGlass"))
        XCTAssertNotNil(weather.childNode(withName: "//weatherTowerRoofTrim"))
        XCTAssertNotNil(weather.childNode(withName: "weatherTerrace"))
        XCTAssertNotNil(weather.childNode(withName: "scienceForecastBase"))
        XCTAssertNotNil(weather.childNode(withName: "scienceMorningWeather"))
        XCTAssertNotNil(weather.childNode(withName: "scienceAfternoonWeather"))
        XCTAssertEqual(weather.milo.xScale, 0.82, accuracy: 0.001)
        try assertCompactScienceHUD(
            weather,
            homeName: "scienceWeatherHome",
            maxTitleWidth: 360
        )
        weather.willLeave()

        let groveState = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        groveState.travel(to: .scienceCreatureGrove)
        let grove = CreatureGroveScene(state: groveState)
        grove.reducedMotion = true
        grove.didMove(to: SKView())

        XCTAssertNotNil(grove.childNode(withName: "creatureGroveBackdropHD"))
        XCTAssertNotNil(grove.childNode(withName: "grovePath"))
        XCTAssertLessThan(grove.childNode(withName: "grovePath")?.alpha ?? 1, 0.3)
        XCTAssertNotNil(grove.childNode(withName: "//grovePondBank"))
        XCTAssertNotNil(grove.childNode(withName: "//grovePondShoreline"))
        XCTAssertNotNil(grove.childNode(withName: "//grovePondRipple"))
        XCTAssertNotNil(grove.childNode(withName: "scienceGroveDuck"))
        XCTAssertNotNil(grove.childNode(withName: "scienceWebbedFeet"))
        XCTAssertNotNil(grove.childNode(withName: "scienceCompareBoard"))
        XCTAssertEqual(grove.milo.xScale, 0.82, accuracy: 0.001)
        try assertCompactScienceHUD(
            grove,
            homeName: "scienceGroveHome",
            maxTitleWidth: 370
        )
        grove.willLeave()
    }

    func testRuneGateReadsAsPhysicalWorldInsteadOfFullscreenWorksheet() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .puzzlePalace)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let architecture = try XCTUnwrap(
            scene.childNode(withName: "puzzleArchitecture") as? SKShapeNode
        )
        XCTAssertLessThan(
            architecture.alpha,
            0.10,
            "Rune Gate should not be dominated by the old giant palace panel."
        )

        let gate = try XCTUnwrap(
            scene.childNode(withName: "puzzleGate") as? SKShapeNode
        )
        let gateFrame = gate.calculateAccumulatedFrame()
        XCTAssertLessThan(gateFrame.width, 190)
        XCTAssertLessThan(gateFrame.height, 270)

        let board = try XCTUnwrap(scene.childNode(withName: "runeBoard"))
        XCTAssertLessThan(
            board.calculateAccumulatedFrame().width,
            520,
            "The rune pattern should read as physical stones, not a wide quiz rail."
        )

        let choices = scene.children.filter { $0.name == "runeChoice" }
        XCTAssertEqual(choices.count, 3)
        for choice in choices {
            let frame = choice.calculateAccumulatedFrame()
            XCTAssertGreaterThanOrEqual(frame.width, 88)
            XCTAssertGreaterThanOrEqual(frame.height, 88)
        }

        let instructionBackdrop = try XCTUnwrap(
            scene.childNode(withName: "instructionBackdrop")
        )
        XCTAssertLessThan(
            instructionBackdrop.calculateAccumulatedFrame().width,
            800,
            "Puzzle Palace instructions should not span nearly the whole screen."
        )
    }

    func testLongPuzzleWorldTitleAndActorScaleStayPresentationSafe() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        state.travel(to: .sortingPedestal)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let title = try XCTUnwrap(scene.childNode(withName: "worldTitle") as? SKLabelNode)
        let backdrop = try XCTUnwrap(
            scene.childNode(withName: "worldTitleBackdrop") as? SKShapeNode
        )
        let titleFrame = title.calculateAccumulatedFrame()
        let backdropFrame = backdrop.calculateAccumulatedFrame().insetBy(dx: 14, dy: 7)

        XCTAssertTrue(
            backdropFrame.contains(titleFrame),
            "Long Puzzle Palace destination titles must remain inside the shared title plaque."
        )
        XCTAssertGreaterThanOrEqual(backdropFrame.minX, 80)
        XCTAssertLessThanOrEqual(backdropFrame.maxX, 520)
        XCTAssertEqual(title.fontName, "Georgia-Bold")
        XCTAssertLessThanOrEqual(title.fontSize, 20)
        let guidance = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)
        let guidanceBackdrop = try XCTUnwrap(scene.childNode(withName: "instructionBackdrop"))
        XCTAssertEqual(guidance.fontName, "AvenirNext-Medium")
        XCTAssertLessThanOrEqual(guidance.fontSize, 18)
        XCTAssertLessThanOrEqual(guidance.preferredMaxLayoutWidth, 620)
        XCTAssertLessThanOrEqual(guidanceBackdrop.calculateAccumulatedFrame().width, 650)
        let home = try XCTUnwrap(scene.childNode(withName: "home"))
        XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().width, 60)
        XCTAssertGreaterThanOrEqual(home.calculateAccumulatedFrame().height, 60)
        XCTAssertEqual(scene.valkyrie.xScale, 0.56, accuracy: 0.001)
        XCTAssertEqual(scene.tiko.xScale, 0.92, accuracy: 0.001)
    }

    func testPolishedSharedControlsRetainLargeTouchGeometry() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = StoryTreeScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        let homeDestination = try XCTUnwrap(scene.childNode(withName: "castle"))
        XCTAssertGreaterThanOrEqual(homeDestination.calculateAccumulatedFrame().width, 60)
        XCTAssertGreaterThanOrEqual(homeDestination.calculateAccumulatedFrame().height, 60)

        let titleBackdrop = try XCTUnwrap(scene.childNode(withName: "worldTitleBackdrop") as? SKShapeNode)
        XCTAssertGreaterThan(titleBackdrop.lineWidth, 1)
        let feedbackBackdrop = try XCTUnwrap(scene.childNode(withName: "instructionBackdrop") as? SKShapeNode)
        XCTAssertGreaterThan(feedbackBackdrop.lineWidth, 1)
    }



    func testScienceGuidanceCueTracksTheNextPhysicalActionWithoutStealingInput() throws {
        let state = try AppState(
            context: ModelContext(try LearningStore.container(inMemory: true))
        )
        let scene = ScienceLabScene(state: state)
        scene.reducedMotion = true
        scene.didMove(to: SKView())
        defer { scene.willLeave() }

        var cue = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        XCTAssertEqual(cue.position.x, 685, accuracy: 0.001)
        XCTAssertEqual(cue.position.y, 235, accuracy: 0.001)
        XCTAssertFalse(cue.hasActions())
        XCTAssertTrue(cue.children.allSatisfy { !$0.hasActions() })
        XCTAssertNotEqual(
            scene.targetName(at: cue.position),
            "decorativeAttentionCue",
            "A visual hint must never steal a gameplay tap."
        )

        scene.valkyrie.position = CGPoint(x: 565, y: 185)
        scene.handleTap(at: CGPoint(x: 685, y: 235))
        cue = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        XCTAssertEqual(cue.position.x, 430, accuracy: 0.001)
        XCTAssertEqual(cue.position.y, 220, accuracy: 0.001)

        scene.valkyrie.position = CGPoint(x: 500, y: 180)
        scene.handleTap(at: CGPoint(x: 430, y: 220))
        cue = try XCTUnwrap(scene.childNode(withName: "decorativeAttentionCue"))
        XCTAssertEqual(cue.position.x, 940, accuracy: 0.001)
        XCTAssertEqual(cue.position.y, 245, accuracy: 0.001)
    }

}
