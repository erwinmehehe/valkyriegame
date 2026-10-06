import SpriteKit
import CoreImage
import UIKit

// Final art uses <character>.atlas with named <action>_01, _02... frames.
// This boundary is the only place gameplay needs to know whether an atlas exists.
@MainActor enum ArtSystem {
    enum Pose: String { case idle, walk, interact, celebrate, react }
    enum Environment { case isles, castle }
    private static var atlasCache: [String: SKTextureAtlas] = [:]
    private static var textureCache: [String: SKTexture] = [:]
    private static var retinaTextureCache: [String: SKTexture] = [:]
    private static var frameCache: [String: [SKTexture]] = [:]
    private static let imageContext = CIContext()
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

    /// Builds a cached Retina-sized texture from approved source art without
    /// replacing the illustration with synthetic geometry. This is an enhancement
    /// path for legacy 1x paintings: high-quality resampling supplies the physical
    /// pixel density and a restrained luminance sharpen restores edge separation.
    /// It does not claim to create new source detail.
    static func retinaEnhancedTexture(
        _ name: String,
        targetPoints: CGSize,
        minimumScale: CGFloat = 2,
        sharpness: CGFloat = 0.28
    ) -> SKTexture? {
        guard targetPoints.width > 0, targetPoints.height > 0, minimumScale >= 1 else {
            return texture(name)
        }

        let key = [
            name,
            String(Int(targetPoints.width.rounded())),
            String(Int(targetPoints.height.rounded())),
            String(format: "%.2f", minimumScale),
            String(format: "%.2f", sharpness)
        ].joined(separator: "|")
        if let cached = retinaTextureCache[key] { return cached }

        let source = UIImage(named: name) ?? Bundle.main.url(
            forResource: name,
            withExtension: "webp"
        ).flatMap { UIImage(contentsOfFile: $0.path) }
        guard let sourceImage = source?.cgImage else { return texture(name) }

        let targetWidth = max(
            sourceImage.width,
            Int(ceil(targetPoints.width * minimumScale))
        )
        let targetHeight = max(
            sourceImage.height,
            Int(ceil(targetPoints.height * minimumScale))
        )

        if sourceImage.width >= targetWidth, sourceImage.height >= targetHeight {
            return texture(name)
        }

        guard let bitmap = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return texture(name)
        }

        bitmap.interpolationQuality = .high
        bitmap.draw(
            sourceImage,
            in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        )
        guard var prepared = bitmap.makeImage() else { return texture(name) }

        if sharpness > 0,
           let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(CIImage(cgImage: prepared), forKey: kCIInputImageKey)
            filter.setValue(min(0.65, sharpness), forKey: kCIInputSharpnessKey)
            if let output = filter.outputImage,
               let sharpened = imageContext.createCGImage(output, from: output.extent) {
                prepared = sharpened
            }
        }

        let image = UIImage(
            cgImage: prepared,
            scale: minimumScale,
            orientation: .up
        )
        let enhanced = SKTexture(image: image)
        enhanced.filteringMode = .linear
        retinaTextureCache[key] = enhanced
        return enhanced
    }

    /// Retina-prepares an already cropped/sub-texture source. This is used for
    /// approved atlas regions that do not exist as standalone asset-catalog images.
    static func retinaEnhancedTexture(
        _ source: SKTexture,
        cacheKey: String,
        targetPoints: CGSize,
        minimumScale: CGFloat = 2,
        sharpness: CGFloat = 0.24
    ) -> SKTexture? {
        guard targetPoints.width > 0, targetPoints.height > 0, minimumScale >= 1 else {
            return source
        }

        let key = [
            "subtexture",
            cacheKey,
            String(Int(targetPoints.width.rounded())),
            String(Int(targetPoints.height.rounded())),
            String(format: "%.2f", minimumScale),
            String(format: "%.2f", sharpness)
        ].joined(separator: "|")
        if let cached = retinaTextureCache[key] { return cached }

        let sourceImage = source.cgImage()
        let targetWidth = max(
            sourceImage.width,
            Int(ceil(targetPoints.width * minimumScale))
        )
        let targetHeight = max(
            sourceImage.height,
            Int(ceil(targetPoints.height * minimumScale))
        )

        if sourceImage.width >= targetWidth, sourceImage.height >= targetHeight {
            source.filteringMode = .linear
            retinaTextureCache[key] = source
            return source
        }

        guard let bitmap = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: targetWidth * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return source
        }

        bitmap.interpolationQuality = .high
        bitmap.draw(
            sourceImage,
            in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        )
        guard var prepared = bitmap.makeImage() else { return source }

        if sharpness > 0,
           let filter = CIFilter(name: "CISharpenLuminance") {
            filter.setValue(CIImage(cgImage: prepared), forKey: kCIInputImageKey)
            filter.setValue(min(0.55, sharpness), forKey: kCIInputSharpnessKey)
            if let output = filter.outputImage,
               let sharpened = imageContext.createCGImage(output, from: output.extent) {
                prepared = sharpened
            }
        }

        let image = UIImage(
            cgImage: prepared,
            scale: minimumScale,
            orientation: .up
        )
        let enhanced = SKTexture(image: image)
        enhanced.filteringMode = .linear
        retinaTextureCache[key] = enhanced
        return enhanced
    }

    static func retinaEnhancedSprite(
        _ name: String,
        size: CGSize,
        minimumScale: CGFloat = 2,
        sharpness: CGFloat = 0.28
    ) -> SKSpriteNode? {
        guard let texture = retinaEnhancedTexture(
            name,
            targetPoints: size,
            minimumScale: minimumScale,
            sharpness: sharpness
        ) else { return nil }
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
    static func paintedBackdrop(
        _ asset: String,
        size: CGSize,
        tint: UIColor = .white,
        blend: CGFloat = 0,
        dim: CGFloat = 0
    ) -> SKNode? {
        guard let texture = texture(asset) else { return nil }
        let root = SKNode()

        let sprite = SKSpriteNode(texture: texture, color: tint, size: size)
        sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        sprite.colorBlendFactor = max(0, min(1, blend))
        sprite.name = "paintedBackdrop"
        root.addChild(sprite)

        if dim > 0 {
            let wash = box(
                size,
                color: UIColor(white: 0.02, alpha: max(0, min(0.8, dim))),
                radius: 0
            )
            wash.strokeColor = .clear
            wash.position = CGPoint(x: size.width / 2, y: size.height / 2)
            wash.zPosition = 1
            root.addChild(wash)
        }

        return root
    }

    static func panel(
        _ size: CGSize,
        fill: UIColor,
        stroke: UIColor,
        radius: CGFloat = 18,
        lineWidth: CGFloat = 3,
        shadowAlpha: CGFloat = 0.28,
        innerHighlight: UIColor? = nil
    ) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth

        if shadowAlpha > 0 {
            let shadow = SKShapeNode(rectOf: size, cornerRadius: radius)
            shadow.fillColor = UIColor(white: 0, alpha: shadowAlpha)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -7)
            shadow.zPosition = -3
            node.addChild(shadow)
        }

        let highlight = SKShapeNode(
            rectOf: CGSize(
                width: max(8, size.width - 10),
                height: max(8, size.height - 10)
            ),
            cornerRadius: max(4, radius - 5)
        )
        highlight.fillColor = .clear
        highlight.strokeColor = innerHighlight ?? UIColor(white: 1, alpha: 0.10)
        highlight.lineWidth = 1
        highlight.zPosition = 2
        node.addChild(highlight)
        return node
    }

    static func medallion(
        radius: CGFloat,
        fill: UIColor,
        stroke: UIColor,
        glow: CGFloat = 0
    ) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = 3
        node.glowWidth = glow

        let inset = SKShapeNode(circleOfRadius: max(4, radius - 7))
        inset.fillColor = .clear
        inset.strokeColor = UIColor(white: 1, alpha: 0.13)
        inset.lineWidth = 1
        inset.zPosition = 2
        node.addChild(inset)

        let shadow = SKShapeNode(circleOfRadius: radius)
        shadow.fillColor = UIColor(white: 0, alpha: 0.24)
        shadow.strokeColor = .clear
        shadow.position.y = -6
        shadow.zPosition = -2
        node.addChild(shadow)
        return node
    }

    static func plaque(
        _ size: CGSize,
        fill: UIColor,
        stroke: UIColor,
        radius: CGFloat = 16
    ) -> SKShapeNode {
        panel(
            size,
            fill: fill,
            stroke: stroke,
            radius: radius,
            lineWidth: 3,
            shadowAlpha: 0.24,
            innerHighlight: UIColor(white: 1, alpha: 0.12)
        )
    }

    static func box(_ size: CGSize, color: UIColor, radius: CGFloat = 12) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = color; node.strokeColor = color.withAlphaComponent(color.cgColor.alpha * 0.8)
        return node
    }
}
