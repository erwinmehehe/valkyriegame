import SwiftUI

@MainActor struct AdventureSettingsView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Gentle sounds", isOn: $state.soundEnabled)
                Toggle("Reduced motion", isOn: $state.reducedMotion)
                Text("This engineering build uses temporary characters and world shapes. Workshop examples are unscored.")
                if let error = state.saveError {
                    Text(error).foregroundStyle(.red)
                    Button("Retry saving") { state.retrySave() }
                }
            }
            .navigationTitle("Adventure settings")
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
