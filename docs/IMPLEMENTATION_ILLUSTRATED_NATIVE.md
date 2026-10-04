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
  story light and Pip's non-academic gear interaction.
- Math Castle keeps the five adaptive mechanics and save format. A brass rack
  offers workshop choices through symbols, Pip himself provides help, a physical
  lever submits work, and success lights the route toward the castle destination.
- Separate foreground corner layers, actor depth and native stonework support
  foreground → player/companion → workbench → destination/background composition.
- Child-facing workshop implementation labels and placeholder banners are removed;
  world chrome is back + title. Settings remains accessible at Story Tree.
- Source provenance and reproducible import script are committed; no browser code,
  old curriculum bank or WebView is used.

## Validation

Static project/resource/hash checks and 53 Linux core tests pass. Native hosted
checks cover actual bundled art, all actor poses, facing, reduced motion, cart
input and powered destination feedback. The CI workflow exports rendered SpriteKit
scene attachments for visual review. Xcode/simulator verification is pending at
initial publication; passing results must be reported against the tested commit.

## Still pending

Physical iPad playtesting, complete animation action sets, deeper layer-separated
art, ambient life and final touch/visual acceptance. The full Lost Starlight chapter,
other worlds, rewards, journal and Grand Gate are not implemented by this art pass.
The castle destination reacts to power but does not open a new world/area yet.

Next: review the actual simulator captures and on-device movement/interaction,
then finish scaffolding, delayed review and the optional Challenge Gate within the
existing Math Castle vertical slice.
