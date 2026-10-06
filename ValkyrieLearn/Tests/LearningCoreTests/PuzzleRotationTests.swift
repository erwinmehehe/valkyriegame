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


    private func recordPathPlanningForCommands(in profile: inout LearnerProfile) {
        recordPathPrerequisites(in: &profile)
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            recordPath(family[0], in: &profile)
        }
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

    func testCommandGearsRequireCompletedPathPlanning() throws {
        var profile = LearnerProfile()
        XCTAssertFalse(PuzzlePalaceDirector.canEnterCommandGears(profile: profile))
        XCTAssertNil(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))

        recordMemoryForCommands(in: &profile)
        XCTAssertFalse(PuzzlePalaceDirector.canEnterCommandGears(profile: profile))

        recordPathPlanningForCommands(in: &profile)

        XCTAssertTrue(PuzzlePalaceDirector.canEnterCommandGears(profile: profile))
        XCTAssertNotNil(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testAssistedCommandRetryChangesVariantAndDoesNotLeakOtherSkills() throws {
        var profile = LearnerProfile()
        recordPathPlanningForCommands(in: &profile)

        let first = try XCTUnwrap(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))
        recordSequence(first, in: &profile, support: .lightHint)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile))

        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)
        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 0)

        recordSequence(retry, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 1)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testThreeIndependentCommandFamiliesRestoreCommandGears() {
        var profile = LearnerProfile()
        recordPathPlanningForCommands(in: &profile)

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &profile)
        }

        XCTAssertEqual(PuzzlePalaceDirector.commandGearsIndependentSuccessCount(profile: profile), 3)
        XCTAssertTrue(PuzzlePalaceDirector.commandGearsComplete(profile: profile))
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    private func recordCommandPrerequisiteForBug(in profile: inout LearnerProfile) {
        recordPathPlanningForCommands(in: &profile)
        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &profile)
        }
    }

    private func recordBug(
        _ encounter: PuzzleBugEncounter,
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

    func testBugLanternCatalogHasExactlyOneBrokenStepPerVariant() {
        XCTAssertEqual(PuzzlePalaceEncounterCatalog.bugLanternFamilies.count, 3)
        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            XCTAssertEqual(family.count, 2)
            XCTAssertEqual(Set(family.map(\.fingerprint)).count, 2)
            for encounter in family {
                XCTAssertEqual(encounter.skillID, PuzzleSkills.debugSingleStep)
                XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.bugLantern)
                let mismatches = encounter.intended.indices.filter {
                    encounter.intended[$0] != encounter.shown[$0]
                }
                XCTAssertEqual(mismatches, [encounter.brokenIndex])
                XCTAssertTrue(encounter.isBrokenStep(encounter.brokenIndex))
            }
        }
    }

    func testBugLanternRequiresPlanningThenSequencing() throws {
        var missingPlanning = LearnerProfile()
        recordMemoryForCommands(in: &missingPlanning)
        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &missingPlanning)
        }
        XCTAssertFalse(PuzzlePalaceDirector.canEnterBugLantern(profile: missingPlanning))
        XCTAssertNil(PuzzlePalaceDirector.nextBugLanternEncounter(profile: missingPlanning))

        var missingSequencing = LearnerProfile()
        recordPathPlanningForCommands(in: &missingSequencing)
        XCTAssertFalse(PuzzlePalaceDirector.canEnterBugLantern(profile: missingSequencing))
        XCTAssertNil(PuzzlePalaceDirector.nextBugLanternEncounter(profile: missingSequencing))

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &missingSequencing)
        }

        XCTAssertTrue(PuzzlePalaceDirector.canEnterBugLantern(profile: missingSequencing))
        XCTAssertNotNil(PuzzlePalaceDirector.nextBugLanternEncounter(profile: missingSequencing))
        XCTAssertNotEqual(missingSequencing.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertNotEqual(missingSequencing.progress(for: PuzzleSkills.actionSequencing).state, .new)
        XCTAssertEqual(missingSequencing.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testAssistedBugRetryChangesVariantAndOnlyIndependentFamiliesCount() throws {
        var profile = LearnerProfile()
        recordCommandPrerequisiteForBug(in: &profile)

        let first = try XCTUnwrap(PuzzlePalaceDirector.nextBugLanternEncounter(profile: profile))
        recordBug(first, in: &profile, support: .lightHint)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextBugLanternEncounter(profile: profile))

        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)
        XCTAssertEqual(PuzzlePalaceDirector.bugLanternIndependentSuccessCount(profile: profile), 0)

        recordBug(retry, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.bugLanternIndependentSuccessCount(profile: profile), 1)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testThreeIndependentBugFamiliesRestoreLanternWithoutGrantingSequenceRepair() {
        var profile = LearnerProfile()
        recordCommandPrerequisiteForBug(in: &profile)

        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            recordBug(family[0], in: &profile)
        }

        XCTAssertEqual(PuzzlePalaceDirector.bugLanternIndependentSuccessCount(profile: profile), 3)
        XCTAssertTrue(PuzzlePalaceDirector.bugLanternComplete(profile: profile))
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.pathPlanning).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    private func recordRepairPrerequisites(in profile: inout LearnerProfile) {
        recordCommandPrerequisiteForBug(in: &profile)
        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            recordBug(family[0], in: &profile)
        }
    }

    private func recordRepair(
        _ encounter: PuzzleRepairEncounter,
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

    func testBugRepairCatalogIsARealTwoStepSwapRepair() {
        XCTAssertEqual(PuzzlePalaceEncounterCatalog.bugRepairFamilies.count, 3)
        for family in PuzzlePalaceEncounterCatalog.bugRepairFamilies {
            XCTAssertEqual(family.count, 2)
            XCTAssertEqual(Set(family.map(\.fingerprint)).count, 2)
            for encounter in family {
                XCTAssertEqual(encounter.skillID, PuzzleSkills.debugSequence)
                XCTAssertEqual(encounter.mechanicID, PuzzlePalaceMechanicID.bugLantern)
                XCTAssertEqual(encounter.correctOrder.count, 4)
                XCTAssertEqual(encounter.presented.count, 4)
                XCTAssertEqual(encounter.swapIndices.count, 2)
                XCTAssertNotEqual(encounter.presented, encounter.correctOrder)
                XCTAssertTrue(encounter.isCorrectSwap(encounter.swapIndices))
                XCTAssertEqual(encounter.repaired(by: encounter.swapIndices), encounter.correctOrder)
            }
        }
    }

    func testBugRepairRequiresPlanningSequencingAndSingleStepDebugging() {
        var missingPlanning = LearnerProfile()
        recordMemoryForCommands(in: &missingPlanning)
        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &missingPlanning)
        }
        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            recordBug(family[0], in: &missingPlanning)
        }

        XCTAssertTrue(PuzzlePalaceDirector.commandGearsComplete(profile: missingPlanning))
        XCTAssertTrue(PuzzlePalaceDirector.bugLanternComplete(profile: missingPlanning))
        XCTAssertFalse(PuzzlePalaceDirector.pathTilesComplete(profile: missingPlanning))
        XCTAssertFalse(PuzzlePalaceDirector.canEnterBugRepair(profile: missingPlanning))

        var missingSequencing = LearnerProfile()
        recordPathPlanningForCommands(in: &missingSequencing)
        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            recordBug(family[0], in: &missingSequencing)
        }

        XCTAssertTrue(PuzzlePalaceDirector.pathTilesComplete(profile: missingSequencing))
        XCTAssertTrue(PuzzlePalaceDirector.bugLanternComplete(profile: missingSequencing))
        XCTAssertFalse(PuzzlePalaceDirector.commandGearsComplete(profile: missingSequencing))
        XCTAssertFalse(PuzzlePalaceDirector.canEnterBugRepair(profile: missingSequencing))

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            recordSequence(family[0], in: &missingSequencing)
        }

        XCTAssertTrue(PuzzlePalaceDirector.commandGearsComplete(profile: missingSequencing))
        XCTAssertTrue(PuzzlePalaceDirector.canEnterBugRepair(profile: missingSequencing))
        XCTAssertNotNil(PuzzlePalaceDirector.nextBugRepairEncounter(profile: missingSequencing))
    }

    func testAssistedRepairRetryChangesVariantAndDoesNotRewritePrerequisiteEvidence() throws {
        var profile = LearnerProfile()
        recordRepairPrerequisites(in: &profile)

        let pathEvidenceBefore = profile.progress(for: PuzzleSkills.pathPlanning).evidence.count
        let bugEvidenceBefore = profile.progress(for: PuzzleSkills.debugSingleStep).evidence.count
        let sequenceEvidenceBefore = profile.progress(for: PuzzleSkills.actionSequencing).evidence.count

        let first = try XCTUnwrap(PuzzlePalaceDirector.nextBugRepairEncounter(profile: profile))
        recordRepair(first, in: &profile, support: .lightHint)
        let retry = try XCTUnwrap(PuzzlePalaceDirector.nextBugRepairEncounter(profile: profile))

        XCTAssertNotEqual(retry.id, first.id)
        XCTAssertNotEqual(retry.fingerprint, first.fingerprint)
        XCTAssertEqual(PuzzlePalaceDirector.bugRepairIndependentSuccessCount(profile: profile), 0)

        recordRepair(retry, in: &profile)
        XCTAssertEqual(PuzzlePalaceDirector.bugRepairIndependentSuccessCount(profile: profile), 1)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.pathPlanning).evidence.count, pathEvidenceBefore)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).evidence.count, bugEvidenceBefore)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.actionSequencing).evidence.count, sequenceEvidenceBefore)
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testThreeIndependentRepairFamiliesCompleteDebugSequence() {
        var profile = LearnerProfile()
        recordRepairPrerequisites(in: &profile)

        for family in PuzzlePalaceEncounterCatalog.bugRepairFamilies {
            recordRepair(family[0], in: &profile)
        }

        XCTAssertEqual(PuzzlePalaceDirector.bugRepairIndependentSuccessCount(profile: profile), 3)
        XCTAssertTrue(PuzzlePalaceDirector.bugRepairComplete(profile: profile))
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }

    func testPalaceRestorationRequiresEveryImplementedRoom() {
        var profile = LearnerProfile()

        func record(
            id: String,
            skillID: SkillID,
            representation: Representation,
            mechanicID: String,
            transfer: Bool = false
        ) {
            MasteryEngine().record(
                LearningEvidence(
                    encounterID: id,
                    skillID: skillID,
                    outcome: .correct,
                    supportLevel: .independent,
                    representation: representation,
                    mechanicID: mechanicID,
                    transferContext: transfer
                ),
                in: &profile
            )
        }

        for encounter in PuzzlePalaceEncounterCatalog.runeGate {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.memoryBridge {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.stopGoOrbs {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.sortingFoundation {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.ruleSwitching {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.changedRuleResort {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallOrientation {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }
        for encounter in PuzzlePalaceEncounterCatalog.mirrorHallRotation {
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }
        for family in PuzzlePalaceEncounterCatalog.pathTileFamilies {
            let encounter = family[0]
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }

        XCTAssertFalse(
            PuzzlePalaceDirector.palaceRestorationComplete(profile: profile),
            "The finale must not unlock before Command Gears is independently restored."
        )

        for family in PuzzlePalaceEncounterCatalog.commandGearFamilies {
            let encounter = family[0]
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }

        XCTAssertFalse(
            PuzzlePalaceDirector.palaceRestorationComplete(profile: profile),
            "The finale must not unlock before Bug Lantern debugging is independently restored."
        )
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)

        for family in PuzzlePalaceEncounterCatalog.bugLanternFamilies {
            let encounter = family[0]
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }

        XCTAssertFalse(
            PuzzlePalaceDirector.palaceRestorationComplete(profile: profile),
            "The finale must not unlock before Advanced Bug Lantern sequence debugging is independently restored."
        )
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSingleStep).state, .new)
        XCTAssertEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)

        for family in PuzzlePalaceEncounterCatalog.bugRepairFamilies {
            let encounter = family[0]
            record(id: encounter.id, skillID: encounter.skillID,
                   representation: encounter.representation, mechanicID: encounter.mechanicID,
                   transfer: encounter.transferContext)
        }

        XCTAssertTrue(PuzzlePalaceDirector.bugRepairComplete(profile: profile))
        XCTAssertTrue(PuzzlePalaceDirector.palaceRestorationComplete(profile: profile))
        XCTAssertNotEqual(profile.progress(for: PuzzleSkills.debugSequence).state, .new)
    }


}
