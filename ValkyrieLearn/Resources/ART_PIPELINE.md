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
Pip retains the canonical penguin and held block; disconnected floating cards and
stars are removed during import. His supplied single pose uses native motion, not
a claim of a completed multi-frame animation set. Actor action/facing logic stays
independent of the art. Missing atlases still show labeled engineering fallbacks.

At 1280×720, Valkyrie's atlas canvas height is 300 points and Pip's 145. Review
actual silhouette, foot registration, occlusion, readable physical routes and
large touch areas on the target iPad. Source action coverage and true foreground
layer separation still need further art production.

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


## Companion presence pass

Lumi, Milo and Tiko currently ship as small single-frame source images rather than
full action atlases. The native renderer must therefore preserve each source
texture's real aspect ratio instead of forcing Pip's atlas proportions onto every
non-Valkyrie actor.

Until dedicated HD companion atlases are produced:

- Lumi renders at a readable fairy-companion scale in Word Garden instead of being
  reduced to a decorative sticker.
- Lumi, Milo and Tiko use subtle world-colored grounding auras so their silhouettes
  remain legible against illustrated environments without becoming floating HUD.
- Their authored interaction methods add short native reaction motion, while
  reduced-motion mode keeps the reactions immediate and spatially stable.
- The presentation layer does not claim additional source animation frames and does
  not change curriculum, evidence, routing or progression.

This is an interim game-feel correction. Dedicated Retina companion art with
idle/walk/interact/react/celebrate coverage remains required for final visual
acceptance.
