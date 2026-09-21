// swift-tools-version: 6.0
@preconcurrency import PackageDescription

let package = Package(
    name: "SampleAppDependencies",
    dependencies: [
        .package(
            url: "https://github.com/pydetech/appspike-sdk-ios-dist.git",
            from: "1.4.5"
        ),
    ]
)
