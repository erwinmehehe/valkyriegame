import XCTest
@testable import LearningCore

final class ScienceAdventureTests: XCTestCase {
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
