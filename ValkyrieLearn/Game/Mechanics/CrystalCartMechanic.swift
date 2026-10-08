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


@MainActor final class PatternLoomMechanic: SKNode, MathCastleReactiveMechanic {
    private let sequenceGroup = SKNode()
    private let activityLabel = ArtSystem.label("", size: 17)
    private let progressLabel = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.patternLoom
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.name = MathMechanicID.patternLoom
        tray.position.y = -15
        tray.zPosition = -5
        addChild(tray)

        let header = ArtSystem.plaque(
            CGSize(width: 275, height: 45),
            fill: UIColor(red: 0.09, green: 0.11, blue: 0.21, alpha: 0.93),
            stroke: UIColor(red: 0.94, green: 0.72, blue: 0.32, alpha: 0.82),
            radius: 15
        )
        header.position = CGPoint(x: 0, y: 126)
        header.name = MathMechanicID.patternLoom
        addChild(header)

        let heading = ArtSystem.label("PATTERN LOOM", size: 18)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.patternLoom
        header.addChild(heading)

        activityLabel.fontName = "AvenirNext-DemiBold"
        activityLabel.fontColor = UIColor(red: 0.95, green: 0.86, blue: 0.60, alpha: 1)
        activityLabel.position = CGPoint(x: 0, y: 80)
        activityLabel.name = MathMechanicID.patternLoom
        addChild(activityLabel)

        progressLabel.fontName = "AvenirNext-DemiBold"
        progressLabel.fontColor = UIColor(red: 0.82, green: 0.95, blue: 0.99, alpha: 1)
        progressLabel.position = CGPoint(x: 0, y: -63)
        progressLabel.name = MathMechanicID.patternLoom
        addChild(progressLabel)

        addChild(sequenceGroup)

        for (symbol, label, number, x) in [
            ("●", "Circle", 1, CGFloat(-160)),
            ("◆", "Diamond", 2, CGFloat(-10)),
            ("▲", "Triangle", 3, CGFloat(140))
        ] {
            let button = ArtSystem.medallion(
                radius: 30,
                fill: UIColor(red: 0.10, green: 0.24, blue: 0.35, alpha: 1),
                stroke: UIColor(red: 0.96, green: 0.77, blue: 0.38, alpha: 0.92),
                glow: 0
            )
            button.position = CGPoint(x: x, y: -122)
            button.name = "loomSymbol\(number)"
            button.zPosition = 50

            let mark = ArtSystem.label(symbol, size: 28)
            mark.fontColor = .white
            mark.name = button.name
            button.addChild(mark)

            // Explicit 68pt target above decorative children and behind no overlays.
            let hit = SKShapeNode(circleOfRadius: 34)
            hit.fillColor = .clear
            hit.strokeColor = .clear
            hit.name = button.name
            hit.zPosition = 40
            button.addChild(hit)
            button.accessibilityLabel = label
            addChild(button)
        }

        let undo = ArtSystem.medallion(
            radius: 25,
            fill: UIColor(red: 0.18, green: 0.12, blue: 0.19, alpha: 1),
            stroke: UIColor(red: 0.76, green: 0.75, blue: 0.88, alpha: 0.86),
            glow: 0
        )
        undo.position = CGPoint(x: 229, y: -122)
        undo.name = "loomUndo"
        undo.zPosition = 50
        let undoMark = ArtSystem.label("↶", size: 30)
        undoMark.name = "loomUndo"
        undo.addChild(undoMark)
        addChild(undo)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    func render(_ model: PatternLoomModel) {
        sequenceGroup.removeAllChildren()
        activityLabel.text = model.isCreation
            ? "CREATE A \(model.family.rawValue.uppercased()) PATTERN"
            : (model.isMissing ? "FILL THE MISSING SHAPE" : "CONTINUE THE PATTERN")
        progressLabel.text = model.isCreation
            ? "\(model.selectedSymbols.count) OF \(model.slotCount) SHAPES PLACED"
            : "TAP A SHAPE TO FILL THE ?"

        let slots = model.visibleSlots
        let step = min(CGFloat(61), CGFloat(476) / CGFloat(max(1, slots.count)))
        let startX = -step * CGFloat(slots.count - 1) / 2
        for (index, symbol) in slots.enumerated() {
            let isGap = !model.isCreation && index == model.gapIndex
            let frame = ArtSystem.panel(
                CGSize(width: step - 5, height: 64),
                fill: isGap
                    ? UIColor(red: 0.29, green: 0.20, blue: 0.14, alpha: 0.98)
                    : UIColor(red: 0.09, green: 0.18, blue: 0.24, alpha: 0.94),
                stroke: isGap
                    ? UIColor(red: 0.99, green: 0.79, blue: 0.40, alpha: 1)
                    : UIColor(red: 0.58, green: 0.82, blue: 0.90, alpha: 0.68),
                radius: 12,
                lineWidth: 2,
                shadowAlpha: 0.08
            )
            frame.position = CGPoint(x: startX + CGFloat(index) * step, y: 5)
            frame.name = MathMechanicID.patternLoom
            sequenceGroup.addChild(frame)

            let glyph: String
            switch symbol {
            case 1: glyph = "●"
            case 2: glyph = "◆"
            case 3: glyph = "▲"
            default: glyph = isGap ? "?" : "·"
            }
            let mark = ArtSystem.label(glyph, size: 30)
            mark.fontName = "AvenirNext-Heavy"
            mark.fontColor = symbol == nil
                ? UIColor(red: 1, green: 0.88, blue: 0.53, alpha: 1)
                : .white
            mark.name = MathMechanicID.patternLoom
            frame.addChild(mark)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        activityLabel.fontColor = UIColor(red: 1.0, green: 0.89, blue: 0.47, alpha: 1)
        guard !reducedMotion else { return }
        sequenceGroup.run(.sequence([
            .scale(to: 1.035, duration: 0.13),
            .scale(to: 1.0, duration: 0.18)
        ]), withKey: "successPulse")
    }
}


@MainActor final class ShapeForgeMechanic: SKNode, MathCastleReactiveMechanic {
    private let display = SKNode()
    private let title = ArtSystem.label("SHAPE FORGE", size: 18)
    private let instructionLabel = ArtSystem.label("", size: 17)

    override init() {
        super.init()
        name = MathMechanicID.shapeForge
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 284))
        tray.name = MathMechanicID.shapeForge
        tray.position.y = -15
        tray.zPosition = -5
        addChild(tray)

        let heading = ArtSystem.plaque(
            CGSize(width: 282, height: 47),
            fill: UIColor(red: 0.07, green: 0.13, blue: 0.22, alpha: 0.95),
            stroke: UIColor(red: 0.95, green: 0.76, blue: 0.38, alpha: 0.84),
            radius: 15
        )
        heading.position.y = 126
        heading.name = MathMechanicID.shapeForge
        addChild(heading)
        title.fontName = "AvenirNext-Heavy"
        title.fontColor = .white
        title.name = MathMechanicID.shapeForge
        heading.addChild(title)

        instructionLabel.fontName = "AvenirNext-DemiBold"
        instructionLabel.fontColor = UIColor(red: 0.96, green: 0.84, blue: 0.57, alpha: 1)
        instructionLabel.position.y = 82
        instructionLabel.name = MathMechanicID.shapeForge
        addChild(instructionLabel)
        addChild(display)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private static func shapeNode(_ shape: ForgeShape, size: CGFloat) -> SKShapeNode {
        let node: SKShapeNode
        switch shape {
        case .circle:
            node = SKShapeNode(circleOfRadius: size * 0.48)
        case .square:
            node = SKShapeNode(rectOf: CGSize(width: size, height: size))
        case .rectangle:
            node = SKShapeNode(rectOf: CGSize(width: size * 1.17, height: size * 0.73))
        case .triangle:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: 0, y: size * 0.59))
            p.addLine(to: CGPoint(x: -size * 0.54, y: -size * 0.41))
            p.addLine(to: CGPoint(x: size * 0.54, y: -size * 0.41))
            p.closeSubpath()
            node = SKShapeNode(path: p)
        }
        node.fillColor = UIColor(red: 0.22, green: 0.67, blue: 0.77, alpha: 1)
        node.strokeColor = UIColor(red: 0.94, green: 0.93, blue: 0.72, alpha: 1)
        node.lineWidth = 3
        node.glowWidth = 1
        return node
    }

    private static func angledTriangle(size: CGFloat) -> SKShapeNode {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: -size * 0.5, y: -size * 0.5))
        p.addLine(to: CGPoint(x: size * 0.5, y: -size * 0.5))
        p.addLine(to: CGPoint(x: -size * 0.5, y: size * 0.5))
        p.closeSubpath()
        return SKShapeNode(path: p)
    }

    private func choiceFrame(name: String, at x: CGFloat, y: CGFloat) -> SKNode {
        let plate = ArtSystem.panel(
            CGSize(width: 108, height: 104),
            fill: UIColor(red: 0.07, green: 0.20, blue: 0.27, alpha: 0.96),
            stroke: UIColor(red: 0.57, green: 0.87, blue: 0.92, alpha: 0.81),
            radius: 17,
            lineWidth: 2,
            shadowAlpha: 0.08
        )
        plate.position = CGPoint(x: x, y: y)
        plate.name = name
        plate.zPosition = 10
        display.addChild(plate)
        return plate
    }

    func render(_ model: ShapeForgeModel) {
        display.removeAllChildren()
        switch model.task {
        case .recognize:
            instructionLabel.text = "FIND THE \(model.shape?.name.uppercased() ?? "SHAPE")"
            for (index, shape) in model.shapeChoices.enumerated() {
                let x = CGFloat(index - 1) * 158
                let frame = choiceFrame(name: "forgeChoice\(index + 1)", at: x, y: -20)
                let artwork = Self.shapeNode(shape, size: 62)
                artwork.name = frame.name
                frame.addChild(artwork)
                let number = ArtSystem.label("\(index + 1)", size: 14)
                number.name = frame.name
                number.position.y = -65
                frame.addChild(number)
            }
        case .attributes:
            instructionLabel.text = "COUNT THE CORNERS"
            if let shape = model.shape {
                let shapeNode = Self.shapeNode(shape, size: 83)
                shapeNode.position.y = 28
                shapeNode.name = MathMechanicID.shapeForge
                display.addChild(shapeNode)
            }
            for (index, corners) in model.cornerChoices.enumerated() {
                let frame = choiceFrame(name: "forgeChoice\(index + 1)", at: CGFloat(index - 1) * 153, y: -104)
                let label = ArtSystem.label("\(corners)", size: 31)
                label.fontName = "AvenirNext-Heavy"
                label.fontColor = .white
                label.name = frame.name
                frame.addChild(label)
            }
        case .compose:
            instructionLabel.text = "FILL THE SQUARE • \(model.placedHalfTurns.count) / 2 PIECES"

            // The gold pieces show two complementary right-triangle halves;
            // cyan triangles show the child's actual placement.
            for (index, turns) in model.requiredHalfTurns.enumerated() {
                let target = Self.angledTriangle(size: 120)
                target.position = CGPoint(x: 0, y: -8)
                target.zRotation = CGFloat(turns) * .pi / 2
                target.fillColor = UIColor(
                    red: index == 0 ? 0.96 : 0.80, green: 0.75, blue: 0.39, alpha: 0.10
                )
                target.strokeColor = UIColor(red: 0.98, green: 0.81, blue: 0.47, alpha: 0.83)
                target.lineWidth = 2
                target.name = MathMechanicID.shapeForge
                display.addChild(target)
            }

            for (index, turns) in model.placedHalfTurns.enumerated() {
                let piece = Self.angledTriangle(size: 120)
                piece.position = CGPoint(x: 0, y: -8)
                piece.zRotation = CGFloat(turns) * .pi / 2
                piece.fillColor = UIColor(
                    red: index == 0 ? 0.24 : 0.28,
                    green: index == 0 ? 0.75 : 0.61,
                    blue: 0.91, alpha: 0.88
                )
                piece.strokeColor = .white
                piece.lineWidth = 2
                piece.name = MathMechanicID.shapeForge
                display.addChild(piece)
            }

            let squareOutline = SKShapeNode(rectOf: CGSize(width: 122, height: 122))
            squareOutline.position = CGPoint(x: 0, y: -8)
            squareOutline.fillColor = .clear
            squareOutline.strokeColor = UIColor(red: 0.99, green: 0.86, blue: 0.53, alpha: 1)
            squareOutline.lineWidth = 3
            squareOutline.name = MathMechanicID.shapeForge
            display.addChild(squareOutline)

            for orientation in 0...3 {
                let name = "forgeHalf\(orientation)"
                let x = CGFloat(orientation) * 110 - 165
                let button = ArtSystem.medallion(
                    radius: 29,
                    fill: UIColor(red: 0.12, green: 0.26, blue: 0.36, alpha: 1),
                    stroke: UIColor(red: 0.86, green: 0.82, blue: 0.57, alpha: 0.96),
                    glow: 0
                )
                button.position = CGPoint(x: x, y: -122)
                button.name = name
                display.addChild(button)
                let piece = Self.angledTriangle(size: 32)
                piece.zRotation = CGFloat(orientation) * .pi / 2
                piece.fillColor = UIColor(red: 0.33, green: 0.75, blue: 0.92, alpha: 1)
                piece.strokeColor = .white
                piece.name = name
                button.addChild(piece)
            }

            let undo = ArtSystem.label("UNDO", size: 15)
            undo.position = CGPoint(x: 213, y: 24)
            undo.fontColor = UIColor(red: 1, green: 0.87, blue: 0.55, alpha: 1)
            undo.name = "forgeUndoHalf"
            display.addChild(undo)
        case .symmetry:
            instructionLabel.text = "MIRROR THE LEFT-HAND SHAPES"
            let axisPath = CGMutablePath()
            axisPath.move(to: CGPoint(x: 0, y: 58))
            axisPath.addLine(to: CGPoint(x: 0, y: -103))
            let axis = SKShapeNode(path: axisPath)
            axis.strokeColor = UIColor(red: 0.99, green: 0.83, blue: 0.46, alpha: 0.94)
            axis.lineWidth = 3
            axis.name = MathMechanicID.shapeForge
            display.addChild(axis)

            for row in 0..<3 {
                let y = CGFloat(33 - row * 54)
                for column in 0..<2 {
                    let rightSide = column == 1
                    let panel = ArtSystem.panel(
                        CGSize(width: 87, height: 47),
                        fill: UIColor(red: 0.08, green: 0.20, blue: 0.29, alpha: 0.96),
                        stroke: rightSide
                            ? UIColor(red: 0.99, green: 0.78, blue: 0.42, alpha: 0.94)
                            : UIColor(red: 0.52, green: 0.82, blue: 0.91, alpha: 0.74),
                        radius: 12,
                        lineWidth: 2,
                        shadowAlpha: 0.06
                    )
                    panel.position = CGPoint(x: rightSide ? 103 : -103, y: y)
                    let name = rightSide ? "forgeMirror\(row)" : MathMechanicID.shapeForge
                    panel.name = name
                    display.addChild(panel)
                    let shape: ForgeShape?
                    if rightSide {
                        shape = model.mirrorCells[row].flatMap { ForgeShape(rawValue: $0) }
                    } else {
                        shape = model.symmetryReference[row]
                    }
                    if let shape {
                        let drawn = Self.shapeNode(shape, size: 27)
                        drawn.name = name
                        panel.addChild(drawn)
                    } else {
                        let marker = ArtSystem.label("?", size: 28)
                        marker.name = name
                        marker.fontColor = UIColor(red: 0.99, green: 0.84, blue: 0.55, alpha: 1)
                        panel.addChild(marker)
                    }
                }
            }
        case .rotate:
            instructionLabel.text = "MATCH THE GOLD OUTLINE"
            let target = Self.angledTriangle(size: 87)
            target.position = CGPoint(x: -121, y: -6)
            target.zRotation = CGFloat(model.targetOrientation) * .pi / 2
            target.fillColor = UIColor(red: 0.96, green: 0.79, blue: 0.40, alpha: 0.11)
            target.strokeColor = UIColor(red: 0.99, green: 0.85, blue: 0.43, alpha: 1)
            target.lineWidth = 4
            target.name = MathMechanicID.shapeForge
            display.addChild(target)

            let selected = Self.angledTriangle(size: 87)
            selected.position = CGPoint(x: 121, y: -6)
            selected.zRotation = CGFloat(model.currentOrientation) * .pi / 2
            selected.fillColor = UIColor(red: 0.25, green: 0.74, blue: 0.88, alpha: 1)
            selected.strokeColor = .white
            selected.lineWidth = 3
            selected.name = MathMechanicID.shapeForge
            display.addChild(selected)

            for (name, symbol, x) in [
                ("forgeTurnLeft", "↺", CGFloat(-104)),
                ("forgeTurnRight", "↻", CGFloat(104))
            ] {
                let button = ArtSystem.medallion(
                    radius: 35,
                    fill: UIColor(red: 0.11, green: 0.26, blue: 0.37, alpha: 1),
                    stroke: UIColor(red: 0.97, green: 0.79, blue: 0.40, alpha: 0.96),
                    glow: 0
                )
                button.position = CGPoint(x: x, y: -118)
                button.name = name
                display.addChild(button)
                let mark = ArtSystem.label(symbol, size: 32)
                mark.fontColor = .white
                mark.name = name
                button.addChild(mark)
            }
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        title.fontColor = UIColor(red: 1, green: 0.90, blue: 0.53, alpha: 1)
        guard !reducedMotion else { return }
        display.run(.sequence([
            .scale(to: 1.03, duration: 0.12),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "shapeSuccessPulse")
    }
}


@MainActor final class MeasurementWorkshopMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let heading = ArtSystem.label("MEASUREMENT WORKSHOP", size: 17)
    private let instruction = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.measurementWorkshop
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.name = MathMechanicID.measurementWorkshop
        tray.position.y = -14
        tray.zPosition = -5
        addChild(tray)

        let plaque = ArtSystem.plaque(
            CGSize(width: 300, height: 47),
            fill: UIColor(red: 0.09, green: 0.16, blue: 0.25, alpha: 0.97),
            stroke: UIColor(red: 0.96, green: 0.75, blue: 0.38, alpha: 0.87),
            radius: 15
        )
        plaque.name = MathMechanicID.measurementWorkshop
        plaque.position.y = 127
        addChild(plaque)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.measurementWorkshop
        plaque.addChild(heading)

        instruction.fontName = "AvenirNext-DemiBold"
        instruction.fontColor = UIColor(red: 0.95, green: 0.86, blue: 0.59, alpha: 1)
        instruction.position.y = 92
        instruction.name = MathMechanicID.measurementWorkshop
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func title(_ message: String, x: CGFloat, y: CGFloat, size: CGFloat = 16) {
        let label = ArtSystem.label(message, size: size)
        label.fontName = "AvenirNext-DemiBold"
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.name = MathMechanicID.measurementWorkshop
        activity.addChild(label)
    }

    private func box(_ width: CGFloat, _ height: CGFloat, x: CGFloat, y: CGFloat,
                     color: UIColor, outline: UIColor, name: String) -> SKShapeNode {
        let panel = SKShapeNode(
            rectOf: CGSize(width: width, height: height),
            cornerRadius: 7
        )
        panel.position = CGPoint(x: x, y: y)
        panel.fillColor = color
        panel.strokeColor = outline
        panel.lineWidth = 2
        panel.name = name
        activity.addChild(panel)
        return panel
    }

    private func button(_ symbol: String, name: String, x: CGFloat) {
        let gear = ArtSystem.gear(radius: 34, symbol: symbol)
        gear.position = CGPoint(x: x, y: -120)
        gear.zPosition = 50
        gear.name = name
        activity.addChild(gear)

        // Named 72pt circular hit region is shared with geometric scene
        // routing, so a decorative child cannot steal a measurement tap.
        let hit = SKShapeNode(circleOfRadius: 36)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.position = CGPoint(x: x, y: -120)
        hit.zPosition = 70
        hit.name = name
        activity.addChild(hit)
    }

    func render(_ model: MeasurementWorkshopModel) {
        activity.removeAllChildren()
        if model.isUnitMeasurement {
            instruction.text = "PLACE EQUAL UNITS • NO GAPS"
            let n = model.targetUnitCount
            let unitWidth: CGFloat = 32
            let baseX = -CGFloat(n) * unitWidth / 2
            _ = box(
                CGFloat(n) * unitWidth + 6, 42, x: 0, y: 5,
                color: UIColor(red: 0.13, green: 0.25, blue: 0.30, alpha: 1),
                outline: UIColor(red: 0.98, green: 0.82, blue: 0.45, alpha: 1),
                name: MathMechanicID.measurementWorkshop
            )
            for i in 0..<n {
                _ = box(
                    1, 40,
                    x: baseX + CGFloat(i) * unitWidth,
                    y: 5,
                    color: UIColor(red: 0.79, green: 0.86, blue: 0.90, alpha: 0.35),
                    outline: .clear,
                    name: MathMechanicID.measurementWorkshop
                )
            }
            for i in 0..<model.placedUnits {
                let x = baseX + (CGFloat(i) + 0.5) * unitWidth
                let isOver = i >= n
                _ = box(
                    model.unitStyle == "tiles" ? 30 : 28,
                    model.unitStyle == "tiles" ? 28 : 32,
                    x: x, y: 5,
                    color: isOver
                        ? UIColor(red: 0.91, green: 0.37, blue: 0.32, alpha: 1)
                        : UIColor(red: 0.29, green: 0.73, blue: 0.80, alpha: 1),
                    outline: .white,
                    name: MathMechanicID.measurementWorkshop
                )
            }
            title("\(model.placedUnits) UNITS PLACED", x: 0, y: -57)
            button("−", name: "measureRemove", x: -94)
            button("+", name: "measureAdd", x: 94)
        } else {
            switch model.task {
            case .length: instruction.text = "COMPARE THE RIBBONS"
            case .weight: instruction.text = "COMPARE THE STONE TRAYS"
            case .capacity: instruction.text = "COMPARE CAPACITY IN CUPS"
            case .units: break
            }

            for (side, value) in [(0, model.leftValue), (1, model.rightValue)] {
                let x: CGFloat = side == 0 ? -123 : 123
                let which = side == 0 ? "LEFT" : "RIGHT"
                _ = box(
                    212, 142, x: x, y: -4,
                    color: UIColor(red: 0.10, green: 0.21, blue: 0.29, alpha: 1),
                    outline: UIColor(red: 0.66, green: 0.84, blue: 0.91, alpha: 0.8),
                    name: MathMechanicID.measurementWorkshop
                )
                title(which, x: x, y: 51, size: 14)
                switch model.task {
                case .length:
                    // Every 18pt segment represents exactly one equal-length unit.
                    for i in 0..<value {
                        _ = box(
                            16, 27,
                            x: x - CGFloat(value - 1) * 9 + CGFloat(i) * 18,
                            y: 4,
                            color: UIColor(red: 0.29, green: 0.74, blue: 0.84, alpha: 1),
                            outline: .white,
                            name: MathMechanicID.measurementWorkshop
                        )
                    }
                    title("RIBBON", x: x, y: -49, size: 12)
                case .weight:
                    // Equal-weight stones make the mass comparison tangible.
                    for i in 0..<value {
                        let stone = SKShapeNode(circleOfRadius: 10)
                        stone.position = CGPoint(
                            x: x + CGFloat(i % 4) * 27 - 40,
                            y: CGFloat(i / 4) * 27 - 5
                        )
                        stone.fillColor = UIColor(red: 0.58, green: 0.73, blue: 0.90, alpha: 1)
                        stone.strokeColor = .white
                        stone.lineWidth = 1
                        stone.name = MathMechanicID.measurementWorkshop
                        activity.addChild(stone)
                    }
                    title("EQUAL STONES", x: x, y: -49, size: 12)
                case .capacity:
                    // All cups share a fixed-width base and each band is an
                    // equal-size scoop. Vessel HEIGHT changes with capacity,
                    // so the child compares what can fit, not water level in two
                    // equal-capacity containers.
                    let vesselHeight = CGFloat(value) * 11 + 4
                    _ = box(
                        88, vesselHeight, x: x, y: -45 + vesselHeight / 2, color: .clear,
                        outline: UIColor(red: 0.75, green: 0.93, blue: 0.99, alpha: 1),
                        name: MathMechanicID.measurementWorkshop
                    )
                    for i in 0..<value {
                        _ = box(
                            78, 9, x: x, y: -43 + CGFloat(i) * 11,
                            color: UIColor(red: 0.27, green: 0.66, blue: 0.93, alpha: 0.95),
                            outline: .clear,
                            name: MathMechanicID.measurementWorkshop
                        )
                    }
                    title("EQUAL CUPS", x: x, y: -62, size: 12)
                case .units:
                    break
                }
            }
            button("◀", name: "measureLeft", x: -155)
            button("=", name: "measureEqual", x: 0)
            button("▶", name: "measureRight", x: 155)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 1, green: 0.88, blue: 0.47, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1.0, duration: 0.17)
        ]), withKey: "measurementSuccess")
    }
}


@MainActor final class DataBoardMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let heading = ArtSystem.label("DATA BOARD", size: 19)
    private let instruction = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.dataBoard
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.name = MathMechanicID.dataBoard
        tray.position.y = -14
        tray.zPosition = -5
        addChild(tray)

        let plaque = ArtSystem.plaque(
            CGSize(width: 276, height: 46),
            fill: UIColor(red: 0.09, green: 0.16, blue: 0.27, alpha: 0.97),
            stroke: UIColor(red: 0.97, green: 0.81, blue: 0.48, alpha: 0.9),
            radius: 15
        )
        plaque.position.y = 127
        plaque.name = MathMechanicID.dataBoard
        addChild(plaque)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.dataBoard
        plaque.addChild(heading)

        instruction.fontName = "AvenirNext-DemiBold"
        instruction.fontColor = UIColor(red: 0.99, green: 0.87, blue: 0.61, alpha: 1)
        instruction.position.y = 99
        instruction.name = MathMechanicID.dataBoard
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func tokenColor(_ code: Int) -> UIColor {
        switch code {
        case 1: return UIColor(red: 0.29, green: 0.73, blue: 0.98, alpha: 1)
        case 2: return UIColor(red: 1.00, green: 0.78, blue: 0.32, alpha: 1)
        default: return UIColor(red: 0.99, green: 0.49, blue: 0.72, alpha: 1)
        }
    }

    private func shapeToken(
        shape: Int, color: Int, radius: CGFloat, name: String
    ) -> SKShapeNode {
        let node: SKShapeNode
        switch shape {
        case 1: node = SKShapeNode(circleOfRadius: radius)
        case 2:
            node = SKShapeNode(rectOf: CGSize(width: radius * 1.8, height: radius * 1.8),
                               cornerRadius: 3)
        default:
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: radius))
            path.addLine(to: CGPoint(x: -radius, y: -radius * 0.8))
            path.addLine(to: CGPoint(x: radius, y: -radius * 0.8))
            path.closeSubpath()
            node = SKShapeNode(path: path)
        }
        node.name = name
        node.fillColor = tokenColor(color)
        node.strokeColor = .white
        node.lineWidth = 2
        return node
    }

    private func text(_ title: String, at position: CGPoint, size: CGFloat = 14,
                      name: String = MathMechanicID.dataBoard) {
        let label = ArtSystem.label(title, size: size)
        label.fontName = "AvenirNext-DemiBold"
        label.fontColor = .white
        label.position = position
        label.name = name
        activity.addChild(label)
    }

    private func panel(_ width: CGFloat, _ height: CGFloat, at point: CGPoint,
                       name: String = MathMechanicID.dataBoard) {
        let node = ArtSystem.panel(
            CGSize(width: width, height: height),
            fill: UIColor(red: 0.08, green: 0.23, blue: 0.30, alpha: 0.98),
            stroke: UIColor(red: 0.56, green: 0.85, blue: 0.94, alpha: 0.80),
            radius: 13,
            lineWidth: 2,
            shadowAlpha: 0.07
        )
        node.position = point
        node.name = name
        activity.addChild(node)
    }

    private func button(_ mark: String, name: String, x: CGFloat, y: CGFloat = -121) {
        let gear = ArtSystem.gear(radius: 34, symbol: mark)
        gear.position = CGPoint(x: x, y: y)
        gear.zPosition = 50
        gear.name = name
        activity.addChild(gear)
        let hit = SKShapeNode(circleOfRadius: 37)
        hit.position = CGPoint(x: x, y: y)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.zPosition = 70
        hit.name = name
        activity.addChild(hit)
    }

    func render(_ model: DataBoardModel) {
        activity.removeAllChildren()
        if model.isSorting {
            renderSorting(model)
        } else {
            renderGraph(model)
        }
    }

    private func renderSorting(_ model: DataBoardModel) {
        instruction.text = model.sortingAttribute == .color
            ? "SORT EACH OBJECT BY COLOR"
            : "SORT EACH OBJECT BY SHAPE"
        let tokens = model.sortingTokens
        if let current = model.nextSortingToken {
            let node = shapeToken(shape: current.shape, color: current.color,
                                  radius: 25, name: MathMechanicID.dataBoard)
            node.position = CGPoint(x: 0, y: 50)
            activity.addChild(node)
        } else {
            text("ALL SORTED — CHECK WITH PIP", at: CGPoint(x: 0, y: 48), size: 15)
        }

        for category in 1...3 {
            let x = CGFloat(category - 2) * 158
            panel(144, 66, at: CGPoint(x: x, y: -36))
            let name: String
            if model.sortingAttribute == .color {
                name = ["BLUE", "GOLD", "PINK"][category - 1]
            } else {
                name = ["CIRCLES", "SQUARES", "TRIANGLES"][category - 1]
            }
            text(name, at: CGPoint(x: x, y: 5), size: 13)
            // Pre-readers should identify the correct bin from its icon,
            // not from English labels alone. Colors are distinct in color
            // mode; silhouettes are distinct in shape mode.
            let marker = shapeToken(
                shape: model.sortingAttribute == .color ? 1 : category,
                color: model.sortingAttribute == .color ? category : 1,
                radius: 11, name: MathMechanicID.dataBoard
            )
            marker.position = CGPoint(x: x, y: -15)
            activity.addChild(marker)
            for (index, bin) in model.sortedBins.enumerated() where bin == category {
                let slot = model.sortedBins.prefix(index + 1).filter { $0 == category }.count - 1
                let tok = tokens[index]
                let drawn = shapeToken(shape: tok.shape, color: tok.color,
                                       radius: 10, name: MathMechanicID.dataBoard)
                drawn.position = CGPoint(x: x - 40 + CGFloat(slot) * 20, y: -39)
                activity.addChild(drawn)
            }
            let symbol = model.sortingAttribute == .color
                ? ["●", "●", "●"][category - 1] : ["●", "■", "▲"][category - 1]
            button(symbol, name: "dataBin\(category)", x: x)
        }

        button("↶", name: "dataUndo", x: 230, y: 53)
        text("\(model.sortedBins.count) OF 5 OBJECTS SORTED",
             at: CGPoint(x: 0, y: -81), size: 13)
    }

    private func renderGraph(_ model: DataBoardModel) {
        instruction.text = "ONE PICTURE = ONE OBJECT"
        let counts = model.graphSourceCounts
        for column in 1...3 {
            let x = CGFloat(column - 2) * 158
            text(["CIRCLES", "SQUARES", "TRIANGLES"][column - 1],
                 at: CGPoint(x: x, y: 79), size: 12)
            let sourceCount = counts[column - 1]
            for index in 0..<sourceCount {
                let shape = shapeToken(
                    shape: column, color: column, radius: 9, name: MathMechanicID.dataBoard
                )
                shape.position = CGPoint(
                    x: x - CGFloat(sourceCount - 1) * 14 + CGFloat(index) * 28,
                    y: 55
                )
                activity.addChild(shape)
            }

            panel(116, 110, at: CGPoint(x: x, y: -37))
            for index in 0..<model.graphTiles[column - 1] {
                let tile = shapeToken(shape: column, color: column, radius: 10,
                                      name: MathMechanicID.dataBoard)
                tile.position = CGPoint(x: x, y: -78 + CGFloat(index) * 18)
                activity.addChild(tile)
            }
            button("+", name: "dataGraph\(column)", x: x)
        }
        button("↶", name: "dataUndo", x: 230, y: 51)
        text("\(model.placedGraphTotal) PICTURES PLACED",
             at: CGPoint(x: 0, y: 23), size: 13)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 1, green: 0.91, blue: 0.55, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.025, duration: 0.13),
            .scale(to: 1.0, duration: 0.16)
        ]), withKey: "dataBoardSuccess")
    }
}


@MainActor final class ClockMarketMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let heading = ArtSystem.label("CLOCK & MARKET", size: 19)
    private let instructions = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.clockMarket
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.clockMarket
        addChild(tray)

        let header = ArtSystem.plaque(
            CGSize(width: 300, height: 47),
            fill: UIColor(red: 0.07, green: 0.15, blue: 0.26, alpha: 0.96),
            stroke: UIColor(red: 0.96, green: 0.78, blue: 0.38, alpha: 0.91),
            radius: 15
        )
        header.position.y = 128
        header.name = MathMechanicID.clockMarket
        addChild(header)
        heading.fontColor = .white
        heading.fontName = "AvenirNext-Heavy"
        heading.name = MathMechanicID.clockMarket
        header.addChild(heading)

        instructions.position.y = 96
        instructions.fontName = "AvenirNext-DemiBold"
        instructions.fontColor = UIColor(red: 1, green: 0.86, blue: 0.54, alpha: 1)
        instructions.name = MathMechanicID.clockMarket
        addChild(instructions)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat = 16,
                      color: UIColor = .white) {
        let label = ArtSystem.label(value, size: size)
        label.position = CGPoint(x: x, y: y)
        label.fontColor = color
        label.fontName = "AvenirNext-DemiBold"
        label.name = MathMechanicID.clockMarket
        activity.addChild(label)
    }

    private func control(_ mark: String, name: String, x: CGFloat, y: CGFloat,
                         radius: CGFloat = 34) {
        let coin = ArtSystem.medallion(
            radius: radius,
            fill: UIColor(red: 0.12, green: 0.27, blue: 0.39, alpha: 1),
            stroke: UIColor(red: 1, green: 0.80, blue: 0.46, alpha: 0.95),
            glow: 0
        )
        coin.position = CGPoint(x: x, y: y)
        coin.zPosition = 50
        coin.name = name
        activity.addChild(coin)
        let label = ArtSystem.label(mark, size: mark.count > 3 ? 13 : 20)
        label.fontName = "AvenirNext-Heavy"
        label.fontColor = .white
        label.name = name
        coin.addChild(label)

        let touch = SKShapeNode(circleOfRadius: radius + 3)
        touch.position = CGPoint(x: x, y: y)
        touch.fillColor = .clear
        touch.strokeColor = .clear
        touch.zPosition = 71
        touch.name = name
        activity.addChild(touch)
    }

    func render(_ model: ClockMarketModel) {
        activity.removeAllChildren()
        switch model.task {
        case .hour, .halfHour, .fiveMinutes:
            renderClock(model)
        case .routines:
            renderRoutines(model)
        case .money:
            renderMoney(model)
        }
    }

    private func renderClock(_ model: ClockMarketModel) {
        instructions.text = model.task == .hour
            ? "TURN THE HOUR HAND"
            : (model.task == .halfHour ? "TURN TO O'CLOCK OR HALF PAST" : "TIME TO FIVE MINUTES")
        let center = CGPoint(x: -113, y: -12)
        let face = SKShapeNode(circleOfRadius: 91)
        face.position = center
        face.fillColor = UIColor(red: 0.99, green: 0.95, blue: 0.82, alpha: 1)
        face.strokeColor = UIColor(red: 0.96, green: 0.77, blue: 0.33, alpha: 1)
        face.lineWidth = 4
        face.name = MathMechanicID.clockMarket
        activity.addChild(face)

        for tick in 0..<12 {
            let angle = CGFloat(tick) * .pi / 6
            let dot = SKShapeNode(circleOfRadius: 3)
            dot.fillColor = UIColor(red: 0.09, green: 0.17, blue: 0.27, alpha: 1)
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: center.x + sin(angle) * 77,
                y: center.y + cos(angle) * 77
            )
            dot.name = MathMechanicID.clockMarket
            activity.addChild(dot)
        }

        let hourAngle = (CGFloat(model.hour % 12) + CGFloat(model.minute) / 60) * .pi / 6
        let minuteAngle = CGFloat(model.minute) * .pi / 30
        for (angle, length, width) in [
            (hourAngle, CGFloat(47), CGFloat(6)),
            (minuteAngle, CGFloat(69), CGFloat(3))
        ] {
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addLine(to: CGPoint(x: sin(angle) * length, y: cos(angle) * length))
            let hand = SKShapeNode(path: path)
            hand.position = center
            hand.strokeColor = UIColor(red: 0.08, green: 0.19, blue: 0.29, alpha: 1)
            hand.lineWidth = width
            hand.lineCap = .round
            hand.name = MathMechanicID.clockMarket
            activity.addChild(hand)
        }
        let minute = model.targetMinute < 10
            ? "0\(model.targetMinute)" : "\(model.targetMinute)"
        let yours = model.minute < 10 ? "0\(model.minute)" : "\(model.minute)"
        text("TARGET  \(model.targetHour):\(minute)", x: 109, y: 62, size: 20)
        text("YOURS  \(model.hour):\(yours)", x: 109, y: 28, size: 16)
        text("HOUR", x: 109, y: 1, size: 12)
        control("−", name: "clockHourMinus", x: 58, y: -46, radius: 34)
        control("+", name: "clockHourPlus", x: 161, y: -46, radius: 34)
        if model.task != .hour {
            text(model.task == .halfHour ? "HALF-HOUR" : "5 MINUTES",
                 x: 109, y: -85, size: 12)
            control("−", name: "clockMinuteMinus", x: 58, y: -125, radius: 33)
            control("+", name: "clockMinutePlus", x: 161, y: -125, radius: 33)
        }
    }

    private func renderRoutines(_ model: ClockMarketModel) {
        instructions.text = "WHICH PART OF THE DAY?"
        let event = model.nextRoutine
        let symbol: String
        switch event {
        case .wakeUp: symbol = "☀"
        case .lunch: symbol = "◉"
        case .dinner: symbol = "☽"
        case .sleep: symbol = "★"
        case nil: symbol = "✓"
        }
        text(symbol, x: 0, y: 51, size: 34,
             color: UIColor(red: 1, green: 0.83, blue: 0.46, alpha: 1))
        text(event?.title ?? "ALL FOUR SORTED", x: 0, y: 10, size: 18)
        for (index, part) in ClockMarketDaypart.allCases.enumerated() {
            let x = CGFloat(index) * 117 - 175.5
            let icon = ["☀", "◒", "☽", "★"][index]
            text(icon, x: x, y: -51, size: 24)
            control(icon, name: "routine\(part.rawValue)", x: x, y: -118,
                    radius: 33)
        }
        text("\(model.routineBins.count) OF 4 EVENTS", x: 0, y: -73, size: 13)
        control("↶", name: "routineUndo", x: 225, y: 51, radius: 29)
    }

    private func renderMoney(_ model: ClockMarketModel) {
        instructions.text = "PHILIPPINE PESO TEACHING COINS"
        text("PRICE: ₱\(model.targetPesos)", x: 0, y: 67, size: 24)
        text("COINS SELECTED: ₱\(model.totalPesos)", x: 0, y: 30, size: 18)
        let count = model.allowedCoins.count
        let spacing: CGFloat = count == 2 ? 148 : 104
        for (index, denomination) in model.allowedCoins.enumerated() {
            let x = CGFloat(index) * spacing - CGFloat(count - 1) * spacing / 2
            control("₱\(denomination)", name: "marketCoin\(denomination)",
                    x: x, y: -65, radius: 34)
        }
        text("\(model.coins.count) COINS ADDED", x: 0, y: -117, size: 13)
        control("↶", name: "marketCoinUndo", x: 222, y: 60, radius: 29)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 1, green: 0.89, blue: 0.51, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1.0, duration: 0.16)
        ]), withKey: "clockMarketPulse")
    }
}


@MainActor final class GroupingGardenMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let heading = ArtSystem.label("GROUPING GARDEN", size: 19)
    private let instruction = ArtSystem.label("", size: 14)

    override init() {
        super.init()
        name = MathMechanicID.groupingGarden
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.groupingGarden
        addChild(tray)

        let plaque = ArtSystem.plaque(
            CGSize(width: 302, height: 47),
            fill: UIColor(red: 0.08, green: 0.23, blue: 0.21, alpha: 0.97),
            stroke: UIColor(red: 0.95, green: 0.83, blue: 0.43, alpha: 1),
            radius: 16
        )
        plaque.position.y = 128
        plaque.name = MathMechanicID.groupingGarden
        addChild(plaque)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.groupingGarden
        plaque.addChild(heading)

        instruction.fontName = "AvenirNext-DemiBold"
        instruction.fontColor = UIColor(red: 0.95, green: 0.86, blue: 0.62, alpha: 1)
        instruction.position.y = 98
        instruction.name = MathMechanicID.groupingGarden
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func text(_ string: String, x: CGFloat, y: CGFloat, size: CGFloat = 15) {
        let label = ArtSystem.label(string, size: size)
        label.fontName = "AvenirNext-DemiBold"
        label.fontColor = .white
        label.position = CGPoint(x: x, y: y)
        label.name = MathMechanicID.groupingGarden
        activity.addChild(label)
    }

    private func control(_ title: String, name: String, x: CGFloat, y: CGFloat,
                         radius: CGFloat = 33) {
        let medallion = ArtSystem.medallion(
            radius: radius,
            fill: UIColor(red: 0.10, green: 0.31, blue: 0.30, alpha: 1),
            stroke: UIColor(red: 0.93, green: 0.84, blue: 0.48, alpha: 1),
            glow: 0
        )
        medallion.name = name
        medallion.position = CGPoint(x: x, y: y)
        medallion.zPosition = 50
        activity.addChild(medallion)

        let label = ArtSystem.label(title, size: title.count > 3 ? 14 : 20)
        label.fontName = "AvenirNext-Heavy"
        label.fontColor = .white
        label.name = name
        medallion.addChild(label)

        let hit = SKShapeNode(circleOfRadius: radius + 5)
        hit.position = CGPoint(x: x, y: y)
        hit.name = name
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.zPosition = 70
        activity.addChild(hit)
    }

    private func seed(x: CGFloat, y: CGFloat, radius: CGFloat = 8) {
        let pip = SKShapeNode(circleOfRadius: radius)
        pip.position = CGPoint(x: x, y: y)
        pip.fillColor = UIColor(red: 0.46, green: 0.89, blue: 0.59, alpha: 1)
        pip.strokeColor = UIColor(red: 0.97, green: 0.92, blue: 0.61, alpha: 1)
        pip.lineWidth = 1.5
        pip.name = MathMechanicID.groupingGarden
        activity.addChild(pip)
    }

    func render(_ model: GroupingGardenModel) {
        activity.removeAllChildren()
        switch model.task {
        case .equalGroups, .equalSharing:
            renderGroupBaskets(model)
        case .repeatedAddition:
            renderRepeatedJumps(model)
        case .halves, .quarters:
            renderFractionCuts(model)
        }
    }

    private func renderGroupBaskets(_ model: GroupingGardenModel) {
        instruction.text = model.task == .equalGroups
            ? "PLACE \(model.groupSize) SEEDS IN EACH BASKET"
            : "SHARE \(model.targetTotal) SEEDS EQUALLY"
        let n = model.groupCount
        let spacing: CGFloat = n == 2 ? 160 : (n == 3 ? 137 : 102)
        for index in 0..<n {
            let x = (CGFloat(index) - CGFloat(n - 1) / 2) * spacing
            let card = ArtSystem.panel(
                CGSize(width: n == 5 ? 94 : 117, height: 115),
                fill: UIColor(red: 0.12, green: 0.25, blue: 0.21, alpha: 0.96),
                stroke: UIColor(red: 0.81, green: 0.77, blue: 0.45, alpha: 0.88),
                radius: 12, lineWidth: 2, shadowAlpha: 0.08
            )
            card.position = CGPoint(x: x, y: 0)
            card.name = MathMechanicID.groupingGarden
            activity.addChild(card)
            text("BASKET \(index + 1)", x: x, y: 39, size: n == 5 ? 11 : 13)

            let count = model.groups[index]
            for piece in 0..<min(count, 12) {
                let dx = CGFloat(piece % 4) * 19 - 28.5
                let dy = CGFloat(piece / 4) * 21 - 33
                seed(x: x + dx, y: dy, radius: 7)
            }
            if count > 12 {
                text("+\(count - 12)", x: x, y: -42, size: 12)
            }
            control("＋", name: "gardenBasket\(index + 1)", x: x, y: -121,
                    radius: 32)
        }
        control("↶", name: "gardenUndoSeed", x: 229, y: 62, radius: 28)
        text("\(model.unitsPlaced) OF \(model.targetTotal) SEEDS PLACED",
             x: 0, y: -73, size: 13)
    }

    private func renderRepeatedJumps(_ model: GroupingGardenModel) {
        instruction.text = "COUNT BY \(model.groupSize) WITH \(model.groupCount) JUMPS"
        let n = model.groupCount
        let spacing: CGFloat = n == 2 ? 155 : (n == 3 ? 145 : 108)
        for i in 0..<n {
            let x = (CGFloat(i) - CGFloat(n - 1) / 2) * spacing
            let bg = ArtSystem.panel(
                CGSize(width: 98, height: 63),
                fill: UIColor(red: 0.13, green: 0.28, blue: 0.24, alpha: 1),
                stroke: UIColor(red: 0.74, green: 0.84, blue: 0.50, alpha: 0.78),
                radius: 9, lineWidth: 1.5, shadowAlpha: 0.04
            )
            bg.position = CGPoint(x: x, y: 38)
            bg.name = MathMechanicID.groupingGarden
            activity.addChild(bg)
            for j in 0..<model.groupSize {
                seed(x: x - CGFloat(model.groupSize - 1) * 8.5 + CGFloat(j) * 17,
                     y: 38, radius: 5.4)
            }
        }

        let originX: CGFloat = -198
        let stepX: CGFloat = 57
        for index in 0...min(model.jumps + 1, model.groupCount + 2) {
            let x = originX + CGFloat(index) * stepX
            if index <= model.jumps {
                let dot = SKShapeNode(circleOfRadius: 8)
                dot.position = CGPoint(x: x, y: -32)
                dot.fillColor = UIColor(red: 0.95, green: 0.81, blue: 0.36, alpha: 1)
                dot.strokeColor = .white
                dot.name = MathMechanicID.groupingGarden
                activity.addChild(dot)
                text("\(index * model.groupSize)", x: x, y: -57, size: 11)
            }
            if index > 0, index <= model.jumps {
                let line = SKShapeNode(
                    rectOf: CGSize(width: stepX - 14, height: 4)
                )
                line.fillColor = UIColor(red: 0.91, green: 0.77, blue: 0.36, alpha: 1)
                line.strokeColor = .clear
                line.position = CGPoint(x: x - stepX / 2, y: -32)
                line.name = MathMechanicID.groupingGarden
                activity.addChild(line)
            }
        }
        text("\(model.jumps) JUMPS  =  \(model.currentJumpTotal)",
             x: 85, y: -82, size: 15)
        control("＋", name: "gardenJumpAdd", x: -90, y: -122)
        control("↶", name: "gardenJumpUndo", x: 90, y: -122)
    }

    private func renderFractionCuts(_ model: GroupingGardenModel) {
        let parts = model.groupCount
        let horizontal = model.orientation == .row
        instruction.text = parts == 2
            ? "MOVE THE CUT TO MAKE 2 EQUAL PARTS"
            : "PLACE 3 CUTS TO MAKE 4 EQUAL PARTS"

        let count = model.unitCells
        let segmentSize: CGFloat = horizontal ? min(38, 348 / CGFloat(count))
            : min(25, 156 / CGFloat(count))
        let centerY: CGFloat = -4
        for cell in 0..<count {
            let part = SKShapeNode(
                rectOf: horizontal
                    ? CGSize(width: segmentSize - 1.5, height: 54)
                    : CGSize(width: 100, height: segmentSize - 1)
            )
            let offset = (CGFloat(cell) + 0.5 - CGFloat(count) / 2) * segmentSize
            part.position = horizontal
                ? CGPoint(x: offset, y: centerY)
                : CGPoint(x: 0, y: centerY + offset)
            part.fillColor = UIColor(red: 0.27, green: 0.62, blue: 0.37, alpha: 1)
            part.strokeColor = UIColor(red: 0.79, green: 0.87, blue: 0.63, alpha: 0.9)
            part.lineWidth = 1
            part.name = MathMechanicID.groupingGarden
            activity.addChild(part)
        }
        for cut in model.cuts {
            let position = (CGFloat(cut) - CGFloat(count) / 2) * segmentSize
            let section = SKShapeNode(
                rectOf: horizontal
                    ? CGSize(width: 4, height: 72)
                    : CGSize(width: 118, height: 4)
            )
            section.position = horizontal
                ? CGPoint(x: position, y: centerY)
                : CGPoint(x: 0, y: centerY + position)
            section.fillColor = UIColor(red: 1, green: 0.87, blue: 0.41, alpha: 1)
            section.strokeColor = .clear
            section.name = MathMechanicID.groupingGarden
            activity.addChild(section)
        }

        let cursor = (CGFloat(model.selectedBoundary) - CGFloat(count) / 2) * segmentSize
        let marker = SKShapeNode(
            rectOf: horizontal
                ? CGSize(width: 3, height: 85)
                : CGSize(width: 132, height: 3)
        )
        marker.fillColor = UIColor(red: 0.32, green: 0.87, blue: 0.96, alpha: 1)
        marker.strokeColor = .white
        marker.lineWidth = 1
        marker.position = horizontal
            ? CGPoint(x: cursor, y: centerY)
            : CGPoint(x: 0, y: centerY + cursor)
        marker.name = MathMechanicID.groupingGarden
        activity.addChild(marker)

        text("\(model.cuts.count) OF \(parts - 1) CUTS - DIVIDER \(model.selectedBoundary)",
             x: 0, y: -90, size: 13)
        control("◀", name: "gardenCutLeft", x: -159, y: -122)
        control("▶", name: "gardenCutRight", x: -53, y: -122)
        control("CUT", name: "gardenCutPlace", x: 53, y: -122)
        control("↶", name: "gardenCutUndo", x: 159, y: -122)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 0.99, green: 0.94, blue: 0.59, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.02, duration: 0.13),
            .scale(to: 1.0, duration: 0.18)
        ]), withKey: "gardenCompletion")
    }
}


@MainActor final class ReasoningStudioMechanic: SKNode, MathCastleReactiveMechanic {
    private let canvas = SKNode()
    private let heading = ArtSystem.label("REASONING STUDIO", size: 18)
    private let subtitle = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.reasoningStudio
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.reasoningStudio
        addChild(tray)

        let header = ArtSystem.plaque(
            CGSize(width: 305, height: 47),
            fill: UIColor(red: 0.09, green: 0.18, blue: 0.29, alpha: 0.98),
            stroke: UIColor(red: 0.96, green: 0.79, blue: 0.41, alpha: 0.92),
            radius: 15
        )
        header.position.y = 128
        header.name = MathMechanicID.reasoningStudio
        addChild(header)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.reasoningStudio
        header.addChild(heading)

        subtitle.fontName = "AvenirNext-DemiBold"
        subtitle.fontColor = UIColor(red: 0.99, green: 0.86, blue: 0.59, alpha: 1)
        subtitle.position.y = 98
        subtitle.name = MathMechanicID.reasoningStudio
        addChild(subtitle)
        addChild(canvas)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat = 16) {
        let item = ArtSystem.label(text, size: size)
        item.fontColor = .white
        item.fontName = "AvenirNext-DemiBold"
        item.position = CGPoint(x: x, y: y)
        item.name = MathMechanicID.reasoningStudio
        canvas.addChild(item)
    }

    private func button(_ text: String, name: String, x: CGFloat, y: CGFloat,
                        radius: CGFloat = 34) {
        let plate = ArtSystem.medallion(
            radius: radius,
            fill: UIColor(red: 0.11, green: 0.27, blue: 0.39, alpha: 1),
            stroke: UIColor(red: 0.98, green: 0.79, blue: 0.43, alpha: 1),
            glow: 0
        )
        plate.position = CGPoint(x: x, y: y)
        plate.name = name
        plate.zPosition = 50
        canvas.addChild(plate)
        let caption = ArtSystem.label(text, size: text.count > 5 ? 11 : 15)
        caption.fontColor = .white
        caption.fontName = "AvenirNext-Heavy"
        caption.name = name
        plate.addChild(caption)
        // Direct geometric hit testing also covers all decorative children.
        let hit = SKShapeNode(circleOfRadius: radius + 3)
        hit.position = CGPoint(x: x, y: y)
        hit.fillColor = .clear
        hit.strokeColor = .clear
        hit.zPosition = 70
        hit.name = name
        canvas.addChild(hit)
    }

    private func counter(x: CGFloat, y: CGFloat, filled: Bool = true) {
        let stone = SKShapeNode(circleOfRadius: 11)
        stone.position = CGPoint(x: x, y: y)
        stone.fillColor = filled
            ? UIColor(red: 0.34, green: 0.81, blue: 0.89, alpha: 1)
            : UIColor(red: 0.20, green: 0.30, blue: 0.34, alpha: 0.45)
        stone.strokeColor = UIColor(red: 1, green: 0.90, blue: 0.57, alpha: 1)
        stone.lineWidth = filled ? 2 : 1
        stone.name = MathMechanicID.reasoningStudio
        canvas.addChild(stone)
    }

    func render(_ model: ReasoningStudioModel) {
        canvas.removeAllChildren()
        switch model.task {
        case .strategy: renderStrategy(model)
        case .differentWays: renderDifferentWays(model)
        case .multiStep: renderMultiStep(model)
        }
    }

    private func renderStrategy(_ model: ReasoningStudioModel) {
        subtitle.text = "CHOOSE A WAY — SHOW EVERY STEP"
        label("\(model.startingValue) + \(model.addend) = ?", x: 0, y: 61, size: 24)
        button("COUNT", name: "reasonCountOn", x: -120, y: 9)
        button("BUILD", name: "reasonBuild", x: 120, y: 9)
        let selected: String
        switch model.chosenStrategy {
        case .countOn: selected = "COUNT ON — NUMBER LINE"
        case .buildCounters: selected = "BUILD — COUNTER TILES"
        case nil: selected = "PICK COUNT OR BUILD"
        }
        label(selected, x: 0, y: -38, size: 14)
        for index in 0..<model.addend {
            let x = (CGFloat(index) - CGFloat(model.addend - 1) / 2) * 42
            if model.chosenStrategy == .countOn {
                label(index < model.strategySteps ? "→" : "·",
                      x: x, y: -75, size: 26)
            } else {
                counter(x: x, y: -72, filled: index < model.strategySteps)
            }
        }
        button("+1", name: "reasonStepAdd", x: -92, y: -123)
        button("UNDO", name: "reasonStepUndo", x: 92, y: -123)
    }

    private func renderDifferentWays(_ model: ReasoningStudioModel) {
        subtitle.text = "MAKE TWO DIFFERENT NUMBER PAIRS"
        label("TWO WAYS TO MAKE \(model.startingValue)", x: 0, y: 70, size: 19)
        for slot in 0..<2 {
            let y: CGFloat = slot == 0 ? 35 : 0
            let line: String
            if slot < model.solutions.count {
                let pair = model.solutions[slot]
                line = "\(slot + 1).  \(pair.left) + \(pair.right) = \(pair.left + pair.right)"
            } else {
                line = "\(slot + 1).  ? + ? = \(model.startingValue)"
            }
            label(line, x: 0, y: y, size: 18)
        }
        label("YOUR PILES:  \(model.draftLeft) + \(model.draftRight)",
              x: 0, y: -45, size: 17)
        button("L+", name: "reasonPairLeftUp", x: -192, y: -122, radius: 32)
        button("L−", name: "reasonPairLeftDown", x: -110, y: -122, radius: 32)
        button("SAVE", name: "reasonPairSave", x: 0, y: -122, radius: 34)
        button("R+", name: "reasonPairRightUp", x: 110, y: -122, radius: 32)
        button("R−", name: "reasonPairRightDown", x: 192, y: -122, radius: 32)
        button("UNDO", name: "reasonPairUndo", x: 226, y: 51, radius: 30)
    }

    private func renderMultiStep(_ model: ReasoningStudioModel) {
        subtitle.text = "SHOW BOTH CHANGES — NOT JUST THE END"
        let firstText = "+\(model.firstChange)"
        let secondText = "\(model.subtractSecond ? "−" : "+")\(model.secondChange)"
        label("START \(model.startingValue)   \(firstText)   THEN \(secondText)",
              x: 0, y: 69, size: 18)
        let stage: String
        if model.observedFinal != nil {
            stage = "BOTH STEPS LOCKED — PULL PIP'S LEVER"
        } else if model.isStageOne {
            stage = "STEP ONE: ADD \(model.firstChange)"
        } else {
            stage = "STEP TWO: \(model.subtractSecond ? "TAKE" : "ADD") \(model.secondChange)"
        }
        label(stage, x: 0, y: 37, size: 14)
        label("YOUR NUMBER: \(model.workingValue)",
              x: 0, y: 4, size: 21)
        for tick in 0...20 {
            let x = CGFloat(tick - 10) * 21
            let mark = SKShapeNode(circleOfRadius: tick == model.workingValue ? 6 : 2.5)
            mark.position = CGPoint(x: x, y: -39)
            mark.fillColor = tick == model.workingValue
                ? UIColor(red: 1, green: 0.86, blue: 0.47, alpha: 1)
                : UIColor(red: 0.46, green: 0.78, blue: 0.85, alpha: 0.9)
            mark.strokeColor = .clear
            mark.name = MathMechanicID.reasoningStudio
            canvas.addChild(mark)
        }
        label("STEP 1: \(model.observedIntermediate.map(String.init) ?? "?")    STEP 2: \(model.observedFinal.map(String.init) ?? "?")",
              x: 0, y: -75, size: 14)
        button("−1", name: "reasonCounterMinus", x: -124, y: -122)
        button("CHECK", name: "reasonConfirm", x: 0, y: -122)
        button("+1", name: "reasonCounterPlus", x: 124, y: -122)
        button("RESET", name: "reasonReset", x: 224, y: 54, radius: 30)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 1, green: 0.91, blue: 0.56, alpha: 1)
        guard !reducedMotion else { return }
        canvas.run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1.0, duration: 0.17)
        ]), withKey: "reasoningSuccess")
    }
}


@MainActor final class NumberTrailMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let heading = ArtSystem.label("NUMBER TRAIL", size: 19)
    private let instruction = ArtSystem.label("", size: 15)
    private var didRender = false
    private var lastObservedFlash = false

    override init() {
        super.init()
        name = MathMechanicID.numberTrail
        zPosition = 750

        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.numberTrail
        addChild(tray)

        let plaque = ArtSystem.plaque(
            CGSize(width: 277, height: 47),
            fill: UIColor(red: 0.08, green: 0.17, blue: 0.29, alpha: 0.97),
            stroke: UIColor(red: 0.98, green: 0.80, blue: 0.43, alpha: 0.91),
            radius: 15
        )
        plaque.position.y = 128
        plaque.name = MathMechanicID.numberTrail
        addChild(plaque)
        heading.fontName = "AvenirNext-Heavy"
        heading.fontColor = .white
        heading.name = MathMechanicID.numberTrail
        plaque.addChild(heading)

        instruction.fontName = "AvenirNext-DemiBold"
        instruction.fontColor = UIColor(red: 0.97, green: 0.84, blue: 0.53, alpha: 1)
        instruction.position.y = 95
        instruction.name = MathMechanicID.numberTrail
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Programmatic mechanics only") }

    private func text(_ message: String, x: CGFloat, y: CGFloat, size: CGFloat = 16) {
        let label = ArtSystem.label(message, size: size)
        label.position = CGPoint(x: x, y: y)
        label.fontName = "AvenirNext-DemiBold"
        label.fontColor = .white
        label.name = MathMechanicID.numberTrail
        activity.addChild(label)
    }

    private func button(_ message: String, name: String, x: CGFloat, y: CGFloat = -122,
                        radius: CGFloat = 33) {
        let surface = ArtSystem.medallion(
            radius: radius,
            fill: UIColor(red: 0.14, green: 0.30, blue: 0.43, alpha: 1),
            stroke: UIColor(red: 0.95, green: 0.81, blue: 0.46, alpha: 0.96),
            glow: 0
        )
        surface.position = CGPoint(x: x, y: y)
        surface.name = name
        surface.zPosition = 60
        activity.addChild(surface)
        let label = ArtSystem.label(message, size: message.count > 3 ? 13 : 23)
        label.fontName = "AvenirNext-Heavy"
        label.fontColor = .white
        label.name = name
        surface.addChild(label)
        let tapTarget = SKShapeNode(circleOfRadius: radius + 3)
        tapTarget.position = CGPoint(x: x, y: y)
        tapTarget.fillColor = .clear
        tapTarget.strokeColor = .clear
        tapTarget.name = name
        tapTarget.zPosition = 75
        activity.addChild(tapTarget)
    }

    func render(_ model: NumberTrailModel) {
        let animateFlash = didRender && model.isEstimate
            && model.flashObserved && !lastObservedFlash
        didRender = true
        lastObservedFlash = model.flashObserved
        activity.removeAllChildren()

        if model.isEstimate {
            renderEstimate(model, animateFlash: animateFlash)
        } else {
            renderCountOn(model)
        }
    }

    private func renderEstimate(_ model: NumberTrailModel, animateFlash: Bool) {
        instruction.text = "ABOUT HOW MANY FIREFLIES?"
        let flashPanel = ArtSystem.panel(
            CGSize(width: 248, height: 164),
            fill: UIColor(red: 0.08, green: 0.21, blue: 0.28, alpha: 0.98),
            stroke: UIColor(red: 0.57, green: 0.83, blue: 0.91, alpha: 0.90),
            radius: 15, lineWidth: 2, shadowAlpha: 0.06
        )
        flashPanel.position = CGPoint(x: -131, y: 0)
        flashPanel.name = MathMechanicID.numberTrail
        activity.addChild(flashPanel)

        if !model.flashObserved {
            text("TAP FLASH TO LOOK", x: -131, y: 2, size: 15)
        } else if animateFlash {
            let sparkleLayer = SKNode()
            sparkleLayer.name = MathMechanicID.numberTrail
            activity.addChild(sparkleLayer)
            // Distinct six arrangements; positions never encode quantities
            // using labels or counts that remain visible after the flash.
            for i in 0..<model.collectionSize {
                let cell = (i * 7 + model.arrangementSeed * 5) % 12
                let firefly = SKShapeNode(circleOfRadius: 11)
                firefly.position = CGPoint(
                    x: -218 + CGFloat(cell % 4) * 58,
                    y: 52 - CGFloat(cell / 4) * 49
                )
                firefly.fillColor = UIColor(red: 1, green: 0.86, blue: 0.36, alpha: 1)
                firefly.strokeColor = UIColor(red: 0.97, green: 0.97, blue: 0.72, alpha: 1)
                firefly.lineWidth = 2
                firefly.glowWidth = 3
                firefly.name = MathMechanicID.numberTrail
                sparkleLayer.addChild(firefly)
            }
            // A brief stimulus disappears before children can slowly count
            // all dots. This presentation action never changes score state.
            sparkleLayer.run(.sequence([.wait(forDuration: 0.85), .hide()]))
        } else {
            text("FIREFLIES HIDDEN", x: -131, y: 2, size: 15)
        }
        text("YOUR ESTIMATE", x: 119, y: 57, size: 15)
        text("\(model.dialValue)", x: 119, y: 4, size: 45)
        if let locked = model.lockedEstimate {
            text("LOCKED: \(locked)", x: 119, y: -56, size: 15)
        } else {
            text("SET A GUESS", x: 119, y: -56, size: 13)
        }

        button("FLASH", name: "trailFlash", x: -157, radius: 36)
        button("−", name: "trailEstimateMinus", x: 17, radius: 33)
        button("+", name: "trailEstimatePlus", x: 108, radius: 33)
        button("SET", name: "trailEstimateLock", x: 207, radius: 33)
    }

    private func renderCountOn(_ model: NumberTrailModel) {
        instruction.text = "COUNT ON \(model.requiredJumps) ONE-STEP JUMPS"
        text("START: \(model.startNumber)", x: -137, y: 62, size: 17)
        text("JUMPS: \(model.jumps)", x: 118, y: 62, size: 17)

        let baseY: CGFloat = -10
        let baseX: CGFloat = -218
        let stepWidth: CGFloat = 43
        let segmentPath = CGMutablePath()
        segmentPath.move(to: CGPoint(x: baseX, y: baseY))
        segmentPath.addLine(to: CGPoint(x: baseX + stepWidth * 10, y: baseY))
        let baseline = SKShapeNode(path: segmentPath)
        baseline.strokeColor = UIColor(red: 0.84, green: 0.91, blue: 0.94, alpha: 1)
        baseline.lineWidth = 3
        baseline.name = MathMechanicID.numberTrail
        activity.addChild(baseline)

        for value in 0...10 {
            let x = baseX + CGFloat(value) * stepWidth
            let mark = SKShapeNode(circleOfRadius: 5)
            mark.fillColor = value <= model.markerNumber
                ? UIColor(red: 0.95, green: 0.75, blue: 0.38, alpha: 1)
                : UIColor(red: 0.56, green: 0.75, blue: 0.85, alpha: 1)
            mark.strokeColor = .white
            mark.lineWidth = 1
            mark.position = CGPoint(x: x, y: baseY)
            mark.name = MathMechanicID.numberTrail
            activity.addChild(mark)
            text("\(value)", x: x, y: -41, size: 13)
        }
        for step in 0..<model.jumps {
            let marker = SKShapeNode(circleOfRadius: 6)
            marker.fillColor = UIColor(red: 0.39, green: 0.84, blue: 0.64, alpha: 1)
            marker.strokeColor = .white
            marker.lineWidth = 1.5
            marker.position = CGPoint(
                x: baseX + CGFloat(model.startNumber + step + 1) * stepWidth,
                y: baseY + 20
            )
            marker.name = MathMechanicID.numberTrail
            activity.addChild(marker)
        }
        let glider = SKShapeNode(circleOfRadius: 13)
        glider.fillColor = UIColor(red: 0.25, green: 0.78, blue: 0.89, alpha: 1)
        glider.strokeColor = .white
        glider.lineWidth = 3
        glider.position = CGPoint(
            x: baseX + CGFloat(model.markerNumber) * stepWidth,
            y: baseY + 27
        )
        glider.name = MathMechanicID.numberTrail
        activity.addChild(glider)
        text("AT \(model.markerNumber)", x: 0, y: -82, size: 20)

        button("↶", name: "trailUndoJump", x: -102, radius: 36)
        button("+1", name: "trailAddJump", x: 102, radius: 36)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        heading.fontColor = UIColor(red: 1, green: 0.89, blue: 0.50, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.025, duration: 0.12),
            .scale(to: 1, duration: 0.17)
        ]), withKey: "trailSuccess")
    }
}


@MainActor final class DifferenceDockMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let title = ArtSystem.label("DIFFERENCE DOCK", size: 18)
    private let instruction = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.differenceDock
        zPosition = 750
        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 282))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.differenceDock
        addChild(tray)
        let plaque = ArtSystem.plaque(
            CGSize(width: 294, height: 47),
            fill: UIColor(red: 0.10, green: 0.19, blue: 0.28, alpha: 0.97),
            stroke: UIColor(red: 0.98, green: 0.79, blue: 0.43, alpha: 1),
            radius: 15
        )
        plaque.position.y = 127
        plaque.name = MathMechanicID.differenceDock
        addChild(plaque)
        title.fontName = "AvenirNext-Heavy"
        title.fontColor = .white
        title.name = MathMechanicID.differenceDock
        plaque.addChild(title)
        instruction.position.y = 93
        instruction.fontColor = UIColor(red: 1, green: 0.86, blue: 0.56, alpha: 1)
        instruction.name = MathMechanicID.differenceDock
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func label(_ text: String, x: CGFloat, y: CGFloat, size: CGFloat = 15) {
        let l = ArtSystem.label(text, size: size)
        l.position = CGPoint(x: x, y: y)
        l.fontName = "AvenirNext-DemiBold"
        l.fontColor = .white
        l.name = MathMechanicID.differenceDock
        activity.addChild(l)
    }

    private func button(_ text: String, name: String, x: CGFloat) {
        let medallion = ArtSystem.medallion(
            radius: 33,
            fill: UIColor(red: 0.10, green: 0.25, blue: 0.38, alpha: 1),
            stroke: UIColor(red: 0.99, green: 0.83, blue: 0.51, alpha: 1),
            glow: 0
        )
        medallion.position = CGPoint(x: x, y: -121)
        medallion.name = name
        activity.addChild(medallion)
        let words = ArtSystem.label(text, size: text.count > 4 ? 10 : 14)
        words.fontColor = .white
        words.fontName = "AvenirNext-Heavy"
        words.name = name
        medallion.addChild(words)
    }

    func render(_ model: DifferenceDockModel) {
        activity.removeAllChildren()
        instruction.text = model.isDifference
            ? "PAIR THE COUNTERS · COUNT THE EXTRA"
            : "BUILD THE WHOLE · TAKE AWAY A PART"

        // Source quantities remain visible throughout. The child creates one
        // real pair or one whole counter per tap, then counts the remainder.
        for index in 0..<model.larger {
            let x = -205 + CGFloat(index) * 30
            let chip = SKShapeNode(circleOfRadius: 11)
            chip.position = CGPoint(x: x, y: 36)
            chip.fillColor = index < model.constructed
                ? UIColor(red: 0.27, green: 0.74, blue: 0.77, alpha: 1)
                : UIColor(red: 0.96, green: 0.76, blue: 0.33, alpha: 1)
            chip.strokeColor = .white
            chip.lineWidth = 2
            chip.name = MathMechanicID.differenceDock
            activity.addChild(chip)
        }

        if model.isDifference {
            for index in 0..<model.smaller {
                let x = -205 + CGFloat(index) * 30
                let chip = SKShapeNode(circleOfRadius: 10)
                chip.position = CGPoint(x: x, y: -11)
                chip.fillColor = UIColor(red: 0.32, green: 0.68, blue: 0.95, alpha: 1)
                chip.strokeColor = .white
                chip.lineWidth = 2
                chip.name = MathMechanicID.differenceDock
                activity.addChild(chip)
                if index < model.constructed {
                    let segment = CGMutablePath()
                    segment.move(to: CGPoint(x: x, y: 2))
                    segment.addLine(to: CGPoint(x: x, y: 23))
                    let line = SKShapeNode(path: segment)
                    line.lineWidth = 2
                    line.strokeColor = UIColor(red: 0.99, green: 0.92, blue: 0.58, alpha: 1)
                    line.name = MathMechanicID.differenceDock
                    activity.addChild(line)
                }
            }
            label("\(model.constructed) / \(model.smaller) PAIRED", x: -58, y: -57)
        } else {
            for index in 0..<model.constructed {
                let x = -205 + CGFloat(index) * 30
                let chip = SKShapeNode(circleOfRadius: 10)
                chip.position = CGPoint(x: x, y: -10)
                chip.fillColor = index < model.response
                    ? UIColor(red: 0.87, green: 0.39, blue: 0.42, alpha: 1)
                    : UIColor(red: 0.25, green: 0.73, blue: 0.84, alpha: 1)
                chip.strokeColor = .white
                chip.lineWidth = 2
                chip.name = MathMechanicID.differenceDock
                activity.addChild(chip)
            }
            label("\(model.constructed) / \(model.larger) BUILT", x: -58, y: -57)
        }

        label(model.isDifference ? "EXTRA" : "TAKE AWAY", x: 178, y: 27, size: 13)
        label("\(model.response)", x: 178, y: -17, size: 33)
        button("BUILD+", name: "dockBuild", x: -183)
        button("UNDO", name: "dockUnbuild", x: -61)
        button("COUNT+", name: "dockAnswerPlus", x: 61)
        button("COUNT−", name: "dockAnswerMinus", x: 183)
    }

    func playSuccessReaction(reducedMotion: Bool) {
        title.fontColor = UIColor(red: 1, green: 0.90, blue: 0.54, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.03, duration: 0.12),
            .scale(to: 1, duration: 0.16)
        ]), withKey: "dockSuccess")
    }
}

@MainActor final class MapQuestMechanic: SKNode, MathCastleReactiveMechanic {
    private let activity = SKNode()
    private let title = ArtSystem.label("MAP QUEST", size: 20)
    private let instruction = ArtSystem.label("", size: 15)

    override init() {
        super.init()
        name = MathMechanicID.mapQuest
        zPosition = 750
        let tray = ArtSystem.supplyTray(CGSize(width: 530, height: 283))
        tray.position.y = -14
        tray.zPosition = -5
        tray.name = MathMechanicID.mapQuest
        addChild(tray)
        let header = ArtSystem.plaque(
            CGSize(width: 260, height: 47),
            fill: UIColor(red: 0.09, green: 0.17, blue: 0.29, alpha: 0.96),
            stroke: UIColor(red: 0.98, green: 0.79, blue: 0.43, alpha: 1),
            radius: 15
        )
        header.position.y = 127
        header.name = MathMechanicID.mapQuest
        addChild(header)
        title.fontColor = .white
        title.fontName = "AvenirNext-Heavy"
        title.name = MathMechanicID.mapQuest
        header.addChild(title)
        instruction.position.y = 96
        instruction.fontColor = UIColor(red: 1, green: 0.86, blue: 0.54, alpha: 1)
        instruction.name = MathMechanicID.mapQuest
        addChild(instruction)
        addChild(activity)
    }

    required init?(coder: NSCoder) { fatalError("Use programmatic mechanics") }

    private func control(_ mark: String, name: String, x: CGFloat,
                         y: CGFloat = -120, radius: CGFloat = 34) {
        let medallion = ArtSystem.medallion(
            radius: radius,
            fill: UIColor(red: 0.10, green: 0.25, blue: 0.38, alpha: 1),
            stroke: UIColor(red: 0.99, green: 0.80, blue: 0.43, alpha: 1),
            glow: 0
        )
        medallion.position = CGPoint(x: x, y: y)
        medallion.name = name
        activity.addChild(medallion)
        let icon = ArtSystem.label(mark, size: 24)
        icon.fontColor = .white
        icon.name = name
        medallion.addChild(icon)
    }

    func render(_ model: MapQuestModel) {
        activity.removeAllChildren()
        instruction.text = model.isPosition
            ? "PLACE PIP \(model.positionDescription) THE LANDMARK"
            : "MOVE PIP TO THE GOLDEN STAR"

        for cell in 0...8 {
            let point = CGPoint(x: CGFloat(cell % 3 - 1) * 154,
                                y: CGFloat(1 - cell / 3) * 53)
            let tile = ArtSystem.panel(
                CGSize(width: 105, height: 45),
                fill: UIColor(red: 0.10, green: 0.24, blue: 0.33, alpha: 0.98),
                stroke: UIColor(red: 0.61, green: 0.87, blue: 0.88, alpha: 0.77),
                radius: 10, lineWidth: 2, shadowAlpha: 0.04
            )
            tile.position = point
            tile.name = "mapCell\(cell)"
            activity.addChild(tile)

            if model.isPosition && cell == 4 {
                let names = ["TREE", "HOUSE", "POND"]
                let name = ArtSystem.label(names[model.landmarkStyle], size: 13)
                name.fontName = "AvenirNext-Heavy"
                name.fontColor = UIColor(red: 1, green: 0.81, blue: 0.45, alpha: 1)
                name.name = tile.name
                tile.addChild(name)
            } else if !model.isPosition && cell == model.destination {
                let star = ArtSystem.label("★", size: 29)
                star.fontColor = UIColor(red: 1, green: 0.84, blue: 0.39, alpha: 1)
                star.name = tile.name
                tile.addChild(star)
            }

            let pipHere = cell == model.currentCell
                && (!model.isPosition || model.selectedCell != nil)
            if pipHere {
                let pipMarker = SKShapeNode(circleOfRadius: 16)
                pipMarker.fillColor = UIColor(red: 0.25, green: 0.76, blue: 0.85, alpha: 1)
                pipMarker.strokeColor = .white
                pipMarker.lineWidth = 2
                pipMarker.name = tile.name
                tile.addChild(pipMarker)
                let letter = ArtSystem.label("P", size: 18)
                letter.fontName = "AvenirNext-Heavy"
                letter.fontColor = UIColor(red: 0.04, green: 0.19, blue: 0.29, alpha: 1)
                letter.name = tile.name
                pipMarker.addChild(letter)
            }
        }

        if !model.isPosition {
            control("←", name: "mapLeft", x: -174)
            control("↑", name: "mapUp", x: -58)
            control("↓", name: "mapDown", x: 58)
            control("→", name: "mapRight", x: 174)
            control("↶", name: "mapUndo", x: 230, y: 75, radius: 29)
        }
    }

    func playSuccessReaction(reducedMotion: Bool) {
        title.fontColor = UIColor(red: 1, green: 0.90, blue: 0.54, alpha: 1)
        guard !reducedMotion else { return }
        activity.run(.sequence([
            .scale(to: 1.025, duration: 0.13),
            .scale(to: 1, duration: 0.17)
        ]), withKey: "mapQuestSuccess")
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
        case MathMechanicID.patternLoom:
            return PatternLoomMechanic()
        case MathMechanicID.shapeForge:
            return ShapeForgeMechanic()
        case MathMechanicID.measurementWorkshop:
            return MeasurementWorkshopMechanic()
        case MathMechanicID.dataBoard:
            return DataBoardMechanic()
        case MathMechanicID.clockMarket:
            return ClockMarketMechanic()
        case MathMechanicID.groupingGarden:
            return GroupingGardenMechanic()
        case MathMechanicID.reasoningStudio:
            return ReasoningStudioMechanic()
        case MathMechanicID.numberTrail:
            return NumberTrailMechanic()
        case MathMechanicID.differenceDock:
            return DifferenceDockMechanic()
        case MathMechanicID.mapQuest:
            return MapQuestMechanic()
        default:
            return nil
        }
    }
}
