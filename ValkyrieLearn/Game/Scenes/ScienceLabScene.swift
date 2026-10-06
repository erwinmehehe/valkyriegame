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
        if let backdrop = ArtSystem.paintedBackdrop(
            "StarlightIsles",
            size: size,
            tint: UIColor(red: 0.48, green: 0.84, blue: 0.76, alpha: 1),
            blend: 0.15,
            dim: 0.12
        ) {
            backdrop.zPosition = -310
            backdrop.name = "scienceGreenhouseBackdrop"
            addChild(backdrop)
        }

        let glassWash = ArtSystem.box(
            size,
            color: UIColor(red: 0.46, green: 0.82, blue: 0.78, alpha: 0.08),
            radius: 0
        )
        glassWash.strokeColor = .clear
        glassWash.position = CGPoint(x: 640, y: 360)
        glassWash.zPosition = -295
        addChild(glassWash)

        let floor = ArtSystem.panel(
            CGSize(width: 1160, height: 142),
            fill: UIColor(red: 0.24, green: 0.24, blue: 0.16, alpha: 0.90),
            stroke: UIColor(red: 0.61, green: 0.57, blue: 0.35, alpha: 0.82),
            radius: 48,
            lineWidth: 4,
            shadowAlpha: 0.34
        )
        floor.position = CGPoint(x: 640, y: 190)
        floor.zPosition = 22
        floor.name = "greenhouseFloor"
        addChild(floor)

        let house = SKNode()
        house.position = CGPoint(x: 705, y: 405)
        house.zPosition = -80
        house.name = "greenhouseStructure"

        let glass = ArtSystem.panel(
            CGSize(width: 865, height: 430),
            fill: UIColor(red: 0.72, green: 0.92, blue: 0.88, alpha: 0.13),
            stroke: UIColor(red: 0.78, green: 0.95, blue: 0.90, alpha: 0.76),
            radius: 24,
            lineWidth: 4,
            shadowAlpha: 0.18
        )
        house.addChild(glass)

        for x in stride(from: CGFloat(-360), through: CGFloat(360), by: CGFloat(120)) {
            let frame = ArtSystem.box(
                CGSize(width: 7, height: 410),
                color: UIColor(red: 0.10, green: 0.31, blue: 0.29, alpha: 0.84),
                radius: 3
            )
            frame.position.x = x
            frame.zPosition = 2
            house.addChild(frame)
        }

        for y in [CGFloat(-115), CGFloat(15), CGFloat(145)] {
            let frame = ArtSystem.box(
                CGSize(width: 815, height: 7),
                color: UIColor(red: 0.10, green: 0.31, blue: 0.29, alpha: 0.72),
                radius: 3
            )
            frame.position.y = y
            frame.zPosition = 2
            house.addChild(frame)
        }

        let roofLeft = ArtSystem.box(
            CGSize(width: 470, height: 11),
            color: UIColor(red: 0.08, green: 0.28, blue: 0.27, alpha: 0.95),
            radius: 3
        )
        roofLeft.position = CGPoint(x: -190, y: 242)
        roofLeft.zRotation = 0.22
        house.addChild(roofLeft)

        let roofRight = ArtSystem.box(
            CGSize(width: 470, height: 11),
            color: UIColor(red: 0.08, green: 0.28, blue: 0.27, alpha: 0.95),
            radius: 3
        )
        roofRight.position = CGPoint(x: 190, y: 242)
        roofRight.zRotation = -0.22
        house.addChild(roofRight)

        let roofPeak = ArtSystem.medallion(
            radius: 15,
            fill: UIColor(red: 0.86, green: 0.67, blue: 0.28, alpha: 0.96),
            stroke: UIColor(red: 1.0, green: 0.87, blue: 0.50, alpha: 0.90)
        )
        roofPeak.position = CGPoint(x: 0, y: 292)
        house.addChild(roofPeak)

        for x in [CGFloat(-250), CGFloat(0), CGFloat(250)] {
            let lamp = SKNode()
            lamp.position = CGPoint(x: x, y: 170)
            let cord = ArtSystem.box(
                CGSize(width: 4, height: 52),
                color: UIColor(red: 0.28, green: 0.22, blue: 0.14, alpha: 0.9),
                radius: 2
            )
            cord.position.y = 26
            lamp.addChild(cord)
            let glow = ArtSystem.medallion(
                radius: 14,
                fill: UIColor(red: 1.0, green: 0.78, blue: 0.31, alpha: 0.88),
                stroke: UIColor(red: 1.0, green: 0.91, blue: 0.60, alpha: 0.88),
                glow: reducedMotion ? 0 : 6
            )
            lamp.addChild(glow)
            house.addChild(lamp)
        }

        addChild(house)

        for x in [CGFloat(455), CGFloat(535), CGFloat(835), CGFloat(915)] {
            let pot = ArtSystem.panel(
                CGSize(width: 58, height: 34),
                fill: UIColor(red: 0.34, green: 0.20, blue: 0.12, alpha: 0.96),
                stroke: UIColor(red: 0.65, green: 0.42, blue: 0.20, alpha: 0.72),
                radius: 10,
                lineWidth: 2,
                shadowAlpha: 0.18
            )
            pot.position = CGPoint(x: x, y: 345 + CGFloat(Int(x) % 3) * 16)
            pot.zPosition = 120
            addChild(pot)

            let leaf = SKShapeNode(ellipseOf: CGSize(width: 50, height: 26))
            leaf.fillColor = UIColor(red: 0.22, green: 0.60, blue: 0.29, alpha: 0.92)
            leaf.strokeColor = UIColor(red: 0.44, green: 0.78, blue: 0.39, alpha: 0.56)
            leaf.lineWidth = 2
            leaf.position = CGPoint(x: x, y: pot.position.y + 34)
            leaf.zRotation = x.truncatingRemainder(dividingBy: 2) == 0 ? 0.25 : -0.25
            leaf.zPosition = 121
            addChild(leaf)
        }

        let bench = ArtSystem.supplyTray(CGSize(width: 300, height: 118))
        bench.position = seedBenchPoint
        bench.name = "scienceSeedBench"
        bench.zPosition = 360
        addChild(bench)

        let soil = ArtSystem.panel(
            CGSize(width: 230, height: 44),
            fill: UIColor(red: 0.21, green: 0.12, blue: 0.07, alpha: 0.98),
            stroke: UIColor(red: 0.52, green: 0.34, blue: 0.17, alpha: 0.72),
            radius: 10,
            lineWidth: 2,
            shadowAlpha: 0.12
        )
        soil.position = CGPoint(x: 0, y: 28)
        soil.name = "scienceSeedBench"
        bench.addChild(soil)

        let benchLabel = ArtSystem.plaque(
            CGSize(width: 118, height: 28),
            fill: UIColor(red: 0.06, green: 0.18, blue: 0.14, alpha: 0.92),
            stroke: UIColor(red: 0.50, green: 0.72, blue: 0.45, alpha: 0.62),
            radius: 12
        )
        benchLabel.position = CGPoint(x: 0, y: -44)
        benchLabel.name = "scienceSeedBench"
        bench.addChild(benchLabel)
        let benchText = ArtSystem.label("SEED BENCH", size: 11)
        benchText.fontColor = UIColor(red: 0.90, green: 0.97, blue: 0.82, alpha: 1)
        benchText.name = "scienceSeedBench"
        benchLabel.addChild(benchText)

        let tankRoot = SKNode()
        tankRoot.position = CGPoint(x: 355, y: 340)
        tankRoot.zPosition = 260
        tankRoot.name = "scienceWaterTank"
        addChild(tankRoot)

        let tank = ArtSystem.panel(
            CGSize(width: 118, height: 150),
            fill: UIColor(red: 0.08, green: 0.35, blue: 0.46, alpha: 0.96),
            stroke: UIColor(red: 0.55, green: 0.85, blue: 0.92, alpha: 0.86),
            radius: 28,
            lineWidth: 4,
            shadowAlpha: 0.26
        )
        tank.name = "scienceWaterTank"
        tankRoot.addChild(tank)

        let tankGlass = SKShapeNode(ellipseOf: CGSize(width: 74, height: 92))
        tankGlass.fillColor = UIColor(red: 0.28, green: 0.70, blue: 0.82, alpha: 0.18)
        tankGlass.strokeColor = UIColor(red: 0.66, green: 0.91, blue: 0.96, alpha: 0.48)
        tankGlass.lineWidth = 2
        tankGlass.name = "scienceWaterTank"
        tankRoot.addChild(tankGlass)

        let tankLabel = ArtSystem.label("WATER", size: 14)
        tankLabel.position.y = 4
        tankLabel.fontColor = UIColor(red: 0.84, green: 0.96, blue: 1.0, alpha: 1)
        tankLabel.name = "scienceWaterTank"
        tankRoot.addChild(tankLabel)

        let pipe = ArtSystem.box(
            CGSize(width: 255, height: 15),
            color: UIColor(red: 0.14, green: 0.42, blue: 0.46, alpha: 0.96),
            radius: 7
        )
        pipe.position = CGPoint(x: 515, y: 300)
        pipe.strokeColor = UIColor(red: 0.54, green: 0.78, blue: 0.77, alpha: 0.62)
        pipe.lineWidth = 2
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

        let prismPedestal = ArtSystem.panel(
            CGSize(width: 110, height: 62),
            fill: UIColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 0.96),
            stroke: UIColor(red: 0.83, green: 0.68, blue: 0.34, alpha: 0.86),
            radius: 18,
            lineWidth: 3,
            shadowAlpha: 0.26
        )
        prismPedestal.position = CGPoint(x: sunPrismPoint.x, y: sunPrismPoint.y - 28)
        prismPedestal.name = "scienceSunPrism"
        prismPedestal.zPosition = 690
        addChild(prismPedestal)

        let prism = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 48))
            p.addLine(to: CGPoint(x: -42, y: -32))
            p.addLine(to: CGPoint(x: 42, y: -32))
            p.closeSubpath()
            return p
        }())
        prism.position = sunPrismPoint
        prism.name = "scienceSunPrism"
        prism.zPosition = 720
        prism.fillColor = UIColor(red: 0.98, green: 0.80, blue: 0.28, alpha: 0.96)
        prism.strokeColor = UIColor(red: 1, green: 0.96, blue: 0.72, alpha: 1)
        prism.lineWidth = 5
        prism.glowWidth = reducedMotion ? 0 : 4
        addChild(prism)

        let beam = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 1000, y: 430))
            p.addLine(to: CGPoint(x: sunPrismPoint.x + 8, y: sunPrismPoint.y + 38))
            return p
        }())
        beam.strokeColor = UIColor(red: 1.0, green: 0.91, blue: 0.45, alpha: 0.34)
        beam.lineWidth = 12
        beam.zPosition = 300
        addChild(beam)

        let sun = ArtSystem.medallion(
            radius: 24,
            fill: UIColor(red: 0.96, green: 0.67, blue: 0.19, alpha: 0.90),
            stroke: UIColor(red: 1.0, green: 0.90, blue: 0.48, alpha: 0.94),
            glow: reducedMotion ? 0 : 6
        )
        sun.position = CGPoint(x: 1015, y: 420)
        sun.zPosition = 305
        sun.addChild(ArtSystem.label("☀", size: 28))
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
