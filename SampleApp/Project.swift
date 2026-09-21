import ProjectDescription

let project = Project(
    name: "SampleApp",
    targets: [
        .target(
            name: "SampleApp",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "dev.appspike.sample",
            deploymentTargets: .iOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
            ]),
            sources: ["Sources/**"],
            dependencies: [
                .external(name: "AppSpikeSDKCore"),
                .external(name: "AppSpikeSDKRemoteConfig"),
            ]
        ),
    ]
)
