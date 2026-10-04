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
    private(set) var mathAdventure: MathAdventureSaveState
    private(set) var workshop: Bool

    let graph: SkillGraph
    let audio = AudioSystem()

    private let store: LearningStore
    private var sessionCursor: SessionPlanCursor?

    var activeMath: MathMechanicRuntime? { mathAdventure.runtime }
    var activeEncounter: LearningEncounter? { mathAdventure.runtime?.encounter }
    var activeCompleted: Bool { mathAdventure.runtime?.completed ?? false }
    var placementComplete: Bool { mathAdventure.placementComplete }

    /// Compatibility view for the original Crystal Cart scene/tests.
    var cart: CrystalCartModel? {
        guard case .crystalCart(let cart) = mathAdventure.runtime else { return nil }
        return cart
    }

    init(context: ModelContext) throws {
        store = try LearningStore(context: context)
        profile = try store.loadProfile()
        mathAdventure = try store.loadMathAdventure()
        workshop = store.snapshot.workshop
        soundEnabled = store.snapshot.soundEnabled
        reducedMotion = store.snapshot.reducedMotion
        world = World(rawValue: store.snapshot.lastWorld) ?? .storyTree
        graph = try MathSkills.graph()
        audio.enabled = soundEnabled
        ReviewScheduler().markDue(in: &profile, at: Date())
    }

    func travel(to world: World) {
        self.world = world
        persist()
    }

    /// Returns the next child-facing beat. Hidden placement runs first, then the
    /// adaptive 60/20/15/5 session planner takes over.
    func prepareNext() -> EncounterSelection {
        if let runtime = mathAdventure.runtime, !runtime.completed {
            return .encounter(runtime.encounter)
        }

        if mathAdventure.runtime?.completed == true {
            mathAdventure.runtime = nil
            workshop = false
        }

        if !mathAdventure.placementComplete {
            return preparePlacement()
        }

        return prepareAdaptiveBeat()
    }

    @discardableResult
    func startWorkshop(_ encounter: LearningEncounter) -> Bool {
        // Keep hidden placement uninterrupted. Workshop opens after the castle has
        // quietly learned enough to start an adaptive session.
        guard mathAdventure.placementComplete else { return false }

        if let runtime = mathAdventure.runtime, !runtime.completed, !workshop {
            return false
        }

        let engagement = EngagementDirector()
        guard engagement.allows(encounter, profile: profile),
              !engagement.needsWorldChange(profile: profile, now: Date()) else {
            return false
        }

        do {
            mathAdventure.runtime = try MathMechanicRuntime(encounter: encounter)
            workshop = true
            profile.begin(encounter, at: Date())
            persist()
            return true
        } catch {
            saveError = "This workshop example could not be opened."
            return false
        }
    }

    @discardableResult
    func incrementActive() -> Bool {
        guard var runtime = mathAdventure.runtime else { return false }
        let changed = runtime.increment()
        mathAdventure.runtime = runtime
        if changed { persist() }
        return changed
    }

    @discardableResult
    func decrementActive() -> Bool {
        guard var runtime = mathAdventure.runtime else { return false }
        let changed = runtime.decrement()
        mathAdventure.runtime = runtime
        if changed { persist() }
        return changed
    }

    func setActiveValue(_ value: Int) {
        guard var runtime = mathAdventure.runtime else { return }
        runtime.setValue(value)
        mathAdventure.runtime = runtime
        persist()
    }

    func chooseComparison(_ choice: ComparisonChoice) {
        guard var runtime = mathAdventure.runtime else { return }
        runtime.chooseComparison(choice)
        mathAdventure.runtime = runtime
        persist()
    }

    // Compatibility names retained for the original Crystal Cart callers/tests.
    func addCrystal() { _ = incrementActive() }
    func removeCrystal() { _ = decrementActive() }

    func scaffold() -> Scaffold? {
        guard var runtime = mathAdventure.runtime, !runtime.completed else { return nil }

        let scaffold = ScaffoldingEngine().next(after: runtime.support)
        runtime.apply(scaffold)

        var cue = scaffold.cue
        var demonstrates = scaffold.demonstratesStep

        if demonstrates {
            switch runtime {
            case .crystalCart(let model):
                if model.quantity < model.encounter.targetQuantity {
                    _ = runtime.increment()
                    cue = "Watch Pip move one crystal. Then you can try."
                } else if model.quantity > model.encounter.targetQuantity {
                    _ = runtime.decrement()
                    cue = "Watch Pip move one crystal back. Then you can try."
                } else {
                    cue = "The cart is ready. Try Pip's lever."
                    demonstrates = false
                }

            case .numberBond(let model):
                if model.selectedPart < model.correctMissingPart {
                    _ = runtime.increment()
                    cue = "Pip adds one crystal to the missing part. What should happen next?"
                } else if model.selectedPart > model.correctMissingPart {
                    _ = runtime.decrement()
                    cue = "Pip removes one crystal from the missing part. What should happen next?"
                } else {
                    cue = "The two parts are ready. Try Pip's lever."
                    demonstrates = false
                }

            case .tenFrame(let model):
                if model.filled < model.encounter.targetQuantity {
                    _ = runtime.increment()
                    cue = "Pip lights one more space. Keep the pattern going."
                } else if model.filled > model.encounter.targetQuantity {
                    _ = runtime.decrement()
                    cue = "Pip turns one light off. Check the frame again."
                } else {
                    cue = "The frame is ready. Try Pip's lever."
                    demonstrates = false
                }

            case .missingBridge(let model):
                if model.selectedNumber < model.correctNumber {
                    _ = runtime.increment()
                    cue = "Pip nudges the missing number up by one. Keep reasoning from there."
                } else if model.selectedNumber > model.correctNumber {
                    _ = runtime.decrement()
                    cue = "Pip nudges the missing number down by one. Check the equation again."
                } else {
                    cue = "The bridge number is ready. Try Pip's lever."
                    demonstrates = false
                }

            case .balanceScale(let model):
                runtime.chooseComparison(model.correctChoice)
                cue = "Pip steadies the scale so you can see the relationship. Try the lever when you're ready."
            }
        }

        mathAdventure.runtime = runtime
        persist()
        return Scaffold(
            support: scaffold.support,
            cue: cue,
            demonstratesStep: demonstrates
        )
    }

    func submit() -> LearningEvidence? {
        guard var runtime = mathAdventure.runtime,
              let evidence = runtime.submit() else {
            return nil
        }

        mathAdventure.runtime = runtime

        if workshop {
            persist()
            return evidence
        }

        MasteryEngine().record(evidence, in: &profile)

        if !mathAdventure.placementComplete {
            resolvePlacement(evidence)
        } else if evidence.outcome == .correct {
            _ = sessionCursor?.advance()
        }

        persist()
        return evidence
    }

    func finishExploration() {
        profile.recordActivity(
            ActivityRecord(
                fingerprint: "pipWind-\(UUID())",
                mechanicID: "pipWind",
                timestamp: Date()
            )
        )

        if mathAdventure.placementComplete,
           case .explorationBreak? = sessionCursor?.current {
            _ = sessionCursor?.advance()
        }

        persist()
    }

    func retrySave() { persist() }

    func persist() {
        do {
            try store.save(
                profile: profile,
                mathAdventure: mathAdventure,
                workshop: workshop,
                sound: soundEnabled,
                reducedMotion: reducedMotion,
                world: world.rawValue
            )
            saveError = nil
        } catch {
            saveError = "Progress could not be saved. Keep the app open and retry in Settings."
        }
    }

    private func preparePlacement() -> EncounterSelection {
        let probes = MathPlacement.playableProbes
        guard !probes.isEmpty else {
            mathAdventure.placementComplete = true
            persist()
            return prepareAdaptiveBeat()
        }

        let engine = PlacementEngine(probes: probes)
        var session = mathAdventure.placementSession ?? engine.begin(startBand: 2)

        if session.isComplete {
            mathAdventure.placementSession = session
            mathAdventure.placementComplete = true
            persist()
            return prepareAdaptiveBeat()
        }

        guard let probe = engine.nextProbe(for: session) else {
            mathAdventure.placementSession = session
            mathAdventure.placementComplete = true
            persist()
            return prepareAdaptiveBeat()
        }

        mathAdventure.placementSession = session

        do {
            mathAdventure.runtime = try MathMechanicRuntime(encounter: probe.encounter)
            workshop = false
            profile.begin(probe.encounter, at: Date())
            persist()
            return .encounter(probe.encounter)
        } catch {
            // `playableProbes` should guarantee this path is unreachable. Fail
            // closed instead of mutating diagnostic state from the app layer.
            saveError = "Pip found a castle machine that is not ready yet."
            persist()
            return .needsContent(probe.skillID)
        }
    }

    private func resolvePlacement(_ evidence: LearningEvidence) {
        let probes = MathPlacement.playableProbes
        let engine = PlacementEngine(probes: probes)

        guard let probe = probes.first(where: {
            $0.encounter.id == evidence.encounterID && $0.skillID == evidence.skillID
        }) else {
            return
        }

        var session = mathAdventure.placementSession ?? engine.begin(startBand: probe.band)
        engine.record(evidence, for: probe, in: &session)
        mathAdventure.placementSession = session

        if PlacementResponse(evidence) == .independentSuccess {
            profile.markPlacementReady(graph.prerequisiteClosure(including: probe.skillID))
        }

        if session.isComplete {
            mathAdventure.placementComplete = true
        }

        // A diagnostic miss is useful evidence; do not make the child grind the same
        // placement item. The next hidden probe steps to a more appropriate band.
        if evidence.outcome == .incorrect {
            mathAdventure.runtime = nil
        }
    }

    private func prepareAdaptiveBeat() -> EncounterSelection {
        var safety = 0

        while safety < 32 {
            safety += 1

            if sessionCursor == nil || sessionCursor?.isComplete == true {
                do {
                    let plan = try MathCastleEncounterCatalog.sessionPlan(
                        for: profile,
                        encounterCount: 12,
                        now: Date()
                    )
                    guard !plan.beats.isEmpty else {
                        return .needsContent(nil)
                    }
                    sessionCursor = SessionPlanCursor(plan: plan)
                } catch {
                    saveError = "Pip could not plan the next castle route."
                    return .needsContent(nil)
                }
            }

            guard let beat = sessionCursor?.current else {
                sessionCursor = nil
                continue
            }

            switch beat {
            case .explorationBreak:
                return .explorationBreak

            case .encounter(let planned):
                do {
                    mathAdventure.runtime = try MathMechanicRuntime(encounter: planned.encounter)
                    workshop = false
                    profile.begin(planned.encounter, at: Date())
                    persist()
                    return .encounter(planned.encounter)
                } catch {
                    // Skip only the unsupported beat and continue the authored session.
                    _ = sessionCursor?.advance()
                }
            }
        }

        return .needsContent(nil)
    }
}
