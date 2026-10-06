import SpriteKit
import UIKit

@MainActor class AdventureScene: SKScene {
    let state: AppState
    let valkyrie = ValkyrieNode()
    let pip = PipNode()
    let instruction = ArtSystem.label("", size: 27)
    var walkable: CGRect { CGRect(x: 85, y: 130, width: 1110, height: 110) }
    var environment: ArtSystem.Environment { .castle }
    var worldTitle: String { "Math Castle" }

    /// Shared composition zones used by every native adventure scene.
    var interactionSafeZone: CGRect { CGRect(x: 430, y: 250, width: 720, height: 360) }
    var actorLane: CGRect { CGRect(x: 105, y: 125, width: 1060, height: 115) }
    var minimumTouchTarget: CGFloat { 52 }
    private var leaving = false
    var reducedMotion = false {
        didSet {
            valkyrie.reducedMotion = reducedMotion; pip.reducedMotion = reducedMotion
            valkyrie.pose(.idle); pip.pose(.idle)
        }
    }
    init(state: AppState) {
        self.state = state
        super.init(size: CGSize(width: 1280, height: 720))
        scaleMode = .aspectFit
        backgroundColor = UIColor(red: 0.12, green: 0.16, blue: 0.25, alpha: 1)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    override func didMove(to view: SKView) {
        guard children.isEmpty else { return }
        let camera = SKCameraNode(); camera.position = CGPoint(x: 640, y: 360)
        addChild(camera); self.camera = camera
        if !reducedMotion {
            camera.setScale(1.025)
            camera.run(.scale(to: 1.0, duration: 0.42), withKey: "sceneEntrance")
        }
        buildWorld()
        valkyrie.position = CGPoint(x: 190, y: 170); pip.position = CGPoint(x: 380, y: 180)
        addChild(valkyrie); addChild(pip)
        let instructionPlate = SKShapeNode(rectOf: CGSize(width: 920, height: 54), cornerRadius: 27)
        instructionPlate.fillColor = UIColor(red: 0.08, green: 0.06, blue: 0.16, alpha: 0.72)
        instructionPlate.strokeColor = UIColor(white: 1, alpha: 0.13)
        instructionPlate.lineWidth = 1
        instructionPlate.position = CGPoint(x: 640, y: 43)
        instructionPlate.name = "instructionPlate"
        instructionPlate.zPosition = 1998
        addChild(instructionPlate)

        instruction.position = CGPoint(x: 640, y: 37)
        instruction.name = "feedbackText"
        instruction.fontSize = 21
        instruction.fontColor = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
        instruction.preferredMaxLayoutWidth = 860; instruction.numberOfLines = 2
        instruction.zPosition = 2000; addChild(instruction)

        let title = ArtSystem.label(worldTitle, size: 23)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 92, y: 668); title.zPosition = 2000
        title.fontColor = UIColor(red: 1, green: 0.96, blue: 0.84, alpha: 0.94)
        addChild(title)
    }
    func buildWorld() {
        let asset = environment == .isles ? "StarlightIsles" : "MathCastle"
        if let backdrop = ArtSystem.sprite(asset, size: size) {
            backdrop.position = CGPoint(x: 640, y: 360); backdrop.zPosition = -100; addChild(backdrop)
        }
        // Reuse source foreground pixels as separate occluding layers.
        let prefix = environment == .isles ? "Isles" : "Castle"
        for (side, x) in [("Left", CGFloat(75)), ("Right", CGFloat(1205))] {
            if let foreground = ArtSystem.sprite(prefix + "Foreground" + side, size: CGSize(width: 150, height: 160)) {
                foreground.position = CGPoint(x: x, y: 80); foreground.zPosition = 1100; addChild(foreground)
            }
        }
        // A quiet edge vignette preserves text contrast without a floating panel.
        for (height, y) in [(CGFloat(62), CGFloat(680)), (CGFloat(96), CGFloat(42))] {
            let shade = ArtSystem.box(CGSize(width: 1280, height: height), color: .black.withAlphaComponent(0.32), radius: 0)
            shade.strokeColor = .clear
            shade.position = CGPoint(x: 640, y: y); shade.zPosition = 1990; addChild(shade)
        }
    }
    @discardableResult
    func worldControl(_ text: String, name: String, at point: CGPoint, radius: CGFloat = 29) -> SKNode {
        let control = SKShapeNode(circleOfRadius: radius)
        control.fillColor = .init(red: 0.12, green: 0.12, blue: 0.2, alpha: 0.65)
        control.strokeColor = .init(white: 1, alpha: 0.3); control.lineWidth = 1
        control.position = point; control.name = name; control.zPosition = 2000
        control.isAccessibilityElement = true
        control.accessibilityLabel = text == "‹" || text == "⌂" ? "Back" : text
        control.addChild(ArtSystem.label(text, size: 27)); addChild(control); return control
    }
    @discardableResult
    func worldGear(_ symbol: String, name: String, at point: CGPoint, radius: CGFloat = 33) -> SKNode {
        let gear = ArtSystem.gear(radius: radius, symbol: symbol)
        gear.position = point; gear.name = name; gear.zPosition = 750; addChild(gear); return gear
    }
    func hotspot(_ text: String, name: String, at point: CGPoint, size: CGSize = CGSize(width: 120, height: 64)) -> SKNode {
        let safeSize = CGSize(width: max(minimumTouchTarget, size.width),
                              height: max(minimumTouchTarget, size.height))
        let node = ArtSystem.box(
            safeSize,
            color: UIColor(red: 0.11, green: 0.08, blue: 0.20, alpha: 0.86),
            radius: min(22, safeSize.height / 2)
        )
        node.strokeColor = UIColor(red: 1.0, green: 0.83, blue: 0.40, alpha: 0.72)
        node.lineWidth = 2
        node.name = name; node.position = point; node.zPosition = 740
        node.isAccessibilityElement = true
        node.accessibilityLabel = text
        let label = ArtSystem.label(text, size: 20)
        label.fontColor = UIColor(red: 1.0, green: 0.96, blue: 0.84, alpha: 1)
        label.name = name
        node.addChild(label); addChild(node); return node
    }

    @discardableResult
    func landmark(_ text: String, symbol: String, name: String, at point: CGPoint,
                  accent: UIColor, width: CGFloat = 180) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 740
        root.isAccessibilityElement = true
        root.accessibilityLabel = text

        let glow = SKShapeNode(circleOfRadius: 31)
        glow.fillColor = accent.withAlphaComponent(0.14)
        glow.strokeColor = accent.withAlphaComponent(0.72)
        glow.lineWidth = 3
        glow.glowWidth = 8
        glow.name = name
        root.addChild(glow)

        let emblem = ArtSystem.label(symbol, size: 27)
        emblem.fontColor = UIColor(red: 1, green: 0.96, blue: 0.80, alpha: 1)
        emblem.name = name
        root.addChild(emblem)

        let labelPlate = ArtSystem.box(
            CGSize(width: max(120, width), height: minimumTouchTarget),
            color: UIColor(red: 0.08, green: 0.06, blue: 0.16, alpha: 0.72),
            radius: 18
        )
        labelPlate.strokeColor = accent.withAlphaComponent(0.40)
        labelPlate.lineWidth = 1
        labelPlate.position = CGPoint(x: width / 2 + 28, y: 0)
        labelPlate.name = name
        let label = ArtSystem.label(text, size: 18)
        label.fontColor = .white
        label.name = name
        labelPlate.addChild(label)
        root.addChild(labelPlate)

        addChild(root)
        return root
    }

    func tactileFeedback(success: Bool) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    func actorSafeDestination(near desired: CGPoint, avoiding protected: CGRect? = nil) -> CGPoint {
        var candidate = CGPoint(
            x: min(actorLane.maxX, max(actorLane.minX, desired.x)),
            y: min(actorLane.maxY, max(actorLane.minY, desired.y))
        )
        guard let protected, protected.insetBy(dx: -70, dy: -45).contains(candidate) else {
            return candidate
        }
        let expanded = protected.insetBy(dx: -95, dy: -55)
        let left = CGPoint(x: max(actorLane.minX, expanded.minX - 35), y: candidate.y)
        let right = CGPoint(x: min(actorLane.maxX, expanded.maxX + 35), y: candidate.y)
        candidate = abs(desired.x - left.x) <= abs(desired.x - right.x) ? left : right
        return candidate
    }
    func targetName(at point: CGPoint) -> String? {
        for hit in nodes(at: point) {
            var node: SKNode? = hit
            while let current = node {
                if let name = current.name { return name }
                node = current.parent
            }
        }
        return nil
    }
    func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        guard !leaving else { return }
        let uncluttered = actorSafeDestination(near: destination, avoiding: interactionSafeZone)
        let point = CGPoint(x: min(walkable.maxX, max(walkable.minX, uncluttered.x)),
                            y: min(walkable.maxY, max(walkable.minY, uncluttered.y)))
        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.leaving else { return }
            self.state.audio.play("footstep"); action?()
        }
        pip.walk(to: CGPoint(x: max(90, point.x - 105), y: point.y + 12)) {}
    }
    func isNear(_ point: CGPoint, radius: CGFloat = 85) -> Bool {
        hypot(valkyrie.position.x - point.x, valkyrie.position.y - point.y) <= radius
            && valkyrie.action(forKey: "travel") == nil
    }
    func walkIfValid(_ point: CGPoint) { if walkable.contains(point) { travel(to: point) } }
    func willLeave() {
        leaving = true
        enumerateChildNodes(withName: "//*") { node, _ in node.removeAllActions() }
        valkyrie.cancelTravel(); pip.cancelTravel(); removeAllActions(); state.persist()
    }
    override func update(_ currentTime: TimeInterval) {
        valkyrie.zPosition = 1000 - valkyrie.position.y
        pip.zPosition = 1000 - pip.position.y
    }
}
