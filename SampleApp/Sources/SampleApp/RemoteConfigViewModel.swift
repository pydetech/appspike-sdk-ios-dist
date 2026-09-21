import AppSpikeSDKCore
import AppSpikeSDKRemoteConfig
import Foundation

struct ConfigEntry: Identifiable {
    let key: String
    let value: String
    let source: String

    var id: String { key }
}

/// Decoded via the `decodedValue` subscript — pair it with a JSON default or a
/// JSON parameter published from the AppSpike console.
struct PaywallConfig: Decodable {
    let headline: String
    let maxItems: Int
}

@MainActor
final class RemoteConfigViewModel: ObservableObject {
    @Published var fetchStatus = ""
    @Published var isFetching = false
    @Published var allEntries: [ConfigEntry] = []
    @Published var signalsStatus = ""
    @Published var settingsStatus = ""

    // MARK: - Fetch lifecycle

    func fetch() {
        isFetching = true
        fetchStatus = "Fetching..."
        Task {
            do {
                try await AppSpikeRemoteConfig.shared.fetch()
                fetchStatus = "Fetch succeeded"
            } catch {
                fetchStatus = "Fetch failed: \(error.localizedDescription)"
            }
            isFetching = false
        }
    }

    func fetchAndActivate() {
        isFetching = true
        fetchStatus = "Fetching & activating..."
        Task {
            do {
                let status = try await AppSpikeRemoteConfig.shared
                    .fetchAndActivate()
                switch status {
                case .successFetchedFromRemote:
                    fetchStatus = "Fetched from remote"
                case .successUsingPreFetchedData:
                    fetchStatus = "Using pre-fetched data"
                case .error:
                    fetchStatus = "Fetch error"
                }
            } catch {
                fetchStatus = "Failed: \(error.localizedDescription)"
            }
            isFetching = false
            refreshAllEntries()
        }
    }

    func bypassCacheAndActivate() {
        isFetching = true
        fetchStatus = "Fetching (cache bypassed)..."
        Task {
            do {
                let changed = try await performBypassCacheFetchAndActivate()
                fetchStatus = changed
                    ? "Cache bypassed — new config activated"
                    : "Cache bypassed — config unchanged"
            } catch {
                fetchStatus = "Failed: \(error.localizedDescription)"
            }
            isFetching = false
            refreshAllEntries()
        }
    }

    /// Zero expiration ignores the minimum fetch interval, so the request
    /// always hits the server instead of the cached template.
    private func performBypassCacheFetchAndActivate() async throws -> Bool {
        try await AppSpikeRemoteConfig.shared.fetch(withExpirationDuration: 0)
        return await AppSpikeRemoteConfig.shared.activate()
    }

    // MARK: - Settings

    /// Defaults of `RemoteConfigSettings` — what "Restore Defaults" applies.
    static let defaultMinimumFetchInterval: TimeInterval = 43_200
    static let defaultFetchTimeout: TimeInterval = 60

    var currentSettings: RemoteConfigSettings {
        AppSpikeRemoteConfig.shared.configSettings
    }

    var settingsSummary: String {
        let settings = currentSettings
        return "minimumFetchInterval \(Int(settings.minimumFetchInterval))s · "
            + "fetchTimeout \(Int(settings.fetchTimeout))s"
    }

    func applySettings(minimumFetchInterval: TimeInterval, fetchTimeout: TimeInterval) {
        AppSpikeRemoteConfig.shared.configSettings = RemoteConfigSettings(
            minimumFetchInterval: minimumFetchInterval,
            fetchTimeout: fetchTimeout
        )
        settingsStatus = "Applied: interval \(Int(minimumFetchInterval))s, "
            + "timeout \(Int(fetchTimeout))s"
    }

    /// Puts the SDK back on the stock interval/timeout pair.
    func restoreDefaultSettings() {
        AppSpikeRemoteConfig.shared.configSettings = RemoteConfigSettings()
        settingsStatus = "Restored defaults: interval "
            + "\(Int(Self.defaultMinimumFetchInterval))s, "
            + "timeout \(Int(Self.defaultFetchTimeout))s"
    }

    // MARK: - Custom signals

    /// Free-form signal entry: set one key to one string value, then fetch
    /// with the cache bypassed and activate, so a `custom_signal` condition
    /// keyed on it takes effect immediately.
    func applyCustomSignal(key: String, value: String) {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            signalsStatus = "Enter a signal key first"
            return
        }
        isFetching = true
        signalsStatus = "Setting '\(key)'..."
        Task {
            do {
                // Builder form takes any runtime string.
                let signals = CustomSignals.Builder()
                    .put(key: key, value: value)
                    .build()
                try await AppSpikeRemoteConfig.shared.setCustomSignals(signals)
                let changed = try await performBypassCacheFetchAndActivate()
                signalsStatus = changed
                    ? "'\(key)' = '\(value)' — new config activated"
                    : "'\(key)' = '\(value)' — config unchanged"
            } catch {
                signalsStatus = "Failed: \(error.localizedDescription)"
            }
            isFetching = false
            refreshAllEntries()
        }
    }

    /// Free-form signal removal: a nil value drops the key.
    func removeCustomSignal(key: String) {
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            signalsStatus = "Enter a signal key first"
            return
        }
        isFetching = true
        signalsStatus = "Removing '\(key)'..."
        Task {
            do {
                // Dictionary form: literals coerce to CustomSignalValue, and a
                // nil value removes the key.
                try await AppSpikeRemoteConfig.shared.setCustomSignals(
                    [key: nil]
                )
                _ = try await performBypassCacheFetchAndActivate()
                signalsStatus = "'\(key)' removed"
            } catch {
                signalsStatus = "Failed: \(error.localizedDescription)"
            }
            isFetching = false
            refreshAllEntries()
        }
    }

    // EXTRA (not required by the sample contract): a one-tap preset showing
    // the multi-signal builder with mixed value types.
    func setGoldPreset() {
        Task {
            do {
                // Signals feed custom_signal conditions and are evaluated
                // on-device — they are never transmitted anywhere.
                let signals = CustomSignals.Builder()
                    .put(key: "tier", value: "gold")
                    .put(key: "session_count", value: Int64(12))
                    .put(key: "spend", value: 12.5)
                    .build()
                try await AppSpikeRemoteConfig.shared.setCustomSignals(signals)
                signalsStatus =
                    "Preset set: tier=gold, session_count=12, spend=12.5"
            } catch {
                signalsStatus = "Failed: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Values

    func refreshAllEntries() {
        allEntries = AppSpikeRemoteConfig.shared.allConfigValues()
            .map { key, value in
                ConfigEntry(
                    key: key,
                    value: value.stringValue,
                    source: sourceLabel(value.source)
                )
            }
            .sorted { $0.key < $1.key }
    }

    /// Canonical source labels: lowercase, parenthesized — never raw enum
    /// names.
    private func sourceLabel(_ source: RemoteConfigSource) -> String {
        switch source {
        case .remote: return "(remote)"
        case .default: return "(default)"
        case .static: return "(static)"
        @unknown default: return "(unknown)"
        }
    }

    static let remoteSourceLabel = "(remote)"

    func getString(_ key: String) -> String {
        AppSpikeRemoteConfig.shared.getString(key)
    }

    func getBoolean(_ key: String) -> String {
        String(AppSpikeRemoteConfig.shared.getBoolean(key))
    }

    func getLong(_ key: String) -> String {
        String(AppSpikeRemoteConfig.shared.getLong(key))
    }

    func getDouble(_ key: String) -> String {
        String(AppSpikeRemoteConfig.shared.getDouble(key))
    }

    /// Every representation of one key: the typed accessors on
    /// `RemoteConfigValue` plus its source, the per-source lookup, and the
    /// registered in-app default.
    func inspect(_ key: String) -> [(String, String)] {
        let remoteConfig = AppSpikeRemoteConfig.shared
        // configValue(forKey:), the subscript, and the property wrapper all
        // resolve through the same remote → default → static precedence.
        let value = remoteConfig[key]
        var rows: [(String, String)] = [
            ("source", sourceLabel(value.source)),
            ("stringValue", value.stringValue),
            ("boolValue", String(value.boolValue)),
            ("numberValue", value.numberValue.stringValue),
            ("dataValue", "\(value.dataValue.count) bytes"),
            ("jsonValue", value.jsonValue.map { String(describing: $0) } ?? "not JSON"),
        ]
        rows.append((
            "remote only",
            remoteConfig.configValue(forKey: key, source: .remote).stringValue
        ))
        rows.append((
            "defaultValue(forKey:)",
            remoteConfig.defaultValue(forKey: key)?.stringValue ?? "no default"
        ))
        if let paywall: PaywallConfig = remoteConfig[decodedValue: key] {
            rows.append((
                "decodedValue",
                "\(paywall.headline) / max \(paywall.maxItems)"
            ))
        }
        if let json = remoteConfig[jsonValue: key] {
            rows.append(("jsonValue subscript", "\(json.count) top-level keys"))
        }
        return rows
    }

    // MARK: - Keys

    func keySummary(prefix: String) -> [(String, String)] {
        let remoteConfig = AppSpikeRemoteConfig.shared
        var rows: [(String, String)] = [
            ("remote keys", String(remoteConfig.allKeys(from: .remote).count)),
            ("default keys", String(remoteConfig.allKeys(from: .default).count)),
        ]
        if !prefix.isEmpty {
            let matches = remoteConfig.keys(withPrefix: prefix).sorted()
            rows.append((
                "prefix \"\(prefix)\"",
                matches.isEmpty ? "no matches" : matches.joined(separator: ", ")
            ))
        }
        return rows
    }

    // MARK: - Info

    func infoRows() -> [(String, String)] {
        let remoteConfig = AppSpikeRemoteConfig.shared
        let settings = remoteConfig.configSettings
        let context = AppSpike.shared.deviceContext()
        return [
            ("lastFetchStatus", remoteConfig.lastFetchStatus.rawValue),
            (
                "lastFetchTime",
                remoteConfig.lastFetchTime.map {
                    $0.formatted(date: .abbreviated, time: .standard)
                } ?? "never"
            ),
            ("minimumFetchInterval", "\(Int(settings.minimumFetchInterval))s"),
            ("fetchTimeout", "\(Int(settings.fetchTimeout))s"),
            ("platform", context.platform),
            ("appVersion", context.appVersion ?? "–"),
            ("language", context.language ?? "–"),
        ]
    }

    // MARK: - Reset

    func reset() {
        // Clears activated + fetched state, custom signals, and defaults...
        AppSpikeRemoteConfig.shared.reset()
        // ...then the sample re-registers its defaults, so the all-values
        // screen shows the defaults set with (default) sources and no remote
        // rows rather than going empty.
        SampleDefaults.apply()
        fetchStatus = "State reset — defaults re-applied"
        signalsStatus = ""
        refreshAllEntries()
    }
}
