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


/// Authored encounter set for the first reusable Math Castle mechanics.
///
/// These are intentionally few and varied. The goal is adaptive delivery across
/// different representations and mechanics, not a large generated question bank.
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
            id: "bridge-missing-8-to-10",
            skillID: MathSkills.missing,
            mechanicID: MathMechanicID.missingNumberBridge,
            representation: .symbolic,
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

    public static let all: [LearningEncounter] =
        MathFoundation.encounters
        + prerequisites
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
            representation: .symbolic,
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
