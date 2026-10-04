# ValkyrieLearn Final Production Roadmap

## Status

This roadmap supersedes the earlier browser-first direction.

**Production target: native iPadOS.**

The current `index.html` build is a prototype/reference only.

## Product goal

Build ValkyrieLearn into an adaptive learning adventure for a strong 5-year-old Kinder 2 learner.

Math is the flagship subject.

The game should continuously:

- identify what she already understands
- find the next appropriate skill
- teach it through physical adventure mechanics
- scaffold when she struggles
- revisit learned concepts through spaced review
- unlock deeper reasoning when she is ready
- prevent boredom by varying mechanics, context, story, choice, and challenge

Age is not a ceiling. Demonstrated understanding controls advancement.

## Locked technology

- Swift
- SpriteKit
- SwiftUI
- SwiftData
- AVFoundation
- CloudKit later only if needed
- TestFlight
- GitHub
- Xcode

Primary platform: **iPad**
Primary orientation: **landscape**
Primary interaction: **tap-to-move + direct touch manipulation**

## Product principles

1. Learning is inside the adventure.
2. Curriculum is invisible to the child.
3. Adapt by micro-skill, not a single global level.
4. One correct answer never equals mastery.
5. Strong performance unlocks deeper thinking, not repetitive larger numbers.
6. Struggle changes teaching representation.
7. Engagement and learning are both optimization targets.
8. Rewards should change or expand the child's world.
9. No ads, dark patterns, or unnecessary online dependency.
10. Do not expand scope before the Adaptive Math Castle vertical slice works.

## Phase 0 — Freeze and prepare

### Goals
- stop expanding the old generated curriculum
- document final product decisions
- preserve HTML prototype as reference
- create native Xcode project

### Deliverables
- SwiftUI app shell
- SpriteKit container
- SwiftData persistence
- test target
- landscape iPad support
- initial asset import pipeline

### Done when
The empty native app runs reliably on the target iPad and can enter a SpriteKit scene.

---

## Phase 1 — Native game-feel foundation

### Goals
Make Valkyrie feel like a protagonist in a real world before building lots of curriculum.

### Build
- Valkyrie sprite atlas
- idle/walk/interact/celebrate/react animations
- tap-to-move
- scene interaction hotspots
- camera/depth system
- foreground occlusion
- Pip companion
- one Math Castle environment
- basic audio
- reduced-motion option

### Done when
A child can tap through the room, Valkyrie visibly travels and interacts, Pip participates in-scene, and the experience feels native to iPad.

---

## Phase 2 — Math Skill Graph v2

### Goal
Replace the old broad/generated math structure with a real developmental skill graph.

### Strands
- number sense
- number composition
- number bonds
- addition
- subtraction
- place value
- patterns/early algebra
- geometry/spatial reasoning
- measurement
- time
- money
- data
- mathematical reasoning
- equal groups/sharing/fractions as readiness-based stretch

### Requirements
- explicit prerequisites
- skill IDs
- representation options
- encounter compatibility
- readiness relationships
- no age ceiling

### Done when
The learning engine can answer:

- what the learner knows
- what prerequisite is missing
- what is ready next
- what should be reviewed

---

## Phase 3 — Learner profile and mastery

### Build
- per-skill states
- LearningEvidence
- support-level weighting
- representation tracking
- response-time capture where useful
- transfer evidence
- mastery transitions
- review-due state

### States
- New
- Learning
- Developing
- Secure
- Review Due
- Mastered

### Critical rule
One correct answer does not mark a skill mastered.

### Done when
Unit tests prove repeated, delayed, varied evidence is required for strong mastery claims.

---

## Phase 4 — Hidden adaptive placement

### Goal
Discover the learner's actual math ceiling without presenting a test screen.

### Adventure probes
- counting/cardinality
- subitizing
- comparison
- addition
- subtraction
- missing addend
- number bonds
- two-digit comparison
- tens/ones
- reasoning/error detection

### Behavior
- jump ahead after clear independent success
- probe prerequisites after struggle
- stop over-testing known concepts
- record support level

### Done when
A strong early learner reaches appropriately challenging content quickly.

---

## Phase 5 — Adaptive Director

### Selection inputs
- skill need
- prerequisites
- mastery state
- review due
- support history
- representation history
- recent mechanics
- engagement
- story/world context

### Starting session mix
- 60% current learning
- 20% spaced review
- 15% stretch
- 5% confidence/fun

### Done when
The engine can build a varied sequence without repeating trivial work or getting stuck.

---

## Phase 6 — Reusable Math Castle mechanics

Build at least five for the first vertical slice, then expand toward the full set.

Candidate mechanics:

1. Crystal Cart
2. Balance Scale
3. Number Bond Machine
4. Ten Frame Gate
5. Missing Number Bridge
6. Gear Equation
7. Pattern Conveyor
8. Measurement Workshop
9. Shape Builder
10. Treasure Shop
11. Clock Tower
12. Number Line Jump
13. Place Value Factory
14. Firefly Estimation
15. Pip's Mistake Machine

Each mechanic must support multiple skills/representations where sensible.

### Done when
The same math skill can appear through multiple game experiences.

---

## Phase 7 — Adaptive scaffolding

### Escalation
1. conceptual cue
2. visual/highlight cue
3. reduce complexity
4. demonstrate first step
5. collaborate if needed
6. schedule a similar transfer problem

### Done when
A wrong answer changes teaching rather than simply repeating the question.

---

## Phase 8 — Anti-boredom / Engagement Director

### Non-negotiable rules
- no identical question twice
- no same mechanic more than twice consecutively
- increase depth after repeated easy independent success
- change representation after repeated struggle
- world/mechanic/story change every few minutes
- player choice each normal session
- at least one non-academic interaction
- review in a different context when possible
- natural stopping points

### Surprise/content beats
- secret room
- golden crystal
- companion mishap
- unexpected bridge problem
- rare creature
- Story Tree signal
- optional side challenge

### Done when
A normal session does not feel like a sequence of worksheets even though meaningful evidence is being collected.

---

## Phase 9 — Challenge Gate

For skills that are secure, unlock optional deeper reasoning.

Examples:
- make a number several ways
- find/fix Pip's mistake
- number riddles
- multiple solutions
- strategy comparison
- multi-step problems

### Done when
Advanced performance leads to richer thinking rather than only bigger numbers.

---

## Phase 10 — Story Tree reward loop

### Build
- persistent home state
- one learning-earned decoration/creature/plant
- placement/use interaction
- visible world growth

### Rule
Reward loop:

**learning -> world change -> reward -> creativity -> return**

### Done when
At least one Math Castle learning achievement permanently changes Story Tree.

---

## Phase 11 — Parent Math dashboard

Show:

- strengths
- developing skills
- review needs
- ready-next skills
- recent session summary

Avoid raw question-count vanity metrics.

### Done when
A parent can understand what the child knows and what the system is teaching next.

---

# Milestone A — Native Adaptive Math Castle Vertical Slice

This is the first major release target.

It must include:

- native iPad app
- landscape SpriteKit world
- Valkyrie protagonist
- Pip companion
- tap-to-move
- hidden adaptive placement
- Math Skill Graph v2
- learner profile
- real mastery
- spaced review
- scaffolding
- at least 5 reusable mechanics
- Engagement Director rules
- Challenge Gate
- one Story Tree persistent reward
- parent-facing summary
- local persistence
- core tests

**Do not start major work on Chapter 2 or new worlds before this milestone is genuinely good on-device.**

---

## Phase 12 — Puzzle Palace v2

Focus:

- working memory
- inhibitory control
- cognitive flexibility
- patterns
- spatial rotation
- sorting
- path planning
- sequencing
- early coding/debugging concepts

Replace the current "one missing rune pattern repeated three times" level of depth with genuinely different cognitive mechanics.

---

## Phase 13 — Word Garden v2

Keep Word Garden's strong physical-adventure structure and deepen the curriculum.

Add:

- phonological awareness
- beginning/ending sounds
- syllables
- oral blending/segmentation
- phoneme manipulation
- letter-sound mapping
- CVC decoding
- vocabulary
- comprehension
- storytelling
- Filipino language experiences

Use recorded instructional audio for phonemes.

---

## Phase 14 — Science Lab v2

Use:

**Observe -> Predict -> Test -> Observe Result -> Explain**

Suggested areas:

- Greenhouse
- Weather Tower
- Creature Grove

Focus on experimentation instead of trivia.

---

## Phase 15 — Social-emotional and independence layer

Embed in story moments:

- asking for help
- persistence
- handling mistakes
- empathy
- cooperation
- waiting
- calming strategies
- apology
- simple conflict resolution

Do not build an SEL multiple-choice island.

---

## Phase 16 — Creativity and expression

Add open-ended use of earned rewards:

- garden
- room
- companion homes
- Story Tree
- flags/shields
- simple rhythm/music
- story creation

Not every activity needs one correct answer.

---

## Phase 17 — Optional offline/physical learning

Later only:

- find objects
- observe weather
- movement breaks
- tidy/independence quests
- parent-confirmed real-world tasks

No camera is required.

---

## Phase 18 — Cloud / multi-device only if needed

Only after the local product works well:

- optional CloudKit sync
- multiple learner profiles
- parent device view

Do not build a server/account platform prematurely.

---

# Art direction requirements across all phases

- Valkyrie is a real protagonist, not a tiny UI sprite
- connected physical environments
- strong foreground-to-background depth
- learning objects embedded in the world
- companions have visible functional roles
- routes, bridges, stairs, water, machinery, paths
- animation/audio make actions feel consequential
- avoid floating quiz UI over static backgrounds

---

# What not to build yet

- Chapter 2
- fifth world
- thousands of new generated questions
- web production version
- monetization
- ads
- account/backend platform
- required speech recognition
- 3D conversion
- multiplayer
- giant avatar system
- excessive badge systems

---

# North-star acceptance test

A successful session should look like this:

1. Valkyrie enters Math Castle because Pip needs help.
2. The system already knows easy counting is secure, so it does not waste time on it.
3. A number-bond mechanic appears.
4. The learner succeeds quickly.
5. Difficulty/depth increases.
6. A missing-addend task causes difficulty.
7. Pip scaffolds using physical crystals.
8. A related task appears later in a different representation.
9. The learner succeeds independently.
10. A spatial or executive-function activity changes the pace.
11. An optional Challenge Gate opens.
12. A meaningful reward is earned.
13. Story Tree changes.
14. Parent view reports what changed in the learner profile.

The child experiences an adventure.

The system experiences high-quality learning evidence.
