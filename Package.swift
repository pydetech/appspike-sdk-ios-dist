// swift-tools-version: 6.0

import PackageDescription

let version = "1.4.5"
let repo = "https://github.com/pydetech/appspike-sdk-ios-dist"

let package = Package(
    name: "AppSpikeSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AppSpikeSDKCore",
            targets: ["AppSpikeSDKCore"]
        ),
        .library(
            name: "AppSpikeSDKRemoteConfig",
            targets: ["AppSpikeSDKRemoteConfig"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "AppSpikeSDKCore",
            url: "\(repo)/releases/download/\(version)/AppSpikeSDKCore.xcframework.zip",
            checksum: "2763782786c72e19b755b4732b28a255324675416868979d384a2c6a915c9d9c"
        ),
        .binaryTarget(
            name: "AppSpikeSDKRemoteConfig",
            url: "\(repo)/releases/download/\(version)/AppSpikeSDKRemoteConfig.xcframework.zip",
            checksum: "96e85688f198e707b63acd35dfc8e1bb1326bcb1d5c762f7d6b456785ae005bd"
        ),
    ]
)
