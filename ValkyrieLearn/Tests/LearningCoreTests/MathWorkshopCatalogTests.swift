import XCTest
@testable import LearningCore

final class MathWorkshopCatalogTests: XCTestCase {
    func testAllFiveStationsOfferDistinctPlayableMechanicFamilies() throws {
        let graph = try MathSkills.graph()
        let profile = LearnerProfile()
        XCTAssertEqual(MathWorkshopCatalog.stationNames.count, 5)
        XCTAssertEqual(MathWorkshopCatalog.stationMechanics.count, 5)
        XCTAssertEqual(Set(MathWorkshopCatalog.stationMechanics.flatMap { $0 }), MathMechanicID.adaptiveSet)
        for station in 0..<5 {
            let choices = MathWorkshopCatalog.choices(at: station, profile: profile, graph: graph)
            XCTAssertFalse(choices.isEmpty, "Station \(station) needs at least one ready option")
            let allowed = Set(MathWorkshopCatalog.stationMechanics[station])
            XCTAssertTrue(choices.allSatisfy { allowed.contains($0.mechanicID) })
            XCTAssertEqual(Set(choices.map(\.fingerprint)).count, choices.count)
            XCTAssertTrue(choices.allSatisfy { MathManipulativeSupport.supports($0) })
        }
    }

    func testUsedAndNotYetEligibleEncountersAreExcluded() throws {
        let graph = try MathSkills.graph()
        var profile = LearnerProfile()
        let original = MathWorkshopCatalog.choices(at: 0, profile: profile, graph: graph)
        let first = try XCTUnwrap(original.first)
        profile.begin(first, at: Date(timeIntervalSince1970: 1000))
        let remaining = MathWorkshopCatalog.choices(at: 0, profile: profile, graph: graph)
        XCTAssertFalse(remaining.contains(where: { $0.fingerprint == first.fingerprint }))
        XCTAssertTrue(remaining.allSatisfy { graph.isEligible($0.skillID, for: profile) })
    }

    func testWorkshopChoicesDoNotModifyLearnerProgress() throws {
        let graph = try MathSkills.graph()
        let profile = LearnerProfile()
        let before = profile
        for station in 0..<5 {
            _ = MathWorkshopCatalog.choices(at: station, profile: profile, graph: graph)
        }
        XCTAssertEqual(profile, before)
        XCTAssertTrue(MathWorkshopCatalog.choices(at: 99, profile: profile, graph: graph).isEmpty)
    }
}
