import Foundation

public struct Scaffold: Equatable {
    public let support: SupportLevel
    public let cue: String
    public let demonstratesStep: Bool
    public init(support: SupportLevel, cue: String, demonstratesStep: Bool) {
        self.support = support; self.cue = cue; self.demonstratesStep = demonstratesStep
    }
}
public struct ScaffoldingEngine {
    public init() {}
    public func next(after support: SupportLevel) -> Scaffold {
        switch support {
        case .independent: return Scaffold(support: .lightHint, cue: "Touch each crystal once as you count.", demonstratesStep: false)
        case .lightHint: return Scaffold(support: .strongHint, cue: "Look at the crystals already in the cart. Count on from there.", demonstratesStep: false)
        case .strongHint, .demonstration: return Scaffold(support: .demonstration, cue: "Watch Pip move one crystal. Then you can try.", demonstratesStep: true)
        }
    }
}
