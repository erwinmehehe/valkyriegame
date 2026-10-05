import Foundation

// MARK: - Puzzle Palace v2 encounter selection

public struct PuzzleEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let fixedRunes: [String]
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
        fixedRunes: [String],
        answer: String,
        choices: [String],
        context: String = "runeGate",
        transferContext: Bool = false
    ) {
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.fixedRunes = fixedRunes
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
            fixedRunes.joined(separator: ","),
            answer,
            context
        ].joined(separator: "|")
    }
}


public struct PuzzleMemoryEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let sequence: [String]
    public let choices: [String]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID = PuzzleSkills.visualSequenceMemory,
        mechanicID: String = PuzzlePalaceMechanicID.memoryBridge,
        representation: Representation = .pictorial,
        prompt: String,
        sequence: [String],
        choices: [String],
        context: String = "memoryBridge",
        transferContext: Bool = false
    ) {
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.sequence = sequence
        self.choices = choices
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            sequence.joined(separator: ","),
            context
        ].joined(separator: "|")
    }
}

public enum PuzzlePalaceEncounterCatalog {
    /// v3.31 used three one-socket rune beats. The native version preserves
    /// those symbols but makes the repeating rule explicit enough to infer:
    /// A B A ? rather than A B ?.
    public static let runeGate: [PuzzleEncounter] = [
        .init(
            id: "puzzle.runeGate.starMoon",
            skillID: PuzzleSkills.visualPatternContinue,
            mechanicID: PuzzlePalaceMechanicID.runeGate,
            representation: .symbolic,
            prompt: "The palace path repeats. Fit the rune that keeps the pattern going.",
            fixedRunes: ["★", "☾", "★"],
            answer: "☾",
            choices: ["◆", "☾", "★"]
        ),
        .init(
            id: "puzzle.runeGate.moonDiamond",
            skillID: PuzzleSkills.visualPatternContinue,
            mechanicID: PuzzlePalaceMechanicID.runeGate,
            representation: .symbolic,
            prompt: "The next arch uses a new pair. Continue its repeating rune path.",
            fixedRunes: ["☾", "◆", "☾"],
            answer: "◆",
            choices: ["☾", "★", "◆"],
            transferContext: true
        ),
        .init(
            id: "puzzle.runeGate.diamondStar",
            skillID: PuzzleSkills.visualPatternContinue,
            mechanicID: PuzzlePalaceMechanicID.runeGate,
            representation: .reasoning,
            prompt: "One more seal blocks the gate. Follow the same kind of repeating rule.",
            fixedRunes: ["◆", "★", "◆"],
            answer: "★",
            choices: ["★", "☾", "◆"],
            transferContext: true
        )
    ]

    public static let memoryBridge: [PuzzleMemoryEncounter] = [
        .init(
            id: "puzzle.memoryBridge.starMoonDiamond",
            prompt: "Watch Tiko wake the bridge runes. Then repeat the order from memory.",
            sequence: ["★", "☾", "◆"],
            choices: ["★", "☾", "◆", "●"]
        ),
        .init(
            id: "puzzle.memoryBridge.diamondCircleStar",
            prompt: "The next bridge remembers a new three-rune path. Watch, then rebuild it.",
            sequence: ["◆", "●", "★"],
            choices: ["★", "☾", "◆", "●"],
            transferContext: true
        ),
        .init(
            id: "puzzle.memoryBridge.moonStarCircleDiamond",
            prompt: "Tiko found a longer bridge memory. Hold the four-rune order, then restore it.",
            sequence: ["☾", "★", "●", "◆"],
            choices: ["★", "☾", "◆", "●"],
            transferContext: true
        )
    ]
}

public enum PuzzlePalaceDirector {
    public static func nextRuneGateEncounter(profile: LearnerProfile) -> PuzzleEncounter {
        let candidates = PuzzlePalaceEncounterCatalog.runeGate
        let independent = Set(
            profile.progress(for: PuzzleSkills.visualPatternContinue).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }
        let attempts = profile.progress(for: PuzzleSkills.visualPatternContinue).evidence.count
        return candidates[attempts % candidates.count]
    }

    public static func runeGateIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let ids = Set(PuzzlePalaceEncounterCatalog.runeGate.map(\.id))
        return Set(
            profile.progress(for: PuzzleSkills.visualPatternContinue).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func runeGateComplete(profile: LearnerProfile) -> Bool {
        runeGateIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.runeGate.count
    }

    public static func canEnterMemoryBridge(profile: LearnerProfile) -> Bool {
        runeGateComplete(profile: profile)
    }

    public static func nextMemoryBridgeEncounter(profile: LearnerProfile) -> PuzzleMemoryEncounter? {
        guard canEnterMemoryBridge(profile: profile) else { return nil }
        let candidates = PuzzlePalaceEncounterCatalog.memoryBridge
        let independent = Set(
            profile.progress(for: PuzzleSkills.visualSequenceMemory).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }
        let attempts = profile.progress(for: PuzzleSkills.visualSequenceMemory).evidence.count
        return candidates[attempts % candidates.count]
    }

    public static func memoryBridgeIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let ids = Set(PuzzlePalaceEncounterCatalog.memoryBridge.map(\.id))
        return Set(
            profile.progress(for: PuzzleSkills.visualSequenceMemory).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func memoryBridgeComplete(profile: LearnerProfile) -> Bool {
        memoryBridgeIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.memoryBridge.count
    }
}

