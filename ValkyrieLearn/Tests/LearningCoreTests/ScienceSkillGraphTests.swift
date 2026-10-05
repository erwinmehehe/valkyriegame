import XCTest
@testable import LearningCore

final class ScienceSkillGraphTests: XCTestCase {
    func testScienceCatalogBuildsAcyclicGraphAndContainsEveryDescriptor() throws {
        let graph = try ScienceSkillCatalog.graph()
        XCTAssertEqual(graph.skills.count, ScienceSkillCatalog.descriptors.count)
        XCTAssertEqual(Set(graph.skills.keys), Set(ScienceSkillCatalog.descriptors.map(\.id)))
    }

    func testEverySciencePrerequisiteAppearsEarlierInDevelopmentalOrder() {
        let orderByID = Dictionary(uniqueKeysWithValues: ScienceSkillCatalog.descriptors.map { ($0.id, $0.developmentalOrder) })

        for descriptor in ScienceSkillCatalog.descriptors {
            XCTAssertFalse(descriptor.title.isEmpty)
            XCTAssertFalse(descriptor.representations.isEmpty)
            XCTAssertFalse(descriptor.responseModes.isEmpty)
            XCTAssertFalse(descriptor.mechanicIDs.isEmpty)

            for prerequisite in descriptor.definition.prerequisites {
                guard let prerequisiteOrder = orderByID[prerequisite] else {
                    XCTFail("Missing descriptor for prerequisite \(prerequisite.rawValue)")
                    continue
                }
                XCTAssertLessThan(prerequisiteOrder, descriptor.developmentalOrder)
            }
        }
    }

    func testSciencePlacementProgressesFromObservationToEvidenceReasoning() {
        XCTAssertEqual(SciencePlacement.probes.map(\.band), Array(1...9))
        XCTAssertEqual(SciencePlacement.probes.first?.skillID, ScienceSkills.noticeDetails)
        XCTAssertEqual(SciencePlacement.probes.last?.skillID, ScienceSkills.explainEvidence)
        XCTAssertEqual(Set(SciencePlacement.probes.map(\.id)).count, SciencePlacement.probes.count)
    }

    func testGreenhouseSkillsRequireObservationBeforeDeeperExperiments() throws {
        let graph = try ScienceSkillCatalog.graph()
        XCTAssertEqual(graph.skills[ScienceSkills.plantParts]?.prerequisites, [ScienceSkills.noticeDetails])
        XCTAssertTrue(graph.skills[ScienceSkills.comparePlantConditions]?.prerequisites.contains(ScienceSkills.plantNeeds) == true)
        XCTAssertTrue(graph.skills[ScienceSkills.comparePlantConditions]?.prerequisites.contains(ScienceSkills.predictOutcome) == true)
    }

    func testWeatherAndHabitatSkillsBuildOnComparisonInsteadOfFactRecall() throws {
        let graph = try ScienceSkillCatalog.graph()
        XCTAssertTrue(graph.skills[ScienceSkills.weatherCompare]?.prerequisites.contains(ScienceSkills.sameDifferent) == true)
        XCTAssertTrue(graph.skills[ScienceSkills.habitatMatch]?.prerequisites.contains(ScienceSkills.sameDifferent) == true)
        XCTAssertTrue(graph.skills[ScienceSkills.compareHabitats]?.prerequisites.contains(ScienceSkills.habitatMatch) == true)
    }

    func testEvidenceExplanationIsStretchAndDependsOnEvidencePlusCauseEffect() throws {
        let graph = try ScienceSkillCatalog.graph()
        let stretch = Set(ScienceSkillCatalog.stretchSkills.map(\.id))

        XCTAssertTrue(stretch.contains(ScienceSkills.explainEvidence))
        XCTAssertTrue(stretch.contains(ScienceSkills.fairComparison))
        XCTAssertEqual(
            Set(graph.skills[ScienceSkills.explainEvidence]?.prerequisites ?? []),
            Set([ScienceSkills.evidenceChoice, ScienceSkills.simpleCauseEffect])
        )
    }

    func testScienceUsesAllWorldMechanicFamilies() {
        let used = Set(ScienceSkillCatalog.descriptors.flatMap(\.mechanicIDs))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.seedBench))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.waterChannel))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.sunPrism))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.shadowWall))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.weatherDial))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.materialTable))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.habitatNests))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.causeEffectMachine))
        XCTAssertTrue(used.contains(ScienceLabMechanicID.miloInspect))
    }
}
