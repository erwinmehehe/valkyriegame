import Foundation

// MARK: - Puzzle Palace v2 curriculum foundation

/// Developmental executive-function and reasoning graph for Puzzle Palace.
///
/// This is a product skill graph, not a claim of formal standards alignment.
/// Skills are intentionally separated so evidence from a pattern task cannot
/// masquerade as working-memory, inhibition, rotation, planning, or debugging mastery.
public enum PuzzleStrand: String, Codable, CaseIterable, Hashable, Sendable {
    case workingMemory
    case inhibitoryControl
    case cognitiveFlexibility
    case patterns
    case spatialReasoning
    case sorting
    case planning
    case sequencing
    case debugging
}

public enum PuzzleRepresentation: String, Codable, CaseIterable, Sendable {
    case rune
    case object
    case path
    case rotation
    case command
}

public enum PuzzleResponseMode: String, Codable, CaseIterable, Sendable {
    case directTouch
    case arrange
    case holdAndRelease
    case route
    case switchRule
    case debug
}

public enum PuzzlePalaceMechanicID {
    public static let runeGate = "puzzlePalace.runeGate"
    public static let memoryBridge = "puzzlePalace.memoryBridge"
    public static let stopGoOrbs = "puzzlePalace.stopGoOrbs"
    public static let sortingPedestal = "puzzlePalace.sortingPedestal"
    public static let changedRuleResort = "puzzlePalace.changedRuleResort"
    public static let mirrorHall = "puzzlePalace.mirrorHall"
    public static let pathTiles = "puzzlePalace.pathTiles"
    public static let commandGears = "puzzlePalace.commandGears"
    public static let bugLantern = "puzzlePalace.bugLantern"
    public static let tikoReach = "puzzlePalace.tikoReach"
}

public struct PuzzleSkillDescriptor: Sendable {
    public let definition: SkillDefinition
    public let strand: PuzzleStrand
    public let title: String
    public let developmentalOrder: Int
    public let representations: [PuzzleRepresentation]
    public let responseModes: [PuzzleResponseMode]
    public let mechanicIDs: [String]
    public let isStretch: Bool

    public var id: SkillID { definition.id }

    public init(
        id: SkillID,
        strand: PuzzleStrand,
        title: String,
        developmentalOrder: Int,
        prerequisites: [SkillID] = [],
        requiredReadiness: SkillState = .developing,
        representations: [PuzzleRepresentation],
        responseModes: [PuzzleResponseMode],
        mechanicIDs: [String],
        isStretch: Bool = false
    ) {
        definition = SkillDefinition(
            id,
            prerequisites: prerequisites,
            requiredReadiness: requiredReadiness
        )
        self.strand = strand
        self.title = title
        self.developmentalOrder = developmentalOrder
        self.representations = representations
        self.responseModes = responseModes
        self.mechanicIDs = mechanicIDs
        self.isStretch = isStretch
    }
}

public enum PuzzleSkills {
    public static let visualSequenceMemory = SkillID(rawValue: "puzzle.workingMemory.visualSequence")
    public static let responseInhibition = SkillID(rawValue: "puzzle.inhibition.stopAndGo")
    public static let visualPatternContinue = SkillID(rawValue: "puzzle.patterns.continueAB")
    public static let patternRuleTransfer = SkillID(rawValue: "puzzle.patterns.transferRule")
    public static let singleRuleSort = SkillID(rawValue: "puzzle.sorting.singleRule")
    public static let ruleSwitching = SkillID(rawValue: "puzzle.flexibility.switchRule")
    public static let changedRuleSort = SkillID(rawValue: "puzzle.sorting.changedRule")
    public static let spatialOrientation = SkillID(rawValue: "puzzle.spatial.orientation")
    public static let mentalRotation = SkillID(rawValue: "puzzle.spatial.mentalRotation")
    public static let pathPlanning = SkillID(rawValue: "puzzle.planning.path")
    public static let actionSequencing = SkillID(rawValue: "puzzle.sequencing.actions")
    public static let debugSingleStep = SkillID(rawValue: "puzzle.debugging.singleStep")
    public static let debugSequence = SkillID(rawValue: "puzzle.debugging.sequence")
}

public enum PuzzleSkillCatalog {
    public static let descriptors: [PuzzleSkillDescriptor] = [
        .init(
            id: PuzzleSkills.visualSequenceMemory,
            strand: .workingMemory,
            title: "Remember a Short Visual Sequence",
            developmentalOrder: 1,
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.memoryBridge]
        ),
        .init(
            id: PuzzleSkills.responseInhibition,
            strand: .inhibitoryControl,
            title: "Wait for the Correct Go Signal",
            developmentalOrder: 2,
            representations: [.object],
            responseModes: [.holdAndRelease, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.stopGoOrbs]
        ),
        .init(
            id: PuzzleSkills.visualPatternContinue,
            strand: .patterns,
            title: "Continue an Alternating Visual Pattern",
            developmentalOrder: 3,
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.runeGate]
        ),
        .init(
            id: PuzzleSkills.singleRuleSort,
            strand: .sorting,
            title: "Sort Objects by One Visible Rule",
            developmentalOrder: 4,
            representations: [.object],
            responseModes: [.arrange, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.sortingPedestal]
        ),
        .init(
            id: PuzzleSkills.patternRuleTransfer,
            strand: .patterns,
            title: "Apply a Pattern Rule to New Symbols",
            developmentalOrder: 5,
            prerequisites: [PuzzleSkills.visualPatternContinue],
            representations: [.rune, .object],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.runeGate]
        ),
        .init(
            id: PuzzleSkills.ruleSwitching,
            strand: .cognitiveFlexibility,
            title: "Switch to a New Rule When the World Changes",
            developmentalOrder: 6,
            prerequisites: [PuzzleSkills.responseInhibition, PuzzleSkills.singleRuleSort],
            representations: [.object],
            responseModes: [.switchRule, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.sortingPedestal]
        ),
        .init(
            id: PuzzleSkills.changedRuleSort,
            strand: .sorting,
            title: "Re-sort the Same Objects Using a Different Rule",
            developmentalOrder: 7,
            prerequisites: [PuzzleSkills.singleRuleSort, PuzzleSkills.ruleSwitching],
            representations: [.object],
            responseModes: [.switchRule, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.changedRuleResort]
        ),
        .init(
            id: PuzzleSkills.spatialOrientation,
            strand: .spatialReasoning,
            title: "Track Direction and Position",
            developmentalOrder: 8,
            representations: [.path, .rotation],
            responseModes: [.route, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.mirrorHall, PuzzlePalaceMechanicID.pathTiles]
        ),
        .init(
            id: PuzzleSkills.mentalRotation,
            strand: .spatialReasoning,
            title: "Recognize a Shape After Rotation",
            developmentalOrder: 9,
            prerequisites: [PuzzleSkills.spatialOrientation],
            representations: [.rotation],
            responseModes: [.directTouch, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.mirrorHall],
            isStretch: true
        ),
        .init(
            id: PuzzleSkills.actionSequencing,
            strand: .sequencing,
            title: "Put Actions in a Useful Order",
            developmentalOrder: 10,
            prerequisites: [PuzzleSkills.visualSequenceMemory],
            representations: [.command, .path],
            responseModes: [.arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.commandGears]
        ),
        .init(
            id: PuzzleSkills.pathPlanning,
            strand: .planning,
            title: "Plan a Route Before Moving",
            developmentalOrder: 11,
            prerequisites: [PuzzleSkills.spatialOrientation, PuzzleSkills.visualSequenceMemory],
            representations: [.path, .command],
            responseModes: [.route, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.pathTiles, PuzzlePalaceMechanicID.commandGears]
        ),
        .init(
            id: PuzzleSkills.debugSingleStep,
            strand: .debugging,
            title: "Find One Broken Step in a Plan",
            developmentalOrder: 12,
            prerequisites: [PuzzleSkills.actionSequencing],
            representations: [.command, .path],
            responseModes: [.debug, .directTouch],
            mechanicIDs: [PuzzlePalaceMechanicID.bugLantern]
        ),
        .init(
            id: PuzzleSkills.debugSequence,
            strand: .debugging,
            title: "Repair a Multi-Step Plan",
            developmentalOrder: 13,
            prerequisites: [PuzzleSkills.debugSingleStep, PuzzleSkills.pathPlanning],
            representations: [.command, .path],
            responseModes: [.debug, .arrange],
            mechanicIDs: [PuzzlePalaceMechanicID.bugLantern, PuzzlePalaceMechanicID.commandGears],
            isStretch: true
        )
    ]

    public static let stretchSkills: [PuzzleSkillDescriptor] = descriptors.filter(\.isStretch)

    public static func descriptor(for id: SkillID) -> PuzzleSkillDescriptor? {
        descriptors.first { $0.id == id }
    }

    public static func graph() throws -> SkillGraph {
        try SkillGraph(descriptors.map(\.definition))
    }
}

