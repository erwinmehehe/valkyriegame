import XCTest
@testable import LearningCore

final class LearningCoreTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 1_700_000_000)
    func evidence(_ index: Int, skill: SkillID = MathSkills.quantity, support: SupportLevel = .independent,
                  outcome: Outcome = .correct, representation: Representation = .concrete,
                  day: Int = 0, transfer: Bool = false, easy: Bool = false) -> LearningEvidence {
        LearningEvidence(encounterID: "test-\(index)", skillID: skill, outcome: outcome,
            supportLevel: support, representation: representation, timestamp: epoch.addingTimeInterval(Double(day)*86_400),
            transferContext: transfer, easySuccess: easy)
    }
    func testPrerequisitesAndUnknownSkill() throws {
        let graph = try MathSkills.graph(); var profile = LearnerProfile()
        XCTAssertTrue(graph.isEligible(MathSkills.quantity, for: profile))
        XCTAssertFalse(graph.isEligible(MathSkills.addition, for: profile))
        profile.skills[MathSkills.counting.rawValue] = SkillProgress(state: .developing)
        XCTAssertTrue(graph.isEligible(MathSkills.addition, for: profile))
        XCTAssertFalse(graph.isEligible(MathSkills.missing, for: profile))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.bonds10.rawValue] = SkillProgress(state: .reviewDue)
        XCTAssertTrue(graph.isEligible(MathSkills.missing, for: profile))
        XCTAssertFalse(graph.isEligible(SkillID(rawValue: "unknown"), for: profile))
    }
    func testInvalidGraphsAreRejected() {
        XCTAssertThrowsError(try SkillGraph([SkillDefinition(MathSkills.quantity), SkillDefinition(MathSkills.quantity)]))
        XCTAssertThrowsError(try SkillGraph([SkillDefinition(MathSkills.quantity, prerequisites: [MathSkills.counting])]))
        XCTAssertThrowsError(try SkillGraph([SkillDefinition(MathSkills.quantity, prerequisites: [MathSkills.counting]),
                                           SkillDefinition(MathSkills.counting, prerequisites: [MathSkills.quantity])]))
    }
    func testStatesRequireRepeatedDelayedVariedTransferEvidence() {
        var profile = LearnerProfile(); let engine = MasteryEngine()
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .new)
        engine.record(evidence(1), in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .learning)
        engine.record(evidence(2), in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .developing)
        engine.record(evidence(3), in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .secure)
        for i in 4...6 { engine.record(evidence(i), in: &profile) }
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .secure)
        engine.record(evidence(7, representation: .pictorial, day: 3), in: &profile)
        engine.record(evidence(8, representation: .story, day: 8, transfer: true), in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .mastered)
        ReviewScheduler().markDue(in: &profile, at: epoch.addingTimeInterval(16 * 86_400))
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .reviewDue)
    }
    func testAssistanceNeverCountsLikeIndependentMastery() {
        for support in [SupportLevel.lightHint, .strongHint, .demonstration] {
            var profile = LearnerProfile()
            for i in 0..<12 { MasteryEngine().record(evidence(i, support: support, representation: .story, day: i, transfer: true), in: &profile) }
            XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .learning)
        }
        XCTAssertGreaterThan(SupportLevel.independent.weight, SupportLevel.lightHint.weight)
        XCTAssertGreaterThan(SupportLevel.lightHint.weight, SupportLevel.strongHint.weight)
        XCTAssertGreaterThan(SupportLevel.strongHint.weight, SupportLevel.demonstration.weight)
    }
    func testDuplicateEvidenceAndRepeatedEncounterDoNotInflateMastery() {
        var profile = LearnerProfile(); let item = evidence(1)
        MasteryEngine().record(item, in: &profile); MasteryEngine().record(item, in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).evidence.count, 1)
        for _ in 0..<10 { MasteryEngine().record(evidence(1), in: &profile) }
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .learning)
    }
    func testRepeatedStruggleDemotesAndChangesRepresentation() {
        var profile = LearnerProfile()
        for i in 0..<3 { MasteryEngine().record(evidence(i), in: &profile) }
        MasteryEngine().record(evidence(4, outcome: .incorrect), in: &profile)
        MasteryEngine().record(evidence(5, outcome: .incorrect), in: &profile)
        XCTAssertEqual(profile.progress(for: MathSkills.quantity).state, .learning)
        XCTAssertEqual(EngagementDirector().adjustment(for: MathSkills.quantity, profile: profile), .changeRepresentation)
    }
    func testEasySuccessHookAndSelectionRequireDeeperContent() throws {
        var profile = LearnerProfile()
        for i in 0..<3 { MasteryEngine().record(evidence(i, easy: true), in: &profile) }
        XCTAssertEqual(EngagementDirector().adjustment(for: MathSkills.quantity, profile: profile), .deepenChallenge)
        let director = AdaptiveDirector(graph: try MathSkills.graph())
        XCTAssertEqual(director.next(for: profile, candidates: [MathFoundation.encounters[0]], now: epoch), .needsContent(MathSkills.quantity))
    }
    func testSelectionRespectsEligibilityAndMechanicLimit() throws {
        var profile = LearnerProfile(); let director = AdaptiveDirector(graph: try MathSkills.graph())
        let count = MathFoundation.encounters[0]; let addition = MathFoundation.encounters[8]
        XCTAssertEqual(director.next(for: profile, candidates: [addition, count], now: epoch), .encounter(count))
        for i in 0..<2 {
            profile.recordActivity(ActivityRecord(fingerprint: "earlier-\(i)", mechanicID: count.mechanicID, timestamp: epoch))
        }
        XCTAssertEqual(director.next(for: profile, candidates: [count], now: epoch), .explorationBreak)
        profile.recordActivity(ActivityRecord(fingerprint: "wind", mechanicID: "pipWind", timestamp: epoch))
        XCTAssertEqual(director.next(for: profile, candidates: [count], now: epoch), .encounter(count))
        profile.begin(count, at: epoch)
        XCTAssertEqual(director.next(for: profile, candidates: [count], now: epoch), .needsContent(MathSkills.quantity))
    }
    func testAlternativeMechanicPreferredAndExactMathCannotBeRelabeled() throws {
        var profile = LearnerProfile(); let first = MathFoundation.encounters[0]
        profile.begin(first, at: epoch)
        let duplicate = LearningEncounter(id: "renamed", skillID: first.skillID, operation: first.operation,
            initialQuantity: first.initialQuantity, targetQuantity: first.targetQuantity, prompt: "Same math, new words")
        XCTAssertFalse(EngagementDirector().allows(duplicate, profile: profile))
        profile.recordActivity(ActivityRecord(fingerprint: "other", mechanicID: "crystalCart", timestamp: epoch))
        let alternative = LearningEncounter(id: "scale-test", skillID: MathSkills.quantity, mechanicID: "balanceScale",
            operation: .counting, initialQuantity: 0, targetQuantity: 5, prompt: "Test-only alternate mechanic")
        XCTAssertEqual(AdaptiveDirector(graph: try MathSkills.graph()).next(for: profile, candidates: [MathFoundation.encounters[1], alternative], now: epoch), .encounter(alternative))
    }
    func testStruggleSelectionUsesDifferentRepresentationAndWorldChange() throws {
        var profile = LearnerProfile()
        for i in 0..<2 { MasteryEngine().record(evidence(i, outcome: .incorrect), in: &profile) }
        let alternate = LearningEncounter(id: "picture-test", skillID: MathSkills.quantity,
            representation: .pictorial, operation: .counting, initialQuantity: 0, targetQuantity: 5, prompt: "Pictorial test")
        let director = AdaptiveDirector(graph: try MathSkills.graph())
        XCTAssertEqual(director.next(for: profile, candidates: [MathFoundation.encounters[0], alternate], now: epoch), .encounter(alternate))
        profile.recordActivity(ActivityRecord(fingerprint: "begin", mechanicID: "crystalCart", timestamp: epoch))
        XCTAssertEqual(director.next(for: profile, candidates: [alternate], now: epoch.addingTimeInterval(181)), .explorationBreak)
    }
    func testProfileAndCartRoundTrip() throws {
        var profile = LearnerProfile(); profile.begin(MathFoundation.encounters[0], at: epoch)
        MasteryEngine().record(evidence(1, support: .lightHint), in: &profile)
        XCTAssertEqual(try JSONDecoder().decode(LearnerProfile.self, from: JSONEncoder().encode(profile)), profile)
        var cart = try CrystalCartModel(encounter: MathFoundation.encounters[0], at: epoch)
        cart.add(); cart.apply(ScaffoldingEngine().next(after: .independent))
        let restored = try JSONDecoder().decode(CrystalCartModel.self, from: JSONEncoder().encode(cart))
        XCTAssertEqual(restored.quantity, 1); XCTAssertEqual(restored.support, .lightHint)
    }
 

    private func placementEvidence(
        _ probe: PlacementProbe,
        outcome: Outcome = .correct,
        support: SupportLevel = .independent,
        easy: Bool = false
    ) -> LearningEvidence {
        LearningEvidence(
            encounterID: probe.encounter.id,
            skillID: probe.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: probe.encounter.representation,
            mechanicID: probe.encounter.mechanicID,
            timestamp: epoch,
            easySuccess: easy
        )
    }

    func testPlacementJumpsForwardThenBracketsIndependentCeiling() {
        let engine = PlacementEngine(probes: MathPlacement.probes)
        var session = engine.begin(startBand: 2)

        let compare = engine.nextProbe(for: session)!
        XCTAssertEqual(compare.band, 2)
        engine.record(placementEvidence(compare, easy: true), for: compare, in: &session)

        let subtraction = engine.nextProbe(for: session)!
        XCTAssertEqual(subtraction.band, 4)
        engine.record(placementEvidence(subtraction, outcome: .incorrect), for: subtraction, in: &session)

        let addition = engine.nextProbe(for: session)!
        XCTAssertEqual(addition.band, 3)
        engine.record(placementEvidence(addition), for: addition, in: &session)

        XCTAssertTrue(session.isComplete)
        XCTAssertNil(engine.nextProbe(for: session))

        let recommendation = engine.recommendation(for: session)
        XCTAssertEqual(recommendation.highestIndependentBand, 3)
        XCTAssertEqual(recommendation.firstSupportNeededBand, 4)
        XCTAssertEqual(recommendation.suggestedBand, 4)
        XCTAssertEqual(recommendation.suggestedSkillID, MathSkills.subtraction)
        XCTAssertEqual(recommendation.confidence, .high)
    }

    func testPlacementSupportedSuccessStepsBackWithoutGrantingMastery() {
        let engine = PlacementEngine(probes: MathPlacement.probes)
        var session = engine.begin(startBand: 6)
        let probe = engine.nextProbe(for: session)!
        XCTAssertEqual(probe.band, 6)

        let item = placementEvidence(probe, support: .lightHint)
        engine.record(item, for: probe, in: &session)

        XCTAssertEqual(session.firstSupportNeededBand, 6)
        XCTAssertEqual(session.nextBand, 5)

        var profile = LearnerProfile()
        XCTAssertEqual(profile.progress(for: probe.skillID).state, .new)
        MasteryEngine().record(item, in: &profile)
        XCTAssertEqual(profile.progress(for: probe.skillID).state, .learning)
    }

    func testPlacementRejectsMismatchedOrDuplicateEvidence() {
        let engine = PlacementEngine(probes: MathPlacement.probes)
        var session = engine.begin(startBand: 3)
        let probe = engine.nextProbe(for: session)!

        let wrongEncounter = LearningEvidence(
            encounterID: "not-this-probe",
            skillID: probe.skillID,
            outcome: .correct,
            timestamp: epoch
        )
        engine.record(wrongEncounter, for: probe, in: &session)
        XCTAssertEqual(session.completedProbeCount, 0)

        let valid = placementEvidence(probe)
        engine.record(valid, for: probe, in: &session)
        XCTAssertEqual(session.completedProbeCount, 1)

        engine.record(valid, for: probe, in: &session)
        XCTAssertEqual(session.completedProbeCount, 1)
    }

    func testPlacementCanReachAdvancedReasoningWithoutAgeCeiling() {
        let engine = PlacementEngine(probes: MathPlacement.probes, maxProbes: 8)
        var session = engine.begin(startBand: 7)

        while let probe = engine.nextProbe(for: session), !session.isComplete {
            engine.record(placementEvidence(probe, easy: true), for: probe, in: &session)
        }

        XCTAssertEqual(session.highestIndependentBand, 9)
        XCTAssertTrue(session.isComplete)

        let recommendation = engine.recommendation(for: session)
        XCTAssertEqual(recommendation.suggestedBand, 9)
        XCTAssertEqual(recommendation.suggestedSkillID, MathSkills.reasoning)
        XCTAssertEqual(recommendation.confidence, .high)
    }


    func testMathSkillGraphV2HasFineGrainedUniqueCatalog() throws {
        let descriptors = MathSkillCatalog.descriptors
        XCTAssertGreaterThanOrEqual(descriptors.count, 60)
        XCTAssertLessThanOrEqual(descriptors.count, 80)

        let ids = Set(descriptors.map(\.id))
        XCTAssertEqual(ids.count, descriptors.count)

        let orders = descriptors.map(\.developmentalOrder)
        XCTAssertEqual(Set(orders).count, descriptors.count)
        XCTAssertEqual(orders.min(), 1)
        XCTAssertEqual(orders.max(), descriptors.count)

        let graph = try MathSkillCatalog.graph()
        XCTAssertEqual(graph.skills.count, descriptors.count)

        for strand in MathStrand.allCases {
            XCTAssertFalse(MathSkillCatalog.skills(in: strand).isEmpty, "Missing skills for \(strand)")
        }
    }

    func testMathSkillCatalogPreservesConcreteToReasoningProgression() {
        XCTAssertEqual(MathSkillCatalog.descriptor(for: MathSkills.addition)?.strand, .addition)
        XCTAssertTrue(MathSkillCatalog.descriptor(for: MathSkills.addition)?.representations.contains(.concrete) == true)
        XCTAssertTrue(MathSkillCatalog.descriptor(for: MathSkills.addSymbols10)?.representations.contains(.symbolic) == true)
        XCTAssertTrue(MathSkillCatalog.descriptor(for: MathSkills.reasoning)?.representations.contains(.reasoning) == true)
        XCTAssertTrue(MathSkillCatalog.descriptor(for: MathSkills.multiStep)?.representations.contains(.story) == true)
    }

    func testStretchSkillsAreReadinessGatedNotAgeGated() throws {
        let graph = try MathSkillCatalog.graph()
        var profile = LearnerProfile()

        XCTAssertFalse(graph.isEligible(MathSkills.repeatedAddition, for: profile))

        profile.skills[MathSkills.equalGroups.rawValue] = SkillProgress(state: .developing)
        profile.skills[MathSkills.addWithin20.rawValue] = SkillProgress(state: .secure)

        XCTAssertTrue(graph.isEligible(MathSkills.repeatedAddition, for: profile))
        XCTAssertEqual(MathSkillCatalog.stretchSkills.count, 5)
        XCTAssertTrue(MathSkillCatalog.stretchSkills.allSatisfy(\.isStretch))
    }

    func testPlacementProbeSkillsExistInV2Graph() throws {
        let graph = try MathSkillCatalog.graph()
        for probe in MathPlacement.probes {
            XCTAssertNotNil(graph.skills[probe.skillID], "Placement probe references unknown skill \(probe.skillID.rawValue)")
            XCTAssertNotNil(MathSkillCatalog.descriptor(for: probe.skillID))
        }
    }

    func testKeyConceptualPrerequisitesMatchIntendedLearningSequence() throws {
        let graph = try MathSkillCatalog.graph()

        XCTAssertEqual(
            Set(graph.skills[MathSkills.bonds10]?.prerequisites ?? []),
            Set([MathSkills.compose10, MathSkills.decompose10])
        )
        XCTAssertEqual(
            Set(graph.skills[MathSkills.missing]?.prerequisites ?? []),
            Set([MathSkills.addition, MathSkills.bonds10])
        )
        XCTAssertEqual(
            Set(graph.skills[MathSkills.compareTwoDigit]?.prerequisites ?? []),
            Set([MathSkills.readTwoDigit, MathSkills.compare])
        )
        XCTAssertEqual(
            Set(graph.skills[MathSkills.halves]?.prerequisites ?? []),
            Set([MathSkills.equalSharing, MathSkills.composeShapes])
        )
    }

}