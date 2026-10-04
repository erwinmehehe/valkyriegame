import Foundation

// Reusable model: rendering and touch input don't own the arithmetic.
// Future operations require their own completion strategy; unsupported ones fail explicitly.
public struct CrystalCartModel: Codable {
    public enum CartError: Error { case unsupportedOperation, invalidQuantity }
    public let encounter: LearningEncounter
    public private(set) var quantity: Int
    public private(set) var attempts = 0
    public private(set) var support: SupportLevel = .independent
    public private(set) var completed = false
    public let startedAt: Date
    public init(encounter: LearningEncounter, at date: Date = Date()) throws {
        guard [.counting, .addition, .missingAddend].contains(encounter.operation) else { throw CartError.unsupportedOperation }
        guard (0...12).contains(encounter.initialQuantity), (1...12).contains(encounter.targetQuantity),
              encounter.initialQuantity < encounter.targetQuantity else { throw CartError.invalidQuantity }
        self.encounter = encounter; quantity = encounter.initialQuantity; startedAt = date
    }
    @discardableResult public mutating func add() -> Bool {
        guard !completed, quantity < 12 else { return false }; quantity += 1; return true
    }
    @discardableResult public mutating func remove() -> Bool {
        guard !completed, quantity > encounter.initialQuantity else { return false }; quantity -= 1; return true
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
            transferContext: encounter.representation == .story || encounter.representation == .reasoning,
            easySuccess: correct && support == .independent && attempts == 1 && date.timeIntervalSince(startedAt) < 25)
    }
}
