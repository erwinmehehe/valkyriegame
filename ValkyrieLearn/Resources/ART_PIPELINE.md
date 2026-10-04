# Native art boundary and v3.31 visual migration

The native build must preserve the visual identity established by the user's
**ValkyrieLearn v3.31 / The Lost Starlight** prototype while keeping production
gameplay in Swift/SpriteKit.

## Phase 1 source-derived art now in the native build

The following reduced standalone resources were extracted from the user-provided
v3.31 HTML and committed as native resources:

- `V331/V331_StoryTree.jpg`
- `V331/V331_MathCastle.jpg`
- `V331/V331_Valkyrie_Idle.png`

These are source-derived reference assets, not newly generated replacement art.

The native runtime loads them directly from the app bundle. It does **not** decode
the old HTML/base64 asset object, use WebKit, or restore the monolithic browser
asset architecture.

Current effect:

- Story Tree uses the v3.31 illustrated world instead of the generic rectangle world.
- Math Castle uses the v3.31 illustrated castle environment underneath the real
  adaptive mechanics.
- Valkyrie uses her v3.31 character art while retaining native tap-to-move,
  depth sorting, interaction, celebration, and reduced-motion behavior.
- Existing gameplay and learning logic is unchanged.

Pip and the reusable Math mechanisms still use engineering/fallback art in this
first migration pass. Their interaction logic is already separated from presentation,
so they can be reskinned without changing mastery, placement, session planning,
persistence, or evidence.

## Production atlas path

Final character animation can still graduate to `<character>.atlas` with named
`<action>_01`, `<action>_02`... frames.

Supported action names:

- `idle`
- `walk`
- `interact`
- `celebrate`
- `react`

`ArtSystem` prefers a production atlas when present, then falls back to committed
v3.31 source art, then to the procedural engineering placeholder. This lets art
improve incrementally without rewriting gameplay.

At 1280×720, Valkyrie remains approximately 205 points tall with world-space feet
and y-sorted depth. Final animation must be verified for silhouette, action
readability, anchor points, hit clearance, and child readability on the intended iPad.

## Next visual migration passes

1. Import Pip's v3.31 visual and companion poses.
2. Skin Crystal Cart, Balance Scale, Number Bond Machine, Ten Frame Gate, and
   Missing Number Bridge using the v3.31 props/machinery language.
3. Restore stronger foreground/midground parallax and scene-specific environmental
   reactions while preserving walkable paths and touch targets.
4. Use the original Word Garden physical-progression quality as the benchmark before
   expanding Word Garden natively.
5. Import Lumi, Milo, and Tiko only when their production worlds enter scope.

Do not replace the v3.31 direction with generic educational UI. Learning objects
should look like things that belong in the world.

## Audio

The four short WAV files remain generated temporary SFX, not instructional audio.
Educational narration/phonemes must be deliberately recorded and separately versioned.
No browser speech or external assets are loaded at runtime.
