# Puzzle Palace — ten-room visual polish master execution plan

**Status:** PROPOSED / NOT OWNER APPROVED. **Tracking:** [#181](https://github.com/erwinmehehe/valkyriegame/issues/181). **Technical issue:** [#161](https://github.com/erwinmehehe/valkyriegame/issues/161). **Baseline captured:** 2026-10-10, `main` at `6d01d7f20234227486497156a7a8a743fb8adf59`. This SHA is an *inventory reference*, not an approved visual golden master.

This document operationalizes [PRODUCTION_VISUAL_GAMEPLAY_CONTRACT.md](PRODUCTION_VISUAL_GAMEPLAY_CONTRACT.md), [AGENTS.md](../AGENTS.md), [GAME_DESIGN.md](GAME_DESIGN.md), and [DEVICE_ACCEPTANCE.md](DEVICE_ACCEPTANCE.md). The earlier visual contract wins if a convenient suggestion here conflicts with an established game or curriculum rule. **No room is aesthetically signed off solely because code or simulator CI passes.**

## The one-sentence objective

Make the ten existing Puzzle Palace rooms feel like a **single premium, painterly, physical storybook adventure** in which Valkyrie and Tiko touch believable stone/brass/glass machinery and the world visibly responds — without changing the approved environments, canonical characters, existing ten room identities, encounter catalog, learning evidence, story routes, accessible inputs, or SwiftData saves.

## Non-negotiable design and engineering boundaries

1. **Retain the present illustrated environments.** Cropped paint texture for native prop materials is acceptable when it fits and is not misleading; new original environment-only Retina paintings require **separate owner/art approval under #116**. Do not replace artwork with a screenshot composite, a flat vector candidate, an AI mockup, a sharpened upscale, or a generic visual reference.
2. **Protect the characters.** Do not redraw or replace the canonical Valkyrie atlas or the approved identity, scale or gameplay role of Tiko.
3. **Keep the native stack.** Swift + SpriteKit, SwiftUI shell, SwiftData offline, AVFoundation. No HTML/WebView, Unity, Godot, backend, new rewards, worlds, or curriculum rewrite.
4. **Environment-first, no generic answer panels.** A rune goes into the painted door lock, bridge slabs really support a crossing, a glass/brass signal controls a barrier, a mirror physically redirects a light beam, and gears drive linked machines. Decoration alone is not acceptance.
5. **One vocabulary, distinct room silhouettes.** Stone, brass, glass and wood can vary in hue by room but share bevel/relief, warm highlights, restrained bloom, perspective, scale, material wear, and in-world mounting. Fewer floating signs, thick dark rows, disconnected dials and unrelated purple rectangles. One home control, compact area label, and one short age-appropriate prompt.
6. **Tap-to-approach and directly manipulate.** Named interactive nodes stay stable while decorative props move. Preserve normally **60pt-or-larger usable touch targets**, readable glyphs, pre-reader narration/VoiceOver, character walk clearance, no double input, and real Reduced Motion states.
7. **Learning evidence is immutable to a visual pass.** Untouched/incomplete produces no earned completion; incorrect is recorded as incorrect; hint-assisted correct is not independent/mastered; independent evidence still requires the authored skill conditions and distinct practice. Do not introduce a demo or prop animation that writes credit.
8. **A result must be physical.** Every incorrect/partial/success outcome has an observable mechanism state. Correcting a mistake must clear stale rejection and safely permit retry. Completion and revisits display the *persisted* world state, not a fresh unanswered worksheet.
9. **No hidden approval.** CI success proves software checks, not owner visual judgment, teacher sign-off, physical-device usability, official curriculum alignment, or approved new paintings.

## Baseline and in-flight work — verified 2026-10-10

| Room / workstream | Already merged into main | Open work (not merged, approval not implied) |
| --- | --- | --- |
| Rune Gate | Initial native door/rune mechanism, #159 and subsequent palace work | [#180](https://github.com/erwinmehehe/valkyriegame/pull/180): tactile lock-and-key polish; prior simulator width assertion failed, focused width fix committed; await fresh pass and **owner visual approval** |
| Memory Bridge | Existing light-sequence and physical bridge work | New polish PR needed |
| Stop/Go Orbs | [#170](https://github.com/erwinmehehe/valkyriegame/pull/170): responsive GO barrier | New coherence/lighting/fixture polish PR needed if owner storyboard requests it |
| Sorting Pedestal | Existing stone alcove gameplay | [#178](https://github.com/erwinmehehe/valkyriegame/pull/178): retained sorted stones; latest CI green, visual review not yet equated with approval |
| Re-sort Vault | [#171](https://github.com/erwinmehehe/valkyriegame/pull/171): rule-console/physical gate switching | Remaining finish and cohesion against Sorting Pedestal visual language |
| Mirror Hall | [#173](https://github.com/erwinmehehe/valkyriegame/pull/173): pivoting glass/cleared rejected state | Optional targeted optics/material polish after shared style approval |
| Path Tiles | [#174](https://github.com/erwinmehehe/valkyriegame/pull/174): Tiko safe wrong-route stop | [#179](https://github.com/erwinmehehe/valkyriegame/pull/179): carved floor/route readers/restored gateway; CI green, **owner visual approval pending** |
| Command Gears | Existing socket and sequence foundations | [#176](https://github.com/erwinmehehe/valkyriegame/pull/176): linked execution, gate and bridge; latest CI green, visual review still required |
| Bug Lantern | Existing cassette/inspection foundations | [#175](https://github.com/erwinmehehe/valkyriegame/pull/175): linked pistons and repaired power; latest CI green, visual review still required |
| Repair Lab | [#172](https://github.com/erwinmehehe/valkyriegame/pull/172): readable gears and physical wrong-swap feedback | Refined art-depth, machine controls and saved-state visual QA; new scoped polish PR if needed |

Separate nonvisual [#177](https://github.com/erwinmehehe/valkyriegame/pull/177) concerns the **unsigned 76-skill Math teacher worksheet**. It must not be counted as Palace visual approval. Existing #118 device testing, #141 educational review and #116 environment-art quality remain independently open.

**Inventory principle:** Green on a branch is not proof the same patch stays green after another branch lands. Many active Palace PRs modify the same SpriteKit scene and native tests. Reconcile with the latest `main`, check semantic conflicts, and run fresh checks where the merge-base changed. Never forcibly overwrite another PR's work.

## Phase zero — establish one golden master BEFORE full rollout

- [ ] **Verify the exact Steam reference** the owner previously mentioned (title/URL). The repo does not document it. Inspiration is a pacing/composition reference only, never a copied asset, UI, character or level.
- [ ] Compile **the same ten-room storyboard** showing for each: (A) problem/initial, (B) child touch, (C) incorrect or partial consequence, (D) successful physical transformation, (E) Tiko/Valkyrie functional role, (F) restored/revisited state.
- [ ] Build one native reference pack from real Simulator frames for all **10 × 4 = 40** standard states, from an identified commit and PR branch. Include actual before/after comparisons and no concept art presented as a render.
- [ ] Inspect showcase **Rune Gate and Repair Lab** as the two canonical physical interaction proofs demanded by the production contract. Compare **Path Tiles #179** as an additional candidate for stone/brass surfaces; do not silently replace the two-proof rule or call #179 approved.
- [ ] Owner signs one *versioned golden-master contact sheet* identifying exactly what is approved: source art IDs, palette/material vocabulary, legible rune/label scale, bevel/relief, depth, camera, allowed effects, touch/VoiceOver cues, character presence, error and success states, scene names and commit SHA.
- [ ] Only after explicit acceptance may the master visual contract be marked **OWNER APPROVED — DESIGN FROZEN**; until then it remains proposed. Freeze *direction*, not bug fixes. If a room conflicts with the accepted board, resolve by revising that scoped room, not by starting another global redesign.

**Deliverable:** contact sheet + source manifest + reviewer/date and decision, attached to [#181](https://github.com/erwinmehehe/valkyriegame/issues/181). The master must be reviewed at **1024×768 landscape 4:3** and safe on the wider 16:9 design canvas. Store the actual screenshot filenames and exact SHA, never a fabricated download path.

## Visual grammar to use in every room

| System | Do | Avoid |
| --- | --- | --- |
| Objects | Carved/chipped masonry, attached brass shafts, glass lenses, real pivots, hinges, mounting bases, plausible contact shadows | Flat unrelated circles/squares, free-floating pads, detached thick black rails |
| Scale / layout | Prop in the painted perspective, clear foreground / actor lane / active puzzle / destination, preserve 4:3 safe margins | A huge central HUD covering the room or controls near clipped edges |
| Type / glyphs | Short narrated instruction, crisp accessible rune at iPad size, distinct material contrast, identifiable start/goal | Small black arrow fonts, answer hinted via glow/position before touch, duplicate floating labels |
| Light / motion | Light and mechanism react to the *actual child's input*; incorrect shows a legible obstruction; animated and Reduced Motion end at same state | Arbitrary sparkles, color-only feedback, endless blinking, continuous animation as proof of progress |
| Affordance | Tap-to-approach, place/swap/slide/rotate/test, stable named interactive parent, companion performs a real action | Decoration that steals a tap, new drag-only requirement, autoplay awarding evidence |
| Completion | Physical route opened, machine restored, object pile present, loaded correctly after force quit/offline revisit | A green border/checkmark over an unchanged scene or empty controls after completion |

## Room-specific acceptance criteria

### Rune Gate — tactile stone-key proof; [PR #180](https://github.com/erwinmehehe/valkyriegame/pull/180)

- [ ] **Before:** three carved keys rest visibly on separate floor-plinths, a three-rune repeating pattern and vacant fourth recess fit *inside* the approved painted door. No lock housing spills past the arch or stairs.
- [ ] **Action / failure:** Valkyrie approaches; Tiko works the actual lock. Wrong key visibly fails in brass jaws and returns to its own plinth. In Reduced Motion jaws present a distinct rejected end state, not a disappearing key. Fast second taps never score twice.
- [ ] **Correct / payoff:** a key actually seats; physical jaws capture it; only earned independent pattern outcomes move the linked door cog. All required independent evidence opens the painted double-door passage and lights a floor route.
- [ ] **Restore:** on revisit the opened door, stable keyed mechanism and lit route are present; no new evidence. Verify a 4:3 doorway-width regression (existing NativeSceneSnapshotTests) and unchanged canonical Valkyrie/Tiko.
- [ ] **Visual owner gate:** side-by-side initial, wrong, correct, restored #180 frames and real hit/character clearance approval.

### Memory Bridge — real light-sequence crossing; **new polish PR required**

- [ ] **Before:** bridge planks and stone runes belong to the chasm/perspective and are individually readable; no anonymous button row or duplicated floating prompt.
- [ ] **Action / failure:** Tiko demonstrates the authored sequence; child's touched rune visibly lights a corresponding bridge stage. Wrong order gives a recoverable local misfire; it must not raise an unearned plank.
- [ ] **Correct / payoff:** earned stages lift and lock actual crossable planks; Valkyrie and Tiko physically cross the completed bridge; correct order still tests memory rather than hinting the answer.
- [ ] **Restore:** bridge remains completed after exit/relaunch/offline return, and completion generates no duplicate pattern-memory evidence.
- [ ] **QA anchor:** named `memoryPad` hit targets and existing sequence-length/scoring tests survive untouched.

### Stop/Go Orbs — readable signal and moving barrier; [PR #170](https://github.com/erwinmehehe/valkyriegame/pull/170) baseline

- [ ] **Before:** glass/brass signal is firmly mounted to existing rail/wall; HOLD and GO are distinguishable by icon/position/fixture state as well as color, including Reduced Motion.
- [ ] **Action / failure:** child's premature run or missed hold visibly meets a **closed** barrier without crossing; retries are safe and wrong input remains incorrect.
- [ ] **Correct / payoff:** a real powered signal releases the barrier; Tiko/Valkyrie cross only during valid GO and the scene retains obvious barrier state.
- [ ] **Restore:** completed barrier is visibly unlocked on revisit with no fresh credit.
- [ ] **QA anchor:** 60pt+ signal tap, timing and hold penalty, fast repeated taps, low-motion snapshots and existing evidence stay correct.

### Sorting Pedestal — carved receiving alcoves; [PR #178](https://github.com/erwinmehehe/valkyriegame/pull/178)

- [ ] **Before:** stone receiving bowls, large meaningful category glyphs and a touchable object all rest on room masonry, not purple ovals.
- [ ] **Action / failure:** wrong placement physically rejects/returns; no incorrect stone remains in the accepted bowl.
- [ ] **Correct / payoff:** each correctly sorted object visibly enters and **remains** in the actual receiving alcove, with mark/glyph intact; only full authored encounter completion records success.
- [ ] **Rule / restore:** when SHAPE switches to MARKS, objects from the previous classification clear before the new category labels apply; a completed revisit shows an unscored physical exhibit, not empty bowls.
- [ ] **QA anchor:** no stale rule, no premature evidence or extra reward, same large named pedestal taps, both motion modes.

### Re-sort Vault — same objects, truly changed rule; [PR #171](https://github.com/erwinmehehe/valkyriegame/pull/171) baseline

- [ ] **Before:** a floor-mounted rule detent, meaningful receiver shutters and clear alcoves sit below—not across—the painted door.
- [ ] **Action / failure:** the **same objects** are classified once by one property and then reclassified under the new visible physical configuration. Wrong receiving choice visibly resists and permits recovery.
- [ ] **Correct / payoff:** dial/track changes real shutter positions and category labels; child can compare the two classifications without implying a new set of objects.
- [ ] **Restore:** unlocked vault and correct final rule/receiver configuration survive scene return; first and second passes keep their authored separate evidence.
- [ ] **QA anchor:** preserve exact two-pass skill attribution, reduced-motion detents, tap overlap with next-room route and saved state.

### Mirror Hall — mirror hardware and real optics; [PR #173](https://github.com/erwinmehehe/valkyriegame/pull/173) baseline

- [ ] **Before:** each selectable mirror is mounted in its illustrated fixture; beam source and receiving target are spatially interpretable without a generic dial overlay.
- [ ] **Action / failure:** child rotates/selects a real pane; a rejected angle visibly **misses** its receiver; the glass moves but hit target remains stable.
- [ ] **Correct / payoff:** corrected mirror redirects an actual light path into the physical receiver; previous red rejection clears so successful state is unambiguous.
- [ ] **Restore:** source, mirror angles, receiver and completed ray persist visually on revisit; distinct spatial orientation and rotation evidence remain distinct.
- [ ] **QA anchor:** no preview of correct choice, stable named mirror parent touch, Reduced Motion and accessible direction descriptions.

### Path Tiles — carved crossing and companion travel; [PR #179](https://github.com/erwinmehehe/valkyriegame/pull/179)

- [ ] **Before:** individually cut floor stones on a grounded dais, clear start/goal marks and high-contrast *engraved* route choices match the approved painting. Do not substitute a generic grid.
- [ ] **Action / failure:** selected route reader physically responds. Tiko safely explores only the traversable prefix; stops **before** cracked/off-board/repeated stone behind a grounded obstacle. Incorrect plan remains incorrect and retry is assisted.
- [ ] **Correct / payoff:** inlaid path visibly powers and Tiko physically traverses a valid unique route to the star. No scoring based on animation alone.
- [ ] **Restore:** route, companion station and a physical gateway to Command Gears are shown, not abandoned buttons or a stale “pick a trail” prompt.
- [ ] **QA anchor:** keep grid coordinates, correct-route predicate, no double scoring, accessible route sequence, 4:3 touch zones and Reduced Motion, plus explicit owner approval of #179 before merge.

### Command Gears — attached gearbox executes commands; [PR #176](https://github.com/erwinmehehe/valkyriegame/pull/176)

- [ ] **Before:** three physical source gears, sockets and the **linked floor machine** share a shaft; labels and gears are large enough to read and tap.
- [ ] **Action / failure:** placing a gear physically transfers it to its socket. TEST runs ordered stages; first invalid command stops the machine and leaves downstream stages inert, rather than coloring all gears red without cause.
- [ ] **Correct / payoff:** a valid door sequence unlocks/opens an actual gate; the bridge variant lowers, crosses and raises the real bridge/deck with clear state feedback.
- [ ] **Restore:** returned room shows a stable powered engine and appropriate completed geometry. Assisted retry cannot masquerade as independent sequencing mastery.
- [ ] **QA anchor:** exact order, first-invalid-step stall, both output families, large named sources, reduced-motion same end states and no duplicate records.

### Bug Lantern — diagnose a linked broken mechanism; [PR #175](https://github.com/erwinmehehe/valkyriegame/pull/175)

- [ ] **Before:** three removable command cassettes/pistons and the lantern appear as one connected, physically understandable power chain.
- [ ] **Action / failure:** inspecting a **working** component lights it as working, not falsely red; testing a broken step stalls/lowers its piston and stops downstream power. Recognizing a fault without replacement does not award final repair evidence.
- [ ] **Correct / payoff:** replacing the actual broken cassette connects the entire power chain and relights the lantern with a concrete physical response.
- [ ] **Restore:** all machine pistons and power conduits remain in correct state; no extra evidence on return.
- [ ] **QA anchor:** preserve debug-single-step/debug-sequence distinctions, correct versus assisted attempt classification, stable cassette taps, low-motion physical states.

### Repair Lab — real clockwork swap and restart; [PR #172](https://github.com/erwinmehehe/valkyriegame/pull/172) baseline

- [ ] **Before:** readable tooth profiles, relief, axles/shafts, labeled swapping rails and receiving sockets match the workshop painting rather than giant black flat gear disks.
- [ ] **Action / failure:** child physically swaps two command parts. Wrong swap **still moves them** and visibly stalls the rotor; no false indication that the machine is repaired.
- [ ] **Correct / payoff:** a correct swap plus the authored FIX action seats the parts and physically restarts the linked machine; Tiko/Valkyrie react to the actual restart.
- [ ] **Restore:** gears, rotor and completion state are consistent after quit/relaunch; retry/hint evidence stays supported rather than independent.
- [ ] **QA anchor:** every gear retains full interaction area, incorrect -> retry -> correct, Rotor/shaft state, 4:3 readability and no replacement of canonical art.

## PR batching, dependencies and proposed merge order

**Small PRs, independent learning semantics, one room's visible behavior per PR.** Branch from latest main, not a sibling PR. Where room variants share the large PuzzlePalaceScene.swift file, integrate serially; after a merge, re-check touching hunks and rerun required native checks. Never force-update another PR and silently discard changes.

| Wave | Room(s) / artifact | Concrete output | Merge/review dependency |
| --- | --- | --- | --- |
| **G0 — lock visual direction** | Entire ten-room pack, master tracker #181, this plan | 40-state **real Simulator** contact sheet, exact SHA, one signed reference board; verify original Steam title/URL | Owner must sign the visual direction BEFORE unrestricted styling rollout |
| **G1 — physical proof** | Rune Gate #180 + Repair Lab (baseline #172, new scoped polish as needed) | Two approved physical interaction proofs with wrong/correct/revisit states; Path Tiles #179 supplies an additional stone-material proposal | #180 has a pending width-fix CI rerun; #179/#180 are **not auto-merge** owner approvals |
| **G2 — foundational rooms** | Memory Bridge; Stop/Go Orbs (#170 baseline) | Two separate focused polish PRs with before/after native gallery | G0/G1 material/affordance decisions locked |
| **G3 — classification pair** | Sorting Pedestal #178; Re-sort Vault (#171 baseline) | Retained physical object sorting followed by a visible changed-rule encounter | Review #178 first; reuse and validate one shared alcove vocabulary |
| **G4 — palace optics and paths** | Mirror Hall (#173 baseline); Path Tiles #179 | Real optics correction and grounded stone crossing; distinct silhouettes | Owner checks both palettes/materials; #179 merge requires approval |
| **G5 — linked machines** | Command Gears #176; Bug Lantern #175; Repair Lab final polish | Gear execution, diagnosable failure, and repaired rotor as three distinct coherent physical systems | Review compatible incoming #175/#176 separately; do not merge overlapping scene/test hunks without fresh validation |
| **G6 — harmonize** | All ten, integration-only PR if needed | Quiet HUD, perspective/material consistency, sound, travel route, 4:3 and 16:9 cleanup | Every room has its visual approval and no unresolved blocker/major |
| **R — device/release** | Issues #118, #141 and #116 | Signed physical device, teacher and art review artifacts on final release SHA | Separate release gates; green Simulator is insufficient |

**Current open-PR integration guidance:** #175, #176, #178 and nonvisual #177 have green CI at the inventoried heads but require actual integration/visual checks (except the docs/scripts-only nature of #177). #179 and #180 stay in **owner visual review** even after green CI. This is not a command to merge on a timer; each dependency must be validated on the resulting codebase. Do not use a green earlier-run commit as a substitute for head-check completion.

## Exact per-room QA sequence (every room and every meaningful variant)

### Preparation

- [ ] Pin repo, PR URL, **exact head SHA**, base/main SHA, scene name and issue links in a separate [room QA record](PUZZLE_PALACE_ROOM_QA_RECORD_TEMPLATE.md).
- [ ] Save one untouched baseline shot from the merged main of the same named room/state/camera and exact old SHA.
- [ ] Confirm original approved asset names and resolution; record any newly proposed art under #116 without merging it into a gameplay PR.
- [ ] Confirm first-time world entry, prerequisites, support state and current saved profile; do not inject fake skill mastery except **test fixtures** clearly identified as fixtures.

### Runtime interaction pass

- [ ] Child can locate an in-world object from one glance, hear a short narration and start by tap-to-approach; Valkyrie and Tiko stay visible and move/act meaningfully.
- [ ] One normal valid touch and one edge-of-hit-area touch register; nominal interactive area **at least 60pt** if spatially possible. Decorative children cannot steal touches.
- [ ] Try rapid double-tap, second finger, tapping a different object during travel, and a stray background tap: no duplicate scoring or stranded animation/input lock.
- [ ] Perform a wrong attempt and document **which exact physical object moved or failed**. No false “working part broken” color, premature crossing, wrong shutter or empty feedback.
- [ ] Recover with retry/undo or hint; a subsequent correct attempt should visibly succeed but retain **assisted** support classification after help.
- [ ] Perform an independent correct attempt on a clean trial; verify only authored independent evidence moves skill/progression and that feedback precedes any route transition.
- [ ] Trigger any partial/busy/incomplete states; verify neither extra evidence nor rewards until the child completes the actual authored manipulation.
- [ ] Replay and revisit; puzzle does not create new evidence simply on scene load, visual restoration, or decorative animation.
- [ ] Check character scale/collision, floor and prop perspective, clipping, text truncation, and door/route touch interference at **1024×768** and wide **1280×720**. Test both landscape directions on a real device under #118.
- [ ] Enable Reduced Motion and repeat wrong/success/restore; **instant legible end states** replace movement, not missing feedback.
- [ ] Verify VoiceOver element labels describe the meaningful object/action/direction, do not reveal the correct answer before testing and identify real status without depending on color alone.
- [ ] Force-quit and relaunch mid-encounter and after completion; repeat in airplane mode on a physical device for #118. Attempt/support/order/room state restore with no double reward/evidence.

### Native screenshot evidence (minimum per room)

- [ ] **Initial** — first unseen problem, no hidden correct answer revealed.
- [ ] **Incorrect/partial** — actual attempted wrong action, physical refusal/miss/stall and retry affordance.
- [ ] **Successful** — correct action's physical transformation and functional companion response.
- [ ] **Restored** — completed room after a fresh scene load / persisted progress, no leftover answer controls.
- [ ] Include extra state captures as applicable: rule change, two-pass sort, stopped path, bridge lower/cross/raise, rejected/assisted rune fit, clockwork wrong swap, Reduced Motion, wide-canvas layout.
- [ ] Export from the **actual Simulator/XCTest run**, not image generation or stitched mock scenes; attach original `native-scene-preview` / `native-scene-review` artifact and 4-up comparison to the issue/PR. Labels give run URL and SHA.
- [ ] Compare *same crop and scale* old versus proposed; owner accepts or requests a specific change. Visual sign-off checkbox stays empty until the owner does so.

### Required automation and outcome invariants

- [ ] `learning-core` passes on exact head.
- [ ] `native-validation` passes on exact head.
- [ ] `ipad-build-and-tests` passes on exact head; real 4:3 screenshots exist and have been inspected.
- [ ] Touch hit/name regression passes; no unreachable interactables, app crashes, warning-level clipping or animation deadlocks.
- [ ] Untouched -> no evidence; incomplete -> no completion; wrong -> incorrect; correction with hint -> assisted; eligible independent correct -> precisely one expected record.
- [ ] Skill fingerprint, encounter IDs, assessment catalog answers and mastery gate unchanged; no fake reward, early route opening or duplicated completion event.
- [ ] SwiftData save/restore and offline state unchanged; if visual change affects persistence expectations, add a real regression instead of mocking state success.
- [ ] After integration on advanced `main`, rerun affected checks and verify visual outputs reflect **the merged code**, not only the old head branch.

## Severity and quality decision

| Severity | Examples | Accept/merge rule |
| --- | --- | --- |
| **Blocker** | Crash, score/milestone falsification, no exit/retry, missing critical asset, unsafe/offscreen mandatory hit target, save corruption | **0 open**; fix and retest |
| **Major** | Wrong physical feedback, unreadable rune on iPad, beam/gate disconnected, clipped controls, broken Reduced Motion outcome, visually misclassified objects, touch-intercepting decorative props | **0 open**; fix or explicit product decision recorded before proceeding |
| **Minor** | Slight bevel/texture variance, noncritical ornament placement, subtle highlight balance | Record exact screenshot/coordinate; only proceed if owner explicitly accepts remaining deviations |

Do not claim an acceptance category complete based on test count. Actual interactive cause/effect, child comprehension and owner visual review decide.

## Definition of done

**A single room is DONE only when all are true:**

1. The six-part storyboard and golden-master visual language are followed; the room still has its distinct physical identity.
2. Initial, incorrect, successful and restored **real** 4:3 images are captured and reviewed with screenshot filenames, native artifact URL, old/new commit SHA and reviewer decision.
3. Native evidence and all three CI checks are green on the latest head/integration SHA; exact touch/VoiceOver/Reduced Motion and offline/relaunch regression cases are documented.
4. No blockers or majors remain; any minors are explicitly acknowledged in the room record.
5. The designated owner approves the visual change where required; approval cannot be inferred from a merged behavior PR.

**Puzzle Palace visual wave is DONE only when all ten rooms are DONE:**

- [ ] Ten owner-reviewed room records, no skipped room.
- [ ] Forty actual native core-state images, versioned contact sheet and golden-master SHA approved.
- [ ] All room-to-room gates/routes, companion actions, naming/affordance/HUD/materials checked together after final integration.
- [ ] All three CI checks green at the **final integrated main SHA**, and no known blocker/major.
- [ ] The visual contract is explicitly marked owner-approved/design-frozen only after actual owner decision.

**Production release is NOT DONE** until the independent real-iPad #118, educator #141 and artwork #116 reviews complete on the relevant release SHA. A finished Palace visual wave does not by itself release the app.

## Minimal handoff and PR description

Every room PR should contain:

1. **Observed before-state defect:** screenshot filename/run + what a five-year-old experiences, not a subjective claim like “looks generic”.
2. **Changed physical behavior and visual materials:** exact named props, interaction sequence, and approved asset source.
3. **Safeguards:** what was deliberately not changed (SkillIDs, learning, characters, save, room identities).
4. **Test evidence:** links to head-SHA green CI, named XCTest regressions, Reduced Motion and 4:3 screenshot artifacts.
5. **4-state comparison:** before/after on the same camera and named room, any blockers/majors/minors, reviewer name/date and outstanding decisions.
6. **Merge decision:** compatible latest `main`, no red tests, no stale picture, explicit owner sign-off if visual direction was changed.

Use [PUZZLE_PALACE_ROOM_QA_RECORD_TEMPLATE.md](PUZZLE_PALACE_ROOM_QA_RECORD_TEMPLATE.md) for every room and track sign-offs centrally in [issue #181](https://github.com/erwinmehehe/valkyriegame/issues/181).

## Open external decisions and linked gates

- Original **Steam title/URL remains unknown** in the repo; ask the owner to verify it, do not invent one.
- Owner has requested a non-generic polished game, but has **not yet signed** the master 40-state storyboard or approved #179/#180 screenshots for merge.
- Art source replacement quality/resolution #116 is separate from the gameplay prop-polish track.
- Physical iPad #118 requires an identified device/iPadOS and tester with actual signing/installation; don't call Simulator evidence physical acceptance.
- Curriculum review #141 requires human evidence and appropriate DepEd crosswalk; do not conflate code coverage with official validation.
- A stopped/queued CI runner is a *pending* status; never claim a pass, and never schedule an unconditional merge.

**Versioning note:** This is a working production plan; update the status matrix after every merged PR and major owner decision. Do not rewrite the art direction without a recorded exception to the agreed golden master.
