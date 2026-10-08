import Foundation

public enum MathSkills {
    public static let quantity = SkillID(rawValue: "math.quantityRecognition")
    public static let counting = SkillID(rawValue: "math.countingCardinality")
    public static let subitizing = SkillID(rawValue: "math.subitizing")
    public static let compare = SkillID(rawValue: "math.compareQuantities")
    public static let addition = SkillID(rawValue: "math.additionObjects")
    public static let subtraction = SkillID(rawValue: "math.subtractionObjects")
    public static let bonds5 = SkillID(rawValue: "math.numberBonds5")
    public static let bonds10 = SkillID(rawValue: "math.numberBonds10")
    public static let missing = SkillID(rawValue: "math.missingAddends")
    public static let placeValue = SkillID(rawValue: "math.placeValueTensOnes")
    public static let reasoning = SkillID(rawValue: "math.reasoningErrorAnalysis")

    public static func graph() throws -> SkillGraph {
        try MathSkillCatalog.graph()
    }
}

// Small authored foundation catalog, not a generated question bank or standards claim.
public enum MathFoundation {
    public static let encounters: [LearningEncounter] = {
        var result: [LearningEncounter] = []

        for (skill, prefix) in [(MathSkills.quantity, "quantity"), (MathSkills.counting, "count")] {
            let totals = skill == MathSkills.quantity ? [7, 5, 8, 6] : [3, 4, 9, 10]
            for total in totals {
                result.append(
                    LearningEncounter(
                        id: "\(prefix)-\(total)",
                        skillID: skill,
                        operation: .counting,
                        initialQuantity: 0,
                        targetQuantity: total,
                        prompt: "Put \(total) crystals into Pip's cart."
                    )
                )
            }
        }

        for (start, add) in [(4, 3), (3, 2), (5, 4)] {
            result.append(
                LearningEncounter(
                    id: "add-\(start)-\(add)",
                    skillID: MathSkills.addition,
                    operation: .addition,
                    initialQuantity: start,
                    targetQuantity: start + add,
                    prompt: "There are \(start) crystals in the cart. Add \(add) more."
                )
            )
        }

        for (start, total) in [(6, 10), (7, 10), (3, 8)] {
            result.append(
                LearningEncounter(
                    id: "missing-\(start)-\(total)",
                    skillID: MathSkills.missing,
                    operation: .missingAddend,
                    initialQuantity: start,
                    targetQuantity: total,
                    prompt: "The machine needs \(total) crystals. It already has \(start)."
                )
            )
        }

        return result
    }()

    // Engineering workshop previews are explicitly unscored and bypass no readiness gates.
    public static let workshopExamples = [encounters[0], encounters[8], encounters[11]]
}

/// Authored hidden-placement probes.
///
/// These are diagnostic descriptors. Some mechanics are intentionally ahead of the
/// current Milestone 0–1 renderer so the plain-Swift diagnostic policy can be tested
/// before every SpriteKit mechanic exists.
public enum MathPlacement {
    public static let probes: [PlacementProbe] = [
        PlacementProbe(
            id: "placement-quantity-5",
            band: 0,
            encounter: LearningEncounter(
                id: "placement-quantity-5",
                skillID: MathSkills.quantity,
                mechanicID: "crystalCart",
                representation: .concrete,
                operation: .counting,
                initialQuantity: 0,
                targetQuantity: 5,
                prompt: "Can you give Pip five crystals?",
                context: "hiddenPlacement"
            )
        ),
        PlacementProbe(
            id: "placement-subitize-5",
            band: 1,
            encounter: LearningEncounter(
                id: "placement-subitize-5",
                skillID: MathSkills.subitizing,
                mechanicID: "quickLook",
                representation: .pictorial,
                operation: .quantityMatching,
                initialQuantity: 0,
                targetQuantity: 5,
                prompt: "How many lights flashed?",
                context: "hiddenPlacement"
            )
        ),
        PlacementProbe(
            id: "placement-compare-6-8",
            band: 2,
            encounter: LearningEncounter(
                id: "placement-compare-6-8",
                skillID: MathSkills.compare,
                mechanicID: "balanceScale",
                representation: .concrete,
                operation: .comparison,
                initialQuantity: 6,
                targetQuantity: 8,
                prompt: "Which side has more crystals?",
                context: "hiddenPlacement"
            )
        ),
        PlacementProbe(
            id: "placement-add-4-3",
            band: 3,
            encounter: LearningEncounter(
                id: "placement-add-4-3",
                skillID: MathSkills.addition,
                mechanicID: "crystalCart",
                representation: .concrete,
                operation: .addition,
                initialQuantity: 4,
                targetQuantity: 7,
                prompt: "There are four crystals. Add three more.",
                context: "hiddenPlacement"
            )
        ),
        PlacementProbe(
            id: "placement-subtract-8-3",
            band: 4,
            encounter: LearningEncounter(
                id: "placement-subtract-8-3",
                skillID: MathSkills.subtraction,
                mechanicID: "crystalCart",
                representation: .concrete,
                operation: .subtraction,
                initialQuantity: 8,
                targetQuantity: 5,
                prompt: "Eight crystals are here. Three leave the cart. How many stay?",
                context: "hiddenPlacement"
            )
        ),
        PlacementProbe(
            id: "placement-bond-5",
            band: 5,
            encounter: LearningEncounter(
                id: "placement-bond-5",
                skillID: MathSkills.bonds5,
                mechanicID: "numberBondMachine",
                representation: .concrete,
                operation: .numberBond,
                initialQuantity: 2,
                targetQuantity: 5,
                prompt: "The machine needs five. Two are on this side. What belongs on the other side?",
                context: "hiddenPlacement",
                challengeDepth: 1
            )
        ),
        PlacementProbe(
            id: "placement-bond-10",
            band: 6,
            encounter: LearningEncounter(
                id: "placement-bond-10",
                skillID: MathSkills.bonds10,
                mechanicID: "numberBondMachine",
                representation: .concrete,
                operation: .numberBond,
                initialQuantity: 6,
                targetQuantity: 10,
                prompt: "The machine needs ten. Six are here. How many more?",
                context: "hiddenPlacement",
                challengeDepth: 1
            )
        ),
        PlacementProbe(
            id: "placement-missing-7-10",
            band: 7,
            encounter: LearningEncounter(
                id: "placement-missing-7-10",
                skillID: MathSkills.missing,
                mechanicID: "missingNumberBridge",
                representation: .concrete,
                operation: .missingAddend,
                initialQuantity: 7,
                targetQuantity: 10,
                prompt: "Seven plus what makes ten?",
                context: "hiddenPlacement",
                challengeDepth: 1
            )
        ),
        PlacementProbe(
            id: "placement-place-value-23",
            band: 8,
            encounter: LearningEncounter(
                id: "placement-place-value-23",
                skillID: MathSkills.placeValue,
                mechanicID: "placeValueFactory",
                representation: .concrete,
                operation: .quantityMatching,
                initialQuantity: 20,
                targetQuantity: 23,
                prompt: "Build twenty-three using tens and ones.",
                context: "hiddenPlacement",
                challengeDepth: 1
            )
        ),
        PlacementProbe(
            id: "placement-reasoning-5-3",
            band: 9,
            encounter: LearningEncounter(
                id: "placement-reasoning-5-3",
                skillID: MathSkills.reasoning,
                mechanicID: "pipMistake",
                representation: .reasoning,
                operation: .addition,
                initialQuantity: 5,
                targetQuantity: 8,
                prompt: "Pip says five plus three is nine. Is Pip right? Fix the machine.",
                context: "hiddenPlacement",
                challengeDepth: 2
            )
        )
    ]
}


public enum MathQuestionPurpose: String, Codable, CaseIterable, Sendable {
    case instruction
    case practice
    case representationTransfer
    case storyTransfer
    case review
    case reasoning
}

public struct MathQuestionVariant: Equatable, Sendable {
    public let encounter: LearningEncounter
    public let gradeBand: MathGradeBand
    public let matatagDomain: MatatagMathDomain
    public let singaporeArea: SingaporeMathArea
    public let difficulty: Int
    public let purpose: MathQuestionPurpose
    public let masteryEligible: Bool
    public let placementEligible: Bool
    public let reviewEligible: Bool

    public init(
        encounter: LearningEncounter,
        gradeBand: MathGradeBand,
        matatagDomain: MatatagMathDomain,
        singaporeArea: SingaporeMathArea,
        difficulty: Int,
        purpose: MathQuestionPurpose,
        masteryEligible: Bool = true,
        placementEligible: Bool = false,
        reviewEligible: Bool = true
    ) {
        self.encounter = encounter
        self.gradeBand = gradeBand
        self.matatagDomain = matatagDomain
        self.singaporeArea = singaporeArea
        self.difficulty = min(5, max(1, difficulty))
        self.purpose = purpose
        self.masteryEligible = masteryEligible
        self.placementEligible = placementEligible
        self.reviewEligible = reviewEligible
    }
}

/// Parameterized production bank for the native manipulatives that can currently
/// observe a child's mathematical action.
///
/// This expands variety without pretending unsupported skills are assessed. Place
/// value is now observed by its dedicated factory; patterns, geometry, measurement,
/// strategy choice, equal groups and fractions stay visible in MathCurriculumMatrix
/// but do not receive mastery evidence until a native mechanic can observe the act.
public enum MathProductionQuestionBank {
    public static let variants: [MathQuestionVariant] = {
        var result: [MathQuestionVariant] = []

        func add(
            _ id: String,
            skill: SkillID,
            mechanic: String,
            representation: Representation,
            operation: CartOperation,
            initial: Int,
            target: Int,
            prompt: String,
            context: String,
            difficulty: Int,
            purpose: MathQuestionPurpose,
            challengeDepth: Int = 0
        ) {
            guard let alignment = MathCurriculumMatrix.alignment(for: skill) else {
                preconditionFailure("Missing curriculum alignment for \(skill.rawValue)")
            }

            result.append(
                MathQuestionVariant(
                    encounter: LearningEncounter(
                        id: id,
                        skillID: skill,
                        mechanicID: mechanic,
                        representation: representation,
                        operation: operation,
                        initialQuantity: initial,
                        targetQuantity: target,
                        prompt: prompt,
                        context: context,
                        challengeDepth: challengeDepth
                    ),
                    gradeBand: alignment.gradeBand,
                    matatagDomain: alignment.matatagDomain,
                    singaporeArea: alignment.singaporeArea,
                    difficulty: difficulty,
                    purpose: purpose
                )
            )
        }

        // K2 / Kindergarten: quantities, counting, cardinality, quick-look and numerals.
        for target in 1...10 {
            add(
                "prod-quantity-\(target)",
                skill: MathSkills.quantity,
                mechanic: MathMechanicID.crystalCart,
                representation: .concrete,
                operation: .counting,
                initial: 0,
                target: target,
                prompt: "Put \(target) crystals in Pip's cart.",
                context: "prod.quantity",
                difficulty: target <= 5 ? 1 : 2,
                purpose: .practice
            )
            add(
                "prod-one-to-one-\(target)",
                skill: MathSkills.oneToOne10,
                mechanic: MathMechanicID.crystalCart,
                representation: .concrete,
                operation: .counting,
                initial: 0,
                target: target,
                prompt: "Move \(target) crystals one at a time into the cart.",
                context: "prod.oneToOne",
                difficulty: target <= 5 ? 1 : 2,
                purpose: .instruction
            )
            add(
                "prod-count-cardinality-\(target)",
                skill: MathSkills.counting,
                mechanic: MathMechanicID.crystalCart,
                representation: .concrete,
                operation: .counting,
                initial: 0,
                target: target,
                prompt: "Count out \(target) crystals. How many are in the cart now?",
                context: "prod.counting",
                difficulty: target <= 5 ? 1 : 2,
                purpose: .practice
            )
            add(
                "prod-cardinality-frame-\(target)",
                skill: MathSkills.cardinality10,
                mechanic: MathMechanicID.tenFrameGate,
                representation: .pictorial,
                operation: .counting,
                initial: 0,
                target: target,
                prompt: "Count and light \(target) spaces. The last count tells how many.",
                context: "prod.cardinality",
                difficulty: target <= 5 ? 1 : 2,
                purpose: .representationTransfer
            )
            add(
                "prod-numeral-quantity-\(target)",
                skill: MathSkills.numeralQuantity10,
                mechanic: MathMechanicID.tenFrameGate,
                representation: .pictorial,
                operation: .quantityMatching,
                initial: 0,
                target: target,
                prompt: "The rune shows \(target). Make that quantity on the ten-frame.",
                context: "prod.numeralQuantity",
                difficulty: target <= 5 ? 1 : 2,
                purpose: .representationTransfer
            )
        }

        for target in 1...5 {
            add(
                "prod-subitize-\(target)",
                skill: MathSkills.subitizing,
                mechanic: MathMechanicID.tenFrameGate,
                representation: .pictorial,
                operation: .quantityMatching,
                initial: 0,
                target: target,
                prompt: "Quick look: remember how many lights flashed, then make the same quantity.",
                context: "quickLook",
                difficulty: target <= 3 ? 1 : 2,
                purpose: .practice
            )
        }

        // Quantity comparison, including zero and equality, with both orientations.
        for left in 0...10 {
            for right in 0...10 {
                let relation: String
                if left == right {
                    relation = "the same number"
                } else if left > right {
                    relation = "more on the left"
                } else {
                    relation = "more on the right"
                }
                add(
                    "prod-compare-\(left)-\(right)",
                    skill: MathSkills.compare,
                    mechanic: MathMechanicID.balanceScale,
                    representation: .concrete,
                    operation: .comparison,
                    initial: left,
                    target: right,
                    prompt: "Compare \(left) and \(right) crystals. Show whether there are \(relation).",
                    context: "prod.compare",
                    difficulty: max(left, right) <= 5 ? 1 : 2,
                    purpose: .practice
                )
            }
        }

        // Part-whole progression to 5.
        for whole in 2...5 {
            for known in 0..<whole {
                add(
                    "prod-compose5-\(whole)-\(known)",
                    skill: MathSkills.compose5,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .concrete,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "\(known) crystals are in one chamber. Complete the whole of \(whole).",
                    context: "prod.compose5",
                    difficulty: 1,
                    purpose: .instruction
                )
                add(
                    "prod-decompose5-\(whole)-\(known)",
                    skill: MathSkills.decompose5,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .concrete,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Split \(whole): keep \(known) in this chamber and build the other part.",
                    context: "prod.decompose5",
                    difficulty: 2,
                    purpose: .practice
                )
                add(
                    "prod-bond5-\(whole)-\(known)",
                    skill: MathSkills.bonds5,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .pictorial,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Complete the number bond. \(known) and what make \(whole)?",
                    context: "prod.bonds5",
                    difficulty: 2,
                    purpose: .representationTransfer
                )
            }
        }

        // Part-whole progression from 6 through 10.
        for whole in 6...10 {
            for known in 1..<whole {
                add(
                    "prod-compose10-\(whole)-\(known)",
                    skill: MathSkills.compose10,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .concrete,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "\(known) crystals are ready. Complete the whole of \(whole).",
                    context: "prod.compose10",
                    difficulty: whole <= 8 ? 2 : 3,
                    purpose: .instruction
                )
                add(
                    "prod-decompose10-\(whole)-\(known)",
                    skill: MathSkills.decompose10,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .concrete,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Decompose \(whole): one part is \(known). Build the other part.",
                    context: "prod.decompose10",
                    difficulty: whole <= 8 ? 2 : 3,
                    purpose: .practice
                )
                add(
                    "prod-bond10-\(whole)-\(known)",
                    skill: MathSkills.bonds10,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .pictorial,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Complete the number bond: \(known) and what make \(whole)?",
                    context: "prod.bonds10",
                    difficulty: whole <= 8 ? 2 : 3,
                    purpose: .representationTransfer
                )
            }
        }

        for known in 1...9 {
            add(
                "prod-make10-\(known)",
                skill: MathSkills.make10,
                mechanic: MathMechanicID.numberBondMachine,
                representation: .pictorial,
                operation: .numberBond,
                initial: known,
                target: 10,
                prompt: "\(known) is one part. What part makes a whole of 10?",
                context: "prod.make10",
                difficulty: 3,
                purpose: .representationTransfer
            )
        }

        for known in 1...5 {
            add(
                "prod-doubles-\(known)",
                skill: MathSkills.doubles10,
                mechanic: MathMechanicID.numberBondMachine,
                representation: .pictorial,
                operation: .numberBond,
                initial: known,
                target: known * 2,
                prompt: "One part is \(known). Build the matching part to make double \(known).",
                context: "prod.doubles",
                difficulty: 3,
                purpose: .practice
            )
        }

        // Addition within 5.
        for start in 1...4 {
            for addend in 1...(5 - start) {
                let total = start + addend
                add(
                    "prod-combine5-\(start)-\(addend)",
                    skill: MathSkills.combine5,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .concrete,
                    operation: .addition,
                    initial: start,
                    target: total,
                    prompt: "Start with \(start) crystals. Add \(addend) more.",
                    context: "prod.combine5",
                    difficulty: 1,
                    purpose: .instruction
                )
            }
        }

        // Addition within 10 across concrete, pictorial/symbolic and story representations.
        for start in 1...9 {
            for addend in 1...(10 - start) {
                let total = start + addend
                add(
                    "prod-add10-\(start)-\(addend)",
                    skill: MathSkills.addition,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .concrete,
                    operation: .addition,
                    initial: start,
                    target: total,
                    prompt: "There are \(start) crystals. Add \(addend) more.",
                    context: "prod.addition",
                    difficulty: total <= 5 ? 1 : 2,
                    purpose: .practice
                )
                add(
                    "prod-add-pictures-\(start)-\(addend)",
                    skill: MathSkills.addPictures10,
                    mechanic: MathMechanicID.tenFrameGate,
                    representation: .pictorial,
                    operation: .addition,
                    initial: start,
                    target: total,
                    prompt: "\(start) lights are on. Add \(addend) to show the total.",
                    context: "prod.addPictures",
                    difficulty: 2,
                    purpose: .representationTransfer
                )
                add(
                    "prod-add-symbols-\(start)-\(addend)",
                    skill: MathSkills.addSymbols10,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .symbolic,
                    operation: .addition,
                    initial: start,
                    target: total,
                    prompt: "\(start) + \(addend) = ?. Build the total.",
                    context: "prod.addSymbols",
                    difficulty: 3,
                    purpose: .representationTransfer
                )
                add(
                    "prod-add-story-\(start)-\(addend)",
                    skill: MathSkills.storyAddition10,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .story,
                    operation: .addition,
                    initial: start,
                    target: total,
                    prompt: "\(start) moonstones are ready. \(addend) more arrive. Show how many there are now.",
                    context: "prod.storyAddition",
                    difficulty: 3,
                    purpose: .storyTransfer,
                    challengeDepth: 1
                )
                add(
                    "prod-missing10-\(start)-\(total)",
                    skill: MathSkills.missing,
                    mechanic: MathMechanicID.missingNumberBridge,
                    representation: .symbolic,
                    operation: .missingAddend,
                    initial: start,
                    target: total,
                    prompt: "\(start) + □ = \(total). Fill the missing part.",
                    context: "prod.missing10",
                    difficulty: 3,
                    purpose: .representationTransfer
                )
            }
        }

        // Grade 2 bridge: addition within 20 through the native missing-number mechanic.
        for start in 5...15 {
            for gap in 2...5 where start + gap <= 20 {
                let total = start + gap
                add(
                    "prod-add20-\(start)-\(gap)",
                    skill: MathSkills.addWithin20,
                    mechanic: MathMechanicID.missingNumberBridge,
                    representation: .symbolic,
                    operation: .missingAddend,
                    initial: start,
                    target: total,
                    prompt: "\(start) + □ = \(total). Find the missing addend.",
                    context: "prod.addWithin20",
                    difficulty: total <= 15 ? 3 : 4,
                    purpose: .practice
                )
            }
        }

        // Subtraction: concrete -> pictorial -> symbolic, bounded by the current cart.
        for initial in 2...5 {
            for target in 0..<initial {
                add(
                    "prod-takeaway5-\(initial)-\(target)",
                    skill: MathSkills.takeAway5,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .concrete,
                    operation: .subtraction,
                    initial: initial,
                    target: target,
                    prompt: "Start with \(initial). Take away \(initial - target). Show what remains.",
                    context: "prod.takeAway5",
                    difficulty: 1,
                    purpose: .instruction
                )
            }
        }

        for initial in 2...10 {
            for target in 0..<initial {
                let removed = initial - target
                add(
                    "prod-sub10-\(initial)-\(target)",
                    skill: MathSkills.subtraction,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .concrete,
                    operation: .subtraction,
                    initial: initial,
                    target: target,
                    prompt: "There are \(initial) crystals. Take away \(removed).",
                    context: "prod.subtraction",
                    difficulty: initial <= 5 ? 1 : 2,
                    purpose: .practice
                )
                add(
                    "prod-sub-pictures-\(initial)-\(target)",
                    skill: MathSkills.subtractPictures10,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .pictorial,
                    operation: .subtraction,
                    initial: initial,
                    target: target,
                    prompt: "The picture starts with \(initial). Remove \(removed) and show what is left.",
                    context: "prod.subtractPictures",
                    difficulty: 2,
                    purpose: .representationTransfer
                )
                add(
                    "prod-sub-symbols-\(initial)-\(target)",
                    skill: MathSkills.subtractSymbols10,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .symbolic,
                    operation: .subtraction,
                    initial: initial,
                    target: target,
                    prompt: "\(initial) - \(removed) = ?. Build the answer.",
                    context: "prod.subtractSymbols",
                    difficulty: 3,
                    purpose: .representationTransfer
                )
            }
        }

        // Current cart renders safely only through 12, so Grade 2 subtraction is
        // deliberately partial rather than falsely claiming full within-20 coverage.
        for initial in 11...12 {
            for removed in 1...5 {
                let target = initial - removed
                add(
                    "prod-sub20-\(initial)-\(removed)",
                    skill: MathSkills.subtractWithin20,
                    mechanic: MathMechanicID.crystalCart,
                    representation: .story,
                    operation: .subtraction,
                    initial: initial,
                    target: target,
                    prompt: "\(initial) crystals arrive. \(removed) power the lift. Show how many remain.",
                    context: "prod.subtractWithin20",
                    difficulty: 4,
                    purpose: .storyTransfer,
                    challengeDepth: 1
                )
            }
        }

        // Deeper reasoning that the current physical manipulatives can genuinely score.
        for whole in 5...10 {
            for known in 1..<whole {
                add(
                    "prod-equivalence-\(whole)-\(known)",
                    skill: MathSkills.equivalence10,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .reasoning,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Another machine also makes \(whole). Complete this different part-whole form with \(known) already shown.",
                    context: "prod.equivalence",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 2
                )
            }
        }

        for whole in 6...10 {
            for known in 1..<whole {
                add(
                    "prod-same-total-\(whole)-\(known)",
                    skill: MathSkills.sameTotalDifferentWay,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .reasoning,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Make the same total of \(whole) using \(known) as one part.",
                    context: "prod.sameTotal",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 2
                )
            }
        }

        for known in 1...5 {
            for whole in (known + 2)...min(10, known + 5) {
                add(
                    "prod-error-analysis-\(known)-\(whole)",
                    skill: MathSkills.reasoning,
                    mechanic: MathMechanicID.numberBondMachine,
                    representation: .reasoning,
                    operation: .numberBond,
                    initial: known,
                    target: whole,
                    prompt: "Pip's machine is wrong. Keep \(known) here and repair the other part so the whole is \(whole).",
                    context: "prod.errorAnalysis",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 2
                )
            }
        }

        for start in 2...8 {
            let maximumChange = min(4, 10 - start)
            if maximumChange > 0 {
                for change in 1...maximumChange {
                    add(
                        "prod-what-changed-\(start)-\(change)",
                        skill: MathSkills.whatChanged,
                        mechanic: MathMechanicID.crystalCart,
                        representation: .reasoning,
                        operation: .addition,
                        initial: start,
                        target: start + change,
                        prompt: "The cart changed from \(start) to \(start + change). Rebuild what changed.",
                        context: "prod.whatChanged",
                        difficulty: 4,
                        purpose: .reasoning,
                        challengeDepth: 2
                    )
                }
            }
        }

        var comparisonReasoningCount = 0
        outer: for left in 1...10 {
            for right in 1...10 where left != right {
                add(
                    "prod-explain-compare-\(left)-\(right)",
                    skill: MathSkills.explainComparison,
                    mechanic: MathMechanicID.balanceScale,
                    representation: .reasoning,
                    operation: .comparison,
                    initial: left,
                    target: right,
                    prompt: "Compare \(left) and \(right). Choose the relationship that the quantities prove.",
                    context: "prod.explainComparison",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 2
                )
                comparisonReasoningCount += 1
                if comparisonReasoningCount == 30 { break outer }
            }
        }

        // Place Value Factory opens the prerequisite-safe bridge from teen numbers
        // into two-digit place value without pretending unsupported geometry or
        // measurement skills are assessed.
        for target in 11...20 {
            add(
                "prod-count20-\(target)",
                skill: MathSkills.countTo20,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .concrete,
                operation: .quantityMatching,
                initial: 0,
                target: target,
                prompt: "Build \(target) with tens and ones.",
                context: "prod.countTo20",
                difficulty: 2,
                purpose: .practice
            )
        }

        for smaller in 10...19 {
            let larger = smaller + 1
            add(
                "prod-order20-left-\(smaller)-\(larger)",
                skill: MathSkills.numberOrder20,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .pictorial,
                operation: .comparison,
                initial: smaller,
                target: larger,
                prompt: "Which number comes first from least to greatest: \(smaller) or \(larger)?",
                context: "prod.numberOrder20",
                difficulty: 2,
                purpose: .representationTransfer
            )
            add(
                "prod-order20-right-\(larger)-\(smaller)",
                skill: MathSkills.numberOrder20,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .pictorial,
                operation: .comparison,
                initial: larger,
                target: smaller,
                prompt: "Which number comes first from least to greatest: \(larger) or \(smaller)?",
                context: "prod.numberOrder20",
                difficulty: 2,
                purpose: .review
            )
        }

        for base in 10...19 {
            add(
                "prod-one-more-\(base)",
                skill: MathSkills.oneMoreLess20,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .concrete,
                operation: .quantityMatching,
                initial: base,
                target: base + 1,
                prompt: "Build one more than \(base).",
                context: "prod.oneMore20",
                difficulty: 2,
                purpose: .practice
            )
        }
        for base in 11...20 {
            add(
                "prod-one-less-\(base)",
                skill: MathSkills.oneMoreLess20,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .concrete,
                operation: .quantityMatching,
                initial: base,
                target: base - 1,
                prompt: "Build one less than \(base).",
                context: "prod.oneLess20",
                difficulty: 2,
                purpose: .review
            )
        }

        for tens in 1...9 {
            let target = tens * 10
            add(
                "prod-group-ten-\(target)",
                skill: MathSkills.groupTen,
                mechanic: MathMechanicID.placeValueFactory,
                representation: .concrete,
                operation: .quantityMatching,
                initial: 0,
                target: target,
                prompt: "Trade the ones for tens. Build \(target) as groups of ten.",
                context: "prod.groupTen",
                difficulty: tens <= 3 ? 2 : 3,
                purpose: .instruction
            )
        }

        for tens in 1...9 {
            for ones in [0, 2, 4, 6, 8] {
                let number = tens * 10 + ones
                add(
                    "prod-place-value-\(number)",
                    skill: MathSkills.placeValue,
                    mechanic: MathMechanicID.placeValueFactory,
                    representation: .concrete,
                    operation: .quantityMatching,
                    initial: 0,
                    target: number,
                    prompt: "Build \(number) using the correct tens and ones.",
                    context: "prod.placeValue",
                    difficulty: number < 50 ? 2 : 3,
                    purpose: .instruction
                )
            }
        }

        for tens in 1...9 {
            for ones in [1, 3, 5, 7, 9] {
                let number = tens * 10 + ones
                add(
                    "prod-build-two-digit-\(number)",
                    skill: MathSkills.buildTwoDigit,
                    mechanic: MathMechanicID.placeValueFactory,
                    representation: .concrete,
                    operation: .quantityMatching,
                    initial: 0,
                    target: number,
                    prompt: "Make \(number) with tens rods and ones cubes.",
                    context: "prod.buildTwoDigit",
                    difficulty: number < 50 ? 2 : 3,
                    purpose: .practice
                )
            }
        }

        func numberWords(_ number: Int) -> String {
            let ones = [
                0: "zero", 1: "one", 2: "two", 3: "three", 4: "four",
                5: "five", 6: "six", 7: "seven", 8: "eight", 9: "nine",
                10: "ten", 11: "eleven", 12: "twelve", 13: "thirteen",
                14: "fourteen", 15: "fifteen", 16: "sixteen",
                17: "seventeen", 18: "eighteen", 19: "nineteen"
            ]
            if let word = ones[number] { return word }
            let tensWords = [
                2: "twenty", 3: "thirty", 4: "forty", 5: "fifty",
                6: "sixty", 7: "seventy", 8: "eighty", 9: "ninety"
            ]
            let tens = number / 10
            let remainder = number % 10
            guard let tensWord = tensWords[tens] else { return "\(number)" }
            guard remainder > 0, let onesWord = ones[remainder] else { return tensWord }
            return "\(tensWord)-\(onesWord)"
        }

        for tens in 1...9 {
            for ones in [0, 4, 7, 9] {
                let number = tens * 10 + ones
                add(
                    "prod-read-two-digit-\(number)",
                    skill: MathSkills.readTwoDigit,
                    mechanic: MathMechanicID.placeValueFactory,
                    representation: .symbolic,
                    operation: .quantityMatching,
                    initial: 0,
                    target: number,
                    prompt: "Build the number named \(numberWords(number)).",
                    context: "prod.readTwoDigit",
                    difficulty: number < 50 ? 3 : 4,
                    purpose: .representationTransfer
                )
            }
        }

        for tens in 2...9 {
            for ones in [1, 4, 7, 9] {
                let a = tens * 10 + ones
                let b = (tens - 1) * 10 + (9 - ones)
                let left = tens.isMultiple(of: 2) ? a : b
                let right = tens.isMultiple(of: 2) ? b : a
                add(
                    "prod-compare-two-digit-\(left)-\(right)",
                    skill: MathSkills.compareTwoDigit,
                    mechanic: MathMechanicID.placeValueFactory,
                    representation: .reasoning,
                    operation: .comparison,
                    initial: left,
                    target: right,
                    prompt: "Compare \(left) and \(right). Which number is greater?",
                    context: "prod.compareTwoDigit",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 1
                )
            }
        }

        for tens in 2...8 {
            for ones in [2, 5, 8, 9] {
                let a = tens * 10 + ones
                let b = (tens + 1) * 10 + max(0, 9 - ones)
                let left = ones.isMultiple(of: 2) ? a : b
                let right = ones.isMultiple(of: 2) ? b : a
                add(
                    "prod-order-two-digit-\(left)-\(right)",
                    skill: MathSkills.orderTwoDigit,
                    mechanic: MathMechanicID.placeValueFactory,
                    representation: .reasoning,
                    operation: .comparison,
                    initial: left,
                    target: right,
                    prompt: "Put these in least-to-greatest order. Which comes first: \(left) or \(right)?",
                    context: "prod.orderTwoDigit",
                    difficulty: 4,
                    purpose: .reasoning,
                    challengeDepth: 1
                )
            }
        }

        return result
    }()

    public static let encounters: [LearningEncounter] = variants.map(\.encounter)

    public static let coveredSkillIDs: Set<SkillID> = Set(encounters.map(\.skillID))

    public static func hasNativeAssessment(for skillID: SkillID) -> Bool {
        coveredSkillIDs.contains(skillID)
    }

    public static func variants(for skillID: SkillID) -> [MathQuestionVariant] {
        variants.filter { $0.encounter.skillID == skillID }
    }

    public static func variants(in band: MathGradeBand) -> [MathQuestionVariant] {
        variants.filter { $0.gradeBand == band }
    }
}


/// Seed scenarios for the reusable Math Castle mechanics.
///
/// The named arrays preserve the original milestone scenarios and regression
/// fixtures. `all` also includes MathProductionQuestionBank, which supplies the
/// larger parameterized K2-readiness through Grade 2 adaptive pool.
public enum MathCastleEncounterCatalog {
    public static let balanceScale: [LearningEncounter] = [
        LearningEncounter(
            id: "scale-compare-5-8",
            skillID: MathSkills.compare,
            mechanicID: MathMechanicID.balanceScale,
            representation: .concrete,
            operation: .comparison,
            initialQuantity: 5,
            targetQuantity: 8,
            prompt: "Which side has more crystals?",
            context: "gearHall"
        ),
        LearningEncounter(
            id: "scale-compare-9-6",
            skillID: MathSkills.compare,
            mechanicID: MathMechanicID.balanceScale,
            representation: .concrete,
            operation: .comparison,
            initialQuantity: 9,
            targetQuantity: 6,
            prompt: "Which side is heavier with crystals?",
            context: "gearHall"
        ),
        LearningEncounter(
            id: "scale-compare-7-7",
            skillID: MathSkills.compare,
            mechanicID: MathMechanicID.balanceScale,
            representation: .concrete,
            operation: .comparison,
            initialQuantity: 7,
            targetQuantity: 7,
            prompt: "Do both pans hold the same number of crystals?",
            context: "gearHall"
        )
    ]

    public static let numberBondMachine: [LearningEncounter] = [
        LearningEncounter(
            id: "bond-5-known-2",
            skillID: MathSkills.bonds5,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .concrete,
            operation: .numberBond,
            initialQuantity: 2,
            targetQuantity: 5,
            prompt: "Five crystals power the machine. Two are here. Fill the other chamber.",
            context: "crystalMine"
        ),
        LearningEncounter(
            id: "bond-5-known-1",
            skillID: MathSkills.bonds5,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .concrete,
            operation: .numberBond,
            initialQuantity: 1,
            targetQuantity: 5,
            prompt: "One crystal is here. Complete the whole of five.",
            context: "crystalMine"
        ),
        LearningEncounter(
            id: "bond-10-known-6",
            skillID: MathSkills.bonds10,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .concrete,
            operation: .numberBond,
            initialQuantity: 6,
            targetQuantity: 10,
            prompt: "The machine needs ten. Six are glowing. Complete the bond.",
            context: "crystalMine"
        ),
        LearningEncounter(
            id: "bond-10-known-3",
            skillID: MathSkills.bonds10,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .concrete,
            operation: .numberBond,
            initialQuantity: 3,
            targetQuantity: 10,
            prompt: "Three crystals are here. Fill the other chamber to make ten.",
            context: "gearHall"
        )
    ]

    public static let tenFrameGate: [LearningEncounter] = [
        LearningEncounter(
            id: "ten-frame-quantity-7",
            skillID: MathSkills.numeralQuantity10,
            mechanicID: MathMechanicID.tenFrameGate,
            representation: .pictorial,
            operation: .quantityMatching,
            initialQuantity: 0,
            targetQuantity: 7,
            prompt: "Light seven spaces to open the gate.",
            context: "bridgeTower"
        ),
        LearningEncounter(
            id: "ten-frame-add-4-to-9",
            skillID: MathSkills.addition,
            mechanicID: MathMechanicID.tenFrameGate,
            representation: .pictorial,
            operation: .addition,
            initialQuantity: 4,
            targetQuantity: 9,
            prompt: "Four lights are on. Add enough to make nine.",
            context: "bridgeTower"
        ),
        LearningEncounter(
            id: "ten-frame-make-10-from-7",
            skillID: MathSkills.make10,
            mechanicID: MathMechanicID.tenFrameGate,
            representation: .pictorial,
            operation: .missingAddend,
            initialQuantity: 7,
            targetQuantity: 10,
            prompt: "Seven spaces glow. Finish the ten-frame.",
            context: "challengeGate",
            challengeDepth: 1
        )
    ]

    public static let missingNumberBridge: [LearningEncounter] = [
        LearningEncounter(
            id: "bridge-missing-6-to-10",
            skillID: MathSkills.missing,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .concrete,
            operation: .missingAddend,
            initialQuantity: 6,
            targetQuantity: 10,
            prompt: "Six plus what makes ten?",
            context: "bridgeTower"
        ),
        LearningEncounter(
            id: "bridge-missing-4-to-9",
            skillID: MathSkills.missing,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .concrete,
            operation: .missingAddend,
            initialQuantity: 4,
            targetQuantity: 9,
            prompt: "Four plus what makes nine?",
            context: "bridgeTower"
        ),
        LearningEncounter(
            id: "bridge-missing-8-to-10",
            skillID: MathSkills.missing,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .concrete,
            operation: .missingAddend,
            initialQuantity: 8,
            targetQuantity: 10,
            prompt: "Eight plus what makes ten?",
            context: "challengeGate",
            challengeDepth: 1
        )
    ]

    // Minimal authored path to the prerequisites of the five supported mechanics.
    // No placement recommendation or synthetic learner state bypasses these gates.
    public static let prerequisites: [LearningEncounter] = [
        LearningEncounter(id: "one-to-one-3", skillID: MathSkills.oneToOne10,
            mechanicID: MathMechanicID.crystalCart, representation: .concrete,
            operation: .counting, initialQuantity: 0, targetQuantity: 3,
            prompt: "Move 3 crystals, one at a time, into the cart.", context: "countingWorkshop"),
        LearningEncounter(id: "one-to-one-4", skillID: MathSkills.oneToOne10,
            mechanicID: MathMechanicID.crystalCart, representation: .concrete,
            operation: .counting, initialQuantity: 0, targetQuantity: 4,
            prompt: "Move 4 crystals, one at a time, into the cart.", context: "countingWorkshop"),
        LearningEncounter(id: "cardinality-6", skillID: MathSkills.cardinality10,
            mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
            operation: .counting, initialQuantity: 0, targetQuantity: 6,
            prompt: "Count and light 6 spaces. The last count tells how many.", context: "countingWorkshop"),
        LearningEncounter(id: "cardinality-9", skillID: MathSkills.cardinality10,
            mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
            operation: .counting, initialQuantity: 0, targetQuantity: 9,
            prompt: "Count and light 9 spaces. The last count tells how many.", context: "countingWorkshop"),
        LearningEncounter(id: "quick-look-2", skillID: MathSkills.subitizing,
            mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
            operation: .quantityMatching, initialQuantity: 0, targetQuantity: 2,
            prompt: "Look at the lights. When they hide, make the same quantity.", context: "quickLook"),
        LearningEncounter(id: "quick-look-3", skillID: MathSkills.subitizing,
            mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
            operation: .quantityMatching, initialQuantity: 0, targetQuantity: 3,
            prompt: "Look at the lights. When they hide, make the same quantity.", context: "quickLook"),
        LearningEncounter(id: "compose5-0", skillID: MathSkills.compose5,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 1, targetQuantity: 4,
            prompt: "1 crystals are in one chamber. Complete the whole of 4.", context: "compose5Workshop"),
        LearningEncounter(id: "compose5-1", skillID: MathSkills.compose5,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 2, targetQuantity: 5,
            prompt: "2 crystals are in one chamber. Complete the whole of 5.", context: "compose5Workshop"),
        LearningEncounter(id: "decompose5-0", skillID: MathSkills.decompose5,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 3, targetQuantity: 5,
            prompt: "Split 5 crystals: 3 stay here. Put the rest in the other chamber.", context: "decompose5Workshop"),
        LearningEncounter(id: "decompose5-1", skillID: MathSkills.decompose5,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 1, targetQuantity: 4,
            prompt: "Split 4 crystals: 1 stay here. Put the rest in the other chamber.", context: "decompose5Workshop"),
        LearningEncounter(id: "compose10-0", skillID: MathSkills.compose10,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 4, targetQuantity: 8,
            prompt: "4 crystals are in one chamber. Complete the whole of 8.", context: "compose10Workshop"),
        LearningEncounter(id: "compose10-1", skillID: MathSkills.compose10,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 5, targetQuantity: 10,
            prompt: "5 crystals are in one chamber. Complete the whole of 10.", context: "compose10Workshop"),
        LearningEncounter(id: "decompose10-0", skillID: MathSkills.decompose10,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 7, targetQuantity: 10,
            prompt: "Split 10 crystals: 7 stay here. Put the rest in the other chamber.", context: "decompose10Workshop"),
        LearningEncounter(id: "decompose10-1", skillID: MathSkills.decompose10,
            mechanicID: MathMechanicID.numberBondMachine, representation: .concrete,
            operation: .numberBond, initialQuantity: 2, targetQuantity: 8,
            prompt: "Split 8 crystals: 2 stay here. Put the rest in the other chamber.", context: "decompose10Workshop")
    ]

    /// Deeper reasoning delivered through the existing physical manipulatives.
    ///
    /// These encounters only enter adaptive play when their real skill prerequisites
    /// are ready. They deliberately avoid awarding unsupported "strategy choice" or
    /// "multiple solutions" evidence until a mechanic can actually observe those acts.
    public static let reasoningDepth: [LearningEncounter] = [
        LearningEncounter(
            id: "reason-equivalence-3-to-10",
            skillID: MathSkills.equivalence10,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 3,
            targetQuantity: 10,
            prompt: "One gate shows 6 + 4 = 10. Build an equal total with 3 already in this chamber.",
            context: "reasoningDepth",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "reason-same-total-2-to-10",
            skillID: MathSkills.sameTotalDifferentWay,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 2,
            targetQuantity: 10,
            prompt: "Pip already made ten with 4 and 6. Make the same total a different way with 2 here.",
            context: "reasoningDepth",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "reason-pip-mistake-4-plus-5",
            skillID: MathSkills.reasoning,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 4,
            targetQuantity: 9,
            prompt: "Pip says 4 and 5 make 10. Repair the machine so the whole is 9.",
            context: "reasoningDepth",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "reason-what-changed-6-to-9",
            skillID: MathSkills.whatChanged,
            mechanicID: MathMechanicID.crystalCart,
            representation: .reasoning,
            operation: .addition,
            initialQuantity: 6,
            targetQuantity: 9,
            prompt: "The cart changed from 6 crystals to 9. Show exactly what changed.",
            context: "reasoningDepth",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "reason-missing-9-to-15",
            skillID: MathSkills.addWithin20,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .reasoning,
            operation: .missingAddend,
            initialQuantity: 9,
            targetQuantity: 15,
            prompt: "Pip left a blank in 9 + □ = 15. Build the missing part of the bridge.",
            context: "reasoningDepth",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "reason-transfer-add-5-to-9",
            skillID: MathSkills.storyAddition10,
            mechanicID: MathMechanicID.crystalCart,
            representation: .story,
            operation: .addition,
            initialQuantity: 5,
            targetQuantity: 9,
            prompt: "Five moonstones are loaded. Four more arrive for the bridge. Show how many are ready now.",
            context: "reasoningTransfer",
            challengeDepth: 1
        ),
        LearningEncounter(
            id: "reason-transfer-subtract-12-to-7",
            skillID: MathSkills.subtractWithin20,
            mechanicID: MathMechanicID.crystalCart,
            representation: .story,
            operation: .subtraction,
            initialQuantity: 12,
            targetQuantity: 7,
            prompt: "Twelve crystals arrive. Five power the lift. Leave the crystals that remain in Pip's cart.",
            context: "reasoningTransfer",
            challengeDepth: 1
        ),
        LearningEncounter(
            id: "reason-explain-compare-7-9",
            skillID: MathSkills.explainComparison,
            mechanicID: MathMechanicID.balanceScale,
            representation: .reasoning,
            operation: .comparison,
            initialQuantity: 7,
            targetQuantity: 9,
            prompt: "The pans look close. Which side must be heavier, and what in the quantities proves it?",
            context: "reasoningDepth",
            challengeDepth: 2
        )
    ]

    public static let all: [LearningEncounter] =
        MathFoundation.encounters
        + prerequisites
        + balanceScale
        + numberBondMachine
        + tenFrameGate
        + missingNumberBridge
        + reasoningDepth
        + MathProductionQuestionBank.encounters

    public static func sessionPlan(
        for profile: LearnerProfile,
        encounterCount: Int = 12,
        now: Date = Date(),
        configuration: SessionPlannerConfiguration = SessionPlannerConfiguration()
    ) throws -> SessionPlan {
        try MathSkillCatalog
            .sessionPlanner(configuration: configuration)
            .plan(
                for: profile,
                candidates: all,
                encounterCount: encounterCount,
                now: now
            )
    }
}


/// Optional deeper-reasoning content unlocked by demonstrated secure performance.
///
/// The gate never blocks normal Math Castle progression. It opens only when the
/// learner has at least two genuinely secure source skills and three distinct
/// prerequisite-safe mechanics are available.
public enum ChallengeGateCatalog {
    public static let reward: StoryRewardID = .moonLantern
    public static let minimumSecureSourceSkills = 2
    public static let challengeCount = 3

    public static let sourceSkills: [SkillID] = [
        MathSkills.compare,
        MathSkills.addition,
        MathSkills.subtraction,
        MathSkills.bonds10,
        MathSkills.missing
    ]

    public static let encounters: [LearningEncounter] = [
        LearningEncounter(
            id: "challenge-add-4-to-9",
            skillID: MathSkills.addition,
            mechanicID: MathMechanicID.tenFrameGate,
            representation: .reasoning,
            operation: .addition,
            initialQuantity: 4,
            targetQuantity: 9,
            prompt: "The gate shows four lights. Build nine without counting from one.",
            context: "challengeGate",
            challengeDepth: 1
        ),
        LearningEncounter(
            id: "challenge-subtract-10-to-6",
            skillID: MathSkills.subtraction,
            mechanicID: MathMechanicID.crystalCart,
            representation: .story,
            operation: .subtraction,
            initialQuantity: 10,
            targetQuantity: 6,
            prompt: "Ten crystals arrive. Four power the bridge. Leave the rest in Pip's cart.",
            context: "challengeGate",
            challengeDepth: 1
        ),
        LearningEncounter(
            id: "challenge-compare-equal-8-8",
            skillID: MathSkills.explainComparison,
            mechanicID: MathMechanicID.balanceScale,
            representation: .reasoning,
            operation: .comparison,
            initialQuantity: 8,
            targetQuantity: 8,
            prompt: "Both pans look different, but the gate says they balance. Which relationship is true?",
            context: "challengeGate",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "challenge-same-total-4-to-10",
            skillID: MathSkills.sameTotalDifferentWay,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 4,
            targetQuantity: 10,
            prompt: "Pip made ten with three and seven. Make ten another way with four already in one chamber.",
            context: "challengeGate",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "challenge-pip-mistake-5-plus-3",
            skillID: MathSkills.reasoning,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 5,
            targetQuantity: 8,
            prompt: "Pip says five and three make nine. Fix his machine so the whole is eight.",
            context: "challengeGate",
            challengeDepth: 2
        ),
        LearningEncounter(
            id: "challenge-missing-9-to-14",
            skillID: MathSkills.addWithin20,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .concrete,
            operation: .missingAddend,
            initialQuantity: 9,
            targetQuantity: 14,
            prompt: "Nine plus what opens the fourteen-stone bridge?",
            context: "challengeGate",
            challengeDepth: 2
        )
    ]

    public static func secureSourceCount(for profile: LearnerProfile) -> Int {
        sourceSkills.reduce(0) { count, skill in
            let secure = profile.progress(for: skill).state.readiness >= SkillState.secure.readiness
            return count + (secure ? 1 : 0)
        }
    }

    public static func availableEncounters(
        for profile: LearnerProfile,
        graph: SkillGraph
    ) -> [LearningEncounter] {
        encounters.filter {
            graph.isEligible($0.skillID, for: profile)
                && MathManipulativeSupport.supports($0)
        }
    }

    public static func canStart(
        for profile: LearnerProfile,
        graph: SkillGraph
    ) -> Bool {
        guard !profile.hasStoryReward(reward),
              secureSourceCount(for: profile) >= minimumSecureSourceSkills else {
            return false
        }

        let available = availableEncounters(for: profile, graph: graph)
        return Set(available.map(\.mechanicID)).count >= challengeCount
    }

    public static func makeSession(
        for profile: LearnerProfile,
        graph: SkillGraph
    ) -> ChallengeGateSession? {
        guard canStart(for: profile, graph: graph) else { return nil }

        let available = availableEncounters(for: profile, graph: graph)
        var selected: [LearningEncounter] = []
        var usedMechanics: Set<String> = []

        for encounter in available where !usedMechanics.contains(encounter.mechanicID) {
            selected.append(encounter)
            usedMechanics.insert(encounter.mechanicID)
            if selected.count == challengeCount { break }
        }

        guard selected.count == challengeCount else { return nil }
        return ChallengeGateSession(
            encounterIDs: selected.map(\.id),
            rewardID: reward
        )
    }

    public static func encounter(id: String) -> LearningEncounter? {
        encounters.first { $0.id == id }
    }
}
