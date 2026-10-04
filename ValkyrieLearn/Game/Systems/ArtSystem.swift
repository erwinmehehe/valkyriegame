import SpriteKit

// Final art uses <character>.atlas with named <action>_01, _02... frames.
// This boundary is the only place gameplay needs to know whether an atlas exists.
@MainActor enum ArtSystem {
    enum Pose: String { case idle, walk, interact, celebrate, react }
    static func frames(character: String, pose: Pose) -> [SKTexture] {
        guard Bundle.main.url(forResource: character, withExtension: "atlasc") != nil
                || Bundle.main.url(forResource: character, withExtension: "atlas") != nil else { return [] }
        let atlas = SKTextureAtlas(named: character)
        return atlas.textureNames.filter { $0.hasPrefix(pose.rawValue + "_") }.sorted().map { atlas.textureNamed($0) }
    }
    static func label(_ text: String, size: CGFloat = 25) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text; label.fontSize = size; label.fontColor = .white
        label.verticalAlignmentMode = .center
        return label
    }
    static func box(_ size: CGSize, color: UIColor, radius: CGFloat = 12) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = color; node.strokeColor = color.withAlphaComponent(0.8)
        return node
    }
}
