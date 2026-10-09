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

    func testSessionPlannerHonorsElapsedWorldChangeBeforeFirstEncounter() throws {
        let skill = SkillID(rawValue: "session.elapsed")
        let graph = try SkillGraph([SkillDefinition(skill)])
        var profile = LearnerProfile()
        profile.recordActivity(ActivityRecord(fingerprint: "old", mechanicID: "cart",
            skillID: skill, timestamp: epoch.addingTimeInterval(-181)))
        let candidate = sessionEncounter(id: "fresh", skill: skill, mechanic: "scale", target: 5)
        let planner = SessionPlanner(graph: graph,
            configuration: SessionPlannerConfiguration(explorationEveryEncounters: 0))
        let plan = planner.plan(for: profile, candidates: [candidate], encounterCount: 1, now: epoch)
        XCTAssertEqual(plan.beats.first, .explorationBreak)
        XCTAssertEqual(plan.explorationBreakCount, 1)
        XCTAssertEqual(plan.encounterCount, 1)

        profile.recordActivity(ActivityRecord(fingerprint: "real-exploration",
            mechanicID: "exploration", timestamp: epoch.addingTimeInterval(-10)))
        let refreshed = planner.plan(for: profile, candidates: [candidate], encounterCount: 1, now: epoch)
        XCTAssertEqual(refreshed.explorationBreakCount, 0)
        XCTAssertEqual(refreshed.encounterCount, 1)
        XCTAssertEqual(profile.recentActivities.count, 2, "Planning must not mutate live history")
    }


    func testParentSummaryDoesNotTurnPlacementReadinessIntoMastery() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        profile.markPlacementReady([
            MathSkills.quantity,
            MathSkills.counting,
            MathSkills.compare
        ])

        let summary = ParentMathSummaryBuilder.build(
            profile: profile,
            graph: graph,
            now: epoch
        )

        XCTAssertEqual(summary.placementReadyCount, 3)
        XCTAssertFalse(summary.strengths.contains { $0.id == MathSkills.compare })
        XCTAssertEqual(profile.progress(for: MathSkills.compare).state, .new)
    }

    func testStoryRewardAndPlacementRoundTrip() throws {
        var profile = LearnerProfile()
        XCTAssertTrue(profile.unlockStoryReward(.moonLantern))
        XCTAssertEqual(profile.cycleStoryRewardPlacement(.moonLantern, slotCount: 3), 1)

        let data = try JSONEncoder().encode(profile)
        let restored = try JSONDecoder().decode(LearnerProfile.self, from: data)

        XCTAssertTrue(restored.hasStoryReward(.moonLantern))
        XCTAssertEqual(restored.storyRewardPlacement(.moonLantern), 1)
    }


    func testParentSummaryDoesNotReportHiddenPlacementAsRecentLearning() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        let probe = try XCTUnwrap(MathAdventure.playableProbes.first)
        profile.begin(probe.encounter, at: epoch)
        profile.markPlacementReady([probe.skillID])

        let summary = ParentMathSummaryBuilder.build(
            profile: profile,
            graph: graph,
            now: epoch.addingTimeInterval(30)
        )

        XCTAssertNil(summary.recentSession)
        XCTAssertFalse(summary.strengths.contains { $0.id == probe.skillID })
        XCTAssertFalse(summary.developing.contains { $0.id == probe.skillID })
    }


    func testCrystalCartSupportsNativeSubtraction() throws {
        let encounter = LearningEncounter(
            id: "cart-subtract-test",
            skillID: MathSkills.subtraction,
            mechanicID: MathMechanicID.crystalCart,
            representation: .concrete,
            operation: .subtraction,
            initialQuantity: 8,
            targetQuantity: 5,
            prompt: "Eight crystals are here. Take away three."
        )

        XCTAssertTrue(MathManipulativeSupport.supports(encounter))
        var cart = try CrystalCartModel(encounter: encounter, at: epoch)
        XCTAssertEqual(cart.quantity, 8)
        XCTAssertTrue(cart.remove())
        XCTAssertTrue(cart.remove())
        XCTAssertTrue(cart.remove())
        XCTAssertEqual(cart.quantity, 5)
        XCTAssertEqual(cart.submit(at: epoch.addingTimeInterval(10))?.outcome, .correct)
    }

    func testPlayablePlacementIncludesSubtractionNowThatCartSupportsIt() {
        XCTAssertTrue(
            MathAdventure.playableProbes.contains {
                $0.skillID == MathSkills.subtraction
                    && $0.encounter.operation == .subtraction
                    && $0.encounter.mechanicID == MathMechanicID.crystalCart
            }
        )
    }


    func testPlayablePlacementReachesPlaceValueAndReasoningWithRealNativeMechanics() {
        let placeValue = MathAdventure.playableProbes.first {
            $0.skillID == MathSkills.placeValue
        }
        XCTAssertEqual(placeValue?.band, 8)
        XCTAssertEqual(placeValue?.encounter.mechanicID, MathMechanicID.placeValueFactory)
        XCTAssertNotNil(placeValue.flatMap { try? MathMechanicRuntime(encounter: $0.encounter) })

        let reasoning = MathAdventure.playableProbes.first {
            $0.skillID == MathSkills.reasoning
        }
        XCTAssertEqual(reasoning?.band, 9)
        XCTAssertEqual(reasoning?.encounter.mechanicID, MathMechanicID.numberBondMachine)
        XCTAssertEqual(reasoning?.encounter.representation, .reasoning)
        XCTAssertEqual(reasoning?.encounter.challengeDepth, 2)
    }

}

final class StarlightBridgeQuestTests: XCTestCase {
    func testQuestRequiresDiscoveryAndCannotInventOrDuplicateCrystals() throws {
        var quest = StarlightBridgeQuest()
        XCTAssertFalse(quest.discovered)
        XCTAssertFalse(quest.isComplete)
        XCTAssertFalse(quest.collect(0), "A crystal cannot be collected before discovery.")
        XCTAssertFalse(quest.install(0, into: 0))
        XCTAssertTrue(quest.discover())
        XCTAssertFalse(quest.discover())
        XCTAssertFalse(quest.collect(-1))
        XCTAssertFalse(quest.collect(StarlightBridgeQuest.crystalCount))
        XCTAssertTrue(quest.collect(0))
        XCTAssertFalse(quest.collect(0))
        XCTAssertEqual(quest.availableCrystals, [0])
        XCTAssertFalse(quest.install(1, into: 0), "Uncollected crystals cannot power sockets.")
        XCTAssertFalse(quest.install(0, into: -1))
        XCTAssertFalse(quest.install(0, into: StarlightBridgeQuest.crystalCount))
        XCTAssertEqual(quest.installedCount, 0)
    }

    func testQuestAllowsFreeChoiceButRequiresThreeDistinctInstalledCrystals() throws {
        var quest = StarlightBridgeQuest()
        XCTAssertTrue(quest.discover())
        for crystal in 0..<StarlightBridgeQuest.crystalCount {
            XCTAssertTrue(quest.collect(crystal))
        }
        XCTAssertEqual(quest.availableCrystals, [0, 1, 2])
        XCTAssertTrue(quest.install(2, into: 0))
        XCTAssertFalse(quest.install(2, into: 1), "Cannot install one crystal twice.")
        XCTAssertFalse(quest.install(0, into: 0), "Cannot overwrite a socket.")
        XCTAssertTrue(quest.install(0, into: 2))
        XCTAssertFalse(quest.isComplete)
        XCTAssertEqual(quest.availableCrystals, [1])
        XCTAssertTrue(quest.install(1, into: 1))
        XCTAssertTrue(quest.isComplete)
        XCTAssertEqual(quest.installedCrystals, [0: 2, 1: 1, 2: 0])
        XCTAssertTrue(quest.availableCrystals.isEmpty)
        XCTAssertFalse(quest.install(1, into: 0))
        XCTAssertFalse(quest.collect(1))
    }

    func testQuestAndLegacyLearnerProfilesRestoreWithoutChangingMastery() throws {
        let untouched = LearnerProfile()
        let encodedLegacy = try JSONEncoder().encode(untouched)
        var restored = try JSONDecoder().decode(LearnerProfile.self, from: encodedLegacy)
        XCTAssertNil(restored.starlightBridgeQuest)
        XCTAssertTrue(restored.skills.isEmpty)
        XCTAssertFalse(restored.hasStoryReward(.starlightBridgeCharm))

        var quest = StarlightBridgeQuest()
        XCTAssertTrue(quest.discover())
        XCTAssertTrue(quest.collect(1))
        restored.starlightBridgeQuest = quest
        let saved = try JSONEncoder().encode(restored)
        var resumed = try JSONDecoder().decode(LearnerProfile.self, from: saved)
        XCTAssertEqual(resumed.starlightBridgeQuest, quest)
        XCTAssertTrue(resumed.skills.isEmpty, "Collecting gems cannot manufacture mastery.")

        var recoveredQuest = try XCTUnwrap(resumed.starlightBridgeQuest)
        XCTAssertTrue(recoveredQuest.collect(0))
        XCTAssertTrue(recoveredQuest.collect(2))
        XCTAssertTrue(recoveredQuest.install(1, into: 2))
        XCTAssertTrue(recoveredQuest.install(0, into: 0))
        XCTAssertTrue(recoveredQuest.install(2, into: 1))
        resumed.starlightBridgeQuest = recoveredQuest
        XCTAssertTrue(try XCTUnwrap(
            JSONDecoder().decode(LearnerProfile.self, from: JSONEncoder().encode(resumed))
                .starlightBridgeQuest
        ).isComplete)
        XCTAssertTrue(resumed.skills.isEmpty)
    }

    func testLoadTrialModelsTwoDifferentWeightsAndLetsChildExperiment() throws {
        var quest = StarlightBridgeQuest()
        XCTAssertNil(quest.testBridge(with: .firefly), "An unrepaired bridge cannot be tested.")
        XCTAssertFalse(quest.toggleBrace(at: 0))
        XCTAssertTrue(quest.discover())
        for index in 0..<StarlightBridgeQuest.crystalCount {
            XCTAssertTrue(quest.collect(index))
            XCTAssertTrue(quest.install(index, into: index))
        }
        XCTAssertTrue(quest.isComplete)
        XCTAssertFalse(quest.hasDeliveredSupplies)
        XCTAssertFalse(quest.toggleBrace(at: -1))
        XCTAssertFalse(quest.toggleBrace(at: 3))
        XCTAssertEqual(quest.testBridge(with: .firefly), .crossed,
                       "The small rescued firefly needs no structural reinforcement.")
        XCTAssertEqual(quest.testBridge(with: .supplyCart), .stoppedAt(0))
        XCTAssertTrue(quest.toggleBrace(at: 2))
        XCTAssertEqual(quest.testBridge(with: .supplyCart), .stoppedAt(0),
                       "An unsupported left span is still weak.")
        XCTAssertTrue(quest.toggleBrace(at: 0))
        XCTAssertEqual(quest.braces, Set([0, 2]))
        XCTAssertFalse(quest.toggleBrace(at: 1),
                       "The child has only two braces; a third requires moving one.")
        XCTAssertEqual(quest.testBridge(with: .supplyCart), .crossed)
        XCTAssertTrue(quest.hasDeliveredSupplies)
        XCTAssertTrue(quest.toggleBrace(at: 0))
        XCTAssertTrue(quest.toggleBrace(at: 1))
        XCTAssertEqual(quest.testBridge(with: .supplyCart), .stoppedAt(0))
        XCTAssertEqual(quest.braces, Set([1, 2]))
        XCTAssertTrue(quest.hasDeliveredSupplies,
                      "Achievement should remain even when replaying experiments.")
        XCTAssertEqual(quest.trialsCompleted, 5)
    }

    func testLoadExperimentRestoresLegacySavesAndNeverGeneratesMathEvidence() throws {
        var quest = StarlightBridgeQuest()
        XCTAssertTrue(quest.discover())
        for index in 0..<StarlightBridgeQuest.crystalCount {
            XCTAssertTrue(quest.collect(index))
            XCTAssertTrue(quest.install(index, into: index))
        }
        XCTAssertTrue(quest.toggleBrace(at: 0))
        XCTAssertTrue(quest.toggleBrace(at: 2))
        XCTAssertEqual(quest.testBridge(with: .supplyCart), .crossed)
        let restored = try JSONDecoder().decode(
            StarlightBridgeQuest.self, from: JSONEncoder().encode(quest)
        )
        XCTAssertEqual(restored.braces, Set([0, 2]))
        XCTAssertEqual(restored.trialsCompleted, 1)
        XCTAssertTrue(restored.hasDeliveredSupplies)

        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(quest)) as? [String: Any])
        for key in ["reinforcedSpans", "successfulSupplyDelivery", "trialCount"] {
            legacy.removeValue(forKey: key)
        }
        let oldBytes = try JSONSerialization.data(withJSONObject: legacy)
        var upgraded = try JSONDecoder().decode(StarlightBridgeQuest.self, from: oldBytes)
        XCTAssertTrue(upgraded.isComplete, "Older crystal placement must remain completed.")
        XCTAssertTrue(upgraded.braces.isEmpty)
        XCTAssertFalse(upgraded.hasDeliveredSupplies)
        XCTAssertEqual(upgraded.trialsCompleted, 0)
        XCTAssertEqual(upgraded.testBridge(with: .supplyCart), .stoppedAt(0))
        XCTAssertEqual(upgraded.trialsCompleted, 1)

        var learner = LearnerProfile()
        learner.starlightBridgeQuest = quest
        let snapshot = try JSONDecoder().decode(
            LearnerProfile.self, from: JSONEncoder().encode(learner)
        )
        XCTAssertTrue(snapshot.skills.isEmpty,
                      "Engineering sandbox must never fabricate academic mastery.")
        XCTAssertEqual(snapshot.starlightBridgeQuest, quest)
    }

    func testHiddenStarIsOptionalPersistentAndAvailableOnReturnVisits() throws {
        var quest = StarlightBridgeQuest()
        XCTAssertFalse(quest.hasFoundHiddenStar)
        XCTAssertFalse(quest.discoverHiddenStar())
        XCTAssertTrue(quest.discover())
        XCTAssertTrue(quest.collect(0))
        XCTAssertFalse(quest.discoverHiddenStar(), "One gem must not reveal the secret.")
        XCTAssertTrue(quest.collect(1))
        XCTAssertTrue(quest.discoverHiddenStar())
        XCTAssertFalse(quest.discoverHiddenStar(), "One hidden star cannot be collected twice.")
        XCTAssertEqual(quest.installedCount, 0, "Secret play must not repair sockets.")
        let restored = try JSONDecoder().decode(StarlightBridgeQuest.self,
                                                from: JSONEncoder().encode(quest))
        XCTAssertTrue(restored.hasFoundHiddenStar)

        var replayQuest = StarlightBridgeQuest()
        XCTAssertTrue(replayQuest.discover())
        for index in 0..<StarlightBridgeQuest.crystalCount {
            XCTAssertTrue(replayQuest.collect(index))
            XCTAssertTrue(replayQuest.install(index, into: index))
        }
        XCTAssertTrue(replayQuest.isComplete)
        XCTAssertTrue(replayQuest.discoverHiddenStar(),
                      "Finding the secret later must not require restarting the main rescue.")
        XCTAssertTrue(replayQuest.isComplete)

        // A save from the earlier, secret-less bridge implementation still decodes.
        var payload = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(replayQuest)) as? [String: Any])
        payload.removeValue(forKey: "hiddenStarFound")
        let older = try JSONSerialization.data(withJSONObject: payload)
        let migrated = try JSONDecoder().decode(StarlightBridgeQuest.self, from: older)
        XCTAssertTrue(migrated.isComplete)
        XCTAssertFalse(migrated.hasFoundHiddenStar)
        XCTAssertTrue(migrated.availableCrystals.isEmpty)
    }

}
