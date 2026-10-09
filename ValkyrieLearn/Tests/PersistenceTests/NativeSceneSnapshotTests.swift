import XCTest
import SpriteKit
import SwiftData
import SnapshotTesting
import LearningCore
@testable import ValkyrieLearn

/// Stable, versioned snapshots of the actual 4:3 native SpriteKit scene tree.
///
/// These are intentionally *structural* baselines: they enforce the physical
/// affordance contract without comparing simulator-OS-dependent image pixels.
/// Golden-master pixel snapshots are available as an explicit opt-in, but are
/// not recorded or auto-approved by CI.
@MainActor final class NativeSceneSnapshotTests: XCTestCase {
    private func makeView() -> (UIWindow, SKView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1024, height: 768))
        let controller = UIViewController()
        let view = SKView(frame: window.bounds)
        controller.view = view
        window.rootViewController = controller
        window.makeKeyAndVisible()
        return (window, view)
    }

    private func freshState() throws -> AppState {
        try AppState(context: ModelContext(LearningStore.container(inMemory: true)))
    }

    private func unlockRuneGate(in state: AppState) {
        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            _ = state.recordPuzzle(
                encounter,
                outcome: .correct,
                support: .independent,
                attempts: 1,
                responseTime: 1
            )
        }
    }

    func testOpenedRuneGateFourByThreeVisualContract() throws {
        let (window, view) = makeView()
        let state = try freshState()
        state.reducedMotion = true
        unlockRuneGate(in: state)
        state.travel(to: .puzzlePalace)

        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        XCTAssertEqual(scene.size, CGSize(width: 1280, height: 960))
        let doorway = scene.childNode(withName: "runeDoorPassage")
        let interior = scene.childNode(withName: "//runeDoorOpenInterior")
        let redundantDais = scene.childNode(withName: "puzzleStageDais")
        let signature = [
            "room=rune-gate-open",
            "painting=\(scene.childNode(withName: "puzzleIllustratedBackdrop") == nil ? "missing" : "present")",
            "door-passage=\(doorway == nil ? "missing" : "present")",
            "open-interior=\((interior != nil && !interior!.isHidden && interior!.alpha == 1) ? "visible" : "hidden")",
            "next-route=\(scene.childNode(withName: "memoryBridgeRoute") == nil ? "missing" : "present")",
            "duplicate-room-hidden=\(redundantDais?.isHidden ?? true)"
        ].joined(separator: "\n")
        assertSnapshot(of: signature, as: .lines, named: "open-gate")
    }

    func testMemoryBridgePadsStayAboveSceneryAndTouchable() throws {
        let (window, view) = makeView()
        let state = try freshState()
        state.reducedMotion = true
        unlockRuneGate(in: state)
        state.travel(to: .memoryBridge)
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        view.presentScene(scene)
        defer {
            scene.willLeave()
            view.presentScene(nil)
            window.isHidden = true
        }

        XCTAssertEqual(scene.size, CGSize(width: 1280, height: 960))
        let encounter = try XCTUnwrap(state.nextPuzzleMemoryEncounter())
        let chasm = try XCTUnwrap(scene.childNode(withName: "memoryChasm"))
        let pads = scene.children.filter { $0.name == "memoryPad" }
        XCTAssertEqual(pads.count, encounter.choices.count)

        var signature = [
            "room=memory-bridge",
            "painting=\(scene.childNode(withName: "puzzleIllustratedBackdrop") == nil ? "missing" : "present")",
            "chasm=present",
            "pad-count=\(pads.count)"
        ]
        for symbol in encounter.choices {
            let pad = try XCTUnwrap(pads.first {
                ($0.userData?["symbol"] as? String) == symbol
            })
            let controlName = ["★": "star", "☾": "moon", "◆": "diamond", "●": "circle"][symbol]
                ?? "unknown"
            let accessible = pad.isAccessibilityElement
                && pad.accessibilityLabel == "Memory rune: \(controlName)"
            let front = pad.zPosition > chasm.zPosition
            let touchable = scene.targetName(at: pad.position) == "memoryPad"
            signature.append(
                "\(controlName): front=\(front), tap=\(touchable), accessible=\(accessible)"
            )
        }
        assertSnapshot(of: signature.joined(separator: "\n"), as: .lines, named: "rune-pads")
    }

    func testSortingRoomsHaveGroundedStoneAlcovesInsteadOfPurpleButtons() throws {
        let (window, view) = makeView()
        let state = try freshState()
        state.reducedMotion = true
        defer { view.presentScene(nil); window.isHidden = true }

        let cases: [(AppState.World, [String], String)] = [
            (.sortingPedestal, ["sortLeftPedestal", "sortRightPedestal"], "sortingRuleDial"),
            (.resortVault, ["resortLeftPedestal", "resortRightPedestal"], "resortRuleDial")
        ]
        for (world, names, dialName) in cases {
            state.travel(to: world)
            let scene = PuzzlePalaceScene(state: state)
            scene.reducedMotion = true
            view.presentScene(scene)

            for name in names {
                let alcove = try XCTUnwrap(scene.childNode(withName: name))
                XCTAssertTrue(alcove.isAccessibilityElement,
                              "Grounded alcoves must retain child-accessible touch labels.")
                let masonry = alcove.children.compactMap { $0 as? SKShapeNode }
                    .filter { $0.name == name && $0.fillTexture != nil }
                XCTAssertGreaterThanOrEqual(masonry.count, 3,
                             "A physical bowl, connected pillar and foot must share carved materials.")
                XCTAssertNotNil(alcove.childNode(withName: name + "Glyph"),
                                "The sort rule must still identify each receiving alcove.")
            }

            let dial = try XCTUnwrap(
                scene.childNode(withName: dialName) as? SKShapeNode
            )
            XCTAssertNotNil(dial.fillTexture)
            XCTAssertLessThan(dial.frame.height, 90,
                              "The rule should be a compact stone plaque, not a giant floating disk.")
            scene.willLeave()
        }
    }

    func testOptionalPixelGoldenMasterRecording() throws {
        // Never accept machine-generated visual goldens without owner review.
        // Enable for a *local*, deliberate golden-master recording session:
        // VALKYRIE_RECORD_VISUAL_GOLDENS=1 SNAPSHOT_TESTING_RECORD=all
        guard ProcessInfo.processInfo.environment["VALKYRIE_RECORD_VISUAL_GOLDENS"] == "1" else {
            throw XCTSkip("Pixel-level goldens need reviewed 4:3 reference images.")
        }
        let state = try freshState()
        state.reducedMotion = true
        unlockRuneGate(in: state)
        state.travel(to: .puzzlePalace)
        let scene = PuzzlePalaceScene(state: state)
        scene.reducedMotion = true
        assertSnapshot(
            of: scene as SKScene,
            as: .image(
                precision: 0.99,
                perceptualPrecision: 0.99,
                size: CGSize(width: 1024, height: 768)
            ),
            named: "owner-reviewed-open-gate",
            timeout: 15
        )
    }
}
