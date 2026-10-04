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
            for total in [7, 5, 8, 6] {
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
                representation: .symbolic,
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
