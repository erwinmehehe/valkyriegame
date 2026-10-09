import SwiftUI
import SpriteKit

/// SpriteKit owns the aspect-fit behavior of legacy 16:9 scenes and the
/// adaptive sizing of Palace/Science scenes. An outer 16:9 SwiftUI wrapper
/// must never shrink the real landscape touch viewport.
enum GameViewportLayout {
    static func size(for container: CGSize) -> CGSize {
        CGSize(width: max(0, container.width), height: max(0, container.height))
    }
}

@MainActor struct GameContainerView: View {
    @ObservedObject var state: AppState
    @State private var scene: AdventureScene?
    @State private var settings = false
    @State private var worldTransitionOpacity = 0.0
    @State private var worldTransitionGeneration = 0
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width >= geometry.size.height
            let viewport = GameViewportLayout.size(for: geometry.size)

            ZStack(alignment: .topTrailing) {
                Color(red: 0.08, green: 0.09, blue: 0.16)

                if let scene {
                    // Let SpriteKit use the actual landscape viewport. Adaptive scenes
                    // grow to 4:3 on iPad instead of being squeezed into a 16:9 strip.
                    // Legacy 16:9 scenes retain their own aspectFit canvas.
                    SpriteView(scene: scene, isPaused: settings || !isLandscape || scenePhase != .active)
                        .frame(width: viewport.width, height: viewport.height)
                        .allowsHitTesting(isLandscape && !settings && scenePhase == .active)
                        .accessibilityHidden(!isLandscape)
                }

                if state.world == .storyTree && isLandscape {
                    Button { settings = true } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                    }
                    .accessibilityLabel("Adventure settings")
                    .accessibilityHint("Opens sound, motion, saving, and learning progress.")
                    .foregroundStyle(.white)
                    .background(.black.opacity(0.35), in: Circle())
                    .padding(16)
                }

                if state.saveError != nil && isLandscape {
                    Text("Progress couldn't be saved. Ask a grown-up to open Settings.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial, in: Capsule())
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                        .allowsHitTesting(false)
                }

                if isLandscape {
                    Color(red: 0.025, green: 0.035, blue: 0.075)
                        .opacity(worldTransitionOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(worldTransitionOpacity > 0.01)
                        .accessibilityHidden(true)
                }

                if !isLandscape {
                    VStack(spacing: 14) {
                        Image(systemName: "ipad.landscape")
                            .font(.system(size: 50, weight: .semibold))
                        Text("Turn iPad sideways")
                            .font(.title.bold())
                        Text("Valkyrie's adventure is designed for landscape play.")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
                    .accessibilityElement(children: .combine)
                }
            }
            .onChange(of: isLandscape) { _, landscape in
                if !landscape { scene?.cancelPendingTap() }
            }
        }
        .ignoresSafeArea()
        .onAppear { rebuild() }
        .onChange(of: state.world) { _, _ in transitionToCurrentWorld() }
        .onChange(of: state.reducedMotion) { _, value in scene?.reducedMotion = value || systemReducedMotion }
        .onChange(of: systemReducedMotion) { _, value in scene?.reducedMotion = value || state.reducedMotion }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { scene?.cancelPendingTap() }
        }
        .onChange(of: settings) { _, presented in
            if presented { scene?.cancelPendingTap() }
        }
        .sheet(isPresented: $settings) { AdventureSettingsView(state: state) }
    }

    private func transitionToCurrentWorld() {
        scene?.cancelPendingTap()
        worldTransitionGeneration += 1
        let generation = worldTransitionGeneration
        let reduceMotion = state.reducedMotion || systemReducedMotion

        guard !reduceMotion else {
            worldTransitionOpacity = 0
            rebuild()
            return
        }

        withAnimation(.easeIn(duration: 0.14)) {
            worldTransitionOpacity = 0.96
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard generation == worldTransitionGeneration else { return }

            rebuild()

            withAnimation(.easeOut(duration: 0.24)) {
                worldTransitionOpacity = 0
            }
        }
    }

    private func rebuild() {
        scene?.willLeave()
        switch state.world {
        case .storyTree:
            scene = StoryTreeScene(state: state)
        case .mathCastle:
            scene = MathCastleScene(state: state)
        case .wordGarden, .sunmillCrossing, .storyHollow:
            scene = WordGardenScene(state: state)
        case .scienceLab:
            scene = ScienceLabScene(state: state)
        case .scienceWeatherTower:
            scene = WeatherTowerScene(state: state)
        case .scienceCreatureGrove:
            scene = CreatureGroveScene(state: state)
        case .puzzlePalace, .memoryBridge, .stopGoOrbs, .sortingPedestal, .resortVault, .mirrorHall, .pathTiles, .commandGears, .bugLantern, .bugLanternRepair:
            scene = PuzzlePalaceScene(state: state)
        }
        scene?.reducedMotion = state.reducedMotion || systemReducedMotion
    }
}
