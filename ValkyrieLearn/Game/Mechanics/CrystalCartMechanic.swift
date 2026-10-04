import SpriteKit
import LearningCore

@MainActor final class CrystalCartMechanic: SKNode {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let contents = SKNode()
    override init() {
        super.init()
        zPosition = 750
        if let cart = ArtSystem.sprite("CrystalCart", size: CGSize(width: 365, height: 255)) {
            cart.position = CGPoint(x: 830, y: 253); cart.name = "cart"; addChild(cart)
        }
        // A native drop surface keeps every crystal independently manipulable.
        let cartHit = ArtSystem.box(CGSize(width: 305, height: 165), color: .clear, radius: 0)
        cartHit.position = cartCenter; cartHit.name = "cart"; addChild(cartHit)
        let supply = ArtSystem.box(CGSize(width: 125, height: 100), color: .init(red: 0.26, green: 0.25, blue: 0.34, alpha: 0.9), radius: 9)
        supply.strokeColor = .init(red: 0.77, green: 0.59, blue: 0.32, alpha: 1); supply.lineWidth = 3
        supply.position = supplyCenter; supply.name = "supply"; addChild(supply)
        let crystal = Self.crystal(); crystal.position = supplyCenter; crystal.setScale(1.45); crystal.name = "supply"; addChild(crystal)
        addChild(contents)
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
            crystal.position = CGPoint(x: 714 + (index % 5) * 58, y: 310 - (index / 5) * 61)
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
}


@MainActor final class BalanceScaleMechanic: SKNode {
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
}

@MainActor final class NumberBondMachineMechanic: SKNode {
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
}

@MainActor final class TenFrameGateMechanic: SKNode {
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
}

@MainActor final class MissingNumberBridgeMechanic: SKNode {
    private let equation = ArtSystem.label("", size: 38)
    private let answer = ArtSystem.label("", size: 44)
    private let deck = SKNode()
    private var latestModel: MissingNumberBridgeModel?

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

        // A stack of spare planks lives beside the bridge, within reach of Pip.
        let supply = ArtSystem.box(CGSize(width: 100, height: 84), color: .init(red: 0.29, green: 0.20, blue: 0.14, alpha: 1))
        supply.position = CGPoint(x: -270, y: 25); supply.name = "missingSupply"
        for index in 0..<3 {
            let plank = Self.plank()
            plank.position = CGPoint(x: CGFloat(index - 1) * 15, y: CGFloat(index) * 5)
            supply.addChild(plank)
        }
        addChild(supply)
        deck.zPosition = 2
        addChild(deck)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: MissingNumberBridgeModel) {
        equation.text = "\(model.encounter.initialQuantity) + ? = \(model.encounter.targetQuantity)"
        answer.text = "\(model.selectedNumber)"
        latestModel = model
        deck.removeAllChildren()
        let total = model.encounter.initialQuantity + model.selectedNumber
        for index in 0..<max(model.encounter.targetQuantity, total) {
            let fixed = index < model.encounter.initialQuantity
            let filled = index < total
            let slot = Self.plank()
            slot.position = deckPoint(index)
            slot.name = fixed ? "missingFixed" : (filled ? "missingPlank" : "missingSlot")
            slot.fillColor = fixed ? .init(red: 0.54, green: 0.40, blue: 0.28, alpha: 1)
                : (filled ? .init(red: 0.28, green: 0.66, blue: 0.65, alpha: 1) : .init(white: 0.06, alpha: 0.7))
            slot.strokeColor = model.completed ? .systemYellow : .init(red: 0.86, green: 0.67, blue: 0.34, alpha: 1)
            slot.glowWidth = model.completed ? 3 : 0
            deck.addChild(slot)
        }
    }

    static func plank() -> SKShapeNode {
        let plank = ArtSystem.box(CGSize(width: 44, height: 48), color: .init(red: 0.28, green: 0.66, blue: 0.65, alpha: 1), radius: 4)
        plank.strokeColor = .init(red: 0.86, green: 0.67, blue: 0.34, alpha: 1)
        plank.lineWidth = 2
        return plank
    }

    private func deckPoint(_ index: Int) -> CGPoint {
        // Extra planks remain visible below the required span so overshooting is
        // recoverable by direct touch; the renderer never silently fixes an answer.
        CGPoint(x: -224 + CGFloat(index % 10) * 48, y: -90 - CGFloat(index / 10) * 54)
    }

    func receives(_ point: CGPoint) -> Bool {
        guard let model = latestModel else { return false }
        return (0..<max(model.encounter.targetQuantity, model.encounter.initialQuantity + model.selectedNumber)).contains {
            CGRect(x: deckPoint($0).x - 24, y: deckPoint($0).y - 26, width: 48, height: 52).contains(point)
        }
    }

    func returnsToSupply(_ point: CGPoint) -> Bool {
        CGRect(x: -320, y: -17, width: 100, height: 84).contains(point)
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
