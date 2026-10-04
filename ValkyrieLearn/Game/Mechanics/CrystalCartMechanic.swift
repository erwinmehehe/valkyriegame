import SpriteKit
import LearningCore

@MainActor final class CrystalCartMechanic: SKNode {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let contents = SKNode()
    override init() {
        super.init()
        zPosition = 750
        let cart = ArtSystem.box(CGSize(width: 305, height: 165), color: .init(red: 0.50, green: 0.30, blue: 0.14, alpha: 1))
        cart.position = cartCenter; cart.name = "cart"; addChild(cart)
        for x in [735, 925] {
            let wheel = SKShapeNode(circleOfRadius: 32); wheel.fillColor = .darkGray
            wheel.strokeColor = .systemOrange; wheel.lineWidth = 5
            wheel.position = CGPoint(x: x, y: 170); wheel.name = "cart"; addChild(wheel)
        }
        let supply = ArtSystem.box(CGSize(width: 125, height: 145), color: .init(red: 0.26, green: 0.25, blue: 0.34, alpha: 1))
        supply.position = supplyCenter; supply.name = "supply"; addChild(supply)
        let crystal = Self.crystal(); crystal.position = supplyCenter; crystal.name = "supply"; addChild(crystal)
        let supplyLabel = ArtSystem.label("Crystals", size: 20)
        supplyLabel.position = CGPoint(x: 595, y: 340); addChild(supplyLabel)
        addChild(contents)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    static func crystal() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 29)); path.addLine(to: CGPoint(x: 26, y: 8))
        path.addLine(to: CGPoint(x: 18, y: -25)); path.addLine(to: CGPoint(x: -18, y: -25))
        path.addLine(to: CGPoint(x: -26, y: 8)); path.closeSubpath()
        let node = SKShapeNode(path: path); node.fillColor = .cyan
        node.strokeColor = .white; node.lineWidth = 2; return node
    }
    func render(_ model: CrystalCartModel) {
        contents.removeAllChildren()
        for index in 0..<model.quantity {
            let crystal = Self.crystal()
            crystal.position = CGPoint(x: 714 + (index % 5) * 58, y: 310 - (index / 5) * 61)
            crystal.name = index < model.encounter.initialQuantity ? "fixedCrystal" : "cartCrystal"
            if index < model.encounter.initialQuantity { crystal.fillColor = .systemPurple }
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

    override init() {
        super.init()
        name = MathMechanicID.balanceScale
        zPosition = 750

        beam.name = "scaleBeam"
        beam.position = CGPoint(x: 0, y: 40)
        addChild(beam)

        let stand = ArtSystem.box(
            CGSize(width: 22, height: 180),
            color: .darkGray,
            radius: 8
        )
        stand.position = CGPoint(x: 0, y: -40)
        addChild(stand)

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
            color: .init(red: 0.34, green: 0.38, blue: 0.48, alpha: 1)
        )
        pan.position = CGPoint(x: x, y: -45)
        pan.name = name
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
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: NumberBondMachineModel) {
        wholeLabel.text = "Whole: \(model.whole)"
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
    private let previewActionKey = "quickLookPreview"

    override init() {
        super.init()
        name = MathMechanicID.tenFrameGate
        zPosition = 750

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
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: TenFrameModel) {
        latestModel = model
        let now = Date()
        let previewVisible = model.previewIsVisible(at: now)
        let visibleQuantity = previewVisible ? model.encounter.targetQuantity : model.filled
        cells.children.enumerated().forEach { index, cell in
            guard let shape = cell as? SKShapeNode else { return }
            shape.fillColor = index < visibleQuantity
                ? .systemTeal
                : .init(red: 0.17, green: 0.20, blue: 0.30, alpha: 1)
            shape.name = previewVisible ? "tenFramePreview"
                : (index < model.encounter.initialQuantity ? "tenFrameFixed" : "tenFrameCell")
        }
        removeAction(forKey: previewActionKey)
        if previewVisible {
            // Re-renders retain the original deadline; they cannot replay the flash.
            let remaining = max(0, model.startedAt.addingTimeInterval(model.previewDuration).timeIntervalSince(now))
            run(.sequence([.wait(forDuration: remaining), .run { [weak self] in
                guard let self, let latest = self.latestModel else { return }
                self.render(latest)
            }]), withKey: previewActionKey)
        }
    }
}

@MainActor final class MissingNumberBridgeMechanic: SKNode {
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
        bridge.name = "missingBridge"
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

        let minus = ArtSystem.box(CGSize(width: 70, height: 56), color: .darkGray)
        minus.position = CGPoint(x: 85, y: -55)
        minus.name = "missingMinus"
        minus.addChild(ArtSystem.label("−", size: 34))
        addChild(minus)

        let plus = ArtSystem.box(CGSize(width: 70, height: 56), color: .darkGray)
        plus.position = CGPoint(x: 205, y: -55)
        plus.name = "missingPlus"
        plus.addChild(ArtSystem.label("+", size: 34))
        addChild(plus)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: MissingNumberBridgeModel) {
        equation.text = "\(model.encounter.initialQuantity) + ? = \(model.encounter.targetQuantity)"
        answer.text = "\(model.selectedNumber)"
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
