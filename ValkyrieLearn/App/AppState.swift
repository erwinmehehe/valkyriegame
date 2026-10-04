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
    @discardableResult func startWorkshop(_ encounter: LearningEncounter) -> Bool {
        // Unscored sandbox: no mastery, evidence or prerequisite bypass.
        guard cart == nil || cart?.completed == true || workshop else { return false }
        let engagement = EngagementDirector()
        guard engagement.allows(encounter, profile: profile),
              !engagement.needsWorldChange(profile: profile, now: Date()) else { return false }
        do {
            cart = try CrystalCartModel(encounter: encounter); workshop = true
            profile.begin(encounter, at: Date()); persist(); return true
        } catch { saveError = "This workshop example could not be opened."; return false }
    }
    func addCrystal() { guard cart != nil else { return }; _ = cart?.add(); persist() }
    func removeCrystal() { guard cart != nil else { return }; _ = cart?.remove(); persist() }
    func scaffold() -> Scaffold? {
        guard let current = cart, !current.completed else { return nil }
        let scaffold = ScaffoldingEngine().next(after: current.support)
        cart?.apply(scaffold)
        var cue = scaffold.cue
        var demonstrates = scaffold.demonstratesStep
        if demonstrates {
            if current.quantity < current.encounter.targetQuantity {
                _ = cart?.add(); cue = "Watch Pip add one crystal. Then you can try."
            } else if current.quantity > current.encounter.targetQuantity {
                _ = cart?.remove(); cue = "Watch Pip take one crystal back. Then you can try."
            } else {
                cue = "The cart is ready. Try Pip's lever."; demonstrates = false
            }
        }
        persist()
        return Scaffold(support: scaffold.support, cue: cue, demonstratesStep: demonstrates)
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
