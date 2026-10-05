import SpriteKit

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
        renderPlant()
        renderGate()

        instruction.text = "Milo noticed something at the seed bench. Walk over and inspect it."
    }

    override func buildWorld() {
        // A native procedural greenhouse foundation. Final illustrated art can replace
        // these nodes without changing the interaction geometry or mechanic names.
        let sky = ArtSystem.box(size, color: UIColor(red: 0.55, green: 0.75, blue: 0.82, alpha: 1), radius: 0)
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 640, y: 360)
        sky.zPosition = -200
        addChild(sky)

        let ground = ArtSystem.box(
            CGSize(width: 1280, height: 260),
            color: UIColor(red: 0.20, green: 0.31, blue: 0.20, alpha: 1),
            radius: 0
        )
        ground.strokeColor = .clear
        ground.position = CGPoint(x: 640, y: 120)
        ground.zPosition = -120
        addChild(ground)

        let house = SKNode()
        house.position = CGPoint(x: 720, y: 390)
        house.zPosition = -80

        let glass = ArtSystem.box(
            CGSize(width: 860, height: 430),
            color: UIColor(red: 0.78, green: 0.92, blue: 0.90, alpha: 0.22),
            radius: 18
        )
        glass.strokeColor = UIColor(red: 0.87, green: 0.96, blue: 0.94, alpha: 0.9)
        glass.lineWidth = 7
        house.addChild(glass)

        for x in stride(from: CGFloat(-360), through: CGFloat(360), by: CGFloat(120)) {
            let frame = ArtSystem.box(
                CGSize(width: 8, height: 410),
                color: UIColor(red: 0.18, green: 0.34, blue: 0.30, alpha: 0.9),
                radius: 2
            )
            frame.position.x = x
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

        addChild(house)

        let path = ArtSystem.box(
            CGSize(width: 1110, height: 120),
            color: UIColor(red: 0.50, green: 0.39, blue: 0.25, alpha: 1),
            radius: 50
        )
        path.position = CGPoint(x: 640, y: 190)
        path.strokeColor = UIColor(red: 0.66, green: 0.53, blue: 0.34, alpha: 1)
        path.lineWidth = 4
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
        addChild(bench)

        let soil = ArtSystem.box(
            CGSize(width: 230, height: 42),
            color: UIColor(red: 0.24, green: 0.14, blue: 0.08, alpha: 1),
            radius: 10
        )
        soil.position = CGPoint(x: 0, y: 28)
        soil.name = "scienceSeedBench"
        bench.addChild(soil)

        let waterTank = ArtSystem.box(
            CGSize(width: 118, height: 150),
            color: UIColor(red: 0.18, green: 0.45, blue: 0.58, alpha: 1),
            radius: 20
        )
        waterTank.position = CGPoint(x: 355, y: 338)
        waterTank.name = "scienceWaterTank"
        waterTank.zPosition = 260
        addChild(waterTank)

        let tankLabel = ArtSystem.label("WATER", size: 18)
        tankLabel.position.y = 8
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

        let valve = SKShapeNode(circleOfRadius: 43)
        valve.position = waterValvePoint
        valve.name = "scienceWaterValve"
        valve.zPosition = 720
        valve.fillColor = UIColor(red: 0.14, green: 0.42, blue: 0.56, alpha: 1)
        valve.strokeColor = UIColor(red: 0.76, green: 0.93, blue: 1, alpha: 1)
        valve.lineWidth = 5
        valve.addChild(ArtSystem.label("💧", size: 34))
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

        let left = ArtSystem.box(
            CGSize(width: 18, height: 150),
            color: UIColor(red: 0.21, green: 0.36, blue: 0.31, alpha: 1),
            radius: 3
        )
        left.position.x = -52
        left.name = "scienceWeatherGate"
        gateNode.addChild(left)

        let right = ArtSystem.box(
            CGSize(width: 18, height: 150),
            color: UIColor(red: 0.21, green: 0.36, blue: 0.31, alpha: 1),
            radius: 3
        )
        right.position.x = 52
        right.name = "scienceWeatherGate"
        gateNode.addChild(right)

        let top = ArtSystem.box(
            CGSize(width: 122, height: 18),
            color: UIColor(red: 0.21, green: 0.36, blue: 0.31, alpha: 1),
            radius: 3
        )
        top.position.y = 66
        top.name = "scienceWeatherGate"
        gateNode.addChild(top)

        let sign = ArtSystem.label(greenhouseComplete ? "Weather Tower →" : "Weather Tower", size: 17)
        sign.position.y = 98
        sign.name = "scienceWeatherGate"
        gateNode.addChild(sign)

        if !greenhouseComplete {
            let vines = ArtSystem.box(
                CGSize(width: 78, height: 120),
                color: UIColor(red: 0.16, green: 0.48, blue: 0.21, alpha: 0.72),
                radius: 20
            )
            vines.name = "scienceWeatherGate"
            gateNode.addChild(vines)
        } else {
            let glow = SKShapeNode(rectOf: CGSize(width: 96, height: 128), cornerRadius: 20)
            glow.fillColor = UIColor(red: 0.92, green: 0.89, blue: 0.48, alpha: 0.08)
            glow.strokeColor = UIColor(red: 0.95, green: 0.91, blue: 0.49, alpha: 0.8)
            glow.lineWidth = 3
            glow.glowWidth = reducedMotion ? 0 : 10
            glow.name = "scienceWeatherGate"
            gateNode.addChild(glow)
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
        valkyrie.walk(to: point) { [weak self] in
            guard let self else { return }
            self.state.audio.play("footstep")
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
                instruction.text = "The Greenhouse path is open. Weather Tower is the next Science Lab area."
                valkyrie.pose(.celebrate)
                milo.inspect(reducedMotion: reducedMotion)
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
