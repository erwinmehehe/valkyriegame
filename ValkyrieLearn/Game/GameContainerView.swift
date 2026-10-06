import SwiftUI
import SpriteKit

@MainActor struct GameContainerView: View {
    @ObservedObject var state: AppState
    @State private var scene: AdventureScene?
    @State private var settings = false
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width >= geometry.size.height

            ZStack(alignment: .topTrailing) {
                Color(red: 0.08, green: 0.09, blue: 0.16)

                if let scene {
                    SpriteView(scene: scene, isPaused: settings)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(isLandscape && !settings)
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
        case .puzzlePalace, .memoryBridge, .stopGoOrbs, .sortingPedestal, .resortVault, .mirrorHall, .pathTiles, .commandGears:
            scene = PuzzlePalaceScene(state: state)
        }
        scene?.reducedMotion = state.reducedMotion || systemReducedMotion
    }
}
