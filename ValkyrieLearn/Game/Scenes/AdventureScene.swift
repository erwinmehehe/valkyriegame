import SpriteKit

@MainActor class AdventureScene: SKScene {
    let state: AppState
    let valkyrie = ValkyrieNode()
    let pip = PipNode()
    let instruction = ArtSystem.label("", size: 27)
    var walkable: CGRect { CGRect(x: 85, y: 130, width: 1110, height: 110) }
    var environment: ArtSystem.Environment { .castle }
    var worldTitle: String { "Math Castle" }
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
        buildWorld()
        valkyrie.position = CGPoint(x: 190, y: 170); pip.position = CGPoint(x: 380, y: 180)
        addChild(valkyrie); addChild(pip)
        instruction.position = CGPoint(x: 640, y: 48)
        instruction.name = "feedbackText"
        instruction.fontSize = 23
        instruction.fontColor = UIColor(red: 1, green: 0.96, blue: 0.83, alpha: 1)
        instruction.preferredMaxLayoutWidth = 940; instruction.numberOfLines = 2
        instruction.zPosition = 2000; addChild(instruction)
        let title = ArtSystem.label(worldTitle, size: 26)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 100, y: 669); title.zPosition = 2000; addChild(title)
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
        control.addChild(ArtSystem.label(text, size: 27)); addChild(control); return control
    }
    @discardableResult
    func worldGear(_ symbol: String, name: String, at point: CGPoint, radius: CGFloat = 33) -> SKNode {
        let gear = ArtSystem.gear(radius: radius, symbol: symbol)
        gear.position = point; gear.name = name; gear.zPosition = 750; addChild(gear); return gear
    }
    func hotspot(_ text: String, name: String, at point: CGPoint, size: CGSize = CGSize(width: 120, height: 64)) -> SKNode {
        let node = ArtSystem.box(size, color: .init(red: 0.40, green: 0.32, blue: 0.21, alpha: 1))
        node.name = name; node.position = point; node.zPosition = 740
        node.addChild(ArtSystem.label(text, size: 22)); addChild(node); return node
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
        let point = CGPoint(x: min(walkable.maxX, max(walkable.minX, destination.x)),
                            y: min(walkable.maxY, max(walkable.minY, destination.y)))
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
