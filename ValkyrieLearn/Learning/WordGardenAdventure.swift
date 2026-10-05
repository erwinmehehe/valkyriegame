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
}

public enum WordGardenDirector {
    /// Flower Gate remains on visual print identity until approved recorded
    /// letter-name/phoneme audio is bundled. Eligibility for later audio skills can
    /// still advance in the profile, but this director will not silently substitute
    /// a visual matching task for a spoken-language assessment.
    public static func nextEncounter(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> LiteracyEncounter {
        let candidates = WordGardenEncounterCatalog.visualLetterShapes
        let completed = Set(
            profile.progress(for: LiteracySkills.visualLetterMatch).evidence
                .filter { $0.outcome == .correct }
                .map(\.encounterID)
        )
        return candidates.first { !completed.contains($0.id) }
            ?? candidates[completed.count % candidates.count]
    }
}
