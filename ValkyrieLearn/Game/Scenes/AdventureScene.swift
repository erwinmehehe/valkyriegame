import SpriteKit

@MainActor class AdventureScene: SKScene {
    let state: AppState
    let valkyrie = ValkyrieNode()
    let pip = PipNode()
    let instruction = ArtSystem.label("", size: 27)
    let walkable = CGRect(x: 85, y: 130, width: 1110, height: 145)

    var sourceBackdrop: ArtSystem.Backdrop? { nil }
    private(set) var usingSourceArt = false

    private var leaving = false

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
        backgroundColor = UIColor(
            red: 0.12,
            green: 0.16,
            blue: 0.25,
            alpha: 1
        )
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    override func didMove(to view: SKView) {
        guard children.isEmpty else { return }

        let camera = SKCameraNode()
        camera.position = CGPoint(x: 640, y: 360)
        addChild(camera)
        self.camera = camera

        buildWorld()

        valkyrie.position = CGPoint(x: 190, y: 170)
        pip.position = CGPoint(x: 380, y: 180)
        addChild(valkyrie)
        addChild(pip)

        let instructionPlate = ArtSystem.box(
            CGSize(width: 1030, height: 78),
            color: .black.withAlphaComponent(usingSourceArt ? 0.46 : 0.28),
            radius: 22
        )
        instructionPlate.position = CGPoint(x: 640, y: 650)
        instructionPlate.zPosition = 1990
        addChild(instructionPlate)

        instruction.position = CGPoint(x: 640, y: 650)
        instruction.preferredMaxLayoutWidth = 940
        instruction.numberOfLines = 2
        instruction.zPosition = 2000
        addChild(instruction)

        if !usingSourceArt {
            let title = ArtSystem.label("ENGINEERING PLACEHOLDERS", size: 15)
            title.position = CGPoint(x: 640, y: 695)
            title.fontColor = .lightGray
            title.zPosition = 2000
            addChild(title)
        }
    }

    func buildWorld() {
        if let sourceBackdrop,
           let art = ArtSystem.backdropNode(sourceBackdrop, size: size) {
            usingSourceArt = true
            addChild(art)

            let atmosphere = ArtSystem.box(
                size,
                color: .init(red: 0.08, green: 0.06, blue: 0.16, alpha: 0.08),
                radius: 0
            )
            atmosphere.position = CGPoint(x: 640, y: 360)
            atmosphere.zPosition = -110
            addChild(atmosphere)

            // Keep some native depth in front of the source illustration without
            // covering its paths, structures, or embedded learning objects.
            for x in [18, 1262] {
                let near = SKShapeNode(
                    ellipseOf: CGSize(width: 150, height: 245)
                )
                near.fillColor = .init(
                    red: 0.08,
                    green: 0.18,
                    blue: 0.15,
                    alpha: 0.30
                )
                near.strokeColor = .clear
                near.position = CGPoint(x: x, y: 65)
                near.zPosition = 1100
                addChild(near)
            }
            return
        }

        usingSourceArt = false

        let sky = ArtSystem.box(
            CGSize(width: 1280, height: 720),
            color: .init(red: 0.18, green: 0.23, blue: 0.38, alpha: 1),
            radius: 0
        )
        sky.position = CGPoint(x: 640, y: 360)
        sky.zPosition = -100
        addChild(sky)

        for x in stride(from: 100, through: 1200, by: 220) {
            let tower = ArtSystem.box(
                CGSize(width: 130, height: 240),
                color: .init(red: 0.31, green: 0.36, blue: 0.49, alpha: 1)
            )
            tower.position = CGPoint(x: x, y: 460)
            tower.zPosition = -50
            addChild(tower)
        }

        let floor = ArtSystem.box(
            CGSize(width: 1280, height: 200),
            color: .init(red: 0.43, green: 0.37, blue: 0.31, alpha: 1),
            radius: 0
        )
        floor.position = CGPoint(x: 640, y: 180)
        floor.zPosition = 0
        addChild(floor)

        let path = ArtSystem.box(
            CGSize(width: 1130, height: 100),
            color: .init(red: 0.65, green: 0.56, blue: 0.43, alpha: 1)
        )
        path.position = CGPoint(x: 640, y: 200)
        path.zPosition = 1
        addChild(path)

        for x in [35, 1250] {
            let near = ArtSystem.box(
                CGSize(width: 125, height: 230),
                color: .init(red: 0.18, green: 0.28, blue: 0.24, alpha: 1)
            )
            near.position = CGPoint(x: x, y: 70)
            near.zPosition = 1100
            addChild(near)
        }
    }

    func hotspot(
        _ text: String,
        name: String,
        at point: CGPoint,
        size: CGSize = CGSize(width: 120, height: 64)
    ) -> SKNode {
        let node: SKShapeNode

        if usingSourceArt {
            node = ArtSystem.box(
                size,
                color: .init(red: 0.10, green: 0.08, blue: 0.18, alpha: 0.58),
                radius: min(22, size.height * 0.32)
            )
            node.strokeColor = .init(
                red: 1.0,
                green: 0.84,
                blue: 0.47,
                alpha: 0.82
            )
            node.lineWidth = 2
        } else {
            node = ArtSystem.box(
                size,
                color: .init(red: 0.40, green: 0.32, blue: 0.21, alpha: 1)
            )
        }

        node.name = name
        node.position = point
        node.zPosition = 950

        let label = ArtSystem.label(text, size: usingSourceArt ? 19 : 22)
        label.name = name
        node.addChild(label)

        addChild(node)
        return node
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

        let point = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )

        valkyrie.walk(to: point) { [weak self] in
            guard let self, !self.leaving else { return }
            self.state.audio.play("footstep")
            action?()
        }

        pip.walk(
            to: CGPoint(x: max(90, point.x - 105), y: point.y + 12)
        ) {}
    }

    func isNear(_ point: CGPoint, radius: CGFloat = 85) -> Bool {
        hypot(
            valkyrie.position.x - point.x,
            valkyrie.position.y - point.y
        ) <= radius
            && valkyrie.action(forKey: "travel") == nil
    }

    func walkIfValid(_ point: CGPoint) {
        if walkable.contains(point) {
            travel(to: point)
        }
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

    override func update(_ currentTime: TimeInterval) {
        valkyrie.zPosition = 1000 - valkyrie.position.y
        pip.zPosition = 1000 - pip.position.y
    }
}
