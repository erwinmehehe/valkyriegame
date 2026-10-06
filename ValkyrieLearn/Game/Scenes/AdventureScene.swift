import SpriteKit
import UIKit

struct AdventureSceneLayout {
    let size: CGSize

    var topHUD: CGRect {
        CGRect(x: 24, y: size.height - 78, width: size.width - 48, height: 58)
    }

    var instructionZone: CGRect {
        CGRect(x: 170, y: 18, width: size.width - 340, height: 66)
    }

    var actorLane: CGRect {
        CGRect(x: 90, y: 118, width: size.width - 180, height: 150)
    }

    var interactionStage: CGRect {
        CGRect(x: 360, y: 250, width: size.width - 430, height: 360)
    }

    var destinationRail: CGRect {
        CGRect(x: size.width - 260, y: 118, width: 220, height: 500)
    }

    func clampedToActorLane(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(actorLane.maxX, max(actorLane.minX, point.x)),
            y: min(actorLane.maxY, max(actorLane.minY, point.y))
        )
    }

    /// Aspect-fit frame used by the 1280x720 design canvas inside any landscape iPad view.
    /// Tests exercise common 4:3, 1.44:1 and 16:9 surfaces so HUD and touch geometry
    /// remain visible even when SpriteKit letterboxes the design canvas.
    func fittedFrame(in viewSize: CGSize) -> CGRect {
        guard viewSize.width > 0, viewSize.height > 0 else { return .zero }
        let scale = min(viewSize.width / size.width, viewSize.height / size.height)
        let fitted = CGSize(width: size.width * scale, height: size.height * scale)
        return CGRect(
            x: (viewSize.width - fitted.width) / 2,
            y: (viewSize.height - fitted.height) / 2,
            width: fitted.width,
            height: fitted.height
        )
    }
}

@MainActor class AdventureScene: SKScene {
    let state: AppState
    let valkyrie = ValkyrieNode()
    let pip = PipNode()
    let instruction = ArtSystem.label("", size: 27)
    let layout = AdventureSceneLayout(size: CGSize(width: 1280, height: 720))

    var walkable: CGRect { layout.actorLane }
    var environment: ArtSystem.Environment { .castle }
    var worldTitle: String { "Math Castle" }

    private var leaving = false
    private var registeredInteractionZones: [CGRect] = []
    private weak var instructionBackdrop: SKShapeNode?
    private weak var titleBackdrop: SKShapeNode?

    var reducedMotion = false {
        didSet {
            valkyrie.reducedMotion = reducedMotion
            pip.reducedMotion = reducedMotion
            valkyrie.pose(.idle)
            pip.pose(.idle)
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

        view.isMultipleTouchEnabled = false
        view.shouldCullNonVisibleNodes = true

        let camera = SKCameraNode()
        camera.position = CGPoint(x: 640, y: 360)
        camera.name = "adventureCamera"
        addChild(camera)
        self.camera = camera

        buildWorld()

        valkyrie.position = CGPoint(x: 190, y: 170)
        pip.position = CGPoint(x: 380, y: 180)
        addChild(valkyrie)
        addChild(pip)

        buildHUD()
        runEntranceAnimation()
    }

    private func buildHUD() {
        let titlePlate = SKShapeNode(
            rectOf: CGSize(width: 350, height: 50),
            cornerRadius: 25
        )
        titlePlate.fillColor = UIColor(red: 0.08, green: 0.07, blue: 0.15, alpha: 0.58)
        titlePlate.strokeColor = UIColor(white: 1, alpha: 0.13)
        titlePlate.lineWidth = 1
        titlePlate.position = CGPoint(x: 215, y: 669)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)
        titleBackdrop = titlePlate

        let title = ArtSystem.label(worldTitle, size: 24)
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: 66, y: 669)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        let instructionPlate = SKShapeNode(
            rectOf: CGSize(width: layout.instructionZone.width, height: 56),
            cornerRadius: 28
        )
        instructionPlate.fillColor = UIColor(red: 0.07, green: 0.06, blue: 0.14, alpha: 0.56)
        instructionPlate.strokeColor = UIColor(white: 1, alpha: 0.12)
        instructionPlate.lineWidth = 1
        instructionPlate.position = CGPoint(x: 640, y: 48)
        instructionPlate.zPosition = 1988
        instructionPlate.name = "instructionBackdrop"
        addChild(instructionPlate)
        instructionBackdrop = instructionPlate

        instruction.position = CGPoint(x: 640, y: 48)
        instruction.name = "feedbackText"
        instruction.fontSize = 22
        instruction.fontColor = UIColor(red: 1, green: 0.97, blue: 0.87, alpha: 1)
        instruction.preferredMaxLayoutWidth = layout.instructionZone.width - 50
        instruction.numberOfLines = 2
        instruction.zPosition = 2000
        addChild(instruction)
    }

    func buildWorld() {
        let asset = environment == .isles ? "StarlightIsles" : "MathCastle"
        if let backdrop = ArtSystem.sprite(asset, size: size) {
            backdrop.position = CGPoint(x: 640, y: 360)
            backdrop.zPosition = -100
            backdrop.name = "worldBackdrop"
            addChild(backdrop)
        }

        let prefix = environment == .isles ? "Isles" : "Castle"
        for (side, x) in [("Left", CGFloat(75)), ("Right", CGFloat(1205))] {
            if let foreground = ArtSystem.sprite(
                prefix + "Foreground" + side,
                size: CGSize(width: 150, height: 160)
            ) {
                foreground.position = CGPoint(x: x, y: 80)
                foreground.zPosition = 1100
                foreground.name = "foreground" + side
                addChild(foreground)
            }
        }

        let topShade = ArtSystem.box(
            CGSize(width: 1280, height: 86),
            color: .black.withAlphaComponent(0.12),
            radius: 0
        )
        topShade.strokeColor = .clear
        topShade.position = CGPoint(x: 640, y: 688)
        topShade.zPosition = 1975
        topShade.name = "topVignette"
        addChild(topShade)
    }

    func runEntranceAnimation() {
        guard !reducedMotion else { return }
        childNode(withName: "worldBackdrop")?.alpha = 0.72
        childNode(withName: "worldBackdrop")?.run(.fadeAlpha(to: 1, duration: 0.34))
        valkyrie.alpha = 0
        pip.alpha = 0
        valkyrie.run(.sequence([
            .wait(forDuration: 0.06),
            .fadeIn(withDuration: 0.24)
        ]))
        pip.run(.sequence([
            .wait(forDuration: 0.14),
            .fadeIn(withDuration: 0.24)
        ]))
    }

    @discardableResult
    func worldControl(
        _ text: String,
        name: String,
        at point: CGPoint,
        radius: CGFloat = 30,
        accessibilityLabel: String? = nil
    ) -> SKNode {
        let touchRadius = max(30, radius)
        let control = SKShapeNode(circleOfRadius: touchRadius)
        control.fillColor = UIColor(red: 0.10, green: 0.09, blue: 0.19, alpha: 0.72)
        control.strokeColor = UIColor(white: 1, alpha: 0.34)
        control.lineWidth = 1.5
        control.position = point
        control.name = name
        control.zPosition = 2000
        control.addChild(ArtSystem.label(text, size: 26))
        makeAccessible(control, label: accessibilityLabel ?? text)
        addChild(control)
        return control
    }

    @discardableResult
    func worldGear(
        _ symbol: String,
        name: String,
        at point: CGPoint,
        radius: CGFloat = 33,
        accessibilityLabel: String? = nil
    ) -> SKNode {
        let gear = ArtSystem.gear(radius: max(30, radius), symbol: symbol)
        gear.position = point
        gear.name = name
        gear.zPosition = 750
        makeAccessible(gear, label: accessibilityLabel ?? symbol)
        registerInteraction(gear, clearance: 22)
        addChild(gear)
        return gear
    }

    @discardableResult
    func hotspot(
        _ text: String,
        name: String,
        at point: CGPoint,
        size requestedSize: CGSize = CGSize(width: 120, height: 64)
    ) -> SKNode {
        let size = CGSize(width: max(60, requestedSize.width), height: max(60, requestedSize.height))
        let node = ArtSystem.box(
            size,
            color: UIColor(red: 0.14, green: 0.12, blue: 0.24, alpha: 0.88),
            radius: min(24, size.height * 0.38)
        )
        node.strokeColor = UIColor(white: 1, alpha: 0.25)
        node.lineWidth = 1.5
        node.name = name
        node.position = point
        node.zPosition = 740
        let label = ArtSystem.label(text, size: min(21, size.height * 0.34))
        label.name = name
        node.addChild(label)
        makeAccessible(node, label: text)
        registerInteraction(node, clearance: 20)
        addChild(node)
        return node
    }

    @discardableResult
    func destinationMarker(
        _ title: String,
        symbol: String,
        name: String,
        at point: CGPoint,
        tint: UIColor,
        width: CGFloat = 168,
        plaqueOffsetY: CGFloat = -58
    ) -> SKNode {
        let root = SKNode()
        root.name = name
        root.position = point
        root.zPosition = 760

        let halo = SKShapeNode(circleOfRadius: 34)
        halo.fillColor = tint.withAlphaComponent(0.16)
        halo.strokeColor = tint.withAlphaComponent(0.72)
        halo.lineWidth = 2
        halo.glowWidth = 8
        halo.name = name
        root.addChild(halo)

        let emblem = ArtSystem.label(symbol, size: 31)
        emblem.fontColor = .white
        emblem.name = name
        root.addChild(emblem)

        let plaque = SKShapeNode(
            rectOf: CGSize(width: max(120, width), height: 44),
            cornerRadius: 22
        )
        plaque.fillColor = UIColor(red: 0.08, green: 0.07, blue: 0.15, alpha: 0.68)
        plaque.strokeColor = tint.withAlphaComponent(0.65)
        plaque.lineWidth = 1.5
        plaque.position = CGPoint(x: 0, y: plaqueOffsetY)
        plaque.name = name
        plaque.userData = NSMutableDictionary(dictionary: ["destinationRole": "plaque"])
        root.addChild(plaque)

        let label = ArtSystem.label(title, size: 17)
        label.fontColor = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
        label.name = name
        plaque.addChild(label)

        makeAccessible(root, label: title)
        addChild(root)
        registerInteraction(root, clearance: 24)

        if !reducedMotion {
            halo.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.58, duration: 1.2),
                .fadeAlpha(to: 1, duration: 1.2)
            ])))
        }
        return root
    }

    func targetName(at point: CGPoint) -> String? {
        // SpriteKit does not guarantee that nodes(at:) is returned in visual order.
        // Resolve the highest rendered named ancestor so a full-screen backdrop can
        // never steal a tap from an in-world control layered above it.
        var best: (name: String, score: CGFloat, depth: Int)?

        for hit in nodes(at: point) {
            var node: SKNode? = hit
            var depth = 0
            while let current = node, current !== self {
                if let name = current.name, !name.isEmpty {
                    var score = current.zPosition
                    var ancestor = current.parent
                    while let parent = ancestor, parent !== self {
                        score += parent.zPosition
                        ancestor = parent.parent
                    }
                    if best == nil
                        || score > best!.score
                        || (score == best!.score && depth < best!.depth) {
                        best = (name, score, depth)
                    }
                }
                depth += 1
                node = current.parent
            }
        }
        return best?.name
    }

    func registerInteraction(_ node: SKNode, clearance: CGFloat = 18) {
        let frame = node.calculateAccumulatedFrame().insetBy(dx: -clearance, dy: -clearance)
        guard !frame.isNull, !frame.isInfinite else { return }
        registeredInteractionZones.append(frame)
    }

    func registerInteractionZone(_ rect: CGRect) {
        registeredInteractionZones.append(rect)
    }

    func clearRegisteredInteractionZones() {
        registeredInteractionZones.removeAll(keepingCapacity: true)
    }

    func safeActorPoint(
        near desired: CGPoint,
        avoiding extraZones: [CGRect] = []
    ) -> CGPoint {
        let combined = registeredInteractionZones + extraZones
        let candidates: [CGFloat] = [0, -115, 115, -165, 165, -220, 220, -280, 280]
        let rendered = valkyrie.calculateAccumulatedFrame()
        let actorFootprint = CGSize(
            width: max(110, rendered.width * 0.88),
            height: max(150, rendered.height * 0.88)
        )

        for offset in candidates {
            let candidate = CGPoint(x: desired.x + offset, y: desired.y)
            let clamped = CGPoint(
                x: min(walkable.maxX, max(walkable.minX, candidate.x)),
                y: min(walkable.maxY, max(walkable.minY, candidate.y))
            )
            let frame = CGRect(
                x: clamped.x - actorFootprint.width / 2,
                y: clamped.y - 8,
                width: actorFootprint.width,
                height: actorFootprint.height
            )
            if !combined.contains(where: { $0.intersects(frame) }) {
                return clamped
            }
        }
        return CGPoint(
            x: min(walkable.maxX, max(walkable.minX, desired.x)),
            y: min(walkable.maxY, max(walkable.minY, desired.y))
        )
    }

    func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        guard !leaving else { return }
        let desired = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )
        let point = safeActorPoint(near: desired)

        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.leaving else { return }
            self.state.audio.play("footstep")
            action?()
        }

        let buddyPoint = CGPoint(
            x: max(walkable.minX, point.x - 105),
            y: min(walkable.maxY, point.y + 12)
        )
        pip.walk(to: buddyPoint) {}
    }

    func focusCamera(on point: CGPoint, duration: TimeInterval = 0.25) {
        guard !reducedMotion, let camera else { return }
        let target = CGPoint(
            x: min(690, max(590, 640 + (point.x - 640) * 0.08)),
            y: min(390, max(340, 360 + (point.y - 360) * 0.06))
        )
        camera.removeAction(forKey: "focus")
        camera.run(.move(to: target, duration: duration), withKey: "focus")
    }

    func resetCamera(duration: TimeInterval = 0.25) {
        guard let camera else { return }
        if reducedMotion {
            camera.position = CGPoint(x: 640, y: 360)
        } else {
            camera.run(.move(to: CGPoint(x: 640, y: 360), duration: duration), withKey: "focus")
        }
    }

    func focusMoment(on point: CGPoint, hold: TimeInterval = 0.45) {
        guard !reducedMotion else { return }
        focusCamera(on: point, duration: 0.20)
        removeAction(forKey: "cameraReset")
        run(.sequence([
            .wait(forDuration: hold),
            .run { [weak self] in self?.resetCamera(duration: 0.28) }
        ]), withKey: "cameraReset")
    }

    func successFeedback() {
        state.audio.play("success")
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    func errorFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    func selectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    func isNear(_ point: CGPoint, radius: CGFloat = 85) -> Bool {
        hypot(valkyrie.position.x - point.x, valkyrie.position.y - point.y) <= radius
            && valkyrie.action(forKey: "travel") == nil
    }

    func walkIfValid(_ point: CGPoint) {
        if walkable.contains(point) { travel(to: point) }
    }

    func willLeave() {
        leaving = true
        enumerateChildNodes(withName: "//*") { node, _ in
            node.removeAllActions()
        }
        valkyrie.cancelTravel()
        pip.cancelTravel()
        removeAllActions()
        state.persist()
    }

    func makeAccessible(_ node: SKNode, label: String, hint: String? = nil) {
        node.isAccessibilityElement = true
        node.accessibilityLabel = label
        node.accessibilityTraits = .button
        if let hint { node.accessibilityHint = hint }
    }

    override func update(_ currentTime: TimeInterval) {
        valkyrie.zPosition = 1000 - valkyrie.position.y
        pip.zPosition = 1000 - pip.position.y
    }
}
