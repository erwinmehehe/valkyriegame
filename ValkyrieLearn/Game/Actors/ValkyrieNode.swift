import SpriteKit

@MainActor class CharacterNode: SKNode {
    let character: String
    let bodyNode = SKNode()
    private var atlasSprite: SKSpriteNode?
    private var temporaryLabel: SKLabelNode?
    private var facing: CGFloat = 1
    var reducedMotion = false
    init(character: String, color: UIColor, height: CGFloat) {
        self.character = character
        super.init()
        addChild(bodyNode)
        let body = ArtSystem.box(CGSize(width: height * 0.42, height: height * 0.62), color: color)
        body.position.y = height * 0.38; bodyNode.addChild(body)
        let head = SKShapeNode(circleOfRadius: height * 0.18)
        head.fillColor = .init(red: 1, green: 0.84, blue: 0.69, alpha: 1)
        head.strokeColor = .clear; head.position.y = height * 0.85; bodyNode.addChild(head)
        let label = ArtSystem.label(character + " · TEMP", size: 18)
        label.position.y = height + 25; addChild(label); temporaryLabel = label
        let shadow = SKShapeNode(ellipseOf: CGSize(width: height * 0.55, height: 18))
        shadow.fillColor = .black.withAlphaComponent(0.2); shadow.strokeColor = .clear; shadow.zPosition = -1; addChild(shadow)
        let sprite = SKSpriteNode(); sprite.size = CGSize(width: height * (character == "Valkyrie" ? 370.0 / 480 : 360.0 / 420), height: height)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0); sprite.isHidden = true
        bodyNode.addChild(sprite); atlasSprite = sprite
        pose(.idle)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    func pose(_ pose: ArtSystem.Pose) {
        removeAction(forKey: "operation")
        bodyNode.removeAction(forKey: "pose")
        atlasSprite?.removeAction(forKey: "pose")
        bodyNode.position = .zero; bodyNode.zRotation = 0; bodyNode.setScale(1)
        bodyNode.xScale = facing
        let frames = ArtSystem.frames(character: character, pose: pose)
        if let first = frames.first, let sprite = atlasSprite {
            temporaryLabel?.isHidden = true
            bodyNode.children.filter { $0 !== sprite }.forEach { $0.isHidden = true }
            sprite.isHidden = false; sprite.texture = first
            if !reducedMotion {
                switch pose {
                case .walk:
                    if frames.count > 1 { sprite.run(.repeatForever(.animate(with: frames, timePerFrame: 0.22)), withKey: "pose") }
                    else { bodyNode.run(.repeatForever(.sequence([.moveBy(x: 0, y: 4, duration: 0.18), .moveBy(x: 0, y: -4, duration: 0.18)])), withKey: "pose") }
                case .idle:
                    bodyNode.run(.repeatForever(.sequence([.scaleY(to: 1.008, duration: 1.8), .scaleY(to: 1, duration: 1.8)])), withKey: "pose")
                case .celebrate:
                    bodyNode.run(.sequence([.moveBy(x: 0, y: 12, duration: 0.18), .moveBy(x: 0, y: -12, duration: 0.22)]), withKey: "pose")
                case .react:
                    bodyNode.run(.sequence([.rotate(toAngle: -0.035, duration: 0.14), .rotate(toAngle: 0, duration: 0.2)]), withKey: "pose")
                case .interact: break // The existing atlas supplies Valkyrie's reaching pose.
                }
            }
            if pose == .interact || pose == .celebrate || pose == .react {
                run(.sequence([.wait(forDuration: reducedMotion ? 0.25 : 0.75), .run { [weak self] in self?.pose(.idle) }]), withKey: "operation")
            }
        } else {
            temporaryLabel?.isHidden = false
            atlasSprite?.isHidden = true
            bodyNode.children.filter { $0 !== atlasSprite }.forEach { $0.isHidden = false }
            guard !reducedMotion else { bodyNode.setScale(1); bodyNode.position = .zero; return }
            let action: SKAction
            switch pose {
            case .walk: action = .sequence([.moveBy(x: 0, y: 5, duration: 0.12), .moveBy(x: 0, y: -5, duration: 0.12)])
            case .interact: action = .sequence([.rotate(toAngle: -0.12, duration: 0.15), .rotate(toAngle: 0, duration: 0.15)])
            case .celebrate: action = .sequence([.scale(to: 1.06, duration: 0.2), .scale(to: 1, duration: 0.2)])
            case .react: action = .sequence([.rotate(toAngle: 0.1, duration: 0.15), .rotate(toAngle: 0, duration: 0.15)])
            case .idle: action = .sequence([.scaleY(to: 1.015, duration: 1), .scaleY(to: 1, duration: 1)])
            }
            bodyNode.run(.repeatForever(action), withKey: "pose")
        }
    }
    func walk(to destination: CGPoint, completion: @escaping () -> Void) {
        removeAction(forKey: "travel")
        pose(.walk)
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        face(toward: destination)
        // Reduced motion keeps spatial continuity without bounce, camera or celebratory motion.
        run(.sequence([.move(to: destination, duration: Double(distance / (reducedMotion ? 800 : 240))),
                       .run { [weak self] in self?.pose(.idle); completion() }]), withKey: "travel")
    }
    func face(toward point: CGPoint) {
        if abs(point.x - position.x) > 1 { facing = point.x < position.x ? -1 : 1; bodyNode.xScale = facing }
    }
    func cancelTravel() { removeAction(forKey: "travel"); pose(.idle) }
}
@MainActor final class ValkyrieNode: CharacterNode {
    init() { super.init(character: "Valkyrie", color: .systemPink, height: 300) }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
}
