# Native iPad build and device acceptance

This is the first illustrated native Math Castle slice, continuing v3.31 / The
Lost Starlight. It is not a completed chapter or a signed TestFlight release.
Production remains Swift, SpriteKit, SwiftUI, SwiftData and AVFoundation.

## Build the consolidated branch

Use a Mac with Xcode 16 or newer, an installed iPad Simulator runtime and Python 3.
Use an iPad running iPadOS 17 or newer for the device check.

```sh
git clone https://github.com/erwinmehehe/valkyriegame.git
cd valkyriegame
git switch native/canonical-v331-math-slice-v1
git rev-parse HEAD
python3 scripts/validate_native.py
swift test
xcodebuild -list -project ValkyrieLearn.xcodeproj
xcrun simctl list devices available
```

The branch contains the complete consolidation even while PR #13 waits for its
native CI gate. After #13 merges, `main` is the supported integration branch.
Record the checkout SHA with the results; do not use an older HTML download.

Select an available iPad simulator UUID from the list above, then run:

```sh
xcodebuild test -project ValkyrieLearn.xcodeproj -scheme ValkyrieLearn \
  -destination 'platform=iOS Simulator,id=REPLACE_WITH_IPAD_SIMULATOR_UUID' \
  -resultBundlePath DeviceAcceptance.xcresult CODE_SIGNING_ALLOWED=NO
xcrun xcresulttool export attachments --path DeviceAcceptance.xcresult \
  --output-path device-acceptance-scenes
open ValkyrieLearn.xcodeproj
```

Use a new result bundle path if one already exists. The simulator run does not
install a signed app on a physical iPad.

## Install on the iPad from Xcode

1. Connect the iPad to the Mac, unlock it and trust the Mac if prompted.
2. Enable Developer Mode on the iPad if Xcode requests it.
3. In Xcode, select the **ValkyrieLearn** scheme and the connected iPad destination.
4. Select the app target, then **Signing & Capabilities**. Choose your development
   Team and leave automatic signing enabled. If the default bundle identifier
   `com.valkyrielearn.ValkyrieLearn` is unavailable, use an identifier owned by your
   Team. Keep it stable between test installs so you can test the same local save.
5. Run with **Product → Run**. Follow any development certificate trust prompt on
   the iPad. Confirm the app launches in landscape.

No signing credentials or provisioning profiles are committed. Do not delete the
installed app between save/restore checks. Installing from Xcode is distinct from
publishing to TestFlight; a signed distribution build is not supplied by CI.

## Fifteen-minute acceptance session

Record device model, iPadOS version, checkout SHA, time, and pass/fail observations.
The times below are a suggested test order, not timers imposed on the child.

| Time | Action | Expected behavior |
| --- | --- | --- |
| 0–2 min | Open Story Tree; tap the castle sign once; try another destination during travel; tap empty sky/chasm. | Valkyrie and Pip remain visible, follow the painted stairs and bridge, and enter the selected world on arrival. Repeated sign taps do not restart the journey. A new destination redirects travel, a valid path tap resumes exploration, and void taps are ignored. |
| 2–4 min | Approach the active castle object, then manipulate it. | The first distant tap moves Valkyrie; interaction requires arrival. Problem stays above the object and feedback below. |
| 4–6 min | Tap/drag crystals, overshoot then correct; try an incorrect total. | Quantities respond once per action; cart can be corrected. No shaming, duplicate credit, or accidental hotspot activation from drag release. |
| 6–8 min | Ask in-scene Pip for successive hints; complete the task. | Support escalates, demonstrates a useful step when needed, and persists. Assisted completion is not independent mastery. |
| 8–10 min | Advance through available objects; use Pip's non-academic gear. | The active mechanic changes, ordinary success lights the castle route, and exploration supplies a change of pace. It does not pretend the Challenge Gate is unlocked. |
| 10–12 min | Return to Story Tree, open Settings → Math progress; try a workshop. | Parent summary reports evidence-backed learning. Unanswered machines and unscored workshop completions do not add recent scored learning. |
| 12–15 min | Leave an object partially manipulated; background and force-quit the app; relaunch. | World, quantity, support, learner profile and completed/pending order restore without duplicate evidence. Test again with airplane mode enabled. |

Also rotate between both landscape directions, enable Reduced Motion, test large
touch targets and non-drag alternatives, and try a second finger during a drag.
Record crashes, missed taps, clipped questions, confusing routes and visible stalls.

## Persistent reward check

On a profile that genuinely has two Secure source skills, verify the optional
Challenge Gate opens three prerequisite-safe challenges across different mechanics.
Provisional placement readiness alone must not open it. Ordinary Math play remains
available without the gate.

Complete the gate, return to Story Tree, and move the Moon Lantern among its branch
slots. Force-quit and reopen: the earned lantern and chosen branch must remain.
If that profile is not yet ready during the fifteen-minute session, record this as
not exercised rather than claiming it passed or modifying the child's mastery.

## Audio and visual limits

Sound on/off and interruption handling must remain safe. The bundle contains basic
footstep, crystal, gear and success WAV cues. AudioSystem only plays named WAV files
that exist; missing cues remain silent. Finished narration, instructional recordings
and ambient music are not provided by these basic effects.
Full animation action sets and deeper environmental integration still need polish.

## Acceptance record

```text
Commit:
Device / iPadOS:
Xcode / simulator runtime:
Simulator build and tests:
Scene attachments reviewed:
Device install and launch:
Fifteen-minute interaction session:
Airplane mode:
Partial-object and assisted-attempt restore:
Challenge Gate / Moon Lantern (or not exercised):
Settings / parent summary:
Reduced motion / rotation / touch:
Audio / interruption (including missing assets):
Crashes, visual defects or other remaining issues:
Tester / date:
```

Real-device acceptance remains required before calling the vertical slice complete.
Next implementation work is to refine connected physical progression, companion
actions and environmental reactions inside the existing Math Castle, driven by
these observations. Do not add Chapter 2, more worlds, accounts or monetization.
