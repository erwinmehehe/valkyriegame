import SpriteKit

@MainActor final class StoryTreeScene: AdventureScene {
    override var environment: ArtSystem.Environment { .isles }
    override var worldTitle: String { "Story Tree · The Lost Starlight" }
    override var walkable: CGRect { CGRect(x: 105, y: 120, width: 750, height: 370) }
    // Follow the painted foreground stair and upper bridge to the castle.
    private let route: [CGPoint] = [CGPoint(x: 190, y: 170), CGPoint(x: 285, y: 235),
        CGPoint(x: 385, y: 275), CGPoint(x: 430, y: 340), CGPoint(x: 475, y: 420),
        CGPoint(x: 580, y: 450), CGPoint(x: 690, y: 450), CGPoint(x: 795, y: 450)]
    private var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var moved = false
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        pip.position = CGPoint(x: 250, y: 210)
    }
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
        _ = worldGear("✦", name: "pipWind", at: CGPoint(x: 315, y: 260), radius: 34)
        let glow = SKShapeNode(circleOfRadius: 45)
        glow.fillColor = .init(red: 1, green: 0.82, blue: 0.3, alpha: 0.13)
        glow.strokeColor = .init(red: 1, green: 0.85, blue: 0.45, alpha: 0.5); glow.glowWidth = 14
        glow.position = CGPoint(x: 350, y: 405); glow.zPosition = 20; glow.name = "storyLight"; addChild(glow)
        if let bloom = ArtSystem.sprite("StoryBloom", size: CGSize(width: 95, height: 100)) {
            bloom.position = CGPoint(x: 430, y: 330); bloom.name = "storyLight"; bloom.zPosition = 815; addChild(bloom)
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
    override func travel(to destination: CGPoint, then action: (() -> Void)? = nil) {
        let start = nearestWaypoint(to: valkyrie.position)
        let end = nearestWaypoint(to: destination)
        let indices = start <= end ? Array(start...end) : Array((end...start).reversed())
        follow(indices, forward: start <= end, completion: action)
    }
    private func follow(_ indices: [Int], forward: Bool, completion: (() -> Void)?) {
        guard let first = indices.first else { completion?(); return }
        super.travel(to: route[first]) { [weak self] in
            self?.follow(Array(indices.dropFirst()), forward: forward, completion: completion)
        }
        let behind = max(0, min(route.count-1, first + (forward ? -1 : 1)))
        let point = behind == first ? CGPoint(x: route[first].x + 35, y: route[first].y + 25) : route[behind]
        pip.walk(to: point) {}
    }
    private func nearestWaypoint(to point: CGPoint) -> Int {
        route.indices.min { hypot(route[$0].x-point.x,route[$0].y-point.y) < hypot(route[$1].x-point.x,route[$1].y-point.y) } ?? 0
    }
    func isOnPath(_ point: CGPoint) -> Bool {
        for (a,b) in zip(route,route.dropFirst()) {
            let dx = b.x-a.x, dy = b.y-a.y
            let t = max(0,min(1,((point.x-a.x)*dx+(point.y-a.y)*dy)/(dx*dx+dy*dy)))
            if hypot(point.x-(a.x+t*dx),point.y-(a.y+t*dy)) <= 38 { return true }
        }
        return false
    }
    override func walkIfValid(_ point: CGPoint) { if isOnPath(point) { travel(to: point) } }
    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        let depth = max(0,min(1,(valkyrie.position.y-170)/280))
        valkyrie.setScale(1-depth*0.42); pip.setScale(1-depth*0.42)
    }
    func handleTap(at point: CGPoint) {
        switch targetName(at: point) {
        case "castle":
            let destination = CGPoint(x: 795, y: 450)
            if isNear(destination) { state.travel(to: .mathCastle) }
            else { instruction.text = "Walk to the castle sign, then tap it to enter."; travel(to: destination) }
        case "pipWind":
            travel(to: CGPoint(x: 285, y: 235)) { [weak self] in
                guard let self else { return }
                self.pip.operate(reducedMotion: self.reducedMotion); self.state.finishExploration()
                self.instruction.text = "Pip's little gears are ready. Where shall we go?"
                self.state.audio.play("gear")
            }
        case "storyLight":
            travel(to: CGPoint(x: 385, y: 275)) { [weak self] in
                self?.valkyrie.pose(.interact)
                self?.instruction.text = "A little light. A big adventure. Pip is ready to help."
            }
        default: walkIfValid(point)
        }
    }
}
