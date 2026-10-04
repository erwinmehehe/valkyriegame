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
