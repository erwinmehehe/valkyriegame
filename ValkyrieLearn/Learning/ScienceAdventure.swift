import Foundation

public enum ScienceGreenhouseStage: String, Codable, Equatable, Sendable {
    case arrive, inspected, watered, lit
}

public enum ScienceWeatherStage: String, Codable, Equatable, Sendable {
    case arrive, morningObserved, afternoonObserved, complete
}

public enum ScienceGroveStage: String, Codable, Equatable, Sendable {
    case arrive, animalObserved, habitatMatched, bodyPartObserved, complete
}

public enum ScienceForecastChoice: String, Codable, Equatable, Sendable {
    case sun, rain
}

public enum ScienceHabitatChoice: String, Codable, Equatable, Sendable {
    case pondEdge, dryRidge
}

/// Durable Science Lab state. This is stored inside LearnerProfile JSON so
/// Science progress survives scene recreation without changing the SwiftData schema.
public struct ScienceAdventure: Codable, Equatable, Sendable {
    public var placement: SciencePlacementSession
    public var greenhouseStage: ScienceGreenhouseStage
    public var greenhouseComplete: Bool
    public var weatherStage: ScienceWeatherStage
    public var selectedForecast: ScienceForecastChoice?
    public var creatureRouteOpen: Bool
    public var groveStage: ScienceGroveStage
    public var selectedHabitat: ScienceHabitatChoice?
    public var groveRestored: Bool

    public init(startBand: Int = 3) {
        placement = SciencePlacementEngine().begin(startBand: startBand)
        greenhouseStage = .arrive
        greenhouseComplete = false
        weatherStage = .arrive
        selectedForecast = nil
        creatureRouteOpen = false
        groveStage = .arrive
        selectedHabitat = nil
        groveRestored = false
    }

    public var placementComplete: Bool { placement.isComplete }

    public func nextPlacementProbe() -> SciencePlacementProbe? {
        SciencePlacementEngine().nextProbe(for: placement)
    }

    public func placementRecommendation() -> SciencePlacementRecommendation {
        SciencePlacementEngine().recommendation(for: placement)
    }

    public mutating func recordPlacement(
        skillID: SkillID,
        outcome: Outcome,
        supportLevel: SupportLevel = .independent,
        easySuccess: Bool = false,
        profile: inout LearnerProfile,
        graph: SkillGraph
    ) {
        let engine = SciencePlacementEngine()
        guard let probe = engine.nextProbe(for: placement), probe.skillID == skillID else { return }
        engine.record(
            SciencePlacementResult(outcome: outcome, supportLevel: supportLevel, easySuccess: easySuccess),
            for: probe,
            in: &placement,
            profile: &profile,
            graph: graph
        )
    }

    @discardableResult
    public mutating func recordEvidence(
        skillID: SkillID,
        mechanicID: String,
        outcome: Outcome,
        supportLevel: SupportLevel = .independent,
        representation: Representation = .concrete,
        easySuccess: Bool = false,
        encounterID: String,
        profile: inout LearnerProfile,
        at date: Date = Date()
    ) -> LearningEvidence {
        let evidence = LearningEvidence(
            encounterID: encounterID,
            skillID: skillID,
            outcome: outcome,
            supportLevel: supportLevel,
            representation: representation,
            mechanicID: mechanicID,
            timestamp: date,
            easySuccess: easySuccess
        )
        MasteryEngine().record(evidence, in: &profile)
        profile.recordActivity(
            ActivityRecord(
                fingerprint: "science|\(encounterID)|\(outcome.rawValue)",
                mechanicID: mechanicID,
                skillID: skillID,
                representation: representation,
                timestamp: date
            )
        )
        return evidence
    }
}
