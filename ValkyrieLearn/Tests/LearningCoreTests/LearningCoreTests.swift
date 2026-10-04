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


    func testEveryPrerequisiteAppearsEarlierInDevelopmentalOrder() {
        let orderByID = Dictionary(uniqueKeysWithValues: MathSkillCatalog.descriptors.map { ($0.id, $0.developmentalOrder) })

        for descriptor in MathSkillCatalog.descriptors {
            XCTAssertFalse(descriptor.title.isEmpty)
            XCTAssertFalse(descriptor.representations.isEmpty)

            for prerequisite in descriptor.definition.prerequisites {
                guard let prerequisiteOrder = orderByID[prerequisite] else {
                    XCTFail("Missing descriptor for prerequisite \(prerequisite.rawValue)")
                    continue
                }
                XCTAssertLessThan(
                    prerequisiteOrder,
                    descriptor.developmentalOrder,
                    "\(descriptor.id.rawValue) depends on a later skill \(prerequisite.rawValue)"
                )
            }
        }
    }


    private func sessionEncounter(
        id: String,
        skill: SkillID,
        mechanic: String,
        target: Int,
        representation: Representation = .concrete,
        depth: Int = 0
    ) -> LearningEncounter {
        LearningEncounter(
            id: id,
            skillID: skill,
            mechanicID: mechanic,
            representation: representation,
            operation: .counting,
            initialQuantity: 0,
            targetQuantity: target,
            prompt: "Session test \(target)",
            context: "sessionPlanner",
            challengeDepth: depth
        )
    }

    func testSessionPlannerBuildsDefault6020155Mix() throws {
        let learningSkill = SkillID(rawValue: "session.learning")
        let reviewSkill = SkillID(rawValue: "session.review")
        let stretchSkill = SkillID(rawValue: "session.stretch")
        let confidenceSkill = SkillID(rawValue: "session.confidence")

        let graph = try SkillGraph([
            SkillDefinition(learningSkill),
            SkillDefinition(reviewSkill),
            SkillDefinition(stretchSkill),
            SkillDefinition(confidenceSkill)
        ])

        var profile = LearnerProfile()
        profile.skills[learningSkill.rawValue] = SkillProgress(state: .developing)

        var review = SkillProgress(state: .secure)
        review.reviewDate = epoch.addingTimeInterval(-86_400)
        profile.skills[reviewSkill.rawValue] = review

        profile.skills[stretchSkill.rawValue] = SkillProgress(state: .new)
        profile.skills[confidenceSkill.rawValue] = SkillProgress(state: .mastered)

        var candidates: [LearningEncounter] = []
        for i in 0..<12 {
            candidates.append(sessionEncounter(
                id: "learn-\(String(format: "%02d", i))",
                skill: learningSkill,
                mechanic: "learn\(i % 3)",
                target: 10 + i
            ))
        }
        for i in 0..<4 {
            candidates.append(sessionEncounter(
                id: "review-\(i)",
                skill: reviewSkill,
                mechanic: "review\(i % 2)",
                target: 100 + i
            ))
        }
        for i in 0..<3 {
            candidates.append(sessionEncounter(
                id: "stretch-\(i)",
                skill: stretchSkill,
                mechanic: "stretch\(i % 2)",
                target: 200 + i
            ))
        }
        candidates.append(sessionEncounter(
            id: "confidence-0",
            skill: confidenceSkill,
            mechanic: "confidence",
            target: 300
        ))

        let planner = SessionPlanner(
            graph: graph,
            stretchSkillIDs: [stretchSkill]
        )
        let plan = planner.plan(
            for: profile,
            candidates: candidates,
            encounterCount: 20,
            now: epoch
        )

        XCTAssertEqual(plan.desiredLaneCounts[.learning], 12)
        XCTAssertEqual(plan.desiredLaneCounts[.review], 4)
        XCTAssertEqual(plan.desiredLaneCounts[.stretch], 3)
        XCTAssertEqual(plan.desiredLaneCounts[.confidence], 1)

        XCTAssertEqual(plan.actualLaneCounts, plan.desiredLaneCounts)
        XCTAssertEqual(plan.encounterCount, 20)
        XCTAssertEqual(plan.unfilledEncounterCount, 0)
        XCTAssertEqual(plan.explorationBreakCount, 4)
        XCTAssertEqual(Set(plan.encounters.map { $0.encounter.fingerprint }).count, 20)
    }

    func testSessionPlannerInsertsBreakInsteadOfUsingSameMechanicThreeTimes() throws {
        let skill = SkillID(rawValue: "session.singleMechanic")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()
        profile.skills[skill.rawValue] = SkillProgress(state: .developing)

        let candidates = (0..<5).map {
            sessionEncounter(
                id: "same-mechanic-\($0)",
                skill: skill,
                mechanic: "crystalCart",
                target: 20 + $0
            )
        }

        let planner = SessionPlanner(
            graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )
        let plan = planner.plan(for: profile, candidates: candidates, encounterCount: 5, now: epoch)

        XCTAssertEqual(plan.encounterCount, 5)
        XCTAssertGreaterThanOrEqual(plan.explorationBreakCount, 2)

        var consecutive = 0
        var previousMechanic: String?
        for beat in plan.beats {
            switch beat {
            case .explorationBreak:
                consecutive = 0
                previousMechanic = nil

            case let .encounter(item):
                if item.encounter.mechanicID == previousMechanic {
                    consecutive += 1
                } else {
                    consecutive = 1
                    previousMechanic = item.encounter.mechanicID
                }
                XCTAssertLessThanOrEqual(consecutive, 2)
            }
        }
    }

    func testSessionPlannerReallocatesUnavailableLanesWithoutRepeatingFingerprints() throws {
        let skill = SkillID(rawValue: "session.reallocate")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()
        profile.skills[skill.rawValue] = SkillProgress(state: .developing)

        let candidates = (0..<10).map {
            sessionEncounter(
                id: "reallocate-\($0)",
                skill: skill,
                mechanic: "mechanic\($0 % 3)",
                target: 30 + $0
            )
        }

        let planner = SessionPlanner(
            graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )
        let plan = planner.plan(for: profile, candidates: candidates, encounterCount: 10, now: epoch)

        XCTAssertEqual(plan.encounterCount, 10)
        XCTAssertEqual(plan.actualLaneCounts[.learning], 10)
        XCTAssertEqual(plan.actualLaneCounts[.review], 0)
        XCTAssertEqual(plan.actualLaneCounts[.stretch], 0)
        XCTAssertEqual(plan.actualLaneCounts[.confidence], 0)
        XCTAssertEqual(Set(plan.encounters.map { $0.encounter.fingerprint }).count, 10)
    }

    func testSessionPlannerNeverUsesRelabeledExactDuplicateMath() throws {
        let skill = SkillID(rawValue: "session.duplicate")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()
        profile.skills[skill.rawValue] = SkillProgress(state: .developing)

        let first = sessionEncounter(id: "first", skill: skill, mechanic: "cart", target: 7)
        let relabeled = LearningEncounter(
            id: "relabeled",
            skillID: skill,
            mechanicID: first.mechanicID,
            representation: first.representation,
            operation: first.operation,
            initialQuantity: first.initialQuantity,
            targetQuantity: first.targetQuantity,
            prompt: "Different words, same math",
            context: first.context,
            challengeDepth: first.challengeDepth
        )
        let different = sessionEncounter(id: "different", skill: skill, mechanic: "scale", target: 8)

        let planner = SessionPlanner(
            graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )
        let plan = planner.plan(
            for: profile,
            candidates: [first, relabeled, different],
            encounterCount: 3,
            now: epoch
        )

        XCTAssertEqual(plan.encounterCount, 2)
        XCTAssertEqual(plan.unfilledEncounterCount, 1)
        XCTAssertEqual(Set(plan.encounters.map { $0.encounter.fingerprint }).count, 2)
    }

    func testSessionPlannerStretchRequiresPrerequisiteReadiness() throws {
        let foundation = SkillID(rawValue: "session.foundation")
        let stretch = SkillID(rawValue: "session.readyStretch")
        let graph = try SkillGraph([
            SkillDefinition(foundation),
            SkillDefinition(stretch, prerequisites: [foundation])
        ])
        let candidate = sessionEncounter(
            id: "stretch-ready",
            skill: stretch,
            mechanic: "numberBondMachine",
            target: 10,
            depth: 1
        )
        let planner = SessionPlanner(
            graph: graph,
            stretchSkillIDs: [stretch],
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )

        var profile = LearnerProfile()
        var blocked = planner.plan(for: profile, candidates: [candidate], encounterCount: 1, now: epoch)
        XCTAssertEqual(blocked.encounterCount, 0)

        profile.skills[foundation.rawValue] = SkillProgress(state: .developing)
        blocked = planner.plan(for: profile, candidates: [candidate], encounterCount: 1, now: epoch)
        XCTAssertEqual(blocked.encounterCount, 1)
        XCTAssertEqual(blocked.encounters.first?.lane, .stretch)
    }

    func testMathCatalogBuildsPlannerWithReadinessBasedStretchSkills() throws {
        let planner = try MathSkillCatalog.sessionPlanner(
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )

        XCTAssertEqual(planner.graph.skills.count, MathSkillCatalog.descriptors.count)
        XCTAssertEqual(
            planner.stretchSkillIDs,
            Set(MathSkillCatalog.stretchSkills.map(\.id))
        )
        XCTAssertEqual(planner.desiredLaneCounts(total: 20)[.learning], 12)
        XCTAssertEqual(planner.desiredLaneCounts(total: 20)[.review], 4)
        XCTAssertEqual(planner.desiredLaneCounts(total: 20)[.stretch], 3)
        XCTAssertEqual(planner.desiredLaneCounts(total: 20)[.confidence], 1)
    }


    func testSessionPlannerDeepensChallengeAfterThreeEasyIndependentSuccesses() throws {
        let skill = SkillID(rawValue: "session.deepen")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()

        for i in 0..<3 {
            MasteryEngine().record(
                evidence(i, skill: skill, representation: .concrete, easy: true),
                in: &profile
            )
        }

        let easy = sessionEncounter(
            id: "deepen-easy",
            skill: skill,
            mechanic: "cart",
            target: 8,
            depth: 0
        )
        let deeper = sessionEncounter(
            id: "deepen-reason",
            skill: skill,
            mechanic: "pipMistake",
            target: 8,
            representation: .reasoning,
            depth: 1
        )

        let planner = SessionPlanner(
            graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )
        let plan = planner.plan(
            for: profile,
            candidates: [easy, deeper],
            encounterCount: 1,
            now: epoch
        )

        XCTAssertEqual(plan.encounterCount, 1)
        XCTAssertEqual(plan.encounters.first?.encounter.id, deeper.id)
        XCTAssertEqual(plan.encounters.first?.lane, .stretch)
    }

    func testSessionPlannerChangesRepresentationAfterRepeatedStruggle() throws {
        let skill = SkillID(rawValue: "session.represent")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()

        MasteryEngine().record(
            evidence(1, skill: skill, outcome: .incorrect, representation: .concrete),
            in: &profile
        )
        MasteryEngine().record(
            evidence(2, skill: skill, outcome: .incorrect, representation: .concrete),
            in: &profile
        )

        let sameRepresentation = sessionEncounter(
            id: "same-representation",
            skill: skill,
            mechanic: "cart",
            target: 6,
            representation: .concrete
        )
        let changedRepresentation = sessionEncounter(
            id: "changed-representation",
            skill: skill,
            mechanic: "pictureGate",
            target: 6,
            representation: .pictorial
        )

        let planner = SessionPlanner(
            graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0)
        )
        let plan = planner.plan(
            for: profile,
            candidates: [sameRepresentation, changedRepresentation],
            encounterCount: 1,
            now: epoch
        )

        XCTAssertEqual(plan.encounterCount, 1)
        XCTAssertEqual(plan.encounters.first?.encounter.id, changedRepresentation.id)
        XCTAssertEqual(plan.encounters.first?.lane, .learning)
    }


    func testChallengeGateRequiresSecurePerformanceAndPrerequisites() throws {
        let graph = try MathSkillCatalog.graph()
        var profile = LearnerProfile()

        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        XCTAssertFalse(
            ChallengeGateCatalog.canStart(for: profile, graph: graph),
            "Secure source labels alone must not bypass missing prerequisites."
        )

        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        XCTAssertTrue(ChallengeGateCatalog.canStart(for: profile, graph: graph))

        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .developing)
        XCTAssertFalse(
            ChallengeGateCatalog.canStart(for: profile, graph: graph),
            "Placement readiness must not count as secure performance."
        )
    }

    func testChallengeGateSessionUsesThreeDifferentMechanics() throws {
        let graph = try MathSkillCatalog.graph()
        var profile = LearnerProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        let session = try XCTUnwrap(
            ChallengeGateCatalog.makeSession(for: profile, graph: graph)
        )

        XCTAssertEqual(session.encounterIDs.count, ChallengeGateCatalog.challengeCount)
        XCTAssertEqual(session.rewardID, .moonLantern)

        let encounters = session.encounterIDs.compactMap { ChallengeGateCatalog.encounter(id: $0) }
        XCTAssertEqual(encounters.count, ChallengeGateCatalog.challengeCount)
        XCTAssertEqual(
            Set(encounters.map(\.mechanicID)).count,
            ChallengeGateCatalog.challengeCount
        )
        XCTAssertTrue(encounters.allSatisfy { $0.challengeDepth > 0 })
        XCTAssertTrue(encounters.allSatisfy(MathManipulativeSupport.supports))
    }

    func testChallengeGateSessionProgressCannotSkipUnknownEncounter() throws {
        let graph = try MathSkillCatalog.graph()
        var profile = LearnerProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        var session = try XCTUnwrap(
            ChallengeGateCatalog.makeSession(for: profile, graph: graph)
        )

        XCTAssertFalse(session.isComplete)
        XCTAssertFalse(session.markCompleted("not-in-this-gate"))
        XCTAssertEqual(session.completedCount, 0)

        for encounterID in session.encounterIDs {
            XCTAssertTrue(session.markCompleted(encounterID))
        }

        XCTAssertTrue(session.isComplete)
        XCTAssertNil(session.nextEncounterID)
    }

    func testStoryTreeRewardUnlockAndPlacementArePersistentModelState() throws {
        var profile = LearnerProfile()

        XCTAssertFalse(profile.hasStoryReward(.moonLantern))
        XCTAssertEqual(profile.storyRewardPlacement(.moonLantern), 0)
        XCTAssertEqual(profile.cycleStoryRewardPlacement(.moonLantern, slotCount: 3), 0)

        XCTAssertTrue(profile.unlockStoryReward(.moonLantern))
        XCTAssertFalse(profile.unlockStoryReward(.moonLantern))
        XCTAssertEqual(profile.cycleStoryRewardPlacement(.moonLantern, slotCount: 3), 1)
        XCTAssertEqual(profile.cycleStoryRewardPlacement(.moonLantern, slotCount: 3), 2)

        let data = try JSONEncoder().encode(profile)
        let restored = try JSONDecoder().decode(LearnerProfile.self, from: data)

        XCTAssertTrue(restored.hasStoryReward(.moonLantern))
        XCTAssertEqual(restored.storyRewardPlacement(.moonLantern), 2)
    }

    func testLearnerProfileDecodesBeforeStoryRewardsExisted() throws {
        let legacyJSON = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "schemaVersion": 1,
          "skills": {},
          "recentActivities": [],
          "usedFingerprints": []
        }
        """.data(using: .utf8)!

        let profile = try JSONDecoder().decode(LearnerProfile.self, from: legacyJSON)
        XCTAssertFalse(profile.hasStoryReward(.moonLantern))
        XCTAssertEqual(profile.storyRewardPlacement(.moonLantern), 0)
    }

}