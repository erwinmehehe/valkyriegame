import XCTest
@testable import LearningCore

final class WordGardenAdventureTests: XCTestCase {
    func testFlowerGateStartsWithNonAudioLetterRecognition() throws {
        let graph = try LiteracySkillCatalog.graph()
        let profile = LearnerProfile()
        let encounter = WordGardenDirector.nextEncounter(profile: profile, graph: graph)

        XCTAssertEqual(encounter.skillID, LiteracySkills.uppercaseLetterNames)
        XCTAssertEqual(encounter.mechanicID, WordGardenMechanicID.letterStones)
        XCTAssertNotNil(LiteracySkillCatalog.descriptor(for: encounter.skillID))
        XCTAssertFalse(LiteracySkillCatalog.descriptor(for: encounter.skillID)?.requiresRecordedAudio == true)
    }

    func testThreeDistinctUppercaseSuccessesUnlockLowercaseWork() throws {
        let graph = try LiteracySkillCatalog.graph()
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.uppercaseLetters {
            mastery.record(LearningEvidence(
                encounterID: encounter.id,
                skillID: encounter.skillID,
                outcome: .correct,
                supportLevel: .independent,
                representation: encounter.representation,
                mechanicID: encounter.mechanicID
            ), in: &profile)
        }

        XCTAssertEqual(profile.progress(for: LiteracySkills.uppercaseLetterNames).state, .secure)
        XCTAssertTrue(graph.isEligible(LiteracySkills.lowercaseLetterNames, for: profile))
        XCTAssertEqual(
            WordGardenDirector.nextEncounter(profile: profile, graph: graph).skillID,
            LiteracySkills.lowercaseLetterNames
        )
    }

    func testFlowerGateDoesNotUsePhonemePlacementWithoutRecordedAudio() throws {
        let graph = try LiteracySkillCatalog.graph()
        let encounter = WordGardenDirector.nextEncounter(profile: LearnerProfile(), graph: graph)

        XCTAssertFalse([
            LiteracySkills.sameDifferentSounds,
            LiteracySkills.beginningSoundMatch,
            LiteracySkills.commonConsonantSounds,
            LiteracySkills.shortVowelSounds
        ].contains(encounter.skillID))
    }
}
