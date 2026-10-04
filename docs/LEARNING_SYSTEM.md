# Learning System Specification

## Purpose

ValkyrieLearn should identify what the learner understands, select an appropriate next challenge, teach when she struggles, review older learning at the right time, and keep strong learners moving forward.

It is not sufficient to track question counts.

## Curriculum policy

The current prototype curriculum is **not authoritative**.

Known issues in the prototype include:

- three parallel child-facing math tracks that mix standards and teaching approaches
- generated quantity being mistaken for curriculum depth
- fixed science/logic/life-skill rows repeated across nominal difficulty levels
- broad level labels that do not prove developmental progression
- a mastery metadata concept that is not fully honored by the old runtime
- some tasks that are closer to quiz trivia than learning experiences

Production must rebuild the curriculum as a fine-grained skill graph.

Before claiming formal alignment with a named official curriculum, create a separate standards-mapping review and document the source standard and competency mapping.

## Learner model

The learner is not one number such as "Math Level 4".

Store a profile by micro-skill.

Suggested skill states:

- `new`
- `learning`
- `developing`
- `secure`
- `reviewDue`
- `mastered`

Suggested evidence model:

```swift
struct LearningEvidence {
    let skillID: SkillID
    let outcome: Outcome
    let supportLevel: SupportLevel
    let representation: Representation
    let mechanicID: String
    let responseTime: TimeInterval?
    let timestamp: Date
    let transferContext: Bool
}
```

Support level should distinguish independent work from progressively stronger help.

## Mastery principles

Never use:

**one correct answer = mastered**

Use a sequence closer to:

**encounter -> practice -> delayed retrieval -> alternate representation -> transfer/application -> mastery**

Mastery should become harder to earn as the claim becomes stronger.

A "secure" skill may still need scheduled review.

## Representation ladder

Prefer concept before symbol when appropriate:

1. concrete/direct manipulation
2. pictorial
3. symbolic
4. story/application
5. reasoning/error analysis

A strong learner may move quickly through early representations, but the engine should still confirm conceptual flexibility.

## Placement

Placement is hidden inside the adventure.

Do not present a formal exam screen to the child.

Math placement should sample across increasingly demanding areas and stop over-testing a clearly demonstrated skill.

Possible probe sequence:

- quantity/cardinality
- subitizing
- comparison
- addition with objects
- subtraction with objects
- missing addend
- number bond
- two-digit comparison
- tens/ones
- reasoning/error detection

A confident high-performing learner should be advanced quickly.

## Math skill graph v2

### A. Number Sense
- recognize small quantities
- one-to-one counting
- cardinality
- subitizing
- numeral/quantity matching
- counting forward/backward
- number order
- missing numbers
- one more / one less
- compare quantities
- estimate small collections
- numbers to 20
- numbers to 50
- numbers to 100 when ready

### B. Number Composition
- compose/decompose to 5
- number bonds to 5
- compose/decompose to 10
- number bonds to 10
- number bonds to 20 when ready
- multiple decompositions
- make-5 / make-10 strategies
- doubles / near doubles

### C. Addition
- combine groups
- add with objects
- add with pictures
- symbolic addition
- count on
- make-10
- missing addends
- related facts
- simple mental strategies
- story problems

### D. Subtraction
- take away
- find what remains
- compare/find difference
- missing part
- inverse relation to addition
- story problems
- symbolic subtraction

### E. Place Value
- group ten
- tens and ones
- build two-digit numbers
- read two-digit numbers
- compare two-digit numbers
- order two-digit numbers
- one more/less
- ten more/less when ready

### F. Patterns / Early Algebra
- AB
- AAB
- ABB
- ABC
- extend patterns
- find missing element
- create own pattern
- find rule
- equivalence
- true/false equations

### G. Geometry / Spatial
- recognize shapes
- compose shapes
- decompose shapes
- rotate shapes
- symmetry
- positional language
- left/right
- maps
- mazes
- tangram-style construction
- mental rotation

### H. Measurement / Time / Money / Data
- longer/shorter
- taller/shorter
- heavier/lighter
- capacity
- sequence events
- simple clocks/time concepts
- practical coin/value concepts
- sorting/classification
- tallying
- picture graphs
- compare data

### I. Mathematical Reasoning
- find the mistake
- explain which is greater
- make the same total another way
- identify irrelevant information
- choose a strategy
- what changed?
- what number could fit?
- more than one solution
- simple multi-step reasoning

### J. Stretch, only when ready
- equal groups
- repeated addition
- early multiplication concepts
- equal sharing
- early division concepts
- halves/quarters
- richer place value
- multi-step reasoning

Age must not be used as a hard ceiling.

## Session selection

Starting heuristic:

- 60% current learning zone
- 20% spaced review
- 15% gentle stretch
- 5% confidence/fun

Selection should also consider:

- prerequisites
- recency
- mechanic repetition
- representation repetition
- support history
- engagement signals
- world/story context
- child preference

## Scaffolding

Wrong answers should trigger teaching, not punishment.

Suggested escalation:

1. specific cue without revealing answer
2. simplify or highlight relevant information
3. reduce choices/complexity
4. demonstrate one step
5. solve collaboratively if necessary
6. give a similar transfer problem later

Record the support level.

A supported success is useful evidence but should weigh less than independent success.

## Spaced review

A secure skill should reappear later.

Do not repeat the exact same surface.

Example for "make 10":

- crystals today
- fireflies tomorrow
- story problem later
- missing addend later
- error detection later

Same skill, different context.

## Challenge Gate

Secure performance should unlock optional deeper reasoning.

Challenge Gate activities may include:

- multiple solutions
- number riddles
- error analysis
- explanation/strategy
- constrained construction
- multi-step problems
- advanced but prerequisite-safe concepts

Challenge Gate is not a punishment and should not block the main story.

## Executive function integration

Blend executive function into academic gameplay.

### Working memory
Remember instructions while acting.

Example: "one blue crystal, then two yellow crystals."

### Inhibitory control
Respond to targets and ignore distractors.

### Cognitive flexibility
Change the sorting/rule criterion mid-task.

Puzzle Palace can emphasize these skills, but they should also appear lightly in other worlds.

## Literacy direction

Word Garden should eventually include:

- same/different sounds
- beginning sounds
- ending sounds
- rhyming
- syllables
- oral blending
- oral segmentation
- phoneme manipulation
- letter-sound mapping
- CVC decoding
- spelling/encoding
- vocabulary
- sentence comprehension
- story comprehension
- prediction/inference
- narrative creation
- Filipino language experiences

Speech recognition should remain optional and is not required for the first production milestones.

## Science direction

Science should teach scientific thinking rather than trivia.

Core loop:

**Observe -> Predict -> Test -> Observe Result -> Explain**

Use interactive experiments when possible.

## Social-emotional learning

Teach through story situations and character consequences.

Topics:

- identifying emotion
- asking for help
- coping with mistakes
- waiting
- persistence
- empathy
- cooperation
- apology
- disagreement/problem solving

Do not reduce SEL to obvious "good answer / bad answer" quizzes.

## Metacognition

Occasionally ask low-pressure reflection:

- Easy / Just Right / Hard
- I counted
- I remembered
- I noticed a pattern
- I tried another way

Do not score these as right/wrong.

## Parent-facing reporting

Report skills, not raw question volume.

Example:

- Number bonds to 10 — Secure
- Missing addends — Developing
- Subtraction within 10 — Needs review
- Place value — Ready next
- Working memory — Developing

The parent should be able to understand:

- strengths
- active learning targets
- recent growth
- review needs
- what is likely ready next

## Offline and real-world learning, later phase

Optional parent-confirmed quests can include:

- find five round objects
- find something beginning with a target sound
- observe weather
- tidy three items
- movement challenges

No camera is required.

## Learning system tests

At minimum, tests must verify:

- prerequisites are respected
- easy demonstrated skills are not over-practiced
- struggling skills receive scaffolding
- supported successes do not count like independent mastery
- spaced review becomes due
- same mechanic does not dominate selection
- Challenge Gate respects prerequisites
- mastery requires repeated evidence
- skill progress survives persistence/relaunch
