# Puzzle Palace — per-room native visual QA and approval record

Copy this **template once per room per proposed change**. Every answer must link to an actual PR, test run, native screenshot, commit or human reviewer observation. Mark **N/A only with a reason**. A filled checklist is not automatically an owner or device approval. See [ten-room master plan](PUZZLE_PALACE_VISUAL_POLISH_MASTER_PLAN.md) and [rollout issue #181](https://github.com/erwinmehehe/valkyriegame/issues/181).

## Review identity

| Field | Value |
| --- | --- |
| Palace room / variant | **TODO** |
| Issue and PR links | **TODO** |
| Main/baseline SHA and branch SHA | **TODO** |
| Exact head SHA tested / run URL | **TODO** |
| Target platform | Native SpriteKit iPad landscape |
| Viewport / rotation | 1024×768 required; 1280×720 safety; both rotations for device |
| Existing approved painting and source asset | **TODO** |
| Changed/new room prop assets (or none) | **TODO** |
| Canonical character atlas unchanged | [ ] Yes [ ] No |
| Owner-approved golden-master sheet + version/SHA | **TODO — blank means not approved** |
| Technical reviewer / date | **TODO** |
| Visual owner reviewer / date | **TODO — blank means not approved** |
| Curriculum and physical device review links, if separately complete | **TODO / not approved** |

## Child-facing physical story

**Initial problem and affordance (one-glance):** TODO.

**Child's actual touch / manipulation, character and companion actions:** TODO.

**Wrong / partial result and safe recovery (not merely a color):** TODO.

**Correct environmental transformation (not merely a check mark):** TODO.

**Revisited/restored world, including any active mechanism/exit:** TODO.

**Differences from approved storyboard and owner decision:** TODO.

## Required native screenshot comparisons

All images below must be **genuine Simulator/XCTest captures**, from a named run and exact head SHA, at **1024×768 4:3**. If an image is a design reference or hand-edited composite, label it as such and do not use it for acceptance.

| State | Baseline/main screenshot (SHA + link) | Proposed screenshot (SHA + link) | Reviewer verdict / specific defect |
| --- | --- | --- | --- |
| Initial / before input | TODO | TODO | TODO |
| Incorrect / partial | TODO | TODO | TODO |
| Successful / environmental change | TODO | TODO | TODO |
| Restored / after relaunch | TODO | TODO | TODO |
| Additional rule/variant state (if applicable) | TODO | TODO | TODO |
| Reduced Motion wrong + successful | TODO | TODO | TODO |
| 1280×720 / wider camera (if applicable) | TODO | TODO | TODO |

**Original artifact names and source CI run:** TODO.

## Exact acceptance — interaction, visual, evidence

Mark each PASS/FAIL/N/A and link a source. **Do not pre-check** before a real run.

### Native composition and artwork

- [ ] Approved painting remains the source of truth; new painting is not substituted before #116 owner acceptance.
- [ ] Game looks like the **same** painterly stone/brass/wood/glass world as the golden master; props are grounded and scaled to the mural.
- [ ] No generic floating quiz tiles, giant HUD overlay, disconnected black rail, ghost control, irrelevant icon or neon-only effect.
- [ ] Valkyrie and Tiko remain canonical, clearly visible and functionally involved.
- [ ] All important objects/labels visible and readable at real 4:3 screen scale, without clipped HUD at 16:9.
- [ ] Signals and correctness can be distinguished without color alone; no answer is leaked before the child's action.

### Controls and accessibility

- [ ] At least 60pt usable direct-interaction regions wherever spatially possible; edge-of-target tap checked.
- [ ] Decorative nodes cannot steal or shadow scored named parent taps.
- [ ] First tap approaches the physical obstacle; direct manipulation occurs only at correct interaction stage.
- [ ] Rapid double tap, second-finger touch, interrupted travel, stray background touch do not cause duplicate evidence/route transitions.
- [ ] Meaningful VoiceOver/accessible labels describe object/action/status and do not narrate a correct answer prematurely.
- [ ] Reduced Motion displays the **same final** wrong, correct, and restored states without relying on animation.

### Learning and retry integrity

- [ ] Untouched -> no completion/evidence.
- [ ] Incomplete -> no completion/evidence.
- [ ] Incorrect action -> one correct incorrect record; local physical failure is visible and safe to retry.
- [ ] Hint / demonstration -> assisted evidence only, never accidental independent mastery.
- [ ] Clean independent correct -> precisely one authored correct record and stage transition only when prerequisites hold.
- [ ] Attempt count, skill ID, encounter/fingerprint/variant family, mastery gates and reward behavior unchanged.
- [ ] Child can retry/reset/undo a wrong or partial action without getting trapped or losing a valid choice.

### World, persistence and performance

- [ ] Physical world result changes the **specific obstacle** that the child touched, and Tiko/Valkyrie respond.
- [ ] Post-success route is navigable; no tap collision with another pedestal, passage, HUD or locked route.
- [ ] After exit/re-entry and force quit/relaunch, progress, assistance and physical world state match recorded evidence.
- [ ] Offline restore on physical iPad is documented separately in #118; do not infer it from a Simulator screenshot.
- [ ] No large frame stalls, camera jumps, severe overlapping effects, stretched textures, cropped characters or duplicate rewards.

### CI and regression

- [ ] `learning-core` green for **this exact head SHA** — URL: TODO
- [ ] `native-validation` green for **this exact head SHA** — URL: TODO
- [ ] `ipad-build-and-tests` green for **this exact head SHA** — URL: TODO
- [ ] Named room-specific XCTest cases passed — names/URLs: TODO
- [ ] Native preview and full-resolution capture artifacts inspected (not merely generated) — URLs: TODO
- [ ] Result of compatibility check/retest after prior PR merges into `main` — SHA / URL: TODO

## Defect ledger

| Severity | Reproduction / screenshot | Owner | Fix PR and retest result | Resolution |
| --- | --- | --- | --- | --- |
| Blocker | TODO / none confirmed | TODO | TODO | Open / fixed |
| Major | TODO / none confirmed | TODO | TODO | Open / fixed |
| Minor | TODO / none confirmed | TODO | TODO | Open / accepted |

**Decision rule:** zero blockers and majors before merge. All minor deviations must be documented and accepted by the relevant owner; “no defects observed” still requires a reviewer and test evidence.

## Final signatures — do not pre-fill

- **Engineering / native CI:** [ ] Approved; reviewer, date, exact SHA and URL: TODO
- **Visual owner:** [ ] Approved **against a named golden master**; reviewer, date, exact SHA and contact-sheet reference: TODO
- **Room integrated into main:** [ ] Yes; squash/merge SHA and post-merge CI link: TODO
- **Full ten-room owner review:** [ ] Completed in #181; golden-master version and SHA: TODO
- **Physical iPad device gate #118:** [ ] Completed by a real tester on release SHA: TODO
- **Curriculum/teacher gate #141:** [ ] Completed with human record: TODO
- **Artwork gate #116:** [ ] Completed where original art changed: TODO

### Room status

- [ ] **IN DEVELOPMENT** — checks/screenshots incomplete or visual approval pending
- [ ] **ROOM VISUALLY APPROVED** — owner accepted exact four-state screenshots and all room quality checks
- [ ] **INTEGRATED** — approved room merged with current native CI green
- [ ] **DEVICE / RELEASE APPROVED** — requires external human gates, *not implied* by any of the above

Do not check a status if its mandatory evidence is missing; use one status with a dated note. Different gates are not interchangeable.
