# Native scene regression tests and image-golden review

ValkyrieLearn remains a native Swift/SpriteKit iPad adventure. This tooling does not switch engines, replace approved painting, change the canonical character, add analytics, or alter the offline learning engine.

## Automatically checked

The PersistenceTests target imports [pointfreeco/swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) version 1.19.6, pinned in the deterministic Xcode project generator. The shipping ValkyrieLearn target does not link SnapshotTesting.

NativeSceneSnapshotTests.swift presents the actual PuzzlePalaceScene on a 1024 x 768 iPad simulator view (design canvas 1280 x 960). Its version-controlled **text** snapshots verify:

- Open Rune Gate: approved painting is installed, physical door passage appears on restore, unlocked route exists, and duplicate synthetic scenery is hidden.
- Memory Bridge: four rune controls are above the bridge masonry, win the hit test, and retain spoken accessibility labels.

These are structural scene-tree baselines, not pixel-diff screenshots. The .txt files live under __Snapshots__/NativeSceneSnapshotTests/ beside the tests. A regression fails CI with a readable text diff. This specifically protects the scenery occlusion fixed in PR #153.

Run the existing Native foundation GitHub Actions workflow or the simulator command:

    xcodebuild test -project ValkyrieLearn.xcodeproj -scheme ValkyrieLearn \
      -destination 'platform=iOS Simulator,name=iPad (9th generation)' \
      CODE_SIGNING_ALLOWED=NO

The first package resolution downloads the test package. scripts/generate_xcode_project.py is authoritative for file and package references. After adding/removing native Swift sources, regenerate the project; scripts/validate_native.py checks determinism.

## Pixel-perfect references require owner approval

The optional testOptionalPixelGoldenMasterRecording uses SnapshotTesting's actual SKScene image strategy, but skips normally. To capture a candidate, run that one test locally on the designated simulator with test-process environment variables:

- VALKYRIE_RECORD_VISUAL_GOLDENS=1
- SNAPSHOT_TESTING_RECORD=all

Review the emitted __Snapshots__/NativeSceneSnapshotTests/*.png against approved native 4:3 compositions. Only commit owner-reviewed reference images. Clear the recording environment variables and rerun to enforce the baseline later. Never automatically record new goldens in CI.

Image diffs can vary across iOS/Simulator versions. Pin the simulator and visually inspect real image diffs before adjusting tolerances. A simulator snapshot is not physical iPad acceptance.

## Guardrails

- Keep SnapshotTesting out of the shipping app and the plain-Swift learning engine.
- Use real AppState and PuzzlePalaceScene, not mocked-up screenshots.
- Never "fix" a regression by auto-updating image baselines.
- Keep the existing scene screenshot exports, navigation tests and learning-evidence tests.
- Physical iPad acceptance, educator review of the 76 Math skills, and approved Retina artwork remain separate release gates.
