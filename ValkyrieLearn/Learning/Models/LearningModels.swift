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

public enum StoryRewardID: String, Codable, CaseIterable, Hashable, Sendable {
    case moonLantern
    case wordGardenLantern
    case puzzlePalaceLantern
    case starlightBridgeCharm
    case lumiLivingBloom
}

public enum CartOperation: String, Codable, CaseIterable, Sendable {
    case counting, quantityMatching, addition, subtraction, numberBond, missingAddend, comparison, equalGroups, pattern, shape, measurement, data, clockMarket, grouping, reasoningStudio, numberTrail, differenceBridge, routeExplorer
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

public struct ChallengeGateSession: Codable, Equatable, Sendable {
    public let encounterIDs: [String]
    public private(set) var completedEncounterIDs: Set<String>
    public let rewardID: StoryRewardID

    public init(
        encounterIDs: [String],
        completedEncounterIDs: Set<String> = [],
        rewardID: StoryRewardID = .moonLantern
    ) {
        self.encounterIDs = encounterIDs
        self.completedEncounterIDs = completedEncounterIDs.intersection(Set(encounterIDs))
        self.rewardID = rewardID
    }

    public var isComplete: Bool {
        !encounterIDs.isEmpty && encounterIDs.allSatisfy(completedEncounterIDs.contains)
    }

    public var nextEncounterID: String? {
        encounterIDs.first { !completedEncounterIDs.contains($0) }
    }

    public var completedCount: Int { completedEncounterIDs.count }

    @discardableResult
    public mutating func markCompleted(_ encounterID: String) -> Bool {
        guard encounterIDs.contains(encounterID) else { return false }
        return completedEncounterIDs.insert(encounterID).inserted
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
/// Two real-world loads for the child's optional, repeatable bridge experiment.
public enum BridgeTestLoad: String, Codable, CaseIterable, Sendable {
    case firefly
    case supplyCart
}

public enum BridgeTestResult: Equatable, Sendable {
    case crossed
    /// The first span that bends under the chosen load.
    case stoppedAt(Int)
}

/// A small, physical exploration quest rather than another scored worksheet.
/// Collect any three starlight shards and choose which bridge sockets to power.
/// Completing this *never* creates math mastery evidence; the normal adaptive
/// Math Castle work order still determines educational progress.
public struct StarlightBridgeQuest: Codable, Equatable, Sendable {
    public static let crystalCount = 3

    public private(set) var discovered = false
    public private(set) var collectedCrystals: Set<Int> = []
    /// Socket index -> crystal index. Free placement is intentional player agency.
    public private(set) var installedCrystals: [Int: Int] = [:]
    /// Optional so earlier native quest saves still restore after this upgrade.
    public private(set) var hiddenStarFound: Bool?

    /// Optional fields keep profiles produced before this mini-game decodable.
    public private(set) var reinforcedSpans: Set<Int>?
    public private(set) var successfulSupplyDelivery: Bool?
    public private(set) var trialCount: Int?

    public init() {}

    public var braces: Set<Int> { reinforcedSpans ?? [] }
    public var hasDeliveredSupplies: Bool { successfulSupplyDelivery == true }
    public var trialsCompleted: Int { trialCount ?? 0 }

    /// Choose where two reusable wooden braces go; tap one again to remove it.
    /// Children may experiment with as many different arrangements as they want.
    @discardableResult
    public mutating func toggleBrace(at span: Int) -> Bool {
        guard isComplete, (0..<Self.crystalCount).contains(span) else { return false }
        var chosen = braces
        if chosen.contains(span) {
            chosen.remove(span)
        } else {
            guard chosen.count < 2 else { return false }
            chosen.insert(span)
        }
        reinforcedSpans = chosen
        return true
    }

    /// Light fireflies can cross the restored span. A supply cart causes the
    /// left/right weak spans to bow unless reinforced. A failed trial shows
    /// exactly where it stopped, with no lost progress or negative scoring.
    /// The child can move braces and test again in any order.
    public mutating func testBridge(with load: BridgeTestLoad) -> BridgeTestResult? {
        guard isComplete else { return nil }
        trialCount = trialsCompleted + 1
        if load == .firefly { return .crossed }
        if let weak = [0, 2].first(where: { !braces.contains($0) }) {
            return .stoppedAt(weak)
        }
        successfulSupplyDelivery = true
        return .crossed
    }

    public var hasFoundHiddenStar: Bool { hiddenStarFound == true }

    /// Discoverable even on a return visit after the firefly was rescued.
    /// This is creative exploration, never a scored maths encounter.
    @discardableResult
    public mutating func discoverHiddenStar() -> Bool {
        guard discovered, collectedCrystals.count >= 2, !hasFoundHiddenStar else {
            return false
        }
        hiddenStarFound = true
        return true
    }

    /// Move light between repaired sockets without undoing the rescue.
    /// The heavy-load experiment is intentionally independent of color order.
    @discardableResult
    public mutating func swapInstalledCrystals(_ first: Int, _ second: Int) -> Bool {
        guard isComplete, first != second,
              (0..<Self.crystalCount).contains(first),
              (0..<Self.crystalCount).contains(second),
              let left = installedCrystals[first],
              let right = installedCrystals[second] else { return false }
        installedCrystals[first] = right
        installedCrystals[second] = left
        return true
    }

    public var isComplete: Bool { installedCrystals.count == Self.crystalCount }
    public var installedCount: Int { installedCrystals.count }
    public var availableCrystals: [Int] {
        (0..<Self.crystalCount).filter {
            collectedCrystals.contains($0) && !installedCrystals.values.contains($0)
        }
    }

    @discardableResult
    public mutating func discover() -> Bool {
        guard !discovered else { return false }
        discovered = true
        return true
    }

    @discardableResult
    public mutating func collect(_ crystal: Int) -> Bool {
        guard discovered, !isComplete, (0..<Self.crystalCount).contains(crystal) else {
            return false
        }
        return collectedCrystals.insert(crystal).inserted
    }

    @discardableResult
    public mutating func install(_ crystal: Int, into socket: Int) -> Bool {
        guard discovered, !isComplete,
              (0..<Self.crystalCount).contains(socket),
              collectedCrystals.contains(crystal),
              installedCrystals[socket] == nil,
              !installedCrystals.values.contains(crystal) else { return false }
        installedCrystals[socket] = crystal
        return true
    }
}

public struct LearnerProfile: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var schemaVersion = 1
    public var skills: [String: SkillProgress] = [:]
    public var recentActivities: [ActivityRecord] = []
    public var usedFingerprints: Set<String> = []
    /// Provisional readiness inferred from hidden placement. This can unlock
    /// prerequisite-safe content without claiming observed mastery.
    public var placementReadySkillIDs: Set<SkillID>?
    /// Optional so profiles written before Story Tree rewards still decode.
    public var storyRewardIDs: Set<StoryRewardID>?
    /// Reward-specific branch slots for child-directed Story Tree decoration.
    public var storyRewardPlacements: [String: Int]?
    /// Optional to preserve decoding of profiles saved before Science Lab.
    public var scienceAdventure: ScienceAdventure?
    /// Optional for decoding learner profiles saved before the bridge adventure.
    public var starlightBridgeQuest: StarlightBridgeQuest?
    /// Optional so profiles saved before Lumi's garden simulation still decode.
    public var lumiLivingGarden: LumiLivingGarden?

    public init(id: UUID = UUID()) { self.id = id }
    public func progress(for skill: SkillID) -> SkillProgress { skills[skill.rawValue] ?? SkillProgress() }

    public func readiness(for skill: SkillID) -> Int {
        let observed = progress(for: skill).state.readiness
        let placement = placementReadySkillIDs?.contains(skill) == true
            ? SkillState.developing.readiness
            : 0
        return max(observed, placement)
    }

    public mutating func markPlacementReady(_ skillIDs: Set<SkillID>) {
        var ready = placementReadySkillIDs ?? []
        ready.formUnion(skillIDs)
        placementReadySkillIDs = ready
    }

    public func hasStoryReward(_ reward: StoryRewardID) -> Bool {
        storyRewardIDs?.contains(reward) == true
    }

    @discardableResult
    public mutating func unlockStoryReward(_ reward: StoryRewardID) -> Bool {
        var rewards = storyRewardIDs ?? []
        let inserted = rewards.insert(reward).inserted
        storyRewardIDs = rewards
        return inserted
    }

    public func storyRewardPlacement(_ reward: StoryRewardID) -> Int {
        max(0, storyRewardPlacements?[reward.rawValue] ?? 0)
    }

    @discardableResult
    public mutating func cycleStoryRewardPlacement(_ reward: StoryRewardID, slotCount: Int) -> Int {
        guard hasStoryReward(reward), slotCount > 0 else {
            return storyRewardPlacement(reward)
        }
        var placements = storyRewardPlacements ?? [:]
        let next = (storyRewardPlacement(reward) + 1) % slotCount
        placements[reward.rawValue] = next
        storyRewardPlacements = placements
        return next
    }
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
