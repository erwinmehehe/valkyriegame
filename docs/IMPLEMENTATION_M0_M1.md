# Native foundation implementation — Milestones 0–1

## Audit and scope

Baseline main commit: `1bca669d6736c4810e53bd1cfa487625f8232992`.
The repository contained seven production planning documents plus `index.html`, and no native project.
All seven documents were read before implementation; the prototype was inspected and remains byte-for-byte unchanged.

This pass implements the Phase 0–1 **engineering foundation** plus the requested first learning-core/cart slice.
It does not declare Phase 0–1 on-device acceptance complete, or claim the larger Milestone A vertical slice is done.
There is no hidden placement, five-mechanic suite, Challenge Gate, reward system or parent reporting yet.

## Created files

- `ValkyrieLearn.xcodeproj/project.pbxproj` and shared `ValkyrieLearn` scheme: iPad app, LearningCoreTests and hosted PersistenceTests targets; local LearningCore package.
- `Package.swift`: Apple-framework-independent LearningCore library and XCTest target.
- `ValkyrieLearn/App/`: SwiftUI entry, recoverable save-open errors and AppState orchestration.
- `ValkyrieLearn/Game/GameContainerView.swift`: aspect-fit landscape SpriteKit container and settings presentation.
- `ValkyrieLearn/Game/Scenes/`: common layered scene, Story Tree home and Math Castle room.
- `ValkyrieLearn/Game/Actors/`: Valkyrie and Pip with placeholder idle/walk/interact/celebrate/react motion.
- `ValkyrieLearn/Game/Mechanics/CrystalCartMechanic.swift`: physical cart/crystal nodes.
- `ValkyrieLearn/Game/Systems/`: atlas-replacement boundary and channel-based AVFoundation audio.
- `ValkyrieLearn/Learning/`: requested model types, prerequisite graph, adaptive selector, mastery, review, scaffolding, engagement and reusable cart model.
- `ValkyrieLearn/Curriculum/Math/MathFoundation.swift`: nine skills with explicit prerequisites and fourteen small authored cart encounters.
- `ValkyrieLearn/Parent/AdventureSettingsView.swift`: settings only, not a parent dashboard.
- `ValkyrieLearn/Persistence/LearningStore.swift`: explicit V1 SwiftData schema/migration boundary, profile/evidence, active cart, world and settings.
- `ValkyrieLearn/Resources/`: landscape Info.plist, four temporary SFX WAVs and atlas naming guide.
- `ValkyrieLearn/Tests/`: 15 plain-Swift XCTest cases and 3 Apple-platform persistence/AppState cases.
- `scripts/`: deterministic checked-in Xcode project generator and static integrity validator.
- `.github/workflows/native.yml`: learning-core and macOS iPad Simulator build/test jobs.
- `.gitignore` and this implementation report.

## Changed files

`README.md` gains the actual native source/build status and links to this report. The product, architecture, learning, game design, migration and roadmap policies remain intact. `index.html` is unchanged.

## Architecture

`MathCastleScene → AppState → AdaptiveDirector → LearningEncounter → CrystalCartModel → LearningEvidence → MasteryEngine → LearnerProfile → LearningStore`.

LearningCore imports Foundation only. It can be compiled and tested without SpriteKit/SwiftUI/SwiftData.
Scenes render and route touch input; they do not decide mastery or prerequisite policy.
CrystalCartModel supports counting, addition and missing addends. Future operation identifiers exist,
but unsupported subtraction/bonds/comparison/equal-groups operations explicitly fail rather than pretending to work.

Evidence preserves outcome, support, attempts, representation, timing, transfer and encounter identity.
A first success means Learning. Developing requires at least two independent distinct successes;
Secure requires at least three. Mastered requires six independent distinct successes, at least three
representations, at least seven days of separation and transfer evidence. Those are provisional,
tested foundation rules, not a curriculum validation claim. Supported work has lower weight.
Two recent incorrect attempts demote to Learning. Secure/Mastered have scheduled reviews.

The engagement foundation remembers used mathematical fingerprints and recent skill/representation combinations.
It excludes identical math even if wording or skill tags change, blocks a third consecutive use of a mechanic,
requests deeper content after three easy successes, and another representation after two meaningful struggles.
After three minutes it requests a world-change beat. With one mechanic or insufficient content it returns
an explicit exploration/content-needed result; it never silently repeats an exhausted question.
The 60/20/15/5 session policy and full placement system remain future work.

## Native interaction path implemented in source

1. Story Tree: tap the path; Valkyrie walks, with Pip following and world-space depth sorting.
2. Tap the Math Castle sign to approach, then tap again to enter.
3. Tap the cart to approach, then tap again to engage it.
4. Drag a crystal from the source crate into the cart, or tap the source crystal once per addition.
5. Drag a movable cart crystal back to the crate, or tap it to remove. Starting purple crystals remain fixed.
6. Tap Pip's lever to submit. Correct totals power the lift; incorrect totals invite scaffolding.
7. Pip is in-scene and operates the mechanism. Asking him escalates light cue → stronger cue → demonstrated step.
8. Choose a fresh eligible order, wind Pip's gear as a non-academic interaction, or return home.
9. After completing an order, the three workshop stations expose the exact counting 7,
   addition 4+3 and missing-addend 6-to-10 examples as **unscored** sandbox practice. They
   never award evidence for locked skills. Active scored work isn't silently discarded.
10. Settings, profile/evidence, in-progress cart/support and last world are saved locally.

Valkyrie is ~205 points tall in a 1280×720 world; visible movement, interaction, reaction and celebration
are placeholder motion, not completed production animation. Foreground pillars, the player/companion,
cart, midground floor/path and distant castle towers establish the required layered composition.
ArtSystem supports replacing labeled temporary shapes with named sprite atlas frames.
Reduced motion removes bounce/pose loops and retains a short spatial move; essential drag interactions have tap alternatives.

## Validation actually performed here

Environment: Linux, no Xcode/iOS SDK or connected iPad.
Swift 6.0.3 Linux was temporarily installed for actual compilation/testing.

- LearningCore and both core XCTest source files compiled and linked with `swift test -j 1`.
- The generated XCTest binary was executed directly: **15 tests, zero failures, process exit 0**.
- SwiftPM's wrapper itself hit an environment process-stat crash during test launching. Direct execution
  avoided that wrapper issue; we do not report the wrapper command as a clean test pass.
- `swiftc -frontend -parse` passed for all app, SpriteKit, settings, SwiftData and Apple-test sources.
  Parsing is syntax validation only, not Apple API type checking.
- `python3 scripts/validate_native.py` passed: reproducible project, file/ID references, scheme targets,
  iPad-only/landscape configuration, learning-module separation and prototype preservation.
- `git diff --check` passed.

**Actual Xcode app build, SwiftData macros/integration tests, simulator launch and physical iPad gameplay are NOT yet verified locally.**
CI is supplied to run the Apple build/test gate. Its observed result must be checked before calling this an installable build.
No IPA or TestFlight release is claimed.

## Exact Mac verification

Requirements: macOS with Xcode 16+ and an iPad Simulator runtime; iPadOS 17+ device for on-device validation.

```sh
git clone https://github.com/erwinmehehe/valkyriegame.git
cd valkyriegame
git checkout native/milestone-0-1
python3 scripts/validate_native.py
swift test
xcodebuild -list -project ValkyrieLearn.xcodeproj
xcrun simctl list devices available
# Replace the destination with an installed iPad simulator name or UDID.
xcodebuild test -project ValkyrieLearn.xcodeproj -scheme ValkyrieLearn \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -resultBundlePath NativeTests.xcresult CODE_SIGNING_ALLOWED=NO
open ValkyrieLearn.xcodeproj
```

In Xcode, select the app target, set your signing Team and a unique bundle ID if needed,
select the intended physical iPad, and Run. Team/signing credentials are deliberately not committed.

Verify both landscape directions; Story Tree entry/return; cart approach/interaction lock; all three workshop modes;
wrong totals and hint escalation; drag cancellation and multi-touch; tap alternatives; foreground occlusion;
reduced motion; sound off/interruption/background; partial cart and profile restore after force quit;
no progress lost on save errors; a normal 15-minute session without crashes. Final art/touch pacing
still needs child/device review. The current audio policy stops interrupted audio; automatic music resume is later work.

## Exact next implementation milestone

First clear the Mac/iPad build and interaction gates above. Then implement **hidden adaptive Math placement**
and expand from Crystal Cart to **3–5 reusable Math mechanics**, with authored alternate representations and
challenge depth so the existing director can respond to readiness/struggle without running out of content.
Follow with mastery/review/scaffolding refinement and Challenge Gate, then Story Tree rewards and parent Math summary.
Do not expand worlds or Chapter 2 in that next pass.
