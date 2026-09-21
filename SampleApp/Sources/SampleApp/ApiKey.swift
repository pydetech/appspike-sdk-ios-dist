/// The one place this sample stores its AppSpike API key.
///
/// Replace the placeholder with the `pk_live_…` key for your app from
/// [console.appspike.dev](https://console.appspike.dev). The sample has no
/// runtime key-entry field on purpose: a text field models an integration
/// nobody ships — real apps pass the key at build time, so the sample does the
/// same.
///
/// While the placeholder is unchanged the sample does not initialize and shows
/// a setup message on screen instead of failing silently.
let appSpikeApiKey = "YOUR_API_KEY"

/// The placeholder shipped in this repo; ``appSpikeApiKey`` must be replaced
/// before the sample will initialize.
let apiKeyPlaceholder = "YOUR_API_KEY"

/// Where the reader has to go to fix an unset key — shown on screen.
let apiKeyLocation = "SampleApp/Sources/SampleApp/ApiKey.swift"
