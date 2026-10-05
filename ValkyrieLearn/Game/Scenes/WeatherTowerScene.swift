import SpriteKit
import LearningCore

@MainActor final class WeatherTowerScene: AdventureScene {
    typealias WeatherStage = ScienceWeatherStage
    typealias ForecastChoice = ScienceForecastChoice

    override var worldTitle: String { "Science Lab · Weather Tower" }
    override var walkable: CGRect { CGRect(x: 90, y: 135, width: 1100, height: 170) }

    let milo = MiloNode()
    var weatherStage: WeatherStage { state.scienceAdventure.weatherStage }
    var selectedForecast: ForecastChoice? { state.scienceAdventure.selectedForecast }
    var creatureRouteOpen: Bool { state.scienceAdventure.creatureRouteOpen }

    private let morningPoint = CGPoint(x: 470, y: 250)
    private let afternoonPoint = CGPoint(x: 700, y: 250)
    private let forecastPoint = CGPoint(x: 930, y: 235)
    private let creatureGatePoint = CGPoint(x: 1140, y: 190)

    private var gateNode = SKNode()
    private var forecastNeedle = SKNode()
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.isHidden = true
        pip.position = CGPoint(x: -500, y: -500)

        valkyrie.position = CGPoint(x: 175, y: 175)
        valkyrie.setScale(0.5)
        milo.position = CGPoint(x: 315, y: 190)
        milo.reducedMotion = reducedMotion
        addChild(milo)

        instruction.text = "Milo found two weather flags. Observe the morning flag first."
    }

    override func buildWorld() {
        let sky = ArtSystem.box(
            size,
            color: UIColor(red: 0.36, green: 0.58, blue: 0.72, alpha: 1),
            radius: 0
        )
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 640, y: 360)
        sky.zPosition = -220
        addChild(sky)

        for (x, y, radius, alpha) in [
            (CGFloat(250), CGFloat(570), CGFloat(90), CGFloat(0.42)),
            (CGFloat(520), CGFloat(610), CGFloat(120), CGFloat(0.36)),
            (CGFloat(860), CGFloat(560), CGFloat(105), CGFloat(0.34))
        ] {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: radius * 2.2, height: radius))
            cloud.fillColor = UIColor(white: 0.92, alpha: alpha)
            cloud.strokeColor = .clear
            cloud.position = CGPoint(x: x, y: y)
            cloud.zPosition = -180
            addChild(cloud)
        }

        let cliff = ArtSystem.box(
            CGSize(width: 1280, height: 250),
            color: UIColor(red: 0.22, green: 0.27, blue: 0.27, alpha: 1),
            radius: 0
        )
        cliff.strokeColor = .clear
        cliff.position = CGPoint(x: 640, y: 105)
        cliff.zPosition = -100
        addChild(cliff)

        let path = ArtSystem.box(
            CGSize(width: 1120, height: 118),
            color: UIColor(red: 0.43, green: 0.37, blue: 0.28, alpha: 1),
            radius: 50
        )
        path.position = CGPoint(x: 640, y: 190)
        path.strokeColor = UIColor(red: 0.60, green: 0.54, blue: 0.42, alpha: 1)
        path.lineWidth = 4
        path.zPosition = 30
        addChild(path)

        let tower = SKNode()
        tower.position = CGPoint(x: 720, y: 385)
        tower.zPosition = -20

        let shaft = ArtSystem.box(
            CGSize(width: 300, height: 390),
            color: UIColor(red: 0.38, green: 0.42, blue: 0.42, alpha: 1),
            radius: 28
        )
        shaft.strokeColor = UIColor(red: 0.64, green: 0.67, blue: 0.64, alpha: 1)
        shaft.lineWidth = 7
        tower.addChild(shaft)

        for y in stride(from: CGFloat(-135), through: CGFloat(135), by: CGFloat(90)) {
            let band = ArtSystem.box(
                CGSize(width: 320, height: 12),
                color: UIColor(red: 0.23, green: 0.31, blue: 0.30, alpha: 1),
                radius: 3
            )
            band.position.y = y
            tower.addChild(band)
        }

        let roof = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 250))
            p.addLine(to: CGPoint(x: -185, y: 180))
            p.addLine(to: CGPoint(x: 185, y: 180))
            p.closeSubpath()
            return p
        }())
        roof.fillColor = UIColor(red: 0.19, green: 0.30, blue: 0.31, alpha: 1)
        roof.strokeColor = UIColor(red: 0.60, green: 0.70, blue: 0.69, alpha: 1)
        roof.lineWidth = 6
        tower.addChild(roof)

        addChild(tower)

        addObservationFlag(
            title: "Morning",
            symbol: "☁︎  ☂",
            at: morningPoint,
            name: "scienceMorningWeather"
        )
        addObservationFlag(
            title: "Afternoon",
            symbol: "☁︎  ☂",
            at: afternoonPoint,
            name: "scienceAfternoonWeather"
        )

        addForecastInstrument()
        addCreatureGate()

        _ = worldControl("⌂", name: "scienceWeatherHome", at: CGPoint(x: 55, y: 665), radius: 30)
    }

    private func addObservationFlag(title: String, symbol: String, at point: CGPoint, name: String) {
        let post = ArtSystem.box(
            CGSize(width: 12, height: 150),
            color: UIColor(red: 0.31, green: 0.25, blue: 0.18, alpha: 1),
            radius: 3
        )
        post.position = CGPoint(x: point.x, y: point.y + 55)
        post.name = name
        post.zPosition = 480
        addChild(post)

        let flag = ArtSystem.box(
            CGSize(width: 170, height: 92),
            color: UIColor(red: 0.20, green: 0.38, blue: 0.48, alpha: 1),
            radius: 12
        )
        flag.position = CGPoint(x: point.x + 70, y: point.y + 105)
        flag.name = name
        flag.zPosition = 520
        flag.strokeColor = UIColor(red: 0.75, green: 0.88, blue: 0.92, alpha: 1)
        flag.lineWidth = 3

        let titleLabel = ArtSystem.label(title, size: 18)
        titleLabel.position.y = 22
        titleLabel.name = name
        flag.addChild(titleLabel)

        let symbolLabel = ArtSystem.label(symbol, size: 28)
        symbolLabel.position.y = -18
        symbolLabel.name = name
        flag.addChild(symbolLabel)

        addChild(flag)
    }

    private func addForecastInstrument() {
        let base = ArtSystem.box(
            CGSize(width: 220, height: 140),
            color: UIColor(red: 0.32, green: 0.25, blue: 0.17, alpha: 1),
            radius: 14
        )
        base.position = CGPoint(x: forecastPoint.x, y: forecastPoint.y + 55)
        base.name = "scienceForecastBase"
        base.zPosition = 500
        base.strokeColor = UIColor(red: 0.68, green: 0.56, blue: 0.35, alpha: 1)
        base.lineWidth = 4
        addChild(base)

        let title = ArtSystem.label("Forecast Vane", size: 18)
        title.position = CGPoint(x: 0, y: 45)
        base.addChild(title)

        for (symbol, name, x) in [
            ("☀", "scienceForecastSun", CGFloat(-55)),
            ("☂", "scienceForecastRain", CGFloat(55))
        ] {
            let choice = SKShapeNode(circleOfRadius: 35)
            choice.fillColor = UIColor(red: 0.18, green: 0.28, blue: 0.30, alpha: 1)
            choice.strokeColor = UIColor(red: 0.74, green: 0.80, blue: 0.68, alpha: 1)
            choice.lineWidth = 3
            choice.position = CGPoint(x: x, y: -8)
            choice.name = name
            let label = ArtSystem.label(symbol, size: 32)
            label.name = name
            choice.addChild(label)
            base.addChild(choice)
        }

        forecastNeedle = SKNode()
        forecastNeedle.position = CGPoint(x: forecastPoint.x, y: forecastPoint.y + 108)
        forecastNeedle.zPosition = 540
        let needle = ArtSystem.box(
            CGSize(width: 8, height: 52),
            color: UIColor(red: 0.94, green: 0.71, blue: 0.27, alpha: 1),
            radius: 3
        )
        needle.position.y = 22
        forecastNeedle.addChild(needle)
        addChild(forecastNeedle)
    }

    private func addCreatureGate() {
        gateNode.position = creatureGatePoint
        gateNode.zPosition = 510
        gateNode.name = "scienceCreatureGate"
        addChild(gateNode)
        renderCreatureGate()
    }

    private func renderCreatureGate() {
        gateNode.removeAllChildren()

        let left = ArtSystem.box(
            CGSize(width: 18, height: 150),
            color: UIColor(red: 0.24, green: 0.34, blue: 0.27, alpha: 1),
            radius: 3
        )
        left.position.x = -52
        left.name = "scienceCreatureGate"
        gateNode.addChild(left)

        let right = ArtSystem.box(
            CGSize(width: 18, height: 150),
            color: UIColor(red: 0.24, green: 0.34, blue: 0.27, alpha: 1),
            radius: 3
        )
        right.position.x = 52
        right.name = "scienceCreatureGate"
        gateNode.addChild(right)

        let top = ArtSystem.box(
            CGSize(width: 122, height: 18),
            color: UIColor(red: 0.24, green: 0.34, blue: 0.27, alpha: 1),
            radius: 3
        )
        top.position.y = 66
        top.name = "scienceCreatureGate"
        gateNode.addChild(top)

        let label = ArtSystem.label("Creature Grove →", size: 16)
        label.position.y = 98
        label.name = "scienceCreatureGate"
        gateNode.addChild(label)

        if creatureRouteOpen {
            let glow = SKShapeNode(rectOf: CGSize(width: 96, height: 128), cornerRadius: 20)
            glow.fillColor = UIColor(red: 0.55, green: 0.84, blue: 0.49, alpha: 0.10)
            glow.strokeColor = UIColor(red: 0.68, green: 0.92, blue: 0.58, alpha: 0.9)
            glow.lineWidth = 3
            glow.glowWidth = reducedMotion ? 0 : 10
            glow.name = "scienceCreatureGate"
            gateNode.addChild(glow)
        } else {
            let cloudLock = ArtSystem.label("☁︎", size: 58)
            cloudLock.fontColor = UIColor(white: 0.88, alpha: 0.92)
            cloudLock.name = "scienceCreatureGate"
            gateNode.addChild(cloudLock)
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
        case "scienceMorningWeather":
            if isNear(morningPoint, radius: 140) {
                observeMorning()
            } else {
                instruction.text = "Walk to the morning flag so Milo can inspect it."
                travel(to: CGPoint(x: morningPoint.x - 100, y: 180))
            }

        case "scienceAfternoonWeather":
            if isNear(afternoonPoint, radius: 140) {
                observeAfternoon()
            } else {
                instruction.text = "Walk to the afternoon flag so Milo can compare it."
                travel(to: CGPoint(x: afternoonPoint.x - 95, y: 180))
            }

        case "scienceForecastSun":
            if isNear(forecastPoint, radius: 150) {
                chooseForecast(.sun)
            } else {
                instruction.text = "Walk to the forecast vane before setting it."
                travel(to: CGPoint(x: forecastPoint.x - 105, y: 180))
            }

        case "scienceForecastRain":
            if isNear(forecastPoint, radius: 150) {
                chooseForecast(.rain)
            } else {
                instruction.text = "Walk to the forecast vane before setting it."
                travel(to: CGPoint(x: forecastPoint.x - 105, y: 180))
            }

        case "scienceCreatureGate":
            if creatureRouteOpen {
                if isNear(creatureGatePoint, radius: 120) {
                    state.travel(to: .scienceCreatureGrove)
                } else {
                    instruction.text = "The Creature Grove route is open. Walk to the gate to continue."
                    travel(to: CGPoint(x: creatureGatePoint.x - 75, y: 180))
                }
            } else {
                instruction.text = "The cloud lock is still closed. Compare both observations and set the forecast vane."
            }

        case "scienceWeatherHome":
            state.travel(to: .storyTree)

        default:
            walkIfValid(point)
        }
    }

    private func observeMorning() {
        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)
        state.scienceObserveMorningWeather()
        instruction.text = "Morning: cloudy with rain. Milo says to compare another observation before forecasting."
    }

    private func observeAfternoon() {
        guard weatherStage != .arrive else {
            instruction.text = "Observe the morning flag first so we have something to compare."
            return
        }
        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)
        state.scienceObserveAfternoonWeather()
        instruction.text = "Afternoon: cloudy with rain again. The same condition appeared twice. What is likely next?"
    }

    private func chooseForecast(_ choice: ForecastChoice) {
        guard weatherStage == .afternoonObserved || weatherStage == .complete else {
            instruction.text = "The forecast vane needs two observations first."
            return
        }

        state.scienceChooseForecast(choice)
        valkyrie.pose(.interact)
        let targetAngle: CGFloat = choice == .sun ? -0.55 : 0.55
        forecastNeedle.run(.rotate(toAngle: targetAngle, duration: reducedMotion ? 0 : 0.25))
        renderCreatureGate()

        if choice == .rain {
            state.audio.play("success")
            instruction.text = "Both observations were rainy, so rain is a reasonable next prediction—not a certainty. The Creature Grove route opened."
        } else {
            milo.inspect(reducedMotion: reducedMotion)
            instruction.text = "Sun could happen, but it does not match the pattern we observed. Compare the two rainy flags again."
        }
    }
}
