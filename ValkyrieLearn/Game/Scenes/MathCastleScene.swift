import SpriteKit
import LearningCore

@MainActor final class MathCastleScene: AdventureScene {
    override var sourceBackdrop: ArtSystem.Backdrop? {
        ArtSystem.Backdrop(resource: "V331_MathCastle", ext: "jpg")
    }

    private var activeMechanicNode: SKNode?
    private var activeTouch: UITouch?
    private var dragOrigin: String?
    private var startPoint = CGPoint.zero
    private var ghost: SKNode?
    private var didDrag = false
    private var engaged = false
    private var selection: EncounterSelection?
    private var gate: SKNode?
    private var gateRunes: [SKShapeNode] = []

    override func buildWorld() {
        super.buildWorld()

        _ = hotspot(
            "Story Tree",
            name: "home",
            at: CGPoint(x: 140, y: 580),
            size: CGSize(width: 170, height: 68)
        )
        _ = hotspot(
            "Pip's lever",
            name: "submit",
            at: CGPoint(x: 1080, y: 250),
            size: CGSize(width: 150, height: 80)
        )
        _ = hotspot("Ask Pip", name: "help", at: CGPoint(x: 400, y: 290))
        _ = hotspot("Wind gear", name: "wind", at: CGPoint(x: 395, y: 390))
        _ = hotspot(
            "Next order",
            name: "next",
            at: CGPoint(x: 1060, y: 410),
            size: CGSize(width: 180, height: 68)
        )

        for (index, title) in ["Count", "Add", "Find part"].enumerated() {
            _ = hotspot(
                title,
                name: "workshop\(index)",
                at: CGPoint(x: 540 + index * 180, y: 500),
                size: CGSize(width: 150, height: 64)
            )
        }

        let workshopLabel = ArtSystem.label("Pip's workshop · unscored examples", size: 18)
        workshopLabel.position = CGPoint(x: 720, y: 550)
        workshopLabel.zPosition = 950
        addChild(workshopLabel)

        gate = hotspot(
            "Challenge Gate",
            name: "challengeGate",
            at: CGPoint(x: 1120, y: 555),
            size: CGSize(width: 175, height: 110)
        )
        decorateChallengeGate()

        updateGateAppearance()
        openOrder()
    }

    private func openOrder() {
        engaged = false
        selection = state.prepareNext()
        refreshActiveMechanic()

        switch selection {
        case .explorationBreak:
            instruction.text = "Pip's gears need a breather. Wind the gear, explore, or visit Story Tree."

        case .needsContent:
            instruction.text = "Pip is rebuilding the next castle machine. Explore the workshop for now."

        case .encounter:
            if state.challengeGateStatus == .active {
                instruction.text = "Challenge Gate · Rune \(state.challengeGateCompletedCount + 1) of \(state.challengeGateTotalCount). Tap the machine when you're ready."
            } else {
                instruction.text = "Tap the castle machine to walk over and help Pip."
            }

        case nil:
            instruction.text = "Pip is checking the castle machines."
        }
    }

    private func decorateChallengeGate() {
        gateRunes.removeAll()
        guard let gate else { return }

        for index in 0..<ChallengeGateCatalog.challengeCount {
            let rune = SKShapeNode(circleOfRadius: 10)
            rune.position = CGPoint(x: CGFloat(index - 1) * 34, y: -28)
            rune.fillColor = .darkGray
            rune.strokeColor = .white.withAlphaComponent(0.7)
            rune.lineWidth = 2
            rune.name = "challengeGate"
            gate.addChild(rune)
            gateRunes.append(rune)
        }
    }

    private func updateGateAppearance() {
        let litCount: Int

        switch state.challengeGateStatus {
        case .locked:
            gate?.alpha = 0.45
            litCount = 0

        case .ready:
            gate?.alpha = 1.0
            litCount = 0
            if reducedMotion == false {
                gate?.run(.sequence([
                    .fadeAlpha(to: 0.72, duration: 0.7),
                    .fadeAlpha(to: 1.0, duration: 0.7)
                ]))
            }

        case .active:
            gate?.alpha = 1.0
            litCount = state.challengeGateCompletedCount

        case .completed:
            gate?.alpha = 0.95
            litCount = ChallengeGateCatalog.challengeCount
        }

        for (index, rune) in gateRunes.enumerated() {
            rune.fillColor = index < litCount ? .systemYellow : .darkGray
            rune.setScale(index < litCount ? 1.12 : 1.0)
        }
    }

    private func refreshActiveMechanic() {
        guard let runtime = state.activeMath else {
            activeMechanicNode?.removeFromParent()
            activeMechanicNode = nil
            return
        }

        let needsReplacement: Bool = {
            switch runtime {
            case .crystalCart:
                return !(activeMechanicNode is CrystalCartMechanic)
            case .balanceScale:
                return !(activeMechanicNode is BalanceScaleMechanic)
            case .numberBond:
                return !(activeMechanicNode is NumberBondMachineMechanic)
            case .tenFrame:
                return !(activeMechanicNode is TenFrameGateMechanic)
            case .missingBridge:
                return !(activeMechanicNode is MissingNumberBridgeMechanic)
            }
        }()

        if needsReplacement {
            activeMechanicNode?.removeFromParent()
            activeMechanicNode = makeMechanicNode(for: runtime)
            if let activeMechanicNode { addChild(activeMechanicNode) }
        }

        switch (runtime, activeMechanicNode) {
        case (.crystalCart(let model), let node as CrystalCartMechanic):
            node.render(model)

        case (.balanceScale(let model), let node as BalanceScaleMechanic):
            node.render(model)

        case (.numberBond(let model), let node as NumberBondMachineMechanic):
            node.render(model)

        case (.tenFrame(let model), let node as TenFrameGateMechanic):
            node.render(model)

        case (.missingBridge(let model), let node as MissingNumberBridgeMechanic):
            node.render(model)

        default:
            break
        }

        if engaged, let encounter = state.activeEncounter {
            instruction.text =
                (state.workshop ? "Workshop · " : "")
                + encounter.prompt
                + " "
                + interactionHint(for: encounter.mechanicID)
        }
    }

    private func makeMechanicNode(for runtime: MathMechanicRuntime) -> SKNode {
        switch runtime {
        case .crystalCart:
            // CrystalCartMechanic was authored with scene-space coordinates.
            return CrystalCartMechanic()

        case .balanceScale:
            let node = BalanceScaleMechanic()
            node.position = CGPoint(x: 790, y: 330)
            return node

        case .numberBond:
            let node = NumberBondMachineMechanic()
            node.position = CGPoint(x: 790, y: 330)
            return node

        case .tenFrame:
            let node = TenFrameGateMechanic()
            node.position = CGPoint(x: 790, y: 330)
            return node

        case .missingBridge:
            let node = MissingNumberBridgeMechanic()
            node.position = CGPoint(x: 790, y: 330)
            return node
        }
    }

    private func interactionHint(for mechanicID: String) -> String {
        switch mechanicID {
        case MathMechanicID.crystalCart:
            return "Tap or drag crystals."
        case MathMechanicID.balanceScale:
            return "Tap the left side, Equal, or the right side."
        case MathMechanicID.numberBondMachine:
            return "Tap the glowing chamber to add. Tap a crystal to remove."
        case MathMechanicID.tenFrameGate:
            return "Tap an empty rune space to place starlight. Tap a new crystal to remove it."
        case MathMechanicID.missingNumberBridge:
            return "Use + and − to set the missing number."
        default:
            return ""
        }
    }

    private func station() -> CGPoint {
        switch state.activeEncounter?.mechanicID {
        case MathMechanicID.crystalCart:
            return CGPoint(x: 490, y: 175)
        default:
            return CGPoint(x: 675, y: 180)
        }
    }

    private func canManipulate() -> Bool {
        guard state.activeMath != nil, !state.activeCompleted else { return false }
        return engaged && isNear(station())
    }

    private func isActiveObject(_ name: String?) -> Bool {
        guard let name else { return false }
        return [
            "cart", "fixedCrystal", "supply", "cartCrystal",
            MathMechanicID.balanceScale, "scaleLeft", "scaleEqual", "scaleRight",
            MathMechanicID.numberBondMachine, "bondMachine", "bondKnown", "bondSelected", "bondFixed", "bondToken",
            MathMechanicID.tenFrameGate, "tenFrameCell", "tenFrameToken", "tenFrameFixed",
            MathMechanicID.missingNumberBridge, "missingBridge", "missingAnswer", "missingPlus", "missingMinus"
        ].contains(name)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }

        activeTouch = touch
        startPoint = touch.location(in: self)
        didDrag = false

        let name = targetName(at: startPoint)
        if canManipulate(),
           state.activeEncounter?.mechanicID == MathMechanicID.crystalCart,
           name == "supply" || name == "cartCrystal" {
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
            ghost = CrystalCartMechanic.crystal()
            ghost?.zPosition = 1900
            if let ghost { addChild(ghost) }
        }

        ghost?.position = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }

        let point = touch.location(in: self)
        let origin = dragOrigin
        if hypot(point.x - startPoint.x, point.y - startPoint.y) > 12 {
            didDrag = true
        }

        defer { clearDrag() }

        if didDrag {
            handleDrag(from: origin, to: point)
            return
        }

        let target = targetName(at: point)

        if isActiveObject(target), !canManipulate() {
            engageActive()
            return
        }

        switch target {
        case "home":
            state.travel(to: .storyTree)

        case "supply":
            if state.incrementActive() {
                refreshActiveMechanic()
                valkyrie.pose(.interact)
                state.audio.play("crystal")
            }

        case "cartCrystal":
            if state.decrementActive() {
                refreshActiveMechanic()
                state.audio.play("crystal")
            }

        case "bondSelected":
            if state.incrementActive() {
                refreshActiveMechanic()
                state.audio.play("crystal")
            }

        case "bondToken":
            if state.decrementActive() {
                refreshActiveMechanic()
                state.audio.play("crystal")
            }

        case "tenFrameCell":
            if state.incrementActive() {
                refreshActiveMechanic()
                state.audio.play("crystal")
            }

        case "tenFrameToken":
            if state.decrementActive() {
                refreshActiveMechanic()
                state.audio.play("crystal")
            }

        case "scaleLeft":
            state.chooseComparison(.left)
            refreshActiveMechanic()
            valkyrie.pose(.interact)

        case "scaleEqual":
            state.chooseComparison(.equal)
            refreshActiveMechanic()
            valkyrie.pose(.interact)

        case "scaleRight":
            state.chooseComparison(.right)
            refreshActiveMechanic()
            valkyrie.pose(.interact)

        case "missingPlus":
            if state.incrementActive() {
                refreshActiveMechanic()
                state.audio.play("gear")
            }

        case "missingMinus":
            if state.decrementActive() {
                refreshActiveMechanic()
                state.audio.play("gear")
            }

        case "submit":
            submitActive()

        case "help":
            if canManipulate() {
                showScaffold()
            } else {
                engageActive()
            }

        case "wind":
            engaged = false
            travel(to: CGPoint(x: 380, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion)
                self.state.finishExploration()
                self.state.audio.play("gear")
                self.instruction.text = "Pip's gears hum! Explore or choose a new work order."
            }

        case "next":
            guard state.activeMath == nil || state.activeCompleted || selection == .explorationBreak else {
                instruction.text = "Finish this machine, or ask Pip for help first."
                return
            }
            openOrder()

        case "workshop0":
            workshop(0)

        case "workshop1":
            workshop(1)

        case "workshop2":
            workshop(2)

        case "challengeGate":
            openChallengeGate()

        default:
            engaged = false
            walkIfValid(point)
        }
    }

    private func handleDrag(from origin: String?, to point: CGPoint) {
        guard canManipulate(),
              let cart = activeMechanicNode as? CrystalCartMechanic else {
            return
        }

        if origin == "supply", cart.receives(point), state.incrementActive() {
            state.audio.play("crystal")
        }

        if origin == "cartCrystal", cart.returnsToSupply(point), state.decrementActive() {
            state.audio.play("crystal")
        }

        refreshActiveMechanic()
    }

    private func submitActive() {
        guard canManipulate() else {
            engageActive()
            return
        }

        let wasChallengeGate = state.challengeGateStatus == .active

        guard let evidence = state.submit() else {
            instruction.text = "Choose an answer on the machine first."
            return
        }

        pip.operate(reducedMotion: reducedMotion)
        refreshActiveMechanic()

        if evidence.outcome == .correct {
            valkyrie.pose(.celebrate)
            state.audio.play("success")
            updateGateAppearance()

            if wasChallengeGate && state.challengeGateStatus == .completed {
                instruction.text = "The final rune shines! A Moon Lantern has appeared at Story Tree."
            } else if wasChallengeGate {
                instruction.text = "A Challenge Gate rune lights up. Choose the next challenge when you're ready."
            } else {
                gate?.run(.fadeAlpha(to: 0.5, duration: reducedMotion ? 0 : 0.4))
                instruction.text = "The castle machine wakes up! Explore, or choose the next work order."
            }
        } else {
            valkyrie.pose(.react)

            if state.activeMath == nil {
                // Hidden placement learned from the miss and intentionally changes
                // the next challenge rather than making the child repeat a test item.
                instruction.text = "Pip has another idea. Choose the next work order and he'll change the machine."
            } else {
                instruction.text = "That changed the machine, but not in the way Pip expected. Let's look together."
                showScaffold()
            }
        }
    }

    private func openChallengeGate() {
        switch state.challengeGateStatus {
        case .locked:
            instruction.text = "The Challenge Gate is still gathering starlight. Keep helping Pip with ready skills."

        case .ready:
            if let runtime = state.activeMath, !runtime.completed {
                instruction.text = "Finish this work order before entering the Challenge Gate."
                return
            }
            if state.beginChallengeGate() {
                updateGateAppearance()
                openOrder()
            } else {
                instruction.text = "The Challenge Gate needs a little more readiness before it opens."
            }

        case .active:
            if state.activeMath == nil || state.activeCompleted {
                openOrder()
            } else {
                instruction.text = "The Challenge Gate is already open. Finish the glowing machine."
                engageActive()
            }

        case .completed:
            instruction.text = "The Challenge Gate is restored. Your Moon Lantern is waiting at Story Tree."
        }
    }

    private func workshop(_ index: Int) {
        guard state.placementComplete else {
            instruction.text = "Pip is still tuning the castle machines. His free-play workshop will open soon."
            return
        }

        if let runtime = state.activeMath, !runtime.completed, !state.workshop {
            instruction.text = "Finish Pip's work order before opening his workshop."
            return
        }

        guard state.startWorkshop(MathFoundation.workshopExamples[index]) else {
            instruction.text = "Choose a fresh example, or wind Pip's gear for a change of pace."
            return
        }

        engaged = false
        refreshActiveMechanic()
        instruction.text = "Unscored workshop. Walk to the cart to try this example."
    }

    private func engageActive() {
        guard state.activeMath != nil, !state.activeCompleted else {
            instruction.text = "Choose a new work order or explore with Pip."
            return
        }

        let target = station()
        if isNear(target) {
            engaged = true
            refreshActiveMechanic()
        } else {
            engaged = false
            instruction.text = "Valkyrie is walking over. Tap the machine again when she arrives."
            travel(to: target)
        }
    }

    private func showScaffold() {
        if let scaffold = state.scaffold() {
            pip.operate(reducedMotion: reducedMotion)
            refreshActiveMechanic()
            instruction.text = scaffold.cue
        }
    }

    private func clearDrag() {
        activeTouch = nil
        dragOrigin = nil
        ghost?.removeFromParent()
        ghost = nil
        didDrag = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            clearDrag()
        }
    }

    override func willLeave() {
        clearDrag()
        super.willLeave()
    }
}
