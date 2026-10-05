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
    /// These are intentionally visual-memory tasks. They can produce honest evidence
    /// before recorded letter-name/phoneme audio is available.
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

    /// Sunmill is a transfer context for the same honest visual-print skill.
    /// Lowercase glyphs are matched by shape only; no spoken letter-name claim is made.
    public static let sunmillVisualShapes: [LiteracyEncounter] = [
        .init(
            id: "sunmill.visual.a",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "Look. Pick the twin.",
            answer: "a",
            choices: ["d", "a", "o", "e"],
            context: "sunmillCrossing",
            transferContext: true
        ),
        .init(
            id: "sunmill.visual.m",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "Look. Pick the twin.",
            answer: "m",
            choices: ["n", "w", "m", "h"],
            context: "sunmillCrossing",
            transferContext: true
        ),
        .init(
            id: "sunmill.visual.s",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .pictorial,
            prompt: "Look. Pick the twin.",
            answer: "s",
            choices: ["c", "s", "g", "o"],
            context: "sunmillCrossing",
            transferContext: true
        )
    ]
}

public enum WordGardenDirector {
    public static func nextFlowerGateEncounter(profile: LearnerProfile) -> LiteracyEncounter {
        nextCandidate(from: WordGardenEncounterCatalog.visualLetterShapes, profile: profile)
    }

    public static func flowerGateComplete(profile: LearnerProfile) -> Bool {
        independentSuccessCount(
            for: WordGardenEncounterCatalog.visualLetterShapes,
            profile: profile
        ) == WordGardenEncounterCatalog.visualLetterShapes.count
    }

    public static func canEnterSunmill(profile: LearnerProfile) -> Bool {
        flowerGateComplete(profile: profile)
    }

    public static func nextSunmillEncounter(profile: LearnerProfile) -> LiteracyEncounter? {
        guard canEnterSunmill(profile: profile) else { return nil }
        return nextCandidate(from: WordGardenEncounterCatalog.sunmillVisualShapes, profile: profile)
    }

    public static func sunmillComplete(profile: LearnerProfile) -> Bool {
        independentSuccessCount(
            for: WordGardenEncounterCatalog.sunmillVisualShapes,
            profile: profile
        ) == WordGardenEncounterCatalog.sunmillVisualShapes.count
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

    /// Compatibility entry point for callers that do not know the physical Word Garden place.
    /// This intentionally remains on the Flower Gate visual task until approved audio ships.
    public static func nextEncounter(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> LiteracyEncounter {
        _ = graph
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
