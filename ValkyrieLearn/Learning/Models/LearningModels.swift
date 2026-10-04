import Foundation

public struct SkillID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public enum SkillState: String, Codable, Sendable {
    case new, learning, developing, secure, reviewDue, mastered
    public var readiness: Int {
        switch self {
        case .new: return 0
        case .learning: return 1
        case .developing: return 2
        case .secure, .reviewDue, .mastered: return 3
        }
    }
}

public enum SupportLevel: Int, Codable, CaseIterable, Sendable {
    case independent, lightHint, strongHint, demonstration
    public var weight: Double {
        switch self {
        case .independent: return 1
        case .lightHint: return 0.55
        case .strongHint: return 0.25
        case .demonstration: return 0.1
        }
    }
}
public enum Representation: String, Codable, CaseIterable, Sendable {
    case concrete, pictorial, symbolic, story, reasoning
}
public enum Outcome: String, Codable, Sendable { case correct, incorrect }
public enum CartOperation: String, Codable, CaseIterable, Sendable {
    case counting, quantityMatching, addition, subtraction, numberBond, missingAddend, comparison, equalGroups
}

public struct LearningEncounter: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let operation: CartOperation
    public let initialQuantity: Int
    public let targetQuantity: Int
    public let prompt: String
    public let context: String
    public let challengeDepth: Int
    public var fingerprint: String {
        // Deliberately excludes ID and wording: relabeling identical math isn't variety.
        "\(mechanicID)|\(representation.rawValue)|\(operation.rawValue)|\(initialQuantity)|\(targetQuantity)|\(context)|\(challengeDepth)"
    }
    public init(id: String, skillID: SkillID, mechanicID: String = "crystalCart",
                representation: Representation = .concrete, operation: CartOperation,
                initialQuantity: Int, targetQuantity: Int, prompt: String,
                context: String = "castleCart", challengeDepth: Int = 0) {
        self.id = id; self.skillID = skillID; self.mechanicID = mechanicID
        self.representation = representation; self.operation = operation
        self.initialQuantity = initialQuantity; self.targetQuantity = targetQuantity
        self.prompt = prompt; self.context = context; self.challengeDepth = challengeDepth
    }
}

public struct LearningEvidence: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let encounterID: String
    public let skillID: SkillID
    public let outcome: Outcome
    public let supportLevel: SupportLevel
    public let representation: Representation
    public let mechanicID: String
    public let attempts: Int
    public let responseTime: TimeInterval?
    public let timestamp: Date
    public let transferContext: Bool
    public let easySuccess: Bool
    public init(id: UUID = UUID(), encounterID: String, skillID: SkillID,
                outcome: Outcome, supportLevel: SupportLevel = .independent,
                representation: Representation = .concrete, mechanicID: String = "crystalCart",
                attempts: Int = 1, responseTime: TimeInterval? = nil, timestamp: Date = Date(),
                transferContext: Bool = false, easySuccess: Bool = false) {
        self.id = id; self.encounterID = encounterID; self.skillID = skillID
        self.outcome = outcome; self.supportLevel = supportLevel
        self.representation = representation; self.mechanicID = mechanicID
        self.attempts = max(1, attempts); self.responseTime = responseTime
        self.timestamp = timestamp; self.transferContext = transferContext; self.easySuccess = easySuccess
    }
}

public struct SkillProgress: Codable, Equatable, Sendable {
    public var state: SkillState = .new
    public var evidence: [LearningEvidence] = []
    public var reviewDate: Date?
    public init(state: SkillState = .new) { self.state = state }
}
public struct ActivityRecord: Codable, Equatable, Sendable {
    public let fingerprint: String
    public let mechanicID: String
    public let skillID: SkillID?
    public let representation: Representation?
    public let timestamp: Date
    public init(fingerprint: String, mechanicID: String, skillID: SkillID? = nil,
                representation: Representation? = nil, timestamp: Date = Date()) {
        self.fingerprint = fingerprint; self.mechanicID = mechanicID
        self.skillID = skillID; self.representation = representation; self.timestamp = timestamp
    }
}
public struct LearnerProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion = 1
    public var skills: [String: SkillProgress] = [:]
    public var recentActivities: [ActivityRecord] = []
    public var usedFingerprints: Set<String> = []
    public init(id: UUID = UUID()) { self.id = id }
    public func progress(for skill: SkillID) -> SkillProgress { skills[skill.rawValue] ?? SkillProgress() }
    public mutating func begin(_ encounter: LearningEncounter, at date: Date) {
        usedFingerprints.insert(encounter.fingerprint)
        recordActivity(ActivityRecord(fingerprint: encounter.fingerprint, mechanicID: encounter.mechanicID,
                                     skillID: encounter.skillID, representation: encounter.representation, timestamp: date))
    }
    public mutating func recordActivity(_ record: ActivityRecord) {
        recentActivities.append(record)
        recentActivities = Array(recentActivities.suffix(20))
    }
}
