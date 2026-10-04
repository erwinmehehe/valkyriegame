import Foundation

public enum MathActivityMode: String, Codable, Sendable { case placement, practice, challenge, workshop }

/// Durable learning-side execution state. A planned activity is reselected after
/// each response so new evidence, review deadlines and engagement affect the next beat.
public struct MathAdventure: Codable, Equatable, Sendable {
    public private(set) var placement: PlacementSession
    public private(set) var placementComplete: Bool
    public private(set) var runtime: MathMechanicRuntime?
    public private(set) var mode: MathActivityMode = .practice
    public private(set) var interactionStarted = false
    public private(set) var explorationPending = false
    public private(set) var laneCounts: [SessionLane: Int] = [:]
    public private(set) var activeLane: SessionLane?
    public private(set) var encountersSinceExploration = 0
    /// Optional so saves written before Challenge Gate continue to decode.
    public private(set) var challengeGateSession: ChallengeGateSession?

    public init(legacyCart: CrystalCartModel? = nil, workshop: Bool = false, continuingLearner: Bool = false) {
        placement = Self.placementEngine.begin()
        placementComplete = continuingLearner || legacyCart != nil
        if let legacyCart {
            runtime = .crystalCart(legacyCart)
            mode = workshop ? .workshop : .practice
            interactionStarted = true
        }
    }

    // Only actually implemented mechanics enter the native placement adventure.
    // Unsupported probes such as place value remain authored future content until
    // their native manipulative exists; advanced reasoning is mapped onto the
    // existing Number Bond machine instead of being hidden behind an age ceiling.
    public static var playableProbes: [PlacementProbe] {
        MathPlacement.probes.compactMap { probe in
            if probe.band == 1 {
                return PlacementProbe(id: probe.id, band: probe.band, encounter:
                    LearningEncounter(id: probe.encounter.id, skillID: probe.skillID,
                        mechanicID: MathMechanicID.tenFrameGate, representation: .pictorial,
                        operation: .quantityMatching, initialQuantity: 0, targetQuantity: 3,
                        prompt: "Watch Pip's lights. When they hide, make the same quantity.", context: "quickLook"))
            }
            if probe.band == 9 {
                // Reuse the existing Number Bond machine as Pip's mistake machine so
                // a strong learner can still demonstrate reasoning in Milestone A
                // without pretending the not-yet-built place-value factory exists.
                return PlacementProbe(id: probe.id, band: probe.band, encounter:
                    LearningEncounter(id: probe.encounter.id, skillID: probe.skillID,
                        mechanicID: MathMechanicID.numberBondMachine, representation: .reasoning,
                        operation: .numberBond, initialQuantity: 5, targetQuantity: 8,
                        prompt: "Pip says five plus three is nine. Fix his machine so the whole is eight.",
                        context: "hiddenPlacement", challengeDepth: 2))
            }
            return (try? MathMechanicRuntime(encounter: probe.encounter)) != nil ? probe : nil
        }
    }
    public static var placementEngine: PlacementEngine { PlacementEngine(probes: playableProbes, maxProbes: 6) }
    public var placementRecommendation: PlacementRecommendation? {
        placementComplete && placement.completedProbeCount > 0 ? Self.placementEngine.recommendation(for: placement) : nil
    }
    public var workshop: Bool { mode == .workshop }
    public var isPlacement: Bool { mode == .placement && runtime != nil }
    public func previewVisible(at date: Date) -> Bool {
        guard interactionStarted, case .tenFrame(let model) = runtime else { return false }
        return model.previewIsVisible(at: date)
    }

    public mutating func prepareNext(profile: inout LearnerProfile, now: Date) throws -> EncounterSelection {
        // Returning home/relaunching must not silently advance a solved or unsolved object.
        if let runtime { return .encounter(runtime.encounter) }

        if let session = challengeGateSession {
            if session.isComplete {
                _ = profile.unlockStoryReward(session.rewardID)
                challengeGateSession = nil
                return .explorationBreak
            }
            guard let encounterID = session.nextEncounterID,
                  let encounter = ChallengeGateCatalog.encounter(id: encounterID),
                  MathManipulativeSupport.supports(encounter) else {
                return .needsContent(nil)
            }
            let graph = try MathSkills.graph()
            guard graph.isEligible(encounter.skillID, for: profile) else {
                return .needsContent(encounter.skillID)
            }
            try open(encounter, mode: .challenge, lane: nil, profile: &profile, now: now)
            return .encounter(encounter)
        }

        if explorationPending { return .explorationBreak }
        if EngagementDirector().needsWorldChange(profile: profile, now: now) || encountersSinceExploration >= 4 {
            explorationPending = true
            return .explorationBreak
        }
        if !placementComplete, let probe = Self.placementEngine.nextProbe(for: placement) {
            try open(probe.encounter, mode: .placement, lane: nil, profile: &profile, now: now)
            return .encounter(probe.encounter)
        }
        placementComplete = true
        let graph = try MathSkills.graph()
        let count = laneCounts.values.reduce(0, +)
        let desired = SessionPlanner(graph: graph).desiredLaneCounts(total: count + 1)
        let preferred = SessionLane.allCases.max {
            (desired[$0, default: 0] - laneCounts[$0, default: 0]) <
            (desired[$1, default: 0] - laneCounts[$1, default: 0])
        } ?? .learning
        let config = SessionPlannerConfiguration(
            learningWeight: preferred == .learning ? 100 : 0,
            reviewWeight: preferred == .review ? 100 : 0,
            stretchWeight: preferred == .stretch ? 100 : 0,
            confidenceWeight: preferred == .confidence ? 100 : 0,
            explorationEveryEncounters: 0)
        let plan = try MathCastleEncounterCatalog.sessionPlan(for: profile, encounterCount: 1, now: now, configuration: config)
        if plan.beats.first == .explorationBreak {
            explorationPending = true
            return .explorationBreak
        }
        guard let item = plan.encounters.first else { return .needsContent(nil) }
        try open(item.encounter, mode: .practice, lane: item.lane, profile: &profile, now: now)
        return .encounter(item.encounter)
    }

    private mutating func open(_ encounter: LearningEncounter, mode: MathActivityMode, lane: SessionLane?,
                               profile: inout LearnerProfile, now: Date) throws {
        let next = try MathMechanicRuntime(encounter: encounter, at: now)
        runtime = next; self.mode = mode; activeLane = lane; interactionStarted = false
        profile.begin(encounter, at: now)
    }
    public mutating func beginInteraction(at now: Date) throws {
        guard !interactionStarted, let current = runtime, !current.completed else { return }
        runtime = try MathMechanicRuntime(encounter: current.encounter, at: now)
        interactionStarted = true
    }
    @discardableResult
    public mutating func beginChallengeGate(
        profile: LearnerProfile,
        graph: SkillGraph
    ) -> Bool {
        guard placementComplete,
              runtime == nil,
              !explorationPending,
              challengeGateSession == nil,
              !profile.hasStoryReward(ChallengeGateCatalog.reward),
              let session = ChallengeGateCatalog.makeSession(for: profile, graph: graph) else {
            return false
        }
        challengeGateSession = session
        mode = .challenge
        interactionStarted = false
        activeLane = nil
        return true
    }

    @discardableResult public mutating func startWorkshop(_ encounter: LearningEncounter, profile: inout LearnerProfile, now: Date) throws -> Bool {
        guard runtime == nil || runtime?.completed == true || workshop,
              !explorationPending,
              EngagementDirector().allows(encounter, profile: profile),
              !EngagementDirector().needsWorldChange(profile: profile, now: now) else { return false }
        try open(encounter, mode: .workshop, lane: nil, profile: &profile, now: now)
        return true
    }
    @discardableResult public mutating func advanceEncounter() -> Bool {
        guard runtime?.completed == true || (workshop && runtime != nil) else { return false }
        runtime = nil; interactionStarted = false; activeLane = nil
        return true
    }
    public mutating func finishExploration(profile: inout LearnerProfile, at now: Date) {
        profile.recordActivity(ActivityRecord(fingerprint: "pipWind-\(UUID())", mechanicID: "pipWind", timestamp: now))
        explorationPending = false; encountersSinceExploration = 0
    }
    @discardableResult public mutating func increment(at now: Date) -> Bool {
        guard interactionStarted else { return false }
        if case .tenFrame(var model) = runtime {
            let changed = model.addCounter(at: now); runtime = .tenFrame(model); return changed
        }
        return runtime?.increment() ?? false
    }
    @discardableResult public mutating func decrement(at now: Date) -> Bool {
        guard interactionStarted else { return false }
        if case .tenFrame(var model) = runtime {
            let changed = model.removeCounter(at: now); runtime = .tenFrame(model); return changed
        }
        return runtime?.decrement() ?? false
    }
    public mutating func chooseComparison(_ choice: ComparisonChoice) {
        guard interactionStarted else { return }; runtime?.chooseComparison(choice)
    }
    public mutating func setNumber(_ value: Int) {
        guard interactionStarted else { return }; runtime?.setValue(value)
    }
    public mutating func submit(profile: inout LearnerProfile, at now: Date) -> LearningEvidence? {
        guard interactionStarted, let evidence = runtime?.submit(at: now) else { return nil }
        if !workshop {
            // Hidden placement is diagnostic. It can establish provisional readiness
            // but must never mutate observed mastery or masquerade as practice evidence.
            if mode != .placement {
                MasteryEngine().record(evidence, in: &profile)
            }
            if mode == .placement, let probe = Self.playableProbes.first(where: { $0.encounter.id == evidence.encounterID }) {
                // A first incorrect response is diagnostic; later scaffolded retries
                // cannot erase it or cause a second jump for the same probe.
                Self.placementEngine.record(evidence, for: probe, in: &placement)
                if PlacementResponse(evidence) == .independentSuccess,
                   let graph = try? MathSkills.graph() {
                    profile.markPlacementReady(graph.prerequisiteClosure(including: probe.skillID))
                }
                placementComplete = placement.isComplete
            }

            if mode == .challenge,
               evidence.outcome == .correct,
               var session = challengeGateSession,
               session.markCompleted(evidence.encounterID) {
                if session.isComplete {
                    _ = profile.unlockStoryReward(session.rewardID)
                    challengeGateSession = nil
                } else {
                    challengeGateSession = session
                }
            }

            if evidence.outcome == .correct {
                encountersSinceExploration += 1
                if let activeLane { laneCounts[activeLane, default: 0] += 1 }
            }
        }
        return evidence
    }
    public mutating func scaffold(at now: Date) -> Scaffold? {
        guard interactionStarted, let current = runtime, !current.completed else { return nil }
        let next = ScaffoldingEngine().next(after: current.support)
        runtime?.apply(next) // Support must precede any teaching action.
        var cue = next.cue
        var demonstration = next.demonstratesStep
        switch current {
        case .crystalCart(let model):
            if demonstration {
                if model.quantity < model.encounter.targetQuantity { _ = increment(at: now); cue = "Watch Pip add one crystal. Then you can try." }
                else if model.quantity > model.encounter.targetQuantity { _ = decrement(at: now); cue = "Watch Pip take one crystal back. Then you can try." }
                else { cue = "The cart is ready. Try Pip's lever."; demonstration = false }
            }
        case .balanceScale(let model):
            cue = next.support == .lightHint ? "Look at both pans. Which holds more?" : "The heavier pan hangs lower. Level pans hold equal quantities."
            if demonstration { runtime?.chooseComparison(model.correctChoice); cue = "Watch Pip compare the pans. Now try the lever." }
        case .numberBond(let model):
            cue = "The whole is \(model.whole). One part is \(model.knownPart). Build the other part."
            if demonstration {
                if model.selectedPart < model.correctMissingPart { _ = increment(at: now) }
                else if model.selectedPart > model.correctMissingPart { _ = decrement(at: now) }
                else { demonstration = false }
            }
        case .tenFrame(let model):
            cue = "Count the lights that are already on. Fill the spaces you still need."
            if model.previewDuration > 0, case .tenFrame(var assisted) = runtime {
                assisted.replayPreview(at: now); runtime = .tenFrame(assisted)
                cue = "Pip will show the lights again. Look, then make the same quantity."
                demonstration = false
            } else if demonstration {
                if model.filled < model.encounter.targetQuantity { _ = increment(at: now) }
                else if model.filled > model.encounter.targetQuantity { _ = decrement(at: now) }
                else { demonstration = false }
            }
        case .missingBridge(let model):
            cue = "Start at \(model.encounter.initialQuantity). How many steps reach \(model.encounter.targetQuantity)?"
            if demonstration {
                if model.selectedNumber < model.correctNumber { _ = increment(at: now) }
                else if model.selectedNumber > model.correctNumber { _ = decrement(at: now) }
                else { demonstration = false }
            }
        }
        return Scaffold(support: next.support, cue: cue, demonstratesStep: demonstration)
    }
}
