import XCTest
@testable import LearningCore

final class PuzzleRotationTests: XCTestCase {
    private func recordOrientation(in profile: inout LearnerProfile, support: SupportLevel = .independent) {
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            MasteryEngine().record(LearningEvidence(
                encounterID: encounter.id, skillID: encounter.skillID, outcome: .correct,
                supportLevel: support, representation: encounter.representation,
                mechanicID: encounter.mechanicID, transferContext: encounter.transferContext
            ), in: &profile)
        }
    }

    private func recordRotation(_ encounter: PuzzleRotationEncounter, in profile: inout LearnerProfile,
                                support: SupportLevel = .independent, outcome: Outcome = .correct) {
        MasteryEngine().record(LearningEvidence(
            encounterID: encounter.id, skillID: encounter.skillID, outcome: outcome,
            supportLevel: support, representation: encounter.representation,
            mechanicID: encounter.mechanicID, transferContext: encounter.transferContext
        ), in: &profile)
    }

    func testRotationRequiresIndependentOrientationAndHallAccess() throws {
        var profile = LearnerProfile()
        XCTAssertNil(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        recordOrientation(in: &profile, support: .strongHint)
        XCTAssertNil(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        recordOrientation(in: &profile)
        // Orientation evidence alone cannot bypass the preceding vault.
        XCTAssertNil(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            MasteryEngine().record(LearningEvidence(
                encounterID: encounter.id, skillID: encounter.skillID, outcome: .correct,
                supportLevel: .independent, representation: encounter.representation,
                mechanicID: encounter.mechanicID
            ), in: &profile)
        }
        XCTAssertNotNil(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        XCTAssertEqual(profile.progress(for: PuzzleSkills.mentalRotation).state, .new)
    }

    func testClockwiseTurnPreservesShapeAndReturnsAfterFourTurns() {
        let shape = PuzzleTileShape(cells: [
            .init(x: 0, y: 0), .init(x: 0, y: 1), .init(x: 0, y: 2), .init(x: 1, y: 0)
        ])
        XCTAssertEqual(shape.rotated(quarterTurns: 1), PuzzleTileShape(cells: [
            .init(x: 0, y: 0), .init(x: 0, y: 1), .init(x: 1, y: 1), .init(x: 2, y: 1)
        ]))
        XCTAssertEqual(shape.rotated(quarterTurns: 4), shape)
        XCTAssertEqual(shape.rotated(quarterTurns: -1), shape.rotated(quarterTurns: 3))
    }

    func testCatalogUsesAsymmetricShapesAndReflectionDistractors() {
        let encounters = PuzzlePalaceEncounterCatalog.mirrorHallRotation
        XCTAssertEqual(encounters.count, 3)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, 3)
        XCTAssertEqual(encounters.map(\.quarterTurns), [1, 2, 3])
        XCTAssertEqual(Set(encounters.map { $0.source.signature }).count, 3)
        for encounter in encounters {
            XCTAssertEqual(encounter.skillID, PuzzleSkills.mentalRotation)
            XCTAssertNotEqual(encounter.answer, encounter.source)
            XCTAssertEqual(encounter.choices.filter { $0 == encounter.answer }.count, 1)
            XCTAssertEqual(Set(encounter.choices.map(\.signature)).count, 3)
            XCTAssertTrue(encounter.choices.contains(encounter.answer.reflected()))
            XCTAssertFalse((0..<4).contains { encounter.source.rotated(quarterTurns: $0) == encounter.answer.reflected() })
        }
    }

    func testHintsErrorsAndRepeatedSuccessCannotCompleteRotation() {
        var profile = LearnerProfile()
        let encounters = PuzzlePalaceEncounterCatalog.mirrorHallRotation
        for encounter in encounters {
            recordRotation(encounter, in: &profile, support: .lightHint)
            recordRotation(encounter, in: &profile, outcome: .incorrect)
        }
        XCTAssertEqual(PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: profile), 0)
        XCTAssertFalse(PuzzlePalaceDirector.mirrorRotationComplete(profile: profile))
        for _ in 0..<4 { recordRotation(encounters[0], in: &profile) }
        XCTAssertEqual(PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: profile), 1)
        XCTAssertFalse(PuzzlePalaceDirector.mirrorRotationComplete(profile: profile))
        for encounter in encounters.dropFirst() { recordRotation(encounter, in: &profile) }
        XCTAssertTrue(PuzzlePalaceDirector.mirrorRotationComplete(profile: profile))
        XCTAssertEqual(profile.progress(for: PuzzleSkills.spatialOrientation).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.mentalRotation).state, .mastered)
    }
    func testAssistedRetryChangesTurnAndPositionWithoutDoubleCountingOneShape() throws {
        var profile = LearnerProfile()
        recordOrientation(in: &profile)
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            MasteryEngine().record(LearningEvidence(encounterID: encounter.id, skillID: encounter.skillID,
                outcome: .correct, supportLevel: .independent, representation: encounter.representation,
                mechanicID: encounter.mechanicID), in: &profile)
        }
        let first = try XCTUnwrap(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        recordRotation(first, in: &profile, support: .demonstration)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)
        XCTAssertNotEqual(retry.answer, first.answer)
        XCTAssertNotEqual(retry.choices.firstIndex(of: retry.answer), first.choices.firstIndex(of: first.answer))
        recordRotation(retry, in: &profile)
        recordRotation(first, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.mirrorRotationIndependentSuccessCount(profile: profile), 1)
        let next = try XCTUnwrap(PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile))
        XCTAssertNotEqual(next.source, first.source)
    }


    private func recordPathPrerequisites(in profile: inout LearnerProfile, includeRotation: Bool = true) {
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            MasteryEngine().record(LearningEvidence(
                encounterID: encounter.id, skillID: encounter.skillID, outcome: .correct,
                supportLevel: .independent, representation: encounter.representation,
                mechanicID: encounter.mechanicID
            ), in: &profile)
        }
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            MasteryEngine().record(LearningEvidence(
                encounterID: encounter.id, skillID: encounter.skillID, outcome: .correct,
                supportLevel: .independent, representation: encounter.representation,
                mechanicID: encounter.mechanicID
            ), in: &profile)
        }
        recordOrientation(in: &profile)
        if includeRotation {
            for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
                recordRotation(encounter, in: &profile)
            }
        }
    }

    private func recordPath(_ encounter: PuzzlePathEncounter, in profile: inout LearnerProfile,
                            support: SupportLevel = .independent, outcome: Outcome = .correct) {
        MasteryEngine().record(LearningEvidence(
            encounterID: encounter.id, skillID: encounter.skillID, outcome: outcome,
            supportLevel: support, representation: encounter.representation,
            mechanicID: encounter.mechanicID, transferContext: encounter.transferContext
        ), in: &profile)
    }

    func testPathTileCatalogHasExactlyOneSafePlanPerVariant() {
        XCTAssertEqual(PuzzlePalaceEncounterCatalog.pathTileFamilies.count, 3)
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            XCTAssertEqual(family.count, 2)
            XCTAssertEqual(Set(family.map(\.fingerprint)).count, family.count)
            for encounter in family {
                XCTAssertEqual(encounter.skillID, PuzzleSkills.pathPlanning)
                XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.pathTiles)
                let valid = encounter.choices.indices.filter(encounter.isValidChoice)
                XCTAssertEqual(valid, [encounter.answerIndex])
            }
        }
    }

    func testPathTilesWaitForFullMirrorHallCompletion() {
        var profile = LearnerProfile()
        recordPathPrerequisites(in: &profile, includeRotation: false)
        XCTAssertFalse(PuzzlePalaceDirector.canEnterPathTiles(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextPathTilesEncounter(profile: profile))

        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            recordRotation(encounter, in: &profile)
        }
        XCTAssertTrue(PuzzlePalaceDirector.canEnterPathTiles(profile: profile))
        XCTAssertNotNil(PuzzlePalaceDirector.nextPathTilesEncounter(profile: profile))
    }

    func testAssistedPathRetryChangesMapAndOnlyIndependentFamiliesCount() throws {
        var profile = LearnerProfile()
        recordPathPrerequisites(in: &profile)
        let first = try XCTUnwrap(PuzzlePalaceDirector.nextPathTilesEncounter(profile: profile))
        recordPath(first, in: &profile, support: .lightHint)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextPathTilesEncounter(profile: profile))
        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)

        recordPath(retry, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.pathTilesIndependentSuccessCount(profile: profile), 1)
        recordPath(first, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.pathTilesIndependentSuccessCount(profile: profile), 1)

        XCTAssertEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
    }


    private func recordMemoryForCommands(in profile: inout LearnerProfile) {
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            MasteryEngine().record(LearningEvidence(
                encounterID: encounter.id,
                skillID: encounter.skillID,
                outcome: .correct,
                supportLevel: .independent,
                representation: encounter.representation,
                mechanicID: encounter.mechanicID
            ), in: &profile)
        }
    }

    private func recordSequence(
        _ encounter: PuzzleSequenceEncounter,
        in profile: inout LearnerProfile,
        support: SupportLevel = .independent,
        outcome: Outcome = .correct
    ) {
        MasteryEngine().record(LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            transferContext: encounter.transferContext
        ), in: &profile)
    }

    func testCommandGearCatalogMeasuresSequencingWithFreshVariants() {
        XCTAssertEqual(PuzzlePalaceEncounterCatalog.commandGearFamilies.count, 3)
        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            XCTAssertEqual(family.count, 2)
            XCTAssertEqual(Set(family.map(\.fingerprint)).count, 2)
            for encounter in family {
                XCTAssertEqual(encounter.skillID, PuzzleSkills.actionSequencing)
                XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.commandGears)
                XCTAssertFalse(encounter.isCorrect(encounter.presented))
                XCTAssertTrue(encounter.isCorrect(encounter.correctOrder))
                XCTAssertEqual(Set(encounter.presented.map(\.id)),
                               Set(encounter.correctOrder.map(\.id)))
            }
        }
    }

    func testCommandGearsRequireMemoryButNotPathPlanning() throws {
        var profile = LearnerProfile()
        XCTAssertFalse(PuzzlePalaceDirector.canEnterCommandGears(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))

        recordMemoryForCommands(in: &profile)

        XCTAssertTrue(PuzzlePalaceDirector.canEnterCommandGears(profile: profile))
        XCTAssertNotNil(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testAssistedCommandRetryChangesVariantAndDoesNotLeakOtherSkills() throws {
        var profile = LearnerProfile()
        recordMemoryForCommands(in: &profile)

        let first = try XCTUnwrap(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))
        recordSequence(first, in: &profile, support: .lightHint)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))

        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)
        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 0)

        recordSequence(retry, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 1)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testThreeIndependentCommandFamiliesRestoreCommandGears() {
        var profile = LearnerProfile()
        recordMemoryForCommands(in: &profile)

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &profile)
        }

        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 3)
        XCTAssertTrue(PuzzlePalaceDirector.commandGearsComplete(profile: profile))
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

}
