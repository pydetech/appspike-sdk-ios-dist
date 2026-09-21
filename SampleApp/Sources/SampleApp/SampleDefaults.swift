import AppSpikeSDKRemoteConfig
import Foundation

/// The sample's in-app defaults.
///
/// Registered once at startup and re-applied after `Reset`, so the all-values
/// screen always falls back to the same baseline instead of going empty.
/// Defaults are served before the first activation and as the fallback for
/// keys the published template does not define; they appear as `(default)`.
enum SampleDefaults {
    static func apply() {
        AppSpikeRemoteConfig.shared.setDefaults([
            // The four shared sample defaults. Every AppSpike sample app
            // registers exactly these, so the docs and the automated
            // sample-test workflow can treat all platforms uniformly.
            "welcome_message": "Hello from defaults",
            "feature_enabled": false,
            "max_retries": 3,
            "price_multiplier": 1.0,

            // iOS-specific extras, each showcasing a platform-only API.
            // `Data` defaults round-trip through `RemoteConfigValue.dataValue`.
            "onboarding_pages": Data("intro,permissions,done".utf8),
            // A dictionary default backs the JSON/Codable accessors —
            // `remoteConfig[jsonValue:]` and `remoteConfig[decodedValue:]`.
            "paywall_config": [
                "headline": "Go Pro",
                "maxItems": 5,
            ],
        ])
        // A bundled plist works too:
        // AppSpikeRemoteConfig.shared.setDefaults(
        //     fromPlist: "RemoteConfigDefaults"
        // )
    }
}
