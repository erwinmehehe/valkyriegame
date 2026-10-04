import SpriteKit

@MainActor final class PipNode: CharacterNode {
    init() { super.init(character: "Pip", color: .systemTeal, height: 145) }
    required init?(coder: NSCoder) { fatalError("Use programmatic scenes") }
    func operate(reducedMotion: Bool) {
        self.reducedMotion = reducedMotion
        pose(.interact)
        run(.sequence([.wait(forDuration: reducedMotion ? 0 : 0.6), .run { [weak self] in self?.pose(.idle) }]), withKey: "operation")
    }
}
