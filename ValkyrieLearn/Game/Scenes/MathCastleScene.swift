import SpriteKit
import LearningCore

@MainActor final class MathCastleScene: AdventureScene {
    private var mechanic: SKNode?
    private var renderedEncounterID: String?
    private let station = CGPoint(x: 490, y: 175)
    private var activeTouch: UITouch?
    private var dragOrigin: String?
    private var startPoint = CGPoint.zero
    private var ghost: SKShapeNode?
    private var didDrag = false
    private var engaged = false
    private var lastPreviewVisible = false
    private var selection: EncounterSelection?
    private var gate: SKNode?
    private let workshopGroups: [[LearningEncounter]] = [
        MathFoundation.workshopExamples,
        MathCastleEncounterCatalog.balanceScale,
        MathCastleEncounterCatalog.numberBondMachine,
        MathCastleEncounterCatalog.tenFrameGate,
        MathCastleEncounterCatalog.missingNumberBridge
    ]
    private var workshopIndices = [0, 0, 0, 0, 0]

    override func buildWorld() {
        super.buildWorld()
        _ = hotspot("Story Tree", name: "home", at: CGPoint(x: 140, y: 580), size: CGSize(width: 170, height: 68))
        _ = hotspot("Pip's lever", name: "submit", at: CGPoint(x: 1120, y: 250), size: CGSize(width: 150, height: 80))
        _ = hotspot("Ask Pip", name: "help", at: CGPoint(x: 395, y: 290))
        _ = hotspot("Wind gear", name: "wind", at: CGPoint(x: 395, y: 390))
        _ = hotspot("Next order", name: "next", at: CGPoint(x: 1100, y: 430), size: CGSize(width: 170, height: 64))
        for (index, title) in ["Cart", "Scale", "Bonds", "Lights", "Bridge"].enumerated() {
            _ = hotspot(title, name: "workshop\(index)", at: CGPoint(x: 450 + index * 155, y: 510), size: CGSize(width: 140, height: 64))
        }
        let workshop = ArtSystem.label("Pip's workshop · unscored examples", size: 18)
        workshop.position = CGPoint(x: 740, y: 560); workshop.zPosition = 950; addChild(workshop)
        gate = hotspot("Castle lift", name: "lift", at: CGPoint(x: 1130, y: 590), size: CGSize(width: 155, height: 80))
        openOrder()
    }

    private func openOrder() {
        clearDrag(); engaged = false
        selection = state.prepareNext()
        refresh()
        if state.runtime?.completed == true {
            instruction.text = completionMessage
        } else {
            switch selection {
            case .explorationBreak: instruction.text = "Let's explore! Wind Pip's gear or return to Story Tree."
            case .needsContent: instruction.text = "Pip has no new ready work orders. Explore, or try his workshop."
            default: instruction.text = "Tap the machine to walk over. Tap again when Valkyrie arrives."
            }
        }
    }

    private var completionMessage: String {
        state.workshop ? "You made it work! Try another station, or choose a new order."
            : "The lift has power! Explore, or choose another work order."
    }

    private func refresh() {
        guard let runtime = state.runtime else {
            mechanic?.removeFromParent(); mechanic = nil; renderedEncounterID = nil
            return
        }
        if renderedEncounterID != runtime.encounter.id || mechanic == nil {
            mechanic?.removeAllActions(); mechanic?.removeFromParent()
            if runtime.encounter.mechanicID == MathMechanicID.crystalCart {
                mechanic = CrystalCartMechanic()
            } else {
                mechanic = MathCastleMechanicFactory.makeNode(for: runtime.encounter)
                mechanic?.position = CGPoint(x: 820, y: 310)
            }
            if let mechanic { addChild(mechanic) }
            renderedEncounterID = runtime.encounter.id
        }
        switch runtime {
        case .crystalCart(let model): (mechanic as? CrystalCartMechanic)?.render(model)
        case .balanceScale(let model): (mechanic as? BalanceScaleMechanic)?.render(model)
        case .numberBond(let model): (mechanic as? NumberBondMachineMechanic)?.render(model)
        case .tenFrame(let model): (mechanic as? TenFrameGateMechanic)?.render(model, allowPreview: engaged && state.previewVisible)
        case .missingBridge(let model): (mechanic as? MissingNumberBridgeMechanic)?.render(model)
        }
        lastPreviewVisible = state.previewVisible
        gate?.alpha = runtime.completed ? 0.5 : 1
        if engaged {
            instruction.text = state.previewVisible ? "Watch the lights. Remember how many you see."
                : (state.workshop ? "Workshop · " : "") + runtime.encounter.prompt
        }
    }

    private func canManipulate() -> Bool {
        engaged && isNear(station) && state.runtime?.completed == false && !state.previewVisible
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; startPoint = touch.location(in: self); didDrag = false
        if canManipulate(), let name = targetName(at: startPoint),
           ["supply", "cartCrystal", "bondSupply", "bondToken", "tenFrameSupply", "tenFrameFilled"].contains(name) {
            dragOrigin = name
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        guard hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 else { return }
        didDrag = true
        guard dragOrigin != nil else { return }
        if ghost == nil {
            ghost = CrystalCartMechanic.crystal(); ghost?.zPosition = 1900
            if let ghost { addChild(ghost) }
        }
        ghost?.position = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 { didDrag = true }
        defer { clearDrag() }
        if didDrag {
            if canManipulate(), let origin = dragOrigin { drop(origin: origin, at: point) }
            return
        }
        handleTap(at: point)
    }

    // Shared by native touches and hosted interaction tests.
    func handleTap(at point: CGPoint) {
        let target = targetName(at: point)
        switch target {
        case "home": state.travel(to: .storyTree)
        case "supply", "bondSupply", "bondSelected", "tenFrameSupply", "tenFrameCell", "missingPlus":
            manipulate { self.state.addCrystal() }
        case "cartCrystal", "bondToken", "tenFrameFilled", "missingMinus":
            manipulate { self.state.removeCrystal() }
        case "scaleLeft": manipulate { self.state.chooseComparison(.left) }
        case "scaleRight": manipulate { self.state.chooseComparison(.right) }
        case "scaleEqual": manipulate { self.state.chooseComparison(.equal) }
        case "submit": submit()
        case "help":
            if canManipulate() { showScaffold() } else { engageMachine() }
        case "wind":
            engaged = false
            travel(to: CGPoint(x: 380, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration(); self.state.audio.play("gear")
                self.instruction.text = "Pip's gears hum! Explore or choose a new work order."
            }
        case "next":
            guard state.runtime == nil || state.runtime?.completed == true || state.workshop else {
                instruction.text = "Finish Pip's work order first. You can explore and come back."
                return
            }
            state.advanceEncounter(); openOrder()
        case "workshop0": workshop(0)
        case "workshop1": workshop(1)
        case "workshop2": workshop(2)
        case "workshop3": workshop(3)
        case "workshop4": workshop(4)
        case "lift":
            engaged = false
            travel(to: CGPoint(x: 1110, y: 230)) { [weak self] in
                self?.instruction.text = "The lift leads farther into the castle. That adventure is still being built."
            }
        case "cart", "fixedCrystal", "bondMachine", "bondKnown", "bondFixed", "tenFrameFixed", "tenFramePreview", "missingBridge", "missingAnswer", "scaleBeam",
             MathMechanicID.balanceScale, MathMechanicID.numberBondMachine, MathMechanicID.tenFrameGate, MathMechanicID.missingNumberBridge:
            engageMachine()
        default:
            if walkable.contains(point) { engaged = false; walkIfValid(point) }
        }
    }

    private func manipulate(_ action: () -> Void) {
        guard canManipulate() else { engageMachine(); return }
        action(); refresh(); valkyrie.pose(.interact); state.audio.play("crystal")
    }

    private func drop(origin: String, at point: CGPoint) {
        guard let mechanic else { return }
        let local = mechanic.convert(point, from: self)
        var changed = false
        switch origin {
        case "supply":
            if let cart = mechanic as? CrystalCartMechanic, cart.receives(local) { state.addCrystal(); changed = true }
        case "cartCrystal":
            if let cart = mechanic as? CrystalCartMechanic, cart.returnsToSupply(local) { state.removeCrystal(); changed = true }
        case "bondSupply":
            if CGRect(x: 30, y: -88, width: 150, height: 116).contains(local) { state.addCrystal(); changed = true }
        case "bondToken":
            if CGRect(x: -315, y: -80, width: 100, height: 100).contains(local) { state.removeCrystal(); changed = true }
        case "tenFrameSupply":
            if CGRect(x: -160, y: -62, width: 320, height: 128).contains(local) { state.addCrystal(); changed = true }
        case "tenFrameFilled":
            if CGRect(x: -320, y: -50, width: 100, height: 100).contains(local) { state.removeCrystal(); changed = true }
        default: break
        }
        if changed { refresh(); valkyrie.pose(.interact); state.audio.play("crystal") }
    }

    private func submit() {
        guard canManipulate() else { engageMachine(); return }
        guard let evidence = state.submit() else {
            instruction.text = "Touch a scale pan, or the equal gear, before pulling Pip's lever."; return
        }
        refresh(); pip.operate(reducedMotion: reducedMotion)
        if evidence.outcome == .correct {
            valkyrie.pose(.celebrate); state.audio.play("success")
            instruction.text = completionMessage
        } else {
            valkyrie.pose(.react); showScaffold()
        }
    }

    private func workshop(_ index: Int) {
        if let runtime = state.runtime, !runtime.completed, !state.workshop {
            instruction.text = "Finish Pip's work order before opening his workshop."; return
        }
        let examples = workshopGroups[index]
        // Try the next unused authored example; the learning layer owns repetition policy.
        for offset in 0..<examples.count {
            let next = (workshopIndices[index] + offset) % examples.count
            if state.startWorkshop(examples[next]) {
                workshopIndices[index] = (next + 1) % examples.count
                clearDrag(); engaged = false; renderedEncounterID = nil; refresh()
                instruction.text = "Unscored workshop. Tap the machine to walk over and try it."
                return
            }
        }
        instruction.text = "Pip has no fresh example here. Try another station or wind his gear."
    }

    private func engageMachine() {
        guard state.runtime != nil, state.runtime?.completed == false else {
            instruction.text = "Choose a new order or a workshop station."; return
        }
        if isNear(station) {
            state.beginInteraction()
            engaged = true; refresh()
        } else {
            engaged = false
            instruction.text = "Valkyrie is walking over. Tap the machine again when she arrives."
            travel(to: station)
        }
    }

    private func showScaffold() {
        if let scaffold = state.scaffold() {
            pip.operate(reducedMotion: reducedMotion); refresh(); instruction.text = scaffold.cue
        }
    }

    private func clearDrag() {
        activeTouch = nil; dragOrigin = nil; ghost?.removeFromParent(); ghost = nil; didDrag = false
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) { clearDrag() }
    }
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        if engaged, lastPreviewVisible != state.previewVisible { refresh() }
    }
    override func willLeave() { clearDrag(); super.willLeave() }
}
