import Foundation

public struct MasteryEngine {
    public init() {}
    public func record(_ evidence: LearningEvidence, in profile: inout LearnerProfile) {
        var progress = profile.progress(for: evidence.skillID)
        guard !progress.evidence.contains(where: { $0.id == evidence.id }) else { return }
        progress.evidence.append(evidence)
        progress.evidence.sort { $0.timestamp < $1.timestamp }
        // Repeated attempts at a single encounter cannot manufacture mastery.
        var best: [String: LearningEvidence] = [:]
        for item in progress.evidence where item.outcome == .correct {
            if best[item.encounterID].map({ $0.supportLevel.weight >= item.supportLevel.weight }) != true {
                best[item.encounterID] = item
            }
        }
        let successes = Array(best.values)
        let independent = successes.filter { $0.supportLevel == .independent }
        let weighted = successes.reduce(0) { $0 + $1.supportLevel.weight }
        let span = (independent.map(\.timestamp).max() ?? evidence.timestamp)
            .timeIntervalSince(independent.map(\.timestamp).min() ?? evidence.timestamp)
        let representations = Set(independent.map(\.representation))
        let recent = Array(progress.evidence.suffix(2))
        if recent.count == 2 && recent.allSatisfy({ $0.outcome == .incorrect }) {
            progress.state = .learning
        } else if independent.count >= 6 && weighted >= 6 && span >= 7 * 86_400 && representations.count >= 3
                    && independent.contains(where: \.transferContext) {
            progress.state = .mastered
        } else if independent.count >= 3 && weighted >= 3 {
            progress.state = .secure
        } else if independent.count >= 2 && weighted >= 2 {
            progress.state = .developing
        } else {
            progress.state = .learning
        }
        let last = progress.evidence.last!.timestamp
        progress.reviewDate = ReviewScheduler().nextDate(for: progress.state, after: last)
        profile.skills[evidence.skillID.rawValue] = progress
    }
}
