import AppSpikeSDKRemoteConfig
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var initState: AppSpikeInitState
    @StateObject private var viewModel = RemoteConfigViewModel()

    @State private var stringKey = ""
    @State private var booleanKey = ""
    @State private var longKey = ""
    @State private var doubleKey = ""
    // Pre-filled with a non-default pair, so Apply is a visible change from
    // the SDK's 43200s / 60s defaults.
    @State private var fetchIntervalText = "300"
    @State private var fetchTimeoutText = "15"
    @State private var signalKey = "tier"
    @State private var signalValue = "silver"

    // The property wrapper reads through the same remote → default → static
    // precedence as the getters; "welcome_message" resolves from setDefaults
    // until a fetched template is activated.
    @RemoteConfigProperty(key: "welcome_message", fallback: "Hello from the fallback")
    private var welcomeMessage: String

    var body: some View {
        NavigationView {
            // Form is a List under the hood: the whole screen scrolls, and the
            // focused text field is kept visible above the keyboard by SwiftUI.
            Form {
                Section("SDK") {
                    Text(initState.status)
                        .font(.caption)
                        .foregroundColor(
                            initState.isInitialized ? .green : .secondary
                        )
                    labeledValue("@RemoteConfigProperty", welcomeMessage)
                }

                if initState.isInitialized {
                    Section("Remote Config") {
                        Button("Fetch") { viewModel.fetch() }
                            .disabled(viewModel.isFetching)

                        Button("Fetch & Activate") {
                            viewModel.fetchAndActivate()
                        }
                        .disabled(viewModel.isFetching)

                        Button("Bypass Cache & Activate") {
                            viewModel.bypassCacheAndActivate()
                        }
                        .disabled(viewModel.isFetching)

                        if !viewModel.fetchStatus.isEmpty {
                            Text(viewModel.fetchStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section {
                        NavigationLink("All Key/Values") {
                            AllValuesView(viewModel: viewModel)
                        }
                        NavigationLink("Value Inspector") {
                            InspectorView(viewModel: viewModel)
                        }
                        NavigationLink("Info & Settings") {
                            InfoSettingsView(
                                viewModel: viewModel,
                                fetchIntervalText: $fetchIntervalText,
                                fetchTimeoutText: $fetchTimeoutText
                            )
                        }
                    }

                    Section("Custom Signals") {
                        // Free-form entry: any key, any string value.
                        TextField("Signal key", text: $signalKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Signal value", text: $signalValue)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Apply Signal") {
                            viewModel.applyCustomSignal(
                                key: signalKey,
                                value: signalValue
                            )
                        }
                        .disabled(viewModel.isFetching)
                        Button("Remove Signal") {
                            viewModel.removeCustomSignal(key: signalKey)
                        }
                        .disabled(viewModel.isFetching)
                        // Convenience preset, in addition to the free-form
                        // entry above.
                        Button("Preset: gold tier") {
                            viewModel.setGoldPreset()
                        }
                        if !viewModel.signalsStatus.isEmpty {
                            Text(viewModel.signalsStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section("Typed Getters") {
                        valueRow("getString", key: $stringKey,
                                 result: viewModel.getString)
                        valueRow("getBoolean", key: $booleanKey,
                                 result: viewModel.getBoolean)
                        valueRow("getLong", key: $longKey,
                                 result: viewModel.getLong)
                        valueRow("getDouble", key: $doubleKey,
                                 result: viewModel.getDouble)
                    }

                    Section {
                        Button("Reset Remote Config State", role: .destructive) {
                            viewModel.reset()
                        }
                    }
                }
            }
            .navigationTitle("AppSpike Sample")
        }
    }

    private func valueRow(
        _ label: String,
        key: Binding<String>,
        result: (String) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            HStack {
                TextField("Key", text: key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !key.wrappedValue.isEmpty {
                    Text(result(key.wrappedValue))
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

private func labeledValue(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 2) {
        Text(label).font(.caption).foregroundColor(.secondary)
        Text(value).font(.system(.caption, design: .monospaced))
    }
}

struct AllValuesView: View {
    @ObservedObject var viewModel: RemoteConfigViewModel
    @State private var keyPrefix = ""

    var body: some View {
        List {
            Section("Keys") {
                TextField("Filter by key prefix", text: $keyPrefix)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                ForEach(viewModel.keySummary(prefix: keyPrefix), id: \.0) { row in
                    labeledValue(row.0, row.1)
                }
            }

            Section("Values") {
                if viewModel.allEntries.isEmpty {
                    Text("No values yet — set defaults or fetch and activate first.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                ForEach(viewModel.allEntries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.key)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Text(entry.source)
                                .font(.caption)
                                .foregroundColor(
                                    entry.source
                                        == RemoteConfigViewModel.remoteSourceLabel
                                        ? .blue : .secondary
                                )
                        }
                        Text(entry.value)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("All Key/Values")
        .onAppear { viewModel.refreshAllEntries() }
        .refreshable { viewModel.refreshAllEntries() }
    }
}

struct InspectorView: View {
    @ObservedObject var viewModel: RemoteConfigViewModel
    @State private var key = "paywall_config"

    var body: some View {
        List {
            Section("Key") {
                TextField("Key", text: $key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            Section("Every representation") {
                ForEach(viewModel.inspect(key), id: \.0) { row in
                    labeledValue(row.0, row.1)
                }
            }
        }
        .navigationTitle("Value Inspector")
    }
}

struct InfoSettingsView: View {
    @ObservedObject var viewModel: RemoteConfigViewModel
    @Binding var fetchIntervalText: String
    @Binding var fetchTimeoutText: String

    var body: some View {
        List {
            Section("Info") {
                ForEach(viewModel.infoRows(), id: \.0) { row in
                    labeledValue(row.0, row.1)
                }
            }
            Section("Config Settings") {
                labeledValue("current", viewModel.settingsSummary)
                TextField("minimumFetchInterval (s)", text: $fetchIntervalText)
                    .keyboardType(.numberPad)
                TextField("fetchTimeout (s)", text: $fetchTimeoutText)
                    .keyboardType(.numberPad)
                Button("Apply Settings") {
                    viewModel.applySettings(
                        minimumFetchInterval:
                            TimeInterval(fetchIntervalText)
                            ?? RemoteConfigViewModel
                                .defaultMinimumFetchInterval,
                        fetchTimeout: TimeInterval(fetchTimeoutText)
                            ?? RemoteConfigViewModel.defaultFetchTimeout
                    )
                }
                Button("Restore Defaults") {
                    viewModel.restoreDefaultSettings()
                    fetchIntervalText = String(
                        Int(RemoteConfigViewModel.defaultMinimumFetchInterval)
                    )
                    fetchTimeoutText = String(
                        Int(RemoteConfigViewModel.defaultFetchTimeout)
                    )
                }
                if !viewModel.settingsStatus.isEmpty {
                    Text(viewModel.settingsStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Info & Settings")
    }
}
