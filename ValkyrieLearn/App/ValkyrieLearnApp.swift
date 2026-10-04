import SwiftUI
import SwiftData

@main @MainActor struct ValkyrieLearnApp: App {
    @State private var bootstrap: Result<ModelContainer, Error> = Result { try LearningStore.container() }
    var body: some Scene {
        WindowGroup {
            switch bootstrap {
            case .success(let container):
                NativeRootView(context: container.mainContext).modelContainer(container)
            case .failure:
                ContentUnavailableView {
                    Label("Your adventure couldn't open", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your save has not been reset. Close and reopen the app, or ask a grown-up for help.")
                } actions: {
                    Button("Try again") { bootstrap = Result { try LearningStore.container() } }
                }
            }
        }
    }
}

@MainActor private struct NativeRootView: View {
    let context: ModelContext
    @State private var state: AppState?
    @State private var failed = false
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        Group {
            if let state { GameContainerView(state: state) }
            else if failed {
                ContentUnavailableView("Your save needs attention", systemImage: "externaldrive.badge.exclamationmark",
                    description: Text("The saved data could not be read. No progress has been erased."))
            } else { ProgressView("Opening Story Tree…") }
        }
        .task {
            guard state == nil, !failed else { return }
            do { state = try AppState(context: context) } catch { failed = true }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { state?.persist(); state?.audio.stop() }
        }
    }
}
