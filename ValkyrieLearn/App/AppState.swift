import Foundation
import SwiftUI
import SwiftData
import LearningCore

@MainActor final class AppState: ObservableObject {
    enum World: String { case storyTree, mathCastle }
    @Published var world: World
    @Published var soundEnabled: Bool { didSet { audio.enabled = soundEnabled; persist() } }
    @Published var reducedMotion: Bool { didSet { persist() } }
    @Published private(set) var saveError: String?
    private(set) var profile: LearnerProfile
    private(set) var cart: CrystalCartModel?
    private(set) var workshop: Bool
    let graph: SkillGraph
    let audio = AudioSystem()
    private let store: LearningStore
    init(context: ModelContext) throws {
        store = try LearningStore(context: context)
        profile = try store.loadProfile()
        cart = try store.loadCart()
        workshop = store.snapshot.workshop
        soundEnabled = store.snapshot.soundEnabled
        reducedMotion = store.snapshot.reducedMotion
        world = World(rawValue: store.snapshot.lastWorld) ?? .storyTree
        graph = try MathSkills.graph()
        audio.enabled = soundEnabled
        ReviewScheduler().markDue(in: &profile, at: Date())
    }
    func travel(to world: World) { self.world = world; persist() }
    func prepareNext() -> EncounterSelection {
        if let cart, !cart.completed { return .encounter(cart.encounter) }
        let selection = AdaptiveDirector(graph: graph).next(for: profile, candidates: MathFoundation.encounters, now: Date())
        if case .encounter(let encounter) = selection {
            do {
                cart = try CrystalCartModel(encounter: encounter)
                workshop = false
                profile.begin(encounter, at: Date())
                persist()
            } catch { saveError = "This work order could not be opened." }
        }
        return selection
    }
    func startWorkshop(_ encounter: LearningEncounter) {
        // Unscored sandbox: no mastery, evidence or prerequisite bypass.
        do { cart = try CrystalCartModel(encounter: encounter); workshop = true; persist() }
        catch { saveError = "This workshop example could not be opened." }
    }
    func addCrystal() { guard cart != nil else { return }; _ = cart?.add(); persist() }
    func removeCrystal() { guard cart != nil else { return }; _ = cart?.remove(); persist() }
    func scaffold() -> Scaffold? {
        guard let current = cart, !current.completed else { return nil }
        let scaffold = ScaffoldingEngine().next(after: current.support)
        cart?.apply(scaffold)
        if scaffold.demonstratesStep && current.quantity < current.encounter.targetQuantity { _ = cart?.add() }
        persist(); return scaffold
    }
    func submit() -> LearningEvidence? {
        guard let evidence = cart?.submit() else { return nil }
        if !workshop { MasteryEngine().record(evidence, in: &profile) }
        persist(); return evidence
    }
    func finishExploration() {
        profile.recordActivity(ActivityRecord(fingerprint: "pipWind-\(UUID())", mechanicID: "pipWind", timestamp: Date()))
        persist()
    }
    func retrySave() { persist() }
    func persist() {
        do {
            try store.save(profile: profile, cart: cart, workshop: workshop,
                           sound: soundEnabled, reducedMotion: reducedMotion, world: world.rawValue)
            saveError = nil
        } catch { saveError = "Progress could not be saved. Keep the app open and retry in Settings." }
    }
}
