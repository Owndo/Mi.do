import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Tasker",
    settings: .settings(
        base: .init().automaticCodeSigning(devTeam: App.teamId).merging(
            [
                "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "NO",
                "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO",
                "SWIFT_VERSION": "5.0"
            ]
        ),
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
            infoPlist: .infoPlist(),
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
                .target(name: Modules.paywallView.name),
                .target(name: Modules.subscriptionManager.name),
            ],
            settings: .settings(defaultSettings: .recommended),
        ),
        .module(.blockSet),
        .moduleTests(.blockSet, dependencies: [.target(name: Modules.blockSet.name)]),
        .module(.models, dependencies: [.target(name: Modules.blockSet.name)]),
        //MARK: - Config file
        .module(.config),
        //MARK: - Managers
        //MARK: - Delegate
            .module(.appDelegate),
        //MARK: - Telemetry
        .module(.telemetry, dependencies: [.target(name: Modules.models.name), .external(name: "PostHog")]),
        //MARK: - Errors
        .module(.errors),
        //MARK: - Permission
        .module(
            .permissionManager,
            dependencies: [
                .target(name: Modules.errors.name),
                .target(name: Modules.telemetry.name)
            ]
        ),
        //MARK: - Subscription
        .module(.subscriptionManager),
        //MARK: - Cas manager
        .module(
            .cas,
            dependencies: [
                .target(name: Modules.blockSet.name),
                .target(name: Modules.models.name)
            ]
        ),
        //MARK: - Profile manager
        .module(.profileManager, dependencies: [.target(name: Modules.models.name), .target(name: Modules.cas.name)]),
        //MARK: - Storage manager
        .module(.storageManager, dependencies: [.target(name: Modules.cas.name)]),
        //MARK: - Task manager
        .module(
            .taskManager,
            dependencies: [
                .target(name: Modules.cas.name),
                .target(name: Modules.dateManager.name),
                .target(name: Modules.notificationManager.name)
            ]
        ),
        //MARK: - Date manager
        .module(
            .dateManager,
            dependencies: [
                .target(
                    name: Modules.profileManager.name
                ),
                .target(name: Modules.telemetry.name)
            ]
        ),
        //MARK: - Notification Manager
        .module(
            .notificationManager,
            dependencies: [
                .target(name: Modules.cas.name),
                .target(name: Modules.dateManager.name),
                .target(name: Modules.storageManager.name),
                .target(name: Modules.subscriptionManager.name),
                .target(name: Modules.permissionManager.name)
            ]
        ),
        //MARK: - Recorder
        .module(
            .recorderManager,
            dependencies: [
                .target(name: Modules.telemetry.name),
                .target(name: Modules.magic.name),
                .target(name: Modules.dateManager.name)
            ]
        ),
        //MARK: - Magic
        .module(.magic, dependencies: [.target(name: Modules.dateManager.name)]),
        //MARK: - Player
        .module(
            .playerManager,
            dependencies: [.target(name: Modules.models.name), .target(name: Modules.storageManager.name)]
        ),
        //MARK: - Appearance
        .module(.appearanceManager, dependencies: [.target(name: Modules.profileManager.name)]),
        //MARK: - Onboarding
        .module(
            .onboardingManager,
            dependencies: [
                .target(name: Modules.profileManager.name),
                .target(name: Modules.taskManager.name),
                .target(name: Modules.dateManager.name)
            ]
        ),
        .moduleView(.uiComponents, dependencies: [.target(name: Modules.models.name)]),
        .moduleView(.paywallView,
                    dependencies: [
                        .target(name: Modules.subscriptionManager.name),
                        .target(name: Modules.uiComponents.name),
                        .target(name: Modules.config.name)
                    ]
                   ),
        .moduleView(
            .taskView,
            dependencies: [
                .target(name: Modules.models.name),
                .target(name: Modules.taskManager.name),
                .target(name: Modules.profileManager.name),
                .target(name: Modules.dateManager.name),
                .target(name: Modules.playerManager.name),
                .target(name: Modules.recorderManager.name),
                .target(name: Modules.permissionManager.name),
                .target(name: Modules.storageManager.name),
                .target(name: Modules.telemetry.name),
                .target(name: Modules.paywallView.name),
                
            ]
        )
        //        .moduleTests(name: "BlockSet", dependencies: [.target(name: "BlockSet")]),
        //        .module(name: "Models", dependencies: [.target(name: "BlockSet")]),
        //        .manager(name: manager(.telemetry)),
        //        .manager(name: manager(.cas), dependencies: [.target(name: "Models"), .target(name: "BlockSet")]),
        //        .manager(name: "TaskManager", dependencies: [.target(name: "Models"), .target(name: "CASManager"), .target(name: "TelemetryManager")]),
        
        //        .manager(name: "DateManager", dependencies: [.target(name: "Models)"), .target(name: "")),
        //        .manager(name: "TelemetryManager", dependencies: [.target(name: "Models")]),
        //        .manager(name: "TaskManager", dependencies: [.target(name: "Models"), .target(name: "CASManager")]),
        //        .manager(name: "CASManager", dependencies: [.target(name: "Models"), .target(name: "BlockSet")]),
        //        .manager(name: "CASManager", dependencies: [.target(name: "Models"), .target(name: "BlockSet")]),
        //        .manager(name: "CASManager", dependencies: [.target(name: "Models"), .target(name: "BlockSet")]),
        
        //        .moduleTests(name: "Managers", dependencies: [.target(name: "Managers"), .target(name: "BlockSet"), .target(name: "Models")]),
        //            .module(name: "UIComponents", dependencies: [.target(name: "Models")]), /*.target(name: "Managers")]),*/
        //        .module(name: "Views", dependencies: [.target(name: "Models"), .target(name: "Managers"), .target(name: "UIComponents")]),
        //            .moduleView(
        //                name: "ProfileView",
        //                dependencies: [
        //                    .target(name: "Models"),
        //                    //                .target(name: "Managers"),
        //                    .target(name: "UIComponents"),
        //                    .target(name: "PaywallView")
        //                ]
        //            ),
        //        .moduleView(
        //            name: "CalendarView",
        //            dependencies: [
        //                .target(name: "Models"),
        //                //                .target(name: "Managers"),
        //                .target(name: "UIComponents"),
        //                .target(name: "PaywallView")
        //            ]
        //        ),
        //        .moduleView(
        //            name: "TaskView",
        //            dependencies: [
        //                .target(name: "Models"),
        //                //                .target(name: "Managers"),
        //                .target(name: "UIComponents"),
        //                .target(name: "PaywallView")
        //            ]
        //        ),
        //        .moduleView(
        //            name: "ListView",
        //            dependencies: [
        //                .target(name: "Models"),
        //                //                .target(name: "Managers"),
        //                .target(name: "UIComponents"),
        //                .target(name: "TaskView")
        //            ]
        //        ),
        //        .moduleView(
        //            name: "MainView",
        //            dependencies: [
        //                .target(name: "Models"),
        //                //                .target(name: "Managers"),
        //                .target(name: "UIComponents"),
        //                .target(name: "CalendarView"),
        //                .target(name: "ListView"),
        //                .target(name: "TaskView"),
        //                .target(name: "ProfileView"),
        //                .target(name: "PaywallView")
        //            ]
        //        ),
        
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
                    )
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
                    )
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
    //    static func module(name: String, dependencies: [TargetDependency] = []) -> Target {
    //        var resources: [ResourceFileElement] = []
    //
    //        if name != "BlockSet" {
    //            resources.append("Tasker/Modules/\(name)/Resources/**")
    //        }
    //
    //        return .target(
    //            name: name,
    //            destinations: App.destinations,
    //            product: .framework,
    //            bundleId: App.bundleId + "." + name,
    //            deploymentTargets: App.deploymentTargets,
    //            sources: ["Tasker/Modules/\(name)/**"],
    //            resources: .resources(resources),
    //            dependencies: dependencies,
    //            settings: .settings(defaultSettings: .recommended)
    //        )
    //    }
    //
    static func module(_ module: Modules, dependencies: [TargetDependency] = []) -> Target {
        var resources: [ResourceFileElement] = []
        
        if module != .blockSet {
            resources.append("\(module.resourcesPath)")
        }
        
        return .target(
            name: module.name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + module.name,
            deploymentTargets: App.deploymentTargets,
            sources: ["\(module.sourcesPath)"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(defaultSettings: .recommended)
        )
    }
    
    static func moduleTests(_ module: Modules, dependencies: [TargetDependency] = []) -> Target {
        .target(
            name: "\(module.name)Tests",
            destinations: App.destinations,
            product: .unitTests,
            bundleId: App.bundleId + "." + module.name + ".Tests",
            deploymentTargets: App.deploymentTargets,
            infoPlist: .default,
            sources: ["\(module.sourcesPath)"],
            dependencies: dependencies
        )
    }
    
    static func moduleView(_ module: Modules, dependencies: [TargetDependency] = []) -> Target {
        
        var resources: [ResourceFileElement] = []
        
        resources.append("\(module.resourcesPath)")
        
        return .target(
            name: module.name,
            destinations: App.destinations,
            product: .framework,
            bundleId: App.bundleId + "." + module.name,
            deploymentTargets: App.deploymentTargets,
            sources: ["\(module.sourcesPath)"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(base: .init().merging(
                [
                    "ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": "NO",
                    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "NO"
                ]
            ).otherSwiftFlags(.longTypeCheckingFlags)
            )
        )
    }
}

extension SettingsDictionary {
    func setProjectVersions() -> SettingsDictionary {
        let currentProjectVersion = App.version
        let markettingVersion = App.version
        
        return appleGenericVersioningSystem().merging([
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: currentProjectVersion),
            "MARKETING_VERSION": SettingValue(stringLiteral: markettingVersion),
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
