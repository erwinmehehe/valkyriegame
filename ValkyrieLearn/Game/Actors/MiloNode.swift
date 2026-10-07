import SpriteKit

@MainActor final class MiloNode: CharacterNode {
    init() {
        super.init(character: "Milo", color: .systemGreen, height: 113)
        name = "milo"
        addPresenceAura(color: .systemGreen, width: 98, height: 28, glow: 4)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    func inspect(reducedMotion: Bool) {
        self.reducedMotion = reducedMotion
        pose(.interact)
        if !reducedMotion {
            childNode(withName: "companionPresence")?.run(
                .sequence([
                    .scale(to: 1.16, duration: 0.16),
                    .scale(to: 1.0, duration: 0.26)
                ]),
                withKey: "presencePulse"
            )
            bodyNode.run(
                .sequence([
                    .group([
                        .moveTo(y: 3, duration: 0.12),
                        .rotate(toAngle: -0.062, duration: 0.12)
                    ]),
                    .group([
                        .moveTo(y: 1, duration: 0.15),
                        .rotate(toAngle: 0.030, duration: 0.15)
                    ]),
                    .group([
                        .moveTo(y: 0, duration: 0.14),
                        .rotate(toAngle: 0, duration: 0.14)
                    ])
                ]),
                withKey: "miloInspect"
            )
        }
        run(
            .sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 0.65),
                .run { [weak self] in self?.pose(.idle) }
            ]),
            withKey: "operation"
        )
    }
}
