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
    // Place value now enters through its dedicated native factory; unsupported
    // future probes remain excluded. Advanced reasoning is mapped onto the existing
    // Number Bond machine instead of being hidden behind an age ceiling.
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
                // a strong learner can demonstrate reasoning without requiring a
                // separate error-analysis machine.
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
    @discardableResult
    public mutating func adjustPlaceValue(tensDelta: Int = 0, onesDelta: Int = 0) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.adjustPlaceValue(tensDelta: tensDelta, onesDelta: onesDelta) ?? false
    }
    @discardableResult public mutating func choosePatternSymbol(_ symbol: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.choosePatternSymbol(symbol) ?? false
    }

    @discardableResult public mutating func undoPatternSymbol() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoPatternSymbol() ?? false
    }

    @discardableResult public mutating func chooseShapeOption(_ option: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.chooseShapeOption(option) ?? false
    }

    @discardableResult public mutating func rotateShape(_ delta: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.rotateShape(delta) ?? false
    }

    @discardableResult public mutating func placeShapeHalf(_ turns: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.placeShapeHalf(turns) ?? false
    }

    @discardableResult public mutating func undoShapeHalf() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoShapeHalf() ?? false
    }

    @discardableResult public mutating func cycleMirrorCell(_ row: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.cycleMirrorCell(row) ?? false
    }

    @discardableResult public mutating func placeMeasureUnit() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.placeMeasureUnit() ?? false
    }

    @discardableResult public mutating func removeMeasureUnit() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.removeMeasureUnit() ?? false
    }

    @discardableResult public mutating func sortDataObject(into bin: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.sortDataObject(into: bin) ?? false
    }

    @discardableResult public mutating func undoDataSort() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoDataSort() ?? false
    }

    @discardableResult public mutating func addPicture(to column: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.addPicture(to: column) ?? false
    }

    @discardableResult public mutating func undoPicture() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoPicture() ?? false
    }

    @discardableResult public mutating func adjustClockHour(_ delta: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.adjustClockHour(delta) ?? false
    }

    @discardableResult public mutating func adjustClockMinute(_ delta: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.adjustClockMinute(delta) ?? false
    }

    @discardableResult public mutating func placeDailyRoutine(_ daypart: ClockMarketDaypart) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.placeDailyRoutine(daypart) ?? false
    }

    @discardableResult public mutating func undoDailyRoutine() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoDailyRoutine() ?? false
    }

    @discardableResult public mutating func addPesoCoin(_ value: Int) -> Bool {
        guard interactionStarted else { return false }
        return runtime?.addPesoCoin(value) ?? false
    }

    @discardableResult public mutating func undoPesoCoin() -> Bool {
        guard interactionStarted else { return false }
        return runtime?.undoPesoCoin() ?? false
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
            cue = "The bridge needs \(model.encounter.targetQuantity) planks. \(model.encounter.initialQuantity) are fixed. Fill the gaps."
            if demonstration { cue = "Watch Pip move one plank. Then finish the bridge." }
            if demonstration {
                if model.selectedNumber < model.correctNumber { _ = increment(at: now) }
                else if model.selectedNumber > model.correctNumber { _ = decrement(at: now) }
                else { demonstration = false }
            }
        case .shapeForge(let model):
            switch model.task {
            case .recognize:
                cue = "Look at each outline. Count corners and notice which sides are curved."
                if demonstration, let option = model.correctOption {
                    _ = runtime?.chooseShapeOption(option)
                    cue = "Pip points to the matching outline. Pull the lever to check."
                }
            case .attributes:
                cue = "Use your finger to count where straight sides meet."
                if demonstration, let option = model.correctOption {
                    _ = runtime?.chooseShapeOption(option)
                    cue = "Pip counted the corners. Pull the lever to check."
                }
            case .rotate:
                cue = "Turn the angled triangle until it points the same way as the gold outline."
                if demonstration {
                    let difference = (model.targetOrientation - model.currentOrientation + 4) % 4
                    if difference != 0 {
                        _ = runtime?.rotateShape(difference == 3 ? -1 : 1)
                        cue = "Pip turned the triangle one quarter-turn. Finish the match."
                    } else {
                        demonstration = false
                    }
                }
            case .compose:
                cue = "A square can be made from two matching right triangles. Turn the first piece to the gold seam, then place the second opposite it."
                // The child must position both halves. Never auto-complete a
                // composition from a scaffold.
                demonstration = false
            case .symmetry:
                cue = "Imagine a mirror down the middle. Tap each right-hand cell until its shape matches the left at the same height."
                // An independent three-cell reconstruction is observable.
                demonstration = false
            }
        case .patternLoom(let model):
            if model.isCreation {
                cue = "Make a repeat group. AB has two different shapes; AAB repeats one twice; ABC uses three different shapes."
                // Creating a pattern requires an independent sequence of choices.
                // Do not silently complete it for the learner.
                demonstration = false
            } else {
                cue = next.support == .lightHint
                    ? "Look for the group that repeats. Which shape belongs in the empty space?"
                    : "Find the first repeating group, then follow it to the missing space."
                if demonstration {
                    _ = runtime?.choosePatternSymbol(model.correctSymbol)
                    cue = "Watch Pip place one repeating shape. Now try the lever."
                }
            }
        case .clockMarket(let model):
            switch model.task {
            case .hour, .halfHour, .fiveMinutes:
                cue = "The short clock hand shows the hour. The long hand counts minutes around the circle."
                if model.task == .halfHour {
                    cue = "The long hand at 12 means o'clock; at 6 it means half past."
                } else if model.task == .fiveMinutes {
                    cue = "Each numeral on the big hand is another five minutes. Move the hour hand too."
                }
                if demonstration {
                    if model.hour != model.targetHour {
                        _ = runtime?.adjustClockHour(1)
                        cue = "Pip moved the short hand one hour. Set both hands to the target."
                    } else if model.task != .hour, model.minute != model.targetMinute {
                        _ = runtime?.adjustClockMinute(1)
                        cue = "Pip moved the long hand one step. Finish setting the time."
                    } else {
                        demonstration = false
                    }
                }
            case .routines:
                cue = "What happens in the morning, afternoon, evening and at night? Sort each picture."
                if demonstration, let routine = model.nextRoutine {
                    _ = runtime?.placeDailyRoutine(routine.daypart)
                    cue = "Pip sorted one event as an example. Sort the remaining picture cards."
                }
            case .money:
                cue = "Look at the peso amount on each teaching coin. Combine the coins to match the price."
                if demonstration {
                    let remaining = model.targetPesos - model.totalPesos
                    if let denomination = model.allowedCoins.reversed().first(where: { $0 <= remaining }) {
                        _ = runtime?.addPesoCoin(denomination)
                        cue = "Pip added one peso coin. Choose coins to finish paying exactly."
                    } else {
                        demonstration = false
                    }
                }
            }
        case .dataBoard(let model):
            if model.isSorting {
                cue = model.sortingAttribute == .color
                    ? "Look at each object's color. Send it to the bin with the matching color."
                    : "Look at each object's shape. Send it to the bin with the matching shape."
                if demonstration, let token = model.nextSortingToken,
                   let attribute = model.sortingAttribute {
                    _ = runtime?.sortDataObject(into: token.category(for: attribute))
                    cue = "Pip sorted one object as an example. Sort the rest yourself."
                }
            } else {
                cue = "Count the shapes in each group above. Put one matching picture in that graph column for each object."
                if demonstration {
                    let counts = model.graphSourceCounts
                    if let index = (0..<3).first(where: { model.graphTiles[$0] < counts[$0] }) {
                        _ = runtime?.addPicture(to: index + 1)
                        cue = "Pip placed one graph picture. Finish the other columns."
                    } else {
                        demonstration = false
                    }
                }
            }
        case .measurementWorkshop(let model):
            switch model.task {
            case .length:
                cue = "Put both ribbons against the same starting line. Compare where they end."
            case .weight:
                cue = "Each stone weighs the same. Which tray has more equal-weight stones?"
            case .capacity:
                cue = "Each level represents one equal measuring cup. Which vessel holds more?"
            case .units:
                cue = "Place the same-size units from one end of the bridge to the other. No gaps or overlaps."
            }
            if demonstration {
                if model.isUnitMeasurement {
                    if model.placedUnits < model.targetUnitCount {
                        _ = runtime?.placeMeasureUnit()
                        cue = "Pip placed one measuring unit. Fill the remaining length."
                    } else {
                        demonstration = false
                    }
                } else {
                    runtime?.chooseComparison(model.correctChoice)
                    cue = "Pip chose a comparison. Pull the lever to check, then try another."
                }
            }
        case .placeValueFactory(let model):
            if model.isComparison {
                cue = model.encounter.skillID == MathSkills.numberOrder20
                    || model.encounter.skillID == MathSkills.orderTwoDigit
                    ? "Compare the tens first, then the ones. Which number comes first from least to greatest?"
                    : "Compare the tens first. If the tens match, compare the ones."
                if demonstration {
                    runtime?.chooseComparison(model.correctChoice)
                    cue = "Watch Pip compare the tens and ones. Now pull the lever."
                }
            } else {
                cue = "Build the number with tens rods and ones cubes."
                if demonstration {
                    if model.selectedTens < model.expectedTens {
                        _ = runtime?.adjustPlaceValue(tensDelta: 1)
                        cue = "Watch Pip add one tens rod. Now keep building."
                    } else if model.selectedTens > model.expectedTens {
                        _ = runtime?.adjustPlaceValue(tensDelta: -1)
                        cue = "Watch Pip remove one tens rod. Now keep building."
                    } else if model.selectedOnes < model.expectedOnes {
                        _ = runtime?.adjustPlaceValue(onesDelta: 1)
                        cue = "Watch Pip add one ones cube. Now keep building."
                    } else if model.selectedOnes > model.expectedOnes {
                        _ = runtime?.adjustPlaceValue(onesDelta: -1)
                        cue = "Watch Pip remove one ones cube. Now keep building."
                    } else {
                        demonstration = false
                    }
                }
            }
        }
        return Scaffold(support: next.support, cue: cue, demonstratesStep: demonstration)
    }
}
