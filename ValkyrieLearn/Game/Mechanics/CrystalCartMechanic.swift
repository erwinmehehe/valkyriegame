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

        // The deck spans a castle water channel. Empty spaces show the water
        // beneath it; there is no answer panel filling the whole structure.
        let water = SKShapeNode(rectOf: CGSize(width: 490, height: 120), cornerRadius: 2)
        water.position = CGPoint(x: 0, y: -100)
        water.fillColor = .init(red: 0.08, green: 0.25, blue: 0.32, alpha: 0.88)
        water.strokeColor = .init(red: 0.23, green: 0.53, blue: 0.60, alpha: 0.5)
        water.lineWidth = 3; water.zPosition = -5; water.name = "missingBridge"
        addChild(water)
        for x in [-258, 258] {
            let bank = ArtSystem.box(CGSize(width: 26, height: 132),
                color: .init(red: 0.34, green: 0.32, blue: 0.35, alpha: 1), radius: 2)
            bank.position = CGPoint(x: x, y: -100)
            bank.strokeColor = .init(red: 0.57, green: 0.51, blue: 0.42, alpha: 1)
            bank.zPosition = -3; bank.name = "missingBridge"; addChild(bank)
        }
        for y in [-42, -158] {
            let edge = ArtSystem.box(CGSize(width: 490, height: 6),
                color: .init(white: 0.05, alpha: 0.65), radius: 0)
            edge.position = CGPoint(x: 0, y: y)
            edge.zPosition = -3; edge.name = "missingBridge"; addChild(edge)
        }
        for row in 0..<3 {
            let ripple = CGMutablePath()
            ripple.move(to: CGPoint(x: -205 + CGFloat(row) * 24, y: -106 - CGFloat(row) * 12))
            ripple.addQuadCurve(to: CGPoint(x: 190 - CGFloat(row) * 24, y: -106 - CGFloat(row) * 12),
                control: CGPoint(x: 0, y: -94 - CGFloat(row) * 12))
            let wave = SKShapeNode(path: ripple)
            wave.strokeColor = .init(red: 0.53, green: 0.85, blue: 0.85, alpha: 0.25)
            wave.lineWidth = 2; wave.zPosition = -4; wave.name = "missingBridge"
            addChild(wave)
        }
        for x in [-246, 246] {
            let support = ArtSystem.box(CGSize(width: 18, height: 130),
                color: .init(red: 0.39, green: 0.27, blue: 0.16, alpha: 1), radius: 3)
            support.position = CGPoint(x: x, y: -96)
            support.name = "missingBridge"; support.zPosition = -1
            addChild(support)
            let cap = ArtSystem.box(CGSize(width: 28, height: 12),
                color: .init(red: 0.79, green: 0.57, blue: 0.24, alpha: 1), radius: 3)
            cap.position = CGPoint(x: x, y: -30); cap.name = "missingBridge"
            addChild(cap)
        }
        let rope = CGMutablePath()
        rope.move(to: CGPoint(x: -246, y: -35))
        rope.addQuadCurve(to: CGPoint(x: 246, y: -35), control: CGPoint(x: 0, y: -70))
        let rail = SKShapeNode(path: rope)
        rail.strokeColor = .init(red: 0.79, green: 0.61, blue: 0.34, alpha: 1)
        rail.lineWidth = 5; rail.name = "missingBridge"; rail.zPosition = -1
        addChild(rail)

        // A small suspended work order supplies the relationship; the child's
        // actual answer is built into the bridge below it.
        for x in [-150, 40] {
            let post = ArtSystem.box(CGSize(width: 12, height: 118),
                color: .init(red: 0.40, green: 0.28, blue: 0.16, alpha: 1), radius: 2)
            post.position = CGPoint(x: x, y: -7); post.zPosition = -2; post.name = "missingBridge"
            addChild(post)
            let chain = ArtSystem.box(CGSize(width: 4, height: 30),
                color: .init(red: 0.78, green: 0.59, blue: 0.27, alpha: 1), radius: 1)
            chain.position = CGPoint(x: x, y: 39); chain.name = "missingBridge"; addChild(chain)
        }
        let lintel = ArtSystem.box(CGSize(width: 220, height: 12),
            color: .init(red: 0.40, green: 0.28, blue: 0.16, alpha: 1), radius: 3)
        lintel.position = CGPoint(x: -55, y: 54); lintel.name = "missingBridge"; addChild(lintel)
        let sign = ArtSystem.box(CGSize(width: 220, height: 48),
            color: .init(red: 0.25, green: 0.19, blue: 0.13, alpha: 0.94), radius: 6)
        sign.position = CGPoint(x: -55, y: 20); sign.name = "missingBridge"
        sign.strokeColor = .init(red: 0.79, green: 0.57, blue: 0.24, alpha: 1); sign.lineWidth = 2
        addChild(sign)
        equation.fontSize = 23; equation.position = sign.position; equation.name = "missingBridge"
        equation.fontColor = .init(red: 1, green: 0.94, blue: 0.77, alpha: 1); addChild(equation)

        let dial = ArtSystem.gear(radius: 44)
        dial.position = CGPoint(x: 145, y: 20); dial.name = "missingAnswer"
        addChild(dial)
        answer.fontSize = 36; answer.position = dial.position; answer.name = "missingAnswer"
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
                : (filled ? .init(red: 0.29, green: 0.51, blue: 0.43, alpha: 1) : .clear)
            slot.strokeColor = .init(red: 0.72, green: 0.56, blue: 0.31, alpha: filled ? 0.8 : 0.3)
            slot.children.forEach { $0.isHidden = !filled }
            slot.glowWidth = 0
            deck.addChild(slot)
        }
    }

    static func plank() -> SKShapeNode {
        let plank = ArtSystem.box(CGSize(width: 44, height: 48), color: .init(red: 0.29, green: 0.51, blue: 0.43, alpha: 1), radius: 1)
        plank.strokeColor = .init(red: 0.86, green: 0.67, blue: 0.34, alpha: 1)
        plank.lineWidth = 1
        let edge = ArtSystem.box(CGSize(width: 42, height: 5),
            color: .init(red: 0.16, green: 0.12, blue: 0.09, alpha: 0.8), radius: 0)
        edge.position.y = -20; edge.strokeColor = .clear; plank.addChild(edge)
        for x in [-10, 10] {
            let grain = CGMutablePath()
            grain.move(to: CGPoint(x: x, y: -17))
            grain.addQuadCurve(to: CGPoint(x: x + 2, y: 17), control: CGPoint(x: x - 4, y: 0))
            let groove = SKShapeNode(path: grain)
            groove.strokeColor = .init(red: 0.12, green: 0.18, blue: 0.12, alpha: 0.35)
            groove.lineWidth = 1
            plank.addChild(groove)
        }
        for point in [CGPoint(x: -13, y: 17), CGPoint(x: 13, y: -17)] {
            let nail = SKShapeNode(circleOfRadius: 2)
            nail.position = point; nail.fillColor = .init(red: 0.9, green: 0.75, blue: 0.44, alpha: 1)
            nail.strokeColor = .clear; plank.addChild(nail)
        }
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
