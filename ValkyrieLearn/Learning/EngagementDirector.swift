import Foundation

public enum EngagementAdjustment: Equatable { case none, deepenChallenge, changeRepresentation }
public struct EngagementDirector {
    public init() {}
    public func allows(_ encounter: LearningEncounter, profile: LearnerProfile) -> Bool {
        guard !profile.usedFingerprints.contains(encounter.fingerprint) else { return false }
        let lastTwo = Array(profile.recentActivities.suffix(2))
        return !(lastTwo.count == 2 && lastTwo.allSatisfy { $0.mechanicID == encounter.mechanicID })
    }
    public func adjustment(for skill: SkillID, profile: LearnerProfile) -> EngagementAdjustment {
        let recent = profile.progress(for: skill).evidence
        if recent.count >= 2 && recent.suffix(2).allSatisfy({ $0.outcome == .incorrect || $0.supportLevel.rawValue >= SupportLevel.strongHint.rawValue }) {
            return .changeRepresentation
        }
        if recent.count >= 3 && recent.suffix(3).allSatisfy({ $0.outcome == .correct && $0.supportLevel == .independent && $0.easySuccess }) {
            return .deepenChallenge
        }
        return .none
    }
    public func needsWorldChange(profile: LearnerProfile, now: Date) -> Bool {
        guard let first = profile.recentActivities.last(where: { $0.skillID == nil })?.timestamp
                ?? profile.recentActivities.first?.timestamp else { return false }
        return now.timeIntervalSince(first) >= 180
    }
    public func repetitionPenalty(_ encounter: LearningEncounter, profile: LearnerProfile) -> Int {
        profile.recentActivities.suffix(5).filter {
            $0.skillID == encounter.skillID && $0.representation == encounter.representation
        }.count
    }
}
