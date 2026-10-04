import SpriteKit

@MainActor class CharacterNode: SKNode {
    let character: String
    let bodyNode = SKNode()
    private let sourceSprite = SKSpriteNode()
    private var atlasSprite: SKSpriteNode?
    private var placeholderNodes: [SKNode] = []
    private let intendedHeight: CGFloat

    var reducedMotion = false

    init(character: String, color: UIColor, height: CGFloat) {
        self.character = character
        intendedHeight = height
        super.init()
        addChild(bodyNode)

        let body = ArtSystem.box(
            CGSize(width: height * 0.42, height: height * 0.62),
            color: color
        )
        body.position.y = height * 0.38
        bodyNode.addChild(body)

        let head = SKShapeNode(circleOfRadius: height * 0.18)
        head.fillColor = .init(red: 1, green: 0.84, blue: 0.69, alpha: 1)
        head.strokeColor = .clear
        head.position.y = height * 0.85
        bodyNode.addChild(head)

        let tempLabel = ArtSystem.label(character + " · TEMP", size: 18)
        tempLabel.position.y = height + 25
        addChild(tempLabel)

        placeholderNodes = [body, head, tempLabel]

        let shadow = SKShapeNode(
            ellipseOf: CGSize(width: height * 0.55, height: 18)
        )
        shadow.fillColor = .black.withAlphaComponent(0.20)
        shadow.strokeColor = .clear
        shadow.zPosition = -1
        addChild(shadow)

        sourceSprite.anchorPoint = CGPoint(x: 0.5, y: 0)
        sourceSprite.zPosition = 1
        sourceSprite.isHidden = true
        bodyNode.addChild(sourceSprite)

        let atlas = SKSpriteNode()
        atlas.size = CGSize(width: height * 0.65, height: height)
        atlas.anchorPoint = CGPoint(x: 0.5, y: 0)
        atlas.isHidden = true
        bodyNode.addChild(atlas)
        atlasSprite = atlas

        pose(.idle)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    func pose(_ pose: ArtSystem.Pose) {
        removeAction(forKey: "operation")
        bodyNode.removeAction(forKey: "pose")
        sourceSprite.removeAction(forKey: "pose")
        atlasSprite?.removeAction(forKey: "pose")

        bodyNode.position = .zero
        bodyNode.zRotation = 0
        bodyNode.setScale(1)

        let frames = ArtSystem.frames(character: character, pose: pose)
        if let first = frames.first, let sprite = atlasSprite {
            showOnly(sprite)
            sprite.texture = first
            if !reducedMotion {
                sprite.run(
                    .repeatForever(.animate(with: frames, timePerFrame: 0.12)),
                    withKey: "pose"
                )
            }
            return
        }

        if let texture = ArtSystem.v331CharacterTexture(character: character, pose: pose) {
            showOnly(sourceSprite)
            sourceSprite.texture = texture
            fitSourceSprite(texture)
            animateSingleFramePose(pose)
            return
        }

        showPlaceholders()
        animatePlaceholderPose(pose)
    }

    private func showOnly(_ sprite: SKSpriteNode) {
        placeholderNodes.forEach { $0.isHidden = true }
        sourceSprite.isHidden = sourceSprite !== sprite
        atlasSprite?.isHidden = atlasSprite !== sprite
    }

    private func showPlaceholders() {
        sourceSprite.isHidden = true
        atlasSprite?.isHidden = true
        placeholderNodes.forEach { $0.isHidden = false }
    }

    private func fitSourceSprite(_ texture: SKTexture) {
        let textureSize = texture.size()
        guard textureSize.width > 0, textureSize.height > 0 else { return }

        let aspect = textureSize.width / textureSize.height
        sourceSprite.size = CGSize(
            width: intendedHeight * aspect,
            height: intendedHeight
        )
    }

    private func animateSingleFramePose(_ pose: ArtSystem.Pose) {
        guard !reducedMotion else { return }

        let action: SKAction
        switch pose {
        case .walk:
            action = .sequence([
                .moveBy(x: 0, y: 5, duration: 0.12),
                .moveBy(x: 0, y: -5, duration: 0.12)
            ])
        case .interact:
            action = .sequence([
                .rotate(toAngle: -0.08, duration: 0.15),
                .rotate(toAngle: 0, duration: 0.15)
            ])
        case .celebrate:
            action = .sequence([
                .scale(to: 1.06, duration: 0.20),
                .scale(to: 1.0, duration: 0.20)
            ])
        case .react:
            action = .sequence([
                .rotate(toAngle: 0.07, duration: 0.15),
                .rotate(toAngle: 0, duration: 0.15)
            ])
        case .idle:
            action = .sequence([
                .moveBy(x: 0, y: 2, duration: 1.0),
                .moveBy(x: 0, y: -2, duration: 1.0)
            ])
        }
        sourceSprite.run(.repeatForever(action), withKey: "pose")
    }

    private func animatePlaceholderPose(_ pose: ArtSystem.Pose) {
        guard !reducedMotion else {
            bodyNode.setScale(1)
            bodyNode.position = .zero
            return
        }

        let action: SKAction
        switch pose {
        case .walk:
            action = .sequence([
                .moveBy(x: 0, y: 5, duration: 0.12),
                .moveBy(x: 0, y: -5, duration: 0.12)
            ])
        case .interact:
            action = .sequence([
                .rotate(toAngle: -0.12, duration: 0.15),
                .rotate(toAngle: 0, duration: 0.15)
            ])
        case .celebrate:
            action = .sequence([
                .scale(to: 1.06, duration: 0.20),
                .scale(to: 1, duration: 0.20)
            ])
        case .react:
            action = .sequence([
                .rotate(toAngle: 0.10, duration: 0.15),
                .rotate(toAngle: 0, duration: 0.15)
            ])
        case .idle:
            action = .sequence([
                .scaleY(to: 1.015, duration: 1),
                .scaleY(to: 1, duration: 1)
            ])
        }
        bodyNode.run(.repeatForever(action), withKey: "pose")
    }

    func walk(to destination: CGPoint, completion: @escaping () -> Void) {
        removeAction(forKey: "travel")
        pose(.walk)
        let distance = hypot(destination.x - position.x, destination.y - position.y)
        run(
            .sequence([
                .move(
                    to: destination,
                    duration: Double(distance / (reducedMotion ? 800 : 240))
                ),
                .run { [weak self] in
                    self?.pose(.idle)
                    completion()
                }
            ]),
            withKey: "travel"
        )
    }

    func cancelTravel() {
        removeAction(forKey: "travel")
        pose(.idle)
    }
}

@MainActor final class ValkyrieNode: CharacterNode {
    init() {
        super.init(character: "Valkyrie", color: .systemPink, height: 205)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }
}
