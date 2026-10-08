# Native iPad build and device acceptance

`main` is the canonical integration branch for the current native iPad build.
The HTML prototype remains reference material only. A vertical slice is not accepted
until it has been exercised on a physical iPad.

Production remains Swift, SpriteKit, SwiftUI, SwiftData and AVFoundation. The
current CI can validate the learning core and native project, run the iPad Simulator
test suite, export scene-review images, and package an unsigned Simulator `.app`
for browser-streaming or other Simulator-only review.

## Build current main

Use a Mac with Xcode 16 or newer, an installed iPad Simulator runtime and Python 3.
Use an iPad running iPadOS 17 or newer for the physical-device check.

```sh
git clone https://github.com/erwinmehehe/valkyriegame.git
cd valkyriegame
git switch main
git pull --ff-only
git rev-parse HEAD
python3 scripts/validate_native.py
swift test
xcodebuild -list -project ValkyrieLearn.xcodeproj
xcrun simctl list devices available
```

Record the checkout SHA with every acceptance result. Do not test an older feature
branch or an HTML download and call it native acceptance.

## GitHub Actions review artifacts

The **Native foundation** workflow is the automated pre-device gate. A healthy run
should complete:

- `learning-core`
- `native-validation`
- `ipad-build-and-tests`

The workflow also publishes review artifacts when available:

- `native-scene-preview` — compact visual review images
- `native-scene-review` — exported native test attachments
- `valkyrie-native-simulator-app` — `ValkyrieLearn-simulator.zip`, an unsigned
  iOS Simulator app for browser-streaming or Simulator-only testing

The Simulator app is not a signed physical-iPad build and does not replace the
device acceptance pass below.

## Run locally in an iPad Simulator

Select an available iPad simulator UUID, then run:

```sh
xcodebuild test -project ValkyrieLearn.xcodeproj -scheme ValkyrieLearn \
  -destination 'platform=iOS Simulator,id=REPLACE_WITH_IPAD_SIMULATOR_UUID' \
  -resultBundlePath DeviceAcceptance.xcresult CODE_SIGNING_ALLOWED=NO
xcrun xcresulttool export attachments --path DeviceAcceptance.xcresult \
  --output-path device-acceptance-scenes
open ValkyrieLearn.xcodeproj
```

Use a new result-bundle path if one already exists. Simulator success is a useful
gate, but it does not prove physical touch behavior, device performance, signing,
rotation behavior, or real save/restore behavior on the target iPad.

## Install on the iPad from Xcode

1. Connect the iPad to the Mac, unlock it and trust the Mac if prompted.
2. Enable Developer Mode on the iPad if Xcode requests it.
3. In Xcode, select the **ValkyrieLearn** scheme and the connected iPad destination.
4. Select the app target, then **Signing & Capabilities**. Choose your development
   Team and leave automatic signing enabled. If the default bundle identifier
   `com.valkyrielearn.ValkyrieLearn` is unavailable, use an identifier owned by
   your Team. Keep it stable between test installs so the same local save can be
   tested across builds.
5. Run with **Product -> Run**. Follow any development certificate trust prompt on
   the iPad. Confirm the app launches and remains usable in landscape.

No signing credentials or provisioning profiles are committed. Do not delete the
installed app between save/restore or upgrade checks. Installing from Xcode is
different from publishing through TestFlight.

## Fifteen-minute acceptance session

Record device model, iPadOS version, checkout SHA, time, and pass/fail observations.
The times below are a suggested test order, not timers imposed on the child.

| Time | Action | Expected behavior |
| --- | --- | --- |
| 0–2 min | Open Story Tree; tap a destination once; try another destination during travel; tap empty sky/chasm. | Valkyrie and the active companion remain visible, follow valid painted routes, and enter the selected world on arrival. Repeated destination taps do not restart the journey. A new valid destination redirects travel and void taps are ignored. |
| 2–4 min | Enter Math Castle; approach the active object, then manipulate it. | The first distant tap moves Valkyrie; interaction requires arrival. Learning content remains readable and visually attached to the world object. |
| 4–6 min | Tap/drag crystals or another direct-manipulation mechanic; overshoot then correct; try an incorrect answer. | Quantities respond once per action and can be corrected. No duplicate credit, shaming, or accidental hotspot activation occurs on drag release. |
| 6–8 min | Ask in-scene Pip for successive hints; complete the task with support. | Support escalates meaningfully and persists. Assisted completion is recorded differently from independent mastery evidence. |
| 8–10 min | Advance through available Math mechanics and use a non-academic interaction. | The mechanic changes rather than repeating one surface indefinitely. Ordinary success advances the world without falsely claiming Challenge Gate readiness. |
| 10–12 min | Return to Story Tree; open Settings -> Math progress; inspect the parent summary. | The summary reports evidence-backed skills. Unanswered or unscored interactions do not create false recent learning. |
| 12–15 min | Leave an object partially manipulated; background the app; force-quit; relaunch. Repeat once in airplane mode. | World state, quantity, support, learner profile, and completed/pending order restore without duplicate evidence or network dependency. |

During the same pass:

- rotate between both landscape directions
- enable and disable Reduced Motion while a scene is active
- test large touch targets and non-drag alternatives
- try a second finger during a drag
- rapidly tap the same destination or interaction
- background and foreground during motion and during feedback
- watch for clipped text, confusing paths, visible stalls, stretched artwork,
  missed taps, camera jumps, duplicated rewards, or frame-rate drops

## Persistent reward and Challenge Gate check

On a profile that genuinely has two Secure source skills, verify the optional
Challenge Gate opens prerequisite-safe challenges across different mechanics.
Provisional placement readiness alone must not open it. Ordinary Math play must
remain available without the gate.

Complete the gate, return to Story Tree, and move the Moon Lantern among its branch
slots. Force-quit and reopen: the earned lantern and chosen branch must remain.

If the profile is not yet ready during the fifteen-minute session, record this as
**not exercised** rather than changing mastery data just to make the gate appear.

## Cross-world smoke check

The current native build also contains Word Garden, Puzzle Palace and Science Lab
work. These do not replace the Math Castle milestone, but each should receive a
short smoke test before a release candidate:

- enter and exit the world without navigation dead ends
- complete at least one authored encounter
- verify the companion remains readable and correctly grounded
- test an incorrect response and recovery
- verify Reduced Motion does not remove required interaction
- return to Story Tree and confirm progress remains intact

Do not turn this smoke check into a reason to expand scope before the Math Castle
vertical slice is accepted.

## Audio and visual limits

Sound on/off and interruption handling must remain safe. The bundle contains basic
effect audio, but finished narration, instructional phoneme recordings, full world
ambience/music, and complete authored character animation sets remain production
work. Missing optional audio must fail silent rather than block learning.

## Defect recording

Every acceptance defect should include:

- checkout SHA
- device and iPadOS version
- world / room / mechanic
- exact reproduction steps
- expected behavior
- actual behavior
- whether it reproduces after relaunch
- screenshot or short screen recording when visual
- severity

Use these severity levels:

- **Blocker** — crash, data loss, progression dead end, app cannot launch, or core
  interaction cannot be completed
- **Major** — materially broken touch, layout, persistence, navigation, feedback,
  accessibility, or learning behavior with a viable workaround
- **Minor** — polish issue that does not prevent normal completion

Device-discovered fixes should be grouped into the smallest coherent follow-up PRs.
Do not mix unrelated content expansion into an acceptance-fix PR.

## Acceptance record

```text
Commit:
Device / iPadOS:
Xcode / simulator runtime:
Native foundation CI:
Simulator build and tests:
Scene preview/review artifacts inspected:
Simulator app artifact (optional):
Device install and launch:
Fifteen-minute interaction session:
Airplane mode:
Partial-object and assisted-attempt restore:
Challenge Gate / Moon Lantern (or not exercised):
Settings / parent summary:
Word Garden smoke check:
Puzzle Palace smoke check:
Science Lab smoke check:
Reduced motion / rotation / multi-touch:
Audio / interruption:
Blockers:
Major defects:
Minor defects:
Tester / date:
```

## Release gate

The first vertical slice is not accepted until a physical-iPad pass has:

- no blocker-level crashes, data loss, or progression dead ends
- reliable touch and navigation through the tested Math route
- correct save/restore behavior across force quit
- correct evidence handling for independent versus assisted success
- usable Reduced Motion behavior
- readable layouts in both landscape directions
- Challenge Gate and persistent reward verified when naturally eligible, or clearly
  recorded as not exercised
- all discovered blocker/major defects either fixed or explicitly deferred with a
  product decision

After that pass, the next implementation work should be driven by observed device
defects first, then companion/character action polish and production audio. Do not
add Chapter 2, more worlds, accounts, monetization, or speculative backend work
before the current slice is stable on-device.
