import SpriteKit
import LearningCore

@MainActor final class CrystalCartMechanic: SKNode {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let contents = SKNode()
    init() {
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
