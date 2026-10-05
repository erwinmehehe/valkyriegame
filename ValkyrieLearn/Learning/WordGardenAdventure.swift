import Foundation

public struct LiteracyEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let answer: String
    public let choices: [String]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID,
        mechanicID: String,
        representation: Representation,
        prompt: String,
        answer: String,
        choices: [String],
        context: String = "flowerGate",
        transferContext: Bool = false
    ) {
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.answer = answer
        self.choices = choices
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        "\(mechanicID)|\(skillID.rawValue)|\(representation.rawValue)|\(answer)|\(context)"
    }
}

public enum WordGardenEncounterCatalog {
    public static let uppercaseLetters: [LiteracyEncounter] = [
        .init(
            id: "flowerGate.upper.A",
            skillID: LiteracySkills.uppercaseLetterNames,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "The gate needs A. Touch the flower carrying A.",
            answer: "A",
            choices: ["M", "A", "S", "T"]
        ),
        .init(
            id: "flowerGate.upper.M",
            skillID: LiteracySkills.uppercaseLetterNames,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "The gate needs M. Touch the flower carrying M.",
            answer: "M",
            choices: ["N", "W", "M", "H"]
        ),
        .init(
            id: "flowerGate.upper.S",
            skillID: LiteracySkills.uppercaseLetterNames,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "Lumi found an S-shaped vine. Touch the matching flower.",
            answer: "S",
            choices: ["C", "S", "G", "O"],
            transferContext: true
        )
    ]

    public static let lowercaseLetters: [LiteracyEncounter] = [
        .init(
            id: "sunmill.lower.a",
            skillID: LiteracySkills.lowercaseLetterNames,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill shows A. Touch the little letter that matches.",
            answer: "a",
            choices: ["d", "a", "o", "e"],
            context: "sunmillCrossing"
        ),
        .init(
            id: "sunmill.lower.m",
            skillID: LiteracySkills.lowercaseLetterNames,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill shows M. Touch the little letter that matches.",
            answer: "m",
            choices: ["n", "w", "m", "h"],
            context: "sunmillCrossing"
        ),
        .init(
            id: "sunmill.lower.s",
            skillID: LiteracySkills.lowercaseLetterNames,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill shows S. Find its little-letter match.",
            answer: "s",
            choices: ["c", "s", "g", "o"],
            context: "sunmillCrossing",
            transferContext: true
        )
    ]
}

public enum WordGardenDirector {
    public static func nextFlowerGateEncounter(profile: LearnerProfile) -> LiteracyEncounter {
        nextCandidate(from: WordGardenEncounterCatalog.uppercaseLetters, profile: profile)
    }

    public static func flowerGateComplete(profile: LearnerProfile) -> Bool {
        profile.progress(for: LiteracySkills.uppercaseLetterNames).state.readiness
            >= SkillState.secure.readiness
    }

    public static func canEnterSunmill(profile: LearnerProfile, graph: SkillGraph) -> Bool {
        flowerGateComplete(profile: profile)
            && graph.isEligible(LiteracySkills.lowercaseLetterNames, for: profile)
    }

    public static func nextSunmillEncounter(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> LiteracyEncounter? {
        guard canEnterSunmill(profile: profile, graph: graph) else { return nil }
        return nextCandidate(from: WordGardenEncounterCatalog.lowercaseLetters, profile: profile)
    }

    public static func sunmillComplete(profile: LearnerProfile) -> Bool {
        profile.progress(for: LiteracySkills.lowercaseLetterNames).state.readiness
            >= SkillState.secure.readiness
    }

    public static func independentSuccessCount(
        for encounters: [LiteracyEncounter],
        profile: LearnerProfile
    ) -> Int {
        guard let skill = encounters.first?.skillID else { return 0 }
        let validIDs = Set(encounters.map(\.id))
        let independent = Set(
            profile.progress(for: skill).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && validIDs.contains($0.encounterID)
                }
                .map(\.encounterID)
        )
        return independent.count
    }

    /// Compatibility entry point for callers that only know they are in Word Garden.
    /// The native scenes use the place-specific selectors above.
    public static func nextEncounter(profile: LearnerProfile, graph: SkillGraph) -> LiteracyEncounter {
        if let sunmill = nextSunmillEncounter(profile: profile, graph: graph),
           !sunmillComplete(profile: profile) {
            return sunmill
        }
        return nextFlowerGateEncounter(profile: profile)
    }

    private static func nextCandidate(
        from candidates: [LiteracyEncounter],
        profile: LearnerProfile
    ) -> LiteracyEncounter {
        precondition(!candidates.isEmpty)
        let skill = candidates[0].skillID
        let independent = Set(
            profile.progress(for: skill).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }

        let attempts = profile.progress(for: skill).evidence.count
        return candidates[attempts % candidates.count]
    }
}
