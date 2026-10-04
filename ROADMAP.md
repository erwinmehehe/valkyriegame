# ValkyrieLearn Roadmap

## Product goal

Build ValkyrieLearn into an adaptive learning adventure for a strong 5-year-old Kinder 2 learner, with Math as the flagship subject. The game should continuously identify what the learner already understands, teach the next skill she is ready for, revisit prior learning through spaced review, and stretch her without making the experience feel like worksheets or a placement test.

## Core design principles

- Learning stays inside the adventure.
- The curriculum is invisible to the child and visible to the learning engine.
- Difficulty adapts skill by skill, not through one global "Math Level".
- One correct answer does not equal mastery.
- Strong performance should unlock deeper reasoning, not just larger numbers.
- Struggle should change the teaching method, not simply repeat the same question.
- No identical question twice.
- No gameplay mechanic more than twice in a row.
- After 3 easy independent successes, increase challenge.
- After 2 meaningful struggles, change representation or scaffolding.
- Every 3-5 minutes, something should change visually, mechanically, or narratively.
- Every session should include player choice and at least one non-academic interaction.
- End sessions while the child still wants more.

## Learning architecture

```
CurriculumGraph
      |
LearnerProfile
      |
AdaptiveDirector
      |
EncounterGenerator
      |
WorldMechanic
      |
EvidenceRecorder
      |
MasteryEngine
      |
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

## Math Castle: flagship adaptive subject

### Number Sense
- quantities and cardinality
- counting forward/backward
- subitizing
- numeral-to-quantity matching
- number order and missing numbers
- one more / one less
- greater / fewer / equal
- estimation
- numbers to 20, 50, and 100 when ready

### Number Relationships
- compose/decompose numbers
- number bonds to 5, 10, and 20
- multiple ways to make the same number
- doubles and near doubles
- make-10 strategies

### Addition & Subtraction
- concrete groups
- pictorial representations
- symbolic equations
- missing addends
- related facts
- mental strategies
- story problems
- error analysis

### Place Value
- groups of ten
- tens and ones
- build and compare two-digit numbers
- one more/less
- ten more/less when ready

### Patterns & Early Algebra
- AB, AAB, ABB, ABC
- missing pattern elements
- create a rule
- equivalence
- true/false equations

### Geometry & Spatial Reasoning
- shapes
- composing and rotating shapes
- symmetry
- maps and mazes
- position and direction
- tangram-style challenges

### Measurement, Time, Money & Data
- length, height, weight, capacity
- simple time concepts
- practical money problems
- sorting, tallying, picture graphs

### Advanced Stretch
Only when demonstrated readiness supports it:
- equal groups
- repeated addition
- early multiplication concepts
- equal sharing and early division
- halves and quarters
- multi-step reasoning

## Adaptive placement

The first Math Castle adventure should quietly sample a range of skills rather than present a test screen.

Example sequence:
1. count a small set
2. subitize
3. compare quantities
4. add with objects
5. subtract with objects
6. solve a missing addend
7. use number bonds
8. compare two-digit numbers
9. build tens and ones
10. solve a reasoning/error problem

If performance is clearly strong, jump forward quickly. If a challenge is difficult, probe nearby prerequisite skills and teach through another representation.

## Learner profile

Track each micro-skill independently using states such as:

- New
- Learning
- Developing
- Secure
- Review Due
- Mastered

Evidence should include:
- independent correct
- hint-assisted correct
- demonstration-assisted success
- incorrect attempts
- response time
- representation used
- last practiced
- transfer/application success

## Mastery model

Mastery should require repeated evidence across time and representations.

Example:
1. solve 3 + 2 with crystals
2. later solve 3 birds + 2 birds
3. later solve 3 + 2 symbolically
4. later detect an incorrect claim such as 3 + 2 = 6

Only then should the skill be considered strongly mastered.

## Adaptive session mix

Starting guideline:
- 60% current learning zone
- 20% spaced review
- 15% gentle stretch
- 5% confidence/fun

This mix should adapt to engagement and performance.

## Anti-boredom / engagement system

The Adaptive Director should optimize both learning and engagement.

Signals to consider:
- repeated fast/easy success
- repeated struggle
- random tapping
- sudden response-time changes
- abandoning activities
- repeated menu opening
- preferred mechanics

Responses:
- increase challenge
- change mechanic
- change representation
- trigger a surprise event
- offer a player choice
- insert exploration or creative play
- open a Challenge Gate

## Reusable Math Castle mechanics

Build 10-15 reusable mechanics that can teach many skills:
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

## Challenge Gate

When a skill becomes secure, optional harder puzzles should appear.

Examples:
- make 8 in three different ways
- identify and fix Pip's mistake
- solve number clues
- find multiple valid solutions
- compare strategies
- solve multi-step story problems

Strong performance should unlock interesting thinking, not just more routine questions.

## Integrating other subjects

### Word Garden
- phonological awareness
- phonics
- blending/segmenting
- vocabulary
- Filipino language
- reading comprehension
- storytelling
- memory

### Science Lab
Use:
Observe -> Predict -> Test -> Observe Result -> Explain

Include plants, weather, materials, light, sound, habitats, and simple engineering experiments.

### Puzzle Palace
Focus on:
- working memory
- inhibitory control
- cognitive flexibility
- patterns
- spatial reasoning
- planning
- sequencing
- early computational thinking / coding

### Social-emotional learning
Embed in story situations rather than quizzes:
- persistence
- asking for help
- frustration
- empathy
- cooperation
- problem solving

## Rewards and Story Tree

Learning should change the world.

Rewards can include:
- plants
- lanterns
- creatures
- books
- outfits
- companion accessories
- building pieces
- Story Tree decorations

Use the loop:

```
learning -> world change -> reward -> creativity -> return
```

## Parent view

Show useful skill information rather than question counts.

Example:
- Number bonds to 10 — Secure
- Missing addends — Developing
- Subtraction within 10 — Needs review
- Place value — Ready next
- Working memory — Developing

## Build order

1. Freeze expansion of the existing 2,700-question curriculum.
2. Build Math Skill Graph v2.
3. Build per-skill learner profile.
4. Build hidden adaptive placement.
5. Replace the current mastery model.
6. Add spaced review.
7. Add adaptive scaffolding.
8. Rebuild Math Castle with reusable manipulatives.
9. Add Challenge Gate.
10. Connect world interactions directly to learning evidence.
11. Add engagement / anti-boredom rules.
12. Build parent Math dashboard.
13. Upgrade Puzzle Palace for executive function.
14. Rebuild Word Garden using the same adaptive engine.
15. Rebuild Science Lab around investigation.
16. Add social-emotional story moments.
17. Expand Story Tree rewards and creation.
18. Add optional offline quests and movement breaks.
19. Expand into Grade 1+ content only when demonstrated readiness supports it.

## Current immediate priority

The next production milestone should be:

**Adaptive Math Castle vertical slice**

It should include:
- hidden placement
- per-skill evidence
- 5-6 reusable math mechanics
- adaptive difficulty
- adaptive scaffolding
- spaced review
- Challenge Gate
- at least one world-changing reward
- anti-boredom mechanic rotation
- parent-facing skill summary

The goal is for the child to say:

> "Can I play Valkyrie?"

while the engine quietly becomes better at deciding what she should learn next.
