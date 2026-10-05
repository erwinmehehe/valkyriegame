import Foundation
import SwiftUI
import SwiftData
import LearningCore

@MainActor final class AppState: ObservableObject {
    enum World: String { case storyTree, mathCastle, wordGarden, sunmillCrossing, storyHollow, scienceLab, scienceWeatherTower, scienceCreatureGrove, puzzlePalace, memoryBridge, stopGoOrbs }
    enum ChallengeGateStatus: Equatable { case locked, ready, active, completed }
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
    var placementComplete: Bool { adventure.placementComplete }
    var challengeGateStatus: ChallengeGateStatus {
        if profile.hasStoryReward(ChallengeGateCatalog.reward) { return .completed }
        if adventure.challengeGateSession != nil { return .active }
        guard placementComplete else { return .locked }
        return ChallengeGateCatalog.canStart(for: profile, graph: graph) ? .ready : .locked
    }
    var challengeGateCompletedCount: Int {
        adventure.challengeGateSession?.completedCount ?? 0
    }
    var challengeGateTotalCount: Int {
        adventure.challengeGateSession?.encounterIDs.count ?? ChallengeGateCatalog.challengeCount
    }
    var previewVisible: Bool { adventure.previewVisible(at: Date()) }
    var interactionStarted: Bool { adventure.interactionStarted }
    let graph: SkillGraph
    let literacyGraph: SkillGraph
    let scienceGraph: SkillGraph
    let puzzleGraph: SkillGraph
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
        literacyGraph = try LiteracySkillCatalog.graph()
        scienceGraph = try ScienceSkillCatalog.graph()
        puzzleGraph = try PuzzleSkillCatalog.graph()
        audio.enabled = soundEnabled
        ReviewScheduler().markDue(in: &profile, at: Date())
    }
    func travel(to world: World) { self.world = world; persist() }

    var scienceAdventure: ScienceAdventure {
        profile.scienceAdventure ?? ScienceAdventure()
    }

    func enterScienceLab() {
        if scienceAdventure.groveRestored || scienceAdventure.creatureRouteOpen {
            travel(to: .scienceCreatureGrove)
        } else if scienceAdventure.greenhouseComplete {
            travel(to: .scienceWeatherTower)
        } else {
            travel(to: .scienceLab)
        }
    }

    private func updateScience(_ body: (inout ScienceAdventure, inout LearnerProfile) -> Void) {
        var science = profile.scienceAdventure ?? ScienceAdventure()
        body(&science, &profile)
        profile.scienceAdventure = science
        persist()
    }

    func scienceInspectGreenhouse() {
        updateScience { science, profile in
            if science.greenhouseStage == .arrive { science.greenhouseStage = .inspected }
            science.recordEvidence(
                skillID: ScienceSkills.noticeDetails,
                mechanicID: ScienceLabMechanicID.miloInspect,
                outcome: .correct,
                representation: .concrete,
                encounterID: "science-greenhouse-inspect",
                profile: &profile
            )
        }
    }

    func scienceRecordDrySoilMistake() {
        updateScience { science, profile in
            science.recordEvidence(
                skillID: ScienceSkills.plantNeeds,
                mechanicID: ScienceLabMechanicID.sunPrism,
                outcome: .incorrect,
                representation: .reasoning,
                encounterID: "science-greenhouse-plant-needs",
                profile: &profile
            )
        }
    }

    func scienceWaterGreenhouse() {
        updateScience { science, profile in
            let easy = !profile.progress(for: ScienceSkills.plantNeeds).evidence.contains {
                $0.outcome == .incorrect
            }
            science.greenhouseStage = .watered
            science.recordPlacement(
                skillID: ScienceSkills.plantNeeds,
                outcome: .correct,
                easySuccess: easy,
                profile: &profile,
                graph: scienceGraph
            )
            science.recordEvidence(
                skillID: ScienceSkills.plantNeeds,
                mechanicID: ScienceLabMechanicID.waterChannel,
                outcome: .correct,
                representation: .reasoning,
                easySuccess: easy,
                encounterID: "science-greenhouse-plant-needs",
                profile: &profile
            )
        }
    }

    func scienceLightGreenhouse() {
        updateScience { science, profile in
            science.greenhouseStage = .lit
            science.greenhouseComplete = true
            science.recordEvidence(
                skillID: ScienceSkills.comparePlantConditions,
                mechanicID: ScienceLabMechanicID.sunPrism,
                outcome: .correct,
                representation: .reasoning,
                encounterID: "science-greenhouse-light-result",
                profile: &profile
            )
        }
    }

    func scienceObserveMorningWeather() {
        updateScience { science, profile in
            if science.weatherStage == .arrive { science.weatherStage = .morningObserved }
            science.recordEvidence(
                skillID: ScienceSkills.weatherObserve,
                mechanicID: ScienceLabMechanicID.weatherDial,
                outcome: .correct,
                representation: .concrete,
                encounterID: "science-weather-morning",
                profile: &profile
            )
        }
    }

    func scienceObserveAfternoonWeather() {
        updateScience { science, profile in
            if science.weatherStage == .morningObserved { science.weatherStage = .afternoonObserved }
            science.recordPlacement(
                skillID: ScienceSkills.weatherCompare,
                outcome: .correct,
                easySuccess: true,
                profile: &profile,
                graph: scienceGraph
            )
            science.recordEvidence(
                skillID: ScienceSkills.weatherCompare,
                mechanicID: ScienceLabMechanicID.weatherDial,
                outcome: .correct,
                representation: .reasoning,
                easySuccess: true,
                encounterID: "science-weather-compare",
                profile: &profile
            )
        }
    }

    func scienceChooseForecast(_ choice: ScienceForecastChoice) {
        updateScience { science, profile in
            science.selectedForecast = choice
            let correct = choice == .rain
            science.recordEvidence(
                skillID: ScienceSkills.weatherPattern,
                mechanicID: ScienceLabMechanicID.weatherDial,
                outcome: correct ? .correct : .incorrect,
                representation: .reasoning,
                encounterID: "science-weather-forecast",
                profile: &profile
            )
            if correct {
                science.weatherStage = .complete
                science.creatureRouteOpen = true
            }
        }
    }

    func scienceObserveAnimal() {
        updateScience { science, profile in
            if science.groveStage == .arrive { science.groveStage = .animalObserved }
            science.recordEvidence(
                skillID: ScienceSkills.animalNeeds,
                mechanicID: ScienceLabMechanicID.miloInspect,
                outcome: .correct,
                representation: .concrete,
                encounterID: "science-grove-animal-needs",
                profile: &profile
            )
        }
    }

    func scienceChooseHabitat(_ choice: ScienceHabitatChoice) {
        updateScience { science, profile in
            science.selectedHabitat = choice
            let correct = choice == .pondEdge
            science.recordPlacement(
                skillID: ScienceSkills.habitatMatch,
                outcome: correct ? .correct : .incorrect,
                easySuccess: correct,
                profile: &profile,
                graph: scienceGraph
            )
            science.recordEvidence(
                skillID: ScienceSkills.habitatMatch,
                mechanicID: ScienceLabMechanicID.habitatNests,
                outcome: correct ? .correct : .incorrect,
                representation: .reasoning,
                encounterID: "science-grove-habitat-match",
                profile: &profile
            )
            if correct { science.groveStage = .habitatMatched }
        }
    }

    func scienceInspectBodyPart() {
        updateScience { science, profile in
            science.groveStage = .bodyPartObserved
            science.recordEvidence(
                skillID: ScienceSkills.bodyPartFunction,
                mechanicID: ScienceLabMechanicID.miloInspect,
                outcome: .correct,
                representation: .reasoning,
                encounterID: "science-grove-webbed-feet",
                profile: &profile
            )
        }
    }

    func scienceCompareHabitat(_ choice: ScienceHabitatChoice) {
        updateScience { science, profile in
            let correct = choice == .pondEdge
            science.recordEvidence(
                skillID: ScienceSkills.compareHabitats,
                mechanicID: ScienceLabMechanicID.habitatNests,
                outcome: correct ? .correct : .incorrect,
                representation: .reasoning,
                encounterID: "science-grove-final-compare",
                profile: &profile
            )
            if correct {
                science.groveStage = .complete
                science.groveRestored = true
            }
        }
    }
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
    @discardableResult
    func beginChallengeGate() -> Bool {
        if let runtime = adventure.runtime, !runtime.completed { return false }
        if adventure.runtime?.completed == true {
            _ = adventure.advanceEncounter()
        }
        let began = adventure.beginChallengeGate(profile: profile, graph: graph)
        if began { persist() }
        return began
    }

    func hasStoryReward(_ reward: StoryRewardID) -> Bool {
        profile.hasStoryReward(reward)
    }

    func storyRewardPlacement(_ reward: StoryRewardID) -> Int {
        profile.storyRewardPlacement(reward)
    }

    @discardableResult
    func cycleStoryRewardPlacement(_ reward: StoryRewardID, slotCount: Int) -> Int {
        let slot = profile.cycleStoryRewardPlacement(reward, slotCount: slotCount)
        persist()
        return slot
    }

    func parentMathSummary(now: Date = Date()) -> ParentMathSummary {
        ParentMathSummaryBuilder.build(profile: profile, graph: graph, now: now)
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

    var flowerGateComplete: Bool {
        WordGardenDirector.flowerGateComplete(profile: profile)
    }

    var sunmillAvailable: Bool {
        WordGardenDirector.canEnterSunmill(profile: profile)
    }

    var sunmillComplete: Bool {
        WordGardenDirector.sunmillComplete(profile: profile)
    }

    var storyHollowAvailable: Bool {
        WordGardenDirector.canEnterStoryHollow(profile: profile)
    }

    var storyHollowComplete: Bool {
        WordGardenDirector.storyHollowComplete(profile: profile)
    }

    func nextLiteracyEncounter() -> LiteracyEncounter {
        WordGardenDirector.nextFlowerGateEncounter(profile: profile)
    }

    func nextSunmillEncounter() -> LiteracyEncounter? {
        WordGardenDirector.nextSunmillEncounter(profile: profile)
    }

    func nextStoryHollowEncounter() -> LiteracyEncounter? {
        WordGardenDirector.nextStoryHollowEncounter(profile: profile)
    }

    var puzzleRuneGateComplete: Bool {
        PuzzlePalaceDirector.runeGateComplete(profile: profile)
    }

    var puzzleMemoryBridgeAvailable: Bool {
        PuzzlePalaceDirector.canEnterMemoryBridge(profile: profile)
    }

    var puzzleMemoryBridgeComplete: Bool {
        PuzzlePalaceDirector.memoryBridgeComplete(profile: profile)
    }

    var puzzleStopGoAvailable: Bool {
        PuzzlePalaceDirector.canEnterStopGoOrbs(profile: profile)
    }

    var puzzleStopGoComplete: Bool {
        PuzzlePalaceDirector.stopGoComplete(profile: profile)
    }

    func nextPuzzleEncounter() -> PuzzleEncounter {
        PuzzlePalaceDirector.nextRuneGateEncounter(profile: profile)
    }

    func nextPuzzleMemoryEncounter() -> PuzzleMemoryEncounter? {
        PuzzlePalaceDirector.nextMemoryBridgeEncounter(profile: profile)
    }

    func nextPuzzleStopGoEncounter() -> PuzzleInhibitionEncounter? {
        PuzzlePalaceDirector.nextStopGoEncounter(profile: profile)
    }

    @discardableResult
    func recordPuzzle(
        _ encounter: PuzzleEncounter,
        outcome: Outcome,
        support: SupportLevel,
        attempts: Int,
        responseTime: TimeInterval?
    ) -> LearningEvidence {
        let evidence = LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            attempts: attempts,
            responseTime: responseTime,
            timestamp: Date(),
            transferContext: encounter.transferContext,
            easySuccess: outcome == .correct && support == .independent && attempts == 1
        )
        MasteryEngine().record(evidence, in: &profile)
        profile.recordActivity(ActivityRecord(
            fingerprint: encounter.fingerprint,
            mechanicID: encounter.mechanicID,
            skillID: encounter.skillID,
            representation: encounter.representation,
            timestamp: evidence.timestamp
        ))
        if outcome == .correct {
            profile.usedFingerprints.insert(encounter.fingerprint)
        }
        persist()
        return evidence
    }

    @discardableResult
    func recordPuzzle(
        _ encounter: PuzzleMemoryEncounter,
        outcome: Outcome,
        support: SupportLevel,
        attempts: Int,
        responseTime: TimeInterval?
    ) -> LearningEvidence {
        let evidence = LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            attempts: attempts,
            responseTime: responseTime,
            timestamp: Date(),
            transferContext: encounter.transferContext,
            easySuccess: outcome == .correct && support == .independent && attempts == 1
        )
        MasteryEngine().record(evidence, in: &profile)
        profile.recordActivity(ActivityRecord(
            fingerprint: encounter.fingerprint,
            mechanicID: encounter.mechanicID,
            skillID: encounter.skillID,
            representation: encounter.representation,
            timestamp: evidence.timestamp
        ))
        if outcome == .correct {
            profile.usedFingerprints.insert(encounter.fingerprint)
        }
        persist()
        return evidence
    }

    @discardableResult
    func recordPuzzle(
        _ encounter: PuzzleInhibitionEncounter,
        outcome: Outcome,
        support: SupportLevel,
        attempts: Int,
        responseTime: TimeInterval?
    ) -> LearningEvidence {
        let evidence = LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            attempts: attempts,
            responseTime: responseTime,
            timestamp: Date(),
            transferContext: encounter.transferContext,
            easySuccess: outcome == .correct && support == .independent && attempts == 1
        )
        MasteryEngine().record(evidence, in: &profile)
        profile.recordActivity(ActivityRecord(
            fingerprint: encounter.fingerprint,
            mechanicID: encounter.mechanicID,
            skillID: encounter.skillID,
            representation: encounter.representation,
            timestamp: evidence.timestamp
        ))
        if outcome == .correct {
            profile.usedFingerprints.insert(encounter.fingerprint)
        }
        persist()
        return evidence
    }

    @discardableResult
    func recordLiteracy(
        _ encounter: LiteracyEncounter,
        outcome: Outcome,
        support: SupportLevel,
        attempts: Int,
        responseTime: TimeInterval?
    ) -> LearningEvidence {
        let evidence = LearningEvidence(
            encounterID: encounter.id,
            skillID: encounter.skillID,
            outcome: outcome,
            supportLevel: support,
            representation: encounter.representation,
            mechanicID: encounter.mechanicID,
            attempts: attempts,
            responseTime: responseTime,
            timestamp: Date(),
            transferContext: encounter.transferContext,
            easySuccess: outcome == .correct && support == .independent && attempts == 1
        )
        MasteryEngine().record(evidence, in: &profile)
        profile.recordActivity(ActivityRecord(
            fingerprint: encounter.fingerprint,
            mechanicID: encounter.mechanicID,
            skillID: encounter.skillID,
            representation: encounter.representation,
            timestamp: evidence.timestamp
        ))
        if outcome == .correct {
            profile.usedFingerprints.insert(encounter.fingerprint)
        }
        if WordGardenDirector.storyHollowComplete(profile: profile) {
            _ = profile.unlockStoryReward(.wordGardenLantern)
        }
        persist()
        return evidence
    }
    func retrySave() { persist() }
    func persist() {
        do {
            try store.save(profile: profile, adventure: adventure,
                           sound: soundEnabled, reducedMotion: reducedMotion, world: world.rawValue)
            saveError = nil
        } catch { saveError = "Progress could not be saved. Keep the app open and retry in Settings." }
    }
}
