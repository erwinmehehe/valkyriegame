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
    private(set) var adventure: MathAdventure
    var runtime: MathMechanicRuntime? { adventure.runtime }
    var cart: CrystalCartModel? {
        if case .crystalCart(let cart) = runtime { return cart }
        return nil
    }
    var workshop: Bool { adventure.workshop }
    var isPlacement: Bool { adventure.isPlacement }
    var previewVisible: Bool { adventure.previewVisible(at: Date()) }
    var interactionStarted: Bool { adventure.interactionStarted }
    let graph: SkillGraph
    let audio = AudioSystem()
    private let store: LearningStore
    init(context: ModelContext) throws {
        store = try LearningStore(context: context)
        profile = try store.loadProfile()
        adventure = try store.loadAdventure(continuingLearner: !profile.skills.isEmpty)
        soundEnabled = store.snapshot.soundEnabled
        reducedMotion = store.snapshot.reducedMotion
        world = World(rawValue: store.snapshot.lastWorld) ?? .storyTree
        graph = try MathSkills.graph()
        audio.enabled = soundEnabled
        ReviewScheduler().markDue(in: &profile, at: Date())
    }
    func travel(to world: World) { self.world = world; persist() }
    func prepareNext() -> EncounterSelection {
        do {
            ReviewScheduler().markDue(in: &profile, at: Date())
            let selection = try adventure.prepareNext(profile: &profile, now: Date())
            persist(); return selection
        } catch {
            saveError = "This work order could not be opened. Your saved progress has not been reset."
            return .needsContent(nil)
        }
    }
    func beginInteraction() {
        do { try adventure.beginInteraction(at: Date()); persist() }
        catch { saveError = "Pip could not start this work order. Try returning to Story Tree." }
    }
    @discardableResult func advanceEncounter() -> Bool {
        let advanced = adventure.advanceEncounter(); persist(); return advanced
    }
    @discardableResult func startWorkshop(_ encounter: LearningEncounter) -> Bool {
        do {
            let opened = try adventure.startWorkshop(encounter, profile: &profile, now: Date())
            if opened { persist() }; return opened
        } catch { saveError = "This workshop example could not be opened."; return false }
    }
    func addCrystal() { beginInteraction(); _ = adventure.increment(at: Date()); persist() }
    func removeCrystal() { beginInteraction(); _ = adventure.decrement(at: Date()); persist() }
    func chooseComparison(_ choice: ComparisonChoice) { beginInteraction(); adventure.chooseComparison(choice); persist() }
    func setNumber(_ number: Int) { beginInteraction(); adventure.setNumber(number); persist() }
    func scaffold() -> Scaffold? {
        beginInteraction()
        let scaffold = adventure.scaffold(at: Date()); persist(); return scaffold
    }
    func submit() -> LearningEvidence? {
        beginInteraction()
        let evidence = adventure.submit(profile: &profile, at: Date()); persist(); return evidence
    }
    func finishExploration() { adventure.finishExploration(profile: &profile, at: Date()); persist() }
    func retrySave() { persist() }
    func persist() {
        do {
            try store.save(profile: profile, adventure: adventure,
                           sound: soundEnabled, reducedMotion: reducedMotion, world: world.rawValue)
            saveError = nil
        } catch { saveError = "Progress could not be saved. Keep the app open and retry in Settings." }
    }
}
