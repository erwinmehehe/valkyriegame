import SpriteKit
import LearningCore

@MainActor final class ScienceLabScene: AdventureScene {
    typealias GreenhouseStage = ScienceGreenhouseStage

    override var worldTitle: String { "Science Lab · Greenhouse" }
    override var walkable: CGRect { CGRect(x: 90, y: 135, width: 1100, height: 170) }

    let milo = MiloNode()
    var greenhouseStage: GreenhouseStage { state.scienceAdventure.greenhouseStage }
    var greenhouseComplete: Bool { state.scienceAdventure.greenhouseComplete }

    private let seedBenchPoint = CGPoint(x: 685, y: 235)
    private let waterValvePoint = CGPoint(x: 430, y: 220)
    private let sunPrismPoint = CGPoint(x: 940, y: 245)
    private let exitPoint = CGPoint(x: 1145, y: 190)

    private var plantNode = SKNode()
    private var gateNode = SKNode()
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.isHidden = true
        pip.position = CGPoint(x: -500, y: -500)

        milo.position = CGPoint(x: 320, y: 190)
        milo.reducedMotion = reducedMotion
        addChild(milo)

        valkyrie.position = CGPoint(x: 175, y: 175)
        valkyrie.setScale(0.5)
        renderPlant()
        renderGate()

        instruction.text = "Milo noticed something at the seed bench. Walk over and inspect it."
    }

    override func buildWorld() {
        // Native geometry now owns the playable environment. The preserved v3.31
        // science quadrant is only a low-opacity color matte because its effective
        // source size is 160x90 pixels and cannot support a Retina fullscreen scene.
        let sky = ArtSystem.box(
            size,
            color: UIColor(red: 0.42, green: 0.64, blue: 0.67, alpha: 1),
            radius: 0
        )
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 640, y: 360)
        sky.zPosition = -250
        sky.name = "scienceNativeBackdrop"
        addChild(sky)

        if let atlas = ArtSystem.texture("V331WorldAtlas") {
            let scienceTexture = SKTexture(
                rect: CGRect(x: 0, y: 0, width: 0.5, height: 0.5),
                in: atlas
            )
            scienceTexture.filteringMode = .linear
            let matte = SKSpriteNode(texture: scienceTexture, color: .white, size: size)
            matte.position = CGPoint(x: 640, y: 360)
            matte.zPosition = -240
            matte.alpha = 0.08
            matte.name = "scienceLegacyMatte"
            addChild(matte)
        }

        // Use the high-resolution illustrated garden atlas as the greenhouse's
        // distant scenery. The greenhouse frame, path and teaching objects remain
        // native SpriteKit nodes in front, so this improves depth without changing
        // any interaction or learning state.
        if let atlas = ArtSystem.texture("WordGardenSourceAtlas") {
            let greenhouseTexture = SKTexture(
                rect: CGRect(x: 0, y: 0.502, width: 0.499, height: 0.498),
                in: atlas
            )
            greenhouseTexture.filteringMode = .linear
            let scenic = SKSpriteNode(
                texture: greenhouseTexture,
                color: UIColor(red: 0.72, green: 0.92, blue: 0.78, alpha: 1),
                size: size
            )
            scenic.colorBlendFactor = 0.08
            scenic.position = CGPoint(x: 640, y: 360)
            scenic.zPosition = -230
            scenic.alpha = 0.94
            scenic.name = "scienceGreenhouseBackdropHD"
            addChild(scenic)

            let scenicWash = ArtSystem.box(
                size,
                color: UIColor(red: 0.08, green: 0.28, blue: 0.19, alpha: 0.12),
                radius: 0
            )
            scenicWash.strokeColor = .clear
            scenicWash.position = CGPoint(x: 640, y: 360)
            scenicWash.zPosition = -229
            scenicWash.name = "scienceGreenhouseBackdropWash"
            addChild(scenicWash)
        }

        let ground = ArtSystem.box(
            CGSize(width: 1280, height: 260),
            color: UIColor(red: 0.18, green: 0.28, blue: 0.19, alpha: 0.98),
            radius: 0
        )
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 640, y: 120)
        ground.zPosition = -120
        ground.name = "scienceGround"
        addChild(ground)

        if let waterBed = ArtSystem.sprite(
            "BridgeChannel",
            size: CGSize(width: 310, height: 105)
        ) {
            waterBed.position = CGPoint(x: 1015, y: 150)
            waterBed.zPosition = -90
            waterBed.alpha = 0.82
            waterBed.name = "scienceWaterBed"
            addChild(waterBed)
        }

        let house = SKNode()
        house.position = CGPoint(x: 720, y: 390)
        house.zPosition = -80
        house.name = "scienceGreenhouseFrame"

        let glass = ArtSystem.box(
            CGSize(width: 860, height: 430),
            color: UIColor(red: 0.78, green: 0.92, blue: 0.90, alpha: 0.12),
            radius: 18
        )
        glass.strokeColor = UIColor(red: 0.87, green: 0.96, blue: 0.94, alpha: 0.82)
        glass.lineWidth = 5
        house.addChild(glass)

        for x in stride(from: CGFloat(-360), through: CGFloat(360), by: CGFloat(120)) {
            let frame = ArtSystem.box(
                CGSize(width: 8, height: 410),
                color: UIColor(red: 0.16, green: 0.31, blue: 0.28, alpha: 0.96),
                radius: 2
            )
            frame.position.x = x
            frame.zPosition = 2
            house.addChild(frame)
        }

        for y in stride(from: CGFloat(-150), through: CGFloat(150), by: CGFloat(100)) {
            let frame = ArtSystem.box(
                CGSize(width: 820, height: 6),
                color: UIColor(red: 0.16, green: 0.31, blue: 0.28, alpha: 0.72),
                radius: 2
            )
            frame.position.y = y
            frame.zPosition = 2
            house.addChild(frame)
        }

        let roofLeft = ArtSystem.box(
            CGSize(width: 470, height: 10),
            color: UIColor(red: 0.18, green: 0.34, blue: 0.30, alpha: 1),
            radius: 2
        )
        roofLeft.position = CGPoint(x: -190, y: 240)
        roofLeft.zRotation = 0.22
        house.addChild(roofLeft)

        let roofRight = ArtSystem.box(
            CGSize(width: 470, height: 10),
            color: UIColor(red: 0.18, green: 0.34, blue: 0.30, alpha: 1),
            radius: 2
        )
        roofRight.position = CGPoint(x: 190, y: 240)
        roofRight.zRotation = -0.22
        house.addChild(roofRight)

        for x in [CGFloat(-300), -100, 100, 300] {
            let planter = ArtSystem.box(
                CGSize(width: 120, height: 56),
                color: UIColor(red: 0.30, green: 0.20, blue: 0.11, alpha: 0.96),
                radius: 12
            )
            planter.position = CGPoint(x: x, y: -155)
            planter.strokeColor = UIColor(red: 0.52, green: 0.38, blue: 0.20, alpha: 0.90)
            planter.lineWidth = 3
            house.addChild(planter)

            if abs(x) > 200, let bloom = ArtSystem.sprite(
                "StoryBloom",
                size: CGSize(width: 78, height: 78)
            ) {
                bloom.position = CGPoint(x: x, y: -105)
                bloom.zPosition = 1
                bloom.name = "scienceSpecimenBloom"
                house.addChild(bloom)
            } else {
                let leaves = SKShapeNode(circleOfRadius: 34)
                leaves.fillColor = UIColor(red: 0.22, green: 0.48, blue: 0.24, alpha: 0.94)
                leaves.strokeColor = UIColor(red: 0.56, green: 0.78, blue: 0.38, alpha: 0.82)
                leaves.lineWidth = 3
                leaves.position = CGPoint(x: x, y: -102)
                house.addChild(leaves)
            }
        }

        // Reflections, hanging vines and a warm crest give the greenhouse the
        // same illustrated depth language as Story Tree and Word Garden while
        // staying below all named interaction targets.
        for (index, x) in [CGFloat(-280), CGFloat(-40), CGFloat(200)].enumerated() {
            let reflection = SKShapeNode(path: {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x - 38, y: 185))
                path.addLine(to: CGPoint(x: x + 44, y: -115))
                return path
            }())
            reflection.strokeColor = UIColor(white: 1, alpha: index == 1 ? 0.13 : 0.20)
            reflection.lineWidth = index == 1 ? 22 : 16
            reflection.zPosition = 1
            house.addChild(reflection)
        }

        for x in [CGFloat(-352), CGFloat(-180), CGFloat(192), CGFloat(350)] {
            let vine = SKNode()
            vine.position = CGPoint(x: x, y: 160)
            vine.zPosition = 3

            let stem = SKShapeNode(rectOf: CGSize(width: 5, height: 116), cornerRadius: 2)
            stem.fillColor = UIColor(red: 0.20, green: 0.43, blue: 0.23, alpha: 0.88)
            stem.strokeColor = .clear
            stem.position.y = -56
            vine.addChild(stem)

            for index in 0..<4 {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 37, height: 17))
                leaf.position = CGPoint(
                    x: index.isMultiple(of: 2) ? -16 : 16,
                    y: -CGFloat(index) * 27 - 15
                )
                leaf.zRotation = index.isMultiple(of: 2) ? 0.36 : -0.36
                leaf.fillColor = UIColor(red: 0.34, green: 0.66, blue: 0.34, alpha: 0.93)
                leaf.strokeColor = UIColor(red: 0.61, green: 0.78, blue: 0.44, alpha: 0.50)
                leaf.lineWidth = 1
                vine.addChild(leaf)
            }
            house.addChild(vine)
        }

        let roofCrest = ArtSystem.plaque(
            CGSize(width: 112, height: 28),
            fill: UIColor(red: 0.38, green: 0.24, blue: 0.10, alpha: 0.96),
            stroke: UIColor(red: 0.88, green: 0.68, blue: 0.29, alpha: 0.92),
            radius: 12
        )
        roofCrest.position = CGPoint(x: 0, y: 246)
        roofCrest.zPosition = 4
        house.addChild(roofCrest)

        let crestMark = ArtSystem.label("✦  LAB  ✦", size: 12)
        crestMark.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.56, alpha: 1)
        roofCrest.addChild(crestMark)

        addChild(house)

        for (height, y) in [(CGFloat(66), CGFloat(687)), (CGFloat(100), CGFloat(46))] {
            let shade = ArtSystem.box(
                CGSize(width: 1280, height: height),
                color: .black.withAlphaComponent(0.20),
                radius: 0
            )
            shade.strokeColor = .clear
            shade.position = CGPoint(x: 640, y: y)
            shade.zPosition = 1850
            addChild(shade)
        }

        let path = ArtSystem.panel(
            CGSize(width: 1110, height: 108),
            fill: UIColor(red: 0.39, green: 0.30, blue: 0.19, alpha: 0.90),
            stroke: UIColor(red: 0.69, green: 0.57, blue: 0.36, alpha: 0.84),
            radius: 50,
            lineWidth: 4,
            shadowAlpha: 0.28,
            innerHighlight: UIColor(red: 0.82, green: 0.70, blue: 0.47, alpha: 0.10)
        )
        path.position = CGPoint(x: 640, y: 190)
        path.zPosition = 20
        addChild(path)

        let bench = ArtSystem.box(
            CGSize(width: 300, height: 120),
            color: UIColor(red: 0.34, green: 0.22, blue: 0.12, alpha: 1),
            radius: 8
        )
        bench.position = seedBenchPoint
        bench.name = "scienceSeedBench"
        bench.zPosition = 360
        if let timber = ArtSystem.texture("BridgeOakPlank") {
            bench.fillColor = .white
            bench.fillTexture = timber
            bench.strokeColor = UIColor(red: 0.54, green: 0.36, blue: 0.18, alpha: 0.88)
            bench.lineWidth = 3
        }
        addChild(bench)

        let soil = ArtSystem.box(
            CGSize(width: 230, height: 42),
            color: UIColor(red: 0.24, green: 0.14, blue: 0.08, alpha: 1),
            radius: 10
        )
        soil.position = CGPoint(x: 0, y: 28)
        soil.name = "scienceSeedBench"
        bench.addChild(soil)

        let waterTank = ArtSystem.panel(
            CGSize(width: 118, height: 150),
            fill: UIColor(red: 0.08, green: 0.35, blue: 0.46, alpha: 0.96),
            stroke: UIColor(red: 0.55, green: 0.85, blue: 0.92, alpha: 0.86),
            radius: 28,
            lineWidth: 4,
            shadowAlpha: 0.28
        )
        waterTank.position = CGPoint(x: 355, y: 338)
        waterTank.name = "scienceWaterTank"
        waterTank.zPosition = 260
        addChild(waterTank)

        let tankGlass = SKShapeNode(ellipseOf: CGSize(width: 74, height: 92))
        tankGlass.fillColor = UIColor(red: 0.28, green: 0.70, blue: 0.82, alpha: 0.18)
        tankGlass.strokeColor = UIColor(red: 0.66, green: 0.91, blue: 0.96, alpha: 0.48)
        tankGlass.lineWidth = 2
        tankGlass.name = "scienceWaterTank"
        waterTank.addChild(tankGlass)

        let tankLabel = ArtSystem.label("WATER", size: 14)
        tankLabel.position.y = 4
        tankLabel.fontColor = UIColor(red: 0.84, green: 0.96, blue: 1.0, alpha: 1)
        tankLabel.name = "scienceWaterTank"
        waterTank.addChild(tankLabel)

        let pipe = ArtSystem.box(
            CGSize(width: 260, height: 18),
            color: UIColor(red: 0.22, green: 0.45, blue: 0.49, alpha: 1),
            radius: 8
        )
        pipe.position = CGPoint(x: 515, y: 300)
        pipe.zPosition = 250
        addChild(pipe)

        let valve = ArtSystem.medallion(
            radius: 43,
            fill: UIColor(red: 0.08, green: 0.32, blue: 0.45, alpha: 0.98),
            stroke: UIColor(red: 0.72, green: 0.94, blue: 1.0, alpha: 0.94),
            glow: reducedMotion ? 0 : 3
        )
        valve.position = waterValvePoint
        valve.name = "scienceWaterValve"
        valve.zPosition = 720
        let drop = ArtSystem.label("💧", size: 32)
        drop.name = "scienceWaterValve"
        valve.addChild(drop)
        addChild(valve)

        let prism = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 46))
            p.addLine(to: CGPoint(x: -42, y: -32))
            p.addLine(to: CGPoint(x: 42, y: -32))
            p.closeSubpath()
            return p
        }())
        prism.position = sunPrismPoint
        prism.name = "scienceSunPrism"
        prism.zPosition = 720
        prism.fillColor = UIColor(red: 0.98, green: 0.83, blue: 0.28, alpha: 1)
        prism.strokeColor = UIColor(red: 1, green: 0.96, blue: 0.72, alpha: 1)
        prism.lineWidth = 5
        addChild(prism)

        let sun = ArtSystem.label("☀", size: 38)
        sun.position = CGPoint(x: 1015, y: 390)
        sun.fontColor = UIColor(red: 1, green: 0.88, blue: 0.35, alpha: 1)
        sun.zPosition = 300
        addChild(sun)

        gateNode = SKNode()
        gateNode.position = exitPoint
        gateNode.zPosition = 500
        gateNode.name = "scienceWeatherGate"
        addChild(gateNode)
        renderGate()

        _ = worldControl("⌂", name: "scienceHome", at: CGPoint(x: 55, y: 665), radius: 30)
    }

    private func renderPlant() {
        plantNode.removeFromParent()
        plantNode = SKNode()
        plantNode.position = CGPoint(x: seedBenchPoint.x, y: seedBenchPoint.y + 60)
        plantNode.zPosition = 620
        plantNode.name = "scienceSeedBench"

        switch greenhouseStage {
        case .arrive, .inspected:
            let seed = SKShapeNode(ellipseOf: CGSize(width: 28, height: 18))
            seed.fillColor = UIColor(red: 0.56, green: 0.35, blue: 0.16, alpha: 1)
            seed.strokeColor = .clear
            seed.name = "scienceSeedBench"
            plantNode.addChild(seed)

        case .watered:
            let stem = ArtSystem.box(
                CGSize(width: 12, height: 58),
                color: UIColor(red: 0.28, green: 0.58, blue: 0.25, alpha: 1),
                radius: 5
            )
            stem.position.y = 18
            stem.name = "scienceSeedBench"
            plantNode.addChild(stem)

            for x in [CGFloat(-18), CGFloat(18)] {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 38, height: 22))
                leaf.fillColor = UIColor(red: 0.47, green: 0.68, blue: 0.34, alpha: 1)
                leaf.strokeColor = .clear
                leaf.position = CGPoint(x: x, y: 34)
                leaf.zRotation = x < 0 ? 0.45 : -0.45
                leaf.name = "scienceSeedBench"
                plantNode.addChild(leaf)
            }

        case .lit:
            let stem = ArtSystem.box(
                CGSize(width: 14, height: 100),
                color: UIColor(red: 0.18, green: 0.53, blue: 0.22, alpha: 1),
                radius: 5
            )
            stem.position.y = 36
            stem.name = "scienceSeedBench"
            plantNode.addChild(stem)

            for (x, y) in [(CGFloat(-26), CGFloat(45)), (CGFloat(27), CGFloat(66)), (CGFloat(-24), CGFloat(82))] {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 48, height: 26))
                leaf.fillColor = UIColor(red: 0.25, green: 0.69, blue: 0.31, alpha: 1)
                leaf.strokeColor = .clear
                leaf.position = CGPoint(x: x, y: y)
                leaf.zRotation = x < 0 ? 0.45 : -0.45
                leaf.name = "scienceSeedBench"
                plantNode.addChild(leaf)
            }

            let bloom = SKShapeNode(circleOfRadius: 24)
            bloom.fillColor = UIColor(red: 1, green: 0.61, blue: 0.29, alpha: 1)
            bloom.strokeColor = UIColor(red: 1, green: 0.84, blue: 0.40, alpha: 1)
            bloom.lineWidth = 4
            bloom.position.y = 104
            bloom.name = "scienceSeedBench"
            plantNode.addChild(bloom)
        }

        addChild(plantNode)
    }

    private func renderGate() {
        gateNode.removeAllChildren()

        let arch = SKShapeNode(rectOf: CGSize(width: 120, height: 154), cornerRadius: 52)
        arch.fillColor = UIColor(red: 0.07, green: 0.22, blue: 0.18, alpha: 0.90)
        arch.strokeColor = greenhouseComplete
            ? UIColor(red: 0.90, green: 0.88, blue: 0.46, alpha: 0.96)
            : UIColor(red: 0.45, green: 0.66, blue: 0.48, alpha: 0.82)
        arch.lineWidth = 6
        arch.name = "scienceWeatherGate"
        gateNode.addChild(arch)

        let inner = SKShapeNode(rectOf: CGSize(width: 78, height: 108), cornerRadius: 34)
        inner.fillColor = UIColor(red: 0.04, green: 0.12, blue: 0.10, alpha: 0.94)
        inner.strokeColor = UIColor(white: 1, alpha: 0.10)
        inner.lineWidth = 2
        inner.name = "scienceWeatherGate"
        gateNode.addChild(inner)

        let sign = ArtSystem.plaque(
            CGSize(width: 150, height: 34),
            fill: UIColor(red: 0.06, green: 0.16, blue: 0.12, alpha: 0.94),
            stroke: UIColor(red: 0.54, green: 0.72, blue: 0.46, alpha: 0.72),
            radius: 15
        )
        sign.position.y = 111
        sign.name = "scienceWeatherGate"
        gateNode.addChild(sign)

        let signText = ArtSystem.label("WEATHER TOWER", size: 12)
        signText.fontColor = UIColor(red: 0.92, green: 0.98, blue: 0.84, alpha: 1)
        signText.name = "scienceWeatherGate"
        sign.addChild(signText)

        if !greenhouseComplete {
            for x in [CGFloat(-28), CGFloat(0), CGFloat(28)] {
                let vine = ArtSystem.box(
                    CGSize(width: 8, height: 105),
                    color: UIColor(red: 0.15, green: 0.49, blue: 0.22, alpha: 0.80),
                    radius: 4
                )
                vine.position = CGPoint(x: x, y: -3)
                vine.zRotation = x / 420
                vine.name = "scienceWeatherGate"
                gateNode.addChild(vine)
            }
            let lock = ArtSystem.label("✿", size: 34)
            lock.fontColor = UIColor(red: 0.70, green: 0.88, blue: 0.52, alpha: 0.86)
            lock.name = "scienceWeatherGate"
            gateNode.addChild(lock)
        } else {
            inner.fillColor = UIColor(red: 0.28, green: 0.58, blue: 0.66, alpha: 0.22)
            inner.strokeColor = UIColor(red: 0.95, green: 0.91, blue: 0.49, alpha: 0.86)
            inner.glowWidth = reducedMotion ? 0 : 12
            let arrow = ArtSystem.label("→", size: 34)
            arrow.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.50, alpha: 1)
            arrow.name = "scienceWeatherGate"
            gateNode.addChild(arrow)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch
        touchStart = touch.location(in: self)
        moved = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if hypot(point.x - touchStart.x, point.y - touchStart.y) > 12 {
            moved = true
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            activeTouch = nil
            moved = false
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        defer {
            activeTouch = nil
            moved = false
        }

        let point = touch.location(in: self)
        guard !moved, hypot(point.x - touchStart.x, point.y - touchStart.y) <= 12 else { return }
        handleTap(at: point)
    }

    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let point = CGPoint(
            x: min(walkable.maxX, max(walkable.minX, destination.x)),
            y: min(walkable.maxY, max(walkable.minY, destination.y))
        )
        state.audio.play("footstep")
        valkyrie.walk(to: point) { [weak self] in
            guard self != nil else { return }
            action?()
        }
        milo.walk(to: CGPoint(x: max(110, point.x - 95), y: min(walkable.maxY, point.y + 18))) {}
    }

    override func walkIfValid(_ point: CGPoint) {
        if walkable.contains(point) { travel(to: point) }
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        milo.zPosition = 1000 - milo.position.y
    }

    override func willLeave() {
        activeTouch = nil
        milo.cancelTravel()
        super.willLeave()
    }

    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "scienceSeedBench":
            // The approach point is 120 horizontally and 50 vertically away:
            // its distance is exactly 130, so arrival must count as in reach.
            if isNear(seedBenchPoint, radius: 130) {
                inspectSeedBench()
            } else {
                instruction.text = "Walk to the seed bench so Milo can inspect it closely."
                travel(to: CGPoint(x: seedBenchPoint.x - 120, y: 185))
            }

        case "scienceWaterValve":
            if isNear(waterValvePoint, radius: 115) {
                testWater()
            } else {
                instruction.text = "Walk to the water valve before turning it."
                travel(to: CGPoint(x: waterValvePoint.x + 70, y: 180))
            }

        case "scienceSunPrism":
            if isNear(sunPrismPoint, radius: 125) {
                testLight()
            } else {
                instruction.text = "Walk to the sun prism before aiming it."
                travel(to: CGPoint(x: sunPrismPoint.x - 90, y: 185))
            }

        case "scienceWeatherGate":
            if greenhouseComplete {
                if isNear(exitPoint, radius: 120) {
                    state.travel(to: .scienceWeatherTower)
                } else {
                    instruction.text = "The Weather Tower path is open. Walk to the gate to continue."
                    travel(to: CGPoint(x: exitPoint.x - 75, y: 180))
                }
            } else {
                instruction.text = "The vine gate is still closed. Finish the plant investigation first."
            }

        case "scienceHome":
            state.travel(to: .storyTree)

        default:
            walkIfValid(point)
        }
    }

    private func inspectSeedBench() {
        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)

        switch greenhouseStage {
        case .arrive:
            state.scienceInspectGreenhouse()
            instruction.text = "Milo notices the soil is dry. What change should we test first?"
        case .inspected:
            instruction.text = "The soil is still dry. The water valve can test our prediction."
        case .watered:
            instruction.text = "The seed sprouted after watering. The young sprout looks pale—what could we change next?"
        case .lit:
            instruction.text = "Water and light changed the plant. The Greenhouse gate is open."
        }
    }

    private func testWater() {
        guard greenhouseStage != .lit else {
            instruction.text = "The plant already has what it needs for this investigation."
            return
        }
        guard greenhouseStage != .arrive else {
            instruction.text = "Milo wants to inspect the seed bench first so we have evidence before changing anything."
            return
        }
        guard greenhouseStage == .inspected else {
            instruction.text = "The soil is already moist. Let's observe the sprout before adding more water."
            return
        }

        valkyrie.pose(.interact)
        state.audio.play("crystal")
        state.scienceWaterGreenhouse()
        renderPlant()
        instruction.text = "The dry soil darkened, and a sprout appeared. Our water test changed the seed tray."
    }

    private func testLight() {
        guard greenhouseStage != .arrive else {
            instruction.text = "Milo wants to inspect the seed bench before changing the light."
            return
        }
        guard greenhouseStage != .inspected else {
            state.scienceRecordDrySoilMistake()
            instruction.text = "The soil is visibly dry. Let's test that observation before changing the light."
            return
        }
        guard greenhouseStage == .watered else {
            instruction.text = "The prism is already aimed at the plant."
            return
        }

        valkyrie.pose(.interact)
        milo.inspect(reducedMotion: reducedMotion)
        state.scienceLightGreenhouse()
        renderPlant()
        renderGate()
        state.audio.play("success")
        instruction.text = "The pale sprout became greener in the light. Observation, prediction, test, result—the Weather Tower path opened."
    }
}
