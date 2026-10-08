# K2-readiness through Grade 2 adaptive mathematics

ValkyrieLearn's math path is readiness-based rather than age-locked. A learner may move
forward when prerequisite evidence is strong and may be routed back to a prerequisite
without being told that they were "demoted."

## Curriculum references

Primary alignment:

- DepEd MATATAG Mathematics for the Philippine early-grade progression.
- DepEd's MATATAG phased implementation places Grade 2 in the second implementation
  phase. K2 in ValkyrieLearn is an internal school-readiness band, not a claim that
  DepEd defines a formal "K2" grade.

Secondary progression and pedagogy reference:

- Singapore MOE Primary Mathematics 2021 syllabus, especially the P1/P2 progression,
  problem-solving emphasis, and movement among concrete, pictorial and symbolic
  representations.

Official reference locations:

- https://www.deped.gov.ph/matatagcurriculumk147/
- https://www.deped.gov.ph/wp-content/uploads/FAQs-ON-THE-MATATAG-CURRICULUM.pdf
- https://www.moe.gov.sg/-/media/files/primary/2021-primary-mathematics-syllabus-p1-to-p6-updated-october-2025.pdf

The code intentionally stores strand-level alignment rather than inventing exact
competency codes. Exact competency-code mappings should only be added after a
curriculum-review pass against the controlling DepEd source for that grade/year.

## Current curriculum matrix

The adaptive graph contains 76 ordered math skills, including three explicit clock-reading skills added to the original 73.

| Band | Skills |
| --- | ---: |
| K2 readiness | 14 |
| Kindergarten | 17 |
| Grade 1 | 32 |
| Grade 2 | 13 |
| Total | 76 |

Each skill is mapped to:

- a Valkyrie developmental band
- a MATATAG math domain
- a Singapore Math content/problem-solving area
- prerequisite relationships already enforced by the SkillGraph
- supported learning representations

The three MATATAG domain labels used by the code are:

- Number and Algebra
- Measurement and Geometry
- Data and Probability

K2 readiness uses the same conceptual domains for organization while remaining
explicitly non-grade-level.

## Production question bank

The native Math Castle now has a parameterized production bank of 2,612 variants.

Together with the 49 existing normal adaptive encounters, the normal adaptive
candidate pool is 2,661 encounters.

Hidden placement and Challenge Gate content remain separate so diagnostic evidence
and optional challenge evidence do not masquerade as ordinary practice.

The production variants carry:

- grade band
- difficulty 1-5
- purpose (instruction, practice, representation transfer, story transfer, review,
  or reasoning)
- mastery eligibility
- placement eligibility
- review eligibility

Question IDs and fingerprints are deterministic. Tests reject duplicate observable
math that has merely been reworded.

## Native-assessment safety

Only skills that the current sixteen native manipulatives can genuinely observe are
placed in the production mastery bank.

Current manipulatives:

- Crystal Cart
- Balance Scale
- Number Bond Machine
- Ten-Frame Gate
- Missing-Number Bridge
- Place Value Factory
- Pattern Loom
- Shape Forge
- Measurement Workshop
- Data Board
- Clock & Market
- Grouping Garden
- Reasoning Studio
- Number Trail
- Difference Bridge
- Route Explorer

The production bank now contains observable assessments for **all 76 of the
76 declared Valkyrie Math skills**. This means every internal skill node has
a candidate native assessment; it does **not** demonstrate that all
grade-specific DepEd competency codes, accessibility requirements, mastery
validity, or physical-device acceptance are complete. Those require separate
curriculum and device review.

Difference Bridge and Route Explorer add 207 deterministic native tasks:
90 ordered comparisons of two quantities (1–10, unequal) require children
to physically pair objects and collect remaining unmatched counters;
45 inverse-fact exercises require the child to build a total by adding the
missing part and explicitly reverse it by taking that part back;
24 one-step rover movements assess positional direction;
and 48 multi-step 3×3 routes assess planning around a blocked rock.
Incomplete responses cannot score. Incorrect completed work can be undone
and corrected; actions, attempts, and support persist with the learner.
These add observable native assessments for findDifference10, inverseFacts10,
positionalLanguage and mapRoute.

Number Trail adds 84 observable number-sense activities: 54 brief-flash
estimation trials (quantities 2–10 in six arrangements) and 30 one-unit
counting-on journeys on a number line, from nonzero starts with targets
through 10. Estimation shows unlabeled fireflies for 850 milliseconds,
then hides them and blocks answer locking until the flash is finished.
A ±1 estimate counts as approximate success; an untouched flash or
unlocked dial cannot create evidence. Counting-on requires each
one-unit jump, permits undo, and preserves incorrect-attempt history.
This adds native evidence to estimate10 and countOn10, which are
distinct from existing count-the-objects and choose-strategy skills.

Reasoning Studio adds 235 deterministic child-authored practice variants:
35 choose-a-strategy questions (choose either counting-on jumps or physically
built counter tiles, then complete every step); eight distinct-two-ways tasks
(two fully built number pairs with the same sum, not a swapped duplicate); and
192 two-stage story problems (confirm intermediate and final totals
independently). No one-tap strategy selection, partial pair, or final-answer
shortcut awards mastery; incorrect complete work can be revised, and adult/Pip
help remains supported evidence rather than independent mastery. This makes
three additional reasoning skills native-assessable; six other gaps stay
intentionally unassessed until observable mechanics exist.

Grouping Garden adds 80 deterministic native assessment variants across five
Grade 2 stretch skills. Equal groups and equal sharing require the learner to
place each seed into a physical basket and finish every group. Repeated addition
shows a group-sized step on the number line for each learner-controlled jump.
Half- and quarter-shapes require placing real partition boundaries: one cut for
two equal parts, three cuts for four equal parts. Wrong distributions, extra
jumps and unequal cuts can be submitted as incorrect and corrected, with no
scoring for partial or untouched work. These are readiness-gated enrichment
skills, not age-locked claims that all learners must reach Grade 2 content.

Clock & Market adds 304 deterministic tasks with fully observable controls:
12 clocks to the hour (K2 readiness), 24 half-hour settings (Grade 1), 144
five-minute settings (Grade 2), 24 four-card daypart orderings, and 100
stage-scaffolded Philippine peso sums. Three clock-reading skills were added
explicitly to the skill graph rather than incorrectly counting clock mastery
as daypart sequencing. Activities remain mastery-eligible only after the
child adjusts actual hands, sorts every routine card, or adds peso tokens;
Pip help is tracked as supported rather than independent work. The coin
icons are simplified denomination markers, not official Bangko Sentral coin
replicas. Stage mappings are strand-level instructional decisions and
require educator review before claiming DepEd competency-code equivalence.

Data Board adds 96 five-object classification variants split between
sorting by COLOR and sorting by SHAPE. The learner selects a real destination
bin for each pictured object, can undo a placement and must sort all five
before the response is scored. It also adds 64 picture-graph variants covering
all combinations of three source-group counts from one through four.
Learners count the displayed shapes and physically place one picture for
each object in its matching graph column. A partial graph earns no evidence;
a wrongly distributed complete tally is incorrect but can be corrected.
These activities add native evidence to classifyObjects and pictureGraph,
without converting passive viewing into mastery.

Measurement Workshop adds 210 deterministic activities covering comparison
of lengths using equal-size ribbon segments, weights using equal-weight stones,
and container capacities using equal-size cup markers, including equality and
both comparison directions. For nonstandard measurement, children must place
equal-size tiles or blocks end-to-end and may correct an overlong answer.
No unstarted measurement can be scored. These four skills receive evidence
only after a concrete selection or placed-unit response.

Shape Forge now measures recognition of triangles, circles, squares and
rectangles; corner counts; actual quarter-turns; spatial composition of a
square from two correctly oriented right triangles; and three-cell vertical
mirror reconstruction. Composition and symmetry require fully observed child
actions; missing pieces and unfinished mirrored rows cannot produce scores.

Pattern Loom adds native evidence for extending AB, AAB and ABC patterns,
filling interior gaps and constructing six-tile repeating patterns. Creation
must be a complete valid sequence, not a one-tap answer. Each native choice
is persisted, and assistance is recorded separately from independent success.

Place Value Factory now adds native evidence for counting to 20, ordering numbers
to 20, one more/one less, grouping tens, tens/ones place value, building and reading
two-digit numbers, comparing two-digit numbers and ordering two-digit numbers.

The original missing difference, inverse-fact, position and route skills
now have observable native actions. All 76 internal nodes are supported;
pedagogical validation of their exercise quality, teacher review against
controlling MATATAG competency codes, and physical iPad checks remain open.

## Adaptive progression rule

A declared grade is context, not a ceiling.

The adaptive planner should continue to use:

1. hidden placement for provisional readiness
2. prerequisite-safe learning content
3. independent evidence for mastery
4. representation changes after struggle
5. deeper reasoning after easy independent success
6. spaced review
7. exploration breaks and world changes for engagement

Placement readiness must never be reported to parents as observed mastery.

## Next curriculum-engineering milestone

All 76 internal math skills have candidate native assessments. The next
priority is **quality and release validation**, not inventing more skills:
test each manipulative on a physical iPad, review the native room screenshots
and pre-reader accessibility, verify K2–Grade 2 competency mappings against
official curriculum documents, and check that scaffolded success is not
reported as independently mastered skill.

The game is not release-approved until those device and curriculum gates pass.
