import AppSpikeSDKRemoteConfig
import AppSpikeSDKCore
import SwiftUI

@main
struct SampleApp: App {
    @StateObject private var initState = AppSpikeInitState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(initState)
                .onAppear { initState.start() }
        }
    }
}

@MainActor
final class AppSpikeInitState: ObservableObject {
    @Published var status: String = "Not initialized"
    @Published var isInitialized = false

    private var hasStarted = false

    /// Reads the API key from the single documented constant. There is no
    /// runtime key-entry field: the key belongs in `ApiKey.swift` at build
    /// time, the way a real app ships it.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true

        guard appSpikeApiKey != apiKeyPlaceholder else {
            status = "No API key — replace \(apiKeyPlaceholder) in \(apiKeyLocation)"
            return
        }
        initialize(apiKey: appSpikeApiKey)
    }

    private func initialize(apiKey: String) {
        SampleDefaults.apply()

        AppSpike.shared.initialize(
            apiKey: apiKey,
            modules: [AppSpikeRemoteConfig.shared]
        ) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success:
                    self?.status = "Initialized"
                    self?.isInitialized = true
                case .error(let message):
                    self?.status = "Error: \(message)"
                }
            }
        }
    }
}
