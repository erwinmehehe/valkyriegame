import Foundation

public enum EncounterSelection: Equatable {
    case encounter(LearningEncounter)
    case explorationBreak
    case needsContent(SkillID?)
}
public struct AdaptiveDirector {
    public let graph: SkillGraph
    public init(graph: SkillGraph) { self.graph = graph }
    public func next(for profile: LearnerProfile, candidates: [LearningEncounter], now: Date) -> EncounterSelection {
        let engagement = EngagementDirector()
        if engagement.needsWorldChange(profile: profile, now: now) { return .explorationBreak }
        let eligible = candidates.filter { graph.isEligible($0.skillID, for: profile) }
        let fresh = eligible.filter { engagement.allows($0, profile: profile) }
        let filtered = fresh.filter { candidate in
            let adjustment = engagement.adjustment(for: candidate.skillID, profile: profile)
            let previous = profile.progress(for: candidate.skillID).evidence.last?.representation
            switch adjustment {
            case .none: return true
            case .deepenChallenge: return candidate.challengeDepth > 0
            case .changeRepresentation: return candidate.representation != previous
            }
        }
        func priority(_ encounter: LearningEncounter) -> Int {
            let state = profile.progress(for: encounter.skillID).state
            let due = profile.progress(for: encounter.skillID).reviewDate.map { $0 <= now } ?? false
            let base = due ? 0 : (state == .mastered || state == .secure ? 30 : state == .developing ? 10 : 20)
            return base + engagement.repetitionPenalty(encounter, profile: profile)
        }
        if let next = filtered.sorted(by: {
            priority($0) == priority($1) ? $0.id < $1.id : priority($0) < priority($1)
        }).first { return .encounter(next) }
        if !fresh.isEmpty { return .needsContent(fresh.first?.skillID) }
        if eligible.contains(where: { !profile.usedFingerprints.contains($0.fingerprint) }) { return .explorationBreak }
        return .needsContent(eligible.first?.skillID)
    }
}


// MARK: - Hidden placement

/// Placement is deliberately separate from mastery. A successful diagnostic probe can
/// move the next probe forward, but it never marks a skill secure/mastered by itself.
public struct PlacementProbe: Identifiable, Equatable, Sendable {
    public let id: String
    public let band: Int
    public let encounter: LearningEncounter

    public var skillID: SkillID { encounter.skillID }

    public init(id: String, band: Int, encounter: LearningEncounter) {
        self.id = id
        self.band = max(0, band)
        self.encounter = encounter
    }
}

public enum PlacementResponse: Equatable, Sendable {
    case independentSuccess
    case supportedSuccess
    case struggle

    public init(_ evidence: LearningEvidence) {
        if evidence.outcome == .correct && evidence.supportLevel == .independent {
            self = .independentSuccess
        } else if evidence.outcome == .correct {
            self = .supportedSuccess
        } else {
            self = .struggle
        }
    }
}

public enum PlacementConfidence: String, Equatable, Sendable {
    case low, medium, high
}

public struct PlacementRecommendation: Equatable, Sendable {
    public let suggestedBand: Int
    public let suggestedSkillID: SkillID?
    public let confidence: PlacementConfidence
    public let highestIndependentBand: Int?
    public let firstSupportNeededBand: Int?

    public init(suggestedBand: Int, suggestedSkillID: SkillID?, confidence: PlacementConfidence,
                highestIndependentBand: Int?, firstSupportNeededBand: Int?) {
        self.suggestedBand = suggestedBand
        self.suggestedSkillID = suggestedSkillID
        self.confidence = confidence
        self.highestIndependentBand = highestIndependentBand
        self.firstSupportNeededBand = firstSupportNeededBand
    }
}

public struct PlacementSession: Codable, Equatable, Sendable {
    public fileprivate(set) var nextBand: Int
    public fileprivate(set) var attemptedProbeIDs: Set<String>
    public fileprivate(set) var highestIndependentBand: Int?
    public fileprivate(set) var firstSupportNeededBand: Int?
    public fileprivate(set) var completedProbeCount: Int
    public fileprivate(set) var isComplete: Bool

    public init(startBand: Int = 2) {
        nextBand = max(0, startBand)
        attemptedProbeIDs = []
        highestIndependentBand = nil
        firstSupportNeededBand = nil
        completedProbeCount = 0
        isComplete = false
    }
}

/// Small adaptive diagnostic controller for the first Math Castle adventure.
///
/// Policy:
/// - starts above trivial counting by default
/// - jumps two bands after an easy independent success
/// - advances one band after an ordinary independent success
/// - steps back after support or an incorrect response
/// - stops after bracketing the learner's current independent ceiling
/// - never mutates LearnerProfile or grants mastery directly
public struct PlacementEngine: Sendable {
    public let probes: [PlacementProbe]
    public let maxProbes: Int

    private let minBand: Int
    private let maxBand: Int

    public init(probes: [PlacementProbe], maxProbes: Int = 8) {
        self.probes = probes.sorted {
            $0.band == $1.band ? $0.id < $1.id : $0.band < $1.band
        }
        self.maxProbes = max(1, maxProbes)
        minBand = self.probes.map(\.band).min() ?? 0
        maxBand = self.probes.map(\.band).max() ?? 0
    }

    public func begin(startBand: Int = 2) -> PlacementSession {
        PlacementSession(startBand: clamped(startBand))
    }

    public func nextProbe(for session: PlacementSession) -> PlacementProbe? {
        guard !session.isComplete else { return nil }

        let remaining = probes.filter { !session.attemptedProbeIDs.contains($0.id) }
        guard !remaining.isEmpty else { return nil }

        let desired = clamped(session.nextBand)
        return remaining.min {
            let leftDistance = abs($0.band - desired)
            let rightDistance = abs($1.band - desired)
            if leftDistance == rightDistance { return $0.band < $1.band }
            return leftDistance < rightDistance
        }
    }

    public func record(_ evidence: LearningEvidence, for probe: PlacementProbe, in session: inout PlacementSession) {
        guard !session.isComplete,
              !session.attemptedProbeIDs.contains(probe.id),
              evidence.encounterID == probe.encounter.id,
              evidence.skillID == probe.skillID else {
            return
        }

        session.attemptedProbeIDs.insert(probe.id)
        session.completedProbeCount += 1

        switch PlacementResponse(evidence) {
        case .independentSuccess:
            session.highestIndependentBand = max(session.highestIndependentBand ?? probe.band, probe.band)
            session.nextBand = probe.band + (evidence.easySuccess ? 2 : 1)

        case .supportedSuccess, .struggle:
            session.firstSupportNeededBand = min(session.firstSupportNeededBand ?? probe.band, probe.band)
            session.nextBand = probe.band - 1
        }

        session.nextBand = clamped(session.nextBand)
        session.isComplete = shouldComplete(session)
    }

    public func recommendation(for session: PlacementSession) -> PlacementRecommendation {
        let suggestedBand: Int

        if let supportBand = session.firstSupportNeededBand {
            suggestedBand = clamped(supportBand)
        } else if let independentBand = session.highestIndependentBand {
            suggestedBand = clamped(independentBand + 1)
        } else {
            suggestedBand = minBand
        }

        let nearestSkill = probes.min {
            let leftDistance = abs($0.band - suggestedBand)
            let rightDistance = abs($1.band - suggestedBand)
            if leftDistance == rightDistance { return $0.band < $1.band }
            return leftDistance < rightDistance
        }?.skillID

        let bracketed = session.highestIndependentBand.flatMap { high in
            session.firstSupportNeededBand.map { $0 <= high + 1 }
        } ?? false

        let confidence: PlacementConfidence
        if bracketed || session.highestIndependentBand == maxBand || session.completedProbeCount >= maxProbes {
            confidence = .high
        } else if session.completedProbeCount >= 3 {
            confidence = .medium
        } else {
            confidence = .low
        }

        return PlacementRecommendation(
            suggestedBand: suggestedBand,
            suggestedSkillID: nearestSkill,
            confidence: confidence,
            highestIndependentBand: session.highestIndependentBand,
            firstSupportNeededBand: session.firstSupportNeededBand
        )
    }

    private func shouldComplete(_ session: PlacementSession) -> Bool {
        if session.completedProbeCount >= maxProbes { return true }

        if let high = session.highestIndependentBand,
           let support = session.firstSupportNeededBand,
           support <= high + 1 {
            return true
        }

        if session.highestIndependentBand == maxBand { return true }

        if session.firstSupportNeededBand == minBand && session.highestIndependentBand == nil {
            return true
        }

        return session.attemptedProbeIDs.count >= probes.count
    }

    private func clamped(_ band: Int) -> Int {
        min(max(band, minBand), maxBand)
    }
}


// MARK: - Adaptive session planning

public enum SessionLane: String, CaseIterable, Codable, Hashable, Sendable {
    case learning
    case review
    case stretch
    case confidence
}

public struct SessionPlannerConfiguration: Equatable, Sendable {
    public let learningWeight: Int
    public let reviewWeight: Int
    public let stretchWeight: Int
    public let confidenceWeight: Int
    public let explorationEveryEncounters: Int

    public init(
        learningWeight: Int = 60,
        reviewWeight: Int = 20,
        stretchWeight: Int = 15,
        confidenceWeight: Int = 5,
        explorationEveryEncounters: Int = 4
    ) {
        self.learningWeight = max(0, learningWeight)
        self.reviewWeight = max(0, reviewWeight)
        self.stretchWeight = max(0, stretchWeight)
        self.confidenceWeight = max(0, confidenceWeight)
        self.explorationEveryEncounters = max(0, explorationEveryEncounters)
    }

    public func weight(for lane: SessionLane) -> Int {
        switch lane {
        case .learning: return learningWeight
        case .review: return reviewWeight
        case .stretch: return stretchWeight
        case .confidence: return confidenceWeight
        }
    }

    public var totalWeight: Int {
        max(1, SessionLane.allCases.reduce(0) { $0 + weight(for: $1) })
    }
}

public struct PlannedSessionEncounter: Equatable, Sendable {
    public let lane: SessionLane
    public let encounter: LearningEncounter

    public init(lane: SessionLane, encounter: LearningEncounter) {
        self.lane = lane
        self.encounter = encounter
    }
}

public enum SessionBeat: Equatable, Sendable {
    case encounter(PlannedSessionEncounter)
    case explorationBreak
}

public struct SessionPlan: Equatable, Sendable {
    public let beats: [SessionBeat]
    public let requestedEncounterCount: Int
    public let desiredLaneCounts: [SessionLane: Int]
    public let actualLaneCounts: [SessionLane: Int]

    public init(
        beats: [SessionBeat],
        requestedEncounterCount: Int,
        desiredLaneCounts: [SessionLane: Int],
        actualLaneCounts: [SessionLane: Int]
    ) {
        self.beats = beats
        self.requestedEncounterCount = requestedEncounterCount
        self.desiredLaneCounts = desiredLaneCounts
        self.actualLaneCounts = actualLaneCounts
    }

    public var encounters: [PlannedSessionEncounter] {
        beats.compactMap {
            guard case let .encounter(item) = $0 else { return nil }
            return item
        }
    }

    public var encounterCount: Int { encounters.count }
    public var explorationBreakCount: Int {
        beats.reduce(0) { count, beat in
            if case .explorationBreak = beat { return count + 1 }
            return count
        }
    }

    public var unfilledEncounterCount: Int {
        max(0, requestedEncounterCount - encounterCount)
    }
}

/// Builds a deterministic session plan from learner state and authored encounters.
///
/// The default target mix is 60% current learning, 20% spaced review,
/// 15% gentle stretch and 5% confidence/fun. The mix is a target rather than
/// a hard failure condition: if a lane lacks safe/eligible content, the planner
/// reallocates the slot rather than repeating an exhausted activity.
///
/// The planner also uses EngagementDirector rules so exact activity fingerprints
/// are not repeated and no mechanic dominates the session.
public struct SessionPlanner: Sendable {
    public let graph: SkillGraph
    public let stretchSkillIDs: Set<SkillID>
    public let configuration: SessionPlannerConfiguration

    public init(
        graph: SkillGraph,
        stretchSkillIDs: Set<SkillID> = [],
        configuration: SessionPlannerConfiguration = SessionPlannerConfiguration()
    ) {
        self.graph = graph
        self.stretchSkillIDs = stretchSkillIDs
        self.configuration = configuration
    }

    public func plan(
        for profile: LearnerProfile,
        candidates: [LearningEncounter],
        encounterCount: Int = 20,
        now: Date
    ) -> SessionPlan {
        let requested = max(0, encounterCount)
        let desired = desiredLaneCounts(total: requested)
        guard requested > 0, !candidates.isEmpty else {
            return SessionPlan(
                beats: [],
                requestedEncounterCount: requested,
                desiredLaneCounts: desired,
                actualLaneCounts: emptyLaneCounts()
            )
        }

        var shadow = profile
        ReviewScheduler().markDue(in: &shadow, at: now)

        var beats: [SessionBeat] = []
        var actual = emptyLaneCounts()
        var selectedCount = 0
        var breakSerial = 0

        // Elapsed play time matters even when a learner spends a long time on
        // only one encounter. Never reset the clock just because a plan is rebuilt.
        if EngagementDirector().needsWorldChange(profile: shadow, now: now) {
            appendExplorationBreak(to: &beats, profile: &shadow, now: now,
                                   serial: &breakSerial, encounterIndex: 0)
        }

        while selectedCount < requested {
            if configuration.explorationEveryEncounters > 0,
               selectedCount > 0,
               selectedCount % configuration.explorationEveryEncounters == 0,
               beats.last != .explorationBreak {
                appendExplorationBreak(
                    to: &beats,
                    profile: &shadow,
                    now: now,
                    serial: &breakSerial,
                    encounterIndex: selectedCount
                )
            }

            var selected: PlannedSessionEncounter?
            let laneOrder = preferredLanes(
                slot: selectedCount,
                actual: actual,
                desired: desired
            )

            for lane in laneOrder {
                if let encounter = bestCandidate(
                    in: lane,
                    profile: shadow,
                    candidates: candidates,
                    now: now
                ) {
                    selected = PlannedSessionEncounter(lane: lane, encounter: encounter)
                    break
                }
            }

            if selected == nil,
               hasUnusedEligibleContent(profile: shadow, candidates: candidates, now: now),
               beats.last != .explorationBreak {
                appendExplorationBreak(
                    to: &beats,
                    profile: &shadow,
                    now: now,
                    serial: &breakSerial,
                    encounterIndex: selectedCount
                )

                for lane in laneOrder {
                    if let encounter = bestCandidate(
                        in: lane,
                        profile: shadow,
                        candidates: candidates,
                        now: now
                    ) {
                        selected = PlannedSessionEncounter(lane: lane, encounter: encounter)
                        break
                    }
                }
            }

            guard let selected else { break }

            beats.append(.encounter(selected))
            actual[selected.lane, default: 0] += 1
            shadow.begin(
                selected.encounter,
                at: now.addingTimeInterval(Double(selectedCount + breakSerial))
            )
            selectedCount += 1
        }

        return SessionPlan(
            beats: beats,
            requestedEncounterCount: requested,
            desiredLaneCounts: desired,
            actualLaneCounts: actual
        )
    }

    public func desiredLaneCounts(total: Int) -> [SessionLane: Int] {
        let total = max(0, total)
        guard total > 0 else { return emptyLaneCounts() }

        let denominator = configuration.totalWeight
        var counts = emptyLaneCounts()
        var remainders: [(lane: SessionLane, remainder: Int)] = []
        var assigned = 0

        for lane in SessionLane.allCases {
            let scaled = total * configuration.weight(for: lane)
            let base = scaled / denominator
            counts[lane] = base
            assigned += base
            remainders.append((lane, scaled % denominator))
        }

        let tieOrder: [SessionLane: Int] = [
            .learning: 0,
            .review: 1,
            .stretch: 2,
            .confidence: 3
        ]

        remainders.sort {
            if $0.remainder == $1.remainder {
                return tieOrder[$0.lane, default: 99] < tieOrder[$1.lane, default: 99]
            }
            return $0.remainder > $1.remainder
        }

        var remaining = total - assigned
        var index = 0
        while remaining > 0 && !remainders.isEmpty {
            counts[remainders[index % remainders.count].lane, default: 0] += 1
            remaining -= 1
            index += 1
        }

        return counts
    }

    private func bestCandidate(
        in lane: SessionLane,
        profile: LearnerProfile,
        candidates: [LearningEncounter],
        now: Date
    ) -> LearningEncounter? {
        let engagement = EngagementDirector()

        let eligible = candidates.filter {
            graph.isEligible($0.skillID, for: profile)
                && matches($0, lane: lane, profile: profile, now: now)
                && engagement.allows($0, profile: profile)
                && respectsAdjustment($0, lane: lane, profile: profile)
        }

        func score(_ encounter: LearningEncounter) -> Int {
            let progress = profile.progress(for: encounter.skillID)
            var value = engagement.repetitionPenalty(encounter, profile: profile) * 100

            switch lane {
            case .learning:
                switch progress.state {
                case .developing: value += 0
                case .learning: value += 10
                case .new: value += 20
                default: value += 40
                }
                value += encounter.challengeDepth * 4

            case .review:
                value += encounter.challengeDepth * 5
                if progress.state != .reviewDue { value += 5 }

            case .stretch:
                value += encounter.challengeDepth * 3
                if stretchSkillIDs.contains(encounter.skillID) { value -= 2 }
                // Preserve meaningful story/reasoning transfer in a 12-task
                // session even as concrete stretch manipulatives expand.
                // A representation label alone never supplies mastery evidence.
                if encounter.representation == .reasoning
                    || encounter.representation == .story { value -= 9 }

            case .confidence:
                value += encounter.challengeDepth * 10
                if progress.state == .mastered { value += 2 }
            }

            return value
        }

        return eligible.sorted {
            let left = score($0)
            let right = score($1)
            return left == right ? $0.id < $1.id : left < right
        }.first
    }

    private func matches(
        _ encounter: LearningEncounter,
        lane: SessionLane,
        profile: LearnerProfile,
        now: Date
    ) -> Bool {
        let progress = profile.progress(for: encounter.skillID)
        let isDue = progress.state == .reviewDue || (progress.reviewDate.map { $0 <= now } ?? false)
        let isStretch = stretchSkillIDs.contains(encounter.skillID) || encounter.challengeDepth > 0

        switch lane {
        case .review:
            return isDue

        case .stretch:
            guard !isDue, progress.state != .mastered else { return false }
            return isStretch

        case .confidence:
            guard !isDue, encounter.challengeDepth == 0 else { return false }
            return progress.state == .secure || progress.state == .mastered

        case .learning:
            guard !isDue, !isStretch else { return false }
            return progress.state == .new
                || progress.state == .learning
                || progress.state == .developing
        }
    }

    private func respectsAdjustment(
        _ encounter: LearningEncounter,
        lane: SessionLane,
        profile: LearnerProfile
    ) -> Bool {
        // The small confidence lane is intentionally allowed to stay easy.
        if lane == .confidence { return true }

        let engagement = EngagementDirector()
        let previous = profile.progress(for: encounter.skillID).evidence.last?.representation

        switch engagement.adjustment(for: encounter.skillID, profile: profile) {
        case .none:
            return true
        case .deepenChallenge:
            return encounter.challengeDepth > 0 || lane == .stretch
        case .changeRepresentation:
            return encounter.representation != previous
        }
    }

    private func hasUnusedEligibleContent(
        profile: LearnerProfile,
        candidates: [LearningEncounter],
        now: Date
    ) -> Bool {
        candidates.contains { encounter in
            guard graph.isEligible(encounter.skillID, for: profile),
                  !profile.usedFingerprints.contains(encounter.fingerprint) else {
                return false
            }

            return SessionLane.allCases.contains {
                matches(encounter, lane: $0, profile: profile, now: now)
            }
        }
    }

    private func preferredLanes(
        slot: Int,
        actual: [SessionLane: Int],
        desired: [SessionLane: Int]
    ) -> [SessionLane] {
        let denominator = configuration.totalWeight

        func deficit(_ lane: SessionLane) -> Int {
            let idealScaled = (slot + 1) * configuration.weight(for: lane)
            let actualScaled = actual[lane, default: 0] * denominator
            return idealScaled - actualScaled
        }

        let primary = SessionLane.allCases
            .filter { actual[$0, default: 0] < desired[$0, default: 0] }
            .sorted {
                let left = deficit($0)
                let right = deficit($1)
                if left == right {
                    return lanePriority($0) < lanePriority($1)
                }
                return left > right
            }

        let fallback = SessionLane.allCases
            .filter { !primary.contains($0) }
            .sorted { lanePriority($0) < lanePriority($1) }

        return primary + fallback
    }

    private func lanePriority(_ lane: SessionLane) -> Int {
        switch lane {
        case .learning: return 0
        case .review: return 1
        case .stretch: return 2
        case .confidence: return 3
        }
    }

    private func appendExplorationBreak(
        to beats: inout [SessionBeat],
        profile: inout LearnerProfile,
        now: Date,
        serial: inout Int,
        encounterIndex: Int
    ) {
        serial += 1
        beats.append(.explorationBreak)
        profile.recordActivity(
            ActivityRecord(
                fingerprint: "planned-exploration-\(serial)",
                mechanicID: "explorationBreak",
                timestamp: now.addingTimeInterval(Double(encounterIndex + serial))
            )
        )
    }

    private func emptyLaneCounts() -> [SessionLane: Int] {
        Dictionary(uniqueKeysWithValues: SessionLane.allCases.map { ($0, 0) })
    }
}


/// Lightweight consumable cursor so the game layer can execute a preplanned adaptive
/// session one beat at a time without owning scheduling policy.
public struct SessionPlanCursor: Sendable {
    public let plan: SessionPlan
    public private(set) var index: Int

    public init(plan: SessionPlan, index: Int = 0) {
        self.plan = plan
        self.index = min(max(0, index), plan.beats.count)
    }

    public var current: SessionBeat? {
        guard index < plan.beats.count else { return nil }
        return plan.beats[index]
    }

    public var isComplete: Bool { index >= plan.beats.count }
    public var remainingBeatCount: Int { max(0, plan.beats.count - index) }

    @discardableResult public mutating func advance() -> SessionBeat? {
        guard index < plan.beats.count else { return nil }
        let completed = plan.beats[index]
        index += 1
        return completed
    }
}
