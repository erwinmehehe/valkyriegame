import XCTest
@testable import LearningCore

final class MathAdventureTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 1000)
    private func solve(_ adventure: inout MathAdventure, profile: inout LearnerProfile, at date: Date) throws -> LearningEvidence {
        try adventure.beginInteraction(at: date)
        let after = date.addingTimeInterval(30)
        switch try XCTUnwrap(adventure.runtime) {
        case .crystalCart(let model):
            if model.quantity < model.encounter.targetQuantity {
                for _ in model.quantity..<model.encounter.targetQuantity {
                    XCTAssertTrue(adventure.increment(at: after))
                }
            } else if model.quantity > model.encounter.targetQuantity {
                for _ in model.encounter.targetQuantity..<model.quantity {
                    XCTAssertTrue(adventure.decrement(at: after))
                }
            }
        case .balanceScale(let model): adventure.chooseComparison(model.correctChoice)
        case .numberBond(let model): adventure.setNumber(model.correctMissingPart)
        case .tenFrame(let model):
            for _ in model.filled..<model.encounter.targetQuantity { XCTAssertTrue(adventure.increment(at: after)) }
        case .missingBridge(let model): adventure.setNumber(model.correctNumber)
        case .placeValueFactory(let model):
            if model.isComparison {
                adventure.chooseComparison(model.correctChoice)
            } else {
                _ = adventure.adjustPlaceValue(
                    tensDelta: model.expectedTens,
                    onesDelta: model.expectedOnes
                )
            }
        case .patternLoom(let model):
            if model.isCreation {
                let unit: [Int]
                switch model.family {
                case .ab: unit = [1, 2]
                case .aab: unit = [1, 1, 2]
                case .abc: unit = [1, 2, 3]
                }
                for index in 0..<model.slotCount {
                    XCTAssertTrue(adventure.choosePatternSymbol(unit[index % unit.count]))
                }
            } else {
                XCTAssertTrue(adventure.choosePatternSymbol(model.correctSymbol))
            }
        case .shapeForge(let model):
            switch model.task {
            case .rotate:
                let forward = (model.targetOrientation - model.currentOrientation + 4) % 4
                for _ in 0..<forward { XCTAssertTrue(adventure.rotateShape(1)) }
            case .compose:
                for turns in model.requiredHalfTurns {
                    XCTAssertTrue(adventure.placeShapeHalf(turns))
                }
            case .symmetry:
                for (row, shape) in model.symmetryReference.enumerated() {
                    for _ in 0..<shape.rawValue {
                        XCTAssertTrue(adventure.cycleMirrorCell(row))
                    }
                }
            case .recognize, .attributes:
                XCTAssertTrue(adventure.chooseShapeOption(try XCTUnwrap(model.correctOption)))
            }
        case .measurementWorkshop(let model):
            if model.isUnitMeasurement {
                for _ in 0..<model.targetUnitCount {
                    XCTAssertTrue(adventure.placeMeasureUnit())
                }
            } else {
                adventure.chooseComparison(model.correctChoice)
            }
        case .dataBoard(let model):
            if model.isSorting {
                for token in model.sortingTokens {
                    let attribute = try XCTUnwrap(model.sortingAttribute)
                    XCTAssertTrue(adventure.sortDataObject(into: token.category(for: attribute)))
                }
            } else {
                for (index, count) in model.graphSourceCounts.enumerated() {
                    for _ in 0..<count {
                        XCTAssertTrue(adventure.addPicture(to: index + 1))
                    }
                }
            }
        case .clockMarket(let model):
            if model.isClock {
                let hours = model.targetHour == 12 ? 12 : model.targetHour
                for _ in 0..<hours {
                    XCTAssertTrue(adventure.adjustClockHour(1))
                }
                let interval = model.task == .halfHour ? 30 : 5
                if model.task != .hour {
                    for _ in 0..<(model.targetMinute / interval) {
                        XCTAssertTrue(adventure.adjustClockMinute(1))
                    }
                }
            } else if model.isRoutines {
                for card in model.routineCards {
                    XCTAssertTrue(adventure.placeDailyRoutine(card.daypart))
                }
            } else {
                var remaining = model.targetPesos
                for coin in model.allowedCoins.reversed() {
                    while remaining >= coin {
                        XCTAssertTrue(adventure.addPesoCoin(coin))
                        remaining -= coin
                    }
                }
                XCTAssertEqual(remaining, 0)
            }
        case .groupingGarden(let model):
            if model.isGroupPlacement {
                for basket in 1...model.groupCount {
                    for _ in 0..<model.groupSize {
                        XCTAssertTrue(adventure.placeGardenSeed(in: basket))
                    }
                }
            } else if model.isRepeatedAddition {
                for _ in 0..<model.groupCount {
                    XCTAssertTrue(adventure.addGardenJump())
                }
            } else {
                var current = model.selectedBoundary
                for boundary in model.requiredCuts {
                    while current < boundary {
                        XCTAssertTrue(adventure.moveGardenCut(1))
                        current += 1
                    }
                    XCTAssertTrue(adventure.placeGardenCut())
                }
            }
        }
        return try XCTUnwrap(adventure.submit(profile: &profile, at: after))
    }
    func testPlacementUsesOnlyPlayableProbesAndDoesNotGrantMastery() throws {
        var adventure = MathAdventure(); var profile = LearnerProfile(); var date = epoch
        var seen = Set<String>()
        for _ in 0..<12 {
            let selection = try adventure.prepareNext(profile: &profile, now: date)
            if selection == .explorationBreak { adventure.finishExploration(profile: &profile, at: date); continue }
            guard adventure.isPlacement else { break }
            let encounter = try XCTUnwrap(adventure.runtime?.encounter)
            XCTAssertTrue(seen.insert(encounter.id).inserted)
            XCTAssertNotNil(try? MathMechanicRuntime(encounter: encounter))
            XCTAssertEqual(try solve(&adventure, profile: &profile, at: date).outcome, .correct)
            XCTAssertTrue(adventure.advanceEncounter())
            date = date.addingTimeInterval(40)
        }
        XCTAssertTrue(adventure.placementComplete)
        XCTAssertNotNil(adventure.placementRecommendation)
        XCTAssertLessThanOrEqual(seen.count, 6)
        XCTAssertFalse(profile.skills.values.contains { $0.state == .mastered || $0.state == .secure })
    }
    func testIncorrectDiagnosticCannotBeErasedBySupportedRetry() throws {
        var adventure = MathAdventure(); var profile = LearnerProfile()
        _ = try adventure.prepareNext(profile: &profile, now: epoch)
        try adventure.beginInteraction(at: epoch)
        adventure.chooseComparison(.left) // Initial diagnostic compares 6 and 8.
        XCTAssertEqual(adventure.submit(profile: &profile, at: epoch)?.outcome, .incorrect)
        let diagnostic = adventure.placement
        XCTAssertEqual(diagnostic.completedProbeCount, 1)
        _ = adventure.scaffold(at: epoch)
        adventure.chooseComparison(.right)
        XCTAssertEqual(adventure.submit(profile: &profile, at: epoch)?.supportLevel, .lightHint)
        XCTAssertEqual(adventure.placement, diagnostic)
        XCTAssertEqual(profile.progress(for: MathSkills.compare).state, .new)
        XCTAssertTrue(profile.progress(for: MathSkills.compare).evidence.isEmpty)
    }
    func testReturningToSolvedOrUnsolvedEncounterNeverAdvances() throws {
        var adventure = MathAdventure(); var profile = LearnerProfile()
        let selection = try adventure.prepareNext(profile: &profile, now: epoch)
        XCTAssertFalse(adventure.advanceEncounter())
        XCTAssertEqual(try adventure.prepareNext(profile: &profile, now: epoch), selection)
        _ = try solve(&adventure, profile: &profile, at: epoch)
        let attempts = profile.progress(for: MathSkills.compare).evidence.count
        XCTAssertEqual(try adventure.prepareNext(profile: &profile, now: epoch), selection)
        XCTAssertNil(adventure.submit(profile: &profile, at: epoch))
        XCTAssertEqual(profile.progress(for: MathSkills.compare).evidence.count, attempts)
        XCTAssertTrue(adventure.advanceEncounter())
    }
    func testAllTwelveRuntimesAndSessionStateRoundTrip() throws {
        let placeValue = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.placeValue).first?.encounter
        )
        let examples = [MathFoundation.workshopExamples[0], MathCastleEncounterCatalog.balanceScale[0],
            MathCastleEncounterCatalog.numberBondMachine[0], MathCastleEncounterCatalog.tenFrameGate[0],
            MathCastleEncounterCatalog.missingNumberBridge[0], placeValue,
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.patternAB).first?.encounter),
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.recognizeShapes).first?.encounter),
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.nonstandardMeasure).first?.encounter),
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.classifyObjects).first?.encounter),
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.clockHour).first?.encounter),
            try XCTUnwrap(MathProductionQuestionBank.variants(for: MathSkills.equalGroups).first?.encounter)]
        for encounter in examples {
            var adventure = MathAdventure(); var profile = LearnerProfile()
            XCTAssertTrue(try adventure.startWorkshop(encounter, profile: &profile, now: epoch))
            try adventure.beginInteraction(at: epoch)
            _ = adventure.increment(at: epoch.addingTimeInterval(2))
            _ = adventure.scaffold(at: epoch.addingTimeInterval(2))
            adventure.chooseComparison(.left)
            let restored = try JSONDecoder().decode(MathAdventure.self, from: JSONEncoder().encode(adventure))
            XCTAssertEqual(restored, adventure)
            var copy = restored
            _ = try solve(&copy, profile: &profile, at: epoch)
            XCTAssertTrue(profile.skills.isEmpty, "Workshops must not provide scored learning evidence")
        }
    }
    func testQuickLookWaitsForEngagementAndReplayRecordsAssistance() throws {
        var adventure = MathAdventure(); var profile = LearnerProfile()
        let encounter = try XCTUnwrap(MathCastleEncounterCatalog.prerequisites.first { $0.context == "quickLook" })
        XCTAssertTrue(try adventure.startWorkshop(encounter, profile: &profile, now: epoch))
        XCTAssertFalse(adventure.previewVisible(at: epoch))
        let engage = epoch.addingTimeInterval(120)
        try adventure.beginInteraction(at: engage)
        XCTAssertTrue(adventure.previewVisible(at: engage))
        XCTAssertFalse(adventure.increment(at: engage))
        let after = engage.addingTimeInterval(2)
        XCTAssertTrue(adventure.increment(at: after))
        XCTAssertEqual(adventure.scaffold(at: after)?.support, .lightHint)
        XCTAssertTrue(adventure.previewVisible(at: after))
        for _ in 1..<encounter.targetQuantity { _ = adventure.increment(at: after.addingTimeInterval(2)) }
        XCTAssertEqual(adventure.submit(profile: &profile, at: after.addingTimeInterval(2))?.supportLevel, .lightHint)
    }
    func testWorkshopCannotReplaceUnfinishedScoredWorkAndCanBeLeftUnscored() throws {
        var adventure = MathAdventure(); var profile = LearnerProfile()
        _ = try adventure.prepareNext(profile: &profile, now: epoch)
        XCTAssertFalse(try adventure.startWorkshop(MathFoundation.workshopExamples[0], profile: &profile, now: epoch))
        _ = try solve(&adventure, profile: &profile, at: epoch)
        XCTAssertTrue(try adventure.startWorkshop(MathFoundation.workshopExamples[0], profile: &profile, now: epoch))
        XCTAssertTrue(adventure.advanceEncounter(), "Unscored exploration can be left without completing it")
        XCTAssertNil(adventure.runtime)
    }
    func testFreshLearnerPracticeCanReachEveryMechanicWithoutSeededReadiness() throws {
        // Continuing learner skips diagnostic orchestration; every readiness state
        // below is still earned by eligible, real runtime evidence.
        var adventure = MathAdventure(continuingLearner: true)
        var profile = LearnerProfile(); var date = epoch; var seen = Set<String>()
        // With seven mechanics and prerequisite-based variation, give the
        // planner sufficient independent scored encounters to reach every one.
        for _ in 0..<180 {
            let selection = try adventure.prepareNext(profile: &profile, now: date)
            if selection == .explorationBreak {
                adventure.finishExploration(profile: &profile, at: date); continue
            }
            guard adventure.runtime != nil else { break }
            let encounter = try XCTUnwrap(adventure.runtime?.encounter)
            XCTAssertTrue(try MathSkills.graph().isEligible(encounter.skillID, for: profile))
            XCTAssertEqual(try solve(&adventure, profile: &profile, at: date).outcome, .correct)
            seen.insert(encounter.mechanicID)
            XCTAssertTrue(adventure.advanceEncounter())
            date = date.addingTimeInterval(40)
        }
        XCTAssertEqual(seen, MathMechanicID.adaptiveSet)
        XCTAssertGreaterThan(adventure.laneCounts.values.reduce(0, +), 0)
    }

    func testPlacementSuccessCreatesProvisionalReadinessWithoutFalseMastery() throws {
        var adventure = MathAdventure()
        var profile = LearnerProfile()

        _ = try adventure.prepareNext(profile: &profile, now: epoch)
        let encounter = try XCTUnwrap(adventure.runtime?.encounter)
        XCTAssertEqual(encounter.skillID, MathSkills.compare)

        XCTAssertEqual(try solve(&adventure, profile: &profile, at: epoch).outcome, .correct)

        XCTAssertEqual(profile.progress(for: MathSkills.compare).state, .new)
        XCTAssertTrue(profile.progress(for: MathSkills.compare).evidence.isEmpty)
        XCTAssertGreaterThanOrEqual(
            profile.readiness(for: MathSkills.compare),
            SkillState.developing.readiness
        )
        XCTAssertTrue(profile.placementReadySkillIDs?.contains(MathSkills.compare) == true)
    }

    func testChallengeGateRequiresObservedSecurePerformanceNotPlacementAlone() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))

        var adventure = MathAdventure(continuingLearner: true)
        XCTAssertFalse(adventure.beginChallengeGate(profile: profile, graph: graph))

        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)
        XCTAssertTrue(adventure.beginChallengeGate(profile: profile, graph: graph))
        XCTAssertEqual(adventure.challengeGateSession?.encounterIDs.count, ChallengeGateCatalog.challengeCount)
    }

    func testChallengeGateCompletesThreeDifferentMechanicsAndUnlocksMoonLantern() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))
        profile.skills[MathSkills.addition.rawValue] = SkillProgress(state: .secure)
        profile.skills[MathSkills.subtraction.rawValue] = SkillProgress(state: .secure)

        var adventure = MathAdventure(continuingLearner: true)
        XCTAssertTrue(adventure.beginChallengeGate(profile: profile, graph: graph))

        var mechanics: Set<String> = []
        var date = epoch

        for index in 0..<ChallengeGateCatalog.challengeCount {
            guard case .encounter(let encounter) = try adventure.prepareNext(profile: &profile, now: date) else {
                return XCTFail("Expected Challenge Gate encounter \(index + 1)")
            }
            XCTAssertEqual(encounter.context, "challengeGate")
            mechanics.insert(encounter.mechanicID)
            XCTAssertEqual(try solve(&adventure, profile: &profile, at: date).outcome, .correct)

            if index < ChallengeGateCatalog.challengeCount - 1 {
                XCTAssertNotNil(adventure.challengeGateSession)
                XCTAssertTrue(adventure.advanceEncounter())
            }

            date = date.addingTimeInterval(60)
        }

        XCTAssertEqual(mechanics.count, ChallengeGateCatalog.challengeCount)
        XCTAssertTrue(profile.hasStoryReward(.moonLantern))
        XCTAssertNil(adventure.challengeGateSession)
    }


    func testResponseTimeStartsWhenChildEngagesNotWhenOrderAppears() throws {
        var adventure = MathAdventure(continuingLearner: true)
        var profile = LearnerProfile()
        let encounter = MathFoundation.workshopExamples[0]

        XCTAssertTrue(try adventure.startWorkshop(encounter, profile: &profile, now: epoch))

        // The order can be visible while Valkyrie walks over / the child looks around.
        let interactionStart = epoch.addingTimeInterval(120)
        try adventure.beginInteraction(at: interactionStart)

        let answerTime = interactionStart.addingTimeInterval(5)
        for _ in encounter.initialQuantity..<encounter.targetQuantity {
            XCTAssertTrue(adventure.increment(at: answerTime))
        }

        let evidence = try XCTUnwrap(adventure.submit(profile: &profile, at: answerTime))
        XCTAssertEqual(try XCTUnwrap(evidence.responseTime), 5, accuracy: 0.001)
    }

    func testNextAdaptiveBeatUsesFreshProfileStateInsteadOfAStalePreplannedSession() throws {
        var adventure = MathAdventure(continuingLearner: true)
        var profile = LearnerProfile()

        // Complete the first adaptive beat normally.
        guard case .encounter = try adventure.prepareNext(profile: &profile, now: epoch) else {
            return XCTFail("Expected first adaptive encounter")
        }
        XCTAssertEqual(try solve(&adventure, profile: &profile, at: epoch).outcome, .correct)
        XCTAssertTrue(adventure.advanceEncounter())

        // A review becomes due after that response. The next slot in the running
        // 60/20/15/5 mix should consult this current learner state.
        var due = SkillProgress(state: .secure)
        due.reviewDate = epoch.addingTimeInterval(-1)
        profile.skills[MathSkills.quantity.rawValue] = due

        guard case .encounter(let next) = try adventure.prepareNext(
            profile: &profile,
            now: epoch.addingTimeInterval(60)
        ) else {
            return XCTFail("Expected a freshly selected adaptive encounter")
        }

        XCTAssertEqual(adventure.activeLane, .review)
        XCTAssertEqual(next.skillID, MathSkills.quantity)
    }

    func testReasoningDepthUsesOnlyObservablePhysicalEvidence() throws {
        let catalog = MathCastleEncounterCatalog.reasoningDepth
        XCTAssertGreaterThanOrEqual(catalog.count, 8)
        XCTAssertEqual(Set(catalog.map(\.fingerprint)).count, catalog.count)
        XCTAssertTrue(catalog.allSatisfy { MathManipulativeSupport.supports($0) })
        XCTAssertTrue(catalog.allSatisfy { $0.challengeDepth > 0 })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.equivalence10 })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.sameTotalDifferentWay })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.reasoning })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.whatChanged })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.storyAddition10 })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.subtractWithin20 })
        XCTAssertTrue(catalog.contains { $0.skillID == MathSkills.explainComparison })

        // Do not claim skills that the current one-answer manipulatives cannot
        // directly observe yet.
        XCTAssertFalse(catalog.contains { $0.skillID == MathSkills.chooseStrategy })
        XCTAssertFalse(catalog.contains { $0.skillID == MathSkills.multipleSolutions })
    }

    func testFifteenMinuteSessionPlanHasVarietyAndNaturalStops() throws {
        var profile = LearnerProfile()
        profile.markPlacementReady(Set(MathSkillCatalog.descriptors.map(\.id)))

        // A strong learner should have both ordinary and deeper reasoning content
        // available without forcing a separate worksheet mode.
        let plan = try MathCastleEncounterCatalog.sessionPlan(
            for: profile,
            encounterCount: 12,
            now: epoch
        )

        XCTAssertEqual(plan.encounters.count, 12)
        let encounters = plan.encounters.map(\.encounter)
        XCTAssertEqual(Set(encounters.map(\.fingerprint)).count, encounters.count)

        var longestMechanicRun = 0
        var currentRun = 0
        var previousMechanic: String?
        for encounter in encounters {
            if encounter.mechanicID == previousMechanic {
                currentRun += 1
            } else {
                previousMechanic = encounter.mechanicID
                currentRun = 1
            }
            longestMechanicRun = max(longestMechanicRun, currentRun)
        }
        XCTAssertLessThanOrEqual(longestMechanicRun, 2)
        XCTAssertGreaterThanOrEqual(Set(encounters.map(\.mechanicID)).count, 3)
        XCTAssertGreaterThanOrEqual(
            plan.explorationBreakCount,
            2,
            "A 12-encounter / roughly 15-minute session should expose natural stopping or exploration beats."
        )
        XCTAssertTrue(
            encounters.contains { $0.representation == .reasoning || $0.representation == .story },
            "A strong learner's longer session should include reasoning or transfer, not only concrete repetition."
        )
    }


    func testK2ThroughGrade2CurriculumMatrixMapsEveryMathSkillExactlyOnce() {
        let catalogIDs = Set(MathSkillCatalog.descriptors.map(\.id))
        let alignedIDs = Set(MathCurriculumMatrix.alignments.map(\.skillID))

        XCTAssertEqual(MathSkillCatalog.descriptors.count, 76)
        XCTAssertEqual(MathCurriculumMatrix.alignments.count, 76)
        XCTAssertEqual(MathCurriculumMatrix.mappedSkillIDs, catalogIDs)
        XCTAssertEqual(alignedIDs, catalogIDs)

        XCTAssertEqual(MathCurriculumMatrix.skills(in: .k2Readiness).count, 14)
        XCTAssertEqual(MathCurriculumMatrix.skills(in: .kindergarten).count, 17)
        XCTAssertEqual(MathCurriculumMatrix.skills(in: .grade1).count, 32)
        XCTAssertEqual(MathCurriculumMatrix.skills(in: .grade2).count, 13)

        XCTAssertEqual(
            MathCurriculumMatrix.alignment(for: MathSkills.pictureGraph)?.matatagDomain,
            .dataAndProbability
        )
        XCTAssertEqual(
            MathCurriculumMatrix.alignment(for: MathSkills.placeValue)?.singaporeArea,
            .numbersAndAlgebra
        )
        XCTAssertEqual(
            MathCurriculumMatrix.alignment(for: MathSkills.multiStep)?.singaporeArea,
            .problemSolving
        )
    }

    func testProductionQuestionBankIncludesPlaceValueFactoryExpansion() throws {
        XCTAssertEqual(MathProductionQuestionBank.variants.count, 2086)
        XCTAssertEqual(MathProductionQuestionBank.encounters.count, 2086)
        XCTAssertEqual(MathCastleEncounterCatalog.all.count, 2135)

        XCTAssertEqual(
            Set(MathProductionQuestionBank.encounters.map(\.id)).count,
            MathProductionQuestionBank.encounters.count
        )
        XCTAssertEqual(
            Set(MathProductionQuestionBank.encounters.map(\.fingerprint)).count,
            MathProductionQuestionBank.encounters.count,
            "Production variants must represent distinct observable math, not relabeled duplicates."
        )

        for encounter in MathProductionQuestionBank.encounters {
            XCTAssertTrue(
                MathManipulativeSupport.supports(encounter),
                "Unsupported production encounter: \(encounter.id)"
            )
            XCTAssertNoThrow(
                try MathMechanicRuntime(encounter: encounter, at: epoch),
                "Production encounter cannot initialize native runtime: \(encounter.id)"
            )
        }
    }

    func testProductionQuestionMetadataIsCompleteAndReviewable() {
        XCTAssertEqual(MathProductionQuestionBank.coveredSkillIDs.count, 67)

        for variant in MathProductionQuestionBank.variants {
            let alignment = MathCurriculumMatrix.alignment(for: variant.encounter.skillID)
            XCTAssertNotNil(alignment)
            XCTAssertEqual(variant.gradeBand, alignment?.gradeBand)
            XCTAssertEqual(variant.matatagDomain, alignment?.matatagDomain)
            XCTAssertEqual(variant.singaporeArea, alignment?.singaporeArea)
            XCTAssertTrue((1...5).contains(variant.difficulty))
            XCTAssertTrue(variant.masteryEligible)
            XCTAssertFalse(variant.placementEligible)
            XCTAssertTrue(variant.reviewEligible)
        }

        XCTAssertGreaterThan(
            MathProductionQuestionBank.variants(in: .k2Readiness).count,
            0
        )
        XCTAssertGreaterThan(
            MathProductionQuestionBank.variants(in: .kindergarten).count,
            0
        )
        XCTAssertGreaterThan(
            MathProductionQuestionBank.variants(in: .grade1).count,
            0
        )
        XCTAssertGreaterThan(
            MathProductionQuestionBank.variants(in: .grade2).count,
            0
        )
    }


    func testPlaceValueFactoryMakesNinePreviouslyBlockedSkillsNativeAssessable() throws {
        let newlySupported: [SkillID] = [
            MathSkills.countTo20,
            MathSkills.numberOrder20,
            MathSkills.oneMoreLess20,
            MathSkills.groupTen,
            MathSkills.placeValue,
            MathSkills.buildTwoDigit,
            MathSkills.readTwoDigit,
            MathSkills.compareTwoDigit,
            MathSkills.orderTwoDigit
        ]

        for skillID in newlySupported {
            let variants = MathProductionQuestionBank.variants(for: skillID)
            XCTAssertFalse(variants.isEmpty, "Missing Place Value Factory variants for \(skillID.rawValue)")
            XCTAssertTrue(variants.allSatisfy {
                $0.encounter.mechanicID == MathMechanicID.placeValueFactory
                    && MathManipulativeSupport.supports($0.encounter)
            })
        }

        XCTAssertEqual(
            Set(newlySupported).intersection(MathProductionQuestionBank.coveredSkillIDs).count,
            newlySupported.count
        )

        let build = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.buildTwoDigit).first?.encounter
        )
        var buildRuntime = try MathMechanicRuntime(encounter: build, at: epoch)
        guard case .placeValueFactory(let buildModel) = buildRuntime else {
            return XCTFail("Expected place-value runtime")
        }
        XCTAssertTrue(buildRuntime.adjustPlaceValue(
            tensDelta: buildModel.expectedTens,
            onesDelta: buildModel.expectedOnes
        ))
        XCTAssertEqual(buildRuntime.submit(at: epoch.addingTimeInterval(10))?.outcome, .correct)

        let compare = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.compareTwoDigit).first?.encounter
        )
        var compareRuntime = try MathMechanicRuntime(encounter: compare, at: epoch)
        guard case .placeValueFactory(let compareModel) = compareRuntime else {
            return XCTFail("Expected place-value comparison runtime")
        }
        compareRuntime.chooseComparison(compareModel.correctChoice)
        XCTAssertEqual(compareRuntime.submit(at: epoch.addingTimeInterval(10))?.outcome, .correct)
    }



    func testPatternLoomUnlocksFiveSkillsThroughObservableActions() throws {
        let skills: [SkillID] = [
            MathSkills.patternAB, MathSkills.patternAAB, MathSkills.patternABC,
            MathSkills.patternMissing, MathSkills.patternCreate
        ]
        for skill in skills {
            let encounters = MathProductionQuestionBank.variants(for: skill).map(\.encounter)
            XCTAssertFalse(encounters.isEmpty)
            XCTAssertTrue(encounters.allSatisfy {
                $0.operation == .pattern
                    && $0.mechanicID == MathMechanicID.patternLoom
                    && MathManipulativeSupport.supports($0)
            })
        }

        let missing = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.patternMissing).first?.encounter
        )
        var runtime = try MathMechanicRuntime(encounter: missing, at: epoch)
        guard case .patternLoom(let model) = runtime else {
            return XCTFail("Expected a Pattern Loom runtime")
        }
        XCTAssertEqual(model.visibleSlots.filter { $0 == nil }.count, 1)
        XCTAssertNil(runtime.submit(at: epoch))
        let wrong = model.correctSymbol == 1 ? 2 : 1
        XCTAssertTrue(runtime.choosePatternSymbol(wrong))
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        XCTAssertTrue(runtime.choosePatternSymbol(model.correctSymbol))
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(5))?.outcome, .correct)
        XCTAssertFalse(runtime.choosePatternSymbol(wrong), "Completed work must be immutable")
        XCTAssertNil(runtime.submit(at: epoch.addingTimeInterval(6)))
        XCTAssertEqual(
            try JSONDecoder().decode(MathMechanicRuntime.self, from: JSONEncoder().encode(runtime)),
            runtime
        )
    }

    func testPatternCreationRequiresFullRepeatingUnitRatherThanOneCorrectTap() throws {
        for family in PatternLoomFamily.allCases {
            let encounter = try XCTUnwrap(
                MathProductionQuestionBank.variants(for: MathSkills.patternCreate)
                    .first(where: { $0.encounter.context == "loom.create.\(family.rawValue)" })?
                    .encounter
            )
            var model = try PatternLoomModel(encounter: encounter, at: epoch)
            XCTAssertFalse(model.isValidCreation)
            XCTAssertNil(model.submit(at: epoch), "Incomplete patterns cannot be scored")

            for _ in 0..<6 { XCTAssertTrue(model.chooseSymbol(1)) }
            XCTAssertFalse(model.chooseSymbol(2), "Cannot add a seventh shape")
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(10))?.outcome, .incorrect)
            for _ in 0..<6 { XCTAssertTrue(model.undo()) }

            let unit: [Int]
            switch family {
            case .ab: unit = [1, 2]
            case .aab: unit = [1, 1, 2]
            case .abc: unit = [1, 2, 3]
            }
            for index in 0..<6 {
                XCTAssertTrue(model.chooseSymbol(unit[index % unit.count]))
            }
            XCTAssertTrue(model.isValidCreation)
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(20))?.outcome, .correct)
            XCTAssertFalse(model.undo(), "Completed attempts cannot be changed")
        }
    }


    func testShapeForgeRecognizesShapesCountsCornersAndRotates() throws {
        let skills: [SkillID] = [
            MathSkills.recognizeShapes,
            MathSkills.shapeAttributes,
            MathSkills.rotateShapes
        ]
        for skill in skills {
            let variants = MathProductionQuestionBank.variants(for: skill)
            XCTAssertFalse(variants.isEmpty)
            XCTAssertTrue(variants.allSatisfy {
                $0.encounter.mechanicID == MathMechanicID.shapeForge
                && $0.encounter.operation == .shape
                && MathManipulativeSupport.supports($0.encounter)
            })
        }

        let example = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.recognizeShapes).first?.encounter
        )
        var runtime = try MathMechanicRuntime(encounter: example, at: epoch)
        guard case .shapeForge(let model) = runtime else {
            return XCTFail("Expected Shape Forge")
        }
        XCTAssertNil(runtime.submit(at: epoch))
        let right = try XCTUnwrap(model.correctOption)
        XCTAssertTrue(runtime.chooseShapeOption(right == 1 ? 2 : 1))
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        XCTAssertTrue(runtime.chooseShapeOption(right))
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(5))?.outcome, .correct)
        XCTAssertFalse(runtime.chooseShapeOption(1))
        XCTAssertEqual(
            try JSONDecoder().decode(MathMechanicRuntime.self, from: JSONEncoder().encode(runtime)),
            runtime
        )

        let attr = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.shapeAttributes).first?.encounter
        )
        let attrModel = try ShapeForgeModel(encounter: attr, at: epoch)
        XCTAssertEqual(attrModel.cornerChoices.count, 3)
        XCTAssertEqual(Set(attrModel.cornerChoices), Set([0, 3, 4]))
        XCTAssertNotNil(attrModel.correctOption)
    }

    func testShapeForgeRotationRequiresMatchingAnAsymmetricPhysicalShape() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.rotateShapes).first?.encounter
        )
        var model = try ShapeForgeModel(encounter: encounter, at: epoch)
        XCTAssertTrue(model.isRotation)
        XCTAssertFalse(model.turn(0), "Only quarter turns are allowed")
        XCTAssertNil(model.submit(at: epoch), "No accidental score before first action for selections")
        let steps = (model.targetOrientation - model.currentOrientation + 4) % 4
        for _ in 0..<steps {
            XCTAssertTrue(model.turn(1))
        }
        XCTAssertEqual(model.currentOrientation, model.targetOrientation)
        XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(10))?.outcome, .correct)
        XCTAssertFalse(model.turn(1), "The completed shape must be immutable")
    }


    func testShapeCompositionRequiresBothCorrectlyOrientedPhysicalHalves() throws {
        let encounters = MathProductionQuestionBank.variants(for: MathSkills.composeShapes)
            .map(\.encounter)
        XCTAssertEqual(encounters.count, 4)
        for encounter in encounters {
            var model = try ShapeForgeModel(encounter: encounter, at: epoch)
            XCTAssertEqual(model.task, .compose)
            XCTAssertNil(model.submit(at: epoch), "A blank composition cannot score.")
            XCTAssertTrue(model.placeTriangleHalf((model.requiredHalfTurns[0] + 1) % 4))
            XCTAssertNil(model.submit(at: epoch), "A single triangle is not a composed square.")
            XCTAssertTrue(model.placeTriangleHalf(model.requiredHalfTurns[1]))
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(4))?.outcome, .incorrect)

            XCTAssertTrue(model.undoTriangleHalf())
            XCTAssertTrue(model.undoTriangleHalf())
            for turns in model.requiredHalfTurns {
                XCTAssertTrue(model.placeTriangleHalf(turns))
            }
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(9))?.outcome, .correct)
            XCTAssertFalse(model.placeTriangleHalf(0))
            XCTAssertEqual(
                try JSONDecoder().decode(ShapeForgeModel.self, from: JSONEncoder().encode(model)),
                model
            )
        }
    }

    func testSymmetryRequiresThreeObservedMirroredShapeCells() throws {
        let encounters = MathProductionQuestionBank.variants(for: MathSkills.symmetry)
            .map(\.encounter)
        XCTAssertEqual(encounters.count, 12)
        let models = try encounters.map { try ShapeForgeModel(encounter: $0, at: epoch) }
        XCTAssertEqual(Set(models.map { $0.symmetryReference.map(\.rawValue) }).count, 12)

        for encounter in encounters {
            var model = try ShapeForgeModel(encounter: encounter, at: epoch)
            XCTAssertEqual(model.task, .symmetry)
            XCTAssertNil(model.submit(at: epoch))
            for row in 0..<3 {
                let desired = model.symmetryReference[row].rawValue
                for _ in 0..<desired { XCTAssertTrue(model.cycleMirrorCell(row)) }
                if row != 2 {
                    XCTAssertNil(model.submit(at: epoch), "An incomplete mirror must not score.")
                }
            }
            XCTAssertEqual(model.mirrorCells.compactMap { $0 }.count, 3)
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(12))?.outcome, .correct)
            XCTAssertFalse(model.cycleMirrorCell(0))
            XCTAssertEqual(
                try JSONDecoder().decode(ShapeForgeModel.self, from: JSONEncoder().encode(model)),
                model
            )
        }
    }


    func testMeasurementWorkshopCoversFourObservableSkillsWithoutInventingMastery() throws {
        for skill in [MathSkills.compareLength, MathSkills.compareWeight, MathSkills.compareCapacity] {
            let encounters = MathProductionQuestionBank.variants(for: skill).map(\.encounter)
            XCTAssertEqual(encounters.count, 64)
            XCTAssertTrue(encounters.allSatisfy {
                $0.mechanicID == MathMechanicID.measurementWorkshop
                    && $0.operation == .measurement
                    && MathManipulativeSupport.supports($0)
            })
        }
        let unitEncounters = MathProductionQuestionBank.variants(
            for: MathSkills.nonstandardMeasure
        ).map(\.encounter)
        XCTAssertEqual(unitEncounters.count, 18)
        XCTAssertEqual(Set(unitEncounters.map(\.context)), ["measure.units.blocks", "measure.units.tiles"])

        let equal = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.compareLength)
                .first(where: { $0.encounter.initialQuantity == 4
                    && $0.encounter.targetQuantity == 4 })?.encounter
        )
        var comparison = try MeasurementWorkshopModel(encounter: equal, at: epoch)
        XCTAssertEqual(comparison.correctChoice, .equal)
        XCTAssertNil(comparison.submit(at: epoch))
        XCTAssertTrue(comparison.choose(.left))
        XCTAssertEqual(comparison.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        XCTAssertTrue(comparison.choose(.equal))
        XCTAssertEqual(comparison.submit(at: epoch.addingTimeInterval(5))?.outcome, .correct)
        XCTAssertFalse(comparison.choose(.right), "Completed assessments must not mutate")
        XCTAssertEqual(
            try JSONDecoder().decode(
                MeasurementWorkshopModel.self, from: JSONEncoder().encode(comparison)
            ),
            comparison
        )
    }

    func testNonstandardMeasurementRequiresContiguousEqualUnitPlacementAndCorrection() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.nonstandardMeasure)
                .first(where: { $0.encounter.targetQuantity == 4 })?.encounter
        )
        var runtime = try MathMechanicRuntime(encounter: encounter, at: epoch)
        guard case .measurementWorkshop(let model) = runtime else {
            return XCTFail("Expected a Measurement Workshop runtime")
        }
        XCTAssertTrue(model.isUnitMeasurement)
        XCTAssertEqual(model.targetUnitCount, 4)
        XCTAssertNil(runtime.submit(at: epoch), "Unstarted measurement cannot award evidence")
        for _ in 0..<6 { XCTAssertTrue(runtime.placeMeasureUnit()) }
        XCTAssertFalse(runtime.placeMeasureUnit(), "No indefinite unit spam")
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(4))?.outcome, .incorrect)
        XCTAssertTrue(runtime.removeMeasureUnit())
        XCTAssertTrue(runtime.removeMeasureUnit())
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(7))?.outcome, .correct)
        XCTAssertFalse(runtime.removeMeasureUnit(), "Correctly submitted work is immutable")
        XCTAssertNil(runtime.submit(at: epoch.addingTimeInterval(8)))
        XCTAssertEqual(
            try JSONDecoder().decode(MathMechanicRuntime.self, from: JSONEncoder().encode(runtime)),
            runtime
        )
    }


    func testDataBoardClassifiesFiveObjectsByVisibleAttributeAndRecordsCorrections() throws {
        let variants = MathProductionQuestionBank.variants(for: MathSkills.classifyObjects)
        XCTAssertEqual(variants.count, 96)
        XCTAssertEqual(Set(variants.map { $0.encounter.context }),
                       Set(["data.sort.color", "data.sort.shape"]))
        XCTAssertTrue(variants.allSatisfy { MathManipulativeSupport.supports($0.encounter) })

        for attribute in DataSortAttribute.allCases {
            let encounter = try XCTUnwrap(
                variants.first(where: { $0.encounter.context == "data.sort.\(attribute.rawValue)" })?
                    .encounter
            )
            var model = try DataBoardModel(encounter: encounter, at: epoch)
            XCTAssertEqual(model.sortingTokens.count, 5)
            XCTAssertNil(model.submit(at: epoch), "Blank sorting must not award evidence")
            for token in model.sortingTokens.prefix(4) {
                XCTAssertTrue(model.sortNext(into: token.category(for: attribute)))
            }
            XCTAssertNil(model.submit(at: epoch), "Four objects are not a complete sort")
            let last = try XCTUnwrap(model.nextSortingToken)
            let right = last.category(for: attribute)
            let wrong = right == 1 ? 2 : 1
            XCTAssertTrue(model.sortNext(into: wrong))
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(6))?.outcome, .incorrect)
            XCTAssertTrue(model.undoSort())
            XCTAssertTrue(model.sortNext(into: right))
            let evidence = try XCTUnwrap(model.submit(at: epoch.addingTimeInterval(10)))
            XCTAssertEqual(evidence.outcome, .correct)
            XCTAssertEqual(evidence.attempts, 2)
            XCTAssertFalse(model.undoSort(), "Submitted correct work must not be edited")
            XCTAssertEqual(
                try JSONDecoder().decode(DataBoardModel.self, from: JSONEncoder().encode(model)),
                model
            )
        }
    }

    func testDataBoardPictureGraphUsesAll64DistinctCountsAndFullTallies() throws {
        let variants = MathProductionQuestionBank.variants(for: MathSkills.pictureGraph)
        XCTAssertEqual(variants.count, 64)
        let signatures = try variants.map {
            try DataBoardModel(encounter: $0.encounter, at: epoch).graphSourceCounts
        }
        XCTAssertEqual(Set(signatures).count, 64)
        XCTAssertTrue(signatures.allSatisfy { $0.count == 3 && $0.allSatisfy { (1...4).contains($0) } })

        let encounter = try XCTUnwrap(variants.first?.encounter)
        var runtime = try MathMechanicRuntime(encounter: encounter, at: epoch)
        guard case .dataBoard(let first) = runtime else {
            return XCTFail("Expected native Data Board runtime")
        }
        XCTAssertEqual(first.graphSourceCounts, [1, 1, 1])
        XCTAssertNil(runtime.submit(at: epoch))
        XCTAssertTrue(runtime.addPicture(to: 1))
        XCTAssertTrue(runtime.addPicture(to: 1))
        XCTAssertNil(runtime.submit(at: epoch), "Partially filled graph cannot score")
        XCTAssertTrue(runtime.addPicture(to: 2))
        XCTAssertEqual(runtime.submit(at: epoch.addingTimeInterval(5))?.outcome, .incorrect)
        XCTAssertTrue(runtime.undoPicture())
        XCTAssertTrue(runtime.undoPicture())
        XCTAssertTrue(runtime.addPicture(to: 2))
        XCTAssertTrue(runtime.addPicture(to: 3))
        let evidence = try XCTUnwrap(runtime.submit(at: epoch.addingTimeInterval(10)))
        XCTAssertEqual(evidence.outcome, .correct)
        XCTAssertEqual(evidence.attempts, 2)
        XCTAssertFalse(runtime.addPicture(to: 1))
        XCTAssertNil(runtime.submit(at: epoch.addingTimeInterval(12)))
        XCTAssertEqual(
            try JSONDecoder().decode(MathMechanicRuntime.self, from: JSONEncoder().encode(runtime)),
            runtime
        )
    }

    func testDataBoardRejectsFakeLearningOperationsAndUnsupportedSeeds() throws {
        let base = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.classifyObjects).first?.encounter
        )
        let wrongMechanic = LearningEncounter(
            id: "invalid-data-mechanic", skillID: MathSkills.classifyObjects,
            mechanicID: MathMechanicID.dataBoard, representation: .concrete,
            operation: .counting, initialQuantity: 1, targetQuantity: 5,
            prompt: "Invalid", context: "data.sort.color"
        )
        XCTAssertFalse(MathManipulativeSupport.supports(wrongMechanic))
        XCTAssertThrowsError(try MathMechanicRuntime(encounter: wrongMechanic, at: epoch))
        let wrongSeed = LearningEncounter(
            id: "invalid-data-seed", skillID: base.skillID, mechanicID: base.mechanicID,
            representation: base.representation, operation: base.operation,
            initialQuantity: 999, targetQuantity: 5, prompt: "Invalid",
            context: base.context
        )
        XCTAssertFalse(MathManipulativeSupport.supports(wrongSeed))
    }


    func testClockMarketCatalogAndSeparateK2Grade1Grade2ClockSkills() throws {
        let expected: [(SkillID, Int)] = [
            (MathSkills.clockHour, 12),
            (MathSkills.clockHalfHour, 24),
            (MathSkills.clockFiveMinutes, 144),
            (MathSkills.timeDayparts, 24),
            (MathSkills.coinValues, 100)
        ]
        var allFingerprints = Set<String>()
        for (skill, quantity) in expected {
            let variants = MathProductionQuestionBank.variants(for: skill)
            XCTAssertEqual(variants.count, quantity, "Wrong count for \(skill.rawValue)")
            for variant in variants {
                let encounter = variant.encounter
                XCTAssertEqual(encounter.operation, .clockMarket)
                XCTAssertEqual(encounter.mechanicID, MathMechanicID.clockMarket)
                XCTAssertTrue(MathManipulativeSupport.supports(encounter))
                XCTAssertTrue(allFingerprints.insert(encounter.fingerprint).inserted)
                var runtime = try MathMechanicRuntime(encounter: encounter, at: epoch)
                XCTAssertNil(runtime.submit(at: epoch), "Blank work cannot award mastery")
            }
        }
        XCTAssertEqual(allFingerprints.count, 304)
        XCTAssertEqual(MathCurriculumMatrix.gradeBand(for: MathSkills.clockHour), .k2Readiness)
        XCTAssertEqual(MathCurriculumMatrix.gradeBand(for: MathSkills.clockHalfHour), .grade1)
        XCTAssertEqual(MathCurriculumMatrix.gradeBand(for: MathSkills.clockFiveMinutes), .grade2)
    }

    func testClockMarketTimeRequiresHandActionsAndCorrectHalfHourSteps() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.clockFiveMinutes)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 35 })?.encounter
        )
        var model = try ClockMarketModel(encounter: encounter, at: epoch)
        XCTAssertNil(model.submit(at: epoch))
        XCTAssertFalse(model.adjustHour(2))
        for _ in 0..<3 { XCTAssertTrue(model.adjustHour(1)) }
        for _ in 0..<6 { XCTAssertTrue(model.adjustMinute(1)) }
        XCTAssertEqual(model.minute, 30)
        XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        XCTAssertTrue(model.adjustMinute(1))
        let evidence = try XCTUnwrap(model.submit(at: epoch.addingTimeInterval(5)))
        XCTAssertEqual(evidence.outcome, .correct)
        XCTAssertEqual(evidence.attempts, 2)
        XCTAssertFalse(model.adjustHour(1))

        let half = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.clockHalfHour)
                .first(where: { $0.encounter.targetQuantity == 30 })?.encounter
        )
        var halfModel = try ClockMarketModel(encounter: half, at: epoch)
        XCTAssertTrue(halfModel.adjustMinute(1))
        XCTAssertEqual(halfModel.minute, 30)
        XCTAssertTrue(halfModel.adjustMinute(1))
        XCTAssertEqual(halfModel.minute, 0)
        XCTAssertFalse(halfModel.adjustMinute(2))
    }

    func testClockMarketDaypartPermutationsRequireAllFourEventsAndAllowUndo() throws {
        let variants = MathProductionQuestionBank.variants(for: MathSkills.timeDayparts)
        let permutations = try variants.map {
            try ClockMarketModel(encounter: $0.encounter, at: epoch)
                .routineCards.map(\.rawValue)
        }
        XCTAssertEqual(Set(permutations).count, 24)
        for variant in variants {
            var model = try ClockMarketModel(encounter: variant.encounter, at: epoch)
            XCTAssertNil(model.submit(at: epoch))
            for card in model.routineCards.prefix(3) {
                XCTAssertTrue(model.placeRoutine(in: card.daypart))
            }
            XCTAssertNil(model.submit(at: epoch), "Three cards cannot be scored")
            let last = try XCTUnwrap(model.nextRoutine)
            let wrong: ClockMarketDaypart = last.daypart == .morning ? .night : .morning
            XCTAssertTrue(model.placeRoutine(in: wrong))
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(4))?.outcome, .incorrect)
            XCTAssertTrue(model.undoRoutine())
            XCTAssertTrue(model.placeRoutine(in: last.daypart))
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(5))?.outcome, .correct)
            XCTAssertFalse(model.undoRoutine())
        }
    }

    func testClockMarketPhilippineCoinLimitsPayExactAndPreserveAssistance() throws {
        let variants = MathProductionQuestionBank.variants(for: MathSkills.coinValues)
        XCTAssertEqual(variants.count, 100)
        for variant in variants {
            let encounter = variant.encounter
            var model = try ClockMarketModel(encounter: encounter, at: epoch)
            XCTAssertNil(model.submit(at: epoch))
            let denominations: [Int]
            switch model.stage {
            case .k2: denominations = [1, 5]
            case .grade1: denominations = [1, 5, 10]
            case .grade2: denominations = [1, 5, 10, 20]
            }
            XCTAssertEqual(model.allowedCoins, denominations)
            XCTAssertFalse(model.addCoin(50))
            var remaining = model.targetPesos
            for coin in denominations.reversed() {
                while remaining >= coin {
                    XCTAssertTrue(model.addCoin(coin))
                    remaining -= coin
                }
            }
            XCTAssertEqual(remaining, 0)
            XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(5))?.outcome, .correct)
        }

        let money = try XCTUnwrap(
            variants.first(where: { $0.encounter.context == "market.money.grade2"
                && $0.encounter.targetQuantity == 35 })?.encounter
        )
        var model = try ClockMarketModel(encounter: money, at: epoch)
        XCTAssertTrue(model.addCoin(20))
        XCTAssertTrue(model.addCoin(20))
        XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        XCTAssertTrue(model.undoCoin())
        XCTAssertTrue(model.addCoin(10))
        XCTAssertTrue(model.addCoin(5))
        model.apply(Scaffold(support: .strongHint, cue: "Use matching coins", demonstratesStep: false))
        let evidence = try XCTUnwrap(model.submit(at: epoch.addingTimeInterval(7)))
        XCTAssertEqual(evidence.outcome, .correct)
        XCTAssertEqual(evidence.attempts, 2)
        XCTAssertEqual(evidence.supportLevel, .strongHint)
        XCTAssertEqual(
            try JSONDecoder().decode(ClockMarketModel.self, from: JSONEncoder().encode(model)),
            model
        )
    }


    func testGroupingGardenAddsFiveObservableSkillsAndEightyDistinctActivities() throws {
        let expected: [(SkillID, Int)] = [
            (MathSkills.equalGroups, 24),
            (MathSkills.repeatedAddition, 20),
            (MathSkills.equalSharing, 20),
            (MathSkills.halves, 10),
            (MathSkills.quarters, 6)
        ]
        var fingerprints = Set<String>()
        for (skill, quantity) in expected {
            let variants = MathProductionQuestionBank.variants(for: skill)
            XCTAssertEqual(variants.count, quantity)
            for variant in variants {
                let item = variant.encounter
                XCTAssertEqual(item.mechanicID, MathMechanicID.groupingGarden)
                XCTAssertEqual(item.operation, .grouping)
                XCTAssertTrue(MathManipulativeSupport.supports(item))
                XCTAssertTrue(fingerprints.insert(item.fingerprint).inserted)
                var runtime = try MathMechanicRuntime(encounter: item, at: epoch)
                XCTAssertNil(runtime.submit(at: epoch), "Blank work cannot score")
            }
        }
        XCTAssertEqual(fingerprints.count, 80)
    }

    func testGroupingGardenBuildEqualGroupsRequiresEverySeedAndRecovers() throws {
        let encounter = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.equalGroups)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 2 })?.encounter
        )
        var model = try GroupingGardenModel(encounter: encounter, at: epoch)
        XCTAssertNil(model.submit(at: epoch))
        for _ in 0..<5 { XCTAssertTrue(model.placeSeed(in: 1)) }
        XCTAssertNil(model.submit(at: epoch), "Incomplete group placement cannot score")
        XCTAssertTrue(model.placeSeed(in: 1))
        XCTAssertFalse(model.placeSeed(in: 1))
        XCTAssertEqual(model.groups, [6, 0, 0])
        XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(2))?.outcome, .incorrect)
        for _ in 0..<4 { XCTAssertTrue(model.undoSeed()) }
        for basket in 2...3 {
            for _ in 0..<2 { XCTAssertTrue(model.placeSeed(in: basket)) }
        }
        XCTAssertEqual(model.groups, [2, 2, 2])
        let evidence = try XCTUnwrap(model.submit(at: epoch.addingTimeInterval(5)))
        XCTAssertEqual(evidence.outcome, .correct)
        XCTAssertEqual(evidence.attempts, 2)
        XCTAssertFalse(model.undoSeed())
        XCTAssertEqual(
            try JSONDecoder().decode(GroupingGardenModel.self, from: JSONEncoder().encode(model)),
            model
        )
    }

    func testGroupingGardenSharingAndRepeatedAdditionAreDifferentObservedSkills() throws {
        let share = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.equalSharing)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 2 })?.encounter
        )
        var sharing = try GroupingGardenModel(encounter: share, at: epoch)
        XCTAssertEqual(sharing.task, .equalSharing)
        for basket in 1...3 {
            XCTAssertTrue(sharing.placeSeed(in: basket))
        }
        XCTAssertNil(sharing.submit(at: epoch))
        for basket in 1...3 {
            XCTAssertTrue(sharing.placeSeed(in: basket))
        }
        XCTAssertEqual(sharing.submit(at: epoch.addingTimeInterval(6))?.outcome, .correct)

        let jumps = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.repeatedAddition)
                .first(where: { $0.encounter.initialQuantity == 3
                    && $0.encounter.targetQuantity == 4 })?.encounter
        )
        var repeated = try GroupingGardenModel(encounter: jumps, at: epoch)
        XCTAssertFalse(repeated.placeSeed(in: 1))
        XCTAssertTrue(repeated.addJump())
        XCTAssertTrue(repeated.addJump())
        XCTAssertNil(repeated.submit(at: epoch))
        XCTAssertTrue(repeated.addJump())
        XCTAssertTrue(repeated.addJump())
        XCTAssertEqual(repeated.currentJumpTotal, 16)
        XCTAssertEqual(repeated.submit(at: epoch.addingTimeInterval(4))?.outcome, .incorrect)
        XCTAssertTrue(repeated.undoJump())
        XCTAssertEqual(repeated.currentJumpTotal, 12)
        XCTAssertEqual(repeated.submit(at: epoch.addingTimeInterval(9))?.outcome, .correct)
        XCTAssertFalse(repeated.addJump())
    }

    func testGroupingGardenAllFractionCutsRequireActualEqualBoundaries() throws {
        let skills = [MathSkills.halves, MathSkills.quarters]
        for skill in skills {
            for variant in MathProductionQuestionBank.variants(for: skill) {
                var model = try GroupingGardenModel(encounter: variant.encounter, at: epoch)
                XCTAssertTrue(model.isFractions)
                XCTAssertNil(model.submit(at: epoch))
                XCTAssertEqual(model.requiredCuts.count, model.groupCount - 1)
                var cursor = model.selectedBoundary
                for (index, boundary) in model.requiredCuts.enumerated() {
                    while cursor < boundary {
                        XCTAssertTrue(model.moveCutSelector(1))
                        cursor += 1
                    }
                    XCTAssertTrue(model.placeCut())
                    if index != model.requiredCuts.count - 1 {
                        XCTAssertNil(model.submit(at: epoch))
                    }
                }
                XCTAssertEqual(model.submit(at: epoch.addingTimeInterval(12))?.outcome, .correct)
                XCTAssertFalse(model.placeCut())
                XCTAssertEqual(
                    try JSONDecoder().decode(GroupingGardenModel.self, from: JSONEncoder().encode(model)),
                    model
                )
            }
        }

        let wrong = try XCTUnwrap(
            MathProductionQuestionBank.variants(for: MathSkills.quarters)
                .first(where: { $0.encounter.initialQuantity == 8 })?.encounter
        )
        var fractions = try GroupingGardenModel(encounter: wrong, at: epoch)
        XCTAssertTrue(fractions.placeCut()) // 1
        XCTAssertTrue(fractions.moveCutSelector(1))
        XCTAssertTrue(fractions.placeCut()) // 2
        XCTAssertTrue(fractions.moveCutSelector(1))
        XCTAssertTrue(fractions.placeCut()) // 3
        XCTAssertEqual(fractions.submit(at: epoch.addingTimeInterval(6))?.outcome, .incorrect)
        for _ in 0..<3 { XCTAssertTrue(fractions.undoCut()) }
        XCTAssertTrue(fractions.moveCutSelector(-1)) // back to 2
        XCTAssertTrue(fractions.placeCut()) // 2
        for _ in 0..<2 { XCTAssertTrue(fractions.moveCutSelector(1)) }
        XCTAssertTrue(fractions.placeCut()) // 4
        for _ in 0..<2 { XCTAssertTrue(fractions.moveCutSelector(1)) }
        XCTAssertTrue(fractions.placeCut()) // 6
        XCTAssertEqual(fractions.submit(at: epoch.addingTimeInterval(14))?.outcome, .correct)
        XCTAssertEqual(fractions.attempts, 2)
    }

    func testUnsupportedSkillsRemainVisibleButDoNotReceiveFalseNativeMasteryQuestions() {
        let unsupportedUntilDedicatedMechanicsExist: [SkillID] = [
            MathSkills.estimate10,
            MathSkills.countOn10,
            MathSkills.findDifference10,
            MathSkills.inverseFacts10,
            MathSkills.positionalLanguage,
            MathSkills.mapRoute,
            MathSkills.chooseStrategy,
            MathSkills.multipleSolutions,
            MathSkills.multiStep,
        ]

        for skillID in unsupportedUntilDedicatedMechanicsExist {
            XCTAssertNotNil(
                MathCurriculumMatrix.alignment(for: skillID),
                "Unsupported skills must stay visible in the curriculum matrix."
            )
            XCTAssertFalse(
                MathProductionQuestionBank.hasNativeAssessment(for: skillID),
                "Do not award mastery for \(skillID.rawValue) until a mechanic can observe the required act."
            )
        }
    }


}
