import XCTest
@testable import LearningCore

final class ScienceAdventureTests: XCTestCase {

    func testScienceFieldStudyCatalogAddsEightDistinctPhysicalChallenges() {
        let all = ScienceFieldStudyCatalog.all

        XCTAssertEqual(ScienceFieldStudyCatalog.greenhouse.count, 3)
        XCTAssertEqual(ScienceFieldStudyCatalog.weatherTower.count, 2)
        XCTAssertEqual(ScienceFieldStudyCatalog.creatureGrove.count, 3)
        XCTAssertEqual(all.count, 8)
        XCTAssertEqual(Set(all.map(\.id)).count, 8)

        for challenge in all {
            XCTAssertTrue(challenge.choiceTargets.contains(challenge.answerTarget))
            XCTAssertGreaterThanOrEqual(challenge.choiceTargets.count, 2)
            XCTAssertEqual(
                Set(challenge.choiceTargets).count,
                challenge.choiceTargets.count,
                "Each physical choice target should appear once."
            )
            XCTAssertNotNil(ScienceSkillCatalog.descriptor(for: challenge.skillID))
        }
    }

    func testFieldStudyAdvancesOnlyAfterCorrectEvidence() {
        var profile = LearnerProfile()
        var science = ScienceAdventure()
        let first = ScienceFieldStudyCatalog.greenhouse[0]

        XCTAssertEqual(
            ScienceFieldStudyCatalog.next(in: .greenhouse, profile: profile)?.id,
            first.id
        )

        science.recordEvidence(
            skillID: first.skillID,
            mechanicID: first.mechanicID,
            outcome: .incorrect,
            representation: first.representation,
            encounterID: first.id,
            profile: &profile
        )
        XCTAssertEqual(
            ScienceFieldStudyCatalog.next(in: .greenhouse, profile: profile)?.id,
            first.id
        )

        science.recordEvidence(
            skillID: first.skillID,
            mechanicID: first.mechanicID,
            outcome: .correct,
            representation: first.representation,
            encounterID: first.id,
            profile: &profile
        )
        XCTAssertEqual(
            ScienceFieldStudyCatalog.completedCount(in: .greenhouse, profile: profile),
            1
        )
        XCTAssertEqual(
            ScienceFieldStudyCatalog.next(in: .greenhouse, profile: profile)?.id,
            ScienceFieldStudyCatalog.greenhouse[1].id
        )
    }

    func testScienceAdventureRoundTripsInsideLearnerProfile() throws {
        var profile = LearnerProfile()
        var science = ScienceAdventure()
        science.greenhouseStage = .lit
        science.greenhouseComplete = true
        science.weatherStage = .afternoonObserved
        science.selectedForecast = .rain
        science.groveStage = .bodyPartObserved
        science.selectedHabitat = .pondEdge
        profile.scienceAdventure = science

        let data = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(LearnerProfile.self, from: data)

        XCTAssertEqual(decoded.scienceAdventure, science)
    }

    func testPlacementReadinessDoesNotBecomeMastery() throws {
        let graph = try ScienceSkillCatalog.graph()
        var profile = LearnerProfile()
        var science = ScienceAdventure(startBand: 3)

        science.recordPlacement(
            skillID: ScienceSkills.plantNeeds,
            outcome: .correct,
            easySuccess: true,
            profile: &profile,
            graph: graph
        )

        XCTAssertTrue(profile.placementReadySkillIDs?.contains(ScienceSkills.plantNeeds) == true)
        XCTAssertEqual(profile.progress(for: ScienceSkills.plantNeeds).state, .new)
        XCTAssertEqual(science.placement.nextBand, 5)
    }

    func testGameplayEvidenceUsesMasteryEngineSeparatelyFromPlacement() {
        var profile = LearnerProfile()
        var science = ScienceAdventure()

        science.recordEvidence(
            skillID: ScienceSkills.noticeDetails,
            mechanicID: ScienceLabMechanicID.miloInspect,
            outcome: .correct,
            encounterID: "science-greenhouse-inspect",
            profile: &profile
        )

        XCTAssertEqual(profile.progress(for: ScienceSkills.noticeDetails).state, .learning)
        XCTAssertEqual(profile.progress(for: ScienceSkills.noticeDetails).evidence.count, 1)
        XCTAssertEqual(science.greenhouseStage, .arrive)
    }
}
