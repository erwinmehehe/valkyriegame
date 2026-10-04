# Native foundation implementation — Milestones 0–1

## Current follow-on status — October 4, 2026

This file began as the Milestones 0–1 implementation report. Treat the early sections below as historical evidence of what the foundation pass contained, not as the current feature inventory.

Current repository progression:

- PR #1 native foundation — merged to `main`
- PR #2 hidden adaptive Math placement — merged to `main`
- PR #3 Math Skill Graph v2 — merged to `main`
- PR #4 adaptive 60/20/15/5 session planner — merged to `main`
- PR #5 reusable five-mechanic Math layer — open against `main`
- PR #6 live Math Castle integration — stacked on PR #5
- PR #7 Challenge Gate + persistent Moon Lantern Story Tree reward — stacked on PR #6
- PR #8 parent-facing adaptive Math dashboard — stacked on PR #7

The current vertical-slice stack therefore includes hidden placement, the 73-skill Math graph, mastery/review/scaffolding, adaptive session planning, five reusable mechanics, Challenge Gate, persistent Story Tree reward state, and parent Math reporting.

**Merge order is PR #5 → PR #6 → PR #7 → PR #8.** Do not flatten or merge a later stacked PR before its base unless the stack is deliberately rebased first.

**Current acceptance gate:** finish CI for the stack, merge in order, then validate the complete experience on the intended physical iPad. Do not begin Puzzle Palace v2, Word Garden v2, Science Lab v2, Chapter 2, or major new-world expansion until the native Adaptive Math Castle vertical slice is genuinely good on-device.

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
- `ValkyrieLearn/Tests/`: 15 plain-Swift XCTest cases and 5 Apple-platform persistence/AppState cases.
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
   never award evidence for locked skills. Workshop use still records activity history and obeys exact-repeat/mechanic limits. Active scored work isn't silently discarded.
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

## Apple CI verification

Native code commit: `f2670d1d3f49441a3686dfe76dc8d21fee5d8058`.
[Successful run 37190988268](https://github.com/erwinmehehe/valkyriegame/actions/runs/37190988268).

- Linux CI: clean `swift test -j 2` pass (15 tests).
- macOS CI: clean `swift test` pass (15 tests).
- Xcode 16.4 (16F6), arm64 iPad Pro 11-inch (M4) Simulator, iOS 18.5: native app and test targets compiled; `xcodebuild test` **TEST SUCCEEDED**.
- Native simulator suites: **20 tests, zero failures** (15 learning/core/cart, 5 SwiftData/AppState).
- SwiftData schema/macros and hosted AppState persistence tests are therefore Apple-platform verified.
- Initial Apple runs caught checkout-dependent project IDs, simulator architecture mismatch, missing SKNode initializer override and a non-public scaffold constructor. All were fixed before the successful run.

The local environment still has no Xcode, but the remote Mac/iPad Simulator gate actually ran and passed.
**Physical iPad installation, touch gameplay, force-quit disk persistence, audio interruption/device performance and production art remain unverified.**
Simulator unit tests do not prove a child can play the full interaction path. No IPA or TestFlight release is claimed.

## Additional source review

One requested sub-agent reviewed native gameplay and persistence. Four concrete findings were fixed: general drag-release hotspot activation, stalled demonstration after crystal overshoot, invisible fallback characters with partial atlases, and stale Pip operation timers. A hosted AppState regression test checks demonstrated removal and persisted support attribution.

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
  -destination 'platform=iOS Simulator,name=iPad Pro 11-inch (M4),OS=18.5' \
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

## Current next implementation milestone

The earlier "build hidden placement and 3–5 reusable Math mechanics" milestone has been implemented in the follow-on PR stack described at the top of this file.

The next release gate is now **device validation and stack integration**, not another major feature expansion:

1. merge PR #5 → PR #6 → PR #7 → PR #8 in order after their required checks pass
2. run the full adaptive Math Castle flow on the intended physical iPad
3. verify touch targets, drag/tap alternatives, orientation, performance, sound interruption, force-quit persistence, reduced motion, and readability
4. observe the child using hidden placement, all five mechanics, scaffolding, Challenge Gate, Story Tree reward interaction, and natural stopping points
5. fix any usability or boredom failures found on-device before calling Milestone A accepted

Only after that acceptance gate should Phase 12+ world expansion begin.
