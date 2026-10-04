import SpriteKit

@MainActor final class PipNode: CharacterNode {
    init() { super.init(character: "Pip", color: .systemTeal, height: 145) }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }

    func operate(reducedMotion: Bool) {
        self.reducedMotion = reducedMotion
        pose(.interact)

        if !reducedMotion {
            bodyNode.run(.sequence([
                .moveBy(x: 0, y: 8, duration: 0.12),
                .moveBy(x: 0, y: -8, duration: 0.14),
                .moveBy(x: 0, y: 5, duration: 0.10),
                .moveBy(x: 0, y: -5, duration: 0.12)
            ]), withKey: "helperHop")
        }

        run(.sequence([
            .wait(forDuration: reducedMotion ? 0.25 : 0.62),
            .run { [weak self] in self?.pose(.idle) }
        ]), withKey: "operation")
    }

    /// Mirrors the reference companion behavior: Pip visibly leaves the child's
    /// side to help the machinery after a successful solve.
    func helpRoute(to destination: CGPoint, reducedMotion: Bool) {
        self.reducedMotion = reducedMotion
        removeAction(forKey: "travel")

        guard !reducedMotion else {
            face(toward: destination)
            operate(reducedMotion: true)
            return
        }

        face(toward: destination)
        pose(.walk)
        let action = SKAction.move(to: destination, duration: 0.72)
        action.timingMode = .easeInEaseOut
        run(.sequence([
            action,
            .run { [weak self] in self?.operate(reducedMotion: false) }
        ]), withKey: "travel")
    }
}
