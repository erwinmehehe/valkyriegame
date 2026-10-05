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


@MainActor final class LumiNode: SKNode {
    private let body = SKNode()
    private let glow = SKShapeNode(circleOfRadius: 56)
    var reducedMotion = false

    override init() {
        super.init()
        name = "lumi"

        glow.fillColor = UIColor(red: 0.76, green: 0.56, blue: 1.0, alpha: 0.10)
        glow.strokeColor = .clear
        glow.glowWidth = 12
        glow.zPosition = -2
        addChild(glow)

        let torso = SKShapeNode(ellipseOf: CGSize(width: 92, height: 110))
        torso.fillColor = UIColor(red: 0.88, green: 0.74, blue: 0.56, alpha: 1)
        torso.strokeColor = UIColor(red: 0.47, green: 0.29, blue: 0.52, alpha: 1)
        torso.lineWidth = 3
        torso.position.y = 36
        body.addChild(torso)

        let head = SKShapeNode(circleOfRadius: 46)
        head.fillColor = UIColor(red: 0.95, green: 0.83, blue: 0.66, alpha: 1)
        head.strokeColor = UIColor(red: 0.47, green: 0.29, blue: 0.52, alpha: 1)
        head.lineWidth = 3
        head.position.y = 102
        body.addChild(head)

        for x in [-20.0, 20.0] {
            let eye = SKShapeNode(circleOfRadius: 15)
            eye.fillColor = UIColor(red: 0.10, green: 0.08, blue: 0.13, alpha: 1)
            eye.strokeColor = UIColor(red: 0.96, green: 0.78, blue: 0.34, alpha: 1)
            eye.lineWidth = 3
            eye.position = CGPoint(x: x, y: 105)
            body.addChild(eye)

            let shine = SKShapeNode(circleOfRadius: 4)
            shine.fillColor = .white
            shine.strokeColor = .clear
            shine.position = CGPoint(x: x - 4, y: 110)
            body.addChild(shine)
        }

        let beak = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -9, y: 88))
            p.addLine(to: CGPoint(x: 9, y: 88))
            p.addLine(to: CGPoint(x: 0, y: 74))
            p.closeSubpath()
            return p
        }())
        beak.fillColor = UIColor(red: 0.93, green: 0.55, blue: 0.18, alpha: 1)
        beak.strokeColor = .clear
        body.addChild(beak)

        let cap = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -50, y: 142))
            p.addLine(to: CGPoint(x: 0, y: 166))
            p.addLine(to: CGPoint(x: 54, y: 142))
            p.addLine(to: CGPoint(x: 0, y: 126))
            p.closeSubpath()
            return p
        }())
        cap.fillColor = UIColor(red: 0.40, green: 0.24, blue: 0.58, alpha: 1)
        cap.strokeColor = UIColor(red: 0.89, green: 0.70, blue: 1.0, alpha: 1)
        cap.lineWidth = 2
        body.addChild(cap)

        let book = SKShapeNode(rectOf: CGSize(width: 76, height: 48), cornerRadius: 8)
        book.fillColor = UIColor(red: 0.12, green: 0.62, blue: 0.67, alpha: 1)
        book.strokeColor = UIColor(red: 0.87, green: 0.91, blue: 0.65, alpha: 1)
        book.lineWidth = 2
        book.position = CGPoint(x: 0, y: 34)
        book.zRotation = -0.08
        body.addChild(book)

        addChild(body)
        setScale(0.62)
        hover()
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic Lumi") }

    func hover() {
        removeAction(forKey: "hover")
        body.removeAction(forKey: "hover")
        body.position = .zero
        guard !reducedMotion else { return }
        body.run(
            .repeatForever(
                .sequence([
                    .moveBy(x: 0, y: 5, duration: 1.0),
                    .moveBy(x: 0, y: -5, duration: 1.0)
                ])
            ),
            withKey: "hover"
        )
    }

    func react() {
        removeAction(forKey: "reach")
        guard !reducedMotion else { return }
        body.run(
            .sequence([
                .rotate(toAngle: -0.10, duration: 0.12),
                .rotate(toAngle: 0.10, duration: 0.12),
                .rotate(toAngle: 0, duration: 0.15)
            ]),
            withKey: "react"
        )
    }

    func celebrate() {
        removeAction(forKey: "reach")
        guard !reducedMotion else { return }
        glow.run(.sequence([.fadeAlpha(to: 1.0, duration: 0.12), .fadeAlpha(to: 0.55, duration: 0.35)]))
        body.run(
            .sequence([
                .moveBy(x: 0, y: 14, duration: 0.16),
                .moveBy(x: 0, y: -14, duration: 0.22)
            ]),
            withKey: "celebrate"
        )
    }

    func reach(to destination: CGPoint, in scene: SKScene, completion: @escaping () -> Void) {
        removeAction(forKey: "reach")
        let localDestination = scene.convert(destination, to: parent ?? scene)
        let start = position
        let duration = reducedMotion ? 0.05 : 0.55
        run(
            .sequence([
                .move(to: localDestination, duration: duration),
                .run { [weak self] in self?.celebrate() },
                .wait(forDuration: reducedMotion ? 0.05 : 0.28),
                .move(to: start, duration: duration),
                .run { [weak self] in self?.hover(); completion() }
            ]),
            withKey: "reach"
        )
    }
}
