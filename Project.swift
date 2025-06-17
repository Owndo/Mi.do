import ProjectDescription

let project = Project(
    name: "Tasker-tuist",
    settings: .settings(base: .init().automaticCodeSigning(devTeam: "\(App.teamId)"), defaultSettings: .recommended),
    targets: [
        .target(
            name: "Tasker",
            destinations: .iOS,
            product: .app,
            bundleId: App.bundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "CFBundleDisplayName": "Mi.dō",
                    "NSUserNotificationsUsageDescription" : "Notifications may include alerts, sounds, and icon badges. You can configurate this in Setting.",
                    "NSMicrophoneUsageDescription": "This app uses microphone for recording your voice"
                ]
            ),
            sources: [.glob(
                "Tasker/**",
                excluding: [
                    "Tasker/Modules/**",
                ]
            )],
            resources: [.glob(pattern: "Tasker/Resources/**", excluding: ["Tasker/Resources/Info.plist"])],
            dependencies: [
                .target(name: "MainView")
            ],
            settings: .settings(
                base: .init().merging(
                    [
                        "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "NO",
                        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO"
                    ]
                ) ,
                defaultSettings: .recommended
            ),
        ),
        .module(name: "BlockSet", dependencies: []),
        .module(name: "Models", dependencies: [.target(name: "BlockSet")]),
        .module(name: "UIComponents", dependencies: [.target(name: "Models")]),
        .module(name: "Managers", dependencies: [.target(name: "Models")]),
        .module(
            name: "Views",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents")
            ]
        ),
        .moduleView(
            name: "Calendar",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
            ]
        ),
        .moduleView(
            name: "TaskView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents")
            ]
        ),
        .moduleView(
            name: "ListView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents"),
                .target(name: "TaskView")
            ]
        ),
        .moduleView(
            name: "MainView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents"),
                .target(name: "Calendar"),
                .target(name: "ListView"),
                .target(name: "TaskView"),
            ]
        )
    ],
    schemes: [
        Scheme.scheme(
            name: "Debug",
            shared: true,
            buildAction: .buildAction(targets: ["Tasker"]),
            runAction:
                    .runAction(
                        configuration: .debug,
                        attachDebugger: false,
                        expandVariableFromTarget: .target("Tasker"),
                        launchStyle: .automatically
                    ),
        )
    ],
    
    resourceSynthesizers: [
        .custom(
            name: "UI",
            parser: .assets,
            extensions: ["xcassets"]
        )
    ]
)


extension Target {
    static func module(name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        var resources: [ResourceFileElement] = []
        
        if name == "UIComponents" {
            resources.append("Tasker/Modules/\(name)/Resources/**")
        }
        
        return .target(
            name: name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + name,
            deploymentTargets: App.deploymentTargets,
            infoPlist: .default,
            sources: ["Tasker/Modules/\(name)/**"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(defaultSettings: .recommended)
        )
    }
    
    static func moduleView(name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        
        return .target(
            name: name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + name,
            deploymentTargets: App.deploymentTargets,
            infoPlist: .default,
            sources: ["Tasker/Modules/Views/\(name)/**"],
            dependencies: dependencies,
            settings: .settings(defaultSettings: .recommended)
        )
    }
}

struct App {
    public static let name = "Tasker"
    public static let destinations: ProjectDescription.Destinations = .iOS
    public static let bundleId = "com.kodi.mido"
    public static let teamId = "JMB8Y7C47R"
    public static let deploymentTargets = DeploymentTargets.iOS("17.0")
}
