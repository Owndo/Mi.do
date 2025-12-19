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
    
    var folder: String {
        switch self {
        case .feature:
            return "Tasker/Modules"
        case .manager:
            return "Tasker/Modules/Managers"
        case .view:
            return "Tasker/Modules/Views"
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
    
    case customErrors = "CustomErrors"
    
    case subscriptionManager = "SubscriptionManager"
    case telemetry = "TelemetryManager"
    
    //MARK: - Views
    case uiComponents = "UIComponents"
    case paywallView = "PaywallView"
    case taskView = "TaskView"
    case calendarView = "CalendarView"
    
    private var kind: ModuleKind {
        switch self {
        case .blockSet, .models, .config:
            return .feature
        case .uiComponents, .paywallView, .taskView, .calendarView:
            return .view
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
