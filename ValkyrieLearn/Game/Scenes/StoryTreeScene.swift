import SpriteKit

@MainActor final class StoryTreeScene: AdventureScene {
    override var sourceBackdrop: ArtSystem.Backdrop? {
        ArtSystem.Backdrop(resource: "V331_StoryTree", ext: "jpg")
    }

    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false
    private var moonLanternNode: SKNode?
    private let moonLanternSlots = [
        CGPoint(x: 315, y: 555),
        CGPoint(x: 430, y: 625),
        CGPoint(x: 545, y: 555)
    ]
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard activeTouch == nil, let touch = touches.first else { return }
        activeTouch = touch; touchStart = touch.location(in: self); moved = false
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        if hypot(point.x - touchStart.x, point.y - touchStart.y) > 12 { moved = true }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) { activeTouch = nil; moved = false }
    }
    override func willLeave() { activeTouch = nil; moved = false; super.willLeave() }
    override func buildWorld() {
        super.buildWorld()

        // Keep the old procedural tree only as a fallback if the v3.31 reference
        // asset is unavailable in a development build.
        if !usingSourceArt {
            let trunk = ArtSystem.box(CGSize(width: 145, height: 320), color: .brown)
            trunk.position = CGPoint(x: 430, y: 420)
            trunk.zPosition = 30
            addChild(trunk)

            let canopy = SKShapeNode(ellipseOf: CGSize(width: 470, height: 225))
            canopy.fillColor = .systemGreen.withAlphaComponent(0.7)
            canopy.strokeColor = .clear
            canopy.position = CGPoint(x: 430, y: 575)
            canopy.zPosition = 35
            addChild(canopy)
        }

        _ = hotspot("Math Castle →", name: "castle", at: CGPoint(x: 1050, y: 320), size: CGSize(width: 230, height: 100))
        _ = hotspot("Wind Pip", name: "pipWind", at: CGPoint(x: 600, y: 285))
        renderMoonLantern()
        if state.hasStoryReward(.moonLantern) {
            instruction.text = "Story Tree grew a Moon Lantern! Tap it to choose a different branch."
        } else {
            instruction.text = "Story Tree · Tap a path to walk. Visit Pip or the castle."
        }
    }
    private func renderMoonLantern() {
        moonLanternNode?.removeFromParent()
        moonLanternNode = nil

        guard state.hasStoryReward(.moonLantern), !moonLanternSlots.isEmpty else { return }

        let placement = state.storyRewardPlacement(.moonLantern) % moonLanternSlots.count
        let lantern = SKNode()
        lantern.name = "moonLantern"
        lantern.position = moonLanternSlots[placement]
        lantern.zPosition = 120

        let glow = SKShapeNode(circleOfRadius: 48)
        glow.fillColor = .systemYellow.withAlphaComponent(0.20)
        glow.strokeColor = .clear
        glow.name = "moonLantern"
        lantern.addChild(glow)

        let hanger = SKShapeNode(rectOf: CGSize(width: 5, height: 30), cornerRadius: 2)
        hanger.fillColor = .systemOrange
        hanger.strokeColor = .clear
        hanger.position = CGPoint(x: 0, y: 36)
        hanger.name = "moonLantern"
        lantern.addChild(hanger)

        let body = SKShapeNode(
            rectOf: CGSize(width: 50, height: 62),
            cornerRadius: 14
        )
        body.fillColor = .systemYellow
        body.strokeColor = .white
        body.lineWidth = 3
        body.name = "moonLantern"
        lantern.addChild(body)

        let moon = ArtSystem.label("☾", size: 31)
        moon.fontColor = .init(red: 0.22, green: 0.24, blue: 0.40, alpha: 1)
        moon.name = "moonLantern"
        lantern.addChild(moon)

        if !reducedMotion {
            glow.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.45, duration: 1.1),
                .fadeAlpha(to: 1.0, duration: 1.1)
            ])))
        }

        addChild(lantern)
        moonLanternNode = lantern
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        defer { activeTouch = nil; moved = false }
        let point = touch.location(in: self)
        guard !moved, hypot(point.x - touchStart.x, point.y - touchStart.y) <= 12 else { return }
        switch targetName(at: point) {
        case "castle":
            let destination = CGPoint(x: 1030, y: 220)
            if isNear(destination) { state.travel(to: .mathCastle) }
            else { instruction.text = "Walk to the castle sign, then tap it to enter."; travel(to: destination) }
        case "pipWind":
            travel(to: CGPoint(x: 565, y: 220)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion); self.state.finishExploration()
                self.instruction.text = "Pip's little gears are ready. Where shall we go?"
                self.state.audio.play("gear")
            }
        case "moonLantern":
            guard state.hasStoryReward(.moonLantern) else { return }
            _ = state.cycleStoryRewardPlacement(.moonLantern, slotCount: moonLanternSlots.count)
            renderMoonLantern()
            state.audio.play("success")
            instruction.text = "The Moon Lantern found a new branch. Tap it again whenever you want to move it."
        default: walkIfValid(point)
        }
    }
}
