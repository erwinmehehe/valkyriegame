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
    private struct MathSave: Codable {
        let mathAdventureVersion: Int
        let adventure: MathAdventure
    }
    func loadAdventure(continuingLearner: Bool) throws -> MathAdventure {
        guard let data = snapshot.cartData else {
            return MathAdventure(continuingLearner: continuingLearner)
        }
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if object?["mathAdventureVersion"] != nil {
            let saved = try JSONDecoder().decode(MathSave.self, from: data)
            guard saved.mathAdventureVersion == 1 else { throw StoreError.unsupportedAdventureVersion }
            return saved.adventure
        }
        // Compatible upgrade from the original V1 Crystal Cart JSON. Preserve
        // quantities, attempts, support, completion and workshop status exactly.
        let cart = try JSONDecoder().decode(CrystalCartModel.self, from: data)
        return MathAdventure(legacyCart: cart, workshop: snapshot.workshop, continuingLearner: continuingLearner)
    }
    func loadCart() throws -> CrystalCartModel? {
        if case .crystalCart(let cart) = try loadAdventure(continuingLearner: false).runtime { return cart }
        return nil
    }
    func save(profile: LearnerProfile, adventure: MathAdventure,
              sound: Bool, reducedMotion: Bool, world: String) throws {
        let profileData = try JSONEncoder().encode(profile)
        let adventureData = try JSONEncoder().encode(MathSave(mathAdventureVersion: 1, adventure: adventure))
        snapshot.profileData = profileData; snapshot.cartData = adventureData
        snapshot.workshop = adventure.workshop; snapshot.soundEnabled = sound
        snapshot.reducedMotion = reducedMotion; snapshot.lastWorld = world
        do { try context.save() }
        catch { context.rollback(); throw error }
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
    enum StoreError: Error { case unsupportedProfileVersion, unsupportedAdventureVersion }
}
