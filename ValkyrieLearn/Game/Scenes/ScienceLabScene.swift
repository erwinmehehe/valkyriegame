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
        applyScienceHUDPolish()
        pip.isHidden = true
        pip.position = CGPoint(x: -500, y: -500)

        milo.position = CGPoint(x: 320, y: 190)
        milo.reducedMotion = reducedMotion
        milo.setScale(0.82)
        addChild(milo)

        valkyrie.position = CGPoint(x: 175, y: 175)
        valkyrie.setScale(0.5)
        renderPlant()
        renderGate()

        instruction.text = "Milo noticed something at the seed bench. Walk over and inspect it."
        refreshGuidanceCue()
    }

    private func applyScienceHUDPolish() {
        childNode(withName: "worldTitleBackdrop")?.removeFromParent()
        childNode(withName: "worldTitle")?.removeFromParent()

        let titlePlate = ArtSystem.plaque(
            CGSize(width: 330, height: 42),
            fill: UIColor(red: 0.045, green: 0.065, blue: 0.13, alpha: 0.88),
            stroke: UIColor(red: 0.42, green: 0.82, blue: 0.61, alpha: 0.54),
            radius: 15
        )
        titlePlate.position = CGPoint(x: 270, y: 672)
        titlePlate.zPosition = 1988
        titlePlate.name = "worldTitleBackdrop"
        addChild(titlePlate)

        let title = ArtSystem.label(worldTitle, size: 20)
        title.fontName = "Georgia-Bold"
        title.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.80, alpha: 1)
        title.horizontalAlignmentMode = .left
        title.position = CGPoint(x: 115, y: 672)
        title.zPosition = 2000
        title.name = "worldTitle"
        addChild(title)

        if let emblem = childNode(withName: "decorativeWorldEmblem") {
            emblem.position = CGPoint(x: 111, y: 672)
            emblem.setScale(0.72)
        }

        if let plate = childNode(withName: "instructionBackdrop") {
            plate.xScale = 0.66
            plate.yScale = 0.80
            plate.position = CGPoint(x: 710, y: 46)
        }
        instruction.position = CGPoint(x: 710, y: 46)
        instruction.fontName = "AvenirNext-Medium"
        instruction.fontSize = 18
        instruction.preferredMaxLayoutWidth = 620
        instruction.numberOfLines = 2
    }

    private func buildScienceHomeControl() {
        let root = SKNode()
        root.name = "scienceHome"
        root.position = CGPoint(x: 55, y: 672)
        root.zPosition = 2100

        let medallion = ArtSystem.medallion(
            radius: 22,
            fill: UIColor(red: 0.05, green: 0.06, blue: 0.14, alpha: 0.92),
            stroke: UIColor(red: 0.42, green: 0.82, blue: 0.61, alpha: 0.50),
            glow: reducedMotion ? 0 : 1
        )
        medallion.name = "scienceHome"
        medallion.addChild(ArtSystem.label("⌂", size: 18))
        root.addChild(medallion)

        let hit = SKShapeNode(circleOfRadius: 30)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.name = "scienceHome"
        hit.zPosition = 2
        root.addChild(hit)

        makeAccessible(root, label: "Return to Story Tree")
        addChild(root)
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
            let preparedTexture = ArtSystem.retinaEnhancedTexture(
                greenhouseTexture,
                cacheKey: "word-garden-upper-crop",
                targetPoints: size,
                sharpness: 0.22
            ) ?? greenhouseTexture
            let scenic = SKSpriteNode(
                texture: preparedTexture,
                color: UIColor(red: 0.72, green: 0.92, blue: 0.78, alpha: 1),
                size: size
            )
            scenic.colorBlendFactor = 0.08
            scenic.position = CGPoint(x: 640, y: 360)
            scenic.zPosition = -230
            scenic.alpha = 0.94
            scenic.name = "scienceGreenhouseBackdropHD"
            scenic.userData = NSMutableDictionary(dictionary: [
                "retinaPrepared": true,
                "sourceAsset": "WordGardenSourceAtlas",
                "sourceCrop": "word-garden-upper-crop"
            ])
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
            color: UIColor(red: 0.78, green: 0.94, blue: 0.91, alpha: 0.08),
            radius: 22
        )
        glass.strokeColor = UIColor(red: 0.82, green: 0.96, blue: 0.91, alpha: 0.68)
        glass.lineWidth = 3
        glass.name = "scienceGreenhouseGlass"
        house.addChild(glass)

        // Use fewer, slimmer mullions so the painted garden remains the dominant
        // visual layer instead of reading like a flat engineering grid.
        for x in [CGFloat(-360), -180, 0, 180, 360] {
            let frame = ArtSystem.box(
                CGSize(width: 7, height: 405),
                color: UIColor(red: 0.12, green: 0.28, blue: 0.24, alpha: 0.88),
                radius: 3
            )
            frame.position.x = x
            frame.zPosition = 2
            frame.name = "scienceGreenhouseMullion"
            house.addChild(frame)

            let brassCap = ArtSystem.box(
                CGSize(width: 13, height: 16),
                color: UIColor(red: 0.78, green: 0.58, blue: 0.25, alpha: 0.88),
                radius: 4
            )
            brassCap.position = CGPoint(x: x, y: -201)
            brassCap.zPosition = 3
            brassCap.name = "scienceGreenhouseMullion"
            house.addChild(brassCap)
        }

        for y in [CGFloat(-130), 0, 130] {
            let frame = ArtSystem.box(
                CGSize(width: 820, height: 5),
                color: UIColor(red: 0.16, green: 0.34, blue: 0.29, alpha: 0.54),
                radius: 2
            )
            frame.position.y = y
            frame.zPosition = 2
            frame.name = "scienceGreenhouseMullion"
            house.addChild(frame)
        }

        let lowerSill = ArtSystem.box(
            CGSize(width: 848, height: 16),
            color: UIColor(red: 0.30, green: 0.23, blue: 0.14, alpha: 0.94),
            radius: 5
        )
        lowerSill.position.y = -212
        lowerSill.zPosition = 3
        lowerSill.name = "scienceGreenhouseSill"
        if let timber = ArtSystem.texture("BridgeOakPlank") {
            lowerSill.fillColor = .white
            lowerSill.fillTexture = timber
            lowerSill.strokeColor = .clear
        }
        house.addChild(lowerSill)

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

        let ridge = ArtSystem.box(
            CGSize(width: 120, height: 12),
            color: UIColor(red: 0.22, green: 0.32, blue: 0.23, alpha: 0.94),
            radius: 4
        )
        ridge.position = CGPoint(x: 0, y: 287)
        ridge.name = "scienceGreenhouseRidge"
        house.addChild(ridge)

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
        buildGreenhouseConceptAccents()

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
            CGSize(width: 1110, height: 86),
            fill: UIColor(red: 0.39, green: 0.30, blue: 0.19, alpha: 0.24),
            stroke: UIColor(red: 0.69, green: 0.57, blue: 0.36, alpha: 0.34),
            radius: 43,
            lineWidth: 3,
            shadowAlpha: 0.08,
            innerHighlight: UIColor(red: 0.82, green: 0.70, blue: 0.47, alpha: 0.06)
        )
        path.position = CGPoint(x: 640, y: 184)
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
            CGSize(width: 118, height: 156),
            fill: UIColor(red: 0.06, green: 0.28, blue: 0.34, alpha: 0.90),
            stroke: UIColor(red: 0.52, green: 0.80, blue: 0.82, alpha: 0.70),
            radius: 34,
            lineWidth: 3,
            shadowAlpha: 0.20,
            innerHighlight: UIColor(red: 0.74, green: 0.96, blue: 0.96, alpha: 0.06)
        )
        waterTank.position = CGPoint(x: 355, y: 338)
        waterTank.name = "scienceWaterTank"
        waterTank.zPosition = 260
        addChild(waterTank)

        for y in [CGFloat(-64), 64] {
            let band = ArtSystem.box(
                CGSize(width: 104, height: 12),
                color: UIColor(red: 0.70, green: 0.53, blue: 0.24, alpha: 0.90),
                radius: 5
            )
            band.position.y = y
            band.name = "scienceWaterTank"
            waterTank.addChild(band)
        }

        let gauge = ArtSystem.panel(
            CGSize(width: 54, height: 100),
            fill: UIColor(red: 0.06, green: 0.16, blue: 0.20, alpha: 0.86),
            stroke: UIColor(red: 0.62, green: 0.88, blue: 0.90, alpha: 0.56),
            radius: 22,
            lineWidth: 2,
            shadowAlpha: 0.10
        )
        gauge.name = "scienceWaterGauge"
        gauge.position.y = -2
        waterTank.addChild(gauge)

        let waterFill = ArtSystem.box(
            CGSize(width: 34, height: 52),
            color: UIColor(red: 0.24, green: 0.72, blue: 0.86, alpha: 0.74),
            radius: 15
        )
        waterFill.position.y = -17
        waterFill.name = "scienceWaterGauge"
        gauge.addChild(waterFill)

        let droplet = ArtSystem.label("◆", size: 15)
        droplet.fontColor = UIColor(red: 0.68, green: 0.94, blue: 1.0, alpha: 1)
        droplet.position.y = 27
        droplet.name = "scienceWaterGauge"
        gauge.addChild(droplet)

        let tankLabel = ArtSystem.label("H₂O", size: 13)
        tankLabel.position.y = 50
        tankLabel.fontColor = UIColor(red: 0.86, green: 0.96, blue: 1.0, alpha: 1)
        tankLabel.name = "scienceWaterTank"
        waterTank.addChild(tankLabel)

        let pipe = ArtSystem.box(
            CGSize(width: 245, height: 12),
            color: UIColor(red: 0.27, green: 0.42, blue: 0.40, alpha: 0.96),
            radius: 6
        )
        pipe.position = CGPoint(x: 510, y: 300)
        pipe.zPosition = 250
        pipe.name = "scienceWaterPipe"
        addChild(pipe)

        let valve = ArtSystem.gear(radius: 42, symbol: "")
        valve.position = waterValvePoint
        valve.name = "scienceWaterValve"
        valve.zPosition = 720
        let drop = ArtSystem.label("💧", size: 27)
        drop.name = "scienceWaterValve"
        valve.addChild(drop)
        addChild(valve)

        let prismPedestal = ArtSystem.panel(
            CGSize(width: 112, height: 48),
            fill: UIColor(red: 0.24, green: 0.18, blue: 0.12, alpha: 0.94),
            stroke: UIColor(red: 0.82, green: 0.63, blue: 0.30, alpha: 0.78),
            radius: 16,
            lineWidth: 3,
            shadowAlpha: 0.20
        )
        prismPedestal.position = CGPoint(x: sunPrismPoint.x, y: sunPrismPoint.y - 42)
        prismPedestal.name = "scienceSunPrism"
        prismPedestal.zPosition = 710
        addChild(prismPedestal)

        let prism = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 52))
            p.addLine(to: CGPoint(x: -42, y: -34))
            p.addLine(to: CGPoint(x: 42, y: -34))
            p.closeSubpath()
            return p
        }())
        prism.position = sunPrismPoint
        prism.name = "scienceSunPrism"
        prism.zPosition = 720
        prism.fillColor = UIColor(red: 0.76, green: 0.95, blue: 1.0, alpha: 0.24)
        prism.strokeColor = UIColor(red: 0.98, green: 0.80, blue: 0.38, alpha: 0.94)
        prism.lineWidth = 5
        prism.glowWidth = reducedMotion ? 0 : 4
        addChild(prism)

        let facet = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: 35))
            p.addLine(to: CGPoint(x: -24, y: -20))
            p.addLine(to: CGPoint(x: 25, y: -20))
            p.closeSubpath()
            return p
        }())
        facet.fillColor = UIColor(red: 0.96, green: 0.86, blue: 0.42, alpha: 0.28)
        facet.strokeColor = UIColor(white: 1, alpha: 0.48)
        facet.lineWidth = 2
        facet.name = "scienceSunPrism"
        prism.addChild(facet)

        let beamPath = CGMutablePath()
        beamPath.move(to: CGPoint(x: 1015, y: 385))
        beamPath.addLine(to: CGPoint(x: 955, y: 295))
        let beam = SKShapeNode(path: beamPath)
        beam.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.42, alpha: 0.34)
        beam.lineWidth = 8
        beam.glowWidth = reducedMotion ? 0 : 5
        beam.zPosition = 280
        beam.name = "sciencePrismBeam"
        addChild(beam)

        let sun = ArtSystem.label("☀", size: 34)
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

        buildScienceHomeControl()
    }

    private func buildGreenhouseConceptAccents() {
        let root = SKNode()
        root.name = "decorativeScienceConceptAccents"
        root.zPosition = -62
        root.isUserInteractionEnabled = false

        let dome = SKShapeNode(ellipseOf: CGSize(width: 950, height: 560))
        dome.position = CGPoint(x: 720, y: 390)
        dome.fillColor = .clear
        dome.strokeColor = UIColor(red: 0.86, green: 0.67, blue: 0.31, alpha: 0.16)
        dome.lineWidth = 4
        dome.name = "decorativeScienceDome"
        root.addChild(dome)

        let domeInner = SKShapeNode(ellipseOf: CGSize(width: 875, height: 500))
        domeInner.position = dome.position
        domeInner.fillColor = .clear
        domeInner.strokeColor = UIColor(red: 0.72, green: 0.91, blue: 0.86, alpha: 0.10)
        domeInner.lineWidth = 2
        domeInner.name = "decorativeScienceDome"
        root.addChild(domeInner)

        for (index, x) in [CGFloat(235), 615, 1035].enumerated() {
            let hanger = SKNode()
            hanger.position = CGPoint(x: x, y: 585 - CGFloat(index % 2) * 34)
            hanger.name = "decorativeScienceHangingPlanter\(index)"

            let cord = SKShapeNode(rectOf: CGSize(width: 3, height: 74), cornerRadius: 1)
            cord.fillColor = UIColor(red: 0.54, green: 0.39, blue: 0.19, alpha: 0.74)
            cord.strokeColor = .clear
            cord.position.y = 36
            hanger.addChild(cord)

            let pot = SKShapeNode(path: {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: -30, y: 8))
                p.addLine(to: CGPoint(x: 30, y: 8))
                p.addLine(to: CGPoint(x: 22, y: -28))
                p.addLine(to: CGPoint(x: -22, y: -28))
                p.closeSubpath()
                return p
            }())
            pot.fillColor = UIColor(red: 0.49, green: 0.28, blue: 0.13, alpha: 0.96)
            pot.strokeColor = UIColor(red: 0.85, green: 0.63, blue: 0.29, alpha: 0.58)
            pot.lineWidth = 2
            hanger.addChild(pot)

            for leafIndex in 0..<5 {
                let leaf = SKShapeNode(ellipseOf: CGSize(width: 28, height: 15))
                leaf.fillColor = leafIndex.isMultiple(of: 2)
                    ? UIColor(red: 0.26, green: 0.62, blue: 0.31, alpha: 0.94)
                    : UIColor(red: 0.42, green: 0.72, blue: 0.38, alpha: 0.92)
                leaf.strokeColor = .clear
                leaf.position = CGPoint(
                    x: CGFloat(leafIndex - 2) * 13,
                    y: 18 + CGFloat(abs(leafIndex - 2)) * 4
                )
                leaf.zRotation = CGFloat(leafIndex - 2) * 0.28
                hanger.addChild(leaf)
            }

            root.addChild(hanger)
        }

        for offset in [CGFloat(-60), 0, 60] {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 1160 + offset, y: 690))
            path.addLine(to: CGPoint(x: 900 + offset * 0.20, y: 310))
            let ray = SKShapeNode(path: path)
            ray.strokeColor = UIColor(red: 1.0, green: 0.88, blue: 0.46, alpha: 0.10)
            ray.lineWidth = 24
            ray.name = "decorativeScienceSunShaft"
            root.addChild(ray)
        }

        let cloche = SKShapeNode(ellipseOf: CGSize(width: 194, height: 214))
        cloche.position = CGPoint(x: seedBenchPoint.x, y: seedBenchPoint.y + 74)
        cloche.fillColor = UIColor(red: 0.78, green: 0.96, blue: 0.94, alpha: 0.055)
        cloche.strokeColor = UIColor(red: 0.80, green: 0.96, blue: 0.92, alpha: 0.25)
        cloche.lineWidth = 3
        cloche.name = "decorativeSciencePlantCloche"
        root.addChild(cloche)

        let clocheBase = ArtSystem.box(
            CGSize(width: 190, height: 12),
            color: UIColor(red: 0.68, green: 0.49, blue: 0.22, alpha: 0.68),
            radius: 5
        )
        clocheBase.position = CGPoint(x: seedBenchPoint.x, y: seedBenchPoint.y - 30)
        clocheBase.strokeColor = .clear
        clocheBase.name = "decorativeSciencePlantCloche"
        root.addChild(clocheBase)

        let railPath = CGMutablePath()
        railPath.move(to: CGPoint(x: waterValvePoint.x, y: 208))
        railPath.addCurve(
            to: CGPoint(x: sunPrismPoint.x, y: 214),
            control1: CGPoint(x: 560, y: 160),
            control2: CGPoint(x: 810, y: 162)
        )
        let rail = SKShapeNode(path: railPath)
        rail.strokeColor = UIColor(red: 0.88, green: 0.65, blue: 0.28, alpha: 0.32)
        rail.lineWidth = 5
        rail.name = "decorativeScienceExperimentRail"
        root.addChild(rail)

        let waterOrb = SKShapeNode(circleOfRadius: 56)
        waterOrb.position = CGPoint(x: 355, y: 352)
        waterOrb.fillColor = UIColor(red: 0.23, green: 0.71, blue: 0.88, alpha: 0.12)
        waterOrb.strokeColor = UIColor(red: 0.55, green: 0.90, blue: 0.98, alpha: 0.40)
        waterOrb.lineWidth = 3
        waterOrb.glowWidth = reducedMotion ? 0 : 5
        waterOrb.name = "decorativeScienceWaterOrb"
        root.addChild(waterOrb)

        let waterDrop = ArtSystem.label("◆", size: 22)
        waterDrop.fontColor = UIColor(red: 0.58, green: 0.92, blue: 1.0, alpha: 0.86)
        waterDrop.name = "decorativeScienceWaterOrb"
        waterOrb.addChild(waterDrop)

        let board = ArtSystem.panel(
            CGSize(width: 176, height: 106),
            fill: UIColor(red: 0.07, green: 0.19, blue: 0.16, alpha: 0.62),
            stroke: UIColor(red: 0.68, green: 0.52, blue: 0.25, alpha: 0.38),
            radius: 14,
            lineWidth: 2,
            shadowAlpha: 0.06,
            innerHighlight: UIColor(red: 0.76, green: 0.94, blue: 0.72, alpha: 0.03)
        )
        board.position = CGPoint(x: 1070, y: 418)
        board.name = "decorativeScienceObservationBoard"
        root.addChild(board)

        for (index, symbol) in ["•", "↗", "✿"].enumerated() {
            let icon = ArtSystem.label(symbol, size: index == 1 ? 24 : 28)
            icon.position = CGPoint(x: CGFloat(index - 1) * 52, y: 4)
            icon.fontColor = index == 2
                ? UIColor(red: 0.80, green: 0.95, blue: 0.48, alpha: 0.92)
                : UIColor(red: 0.75, green: 0.93, blue: 0.76, alpha: 0.86)
            icon.name = "decorativeScienceObservationBoard"
            board.addChild(icon)
        }

        addChild(root)
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

            let aura = SKShapeNode(circleOfRadius: 48)
            aura.fillColor = UIColor(red: 0.90, green: 0.90, blue: 0.36, alpha: 0.08)
            aura.strokeColor = UIColor(red: 1.0, green: 0.82, blue: 0.34, alpha: 0.34)
            aura.lineWidth = 2
            aura.glowWidth = reducedMotion ? 0 : 8
            aura.position.y = 70
            aura.name = "scienceSeedBench"
            plantNode.addChild(aura)
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
        refreshGuidanceCue()
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
        refreshGuidanceCue()
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
        refreshGuidanceCue()
    }

    private func refreshGuidanceCue() {
        let tint = UIColor(red: 0.57, green: 0.93, blue: 0.63, alpha: 1)
        switch greenhouseStage {
        case .arrive:
            showAttentionCue(at: seedBenchPoint, tint: tint)
        case .inspected:
            showAttentionCue(at: waterValvePoint, tint: tint)
        case .watered:
            showAttentionCue(at: sunPrismPoint, tint: tint)
        case .lit:
            showAttentionCue(at: exitPoint, tint: tint, width: 104)
        }
    }

}
