import Foundation
import SwiftUI
import SwiftData
import LearningCore

@MainActor final class AppState: ObservableObject {
    enum World: String { case storyTree, mathCastle, wordGarden, sunmillCrossing, storyHollow, scienceLab, scienceWeatherTower, scienceCreatureGrove, puzzlePalace, memoryBridge, stopGoOrbs, sortingPedestal, resortVault, mirrorHall, pathTiles, commandGears, bugLantern, bugLanternRepair }
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
            }
        }
    }

    func scienceNextFieldStudy(in world: ScienceFieldStudyWorld) -> ScienceFieldStudyChallenge? {
        ScienceFieldStudyCatalog.next(in: world, profile: profile)
    }

    func scienceFieldStudyCompletedCount(in world: ScienceFieldStudyWorld) -> Int {
        ScienceFieldStudyCatalog.completedCount(in: world, profile: profile)
    }

    @discardableResult
    func scienceAnswerFieldStudy(
        _ challenge: ScienceFieldStudyChallenge,
        targetName: String
    ) -> Bool {
        guard challenge.choiceTargets.contains(targetName),
              ScienceFieldStudyCatalog.next(in: challenge.world, profile: profile)?.id == challenge.id
        else {
            return false
        }

        let correct = targetName == challenge.answerTarget
        updateScience { science, profile in
            science.recordEvidence(
                skillID: challenge.skillID,
                mechanicID: challenge.mechanicID,
                outcome: correct ? .correct : .incorrect,
                representation: challenge.representation,
                encounterID: challenge.id,
                profile: &profile
            )

            guard correct,
                  ScienceFieldStudyCatalog.isComplete(challenge.world, in: profile)
            else {
                return
            }

            switch challenge.world {
            case .greenhouse:
                science.greenhouseComplete = true
            case .weatherTower:
                science.creatureRouteOpen = true
            case .creatureGrove:
                science.groveRestored = true
            }
        }
        return correct
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

    /// World interactions save independently of skill evidence or encounter state.
    var starlightBridgeQuest: StarlightBridgeQuest {
        profile.starlightBridgeQuest ?? StarlightBridgeQuest()
    }

    @discardableResult
    func discoverStarlightBridge() -> Bool {
        var quest = starlightBridgeQuest
        guard quest.discover() else { return false }
        profile.starlightBridgeQuest = quest
        persist()
        return true
    }

    @discardableResult
    func collectStarlightCrystal(_ index: Int) -> Bool {
        var quest = starlightBridgeQuest
        guard quest.collect(index) else { return false }
        profile.starlightBridgeQuest = quest
        persist()
        return true
    }

    @discardableResult
    func discoverHiddenStarlightStar() -> Bool {
        var quest = starlightBridgeQuest
        guard quest.discoverHiddenStar() else { return false }
        profile.starlightBridgeQuest = quest
        persist()
        return true
    }

    @discardableResult
    func installStarlightCrystal(_ index: Int, into socket: Int) -> Bool {
        var quest = starlightBridgeQuest
        guard quest.install(index, into: socket) else { return false }
        profile.starlightBridgeQuest = quest
        if quest.isComplete {
            _ = profile.unlockStoryReward(.starlightBridgeCharm)
        }
        persist()
        return true
    }

    /// Bridge experiments are intentionally unscored. Persist only their
    /// physical arrangement and visible discovery/reward.
    @discardableResult
    func toggleStarlightBridgeBrace(_ span: Int) -> Bool {
        var quest = starlightBridgeQuest
        guard quest.toggleBrace(at: span) else { return false }
        profile.starlightBridgeQuest = quest
        persist()
        return true
    }

    func testStarlightBridge(with load: BridgeTestLoad) -> BridgeTestResult? {
        var quest = starlightBridgeQuest
        guard let result = quest.testBridge(with: load) else { return nil }
        profile.starlightBridgeQuest = quest
        persist()
        return result
    }

    /// A free-form gardening activity, not a literacy encounter. Weather
    /// experiments never create evidence or modify any skill state.
    var lumiLivingGarden: LumiLivingGarden {
        profile.lumiLivingGarden ?? LumiLivingGarden()
    }

    @discardableResult
    func plantLumiSeed(_ seed: LumiSeed, at plot: Int) -> Bool {
        var garden = lumiLivingGarden
        guard garden.plant(seed, at: plot) else { return false }
        profile.lumiLivingGarden = garden
        persist()
        return true
    }

    @discardableResult
    func tendLumiGarden(_ care: LumiGardenCare, at plot: Int) -> Bool {
        var garden = lumiLivingGarden
        guard garden.tend(care, at: plot) else { return false }
        profile.lumiLivingGarden = garden
        if garden.bloomingCount > 0 {
            _ = profile.unlockStoryReward(.lumiLivingBloom)
        }
        persist()
        return true
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
    func adjustPlaceValue(tensDelta: Int = 0, onesDelta: Int = 0) {
        beginInteraction()
        _ = adventure.adjustPlaceValue(tensDelta: tensDelta, onesDelta: onesDelta)
        persist()
    }
    func choosePatternSymbol(_ symbol: Int) {
        beginInteraction()
        if adventure.choosePatternSymbol(symbol) { persist() }
    }
    func undoPatternSymbol() {
        beginInteraction()
        if adventure.undoPatternSymbol() { persist() }
    }
    func chooseShapeOption(_ option: Int) {
        beginInteraction()
        if adventure.chooseShapeOption(option) { persist() }
    }
    func rotateShape(_ delta: Int) {
        beginInteraction()
        if adventure.rotateShape(delta) { persist() }
    }
    func placeShapeHalf(_ quarterTurns: Int) {
        beginInteraction()
        if adventure.placeShapeHalf(quarterTurns) { persist() }
    }
    func undoShapeHalf() {
        beginInteraction()
        if adventure.undoShapeHalf() { persist() }
    }
    func cycleMirrorCell(_ row: Int) {
        beginInteraction()
        if adventure.cycleMirrorCell(row) { persist() }
    }
    func placeMeasureUnit() {
        beginInteraction()
        if adventure.placeMeasureUnit() { persist() }
    }
    func removeMeasureUnit() {
        beginInteraction()
        if adventure.removeMeasureUnit() { persist() }
    }
    func sortDataObject(into bin: Int) {
        beginInteraction()
        if adventure.sortDataObject(into: bin) { persist() }
    }
    func undoDataSort() {
        beginInteraction()
        if adventure.undoDataSort() { persist() }
    }
    func addPicture(to column: Int) {
        beginInteraction()
        if adventure.addPicture(to: column) { persist() }
    }
    func undoPicture() {
        beginInteraction()
        if adventure.undoPicture() { persist() }
    }
    func adjustClockHour(_ delta: Int) {
        beginInteraction()
        if adventure.adjustClockHour(delta) { persist() }
    }
    func adjustClockMinute(_ delta: Int) {
        beginInteraction()
        if adventure.adjustClockMinute(delta) { persist() }
    }
    func placeDailyRoutine(_ daypart: ClockMarketDaypart) {
        beginInteraction()
        if adventure.placeDailyRoutine(daypart) { persist() }
    }
    func undoDailyRoutine() {
        beginInteraction()
        if adventure.undoDailyRoutine() { persist() }
    }
    func addPesoCoin(_ pesos: Int) {
        beginInteraction()
        if adventure.addPesoCoin(pesos) { persist() }
    }
    func undoPesoCoin() {
        beginInteraction()
        if adventure.undoPesoCoin() { persist() }
    }
    func placeGardenSeed(in basket: Int) {
        beginInteraction()
        if adventure.placeGardenSeed(in: basket) { persist() }
    }
    func undoGardenSeed() {
        beginInteraction()
        if adventure.undoGardenSeed() { persist() }
    }
    func addGardenJump() {
        beginInteraction()
        if adventure.addGardenJump() { persist() }
    }
    func undoGardenJump() {
        beginInteraction()
        if adventure.undoGardenJump() { persist() }
    }
    func moveGardenCut(_ delta: Int) {
        beginInteraction()
        if adventure.moveGardenCut(delta) { persist() }
    }
    func placeGardenCut() {
        beginInteraction()
        if adventure.placeGardenCut() { persist() }
    }
    func undoGardenCut() {
        beginInteraction()
        if adventure.undoGardenCut() { persist() }
    }
    func chooseReasoningStrategy(_ choice: ReasoningStudioStrategy) {
        beginInteraction()
        if adventure.chooseReasoningStrategy(choice) { persist() }
    }
    func addReasoningStep() {
        beginInteraction()
        if adventure.addReasoningStep() { persist() }
    }
    func undoReasoningStep() {
        beginInteraction()
        if adventure.undoReasoningStep() { persist() }
    }
    func adjustReasoningPair(left: Bool, delta: Int) {
        beginInteraction()
        if adventure.adjustReasoningPair(left: left, delta: delta) { persist() }
    }
    func saveReasoningPair() {
        beginInteraction()
        if adventure.saveReasoningPair() { persist() }
    }
    func undoReasoningPair() {
        beginInteraction()
        if adventure.undoReasoningPair() { persist() }
    }
    func moveReasoningCounter(_ delta: Int) {
        beginInteraction()
        if adventure.moveReasoningCounter(delta) { persist() }
    }
    func confirmReasoningStage() {
        beginInteraction()
        if adventure.confirmReasoningStage() { persist() }
    }
    func resetReasoningStages() {
        beginInteraction()
        if adventure.resetReasoningStages() { persist() }
    }
    func revealTrailCollection() {
        beginInteraction()
        if adventure.revealTrailCollection() { persist() }
    }
    func adjustTrailEstimate(_ delta: Int) {
        beginInteraction()
        if adventure.adjustTrailEstimate(delta) { persist() }
    }
    func lockTrailEstimate() {
        beginInteraction()
        if adventure.lockTrailEstimate() { persist() }
    }
    func addTrailJump() {
        beginInteraction()
        if adventure.addTrailJump() { persist() }
    }
    func undoTrailJump() {
        beginInteraction()
        if adventure.undoTrailJump() { persist() }
    }

    func matchDifferencePair() {
        beginInteraction()
        if adventure.matchDifferencePair() { persist() }
    }
    func undoDifferencePair() {
        beginInteraction()
        if adventure.undoDifferencePair() { persist() }
    }
    func collectDifference() {
        beginInteraction()
        if adventure.collectDifference() { persist() }
    }
    func undoDifferenceCollection() {
        beginInteraction()
        if adventure.undoDifferenceCollection() { persist() }
    }
    func addInverseCounter() {
        beginInteraction()
        if adventure.addInverseCounter() { persist() }
    }
    func undoInverseCounter() {
        beginInteraction()
        if adventure.undoInverseCounter() { persist() }
    }
    func reverseInverseCounter() {
        beginInteraction()
        if adventure.reverseInverseCounter() { persist() }
    }
    func undoInverseReverse() {
        beginInteraction()
        if adventure.undoInverseReverse() { persist() }
    }
    func moveOnMap(_ direction: MapMove) {
        beginInteraction()
        if adventure.moveOnMap(direction) { persist() }
    }
    func undoMapMove() {
        beginInteraction()
        if adventure.undoMapMove() { persist() }
    }
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

    var puzzleSortingAvailable: Bool {
        PuzzlePalaceDirector.canEnterSortingPedestal(profile: profile)
    }

    var puzzleSortingFoundationComplete: Bool {
        PuzzlePalaceDirector.sortingFoundationComplete(profile: profile)
    }

    var puzzleRuleSwitchingComplete: Bool {
        PuzzlePalaceDirector.ruleSwitchingComplete(profile: profile)
    }

    var puzzleSortingPedestalComplete: Bool {
        PuzzlePalaceDirector.sortingPedestalComplete(profile: profile)
    }

    var puzzleResortAvailable: Bool {
        PuzzlePalaceDirector.canEnterChangedRuleResort(profile: profile)
    }

    var puzzleResortComplete: Bool {
        PuzzlePalaceDirector.changedRuleResortComplete(profile: profile)
    }

    var puzzleMirrorHallAvailable: Bool {
        PuzzlePalaceDirector.canEnterMirrorHall(profile: profile)
    }

    var puzzleMirrorHallComplete: Bool {
        PuzzlePalaceDirector.mirrorHallComplete(profile: profile)
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

    func nextPuzzleSortingEncounter() -> PuzzleSortEncounter? {
        if puzzleSortingFoundationComplete {
            return PuzzlePalaceDirector.nextRuleSwitchingEncounter(profile: profile)
        }
        return PuzzlePalaceDirector.nextSortingFoundationEncounter(profile: profile)
    }

    func nextPuzzleResortEncounter() -> PuzzleResortEncounter? {
        PuzzlePalaceDirector.nextChangedRuleResortEncounter(profile: profile)
    }

    var puzzleMirrorRotationComplete: Bool {
        PuzzlePalaceDirector.mirrorRotationComplete(profile: profile)
    }

    func nextPuzzleMirrorRotationEncounter() -> PuzzleRotationEncounter? {
        PuzzlePalaceDirector.nextMirrorRotationEncounter(profile: profile)
    }

    func nextPuzzleMirrorHallEncounter() -> PuzzleOrientationEncounter? {
        PuzzlePalaceDirector.nextMirrorHallEncounter(profile: profile)
    }

    var puzzlePathTilesAvailable: Bool {
        PuzzlePalaceDirector.canEnterPathTiles(profile: profile)
    }

    var puzzlePathTilesComplete: Bool {
        PuzzlePalaceDirector.pathTilesComplete(profile: profile)
    }

    func nextPuzzlePathTilesEncounter() -> PuzzlePathEncounter? {
        PuzzlePalaceDirector.nextPathTilesEncounter(profile: profile)
    }

    var puzzleCommandGearsAvailable: Bool {
        PuzzlePalaceDirector.canEnterCommandGears(profile: profile)
    }

    var puzzleCommandGearsComplete: Bool {
        PuzzlePalaceDirector.commandGearsComplete(profile: profile)
    }

    var puzzlePalaceComplete: Bool {
        PuzzlePalaceDirector.palaceRestorationComplete(profile: profile)
    }

    func nextPuzzleCommandGearsEncounter() -> PuzzleSequenceEncounter? {
        PuzzlePalaceDirector.nextCommandGearsEncounter(profile: profile)
    }

    var puzzleBugLanternAvailable: Bool {
        PuzzlePalaceDirector.canEnterBugLantern(profile: profile)
    }

    var puzzleBugLanternComplete: Bool {
        PuzzlePalaceDirector.bugLanternComplete(profile: profile)
    }

    func nextPuzzleBugLanternEncounter() -> PuzzleBugEncounter? {
        PuzzlePalaceDirector.nextBugLanternEncounter(profile: profile)
    }

    var puzzleBugRepairAvailable: Bool {
        PuzzlePalaceDirector.canEnterBugRepair(profile: profile)
    }

    var puzzleBugRepairComplete: Bool {
        PuzzlePalaceDirector.bugRepairComplete(profile: profile)
    }

    func nextPuzzleBugRepairEncounter() -> PuzzleRepairEncounter? {
        PuzzlePalaceDirector.nextBugRepairEncounter(profile: profile)
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
    func recordPuzzle(
        _ encounter: PuzzleSortEncounter,
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
        _ encounter: PuzzleResortEncounter,
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
        _ encounter: PuzzleOrientationEncounter,
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
        _ encounter: PuzzleRotationEncounter,
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
        _ encounter: PuzzlePathEncounter,
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
        _ encounter: PuzzleSequenceEncounter,
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
        _ encounter: PuzzleBugEncounter,
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
        _ encounter: PuzzleRepairEncounter,
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
        if PuzzlePalaceDirector.palaceRestorationComplete(profile: profile) {
            _ = profile.unlockStoryReward(.puzzlePalaceLantern)
        }
        do {
            try store.save(profile: profile, adventure: adventure,
                           sound: soundEnabled, reducedMotion: reducedMotion, world: world.rawValue)
            saveError = nil
        } catch { saveError = "Progress could not be saved. Keep the app open and retry in Settings." }
    }
}
