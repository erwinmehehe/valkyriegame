import Foundation

// Reusable model: rendering and touch input don't own the arithmetic.
// Future operations require their own completion strategy; unsupported ones fail explicitly.
public struct CrystalCartModel: Codable, Equatable, Sendable {
    public enum CartError: Error { case unsupportedOperation, invalidQuantity }
    public let encounter: LearningEncounter
    public private(set) var quantity: Int
    public private(set) var attempts = 0
    public private(set) var support: SupportLevel = .independent
    public private(set) var completed = false
    public let startedAt: Date
    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard [.counting, .addition, .subtraction, .missingAddend].contains(encounter.operation) else {
            throw CartError.unsupportedOperation
        }
        guard (0...12).contains(encounter.initialQuantity),
              (0...12).contains(encounter.targetQuantity) else {
            throw CartError.invalidQuantity
        }
        if encounter.operation == .subtraction {
            guard encounter.initialQuantity > encounter.targetQuantity else {
                throw CartError.invalidQuantity
            }
        } else {
            guard encounter.initialQuantity < encounter.targetQuantity,
                  encounter.targetQuantity > 0 else {
                throw CartError.invalidQuantity
            }
        }
        self.encounter = encounter; quantity = encounter.initialQuantity; startedAt = date
    }
    @discardableResult public mutating func add() -> Bool {
        let maximum = encounter.operation == .subtraction
            ? encounter.initialQuantity
            : 12
        guard !completed, quantity < maximum else { return false }
        quantity += 1
        return true
    }
    @discardableResult public mutating func remove() -> Bool {
        let minimum = encounter.operation == .subtraction
            ? 0
            : encounter.initialQuantity
        guard !completed, quantity > minimum else { return false }
        quantity -= 1
        return true
    }
    public mutating func apply(_ scaffold: Scaffold) { support = maxSupport(support, scaffold.support) }
    private func maxSupport(_ a: SupportLevel, _ b: SupportLevel) -> SupportLevel { a.rawValue >= b.rawValue ? a : b }
    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed else { return nil }
        attempts += 1
        let correct = quantity == encounter.targetQuantity
        completed = correct
        return LearningEvidence(encounterID: encounter.id, skillID: encounter.skillID,
            outcome: correct ? .correct : .incorrect, supportLevel: support,
            representation: encounter.representation, mechanicID: encounter.mechanicID,
            attempts: attempts, responseTime: max(0, date.timeIntervalSince(startedAt)), timestamp: date,
            // A representation label alone does not demonstrate transfer.
            // These fixed-answer manipulatives currently assess their concrete relation only.
            transferContext: false,
            easySuccess: correct && support == .independent && attempts == 1 && date.timeIntervalSince(startedAt) < 25)
    }
}


public struct PlaceValueFactoryModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidQuantities
    }

    public let encounter: LearningEncounter
    public private(set) var selectedTens: Int
    public private(set) var selectedOnes: Int
    public private(set) var selectedComparison: ComparisonChoice?
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public let startedAt: Date

    public var isComparison: Bool { encounter.operation == .comparison }
    public var targetNumber: Int { encounter.targetQuantity }
    public var builtNumber: Int { selectedTens * 10 + selectedOnes }
    public var expectedTens: Int { targetNumber / 10 }
    public var expectedOnes: Int { targetNumber % 10 }
    public var leftNumber: Int { encounter.initialQuantity }
    public var rightNumber: Int { encounter.targetQuantity }

    public var correctChoice: ComparisonChoice {
        let asksForAscendingFirst =
            encounter.skillID == MathSkills.numberOrder20
            || encounter.skillID == MathSkills.orderTwoDigit

        if leftNumber == rightNumber { return .equal }

        if asksForAscendingFirst {
            return leftNumber < rightNumber ? .left : .right
        }

        return leftNumber > rightNumber ? .left : .right
    }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.placeValueFactory else {
            throw ModelError.unsupportedMechanic
        }
        guard [.quantityMatching, .comparison].contains(encounter.operation) else {
            throw ModelError.unsupportedOperation
        }
        guard (0...99).contains(encounter.initialQuantity),
              (1...99).contains(encounter.targetQuantity) else {
            throw ModelError.invalidQuantities
        }

        self.encounter = encounter
        selectedTens = 0
        selectedOnes = 0
        selectedComparison = nil
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    @discardableResult public mutating func addTen() -> Bool {
        guard !isComparison, !completed, selectedTens < 9 else { return false }
        selectedTens += 1
        return true
    }

    @discardableResult public mutating func removeTen() -> Bool {
        guard !isComparison, !completed, selectedTens > 0 else { return false }
        selectedTens -= 1
        return true
    }

    @discardableResult public mutating func addOne() -> Bool {
        guard !isComparison, !completed, selectedOnes < 9 else { return false }
        selectedOnes += 1
        return true
    }

    @discardableResult public mutating func removeOne() -> Bool {
        guard !isComparison, !completed, selectedOnes > 0 else { return false }
        selectedOnes -= 1
        return true
    }

    public mutating func choose(_ choice: ComparisonChoice) {
        guard isComparison, !completed else { return }
        selectedComparison = choice
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed else { return nil }

        if isComparison {
            guard let selectedComparison else { return nil }
            attempts += 1
            let correct = selectedComparison == correctChoice
            completed = correct
            return ManipulativeEvidence.make(
                encounter: encounter,
                outcome: correct ? .correct : .incorrect,
                support: support,
                attempts: attempts,
                startedAt: startedAt,
                at: date
            )
        }

        attempts += 1
        let correct = selectedTens == expectedTens && selectedOnes == expectedOnes
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}



public enum PatternLoomFamily: String, Codable, CaseIterable, Sendable {
    case ab
    case aab
    case abc

    public var unitLength: Int {
        switch self {
        case .ab: return 2
        case .aab, .abc: return 3
        }
    }
}

/// Scores the child's actual pattern extension, interior-gap prediction, or
/// construction of a full repeating pattern. Rendering never decides correctness.
public struct PatternLoomModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidPattern
    }

    public let encounter: LearningEncounter
    public let family: PatternLoomFamily
    public let task: String
    public private(set) var selectedSymbols: [Int]
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public let startedAt: Date

    public var isCreation: Bool { task == "create" }
    public var isMissing: Bool { task == "missing" }
    public var gapIndex: Int { isMissing ? encounter.targetQuantity : encounter.targetQuantity }
    public var slotCount: Int { isCreation ? 6 : (isMissing ? 7 : encounter.targetQuantity + 1) }

    public var repeatingUnit: [Int] {
        let base: [Int]
        switch family {
        case .ab: base = [1, 2]
        case .aab: base = [1, 1, 2]
        case .abc: base = [1, 2, 3]
        }
        let shift = encounter.initialQuantity
        return base.map { (($0 - 1 + shift) % 3) + 1 }
    }

    public var correctSymbol: Int {
        repeatingUnit[gapIndex % repeatingUnit.count]
    }

    /// In create mode the loom starts empty. In extension/missing mode, only the
    /// required one-slot answer is hidden, not the entire model pattern.
    public var visibleSlots: [Int?] {
        if isCreation {
            return (0..<slotCount).map { $0 < selectedSymbols.count ? selectedSymbols[$0] : nil }
        }
        return (0..<slotCount).map { index in
            if index == gapIndex { return selectedSymbols.first }
            return repeatingUnit[index % repeatingUnit.count]
        }
    }

    public var isValidCreation: Bool {
        guard isCreation, selectedSymbols.count == slotCount else { return false }
        let unitLength = family.unitLength
        let unit = Array(selectedSymbols.prefix(unitLength))
        let validUnit: Bool
        switch family {
        case .ab:
            validUnit = unit[0] != unit[1]
        case .aab:
            validUnit = unit[0] == unit[1] && unit[0] != unit[2]
        case .abc:
            validUnit = Set(unit).count == 3
        }
        return validUnit && selectedSymbols.enumerated().allSatisfy {
            $0.element == unit[$0.offset % unitLength]
        }
    }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.patternLoom else {
            throw ModelError.unsupportedMechanic
        }
        guard encounter.operation == .pattern else {
            throw ModelError.unsupportedOperation
        }
        let parts = encounter.context.split(separator: ".").map(String.init)
        guard parts.count == 3, parts[0] == "loom",
              ["extend", "missing", "create"].contains(parts[1]),
              let family = PatternLoomFamily(rawValue: parts[2]),
              (0...2).contains(encounter.initialQuantity),
              (parts[1] == "extend" && (3...7).contains(encounter.targetQuantity)
                || parts[1] == "missing" && (2...5).contains(encounter.targetQuantity)
                || parts[1] == "create" && encounter.targetQuantity == 6)
        else {
            throw ModelError.invalidPattern
        }

        switch encounter.skillID {
        case MathSkills.patternAB:
            guard parts[1] == "extend", family == .ab else { throw ModelError.invalidPattern }
        case MathSkills.patternAAB:
            guard parts[1] == "extend", family == .aab else { throw ModelError.invalidPattern }
        case MathSkills.patternABC:
            guard parts[1] == "extend", family == .abc else { throw ModelError.invalidPattern }
        case MathSkills.patternMissing:
            guard parts[1] == "missing" else { throw ModelError.invalidPattern }
        case MathSkills.patternCreate:
            guard parts[1] == "create" else { throw ModelError.invalidPattern }
        default:
            throw ModelError.invalidPattern
        }

        self.encounter = encounter
        self.family = family
        self.task = parts[1]
        selectedSymbols = []
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    @discardableResult public mutating func chooseSymbol(_ symbol: Int) -> Bool {
        guard !completed, (1...3).contains(symbol) else { return false }
        if isCreation {
            guard selectedSymbols.count < slotCount else { return false }
            selectedSymbols.append(symbol)
        } else {
            if selectedSymbols.first == symbol { return false }
            selectedSymbols = [symbol]
        }
        return true
    }

    @discardableResult public mutating func undo() -> Bool {
        guard !completed, !selectedSymbols.isEmpty else { return false }
        selectedSymbols.removeLast()
        return true
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed, !selectedSymbols.isEmpty else { return nil }
        if isCreation && selectedSymbols.count != slotCount { return nil }
        attempts += 1
        let correct = isCreation ? isValidCreation : selectedSymbols.first == correctSymbol
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}

public enum MathMechanicID {
    public static let crystalCart = "crystalCart"
    public static let balanceScale = "balanceScale"
    public static let numberBondMachine = "numberBondMachine"
    public static let tenFrameGate = "tenFrameGate"
    public static let missingNumberBridge = "missingNumberBridge"
    public static let placeValueFactory = "placeValueFactory"
    public static let patternLoom = "patternLoom"

    public static let adaptiveSet: Set<String> = [
        crystalCart,
        balanceScale,
        numberBondMachine,
        tenFrameGate,
        missingNumberBridge,
        placeValueFactory,
        patternLoom
    ]
}

public enum ComparisonChoice: String, Codable, CaseIterable, Sendable {
    case left
    case equal
    case right
}

private enum ManipulativeEvidence {
    static func make(
        encounter: LearningEncounter,
        outcome: Outcome,
        support: SupportLevel,
        attempts: Int,
        startedAt: Date,
        at date: Date
    ) -> LearningEvidence {
        LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            attempts: attempts,
            responseTime: max(0, date.timeIntervalSince(startedAt)),
            timestamp: date,
            transferContext: encounter.representation == .story || encounter.representation == .reasoning,
            easySuccess: outcome == .correct
                && support == .independent
                && attempts == 1
                && date.timeIntervalSince(startedAt) < 25
        )
    }

    static func stronger(_ current: SupportLevel, _ incoming: SupportLevel) -> SupportLevel {
        current.rawValue >= incoming.rawValue ? current : incoming
    }
}

public struct NumberBondMachineModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidQuantities
    }

    public let encounter: LearningEncounter
    public let knownPart: Int
    public private(set) var selectedPart: Int
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public let startedAt: Date

    public var whole: Int { encounter.targetQuantity }
    public var correctMissingPart: Int { whole - knownPart }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.numberBondMachine else {
            throw ModelError.unsupportedMechanic
        }
        guard [.numberBond, .missingAddend].contains(encounter.operation) else {
            throw ModelError.unsupportedOperation
        }
        guard encounter.targetQuantity > 0,
              encounter.targetQuantity <= 20,
              encounter.initialQuantity >= 0,
              encounter.initialQuantity < encounter.targetQuantity else {
            throw ModelError.invalidQuantities
        }

        self.encounter = encounter
        knownPart = encounter.initialQuantity
        selectedPart = 0
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    @discardableResult public mutating func addPart() -> Bool {
        guard !completed, selectedPart < whole else { return false }
        selectedPart += 1
        return true
    }

    @discardableResult public mutating func removePart() -> Bool {
        guard !completed, selectedPart > 0 else { return false }
        selectedPart -= 1
        return true
    }

    public mutating func setPart(_ value: Int) {
        guard !completed else { return }
        selectedPart = min(whole, max(0, value))
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed else { return nil }
        attempts += 1
        let correct = selectedPart == correctMissingPart
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}

public struct TenFrameModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidQuantities
    }

    public let encounter: LearningEncounter
    public private(set) var filled: Int
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public private(set) var startedAt: Date

    /// Quick-look probes hide the reference before accepting construction.
    public var previewDuration: TimeInterval { encounter.context == "quickLook" ? 1.25 : 0 }
    public func previewIsVisible(at date: Date = Date()) -> Bool {
        date.timeIntervalSince(startedAt) < previewDuration
    }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.tenFrameGate else {
            throw ModelError.unsupportedMechanic
        }
        guard [.counting, .quantityMatching, .addition, .missingAddend].contains(encounter.operation) else {
            throw ModelError.unsupportedOperation
        }
        guard (0...10).contains(encounter.initialQuantity),
              (1...10).contains(encounter.targetQuantity),
              encounter.initialQuantity <= encounter.targetQuantity else {
            throw ModelError.invalidQuantities
        }

        self.encounter = encounter
        filled = encounter.initialQuantity
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    @discardableResult public mutating func addCounter(at date: Date = Date()) -> Bool {
        guard !previewIsVisible(at: date), !completed, filled < 10 else { return false }
        filled += 1
        return true
    }

    @discardableResult public mutating func removeCounter(at date: Date = Date()) -> Bool {
        guard !previewIsVisible(at: date), !completed, filled > encounter.initialQuantity else { return false }
        filled -= 1
        return true
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func replayPreview(at date: Date) {
        guard !completed, previewDuration > 0 else { return }
        support = ManipulativeEvidence.stronger(support, .lightHint)
        startedAt = date
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !previewIsVisible(at: date), !completed else { return nil }
        attempts += 1
        let correct = filled == encounter.targetQuantity
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}

public struct BalanceScaleModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidQuantities
    }

    public let encounter: LearningEncounter
    public private(set) var selected: ComparisonChoice?
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public let startedAt: Date

    public var leftQuantity: Int { encounter.initialQuantity }
    public var rightQuantity: Int { encounter.targetQuantity }

    public var correctChoice: ComparisonChoice {
        if leftQuantity < rightQuantity { return .right }
        if leftQuantity > rightQuantity { return .left }
        return .equal
    }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.balanceScale else {
            throw ModelError.unsupportedMechanic
        }
        guard encounter.operation == .comparison else {
            throw ModelError.unsupportedOperation
        }
        guard (0...20).contains(encounter.initialQuantity),
              (0...20).contains(encounter.targetQuantity) else {
            throw ModelError.invalidQuantities
        }

        self.encounter = encounter
        selected = nil
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    public mutating func choose(_ choice: ComparisonChoice) {
        guard !completed else { return }
        selected = choice
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed, let selected else { return nil }
        attempts += 1
        let correct = selected == correctChoice
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}

public struct MissingNumberBridgeModel: Codable, Equatable, Sendable {
    public enum ModelError: Error {
        case unsupportedMechanic
        case unsupportedOperation
        case invalidQuantities
    }

    public let encounter: LearningEncounter
    public private(set) var selectedNumber: Int
    public private(set) var attempts: Int
    public private(set) var support: SupportLevel
    public private(set) var completed: Bool
    public let startedAt: Date

    public var correctNumber: Int { encounter.targetQuantity - encounter.initialQuantity }

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard encounter.mechanicID == MathMechanicID.missingNumberBridge else {
            throw ModelError.unsupportedMechanic
        }
        guard encounter.operation == .missingAddend else {
            throw ModelError.unsupportedOperation
        }
        guard encounter.targetQuantity > 0,
              encounter.targetQuantity <= 20,
              encounter.initialQuantity >= 0,
              encounter.initialQuantity < encounter.targetQuantity else {
            throw ModelError.invalidQuantities
        }

        self.encounter = encounter
        selectedNumber = 0
        attempts = 0
        support = .independent
        completed = false
        startedAt = date
    }

    @discardableResult public mutating func increment() -> Bool {
        guard !completed, selectedNumber < 20 else { return false }
        selectedNumber += 1
        return true
    }

    @discardableResult public mutating func decrement() -> Bool {
        guard !completed, selectedNumber > 0 else { return false }
        selectedNumber -= 1
        return true
    }

    public mutating func setNumber(_ value: Int) {
        guard !completed else { return }
        selectedNumber = min(20, max(0, value))
    }

    public mutating func apply(_ scaffold: Scaffold) {
        support = ManipulativeEvidence.stronger(support, scaffold.support)
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        guard !completed else { return nil }
        attempts += 1
        let correct = selectedNumber == correctNumber
        completed = correct
        return ManipulativeEvidence.make(
            encounter: encounter,
            outcome: correct ? .correct : .incorrect,
            support: support,
            attempts: attempts,
            startedAt: startedAt,
            at: date
        )
    }
}

public enum MathManipulativeSupport {
    public static func supports(_ encounter: LearningEncounter) -> Bool {
        switch encounter.mechanicID {
        case MathMechanicID.crystalCart:
            return [.counting, .addition, .subtraction, .missingAddend].contains(encounter.operation)
        case MathMechanicID.balanceScale:
            return encounter.operation == .comparison
        case MathMechanicID.numberBondMachine:
            return [.numberBond, .missingAddend].contains(encounter.operation)
        case MathMechanicID.tenFrameGate:
            return [.counting, .quantityMatching, .addition, .missingAddend].contains(encounter.operation)
        case MathMechanicID.missingNumberBridge:
            return encounter.operation == .missingAddend
        case MathMechanicID.patternLoom:
            return (try? PatternLoomModel(encounter: encounter)) != nil
        case MathMechanicID.placeValueFactory:
            return [.quantityMatching, .comparison].contains(encounter.operation)
                && (1...99).contains(encounter.targetQuantity)
                && (0...99).contains(encounter.initialQuantity)
        default:
            return false
        }
    }
}


public enum MathMechanicRuntimeError: Error {
    case unsupportedEncounter
}

/// Single learning-side adapter used by Math Castle regardless of the active renderer.
/// SpriteKit can send simple actions without owning arithmetic, correctness, support,
/// or evidence rules.
public enum MathMechanicRuntime: Codable, Equatable, Sendable {
    case crystalCart(CrystalCartModel)
    case balanceScale(BalanceScaleModel)
    case numberBond(NumberBondMachineModel)
    case tenFrame(TenFrameModel)
    case missingBridge(MissingNumberBridgeModel)
    case placeValueFactory(PlaceValueFactoryModel)
    case patternLoom(PatternLoomModel)

    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        switch encounter.mechanicID {
        case MathMechanicID.crystalCart:
            self = .crystalCart(try CrystalCartModel(encounter: encounter, at: date))
        case MathMechanicID.balanceScale:
            self = .balanceScale(try BalanceScaleModel(encounter: encounter, at: date))
        case MathMechanicID.numberBondMachine:
            self = .numberBond(try NumberBondMachineModel(encounter: encounter, at: date))
        case MathMechanicID.tenFrameGate:
            self = .tenFrame(try TenFrameModel(encounter: encounter, at: date))
        case MathMechanicID.missingNumberBridge:
            self = .missingBridge(try MissingNumberBridgeModel(encounter: encounter, at: date))
        case MathMechanicID.placeValueFactory:
            self = .placeValueFactory(try PlaceValueFactoryModel(encounter: encounter, at: date))
        case MathMechanicID.patternLoom:
            self = .patternLoom(try PatternLoomModel(encounter: encounter, at: date))
        default:
            throw MathMechanicRuntimeError.unsupportedEncounter
        }
    }

    public var encounter: LearningEncounter {
        switch self {
        case .crystalCart(let model): return model.encounter
        case .balanceScale(let model): return model.encounter
        case .numberBond(let model): return model.encounter
        case .tenFrame(let model): return model.encounter
        case .missingBridge(let model): return model.encounter
        case .placeValueFactory(let model): return model.encounter
        case .patternLoom(let model): return model.encounter
        }
    }

    public var completed: Bool {
        switch self {
        case .crystalCart(let model): return model.completed
        case .balanceScale(let model): return model.completed
        case .numberBond(let model): return model.completed
        case .tenFrame(let model): return model.completed
        case .missingBridge(let model): return model.completed
        case .placeValueFactory(let model): return model.completed
        case .patternLoom(let model): return model.completed
        }
    }

    public var support: SupportLevel {
        switch self {
        case .crystalCart(let model): return model.support
        case .balanceScale(let model): return model.support
        case .numberBond(let model): return model.support
        case .tenFrame(let model): return model.support
        case .missingBridge(let model): return model.support
        case .placeValueFactory(let model): return model.support
        case .patternLoom(let model): return model.support
        }
    }

    @discardableResult public mutating func increment() -> Bool {
        switch self {
        case .crystalCart(var model):
            let changed = model.add()
            self = .crystalCart(model)
            return changed
        case .numberBond(var model):
            let changed = model.addPart()
            self = .numberBond(model)
            return changed
        case .tenFrame(var model):
            let changed = model.addCounter()
            self = .tenFrame(model)
            return changed
        case .missingBridge(var model):
            let changed = model.increment()
            self = .missingBridge(model)
            return changed
        case .balanceScale, .placeValueFactory, .patternLoom:
            return false
        }
    }

    @discardableResult public mutating func decrement() -> Bool {
        switch self {
        case .crystalCart(var model):
            let changed = model.remove()
            self = .crystalCart(model)
            return changed
        case .numberBond(var model):
            let changed = model.removePart()
            self = .numberBond(model)
            return changed
        case .tenFrame(var model):
            let changed = model.removeCounter()
            self = .tenFrame(model)
            return changed
        case .missingBridge(var model):
            let changed = model.decrement()
            self = .missingBridge(model)
            return changed
        case .balanceScale, .placeValueFactory, .patternLoom:
            return false
        }
    }

    public mutating func setValue(_ value: Int) {
        switch self {
        case .numberBond(var model):
            model.setPart(value)
            self = .numberBond(model)
        case .missingBridge(var model):
            model.setNumber(value)
            self = .missingBridge(model)
        default:
            break
        }
    }

    public mutating func chooseComparison(_ choice: ComparisonChoice) {
        switch self {
        case .balanceScale(var model):
            model.choose(choice)
            self = .balanceScale(model)
        case .placeValueFactory(var model):
            model.choose(choice)
            self = .placeValueFactory(model)
        default:
            break
        }
    }

    @discardableResult
    public mutating func adjustPlaceValue(tensDelta: Int = 0, onesDelta: Int = 0) -> Bool {
        guard case .placeValueFactory(var model) = self else { return false }
        var changed = false

        if tensDelta > 0 {
            for _ in 0..<tensDelta { changed = model.addTen() || changed }
        } else if tensDelta < 0 {
            for _ in 0..<(-tensDelta) { changed = model.removeTen() || changed }
        }

        if onesDelta > 0 {
            for _ in 0..<onesDelta { changed = model.addOne() || changed }
        } else if onesDelta < 0 {
            for _ in 0..<(-onesDelta) { changed = model.removeOne() || changed }
        }

        self = .placeValueFactory(model)
        return changed
    }


    @discardableResult public mutating func choosePatternSymbol(_ symbol: Int) -> Bool {
        guard case .patternLoom(var model) = self else { return false }
        let changed = model.chooseSymbol(symbol)
        self = .patternLoom(model)
        return changed
    }

    @discardableResult public mutating func undoPatternSymbol() -> Bool {
        guard case .patternLoom(var model) = self else { return false }
        let changed = model.undo()
        self = .patternLoom(model)
        return changed
    }

    public mutating func apply(_ scaffold: Scaffold) {
        switch self {
        case .crystalCart(var model):
            model.apply(scaffold)
            self = .crystalCart(model)
        case .balanceScale(var model):
            model.apply(scaffold)
            self = .balanceScale(model)
        case .numberBond(var model):
            model.apply(scaffold)
            self = .numberBond(model)
        case .tenFrame(var model):
            model.apply(scaffold)
            self = .tenFrame(model)
        case .missingBridge(var model):
            model.apply(scaffold)
            self = .missingBridge(model)
        case .placeValueFactory(var model):
            model.apply(scaffold)
            self = .placeValueFactory(model)
        case .patternLoom(var model):
            model.apply(scaffold)
            self = .patternLoom(model)
        }
    }

    public mutating func submit(at date: Date = Date()) -> LearningEvidence? {
        switch self {
        case .crystalCart(var model):
            let evidence = model.submit(at: date)
            self = .crystalCart(model)
            return evidence
        case .balanceScale(var model):
            let evidence = model.submit(at: date)
            self = .balanceScale(model)
            return evidence
        case .numberBond(var model):
            let evidence = model.submit(at: date)
            self = .numberBond(model)
            return evidence
        case .tenFrame(var model):
            let evidence = model.submit(at: date)
            self = .tenFrame(model)
            return evidence
        case .missingBridge(var model):
            let evidence = model.submit(at: date)
            self = .missingBridge(model)
            return evidence
        case .placeValueFactory(var model):
            let evidence = model.submit(at: date)
            self = .placeValueFactory(model)
            return evidence
        case .patternLoom(var model):
            let evidence = model.submit(at: date)
            self = .patternLoom(model)
            return evidence
        }
    }
}
