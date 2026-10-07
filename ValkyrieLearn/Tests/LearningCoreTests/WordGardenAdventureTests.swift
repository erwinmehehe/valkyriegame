import XCTest
@testable import LearningCore

final class WordGardenAdventureTests: XCTestCase {

    func testWordGardenShipsEighteenDistinctNoAudioAuthoredEncounters() {
        let flower = WordGardenEncounterCatalog.visualLetterShapes
        let sunmill = WordGardenEncounterCatalog.sunmillVisualShapes
        let hollow = WordGardenEncounterCatalog.storyHollowSequence
        let all = flower + sunmill + hollow

        XCTAssertEqual(flower.count, 6)
        XCTAssertEqual(sunmill.count, 6)
        XCTAssertEqual(hollow.count, 6)
        XCTAssertEqual(all.count, 18)
        XCTAssertEqual(Set(all.map(\.id)).count, 18)
        XCTAssertEqual(Set(all.map(\.fingerprint)).count, 18)

        for encounter in all {
            XCTAssertTrue(encounter.choices.contains(encounter.answer))
            XCTAssertEqual(Set(encounter.choices).count, encounter.choices.count)
            XCTAssertGreaterThanOrEqual(encounter.choices.count, 4)
            XCTAssertFalse(
                LiteracySkillCatalog.descriptor(for: encounter.skillID)?
                    .requiresRecordedAudio ?? true
            )
        }

        XCTAssertEqual(WordGardenEncounterCatalog.storyHollowPatterns.count, 2)
        XCTAssertTrue(
            WordGardenEncounterCatalog.storyHollowPatterns.allSatisfy {
                $0.count == WordGardenEncounterCatalog.storyHollowPatternLength
            }
        )
    }

    func testStoryHollowRotatesToSecondMemoryAfterFirstThreeRestorations() {
        let first = WordGardenEncounterCatalog.storyHollowVisiblePatternProgress(
            independentCount: 0
        )
        XCTAssertEqual(first.pattern, ["m", "a", "p"])
        XCTAssertEqual(first.filledCount, 0)

        let firstComplete = WordGardenEncounterCatalog.storyHollowVisiblePatternProgress(
            independentCount: 3
        )
        XCTAssertEqual(firstComplete.pattern, ["r", "i", "n"])
        XCTAssertEqual(firstComplete.filledCount, 0)

        let secondNearlyComplete = WordGardenEncounterCatalog.storyHollowVisiblePatternProgress(
            independentCount: 5
        )
        XCTAssertEqual(secondNearlyComplete.pattern, ["r", "i", "n"])
        XCTAssertEqual(secondNearlyComplete.filledCount, 2)

        let complete = WordGardenEncounterCatalog.storyHollowVisiblePatternProgress(
            independentCount: 6
        )
        XCTAssertEqual(complete.pattern, ["r", "i", "n"])
        XCTAssertEqual(complete.filledCount, 3)
    }

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

    func testSixIndependentFlowerGateMatchesUnlockSunmillWithoutSpokenMastery() throws {
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

    func testSixIndependentSunmillTransfersWakeCrossingWithoutSpokenLetterClaims() throws {
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
            6
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
    func testStoryHollowStaysLockedUntilSunmillHasSixIndependentTransferMatches() throws {
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
            6
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


    func testStopGoOrbsStayLockedUntilMemoryBridgeIsIndependentlyRestored() throws {
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

        XCTAssertFalse(PuzzlePalaceDirector.canEnterStopGoOrbs(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextStopGoEncounter(profile: profile))

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

        XCTAssertTrue(PuzzlePalaceDirector.canEnterStopGoOrbs(profile: profile))
        let inhibition = try XCTUnwrap(
            PuzzlePalaceDirector.nextStopGoEncounter(profile: profile)
        )
        XCTAssertEqual(inhibition.skillID, PuzzleSkills.responseInhibition)
        XCTAssertEqual(inhibition.mechanicID, PuzzlePalaceMechanicID.stopGoOrbs)
        XCTAssertEqual(inhibition.context, "stopGoOrbs")
    }

    func testStopGoCatalogRequiresBothHoldingAndActing() {
        let encounters = PuzzlePalaceEncounterCatalog.stopGoOrbs

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)
        XCTAssertEqual(encounters.map { $0.signals.count }, [4, 5, 7])

        for encounter in encounters {
            XCTAssertTrue(encounter.signals.contains(.hold))
            XCTAssertTrue(encounter.signals.contains(.go))
            XCTAssertGreaterThanOrEqual(
                encounter.signals.filter { $0 == .hold }.count,
                2
            )
        }
    }

    func testSupportedStopGoSuccessDoesNotCountAsIndependentInhibition() {
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
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
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
            PuzzlePalaceDirector.stopGoIndependentSuccessCount(profile: profile),
            0
        )
        XCTAssertFalse(PuzzlePalaceDirector.stopGoComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.nextStopGoEncounter(profile: profile)?.id,
            PuzzlePalaceEncounterCatalog.stopGoOrbs[0].id
        )
    }

    func testIndependentStopGoCompletionAdvancesOnlyInhibitoryControl() {
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
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }
        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
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

        XCTAssertTrue(PuzzlePalaceDirector.stopGoComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.stopGoIndependentSuccessCount(profile: profile),
            3
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.responseInhibition).state,
            .secure
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.ruleSwitching).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.singleRuleSort).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
    }


    func testSortingPedestalStaysLockedUntilStopGoIsIndependentlyStable() throws {
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
                    mechanicID: encounter.mechanicID
                ),
                in: &profile
            )
        }

        XCTAssertFalse(PuzzlePalaceDirector.canEnterSortingPedestal(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextSortingFoundationEncounter(profile: profile))

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
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

        XCTAssertTrue(PuzzlePalaceDirector.canEnterSortingPedestal(profile: profile))
        let sort = try XCTUnwrap(
            PuzzlePalaceDirector.nextSortingFoundationEncounter(profile: profile)
        )
        XCTAssertEqual(sort.skillID, PuzzleSkills.singleRuleSort)
        XCTAssertEqual(sort.mechanicID, PuzzlePalaceMechanicID.sortingPedestal)
        XCTAssertTrue(Set(sort.rules).count == 1)
    }

    func testSortingFoundationKeepsOneRuleStableWithinEachEncounter() {
        let encounters = PuzzlePalaceEncounterCatalog.sortingFoundation

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)

        for encounter in encounters {
            XCTAssertEqual(encounter.skillID, PuzzleSkills.singleRuleSort)
            XCTAssertEqual(Set(encounter.rules).count, 1)
            XCTAssertEqual(encounter.rules.count, encounter.objects.count)
            XCTAssertGreaterThanOrEqual(encounter.objects.count, 4)
        }
    }

    func testRuleSwitchingEncountersActuallyChangeRulesMidRun() {
        let encounters = PuzzlePalaceEncounterCatalog.ruleSwitching

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)

        for encounter in encounters {
            XCTAssertEqual(encounter.skillID, PuzzleSkills.ruleSwitching)
            XCTAssertEqual(encounter.rules.count, encounter.objects.count)
            XCTAssertGreaterThan(Set(encounter.rules).count, 1)
            XCTAssertTrue(encounter.rules.contains(.shape))
            XCTAssertTrue(encounter.rules.contains(.marks))
        }
    }

    func testSupportedFoundationSortsDoNotUnlockRuleSwitching() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
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

        XCTAssertFalse(PuzzlePalaceDirector.sortingFoundationComplete(profile: profile))
        XCTAssertFalse(PuzzlePalaceDirector.canStartRuleSwitching(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextRuleSwitchingEncounter(profile: profile))
    }

    func testRuleSwitchingUnlocksOnlyAfterIndependentFoundationAndInhibition() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
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
        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
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

        XCTAssertTrue(PuzzlePalaceDirector.sortingFoundationComplete(profile: profile))
        XCTAssertTrue(PuzzlePalaceDirector.canStartRuleSwitching(profile: profile))
        let switching = try XCTUnwrap(
            PuzzlePalaceDirector.nextRuleSwitchingEncounter(profile: profile)
        )
        XCTAssertEqual(switching.skillID, PuzzleSkills.ruleSwitching)
        XCTAssertGreaterThan(Set(switching.rules).count, 1)
    }

    func testSortingPedestalCompletionKeepsChangedRuleSortSeparate() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation
            + PuzzlePalaceEncounterCatalog.ruleSwitching {
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

        XCTAssertTrue(PuzzlePalaceDirector.sortingFoundationComplete(profile: profile))
        XCTAssertTrue(PuzzlePalaceDirector.ruleSwitchingComplete(profile: profile))
        XCTAssertTrue(PuzzlePalaceDirector.sortingPedestalComplete(profile: profile))
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.singleRuleSort).state,
            .secure
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.ruleSwitching).state,
            .secure
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .new,
            "Switching between visible rules must not manufacture changed-rule re-sort mastery."
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.spatialOrientation).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
    }


    func testChangedRuleResortStaysLockedUntilSortingAndSwitchingAreIndependent() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
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

        XCTAssertFalse(PuzzlePalaceDirector.canEnterChangedRuleResort(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextChangedRuleResortEncounter(profile: profile))

        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
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

        XCTAssertTrue(PuzzlePalaceDirector.canEnterChangedRuleResort(profile: profile))
        let resort = try XCTUnwrap(
            PuzzlePalaceDirector.nextChangedRuleResortEncounter(profile: profile)
        )
        XCTAssertEqual(resort.skillID, PuzzleSkills.changedRuleSort)
        XCTAssertEqual(resort.mechanicID, PuzzlePalaceMechanicID.changedRuleResort)
        XCTAssertEqual(resort.context, "resortVault")
    }

    func testChangedRuleResortUsesTheSameSetAcrossTwoDifferentRules() {
        let encounters = PuzzlePalaceEncounterCatalog.changedRuleResort

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)

        for encounter in encounters {
            XCTAssertNotEqual(encounter.initialRule, encounter.changedRule)
            XCTAssertEqual(encounter.objects.count, 4)
            XCTAssertEqual(Set(encounter.objects.map(\.id)).count, encounter.objects.count)
            XCTAssertTrue(
                encounter.objects.contains {
                    $0.bucket(for: encounter.initialRule)
                        != $0.bucket(for: encounter.changedRule)
                },
                "At least one object must physically change groups when the rule flips."
            )
        }
    }

    func testSupportedChangedRuleResortDoesNotCountAsIndependent() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
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
            PuzzlePalaceDirector.changedRuleResortIndependentSuccessCount(profile: profile),
            0
        )
        XCTAssertFalse(PuzzlePalaceDirector.changedRuleResortComplete(profile: profile))
    }

    func testIndependentChangedRuleResortAdvancesOnlyChangedRuleSort() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
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

        XCTAssertTrue(PuzzlePalaceDirector.changedRuleResortComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.changedRuleResortIndependentSuccessCount(profile: profile),
            3
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.changedRuleSort).state,
            .secure
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.spatialOrientation).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.mentalRotation).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
    }

    func testChangedRuleSortUsesDedicatedResortMechanic() throws {
        let descriptor = try XCTUnwrap(
            PuzzleSkillCatalog.descriptor(for: PuzzleSkills.changedRuleSort)
        )
        XCTAssertEqual(
            descriptor.mechanicIDs,
            [PuzzlePalaceMechanicID.changedRuleResort]
        )
        XCTAssertFalse(
            descriptor.mechanicIDs.contains(PuzzlePalaceMechanicID.sortingPedestal)
        )
    }

    func testMirrorHallStaysLockedUntilChangedRuleResortIsIndependentlyStable() throws {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        XCTAssertFalse(PuzzlePalaceDirector.canEnterMirrorHall(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextMirrorHallEncounter(profile: profile))

        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
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

        XCTAssertTrue(PuzzlePalaceDirector.canEnterMirrorHall(profile: profile))
        let orientation = try XCTUnwrap(
            PuzzlePalaceDirector.nextMirrorHallEncounter(profile: profile)
        )
        XCTAssertEqual(orientation.skillID, PuzzleSkills.spatialOrientation)
        XCTAssertEqual(orientation.mechanicID, PuzzlePalaceMechanicID.mirrorHall)
        XCTAssertEqual(orientation.context, "mirrorHall")
    }

    func testMirrorHallUsesDistinctDirectionMatches() {
        let encounters = PuzzlePalaceEncounterCatalog.mirrorHallOrientation

        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.id)).count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)

        for encounter in encounters {
            XCTAssertEqual(encounter.skillID, PuzzleSkills.spatialOrientation)
            XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.mirrorHall)
            XCTAssertEqual(Set(encounter.choices).count, encounter.choices.count)
            XCTAssertTrue(encounter.choices.contains(encounter.target))
            XCTAssertGreaterThanOrEqual(encounter.choices.count, 3)
        }
    }

    func testSupportedMirrorHallMatchesDoNotCountAsIndependentOrientation() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
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
            PuzzlePalaceDirector.mirrorHallIndependentSuccessCount(profile: profile),
            0
        )
        XCTAssertFalse(PuzzlePalaceDirector.mirrorHallComplete(profile: profile))
    }

    func testIndependentMirrorHallAdvancesOrientationWithoutGrantingMentalRotation() {
        var profile = LearnerProfile()
        let mastery = MasteryEngine()

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
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

        XCTAssertTrue(PuzzlePalaceDirector.mirrorHallComplete(profile: profile))
        XCTAssertEqual(
            PuzzlePalaceDirector.mirrorHallIndependentSuccessCount(profile: profile),
            3
        )
        XCTAssertEqual(
            profile.progress(for: PuzzleSkills.spatialOrientation).state,
            .secure
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.mentalRotation).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
    }

}
