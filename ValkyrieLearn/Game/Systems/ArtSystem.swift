import SpriteKit

// Final art uses <character>.atlas with named <action>_01, _02... frames.
// This boundary is the only place gameplay needs to know whether an atlas exists.
@MainActor enum ArtSystem {
    enum Pose: String { case idle, walk, interact, celebrate, react }
    enum Environment { case isles, castle }
    private static var atlasCache: [String: SKTextureAtlas] = [:]
    private static var textureCache: [String: SKTexture] = [:]
    private static var frameCache: [String: [SKTexture]] = [:]
    static func frames(character: String, pose: Pose) -> [SKTexture] {
        let key = character + "|" + pose.rawValue
        if let cached = frameCache[key] { return cached }

        let hasAtlas = Bundle.main.url(forResource: character, withExtension: "atlasc") != nil
            || Bundle.main.url(forResource: character, withExtension: "atlas") != nil

        let frames: [SKTexture]
        if !hasAtlas {
            frames = texture(character).map { [$0] } ?? []
        } else {
            let atlas = atlasCache[character] ?? SKTextureAtlas(named: character)
            atlasCache[character] = atlas
            frames = atlas.textureNames
                .filter { $0.hasPrefix(pose.rawValue + "_") }
                .sorted()
                .map {
                    let texture = atlas.textureNamed($0)
                    texture.filteringMode = .linear
                    return texture
                }
        }

        frameCache[key] = frames
        return frames
    }
    static func texture(_ name: String) -> SKTexture? {
        if let cached = textureCache[name] { return cached }
        let image = UIImage(named: name) ?? Bundle.main.url(forResource: name, withExtension: "webp")
            .flatMap { UIImage(contentsOfFile: $0.path) }
        guard let image else { return nil }
        let texture = SKTexture(image: image); texture.filteringMode = .linear
        textureCache[name] = texture
        return texture
    }
    static func sprite(_ name: String, size: CGSize) -> SKSpriteNode? {
        guard let texture = texture(name) else { return nil }
        return SKSpriteNode(texture: texture, color: .white, size: size)
    }

    static func pixelSize(_ name: String) -> CGSize? {
        let image = UIImage(named: name) ?? Bundle.main.url(forResource: name, withExtension: "webp")
            .flatMap { UIImage(contentsOfFile: $0.path) }
        guard let cgImage = image?.cgImage else { return nil }
        return CGSize(width: cgImage.width, height: cgImage.height)
    }

    static func sourceScale(for name: String, targetPoints: CGSize) -> CGFloat? {
        guard let pixels = pixelSize(name), targetPoints.width > 0, targetPoints.height > 0 else { return nil }
        return min(pixels.width / targetPoints.width, pixels.height / targetPoints.height)
    }

    static func isRetinaReady(
        _ name: String,
        targetPoints: CGSize,
        minimumScale: CGFloat = 2
    ) -> Bool {
        guard let scale = sourceScale(for: name, targetPoints: targetPoints) else { return false }
        return scale >= minimumScale
    }
    static func gear(radius: CGFloat, symbol: String = "") -> SKNode {
        let node = SKNode()
        if let face = sprite("BridgeDial", size: CGSize(width: radius * 2, height: radius * 2)) {
            node.addChild(face)
            if !symbol.isEmpty { node.addChild(label(symbol, size: radius * 0.75)) }
            return node
        }
        let path = CGMutablePath()
        for index in 0..<48 {
            let angle = CGFloat(index) * .pi / 24
            let r = radius * (index % 4 < 2 ? 1 : 0.84)
            let point = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        let teeth = SKShapeNode(path: path)
        teeth.fillColor = UIColor(red: 0.71, green: 0.44, blue: 0.16, alpha: 1)
        teeth.strokeColor = UIColor(red: 1, green: 0.81, blue: 0.38, alpha: 1); teeth.lineWidth = 3
        node.addChild(teeth)
        let hub = SKShapeNode(circleOfRadius: radius * 0.64)
        hub.fillColor = UIColor(red: 0.12, green: 0.23, blue: 0.29, alpha: 1)
        hub.strokeColor = .init(red: 1, green: 0.78, blue: 0.35, alpha: 1); hub.lineWidth = 2
        node.addChild(hub)
        if !symbol.isEmpty { node.addChild(label(symbol, size: radius * 0.75)) }
        return node
    }
    static func label(_ text: String, size: CGFloat = 25) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        label.text = text; label.fontSize = size; label.fontColor = .white
        label.verticalAlignmentMode = .center
        return label
    }
    static func supplyTray(_ size: CGSize) -> SKShapeNode {
        // Keep the full native touch surface; the raised frame is only decoration.
        let tray = box(size, color: .init(red: 0.29, green: 0.20, blue: 0.14, alpha: 1), radius: 3)
        guard let floor = texture("BridgeOakPlank"), let timber = texture("BridgeTimber") else { return tray }
        tray.fillColor = .white; tray.fillTexture = floor; tray.strokeColor = .clear
        let railWidth: CGFloat = 10
        for x in [-size.width / 2 + railWidth / 2, size.width / 2 - railWidth / 2] {
            let rail = SKSpriteNode(texture: timber, color: .white, size: CGSize(width: railWidth, height: size.height))
            rail.position.x = x; tray.addChild(rail)
        }
        for y in [-size.height / 2 + railWidth / 2, size.height / 2 - railWidth / 2] {
            let rail = SKSpriteNode(texture: timber, color: .white, size: CGSize(width: railWidth, height: size.width))
            rail.zRotation = .pi / 2; rail.position.y = y; tray.addChild(rail)
        }
        return tray
    }
    static func box(_ size: CGSize, color: UIColor, radius: CGFloat = 12) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = color; node.strokeColor = color.withAlphaComponent(color.cgColor.alpha * 0.8)
        return node
    }
}
