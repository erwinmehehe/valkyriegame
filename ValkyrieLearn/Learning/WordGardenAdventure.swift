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
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            choices.joined(separator: ","),
            answer,
            context
        ].joined(separator: "|")
    }
}

public enum WordGardenEncounterCatalog {
    /// Flower Gate measures visual identity only. The target rune is shown briefly
    /// by the native scene and then hidden before the learner chooses.
    public static let visualLetterShapes: [LiteracyEncounter] = [
        .init(
            id: "flowerGate.visual.A",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "Remember the glowing rune. Then touch the flower carrying the same shape.",
            answer: "A",
            choices: ["M", "A", "S", "T"]
        ),
        .init(
            id: "flowerGate.visual.M",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "Remember the glowing rune. Then touch the flower carrying the same shape.",
            answer: "M",
            choices: ["N", "W", "M", "H"]
        ),
        .init(
            id: "flowerGate.visual.S",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .pictorial,
            prompt: "Remember the glowing vine-rune. Then find the matching flower.",
            answer: "S",
            choices: ["C", "S", "G", "O"],
            transferContext: true
        )
    ]

    /// Sunmill teaches a visual uppercase/lowercase relationship without naming
    /// the letters aloud. Spoken letter-name evidence remains gated on recordings.
    public static let visualCasePairs: [LiteracyEncounter] = [
        .init(
            id: "sunmill.case.A-a",
            skillID: LiteracySkills.visualCasePairing,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill shows a tall rune. Find its little partner shape.",
            answer: "a",
            choices: ["d", "a", "o", "e"],
            context: "sunmillCrossing"
        ),
        .init(
            id: "sunmill.case.M-m",
            skillID: LiteracySkills.visualCasePairing,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill shows another tall rune. Find its little partner shape.",
            answer: "m",
            choices: ["n", "w", "m", "h"],
            context: "sunmillCrossing"
        ),
        .init(
            id: "sunmill.case.S-s",
            skillID: LiteracySkills.visualCasePairing,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .pictorial,
            prompt: "The Sunmill rune curls through the light. Find its little partner shape.",
            answer: "s",
            choices: ["c", "s", "g", "o"],
            context: "sunmillCrossing",
            transferContext: true
        )
    ]

    public static func uppercaseTarget(for encounter: LiteracyEncounter) -> String? {
        switch encounter.id {
        case "sunmill.case.A-a": return "A"
        case "sunmill.case.M-m": return "M"
        case "sunmill.case.S-s": return "S"
        default: return nil
        }
    }
}

public enum WordGardenDirector {
    public static func nextFlowerGateEncounter(profile: LearnerProfile) -> LiteracyEncounter {
        nextCandidate(from: WordGardenEncounterCatalog.visualLetterShapes, profile: profile)
    }

    public static func flowerGateComplete(profile: LearnerProfile) -> Bool {
        profile.progress(for: LiteracySkills.visualLetterMatch).state.readiness
            >= SkillState.secure.readiness
    }

    public static func canEnterSunmill(profile: LearnerProfile, graph: SkillGraph) -> Bool {
        flowerGateComplete(profile: profile)
            && graph.isEligible(LiteracySkills.visualCasePairing, for: profile)
    }

    public static func nextSunmillEncounter(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> LiteracyEncounter? {
        guard canEnterSunmill(profile: profile, graph: graph) else { return nil }
        return nextCandidate(from: WordGardenEncounterCatalog.visualCasePairs, profile: profile)
    }

    public static func sunmillComplete(profile: LearnerProfile) -> Bool {
        profile.progress(for: LiteracySkills.visualCasePairing).state.readiness
            >= SkillState.secure.readiness
    }

    public static func independentSuccessCount(
        for encounters: [LiteracyEncounter],
        profile: LearnerProfile
    ) -> Int {
        guard let skill = encounters.first?.skillID else { return 0 }
        let validIDs = Set(encounters.map(\.id))
        return Set(
            profile.progress(for: skill).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && validIDs.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func nextEncounter(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> LiteracyEncounter {
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
