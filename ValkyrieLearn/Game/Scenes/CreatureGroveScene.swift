import SpriteKit
import LearningCore

@MainActor final class CreatureGroveScene: AdventureScene {
    typealias GroveStage = ScienceGroveStage
    typealias HabitatChoice = ScienceHabitatChoice

    override var worldTitle: String { "Science Lab · Creature Grove" }
    override var walkable: CGRect { CGRect(x: 90, y: 135, width: 1100, height: 170) }

    let milo = MiloNode()
    var groveStage: GroveStage { state.scienceAdventure.groveStage }
    var selectedHabitat: HabitatChoice? { state.scienceAdventure.selectedHabitat }
    var groveRestored: Bool { state.scienceAdventure.groveRestored }

    private let duckPoint = CGPoint(x: 335, y: 235)
    private let habitatPoint = CGPoint(x: 610, y: 235)
    private let feetPoint = CGPoint(x: 840, y: 235)
    private let comparePoint = CGPoint(x: 1030, y: 235)
    private let finalePoint = CGPoint(x: 1150, y: 185)

    private var pondNode = SKNode()
    private var finaleNode = SKNode()
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.isHidden = true
        pip.position = CGPoint(x: -500, y: -500)

        valkyrie.position = CGPoint(x: 165, y: 175)
        valkyrie.setScale(0.5)
        milo.position = CGPoint(x: 245, y: 190)
        milo.reducedMotion = reducedMotion
        addChild(milo)

        renderPond()
        renderFinale()
        instruction.text = "Milo spotted a duck near the grove. Observe it before changing the habitat."
    }

    override func buildWorld() {
        let sky = ArtSystem.box(
            size,
            color: UIColor(red: 0.48, green: 0.68, blue: 0.70, alpha: 1),
            radius: 0
        )
        sky.strokeColor = .clear
        sky.position = CGPoint(x: 640, y: 360)
        sky.zPosition = -220
        addChild(sky)
        ArtSystem.scienceBackdrop(in: self, environment: .creatureGrove)

        let grove = ArtSystem.box(
            CGSize(width: 1280, height: 310),
            color: UIColor(red: 0.17, green: 0.34, blue: 0.20, alpha: 1),
            radius: 0
        )
        grove.strokeColor = .clear
        grove.position = CGPoint(x: 640, y: 130)
        grove.zPosition = -120
        addChild(grove)

        for (x, height) in [
            (CGFloat(120), CGFloat(310)),
            (CGFloat(245), CGFloat(360)),
            (CGFloat(1000), CGFloat(345)),
            (CGFloat(1160), CGFloat(320))
        ] {
            let trunk = ArtSystem.box(
                CGSize(width: 34, height: height),
                color: UIColor(red: 0.28, green: 0.20, blue: 0.12, alpha: 1),
                radius: 12
            )
            trunk.position = CGPoint(x: x, y: 340)
            trunk.zPosition = -80
            addChild(trunk)
            for offset in [CGFloat(-20), 10, 30] {
                let bark = ArtSystem.box(
                    CGSize(width: 4, height: height * 0.62),
                    color: UIColor(red: 0.55, green: 0.39, blue: 0.19, alpha: 0.40),
                    radius: 2
                )
                bark.position = CGPoint(x: x + offset * 0.30, y: 320)
                bark.zPosition = -79
                addChild(bark)
            }

            let crown = SKShapeNode(ellipseOf: CGSize(width: 190, height: 125))
            crown.fillColor = UIColor(red: 0.16, green: 0.43, blue: 0.22, alpha: 1)
            crown.strokeColor = UIColor(red: 0.27, green: 0.56, blue: 0.29, alpha: 0.8)
            crown.lineWidth = 4
            crown.position = CGPoint(x: x, y: 535 + (height - 310) * 0.3)
            crown.zPosition = -75
            addChild(crown)
            // Layered canopies break up the prototype's single-disc trees.
            for (dx, dy, width, height) in [
                (CGFloat(-55), CGFloat(-24), CGFloat(115), CGFloat(86)),
                (CGFloat(52), CGFloat(-10), CGFloat(132), CGFloat(100)),
                (CGFloat(-13), CGFloat(42), CGFloat(122), CGFloat(98))
            ] {
                let foliage = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
                foliage.position = CGPoint(
                    x: x + dx,
                    y: 535 + (height - 310) * 0.3 + dy
                )
                foliage.fillColor = UIColor(red: 0.23, green: 0.54, blue: 0.27, alpha: 0.97)
                foliage.strokeColor = UIColor(red: 0.45, green: 0.69, blue: 0.38, alpha: 0.52)
                foliage.lineWidth = 3
                foliage.zPosition = -74
                addChild(foliage)
            }
        }

        let path = ArtSystem.box(
            CGSize(width: 1120, height: 120),
            color: UIColor(red: 0.43, green: 0.37, blue: 0.25, alpha: 1),
            radius: 50
        )
        path.position = CGPoint(x: 640, y: 185)
        path.strokeColor = UIColor(red: 0.61, green: 0.55, blue: 0.39, alpha: 1)
        path.lineWidth = 4
        path.zPosition = 25
        addChild(path)
        // A low stone trail physically connects observations around the pond.
        for (index, x) in stride(from: CGFloat(158), through: CGFloat(1150), by: CGFloat(124)).enumerated() {
            let slab = SKShapeNode(ellipseOf: CGSize(width: 83, height: 26))
            slab.position = CGPoint(x: x, y: 175 + CGFloat(index % 2) * 11)
            slab.fillColor = UIColor(red: 0.76, green: 0.71, blue: 0.54, alpha: 0.23)
            slab.strokeColor = UIColor(red: 0.91, green: 0.84, blue: 0.61, alpha: 0.34)
            slab.lineWidth = 2
            slab.zPosition = 26
            addChild(slab)
        }
        for (x, y, size) in [
            (CGFloat(110), CGFloat(320), CGFloat(82)),
            (CGFloat(260), CGFloat(330), CGFloat(68)),
            (CGFloat(1110), CGFloat(325), CGFloat(75)),
            (CGFloat(1200), CGFloat(340), CGFloat(93))
        ] {
            if let bloom = ArtSystem.sprite(
                "StoryBloom",
                size: CGSize(width: size, height: size)
            ) {
                bloom.position = CGPoint(x: x, y: y)
                bloom.zPosition = -68
                addChild(bloom)
            }
        }

        addDuckObservation()
        addHabitatChoices()
        addBodyPartStation()
        addHabitatComparison()
        addFinaleStone()

        _ = worldControl("⌂", name: "scienceGroveHome", at: CGPoint(x: 55, y: 665), radius: 30)
    }

    private func addDuckObservation() {
        let perch = ArtSystem.box(
            CGSize(width: 170, height: 82),
            color: UIColor(red: 0.34, green: 0.24, blue: 0.14, alpha: 1),
            radius: 18
        )
        perch.position = CGPoint(x: duckPoint.x, y: duckPoint.y + 35)
        perch.name = "scienceGroveDuck"
        perch.zPosition = 500
        addChild(perch)

        let duck = ArtSystem.label("🦆", size: 56)
        duck.position.y = 18
        duck.name = "scienceGroveDuck"
        perch.addChild(duck)

        let needs = ArtSystem.label("water · food · cover", size: 15)
        needs.position.y = -30
        needs.name = "scienceGroveDuck"
        perch.addChild(needs)
    }

    private func addHabitatChoices() {
        let title = ArtSystem.label("Choose a habitat", size: 18)
        title.position = CGPoint(x: habitatPoint.x, y: habitatPoint.y + 115)
        title.zPosition = 520
        addChild(title)

        let pond = ArtSystem.box(
            CGSize(width: 150, height: 92),
            color: UIColor(red: 0.18, green: 0.45, blue: 0.44, alpha: 1),
            radius: 18
        )
        pond.position = CGPoint(x: habitatPoint.x - 82, y: habitatPoint.y + 35)
        pond.name = "scienceHabitatPond"
        pond.zPosition = 520
        pond.strokeColor = UIColor(red: 0.55, green: 0.78, blue: 0.63, alpha: 1)
        pond.lineWidth = 3
        let pondLabel = ArtSystem.label("pond + reeds", size: 16)
        pondLabel.name = "scienceHabitatPond"
        pond.addChild(pondLabel)
        addChild(pond)

        let ridge = ArtSystem.box(
            CGSize(width: 150, height: 92),
            color: UIColor(red: 0.49, green: 0.38, blue: 0.25, alpha: 1),
            radius: 18
        )
        ridge.position = CGPoint(x: habitatPoint.x + 82, y: habitatPoint.y + 35)
        ridge.name = "scienceHabitatRidge"
        ridge.zPosition = 520
        ridge.strokeColor = UIColor(red: 0.72, green: 0.62, blue: 0.43, alpha: 1)
        ridge.lineWidth = 3
        let ridgeLabel = ArtSystem.label("dry bare ridge", size: 16)
        ridgeLabel.name = "scienceHabitatRidge"
        ridge.addChild(ridgeLabel)
        addChild(ridge)
    }

    private func addBodyPartStation() {
        let station = ArtSystem.box(
            CGSize(width: 178, height: 132),
            color: UIColor(red: 0.28, green: 0.35, blue: 0.29, alpha: 1),
            radius: 18
        )
        station.position = CGPoint(x: feetPoint.x, y: feetPoint.y + 55)
        station.name = "scienceWebbedFeet"
        station.zPosition = 520
        station.strokeColor = UIColor(red: 0.59, green: 0.75, blue: 0.49, alpha: 1)
        station.lineWidth = 3

        let title = ArtSystem.label("Milo Inspect", size: 17)
        title.position.y = 40
        title.name = "scienceWebbedFeet"
        station.addChild(title)

        let feet = ArtSystem.label("webbed feet", size: 18)
        feet.position.y = 5
        feet.name = "scienceWebbedFeet"
        station.addChild(feet)

        let motion = ArtSystem.label("push water", size: 15)
        motion.position.y = -30
        motion.name = "scienceWebbedFeet"
        station.addChild(motion)

        addChild(station)
    }

    private func addHabitatComparison() {
        let board = ArtSystem.box(
            CGSize(width: 230, height: 150),
            color: UIColor(red: 0.29, green: 0.24, blue: 0.16, alpha: 1),
            radius: 16
        )
        board.position = CGPoint(x: comparePoint.x, y: comparePoint.y + 62)
        board.name = "scienceCompareBoard"
        board.zPosition = 515
        board.strokeColor = UIColor(red: 0.62, green: 0.51, blue: 0.34, alpha: 1)
        board.lineWidth = 4

        let title = ArtSystem.label("Which place meets more needs?", size: 14)
        title.position.y = 52
        board.addChild(title)

        let sheltered = SKShapeNode(rectOf: CGSize(width: 90, height: 62), cornerRadius: 12)
        sheltered.fillColor = UIColor(red: 0.17, green: 0.46, blue: 0.35, alpha: 1)
        sheltered.strokeColor = UIColor(red: 0.55, green: 0.79, blue: 0.58, alpha: 1)
        sheltered.lineWidth = 3
        sheltered.position = CGPoint(x: -55, y: -12)
        sheltered.name = "scienceCompareShelteredPond"
        let shelteredLabel = ArtSystem.label("pond edge", size: 14)
        shelteredLabel.name = "scienceCompareShelteredPond"
        sheltered.addChild(shelteredLabel)
        board.addChild(sheltered)

        let exposed = SKShapeNode(rectOf: CGSize(width: 90, height: 62), cornerRadius: 12)
        exposed.fillColor = UIColor(red: 0.45, green: 0.36, blue: 0.24, alpha: 1)
        exposed.strokeColor = UIColor(red: 0.70, green: 0.60, blue: 0.42, alpha: 1)
        exposed.lineWidth = 3
        exposed.position = CGPoint(x: 55, y: -12)
        exposed.name = "scienceCompareExposedRidge"
        let exposedLabel = ArtSystem.label("bare ridge", size: 14)
        exposedLabel.name = "scienceCompareExposedRidge"
        exposed.addChild(exposedLabel)
        board.addChild(exposed)

        addChild(board)
    }

    private func addFinaleStone() {
        let stone = SKShapeNode(circleOfRadius: 48)
        stone.position = finalePoint
        stone.name = "scienceGroveFinale"
        stone.zPosition = 540
        stone.fillColor = UIColor(red: 0.28, green: 0.38, blue: 0.31, alpha: 1)
        stone.strokeColor = UIColor(red: 0.55, green: 0.70, blue: 0.50, alpha: 1)
        stone.lineWidth = 4
        let label = ArtSystem.label("✦", size: 34)
        label.name = "scienceGroveFinale"
        stone.addChild(label)
        addChild(stone)
    }

    private func renderPond() {
        pondNode.removeFromParent()
        pondNode = SKNode()
        pondNode.position = CGPoint(x: 690, y: 395)
        pondNode.zPosition = 120

        let water = SKShapeNode(ellipseOf: CGSize(width: 530, height: 135))
        water.fillColor = groveRestored
            ? UIColor(red: 0.20, green: 0.60, blue: 0.62, alpha: 0.88)
            : UIColor(red: 0.22, green: 0.43, blue: 0.43, alpha: 0.62)
        water.strokeColor = groveRestored
            ? UIColor(red: 0.58, green: 0.87, blue: 0.76, alpha: 1)
            : UIColor(red: 0.36, green: 0.57, blue: 0.52, alpha: 0.8)
        water.lineWidth = 4
        pondNode.addChild(water)

        // Soft ripples and lily pads turn the single-color ellipse into water.
        for (index, x) in [CGFloat(-170), -75, 25, 145].enumerated() {
            let ripple = SKShapeNode(ellipseOf: CGSize(width: 80, height: 16))
            ripple.position = CGPoint(x: x, y: index.isMultiple(of: 2) ? 21 : -12)
            ripple.fillColor = .clear
            ripple.strokeColor = UIColor(red: 0.70, green: 0.95, blue: 0.91, alpha: 0.36)
            ripple.lineWidth = 3
            pondNode.addChild(ripple)
            if groveRestored {
                let lily = SKShapeNode(ellipseOf: CGSize(width: 45, height: 19))
                lily.position = CGPoint(x: x - 12, y: index.isMultiple(of: 2) ? 15 : -19)
                lily.fillColor = UIColor(red: 0.38, green: 0.68, blue: 0.33, alpha: 0.96)
                lily.strokeColor = UIColor(red: 0.59, green: 0.81, blue: 0.44, alpha: 0.72)
                lily.lineWidth = 2
                pondNode.addChild(lily)
            }
        }
        if groveRestored {
            for x in stride(from: CGFloat(-225), through: CGFloat(225), by: CGFloat(75)) {
                let reed = ArtSystem.box(
                    CGSize(width: 7, height: 52 + abs(x.truncatingRemainder(dividingBy: 30))),
                    color: UIColor(red: 0.31, green: 0.66, blue: 0.28, alpha: 1),
                    radius: 3
                )
                reed.position = CGPoint(x: x, y: 65)
                pondNode.addChild(reed)
            }

            for (x, y) in [
                (CGFloat(-150), CGFloat(20)),
                (CGFloat(-30), CGFloat(-15)),
                (CGFloat(110), CGFloat(15)),
                (CGFloat(190), CGFloat(-5))
            ] {
                let glow = SKShapeNode(circleOfRadius: 7)
                glow.fillColor = UIColor(red: 1, green: 0.88, blue: 0.38, alpha: 0.95)
                glow.strokeColor = .clear
                glow.glowWidth = reducedMotion ? 0 : 8
                glow.position = CGPoint(x: x, y: y)
                pondNode.addChild(glow)
            }
        }

        addChild(pondNode)
    }

    private func renderFinale() {
        finaleNode.removeFromParent()
        finaleNode = SKNode()
        finaleNode.position = CGPoint(x: 640, y: 565)
        finaleNode.zPosition = 650

        guard groveRestored else {
            addChild(finaleNode)
            return
        }

        let halo = SKShapeNode(circleOfRadius: 58)
        halo.fillColor = UIColor(red: 0.75, green: 0.89, blue: 0.45, alpha: 0.12)
        halo.strokeColor = UIColor(red: 0.86, green: 0.96, blue: 0.52, alpha: 0.85)
        halo.lineWidth = 4
        halo.glowWidth = reducedMotion ? 0 : 14
        finaleNode.addChild(halo)

        let star = ArtSystem.label("✦", size: 46)
        star.fontColor = UIColor(red: 1, green: 0.88, blue: 0.38, alpha: 1)
        finaleNode.addChild(star)

        let text = ArtSystem.label("Science Lab restored", size: 20)
        text.position.y = -78
        finaleNode.addChild(text)

        addChild(finaleNode)
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
        case "scienceGroveDuck":
            if isNear(duckPoint, radius: 135) {
                observeAnimal()
            } else {
                instruction.text = "Walk closer so Milo can observe the duck without guessing."
                travel(to: CGPoint(x: duckPoint.x - 95, y: 180))
            }

        case "scienceHabitatPond":
            if isNear(habitatPoint, radius: 180) {
                chooseHabitat(.pondEdge)
            } else {
                instruction.text = "Walk to the habitat stones before choosing."
                travel(to: CGPoint(x: habitatPoint.x - 90, y: 180))
            }

        case "scienceHabitatRidge":
            if isNear(habitatPoint, radius: 180) {
                chooseHabitat(.dryRidge)
            } else {
                instruction.text = "Walk to the habitat stones before choosing."
                travel(to: CGPoint(x: habitatPoint.x - 90, y: 180))
            }

        case "scienceWebbedFeet":
            if isNear(feetPoint, radius: 145) {
                inspectBodyPart()
            } else {
                instruction.text = "Walk closer so Milo can inspect the duck's feet."
                travel(to: CGPoint(x: feetPoint.x - 90, y: 180))
            }

        case "scienceCompareShelteredPond":
            if isNear(comparePoint, radius: 170) {
                compareHabitats(.pondEdge)
            } else {
                instruction.text = "Walk to the habitat comparison board first."
                travel(to: CGPoint(x: comparePoint.x - 110, y: 180))
            }

        case "scienceCompareExposedRidge":
            if isNear(comparePoint, radius: 170) {
                compareHabitats(.dryRidge)
            } else {
                instruction.text = "Walk to the habitat comparison board first."
                travel(to: CGPoint(x: comparePoint.x - 110, y: 180))
            }

        case "scienceGroveFinale":
            if groveRestored {
                valkyrie.pose(.celebrate)
                milo.inspect(reducedMotion: reducedMotion)
                instruction.text = "The grove is active again. Water, food, cover, body parts, and habitat evidence all worked together."
            } else {
                instruction.text = "The grove star is still dim. Finish the animal investigation first."
            }

        case "scienceGroveHome":
            state.travel(to: .storyTree)

        default:
            walkIfValid(point)
        }
    }

    private func observeAnimal() {
        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)

        state.scienceObserveAnimal()
        instruction.text = "Milo observes that the duck uses water, finds food nearby, and needs places with cover. Which habitat offers those resources?"
    }

    private func chooseHabitat(_ choice: HabitatChoice) {
        guard groveStage != .arrive else {
            instruction.text = "Observe the duck first so the habitat choice uses evidence."
            return
        }
        guard groveStage == .animalObserved || groveStage == .habitatMatched else {
            instruction.text = "The habitat match is already recorded. Inspect how the duck moves next."
            return
        }

        state.scienceChooseHabitat(choice)
        valkyrie.pose(.interact)

        if choice == .pondEdge {
            state.audio.play("success")
            instruction.text = "The pond edge provides water, nearby food, and reed cover. Now inspect a body part that helps the duck use this habitat."
        } else {
            milo.inspect(reducedMotion: reducedMotion)
            instruction.text = "The bare ridge offers little water or cover. Compare that with the needs Milo observed."
        }
    }

    private func inspectBodyPart() {
        guard groveStage == .habitatMatched || groveStage == .bodyPartObserved else {
            instruction.text = "Match the duck to a habitat before studying how its body helps there."
            return
        }

        milo.inspect(reducedMotion: reducedMotion)
        valkyrie.pose(.interact)
        state.scienceInspectBodyPart()
        instruction.text = "The webbing spreads the foot's surface against the water. That can help the duck push water while swimming. Compare the habitats one more time."
    }

    private func compareHabitats(_ choice: HabitatChoice) {
        guard groveStage == .bodyPartObserved || groveStage == .complete else {
            instruction.text = "Inspect the duck and its webbed feet before making the final habitat comparison."
            return
        }

        state.scienceCompareHabitat(choice)
        if choice == .pondEdge {
            renderPond()
            renderFinale()
            state.audio.play("success")
            valkyrie.pose(.celebrate)
            instruction.text = "The pond edge meets more of the duck's observed needs. The grove responded to the evidence and came back to life."
        } else {
            milo.inspect(reducedMotion: reducedMotion)
            instruction.text = "The exposed ridge still lacks water and protective cover. Use the needs we observed, not just where the duck could stand."
        }
    }
}
