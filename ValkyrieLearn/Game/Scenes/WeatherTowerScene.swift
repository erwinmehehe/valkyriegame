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
        if let backdrop = ArtSystem.paintedBackdrop(
            "StarlightIsles",
            size: size,
            tint: UIColor(red: 0.45, green: 0.76, blue: 0.88, alpha: 1),
            blend: 0.22,
            dim: 0.14
        ) {
            backdrop.zPosition = -300
            backdrop.name = "weatherBackdropHD"
            addChild(backdrop)
        }

        let horizonWash = ArtSystem.box(
            CGSize(width: 1280, height: 250),
            color: UIColor(red: 0.09, green: 0.18, blue: 0.25, alpha: 0.34),
            radius: 0
        )
        horizonWash.strokeColor = .clear
        horizonWash.position = CGPoint(x: 640, y: 116)
        horizonWash.zPosition = -145
        addChild(horizonWash)

        for (x, y, w, h, alpha) in [
            (CGFloat(235), CGFloat(575), CGFloat(250), CGFloat(78), CGFloat(0.20)),
            (CGFloat(535), CGFloat(620), CGFloat(330), CGFloat(92), CGFloat(0.18)),
            (CGFloat(900), CGFloat(560), CGFloat(280), CGFloat(84), CGFloat(0.17))
        ] {
            let cloud = SKShapeNode(ellipseOf: CGSize(width: w, height: h))
            cloud.fillColor = UIColor(white: 0.96, alpha: alpha)
            cloud.strokeColor = UIColor(white: 1, alpha: alpha * 0.7)
            cloud.lineWidth = 2
            cloud.position = CGPoint(x: x, y: y)
            cloud.zPosition = -170
            addChild(cloud)
            if !reducedMotion {
                cloud.run(.repeatForever(.sequence([
                    .moveBy(x: 18, y: 0, duration: 5.5),
                    .moveBy(x: -18, y: 0, duration: 5.5)
                ])))
            }
        }

        let terrace = ArtSystem.panel(
            CGSize(width: 1160, height: 112),
            fill: UIColor(red: 0.14, green: 0.18, blue: 0.20, alpha: 0.60),
            stroke: UIColor(red: 0.65, green: 0.57, blue: 0.38, alpha: 0.56),
            radius: 38,
            lineWidth: 2.5,
            shadowAlpha: 0.16,
            innerHighlight: UIColor(red: 0.85, green: 0.74, blue: 0.52, alpha: 0.04)
        )
        terrace.position = CGPoint(x: 640, y: 190)
        terrace.zPosition = 24
        terrace.name = "weatherTerrace"
        addChild(terrace)

        let terraceInlay = ArtSystem.box(
            CGSize(width: 1020, height: 5),
            color: UIColor(red: 0.82, green: 0.66, blue: 0.36, alpha: 0.52),
            radius: 2
        )
        terraceInlay.position = CGPoint(x: 640, y: 235)
        terraceInlay.strokeColor = .clear
        terraceInlay.zPosition = 28
        addChild(terraceInlay)

        for x in stride(from: CGFloat(200), through: CGFloat(1100), by: CGFloat(150)) {
            let lamp = ArtSystem.medallion(
                radius: 10,
                fill: UIColor(red: 0.98, green: 0.73, blue: 0.28, alpha: 0.72),
                stroke: UIColor(red: 1.0, green: 0.89, blue: 0.60, alpha: 0.86),
                glow: reducedMotion ? 0 : 5
            )
            lamp.position = CGPoint(x: x, y: 240)
            lamp.zPosition = 31
            addChild(lamp)
        }

        let tower = SKNode()
        tower.position = CGPoint(x: 715, y: 405)
        tower.zPosition = -30
        tower.name = "weatherTowerStructure"

        let shaft = ArtSystem.panel(
            CGSize(width: 274, height: 372),
            fill: UIColor(red: 0.12, green: 0.20, blue: 0.24, alpha: 0.82),
            stroke: UIColor(red: 0.61, green: 0.74, blue: 0.75, alpha: 0.72),
            radius: 38,
            lineWidth: 4,
            shadowAlpha: 0.24,
            innerHighlight: UIColor(red: 0.66, green: 0.92, blue: 0.95, alpha: 0.05)
        )
        shaft.name = "weatherTowerShaft"
        tower.addChild(shaft)

        let observationGlass = ArtSystem.panel(
            CGSize(width: 184, height: 226),
            fill: UIColor(red: 0.12, green: 0.36, blue: 0.43, alpha: 0.16),
            stroke: UIColor(red: 0.62, green: 0.88, blue: 0.91, alpha: 0.48),
            radius: 42,
            lineWidth: 2,
            shadowAlpha: 0.08,
            innerHighlight: UIColor(white: 1, alpha: 0.05)
        )
        observationGlass.position = CGPoint(x: 0, y: 12)
        observationGlass.name = "weatherObservationGlass"
        tower.addChild(observationGlass)

        for x in [CGFloat(-148), CGFloat(148)] {
            let buttress = ArtSystem.panel(
                CGSize(width: 34, height: 320),
                fill: UIColor(red: 0.10, green: 0.17, blue: 0.20, alpha: 0.84),
                stroke: UIColor(red: 0.45, green: 0.58, blue: 0.59, alpha: 0.56),
                radius: 15,
                lineWidth: 2,
                shadowAlpha: 0.18
            )
            buttress.position = CGPoint(x: x, y: -18)
            buttress.name = "weatherTowerButtress"
            tower.addChild(buttress)
        }

        for y in [CGFloat(-112), CGFloat(-18), CGFloat(76)] {
            let band = ArtSystem.box(
                CGSize(width: 294, height: 9),
                color: UIColor(red: 0.52, green: 0.43, blue: 0.27, alpha: 0.84),
                radius: 4
            )
            band.strokeColor = UIColor(red: 0.87, green: 0.69, blue: 0.38, alpha: 0.54)
            band.lineWidth = 1
            band.position.y = y
            band.name = "weatherTowerBand"
            tower.addChild(band)
        }

        for y in [CGFloat(-70), CGFloat(40), CGFloat(135)] {
            let window = ArtSystem.medallion(
                radius: 28,
                fill: UIColor(red: 0.12, green: 0.42, blue: 0.52, alpha: 0.86),
                stroke: UIColor(red: 0.70, green: 0.92, blue: 0.94, alpha: 0.90),
                glow: reducedMotion ? 0 : 5
            )
            window.position = CGPoint(x: 0, y: y)
            tower.addChild(window)
            let spark = ArtSystem.label("✦", size: 18)
            spark.fontColor = UIColor(red: 0.94, green: 0.97, blue: 0.78, alpha: 0.92)
            window.addChild(spark)
        }

        let roof = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 255))
            p.addLine(to: CGPoint(x: -205, y: 170))
            p.addLine(to: CGPoint(x: 205, y: 170))
            p.closeSubpath()
            return p
        }())
        roof.fillColor = UIColor(red: 0.08, green: 0.23, blue: 0.28, alpha: 0.92)
        roof.strokeColor = UIColor(red: 0.76, green: 0.66, blue: 0.39, alpha: 0.76)
        roof.lineWidth = 5
        roof.name = "weatherTowerRoof"
        tower.addChild(roof)

        let roofTrim = ArtSystem.box(
            CGSize(width: 330, height: 8),
            color: UIColor(red: 0.86, green: 0.68, blue: 0.34, alpha: 0.72),
            radius: 4
        )
        roofTrim.position = CGPoint(x: 0, y: 171)
        roofTrim.name = "weatherTowerRoofTrim"
        tower.addChild(roofTrim)

        let cupola = ArtSystem.panel(
            CGSize(width: 105, height: 72),
            fill: UIColor(red: 0.12, green: 0.36, blue: 0.42, alpha: 0.82),
            stroke: UIColor(red: 0.79, green: 0.69, blue: 0.42, alpha: 0.78),
            radius: 18,
            lineWidth: 4,
            shadowAlpha: 0.22
        )
        cupola.position = CGPoint(x: 0, y: 225)
        tower.addChild(cupola)

        let mast = ArtSystem.box(
            CGSize(width: 8, height: 96),
            color: UIColor(red: 0.82, green: 0.64, blue: 0.30, alpha: 1),
            radius: 3
        )
        mast.position = CGPoint(x: 0, y: 300)
        tower.addChild(mast)

        let vane = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -62, y: 0))
            p.addLine(to: CGPoint(x: 48, y: 0))
            p.addLine(to: CGPoint(x: 30, y: 16))
            p.move(to: CGPoint(x: 48, y: 0))
            p.addLine(to: CGPoint(x: 30, y: -16))
            return p
        }())
        vane.strokeColor = UIColor(red: 1.0, green: 0.80, blue: 0.38, alpha: 1)
        vane.lineWidth = 6
        vane.position = CGPoint(x: 0, y: 337)
        tower.addChild(vane)

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
        let root = SKNode()
        root.position = point
        root.name = name
        root.zPosition = 520

        let hit = SKShapeNode(rectOf: CGSize(width: 190, height: 155), cornerRadius: 24)
        hit.fillColor = UIColor(white: 1, alpha: 0.001)
        hit.strokeColor = .clear
        hit.position = CGPoint(x: 25, y: 58)
        hit.name = name
        root.addChild(hit)

        let post = ArtSystem.box(
            CGSize(width: 14, height: 155),
            color: UIColor(red: 0.30, green: 0.21, blue: 0.13, alpha: 1),
            radius: 5
        )
        post.strokeColor = UIColor(red: 0.68, green: 0.51, blue: 0.28, alpha: 0.82)
        post.lineWidth = 2
        post.position = CGPoint(x: -58, y: 48)
        post.name = name
        root.addChild(post)

        let finial = ArtSystem.medallion(
            radius: 10,
            fill: UIColor(red: 0.92, green: 0.70, blue: 0.30, alpha: 1),
            stroke: UIColor(red: 1.0, green: 0.87, blue: 0.52, alpha: 1)
        )
        finial.position = CGPoint(x: -58, y: 132)
        finial.name = name
        root.addChild(finial)

        let pennant = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -50, y: 110))
            p.addLine(to: CGPoint(x: 100, y: 110))
            p.addLine(to: CGPoint(x: 82, y: 66))
            p.addLine(to: CGPoint(x: 100, y: 26))
            p.addLine(to: CGPoint(x: -50, y: 26))
            p.closeSubpath()
            return p
        }())
        pennant.fillColor = UIColor(red: 0.09, green: 0.31, blue: 0.43, alpha: 0.94)
        pennant.strokeColor = UIColor(red: 0.70, green: 0.87, blue: 0.92, alpha: 0.92)
        pennant.lineWidth = 3
        pennant.name = name
        root.addChild(pennant)

        let titleLabel = ArtSystem.label(title, size: 17)
        titleLabel.position = CGPoint(x: 20, y: 86)
        titleLabel.fontColor = UIColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1)
        titleLabel.name = name
        root.addChild(titleLabel)

        let weatherSeal = ArtSystem.medallion(
            radius: 27,
            fill: UIColor(red: 0.12, green: 0.22, blue: 0.30, alpha: 0.92),
            stroke: UIColor(red: 0.75, green: 0.88, blue: 0.89, alpha: 0.80)
        )
        weatherSeal.position = CGPoint(x: 20, y: 48)
        weatherSeal.name = name
        root.addChild(weatherSeal)

        let symbolLabel = ArtSystem.label(symbol, size: 23)
        symbolLabel.name = name
        weatherSeal.addChild(symbolLabel)

        addChild(root)
    }

    private func addForecastInstrument() {
        let root = SKNode()
        root.position = forecastPoint
        root.name = "scienceForecastBase"
        root.zPosition = 540
        addChild(root)

        let dial = ArtSystem.gear(radius: 82, symbol: "")
        dial.position = CGPoint(x: 0, y: 62)
        dial.name = "scienceForecastBase"
        root.addChild(dial)

        let plate = ArtSystem.medallion(
            radius: 65,
            fill: UIColor(red: 0.10, green: 0.20, blue: 0.25, alpha: 0.96),
            stroke: UIColor(red: 0.84, green: 0.69, blue: 0.36, alpha: 0.92),
            glow: reducedMotion ? 0 : 3
        )
        plate.position = CGPoint(x: 0, y: 62)
        plate.name = "scienceForecastBase"
        root.addChild(plate)

        let title = ArtSystem.plaque(
            CGSize(width: 172, height: 38),
            fill: UIColor(red: 0.20, green: 0.14, blue: 0.10, alpha: 0.94),
            stroke: UIColor(red: 0.86, green: 0.69, blue: 0.36, alpha: 0.92),
            radius: 16
        )
        title.position = CGPoint(x: 0, y: 144)
        title.name = "scienceForecastBase"
        root.addChild(title)

        let titleLabel = ArtSystem.label("FORECAST VANE", size: 15)
        titleLabel.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.65, alpha: 1)
        title.addChild(titleLabel)

        for (symbol, name, x, tint) in [
            ("☀", "scienceForecastSun", CGFloat(-55), UIColor(red: 0.98, green: 0.71, blue: 0.24, alpha: 1)),
            ("☂", "scienceForecastRain", CGFloat(55), UIColor(red: 0.36, green: 0.62, blue: 0.92, alpha: 1))
        ] {
            let choice = ArtSystem.medallion(
                radius: 34,
                fill: UIColor(red: 0.08, green: 0.16, blue: 0.21, alpha: 0.98),
                stroke: tint.withAlphaComponent(0.92),
                glow: reducedMotion ? 0 : 2
            )
            choice.position = CGPoint(x: x, y: 47)
            choice.name = name
            let label = ArtSystem.label(symbol, size: 30)
            label.name = name
            choice.addChild(label)
            root.addChild(choice)
        }

        forecastNeedle = SKNode()
        forecastNeedle.position = CGPoint(x: 0, y: 104)
        forecastNeedle.zPosition = 8
        let needle = ArtSystem.box(
            CGSize(width: 7, height: 54),
            color: UIColor(red: 1.0, green: 0.76, blue: 0.28, alpha: 1),
            radius: 3
        )
        needle.position.y = 20
        forecastNeedle.addChild(needle)
        let pivot = ArtSystem.medallion(
            radius: 9,
            fill: UIColor(red: 0.95, green: 0.74, blue: 0.31, alpha: 1),
            stroke: UIColor(red: 1.0, green: 0.90, blue: 0.58, alpha: 1)
        )
        forecastNeedle.addChild(pivot)
        root.addChild(forecastNeedle)
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

        let arch = SKShapeNode(rectOf: CGSize(width: 118, height: 150), cornerRadius: 52)
        arch.fillColor = UIColor(red: 0.08, green: 0.20, blue: 0.17, alpha: 0.88)
        arch.strokeColor = creatureRouteOpen
            ? UIColor(red: 0.60, green: 0.90, blue: 0.58, alpha: 1)
            : UIColor(red: 0.48, green: 0.58, blue: 0.50, alpha: 0.88)
        arch.lineWidth = 6
        arch.name = "scienceCreatureGate"
        gateNode.addChild(arch)

        let inner = SKShapeNode(rectOf: CGSize(width: 76, height: 106), cornerRadius: 32)
        inner.fillColor = UIColor(red: 0.05, green: 0.11, blue: 0.10, alpha: 0.92)
        inner.strokeColor = UIColor(white: 1, alpha: 0.12)
        inner.lineWidth = 2
        inner.name = "scienceCreatureGate"
        gateNode.addChild(inner)

        let crest = ArtSystem.medallion(
            radius: 20,
            fill: creatureRouteOpen
                ? UIColor(red: 0.20, green: 0.48, blue: 0.28, alpha: 0.96)
                : UIColor(red: 0.20, green: 0.28, blue: 0.26, alpha: 0.96),
            stroke: creatureRouteOpen
                ? UIColor(red: 0.70, green: 0.96, blue: 0.64, alpha: 1)
                : UIColor(red: 0.60, green: 0.68, blue: 0.62, alpha: 0.72),
            glow: creatureRouteOpen && !reducedMotion ? 7 : 0
        )
        crest.position = CGPoint(x: 0, y: 71)
        crest.name = "scienceCreatureGate"
        gateNode.addChild(crest)

        let crestLabel = ArtSystem.label(creatureRouteOpen ? "✦" : "☁︎", size: 24)
        crestLabel.name = "scienceCreatureGate"
        crest.addChild(crestLabel)

        let labelPlate = ArtSystem.plaque(
            CGSize(width: 150, height: 34),
            fill: UIColor(red: 0.07, green: 0.15, blue: 0.14, alpha: 0.90),
            stroke: UIColor(red: 0.50, green: 0.69, blue: 0.52, alpha: 0.64),
            radius: 15
        )
        labelPlate.position = CGPoint(x: 0, y: 111)
        labelPlate.name = "scienceCreatureGate"
        gateNode.addChild(labelPlate)

        let label = ArtSystem.label("CREATURE GROVE", size: 12)
        label.fontColor = UIColor(red: 0.90, green: 0.98, blue: 0.88, alpha: 1)
        label.name = "scienceCreatureGate"
        labelPlate.addChild(label)

        if creatureRouteOpen && !reducedMotion {
            inner.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.62, duration: 0.9),
                .fadeAlpha(to: 1.0, duration: 0.9)
            ])))
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
