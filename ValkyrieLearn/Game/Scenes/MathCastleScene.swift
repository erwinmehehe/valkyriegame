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
    private var challengeRunes: [SKShapeNode] = []
    private var wasPowered = false
    private let questionPlate = SKShapeNode(
        rectOf: CGSize(width: 650, height: 76),
        cornerRadius: 24
    )
    private let questionLabel = ArtSystem.label("", size: 23)
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
        // A source-textured courtyard supports the live actors and machinery.
        if let floor = ArtSystem.sprite("CastleCourtyard", size: CGSize(width: 1280, height: 250)) {
            floor.position = CGPoint(x: 640, y: 125)
            floor.zPosition = -80
            addChild(floor)
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

        questionPlate.position = CGPoint(x: 790, y: 607)
        questionPlate.fillColor = UIColor(red: 0.12, green: 0.08, blue: 0.20, alpha: 0.78)
        questionPlate.strokeColor = UIColor(red: 1.0, green: 0.76, blue: 0.28, alpha: 0.95)
        questionPlate.lineWidth = 3
        questionPlate.zPosition = 1995
        questionPlate.name = "questionPromptPlate"
        questionPlate.isHidden = true
        addChild(questionPlate)

        questionLabel.position = CGPoint(x: 790, y: 607)
        questionLabel.preferredMaxLayoutWidth = 590
        questionLabel.numberOfLines = 2
        questionLabel.fontColor = UIColor(red: 1.0, green: 0.97, blue: 0.86, alpha: 1)
        questionLabel.zPosition = 2000
        questionLabel.name = "questionPrompt"
        questionLabel.isHidden = true
        addChild(questionLabel)

        pip.name = "help"
        nextGear = worldGear("→", name: "next", at: CGPoint(x: 1110, y: 430), radius: 34)
        lever = makeLever()
        let light = SKShapeNode(circleOfRadius: 27)
        light.position = CGPoint(x: 1105, y: 352); light.zPosition = 40; light.lineWidth = 2
        light.name = "castlePowerLight"
        light.fillColor = .init(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
        light.strokeColor = .init(red: 0.95, green: 0.71, blue: 0.32, alpha: 1)
        addChild(light); powerLight = light
        let portal = SKShapeNode(ellipseOf: CGSize(width: 115, height: 170))
        portal.position = CGPoint(x: 1125, y: 567); portal.zPosition = 25; portal.name = "challengeGate"
        portal.fillColor = .init(red: 0.33, green: 0.73, blue: 1, alpha: 0.08)
        portal.strokeColor = .init(red: 0.56, green: 0.87, blue: 1, alpha: 0.2); portal.glowWidth = 8
        addChild(portal); gate = portal

        for index in 0..<ChallengeGateCatalog.challengeCount {
            let rune = SKShapeNode(circleOfRadius: 10)
            rune.position = CGPoint(x: 1090 + CGFloat(index) * 35, y: 505)
            rune.zPosition = 40
            rune.fillColor = .darkGray
            rune.strokeColor = UIColor(red: 1, green: 0.78, blue: 0.35, alpha: 0.9)
            rune.lineWidth = 2
            rune.name = "challengeGate"
            addChild(rune)
            challengeRunes.append(rune)
        }

        for index in 0..<5 {
            let lamp = SKShapeNode(circleOfRadius: 7)
            lamp.position = CGPoint(x: 1080 + index * 10, y: 390 + index * 28)
            lamp.zPosition = 25; lamp.name = "powerRouteLamp\(index)"; lamp.fillColor = .init(red: 0.34, green: 0.31, blue: 0.37, alpha: 1)
            lamp.strokeColor = .init(red: 0.93, green: 0.66, blue: 0.25, alpha: 1); addChild(lamp); routeLights.append(lamp)
        }
        updateChallengeGateAppearance()
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

    private func updateChallengeGateAppearance() {
        let litCount: Int
        switch state.challengeGateStatus {
        case .locked:
            gate?.alpha = 0.45
            (gate as? SKShapeNode)?.strokeColor = .init(red: 0.56, green: 0.87, blue: 1, alpha: 0.18)
            (gate as? SKShapeNode)?.glowWidth = 4
            litCount = 0
        case .ready:
            gate?.alpha = 0.95
            (gate as? SKShapeNode)?.strokeColor = .init(red: 1, green: 0.82, blue: 0.40, alpha: 0.90)
            (gate as? SKShapeNode)?.glowWidth = 14
            litCount = 0
        case .active:
            gate?.alpha = 1.0
            (gate as? SKShapeNode)?.strokeColor = .init(red: 0.65, green: 0.91, blue: 1, alpha: 0.95)
            (gate as? SKShapeNode)?.glowWidth = 18
            litCount = state.challengeGateCompletedCount
        case .completed:
            gate?.alpha = 1.0
            (gate as? SKShapeNode)?.strokeColor = .init(red: 1, green: 0.86, blue: 0.38, alpha: 1)
            (gate as? SKShapeNode)?.glowWidth = 16
            litCount = ChallengeGateCatalog.challengeCount
        }

        for (index, rune) in challengeRunes.enumerated() {
            let lit = index < litCount
            rune.fillColor = lit ? .systemYellow : .darkGray
            rune.glowWidth = lit ? 7 : 0
            rune.setScale(lit ? 1.12 : 1.0)
        }
    }

    private func updatePower(_ powered: Bool) {
        nextGear?.isHidden = !(powered || state.workshop || state.runtime == nil)
        powerLight?.fillColor = powered ? .init(red: 1, green: 0.86, blue: 0.38, alpha: 1) : .init(red: 0.21, green: 0.18, blue: 0.32, alpha: 1)
        powerLight?.glowWidth = powered ? 16 : 0
        for lamp in routeLights { lamp.fillColor = powered ? .init(red: 1, green: 0.86, blue: 0.4, alpha: 1) : .init(red: 0.34, green: 0.31, blue: 0.37, alpha: 1); lamp.glowWidth = powered ? 6 : 0 }
        if powered && !wasPowered && !reducedMotion {
            lever?.run(.sequence([.rotate(toAngle: -0.18, duration: 0.16), .rotate(toAngle: 0, duration: 0.22)]), withKey: "pull")
        }
        wasPowered = powered
        updateChallengeGateAppearance()
    }

    private func showQuestion(_ text: String?) {
        guard let text, !text.isEmpty else {
            questionPlate.isHidden = true
            questionLabel.isHidden = true
            questionLabel.text = nil
            return
        }
        questionLabel.text = "Pip asks: " + text
        questionPlate.isHidden = false
        questionLabel.isHidden = false
    }

    private func openOrder() {
        clearDrag(); engaged = false
        showQuestion(nil)
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
            : "The castle route has power! Explore, or choose another work order."
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
            showQuestion(
                state.previewVisible
                    ? "Watch the lights. Remember how many you see."
                    : runtime.encounter.prompt
            )
            instruction.text = state.previewVisible
                ? "Look closely. Pip will hide the lights in a moment."
                : (runtime.encounter.mechanicID == MathMechanicID.missingNumberBridge
                    ? "Move spare planks into the gaps. Tap a loose plank to take it back. Pull Pip's lever to check."
                    : "Use the machine, then pull Pip's lever to check your idea.")
        } else {
            showQuestion(nil)
        }
    }

    private func canManipulate() -> Bool {
        engaged && isNear(station) && state.runtime?.completed == false && !state.previewVisible
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; startPoint = touch.location(in: self); didDrag = false
        if canManipulate(), let name = targetName(at: startPoint),
           ["supply", "cartCrystal", "bondSupply", "bondToken", "tenFrameSupply", "tenFrameFilled", "missingSupply", "missingPlank"].contains(name) {
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
            ghost = dragOrigin == "missingSupply" || dragOrigin == "missingPlank"
                ? MissingNumberBridgeMechanic.plank() : CrystalCartMechanic.crystal()
            ghost?.zPosition = 1900
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
        case "supply", "bondSupply", "bondSelected", "tenFrameSupply", "tenFrameCell", "missingPlus", "missingSupply", "missingSlot":
            manipulate { self.state.addCrystal() }
        case "cartCrystal", "bondToken", "tenFrameFilled", "missingMinus", "missingPlank":
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
        case "challengeGate":
            openChallengeGate()
        case "cart", "fixedCrystal", "bondMachine", "bondKnown", "bondFixed", "tenFrameFixed", "tenFramePreview", "missingBridge", "missingAnswer", "missingFixed", "scaleBeam",
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

    func drop(origin: String, at point: CGPoint) {
        guard canManipulate() else { return }
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
        case "missingSupply":
            if let bridge = mechanic as? MissingNumberBridgeMechanic, bridge.receives(local) { state.addCrystal(); changed = true }
        case "missingPlank":
            if let bridge = mechanic as? MissingNumberBridgeMechanic, bridge.returnsToSupply(local) { state.removeCrystal(); changed = true }
        default: break
        }
        if changed { refresh(); valkyrie.pose(.interact); state.audio.play("crystal") }
    }

    private func submit() {
        guard canManipulate() else { engageMachine(); return }
        let wasChallengeGate = state.challengeGateStatus == .active
        guard let evidence = state.submit() else {
            instruction.text = "Touch a scale pan, or the equal gear, before pulling Pip's lever."; return
        }
        refresh(); pip.operate(reducedMotion: reducedMotion)
        updateChallengeGateAppearance()
        if evidence.outcome == .correct {
            valkyrie.pose(.celebrate); state.audio.play("success")
            showQuestion(nil)
            if wasChallengeGate && state.challengeGateStatus == .completed {
                instruction.text = "The final rune shines! Your Moon Lantern is waiting at Story Tree."
            } else if wasChallengeGate {
                instruction.text = "A Challenge Gate rune lights up. Follow the arrow for the next challenge."
            } else {
                instruction.text = completionMessage
            }
        } else {
            valkyrie.pose(.react); showScaffold()
        }
    }

    private func openChallengeGate() {
        switch state.challengeGateStatus {
        case .locked:
            instruction.text = "The Challenge Gate is still gathering starlight. Keep helping Pip with ready skills."

        case .ready:
            if let runtime = state.runtime, !runtime.completed {
                instruction.text = "Finish this work order before entering the Challenge Gate."
                return
            }
            if state.beginChallengeGate() {
                engaged = false
                renderedEncounterID = nil
                updateChallengeGateAppearance()
                openOrder()
            } else {
                instruction.text = "The Challenge Gate needs a little more readiness before it opens."
            }

        case .active:
            if state.runtime == nil || state.runtime?.completed == true {
                _ = state.advanceEncounter()
                openOrder()
            } else {
                instruction.text = "The Challenge Gate is already open. Finish the glowing machine."
                engageMachine()
            }

        case .completed:
            instruction.text = "The Challenge Gate is restored. Your Moon Lantern is waiting at Story Tree."
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
            pip.face(toward: CGPoint(x: 820, y: 310))
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
