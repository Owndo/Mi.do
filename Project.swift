import ProjectDescription

let project = Project(
    name: "Tasker",
    settings: .settings(base: .init().automaticCodeSigning(devTeam: App.teamId), debug: SettingsDictionary().setProjectVersions(), release: SettingsDictionary().setProjectVersions(), defaultSettings: .recommended),
    targets: [
        .target(
            name: App.name,
            destinations: .iOS,
            product: .app,
            bundleId: App.bundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchStoryboardName": "LaunchScreen",
                    "CFBundleDisplayName": "Mi.dō",
                    "CFBundleShortVersionString": "\(App.version)",
                    "NSUserNotificationsUsageDescription": "Notifications may include alerts, sounds, or badges. Can be adjusted anytime in Settings.",
                    "NSMicrophoneUsageDescription": "Microphone access is needed to record voice.",
                    "NSPhotoLibraryUsageDescription": "Photo library access allows adding images from the device gallery."
                ]
            ),
            sources: [.glob(
                "Tasker/**",
                excluding: [
                    "Tasker/Modules/**",
                    "Tasker/Tests/**",
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
        .module(name: "UIComponents", dependencies: [.target(name: "Models"), .target(name: "Managers")]),
        .module(name: "Managers", dependencies: [.target(name: "Models")]),
        .target(
            name: "ManagersTests",
            destinations: App.destinations,
            product: .unitTests,
            bundleId: App.bundleId + ".ManagersTests",
            deploymentTargets: App.deploymentTargets,
            infoPlist: .default,
            sources: ["Tasker/Tests/ManagersTests/**"],
            //            resources: [],
            dependencies: [
                .target(name: "Managers"),
                .target(name: "Models")
            ]
        ),
        .module(
            name: "Views",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents")
            ]
        ),
        .moduleView(
            name: "Profile",
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
                .target(name: "UIComponents")
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
                .target(name: "Profile"),
            ]
        )
    ],
    schemes: [
        Scheme.scheme(
            name: "Tasker",
            shared: true,
            buildAction: .buildAction(targets: ["Tasker"]),
            runAction:
                    .runAction(
                        configuration: .debug,
                        attachDebugger: false,
                        expandVariableFromTarget: .target("Tasker"),
                        launchStyle: .automatically
                    ),
        ),
        Scheme.scheme(
            name: "Debug",
            shared: true,
            buildAction: .buildAction(targets: ["Tasker"]),
            runAction:
                    .runAction(
                        configuration: .debug,
                        attachDebugger: true,
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
        
        if name != "BlockSet" || name != "Models" {
            resources.append("Tasker/Modules/\(name)/Resources/**")
        }
        
        return .target(
            name: name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + name,
            deploymentTargets: App.deploymentTargets,
            sources: ["Tasker/Modules/\(name)/**"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(defaultSettings: .recommended)
        )
    }
    
    static func moduleView(name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        
        var resources: [ResourceFileElement] = []
        
        resources.append("Tasker/Modules/Views/\(name)/Resources/**")
        
        return .target(
            name: name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + name,
            deploymentTargets: App.deploymentTargets,
            sources: ["Tasker/Modules/Views/\(name)/**"],
            resources: .resources(resources),
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
    public static let version = "0.7.0"
}


extension SettingsDictionary {
    func setProjectVersions() -> SettingsDictionary {
        let currentProjectVersion = "0.7.0"
        let markettingVersion = "0.7.0"
        
        return appleGenericVersioningSystem().merging([
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: currentProjectVersion),
            "MARKETING_VERSION": SettingValue(stringLiteral: markettingVersion)
        ])
    }
}

