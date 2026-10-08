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

The adaptive graph contains 73 ordered math skills.

| Band | Skills |
| --- | ---: |
| K2 readiness | 13 |
| Kindergarten | 17 |
| Grade 1 | 31 |
| Grade 2 | 12 |
| Total | 73 |

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

The native Math Castle now has a parameterized production bank of 1,196 variants.

Together with the 49 existing normal adaptive encounters, the normal adaptive
candidate pool is 1,245 encounters.

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

Only skills that the current six native manipulatives can genuinely observe are
placed in the production mastery bank.

Current manipulatives:

- Crystal Cart
- Balance Scale
- Number Bond Machine
- Ten-Frame Gate
- Missing-Number Bridge
- Place Value Factory

The production bank currently covers 41 of the 73 skill nodes.

The remaining skills stay in the curriculum graph and alignment matrix, but the app
does not award mastery for them yet. This is intentional.

Place Value Factory now adds native evidence for counting to 20, ordering numbers
to 20, one more/one less, grouping tens, tens/ones place value, building and reading
two-digit numbers, comparing two-digit numbers and ordering two-digit numbers.

Examples that still require dedicated observable mechanics include:

- estimation
- count-on strategy evidence
- difference/inverse-fact reasoning
- pattern extension and creation
- shape attributes, composition, rotation and symmetry
- route/position reasoning
- length, weight, capacity and nonstandard measurement
- picture graphs and classification
- time and Philippine money
- explicit strategy choice and multiple-solution reasoning
- equal groups / repeated addition
- equal sharing
- halves and quarters

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

The next major implementation milestone is not "more questions." It is adding the
missing manipulatives so coverage can grow from 41/73 skills toward the full K2-G2
matrix without weakening evidence quality.

Place Value Factory is now implemented. Recommended next order:

1. Pattern Loom — AB/AAB/ABC, missing element, pattern creation
2. Shape Forge — attributes, composition, rotation, symmetry
3. Measurement Workshop — length, weight, capacity, repeated units
4. Data Board — sorting/classification and picture graphs
5. Clock & Market — time/dayparts and Philippine money
6. Grouping Garden — equal groups, repeated addition, equal sharing, halves/quarters
7. Reasoning Studio — strategy choice, multiple solutions and multi-step problems

Every new mechanic should add observable-action tests before its skills become
mastery-eligible.
