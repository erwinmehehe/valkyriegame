import SpriteKit

@MainActor final class StoryTreeScene: AdventureScene {
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false
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
        let trunk = ArtSystem.box(CGSize(width: 145, height: 320), color: .brown)
        trunk.position = CGPoint(x: 430, y: 420); trunk.zPosition = 30; addChild(trunk)
        let canopy = SKShapeNode(ellipseOf: CGSize(width: 470, height: 225))
        canopy.fillColor = .systemGreen.withAlphaComponent(0.7); canopy.strokeColor = .clear
        canopy.position = CGPoint(x: 430, y: 575); canopy.zPosition = 35; addChild(canopy)
        _ = hotspot("Math Castle →", name: "castle", at: CGPoint(x: 1050, y: 320), size: CGSize(width: 230, height: 100))
        _ = hotspot("Wind Pip", name: "pipWind", at: CGPoint(x: 600, y: 285))
        instruction.text = "Story Tree · Tap a path to walk. Visit Pip or the castle."
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
        default: walkIfValid(point)
        }
    }
}
