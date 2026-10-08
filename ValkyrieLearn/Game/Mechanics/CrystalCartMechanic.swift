import SpriteKit
import LearningCore

@MainActor protocol MathCastleReactiveMechanic: AnyObject {
    func playSuccessReaction(reducedMotion: Bool)
}

@MainActor final class CrystalCartMechanic: SKNode, MathCastleReactiveMechanic {
    let cartCenter = CGPoint(x: 830, y: 265)
    let supplyCenter = CGPoint(x: 595, y: 235)
    private let cartAssembly = SKNode()
    private let contents = SKNode()
    override init() {
        super.init()
        zPosition = 750
        addChild(cartAssembly)

        let dropZone = ArtSystem.panel(
            CGSize(width: 292, height: 142),
            fill: UIColor(red: 0.10, green: 0.20, blue: 0.25, alpha: 0.18),
            stroke: UIColor(red: 0.58, green: 0.88, blue: 0.94, alpha: 0.50),
            radius: 34,
            lineWidth: 3,
            shadowAlpha: 0.12,
            innerHighlight: UIColor(red: 0.80, green: 0.96, blue: 1.0, alpha: 0.08)
        )
        dropZone.position = cartCenter
        dropZone.zPosition = -1
        dropZone.name = "cartDropZone"
        cartAssembly.addChild(dropZone)

        if let cart = ArtSystem.sprite("CrystalCart", size: CGSize(width: 365, height: 255)) {
            cart.position = CGPoint(x: 830, y: 253)
            cart.name = "cart"
            cartAssembly.addChild(cart)
        }
        // A native drop surface keeps every crystal independently manipulable.
        let cartHit = ArtSystem.box(CGSize(width: 305, height: 165), color: .clear, radius: 0)
        cartHit.position = cartCenter; cartHit.name = "cart"; cartAssembly.addChild(cartHit)

        let supply = ArtSystem.supplyTray(CGSize(width: 125, height: 100))
        supply.position = supplyCenter; supply.name = "supply"; addChild(supply)

        let supplyPlaque = ArtSystem.plaque(
            CGSize(width: 116, height: 28),
            fill: UIColor(red: 0.10, green: 0.12, blue: 0.18, alpha: 0.92),
            stroke: UIColor(red: 0.63, green: 0.86, blue: 0.92, alpha: 0.72),
            radius: 12
        )
        supplyPlaque.position = CGPoint(x: supplyCenter.x, y: supplyCenter.y + 72)
        supplyPlaque.name = "supply"
        addChild(supplyPlaque)

        let supplyLabel = ArtSystem.label("CRYSTALS", size: 12)
        supplyLabel.fontName = "AvenirNext-Bold"
        supplyLabel.fontColor = UIColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 1)
        supplyLabel.name = "supply"
        supplyPlaque.addChild(supplyLabel)

        let crystal = Self.crystal(); crystal.position = supplyCenter; crystal.setScale(1.45); crystal.name = "supply"; addChild(crystal)
        cartAssembly.addChild(contents)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    static func crystal() -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 29)); path.addLine(to: CGPoint(x: 26, y: 8))
        path.addLine(to: CGPoint(x: 18, y: -25)); path.addLine(to: CGPoint(x: -18, y: -25))
        path.addLine(to: CGPoint(x: -26, y: 8)); path.closeSubpath()
        let node = SKShapeNode(path: path); node.fillColor = .cyan
        if let sprite = ArtSystem.sprite("Crystal", size: CGSize(width: 44, height: 59)) {
            node.fillColor = .clear; node.strokeColor = .clear; node.addChild(sprite)
        } else { node.strokeColor = .white; node.lineWidth = 2 }
        return node
    }
    func render(_ model: CrystalCartModel) {
        contents.removeAllChildren()
        for index in 0..<model.quantity {
            let crystal = Self.crystal()
            crystal.position = CGPoint(
                x: 714 + CGFloat(index % 5) * 58,
                y: 310 - CGFloat(index / 5) * 61
            )
            let fixed = model.encounter.operation != .subtraction
                && index < model.encounter.initialQuantity
            crystal.name = fixed ? "fixedCrystal" : "cartCrystal"
            if fixed {
                if let sprite = crystal.children.first as? SKSpriteNode {
                    sprite.color = .systemPurple
                    sprite.colorBlendFactor = 0.28
                } else {
                    crystal.fillColor = .systemPurple
                }
            }
            contents.addChild(crystal)
        }
    }
    func receives(_ point: CGPoint) -> Bool {
        CGRect(x: 675, y: 165, width: 310, height: 190).contains(point)
    }
    func returnsToSupply(_ point: CGPoint) -> Bool {
        CGRect(x: 525, y: 155, width: 135, height: 190).contains(point)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        cartAssembly.removeAction(forKey: "successTravel")
        contents.removeAction(forKey: "successGlow")

        if reducedMotion {
            cartAssembly.position.x = 42
            return
        }

        let travel = SKAction.moveBy(x: 78, y: 6, duration: 0.68)
        travel.timingMode = .easeInEaseOut
        cartAssembly.run(travel, withKey: "successTravel")
        contents.run(.sequence([
            .scale(to: 1.045, duration: 0.16),
            .scale(to: 1, duration: 0.24)
        ]), withKey: "successGlow")
    }
}


@MainActor final class BalanceScaleMechanic: SKNode, MathCastleReactiveMechanic {
    private let leftContents = SKNode()
    private let rightContents = SKNode()
    private let beam = ArtSystem.box(CGSize(width: 360, height: 18), color: .systemOrange, radius: 8)
    private var leftPan: SKNode?
    private var rightPan: SKNode?
    private var leftHanger: SKShapeNode?
    private var rightHanger: SKShapeNode?
    private let equalSelection = SKShapeNode(circleOfRadius: 40)

    override init() {
        super.init()
        name = MathMechanicID.balanceScale
        zPosition = 750

        if let texture = ArtSystem.texture("BridgeOakPlank") { beam.fillColor = .white; beam.fillTexture = texture; beam.strokeColor = .clear }
        beam.name = "scaleBeam"
        beam.position = CGPoint(x: 0, y: 40)
        addChild(beam)

        let stand = ArtSystem.box(
            CGSize(width: 22, height: 180),
            color: .init(red: 0.73, green: 0.51, blue: 0.24, alpha: 1),
            radius: 8
        )
        if let texture = ArtSystem.texture("BridgeTimber") { stand.fillColor = .white; stand.fillTexture = texture; stand.strokeColor = .clear }
        stand.position = CGPoint(x: 0, y: -40)
        addChild(stand)

        let pivot = ArtSystem.gear(radius: 27)
        pivot.position = CGPoint(x: 0, y: 40)
        pivot.zPosition = 2
        pivot.name = "scaleBeam"
        addChild(pivot)

        let base = ArtSystem.supplyTray(CGSize(width: 126, height: 24))
        base.position = CGPoint(x: 0, y: -164)
        base.name = "scaleBase"
        base.zPosition = -1
        addChild(base)

        let equal = ArtSystem.gear(radius: 36, symbol: "=")
        equal.position = CGPoint(x: 0, y: -115); equal.name = "scaleEqual"
        equalSelection.userData = ["selectionIndicator": true]
        equalSelection.fillColor = .clear; equalSelection.strokeColor = .systemYellow
        equalSelection.lineWidth = 4; equalSelection.isHidden = true
        // Keep the selectable gear as the ancestor of its decorative ring.
        equal.addChild(equalSelection)
        addChild(equal)

        leftPan = addPan(name: "scaleLeft", x: -150)
        rightPan = addPan(name: "scaleRight", x: 150)
        leftContents.zPosition = 1
        rightContents.zPosition = 1

        addChild(leftContents)
        addChild(rightContents)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func addPan(name: String, x: CGFloat) -> SKNode {
        let pan = ArtSystem.supplyTray(CGSize(width: 180, height: 72))
        pan.position = CGPoint(x: x, y: -45)
        pan.name = name
        let hanger = SKShapeNode(path: hangerPath(x: x, offset: 0, angle: 0))
        hanger.strokeColor = .init(red: 0.88, green: 0.66, blue: 0.28, alpha: 1); hanger.lineWidth = 3
        hanger.userData = ["pan": name]
        if name == "scaleLeft" { leftHanger = hanger } else { rightHanger = hanger }
        addChild(hanger)
        addChild(pan)
        return pan
    }

    private func hangerPath(x: CGFloat, offset: CGFloat, angle: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let panTop = -45 + offset + 36
        path.move(to: CGPoint(x: x - 70, y: panTop))
        path.addLine(to: CGPoint(x: x * cos(angle), y: 40 + x * sin(angle)))
        path.addLine(to: CGPoint(x: x + 70, y: panTop))
        return path
    }

    func render(_ model: BalanceScaleModel) {
        // Positive rotation lowers the left end in SpriteKit's upward y-axis.
        let angle: CGFloat = model.leftQuantity == model.rightQuantity ? 0
            : (model.leftQuantity > model.rightQuantity ? 0.14 : -0.14)
        beam.zRotation = angle
        let leftOffset = -150 * sin(angle)
        let rightOffset = 150 * sin(angle)
        leftPan?.position.y = -45 + leftOffset
        rightPan?.position.y = -45 + rightOffset
        leftHanger?.path = hangerPath(x: -150, offset: leftOffset, angle: angle)
        rightHanger?.path = hangerPath(x: 150, offset: rightOffset, angle: angle)
        leftContents.position.y = leftOffset
        rightContents.position.y = rightOffset
        for (pan, choice) in [(leftPan, ComparisonChoice.left), (rightPan, ComparisonChoice.right)] {
            (pan as? SKShapeNode)?.strokeColor = model.selected == choice ? .systemYellow : .white
            (pan as? SKShapeNode)?.lineWidth = model.selected == choice ? 5 : 1.5
        }
        equalSelection.isHidden = model.selected != .equal
        renderQuantity(model.leftQuantity, in: leftContents, centerX: -150, targetName: "scaleLeft")
        renderQuantity(model.rightQuantity, in: rightContents, centerX: 150, targetName: "scaleRight")
    }

    private func renderQuantity(_ quantity: Int, in node: SKNode, centerX: CGFloat, targetName: String) {
        node.removeAllChildren()
        for index in 0..<quantity {
            let token = tokenNode()
            token.name = targetName
            let column = index % 5
            let row = index / 5
            token.position = CGPoint(
                x: centerX - 52 + CGFloat(column) * 26,
                y: -35 + CGFloat(row) * 26
            )
            node.addChild(token)
        }
    }

    private func tokenNode() -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: 10)
        node.fillColor = .cyan
        node.strokeColor = .white
        node.lineWidth = 1.5
        if let crystal = ArtSystem.sprite("Crystal", size: CGSize(width: 20, height: 27)) {
            node.fillColor = .clear; node.strokeColor = .clear; node.addChild(crystal)
        }
        return node
    }

    func playSuccessReaction(reducedMotion: Bool) {
        guard !reducedMotion else {
            beam.alpha = 1
            return
        }

        run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1, duration: 0.18)
        ]), withKey: "successPulse")
    }
}

@MainActor final class NumberBondMachineMechanic: SKNode, MathCastleReactiveMechanic {
    private let knownContents = SKNode()
    private let selectedContents = SKNode()
    private let wholeLabel = ArtSystem.label("", size: 34)

    override init() {
        super.init()
        name = MathMechanicID.numberBondMachine
        zPosition = 750

        // Preserve the machine's touch footprint while opening its frame to the world.
        let shell = ArtSystem.box(CGSize(width: 430, height: 250), color: .clear, radius: 0)
        shell.name = "bondMachine"; addChild(shell)

        let machineBase = ArtSystem.supplyTray(CGSize(width: 468, height: 30))
        machineBase.position = CGPoint(x: 0, y: -126)
        machineBase.zPosition = -2
        machineBase.name = "bondMachineBase"
        addChild(machineBase)
        for x in [-205, 205] {
            let post = ArtSystem.box(CGSize(width: 18, height: 230), color: .brown, radius: 3)
            if let texture = ArtSystem.texture("BridgeTimber") { post.fillColor = .white; post.fillTexture = texture; post.strokeColor = .clear }
            post.position.x = CGFloat(x); shell.addChild(post)
        }
        for y in [-100, 100] {
            let rail = ArtSystem.box(CGSize(width: 430, height: 14), color: .brown, radius: 3)
            if let texture = ArtSystem.texture("BridgeOakPlank") { rail.fillColor = .white; rail.fillTexture = texture; rail.strokeColor = .clear }
            rail.position.y = CGFloat(y); shell.addChild(rail)
        }
        let junction = CGMutablePath()
        junction.move(to: CGPoint(x: 0, y: 82)); junction.addLine(to: CGPoint(x: 0, y: 45))
        for x in [-105, 105] {
            junction.move(to: CGPoint(x: 0, y: 45)); junction.addLine(to: CGPoint(x: CGFloat(x), y: 45))
            junction.addLine(to: CGPoint(x: CGFloat(x), y: 27.5))
        }
        let pipes = SKShapeNode(path: junction)
        pipes.strokeColor = .init(red: 0.88, green: 0.66, blue: 0.28, alpha: 1); pipes.lineWidth = 4
        shell.addChild(pipes)
        let totalDial = ArtSystem.gear(radius: 34)
        totalDial.position = CGPoint(x: 0, y: 82); shell.addChild(totalDial)

        let wholePlaque = ArtSystem.plaque(
            CGSize(width: 88, height: 24),
            fill: UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 0.92),
            stroke: UIColor(red: 0.89, green: 0.68, blue: 0.31, alpha: 0.66),
            radius: 10
        )
        wholePlaque.position = CGPoint(x: 0, y: 132)
        wholePlaque.name = "bondWholePlaque"
        addChild(wholePlaque)

        let wholeCaption = ArtSystem.label("WHOLE", size: 11)
        wholeCaption.fontName = "AvenirNext-Bold"
        wholeCaption.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.66, alpha: 1)
        wholeCaption.name = "bondWholePlaque"
        wholePlaque.addChild(wholeCaption)

        for (index, x) in [CGFloat(-105), 105].enumerated() {
            let glow = SKShapeNode(ellipseOf: CGSize(width: 176, height: 132))
            glow.fillColor = index == 0
                ? UIColor(red: 0.54, green: 0.42, blue: 0.86, alpha: 0.07)
                : UIColor(red: 0.25, green: 0.78, blue: 0.88, alpha: 0.07)
            glow.strokeColor = UIColor(red: 0.91, green: 0.70, blue: 0.32, alpha: 0.16)
            glow.lineWidth = 2
            glow.position = CGPoint(x: x, y: -30)
            glow.zPosition = -1
            glow.name = index == 0 ? "bondKnownGlow" : "bondBuildGlow"
            addChild(glow)
        }

        let known = ArtSystem.supplyTray(CGSize(width: 150, height: 115))
        known.position = CGPoint(x: -105, y: -30)
        known.name = "bondKnown"
        addChild(known)

        let selected = ArtSystem.supplyTray(CGSize(width: 150, height: 115))
        selected.position = CGPoint(x: 105, y: -30)
        selected.name = "bondSelected"
        addChild(selected)

        for (title, x, name) in [
            ("KNOWN", CGFloat(-105), "bondKnown"),
            ("BUILD", CGFloat(105), "bondSelected")
        ] {
            let plaque = ArtSystem.plaque(
                CGSize(width: 84, height: 26),
                fill: UIColor(red: 0.09, green: 0.11, blue: 0.17, alpha: 0.92),
                stroke: UIColor(red: 0.80, green: 0.63, blue: 0.31, alpha: 0.66),
                radius: 11
            )
            plaque.position = CGPoint(x: x, y: 43)
            plaque.name = name
            addChild(plaque)

            let label = ArtSystem.label(title, size: 11)
            label.fontName = "AvenirNext-Bold"
            label.fontColor = UIColor(red: 1.0, green: 0.90, blue: 0.63, alpha: 1)
            label.name = name
            plaque.addChild(label)
        }

        wholeLabel.fontName = "AvenirNext-Heavy"
        wholeLabel.fontSize = 32
        wholeLabel.fontColor = UIColor(red: 1.0, green: 0.95, blue: 0.78, alpha: 1)
        wholeLabel.position = CGPoint(x: 0, y: 82)
        addChild(wholeLabel)
        addChild(knownContents)
        addChild(selectedContents)
        let supply = ArtSystem.supplyTray(CGSize(width: 100, height: 100))
        supply.position = CGPoint(x: -265, y: -30); supply.name = "bondSupply"
        supply.addChild(Self.crystalToken(radius: 18, fixed: false))
        addChild(supply)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: NumberBondMachineModel) {
        wholeLabel.text = "\(model.whole)"
        renderTokens(model.knownPart, in: knownContents, centerX: -105, fixed: true)
        renderTokens(model.selectedPart, in: selectedContents, centerX: 105, fixed: false)
    }

    private static func crystalToken(radius: CGFloat, fixed: Bool) -> SKShapeNode {
        let token = SKShapeNode(circleOfRadius: radius)
        token.fillColor = fixed ? .systemPurple : .cyan; token.strokeColor = .white; token.lineWidth = 1.5
        if let crystal = ArtSystem.sprite("Crystal", size: CGSize(width: radius * 2, height: radius * 2.6)) {
            if fixed { crystal.color = .systemPurple; crystal.colorBlendFactor = 0.25 }
            token.fillColor = .clear; token.strokeColor = .clear; token.addChild(crystal)
        }
        return token
    }

    private func renderTokens(_ count: Int, in node: SKNode, centerX: CGFloat, fixed: Bool) {
        node.removeAllChildren()
        for index in 0..<count {
            let token = Self.crystalToken(radius: 10, fixed: fixed)
            // Five columns keep every supported quantity (up to twenty) inside its tray.
            token.position = CGPoint(
                x: centerX - 44 + CGFloat(index % 5) * 22,
                y: -62 + CGFloat(index / 5) * 22
            )
            token.name = fixed ? "bondFixed" : "bondToken"
            node.addChild(token)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        wholeLabel.fontColor = UIColor(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        guard !reducedMotion else { return }

        run(.sequence([
            .scale(to: 1.035, duration: 0.14),
            .scale(to: 0.99, duration: 0.12),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "successPulse")
        wholeLabel.run(.sequence([
            .fadeAlpha(to: 0.45, duration: 0.10),
            .fadeAlpha(to: 1, duration: 0.18)
        ]), withKey: "successWhole")
    }
}

@MainActor final class TenFrameGateMechanic: SKNode, MathCastleReactiveMechanic {
    private let cells = SKNode()
    private var latestModel: TenFrameModel?
    private var latestAllowsPreview = true
    private let previewActionKey = "quickLookPreview"

    override init() {
        super.init()
        name = MathMechanicID.tenFrameGate
        zPosition = 750
        cells.name = "tenFrameCells"

        // Build a physical 2x5 crystal gate. The ten touch cells remain identical
        // in count and hit size, but the surrounding machine now uses the same
        // timber/brass vocabulary as the rest of Math Castle.
        let frame = ArtSystem.supplyTray(CGSize(width: 378, height: 172))
        frame.position = CGPoint(x: 0, y: -2)
        frame.zPosition = -3
        frame.name = "tenFrameGateFrame"
        addChild(frame)

        let frameInset = ArtSystem.panel(
            CGSize(width: 344, height: 140),
            fill: UIColor(red: 0.07, green: 0.12, blue: 0.20, alpha: 0.86),
            stroke: UIColor(red: 0.72, green: 0.58, blue: 0.30, alpha: 0.62),
            radius: 18,
            lineWidth: 2,
            shadowAlpha: 0,
            innerHighlight: UIColor(red: 0.55, green: 0.88, blue: 0.96, alpha: 0.08)
        )
        frameInset.position = CGPoint(x: 0, y: -2)
        frameInset.zPosition = -2
        frameInset.name = "tenFrameGateInset"
        addChild(frameInset)

        let rowDivider = ArtSystem.box(
            CGSize(width: 324, height: 8),
            color: UIColor(red: 0.76, green: 0.56, blue: 0.24, alpha: 0.88),
            radius: 4
        )
        if let texture = ArtSystem.texture("BridgeTimber") {
            rowDivider.fillColor = .white
            rowDivider.fillTexture = texture
            rowDivider.strokeColor = .clear
        }
        rowDivider.position = CGPoint(x: 0, y: -2)
        rowDivider.zPosition = -1
        rowDivider.name = "tenFrameRowDivider"
        addChild(rowDivider)

        let tenBadge = ArtSystem.gear(radius: 24, symbol: "10")
        tenBadge.position = CGPoint(x: 0, y: 98)
        tenBadge.zPosition = 1
        tenBadge.name = "tenFrameGateBadge"
        addChild(tenBadge)

        for index in 0..<10 {
            let cell = ArtSystem.panel(
                CGSize(width: 62, height: 62),
                fill: UIColor(red: 0.08, green: 0.13, blue: 0.22, alpha: 0.98),
                stroke: UIColor(red: 0.47, green: 0.58, blue: 0.72, alpha: 0.62),
                radius: 11,
                lineWidth: 2,
                shadowAlpha: 0.16,
                innerHighlight: UIColor(red: 0.65, green: 0.90, blue: 0.96, alpha: 0.08)
            )
            let column = index % 5
            let row = index / 5
            cell.position = CGPoint(
                x: -128 + CGFloat(column) * 64,
                y: 30 - CGFloat(row) * 64
            )
            cell.name = "tenFrameCell"

            let well = SKShapeNode(ellipseOf: CGSize(width: 39, height: 26))
            well.fillColor = UIColor(red: 0.03, green: 0.08, blue: 0.14, alpha: 0.58)
            well.strokeColor = UIColor(red: 0.78, green: 0.61, blue: 0.30, alpha: 0.22)
            well.lineWidth = 1
            well.position.y = -8
            well.zPosition = 1
            cell.addChild(well)

            if let crystal = ArtSystem.sprite("Crystal", size: CGSize(width: 34, height: 46)) {
                crystal.name = "tenFrameCell"
                crystal.isHidden = true
                crystal.zPosition = 2
                cell.addChild(crystal)
            }

            cells.addChild(cell)
        }
        addChild(cells)

        let supply = ArtSystem.supplyTray(CGSize(width: 100, height: 100))
        supply.position = CGPoint(x: -270, y: 0); supply.name = "tenFrameSupply"
        if let crystal = ArtSystem.sprite("Crystal", size: CGSize(width: 38, height: 52)) {
            crystal.name = "tenFrameSupply"
            supply.addChild(crystal)
        }
        addChild(supply)

        let supplyPlaque = ArtSystem.plaque(
            CGSize(width: 94, height: 26),
            fill: UIColor(red: 0.09, green: 0.11, blue: 0.17, alpha: 0.92),
            stroke: UIColor(red: 0.60, green: 0.86, blue: 0.91, alpha: 0.68),
            radius: 11
        )
        supplyPlaque.position = CGPoint(x: -270, y: 70)
        supplyPlaque.name = "tenFrameSupply"
        addChild(supplyPlaque)

        let supplyLabel = ArtSystem.label("ADD", size: 11)
        supplyLabel.fontName = "AvenirNext-Bold"
        supplyLabel.fontColor = UIColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 1)
        supplyLabel.name = "tenFrameSupply"
        supplyPlaque.addChild(supplyLabel)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: TenFrameModel, allowPreview: Bool = true) {
        latestModel = model
        latestAllowsPreview = allowPreview
        let now = Date()
        let previewVisible = allowPreview && model.previewIsVisible(at: now)
        let visibleQuantity = previewVisible ? model.encounter.targetQuantity : model.filled
        cells.children.enumerated().forEach { index, cell in
            guard let shape = cell as? SKShapeNode else { return }
            let active = index < visibleQuantity
            let fixed = index < model.encounter.initialQuantity

            shape.fillColor = active
                ? UIColor(red: 0.08, green: 0.25, blue: 0.31, alpha: 0.96)
                : UIColor(red: 0.08, green: 0.13, blue: 0.22, alpha: 0.98)
            shape.strokeColor = active
                ? UIColor(red: 0.55, green: 0.90, blue: 0.96, alpha: 0.96)
                : UIColor(red: 0.47, green: 0.58, blue: 0.72, alpha: 0.62)
            shape.lineWidth = active ? 3 : 2
            shape.name = previewVisible ? "tenFramePreview"
                : (fixed ? "tenFrameFixed"
                   : (index < model.filled ? "tenFrameFilled" : "tenFrameCell"))

            if let crystal = shape.children.compactMap({ $0 as? SKSpriteNode }).first {
                crystal.isHidden = !active
                crystal.name = shape.name
                crystal.color = fixed ? .systemPurple : .white
                crystal.colorBlendFactor = fixed ? 0.26 : 0
            }
        }
        removeAction(forKey: previewActionKey)
        if previewVisible {
            // Re-renders retain the original deadline; they cannot replay the flash.
            let remaining = max(0, model.startedAt.addingTimeInterval(model.previewDuration).timeIntervalSince(now))
            run(.sequence([.wait(forDuration: remaining), .run { [weak self] in
                guard let self, let latest = self.latestModel else { return }
                self.render(latest, allowPreview: self.latestAllowsPreview)
            }]), withKey: previewActionKey)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        let active = cells.children.compactMap { $0 as? SKShapeNode }
            .filter { ["tenFrameFixed", "tenFrameFilled", "tenFramePreview"].contains($0.name ?? "") }

        for (index, cell) in active.enumerated() {
            cell.strokeColor = UIColor(red: 1, green: 0.82, blue: 0.38, alpha: 1)
            cell.lineWidth = 3
            guard !reducedMotion else { continue }

            cell.run(.sequence([
                .wait(forDuration: Double(index) * 0.055),
                .scale(to: 1.13, duration: 0.08),
                .scale(to: 1, duration: 0.12)
            ]), withKey: "successCell")
        }
    }
}

@MainActor final class MissingNumberBridgeMechanic: SKNode, MathCastleReactiveMechanic {
    private let equation = ArtSystem.label("", size: 38)
    private let answer = ArtSystem.label("", size: 44)
    private let deck = SKNode()
    private var latestModel: MissingNumberBridgeModel?

    override init() {
        super.init()
        name = MathMechanicID.missingNumberBridge
        zPosition = 750

        // The deck spans a castle water channel. Empty spaces show the water
        // beneath it; there is no answer panel filling the whole structure.
        if let water = ArtSystem.sprite("BridgeChannel", size: CGSize(width: 540, height: 156)) {
            water.position = CGPoint(x: 0, y: -100)
            water.zPosition = -5; water.name = "missingBridge"; addChild(water)
        }
        for x in [-246, 246] {
            let support = ArtSystem.sprite("BridgeTimber", size: CGSize(width: 18, height: 130)) ?? SKSpriteNode(color: .brown, size: CGSize(width: 18, height: 130))
            support.position = CGPoint(x: x, y: -96)
            support.name = "missingBridge"; support.zPosition = -1
            addChild(support)
            let cap = ArtSystem.box(CGSize(width: 28, height: 12),
                color: .init(red: 0.79, green: 0.57, blue: 0.24, alpha: 1), radius: 3)
            cap.position = CGPoint(x: x, y: -30); cap.name = "missingBridge"
            addChild(cap)
        }
        let rope = CGMutablePath()
        rope.move(to: CGPoint(x: -246, y: -35))
        rope.addQuadCurve(to: CGPoint(x: 246, y: -35), control: CGPoint(x: 0, y: -70))
        let rail = SKShapeNode(path: rope)
        rail.strokeColor = .init(red: 0.79, green: 0.61, blue: 0.34, alpha: 1)
        rail.lineWidth = 5; rail.name = "missingBridge"; rail.zPosition = -1
        addChild(rail)

        // A small suspended work order supplies the relationship; the child's
        // actual answer is built into the bridge below it.
        for x in [-150, 40] {
            let post = ArtSystem.sprite("BridgeTimber", size: CGSize(width: 12, height: 118)) ?? SKSpriteNode(color: .brown, size: CGSize(width: 12, height: 118))
            post.position = CGPoint(x: x, y: -7); post.zPosition = -2; post.name = "missingBridge"
            addChild(post)
            let chain = ArtSystem.box(CGSize(width: 4, height: 30),
                color: .init(red: 0.78, green: 0.59, blue: 0.27, alpha: 1), radius: 1)
            chain.position = CGPoint(x: x, y: 39); chain.name = "missingBridge"; addChild(chain)
        }
        let lintel = ArtSystem.box(CGSize(width: 220, height: 12),
            color: .init(red: 0.40, green: 0.28, blue: 0.16, alpha: 1), radius: 3)
        lintel.fillColor = .white; lintel.fillTexture = ArtSystem.texture("BridgeOakPlank"); lintel.strokeColor = .clear
        lintel.position = CGPoint(x: -55, y: 54); lintel.name = "missingBridge"; addChild(lintel)
        let sign = ArtSystem.box(CGSize(width: 220, height: 48),
            color: .init(red: 0.25, green: 0.19, blue: 0.13, alpha: 0.94), radius: 6)
        sign.position = CGPoint(x: -55, y: 20); sign.name = "missingBridge"
        sign.fillColor = .white; sign.fillTexture = ArtSystem.texture("BridgeWorkOrder")
        sign.strokeColor = .clear
        addChild(sign)
        equation.fontSize = 23; equation.position = sign.position; equation.name = "missingBridge"
        equation.fontColor = .init(red: 1, green: 0.94, blue: 0.77, alpha: 1); addChild(equation)

        let dial = ArtSystem.gear(radius: 44)
        dial.position = CGPoint(x: 145, y: 20); dial.name = "missingAnswer"
        addChild(dial)
        answer.fontSize = 36; answer.position = dial.position; answer.name = "missingAnswer"
        addChild(answer)

        let minus = ArtSystem.gear(radius: 30, symbol: "−")
        minus.position = CGPoint(x: 85, y: -55)
        minus.name = "missingMinus"
        addChild(minus)

        let plus = ArtSystem.gear(radius: 30, symbol: "+")
        plus.position = CGPoint(x: 205, y: -55)
        plus.name = "missingPlus"
        addChild(plus)

        // A stack of spare planks lives beside the bridge, within reach of Pip.
        let supply = ArtSystem.supplyTray(CGSize(width: 100, height: 84))
        supply.position = CGPoint(x: -270, y: 25); supply.name = "missingSupply"
        for index in 0..<3 {
            let plank = Self.plank()
            plank.position = CGPoint(x: CGFloat(index - 1) * 15, y: CGFloat(index) * 5)
            supply.addChild(plank)
        }
        addChild(supply)
        deck.zPosition = 2
        addChild(deck)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: MissingNumberBridgeModel) {
        equation.text = "\(model.encounter.initialQuantity) + ? = \(model.encounter.targetQuantity)"
        answer.text = "\(model.selectedNumber)"
        latestModel = model
        deck.removeAllChildren()
        let total = model.encounter.initialQuantity + model.selectedNumber
        for index in 0..<max(model.encounter.targetQuantity, total) {
            let fixed = index < model.encounter.initialQuantity
            let filled = index < total
            let slot = Self.plank()
            slot.position = deckPoint(index)
            slot.name = fixed ? "missingFixed" : (filled ? "missingPlank" : "missingSlot")
            slot.fillColor = .clear
            slot.strokeColor = filled ? .clear : .init(red: 0.86, green: 0.67, blue: 0.34, alpha: 0.3)
            if let surface = slot.children.first as? SKSpriteNode {
                surface.name = slot.name
                surface.texture = ArtSystem.texture(fixed ? "BridgeOakPlank" : "BridgeGreenPlank")
                surface.isHidden = !filled
            }
            slot.glowWidth = 0
            deck.addChild(slot)
        }
    }

    static func plank() -> SKShapeNode {
        // The invisible shape owns the unchanged child-sized touch footprint.
        let plank = ArtSystem.box(CGSize(width: 44, height: 48), color: .clear, radius: 1)
        plank.strokeColor = .clear
        if let surface = ArtSystem.sprite("BridgeGreenPlank", size: CGSize(width: 44, height: 48)) {
            plank.addChild(surface)
        }
        return plank
    }

    private func deckPoint(_ index: Int) -> CGPoint {
        // Extra planks remain visible below the required span so overshooting is
        // recoverable by direct touch; the renderer never silently fixes an answer.
        CGPoint(x: -224 + CGFloat(index % 10) * 48, y: -90 - CGFloat(index / 10) * 54)
    }

    func receives(_ point: CGPoint) -> Bool {
        guard let model = latestModel else { return false }
        return (0..<max(model.encounter.targetQuantity, model.encounter.initialQuantity + model.selectedNumber)).contains {
            CGRect(x: deckPoint($0).x - 24, y: deckPoint($0).y - 26, width: 48, height: 52).contains(point)
        }
    }

    func returnsToSupply(_ point: CGPoint) -> Bool {
        CGRect(x: -320, y: -17, width: 100, height: 84).contains(point)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        answer.fontColor = .init(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        guard !reducedMotion else { return }
        answer.run(.sequence([
            .scale(to: 1.08, duration: 0.10),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "successAnswer")
    }

}


@MainActor final class PlaceValueFactoryMechanic: SKNode, MathCastleReactiveMechanic {
    private let buildGroup = SKNode()
    private let comparisonGroup = SKNode()
    private let tensContents = SKNode()
    private let onesContents = SKNode()
    private let targetLabel = ArtSystem.label("", size: 34)
    private let builtLabel = ArtSystem.label("", size: 26)
    private let leftLabel = ArtSystem.label("", size: 31)
    private let rightLabel = ArtSystem.label("", size: 31)
    private let relationLabel = ArtSystem.label("", size: 15)
    private var latestModel: PlaceValueFactoryModel?

    override init() {
        super.init()
        name = MathMechanicID.placeValueFactory
        zPosition = 750

        let base = ArtSystem.supplyTray(CGSize(width: 520, height: 278))
        base.name = MathMechanicID.placeValueFactory
        base.position = CGPoint(x: 0, y: -15)
        base.zPosition = -5
        addChild(base)

        let header = ArtSystem.plaque(
            CGSize(width: 292, height: 46),
            fill: UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 0.94),
            stroke: UIColor(red: 0.93, green: 0.70, blue: 0.30, alpha: 0.74),
            radius: 15
        )
        header.position = CGPoint(x: 0, y: 126)
        header.name = MathMechanicID.placeValueFactory
        addChild(header)

        let title = ArtSystem.label("PLACE VALUE FACTORY", size: 16)
        title.fontName = "AvenirNext-Heavy"
        title.fontColor = UIColor(red: 1.0, green: 0.91, blue: 0.64, alpha: 1)
        title.name = MathMechanicID.placeValueFactory
        header.addChild(title)

        buildGroup.name = "placeValueBuildGroup"
        comparisonGroup.name = "placeValueCompareGroup"
        addChild(buildGroup)
        addChild(comparisonGroup)

        let targetPlaque = ArtSystem.plaque(
            CGSize(width: 126, height: 64),
            fill: UIColor(red: 0.08, green: 0.17, blue: 0.23, alpha: 0.94),
            stroke: UIColor(red: 0.51, green: 0.88, blue: 0.95, alpha: 0.76),
            radius: 15
        )
        targetPlaque.position = CGPoint(x: 0, y: 66)
        targetPlaque.name = MathMechanicID.placeValueFactory
        buildGroup.addChild(targetPlaque)
        targetLabel.fontName = "AvenirNext-Heavy"
        targetLabel.fontColor = .white
        targetLabel.name = MathMechanicID.placeValueFactory
        targetPlaque.addChild(targetLabel)

        for (title, x) in [("TENS", CGFloat(-128)), ("ONES", CGFloat(128))] {
            let label = ArtSystem.label(title, size: 15)
            label.fontName = "AvenirNext-Bold"
            label.fontColor = UIColor(red: 0.94, green: 0.83, blue: 0.52, alpha: 1)
            label.position = CGPoint(x: x, y: 45)
            label.name = MathMechanicID.placeValueFactory
            buildGroup.addChild(label)

            let tray = ArtSystem.panel(
                CGSize(width: 184, height: 138),
                fill: UIColor(red: 0.06, green: 0.13, blue: 0.19, alpha: 0.86),
                stroke: UIColor(red: 0.52, green: 0.70, blue: 0.76, alpha: 0.62),
                radius: 18,
                lineWidth: 2,
                shadowAlpha: 0.10,
                innerHighlight: UIColor(red: 0.70, green: 0.92, blue: 0.96, alpha: 0.06)
            )
            tray.position = CGPoint(x: x, y: -35)
            tray.name = MathMechanicID.placeValueFactory
            buildGroup.addChild(tray)
        }

        buildGroup.addChild(tensContents)
        buildGroup.addChild(onesContents)

        for (symbol, name, x, y) in [
            ("+", "placeTensPlus", CGFloat(-178), CGFloat(-118)),
            ("−", "placeTensMinus", CGFloat(-78), CGFloat(-118)),
            ("+", "placeOnesPlus", CGFloat(78), CGFloat(-118)),
            ("−", "placeOnesMinus", CGFloat(178), CGFloat(-118))
        ] {
            let gear = ArtSystem.gear(radius: 31, symbol: symbol)
            gear.position = CGPoint(x: x, y: y)
            gear.name = name
            buildGroup.addChild(gear)

            // Give each visible control a stable 68pt named hit target above
            // decorative gear children. SpriteKit nodes(at:) ordering is not
            // deterministic, so relying on the artwork node alone can lose taps.
            let hit = SKShapeNode(circleOfRadius: 34)
            hit.position = CGPoint(x: x, y: y)
            hit.fillColor = .clear
            hit.strokeColor = .clear
            hit.zPosition = 20
            hit.name = name
            buildGroup.addChild(hit)
        }

        builtLabel.fontName = "AvenirNext-Bold"
        builtLabel.fontColor = UIColor(red: 0.90, green: 0.98, blue: 1.0, alpha: 1)
        builtLabel.position = CGPoint(x: 0, y: -127)
        builtLabel.name = MathMechanicID.placeValueFactory
        buildGroup.addChild(builtLabel)

        let leftCard = comparisonCard(x: -145, name: "placeLeft")
        comparisonGroup.addChild(leftCard)
        let rightCard = comparisonCard(x: 145, name: "placeRight")
        comparisonGroup.addChild(rightCard)

        leftLabel.fontName = "AvenirNext-Heavy"
        leftLabel.fontColor = .white
        leftLabel.position = CGPoint(x: -145, y: 45)
        leftLabel.name = "placeLeft"
        comparisonGroup.addChild(leftLabel)

        rightLabel.fontName = "AvenirNext-Heavy"
        rightLabel.fontColor = .white
        rightLabel.position = CGPoint(x: 145, y: 45)
        rightLabel.name = "placeRight"
        comparisonGroup.addChild(rightLabel)

        for (symbol, name, x) in [
            ("◀", "placeLeft", CGFloat(-145)),
            ("=", "placeEqual", CGFloat(0)),
            ("▶", "placeRight", CGFloat(145))
        ] {
            let gear = ArtSystem.gear(radius: 34, symbol: symbol)
            gear.position = CGPoint(x: x, y: -118)
            gear.name = name
            comparisonGroup.addChild(gear)
        }

        relationLabel.fontName = "AvenirNext-Bold"
        relationLabel.fontColor = UIColor(red: 0.94, green: 0.83, blue: 0.52, alpha: 1)
        relationLabel.position = CGPoint(x: 0, y: 92)
        relationLabel.name = MathMechanicID.placeValueFactory
        comparisonGroup.addChild(relationLabel)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func comparisonCard(x: CGFloat, name: String) -> SKNode {
        let card = ArtSystem.panel(
            CGSize(width: 210, height: 150),
            fill: UIColor(red: 0.06, green: 0.15, blue: 0.22, alpha: 0.91),
            stroke: UIColor(red: 0.55, green: 0.82, blue: 0.90, alpha: 0.70),
            radius: 20,
            lineWidth: 3,
            shadowAlpha: 0.12,
            innerHighlight: UIColor(red: 0.72, green: 0.93, blue: 0.97, alpha: 0.06)
        )
        card.position = CGPoint(x: x, y: 0)
        card.name = name
        return card
    }

    func render(_ model: PlaceValueFactoryModel) {
        latestModel = model
        buildGroup.isHidden = model.isComparison
        comparisonGroup.isHidden = !model.isComparison

        if model.isComparison {
            leftLabel.text = "\(model.leftNumber)"
            rightLabel.text = "\(model.rightNumber)"
            let ordering = model.encounter.skillID == MathSkills.numberOrder20
                || model.encounter.skillID == MathSkills.orderTwoDigit
            relationLabel.text = ordering ? "WHICH COMES FIRST?" : "WHICH IS GREATER?"
            renderComparisonBlocks(number: model.leftNumber, centerX: -145, prefix: "placeLeft")
            renderComparisonBlocks(number: model.rightNumber, centerX: 145, prefix: "placeRight")
            return
        }

        targetLabel.text = "\(model.targetNumber)"
        builtLabel.text = "\(model.selectedTens) tens + \(model.selectedOnes) ones = \(model.builtNumber)"
        renderBuildBlocks(model)
    }

    private func renderBuildBlocks(_ model: PlaceValueFactoryModel) {
        tensContents.removeAllChildren()
        onesContents.removeAllChildren()

        for index in 0..<model.selectedTens {
            let rod = Self.tenRod()
            rod.position = CGPoint(
                x: -176 + CGFloat(index % 5) * 24,
                y: 1 - CGFloat(index / 5) * 65
            )
            rod.name = "placeTensBuilt"
            tensContents.addChild(rod)
        }

        for index in 0..<model.selectedOnes {
            let cube = Self.oneCube()
            cube.position = CGPoint(
                x: 88 + CGFloat(index % 5) * 25,
                y: 5 - CGFloat(index / 5) * 27
            )
            cube.name = "placeOnesBuilt"
            onesContents.addChild(cube)
        }
    }

    private func renderComparisonBlocks(number: Int, centerX: CGFloat, prefix: String) {
        let existing = comparisonGroup.children.filter { $0.name?.hasPrefix(prefix + "Block") == true }
        existing.forEach { $0.removeFromParent() }

        let tens = number / 10
        let ones = number % 10

        for index in 0..<tens {
            let rod = Self.tenRod(scale: 0.72)
            rod.position = CGPoint(
                x: centerX - 68 + CGFloat(index % 5) * 28,
                y: 7 - CGFloat(index / 5) * 50
            )
            rod.name = prefix + "BlockTen"
            comparisonGroup.addChild(rod)
        }

        for index in 0..<ones {
            let cube = Self.oneCube(scale: 0.78)
            cube.position = CGPoint(
                x: centerX - 50 + CGFloat(index % 5) * 24,
                y: -48 - CGFloat(index / 5) * 24
            )
            cube.name = prefix + "BlockOne"
            comparisonGroup.addChild(cube)
        }
    }

    private static func tenRod(scale: CGFloat = 1) -> SKShapeNode {
        let rod = ArtSystem.box(
            CGSize(width: 20 * scale, height: 92 * scale),
            color: UIColor(red: 0.28, green: 0.74, blue: 0.87, alpha: 1),
            radius: 5 * scale
        )
        rod.strokeColor = UIColor(red: 0.86, green: 0.98, blue: 1, alpha: 0.92)
        rod.lineWidth = max(1, 2 * scale)

        for index in 1..<10 {
            let mark = SKShapeNode(rectOf: CGSize(width: 14 * scale, height: 1.2 * scale))
            mark.fillColor = UIColor.white.withAlphaComponent(0.44)
            mark.strokeColor = .clear
            mark.position.y = (-46 + CGFloat(index) * 9.2) * scale
            rod.addChild(mark)
        }
        return rod
    }

    private static func oneCube(scale: CGFloat = 1) -> SKShapeNode {
        let cube = ArtSystem.box(
            CGSize(width: 20 * scale, height: 20 * scale),
            color: UIColor(red: 0.63, green: 0.46, blue: 0.91, alpha: 1),
            radius: 4 * scale
        )
        cube.strokeColor = UIColor(red: 0.94, green: 0.90, blue: 1, alpha: 0.92)
        cube.lineWidth = max(1, 1.5 * scale)
        return cube
    }

    func playSuccessReaction(reducedMotion: Bool) {
        targetLabel.fontColor = UIColor(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        leftLabel.fontColor = UIColor(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        rightLabel.fontColor = UIColor(red: 1, green: 0.88, blue: 0.42, alpha: 1)
        guard !reducedMotion else { return }

        run(.sequence([
            .scale(to: 1.035, duration: 0.12),
            .scale(to: 1, duration: 0.18)
        ]), withKey: "successPulse")
    }
}

@MainActor enum MathCastleMechanicFactory {
    static func makeNode(for encounter: LearningEncounter) -> SKNode? {
        switch encounter.mechanicID {
        case MathMechanicID.balanceScale:
            return BalanceScaleMechanic()
        case MathMechanicID.numberBondMachine:
            return NumberBondMachineMechanic()
        case MathMechanicID.tenFrameGate:
            return TenFrameGateMechanic()
        case MathMechanicID.missingNumberBridge:
            return MissingNumberBridgeMechanic()
        case MathMechanicID.placeValueFactory:
            return PlaceValueFactoryMechanic()
        default:
            return nil
        }
    }
}
