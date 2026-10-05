import XCTest
import SwiftData
import SpriteKit
import LearningCore
@testable import ValkyrieLearn

@MainActor final class NativeArtTests: XCTestCase {
    func testApprovedArtIsPackagedAndEveryActorPoseResolves() async throws {
        for name in ["StarlightIsles", "MathCastle", "CrystalCart", "Crystal", "IslesForegroundLeft", "CastleForegroundRight", "BridgeOakPlank", "BridgeGreenPlank", "BridgeTimber", "BridgeWorkOrder", "BridgeChannel", "BridgeDial", "V331WorldAtlas", "Lumi"] {
            XCTAssertNotNil(ArtSystem.texture(name), "Missing bundled image: \(name)")
        }
        for character in ["Valkyrie", "Pip"] {
            for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
                XCTAssertFalse(ArtSystem.frames(character: character, pose: pose).isEmpty, "Missing \(character) \(pose)")
            }
        }
        XCTAssertEqual(ArtSystem.frames(character: "Valkyrie", pose: .walk).count, 2)
        for pose in [ArtSystem.Pose.idle, .walk, .interact, .celebrate, .react] {
            XCTAssertFalse(ArtSystem.frames(character: "Lumi", pose: pose).isEmpty)
        }
        let lumi = LumiNode()
        lumi.pose(.interact)
        XCTAssertFalse(lumi.bodyNode.children.compactMap { $0 as? SKSpriteNode }.first?.isHidden ?? true)
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
        let scene = MathCastleScene(state: state); scene.didMove(to: SKView())
        scene.update(0) // Exercise real actor depth, not the initial z = 0 state.
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 390, y: 605)), "wind")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 52, y: 669)), "home")
        XCTAssertEqual(scene.targetName(at: CGPoint(x: 595, y: 235)), "supply")
        XCTAssertTrue(scene.childNode(withName: "next")?.isHidden == false) // Free workshop exit.
        scene.valkyrie.position = CGPoint(x: 490, y: 175)
        scene.handleTap(at: CGPoint(x: 830, y: 265))
        let target = try XCTUnwrap(state.runtime?.encounter.targetQuantity)
        for _ in 0..<target { scene.handleTap(at: CGPoint(x: 595, y: 235)) }
        scene.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(state.runtime?.completed == true)
        let powerLight = try XCTUnwrap(scene.childNode(withName: "castlePowerLight") as? SKShapeNode)
        XCTAssertEqual(powerLight.glowWidth, 16)
        let portal = try XCTUnwrap(scene.childNode(withName: "challengeGate") as? SKShapeNode)
        XCTAssertEqual(portal.glowWidth, 4, "Ordinary work powers the castle route but must not fake Challenge Gate readiness.")
        scene.willLeave()
    }

    func testStoryTreeIgnoresTheChasmAndRoutesCastleEntryThroughThePaintedPath() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))
        let scene = StoryTreeScene(state: state); scene.didMove(to: SKView())
        XCTAssertFalse(scene.isOnPath(CGPoint(x: 1000, y: 200)))
        scene.handleTap(at: CGPoint(x: 1000, y: 200))
        XCTAssertNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertTrue(scene.isOnPath(CGPoint(x: 285, y: 235)))
        scene.handleTap(at: CGPoint(x: 795, y: 445))
        XCTAssertNotNil(scene.valkyrie.action(forKey: "travel"))
        XCTAssertEqual(state.world, .storyTree)
        scene.valkyrie.cancelTravel(); scene.pip.cancelTravel()
        scene.valkyrie.position = CGPoint(x: 795, y: 450)
        scene.update(0)
        let sign = try XCTUnwrap(scene.childNode(withName: "castle"))
        XCTAssertLessThan(sign.zPosition, scene.valkyrie.zPosition)
        scene.handleTap(at: CGPoint(x: 795, y: 445))
        XCTAssertEqual(state.world, .mathCastle)
        scene.willLeave()
    }

    func testWordGardenFlowerGateUnlocksNativeSunmillCrossing() async throws {
        let state = try AppState(context: ModelContext(try LearningStore.container(inMemory: true)))

        let story = StoryTreeScene(state: state)
        story.didMove(to: SKView())
        story.valkyrie.position = CGPoint(x: 190, y: 170)
        story.handleTap(at: CGPoint(x: 205, y: 165))
        XCTAssertEqual(state.world, .wordGarden)
        story.willLeave()

        state.travel(to: .wordGarden)
        let flower = WordGardenScene(state: state)
        flower.didMove(to: SKView())
        XCTAssertNotNil(flower.childNode(withName: "flowerGate"))
        XCTAssertNotNil(flower.childNode(withName: "questionPrompt"))
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
        XCTAssertNotNil(sunmill.childNode(withName: "sunmillWater"))
        XCTAssertTrue(sunmill.childNode(withName: "sunmillBridge")?.isHidden == true)
        XCTAssertEqual(sunmill.children.filter { $0.name == "sunmillChoice" }.count, 4)
        XCTAssertEqual(
            state.nextSunmillEncounter()?.skillID,
            LiteracySkills.visualCasePairing
        )
        sunmill.handleTap(at: CGPoint(x: 1110, y: 665))
        XCTAssertEqual(state.world, .wordGarden)
        sunmill.willLeave()
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
        home.handleTap(at: CGPoint(x: 795, y: 445))
        // Exercise the painted waypoint route before the arrival capture.
        try await Task.sleep(nanoseconds: 3_000_000_000)
        XCTAssertTrue(home.isNear(CGPoint(x: 795, y: 450)))
        try await capture(home, in: view, name: "Story-Tree-native-castle-arrival")
        home.willLeave()

        state.travel(to: .wordGarden)
        let flower = WordGardenScene(state: state); flower.reducedMotion = true
        view.presentScene(flower)
        try await capture(flower, in: view, name: "Word-Garden-native-flower-gate")
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
        state.travel(to: .sunmillCrossing)
        let sunmill = WordGardenScene(state: state); sunmill.reducedMotion = true
        view.presentScene(sunmill)
        try await capture(sunmill, in: view, name: "Word-Garden-native-sunmill")
        sunmill.willLeave()

        for encounter in WordGardenEncounterCatalog.visualCasePairs {
            _ = state.recordLiteracy(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
        let awakeSunmill = WordGardenScene(state: state); awakeSunmill.reducedMotion = true
        view.presentScene(awakeSunmill)
        try await capture(awakeSunmill, in: view, name: "Word-Garden-native-sunmill-awake")
        XCTAssertFalse(awakeSunmill.childNode(withName: "sunmillBridge")?.isHidden ?? true)
        awakeSunmill.willLeave()

        state.travel(to: .mathCastle)
        XCTAssertTrue(state.startWorkshop(MathFoundation.workshopExamples[0]))
        let castle = MathCastleScene(state: state); castle.reducedMotion = true
        view.presentScene(castle)
        castle.valkyrie.position = CGPoint(x: 490, y: 175); castle.pip.position = CGPoint(x: 385, y: 187)
        castle.handleTap(at: CGPoint(x: 830, y: 265))
        try await capture(castle, in: view, name: "Math-Castle-native-cart")
        for _ in 0..<(state.runtime?.encounter.targetQuantity ?? 0) { castle.handleTap(at: CGPoint(x: 595, y: 235)) }
        castle.handleTap(at: CGPoint(x: 1120, y: 250))
        try await capture(castle, in: view, name: "Math-Castle-native-powered")
        castle.willLeave()
        XCTAssertTrue(state.startWorkshop(MathCastleEncounterCatalog.missingNumberBridge[0]))
        let bridge = MathCastleScene(state: state); bridge.reducedMotion = true
        view.presentScene(bridge)
        bridge.valkyrie.position = CGPoint(x: 490, y: 175)
        bridge.handleTap(at: CGPoint(x: 965, y: 330))
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-gaps")
        for _ in 0..<4 { bridge.drop(origin: "missingSupply", at: CGPoint(x: 884, y: 220)) }
        bridge.handleTap(at: CGPoint(x: 1120, y: 250))
        XCTAssertTrue(state.runtime?.completed == true)
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-repaired")
        let repairedID = state.runtime?.encounter.id
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        bridge.handleTap(at: CGPoint(x: 1200, y: 430)) // Ignore repeated taps in transit.
        XCTAssertEqual(state.runtime?.encounter.id, repairedID)
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 1110, y: 400), radius: 55))
        XCTAssertGreaterThan(bridge.pip.position.x, 1000)
        XCTAssertGreaterThan(bridge.pip.position.y, 240)
        XCTAssertEqual(state.runtime?.encounter.id, repairedID, "Arrival must preserve the solved bridge")
        try await capture(bridge, in: view, name: "Math-Castle-native-bridge-landing")
        bridge.handleTap(at: CGPoint(x: 1200, y: 430))
        XCTAssertTrue(bridge.crossingBridge)
        XCTAssertEqual(state.runtime?.encounter.id, repairedID, "Keep the deck beneath the actors during the return")
        try await waitForBridgeTravel(bridge)
        XCTAssertTrue(bridge.isNear(CGPoint(x: 490, y: 175)))
        XCTAssertNotEqual(state.runtime?.encounter.id, repairedID)
        bridge.willLeave()
    }

    private func waitForBridgeTravel(_ scene: MathCastleScene) async throws {
        let deadline = Date().addingTimeInterval(10)
        while scene.crossingBridge && Date() < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertFalse(scene.crossingBridge, "Bridge route did not finish within ten seconds")
    }

    private func capture(_ scene: AdventureScene, in view: SKView, name: String) async throws {
        // Let SpriteKit render an actual frame on the simulator, not a mock composition.
        try await Task.sleep(nanoseconds: 300_000_000)
        let texture = try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: scene.size)))
        let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
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
        let feedback = try XCTUnwrap(scene.childNode(withName: "feedbackText") as? SKLabelNode)

        XCTAssertFalse(prompt.isHidden)
        XCTAssertTrue(prompt.text?.contains(encounter.prompt) == true)
        XCTAssertGreaterThan(prompt.position.y, 500)
        XCTAssertLessThan(feedback.position.y, 100)
        XCTAssertGreaterThan(prompt.position.y, feedback.position.y)

        scene.willLeave()
    }

}
