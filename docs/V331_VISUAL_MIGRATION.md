# ValkyrieLearn v3.31 Visual Migration

## Purpose

The user-provided **ValkyrieLearn v3.31 / The Lost Starlight** playable HTML is the visual and game-feel reference for the native iPad production build.

This migration does **not** restart the project and does **not** restore the browser game as the production runtime.

The goal is:

**v3.31 visual identity + native SpriteKit gameplay + the new adaptive learning engine.**

## Source of truth

Visual reference source:

- `ValkyrieLearn-v3.31-Play(2).html` supplied by the user
- the repository's lighter modular `index.html` remains a useful interaction/code reference, but it does not contain the full v3.31 visual payload

The v3.31 source establishes:

- Valkyrie's illustrated character identity
- companion identity
- richly illustrated fantasy environments
- strong foreground / player / gameplay / middle-ground / destination depth
- traversable-looking paths and architecture
- learning objects embedded into the world
- Story Tree as the emotional home
- Word Garden's physical progression as the quality benchmark

## Phase 1 migrated into native SpriteKit

Source-derived assets now bundled natively:

- `Resources/V331/V331_StoryTree.jpg`
- `Resources/V331/V331_MathCastle.jpg`
- `Resources/V331/V331_Valkyrie_Idle.png`
- `Resources/V331/V331_Pip.png`

These files were extracted from the user's v3.31 source and reduced into standalone native resources. They are not newly generated replacement art.

Native behavior:

- Story Tree renders the v3.31 illustrated home world instead of the generic engineering rectangle scene.
- Math Castle renders the v3.31 castle environment underneath the live adaptive mechanics.
- Valkyrie renders with v3.31 source art while retaining native tap-to-move, world-space depth, interaction poses, celebration, persistence, and reduced-motion handling.
- Pip renders from v3.31 source art while retaining native companion following and scaffolding behavior.
- production atlases remain the preferred future animation path; source textures are an intentional fallback between full atlases and engineering placeholders.

## What remains native and unchanged

The visual migration does not replace or bypass:

- Swift / SpriteKit / SwiftUI production architecture
- SwiftData persistence
- hidden adaptive Math placement
- Math Skill Graph v2
- mastery and review logic
- adaptive 60/20/15/5 session planning
- anti-boredom rules
- Crystal Cart
- Balance Scale
- Number Bond Machine
- Ten Frame Gate
- Missing Number Bridge
- Pip scaffolding
- Challenge Gate
- persistent Moon Lantern Story Tree reward
- parent-facing Math dashboard

No WebKit or JavaScript runtime is added. The app does not decode the original HTML or its base64 payload at runtime.

## Why this is a migration, not a restart

The current native engine already contains the production learning, persistence, touch, and progression systems that the HTML prototype did not provide at production quality.

The migration replaces the temporary presentation layer while keeping those systems intact.

Conceptually:

```
v3.31 visual/game identity
          +
native adaptive architecture
          =
production ValkyrieLearn
```

## Phase 2 visual work

After Phase 1 is stable on the physical iPad:

1. extract and skin the five Math mechanics using the v3.31 props and machinery language
2. add proper Valkyrie pose/animation atlases for walk, interact, celebrate, and react
3. add Pip pose/animation frames
4. improve foreground and middle-ground parallax without hiding touch targets
5. add environment reactions to successful learning encounters
6. tune Valkyrie's apparent scene scale toward the intended ~15–20% composition where appropriate
7. review touch readability on the child's actual iPad

## Expansion rule

Do not use this work as a reason to start rebuilding all worlds simultaneously.

The next acceptance target remains the **Native Adaptive Math Castle vertical slice** on the intended physical iPad.

Only after that experience is genuinely good should production expand into:

- Puzzle Palace v2
- Word Garden v2
- Science Lab v2
- broader Story Tree systems

When Word Garden enters native production, its original v3.31 physical-progression quality is the benchmark rather than a generic literacy menu.

## Non-negotiable art-direction rule

Do not replace ValkyrieLearn's established v3.31 identity with generic educational UI.

Learning should look like something happening **inside the adventure world**, not a worksheet panel floating above unrelated scenery.
