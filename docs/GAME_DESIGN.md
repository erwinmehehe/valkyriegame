# Game Design and Engagement Specification

## Product identity

ValkyrieLearn is a **real adventure game with an adaptive learning engine underneath it**.

The child should not feel that she is switching between "game mode" and "school mode".

Learning should cause things to happen in the world.

## Core loop

**Explore -> encounter obstacle -> learn -> manipulate world -> advance -> discover -> reward -> unlock**

The strongest current prototype idea is the Word Garden flow because learning is tied to physical world progression.

Use that structural quality as the benchmark for all worlds.

## Player model

Valkyrie is the protagonist, not a decorative sprite.

Primary movement model:

- guided tap-to-move
- scene-defined walkable destinations/interaction points
- direct manipulation for learning objects

This is intentionally not a platformer unless a future decision changes scope.

## World structure benchmark

Each major world should eventually include:

- multiple connected physical areas
- a companion ability
- several reusable mechanics
- environmental transformation
- meaningful backtracking/revisit
- contextual secret
- final payoff
- persistent reward/home impact

## Word Garden / Lumi

Role:

- literacy
- phonological awareness
- vocabulary
- Filipino
- comprehension
- storytelling

Physical learning objects:

- flowers
- vines
- seeds
- bells
- story lanterns
- letter/sound stones

Lumi's functional ability:

- reach inaccessible objects
- activate natural/magical mechanisms
- retrieve items

## Math Castle / Pip

This is the flagship production world.

Suggested areas:

**Crystal Mine -> Gear Hall -> Bridge Tower**

Mechanics may include:

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

Pip's identity:

- mechanical helper
- loves systems
- can reach/operate machinery
- occasionally makes believable mistakes for the child to diagnose

## Science Lab / Milo

Suggested areas:

**Greenhouse -> Weather Tower -> Creature Grove**

Mechanics:

- plant experiment
- light/shadow
- water
- weather observation
- material tests
- animal habitat
- cause/effect machines

Milo's identity:

- careful observer
- inspect/smell/listen/dig/notice
- asks prediction questions

## Puzzle Palace / Tiko

Suggested areas:

**Rune Hall -> Mirror Maze -> Clockwork Chamber**

Mechanics:

- memory sequences
- pattern rules
- spatial rotation
- sorting
- changing rules
- path planning
- simple command sequences/debugging

Tiko's identity:

- mischievous
- memory/scouting/spatial helper
- discovers secrets

## Story Tree home base

Story Tree is the persistent emotional center.

As learning progresses:

- branches regrow
- flowers appear
- lanterns accumulate
- creatures arrive
- companions build homes
- books/artifacts appear
- earned objects can be placed

Progress should feel like:

> look what my world became

rather than:

> 84% complete

## Reward philosophy

Prefer usable rewards over badges.

Examples:

- seeds
- plants
- creatures
- books
- lanterns
- outfits
- companion accessories
- furniture
- building pieces
- visual effects

Reward loop:

**learning -> reward -> creativity**

## Challenge Gate

An optional challenge space for strong performance.

It should:

- appear when prerequisite skills are secure
- offer deeper reasoning
- feel special
- provide rare but non-gambling rewards
- never become required grinding

## Anti-boredom system

Boredom prevention is part of game design, not polish.

### Avoid
- identical repeated questions
- same mechanic over and over
- long static instruction screens
- forcing easy work after clear mastery
- constant academic prompts
- reward screens after every tiny action
- excessive menus

### Include
- mechanic rotation
- player choice
- world movement
- character moments
- surprise events
- occasional silly contexts
- secrets
- optional challenges
- creation/decorating
- non-academic interactions

## Surprise-event examples

Use sparingly:

- golden crystal appears
- secret tunnel opens
- companion loses/fetches an object
- bridge breaks unexpectedly
- rare creature arrives
- weather changes
- hidden room appears
- Story Tree sends a magical signal

Surprise should support delight, not manipulate compulsive play.

## Session shape

A normal 10–15 minute session can roughly feel like:

1. exploration/story
2. adaptive learning encounter
3. character/world reaction
4. different mechanic
5. logic/executive-function beat
6. optional Challenge Gate or creative beat
7. return/reward/natural stopping point

Do not rigidly script every session to identical timings.

## Character voice

Valkyrie should model:

- curiosity
- persistence
- kindness
- asking questions
- handling mistakes
- trying another strategy

Short reactions are better than long lectures.

Examples:

- "I think I hear water."
- "Pip, can you reach that gear?"
- "That didn't work. Let's try another way."

## Visual direction

The target is a richly illustrated 2D/2.5D adventure.

Valkyrie should often occupy roughly 15–20% of the scene when composition permits.

Use strong depth:

**foreground -> player -> gameplay -> middle ground -> destination -> atmosphere**

The environment must look traversable:

- bridges
- stairs
- platforms
- trails
- water
- machinery
- paths

Learning must be physically embedded:

- word flowers
- crystals/carts
- bridge pieces
- gears
- runes
- experiment tools

Avoid floating quiz panels over otherwise static art.

## Secrets

Secrets should be discovered through:

**remember -> connect -> revisit -> discover**

Do not simply award secrets automatically after a stage.

The Word Garden return/revisit reward pattern is the desired model.

## Audio and feel

Eventually each world should have:

- gentle music
- ambience
- footsteps
- object sounds
- companion reactions
- success/reward sting
- environmental transformation sounds

Audio should support attention without becoming noisy.

## Child-friendly failure

Never shame.

Avoid:

- harsh buzzer
- "WRONG"
- punitive loss loops

Use:

- character reaction
- environmental hint
- scaffold
- retry
- different representation

## Physical/offline later

The game can encourage movement and real-world observation, but it cannot replace physical play.

Optional later systems:

- movement breaks
- parent-confirmed offline quests
- real-world observation tasks

These should be adventurous, not punishment.

## Art production note

The earlier user-supplied reference image established the desired direction: protagonist scale, physical connectivity, embedded learning objects, companion roles, and deep composition.

Until those image references are committed into the repository, this document is the textual production specification.
