import SpriteKit

@MainActor final class TikoNode: CharacterNode {
    init() {
        super.init(character: "Tiko", color: .systemPurple, height: 130)
        name = "tiko"
        addPresenceAura(color: .systemPurple, width: 100, height: 28, glow: 5)
    }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }

    func operateRune(at point: CGPoint, reducedMotion: Bool, completion: @escaping () -> Void) {
        self.reducedMotion = reducedMotion
        face(toward: point)
        pose(.interact)
        if !reducedMotion {
            childNode(withName: "companionPresence")?.run(
                .sequence([
                    .scale(to: 1.18, duration: 0.12),
                    .scale(to: 1.0, duration: 0.22)
                ]),
                withKey: "presencePulse"
            )
            bodyNode.run(
                .sequence([
                    .group([
                        .moveTo(y: 2, duration: 0.12),
                        .rotate(toAngle: -0.060, duration: 0.12)
                    ]),
                    .group([
                        .moveTo(y: 1, duration: 0.15),
                        .rotate(toAngle: 0.042, duration: 0.15)
                    ]),
                    .group([
                        .moveTo(y: 0, duration: 0.14),
                        .rotate(toAngle: 0, duration: 0.14)
                    ])
                ]),
                withKey: "tikoRuneFocus"
            )
        }
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

