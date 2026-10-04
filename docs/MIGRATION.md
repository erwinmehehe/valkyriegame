# Migration Plan — HTML Prototype to Native iPad

## Decision

The existing `index.html` prototype remains in the repository for reference.

It is **not** the production base.

Do not continue turning it into a larger monolithic game.

## What to preserve conceptually

Preserve and reinterpret:

- Valkyrie character identity
- Lumi, Pip, Milo, Tiko
- four world identities
- Story Tree / Grand Gate concepts
- Word Garden physical progression
- environmental learning
- companion abilities
- secrets through revisit/discovery
- accessibility lessons
- story/adventure tone
- art direction

## What not to port blindly

Do not directly migrate:

- the 2,700 generated question bank as canonical curriculum
- three child-facing Math curricula
- one-correct-answer mastery behavior
- fixed-row science/logic/life-skills duplication
- the global six-level progression as the primary adaptive model
- giant embedded base64 asset architecture
- browser speech synthesis as core instructional audio
- DOM/CSS movement code
- legacy save keys/version scheme

## Migration phases

### Phase A — Native shell

Create Xcode project with:

- SwiftUI app shell
- SpriteKit game container
- landscape support
- local SwiftData store
- basic app navigation
- test target

Acceptance:

- runs on intended iPad
- can enter/exit a SpriteKit scene
- local settings persist

### Phase B — Character/world proof

Implement:

- Valkyrie sprite atlas
- tap-to-move
- depth/foreground occlusion
- Pip
- one Math Castle room
- interaction hotspots
- basic audio

Acceptance:

- child can tap a destination and Valkyrie visibly walks/interacts
- interaction feels responsive on iPad

### Phase C — Learning core

Implement plain Swift:

- SkillGraph
- LearnerProfile
- AdaptiveDirector
- LearningEncounter
- LearningEvidence
- MasteryEngine
- ScaffoldingEngine
- ReviewScheduler

Acceptance:

- full unit test coverage for core transition rules
- no SpriteKit dependency in learning target/module

### Phase D — Adaptive Math vertical slice

Implement:

- hidden placement
- at least five reusable Math mechanics
- adaptive activity selection
- scaffolding
- spaced review
- Challenge Gate
- anti-boredom rotation

Acceptance:

- 10–15 minute playable session
- clearly strong skills advance quickly
- struggle changes teaching representation
- same mechanic does not dominate
- progress persists

### Phase E — Story Tree and parent view

Implement:

- one persistent reward path
- Story Tree change
- parent skill summary

Acceptance:

- learning affects visible home-world state
- parent can see mastered/developing/review/ready-next skills

### Phase F — Expand systems

Only after vertical slice quality is proven:

- deeper Math Castle
- Puzzle Palace executive function
- Word Garden literacy
- Science Lab investigation
- SEL story moments
- more Story Tree creation
- optional offline/movement activities

## Archive policy

Keep `index.html` available as a design reference until all needed interactions/assets have been migrated or replaced.

Agents should not delete it merely because production is native.

If a future milestone makes the prototype unnecessary, archive/remove it in a deliberate cleanup task.
