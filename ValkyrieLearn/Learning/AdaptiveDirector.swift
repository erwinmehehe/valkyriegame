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
