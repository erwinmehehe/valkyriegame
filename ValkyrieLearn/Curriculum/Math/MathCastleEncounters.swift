import Foundation

/// Authored encounter set for the first reusable Math Castle mechanics.
///
/// These are intentionally few and varied. The goal is to prove adaptive delivery
/// across different representations/mechanics, not to manufacture a giant question bank.
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
            skillID: MathSkills.explainComparison,
            mechanicID: MathMechanicID.balanceScale,
            representation: .reasoning,
            operation: .comparison,
            initialQuantity: 7,
            targetQuantity: 7,
            prompt: "The scale is level. What does that tell us?",
            context: "gearHall",
            challengeDepth: 1
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
            id: "bond-10-known-3-reason",
            skillID: MathSkills.sameTotalDifferentWay,
            mechanicID: MathMechanicID.numberBondMachine,
            representation: .reasoning,
            operation: .numberBond,
            initialQuantity: 3,
            targetQuantity: 10,
            prompt: "Pip already made ten one way. Can you complete a different split?",
            context: "challengeGate",
            challengeDepth: 1
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
            representation: .symbolic,
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
            representation: .symbolic,
            operation: .missingAddend,
            initialQuantity: 4,
            targetQuantity: 9,
            prompt: "Four plus what makes nine?",
            context: "bridgeTower"
        ),
        LearningEncounter(
            id: "bridge-missing-8-to-13",
            skillID: MathSkills.addWithin20,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .symbolic,
            operation: .missingAddend,
            initialQuantity: 8,
            targetQuantity: 13,
            prompt: "Eight plus what makes thirteen?",
            context: "challengeGate",
            challengeDepth: 1
        )
    ]

    public static let all: [LearningEncounter] =
        MathFoundation.encounters
        + balanceScale
        + numberBondMachine
        + tenFrameGate
        + missingNumberBridge

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
