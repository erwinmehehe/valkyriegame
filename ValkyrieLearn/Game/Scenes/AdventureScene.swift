import SpriteKit
import UIKit

/// A tap owns one contact and stays cancelled once that contact becomes a swipe.
/// Kept independent of UITouch so interruption and extra-contact handling can be tested.
struct SceneTapGesture<Contact: Hashable> {
    private var contact: Contact?
    private var start = CGPoint.zero
    private var moved = false

    mutating func begin(_ contact: Contact, at point: CGPoint) {
        guard self.contact == nil else { return }
        self.contact = contact
        start = point
        moved = false
    }

    mutating func move(_ contact: Contact, to point: CGPoint) {
        guard self.contact == contact else { return }
        if hypot(point.x - start.x, point.y - start.y) > 12 { moved = true }
    }

    mutating func end(_ contact: Contact, at point: CGPoint) -> CGPoint? {
        guard self.contact == contact else { return nil }
        move(contact, to: point)
        defer { reset() }
        return moved ? nil : point
    }

    mutating func cancel(_ contact: Contact) {
        if self.contact == contact { reset() }
    }

    mutating func reset() {
        contact = nil
        moved = false
    }
}

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

    /// Gameplay stays on its original canvas; taller iPads gain space for HUD chrome.
    var designCanvasSize: CGSize { layout.size }
    var verticalViewportInset: CGFloat { max(0, (size.height - designCanvasSize.height) / 2) }

    func prepareAdaptiveLandscapeCanvas(for view: SKView) {
        guard children.isEmpty, view.bounds.width > 0, view.bounds.height > 0 else { return }
        let height = designCanvasSize.width * view.bounds.height / view.bounds.width
        size = CGSize(width: designCanvasSize.width, height: max(designCanvasSize.height, min(960, height)))
    }

    var walkable: CGRect { layout.actorLane }
    var environment: ArtSystem.Environment { .castle }
    var worldTitle: String { "Math Castle" }

    private final class InteractionRegistration {
        weak var node: SKNode?
        let clearance: CGFloat

        init(node: SKNode, clearance: CGFloat) {
            self.node = node
            self.clearance = clearance
        }
    }

    private var leaving = false
    private var tapGesture = SceneTapGesture<ObjectIdentifier>()
    private var attentionCue: (point: CGPoint, tint: UIColor?, width: CGFloat)?
    private var registeredInteractionZones: [CGRect] = []
    private var interactionRegistrations: [InteractionRegistration] = []
    private weak var instructionBackdrop: SKShapeNode?
    private weak var titleBackdrop: SKShapeNode?
    private let successHaptic = UINotificationFeedbackGenerator()
    private let errorHaptic = UINotificationFeedbackGenerator()
    private let selectionHaptic = UISelectionFeedbackGenerator()

    var reducedMotion = false {
        didSet {
            valkyrie.reducedMotion = reducedMotion
            pip.reducedMotion = reducedMotion
            enumerateChildNodes(withName: "//*") { [self] node, _ in
                // Every world companion must use the same live preference.
                if let character = node as? CharacterNode {
                    character.reducedMotion = reducedMotion
                }
            }
            syncDecorativeMotion()
            if reducedMotion {
                removeAction(forKey: "cameraReset")
                camera?.removeAction(forKey: "focus")
                camera?.position = CGPoint(x: 640, y: 360)
            }
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
        successHaptic.prepare()
        errorHaptic.prepare()
        selectionHaptic.prepare()

        let camera = SKCameraNode()
        camera.position = CGPoint(x: 640, y: 360)
        camera.name = "adventureCamera"
        addChild(camera)
        self.camera = camera

        buildWorld()
        syncDecorativeMotion()

        valkyrie.position = CGPoint(x: 190, y: 170)
        pip.position = CGPoint(x: 380, y: 180)
        addChild(valkyrie)
        addChild(pip)

        buildHUD()
        runEntranceAnimation()
    }

    private func buildHUD() {
        let titleLeft: CGFloat = 88
        let titleWidth = min(
            CGFloat(520),
            max(CGFloat(350), CGFloat(worldTitle.count) * 11.5 + 110)
        )
        let titlePlate = ArtSystem.panel(
            CGSize(width: titleWidth, height: 50),
            fill: UIColor(red: 0.055, green: 0.05, blue: 0.11, alpha: 0.82),
            stroke: ambientTint.withAlphaComponent(0.48),
            radius: 25,
            lineWidth: 1.5,
            shadowAlpha: 0.30
        )
        titlePlate.position = CGPoint(x: titleLeft + titleWidth / 2, y: 669)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)
        titleBackdrop = titlePlate

        let emblem = ArtSystem.medallion(
            radius: 17,
            fill: ambientTint.withAlphaComponent(0.16),
            stroke: ambientTint.withAlphaComponent(0.72),
            glow: 0
        )
        emblem.name = "decorativeWorldEmblem"
        emblem.position = CGPoint(x: titleLeft + 26, y: 669)
        emblem.zPosition = 1995
        let mark = ArtSystem.label(worldEmblem, size: 20)
        mark.fontColor = ambientTint
        emblem.addChild(mark)
        addChild(emblem)

        let title = ArtSystem.label(worldTitle, size: worldTitle.count > 28 ? 21 : 24)
        title.horizontalAlignmentMode = .left
        title.verticalAlignmentMode = .center
        title.position = CGPoint(x: titleLeft + 52, y: 669)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        let instructionPlate = ArtSystem.panel(
            CGSize(width: layout.instructionZone.width, height: 56),
            fill: UIColor(red: 0.045, green: 0.045, blue: 0.095, alpha: 0.84),
            stroke: ambientTint.withAlphaComponent(0.32),
            radius: 28,
            lineWidth: 1.5,
            shadowAlpha: 0.32
        )
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

        for (name, delay) in [
            ("worldTitleBackdrop", 0.04),
            ("worldTitle", 0.08),
            ("decorativeWorldEmblem", 0.08),
            ("instructionBackdrop", 0.10),
            ("feedbackText", 0.14)
        ] {
            guard let node = childNode(withName: name) else { continue }
            node.alpha = 0
            node.run(.sequence([
                .wait(forDuration: delay),
                .fadeIn(withDuration: 0.24)
            ]), withKey: "entrance")
        }

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

    private var worldEmblem: String {
        if worldTitle.hasPrefix("Word Garden") { return "✿" }
        if worldTitle.hasPrefix("Science Lab") { return "⚗" }
        if worldTitle.hasPrefix("Puzzle Palace") { return "◈" }
        if worldTitle.hasPrefix("Story Tree") { return "✦" }
        return "◆"
    }

    private var ambientTint: UIColor {
        if worldTitle.hasPrefix("Word Garden") {
            return UIColor(red: 1.0, green: 0.64, blue: 0.82, alpha: 1)
        }
        if worldTitle.hasPrefix("Science Lab") {
            return UIColor(red: 0.58, green: 0.94, blue: 0.78, alpha: 1)
        }
        if worldTitle.hasPrefix("Puzzle Palace") {
            return UIColor(red: 0.73, green: 0.64, blue: 1.0, alpha: 1)
        }
        if worldTitle.hasPrefix("Story Tree") {
            return UIColor(red: 1.0, green: 0.82, blue: 0.36, alpha: 1)
        }
        return UIColor(red: 1.0, green: 0.80, blue: 0.38, alpha: 1)
    }

    private func syncDecorativeMotion() {
        childNode(withName: "decorativeAmbientLife")?.removeFromParent()
        // Recreate guidance in its static/animated form without losing the
        // selected object, color or destination when settings change mid-scene.
        if let cue = attentionCue {
            showAttentionCue(at: cue.point, tint: cue.tint, width: cue.width)
        }

        for name in ["foregroundLeft", "foregroundRight"] {
            guard let foreground = childNode(withName: name) else { continue }
            foreground.removeAction(forKey: "ambientSway")
            // Restore authored transforms before restarting an ambient loop.
            // Otherwise each settings toggle accumulates drift and rotation.
            foreground.position = CGPoint(x: name == "foregroundLeft" ? 75 : 1205, y: 80)
            foreground.zRotation = 0
            if !reducedMotion {
                let direction: CGFloat = name == "foregroundLeft" ? 1 : -1
                foreground.run(.repeatForever(.sequence([
                    .group([
                        .moveBy(x: direction * 2, y: 3, duration: 2.6),
                        .rotate(byAngle: direction * 0.006, duration: 2.6)
                    ]),
                    .group([
                        .moveBy(x: direction * -2, y: -3, duration: 2.6),
                        .rotate(byAngle: direction * -0.006, duration: 2.6)
                    ])
                ])), withKey: "ambientSway")
            }
        }

        enumerateChildNodes(withName: "//*") { [self] node, _ in
            guard (node.userData?["decorativeMotionRole"] as? String) == "pulse" else { return }
            node.removeAction(forKey: "ambientPulse")
            node.alpha = 1
            if !reducedMotion {
                node.run(.repeatForever(.sequence([
                    .fadeAlpha(to: 0.58, duration: 1.2),
                    .fadeAlpha(to: 1, duration: 1.2)
                ])), withKey: "ambientPulse")
            }
        }

        // Preferences can arrive before didMove; ambient nodes must not make
        // the scene look built before its world and controls are installed.
        guard !reducedMotion, childNode(withName: "adventureCamera") != nil else { return }

        let root = SKNode()
        root.name = "decorativeAmbientLife"
        root.zPosition = 115
        root.isUserInteractionEnabled = false

        let points: [CGPoint] = [
            CGPoint(x: 165, y: 420),
            CGPoint(x: 320, y: 545),
            CGPoint(x: 485, y: 455),
            CGPoint(x: 650, y: 565),
            CGPoint(x: 815, y: 440),
            CGPoint(x: 970, y: 535),
            CGPoint(x: 1115, y: 405)
        ]

        for (index, point) in points.enumerated() {
            let mote = SKShapeNode(circleOfRadius: index.isMultiple(of: 3) ? 4.5 : 3.2)
            mote.fillColor = ambientTint.withAlphaComponent(0.52)
            mote.strokeColor = .clear
            mote.glowWidth = 4
            mote.position = point
            mote.alpha = 0.45 + CGFloat(index % 3) * 0.16
            mote.isUserInteractionEnabled = false
            root.addChild(mote)

            let dx: CGFloat = index.isMultiple(of: 2) ? 8 : -7
            let dy: CGFloat = 8 + CGFloat(index % 3) * 3
            let duration = 2.4 + Double(index % 4) * 0.38
            mote.run(.repeatForever(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: duration),
                    .fadeAlpha(to: 0.30, duration: duration)
                ]),
                .group([
                    .moveBy(x: -dx, y: -dy, duration: duration),
                    .fadeAlpha(to: 0.82, duration: duration)
                ])
            ])), withKey: "ambientDrift")
        }

        addChild(root)
    }

    private func playSuccessBurst(at point: CGPoint) {
        guard !reducedMotion else { return }
        childNode(withName: "successBurst")?.removeFromParent()

        let root = SKNode()
        root.name = "successBurst"
        root.position = point
        root.zPosition = 1850
        root.isUserInteractionEnabled = false

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.fillColor = .clear
        ring.strokeColor = ambientTint.withAlphaComponent(0.90)
        ring.lineWidth = 4
        ring.glowWidth = 9
        ring.setScale(0.72)
        root.addChild(ring)
        ring.run(.group([
            .scale(to: 2.25, duration: 0.56),
            .fadeOut(withDuration: 0.56)
        ]))

        let directions: [CGPoint] = [
            CGPoint(x: 0, y: 48),
            CGPoint(x: 38, y: 32),
            CGPoint(x: 48, y: 0),
            CGPoint(x: 34, y: -30),
            CGPoint(x: -34, y: -30),
            CGPoint(x: -48, y: 0),
            CGPoint(x: -38, y: 32)
        ]
        for (index, direction) in directions.enumerated() {
            let sparkle = SKShapeNode(circleOfRadius: index.isMultiple(of: 2) ? 5 : 3.5)
            sparkle.fillColor = ambientTint
            sparkle.strokeColor = .white.withAlphaComponent(0.55)
            sparkle.lineWidth = 1
            sparkle.glowWidth = 6
            root.addChild(sparkle)
            sparkle.run(.group([
                .move(to: direction, duration: 0.48 + Double(index % 2) * 0.08),
                .fadeOut(withDuration: 0.56),
                .scale(to: 0.55, duration: 0.56)
            ]))
        }

        addChild(root)
        root.run(.sequence([
            .wait(forDuration: 0.64),
            .removeFromParent()
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
        let control = ArtSystem.medallion(
            radius: touchRadius,
            fill: UIColor(red: 0.075, green: 0.07, blue: 0.15, alpha: 0.92),
            stroke: ambientTint.withAlphaComponent(0.60),
            glow: reducedMotion ? 0 : 2
        )
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
        let node = ArtSystem.panel(
            size,
            fill: UIColor(red: 0.095, green: 0.085, blue: 0.18, alpha: 0.94),
            stroke: ambientTint.withAlphaComponent(0.42),
            radius: min(24, size.height * 0.38),
            lineWidth: 2,
            shadowAlpha: 0.28
        )
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
        halo.userData = NSMutableDictionary(dictionary: ["decorativeMotionRole": "pulse"])
        root.addChild(halo)

        let emblem = ArtSystem.label(symbol, size: 31)
        emblem.fontColor = .white
        emblem.name = name
        root.addChild(emblem)

        let plaque = ArtSystem.panel(
            CGSize(width: max(120, width), height: 44),
            fill: UIColor(red: 0.055, green: 0.05, blue: 0.11, alpha: 0.88),
            stroke: tint.withAlphaComponent(0.72),
            radius: 22,
            lineWidth: 2,
            shadowAlpha: 0.28,
            innerHighlight: tint.withAlphaComponent(0.14)
        )
        plaque.position = CGPoint(x: 0, y: plaqueOffsetY)
        plaque.name = name
        plaque.userData = NSMutableDictionary(dictionary: ["destinationRole": "plaque"])
        root.addChild(plaque)

        let label = ArtSystem.label(title, size: 17)
        label.fontColor = UIColor(red: 1, green: 0.97, blue: 0.88, alpha: 1)
        label.name = name
        plaque.addChild(label)

        makeAccessible(root, label: title, hint: "Tap once. Valkyrie walks here and enters the adventure.")
        addChild(root)
        registerInteraction(root, clearance: 24)

        if !reducedMotion {
            halo.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.58, duration: 1.2),
                .fadeAlpha(to: 1, duration: 1.2)
            ])), withKey: "ambientPulse")
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
                if let name = current.name, !name.isEmpty, !name.hasPrefix("decorative"), name != "successBurst" {
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
        guard !interactionRegistrations.contains(where: { $0.node === node }) else { return }
        interactionRegistrations.append(InteractionRegistration(node: node, clearance: clearance))
    }

    func registerInteractionZone(_ rect: CGRect) {
        registeredInteractionZones.append(rect)
    }

    func clearRegisteredInteractionZones() {
        registeredInteractionZones.removeAll(keepingCapacity: true)
        interactionRegistrations.removeAll(keepingCapacity: true)
    }

    private func liveInteractionZones() -> [CGRect] {
        interactionRegistrations.removeAll { registration in
            guard let node = registration.node else { return true }
            return node.scene !== self
        }

        return interactionRegistrations.compactMap { registration in
            guard let node = registration.node else { return nil }
            let frame = node.calculateAccumulatedFrame().insetBy(
                dx: -registration.clearance,
                dy: -registration.clearance
            )
            return frame.isNull || frame.isInfinite ? nil : frame
        }
    }

    func safeActorPoint(
        near desired: CGPoint,
        avoiding extraZones: [CGRect] = []
    ) -> CGPoint {
        let combined = registeredInteractionZones + liveInteractionZones() + extraZones
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

        state.audio.play("footstep")
        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.leaving else { return }
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

    func successFeedback(at point: CGPoint? = nil) {
        state.audio.play("success")
        successHaptic.notificationOccurred(.success)
        successHaptic.prepare()
        playSuccessBurst(
            at: point ?? CGPoint(
                x: valkyrie.position.x,
                y: valkyrie.position.y + 92
            )
        )
    }

    func errorFeedback() {
        errorHaptic.notificationOccurred(.error)
        errorHaptic.prepare()
    }

    func selectionFeedback() {
        selectionHaptic.selectionChanged()
        selectionHaptic.prepare()
    }

    func isNear(_ point: CGPoint, radius: CGFloat = 85) -> Bool {
        hypot(valkyrie.position.x - point.x, valkyrie.position.y - point.y) <= radius
            && valkyrie.action(forKey: "travel") == nil
    }

    func walkIfValid(_ point: CGPoint) {
        if walkable.contains(point) { travel(to: point) }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !leaving, let touch = touches.first else { return }
        tapGesture.begin(ObjectIdentifier(touch), at: touch.location(in: self))
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            tapGesture.move(ObjectIdentifier(touch), to: touch.location(in: self))
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { tapGesture.cancel(ObjectIdentifier(touch)) }
    }

    func completedTap(in touches: Set<UITouch>) -> CGPoint? {
        guard !leaving else { return nil }
        for touch in touches {
            if let point = tapGesture.end(ObjectIdentifier(touch), at: touch.location(in: self)) {
                return point
            }
        }
        return nil
    }

    func cancelPendingTap() {
        tapGesture.reset()
    }

    func willLeave() {
        leaving = true
        cancelPendingTap()
        clearAttentionCue()
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

    func clearAttentionCue() {
        attentionCue = nil
        childNode(withName: "decorativeAttentionCue")?.removeFromParent()
    }


    func showAttentionCue(
        at point: CGPoint,
        tint: UIColor? = nil,
        width: CGFloat = 118
    ) {
        clearAttentionCue()
        attentionCue = (point, tint, width)

        let color = tint ?? ambientTint
        let root = SKNode()
        root.name = "decorativeAttentionCue"
        root.position = point
        root.zPosition = 175
        root.isUserInteractionEnabled = false

        let shadow = SKShapeNode(ellipseOf: CGSize(width: width, height: 30))
        shadow.fillColor = UIColor(white: 0.02, alpha: 0.18)
        shadow.strokeColor = .clear
        shadow.position.y = -4
        shadow.isUserInteractionEnabled = false
        root.addChild(shadow)

        let ring = SKShapeNode(ellipseOf: CGSize(width: width, height: 34))
        ring.fillColor = color.withAlphaComponent(0.06)
        ring.strokeColor = color.withAlphaComponent(0.78)
        ring.lineWidth = 3
        ring.glowWidth = reducedMotion ? 0 : 7
        ring.isUserInteractionEnabled = false
        root.addChild(ring)

        let inner = SKShapeNode(ellipseOf: CGSize(width: width * 0.58, height: 18))
        inner.fillColor = color.withAlphaComponent(0.10)
        inner.strokeColor = color.withAlphaComponent(0.34)
        inner.lineWidth = 1.5
        inner.isUserInteractionEnabled = false
        root.addChild(inner)

        let spark = ArtSystem.label("✦", size: 18)
        spark.fontColor = color.withAlphaComponent(0.90)
        spark.position.y = 24
        spark.isUserInteractionEnabled = false
        root.addChild(spark)

        if !reducedMotion {
            ring.run(.repeatForever(.sequence([
                .group([
                    .scaleX(to: 1.12, duration: 0.72),
                    .scaleY(to: 1.12, duration: 0.72),
                    .fadeAlpha(to: 0.38, duration: 0.72)
                ]),
                .group([
                    .scaleX(to: 1.0, duration: 0.72),
                    .scaleY(to: 1.0, duration: 0.72),
                    .fadeAlpha(to: 1.0, duration: 0.72)
                ])
            ])), withKey: "attentionPulse")
            spark.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 5, duration: 0.55),
                .moveBy(x: 0, y: -5, duration: 0.55)
            ])), withKey: "attentionFloat")
        }

        addChild(root)
    }

}
