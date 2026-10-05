import SpriteKit

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

