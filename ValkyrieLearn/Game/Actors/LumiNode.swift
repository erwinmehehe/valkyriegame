import SpriteKit

@MainActor final class LumiNode: CharacterNode {
    init() { super.init(character: "Lumi", color: .systemYellow, height: 120) }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }

    func reach(to point: CGPoint, reducedMotion: Bool, completion: @escaping () -> Void) {
        self.reducedMotion = reducedMotion
        face(toward: point)
        pose(.interact)
        let dx = max(-80, min(80, point.x - position.x))
        guard !reducedMotion else { completion(); return }
        run(.sequence([
            .moveBy(x: dx * 0.35, y: 18, duration: 0.22),
            .moveBy(x: -dx * 0.35, y: -18, duration: 0.22),
            .run(completion)
        ]), withKey: "lumiReach")
    }
}


@MainActor final class TikoNode: CharacterNode {
    init() { super.init(character: "Tiko", color: .systemPurple, height: 118) }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }

    func operateRune(at point: CGPoint, reducedMotion: Bool, completion: @escaping () -> Void) {
        self.reducedMotion = reducedMotion
        face(toward: point)
        pose(.interact)
        guard !reducedMotion else {
            completion()
            return
        }
        run(
            .sequence([
                .moveBy(x: 0, y: 14, duration: 0.14),
                .moveBy(x: 0, y: -14, duration: 0.16),
                .run(completion)
            ]),
            withKey: "tikoRuneHop"
        )
    }
}
