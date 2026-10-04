import SpriteKit
import LearningCore

@MainActor enum MathMechanicArt {
    static let gold = UIColor(red: 0.93, green: 0.63, blue: 0.16, alpha: 1)
    static let paleGold = UIColor(red: 1.00, green: 0.86, blue: 0.46, alpha: 1)
    static let wood = UIColor(red: 0.31, green: 0.16, blue: 0.08, alpha: 0.96)
    static let deepPurple = UIColor(red: 0.16, green: 0.10, blue: 0.29, alpha: 0.94)
    static let violet = UIColor(red: 0.38, green: 0.20, blue: 0.60, alpha: 0.94)
    static let teal = UIColor(red: 0.12, green: 0.48, blue: 0.54, alpha: 0.95)

    static func panel(
        _ size: CGSize,
        name: String? = nil,
        color: UIColor = deepPurple,
        radius: CGFloat = 18
    ) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = color
        node.strokeColor = gold
        node.lineWidth = 3
        node.glowWidth = 1.5
        node.name = name
        return node
    }

    static func woodPanel(
        _ size: CGSize,
        name: String? = nil,
        radius: CGFloat = 16
    ) -> SKShapeNode {
        panel(size, name: name, color: wood, radius: radius)
    }

    static func sourceSprite(
        resource: String,
        size: CGSize,
        name: String? = nil
    ) -> SKSpriteNode? {
        guard let texture = ArtSystem.sourceTexture(resource: resource, ext: "png") else {
            return nil
        }
        let node = SKSpriteNode(texture: texture)
        node.size = size
        node.name = name
        return node
    }

    static func crystal(
        size: CGFloat,
        name: String,
        fixed: Bool = false
    ) -> SKNode {
        let holder = SKNode()
        holder.name = name

        let glow = SKShapeNode(circleOfRadius: size * 0.34)
        glow.fillColor = fixed
            ? UIColor.systemPurple.withAlphaComponent(0.18)
            : UIColor.systemCyan.withAlphaComponent(0.22)
        glow.strokeColor = .clear
        glow.glowWidth = size * 0.12
        glow.name = name
        holder.addChild(glow)

        if let sprite = sourceSprite(
            resource: "V331_Crystal",
            size: CGSize(width: size * 0.92, height: size),
            name: name
        ) {
            sprite.position.y = size * 0.05
            sprite.alpha = fixed ? 0.78 : 1.0
            holder.addChild(sprite)
        } else {
            let fallback = SKShapeNode(circleOfRadius: size * 0.25)
            fallback.fillColor = fixed ? .systemPurple : .cyan
            fallback.strokeColor = paleGold
            fallback.lineWidth = 2
            fallback.name = name
            holder.addChild(fallback)
        }

        return holder
    }

    static func button(
        _ title: String,
        name: String,
        size: CGSize,
        color: UIColor = deepPurple
    ) -> SKShapeNode {
        let node = panel(size, name: name, color: color, radius: 14)
        let label = ArtSystem.label(title, size: 20)
        label.name = name
        node.addChild(label)
        return node
    }
}

@MainActor final class CrystalCartMechanic: SKNode {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let contents = SKNode()

    override init() {
        super.init()
        zPosition = 750

        if let cart = MathMechanicArt.sourceSprite(
            resource: "V331_Cart",
            size: CGSize(width: 320, height: 295),
            name: "cart"
        ) {
            cart.position = CGPoint(x: cartCenter.x, y: cartCenter.y - 8)
            addChild(cart)
        } else {
            let cart = MathMechanicArt.woodPanel(
                CGSize(width: 305, height: 165),
                name: "cart"
            )
            cart.position = cartCenter
            addChild(cart)
        }

        let supply = MathMechanicArt.panel(
            CGSize(width: 132, height: 152),
            name: "supply",
            color: UIColor(red: 0.10, green: 0.11, blue: 0.22, alpha: 0.72),
            radius: 22
        )
        supply.position = supplyCenter
        addChild(supply)

        let crystal = Self.crystal(name: "supply")
        crystal.position = CGPoint(x: supplyCenter.x, y: supplyCenter.y - 4)
        addChild(crystal)

        let supplyLabel = ArtSystem.label("Starlight", size: 18)
        supplyLabel.position = CGPoint(x: supplyCenter.x, y: supplyCenter.y + 96)
        supplyLabel.fontColor = MathMechanicArt.paleGold
        addChild(supplyLabel)

        addChild(contents)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    static func crystal(name: String = "crystal") -> SKNode {
        MathMechanicArt.crystal(size: 62, name: name)
    }

    func render(_ model: CrystalCartModel) {
        contents.removeAllChildren()

        for index in 0..<model.quantity {
            let subtraction = model.encounter.operation == .subtraction
            let fixed = index < model.encounter.initialQuantity
            let hitName = subtraction || !fixed ? "cartCrystal" : "fixedCrystal"
            let crystal = MathMechanicArt.crystal(
                size: 46,
                name: hitName,
                fixed: fixed
            )
            crystal.position = CGPoint(
                x: 714 + CGFloat(index % 5) * 58,
                y: 314 - CGFloat(index / 5) * 53
            )
            contents.addChild(crystal)
        }
    }

    func receives(_ point: CGPoint) -> Bool {
        CGRect(x: 675, y: 165, width: 310, height: 205).contains(point)
    }

    func returnsToSupply(_ point: CGPoint) -> Bool {
        CGRect(x: 525, y: 150, width: 140, height: 200).contains(point)
    }
}

@MainActor final class BalanceScaleMechanic: SKNode {
    private let leftContents = SKNode()
    private let rightContents = SKNode()
    private var leftPan: SKShapeNode?
    private var rightPan: SKShapeNode?
    private var equalButton: SKShapeNode?

    override init() {
        super.init()
        name = MathMechanicID.balanceScale
        zPosition = 750

        let halo = SKShapeNode(circleOfRadius: 58)
        halo.fillColor = UIColor.systemPurple.withAlphaComponent(0.12)
        halo.strokeColor = MathMechanicArt.gold.withAlphaComponent(0.5)
        halo.lineWidth = 2
        halo.position = CGPoint(x: 0, y: 32)
        addChild(halo)

        let beam = MathMechanicArt.woodPanel(
            CGSize(width: 370, height: 22),
            radius: 9
        )
        beam.position = CGPoint(x: 0, y: 45)
        addChild(beam)

        let stand = MathMechanicArt.woodPanel(
            CGSize(width: 28, height: 185),
            radius: 9
        )
        stand.position = CGPoint(x: 0, y: -38)
        addChild(stand)

        let pivot = SKShapeNode(circleOfRadius: 19)
        pivot.fillColor = MathMechanicArt.gold
        pivot.strokeColor = MathMechanicArt.paleGold
        pivot.lineWidth = 3
        pivot.position = CGPoint(x: 0, y: 45)
        addChild(pivot)

        leftPan = addPan(name: "scaleLeft", x: -150)
        rightPan = addPan(name: "scaleRight", x: 150)

        let equal = MathMechanicArt.button(
            "Equal",
            name: "scaleEqual",
            size: CGSize(width: 96, height: 54)
        )
        equal.position = CGPoint(x: 0, y: -92)
        addChild(equal)
        equalButton = equal

        addChild(leftContents)
        addChild(rightContents)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic mechanics")
    }

    @discardableResult
    private func addPan(name: String, x: CGFloat) -> SKShapeNode {
        let pan = MathMechanicArt.panel(
            CGSize(width: 184, height: 76),
            name: name,
            color: MathMechanicArt.deepPurple,
            radius: 22
        )
        pan.position = CGPoint(x: x, y: -45)
        addChild(pan)

        let chain = SKShapeNode(rectOf: CGSize(width: 4, height: 72), cornerRadius: 2)
        chain.fillColor = MathMechanicArt.gold
        chain.strokeColor = .clear
        chain.position = CGPoint(x: x, y: 2)
        chain.name = name
        addChild(chain)

        return pan
    }

    func render(_ model: BalanceScaleModel) {
        renderQuantity(
            model.leftQuantity,
            in: leftContents,
            centerX: -150,
            hitName: "scaleLeft"
        )
        renderQuantity(
            model.rightQuantity,
            in: rightContents,
            centerX: 150,
            hitName: "scaleRight"
        )

        let idle = MathMechanicArt.deepPurple
        let selected = MathMechanicArt.teal
        leftPan?.fillColor = model.selected == .left ? selected : idle
        rightPan?.fillColor = model.selected == .right ? selected : idle
        equalButton?.fillColor = model.selected == .equal
            ? selected
            : MathMechanicArt.deepPurple
    }

    private func renderQuantity(
        _ quantity: Int,
        in node: SKNode,
        centerX: CGFloat,
        hitName: String
    ) {
        node.removeAllChildren()
        for index in 0..<quantity {
            let token = MathMechanicArt.crystal(size: 27, name: hitName)
            let column = index % 5
            let row = index / 5
            token.position = CGPoint(
                x: centerX - 52 + CGFloat(column) * 26,
                y: -34 + CGFloat(row) * 25
            )
            node.addChild(token)
        }
    }
}

@MainActor final class NumberBondMachineMechanic: SKNode {
    private let knownContents = SKNode()
    private let selectedContents = SKNode()
    private let wholeLabel = ArtSystem.label("", size: 32)

    override init() {
        super.init()
        name = MathMechanicID.numberBondMachine
        zPosition = 750

        let shell = MathMechanicArt.woodPanel(
            CGSize(width: 440, height: 255),
            name: "bondMachine",
            radius: 28
        )
        addChild(shell)

        let core = SKShapeNode(circleOfRadius: 41)
        core.fillColor = UIColor.systemPurple.withAlphaComponent(0.34)
        core.strokeColor = MathMechanicArt.paleGold
        core.lineWidth = 3
        core.glowWidth = 5
        core.position = CGPoint(x: 0, y: 78)
        core.name = "bondMachine"
        addChild(core)

        let known = MathMechanicArt.panel(
            CGSize(width: 158, height: 118),
            name: "bondKnown",
            color: UIColor(red: 0.28, green: 0.18, blue: 0.44, alpha: 0.96)
        )
        known.position = CGPoint(x: -108, y: -34)
        addChild(known)

        let selected = MathMechanicArt.panel(
            CGSize(width: 158, height: 118),
            name: "bondSelected",
            color: MathMechanicArt.teal
        )
        selected.position = CGPoint(x: 108, y: -34)
        addChild(selected)

        for x in [-52.0, 52.0] {
            let conduit = SKShapeNode(rectOf: CGSize(width: 72, height: 7), cornerRadius: 3)
            conduit.fillColor = MathMechanicArt.gold
            conduit.strokeColor = .clear
            conduit.zRotation = x < 0 ? -0.55 : 0.55
            conduit.position = CGPoint(x: x, y: 30)
            addChild(conduit)
        }

        wholeLabel.position = CGPoint(x: 0, y: 74)
        wholeLabel.fontColor = MathMechanicArt.paleGold
        wholeLabel.name = "bondMachine"
        addChild(wholeLabel)

        addChild(knownContents)
        addChild(selectedContents)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic mechanics")
    }

    func render(_ model: NumberBondMachineModel) {
        wholeLabel.text = "Whole (model.whole)"
        renderTokens(
            model.knownPart,
            in: knownContents,
            centerX: -108,
            fixed: true
        )
        renderTokens(
            model.selectedPart,
            in: selectedContents,
            centerX: 108,
            fixed: false
        )
    }

    private func renderTokens(
        _ count: Int,
        in node: SKNode,
        centerX: CGFloat,
        fixed: Bool
    ) {
        node.removeAllChildren()
        for index in 0..<count {
            let token = MathMechanicArt.crystal(
                size: 28,
                name: fixed ? "bondFixed" : "bondToken",
                fixed: fixed
            )
            token.position = CGPoint(
                x: centerX - 42 + CGFloat(index % 4) * 28,
                y: -50 + CGFloat(index / 4) * 28
            )
            node.addChild(token)
        }
    }
}

@MainActor final class TenFrameGateMechanic: SKNode {
    private let cells = SKNode()

    override init() {
        super.init()
        name = MathMechanicID.tenFrameGate
        zPosition = 750

        let gate = MathMechanicArt.woodPanel(
            CGSize(width: 350, height: 172),
            name: MathMechanicID.tenFrameGate,
            radius: 24
        )
        addChild(gate)

        for index in 0..<10 {
            let cell = MathMechanicArt.panel(
                CGSize(width: 58, height: 58),
                name: "tenFrameCell",
                color: UIColor(red: 0.10, green: 0.08, blue: 0.19, alpha: 0.92),
                radius: 12
            )
            let column = index % 5
            let row = index / 5
            cell.position = CGPoint(
                x: -128 + CGFloat(column) * 64,
                y: 34 - CGFloat(row) * 64
            )
            cells.addChild(cell)
        }
        addChild(cells)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic mechanics")
    }

    func render(_ model: TenFrameModel) {
        cells.children.enumerated().forEach { index, cell in
            guard let shape = cell as? SKShapeNode else { return }

            shape.removeAllChildren()

            let filled = index < model.filled
            let fixed = index < model.encounter.initialQuantity

            if fixed {
                shape.name = "tenFrameFixed"
            } else if filled {
                shape.name = "tenFrameToken"
            } else {
                shape.name = "tenFrameCell"
            }

            shape.fillColor = filled
                ? UIColor(red: 0.18, green: 0.15, blue: 0.36, alpha: 0.96)
                : UIColor(red: 0.10, green: 0.08, blue: 0.19, alpha: 0.92)

            if filled {
                let crystal = MathMechanicArt.crystal(
                    size: 43,
                    name: shape.name ?? "tenFrameToken",
                    fixed: fixed
                )
                crystal.position = CGPoint(x: 0, y: -1)
                shape.addChild(crystal)
            }
        }
    }
}

@MainActor final class MissingNumberBridgeMechanic: SKNode {
    private let equation = ArtSystem.label("", size: 36)
    private let answer = ArtSystem.label("", size: 42)

    override init() {
        super.init()
        name = MathMechanicID.missingNumberBridge
        zPosition = 750

        let bridge = MathMechanicArt.woodPanel(
            CGSize(width: 510, height: 158),
            name: "missingBridge",
            radius: 18
        )
        addChild(bridge)

        for x in stride(from: -220, through: 210, by: 72) {
            let plank = SKShapeNode(
                rectOf: CGSize(width: 62, height: 116),
                cornerRadius: 8
            )
            plank.fillColor = UIColor(red: 0.24, green: 0.12, blue: 0.06, alpha: 0.62)
            plank.strokeColor = MathMechanicArt.gold.withAlphaComponent(0.65)
            plank.lineWidth = 2
            plank.position = CGPoint(x: CGFloat(x), y: 0)
            plank.name = "missingBridge"
            addChild(plank)
        }

        equation.position = CGPoint(x: -70, y: 24)
        equation.fontColor = MathMechanicArt.paleGold
        equation.name = "missingBridge"
        addChild(equation)

        let answerBox = MathMechanicArt.panel(
            CGSize(width: 92, height: 82),
            name: "missingAnswer",
            color: MathMechanicArt.violet,
            radius: 18
        )
        answerBox.position = CGPoint(x: 145, y: 22)
        addChild(answerBox)

        answer.position = CGPoint(x: 145, y: 7)
        answer.name = "missingAnswer"
        addChild(answer)

        let minus = MathMechanicArt.button(
            "−",
            name: "missingMinus",
            size: CGSize(width: 72, height: 58)
        )
        minus.position = CGPoint(x: 85, y: -58)
        addChild(minus)

        let plus = MathMechanicArt.button(
            "+",
            name: "missingPlus",
            size: CGSize(width: 72, height: 58)
        )
        plus.position = CGPoint(x: 205, y: -58)
        addChild(plus)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic mechanics")
    }

    func render(_ model: MissingNumberBridgeModel) {
        equation.text = "\(model.encounter.initialQuantity) + ? = \(model.encounter.targetQuantity)"
        answer.text = "\(model.selectedNumber)"
    }
}

@MainActor enum MathCastleMechanicFactory {
    static func makeNode(for encounter: LearningEncounter) -> SKNode? {
        switch encounter.mechanicID {
        case MathMechanicID.crystalCart:
            return CrystalCartMechanic()
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
