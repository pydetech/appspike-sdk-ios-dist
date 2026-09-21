# AppSpike SDK for iOS

**The free Firebase Remote Config alternative.**

> **Firebase Remote Config is going paid.** Google's usage-based pricing took effect on
> September 1, 2026. Existing free-plan (Spark) projects hit enforcement on
> **December 1, 2026**: past 100K daily fetches they get a 30-day grace period and are
> then throttled. Existing Blaze projects are billed automatically from
> **February 1, 2027**. The dates come from
> [Firebase's own pricing schedule](https://firebase.google.com/docs/remote-config/pricing).
> The [migration schedule below](#when-to-migrate) fits inside that window.


Native Swift SDK for [AppSpike Remote Config](https://appspike.dev/remote-config). **Free** remote configuration, feature flags, and staged rollouts, with every condition evaluated **locally on-device**. AppSpike Remote Config is also a drop-in replacement for Firebase Remote Config: the same fetch/activate semantics, with no fetch limits and no usage fees.

[Product](https://appspike.dev/remote-config) · [Docs](https://appspike.dev/docs/remote-config)

## Installation

### Swift Package Manager

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/pydetech/appspike-sdk-ios-dist.git",
        from: "1.4.5"
    ),
]
```

Then add the targets you need:

```swift
.target(
    name: "YourApp",
    dependencies: [
        .product(name: "AppSpikeSDKCore", package: "appspike-sdk-ios-dist"),
        .product(name: "AppSpikeSDKRemoteConfig", package: "appspike-sdk-ios-dist"),
    ]
),
```

Or in Xcode: **File > Add Package Dependencies**, paste `https://github.com/pydetech/appspike-sdk-ios-dist.git`.

### Tuist

In your `Tuist/Package.swift`:

```swift
let package = Package(
    name: "Dependencies",
    dependencies: [
        .package(
            url: "https://github.com/pydetech/appspike-sdk-ios-dist.git",
            from: "1.4.5"
        ),
    ]
)
```

Then in `Project.swift`:

```swift
dependencies: [
    .external(name: "AppSpikeSDKCore"),
    .external(name: "AppSpikeSDKRemoteConfig"),
]
```

## Quick Start

**1. Register your app.** Create your app at [console.appspike.dev](https://console.appspike.dev) and copy its `pk_live_…` API key.

**2. Initialize the SDK.** Pass Remote Config in as a module.

```swift
import AppSpikeSDKCore
import AppSpikeSDKRemoteConfig

AppSpike.shared.initialize(
    apiKey: "your-api-key",
    modules: [AppSpikeRemoteConfig.shared]
) { result in
    switch result {
    case .success:
        print("SDK initialized")
    case .error(let message):
        print("Init failed: \(message)")
    }
}
```

**3. Set defaults.** These are served until a fetched config is activated.

```swift
AppSpikeRemoteConfig.shared.setDefaults([
    "welcome_message": "Hello!",
    "feature_enabled": false,
    "max_retries": 3,
    "price": 9.99,
])
```

**4. Fetch and activate**

```swift
Task {
    do {
        let status = try await AppSpikeRemoteConfig.shared.fetchAndActivate()
        print("Config status: \(status)")
    } catch {
        // A failed fetch is an ordinary outcome — offline, or a backoff window.
        // Your defaults (or the last activated config) stay in place.
        print("Fetch skipped: \(error)")
    }
}
```

**5. Read values.** The accessors are typed, and in-app defaults are the fallback.

```swift
let message = AppSpikeRemoteConfig.shared.configValue(forKey: "welcome_message").stringValue
let enabled = AppSpikeRemoteConfig.shared.configValue(forKey: "feature_enabled").boolValue
let retries = AppSpikeRemoteConfig.shared.configValue(forKey: "max_retries").numberValue.intValue

// Or use convenience methods
let message2 = AppSpikeRemoteConfig.shared.getString("welcome_message")

// Or use property wrappers
@RemoteConfigProperty(key: "welcome_message") var welcomeMessage: String

// Or listen for updates
for try await update in AppSpikeRemoteConfig.shared.configUpdates {
    print("Keys changed: \(update.updatedKeys)")
}
```

## Why AppSpike Remote Config?

**A free, direct replacement for Firebase Remote Config.** The same fetch/activate lifecycle in a native Swift API, with no fetch metering or usage fees. Firebase Remote Config is free up to 100K fetches per day, then bills $0.06 per 10K. AppSpike Remote Config stays free at any scale.

**Your targeting data stays on the device.** Firebase Remote Config sends custom signals to Google's servers with every fetch and evaluates conditions there. AppSpike Remote Config downloads the template once and evaluates every condition locally. User tier, level, or any signal you set is never transmitted anywhere.

**Works offline.** The last activated config keeps serving with no network, and changed signals or crossed time boundaries take effect on the next fetch cycle even offline.

**Migration is mechanical.** The API maps onto Firebase Remote Config's method-for-method, with subscript reads staying subscript reads. The [migration guide](#migrating-from-firebase-remote-config) below covers every call, and there is an [AI prompt](#ai-assisted-migration) that does the conversion for you.

**Battle tested.** It already serves millions of users in PokeRaid and PokeTrade.

## Migrating from Firebase Remote Config

The API is designed to be a drop-in replacement. Move your config template in the console first, then the code changes are imports and initialization. The value access API is identical.

### Feature comparison

| Feature | Firebase Remote Config | AppSpike Remote Config |
|---------|----------------------|----------------------|
| Fetch & activate lifecycle | ✅ | ✅ |
| Typed value access (string, bool, number, data, JSON) | ✅ | ✅ |
| In-app defaults | ✅ | ✅ |
| Plist defaults | ✅ | ✅ |
| Custom signals / targeting | ✅ | ✅ |
| Percent rollout | ✅ | ✅ |
| Country / language targeting | ✅ | ✅ |
| App version / build targeting | ✅ | ✅ |
| Date/time conditions | ✅ | ✅ |
| Regex matching | ✅ | ✅ |
| Config update listeners | ✅ | ✅ (on fetch & activate) |
| AsyncSequence for updates | ✅ | ✅ |
| Property wrappers (`@RemoteConfigProperty`) | ❌ | ✅ |
| Codable subscript decoding | ✅ | ✅ |
| Minimum fetch interval | ✅ | ✅ |
| Exponential backoff on failure | ✅ | ✅ |
| Price at scale | 100K fetches/day free, then $0.06 per 10K | Free, no fetch metering |
| Config import | ❌ No import path from other providers | ✅ One-click import from Firebase |
| Version history & rollback | ✅ | ✅ |
| Real-time config updates | ✅ Real-time Remote Config | ✅ (push setup required) |
| A/B testing | ✅ Firebase A/B Testing | ✅ Via percentage conditions |
| Analytics audience targeting | ✅ Google Analytics audiences | ❌ Use custom signals instead |
| Device targeting identity | Google Installation ID | AppSpike device ID |
| Multiple app instances | ✅ | ❌ |

### When to migrate

The two SDKs run side by side in the same app, so nothing forces a single cutover day. Two dates bound the plan: existing Spark projects face throttling enforcement from December 1, 2026, and existing Blaze projects are billed from February 1, 2027.

1. **Today.** Register your app at [console.appspike.dev](https://console.appspike.dev), import your Firebase Remote Config template, and publish. Nothing in your app changes yet.
2. **Next development cycle.** Make the code changes below in a branch. Debug builds can run both SDKs together and compare values.
3. **Before the cutover release.** Finish any in-flight percentage rollouts and experiments on Firebase Remote Config. Rollout groups are re-randomized on AppSpike, so a mid-rollout user can change groups. If your template changed since step 1, import it again.
4. **The cutover release.** Ship the swap as a normal app release. Keep your in-app defaults registered. They cover every device that has not fetched yet.
5. **After the rollout.** Once the release has reached most of your fleet, remove the FirebaseRemoteConfig product from your dependencies.

### Step-by-step

**1. Move your config template.** In the [AppSpike console](https://console.appspike.dev), register your app, import your Firebase Remote Config template (Firebase export upload is supported), review it, and publish. Your parameters and conditions exist on the AppSpike side before the app code changes.

**2. Replace the dependency**

Drop the `FirebaseRemoteConfig` product from your target's dependencies and add `AppSpikeSDKCore` + `AppSpikeSDKRemoteConfig` (see [Installation](#installation)).

**3. Update imports**

```swift
// Before
import FirebaseRemoteConfig

// After
import AppSpikeSDKCore
import AppSpikeSDKRemoteConfig
```

`RemoteConfigSettings`, `CustomSignals`, `RemoteConfigFetchError` and `RemoteConfigThrottledError` (used by the steps below) all come from `AppSpikeSDKRemoteConfig`, so those two imports are the whole list.

**4. Add initialization.** `AppSpike.shared.initialize` is added once at app startup.

```swift
// Before
let config = RemoteConfig.remoteConfig()

// After
AppSpike.shared.initialize(
    apiKey: "your-api-key",
    modules: [AppSpikeRemoteConfig.shared]
) { result in
    switch result {
    case .success: break
    case .error(let message): print("Init failed: \(message)")
    }
}
let config = AppSpike.remoteConfig()   // same shape as RemoteConfig.remoteConfig();
                                       // returns the AppSpikeRemoteConfig.shared singleton
```

**5. Defaults.** The Firebase calls compile verbatim.

```swift
// Before
config.setDefaults(["welcome_message": "Hello!" as NSObject])
config.setDefaults(fromPlist: "RemoteConfigDefaults")

// After — same method names, same arguments; only the receiver changed
config.setDefaults(["welcome_message": "Hello!"])
config.setDefaults(fromPlist: "RemoteConfigDefaults")
```

**6. Settings.** You get a memberwise initializer instead of a mutated object.

```swift
// Before
let settings = RemoteConfigSettings()
settings.minimumFetchInterval = 0
settings.fetchTimeout = 60
config.configSettings = settings

// After — same property names, but AppSpike's RemoteConfigSettings is a struct
config.configSettings = RemoteConfigSettings(
    minimumFetchInterval: 0,
    fetchTimeout: 60
)
```

**7. Fetch / activate.** Same names, same `async`.

```swift
// Before
try await config.fetchAndActivate()
try await config.fetch()
try await config.activate()

// After — identical, except activate() does not throw (it returns Bool)
Task {
    do {
        let status = try await config.fetchAndActivate()
        print("Config status: \(status)")
    } catch {
        // A failed fetch is an ordinary outcome — offline, or a backoff window.
        // Your defaults (or the last activated config) stay in place.
        print("Fetch skipped: \(error)")
    }
}
```

Keep whatever `do`/`catch` you had around the Firebase fetch. `fetch()` and `fetchAndActivate()` throw here the same way.

**8. Read values.** Replace the receiver and keep the calls.

```swift
// Before
config.configValue(forKey: "key").stringValue
config.configValue(forKey: "key").boolValue
config.configValue(forKey: "key").numberValue
config.configValue(forKey: "key").dataValue
config.configValue(forKey: "key").jsonValue
config["key"].stringValue

// After — the same expressions, with `config` now the AppSpike instance
config.configValue(forKey: "key").stringValue
config.configValue(forKey: "key").boolValue
config.configValue(forKey: "key").numberValue
config.configValue(forKey: "key").dataValue
config.configValue(forKey: "key").jsonValue
config["key"].stringValue
```

**9. Custom signals.** The Firebase call compiles verbatim.

```swift
// Before
try await config.setCustomSignals(["tier": "gold", "level": 5])

// After — same overload, `[String: CustomSignalValue?]`
try await config.setCustomSignals(["tier": "gold", "level": 5])

// Or the builder, if you prefer it (AppSpike addition, Firebase Android's shape)
let signals = CustomSignals.Builder()
    .put(key: "tier", value: "gold")
    .put(key: "level", value: 5)
    .build()
try await config.setCustomSignals(signals)
```

Signals are evaluated on-device and never transmitted, so they take effect at the next fetch + activate.

**10. Config update listeners.** The Firebase closure compiles verbatim.

```swift
// Before
let registration = config.addOnConfigUpdateListener { update, error in
    print("Changed: \(update?.updatedKeys ?? [])")
}

// After — same `(update, error)` pair. AppSpike always calls it as (update, nil):
// delivery is activation-driven, and the error half is reserved for a future push channel.
let registration = config.addOnConfigUpdateListener { update, error in
    print("Changed: \(update?.updatedKeys ?? [])")
}

// Or the AsyncSequence, Firebase's shape exactly
for try await update in config.configUpdates {
    print("Changed: \(update.updatedKeys)")
}
```

**11. Error handling.** You get typed errors instead of NSError codes.

```swift
// Before (Firebase reports fetch failures as NSError codes)
do {
    try await config.fetch()
} catch let error as NSError {
    if error.code == RemoteConfigError.throttled.rawValue { /* back off */ }
}

// After (typed Swift errors)
do {
    try await config.fetch()
} catch is RemoteConfigThrottledError {
    // throttled — try again later
} catch let error as RemoteConfigFetchError {
    // other fetch failure
    print(error.message)
}
```

### API mapping reference

| Firebase | AppSpike | Change |
|----------|----------|--------|
| `RemoteConfig.remoteConfig()` | `AppSpike.remoteConfig()` | Same pattern |
| `config.configValue(forKey:)` | `config.configValue(forKey:)` | Same |
| `config["key"]` | `config["key"]` | Same |
| `value.stringValue` | `value.stringValue` | Same |
| `value.boolValue` | `value.boolValue` | Same |
| `value.numberValue` | `value.numberValue` | Same |
| `value.dataValue` | `value.dataValue` | Same |
| `value.jsonValue` | `value.jsonValue` | Same |
| `value.source` | `value.source` | Same |
| `config.configSettings` | `config.configSettings` | Same |
| `config.lastFetchTime` | `config.lastFetchTime` | Same |
| `config.lastFetchStatus` | `config.lastFetchStatus` | Same |
| `config.setDefaults(_:)` | `config.setDefaults(_:)` | Same |
| `config.setDefaults(fromPlist:)` | `config.setDefaults(fromPlist:)` | Same |
| `config.fetch()` | `config.fetch()` | Same |
| `config.activate()` | `config.activate()` | Same |
| `config.fetchAndActivate()` | `config.fetchAndActivate()` | Same |
| `config.allKeys(from:)` | `config.allKeys(from:)` | Same |
| `config.keysWithPrefix(_:)` | `config.keysWithPrefix(_:)` | Same |
| `config.setCustomSignals(_:)` | `config.setCustomSignals(_:)` | Same |
| `config.addOnConfigUpdateListener` | `config.addOnConfigUpdateListener` | Same `(update, error)` callback. AppSpike always calls it as `(update, nil)` |
| `config.reset()` | `config.reset()` | Same |
| `RemoteConfig` | `AppSpikeRemoteConfig` | Branded class name |
| `RemoteConfigSource` | `RemoteConfigSource` | Same |
| `RemoteConfigFetchStatus` | `RemoteConfigFetchStatus` | Same |
| `RemoteConfigError` (NSError codes) | `RemoteConfigFetchError` / `RemoteConfigThrottledError` | Typed Swift errors instead of error codes |

### AI-Assisted Migration

Copy the prompt below into your AI coding assistant (Claude, Cursor, Copilot, etc.) to migrate automatically:

<details>
<summary>Migration prompt</summary>

```
Migrate this iOS project from Firebase Remote Config to AppSpike Remote Config.

Rules:
1. Replace the FirebaseRemoteConfig SPM dependency with:
   .package(url: "https://github.com/pydetech/appspike-sdk-ios-dist.git", from: "1.4.5")
   Products: "AppSpikeSDKCore" and "AppSpikeSDKRemoteConfig"

2. Replace all `import FirebaseRemoteConfig` with:
   import AppSpikeSDKCore
   import AppSpikeSDKRemoteConfig

3. Replace `RemoteConfig.remoteConfig()` with `AppSpike.remoteConfig()`

4. Add AppSpike initialization before any Remote Config usage:
   AppSpike.shared.initialize(apiKey: "YOUR_API_KEY", modules: [AppSpikeRemoteConfig.shared]) { result in }

5. Replace `RemoteConfigSettings()` constructor:
   - Before: let s = RemoteConfigSettings(); s.minimumFetchInterval = 0; s.fetchTimeout = 60
   - After: RemoteConfigSettings(minimumFetchInterval: 0, fetchTimeout: 60)

6. The following APIs are IDENTICAL and need NO changes:
   - configValue(forKey:), subscript ["key"]
   - stringValue, boolValue, numberValue, dataValue, jsonValue, source
   - setDefaults(_:), setDefaults(fromPlist:)
   - fetch(), activate(), fetchAndActivate()
   - configSettings (get/set), lastFetchTime, lastFetchStatus
   - allKeys(from:), keysWithPrefix(_:)
   - setCustomSignals(_:)
   - addOnConfigUpdateListener, reset()

7. addOnConfigUpdateListener keeps Firebase's exact `{ update, error in ... }` callback, so
   existing listeners port unchanged. AppSpike always calls it as (update, nil).

8. Replace Firebase error handling:
   - `RemoteConfigError` (NSError with codes) → `RemoteConfigFetchError` (typed Swift error)
   - Throttle: `error.code == RemoteConfigError.throttled.rawValue` → `catch is RemoteConfigThrottledError`
   - Access error message via `.message` property, not `.localizedDescription`

9. Remove any Firebase Analytics or A/B Testing integration code that depends on Remote Config — those are Firebase-specific.

10. Search for `RemoteConfigFetchAndActivateStatus` — the enum cases are the same:
   .successFetchedFromRemote, .successUsingPreFetchedData, .error

Apply these changes to every file in the project. After migrating, verify the project builds.
```

</details>

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Modules

| Module | Description |
|--------|-------------|
| `AppSpikeSDKCore` | Session management, authentication, device context |
| `AppSpikeSDKRemoteConfig` | Remote config with local evaluation of all condition types |

## Sample App

The `SampleApp/` directory contains a SwiftUI demo app.

**Prerequisites**

- Xcode 16 or later
- [Tuist](https://tuist.dev), installed with `brew install tuist` (or `mise install tuist`)

**Run it**

```bash
cd SampleApp
tuist install    # resolves the SDK package and downloads the binary frameworks
tuist generate   # generates SampleApp.xcworkspace and opens it in Xcode
```

Then:

1. Set `appSpikeApiKey` in `SampleApp/Sources/SampleApp/ApiKey.swift`.
2. Select the `SampleApp` scheme and an iOS 15+ simulator, and press Run (⌘R).

## License

Copyright (c) 2026 Pyde Technologies LTD. All rights reserved.

The AppSpike SDK is proprietary software, free to use with AppSpike services. Redistribution, modification, and reverse engineering are not permitted. See [LICENSE](LICENSE) for the full terms, or contact info@pyde.tech.
