import SpriteKit
import LearningCore

@MainActor protocol MathCastleReactiveMechanic: AnyObject {
    func playSuccessReaction(reducedMotion: Bool)
}

@MainActor final class CrystalCartMechanic: SKNode, MathCastleReactiveMechanic {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let cartAssembly = SKNode()
    private let contents = SKNode()
    override init() {
        super.init()
        zPosition = 750
        addChild(cartAssembly)
        if let cart = ArtSystem.sprite("CrystalCart", size: CGSize(width: 320, height: 225)) {
            cart.position = CGPoint(x: 815, y: 250)
            cart.name = "cart"
            cartAssembly.addChild(cart)
        }
        // The visual cart is closer to the reference scale, while the native drop
        // target remains generously sized for a child's finger.
        let cartHit = ArtSystem.box(CGSize(width: 285, height: 155), color: .clear, radius: 0)
        cartHit.position = CGPoint(x: 815, y: 260)
        cartHit.name = "cart"
        cartAssembly.addChild(cartHit)
        let supply = ArtSystem.box(CGSize(width: 125, height: 100), color: .init(red: 0.26, green: 0.25, blue: 0.34, alpha: 0.9), radius: 9)
        supply.strokeColor = .init(red: 0.77, green: 0.59, blue: 0.32, alpha: 1); supply.lineWidth = 3
        supply.position = supplyCenter; supply.name = "supply"; addChild(supply)
        let crystal = Self.crystal(); crystal.position = supplyCenter; crystal.setScale(1.45); crystal.name = "supply"; addChild(crystal)
        cartAssembly.addChild(contents)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    static func crystal() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 29)); path.addLine(to: CGPoint(x: 26, y: 8))
        path.addLine(to: CGPoint(x: 18, y: -25)); path.addLine(to: CGPoint(x: -18, y: -25))
        path.addLine(to: CGPoint(x: -26, y: 8)); path.closeSubpath()
        let node = SKShapeNode(path: path); node.fillColor = .cyan
        if let sprite = ArtSystem.sprite("Crystal", size: CGSize(width: 44, height: 59)) {
            node.fillColor = .clear; node.strokeColor = .clear; node.addChild(sprite)
        } else { node.strokeColor = .white; node.lineWidth = 2 }
        return node
    }
    func render(_ model: CrystalCartModel) {
        contents.removeAllChildren()
        for index in 0..<model.quantity {
            let crystal = Self.crystal()
            crystal.position = CGPoint(
                x: 710 + CGFloat(index % 5) * 53,
                y: 300 - CGFloat(index / 5) * 54
            )
            let fixed = model.encounter.operation != .subtraction
                && index < model.encounter.initialQuantity
            crystal.name = fixed ? "fixedCrystal" : "cartCrystal"
            if fixed {
                if let sprite = crystal.children.first as? SKSpriteNode {
                    sprite.color = .systemPurple
                    sprite.colorBlendFactor = 0.28
                } else {
                    crystal.fillColor = .systemPurple
                }
            }
            contents.addChild(crystal)
        }
    }
    func receives(_ point: CGPoint) -> Bool {
        CGRect(x: 675, y: 165, width: 310, height: 190).contains(point)
    }
    func returnsToSupply(_ point: CGPoint) -> Bool {
        CGRect(x: 525, y: 155, width: 135, height: 190).contains(point)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        cartAssembly.removeAction(forKey: "successTravel")
        contents.removeAction(forKey: "successGlow")

        if reducedMotion {
            cartAssembly.position.x = 42
            return
        }

        let travel = SKAction.moveBy(x: 78, y: 6, duration: 0.68)
        travel.timingMode = .easeInEaseOut
        cartAssembly.run(travel, withKey: "successTravel")
        contents.run(.sequence([
            .scale(to: 1.045, duration: 0.16),
            .scale(to: 1, duration: 0.24)
        ]), withKey: "successGlow")
    }
}


@MainActor final class BalanceScaleMechanic: SKNode, MathCastleReactiveMechanic {
    private let leftContents = SKNode()
    private let rightContents = SKNode()
    private let beam = ArtSystem.box(CGSize(width: 360, height: 18), color: .systemOrange, radius: 8)
    private var leftPan: SKNode?
    private var rightPan: SKNode?
    private var equalGear: SKShapeNode?

    override init() {
        super.init()
        name = MathMechanicID.balanceScale
        zPosition = 750

        beam.name = "scaleBeam"
        beam.position = CGPoint(x: 0, y: 40)
        addChild(beam)

        let stand = ArtSystem.box(
            CGSize(width: 22, height: 180),
            color: .init(red: 0.73, green: 0.51, blue: 0.24, alpha: 1),
            radius: 8
        )
        stand.position = CGPoint(x: 0, y: -40)
        addChild(stand)
        let equal = ArtSystem.gear(radius: 36, symbol: "=")
        equal.position = CGPoint(x: 0, y: -115); equal.name = "scaleEqual"
        addChild(equal); equalGear = equal.children.first as? SKShapeNode

        leftPan = addPan(name: "scaleLeft", x: -150)
        rightPan = addPan(name: "scaleRight", x: 150)
        leftContents.zPosition = 1
        rightContents.zPosition = 1

        addChild(leftContents)
        addChild(rightContents)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func addPan(name: String, x: CGFloat) -> SKNode {
        let pan = ArtSystem.box(
            CGSize(width: 180, height: 72),
            color: .init(red: 0.35, green: 0.5, blue: 0.53, alpha: 1)
        )
        pan.position = CGPoint(x: x, y: -45)
        pan.name = name
        let chains = CGMutablePath()
        chains.move(to: CGPoint(x: x-70, y: -15)); chains.addLine(to: CGPoint(x: x, y: 45))
        chains.addLine(to: CGPoint(x: x+70, y: -15))
        let hanger = SKShapeNode(path: chains); hanger.strokeColor = .init(red: 0.88, green: 0.66, blue: 0.28, alpha: 1); hanger.lineWidth = 3
        addChild(hanger)
        addChild(pan)
        return pan
    }

    func render(_ model: BalanceScaleModel) {
        // Positive rotation lowers the left end in SpriteKit's upward y-axis.
        let angle: CGFloat = model.leftQuantity == model.rightQuantity ? 0
            : (model.leftQuantity > model.rightQuantity ? 0.14 : -0.14)
        beam.zRotation = angle
        let leftOffset = -150 * sin(angle)
        let rightOffset = 150 * sin(angle)
        leftPan?.position.y = -45 + leftOffset
        rightPan?.position.y = -45 + rightOffset
        leftContents.position.y = leftOffset
        rightContents.position.y = rightOffset
        for (pan, choice) in [(leftPan, ComparisonChoice.left), (rightPan, ComparisonChoice.right)] {
            (pan as? SKShapeNode)?.strokeColor = model.selected == choice ? .systemYellow : .white
            (pan as? SKShapeNode)?.lineWidth = model.selected == choice ? 5 : 1.5
        }
        equalGear?.fillColor = model.selected == .equal ? .systemOrange : .darkGray
        renderQuantity(model.leftQuantity, in: leftContents, centerX: -150, targetName: "scaleLeft")
        renderQuantity(model.rightQuantity, in: rightContents, centerX: 150, targetName: "scaleRight")
    }

    private func renderQuantity(_ quantity: Int, in node: SKNode, centerX: CGFloat, targetName: String) {
        node.removeAllChildren()
        for index in 0..<quantity {
            let token = tokenNode()
            token.name = targetName
            let column = index % 5
            let row = index / 5
            token.position = CGPoint(
                x: centerX - 52 + CGFloat(column) * 26,
                y: -35 + CGFloat(row) * 26
            )
            node.addChild(token)
        }
    }

    private func tokenNode() -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor = .cyan
        node.strokeColor = .white
        node.lineWidth = 1.5
        return node
    }

    func playSuccessReaction(reducedMotion: Bool) {
        guard !reducedMotion else {
            beam.alpha = 1
            return
        }

        let angle = beam.zRotation
        beam.run(.sequence([
            .rotate(toAngle: angle + 0.035, duration: 0.10),
            .rotate(toAngle: angle - 0.02, duration: 0.12),
            .rotate(toAngle: angle, duration: 0.16)
        ]), withKey: "successBalance")
        run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1, duration: 0.18)
        ]), withKey: "successPulse")
    }
}

@MainActor final class NumberBondMachineMechanic: SKNode, MathCastleReactiveMechanic {
    private let knownContents = SKNode()
    private let selectedContents = SKNode()
    private let wholeLabel = ArtSystem.label("", size: 34)

    override init() {
        super.init()
        name = MathMechanicID.numberBondMachine
        zPosition = 750

        let shell = ArtSystem.box(
            CGSize(width: 430, height: 250),
            color: .init(red: 0.22, green: 0.26, blue: 0.40, alpha: 1)
        )
        shell.strokeColor = .init(red: 0.84, green: 0.64, blue: 0.3, alpha: 1); shell.lineWidth = 5
        shell.name = "bondMachine"
        addChild(shell)

        let known = ArtSystem.box(
            CGSize(width: 150, height: 115),
            color: .init(red: 0.35, green: 0.28, blue: 0.48, alpha: 1)
        )
        known.position = CGPoint(x: -105, y: -30)
        known.name = "bondKnown"
        addChild(known)

        let selected = ArtSystem.box(
            CGSize(width: 150, height: 115),
            color: .init(red: 0.22, green: 0.45, blue: 0.50, alpha: 1)
        )
        selected.position = CGPoint(x: 105, y: -30)
        selected.name = "bondSelected"
        addChild(selected)

        wholeLabel.position = CGPoint(x: 0, y: 82)
        addChild(wholeLabel)
        addChild(knownContents)
        addChild(selectedContents)
        let supply = ArtSystem.box(CGSize(width: 100, height: 100), color: .darkGray)
        supply.position = CGPoint(x: -265, y: -30); supply.name = "bondSupply"
        let token = SKShapeNode(circleOfRadius: 18)
        token.fillColor = .cyan; token.strokeColor = .white; supply.addChild(token)
        addChild(supply)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: NumberBondMachineModel) {
        wholeLabel.text = "\(model.whole)"
        renderTokens(model.knownPart, in: knownContents, centerX: -105, fixed: true)
        renderTokens(model.selectedPart, in: selectedContents, centerX: 105, fixed: false)
    }

    private func renderTokens(_ count: Int, in node: SKNode, centerX: CGFloat, fixed: Bool) {
        node.removeAllChildren()
        for index in 0..<count {
            let token = SKShapeNode(circleOfRadius: 11)
            token.fillColor = fixed ? .systemPurple : .cyan
            token.strokeColor = .white
            token.lineWidth = 1.5
            token.position = CGPoint(
                x: centerX - 42 + CGFloat(index % 4) * 28,
                y: -48 + CGFloat(index / 4) * 28
            )
            token.name = fixed ? "bondFixed" : "bondToken"
            node.addChild(token)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        wholeLabel.fontColor = UIColor(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        guard !reducedMotion else { return }

        run(.sequence([
            .scale(to: 1.035, duration: 0.14),
            .scale(to: 0.99, duration: 0.12),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "successPulse")
        wholeLabel.run(.sequence([
            .fadeAlpha(to: 0.45, duration: 0.10),
            .fadeAlpha(to: 1, duration: 0.18)
        ]), withKey: "successWhole")
    }
}

@MainActor final class TenFrameGateMechanic: SKNode, MathCastleReactiveMechanic {
    private let cells = SKNode()
    private var latestModel: TenFrameModel?
    private var latestAllowsPreview = true
    private let previewActionKey = "quickLookPreview"

    override init() {
        super.init()
        name = MathMechanicID.tenFrameGate
        zPosition = 750
        cells.name = "tenFrameCells"

        let brass = UIColor(red: 0.69, green: 0.46, blue: 0.21, alpha: 1)
        for x in [-183,183] {
            let pillar = ArtSystem.box(CGSize(width: 22, height: 205), color: brass, radius: 5)
            pillar.position = CGPoint(x: x, y: -10); addChild(pillar)
        }
        for y in [-118,98] {
            let crossbar = ArtSystem.box(CGSize(width: 400, height: 24), color: brass, radius: 5)
            crossbar.position.y = CGFloat(y); addChild(crossbar)
        }

        for index in 0..<10 {
            let cell = ArtSystem.box(
                CGSize(width: 62, height: 62),
                color: .init(red: 0.17, green: 0.20, blue: 0.30, alpha: 1),
                radius: 8
            )
            let column = index % 5
            let row = index / 5
            cell.position = CGPoint(
                x: -128 + CGFloat(column) * 64,
                y: 34 - CGFloat(row) * 64
            )
            cell.name = "tenFrameCell"
            cells.addChild(cell)
        }
        addChild(cells)
        let supply = ArtSystem.box(CGSize(width: 100, height: 100), color: .darkGray)
        supply.position = CGPoint(x: -270, y: 0); supply.name = "tenFrameSupply"
        let token = SKShapeNode(circleOfRadius: 18)
        token.fillColor = .systemTeal; token.strokeColor = .white; supply.addChild(token)
        addChild(supply)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: TenFrameModel, allowPreview: Bool = true) {
        latestModel = model
        latestAllowsPreview = allowPreview
        let now = Date()
        let previewVisible = allowPreview && model.previewIsVisible(at: now)
        let visibleQuantity = previewVisible ? model.encounter.targetQuantity : model.filled
        cells.children.enumerated().forEach { index, cell in
            guard let shape = cell as? SKShapeNode else { return }
            shape.fillColor = index < visibleQuantity
                ? .systemTeal
                : .init(red: 0.17, green: 0.20, blue: 0.30, alpha: 1)
            shape.name = previewVisible ? "tenFramePreview"
                : (index < model.encounter.initialQuantity ? "tenFrameFixed"
                   : (index < model.filled ? "tenFrameFilled" : "tenFrameCell"))
        }
        removeAction(forKey: previewActionKey)
        if previewVisible {
            // Re-renders retain the original deadline; they cannot replay the flash.
            let remaining = max(0, model.startedAt.addingTimeInterval(model.previewDuration).timeIntervalSince(now))
            run(.sequence([.wait(forDuration: remaining), .run { [weak self] in
                guard let self, let latest = self.latestModel else { return }
                self.render(latest, allowPreview: self.latestAllowsPreview)
            }]), withKey: previewActionKey)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        let active = cells.children.compactMap { $0 as? SKShapeNode }
            .filter { $0.fillColor != UIColor(red: 0.17, green: 0.20, blue: 0.30, alpha: 1) }

        for (index, cell) in active.enumerated() {
            cell.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.38, alpha: 1)
            cell.lineWidth = 3
            guard !reducedMotion else { continue }

            cell.run(.sequence([
                .wait(forDuration: Double(index) * 0.055),
                .scale(to: 1.13, duration: 0.08),
                .scale(to: 1, duration: 0.12)
            ]), withKey: "successCell")
        }
    }
}

@MainActor final class MissingNumberBridgeMechanic: SKNode, MathCastleReactiveMechanic {
    private var bridgeDeck: SKShapeNode?
    private var answerBoxNode: SKShapeNode?
    private let equation = ArtSystem.label("", size: 38)
    private let answer = ArtSystem.label("", size: 44)

    override init() {
        super.init()
        name = MathMechanicID.missingNumberBridge
        zPosition = 750

        let bridge = ArtSystem.box(
            CGSize(width: 500, height: 150),
            color: .init(red: 0.35, green: 0.29, blue: 0.24, alpha: 1)
        )
        bridge.strokeColor = .init(red: 0.81, green: 0.61, blue: 0.26, alpha: 1); bridge.lineWidth = 4
        bridge.name = "missingBridge"
        bridgeDeck = bridge
        for x in stride(from: -230, through: 230, by: 46) {
            let joint = ArtSystem.box(CGSize(width: 2, height: 142), color: .init(red: 0.18, green: 0.12, blue: 0.1, alpha: 0.55), radius: 0)
            joint.position.x = CGFloat(x); bridge.addChild(joint)
        }
        addChild(bridge)

        equation.position = CGPoint(x: -70, y: 20)
        addChild(equation)

        let answerBox = ArtSystem.box(
            CGSize(width: 88, height: 78),
            color: .init(red: 0.20, green: 0.42, blue: 0.50, alpha: 1)
        )
        answerBox.position = CGPoint(x: 145, y: 20)
        answerBox.name = "missingAnswer"
        answerBoxNode = answerBox
        addChild(answerBox)

        answer.position = CGPoint(x: 145, y: 5)
        answer.name = "missingAnswer"
        addChild(answer)

        let minus = ArtSystem.gear(radius: 30, symbol: "−")
        minus.position = CGPoint(x: 85, y: -55)
        minus.name = "missingMinus"
        addChild(minus)

        let plus = ArtSystem.gear(radius: 30, symbol: "+")
        plus.position = CGPoint(x: 205, y: -55)
        plus.name = "missingPlus"
        addChild(plus)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: MissingNumberBridgeModel) {
        equation.text = "\(model.encounter.initialQuantity) + ? = \(model.encounter.targetQuantity)"
        answer.text = "\(model.selectedNumber)"
    }

    func playSuccessReaction(reducedMotion: Bool) {
        bridgeDeck?.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.38, alpha: 1)
        bridgeDeck?.glowWidth = 4
        answerBoxNode?.fillColor = UIColor(red: 0.28, green: 0.62, blue: 0.64, alpha: 1)

        guard !reducedMotion else { return }

        bridgeDeck?.run(.sequence([
            .moveBy(x: 0, y: 8, duration: 0.12),
            .moveBy(x: 0, y: -8, duration: 0.18)
        ]), withKey: "successLock")
        answerBoxNode?.run(.sequence([
            .scale(to: 1.12, duration: 0.10),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "successAnswer")
    }
}

@MainActor enum MathCastleMechanicFactory {
    static func makeNode(for encounter: LearningEncounter) -> SKNode? {
        switch encounter.mechanicID {
        case MathMechanicID.balanceScale:
            return BalanceScaleMechanic()
        case MathMechanicID.numberBondMachine:
            return NumberBondMachineMechanic()
        case MathMechanicID.tenFrameGate:
            return TenFrameGateMechanic()
        case MathMechanicID.missingNumberBridge:
            return MissingNumberBridgeMechanic()
        default:
            return nil
        }
    }
}
