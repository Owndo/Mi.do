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
            dependencies: [.target(name: Modules.appView.name),],
            settings: .settings(
                base: [:],
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "PRODUCT_BUNDLE_IDENTIFIER": "mido.robocode.debug"
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "PRODUCT_BUNDLE_IDENTIFIER": "mido.robocode"
                        ]
                    )
                ]
            )
        ),
        .module(.blockSet),
        .module(.blockSetTests, dependencies: [.target(name: Modules.blockSet.name)]),
        .module(.models, dependencies: [.target(name: Modules.blockSet.name)]),
        //MARK: - Config file
        .module(.config),
        //MARK: - Managers
        
        //MARK: - Delegate
            .module(.appDelegate),
        
        //MARK: - Telemetry manager
        .module(.telemetry,
                dependencies: [
                    .target(name: Modules.models.name),
                    .target(
                        name: Modules.customErrors.name
                    ),
                    .external(name: "PostHog")
                ]
               ),
        
        //MARK: - Errors
        .module(.customErrors),
        
        //MARK: - Permission manager
        .module(.permissionManager,
                dependencies: [
                    .target(name: Modules.customErrors.name),
                    .target(name: Modules.telemetry.name)
                ]
               ),
        
        //MARK: - Subscription manager
        .module(.subscriptionManager),
        
        //MARK: - Cas manager
        .module(.cas,
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
        .module(.taskManager,
                dependencies: [
                    .target(name: Modules.cas.name),
                    .target(name: Modules.dateManager.name),
                    .target(name: Modules.notificationManager.name)
                ]
               ),
        .module(
            .taskManagerTests,
            dependencies: [
                .target(name: Modules.taskManager.name),
                .target(name: Modules.dependencyManager.name),
            ]
        ),
        
        //MARK: - Date manager
        .module(.dateManager,
                dependencies: [
                    .target(
                        name: Modules.profileManager.name
                    ),
                    .target(name: Modules.telemetry.name)
                ]
               ),
        
        //MARK: - Notification manager
        .module(.notificationManager,
                dependencies: [
                    .target(name: Modules.cas.name),
                    .target(name: Modules.dateManager.name),
                    .target(name: Modules.storageManager.name),
                    .target(name: Modules.subscriptionManager.name),
                    .target(name: Modules.permissionManager.name)
                ]
               ),
        
        //MARK: - Recorder
        .module(.recorderManager,
                dependencies: [
                    .target(name: Modules.telemetry.name),
                    .target(name: Modules.magic.name),
                    .target(name: Modules.dateManager.name)
                ]
               ),
        
        //MARK: - Magic manager
        .module(.magic, dependencies: [.target(name: Modules.dateManager.name)]),
        
        //MARK: - Player manager
        .module(.playerManager,
                dependencies: [.target(name: Modules.models.name), .target(name: Modules.cas.name)]
               ),
        
        //MARK: - Appearance manager
        .module(.appearanceManager, dependencies: [.target(name: Modules.profileManager.name)]),
        
        //MARK: - Onboarding
        .module(.onboardingManager,
                dependencies: [
                    .target(name: Modules.config.name),
                    .target(name: Modules.profileManager.name),
                    .target(name: Modules.taskManager.name),
                    .target(name: Modules.dateManager.name)
                ]
               ),
        
        //MARK: - Welcome manager
        .module(.welcomeManager,
                dependencies: [
                    .target(name: Modules.config.name),
                    .target(name: Modules.profileManager.name),
                    .target(name: Modules.taskManager.name),
                    .target(name: Modules.dateManager.name)
                ]
               ),
        
        //MARK: - Video manager
        .module(.videoManager),
        
        //MARK: - Dependency
        .module(
            .dependencyManager,
            dependencies: [
                .target(name: Modules.appearanceManager.name),
                .target(name: Modules.cas.name),
                .target(name: Modules.dateManager.name),
                .target(name: Modules.models.name),
                .target(name: Modules.notificationManager.name),
                .target(name: Modules.onboardingManager.name),
                .target(name: Modules.permissionManager.name),
                .target(name: Modules.playerManager.name),
                .target(name: Modules.profileManager.name),
                .target(name: Modules.recorderManager.name),
                .target(name: Modules.storageManager.name),
                .target(name: Modules.subscriptionManager.name),
                .target(name: Modules.taskManager.name),
                .target(name: Modules.telemetry.name)
            ]
        ),
        
        //MARK: - Views
        
            .moduleView(.uiComponents,
                        dependencies: [
                            .target(name: Modules.models.name),
                            .target(
                                name: Modules.appearanceManager.name
                            )
                        ]
                       ),
        
        //MARK: - PaywallView
        
            .moduleView(.paywallView,
                        dependencies: [
                            .target(name: Modules.subscriptionManager.name),
                            .target(name: Modules.uiComponents.name),
                            .target(name: Modules.config.name)
                        ]
                       ),
        
        //MARK: - Calendar
        
            .moduleView(.calendarView,
                        dependencies: [
                            .target(name: Modules.models.name),
                            .target(name: Modules.dateManager.name),
                            .target(name: Modules.taskManager.name),
                            .target(name: Modules.appearanceManager.name),
                            .target(name: Modules.telemetry.name),
                            .target(name: Modules.uiComponents.name)
                        ]
                       ),
        
        //MARK: - TaskView
        
            .moduleView(.taskView,
                        dependencies: [
                            .target(name: Modules.models.name),
                            .target(name: Modules.appearanceManager.name),
                            .target(name: Modules.taskManager.name),
                            .target(name: Modules.profileManager.name),
                            .target(name: Modules.dateManager.name),
                            .target(name: Modules.playerManager.name),
                            .target(name: Modules.recorderManager.name),
                            .target(name: Modules.permissionManager.name),
                            .target(name: Modules.storageManager.name),
                            .target(name: Modules.telemetry.name),
                            .target(name: Modules.paywallView.name),
                            .target(name: Modules.uiComponents.name)
                        ]
                       ),
        
        //MARK: - HistoryView
        
            .moduleView(.historyView, dependencies: [.target(name: Modules.uiComponents.name)]),
        
        //MARK: - ArticlesView
        .moduleView(.articlesView, dependencies: [.target(name: Modules.uiComponents.name)]),
        
        //MARK: - AppearanceView
        .moduleView(.appearanceView, dependencies: [.target(name: Modules.appearanceManager.name), .target(name: Modules.uiComponents.name)]),
        
        //MARK: - SettingsView
        .moduleView(.settingsView,
                    dependencies: [
                        .target(name: Modules.dateManager.name),
                        .target(name: Modules.telemetry.name),
                        .target(name: Modules.appearanceManager.name),
                        .target(name: Modules.uiComponents.name),
                        .target(name: Modules.config.name)
                    ]
                   ),
        
        //MARK: - ProfileView
        .moduleView(.profileView,
                    dependencies: [
                        .target(name: Modules.profileManager.name),
                        .target(name: Modules.taskManager.name),
                        .target(name: Modules.dateManager.name),
                        .target(name: Modules.appearanceManager.name),
                        .target(name: Modules.subscriptionManager.name),
                        .target(name: Modules.paywallView.name),
                        .target(name: Modules.settingsView.name),
                        .target(name: Modules.appearanceView.name),
                        .target(name: Modules.articlesView.name),
                        .target(name: Modules.historyView.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
        //MARK: - ListView
        .moduleView(.listView,
                    dependencies: [
                        .target(name: Modules.appearanceManager.name),
                        .target(name: Modules.dateManager.name),
                        .target(name: Modules.profileManager.name),
                        .target(name: Modules.playerManager.name),
                        .target(name: Modules.notificationManager.name),
                        .target(name: Modules.storageManager.name),
                        .target(name: Modules.recorderManager.name),
                        .target(name: Modules.taskManager.name),
                        .target(name: Modules.taskView.name),
                        .target(name: Modules.telemetry.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
        //MARK: - OnboardingView
        .moduleView(.onboaringView,
                    dependencies: [
                        .target(name: Modules.onboardingManager.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
            .moduleView(.videoPlayerView,
                        dependencies: [
                            .target(name: Modules.videoManager.name)
                        ]
                       ),
        
        //MARK: - WelcomeView
        .moduleView(.welcomeView,
                    dependencies: [
                        .target(name: Modules.welcomeManager.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
        //MARK: - NotesView
        .moduleView(.notesView,
                    dependencies: [
                        .target(name: Modules.appearanceManager.name),
                        .target(name: Modules.profileManager.name),
                        .target(name: Modules.telemetry.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
        //MARK: - MainView
        .moduleView(.mainView,
                    dependencies: [
                        // Managers
                        .target(name: Modules.appDelegate.name),
                        .target(name: Modules.appearanceManager.name),
                        .target(name: Modules.customErrors.name),
                        .target(name: Modules.dateManager.name),
                        .target(name: Modules.onboardingManager.name),
                        .target(name: Modules.permissionManager.name),
                        .target(name: Modules.profileManager.name),
                        .target(name: Modules.recorderManager.name),
                        .target(name: Modules.taskManager.name),
                        .target(name: Modules.subscriptionManager.name),
                        .target(name: Modules.welcomeManager.name),
                        
                        // Views
                        .target(name: Modules.calendarView.name),
                        .target(name: Modules.onboaringView.name),
                        .target(name: Modules.listView.name),
                        .target(name: Modules.notesView.name),
                        .target(name: Modules.paywallView.name),
                        .target(name: Modules.profileView.name),
                        .target(name: Modules.taskView.name),
                        .target(name: Modules.uiComponents.name),
                        .target(name: Modules.welcomeView.name)
                    ]
                   ),
        .moduleView(.launchView,
                    dependencies: [
                        .target(name: Modules.videoManager.name),
                        .target(name: Modules.videoPlayerView.name),
                        .target(name: Modules.uiComponents.name)
                    ]
                   ),
        
        //MARK: - AppView
        .moduleView(
            .appView,
            dependencies: [
                .target(name: Modules.mainView.name),
                .target(name: Modules.launchView.name),
                
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
                        options: .options(storeKitConfigurationPath: "Tasker/Modules/Managers/SubscriptionManager/Mi.storekit"),
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
    
    //MARK: - Module
    static func module(_ module: Modules, dependencies: [TargetDependency] = []) -> Target {
        var resources: [ResourceFileElement] = []
        
        if module != .blockSet {
            resources.append("\(module.resourcesPath)")
        }
        
        return .target(
            name: module.name,
            destinations: App.destinations,
            product: module.kind == .tests ? .unitTests : .framework,
            bundleId: App.bundleId + "." + module.name,
            deploymentTargets: App.deploymentTargets,
            sources: ["\(module.sourcesPath)"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(defaultSettings: .recommended)
        )
    }
    
    //MARK: - ModuleView
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

//MARK: - Flag for check time "View"
extension Array where Element == String {
    static let longTypeCheckingFlags = [
        "-Xfrontend",
        "-warn-long-function-bodies=100",
        "-Xfrontend",
        "-warn-long-expression-type-checking=100"
    ]
}
