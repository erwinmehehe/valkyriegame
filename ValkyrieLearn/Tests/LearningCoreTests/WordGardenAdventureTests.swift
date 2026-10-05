import XCTest
@testable import LearningCore

final class WordGardenAdventureTests: XCTestCase {
    func testFlowerGateStartsWithNonAudioUppercaseRecognition() throws {
        let graph = try LiteracySkillCatalog.graph()
        let profile = LearnerProfile()
        let encounter = WordGardenDirector.nextFlowerGateEncounter(profile: profile)

        XCTAssertEqual(encounter.skillID, LiteracySkills.uppercaseLetterNames)
        XCTAssertEqual(encounter.mechanicID, WordGardenMechanicID.letterStones)
        XCTAssertNotNil(LiteracySkillCatalog.descriptor(for: encounter.skillID))
        XCTAssertFalse(
            LiteracySkillCatalog.descriptor(for: encounter.skillID)?.requiresRecordedAudio == true
        )
        XCTAssertFalse(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))
    }

    func testThreeDistinctUppercaseSuccessesWakeFlowerGateAndUnlockSunmill() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.uppercaseLetters {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .secure
        )
        XCTAssertTrue(WordGardenDirector.flowerGateComplete(profile: profile))
        XCTAssertTrue(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))

        let sunmill = try XCTUnwrap(
            WordGardenDirector.nextSunmillEncounter(profile: profile, graph: graph)
        )
        XCTAssertEqual(sunmill.skillID, LiteracySkills.lowercaseLetterNames)
        XCTAssertEqual(sunmill.mechanicID, WordGardenMechanicID.sunmillPair)
        XCTAssertEqual(sunmill.context, "sunmillCrossing")
    }

    func testSupportedFlowerGateSuccessDoesNotPretendTheRouteIsSecure() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.uppercaseLetters {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .lightHint,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        XCTAssertFalse(WordGardenDirector.flowerGateComplete(profile: profile))
        XCTAssertFalse(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))
        XCTAssertNil(WordGardenDirector.nextSunmillEncounter(profile: profile, graph: graph))
    }

    func testSunmillCompletesAfterThreeIndependentLowercaseMatches() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.uppercaseLetters {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        for encounter in WordGardenEncounterCatalog.lowercaseLetters {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        XCTAssertEqual(
            profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .secure
        )
        XCTAssertEqual(
            WordGardenDirector.independentSuccessCount(
                for: WordGardenEncounterCatalog.lowercaseLetters,
                profile: profile
            ),
            3
        )
        XCTAssertTrue(WordGardenDirector.sunmillComplete(profile: profile))
        XCTAssertTrue(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))
    }

    func testWordGardenNativePlacesDoNotUsePhonemeTasksWithoutRecordedAudio() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()

        let flower = WordGardenDirector.nextFlowerGateEncounter(profile: profile)
        XCTAssertFalse(isRecordedAudioSkill(flower.skillID))

        var mastery = MasteryEngine()
        for encounter in WordGardenEncounterCatalog.uppercaseLetters {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        let sunmill = try XCTUnwrap(
            WordGardenDirector.nextSunmillEncounter(profile: profile, graph: graph)
        )
        XCTAssertFalse(isRecordedAudioSkill(sunmill.skillID))
    }

    private func isRecordedAudioSkill(_ skill: SkillID) -> Bool {
        LiteracySkillCatalog.descriptor(for: skill)?.requiresRecordedAudio == true
    }
}
