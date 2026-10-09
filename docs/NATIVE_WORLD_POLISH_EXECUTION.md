# ValkyrieLearn native world-polish implementation contract

Status: IMPLEMENTATION BACKLOG — NOT ARTWORK APPROVAL
Baseline: main at 9fad2495e9b31f406ff7a3f419f38830b78dfcd2 (2026-10-09)
Reference: the 74 user-supplied native simulator captures (2026-10-09)
Primary source: AGENTS.md, ROADMAP.md, docs/PRODUCTION_VISUAL_GAMEPLAY_CONTRACT.md, docs/DEVICE_ACCEPTANCE.md, docs/SESSION_ACCEPTANCE.md
Related work: #116 (Retina paintings), #118 (physical iPad), #141 (educator review), #158 (4:3 painted edges), #161 (Palace mechanical polish).

## Locked product constraints

Native Swift/SpriteKit gameplay, SwiftUI shell and SwiftData offline progress stay intact. Keep the six canonical Valkyrie atlas pose textures and approved companions untouched. Do not replace approved paintings, import substitute characters, change child-learning evidence, or award mastery for ambient exploration. Use adaptive 4:3 iPad framing; preserve input positions and accessible labels. Reduced Motion cannot erase a physical state change. New environment-only paintings need side-by-side review under #116; the golden-master storyboard still needs explicit owner sign-off.

## First-run child journey and shared UX language

A child should always be able to: (1) see the obstacle, (2) notice a physical prop that can be tapped or moved, (3) watch Valkyrie/Tiko approach, (4) perform an action with visible world consequence, (5) try again without shame if it fails, (6) revisit a changed world, and (7) exit without losing progress.

The common controls are a quiet top home/room label, one short contextual instruction (spoken support planned), 60pt+ targets where spatially possible, a visible mechanical test lever where required, and exactly one clear success event. No second giant prompt panel, floating decorative circle used as a button, or full-width answer menu over the painting. Preserve existing names and accessibility labels of gameplay hit targets when rendering changes.

## Palace room implementation matrix

| Room | Physical interaction and child-visible outcome | Failure, support and replay | File / validation |
| --- | --- | --- | --- |
| Rune Gate | Three carved runes already occupy the lock. Child inserts a missing rune into the real door socket; authentic stone doors separate and reveal the traversable route. Keep choices next to the door, not across scenery. | Incorrect stone stays retrievable; show an amber lock response; avoid counting guided insertion as independent. | PuzzlePalaceScene.swift: buildRuneEncounter, openRuneGate; 4:3 door/choice overlap and saved-open regression. |
| Memory Bridge | Tiko reveals a sequence on stone pads. Child repeats it; bridge segments raise one by one, Tiko crosses the actual gap. | On an incorrect step, the affected plank visibly lowers, playback slows or replays; memory evidence remains separate from inhibition. | buildMemoryEncounter, memoryPad, restoreMemoryBridge; deliberate-tap, pause/resume and 4:3 pad tests. |
| Stop/Go Orbs | Orb is a mounted brass signal with shutter and barrier; HOLD closes a gate, GO opens it. Avoid neon giant button and tiny legend. | Wrong timing gives a physical closed gate with safe retry; Reduced Motion preserves open/closed geometry. | buildStopGoWorld, signal/update, stopGoBarrier; tests for shutter state and saved restoration. |
| Sorting Pedestal | Object sits on a stone work surface. Child places it into one of two carved alcoves; the receiving pedestal reacts and accepts or rejects the piece. | Incorrect piece rests at the wrong alcove briefly then returns. Next stage changes the actual property rule, not just a caption. | buildSortingWorld, buildSortPedestal, render sort choices; category/tap/evidence tests. |
| Re-sort Vault | Same physical collection, but shelves/pedestals reconfigure for a changed rule. Let child move each object again. | Show why the new alcove no longer accepts the object without shaming; preserve rule-switch evidence stream. | buildResort world/encounters; return, undo, persistence and distinct evidence tests. |
| Mirror Hall | Three grounded, pivotable mirrors direct visible light across the room. Rotating or selecting an orientation visibly moves a beam onto a receiver; maintain the existing orientation and mental-rotation challenge families. | Wrong direction sends the beam elsewhere; allow retry and display the resulting ray even with Reduced Motion. | buildMirrorHallWorld, orientation/rotation encounters; tests for active beam, 60pt target, orientation vs rotation evidence. |
| Path Tiles | Route tokens on the side workbench describe a planned crossing. Selecting a token lights a connected route between *floor stones*, lifts the safe bevels and lets Tiko walk from the first stone to the goal. | Wrong plan reaches a cracked step or leaves the route incomplete; wrong stones visibly drop/tint and a fresh plan is available. Never auto-complete by tapping a grid stone. | buildPathTilesEncounter, revealAttemptedStoneTrail, animateTikoAlongPath; map, retry, reduced-motion, and progression tests. |
| Command Gears | Assemble three toothed command gears on one mechanical shaft, then pull RUN and watch gears and linked obstacle execute commands in order. | Incomplete chain does not score; wrong chain plays a safe stalled mechanism and preserves honest sequencing evidence. | buildCommandGearsWorld / encounter / run; socket hit areas, distinct sequencing evidence. |
| Bug Lantern | Show the three-step mechanism on a connected rail, with the visibly broken component as the thing to inspect, not a stack of generic answer cards. Let a light travel step by step until the machine jams. | A wrong diagnosis shows the remaining failure; correct inspection opens the repair route without awarding a different skill. | buildBugLanternWorld, buildBugLanternEncounter, finishBugLantern; debugging evidence, no premature reward. |
| Repair Lab | Four real gears share a clockwork drive shaft. Child lifts two misplaced gears and pulls TEST; gears swap, rotor turns and lamp lights when correct. | Wrong swap causes controlled stalled motion; reset and try again. Lift/deselect must be physical and immediate under Reduced Motion. | buildBugRepairEncounter, renderRepairSelection, submitBugRepair; saved completion, swap/label and evidence tests. |

## Other worlds implementation matrix

| World | Highest-impact action | Acceptance |
| --- | --- | --- |
| Story Tree | Keep Valkyrie on painted paths, visibly walk toward one-tap destinations, give earned lanterns/plants/creatures meaningful placeable branch slots. | Valid hit zones match labels; no moth/actor hides navigation; branch placement, reward and state survive force-quit. |
| Math Castle | Make Crystal Cart, scale and bridge tests move actual loads and machinery. Reward correct math with observable machine outcomes, not only number labels or lamps. | Require approach before scoring; no untouched input scores; support vs independent evidence and anti-repetition unchanged; wrong loads bend/stop safely. |
| Word Garden | Keep Flower Gate's parchment rune readable with just one prompt; planting/watering/shade produce reversible visible growth with Lumi participating. | Large letter/flower taps, accessible alternatives, original garden art, saved raised flower and relaunch persistence. |
| Science Lab | Milo's moveable lamp casts visible size/direction-changing shadows on the environment; replace reused garden crops only after approval of an original greenhouse painting. | Drag, tap-alternative, partial discoveries and science evidence separation remain correct. |
| Weather Tower | Wind strength and sail changes physically move the cart, and the rescued kite stays home; improve 4:3 scenery coverage without stretching painted content. | Calm/leaf/gust outcomes are distinct, replayable, and survive relaunch; no false Math/Science mastery. |
| Creature Grove | Animal, habitat and comparison objects must visibly respond to placement/observation and show what was restored. | All three field studies and cross-world routes remain safely navigable and persist. |

## Release-safe implementation batches

### Batch A: playable Palace foundation
- DONE on main: #159 Rune Gate, Memory Bridge, Command Gears physical presentation; #164 Repair Lab selected gear lifts.
- IN PROGRESS in integration branch: Stop/Go shutter, Sorting/Re-sort carved props, connected Path Tiles trail and first-stone travel.
- REMAINING: full real-device validation of each interaction and actual native 4:3/16:9 screenshots.
 
### Batch B: Palace remaining physical affordances
- Mirror Hall: integrate visible light beam/receiver and tactile mirror orientation.
- Bug Lantern: move diagnosis into connected machine and visibly jam at the identified step.
- Repair Lab: make success rotor/lantern and failed trial clear at every step.
- Audit route/room return controls, hint strength, persistence, Reduced Motion, and deliberate multi-touch behavior.

### Batch C: all-world consistency
- Math Castle: prioritize Crystal Cart, scales and bridge cause/effect over more worksheet-style questions.
- Word Garden: one readable prompt, tactile flower/seed state and Lumi actions.
- Science/Weather: fix 4:3 scenic edges (#158); new original Retina 4:3 environment art remains gated by #116.
- Story Tree: ensure navigation markers and earned placements are clear in the real iPad viewport.

## Test and screenshot checklist

For every modified room, capture actual iPad Simulator screenshots: 1024x768 landscape, 1280x720 comparison, initial/partial/incorrect/correct/restored state. Never call a generated concept a native screenshot. Inspect text clipping and active touch geometry. Run LearningCore tests, native-validation, iPad build/tests, then physical iPad 15-minute acceptance under #118. Check a deliberate tap vs swipe, two-finger interruptions, application background/foreground, portrait guidance, saved state after relaunch, Reduced Motion, and offline mode. Owner-reviewed pixel goldens are separate and cannot be silently updated. Actual educator review of the 76 Math skills stays outstanding under #141.

## Success standard

A five-to-eight-year-old should understand which object to touch without a paragraph of reading. The changed machine, route, flower or obstacle—not a floating badge—must provide the primary success feedback. The child can fail safely, retry and revisit without losing work. Keep all existing assessment separations and curriculum truthfulness; no changes to the original Valkyrie identity.
