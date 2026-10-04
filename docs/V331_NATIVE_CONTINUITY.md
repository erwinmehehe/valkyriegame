# v3.31 / The Lost Starlight continuity audit

Audited on 2026-10-04 against the exact supplied reference files:

- `ValkyrieLearn-v3.31-Play(1).html` (31,109,627 bytes; title: “Valkyrie v3.31 · The Lost Starlight”).
- `ValkyrieLearn-v3.31-Word-Garden-RC.zip` (66,595,708 bytes), including `ART_V331.md`, `QA_V331.md`, chapter implementation notes and the separate `preview/adventure-art` sources.

This is a continuation of the adventure's product and art direction through a native implementation. The Swift/SpriteKit implementation replaces the browser runtime under the locked production architecture. Earlier native PRs remain the foundation; they are not being discarded. The HTML and ZIP are references, not a production WebView or a claim that their features already run natively. Historical notes inside the ZIP describe different release stages; the actual v3.31 runtime is the feature baseline.

## Verified baseline and current gap

| v3.31 reference | Native implementation at this pass |
| --- | --- |
| The Lost Starlight: recover four world lights for the Story Tree; reach the Grand Gate | Story Tree and Math Castle navigation exist. Chapter story, world-return beats and finale are not ported. |
| Valkyrie walks through the world; companions operate physical mechanisms | Valkyrie approach/engagement and in-scene Pip exist. Characters still use explicitly temporary procedural art. |
| Illustrated Starlight Isles with visible player, routes and destinations | Story Tree is a placeholder home scene. Illustrated overworld and progression changes are not ported. |
| Flower Gate → Sunmill Crossing → Story Hollow, with forward/backward traversal | Word Garden is not in native scope yet. Preserve this connected spatial design for its later migration. |
| Letters activate flowers; Lumi operates high mechanisms; child rotates a waterwheel and carries a song seed | Native Math Castle has direct manipulation and environmental machines. Garden mechanics are not ported. |
| Return to the old hollow after restoring the canal AND delivering the seed; earn a persistent moon lantern | No native equivalent yet. Preserve the remote prerequisites, return journey and one-time reward rather than replacing them with a generic reward button. |
| Discoveries, keepsakes, wearable rewards and chapter state persist separately from learning mastery | Native learner, encounter, placement, settings and math activity saves exist. Chapter/discovery/reward persistence is not implemented. |
| Illustrated environments, character action poses, light-led composition and restrained controls | Asset replacement boundary exists. Current scene rendering has not met visual acceptance. |

## Existing source art to carry forward

The ZIP contains separate PNGs in `preview/adventure-art`: `overworld.png`, `worlds.png`, `props.png`, `valkyrie-poses.png`, `valkyrie-garden-actions.png`, `lumi-flight.png`, `flower-gate.png`, `sunmill-crossing.png` and `story-hollow.png`. They are reusable source material, not missing work that must automatically be regenerated. They have not been imported into the native Resources directory in this pass.

Before native use, inspect and separate atlas frames/props, retain alpha, establish world-space anchors, and verify walkable paths and interactive object clearance. A painted environment alone does not supply collision, traversal, touch targets or environmental reactions. Use the existing ArtSystem/actor boundary rather than coupling learning logic to image coordinates.

## Acceptance for the next visual pass

Keep the current native math systems. Within Story Tree and Math Castle, carry forward the source artwork and rebuild composition around foreground → Valkyrie/Pip → physical problem → middle ground → visible destination → atmospheric background. Validate protagonist scale, movement, interaction lighting, readable routes and restrained chrome on iPad. Complete one coherent native scene before expanding worlds.

The next learning milestone remains scaffolding, spaced review and the prerequisite-safe Challenge Gate. Neither that work nor passing automated tests should be reported as completion of the Lost Starlight story or visual direction. Physical iPad playtesting is still required.
