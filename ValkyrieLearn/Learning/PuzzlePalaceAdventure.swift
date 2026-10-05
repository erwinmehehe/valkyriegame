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


public enum PuzzleGateSignal: String, Codable, CaseIterable, Equatable, Sendable {
    case hold
    case go
}

public struct PuzzleInhibitionEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let signals: [PuzzleGateSignal]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID = PuzzleSkills.responseInhibition,
        mechanicID: String = PuzzlePalaceMechanicID.stopGoOrbs,
        representation: Representation = .concrete,
        prompt: String,
        signals: [PuzzleGateSignal],
        context: String = "stopGoOrbs",
        transferContext: Bool = false
    ) {
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.signals = signals
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            signals.map(\.rawValue).joined(separator: ","),
            context
        ].joined(separator: "|")
    }
}


public enum PuzzleSortRule: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case shape
    case marks
}

public enum PuzzleSortBucket: String, Codable, CaseIterable, Equatable, Sendable {
    case left
    case right
}

public struct PuzzleSortObject: Identifiable, Equatable, Sendable {
    public let id: String
    public let shape: String
    public let markCount: Int

    public init(id: String, shape: String, markCount: Int) {
        self.id = id
        self.shape = shape
        self.markCount = markCount
    }

    public func bucket(for rule: PuzzleSortRule) -> PuzzleSortBucket {
        switch rule {
        case .shape:
            return shape == "round" ? .left : .right
        case .marks:
            return markCount == 1 ? .left : .right
        }
    }

    public var glyph: String {
        shape == "round" ? "●" : "▲"
    }

    public var marks: String {
        String(repeating: "•", count: max(1, min(markCount, 2)))
    }
}

public struct PuzzleSortEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let rules: [PuzzleSortRule]
    public let objects: [PuzzleSortObject]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID,
        mechanicID: String = PuzzlePalaceMechanicID.sortingPedestal,
        representation: Representation = .concrete,
        prompt: String,
        rules: [PuzzleSortRule],
        objects: [PuzzleSortObject],
        context: String = "sortingPedestal",
        transferContext: Bool = false
    ) {
        precondition(!objects.isEmpty)
        precondition(rules.count == objects.count)
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.rules = rules
        self.objects = objects
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            rules.map(\.rawValue).joined(separator: ","),
            objects.map { "\($0.shape)-\($0.markCount)" }.joined(separator: ","),
            context
        ].joined(separator: "|")
    }
}


public struct PuzzleResortEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let initialRule: PuzzleSortRule
    public let changedRule: PuzzleSortRule
    public let objects: [PuzzleSortObject]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID = PuzzleSkills.changedRuleSort,
        mechanicID: String = PuzzlePalaceMechanicID.changedRuleResort,
        representation: Representation = .concrete,
        prompt: String,
        initialRule: PuzzleSortRule,
        changedRule: PuzzleSortRule,
        objects: [PuzzleSortObject],
        context: String = "resortVault",
        transferContext: Bool = false
    ) {
        precondition(initialRule != changedRule)
        precondition(!objects.isEmpty)
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.initialRule = initialRule
        self.changedRule = changedRule
        self.objects = objects
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            initialRule.rawValue,
            changedRule.rawValue,
            objects.map { "\($0.id):\($0.shape)-\($0.markCount)" }.joined(separator: ","),
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

    public static let stopGoOrbs: [PuzzleInhibitionEncounter] = [
        .init(
            id: "puzzle.stopGo.holdGoHoldGo",
            prompt: "The palace orb opens only on GO. Hold still through the lock signals.",
            signals: [.hold, .go, .hold, .go]
        ),
        .init(
            id: "puzzle.stopGo.doubleHoldGo",
            prompt: "Tiko changed the rhythm. Wait through both lock signals before GO.",
            signals: [.hold, .hold, .go, .hold, .go],
            transferContext: true
        ),
        .init(
            id: "puzzle.stopGo.mixedLong",
            prompt: "The final orb mixes short and long waits. Touch only when the gate opens.",
            signals: [.hold, .go, .hold, .hold, .go, .hold, .go],
            transferContext: true
        )
    ]

    private static let roundOne = PuzzleSortObject(id: "round-one", shape: "round", markCount: 1)
    private static let roundTwo = PuzzleSortObject(id: "round-two", shape: "round", markCount: 2)
    private static let pointedOne = PuzzleSortObject(id: "pointed-one", shape: "pointed", markCount: 1)
    private static let pointedTwo = PuzzleSortObject(id: "pointed-two", shape: "pointed", markCount: 2)

    public static let sortingFoundation: [PuzzleSortEncounter] = [
        .init(
            id: "puzzle.sorting.shapeA",
            skillID: PuzzleSkills.singleRuleSort,
            prompt: "The pedestal is sorting by SHAPE. Send round stones left and pointed stones right.",
            rules: [.shape, .shape, .shape, .shape],
            objects: [roundOne, pointedTwo, roundTwo, pointedOne]
        ),
        .init(
            id: "puzzle.sorting.marksA",
            skillID: PuzzleSkills.singleRuleSort,
            prompt: "The dial changed. Sort by MARKS: one mark left, two marks right.",
            rules: [.marks, .marks, .marks, .marks],
            objects: [pointedOne, roundTwo, roundOne, pointedTwo],
            transferContext: true
        ),
        .init(
            id: "puzzle.sorting.shapeB",
            skillID: PuzzleSkills.singleRuleSort,
            prompt: "One more stable rule: sort these new stones by SHAPE.",
            rules: [.shape, .shape, .shape, .shape],
            objects: [pointedTwo, roundOne, pointedOne, roundTwo],
            transferContext: true
        )
    ]

    public static let ruleSwitching: [PuzzleSortEncounter] = [
        .init(
            id: "puzzle.switch.shapeToMarks",
            skillID: PuzzleSkills.ruleSwitching,
            prompt: "Watch the palace dial. The sorting rule will change while the stones keep coming.",
            rules: [.shape, .shape, .marks, .marks],
            objects: [roundTwo, pointedOne, pointedTwo, roundOne]
        ),
        .init(
            id: "puzzle.switch.marksToShape",
            skillID: PuzzleSkills.ruleSwitching,
            prompt: "Tiko reversed the dial. Follow each rule change before choosing a pedestal.",
            rules: [.marks, .marks, .shape, .shape],
            objects: [pointedTwo, roundOne, roundTwo, pointedOne],
            transferContext: true
        ),
        .init(
            id: "puzzle.switch.alternating",
            skillID: PuzzleSkills.ruleSwitching,
            prompt: "The final dial shifts more often. Use the rule that is glowing now.",
            rules: [.shape, .marks, .marks, .shape, .marks],
            objects: [roundOne, pointedTwo, roundTwo, pointedOne, roundOne],
            transferContext: true
        )
    ]

    public static let changedRuleResort: [PuzzleResortEncounter] = [
        .init(
            id: "puzzle.resort.shapeToMarksA",
            prompt: "Sort this exact set by SHAPE. When the vault flips, re-sort the same stones by MARKS.",
            initialRule: .shape,
            changedRule: .marks,
            objects: [roundOne, pointedTwo, roundTwo, pointedOne]
        ),
        .init(
            id: "puzzle.resort.marksToShapeA",
            prompt: "Start with MARKS. Then keep the same stones and rebuild the groups by SHAPE.",
            initialRule: .marks,
            changedRule: .shape,
            objects: [pointedOne, roundTwo, pointedTwo, roundOne],
            transferContext: true
        ),
        .init(
            id: "puzzle.resort.shapeToMarksB",
            prompt: "The final vault set must survive a full rule change without swapping any stones.",
            initialRule: .shape,
            changedRule: .marks,
            objects: [roundTwo, pointedOne, roundOne, pointedTwo],
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

    public static func canEnterStopGoOrbs(profile: LearnerProfile) -> Bool {
        memoryBridgeComplete(profile: profile)
    }

    public static func nextStopGoEncounter(profile: LearnerProfile) -> PuzzleInhibitionEncounter? {
        guard canEnterStopGoOrbs(profile: profile) else { return nil }
        let candidates = PuzzlePalaceEncounterCatalog.stopGoOrbs
        let independent = Set(
            profile.progress(for: PuzzleSkills.responseInhibition).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }
        let attempts = profile.progress(for: PuzzleSkills.responseInhibition).evidence.count
        return candidates[attempts % candidates.count]
    }

    public static func stopGoIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let ids = Set(PuzzlePalaceEncounterCatalog.stopGoOrbs.map(\.id))
        return Set(
            profile.progress(for: PuzzleSkills.responseInhibition).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func stopGoComplete(profile: LearnerProfile) -> Bool {
        stopGoIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.stopGoOrbs.count
    }

    public static func canEnterSortingPedestal(profile: LearnerProfile) -> Bool {
        stopGoComplete(profile: profile)
    }

    public static func nextSortingFoundationEncounter(profile: LearnerProfile) -> PuzzleSortEncounter? {
        guard canEnterSortingPedestal(profile: profile) else { return nil }
        return nextSortCandidate(
            from: PuzzlePalaceEncounterCatalog.sortingFoundation,
            skill: PuzzleSkills.singleRuleSort,
            profile: profile
        )
    }

    public static func sortingFoundationComplete(profile: LearnerProfile) -> Bool {
        independentSortSuccessCount(
            for: PuzzlePalaceEncounterCatalog.sortingFoundation,
            skill: PuzzleSkills.singleRuleSort,
            profile: profile
        ) == PuzzlePalaceEncounterCatalog.sortingFoundation.count
    }

    public static func canStartRuleSwitching(profile: LearnerProfile) -> Bool {
        canEnterSortingPedestal(profile: profile)
            && sortingFoundationComplete(profile: profile)
    }

    public static func nextRuleSwitchingEncounter(profile: LearnerProfile) -> PuzzleSortEncounter? {
        guard canStartRuleSwitching(profile: profile) else { return nil }
        return nextSortCandidate(
            from: PuzzlePalaceEncounterCatalog.ruleSwitching,
            skill: PuzzleSkills.ruleSwitching,
            profile: profile
        )
    }

    public static func ruleSwitchingComplete(profile: LearnerProfile) -> Bool {
        independentSortSuccessCount(
            for: PuzzlePalaceEncounterCatalog.ruleSwitching,
            skill: PuzzleSkills.ruleSwitching,
            profile: profile
        ) == PuzzlePalaceEncounterCatalog.ruleSwitching.count
    }

    public static func sortingPedestalComplete(profile: LearnerProfile) -> Bool {
        sortingFoundationComplete(profile: profile)
            && ruleSwitchingComplete(profile: profile)
    }

    public static func canEnterChangedRuleResort(profile: LearnerProfile) -> Bool {
        sortingPedestalComplete(profile: profile)
    }

    public static func nextChangedRuleResortEncounter(profile: LearnerProfile) -> PuzzleResortEncounter? {
        guard canEnterChangedRuleResort(profile: profile) else { return nil }
        let candidates = PuzzlePalaceEncounterCatalog.changedRuleResort
        let independent = Set(
            profile.progress(for: PuzzleSkills.changedRuleSort).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }
        let attempts = profile.progress(for: PuzzleSkills.changedRuleSort).evidence.count
        return candidates[attempts % candidates.count]
    }

    public static func changedRuleResortIndependentSuccessCount(
        profile: LearnerProfile
    ) -> Int {
        let ids = Set(PuzzlePalaceEncounterCatalog.changedRuleResort.map(\.id))
        return Set(
            profile.progress(for: PuzzleSkills.changedRuleSort).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func changedRuleResortComplete(profile: LearnerProfile) -> Bool {
        changedRuleResortIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.changedRuleResort.count
    }

    public static func independentSortSuccessCount(
        for encounters: [PuzzleSortEncounter],
        skill: SkillID,
        profile: LearnerProfile
    ) -> Int {
        let ids = Set(encounters.map(\.id))
        return Set(
            profile.progress(for: skill).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    private static func nextSortCandidate(
        from candidates: [PuzzleSortEncounter],
        skill: SkillID,
        profile: LearnerProfile
    ) -> PuzzleSortEncounter {
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

