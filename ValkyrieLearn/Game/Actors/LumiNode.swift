import SpriteKit

@MainActor final class LumiNode: CharacterNode {
    init() {
        super.init(character: "Lumi", color: .systemYellow, height: 128)
        name = "lumi"
        addPresenceAura(color: .systemYellow, width: 96, height: 26, glow: 5)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }

    func reach(to point: CGPoint, reducedMotion: Bool, completion: @escaping () -> Void) {
        self.reducedMotion = reducedMotion
        face(toward: point)
        pose(.interact)
        let dx = max(-80, min(80, point.x - position.x))
        if !reducedMotion {
            childNode(withName: "companionPresence")?.run(
                .sequence([
                    .scale(to: 1.22, duration: 0.16),
                    .scale(to: 1.0, duration: 0.24)
                ]),
                withKey: "presencePulse"
            )
        }
        guard !reducedMotion else { completion(); return }
        run(.sequence([
            .moveBy(x: dx * 0.35, y: 18, duration: 0.22),
            .moveBy(x: -dx * 0.35, y: -18, duration: 0.22),
            .run(completion)
        ]), withKey: "lumiReach")
    }
}
