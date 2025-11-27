import ProjectDescription

let project = Project(
    name: "Tasker",
    settings: .settings(
        base: .init().automaticCodeSigning(devTeam: App.teamId),
        debug: SettingsDictionary().setProjectVersions(),
        release: SettingsDictionary().setProjectVersions(),
        defaultSettings: .recommended
    ),
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
                    "NSSpeechRecognitionUsageDescription": "Speech recognize access is needed to fill your tasks.",
                    "NSPhotoLibraryUsageDescription": "Photo library access allows adding images from the device gallery.",
                    // Background mode
                    "UIBackgroundModes": ["fetch", "processing", "remote-notification"],
                    "BGTaskSchedulerPermittedIdentifiers": [
                        "mido.robocode.updateNotificationsAndSync"
                    ],
                    // iCloud
                    "NSUbiquitousContainers": [
                        "iCloud.com.mido.robocode": [
                            "NSUbiquitousContainerIsDocumentScopePublic": true,
                            "NSUbiquitousContainerSupportedFolderLevels": ["ANY"],
                            "NSUbiquitousContainerName": "Mi.dō",
                            "NSUbiquitousContainerIdentifier": "$(TeamIdentifierPrefix)$(CFBundleIdentifier)"
                        ]
                    ],
                    "CFBundleLocalizations": [
                        "en",
                        "ru",
                        "fr",
                        "fr-CA",
                        "es",
                        "es-MX",
                        "es-419",
                        "it",
                        "de",
                        "pt",
                        "pt-PT"
                    ]
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
            entitlements: .file(path: "Tasker/Tasker.entitlements"),
            dependencies: [
                .target(name: "MainView"),
            ],
            settings: .settings(
                base: .init().merging(
                    [
                        "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "NO",
                        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO"
                    ]
                ).otherSwiftFlags(.longTypeCheckingFlags),
                defaultSettings: .recommended
            ),
        ),
        .module(name: "BlockSet", dependencies: []),
        .moduleTests(name: "BlockSet", dependencies: [.target(name: "BlockSet")]),
        .module(name: "Models", dependencies: [.target(name: "BlockSet")]),
        .module(name: "UIComponents", dependencies: [.target(name: "Models"), .target(name: "Managers")]),
        .module(name: "Managers", dependencies: [.target(name: "Models"), .external(name: "PostHog")]),
        .moduleTests(name: "Managers", dependencies: [.target(name: "Managers"), .target(name: "BlockSet"), .target(name: "Models")]),
//        .target(
//            name: "Tests",
//            destinations: App.destinations,
//            product: .unitTests,
//            bundleId: App.bundleId + ".Tests",
//            deploymentTargets: App.deploymentTargets,
//            infoPlist: .default,
//            sources: ["Tasker/Tests**"],
//            dependencies: [
//                .target(name: "BlockSet"),
//                .target(name: "Models"),
//                .target(name: "Managers")
//            ]
//        ),
        .module(
            name: "Views",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents")
            ]
        ),
        .moduleView(
            name: "ProfileView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents"),
                .target(name: "PaywallView")
            ]
        ),
        .moduleView(
            name: "CalendarView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents"),
                .target(name: "PaywallView")
            ]
        ),
        .moduleView(
            name: "TaskView",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Managers"),
                .target(name: "UIComponents"),
                .target(name: "PaywallView")
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
                .target(name: "CalendarView"),
                .target(name: "ListView"),
                .target(name: "TaskView"),
                .target(name: "ProfileView"),
                .target(name: "PaywallView")
            ]
        ),
        .moduleView(
            name: "PaywallView",
            dependencies: [
                .target(name: "Managers"),
                .target(name: "UIComponents"),
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
                        configuration: .release,
                        attachDebugger: false,
                        options: .options(storeKitConfigurationPath: "Tasker/Modules/Managers/SubscriptionManager/Mi.storekit"),
                        expandVariableFromTarget: .target("Tasker"),
                        launchStyle: .automatically
                    ),
        ),
        Scheme.scheme(
            name: "Debug",
            shared: true,
            buildAction: .buildAction(targets: ["Tasker"]),
//            testAction: TestAction.targets(["Tests"], arguments: nil, configuration: .debug),
            runAction:
                    .runAction(
                        configuration: .debug,
                        attachDebugger: true,
                        expandVariableFromTarget: .target("Tasker"),
                        launchStyle: .automatically
                    ),
        )
    ],
    additionalFiles: [
        "Tasker/Tasker.entitlements"
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
    static func module(name: String, dependencies: [TargetDependency]) -> Target {
        var resources: [ResourceFileElement] = []
        
        if name != "BlockSet" {
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
    
    static func moduleTests(name: String, dependencies: [TargetDependency] = []) -> Target {
        .target(
            name: "\(name)Tests",
            destinations: App.destinations,
            product: .unitTests,
            bundleId: App.bundleId + "." + name + ".Tests",
            deploymentTargets: App.deploymentTargets,
            infoPlist: .default,
            sources: ["Tasker/Tests/\(name)/**"],
            dependencies: dependencies
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
    public static let bundleId = "mido.robocode"
    public static let teamId = "5M63H38ZMF"
    public static let deploymentTargets = DeploymentTargets.iOS("17.0")
    public static let version = "1.1.3"
}


extension SettingsDictionary {
    func setProjectVersions() -> SettingsDictionary {
        let currentProjectVersion = App.version
        let markettingVersion = App.version
        
        return appleGenericVersioningSystem().merging([
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: currentProjectVersion),
            "MARKETING_VERSION": SettingValue(stringLiteral: markettingVersion)
        ])
    }
}

extension Array where Element == String {
    static let longTypeCheckingFlags = [
        "-Xfrontend",
        "-warn-long-function-bodies=100",
        "-Xfrontend",
        "-warn-long-expression-type-checking=100"
    ]
}
