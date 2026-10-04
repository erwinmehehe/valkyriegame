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

public struct PlacementSession: Equatable, Sendable {
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
