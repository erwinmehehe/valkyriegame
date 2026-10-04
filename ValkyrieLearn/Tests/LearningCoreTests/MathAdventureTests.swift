import XCTest
@testable import LearningCore

final class MathAdventureTests: XCTestCase {
    let epoch = Date(timeIntervalSince1970: 1000)
    private func solve(_ adventure: inout MathAdventure, profile: inout LearnerProfile, at date: Date) throws -> LearningEvidence {
        try adventure.beginInteraction(at: date)
        let after = date.addingTimeInterval(30)
        switch try XCTUnwrap(adventure.runtime) {
        case .crystalCart(let model):
            for _ in model.quantity..<model.encounter.targetQuantity { XCTAssertTrue(adventure.increment(at: after)) }
        case .balanceScale(let model): adventure.chooseComparison(model.correctChoice)
        case .numberBond(let model): adventure.setNumber(model.correctMissingPart)
        case .tenFrame(let model):
            for _ in model.filled..<model.encounter.targetQuantity { XCTAssertTrue(adventure.increment(at: after)) }
        case .missingBridge(let model): adventure.setNumber(model.correctNumber)
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
        XCTAssertEqual(profile.progress(for: MathSkills.compare).state, .learning)
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
    func testAllFiveRuntimesAndSessionStateRoundTrip() throws {
        let examples = [MathFoundation.workshopExamples[0], MathCastleEncounterCatalog.balanceScale[0],
            MathCastleEncounterCatalog.numberBondMachine[0], MathCastleEncounterCatalog.tenFrameGate[0],
            MathCastleEncounterCatalog.missingNumberBridge[0]]
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
        for _ in 0..<80 {
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
}
