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

        // A very soft silhouette wash separates illustrated characters from busy
        // painted worlds without altering the character artwork itself.
        let silhouetteGlow = SKShapeNode(
            ellipseOf: CGSize(width: height * 0.66, height: height * 0.82)
        )
        silhouetteGlow.name = "characterSilhouetteGlow"
        silhouetteGlow.fillColor = color.withAlphaComponent(character == "Valkyrie" ? 0.030 : 0.022)
        silhouetteGlow.strokeColor = color.withAlphaComponent(character == "Valkyrie" ? 0.12 : 0.085)
        silhouetteGlow.lineWidth = character == "Valkyrie" ? 2.2 : 1.6
        silhouetteGlow.glowWidth = character == "Valkyrie" ? 7 : 5
        silhouetteGlow.position.y = height * 0.45
        silhouetteGlow.zPosition = -3
        silhouetteGlow.isUserInteractionEnabled = false
        addChild(silhouetteGlow)

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
        syncCharacterPresentation(for: pose)
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
                    bodyNode.run(idleMotion(), withKey: "pose")
                case .celebrate:
                    bodyNode.run(celebrationMotion(), withKey: "pose")
                case .react:
                    bodyNode.run(reactionMotion(), withKey: "pose")
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
            case .walk: action = companionStep()
            case .interact:
                action = .sequence([
                    eased(.rotate(toAngle: -0.10, duration: 0.14)),
                    eased(.rotate(toAngle: 0, duration: 0.18))
                ])
            case .celebrate: action = celebrationMotion()
            case .react: action = reactionMotion()
            case .idle: action = idleMotion()
            }
            bodyNode.run(action, withKey: "pose")
        }
    }

    private func eased(_ action: SKAction) -> SKAction {
        action.timingMode = .easeInEaseOut
        return action
    }

    private func syncCharacterPresentation(for pose: ArtSystem.Pose) {
        if let shadow = childNode(withName: "characterGroundShadow") {
            shadow.removeAction(forKey: "poseShadow")
            shadow.alpha = 1
            switch pose {
            case .idle:
                shadow.xScale = 1
                shadow.yScale = 1
            case .walk:
                shadow.xScale = 0.92
                shadow.yScale = 0.88
            case .interact:
                shadow.xScale = 0.96
                shadow.yScale = 0.90
            case .celebrate:
                shadow.xScale = 0.80
                shadow.yScale = 0.76
            case .react:
                shadow.xScale = 1.08
                shadow.yScale = 0.92
            }
        }

        guard let glow = childNode(withName: "characterSilhouetteGlow") else { return }
        glow.removeAction(forKey: "characterPresence")
        glow.setScale(1)
        glow.alpha = pose == .celebrate ? 1 : (pose == .react ? 0.62 : 0.78)

        guard !reducedMotion else { return }
        let peak: CGFloat = character == "Valkyrie" ? 0.96 : 0.88
        let floor: CGFloat = character == "Valkyrie" ? 0.72 : 0.64
        let duration: TimeInterval = character == "Milo" ? 1.8 : (character == "Lumi" ? 2.8 : 2.3)
        glow.alpha = floor
        glow.run(
            .repeatForever(.sequence([
                .fadeAlpha(to: peak, duration: duration),
                .fadeAlpha(to: floor, duration: duration)
            ])),
            withKey: "characterPresence"
        )
    }

    private func idleMotion() -> SKAction {
        let profile: (scale: CGFloat, rise: CGFloat, beat: TimeInterval)
        switch character {
        case "Valkyrie": profile = (1.006, 1.5, 2.15)
        case "Pip": profile = (1.012, 2.0, 1.30)
        case "Lumi": profile = (1.005, 2.4, 2.70)
        case "Milo": profile = (1.010, 1.8, 1.55)
        case "Tiko": profile = (1.006, 1.0, 2.35)
        default: profile = (1.008, 1.2, 1.8)
        }

        return .repeatForever(.sequence([
            .group([
                eased(.scaleY(to: profile.scale, duration: profile.beat)),
                eased(.moveTo(y: profile.rise, duration: profile.beat))
            ]),
            .group([
                eased(.scaleY(to: 1, duration: profile.beat)),
                eased(.moveTo(y: 0, duration: profile.beat))
            ])
        ]))
    }

    private func celebrationMotion() -> SKAction {
        let profile: (rise: CGFloat, tilt: CGFloat, up: TimeInterval, down: TimeInterval)
        switch character {
        case "Valkyrie": profile = (18, -0.032, 0.19, 0.28)
        case "Milo": profile = (13, -0.065, 0.13, 0.18)
        case "Tiko": profile = (10, -0.038, 0.18, 0.24)
        case "Pip": profile = (11, -0.080, 0.12, 0.17)
        case "Lumi": profile = (15, -0.020, 0.24, 0.30)
        default: profile = (14, -0.04, 0.18, 0.24)
        }

        var actions: [SKAction] = [
            .group([
                eased(.moveBy(x: 0, y: profile.rise, duration: profile.up)),
                eased(.rotate(toAngle: profile.tilt, duration: profile.up))
            ]),
            .group([
                eased(.moveBy(x: 0, y: -profile.rise, duration: profile.down)),
                eased(.rotate(toAngle: -profile.tilt * 0.45, duration: profile.down))
            ])
        ]
        if character == "Pip" || character == "Milo" {
            actions.append(.group([
                eased(.moveBy(x: 0, y: 5, duration: 0.10)),
                eased(.rotate(toAngle: profile.tilt * 0.55, duration: 0.10))
            ]))
            actions.append(.group([
                eased(.moveBy(x: 0, y: -5, duration: 0.12)),
                eased(.rotate(toAngle: 0, duration: 0.12))
            ]))
        } else {
            actions.append(eased(.rotate(toAngle: 0, duration: 0.12)))
        }
        return .sequence(actions)
    }

    private func reactionMotion() -> SKAction {
        let profile: (first: CGFloat, second: CGFloat, beat: TimeInterval)
        switch character {
        case "Valkyrie": profile = (-0.032, 0.018, 0.13)
        case "Milo": profile = (-0.075, 0.040, 0.10)
        case "Tiko": profile = (-0.038, 0.020, 0.16)
        case "Pip": profile = (-0.095, 0.070, 0.10)
        case "Lumi": profile = (-0.025, 0.012, 0.18)
        default: profile = (-0.04, 0.025, 0.12)
        }
        return .sequence([
            eased(.rotate(toAngle: profile.first, duration: profile.beat)),
            eased(.rotate(toAngle: profile.second, duration: profile.beat)),
            eased(.rotate(toAngle: 0, duration: profile.beat + 0.04))
        ])
    }

    private func companionStep() -> SKAction {
        let step: (rise: CGFloat, tilt: CGFloat, beat: TimeInterval)
        switch character {
        case "Valkyrie": step = (4.5, 0.012, 0.22) // Confident, grounded stride.
        case "Pip": step = (3.8, 0.034, 0.17) // Cheerful waddle.
        case "Lumi": step = (2.2, 0.010, 0.31) // Gentle glide.
        case "Milo": step = (3.4, 0.022, 0.15) // Quick scout.
        case "Tiko": step = (1.7, 0.014, 0.27) // Careful mechanic steps.
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
