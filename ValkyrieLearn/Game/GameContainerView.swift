import SwiftUI
import SpriteKit

@MainActor struct GameContainerView: View {
    @ObservedObject var state: AppState
    @State private var scene: AdventureScene?
    @State private var settings = false
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                Color(red: 0.08, green: 0.09, blue: 0.16)
                if let scene {
                    SpriteView(scene: scene, isPaused: settings)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                if state.world == .storyTree {
                    Button { settings = true } label: {
                        Image(systemName: "gearshape.fill").font(.title2).padding(14)
                    }
                    .accessibilityLabel("Adventure settings")
                    .foregroundStyle(.white).background(.black.opacity(0.35), in: Circle()).padding()
                }
                if state.saveError != nil {
                    Text("Ask a grown-up to check saving in Settings.")
                        .padding().background(.ultraThinMaterial).frame(maxHeight: .infinity, alignment: .bottom)
                }
                if geometry.size.height > geometry.size.width {
                    Text("Turn iPad sideways to explore.").font(.title).padding().background(.regularMaterial)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { rebuild() }
        .onChange(of: state.world) { _, _ in rebuild() }
        .onChange(of: state.reducedMotion) { _, value in scene?.reducedMotion = value || systemReducedMotion }
        .onChange(of: systemReducedMotion) { _, value in scene?.reducedMotion = value || state.reducedMotion }
        .sheet(isPresented: $settings) { AdventureSettingsView(state: state) }
    }
    private func rebuild() {
        scene?.willLeave()
        switch state.world {
        case .storyTree:
            scene = StoryTreeScene(state: state)
        case .wordGarden:
            scene = WordGardenScene(state: state)
        case .mathCastle:
            scene = MathCastleScene(state: state)
        }
        scene?.reducedMotion = state.reducedMotion || systemReducedMotion
    }
}
