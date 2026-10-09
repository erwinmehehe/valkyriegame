# ValkyrieLearn - one-time production visual and gameplay contract

Status: **Proposed for one owner sign-off.** The production principles below are already established in `AGENTS.md` and `docs/GAME_DESIGN.md`; this document makes them testable and stops ad-hoc redesigns. Do not claim owner-approved visual sign-off until the Steam inspiration is identified and the reference board is accepted.

## Decision: what we are building

A **native, illustrated 2D/2.5D iPad adventure**, not a worksheet, a quiz app, a free-roaming 3D/platform game, or a web prototype. The child explores connected places, encounters an obstacle, directly manipulates objects, observes physical consequences, receives contextual help, opens a route, and revisits the changed world. Adaptive learning and evidence recording remain underneath that experience.

**Locked native architecture:** Swift + SpriteKit gameplay + SwiftUI shell/parent area + SwiftData offline persistence + AVFoundation audio; landscape iPad, guided tap-to-move and direct touch. Keep the canonical protagonist in `ValkyrieLearn/Resources/Valkyrie.atlas`, the approved companion identities, existing learning/evidence systems, persistence, and story progression.

**One source of visual truth:** the current approved painted world artwork and canonical protagonist, then a single signed-off contact sheet of native 4:3 iPad compositions for every world. Use a named Steam game *only after its exact title/URL is verified by the owner* as a high-level pacing/composition benchmark; never reproduce copyrighted characters, art, interfaces, or levels. The original user-supplied reference image mentioned in `docs/GAME_DESIGN.md` is not committed. The exact Steam title is NOT documented in the repository: **do not guess**.

## Global visual contract - no more separate styles per feature

1. **One authored painterly universe.** Warm storybook fantasy with consistent perspective, atmospheric depth, grounded brass/stone/wood/glass/foliage materials, shadows, rim light, and warm/cool color relationships. Room palettes can vary within the existing world identities, not become unrelated UI themes.
2. **Readable 4:3 composition.** Evaluate on real 1024x768 simulator captures in both landscape orientations, also consider the wider design canvas. The hero is visually present and can occupy about 15-20% of a scene when appropriate. Layer foreground -> playable actors -> manipulable props -> midground -> meaningful destination -> atmosphere. Keep interactions within the safe iPad viewport.
3. **Environment-first challenges.** Objects belong to the illustration's world: a rune fits a stone lock, a gear turns a machine, water feeds a seed, a plank bridges a chasm. No generic floating choice plates, grids of indistinguishable dark rectangles, punctuation/symbol-only interactions, or neon halos standing in for real environmental response.
4. **One game-wide affordance language.** Tap-to-approach, drag/place, turn, pull, slide and retry must look and feel consistent. Touch targets should normally be at least 60pt across when spatially possible; preserve accessible labels and Reduced Motion equivalents.
5. **Quiet HUD.** One consistent home affordance, a compact area name, and one short contextual prompt (with spoken support where needed). No large translucent instruction slab covering play, redundant signs, instructional paragraphs, or dozens of progress lights. Native interactive props visually lead the eye.
6. **Every answer has a visible physical outcome.** Wrong or partial input leaves an observable and safely retryable consequence; correct input transforms the relevant world object and character behavior. A glowing checkmark alone is not an outcome.
7. **Characters act, not watch.** Valkyrie approaches and interacts; Pip/Lumi/Tiko/Milo use their established abilities and react at the obstacle. No imported or newly redrawn substitute for the canonical protagonist.
8. **High-resolution assets without fakery.** New background replacements are original *environment-only*, preferably 4:3 Retina 2560x1920 or higher as in issue #116, with no baked-in player, answers, HUD or touch targets. Do not pass upscales, collage crops, or flat candidate vectors off as finished paintings. Keep approved art in use until side-by-side owner approval.
9. **Fair, age-accessible learning.** The first target is a strong age-five/Kinder 2 child. Pre-readers must understand the physical goal through narration, demonstration and cause/effect; deeper reasoning can unlock with demonstrated readiness. Never infer mastery from an untouched action. Preserve correct/incorrect/scaffold evidence integrity, offline restore, and non-punitive replay.
10. **No feature creep during the visual pass.** No new worlds, currencies, reward loops, backend, random prizes, gameplay engine switches, or character redesigns. Fix presentation around existing encounters; avoid replacing the curriculum and persistence systems.

## Mandatory world roles

| World | Core playable fantasy | Physical feedback to preserve/achieve |
|---|---|---|
| Story Tree | Living hub and persistent home | Earned objects become placeable and remain across sessions |
| Math Castle | Help Pip operate tangible mechanisms | Crystals, cart, scales, machines, gates and bridges change physically |
| Word Garden | Help Lumi tend a responsive garden | Plant, water, shade, grow, retrieve and revisit persistent life |
| Science Lab | Explore with Milo through physical experiments | Change materials/light/conditions and see observable outcomes |
| Weather Tower | Experiment with wind, weather and rescue | Sail/fan choice moves the craft; rescued kite persists |
| Puzzle Palace | Help Tiko restore magical palace machinery | Every room is a distinct in-world obstacle, never a worksheet panel |

## Puzzle Palace - exact redesign scope (keep 10 existing room identities and assessment models)

| Existing room | Final child-facing physical interaction / result |
|---|---|
| Rune Gate | Insert a carved rune into a stone mechanism; the authentic gate unlocks/opens, floor route lights guide the exit |
| Memory Bridge | Repeat a short observed light sequence using in-world bridge stones; each correct stage raises a plank Tiko can cross |
| Stop/Go Orbs | React to the orb signal while a visible powered barrier responds; stopped/running states are visually unambiguous |
| Sorting Pedestal | Place pictured/material objects into sculpted alcoves; pedestals react to the chosen property |
| Re-sort Vault | Same tangible object collection under a changed rule; shelves/pedestals visibly reconfigure |
| Mirror Hall | Rotate/flip embodied mirrors or tiles; light and object orientation make the spatial result understandable |
| Path Tiles | Arrange a navigable path and watch Tiko physically traverse it, stopping safely for unsuitable routes |
| Command Gears | Put three mechanical instruction gears into a track, pull TEST, watch the linked mechanism execute each command |
| Bug Lantern | Observe a sequence failing at one step; identify and replace the actual broken component to relight the lantern |
| Repair Lab | Swap the two out-of-order command components on a real clockwork rail and pull FIX; the repaired machine visibly works |

Implementation note: these are **presentation and interaction targets**, not permission to rewrite the existing underlying reasoning/recording requirements. A correct guess must not bypass the currently required task conditions; wrong attempts do not punish or trap the child. When a tactile redesign conflicts with an existing test or evidence rule, resolve explicitly before changing that rule.

## Stop-the-redesign production sequence

1. **Reference capture and sign-off ONCE.** Confirm the precise Steam game/title or URL plus any user-supplied original art. Assemble one contact sheet covering all six world identities and all ten Puzzle Palace rooms, with a close-up physical-objects/interaction sample for Rune Gate and Repair Lab. Record approved screenshots, source assets and exact SHA. Do **not** present concept art as a native build.
2. **Storyboards for the entire ten-room Palace in one review.** Each storyboard shows (a) problem, (b) child input, (c) observable unsuccessful/partial response, (d) successful environmental transformation, (e) companion role, (f) return visit. Fix composition and art/prop style in this one batch.
3. **Two native interaction proofs.** Build Rune Gate and Repair Lab only after the full storyboard review, from the same physical-prop rendering system and scene conventions. Validate on actual 4:3 iPad Simulator screenshots and child-understandable actions. This proves the pattern for the remaining eight, not a new design cycle.
4. **Freeze and implement the remaining rooms in batches.** Preserve assessment catalogs, LearnerProfile, save schema and canonical sprites. Extract reusable world/prop components from the large monolithic `PuzzlePalaceScene.swift` where safe. Changes after this point are bug fixes, accessibility fixes or failures against the accepted storyboard - NOT another aesthetic redesign.
5. **One release QA gate.** Native `learning-core`, `native-validation`, `ipad-build-and-tests` on the exact PR head; ten-room screenshot review; real tap/drag; wrong/correct/retry, reduced-motion, offline save/restore; completion/revisit; physical iPad and child acceptance documented under issue #118. Educational validity and curriculum review are separate gates.

## Non-negotiable acceptance checklist for each Palace room

- [ ] It looks like one coherent painted scene with physical, grounded interaction props, not unrelated icons pasted over a background.
- [ ] In one glance a pre-reader can tell which object to touch and what is visibly broken/missing.
- [ ] The result of touching/turning/placing an object is spatial and immediate, not only a label or glow.
- [ ] Correct, incorrect and incomplete inputs each show clear, non-shaming responses with repeat/undo.
- [ ] Valkyrie and Tiko have a visible functional role, not just an idle sprite.
- [ ] The room has its own silhouette and theme but uses the same materials, camera language, HUD and touch conventions.
- [ ] Native 4:3 capture and on-device interaction are reviewed; no false claims that a composite screenshot is a native render.
- [ ] Save/restore, accessibility, reduced motion, learning evidence, and existing progression still pass tests.
- [ ] Any proposed new visual style is rejected unless the owner explicitly reopens the locked design decision.

## Owner sign-off (single outstanding factual item)

- [ ] Verify the exact **Steam game title/URL** used as the original inspiration. The existing repository does NOT name it. Its role is a high-level visual/experience benchmark, not an asset-copy instruction.
- [ ] Approve the complete cross-world visual storyboard/contact sheet as the **golden master** with revision and commit SHA.
- [ ] After approval, set this document's status to **OWNER APPROVED - DESIGN FROZEN**, and do not reopen aesthetic debates in individual feature PRs. Changes beyond fixes against the master require a specific owner-approved exception.

## Existing source-of-truth documents

- `AGENTS.md`: platform, canonical character, style and gameplay constraints.
- `docs/GAME_DESIGN.md`: core loop, companion roles, physical gameplay, world depth and no floating panels.
- `docs/IMPLEMENTATION_ILLUSTRATED_WORLDS_V2.md`: historical image quality limitations; not proof of Retina source artwork.
- Issue #116: original 4:3 Retina environment asset gate.
- Issue #118: physical iPad acceptance gate.
- PR #119: candidate Science vectors remain **review-only**, not approved replacements.
