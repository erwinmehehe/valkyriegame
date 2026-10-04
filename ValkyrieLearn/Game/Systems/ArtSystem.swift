import SpriteKit
import UIKit

// Final production art can still graduate to <character>.atlas with named
// <action>_01, _02... frames. Until then, this boundary also exposes selected
// source-derived v3.31 art so the native build keeps the game's established identity.
@MainActor enum ArtSystem {
    enum Pose: String { case idle, walk, interact, celebrate, react }

    struct Backdrop {
        let resource: String
        let ext: String
    }

    static func frames(character: String, pose: Pose) -> [SKTexture] {
        guard Bundle.main.url(forResource: character, withExtension: "atlasc") != nil
                || Bundle.main.url(forResource: character, withExtension: "atlas") != nil else { return [] }
        let atlas = SKTextureAtlas(named: character)
        return atlas.textureNames
            .filter { $0.hasPrefix(pose.rawValue + "_") }
            .sorted()
            .map { atlas.textureNamed($0) }
    }

    static func sourceTexture(resource: String, ext: String) -> SKTexture? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext),
              let image = UIImage(contentsOfFile: url.path) else {
            return nil
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    static func v331CharacterTexture(character: String, pose: Pose) -> SKTexture? {
        // Phase 1 imports Valkyrie's source art as a native texture rather than
        // decoding the old HTML/base64 asset system at runtime. A future atlas pass
        // can add pose frames without changing CharacterNode or learning logic.
        guard character == "Valkyrie" else { return nil }
        return sourceTexture(resource: "V331_Valkyrie_Idle", ext: "png")
    }

    static func backdropNode(_ backdrop: Backdrop, size: CGSize) -> SKSpriteNode? {
        guard let texture = sourceTexture(resource: backdrop.resource, ext: backdrop.ext) else {
            return nil
        }
        let sprite = SKSpriteNode(texture: texture)
        sprite.size = size
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sprite.zPosition = -120
        return sprite
    }

    static func label(_ text: String, size: CGFloat = 25) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text
        label.fontSize = size
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        return label
    }

    static func box(_ size: CGSize, color: UIColor, radius: CGFloat = 12) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = color
        node.strokeColor = color.withAlphaComponent(0.8)
        return node
    }
}
