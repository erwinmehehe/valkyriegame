import XCTest
@testable import LearningCore

final class WordGardenAdventureTests: XCTestCase {
    func testFlowerGateStartsWithNonAudioVisualLetterMatching() throws {
        let graph = try LiteracySkillCatalog.graph()
        let encounter = WordGardenDirector.nextEncounter(
            profile: LearnerProfile(),
            graph: graph
        )

        XCTAssertEqual(encounter.skillID, LiteracySkills.visualLetterMatch)
        XCTAssertEqual(encounter.mechanicID, WordGardenMechanicID.letterStones)
        XCTAssertFalse(
            LiteracySkillCatalog.descriptor(for: encounter.skillID)?.requiresRecordedAudio ?? true
        )
        XCTAssertFalse(encounter.prompt.contains(encounter.answer))
    }

    func testThreeDistinctVisualMatchesSecureOnlyVisualPrintIdentity() throws {
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
        XCTAssertTrue(
            graph.isEligible(LiteracySkills.uppercaseLetterNames, for: profile)
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new,
            "Visual shape matching must not manufacture spoken letter-name mastery."
        )
        XCTAssertEqual(
            WordGardenDirector.nextEncounter(profile: profile, graph: graph).skillID,
            LiteracySkills.visualLetterMatch,
            "Flower Gate stays on honest no-audio work until recorded instruction ships."
        )
    }

    func testSpokenLetterNamesAndPhonemesRemainAudioGated() throws {
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.uppercaseLetterNames)?.requiresRecordedAudio == true
        )
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.lowercaseLetterNames)?.requiresRecordedAudio == true
        )

        let encounter = WordGardenDirector.nextEncounter(
            profile: LearnerProfile(),
            graph: try LiteracySkillCatalog.graph()
        )
        XCTAssertFalse([
            LiteracySkills.uppercaseLetterNames,
            LiteracySkills.lowercaseLetterNames,
            LiteracySkills.sameDifferentSounds,
            LiteracySkills.beginningSoundMatch,
            LiteracySkills.commonConsonantSounds,
            LiteracySkills.shortVowelSounds
        ].contains(encounter.skillID))
    }
}
