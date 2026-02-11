//
//  Modules.swift
//  ProjectDescriptionHelpers
//
//  Created by Rodion Akhmedov on 12/3/25.
//

import Foundation

public enum ModuleKind: String {
    case feature
    case manager
    case view
    case tests
    
    var folder: String {
        switch self {
        case .feature:
            return "Tasker/Modules"
        case .manager:
            return "Tasker/Modules/Managers"
        case .view:
            return "Tasker/Modules/Views"
        case .tests:
            return "Tasker/Tests"
        }
    }
}

public enum Modules: String {
    //MARK: - Modules
    case blockSet = "BlockSet"
    case models = "Models"
    case config = "ConfigurationFile"
    
    //MARK: - Managers
    
    case cas = "CASManager"
    case taskManager = "TaskManager"
    case profileManager = "ProfileManager"
    case storageManager = "StorageManager"
    case dateManager = "DateManager"
    case permissionManager = "PermissionManager"
    case notificationManager = "NotificationManager"
    case playerManager = "PlayerManager"
    case recorderManager = "RecorderManager"
    case magic = "MagicManager"
    case appearanceManager = "AppearanceManager"
    case appDelegate = "AppDelegate"
    case onboardingManager = "OnboardingManager"
    case videoManager = "VideoManager"
    case welcomeManager = "WelcomeManager"
    
    case customErrors = "CustomErrors"
    
    case subscriptionManager = "SubscriptionManager"
    case telemetry = "TelemetryManager"
    case dependencyManager = "DependencyManager"
    
    //MARK: - Views
    case uiComponents = "UIComponents"
    case paywallView = "PaywallView"
    case taskView = "TaskView"
    case calendarView = "CalendarView"
    case historyView = "HistoryView"
    case articlesView = "ArticlesView"
    case appearanceView = "AppearanceView"
    case settingsView = "SettingsView"
    case profileView = "ProfileView"
    case launchView = "LaunchView"
    case listView = "ListView"
    case onboaringView = "OnboardingView"
    case welcomeView = "WelcomeView"
    case notesView = "NotesView"
    case videoPlayerView = "VideoPlayerView"
    case mainView = "MainView"
    case appView = "AppView"
    
    //MARK: - Tests
    
    case blockSetTests = "BlockSetTests"
    case taskManagerTests = "TaskManagerTests"
    
    public var kind: ModuleKind {
        switch self {
        case .blockSet, .models, .config:
            return .feature
        case .uiComponents,
             .paywallView,
             .taskView,
             .calendarView,
             .historyView,
             .articlesView,
             .appearanceView,
             .settingsView,
             .profileView,
             .launchView,
             .listView,
             .onboaringView,
             .welcomeView,
             .videoPlayerView,
             .notesView,
             .mainView,
             .appView:
            return .view
        case .blockSetTests,
            .taskManagerTests:
            return .tests
        default:
            return .manager
        }
    }
    
    public var name: String {
        rawValue
    }
    
    public var sourcesPath: String {
        "\(kind.folder)/\(name)/**"
    }
    
    public var resourcesPath: String {
        "\(kind.folder)/\(name)/Resources/**"
    }
}
