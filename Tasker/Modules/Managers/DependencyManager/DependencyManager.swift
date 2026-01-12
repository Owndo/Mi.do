//
//  DependencyManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/11/25.
//

import Foundation
import AppearanceManager
import CASManager
import DateManager
import NotificationManager
import OnboardingManager
import PermissionManager
import PlayerManager
import ProfileManager
import RecorderManager
import ProfileManager
import StorageManager
import SubscriptionManager
import TaskManager
import TelemetryManager

public final class DependencyManager: DependencyManagerProtocol {
    //MARK: - Cas manager
    
    public let casManager: CASManagerProtocol
    
    //MARK: - Date manager
    
    public let dateManager: DateManagerProtocol
    
    //MARK: - Profile manager
    
    public let profileManager: ProfileManagerProtocol
    
    //MARK: - Task manager
    
    public let taskManager: TaskManagerProtocol
    
    //MARK: - Onboarding manager
    
    public lazy var onboardingManager: OnboardingManagerProtocol = OnboardingManager.createManager(dateManager: dateManager, profileManager: profileManager, taskManager: taskManager)
    
    //MARK: - Storage manager
    
    public lazy var storageManager: StorageManagerProtocol = StorageManager.createStorageManager(casManager: casManager)
    
    //MARK: - Player manager
    
    public lazy var playerManager: PlayerManagerProtocol = PlayerManager.createPlayerManager(storageManager: storageManager)
    
    
    //MARK: - Permission manager
    
    public lazy var permissionManager: PermissionProtocol = PermissionManager.createPermissionManager()
    
    //MARK: - Recorder manager
    
    public lazy var recorderManager: RecorderManagerProtocol = RecorderManager.createRecorderManager(dateManager: dateManager)
    
    
    //MARK: - Notification manager
    
    public let notificationManager: NotificationManagerProtocol
    
    //MARK: - Appearance manager
    
    public lazy var appearanceManager: AppearanceManagerProtocol = AppearanceManager.createAppearanceManager(profileManager: profileManager)
    
    //MARK: - Subscription manager
    
    public let subscriptionManager: SubscriptionManagerProtocol
    
    //MARK: - Telemetry manager
    
    public lazy var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    //MARK: - Init
    
    private init(
        casManager: CASManagerProtocol,
        dateManager: DateManagerProtocol,
        profileManager: ProfileManagerProtocol,
        taskManager: TaskManagerProtocol,
        notificationManager: NotificationManagerProtocol,
        subscriptionManager: SubscriptionManagerProtocol
    ) {
        self.casManager = casManager
        self.profileManager = profileManager
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.notificationManager = notificationManager
        self.subscriptionManager = subscriptionManager
    }
    
    //MARK: - Create Manager
    
    public static func createDependencies() async -> DependencyManagerProtocol {
        let casManager = await CASManager.createCASManager()
        
        let storageManager = StorageManager.createStorageManager(casManager: casManager)
        
        let profileManager = await ProfileManager.createProfileManager(casManager: casManager)
        let dateManager = await DateManager.createDateManager(profileManager: profileManager)
        
        let notificationManager = await NotificationManager.createNotificationManager(profileManager: profileManager, storageManager: storageManager)
        
        let taskManager = await TaskManager.createTaskManager(casManager: casManager, dateManager: dateManager, notificationManager: notificationManager)
        let subscriptionManager = await SubscriptionManager.createSubscriptionManager()
        
        let dependencies = DependencyManager(
            casManager: casManager,
            dateManager: dateManager,
            profileManager: profileManager,
            taskManager: taskManager,
            notificationManager: notificationManager,
            subscriptionManager: subscriptionManager
        )
        
        return dependencies
    }
    
    public static func createDependenciesForTesting() async -> DependencyManagerProtocol {
        let casManager = MockCas.createCASManager()
        
        let profileManager = await ProfileManager.createProfileManager(casManager: casManager)
        let dateManager = await DateManager.createDateManager(profileManager: profileManager)
        
        let notificationManager = MockNotificationManager()
        
        let taskManager = await TaskManager.createTaskManager(casManager: casManager, dateManager: dateManager, notificationManager: notificationManager)
        let subscriptionManager = SubscriptionManager.createMockSubscriptionManager()
        
        
        let dependencies = DependencyManager(
            casManager: casManager,
            dateManager: dateManager,
            profileManager: profileManager,
            taskManager: taskManager,
            notificationManager: notificationManager,
            subscriptionManager: subscriptionManager
        )
        
        return dependencies
    }
}

//public protocol DependencyRegister {
//    var manager: DependenciesManagerProtocol { get set }
//}

//public enum DependencyContext {
//    private static var _current: DependencyRegister?
//
//    public static var current: DependencyRegister {
//        get {
//            guard let _current = _current else {
//                fatalError("DependencyContext not initialized. Call DependencyContext.initialize() first")
//            }
//            return _current
//        }
//    }
//
//    public static func initialize() async {
//        let manager = await DependenciesManager.createDependencies()
//        _current = DefaultRegister(manager: manager)
//    }
//
//    public static func setCustom(_ register: DependencyRegister) {
//        _current = register
//    }
//
//    private struct DefaultRegister: DependencyRegister {
//        var manager: DependencyManagerProtocol
//    }
//}
//
//@propertyWrapper
//public final class Injected<T> {
//    private var keyPath: KeyPath<DependencyManagerProtocol, T>
//    private var cached: T?
//
//    public init(_ keyPath: KeyPath<DependencyManagerProtocol, T>) {
//        self.keyPath = keyPath
//    }
//
//    public var wrappedValue: T {
//        get {
//            if let cached = cached {
//                return cached
//            }
//            let resolved = DependencyContext.current.manager[keyPath: keyPath]
//            cached = resolved
//            return resolved
//        }
//        set {
//            cached = newValue
//        }
//    }
//}
