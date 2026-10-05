import XCTest
@testable import LearningCore

final class LiteracySkillGraphTests: XCTestCase {
    func testLiteracyCatalogBuildsAcyclicGraphAndContainsEveryDescriptor() throws {
        let graph = try LiteracySkillCatalog.graph()

        XCTAssertEqual(graph.skills.count, LiteracySkillCatalog.descriptors.count)
        XCTAssertEqual(
            Set(graph.skills.keys),
            Set(LiteracySkillCatalog.descriptors.map(\.id))
        )
    }

    func testEveryLiteracyPrerequisiteAppearsEarlierInDevelopmentalOrder() {
        let orderByID = Dictionary(
            uniqueKeysWithValues: LiteracySkillCatalog.descriptors.map {
                ($0.id, $0.developmentalOrder)
            }
        )

        for descriptor in LiteracySkillCatalog.descriptors {
            XCTAssertFalse(descriptor.title.isEmpty)
            XCTAssertFalse(descriptor.representations.isEmpty)
            XCTAssertFalse(descriptor.responseModes.isEmpty)
            XCTAssertFalse(descriptor.mechanicIDs.isEmpty)

            for prerequisite in descriptor.definition.prerequisites {
                guard let prerequisiteOrder = orderByID[prerequisite] else {
                    XCTFail("Missing descriptor for prerequisite \(prerequisite.rawValue)")
                    continue
                }
                XCTAssertLessThan(
                    prerequisiteOrder,
                    descriptor.developmentalOrder,
                    "\(descriptor.id.rawValue) depends on a later literacy skill"
                )
            }
        }
    }

    func testCVCDecodingRequiresOralAndPrintFoundations() throws {
        let graph = try LiteracySkillCatalog.graph()

        XCTAssertEqual(
            Set(graph.skills[LiteracySkills.blendCVC]?.prerequisites ?? []),
            Set([LiteracySkills.blendVC, LiteracySkills.oralBlendThree])
        )
        XCTAssertEqual(
            Set(graph.skills[LiteracySkills.decodeCVC]?.prerequisites ?? []),
            Set([LiteracySkills.blendCVC])
        )
        XCTAssertEqual(
            Set(graph.skills[LiteracySkills.encodeCVC]?.prerequisites ?? []),
            Set([LiteracySkills.segmentCVC, LiteracySkills.soundLetterMapping])
        )
    }

    func testCriticalPhonemeInstructionUsesRecordedAudio() {
        let audioSkills: [SkillID] = [
            LiteracySkills.sameDifferentSounds,
            LiteracySkills.beginningSoundMatch,
            LiteracySkills.endingSoundMatch,
            LiteracySkills.oralBlendTwo,
            LiteracySkills.oralBlendThree,
            LiteracySkills.segmentCVC,
            LiteracySkills.commonConsonantSounds,
            LiteracySkills.shortVowelSounds,
            LiteracySkills.soundLetterMapping
        ]

        for id in audioSkills {
            XCTAssertTrue(
                LiteracySkillCatalog.descriptor(for: id)?.requiresRecordedAudio == true,
                "Expected recorded audio modeling for \(id.rawValue)"
            )
        }
    }

    func testHiddenLiteracyPlacementUsesDirectTouchResponsesWithoutSpeechRecognition() throws {
        let graph = try LiteracySkillCatalog.graph()
        let probes = LiteracyPlacement.probes

        XCTAssertEqual(probes.map(\.band), probes.map(\.band).sorted())
        XCTAssertEqual(Set(probes.map(\.id)).count, probes.count)
        XCTAssertEqual(Set(probes.map(\.skillID)).count, probes.count)

        for probe in probes {
            XCTAssertNotNil(graph.skills[probe.skillID])
            XCTAssertNotNil(LiteracySkillCatalog.descriptor(for: probe.skillID))
            XCTAssertFalse(probe.promptIntent.isEmpty)

            switch probe.responseMode {
            case .listenAndChoose, .directTouch, .arrange, .pictureChoice, .storySequence, .creativeChoice:
                break
            }
        }
    }

    func testWordGardenCurriculumUsesPhysicalWorldMechanicsAcrossStrands() {
        let usedMechanics = Set(
            LiteracySkillCatalog.descriptors.flatMap(\.mechanicIDs)
        )

        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.soundFlower))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.rhymeVine))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.syllableBells))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.letterStones))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.seedBlendPath))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.wordBloom))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.storyLantern))
        XCTAssertTrue(usedMechanics.contains(WordGardenMechanicID.lumiReach))
    }

    func testFilipinoPathIsParallelAndPrerequisiteSafe() throws {
        let graph = try LiteracySkillCatalog.graph()

        XCTAssertEqual(
            graph.skills[LiteracySkills.filipinoSyllableAwareness]?.prerequisites,
            [LiteracySkills.filipinoOralVocabulary]
        )
        XCTAssertEqual(
            graph.skills[LiteracySkills.filipinoBeginningSounds]?.prerequisites,
            [LiteracySkills.filipinoSyllableAwareness]
        )
        XCTAssertEqual(
            graph.skills[LiteracySkills.filipinoSimpleComprehension]?.prerequisites,
            [LiteracySkills.filipinoOralVocabulary]
        )
    }

    func testLiteracyStretchSkillsAreDepthNotAgeCeilings() {
        let stretchIDs = Set(LiteracySkillCatalog.stretchSkills.map(\.id))

        XCTAssertTrue(stretchIDs.contains(LiteracySkills.manipulateInitialPhoneme))
        XCTAssertTrue(stretchIDs.contains(LiteracySkills.wordFamilyTransfer))
        XCTAssertTrue(stretchIDs.contains(LiteracySkills.simpleInference))
        XCTAssertTrue(stretchIDs.contains(LiteracySkills.createStorySequence))
        XCTAssertFalse(stretchIDs.contains(LiteracySkills.decodeCVC))
    }

    func testLiteracyPlacementStartsAboveTrivialSoundDiscrimination() throws {
        let engine = LiteracyPlacementEngine()
        let session = engine.begin()

        XCTAssertEqual(session.nextBand, 3)
        XCTAssertEqual(
            engine.nextProbe(for: session)?.skillID,
            LiteracySkills.beginningSoundMatch
        )
    }

    func testEasyIndependentLiteracyPlacementJumpsForwardAndOnlyMarksProvisionalReadiness() throws {
        let graph = try LiteracySkillCatalog.graph()
        let engine = LiteracyPlacementEngine()
        var session = engine.begin(startBand: 3)
        var profile = LearnerProfile()
        let probe = try XCTUnwrap(engine.nextProbe(for: session))

        engine.record(
            LiteracyPlacementResult(
                outcome: .correct,
                supportLevel: .independent,
                easySuccess: true
            ),
            for: probe,
            in: &session,
            profile: &profile,
            graph: graph
        )

        XCTAssertEqual(session.nextBand, 5)
        XCTAssertEqual(session.highestIndependentBand, 3)
        XCTAssertTrue(
            profile.placementReadySkillIDs?.contains(LiteracySkills.beginningSoundMatch) == true
        )
        XCTAssertTrue(
            profile.placementReadySkillIDs?.contains(LiteracySkills.sameDifferentSounds) == true
        )
        XCTAssertEqual(
            profile.progress(for: LiteracySkills.beginningSoundMatch).state,
            .new,
            "Diagnostic readiness must not masquerade as observed mastery."
        )
    }

    func testSupportedLiteracyPlacementStepsBackWithoutGrantingReadiness() throws {
        let graph = try LiteracySkillCatalog.graph()
        let engine = LiteracyPlacementEngine()
        var session = engine.begin(startBand: 5)
        var profile = LearnerProfile()
        let probe = try XCTUnwrap(engine.nextProbe(for: session))

        engine.record(
            LiteracyPlacementResult(
                outcome: .correct,
                supportLevel: .strongHint
            ),
            for: probe,
            in: &session,
            profile: &profile,
            graph: graph
        )

        XCTAssertEqual(session.nextBand, 4)
        XCTAssertEqual(session.firstSupportNeededBand, 5)
        XCTAssertTrue(profile.placementReadySkillIDs?.isEmpty ?? true)
    }

    func testLiteracyPlacementStopsAfterBracketingIndependentCeiling() throws {
        let graph = try LiteracySkillCatalog.graph()
        let engine = LiteracyPlacementEngine(maxProbes: 6)
        var session = engine.begin(startBand: 4)
        var profile = LearnerProfile()

        let independent = try XCTUnwrap(engine.nextProbe(for: session))
        XCTAssertEqual(independent.band, 4)
        engine.record(
            LiteracyPlacementResult(outcome: .correct),
            for: independent,
            in: &session,
            profile: &profile,
            graph: graph
        )
        XCTAssertFalse(session.isComplete)

        let support = try XCTUnwrap(engine.nextProbe(for: session))
        XCTAssertEqual(support.band, 5)
        engine.record(
            LiteracyPlacementResult(
                outcome: .incorrect,
                supportLevel: .independent
            ),
            for: support,
            in: &session,
            profile: &profile,
            graph: graph
        )

        XCTAssertTrue(session.isComplete)
        XCTAssertEqual(session.highestIndependentBand, 4)
        XCTAssertEqual(session.firstSupportNeededBand, 5)

        let recommendation = engine.recommendation(for: session)
        XCTAssertEqual(recommendation.suggestedBand, 5)
        XCTAssertEqual(recommendation.confidence, .high)
    }

    func testDuplicateLiteracyPlacementResponseCannotMoveTheCeilingTwice() throws {
        let graph = try LiteracySkillCatalog.graph()
        let engine = LiteracyPlacementEngine()
        var session = engine.begin(startBand: 3)
        var profile = LearnerProfile()
        let probe = try XCTUnwrap(engine.nextProbe(for: session))
        let result = LiteracyPlacementResult(
            outcome: .correct,
            supportLevel: .independent,
            easySuccess: true
        )

        engine.record(
            result,
            for: probe,
            in: &session,
            profile: &profile,
            graph: graph
        )
        let count = session.completedProbeCount
        let nextBand = session.nextBand

        engine.record(
            result,
            for: probe,
            in: &session,
            profile: &profile,
            graph: graph
        )

        XCTAssertEqual(session.completedProbeCount, count)
        XCTAssertEqual(session.nextBand, nextBand)
    }

}
