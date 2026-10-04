# ValkyrieLearn

ValkyrieLearn is a native iPad educational adventure for a strong early learner. The product goal is not to make a worksheet app with game graphics. It is to build a real adventure in which learning drives world interaction, story progress, rewards, and discovery.

## Current status

The repository currently contains an HTML/JavaScript playable prototype in `index.html`. That prototype is a design and interaction reference only.

**Production direction is now locked to native iPadOS. Do not continue extending the HTML prototype as the production game.**

Production stack:

- Swift
- SpriteKit for the game world
- SwiftUI for app shell, parent area, settings, and reports
- SwiftData for local learner/progress data
- AVFoundation for narration, phonemes, music, and sound
- CloudKit only later if cross-device sync is needed
- TestFlight for early distribution

Primary orientation: **landscape iPad**.

Primary interaction model: **tap-to-move + direct touch manipulation**, not keyboard/mouse controls and not a virtual joystick by default.

## Target learner profile

The first product target is a 5-year-old Kinder 2 learner who is already strong in math and should be challenged beyond age expectations when her demonstrated understanding supports it.

The system must adapt by individual skill. Age is a starting context, not a ceiling.

## Source of truth

AI agents and contributors should read these files before changing production code:

1. `AGENTS.md` — non-negotiable agent instructions
2. `ROADMAP.md` — build sequence and milestones
3. `docs/ARCHITECTURE.md` — native app architecture
4. `docs/LEARNING_SYSTEM.md` — curriculum, mastery, adaptive learning
5. `docs/GAME_DESIGN.md` — gameplay, worlds, engagement, rewards
6. `docs/MIGRATION.md` — how to move from the HTML prototype to native iPadOS

If a code change conflicts with these documents, stop and resolve the conflict before implementing.

## Product north star

A good ValkyrieLearn session should make the child think:

> "Can I play Valkyrie?"

while the system quietly determines:

- what she already understands
- what she is ready to learn next
- when to review an older skill
- when to increase challenge
- when to scaffold
- when to change the mechanic to prevent boredom

The game must optimize both **learning** and **engagement**.

## Immediate milestone

Build the **Native Adaptive Math Castle vertical slice**.

It must prove:

- native iPad rendering and touch
- Valkyrie as an active protagonist
- hidden adaptive placement
- per-skill learner profile
- real mastery evidence
- adaptive scaffolding
- spaced review
- reusable Math Castle mechanics
- Challenge Gate for advanced reasoning
- anti-boredom mechanic rotation
- one persistent Story Tree reward
- parent-facing skill summary

Do not build Chapter 2 or additional worlds before this vertical slice is strong.
