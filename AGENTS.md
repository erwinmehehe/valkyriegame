# AGENTS.md — ValkyrieLearn Production Instructions

This file is the operating contract for AI coding agents working in this repository.

## 1. Product mission

Build ValkyrieLearn as a **native iPad educational adventure**, not a browser game and not a quiz app.

The first target learner profile is:

- age 5
- Kinder 2
- already strong in early mathematics
- should be allowed to advance into Grade 1+ concepts when demonstrated readiness supports it

The primary product goal is to make the learner **better at thinking mathematically**, not merely faster at answering arithmetic questions.

The child-facing experience must feel like an adventure. Curriculum metadata, mastery scores, diagnostic logic, and evidence tracking should remain mostly invisible to the child.

## 2. Platform and stack are locked

Production target: **iPadOS native**

Use:

- Swift
- SpriteKit for gameplay scenes, actors, camera, particles, touch objects, and world interaction
- SwiftUI for navigation, parent dashboard, settings, profiles, and non-game UI
- SwiftData for offline-first learner/progress persistence
- AVFoundation for narration, phonemes, music, and sound
- CloudKit only later if cross-device sync is explicitly approved
- XCTest / Swift Testing for learning-engine tests
- TestFlight for early device builds

Do not make React, Phaser, Godot, Unity, a WebView, or the current HTML file the production architecture unless the owner explicitly changes this decision.

## 3. The existing HTML file is a prototype

`index.html` is valuable as a reference for:

- art direction
- world identities
- character names
- story ideas
- Word Garden interaction flow
- existing mechanics
- progression concepts
- accessibility lessons
- what worked and what did not

Do **not** keep adding production features to the HTML prototype.

Do **not** blindly port its curriculum or adaptive code. Some of that logic is intentionally being replaced.

## 4. Core gameplay model

Default interaction model for age 5:

1. tap a destination or meaningful object
2. Valkyrie walks there
3. child directly manipulates physical game objects
4. challenge is solved in-world
5. environment changes
6. companion reacts
7. progress/reward occurs

Use tap-to-move and touch manipulation. Do not introduce a virtual joystick by default.

Learning must be embedded in the physical world. Avoid floating multiple-choice UI unless the learning objective genuinely requires a choice interface.

Core loop:

**Explore -> encounter obstacle -> learn -> manipulate world -> advance -> discover -> reward -> unlock**

## 5. Learning architecture

Production data flow:

```
CurriculumGraph
      ↓
LearnerProfile
      ↓
AdaptiveDirector
      ↓
EncounterGenerator
      ↓
WorldMechanic
      ↓
EvidenceRecorder
      ↓
MasteryEngine
      ↓
ReviewScheduler
```

Supporting systems:

```
StoryManager
RewardManager
SaveManager
AudioManager
EngagementDirector
```

The learning engine must be plain Swift and must not depend on SpriteKit. It must be unit-testable without rendering the game.

Worlds ask the learning engine what to teach. Worlds do not own curriculum progression.

## 6. Curriculum rule: rebuild, do not expand the old bank

The old prototype contains 2,700 generated tasks and labels such as MATATAG Math, Singapore Math, and Chinese Mastery Math.

Treat that as **prototype content only**.

Do not:

- generate thousands more questions
- assume the current labels prove curriculum alignment
- treat the three math labels as three child-facing subjects
- mark a curriculum as validated without a separate standards-mapping review

Production direction:

- one child-facing **Math Castle**
- official age/grade standards used as alignment references
- concrete/pictorial/abstract methods, number bonds, structured variation, and reasoning used as teaching approaches
- a fine-grained skill graph drives actual progression

The child should not choose between "MATATAG Math", "Singapore Math", and "Chinese Math".

## 7. Adaptive learning requirements

Adapt by **skill**, not by one global Math Level.

Every relevant skill should have a state such as:

- new
- learning
- developing
- secure
- reviewDue
- mastered

Evidence should distinguish:

- independent correct
- correct after light hint
- correct after strong hint
- correct after demonstration
- incorrect
- attempts
- response time
- representation
- last practiced
- transfer/application success

One correct answer must never equal mastery.

Mastery should require repeated evidence across time and different representations.

Example:

1. solve 3 + 2 using crystals
2. later solve the same relationship in a story context
3. later solve it symbolically
4. later detect or explain an incorrect result

## 8. Adaptive session policy

Starting target mix:

- 60% current learning zone
- 20% spaced review
- 15% gentle stretch
- 5% confidence/fun

This is a starting policy, not a hardcoded eternal ratio.

If the learner clearly demonstrates a skill, advance quickly. Do not force repetitive easy practice.

If she struggles, change the teaching representation before simply lowering numbers.

## 9. Anti-boredom rules are product requirements

These rules are non-negotiable unless user testing proves a better replacement:

- no identical question twice
- no same mechanic more than twice consecutively
- after roughly 3 easy independent successes, increase depth/challenge
- after roughly 2 meaningful struggles, change scaffolding or representation
- every 3–5 minutes, something should change mechanically, visually, narratively, or spatially
- each normal session should include meaningful player choice
- each normal session should include at least one non-academic interaction
- spaced review should usually return in a different surface/context
- hard work should unlock interesting experiences, not just more questions
- sessions should have natural stopping points before fatigue

The EngagementDirector may consider signals such as random tapping, sudden changes in response time, repeated abandoning, repeated hint use, and mechanic preferences.

Do not interpret every behavior as a learning deficit. Sometimes change the activity.

## 10. Math is the flagship subject

Math Castle must prioritize depth, flexibility, reasoning, and transfer.

Core strands:

- number sense
- subitizing
- counting/cardinality
- number relationships
- number bonds
- addition
- subtraction
- missing addends
- place value
- patterns
- equivalence
- geometry
- spatial reasoning
- measurement
- time
- money
- data
- mathematical reasoning
- early equal groups/sharing/fractions only when ready

Strong math performance should unlock deeper reasoning, not just larger numbers.

Prefer questions such as:

- make the same total another way
- find the mistake
- which does not belong
- what changed
- explain which is greater
- what number could go here
- find more than one solution

## 11. Reusable mechanics, not one-off question screens

Math Castle should grow into reusable systems such as:

- Crystal Cart
- Balance Scale
- Number Bond Machine
- Ten Frame Gate
- Gear Equation
- Missing Number Bridge
- Pattern Conveyor
- Measurement Workshop
- Shape Builder
- Treasure Shop
- Clock Tower
- Number Line Jump
- Place Value Factory
- Firefly Estimation
- Pip's Mistake Machine

A single mechanic should support multiple skills and multiple representations.

Do not create a new scene for every question.

## 12. World roles

### Math Castle / Pip
Math, engineering, quantity, number relationships, measurement, spatial reasoning.

Pip is a mechanical helper. He can also make believable mistakes that the child corrects.

### Word Garden / Lumi
Phonological awareness, phonics, blending, vocabulary, comprehension, Filipino, storytelling.

Lumi's ability is reaching/activating inaccessible natural objects such as ropes, bells, latches, flowers, or seeds.

### Science Lab / Milo
Observation, prediction, testing, cause/effect, plants, weather, light, sound, materials, habitats, simple engineering.

Science loop:

**Observe -> Predict -> Test -> Observe Result -> Explain**

### Puzzle Palace / Tiko
Working memory, inhibitory control, cognitive flexibility, patterns, spatial reasoning, planning, sequencing, early computational thinking.

Tiko should support memory/scouting/spatial gameplay.

## 13. Whole-child development

Blend these into existing adventures instead of creating eight menu islands:

- language & literacy
- mathematical thinking
- science & discovery
- logic & executive function
- social-emotional development
- life skills & independence
- creativity & expression
- physical / real-world exploration

SEL should be situational and playable, not a "correct behavior" quiz.

Executive function should include working memory, inhibition, and rule switching.

Creativity needs activities with no single correct answer.

## 14. Story Tree and rewards

Story Tree is the persistent home base.

Learning should visibly improve the world.

Reward loop:

**learning -> world change -> reward -> creativity -> return**

Useful rewards can include:

- plants
- lanterns
- creatures
- books
- outfits
- companion accessories
- building pieces
- home decorations

Prefer rewards the child can use or place. Avoid badge clutter.

## 15. Art direction

The production visual target is a high-quality illustrated adventure, not a UI pasted on top of backgrounds.

Valkyrie must be a real protagonist, roughly 15–20% of the scene when appropriate.

Scenes should visually support:

**foreground -> player -> gameplay objects -> midground -> destination -> atmosphere**

Worlds should feel physically traversable with paths, bridges, stairs, platforms, water, machinery, and connected destinations.

Companions should participate inside the scene, not float as generic hint buttons.

Learning objects should look native to the world: flowers, crystals, carts, gears, bridges, runes, tools, creatures.

### Canonical Valkyrie identity — immutable unless the owner explicitly approves a character redesign

The single approved protagonist is the character in `ValkyrieLearn/Resources/Valkyrie.atlas`, sourced from v3.31. **Keep her exact face, hair, clothing, proportions, colors, and six pose textures**. The production SpriteKit `ValkyrieNode` must continue to render that atlas in every world; no AI-generated substitute, repaint, synthesized lookalike, new outfit, or silhouette swap is permitted during art-polish work.

**World art creation rule:** create standalone *environment-only* images with no people or humanoid figures and no baked-in Valkyrie. Only add the canonical character through `ValkyrieNode` at runtime. Backgrounds must not contain portraits, HUD, text, answers, or other game-state objects.

**Preview accuracy rule:** don't call generated concepts or collages "current native game" screenshots. Native previews must come from the actual iPad simulator. Do not include a different child/character in visual proposals for this product.

`python3 scripts/verify_valkyrie_identity.py` independently verifies the six source bytes/dimensions; the native pull-request gate also rejects edits to the sprite atlas and the character-rendering code. Explicit future character changes require their own reviewed task and owner approval before altering the lock.

## 16. Audio

Core educational audio should use deliberate recordings where correctness matters, especially phonemes.

Do not rely on system speech synthesis for phonics accuracy.

Eventually provide:

- world ambience
- footsteps
- interaction sounds
- character reactions
- reward sting
- gentle music
- narrated instructions where useful
- recorded phonemes/words

## 17. Accessibility and child usability

Retain the strengths of the prototype:

- large touch targets
- no hover dependency
- reduced-motion support
- readable text
- audio on/off
- non-drag alternatives where a drag interaction is essential
- clear feedback without shaming
- mistakes treated as learning opportunities

Do not design around keyboard/mouse parity at the expense of iPad touch quality.

## 18. Privacy and safety

Production should be offline-first.

For the initial personal iPad build:

- no account required
- no ads
- no unnecessary analytics
- no microphone requirement
- no camera requirement
- no location requirement
- no child data sent to a server unless explicitly approved later

Do not add dark patterns, streak pressure, loot-box mechanics, or manipulative retention systems.

## 19. Scope control

Do not prioritize yet:

- Chapter 2
- additional worlds
- thousands more generated questions
- monetization
- accounts/backend
- speech recognition
- giant avatar system
- 3D conversion
- multiplayer
- excessive menu screens

First make the Adaptive Math Castle vertical slice excellent.

## 20. Definition of done for the first vertical slice

The first production milestone is complete only when it runs on an actual iPad and includes:

- native Swift/SpriteKit scene
- landscape layout
- Valkyrie visible as protagonist
- tap-to-move
- Pip integrated in-scene
- hidden math placement sequence
- per-skill learner profile
- at least 5 reusable Math Castle mechanics
- adaptive challenge selection
- multi-step scaffolding
- spaced review
- Challenge Gate
- anti-boredom mechanic rotation
- one persistent Story Tree reward
- local save/restore
- parent-facing skill summary
- automated unit tests for mastery/adaptive logic
- no blocker-level crashes in a normal 15-minute session

## 21. Agent workflow

Before coding:

1. read this file
2. read `ROADMAP.md`
3. read the relevant spec in `docs/`
4. inspect existing code before replacing it
5. identify which milestone/acceptance criterion the change serves

When implementing:

- make the smallest coherent production change
- keep learning logic separate from rendering
- add tests for learning-engine behavior
- preserve offline-first behavior
- avoid speculative infrastructure

Before considering work complete:

- build
- run tests
- test the relevant interaction path
- state what acceptance criterion is now satisfied
- note any remaining gap honestly

When uncertain, prefer the product principles in this document over preserving prototype code.
