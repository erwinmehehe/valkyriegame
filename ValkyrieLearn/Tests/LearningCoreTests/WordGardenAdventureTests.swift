import XCTest
@testable import LearningCore

final class WordGardenAdventureTests: XCTestCase {
    func testFlowerGateStartsWithNonAudioVisualIdentity() throws {
        let graph = try LiteracySkillCatalog.graph()
        let profile = LearnerProfile()
        let encounter = WordGardenDirector.nextFlowerGateEncounter(profile: profile)

        XCTAssertEqual(encounter.skillID, LiteracySkills.visualLetterMatch)
        XCTAssertEqual(encounter.mechanicID, WordGardenMechanicID.letterStones)
        XCTAssertFalse(
            LiteracySkillCatalog.descriptor(for: encounter.skillID)?.requiresRecordedAudio ?? true
        )
        XCTAssertFalse(encounter.prompt.contains(encounter.answer))
        XCTAssertFalse(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))
    }

    func testThreeDistinctVisualMatchesWakeFlowerGateAndUnlockSunmill() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
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
            profile.progress(for: LiteracySkills.visualLetterMatch).state,
            .secure
        )
        XCTAssertTrue(WordGardenDirector.flowerGateComplete(profile: profile))
        XCTAssertTrue(WordGardenDirector.canEnterSunmill(profile: profile, graph: graph))

        let sunmill = try XCTUnwrap(
            WordGardenDirector.nextSunmillEncounter(profile: profile, graph: graph)
        )
        XCTAssertEqual(sunmill.skillID, LiteracySkills.visualCasePairing)
        XCTAssertEqual(sunmill.mechanicID, WordGardenMechanicID.sunmillPair)
        XCTAssertEqual(sunmill.context, "sunmillCrossing")
    }

    func testSupportedFlowerGateSuccessDoesNotPretendTheRouteIsSecure() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
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

    func testSunmillCompletesAfterThreeIndependentVisualCasePairs() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
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

        for encounter in WordGardenEncounterCatalog.visualCasePairs {
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
            profile.progress(for: LiteracySkills.visualCasePairing).state,
            .secure
        )
        XCTAssertEqual(
            WordGardenDirector.independentSuccessCount(
                for: WordGardenEncounterCatalog.visualCasePairs,
                profile: profile
            ),
            3
        )
        XCTAssertTrue(WordGardenDirector.sunmillComplete(profile: profile))
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
    }

    func testSpokenLetterNamesAndPhonemesRemainAudioGatedAcrossNativePlaces() throws {
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.uppercaseLetterNames)?.requiresRecordedAudio == true
        )
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.lowercaseLetterNames)?.requiresRecordedAudio == true
        )

        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes {
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

        let flower = WordGardenDirector.nextFlowerGateEncounter(profile: LearnerProfile())
        let sunmill = try XCTUnwrap(
            WordGardenDirector.nextSunmillEncounter(profile: profile, graph: graph)
        )

        XCTAssertFalse(isRecordedAudioSkill(flower.skillID))
        XCTAssertFalse(isRecordedAudioSkill(sunmill.skillID))
        XCTAssertFalse([
            LiteracySkills.uppercaseLetterNames,
            LiteracySkills.lowercaseLetterNames,
            LiteracySkills.sameDifferentSounds,
            LiteracySkills.beginningSoundMatch,
            LiteracySkills.commonConsonantSounds,
            LiteracySkills.shortVowelSounds
        ].contains(sunmill.skillID))
    }

    func testSunmillTargetMapsToUppercasePartnerWithoutChangingSkillMeaning() {
        for encounter in WordGardenEncounterCatalog.visualCasePairs {
            XCTAssertNotNil(WordGardenEncounterCatalog.uppercaseTarget(for: encounter))
            XCTAssertEqual(encounter.skillID, LiteracySkills.visualCasePairing)
        }
    }

    private func isRecordedAudioSkill(_ skill: SkillID) -> Bool {
        LiteracySkillCatalog.descriptor(for: skill)?.requiresRecordedAudio == true
    }
}
