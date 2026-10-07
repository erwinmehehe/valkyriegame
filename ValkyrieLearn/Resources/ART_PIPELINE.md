# Native adventure art boundary

The native app now includes approved v3.31 source artwork in `AdventureArt.xcassets`,
`Valkyrie.atlas` and `Pip.atlas`. This replaces the earlier engineering characters
and environment shapes in Story Tree and Math Castle. It is a first illustrated
integration, not final animation or physical-iPad acceptance.

`V331_ART_MANIFEST.json` records source/archive hashes and exact output hashes and
sizes. Reproduce the import with Pillow installed:

```sh
python3 scripts/import_v331_art.py --source-zip /path/to/ValkyrieLearn-v3.31-Word-Garden-RC.zip
python3 scripts/generate_xcode_project.py
python3 scripts/validate_native.py
```

The ZIP remains external reference material. Only resources used by the current
native scenes are imported. The math backdrop is the upper-right quadrant of
`worlds.png`, cropped past the grid seam. Overworld and math images are exported at
1280×720 high-quality JPEGs (quality 92). Transparent
actors and props remain PNGs. Corner foreground crops use feathered alpha and are separate occluders.
Cart/crystal source props retain alpha; their hit areas and quantities are native.
A feathered crop of the painted castle floor supplies the live foreground courtyard.
Story Tree movement follows explicit waypoints along the illustrated stairs/bridge;
taps in the chasm are ignored and characters scale with depth along that route.

Valkyrie's supplied idle, two walk/contact and crouching reach poses share a
370×480 atlas canvas, source scale and bottom foot anchor. Celebration/reaction use
the supplied idle art with short native motion; they are not newly drawn poses.
Pip now uses the approved HD sky-blue reading companion from the companion art
refresh. The existing `idle/walk/interact/react/celebrate` atlas names remain a
stable gameplay boundary. This refresh intentionally places the same approved
320×320 base pose under each pose name while CharacterNode supplies native
movement, facing and reaction timing; it does not claim authored frame-by-frame
animation coverage.

At 1280×720, Valkyrie's atlas canvas height is 300 points and Pip's gameplay render
height is 145 points. Pip's 320px source therefore exceeds 2× presentation density.
Review actual silhouette, foot registration, occlusion, readable physical routes
and large touch areas on the target iPad. True per-pose companion animation and
foreground layer separation can continue as later art-production work.

The four short WAV files remain temporary SFX. Educational narration/phonemes
must be deliberately recorded and separately versioned. No browser speech or
external assets are loaded at runtime.

## Illustrated bridge props

The six Bridge assets are generated additions, not original v3.31 artwork.
The built-in image generator used CrystalCart as a material/style reference:
transparent atlas, textured oak and green repair planks, brass-capped timber,
blank work-order sign, banked water channel, blank brass dial; warm upper-left
lighting, no labels or characters. BRIDGE_ART_MANIFEST.json records source hash,
exact atlas crop rectangles, output hashes and dimensions. The PNGs retain alpha.
The approved V331_ART_MANIFEST.json and original resources remain unchanged.

SpriteKit keeps quantity selection, drop footprints, equation text and traversal
native. The same timber materials cover the crossing steps and their supports.


## HD companion refresh

Milo, Tiko, Lumi and Pip now ship with 320×320 production companion art. This
replaces the previous 84×84 Milo, Tiko and Lumi placeholders and the earlier Pip
penguin artwork while keeping all existing actor names and gameplay APIs stable.

- Milo, Tiko and Lumi remain single-source companion illustrations. Their existing
  native SpriteKit motion continues to provide idle, travel and interaction
  behavior without pretending that duplicate authored frames exist.
- Pip keeps the `Pip.atlas` pose filenames so `ArtSystem.frames` and existing
  gameplay code do not change. The five pose entries currently share the approved
  base illustration and use native motion for the visible action.
- Current gameplay heights are Milo 113pt, Tiko 130pt, Lumi 128pt and Pip 145pt.
  A 320px source provides at least 2.2× pixel density for every companion on the
  target iPad presentation.
- Companion grounding auras, Reduced Motion behavior, curriculum, evidence,
  persistence, routing and progression remain unchanged.
- Valkyrie's character art and atlas are explicitly outside this refresh.

True authored idle/walk/interact/react/celebrate companion frames can replace the
current pose files later without changing the CharacterNode or ArtSystem boundary.
