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
    private var nextGear: SKNode?
    private var lever: SKNode?
    private var powerLight: SKShapeNode?
    private var routeLights: [SKShapeNode] = []
    private var wasPowered = false
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
        _ = worldControl("‹", name: "home", at: CGPoint(x: 52, y: 669))
        // Native stonework connects the foreground landing to the workbench.
        let dais = SKShapeNode(ellipseOf: CGSize(width: 640, height: 115))
        dais.fillColor = .init(red: 0.4, green: 0.38, blue: 0.43, alpha: 0.88)
        dais.strokeColor = .init(red: 0.89, green: 0.68, blue: 0.35, alpha: 1); dais.lineWidth = 5
        dais.position = CGPoint(x: 830, y: 178); dais.zPosition = 5; addChild(dais)
        for index in 0..<6 {
            let stone = ArtSystem.box(CGSize(width: 85, height: 20), color: .init(red: 0.6, green: 0.57, blue: 0.57, alpha: 0.8), radius: 4)
            stone.position = CGPoint(x: 240 + index * 65, y: 150 + index * 6); stone.zPosition = 6; addChild(stone)
        }
        // The five workshop seals are mounted on one physical brass rack.
        let rack = ArtSystem.box(CGSize(width: 440, height: 14), color: .init(red: 0.55, green: 0.34, blue: 0.13, alpha: 1), radius: 3)
        rack.position = CGPoint(x: 330, y: 503); rack.zPosition = 30; addChild(rack)
        for x in [150, 510] {
            let post = ArtSystem.box(CGSize(width: 14, height: 142), color: .init(red: 0.55, green: 0.34, blue: 0.13, alpha: 1), radius: 3)
            post.position = CGPoint(x: x, y: 440); post.zPosition = 29; addChild(post)
        }
        for (index, symbol) in ["◆", "⚖", "◉", "▦", "↔"].enumerated() {
            _ = worldGear(symbol, name: "workshop\(index)", at: CGPoint(x: 150 + index * 90, y: 535), radius: 31)
        }
        _ = worldGear("↻", name: "wind", at: CGPoint(x: 390, y: 605), radius: 32)
        pip.name = "help"
        nextGear = worldGear("→", name: "next", at: CGPoint(x: 1110, y: 430), radius: 34)
        lever = makeLever()
        let light = SKShapeNode(circleOfRadius: 27)
        light.position = CGPoint(x: 1105, y: 352); light.zPosition = 40; light.lineWidth = 2
        light.fillColor = .init(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
        light.strokeColor = .init(red: 0.95, green: 0.71, blue: 0.32, alpha: 1)
        addChild(light); powerLight = light
        let portal = SKShapeNode(ellipseOf: CGSize(width: 115, height: 170))
        portal.position = CGPoint(x: 1125, y: 567); portal.zPosition = 25; portal.name = "lift"
        portal.fillColor = .init(red: 0.33, green: 0.73, blue: 1, alpha: 0.08)
        portal.strokeColor = .init(red: 0.56, green: 0.87, blue: 1, alpha: 0.2); portal.glowWidth = 8
        addChild(portal); gate = portal
        for index in 0..<5 {
            let lamp = SKShapeNode(circleOfRadius: 7)
            lamp.position = CGPoint(x: 1080 + index * 10, y: 390 + index * 28)
            lamp.zPosition = 25; lamp.fillColor = .init(red: 0.34, green: 0.31, blue: 0.37, alpha: 1)
            lamp.strokeColor = .init(red: 0.93, green: 0.66, blue: 0.25, alpha: 1); addChild(lamp); routeLights.append(lamp)
        }
        openOrder()
    }

    private func makeLever() -> SKNode {
        let node = SKNode(); node.name = "submit"; node.position = CGPoint(x: 1120, y: 250); node.zPosition = 760
        let base = ArtSystem.box(CGSize(width: 90, height: 32), color: .init(red: 0.47, green: 0.3, blue: 0.14, alpha: 1), radius: 6)
        base.position.y = -45; node.addChild(base)
        let arm = ArtSystem.box(CGSize(width: 14, height: 80), color: .init(red: 0.93, green: 0.74, blue: 0.35, alpha: 1), radius: 6)
        arm.zRotation = -.pi / 8; arm.position.y = -5; node.addChild(arm)
        let handle = SKShapeNode(circleOfRadius: 27)
        handle.position = CGPoint(x: 15, y: 32); handle.fillColor = .init(red: 0.38, green: 0.71, blue: 0.72, alpha: 1)
        handle.strokeColor = .init(red: 1, green: 0.82, blue: 0.44, alpha: 1); handle.lineWidth = 3; node.addChild(handle)
        // Touch area stays large even where the lever's silhouette is narrow.
        let hit = ArtSystem.box(CGSize(width: 150, height: 110), color: .clear, radius: 0); hit.name = "submit"; node.addChild(hit)
        addChild(node); return node
    }

    private func updatePower(_ powered: Bool) {
        nextGear?.isHidden = !(powered || state.workshop || state.runtime == nil)
        powerLight?.fillColor = powered ? .init(red: 1, green: 0.86, blue: 0.38, alpha: 1) : .init(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
        powerLight?.glowWidth = powered ? 16 : 0
        (gate as? SKShapeNode)?.strokeColor = .init(red: 0.65, green: 0.91, blue: 1, alpha: powered ? 0.85 : 0.2)
        (gate as? SKShapeNode)?.glowWidth = powered ? 18 : 8
        for lamp in routeLights { lamp.fillColor = powered ? .init(red: 1, green: 0.86, blue: 0.4, alpha: 1) : .init(red: 0.34, green: 0.31, blue: 0.37, alpha: 1); lamp.glowWidth = powered ? 6 : 0 }
        if powered && !wasPowered && !reducedMotion {
            lever?.run(.sequence([.rotate(toAngle: -0.18, duration: 0.16), .rotate(toAngle: 0, duration: 0.22)]), withKey: "pull")
        }
        wasPowered = powered
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
            updatePower(false); return
        }
        if renderedEncounterID != runtime.encounter.id || mechanic == nil {
            mechanic?.removeAllActions(); mechanic?.removeFromParent()
            if runtime.encounter.mechanicID == MathMechanicID.crystalCart {
                mechanic = CrystalCartMechanic()
            } else {
                mechanic = MathCastleMechanicFactory.makeNode(for: runtime.encounter)
                mechanic?.position = CGPoint(x: 820, y: 310)
            }
            if let mechanic { mechanic.zPosition = 815; addChild(mechanic) }
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
        updatePower(runtime.completed)
        if engaged {
            instruction.text = state.previewVisible ? "Watch the lights. Remember how many you see."
                : runtime.encounter.prompt
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
                self?.instruction.text = "The starlight lifts lead farther into the castle. More paths are still being built."
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
                instruction.text = "Tap the machine to walk over and try it."
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
            valkyrie.face(toward: CGPoint(x: 820, y: 310))
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
