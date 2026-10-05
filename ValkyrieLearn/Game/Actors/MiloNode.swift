import SpriteKit

@MainActor final class MiloNode: CharacterNode {
    init() {
        super.init(character: "Milo", color: .systemGreen, height: 112)
    }

    required init?(coder: NSCoder) {
        fatalError("Use programmatic scenes")
    }

    func inspect(reducedMotion: Bool) {
        self.reducedMotion = reducedMotion
        pose(.interact)
        run(
            .sequence([
                .wait(forDuration: reducedMotion ? 0.2 : 0.65),
                .run { [weak self] in self?.pose(.idle) }
            ]),
            withKey: "operation"
        )
    }
}
