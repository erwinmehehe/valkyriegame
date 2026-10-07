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
        ),
        .init(
            id: "flowerGate.visual.P",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "A new rune woke in the gate. Remember its shape, then find its flower.",
            answer: "P",
            choices: ["F", "P", "R", "B"],
            transferContext: true
        ),
        .init(
            id: "flowerGate.visual.K",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .pictorial,
            prompt: "Watch the branching rune closely. Touch the flower carrying the same lines.",
            answer: "K",
            choices: ["H", "X", "K", "R"],
            transferContext: true
        ),
        .init(
            id: "flowerGate.visual.R",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.letterStones,
            representation: .symbolic,
            prompt: "Remember the final gate-rune. Match every curve and line on a flower.",
            answer: "R",
            choices: ["P", "B", "R", "K"],
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
        ),
        .init(
            id: "sunmill.visual.p",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "The Sunmill turned to a new rune. Pick the leaf with the same shape.",
            answer: "p",
            choices: ["q", "p", "b", "d"],
            context: "sunmillCrossing",
            transferContext: true
        ),
        .init(
            id: "sunmill.visual.k",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .pictorial,
            prompt: "Look at the mill-rune's branches. Find the leaf that matches exactly.",
            answer: "k",
            choices: ["h", "k", "x", "t"],
            context: "sunmillCrossing",
            transferContext: true
        ),
        .init(
            id: "sunmill.visual.r",
            skillID: LiteracySkills.visualLetterMatch,
            mechanicID: WordGardenMechanicID.sunmillPair,
            representation: .symbolic,
            prompt: "Hold the last mill-rune in memory, then pick its twin leaf.",
            answer: "r",
            choices: ["n", "r", "v", "c"],
            context: "sunmillCrossing",
            transferContext: true
        )
    ]

    /// Story Hollow stays on visual print memory until recorded phoneme/letter-name
    /// audio exists. Two separate three-rune memories increase transfer without
    /// claiming that the child decoded the letter strings as words.
    public static let storyHollowPatterns: [[String]] = [
        ["m", "a", "p"],
        ["r", "i", "n"]
    ]
    public static let storyHollowPattern = storyHollowPatterns[0]
    public static let storyHollowPatternLength = 3

    public static let storyHollowSequence: [LiteracyEncounter] = [
        .init(
            id: "storyHollow.sequence.first",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .symbolic,
            prompt: "Remember the three glowing seed-runes. Restore the first shape.",
            answer: "m",
            choices: ["m", "n", "w", "h"],
            context: "storyHollow"
        ),
        .init(
            id: "storyHollow.sequence.middle",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .symbolic,
            prompt: "Remember the seed-runes. Restore the middle shape.",
            answer: "a",
            choices: ["a", "d", "o", "e"],
            context: "storyHollow"
        ),
        .init(
            id: "storyHollow.sequence.last",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .symbolic,
            prompt: "Remember the seed-runes. Restore the last shape.",
            answer: "p",
            choices: ["p", "q", "b", "d"],
            context: "storyHollow",
            transferContext: true
        ),
        .init(
            id: "storyHollow.sequence.transfer.first",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .pictorial,
            prompt: "A second memory branch woke. Remember its three seed-runes and restore the first shape.",
            answer: "r",
            choices: ["r", "n", "v", "c"],
            context: "storyHollow",
            transferContext: true
        ),
        .init(
            id: "storyHollow.sequence.transfer.middle",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .symbolic,
            prompt: "Keep the new memory in mind. Restore the middle seed-rune.",
            answer: "i",
            choices: ["i", "l", "j", "t"],
            context: "storyHollow",
            transferContext: true
        ),
        .init(
            id: "storyHollow.sequence.transfer.last",
            skillID: LiteracySkills.visualPrintSequence,
            mechanicID: WordGardenMechanicID.storySeedSequence,
            representation: .pictorial,
            prompt: "Finish the second memory branch by restoring its last seed-rune.",
            answer: "n",
            choices: ["n", "m", "h", "r"],
            context: "storyHollow",
            transferContext: true
        )
    ]

    public static func storyHollowPattern(for encounter: LiteracyEncounter) -> [String] {
        guard let index = storyHollowSequence.firstIndex(where: { $0.id == encounter.id }) else {
            return storyHollowPattern
        }
        let patternIndex = min(index / storyHollowPatternLength, storyHollowPatterns.count - 1)
        return storyHollowPatterns[patternIndex]
    }

    public static func storyHollowPosition(for encounter: LiteracyEncounter) -> Int {
        guard let index = storyHollowSequence.firstIndex(where: { $0.id == encounter.id }) else {
            return 0
        }
        return index % storyHollowPatternLength
    }

    public static func storyHollowVisiblePatternProgress(independentCount: Int) -> (
        pattern: [String],
        filledCount: Int
    ) {
        let clamped = min(max(0, independentCount), storyHollowSequence.count)
        if clamped >= storyHollowSequence.count {
            return (storyHollowPatterns.last ?? storyHollowPattern, storyHollowPatternLength)
        }

        let patternIndex = min(
            clamped / storyHollowPatternLength,
            storyHollowPatterns.count - 1
        )
        return (
            storyHollowPatterns[patternIndex],
            clamped % storyHollowPatternLength
        )
    }
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

    public static func canEnterStoryHollow(profile: LearnerProfile) -> Bool {
        sunmillComplete(profile: profile)
    }

    public static func nextStoryHollowEncounter(profile: LearnerProfile) -> LiteracyEncounter? {
        guard canEnterStoryHollow(profile: profile) else { return nil }
        return nextCandidate(
            from: WordGardenEncounterCatalog.storyHollowSequence,
            profile: profile
        )
    }

    public static func storyHollowComplete(profile: LearnerProfile) -> Bool {
        independentSuccessCount(
            for: WordGardenEncounterCatalog.storyHollowSequence,
            profile: profile
        ) == WordGardenEncounterCatalog.storyHollowSequence.count
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
