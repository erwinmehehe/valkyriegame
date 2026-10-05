import Foundation

public enum ScienceStrand: String, Codable, CaseIterable, Sendable {
    case inquiry
    case plants
    case lightAndShadow
    case waterAndWeather
    case materials
    case animalsAndHabitats
    case causeAndEffect
}

public enum ScienceRepresentation: String, Codable, CaseIterable, Sendable {
    case observation
    case picture
    case object
    case sequence
    case simpleData
    case story
}

public enum ScienceResponseMode: String, Codable, CaseIterable, Sendable {
    case observeAndChoose
    case predict
    case directTouch
    case arrange
    case compare
    case explainChoice
}

public enum ScienceLabMechanicID {
    public static let seedBench = "scienceLab.seedBench"
    public static let waterChannel = "scienceLab.waterChannel"
    public static let sunPrism = "scienceLab.sunPrism"
    public static let shadowWall = "scienceLab.shadowWall"
    public static let weatherDial = "scienceLab.weatherDial"
    public static let materialTable = "scienceLab.materialTable"
    public static let habitatNests = "scienceLab.habitatNests"
    public static let causeEffectMachine = "scienceLab.causeEffectMachine"
    public static let miloInspect = "scienceLab.miloInspect"
}

public struct ScienceSkillDescriptor: Sendable {
    public let definition: SkillDefinition
    public let strand: ScienceStrand
    public let title: String
    public let developmentalOrder: Int
    public let representations: [ScienceRepresentation]
    public let responseModes: [ScienceResponseMode]
    public let mechanicIDs: [String]
    public let isStretch: Bool

    public var id: SkillID { definition.id }

    public init(
        id: SkillID,
        strand: ScienceStrand,
        title: String,
        developmentalOrder: Int,
        prerequisites: [SkillID] = [],
        requiredReadiness: SkillState = .developing,
        representations: [ScienceRepresentation],
        responseModes: [ScienceResponseMode],
        mechanicIDs: [String],
        isStretch: Bool = false
    ) {
        definition = SkillDefinition(id, prerequisites: prerequisites, requiredReadiness: requiredReadiness)
        self.strand = strand
        self.title = title
        self.developmentalOrder = developmentalOrder
        self.representations = representations
        self.responseModes = responseModes
        self.mechanicIDs = mechanicIDs
        self.isStretch = isStretch
    }
}

public enum ScienceSkills {
    public static let noticeDetails = SkillID(rawValue: "science.inquiry.noticeDetails")
    public static let sameDifferent = SkillID(rawValue: "science.inquiry.sameDifferent")
    public static let predictOutcome = SkillID(rawValue: "science.inquiry.predictOutcome")
    public static let orderEvents = SkillID(rawValue: "science.inquiry.orderEvents")
    public static let evidenceChoice = SkillID(rawValue: "science.inquiry.evidenceChoice")

    public static let plantParts = SkillID(rawValue: "science.plants.parts")
    public static let plantNeeds = SkillID(rawValue: "science.plants.needs")
    public static let seedToPlant = SkillID(rawValue: "science.plants.seedToPlant")
    public static let comparePlantConditions = SkillID(rawValue: "science.plants.compareConditions")
    public static let pollination = SkillID(rawValue: "science.plants.pollination")

    public static let lightSource = SkillID(rawValue: "science.light.source")
    public static let shadowCause = SkillID(rawValue: "science.light.shadowCause")
    public static let shadowChange = SkillID(rawValue: "science.light.shadowChange")
    public static let transparentOpaque = SkillID(rawValue: "science.light.transparentOpaque")

    public static let waterStatesEveryday = SkillID(rawValue: "science.water.everydayStates")
    public static let waterMovement = SkillID(rawValue: "science.water.movement")
    public static let weatherObserve = SkillID(rawValue: "science.weather.observe")
    public static let weatherCompare = SkillID(rawValue: "science.weather.compare")
    public static let weatherPattern = SkillID(rawValue: "science.weather.pattern")

    public static let materialProperties = SkillID(rawValue: "science.materials.properties")
    public static let sortMaterials = SkillID(rawValue: "science.materials.sort")
    public static let materialUse = SkillID(rawValue: "science.materials.use")
    public static let testAbsorbency = SkillID(rawValue: "science.materials.absorbency")

    public static let animalNeeds = SkillID(rawValue: "science.animals.needs")
    public static let habitatMatch = SkillID(rawValue: "science.animals.habitatMatch")
    public static let bodyPartFunction = SkillID(rawValue: "science.animals.bodyPartFunction")
    public static let compareHabitats = SkillID(rawValue: "science.animals.compareHabitats")

    public static let simpleCauseEffect = SkillID(rawValue: "science.causeEffect.simple")
    public static let fairComparison = SkillID(rawValue: "science.causeEffect.fairComparison")
    public static let explainEvidence = SkillID(rawValue: "science.causeEffect.explainEvidence")
    public static let transferPrediction = SkillID(rawValue: "science.causeEffect.transferPrediction")
}

public enum ScienceSkillCatalog {
    public static let descriptors: [ScienceSkillDescriptor] = [
        .init(id: ScienceSkills.noticeDetails, strand: .inquiry, title: "Notice Important Details", developmentalOrder: 1,
              representations: [.observation, .picture], responseModes: [.observeAndChoose, .directTouch],
              mechanicIDs: [ScienceLabMechanicID.miloInspect]),
        .init(id: ScienceSkills.sameDifferent, strand: .inquiry, title: "Compare What Is the Same and Different", developmentalOrder: 2,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.observation, .object],
              responseModes: [.compare, .observeAndChoose], mechanicIDs: [ScienceLabMechanicID.miloInspect, ScienceLabMechanicID.materialTable]),
        .init(id: ScienceSkills.predictOutcome, strand: .inquiry, title: "Make a Prediction Before a Test", developmentalOrder: 3,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.object, .story],
              responseModes: [.predict, .explainChoice], mechanicIDs: [ScienceLabMechanicID.causeEffectMachine]),
        .init(id: ScienceSkills.orderEvents, strand: .inquiry, title: "Put Observed Events in Order", developmentalOrder: 4,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.sequence, .picture],
              responseModes: [.arrange, .observeAndChoose], mechanicIDs: [ScienceLabMechanicID.seedBench, ScienceLabMechanicID.weatherDial]),
        .init(id: ScienceSkills.evidenceChoice, strand: .inquiry, title: "Choose Evidence That Supports an Observation", developmentalOrder: 5,
              prerequisites: [ScienceSkills.sameDifferent, ScienceSkills.predictOutcome], representations: [.observation, .simpleData],
              responseModes: [.observeAndChoose, .explainChoice], mechanicIDs: [ScienceLabMechanicID.miloInspect], isStretch: true),

        .init(id: ScienceSkills.plantParts, strand: .plants, title: "Recognize Major Plant Parts", developmentalOrder: 6,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.object, .picture],
              responseModes: [.directTouch, .observeAndChoose], mechanicIDs: [ScienceLabMechanicID.seedBench]),
        .init(id: ScienceSkills.plantNeeds, strand: .plants, title: "Identify What Plants Need to Grow", developmentalOrder: 7,
              prerequisites: [ScienceSkills.plantParts], representations: [.object, .picture],
              responseModes: [.observeAndChoose, .predict], mechanicIDs: [ScienceLabMechanicID.seedBench, ScienceLabMechanicID.waterChannel, ScienceLabMechanicID.sunPrism]),
        .init(id: ScienceSkills.seedToPlant, strand: .plants, title: "Sequence Seed to Young Plant", developmentalOrder: 8,
              prerequisites: [ScienceSkills.orderEvents, ScienceSkills.plantParts], representations: [.sequence, .picture],
              responseModes: [.arrange], mechanicIDs: [ScienceLabMechanicID.seedBench]),
        .init(id: ScienceSkills.comparePlantConditions, strand: .plants, title: "Compare Plant Growth Conditions", developmentalOrder: 9,
              prerequisites: [ScienceSkills.plantNeeds, ScienceSkills.predictOutcome], representations: [.observation, .simpleData],
              responseModes: [.predict, .compare], mechanicIDs: [ScienceLabMechanicID.seedBench, ScienceLabMechanicID.waterChannel, ScienceLabMechanicID.sunPrism]),
        .init(id: ScienceSkills.pollination, strand: .plants, title: "Connect Flowers, Pollinators, and Seed Production", developmentalOrder: 10,
              prerequisites: [ScienceSkills.plantParts, ScienceSkills.orderEvents], representations: [.sequence, .story],
              responseModes: [.arrange, .explainChoice], mechanicIDs: [ScienceLabMechanicID.seedBench, ScienceLabMechanicID.habitatNests]),

        .init(id: ScienceSkills.lightSource, strand: .lightAndShadow, title: "Identify a Light Source", developmentalOrder: 11,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.observation, .object],
              responseModes: [.observeAndChoose], mechanicIDs: [ScienceLabMechanicID.sunPrism]),
        .init(id: ScienceSkills.shadowCause, strand: .lightAndShadow, title: "Connect Blocking Light with a Shadow", developmentalOrder: 12,
              prerequisites: [ScienceSkills.lightSource, ScienceSkills.predictOutcome], representations: [.observation, .object],
              responseModes: [.predict, .directTouch], mechanicIDs: [ScienceLabMechanicID.shadowWall, ScienceLabMechanicID.sunPrism]),
        .init(id: ScienceSkills.shadowChange, strand: .lightAndShadow, title: "Predict How Moving Light Changes a Shadow", developmentalOrder: 13,
              prerequisites: [ScienceSkills.shadowCause], representations: [.observation, .sequence],
              responseModes: [.predict, .compare], mechanicIDs: [ScienceLabMechanicID.shadowWall, ScienceLabMechanicID.sunPrism]),
        .init(id: ScienceSkills.transparentOpaque, strand: .lightAndShadow, title: "Compare Materials That Pass or Block Light", developmentalOrder: 14,
              prerequisites: [ScienceSkills.sameDifferent, ScienceSkills.lightSource], representations: [.object, .observation],
              responseModes: [.compare, .directTouch], mechanicIDs: [ScienceLabMechanicID.materialTable, ScienceLabMechanicID.sunPrism]),

        .init(id: ScienceSkills.waterStatesEveryday, strand: .waterAndWeather, title: "Recognize Everyday Forms of Water", developmentalOrder: 15,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.picture, .observation],
              responseModes: [.observeAndChoose], mechanicIDs: [ScienceLabMechanicID.waterChannel]),
        .init(id: ScienceSkills.waterMovement, strand: .waterAndWeather, title: "Predict How Water Moves Downhill", developmentalOrder: 16,
              prerequisites: [ScienceSkills.predictOutcome], representations: [.object, .observation],
              responseModes: [.predict, .directTouch], mechanicIDs: [ScienceLabMechanicID.waterChannel]),
        .init(id: ScienceSkills.weatherObserve, strand: .waterAndWeather, title: "Observe Basic Weather Conditions", developmentalOrder: 17,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.observation, .picture],
              responseModes: [.observeAndChoose], mechanicIDs: [ScienceLabMechanicID.weatherDial, ScienceLabMechanicID.miloInspect]),
        .init(id: ScienceSkills.weatherCompare, strand: .waterAndWeather, title: "Compare Weather Across Two Observations", developmentalOrder: 18,
              prerequisites: [ScienceSkills.weatherObserve, ScienceSkills.sameDifferent], representations: [.simpleData, .observation],
              responseModes: [.compare], mechanicIDs: [ScienceLabMechanicID.weatherDial]),
        .init(id: ScienceSkills.weatherPattern, strand: .waterAndWeather, title: "Notice a Simple Weather Pattern", developmentalOrder: 19,
              prerequisites: [ScienceSkills.weatherCompare, ScienceSkills.orderEvents], representations: [.simpleData, .sequence],
              responseModes: [.arrange, .predict], mechanicIDs: [ScienceLabMechanicID.weatherDial], isStretch: true),

        .init(id: ScienceSkills.materialProperties, strand: .materials, title: "Describe Observable Material Properties", developmentalOrder: 20,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.object, .observation],
              responseModes: [.observeAndChoose, .compare], mechanicIDs: [ScienceLabMechanicID.materialTable]),
        .init(id: ScienceSkills.sortMaterials, strand: .materials, title: "Sort Materials by an Observable Property", developmentalOrder: 21,
              prerequisites: [ScienceSkills.materialProperties, ScienceSkills.sameDifferent], representations: [.object],
              responseModes: [.arrange, .compare], mechanicIDs: [ScienceLabMechanicID.materialTable]),
        .init(id: ScienceSkills.materialUse, strand: .materials, title: "Match a Material Property to a Useful Purpose", developmentalOrder: 22,
              prerequisites: [ScienceSkills.materialProperties], representations: [.object, .story],
              responseModes: [.explainChoice, .observeAndChoose], mechanicIDs: [ScienceLabMechanicID.materialTable]),
        .init(id: ScienceSkills.testAbsorbency, strand: .materials, title: "Compare Which Material Absorbs More Water", developmentalOrder: 23,
              prerequisites: [ScienceSkills.predictOutcome, ScienceSkills.materialProperties], representations: [.object, .simpleData],
              responseModes: [.predict, .compare], mechanicIDs: [ScienceLabMechanicID.materialTable, ScienceLabMechanicID.waterChannel]),

        .init(id: ScienceSkills.animalNeeds, strand: .animalsAndHabitats, title: "Identify Basic Animal Needs", developmentalOrder: 24,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.picture, .story],
              responseModes: [.observeAndChoose], mechanicIDs: [ScienceLabMechanicID.habitatNests]),
        .init(id: ScienceSkills.habitatMatch, strand: .animalsAndHabitats, title: "Match an Animal to a Suitable Habitat", developmentalOrder: 25,
              prerequisites: [ScienceSkills.animalNeeds, ScienceSkills.sameDifferent], representations: [.picture, .object],
              responseModes: [.arrange, .explainChoice], mechanicIDs: [ScienceLabMechanicID.habitatNests]),
        .init(id: ScienceSkills.bodyPartFunction, strand: .animalsAndHabitats, title: "Connect an Animal Body Part with Its Function", developmentalOrder: 26,
              prerequisites: [ScienceSkills.noticeDetails], representations: [.picture, .story],
              responseModes: [.observeAndChoose, .explainChoice], mechanicIDs: [ScienceLabMechanicID.miloInspect, ScienceLabMechanicID.habitatNests]),
        .init(id: ScienceSkills.compareHabitats, strand: .animalsAndHabitats, title: "Compare Two Habitats and Their Resources", developmentalOrder: 27,
              prerequisites: [ScienceSkills.habitatMatch, ScienceSkills.sameDifferent], representations: [.picture, .simpleData],
              responseModes: [.compare, .explainChoice], mechanicIDs: [ScienceLabMechanicID.habitatNests], isStretch: true),

        .init(id: ScienceSkills.simpleCauseEffect, strand: .causeAndEffect, title: "Identify a Simple Cause and Effect", developmentalOrder: 28,
              prerequisites: [ScienceSkills.orderEvents, ScienceSkills.predictOutcome], representations: [.sequence, .story],
              responseModes: [.arrange, .explainChoice], mechanicIDs: [ScienceLabMechanicID.causeEffectMachine]),
        .init(id: ScienceSkills.fairComparison, strand: .causeAndEffect, title: "Change One Thing in a Simple Comparison", developmentalOrder: 29,
              prerequisites: [ScienceSkills.comparePlantConditions, ScienceSkills.testAbsorbency], representations: [.object, .simpleData],
              responseModes: [.predict, .compare], mechanicIDs: [ScienceLabMechanicID.causeEffectMachine], isStretch: true),
        .init(id: ScienceSkills.explainEvidence, strand: .causeAndEffect, title: "Use an Observation to Explain an Outcome", developmentalOrder: 30,
              prerequisites: [ScienceSkills.evidenceChoice, ScienceSkills.simpleCauseEffect], representations: [.observation, .simpleData],
              responseModes: [.explainChoice], mechanicIDs: [ScienceLabMechanicID.miloInspect, ScienceLabMechanicID.causeEffectMachine], isStretch: true),
        .init(id: ScienceSkills.transferPrediction, strand: .causeAndEffect, title: "Apply a Cause-and-Effect Pattern to a New Situation", developmentalOrder: 31,
              prerequisites: [ScienceSkills.explainEvidence], representations: [.story, .object],
              responseModes: [.predict, .explainChoice], mechanicIDs: [ScienceLabMechanicID.causeEffectMachine], isStretch: true)
    ]

    public static func descriptor(for id: SkillID) -> ScienceSkillDescriptor? {
        descriptors.first { $0.id == id }
    }

    public static func graph() throws -> SkillGraph {
        try SkillGraph(descriptors.map(\.definition))
    }

    public static var stretchSkills: [ScienceSkillDescriptor] {
        descriptors.filter(\.isStretch)
    }
}

public struct SciencePlacementProbe: Identifiable, Equatable, Sendable {
    public let id: String
    public let band: Int
    public let skillID: SkillID
    public let responseMode: ScienceResponseMode
    public let mechanicID: String
    public let promptIntent: String

    public init(id: String, band: Int, skillID: SkillID, responseMode: ScienceResponseMode, mechanicID: String, promptIntent: String) {
        self.id = id
        self.band = max(0, band)
        self.skillID = skillID
        self.responseMode = responseMode
        self.mechanicID = mechanicID
        self.promptIntent = promptIntent
    }
}

public enum SciencePlacement {
    public static let probes: [SciencePlacementProbe] = [
        .init(id: "science-place-observe", band: 1, skillID: ScienceSkills.noticeDetails,
              responseMode: .observeAndChoose, mechanicID: ScienceLabMechanicID.miloInspect,
              promptIntent: "Notice the changed detail in Milo's observation."),
        .init(id: "science-place-predict", band: 2, skillID: ScienceSkills.predictOutcome,
              responseMode: .predict, mechanicID: ScienceLabMechanicID.causeEffectMachine,
              promptIntent: "Predict what will happen before activating the mechanism."),
        .init(id: "science-place-plant-needs", band: 3, skillID: ScienceSkills.plantNeeds,
              responseMode: .observeAndChoose, mechanicID: ScienceLabMechanicID.seedBench,
              promptIntent: "Choose what this plant needs next."),
        .init(id: "science-place-shadow", band: 4, skillID: ScienceSkills.shadowCause,
              responseMode: .predict, mechanicID: ScienceLabMechanicID.shadowWall,
              promptIntent: "Predict where a shadow appears when light is blocked."),
        .init(id: "science-place-weather", band: 5, skillID: ScienceSkills.weatherCompare,
              responseMode: .compare, mechanicID: ScienceLabMechanicID.weatherDial,
              promptIntent: "Compare two weather observations."),
        .init(id: "science-place-material", band: 6, skillID: ScienceSkills.testAbsorbency,
              responseMode: .predict, mechanicID: ScienceLabMechanicID.materialTable,
              promptIntent: "Predict and compare which material absorbs more water."),
        .init(id: "science-place-habitat", band: 7, skillID: ScienceSkills.habitatMatch,
              responseMode: .explainChoice, mechanicID: ScienceLabMechanicID.habitatNests,
              promptIntent: "Choose a suitable habitat and explain the evidence."),
        .init(id: "science-place-cause", band: 8, skillID: ScienceSkills.simpleCauseEffect,
              responseMode: .arrange, mechanicID: ScienceLabMechanicID.causeEffectMachine,
              promptIntent: "Restore a cause-and-effect sequence."),
        .init(id: "science-place-evidence", band: 9, skillID: ScienceSkills.explainEvidence,
              responseMode: .explainChoice, mechanicID: ScienceLabMechanicID.miloInspect,
              promptIntent: "Choose the observation that best explains the outcome.")
    ]
}


public struct SciencePlacementResult: Equatable, Sendable {
    public let outcome: Outcome
    public let supportLevel: SupportLevel
    public let easySuccess: Bool

    public init(outcome: Outcome, supportLevel: SupportLevel = .independent, easySuccess: Bool = false) {
        self.outcome = outcome
        self.supportLevel = supportLevel
        self.easySuccess = easySuccess
    }
}

public enum SciencePlacementResponse: Equatable, Sendable {
    case independentSuccess
    case supportedSuccess
    case struggle

    public init(_ result: SciencePlacementResult) {
        if result.outcome == .correct && result.supportLevel == .independent {
            self = .independentSuccess
        } else if result.outcome == .correct {
            self = .supportedSuccess
        } else {
            self = .struggle
        }
    }
}

public struct SciencePlacementSession: Codable, Equatable, Sendable {
    public fileprivate(set) var nextBand: Int
    public fileprivate(set) var attemptedProbeIDs: Set<String>
    public fileprivate(set) var highestIndependentBand: Int?
    public fileprivate(set) var firstSupportNeededBand: Int?
    public fileprivate(set) var completedProbeCount: Int
    public fileprivate(set) var isComplete: Bool

    public init(startBand: Int = 3) {
        nextBand = max(0, startBand)
        attemptedProbeIDs = []
        highestIndependentBand = nil
        firstSupportNeededBand = nil
        completedProbeCount = 0
        isComplete = false
    }
}

public struct SciencePlacementRecommendation: Equatable, Sendable {
    public let suggestedBand: Int
    public let suggestedSkillID: SkillID?
    public let confidence: PlacementConfidence
    public let highestIndependentBand: Int?
    public let firstSupportNeededBand: Int?
}

public struct SciencePlacementEngine: Sendable {
    public let probes: [SciencePlacementProbe]
    public let maxProbes: Int
    private let minBand: Int
    private let maxBand: Int

    public init(probes: [SciencePlacementProbe] = SciencePlacement.probes, maxProbes: Int = 6) {
        self.probes = probes.sorted {
            $0.band == $1.band ? $0.id < $1.id : $0.band < $1.band
        }
        self.maxProbes = max(1, maxProbes)
        minBand = self.probes.map(\.band).min() ?? 0
        maxBand = self.probes.map(\.band).max() ?? 0
    }

    public func begin(startBand: Int = 3) -> SciencePlacementSession {
        SciencePlacementSession(startBand: clamped(startBand))
    }

    public func nextProbe(for session: SciencePlacementSession) -> SciencePlacementProbe? {
        guard !session.isComplete else { return nil }
        let remaining = probes.filter { !session.attemptedProbeIDs.contains($0.id) }
        guard !remaining.isEmpty else { return nil }
        let desired = clamped(session.nextBand)
        return remaining.min {
            let ld = abs($0.band - desired)
            let rd = abs($1.band - desired)
            return ld == rd ? $0.band < $1.band : ld < rd
        }
    }

    public func record(
        _ result: SciencePlacementResult,
        for probe: SciencePlacementProbe,
        in session: inout SciencePlacementSession,
        profile: inout LearnerProfile,
        graph: SkillGraph
    ) {
        guard !session.isComplete,
              !session.attemptedProbeIDs.contains(probe.id),
              probes.contains(where: { $0.id == probe.id && $0.skillID == probe.skillID }) else {
            return
        }

        session.attemptedProbeIDs.insert(probe.id)
        session.completedProbeCount += 1

        switch SciencePlacementResponse(result) {
        case .independentSuccess:
            session.highestIndependentBand = max(session.highestIndependentBand ?? probe.band, probe.band)
            session.nextBand = probe.band + (result.easySuccess ? 2 : 1)
            profile.markPlacementReady(graph.prerequisiteClosure(including: probe.skillID))
        case .supportedSuccess, .struggle:
            session.firstSupportNeededBand = min(session.firstSupportNeededBand ?? probe.band, probe.band)
            session.nextBand = probe.band - 1
        }

        session.nextBand = clamped(session.nextBand)
        session.isComplete = shouldComplete(session)
    }

    public func recommendation(for session: SciencePlacementSession) -> SciencePlacementRecommendation {
        let band: Int
        if let support = session.firstSupportNeededBand {
            band = clamped(support)
        } else if let independent = session.highestIndependentBand {
            band = clamped(independent + 1)
        } else {
            band = minBand
        }

        let skill = probes.min {
            let ld = abs($0.band - band)
            let rd = abs($1.band - band)
            return ld == rd ? $0.band < $1.band : ld < rd
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

        return SciencePlacementRecommendation(
            suggestedBand: band,
            suggestedSkillID: skill,
            confidence: confidence,
            highestIndependentBand: session.highestIndependentBand,
            firstSupportNeededBand: session.firstSupportNeededBand
        )
    }

    private func shouldComplete(_ session: SciencePlacementSession) -> Bool {
        if session.completedProbeCount >= maxProbes { return true }
        if session.highestIndependentBand == maxBand { return true }
        if let high = session.highestIndependentBand,
           let support = session.firstSupportNeededBand,
           support <= high + 1,
           session.completedProbeCount >= 2 {
            return true
        }
        return session.attemptedProbeIDs.count >= probes.count
    }

    private func clamped(_ band: Int) -> Int {
        min(max(band, minBand), maxBand)
    }
}
