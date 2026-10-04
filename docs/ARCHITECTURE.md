# Native iPad Architecture

## Production decision

ValkyrieLearn production is a native iPadOS application.

Locked baseline:

- Swift
- SpriteKit
- SwiftUI
- SwiftData
- AVFoundation
- CloudKit optional later
- TestFlight for early delivery

The HTML prototype is not the runtime architecture.

## Application boundaries

```
ValkyrieLearnApp
│
├── SwiftUI App Shell
│   ├── child entry/home
│   ├── parent area
│   ├── settings
│   ├── skill progress
│   └── session history
│
├── SpriteKit Game
│   ├── Story Tree
│   ├── Math Castle
│   ├── Word Garden
│   ├── Science Lab
│   └── Puzzle Palace
│
├── Learning Core (plain Swift)
│   ├── SkillGraph
│   ├── LearnerProfile
│   ├── AdaptiveDirector
│   ├── EncounterGenerator
│   ├── EvidenceRecorder
│   ├── MasteryEngine
│   ├── ReviewScheduler
│   ├── ScaffoldingEngine
│   └── EngagementDirector
│
├── Persistence
│   ├── SwiftData models
│   ├── local save
│   └── optional CloudKit sync later
│
└── Media
    ├── art
    ├── sprite atlases
    ├── music
    ├── SFX
    └── recorded educational audio
```

## Critical separation

The learning core must not import SpriteKit.

SpriteKit scenes must not implement mastery policy directly.

Example:

```
AdaptiveDirector -> LearningEncounter
MathCastleScene -> renders encounter using a mechanic
Mechanic -> produces LearningEvidence
MasteryEngine -> updates LearnerProfile
ReviewScheduler -> determines future review eligibility
```

This makes learning rules testable and game mechanics reusable.

## Suggested project layout

```
ValkyrieLearn/
├── App/
│   ├── ValkyrieLearnApp.swift
│   ├── AppState.swift
│   └── Navigation/
│
├── Game/
│   ├── GameContainerView.swift
│   ├── GameConfiguration.swift
│   ├── Scenes/
│   │   ├── BootScene.swift
│   │   ├── StoryTreeScene.swift
│   │   ├── MathCastleScene.swift
│   │   ├── WordGardenScene.swift
│   │   ├── ScienceLabScene.swift
│   │   └── PuzzlePalaceScene.swift
│   ├── Actors/
│   │   ├── ValkyrieNode.swift
│   │   ├── PipNode.swift
│   │   ├── LumiNode.swift
│   │   ├── MiloNode.swift
│   │   └── TikoNode.swift
│   ├── Mechanics/
│   │   ├── CrystalCartMechanic.swift
│   │   ├── BalanceScaleMechanic.swift
│   │   ├── NumberBondMechanic.swift
│   │   ├── TenFrameMechanic.swift
│   │   └── PlaceValueMechanic.swift
│   └── Systems/
│       ├── InteractionSystem.swift
│       ├── StorySystem.swift
│       ├── RewardSystem.swift
│       └── AudioSystem.swift
│
├── Learning/
│   ├── Models/
│   │   ├── SkillID.swift
│   │   ├── SkillState.swift
│   │   ├── LearningEncounter.swift
│   │   └── LearningEvidence.swift
│   ├── SkillGraph.swift
│   ├── LearnerProfile.swift
│   ├── AdaptiveDirector.swift
│   ├── EncounterGenerator.swift
│   ├── EvidenceRecorder.swift
│   ├── MasteryEngine.swift
│   ├── ReviewScheduler.swift
│   ├── ScaffoldingEngine.swift
│   └── EngagementDirector.swift
│
├── Curriculum/
│   ├── Math/
│   ├── Literacy/
│   ├── Science/
│   └── ExecutiveFunction/
│
├── Parent/
│   ├── ParentDashboardView.swift
│   ├── SkillProgressView.swift
│   └── SessionHistoryView.swift
│
├── Persistence/
│   ├── Models/
│   ├── LearningStore.swift
│   └── SaveMigration.swift
│
├── Media/
│   ├── Audio/
│   └── AssetCatalog/
│
└── Tests/
    ├── AdaptiveDirectorTests.swift
    ├── MasteryEngineTests.swift
    ├── ReviewSchedulerTests.swift
    └── SkillGraphTests.swift
```

## Scene model

Primary orientation: landscape.

Prefer a guided point-and-click adventure:

- tap walkable destination
- animate Valkyrie to target
- enter interaction radius
- manipulate object
- resolve challenge
- update environment

Do not add full platforming physics unless explicitly required by a future game design decision.

## Input

Production input is iPad touch.

Priorities:

1. tap-to-move
2. tap-to-interact
3. drag/direct manipulation
4. accessible tap alternative for essential drag actions
5. multi-touch only when genuinely useful

Avoid tiny controls and hover assumptions.

## Rendering and depth

SpriteKit z-positioning should support:

- atmosphere / sky
- distant environment
- destinations
- middle-ground structures
- gameplay objects
- Valkyrie
- companions
- near props
- foreground occlusion
- HUD

Valkyrie should be allowed to move behind/in front of scene elements naturally.

## Character animation

Use sprite atlases rather than embedded base64 image blobs.

Initial Valkyrie animation set:

- idle
- walk
- interact
- push/pull
- carry
- think
- celebrate
- react/surprised

Companions also need functional animations tied to their abilities.

## Persistence

SwiftData should store locally:

- learner profile
- skill evidence
- mastery state
- review schedule
- session summaries
- world progress
- rewards
- Story Tree state
- settings

Do not block the first production build on authentication or a server.

## Save schema

Use explicit schema versions from the start.

Every persisted model change that is not backward-compatible requires a migration strategy.

Do not repeat the prototype pattern of unrelated visible/save version numbers.

## Audio

Use AVFoundation / native audio where appropriate.

Separate:

- music
- ambient loops
- gameplay SFX
- narration
- educational recordings

Recorded phoneme assets should be treated as instructional content and versioned separately from generic game SFX.

## Testing strategy

### Unit tests
Required for:

- prerequisite logic
- encounter selection
- mastery transitions
- hint-weighted evidence
- review scheduling
- no infinite selection loops
- advanced-skill gating
- fallback behavior when all preferred activities are recent

### Device/UI testing
Required on real iPad for:

- touch hit areas
- drag feel
- landscape layouts
- animation pacing
- audio interruption/resume
- save/restore
- child session flow

## Performance

Target smooth performance on the actual intended iPad before adding effects.

Prefer:

- atlases
- reusable nodes
- bounded particle counts
- lazy/preloaded scene assets as appropriate
- no giant monolithic asset blobs

## Dependency policy

Prefer Apple frameworks and small, justified dependencies.

Do not add a third-party library for functionality that is straightforward in the chosen native stack without a clear maintenance benefit.
