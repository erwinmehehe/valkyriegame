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


public enum PuzzleOrientation: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case north
    case east
    case south
    case west

    public var glyph: String {
        switch self {
        case .north: return "↑"
        case .east: return "→"
        case .south: return "↓"
        case .west: return "←"
        }
    }
}

public struct PuzzleOrientationEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let target: PuzzleOrientation
    public let choices: [PuzzleOrientation]
    public let context: String
    public let transferContext: Bool

    public init(
        id: String,
        skillID: SkillID = PuzzleSkills.spatialOrientation,
        mechanicID: String = PuzzlePalaceMechanicID.mirrorHall,
        representation: Representation = .pictorial,
        prompt: String,
        target: PuzzleOrientation,
        choices: [PuzzleOrientation],
        context: String = "mirrorHall",
        transferContext: Bool = false
    ) {
        precondition(!choices.isEmpty)
        precondition(Set(choices).count == choices.count)
        precondition(choices.contains(target))
        self.id = id
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.target = target
        self.choices = choices
        self.context = context
        self.transferContext = transferContext
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            representation.rawValue,
            target.rawValue,
            choices.map(\.rawValue).joined(separator: ","),
            context
        ].joined(separator: "|")
    }
}


/// Integer tiles keep the reasoning task independent of SpriteKit geometry.
public struct PuzzleTile: Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int
    public init(x: Int, y: Int) { self.x = x; self.y = y }
}

public struct PuzzleTileShape: Equatable, Sendable {
    public let cells: [PuzzleTile]

    public init(cells: [PuzzleTile]) {
        precondition(!cells.isEmpty && Set(cells).count == cells.count)
        let minX = cells.map(\.x).min()!
        let minY = cells.map(\.y).min()!
        self.cells = cells.map { PuzzleTile(x: $0.x - minX, y: $0.y - minY) }
            .sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
    }

    public func rotated(quarterTurns: Int) -> PuzzleTileShape {
        var result = self
        for _ in 0..<((quarterTurns % 4 + 4) % 4) {
            result = PuzzleTileShape(cells: result.cells.map { PuzzleTile(x: $0.y, y: -$0.x) })
        }
        return result
    }

    public func reflected() -> PuzzleTileShape {
        PuzzleTileShape(cells: cells.map { PuzzleTile(x: -$0.x, y: $0.y) })
    }

    public var signature: String { cells.map { "\($0.x),\($0.y)" }.joined(separator: ";") }
}

public struct PuzzleRotationEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let source: PuzzleTileShape
    public let quarterTurns: Int
    public let choices: [PuzzleTileShape]
    public let transferContext: Bool
    public let skillID = PuzzleSkills.mentalRotation
    public let mechanicID = PuzzlePalaceMechanicID.mirrorHall
    public let representation = Representation.pictorial
    public var answer: PuzzleTileShape { source.rotated(quarterTurns: quarterTurns) }
    public var prompt: String { "Turn Tiko's shape clockwise in your mind. Touch the shape it becomes." }
    public var turnCue: String {
        switch quarterTurns {
        case 1: return "↻ ¼ TURN"
        case 2: return "↻ ½ TURN"
        default: return "↻ ¾ TURN"
        }
    }
    public var fingerprint: String {
        [mechanicID, skillID.rawValue, source.signature, String(quarterTurns),
         choices.map(\.signature).joined(separator: "|"), "mirrorRotation"].joined(separator: "|")
    }

    public init(id: String, source: PuzzleTileShape, quarterTurns: Int, answerIndex: Int,
                transferContext: Bool = false) {
        precondition((1...3).contains(quarterTurns) && (0...2).contains(answerIndex))
        let target = source.rotated(quarterTurns: quarterTurns)
        let reflection = target.reflected()
        precondition(target != source && target != reflection && source != reflection)
        var options = [source, reflection]
        options.insert(target, at: answerIndex)
        self.id = id
        self.source = source
        self.quarterTurns = quarterTurns
        self.choices = options
        self.transferContext = transferContext
    }
}


public struct PuzzlePathEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let prompt: String
    public let gridWidth: Int
    public let gridHeight: Int
    public let start: PuzzleTile
    public let goal: PuzzleTile
    public let blocked: Set<PuzzleTile>
    public let choices: [[PuzzleOrientation]]
    public let answerIndex: Int
    public let transferContext: Bool
    public let skillID = PuzzleSkills.pathPlanning
    public let mechanicID = PuzzlePalaceMechanicID.pathTiles
    public let representation = Representation.pictorial

    public init(
        id: String,
        prompt: String,
        gridWidth: Int,
        gridHeight: Int,
        start: PuzzleTile,
        goal: PuzzleTile,
        blocked: [PuzzleTile],
        choices: [[PuzzleOrientation]],
        answerIndex: Int,
        transferContext: Bool = false
    ) {
        precondition(gridWidth > 1 && gridHeight > 1)
        precondition(!choices.isEmpty && choices.indices.contains(answerIndex))
        self.id = id
        self.prompt = prompt
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        self.start = start
        self.goal = goal
        self.blocked = Set(blocked)
        self.choices = choices
        self.answerIndex = answerIndex
        self.transferContext = transferContext

        precondition(isInBounds(start) && isInBounds(goal))
        precondition(!self.blocked.contains(start) && !self.blocked.contains(goal))
        let signatures = choices.map { $0.map(\.rawValue).joined(separator: ",") }
        precondition(Set(signatures).count == choices.count)
        let validChoices = choices.indices.filter { isValidChoice($0) }
        precondition(validChoices == [answerIndex])
    }

    public func route(for choiceIndex: Int) -> [PuzzleTile] {
        precondition(choices.indices.contains(choiceIndex))
        var current = start
        var result = [current]
        for direction in choices[choiceIndex] {
            switch direction {
            case .north: current = PuzzleTile(x: current.x, y: current.y + 1)
            case .east: current = PuzzleTile(x: current.x + 1, y: current.y)
            case .south: current = PuzzleTile(x: current.x, y: current.y - 1)
            case .west: current = PuzzleTile(x: current.x - 1, y: current.y)
            }
            result.append(current)
        }
        return result
    }

    public func isValidChoice(_ choiceIndex: Int) -> Bool {
        guard choices.indices.contains(choiceIndex) else { return false }
        let route = route(for: choiceIndex)
        guard route.last == goal, Set(route).count == route.count else { return false }
        return route.allSatisfy { isInBounds($0) && !blocked.contains($0) }
    }

    public func isInBounds(_ tile: PuzzleTile) -> Bool {
        tile.x >= 0 && tile.x < gridWidth && tile.y >= 0 && tile.y < gridHeight
    }

    public var fingerprint: String {
        let blockedSignature = blocked
            .sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
            .map { String($0.x) + "," + String($0.y) }
            .joined(separator: ";")
        let choiceSignature = choices
            .map { $0.map(\.rawValue).joined(separator: ",") }
            .joined(separator: "|")
        return [
            mechanicID,
            skillID.rawValue,
            String(gridWidth) + "x" + String(gridHeight),
            String(start.x) + "," + String(start.y),
            String(goal.x) + "," + String(goal.y),
            blockedSignature,
            choiceSignature
        ].joined(separator: "|")
    }
}


public struct PuzzleCommandStep: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let glyph: String
    public let title: String

    public init(id: String, glyph: String, title: String) {
        precondition(!id.isEmpty && !glyph.isEmpty && !title.isEmpty)
        self.id = id
        self.glyph = glyph
        self.title = title
    }
}

public struct PuzzleSequenceEncounter: Identifiable, Equatable, Sendable {
    public let id: String
    public let prompt: String
    public let correctOrder: [PuzzleCommandStep]
    public let presented: [PuzzleCommandStep]
    public let transferContext: Bool
    public let skillID = PuzzleSkills.actionSequencing
    public let mechanicID = PuzzlePalaceMechanicID.commandGears
    public let representation = Representation.pictorial

    public init(
        id: String,
        prompt: String,
        correctOrder: [PuzzleCommandStep],
        presented: [PuzzleCommandStep],
        transferContext: Bool = false
    ) {
        precondition(correctOrder.count == 3 && presented.count == 3)
        precondition(Set(correctOrder.map(\.id)).count == 3)
        precondition(Set(presented.map(\.id)) == Set(correctOrder.map(\.id)))
        precondition(presented != correctOrder)
        self.id = id
        self.prompt = prompt
        self.correctOrder = correctOrder
        self.presented = presented
        self.transferContext = transferContext
    }

    public func isCorrect(_ steps: [PuzzleCommandStep]) -> Bool {
        steps.map(\.id) == correctOrder.map(\.id)
    }

    public var fingerprint: String {
        [
            mechanicID,
            skillID.rawValue,
            correctOrder.map(\.id).joined(separator: ","),
            presented.map(\.id).joined(separator: ",")
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


    public static let mirrorHallRotation: [PuzzleRotationEncounter] = [
        .init(id: "puzzle.mirrorRotation.elbow", source: PuzzleTileShape(cells: [
            .init(x: 0, y: 0), .init(x: 0, y: 1), .init(x: 0, y: 2), .init(x: 1, y: 0)
        ]), quarterTurns: 1, answerIndex: 2),
        .init(id: "puzzle.mirrorRotation.flag", source: PuzzleTileShape(cells: [
            .init(x: 0, y: 0), .init(x: 0, y: 1), .init(x: 0, y: 2),
            .init(x: 1, y: 0), .init(x: 1, y: 1)
        ]), quarterTurns: 2, answerIndex: 0, transferContext: true),
        .init(id: "puzzle.mirrorRotation.branch", source: PuzzleTileShape(cells: [
            .init(x: 0, y: 1), .init(x: 1, y: 0), .init(x: 1, y: 1),
            .init(x: 1, y: 2), .init(x: 2, y: 2)
        ]), quarterTurns: 3, answerIndex: 1, transferContext: true)
    ]

    /// Alternate turns prevent an immediate assisted retry from copying the same answer.
    public static let mirrorHallRotationVariants: [[PuzzleRotationEncounter]] = mirrorHallRotation.map { base in
        let answerIndex = base.choices.firstIndex(of: base.answer)!
        return [base] + (1...2).map { offset in
            PuzzleRotationEncounter(id: base.id + ".variant\(offset)", source: base.source,
                quarterTurns: (base.quarterTurns - 1 + offset) % 3 + 1,
                answerIndex: (answerIndex + offset) % 3, transferContext: true)
        }
    }

    public static let mirrorHallOrientation: [PuzzleOrientationEncounter] = [
        .init(
            id: "puzzle.mirrorHall.north",
            prompt: "Tiko lights one compass beam. Touch the mirror arrow pointing the same way.",
            target: .north,
            choices: [.east, .north, .west]
        ),
        .init(
            id: "puzzle.mirrorHall.west",
            prompt: "The hall turns. Track Tiko's new direction and choose the matching mirror.",
            target: .west,
            choices: [.south, .east, .west],
            transferContext: true
        ),
        .init(
            id: "puzzle.mirrorHall.south",
            representation: .reasoning,
            prompt: "One final mirror shifts the viewpoint. Keep the direction stable and match it.",
            target: .south,
            choices: [.north, .south, .east],
            transferContext: true
        )
    ]


    public static let pathTileFamilies: [[PuzzlePathEncounter]] = [
        [
            .init(
                id: "puzzle.pathTiles.archwayA",
                prompt: "Plan the whole route before Tiko moves. Which path reaches the star without touching a dark tile?",
                gridWidth: 4,
                gridHeight: 3,
                start: .init(x: 0, y: 0),
                goal: .init(x: 3, y: 2),
                blocked: [.init(x: 1, y: 0), .init(x: 2, y: 1)],
                choices: [
                    [.east, .north, .north, .east, .east],
                    [.north, .east, .north, .east, .east],
                    [.north, .east, .east, .north, .east]
                ],
                answerIndex: 1
            ),
            .init(
                id: "puzzle.pathTiles.archwayB",
                prompt: "The floor shifted. Pick a complete safe route before anyone steps onto the tiles.",
                gridWidth: 4,
                gridHeight: 3,
                start: .init(x: 0, y: 0),
                goal: .init(x: 3, y: 2),
                blocked: [.init(x: 0, y: 1), .init(x: 2, y: 0)],
                choices: [
                    [.east, .north, .east, .north, .east],
                    [.north, .east, .north, .east, .east],
                    [.east, .east, .north, .north, .east]
                ],
                answerIndex: 0,
                transferContext: true
            )
        ],
        [
            .init(
                id: "puzzle.pathTiles.galleryA",
                prompt: "Look ahead across the gallery. Choose the route that stays clear all the way to the star.",
                gridWidth: 4,
                gridHeight: 4,
                start: .init(x: 0, y: 0),
                goal: .init(x: 3, y: 3),
                blocked: [.init(x: 0, y: 1), .init(x: 2, y: 2)],
                choices: [
                    [.north, .east, .north, .north, .east, .east],
                    [.east, .north, .east, .north, .north, .east],
                    [.east, .north, .north, .north, .east, .east]
                ],
                answerIndex: 2,
                transferContext: true
            ),
            .init(
                id: "puzzle.pathTiles.galleryB",
                prompt: "Tiko found another floor plan. Decide on the safe route before testing it.",
                gridWidth: 4,
                gridHeight: 4,
                start: .init(x: 0, y: 0),
                goal: .init(x: 3, y: 3),
                blocked: [.init(x: 1, y: 1), .init(x: 3, y: 1)],
                choices: [
                    [.north, .north, .east, .north, .east, .east],
                    [.east, .north, .north, .east, .north, .east],
                    [.north, .east, .east, .east, .north, .north]
                ],
                answerIndex: 0,
                transferContext: true
            )
        ],
        [
            .init(
                id: "puzzle.pathTiles.returnA",
                prompt: "Now plan from the far side. Which full route gets Tiko home without crossing a blocked tile?",
                gridWidth: 4,
                gridHeight: 3,
                start: .init(x: 3, y: 0),
                goal: .init(x: 0, y: 2),
                blocked: [.init(x: 2, y: 0), .init(x: 1, y: 1)],
                choices: [
                    [.west, .north, .north, .west, .west],
                    [.north, .north, .west, .west, .west],
                    [.north, .west, .west, .north, .west]
                ],
                answerIndex: 1,
                transferContext: true
            ),
            .init(
                id: "puzzle.pathTiles.returnB",
                prompt: "One last shifted path: choose a complete route first, then let Tiko scout it.",
                gridWidth: 4,
                gridHeight: 3,
                start: .init(x: 3, y: 0),
                goal: .init(x: 0, y: 2),
                blocked: [.init(x: 3, y: 1), .init(x: 1, y: 0)],
                choices: [
                    [.north, .west, .north, .west, .west],
                    [.west, .west, .north, .north, .west],
                    [.west, .north, .north, .west, .west]
                ],
                answerIndex: 2,
                transferContext: true
            )
        ]
    ]


    public static let commandGearFamilies: [[PuzzleSequenceEncounter]] = {
        let takeKey = PuzzleCommandStep(id: "takeKey", glyph: "◆", title: "TAKE KEY")
        let unlock = PuzzleCommandStep(id: "unlock", glyph: "◇", title: "UNLOCK")
        let crossDoor = PuzzleCommandStep(id: "crossDoor", glyph: "→", title: "GO THROUGH")

        let placeCrystal = PuzzleCommandStep(id: "placeCrystal", glyph: "✦", title: "PLACE CRYSTAL")
        let turnGear = PuzzleCommandStep(id: "turnGear", glyph: "↻", title: "TURN GEAR")
        let openDoor = PuzzleCommandStep(id: "openDoor", glyph: "▱", title: "OPEN DOOR")

        let lowerBridge = PuzzleCommandStep(id: "lowerBridge", glyph: "↓", title: "LOWER BRIDGE")
        let crossBridge = PuzzleCommandStep(id: "crossBridge", glyph: "→", title: "CROSS")
        let raiseBridge = PuzzleCommandStep(id: "raiseBridge", glyph: "↑", title: "RAISE BRIDGE")

        return [
            [
                .init(
                    id: "puzzle.commandGears.keyGateA",
                    prompt: "Tiko needs to get through the locked gate. Put the three command gears in a useful order.",
                    correctOrder: [takeKey, unlock, crossDoor],
                    presented: [crossDoor, takeKey, unlock]
                ),
                .init(
                    id: "puzzle.commandGears.keyGateB",
                    prompt: "The gate reset. Build the command chain Tiko needs before he can go through.",
                    correctOrder: [takeKey, unlock, crossDoor],
                    presented: [unlock, crossDoor, takeKey],
                    transferContext: true
                )
            ],
            [
                .init(
                    id: "puzzle.commandGears.crystalDoorA",
                    prompt: "Power the palace door. Which action should happen first, next, and last?",
                    correctOrder: [placeCrystal, turnGear, openDoor],
                    presented: [openDoor, placeCrystal, turnGear],
                    transferContext: true
                ),
                .init(
                    id: "puzzle.commandGears.crystalDoorB",
                    prompt: "This door uses the same machine in a new arrangement. Build the useful action order.",
                    correctOrder: [placeCrystal, turnGear, openDoor],
                    presented: [turnGear, openDoor, placeCrystal],
                    transferContext: true
                )
            ],
            [
                .init(
                    id: "puzzle.commandGears.bridgeA",
                    prompt: "Tiko must cross and leave the bridge safe behind him. Arrange the commands.",
                    correctOrder: [lowerBridge, crossBridge, raiseBridge],
                    presented: [crossBridge, raiseBridge, lowerBridge],
                    transferContext: true
                ),
                .init(
                    id: "puzzle.commandGears.bridgeB",
                    prompt: "The bridge gears shuffled. Put the actions back into a useful order.",
                    correctOrder: [lowerBridge, crossBridge, raiseBridge],
                    presented: [raiseBridge, lowerBridge, crossBridge],
                    transferContext: true
                )
            ]
        ]
    }()

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


    public static func canEnterMirrorHall(profile: LearnerProfile) -> Bool {
        changedRuleResortComplete(profile: profile)
    }

    public static func nextMirrorHallEncounter(profile: LearnerProfile) -> PuzzleOrientationEncounter? {
        guard canEnterMirrorHall(profile: profile) else { return nil }
        let candidates = PuzzlePalaceEncounterCatalog.mirrorHallOrientation
        let independent = Set(
            profile.progress(for: PuzzleSkills.spatialOrientation).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        if let unfinished = candidates.first(where: { !independent.contains($0.id) }) {
            return unfinished
        }
        let attempts = profile.progress(for: PuzzleSkills.spatialOrientation).evidence.count
        return candidates[attempts % candidates.count]
    }

    public static func mirrorHallIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let ids = Set(PuzzlePalaceEncounterCatalog.mirrorHallOrientation.map(\.id))
        return Set(
            profile.progress(for: PuzzleSkills.spatialOrientation).evidence
                .filter {
                    $0.outcome == .correct
                        && $0.supportLevel == .independent
                        && ids.contains($0.encounterID)
                }
                .map(\.encounterID)
        ).count
    }

    public static func mirrorHallComplete(profile: LearnerProfile) -> Bool {
        mirrorHallIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.mirrorHallOrientation.count
    }

    public static func nextMirrorRotationEncounter(profile: LearnerProfile) -> PuzzleRotationEncounter? {
        guard canEnterMirrorHall(profile: profile), mirrorHallComplete(profile: profile),
              !mirrorRotationComplete(profile: profile) else { return nil }
        let evidence = profile.progress(for: PuzzleSkills.mentalRotation).evidence
        let independent = Set(evidence.filter { $0.outcome == .correct && $0.supportLevel == .independent }
            .map(\.encounterID))
        let seen = Set(evidence.map(\.encounterID))
        for variants in PuzzlePalaceEncounterCatalog.mirrorHallRotationVariants {
            guard !variants.contains(where: { independent.contains($0.id) }) else { continue }
            if let fresh = variants.first(where: { !seen.contains($0.id) }) { return fresh }
            // Exhausted variants revisit a different turn, never the just-demonstrated answer.
            return variants.first { $0.id != evidence.last?.encounterID }
        }
        return nil
    }

    public static func mirrorRotationIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let independent = Set(profile.progress(for: PuzzleSkills.mentalRotation).evidence
            .filter { $0.outcome == .correct && $0.supportLevel == .independent }.map(\.encounterID))
        return PuzzlePalaceEncounterCatalog.mirrorHallRotationVariants.filter { variants in
            variants.contains { independent.contains($0.id) }
        }.count
    }

    public static func mirrorRotationComplete(profile: LearnerProfile) -> Bool {
        mirrorRotationIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.mirrorHallRotation.count
    }


    public static func canEnterPathTiles(profile: LearnerProfile) -> Bool {
        memoryBridgeComplete(profile: profile)
            && canEnterMirrorHall(profile: profile)
            && mirrorHallComplete(profile: profile)
            && mirrorRotationComplete(profile: profile)
    }

    public static func nextPathTilesEncounter(profile: LearnerProfile) -> PuzzlePathEncounter? {
        guard canEnterPathTiles(profile: profile), !pathTilesComplete(profile: profile) else { return nil }
        let evidence = profile.progress(for: PuzzleSkills.pathPlanning).evidence
        let independent = Set(
            evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        let seen = Set(evidence.map(\.encounterID))

        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            guard !family.contains(where: { independent.contains($0.id) }) else { continue }
            if let fresh = family.first(where: { !seen.contains($0.id) }) {
                return fresh
            }
            return family.first { $0.id != evidence.last?.encounterID } ?? family.first
        }
        return nil
    }

    public static func pathTilesIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let independent = Set(
            profile.progress(for: PuzzleSkills.pathPlanning).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        return PuzzlePalaceEncounterCatalog.pathTileFamilies.filter { family in
            family.contains { independent.contains($0.id) }
        }.count
    }

    public static func pathTilesComplete(profile: LearnerProfile) -> Bool {
        pathTilesIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.pathTileFamilies.count
    }


    public static func canEnterCommandGears(profile: LearnerProfile) -> Bool {
        // Curriculum prerequisite for action sequencing is visual sequence memory.
        // Path Tiles is a neighboring narrative chamber, not a mastery prerequisite.
        memoryBridgeComplete(profile: profile)
    }

    public static func nextCommandGearsEncounter(profile: LearnerProfile) -> PuzzleSequenceEncounter? {
        guard canEnterCommandGears(profile: profile), !commandGearsComplete(profile: profile) else { return nil }
        let evidence = profile.progress(for: PuzzleSkills.actionSequencing).evidence
        let independent = Set(
            evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        let seen = Set(evidence.map(\.encounterID))

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            guard !family.contains(where: { independent.contains($0.id) }) else { continue }
            if let fresh = family.first(where: { !seen.contains($0.id) }) {
                return fresh
            }
            return family.first { $0.id != evidence.last?.encounterID } ?? family.first
        }
        return nil
    }

    public static func commandGearsIndependentSuccessCount(profile: LearnerProfile) -> Int {
        let independent = Set(
            profile.progress(for: PuzzleSkills.actionSequencing).evidence
                .filter { $0.outcome == .correct && $0.supportLevel == .independent }
                .map(\.encounterID)
        )
        return PuzzlePalaceEncounterCatalog.commandGearFamilies.filter { family in
            family.contains { independent.contains($0.id) }
        }.count
    }

    public static func commandGearsComplete(profile: LearnerProfile) -> Bool {
        commandGearsIndependentSuccessCount(profile: profile)
            == PuzzlePalaceEncounterCatalog.commandGearFamilies.count
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

