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
- `V331/V331_Pip.png`
- `V331/V331_Cart.png`
- `V331/V331_Crystal.png`

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
- Pip uses his v3.31 companion art while retaining native follow/scaffolding behavior.
- Crystal Cart uses the original v3.31 cart and crystal language.
- Balance Scale, Number Bond Machine, Ten Frame Gate, and Missing Number Bridge
  now share the same wood / gold / violet / starlight visual language, and use
  source-derived v3.31 crystal art for manipulatives where appropriate.
- Existing gameplay and learning logic is unchanged.

The reusable mechanics remain native SpriteKit objects with the same hit targets,
model bindings, evidence submission, placement behavior, and persistence. This is
a presentation migration, not a new learning implementation.

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

1. Add proper Valkyrie and Pip pose/animation atlases while preserving the current
   source-art fallback.
2. Restore stronger foreground/midground parallax and scene-specific environmental
   reactions while preserving walkable paths and touch targets.
3. Push the Math Castle mechanics further into the environment: bridge repair,
   gate activation, cart travel and machine reactions should visibly change the room.
4. Use the original Word Garden physical-progression quality as the benchmark before
   expanding Word Garden natively.
5. Import Lumi, Milo, and Tiko only when their production worlds enter scope.

Do not replace the v3.31 direction with generic educational UI. Learning objects
should look like things that belong in the world.

## Audio

The four short WAV files remain generated temporary SFX, not instructional audio.
Educational narration/phonemes must be deliberately recorded and separately versioned.
No browser speech or external assets are loaded at runtime.
