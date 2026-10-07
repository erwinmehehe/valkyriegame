import SpriteKit

@MainActor class CharacterNode: SKNode {
    let character: String
    let bodyNode = SKNode()
    private var atlasSprite: SKSpriteNode?
    private var temporaryLabel: SKLabelNode?
    private var facing: CGFloat = 1
    private let renderHeight: CGFloat
    private var currentPose: ArtSystem.Pose = .idle
    var reducedMotion = false {
        didSet {
            guard reducedMotion != oldValue else { return }
            // Refresh visual motion without cancelling travel, companion ability
            // callbacks or the existing return-to-idle deadline.
            pose(currentPose, rescheduleIdleReturn: false)
            if reducedMotion, let aura = childNode(withName: "companionPresence") {
                aura.removeAction(forKey: "presencePulse")
                aura.setScale(1)
            }
        }
    }
    init(character: String, color: UIColor, height: CGFloat) {
        self.character = character
        self.renderHeight = height
        super.init()
        addChild(bodyNode)
        let body = ArtSystem.box(CGSize(width: height * 0.42, height: height * 0.62), color: color)
        body.position.y = height * 0.38; bodyNode.addChild(body)
        let head = SKShapeNode(circleOfRadius: height * 0.18)
        head.fillColor = .init(red: 1, green: 0.84, blue: 0.69, alpha: 1)
        head.strokeColor = .clear; head.position.y = height * 0.85; bodyNode.addChild(head)
        let label = ArtSystem.label(character + " · TEMP", size: 18)
        label.position.y = height + 25; addChild(label); temporaryLabel = label
        // A broad, faint penumbra and compact contact shadow keep feet grounded
        // without putting a hard black oval under every illustrated companion.
        let shadow = SKNode()
        shadow.name = "characterGroundShadow"
        shadow.zPosition = -1
        shadow.isUserInteractionEnabled = false
        let layers: [(CGFloat, CGFloat, CGFloat)] = [(0.60, 0.085, 0.055), (0.48, 0.060, 0.10), (0.32, 0.035, 0.16)]
        for (width, depth, opacity) in layers {
            let layer = SKShapeNode(ellipseOf: CGSize(width: height * width, height: height * depth))
            layer.fillColor = UIColor(red: 0.06, green: 0.08, blue: 0.13, alpha: opacity)
            layer.strokeColor = .clear
            shadow.addChild(layer)
        }
        addChild(shadow)
        let sprite = SKSpriteNode(); sprite.size = CGSize(width: height * (character == "Valkyrie" ? 370.0 / 480 : 360.0 / 420), height: height)
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0); sprite.isHidden = true
        bodyNode.addChild(sprite); atlasSprite = sprite
        pose(.idle)
    }

    @discardableResult
    func addPresenceAura(
        color: UIColor,
        width: CGFloat,
        height: CGFloat = 28,
        glow: CGFloat = 4
    ) -> SKShapeNode {
        let aura = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        aura.name = "companionPresence"
        aura.fillColor = color.withAlphaComponent(0.14)
        aura.strokeColor = color.withAlphaComponent(0.28)
        aura.lineWidth = 1.5
        aura.glowWidth = glow
        aura.position.y = 8
        aura.zPosition = -2
        aura.isUserInteractionEnabled = false
        addChild(aura)
        return aura
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    func pose(_ pose: ArtSystem.Pose, rescheduleIdleReturn: Bool = true) {
        currentPose = pose
        if rescheduleIdleReturn { removeAction(forKey: "operation") }
        for key in ["pose", "helperHop", "miloInspect", "tikoRuneFocus"] {
            bodyNode.removeAction(forKey: key)
        }
        atlasSprite?.removeAction(forKey: "pose")
        // Starting another reaction must not inherit a partly expanded aura.
        if rescheduleIdleReturn, let aura = childNode(withName: "companionPresence") {
            aura.removeAction(forKey: "presencePulse")
            aura.setScale(1)
        }
        bodyNode.position = .zero; bodyNode.zRotation = 0; bodyNode.setScale(1)
        bodyNode.xScale = facing
        let frames = ArtSystem.frames(character: character, pose: pose)
        if let first = frames.first, let sprite = atlasSprite {
            temporaryLabel?.isHidden = true
            bodyNode.children.filter { $0 !== sprite }.forEach { $0.isHidden = true }
            sprite.isHidden = false
            sprite.texture = first
            let textureSize = first.size()
            if textureSize.height > 0 {
                sprite.size = CGSize(
                    width: renderHeight * textureSize.width / textureSize.height,
                    height: renderHeight
                )
            }
            if !reducedMotion {
                switch pose {
                case .walk:
                    if frames.count > 1 { sprite.run(.repeatForever(.animate(with: frames, timePerFrame: 0.22)), withKey: "pose") }
                    else { bodyNode.run(companionStep(), withKey: "pose") }
                case .idle:
                    let breath = character == "Pip" ? 1.4 : (character == "Tiko" ? 2.2 : 1.8)
                    bodyNode.run(.repeatForever(.sequence([
                        eased(.scaleY(to: 1.008, duration: breath)),
                        eased(.scaleY(to: 1, duration: breath))
                    ])), withKey: "pose")
                case .celebrate:
                    bodyNode.run(.sequence([
                        .group([
                            .moveBy(x: 0, y: 15, duration: 0.20),
                            .rotate(toAngle: -0.045, duration: 0.20)
                        ]),
                        .group([
                            .moveBy(x: 0, y: -15, duration: 0.28),
                            .rotate(toAngle: 0.025, duration: 0.22)
                        ]),
                        .rotate(toAngle: 0, duration: 0.12)
                    ]), withKey: "pose")
                case .react:
                    bodyNode.run(.sequence([
                        .rotate(toAngle: -0.04, duration: 0.12),
                        .rotate(toAngle: 0.025, duration: 0.12),
                        .rotate(toAngle: 0, duration: 0.16)
                    ]), withKey: "pose")
                case .interact: break // The existing atlas supplies Valkyrie's reaching pose.
                }
            }
            if rescheduleIdleReturn && (pose == .interact || pose == .celebrate || pose == .react) {
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

    private func eased(_ action: SKAction) -> SKAction {
        action.timingMode = .easeInEaseOut
        return action
    }

    private func companionStep() -> SKAction {
        let step: (rise: CGFloat, tilt: CGFloat, beat: TimeInterval)
        switch character {
        case "Pip": step = (3.5, 0.028, 0.18) // Waddle.
        case "Lumi": step = (2, 0.012, 0.30) // Gentle glide.
        case "Milo": step = (3, 0.018, 0.16) // Quick scout.
        case "Tiko": step = (1.5, 0.012, 0.28) // Careful steps.
        default: step = (3, 0.018, 0.20)
        }
        // Absolute positions prevent interrupted/restarted walks from drifting.
        return .repeatForever(.sequence([
            .group([eased(.moveTo(y: step.rise, duration: step.beat)), eased(.rotate(toAngle: -step.tilt, duration: step.beat))]),
            .group([eased(.moveTo(y: 0, duration: step.beat)), eased(.rotate(toAngle: step.tilt, duration: step.beat))])
        ]))
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
