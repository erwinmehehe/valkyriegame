import SpriteKit
import LearningCore

@MainActor final class MathCastleScene: AdventureScene {
    private let mechanic = CrystalCartMechanic()
    private let station = CGPoint(x: 490, y: 175)
    private var activeTouch: UITouch?
    private var dragOrigin: String?
    private var startPoint = CGPoint.zero
    private var ghost: SKShapeNode?
    private var didDrag = false
    private var engaged = false
    private var selection: EncounterSelection?
    private var gate: SKNode?
    override func buildWorld() {
        super.buildWorld()
        addChild(mechanic)
        _ = hotspot("Story Tree", name: "home", at: CGPoint(x: 140, y: 580), size: CGSize(width: 170, height: 68))
        _ = hotspot("Pip's lever", name: "submit", at: CGPoint(x: 1050, y: 250), size: CGSize(width: 150, height: 80))
        _ = hotspot("Ask Pip", name: "help", at: CGPoint(x: 400, y: 290))
        _ = hotspot("Wind gear", name: "wind", at: CGPoint(x: 395, y: 390))
        _ = hotspot("Next order", name: "next", at: CGPoint(x: 1060, y: 410), size: CGSize(width: 180, height: 68))
        for (index, title) in ["Count", "Add", "Find part"].enumerated() {
            _ = hotspot(title, name: "workshop\(index)", at: CGPoint(x: 540 + index * 180, y: 500), size: CGSize(width: 150, height: 64))
        }
        let workshop = ArtSystem.label("Pip's workshop · unscored examples", size: 18)
        workshop.position = CGPoint(x: 720, y: 550); workshop.zPosition = 950; addChild(workshop)
        gate = hotspot("Castle lift", name: "lift", at: CGPoint(x: 1120, y: 555), size: CGSize(width: 155, height: 110))
        openOrder()
    }
    private func openOrder() {
        engaged = false
        selection = state.prepareNext()
        refresh()
        switch selection {
        case .explorationBreak: instruction.text = "Let's explore! Wind Pip's gear or return to Story Tree."
        case .needsContent: instruction.text = "Pip has no new ready work orders. Explore, or play in his unscored workshop."
        default: instruction.text = "Tap the cart to walk over. Then tap it again to work."
        }
    }
    private func refresh() {
        if let cart = state.cart {
            mechanic.render(cart)
            if engaged {
                instruction.text = (state.workshop ? "Workshop · " : "") + cart.encounter.prompt
            }
        }
    }
    private func canManipulate() -> Bool {
        engaged && isNear(station) && state.cart?.completed == false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; startPoint = touch.location(in: self); didDrag = false
        let name = targetName(at: startPoint)
        if canManipulate(), name == "supply" || name == "cartCrystal" { dragOrigin = name }
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
        let origin = dragOrigin
        if hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 { didDrag = true }
        defer { clearDrag() }
        if didDrag {
            if canManipulate() {
                if origin == "supply", mechanic.receives(point) { state.addCrystal() }
                if origin == "cartCrystal", mechanic.returnsToSupply(point) { state.removeCrystal() }
                refresh(); state.audio.play("crystal")
            }
            return
        }
        switch targetName(at: point) {
        case "home": state.travel(to: .storyTree)
        case "cart", "fixedCrystal": engageCart()
        case "supply":
            if canManipulate() { state.addCrystal(); refresh(); valkyrie.pose(.interact); state.audio.play("crystal") }
            else { engageCart() }
        case "cartCrystal":
            if canManipulate() { state.removeCrystal(); refresh() } else { engageCart() }
        case "submit":
            guard canManipulate() else { engageCart(); return }
            if let evidence = state.submit() {
                pip.operate(reducedMotion: reducedMotion)
                if evidence.outcome == .correct {
                    valkyrie.pose(.celebrate); state.audio.play("success")
                    gate?.run(.fadeAlpha(to: 0.5, duration: reducedMotion ? 0 : 0.4))
                    instruction.text = "The lift has power! Explore, or choose another work order."
                } else {
                    valkyrie.pose(.react)
                    instruction.text = "The lift needs a different amount. Let's look together."
                    showScaffold()
                }
            }
        case "help":
            if canManipulate() { showScaffold() } else { engageCart() }
        case "wind":
            engaged = false
            travel(to: CGPoint(x: 380, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration(); self.state.audio.play("gear")
                self.instruction.text = "Pip's gears hum! Explore or choose a new work order."
            }
        case "next":
            guard state.cart == nil || state.cart?.completed == true || selection == .explorationBreak else {
                instruction.text = "Finish this work order, or explore with Pip first."; return
            }
            openOrder()
        case "workshop0": workshop(0)
        case "workshop1": workshop(1)
        case "workshop2": workshop(2)
        case "lift":
            travel(to: CGPoint(x: 1110, y: 230)) { [weak self] in
                self?.instruction.text = "The lift leads farther into the castle. That adventure is still being built."
            }
        default:
            engaged = false; walkIfValid(point)
        }
    }
    private func workshop(_ index: Int) {
        // Do not silently discard an active scored encounter.
        if let cart = state.cart, !cart.completed, !state.workshop {
            instruction.text = "Finish Pip's work order before opening his workshop."; return
        }
        state.startWorkshop(MathFoundation.workshopExamples[index])
        engaged = false; refresh(); instruction.text = "Unscored workshop. Walk to the cart to try this example."
    }
    private func engageCart() {
        guard state.cart != nil, state.cart?.completed == false else {
            instruction.text = "Choose a new order or a workshop example."; return
        }
        if isNear(station) {
            engaged = true; refresh()
            instruction.text = (state.workshop ? "Workshop · " : "") + (state.cart?.encounter.prompt ?? "") + " Tap or drag crystals."
        } else {
            engaged = false
            instruction.text = "Valkyrie is walking over. Tap the cart again when she arrives."
            travel(to: station)
        }
    }
    private func showScaffold() {
        if let scaffold = state.scaffold() {
            pip.operate(reducedMotion: reducedMotion); refresh()
            instruction.text = scaffold.cue
        }
    }
    private func clearDrag() {
        activeTouch = nil; dragOrigin = nil; ghost?.removeFromParent(); ghost = nil; didDrag = false
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) { clearDrag() }
    }
    override func willLeave() { clearDrag(); super.willLeave() }
}
