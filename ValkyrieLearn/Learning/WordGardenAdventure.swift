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
        .init(id: "flowerGate.upper.A", skillID: LiteracySkills.uppercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .symbolic,
              prompt: "The gate needs A. Touch the flower carrying A.", answer: "A",
              choices: ["M", "A", "S", "T"]),
        .init(id: "flowerGate.upper.M", skillID: LiteracySkills.uppercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .symbolic,
              prompt: "The gate needs M. Touch the flower carrying M.", answer: "M",
              choices: ["N", "W", "M", "H"]),
        .init(id: "flowerGate.upper.S", skillID: LiteracySkills.uppercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .pictorial,
              prompt: "Lumi found an S-shaped vine. Touch the matching flower.", answer: "S",
              choices: ["C", "S", "G", "O"], transferContext: true)
    ]

    public static let lowercaseLetters: [LiteracyEncounter] = [
        .init(id: "flowerGate.lower.a", skillID: LiteracySkills.lowercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .symbolic,
              prompt: "Find the little letter that matches A.", answer: "a",
              choices: ["d", "a", "o", "e"]),
        .init(id: "flowerGate.lower.m", skillID: LiteracySkills.lowercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .symbolic,
              prompt: "Find the little letter that matches M.", answer: "m",
              choices: ["n", "w", "m", "h"]),
        .init(id: "flowerGate.lower.s", skillID: LiteracySkills.lowercaseLetterNames,
              mechanicID: WordGardenMechanicID.letterStones, representation: .pictorial,
              prompt: "The vine curls like S. Which little letter matches it?", answer: "s",
              choices: ["c", "s", "g", "o"], transferContext: true)
    ]
}

public enum WordGardenDirector {
    public static func nextEncounter(profile: LearnerProfile, graph: SkillGraph) -> LiteracyEncounter {
        let lowerEligible = graph.isEligible(LiteracySkills.lowercaseLetterNames, for: profile)
        let candidates = lowerEligible
            ? WordGardenEncounterCatalog.lowercaseLetters
            : WordGardenEncounterCatalog.uppercaseLetters
        let completed = Set(
            profile.progress(for: candidates[0].skillID).evidence
                .filter { $0.outcome == .correct }
                .map(\.encounterID)
        )
        return candidates.first { !completed.contains($0.id) } ?? candidates[completed.count % candidates.count]
    }
}
