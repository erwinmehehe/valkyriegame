import Foundation
import SwiftData
import LearningCore

// V1 is explicit. Future incompatible schema changes add a VersionedSchema and migration stage.
enum LearningSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [LearnerSnapshot.self] }
    @Model final class LearnerSnapshot {
        @Attribute(.unique) var id: UUID
        var profileData: Data
        var cartData: Data?
        var workshop = false
        var soundEnabled = true
        var reducedMotion = false
        var lastWorld = "storyTree"
        init(profile: LearnerProfile) throws {
            id = profile.id
            profileData = try JSONEncoder().encode(profile)
        }
    }
}
enum LearningMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LearningSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
typealias LearnerSnapshot = LearningSchemaV1.LearnerSnapshot

@MainActor final class LearningStore {
    let context: ModelContext
    private(set) var snapshot: LearnerSnapshot
    static func container(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: LearningSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, migrationPlan: LearningMigrationPlan.self, configurations: [configuration])
    }
    init(context: ModelContext) throws {
        self.context = context
        context.autosaveEnabled = false
        var descriptor = FetchDescriptor<LearnerSnapshot>()
        descriptor.fetchLimit = 1
        if let saved = try context.fetch(descriptor).first { snapshot = saved }
        else {
            snapshot = try LearnerSnapshot(profile: LearnerProfile())
            context.insert(snapshot); try context.save()
        }
    }
    func loadProfile() throws -> LearnerProfile {
        let profile = try JSONDecoder().decode(LearnerProfile.self, from: snapshot.profileData)
        guard profile.schemaVersion == 1 else { throw StoreError.unsupportedProfileVersion }
        return profile
    }
    func loadCart() throws -> CrystalCartModel? {
        try snapshot.cartData.map { try JSONDecoder().decode(CrystalCartModel.self, from: $0) }
    }
    func save(profile: LearnerProfile, cart: CrystalCartModel?, workshop: Bool,
              sound: Bool, reducedMotion: Bool, world: String) throws {
        let data = try JSONEncoder().encode(profile)
        let cartData = try cart.map { try JSONEncoder().encode($0) }
        snapshot.profileData = data; snapshot.cartData = cartData
        snapshot.workshop = workshop; snapshot.soundEnabled = sound
        snapshot.reducedMotion = reducedMotion; snapshot.lastWorld = world
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
    enum StoreError: Error { case unsupportedProfileVersion }
}
