# First native v3.31 art integration

Continues the native math flow from PR #9; does not rebuild the HTML prototype.
Serves roadmap Phase 1 character/world proof and the documented visual direction.

## Changes

- Imported existing v3.31 overworld, Math Castle quadrant, Valkyrie action poses,
  canonical Pip and physical cart/crystal art into native asset catalogs/atlases.
- Shared character canvases preserve foot anchors across poses. Walking changes
  facing; machine engagement faces the physical workbench. Reduced motion retains
  spatial movement and removes ambient bounce/breathing.
- Story Tree uses the illustrated Isles, one castle destination sign, a touchable
  story light and Pip's non-academic gear interaction. Valkyrie and Pip follow the
  painted stair/bridge waypoints; void taps are ignored and depth changes scale.
- Math Castle keeps the five adaptive mechanics and save format. A brass rack
  offers workshop choices through symbols, Pip himself provides help, a physical
  lever submits work, and success lights the route toward the castle destination.
- Separate foreground corner layers, actor depth and a source-textured courtyard support
  foreground → player/companion → workbench → destination/background composition.
- Child-facing workshop implementation labels and placeholder banners are removed;
  world chrome is back + title. Settings remains accessible at Story Tree.
- Source provenance and reproducible import script are committed; no browser code,
  old curriculum bank or WebView is used.

## Math Castle physical-progression refinement

The next illustrated pass restores the strongest interaction structure from the
v3.31 reference without restoring the browser runtime:

- successful manipulation now causes visible cause-and-effect through the room:
  the active machine reacts, starlight travels through a conduit, route lamps wake
  in sequence, decorative gears turn, a physical bridge unfolds, and the next
  destination begins glowing
- the child must physically follow the opened route before the next adaptive work
  order is selected; "next" is no longer only an immediate state change
- Pip visibly leaves Valkyrie's side to help the machinery after a successful solve
  and uses a short helper-hop/operate animation
- Valkyrie's success and retry poses are slightly longer and more readable
- Crystal Cart moves toward the powered route on success and is scaled closer to
  the original reference composition while retaining a child-sized native hit area
- Balance Scale, Number Bond Machine, Ten Frame Gate and Missing Number Bridge each
  provide their own success animation instead of only changing text
- every valid manipulation lightly wakes nearby gears without revealing whether
  the answer is correct
- incorrect work keeps the route closed and uses a gentle machine wobble/power flicker
  before Pip scaffolds; there is no punitive failure animation
- reduced-motion mode applies the final environmental state immediately without
  route, bridge, gear, helper-hop or celebration travel animation
- relaunching/re-entering an already completed work order restores the powered
  environment without replaying the success sequence
- Math Castle character scale is reduced so Valkyrie sits inside the composition
  rather than covering the workbench and route

This remains presentation/game-feel work only. Correctness, hidden placement,
mastery, review, Challenge Gate rules and persistence remain in LearningCore/AppState.

## Validation

Static project/resource/hash checks and 53 Linux core tests pass. Native hosted
checks cover actual bundled art, all actor poses, facing, reduced motion, cart
input and powered destination feedback. The CI workflow exports rendered SpriteKit
scene attachments for visual review. Xcode/simulator verification is pending at
initial publication; passing results must be reported against the tested commit.

The initial native run (37204471879, head d62e1745f24737b42992a370650efefcfbc123eb)
passed 71 simulator tests. Review of its actual captures prompted corrections to
transparent hit-area outlines, courtyard grounding and painted-map path traversal.
The follow-up implementation must be verified again before acceptance.

## Still pending

Physical iPad playtesting, complete animation action sets, deeper layer-separated
art, ambient life and final touch/visual acceptance. The full Lost Starlight chapter,
other worlds, rewards, journal and Grand Gate are not implemented by this art pass.
The castle destination reacts to power but does not open a new world/area yet.

Next: review the actual simulator captures and on-device movement/interaction,
then finish scaffolding, delayed review and the optional Challenge Gate within the
existing Math Castle vertical slice.
