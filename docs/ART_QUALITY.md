# Native Art Quality Guardrails

ValkyrieLearn targets landscape Retina iPads. Full-screen gameplay backgrounds must be authored and selected for that output, not enlarged from reference thumbnails or multi-world contact sheets.

## Production rules

- Do not stretch a quadrant of `V331WorldAtlas.webp` across a gameplay scene. It is a visual reference sheet only.
- Prefer a dedicated full-resolution image for an illustrated full-screen backdrop.
- For the current 1280×720 SpriteKit design canvas, full-screen bitmap art should have enough source detail for a 2× render target (approximately 2560×1440 pixels or better).
- If dedicated HD art is unavailable, use a high-resolution illustrated base plus native SpriteKit layers, or a fully native vector environment, rather than enlarging a small bitmap.
- Keep character atlases and gameplay objects independent from world-background resolution.
- Use linear texture filtering for illustrated bitmap art. Do not use nearest-neighbor filtering as a substitute for adequate source resolution.
- Verify art quality using the 2560×1440 native scene screenshots exported by CI.
- Treat visible softness in the background while labels/characters remain sharp as an asset-resolution problem first, not a HUD or scene-scale problem.

## Current affected worlds

- Story Tree: full-resolution illustrated art
- Math Castle: full-resolution illustrated art
- Word Garden: high-resolution source atlas
- Puzzle Palace: full-resolution illustrated base plus native Palace layers
- Science Lab Greenhouse: full-resolution illustrated base plus native greenhouse layers
- Weather Tower and Creature Grove: native vector environments

Dedicated HD Puzzle Palace and Science Lab paintings can replace the temporary shared illustrated bases later without changing gameplay or learning logic.
