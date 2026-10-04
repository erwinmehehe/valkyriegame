import SpriteKit

@MainActor final class StoryTreeScene: AdventureScene {
    override var environment: ArtSystem.Environment { .isles }
    override var worldTitle: String { "Story Tree · The Lost Starlight" }
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
        let sign = hotspot("Math Castle →", name: "castle", at: CGPoint(x: 795, y: 445), size: CGSize(width: 210, height: 56))
        let post = ArtSystem.box(CGSize(width: 15, height: 95), color: .init(red: 0.39, green: 0.24, blue: 0.12, alpha: 1), radius: 3)
        post.position.y = -64; post.zPosition = -1; sign.addChild(post)
        _ = worldGear("✦", name: "pipWind", at: CGPoint(x: 540, y: 235), radius: 34)
        let glow = SKShapeNode(circleOfRadius: 45)
        glow.fillColor = .init(red: 1, green: 0.82, blue: 0.3, alpha: 0.13)
        glow.strokeColor = .init(red: 1, green: 0.85, blue: 0.45, alpha: 0.5); glow.glowWidth = 14
        glow.position = CGPoint(x: 350, y: 405); glow.zPosition = 20; glow.name = "storyLight"; addChild(glow)
        if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 95, height: 100)) {
            bloom.position = CGPoint(x: 350, y: 245); bloom.name = "storyLight"; bloom.zPosition = 815; addChild(bloom)
        }
        pip.name = "pipWind"
        instruction.text = "The Story Tree is waiting for its starlight. Let's find Pip's castle."
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        defer { activeTouch = nil; moved = false }
        let point = touch.location(in: self)
        guard !moved, hypot(point.x - touchStart.x, point.y - touchStart.y) <= 12 else { return }
        handleTap(at: point)
    }
    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "castle":
            let destination = CGPoint(x: 795, y: 220)
            if isNear(destination) { state.travel(to: .mathCastle) }
            else { instruction.text = "Walk to the castle sign, then tap it to enter."; travel(to: destination) }
        case "pipWind":
            travel(to: CGPoint(x: 535, y: 210)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion); self.state.finishExploration()
                self.instruction.text = "Pip's little gears are ready. Where shall we go?"
                self.state.audio.play("gear")
            }
        case "storyLight":
            travel(to: CGPoint(x: 350, y: 195)) { [weak self] in
                self?.valkyrie.pose(.interact)
                self?.instruction.text = "A little light. A big adventure. Pip is ready to help."
            }
        default: walkIfValid(point)
        }
    }
}
