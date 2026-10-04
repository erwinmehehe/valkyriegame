import Foundation

public struct SkillDefinition: Sendable {
    public let id: SkillID
    public let prerequisites: [SkillID]
    public let requiredReadiness: SkillState
    public init(_ id: SkillID, prerequisites: [SkillID] = [], requiredReadiness: SkillState = .developing) {
        self.id = id; self.prerequisites = prerequisites; self.requiredReadiness = requiredReadiness
    }
}
public enum SkillGraphError: Error { case duplicate, missingPrerequisite, cycle }
public struct SkillGraph: Sendable {
    public let skills: [SkillID: SkillDefinition]
    public init(_ definitions: [SkillDefinition]) throws {
        var map: [SkillID: SkillDefinition] = [:]
        for definition in definitions {
            guard map[definition.id] == nil else { throw SkillGraphError.duplicate }
            map[definition.id] = definition
        }
        for definition in definitions {
            guard definition.prerequisites.allSatisfy({ map[$0] != nil }) else { throw SkillGraphError.missingPrerequisite }
        }
        func visit(_ id: SkillID, path: Set<SkillID>) throws {
            guard !path.contains(id) else { throw SkillGraphError.cycle }
            for prerequisite in map[id]!.prerequisites { try visit(prerequisite, path: path.union([id])) }
        }
        for id in map.keys { try visit(id, path: []) }
        skills = map
    }
    public func isEligible(_ id: SkillID, for profile: LearnerProfile) -> Bool {
        guard let skill = skills[id] else { return false }
        return skill.prerequisites.allSatisfy {
            profile.readiness(for: $0) >= skill.requiredReadiness.readiness
        }
    }

    /// Returns a skill and every transitive prerequisite that supports it.
    /// Placement can use this as provisional readiness without changing mastery states.
    public func prerequisiteClosure(including id: SkillID) -> Set<SkillID> {
        guard skills[id] != nil else { return [] }
        var result: Set<SkillID> = []

        func visit(_ current: SkillID) {
            guard result.insert(current).inserted else { return }
            for prerequisite in skills[current]?.prerequisites ?? [] {
                visit(prerequisite)
            }
        }

        visit(id)
        return result
    }
}
