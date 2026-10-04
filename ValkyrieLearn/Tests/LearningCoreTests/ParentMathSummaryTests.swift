import XCTest
@testable import LearningCore

final class ParentMathSummaryTests: XCTestCase {
    private let epoch = Date(timeIntervalSince1970: 1_700_000_000)

    private func summary(_ profile: LearnerProfile, at date: Date) throws -> ParentMathSummary {
        ParentMathSummaryBuilder.build(profile: profile, graph: try MathSkills.graph(), now: date)
    }

    func testOpenedUnansweredMachineIsNotRecentLearning() throws {
        var profile = LearnerProfile()
        profile.begin(MathFoundation.workshopExamples[0], at: epoch)
        XCTAssertNil(try summary(profile, at: epoch.addingTimeInterval(30)).recentSession)
    }

    func testCompletedWorkshopRemainsUnscoredAfterProfileRestore() throws {
        var profile = LearnerProfile()
        var adventure = MathAdventure(continuingLearner: true)
        let encounter = MathFoundation.workshopExamples[0]
        XCTAssertTrue(try adventure.startWorkshop(encounter, profile: &profile, now: epoch))
        try adventure.beginInteraction(at: epoch)
        for _ in encounter.initialQuantity..<encounter.targetQuantity {
            XCTAssertTrue(adventure.increment(at: epoch.addingTimeInterval(1)))
        }
        XCTAssertEqual(adventure.submit(profile: &profile, at: epoch.addingTimeInterval(10))?.outcome, .correct)
        XCTAssertTrue(profile.progress(for: encounter.skillID).evidence.isEmpty)
        let restored = try JSONDecoder().decode(LearnerProfile.self, from: JSONEncoder().encode(profile))
        XCTAssertNil(try summary(restored, at: epoch.addingTimeInterval(30)).recentSession)
    }

    func testMixedVisitReportsOnlyScoredEvidenceAndExcludesLegacyPlacement() throws {
        var profile = LearnerProfile()
        let scored = LearningEvidence(encounterID: "practice-quantity", skillID: MathSkills.quantity,
            outcome: .correct, timestamp: epoch.addingTimeInterval(10))
        MasteryEngine().record(scored, in: &profile)
        let unopened = LearningEncounter(id: "unanswered-story", skillID: MathSkills.addition,
            representation: .story, operation: .addition, initialQuantity: 4, targetQuantity: 7,
            prompt: "Add three crystals.")
        profile.begin(unopened, at: epoch.addingTimeInterval(20))
        let probe = try XCTUnwrap(MathAdventure.playableProbes.first)
        MasteryEngine().record(LearningEvidence(encounterID: probe.encounter.id, skillID: probe.skillID,
            outcome: .correct, supportLevel: .demonstration, representation: .reasoning,
            timestamp: epoch.addingTimeInterval(25)), in: &profile)

        let recent = try XCTUnwrap(try summary(profile, at: epoch.addingTimeInterval(30)).recentSession)
        XCTAssertEqual(recent.skills.map(\.id), [MathSkills.quantity])
        XCTAssertEqual(recent.startedAt, scored.timestamp)
        XCTAssertEqual(recent.endedAt, scored.timestamp)
        XCTAssertFalse(recent.usedPipSupport)
        XCTAssertFalse(recent.includedReasoningOrStory)
    }

    func testEvidenceGroupsByInactivityAndRecordsSupportOnAnIncorrectAttempt() throws {
        var profile = LearnerProfile()
        MasteryEngine().record(LearningEvidence(encounterID: "previous-block", skillID: MathSkills.counting,
            outcome: .correct, timestamp: epoch), in: &profile)
        let start = epoch.addingTimeInterval(21 * 60)
        MasteryEngine().record(LearningEvidence(encounterID: "new-block", skillID: MathSkills.addition,
            outcome: .incorrect, supportLevel: .strongHint, representation: .story,
            timestamp: start), in: &profile)
        MasteryEngine().record(LearningEvidence(encounterID: "new-block", skillID: MathSkills.addition,
            outcome: .correct, timestamp: start.addingTimeInterval(20)), in: &profile)
        // Future evidence must not alter the summary for the requested time.
        MasteryEngine().record(LearningEvidence(encounterID: "future", skillID: MathSkills.bonds10,
            outcome: .correct, timestamp: start.addingTimeInterval(100)), in: &profile)

        let recent = try XCTUnwrap(try summary(profile, at: start.addingTimeInterval(30)).recentSession)
        XCTAssertEqual(recent.skills.map(\.id), [MathSkills.addition])
        XCTAssertEqual(recent.startedAt, start)
        XCTAssertEqual(recent.endedAt, start.addingTimeInterval(20))
        XCTAssertTrue(recent.usedPipSupport)
        XCTAssertTrue(recent.includedReasoningOrStory)
    }
}
