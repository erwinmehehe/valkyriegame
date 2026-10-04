import Foundation

public struct ReviewScheduler {
    public init() {}
    public func nextDate(for state: SkillState, after date: Date) -> Date? {
        switch state {
        case .secure: return date.addingTimeInterval(2 * 86_400)
        case .mastered: return date.addingTimeInterval(7 * 86_400)
        case .reviewDue: return date
        default: return nil
        }
    }
    public func markDue(in profile: inout LearnerProfile, at date: Date) {
        for key in Array(profile.skills.keys) {
            guard var progress = profile.skills[key], let due = progress.reviewDate, due <= date,
                  [.secure, .mastered].contains(progress.state) else { continue }
            progress.state = .reviewDue; profile.skills[key] = progress
        }
    }
}
