import Foundation

/// Free-play science experiment: a lamp and real cutout props cast a
/// changing shadow. It has no quiz answers or academic mastery evidence.
public enum MiloShadowProp: Int, CaseIterable, Codable, Hashable, Sendable {
    case leaf, gear, star
}

public enum MiloShadowHeight: String, CaseIterable, Codable, Hashable, Sendable {
    case high, low
}

public enum MiloShadowDirection: String, Equatable, Sendable {
    case left, middle, right
}

public struct MiloShadowProjection: Equatable, Sendable {
    public let horizontalOffset: Double
    public let scale: Double
    public let direction: MiloShadowDirection
}

public struct MiloShadowTrial: Codable, Hashable, Sendable {
    public let prop: MiloShadowProp
    public let height: MiloShadowHeight
    public let lampNotch: Int

    public init(prop: MiloShadowProp, height: MiloShadowHeight, lampNotch: Int) {
        self.prop = prop
        self.height = height
        self.lampNotch = lampNotch
    }
}

/// Stored on the learner profile, with no learning evidence recorded.
/// Testing different silhouettes at different lamp heights reveals a hidden
/// glowing moth. Subsequent movement and tests remain completely replayable.
public struct MiloShadowWorkshop: Codable, Equatable, Sendable {
    public private(set) var explored = false
    public private(set) var prop: MiloShadowProp = .leaf
    public private(set) var height: MiloShadowHeight = .high
    public private(set) var lampNotch = 2
    public private(set) var observations: Set<MiloShadowTrial> = []

    public init() {}

    @discardableResult
    public mutating func explore() -> Bool {
        guard !explored else { return false }
        explored = true
        return true
    }

    @discardableResult
    public mutating func choose(_ newProp: MiloShadowProp) -> Bool {
        guard explored, prop != newProp else { return false }
        prop = newProp
        return true
    }

    @discardableResult
    public mutating func moveLamp(to notch: Int) -> Bool {
        guard explored, (0...4).contains(notch), lampNotch != notch else { return false }
        lampNotch = notch
        return true
    }

    @discardableResult
    public mutating func setHeight(_ newHeight: MiloShadowHeight) -> Bool {
        guard explored, height != newHeight else { return false }
        height = newHeight
        return true
    }

    /// Moving the source changes the *opposite* side of the cast shadow.
    /// Lowering the source makes it larger, making the cause/effect visible.
    public var projection: MiloShadowProjection {
        let offset = Double(2 - lampNotch) * 44
        let base = height == .low ? 1.42 : 0.77
        let scale = base + Double(abs(lampNotch - 2)) * 0.055
        let direction: MiloShadowDirection = lampNotch < 2 ? .right :
            lampNotch > 2 ? .left : .middle
        return MiloShadowProjection(horizontalOffset: offset, scale: scale,
                                    direction: direction)
    }

    @discardableResult
    public mutating func observe() -> Bool {
        guard explored else { return false }
        return observations.insert(
            MiloShadowTrial(prop: prop, height: height, lampNotch: lampNotch)
        ).inserted
    }

    public var hasFoundMoth: Bool {
        Set(observations.map(\.height)).count == MiloShadowHeight.allCases.count
            && Set(observations.map(\.prop)).count >= 2
    }
}

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


public enum ScienceFieldStudyWorld: String, Codable, CaseIterable, Sendable {
    case greenhouse
    case weatherTower
    case creatureGrove
}

public struct ScienceFieldStudyChallenge: Equatable, Sendable {
    public let id: String
    public let world: ScienceFieldStudyWorld
    public let skillID: SkillID
    public let mechanicID: String
    public let representation: Representation
    public let prompt: String
    public let answerTarget: String
    public let choiceTargets: [String]

    public init(
        id: String,
        world: ScienceFieldStudyWorld,
        skillID: SkillID,
        mechanicID: String,
        representation: Representation = .reasoning,
        prompt: String,
        answerTarget: String,
        choiceTargets: [String]
    ) {
        self.id = id
        self.world = world
        self.skillID = skillID
        self.mechanicID = mechanicID
        self.representation = representation
        self.prompt = prompt
        self.answerTarget = answerTarget
        self.choiceTargets = choiceTargets
    }
}

/// Authored retention/transfer work that reuses each room's physical stations.
/// Fresh playthroughs complete these after the room's main investigation; old
/// saves that already carry a completion flag remain grandfathered.
public enum ScienceFieldStudyCatalog {
    public static let greenhouse: [ScienceFieldStudyChallenge] = [
        .init(
            id: "science-field-greenhouse-first-evidence",
            world: .greenhouse,
            skillID: ScienceSkills.orderEvents,
            mechanicID: ScienceLabMechanicID.seedBench,
            prompt: "Field study: where did we collect our first plant evidence?",
            answerTarget: "scienceSeedBench",
            choiceTargets: ["scienceSeedBench", "scienceWaterValve", "scienceSunPrism"]
        ),
        .init(
            id: "science-field-greenhouse-dry-soil",
            world: .greenhouse,
            skillID: ScienceSkills.plantNeeds,
            mechanicID: ScienceLabMechanicID.waterChannel,
            prompt: "The soil was dry. Which station tested the change it needed?",
            answerTarget: "scienceWaterValve",
            choiceTargets: ["scienceSeedBench", "scienceWaterValve", "scienceSunPrism"]
        ),
        .init(
            id: "science-field-greenhouse-pale-sprout",
            world: .greenhouse,
            skillID: ScienceSkills.comparePlantConditions,
            mechanicID: ScienceLabMechanicID.sunPrism,
            prompt: "The sprout was pale after watering. Which station changed its light?",
            answerTarget: "scienceSunPrism",
            choiceTargets: ["scienceSeedBench", "scienceWaterValve", "scienceSunPrism"]
        )
    ]

    public static let weatherTower: [ScienceFieldStudyChallenge] = [
        .init(
            id: "science-field-weather-first-observation",
            world: .weatherTower,
            skillID: ScienceSkills.orderEvents,
            mechanicID: ScienceLabMechanicID.weatherDial,
            prompt: "Field study: which weather flag did we observe first?",
            answerTarget: "scienceMorningWeather",
            choiceTargets: ["scienceMorningWeather", "scienceAfternoonWeather"]
        ),
        .init(
            id: "science-field-weather-repeated-clue",
            world: .weatherTower,
            skillID: ScienceSkills.weatherPattern,
            mechanicID: ScienceLabMechanicID.weatherDial,
            prompt: "Both flags repeated the umbrella clue. Which forecast matches that pattern?",
            answerTarget: "scienceForecastRain",
            choiceTargets: ["scienceForecastSun", "scienceForecastRain"]
        )
    ]

    public static let creatureGrove: [ScienceFieldStudyChallenge] = [
        .init(
            id: "science-field-grove-resources",
            world: .creatureGrove,
            skillID: ScienceSkills.habitatMatch,
            mechanicID: ScienceLabMechanicID.habitatNests,
            prompt: "Field study: which habitat kept water and protective cover together?",
            answerTarget: "scienceHabitatPond",
            choiceTargets: ["scienceHabitatPond", "scienceHabitatRidge"]
        ),
        .init(
            id: "science-field-grove-swimming-body-part",
            world: .creatureGrove,
            skillID: ScienceSkills.bodyPartFunction,
            mechanicID: ScienceLabMechanicID.miloInspect,
            prompt: "Which station showed the body part that helps the duck push against water?",
            answerTarget: "scienceWebbedFeet",
            choiceTargets: ["scienceGroveDuck", "scienceWebbedFeet"]
        ),
        .init(
            id: "science-field-grove-final-evidence",
            world: .creatureGrove,
            skillID: ScienceSkills.compareHabitats,
            mechanicID: ScienceLabMechanicID.habitatNests,
            prompt: "Which side of the comparison board kept both water and shelter?",
            answerTarget: "scienceCompareShelteredPond",
            choiceTargets: ["scienceCompareShelteredPond", "scienceCompareExposedRidge"]
        )
    ]

    public static var all: [ScienceFieldStudyChallenge] {
        greenhouse + weatherTower + creatureGrove
    }

    public static func challenges(for world: ScienceFieldStudyWorld) -> [ScienceFieldStudyChallenge] {
        switch world {
        case .greenhouse: greenhouse
        case .weatherTower: weatherTower
        case .creatureGrove: creatureGrove
        }
    }

    public static func isComplete(
        _ challenge: ScienceFieldStudyChallenge,
        in profile: LearnerProfile
    ) -> Bool {
        profile.progress(for: challenge.skillID).evidence.contains {
            $0.encounterID == challenge.id && $0.outcome == .correct
        }
    }

    public static func next(
        in world: ScienceFieldStudyWorld,
        profile: LearnerProfile
    ) -> ScienceFieldStudyChallenge? {
        challenges(for: world).first { !isComplete($0, in: profile) }
    }

    public static func completedCount(
        in world: ScienceFieldStudyWorld,
        profile: LearnerProfile
    ) -> Int {
        challenges(for: world).filter { isComplete($0, in: profile) }.count
    }

    public static func isComplete(
        _ world: ScienceFieldStudyWorld,
        in profile: LearnerProfile
    ) -> Bool {
        next(in: world, profile: profile) == nil
    }
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
