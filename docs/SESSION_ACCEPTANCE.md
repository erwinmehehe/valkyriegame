# ValkyrieLearn 15-Minute iPad Session Acceptance

This is the manual acceptance gate for the current native iPad vertical slice. Run it on a real iPad after CI is green and before calling a gameplay/polish milestone complete.

## Test conditions

- Real iPad running iPadOS 17 or later
- Landscape orientation
- Fresh install or a known test profile
- Sound on for the first pass
- Repeat once with Reduced Motion enabled
- Do not coach the child unless the app becomes genuinely unclear
- Record the screen if possible so dead taps, pauses, overlaps and repeated instructions can be reviewed afterward

## Minute 0–2: Story Tree

Start at Story Tree.

Acceptance:
- Valkyrie and Pip are immediately visible and readable.
- The child can identify at least one world destination without adult explanation.
- Tapping a destination causes immediate feedback and a believable walk.
- One tap enters the selected adventure on arrival; a second tap is unnecessary.
- Repeated taps on the same destination do not restart walking. A different destination redirects the journey, and tapping the painted path cancels world entry.
- Mid-bridge path taps land at the intended spot, and Pip stays on the painted route.
- No destination label is covered by Valkyrie.
- No tap on the surrounding chasm moves Valkyrie off the painted route.
- Settings is easy for a grown-up to reach but does not dominate the child-facing scene.
- Any earned Moon, Flower or Palace Lantern appears after relaunch and can be moved to another branch.

Fail the pass for:
- a dead destination tap
- actor/control overlap that hides the intended target
- portrait guidance allowing taps into the game underneath
- reward state disappearing after relaunch

## Minute 2–8: Math Castle

Play normal adaptive Math Castle work rather than selecting workshop examples.

Acceptance:
- The learner reaches a meaningful task quickly; known-easy material does not dominate.
- A scored interaction requires Valkyrie to approach the physical machine before input is accepted.
- The active mechanic is visually primary and unrelated controls recede.
- Wrong work changes support or representation instead of immediately repeating the exact same prompt.
- No identical encounter fingerprint repeats.
- The same mechanic is not presented more than twice consecutively.
- At least three distinct mechanics are seen in a longer session when readiness allows.
- A natural exploration/stopping beat appears after roughly four scored encounters.
- A strong learner can encounter deeper reasoning/transfer work such as:
  - equal totals/equivalence
  - fixing Pip's mathematical mistake
  - reasoning about what changed
  - a missing value within 20
  - explaining a comparison
  - applying addition/subtraction in a story context
- The app does not award "choose a strategy" or "multiple solutions" evidence unless a future mechanic directly observes those actions.
- Pip support is visible in-world and assisted work remains distinguishable from independent evidence.
- Taps and valid drags describe the actual quantity or selected pan without marking an answer correct before the lever is pulled. Pip acknowledges a real edit, while inputs at a quantity limit do not replay his reaction or the input sound.
- A retry lights the machine lamp amber even with Reduced Motion enabled. Correcting and submitting quickly leaves it steadily gold; an earlier retry effect must not dim the successful machine.

Fail the pass for:
- a worksheet-like modal flow replacing the world
- more than two consecutive uses of the same mechanic
- repeated trivial work after several easy independent successes
- a supported/demo response counting as independent mastery
- instruction text that requires a grown-up to translate what to do

## Minute 8–13: Puzzle Palace

Enter Puzzle Palace and continue from the learner's current restored room.

Acceptance:
- Restored rooms stay restored after leaving and returning.
- Tiko participates physically rather than acting as a generic hint button.
- Memory, inhibition, sorting, rule switching, rotation, planning and sequencing remain separate evidence streams.
- Path Tiles still measures planning rather than step-by-step sequencing.
- Command Gears still measures action sequencing rather than debugging.
- When every currently implemented Palace room is independently restored:
  - the Command Engine shows the Palace finale state
  - Valkyrie and Tiko receive a visible restoration payoff
  - the violet Palace Lantern is earned
  - returning to Story Tree shows the Palace Lantern
  - moving that lantern to another branch persists after relaunch
- Palace ambience stops after leaving Palace rooms.

The current finale intentionally covers the rooms implemented today. A future Bug Lantern/debugging room should extend the centralized Palace completion gate instead of silently awarding debugging mastery here.

Fail the pass for:
- one Palace mechanic granting evidence for another cognitive skill
- ambience continuing after leaving Puzzle Palace
- completion depending on assisted attempts
- the Palace reward appearing before every currently implemented room is independently restored

## Minute 13–15: Stop, relaunch and grown-up view

At a natural stopping point, return to Story Tree and close the app. Relaunch it.

Acceptance:
- The app returns to a coherent saved world/state.
- Current learner progress, support state and restored rooms persist.
- Story Tree rewards persist in their selected branch slots.
- Parent Math Progress reflects strengths, developing skills, review needs and ready-next skills without exposing raw question-count vanity metrics.
- Recent learning identifies whether Pip support was used.
- No save error appears during a normal session.

## Reduced Motion pass

Repeat the critical interaction path with Reduced Motion enabled.

Acceptance:
- Gameplay remains fully understandable.
- Required state changes still occur.
- Decorative pulsing, entrance motion and camera emphasis are suppressed where expected.
- Toggling Reduced Motion during travel preserves movement; beacon and earned-lantern pulses stop immediately and foreground decorations return to their authored positions.
- No task depends on animation timing to reveal the correct answer.

## Character presentation check

Watch Valkyrie and each available companion approach and operate a world object.
Pip should waddle, Lumi glide gently, Milo move briskly, and Tiko take slower,
smaller steps. Foot shadows remain on the ground while their bodies move.
Trigger another reaction before an aura pulse finishes: the aura must not stay
enlarged, the actor must keep facing the object, and its world position must not
jump. Repeat with Reduced Motion enabled; static poses and ability completions
must remain clear without decorative body motion.

## Deliberate tap check

In Word Garden and Puzzle Palace, swipe across an answer or destination, then
slide away and back before lifting. Neither gesture should choose an answer,
move Valkyrie, change rooms or record learning evidence. A short tap with slight
finger movement should still work. Interrupt a press by opening the iPad app
switcher; returning and lifting must not activate the old press, and the next
deliberate tap must respond normally.

During a Palace memory sequence, rotate until the landscape guidance is visible
or open the app switcher. Gameplay should pause rather than finish the unseen
sequence. Return to landscape and the foreground to resume from the paused state.

## Session verdict

A pass requires:
- zero blocker crashes
- zero progression dead ends
- zero persistent dead taps on primary controls
- no actor obscuring a scored answer after approach
- no stale audio after world changes
- no lost progress after relaunch
- no false cross-skill evidence
- no more than two consecutive uses of the same mechanic
- at least one natural stopping/exploration beat
- child-facing instructions that can be acted on without adult translation

Log every failure with:
- world/room
- exact action
- expected result
- actual result
- screenshot or screen-recording timestamp
- whether it reproduces after relaunch
