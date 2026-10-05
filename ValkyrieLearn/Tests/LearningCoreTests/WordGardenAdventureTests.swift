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
        XCTAssertFalse(WordGardenDirector.flowerGateComplete(profile: LearnerProfile()))
    }

    func testThreeIndependentFlowerGateMatchesUnlockSunmillWithoutSpokenMastery() throws {
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
        XCTAssertTrue(WordGardenDirector.canEnterSunmill(profile: profile))
        XCTAssertTrue(
            graph.isEligible(LiteracySkills.uppercaseLetterNames, for: profile)
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new,
            "Visual shape matching must not manufacture spoken letter-name mastery."
        )

        let sunmill = try XCTUnwrap(
            WordGardenDirector.nextSunmillEncounter(profile: profile)
        )
        XCTAssertEqual(sunmill.skillID, LiteracySkills.visualLetterMatch)
        XCTAssertEqual(sunmill.mechanicID, WordGardenMechanicID.sunmillPair)
        XCTAssertEqual(sunmill.context, "sunmillCrossing")
        XCTAssertTrue(sunmill.transferContext)
        XCTAssertFalse(sunmill.prompt.contains(sunmill.answer))

        XCTAssertEqual(
            WordGardenDirector.nextEncounter(profile: profile, graph: graph).skillID,
            LiteracySkills.visualLetterMatch,
            "Generic Word Garden selection stays on honest no-audio work."
        )
    }

    func testSupportedFlowerGateMatchesDoNotUnlockSunmill() throws {
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
        XCTAssertFalse(WordGardenDirector.canEnterSunmill(profile: profile))
        XCTAssertNil(WordGardenDirector.nextSunmillEncounter(profile: profile))
    }

    func testThreeIndependentSunmillTransfersWakeCrossingWithoutSpokenLetterClaims() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes
            + WordGardenEncounterCatalog.sunmillVisualShapes {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        XCTAssertTrue(WordGardenDirector.sunmillComplete(profile: profile))
        XCTAssertEqual(
            WordGardenDirector.independentSuccessCount(
                for: WordGardenEncounterCatalog.sunmillVisualShapes,
                profile: profile
            ),
            3
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
    }

    func testSpokenLetterNamesAndPhonemesRemainAudioGated() throws {
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.uppercaseLetterNames)?.requiresRecordedAudio == true
        )
        XCTAssertTrue(
            LiteracySkillCatalog.descriptor(for: LiteracySkills.lowercaseLetterNames)?.requiresRecordedAudio == true
        )

        let flower = WordGardenDirector.nextEncounter(
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
        ].contains(flower.skillID))
    }
    func testStoryHollowStaysLockedUntilSunmillHasThreeIndependentTransferMatches() throws {
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

        XCTAssertFalse(WordGardenDirector.canEnterStoryHollow(profile: profile))
        XCTAssertNil(WordGardenDirector.nextStoryHollowEncounter(profile: profile))

        for encounter in WordGardenEncounterCatalog.sunmillVisualShapes {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: true
                ),
                in: &profile
            )
        }

        XCTAssertTrue(WordGardenDirector.canEnterStoryHollow(profile: profile))
        let hollow = try XCTUnwrap(
            WordGardenDirector.nextStoryHollowEncounter(profile: profile)
        )
        XCTAssertEqual(hollow.skillID, LiteracySkills.visualPrintSequence)
        XCTAssertEqual(hollow.mechanicID, WordGardenMechanicID.storySeedSequence)
        XCTAssertEqual(hollow.context, "storyHollow")
        let promptTokens = hollow.prompt.lowercased().split { !$0.isLetter }.map(String.init)
        XCTAssertFalse(promptTokens.contains(hollow.answer.lowercased()))
    }

    func testStoryHollowCompletionIsVisualSequenceEvidenceNotReadingMastery() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes
            + WordGardenEncounterCatalog.sunmillVisualShapes
            + WordGardenEncounterCatalog.storyHollowSequence {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        XCTAssertTrue(WordGardenDirector.storyHollowComplete(profile: profile))
        XCTAssertEqual(
            WordGardenDirector.independentSuccessCount(
                for: WordGardenEncounterCatalog.storyHollowSequence,
                profile: profile
            ),
            3
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.visualPrintSequence).state,
            .secure
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.uppercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.lowercaseLetterNames).state,
            .new
        )
        XCTAssertEqual(profile.progress(for: LiteracySkills.decodeCVC).state, .new)
    }

    func testSupportedStoryHollowRestorationsDoNotFakeIndependentCompletion() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in WordGardenEncounterCatalog.visualLetterShapes
            + WordGardenEncounterCatalog.sunmillVisualShapes {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        for encounter in WordGardenEncounterCatalog.storyHollowSequence {
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

        XCTAssertFalse(WordGardenDirector.storyHollowComplete(profile: profile))
        XCTAssertNotNil(WordGardenDirector.nextStoryHollowEncounter(profile: profile))
    }

}


final class PuzzlePalaceAdventureTests: XCTestCase {
    func testRuneGateUsesThreeDistinctTransferSafePatterns() {
        let encounters = PuzzlePalaceEncounterCatalog.runeGate

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)

        for encounter in encounters {
            XCTAssertEqual(encounter.skillID, PuzzleSkills.visualPatternContinue)
            XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.runeGate)
            XCTAssertEqual(encounter.fixedRunes.count, 3)
            XCTAssertEqual(Set(encounter.choices).count, encounter.choices.count)
            XCTAssertTrue(encounter.choices.contains(encounter.answer))
            XCTAssertFalse(encounter.prompt.contains(encounter.answer))
        }
    }

    func testOneCorrectRuneNeverCompletesTheGate() {
        var profile = LearnerProfile()
        let encounter = PuzzlePalaceEncounterCatalog.runeGate[0]
        MasteryEngine().record(
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

        XCTAssertEqual(
            PuzzlePalaceDirector.runeGateIndependentSuccessCount(profile: profile),
            1
        )
        XCTAssertFalse(PuzzlePalaceDirector.runeGateComplete(profile: profile))
    }

    func testSupportedRuneSuccessMustBeRepeatedIndependently() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
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

        XCTAssertEqual(
            PuzzlePalaceDirector.runeGateIndependentSuccessCount(profile: profile),
            0
        )
        XCTAssertFalse(PuzzlePalaceDirector.runeGateComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.nextRuneGateEncounter(profile: profile).id,
            PuzzlePalaceEncounterCatalog.runeGate[0].id
        )
    }

    func testThreeIndependentRunePatternsOpenTheGate() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        XCTAssertEqual(
            PuzzlePalaceDirector.runeGateIndependentSuccessCount(profile: profile),
            3
        )
        XCTAssertTrue(PuzzlePalaceDirector.runeGateComplete(profile: profile))
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.visualSequenceMemory).state,
            .new,
            "Pattern completion must not manufacture working-memory mastery."
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.responseInhibition).state,
            .new,
            "Rune choices must not manufacture inhibition mastery."
        )
    }

    func testMemoryBridgeStaysLockedUntilRuneGateIsIndependentlyOpen() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        XCTAssertFalse(PuzzlePalaceDirector.canEnterMemoryBridge(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextMemoryBridgeEncounter(profile: profile))

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
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

        XCTAssertTrue(PuzzlePalaceDirector.canEnterMemoryBridge(profile: profile))
        let memory = try XCTUnwrap(
            PuzzlePalaceDirector.nextMemoryBridgeEncounter(profile: profile)
        )
        XCTAssertEqual(memory.skillID, PuzzleSkills.visualSequenceMemory)
        XCTAssertEqual(memory.mechanicID, PuzzlePalaceMechanicID.memoryBridge)
        XCTAssertEqual(memory.context, "memoryBridge")
        XCTAssertGreaterThanOrEqual(memory.sequence.count, 3)
        XCTAssertFalse(memory.prompt.contains(memory.sequence.joined()))
    }

    func testSupportedMemoryBridgeSequencesDoNotCountAsIndependentRestoration() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
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

        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .lightHint,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        XCTAssertEqual(
            PuzzlePalaceDirector.memoryBridgeIndependentSuccessCount(profile: profile),
            0
        )
        XCTAssertFalse(PuzzlePalaceDirector.memoryBridgeComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.nextMemoryBridgeEncounter(profile: profile)?.id,
            PuzzlePalaceEncounterCatalog.memoryBridge[0].id
        )
    }

    func testThreeIndependentMemorySequencesRestoreBridgeWithoutLeakingOtherExecutiveSkills() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
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
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            mastery.record(
                LearningEvidence(
                    encounterID: encounter.id,
                    skillID: encounter.skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: encounter.representation,
                    mechanicID: encounter.mechanicID,
                    transferContext: encounter.transferContext
                ),
                in: &profile
            )
        }

        XCTAssertEqual(
            PuzzlePalaceDirector.memoryBridgeIndependentSuccessCount(profile: profile),
            3
        )
        XCTAssertTrue(PuzzlePalaceDirector.memoryBridgeComplete(profile: profile))
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.visualSequenceMemory).state,
            .secure
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.responseInhibition).state,
            .new
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.ruleSwitching).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
    }

    func testMemoryBridgeUsesDistinctSequencesAndIncreasesMemoryLoad() {
        let encounters = PuzzlePalaceEncounterCatalog.memoryBridge

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)
        XCTAssertEqual(encounters.map { $0.sequence.count }, [3, 3, 4])
        XCTAssertTrue(encounters.allSatisfy {
            Set($0.sequence).isSubset(of: Set($0.choices))
        })
    }

}
