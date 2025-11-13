//
//  DependenciesManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/11/25.
//

import Foundation

public final class DependenciesManager: DependenciesManagerProtocol {
    //MARK: - Cas manager
    
    public let casManager: CASManagerProtocol
    
    //MARK: - Profile manager
    
    public let profileManager: ProfileManagerProtocol
    
    //MARK: - Task manager
    
    public let taskManager: TaskManagerProtocol
    
    //MARK: - Date manager
    
    public let dateManager: DateManagerProtocol
    
    //MARK: - Onboarding manager
    
    public lazy var onboardingManager: OnboardingManagerProtocol = OnboardingManager(
        profileManager: profileManager,
        taskManager: taskManager,
        dateManager: dateManager
    )
    
    //MARK: - Storage manager
    
    public lazy var storageManager: StorageManagerProtocol = StorageManager(casManager: casManager)
    
    //MARK: - Player manager
    
    public lazy var playerManager: PlayerManagerProtocol = PlayerManager(storageManager: storageManager)
    
  
    //MARK: - Permission manager
    
    public lazy var permissionManager: PermissionProtocol = PermissionManager(telemetryManager: telemetryManager)
    
    //MARK: - Recorder manager
    
    public lazy var recorderManager: RecorderManagerProtocol = RecorderManager(
        telemetryManager: telemetryManager,
        dateManager: dateManager
    )
   
    
    //MARK: - Notification manager
    
    public lazy var notificationManager: NotificationManagerProtocol = NotificationManager(
        subscriptionManager: subscriptionManager,
        storageManager: storageManager,
        dateManager: dateManager
    )
    
    //MARK: - Appearance manager
    
    public lazy var appearanceManager: AppearanceManagerProtocol = AppearanceManager(profileManager: profileManager)
 
    //MARK: - Subscription manager
    
    public lazy var subscriptionManager: SubscriptionManagerProtocol = SubscriptionManager()
    
    //MARK: - Telemetry manager
    
    public lazy var telemetryManager: TelemetryManagerProtocol = TelemetryManager.createTelemetryManager()
    
    //MARK: - Init
    
    private init(
        casManager: CASManagerProtocol,
        profileManager: ProfileManagerProtocol,
        dateManager: DateManagerProtocol,
        taskManager: TaskManagerProtocol
    ) {
        self.casManager = casManager
        self.profileManager = profileManager
        self.dateManager = dateManager
        self.taskManager = taskManager
    }
    
    public static func createDependencies() async -> DependenciesManagerProtocol {
        let cas = await CASManager.createCASManager()
        
        let storageManager = StorageManager(casManager: cas)
        let telemetryManager = TelemetryManager.createTelemetryManager()
        let subscriptionManager = SubscriptionManager()
        
        let profileManager = await ProfileManager.createProfileManager(casManager: cas)
        let dateManager = await DateManager.createDateManager(profileManager: profileManager, telemetryManager: telemetryManager)
        
        let notificationManager = NotificationManager(subscriptionManager: subscriptionManager, storageManager: storageManager, dateManager: dateManager)

        let taskManager = await TaskManager.createTaskManager(casManager: cas, dateManager: dateManager, notificationManager: notificationManager, telemetryManager: telemetryManager)
        
        let dependencies = DependenciesManager(
            casManager: cas,
            profileManager: profileManager,
            dateManager: dateManager,
            taskManager: taskManager
        )
        
        return dependencies
    }
    
    public static func createDependenciesForTesting() async -> DependenciesManagerProtocol {
        let cas = MockCas.createCASManager()
        
        let telemetryManager = MockTelemetryManager()
        
        let profileManager = await ProfileManager.createProfileManager(casManager: cas)
        let dateManager = await DateManager.createDateManager(profileManager: profileManager, telemetryManager: telemetryManager)
        
        let notificationManager = MockNotificationManager()

        let taskManager = await TaskManager.createTaskManager(casManager: cas, dateManager: dateManager, notificationManager: notificationManager, telemetryManager: telemetryManager)
        
        
        let dependencies = DependenciesManager(
            casManager: cas,
            profileManager: profileManager,
            dateManager: dateManager,
            taskManager: taskManager
        )
        
        return dependencies
    }
}

public protocol DependenciesManagerProtocol {
    var casManager: CASManagerProtocol { get }
    var profileManager: ProfileManagerProtocol { get }
    var taskManager: TaskManagerProtocol { get }
    var onboardingManager: OnboardingManagerProtocol { get }
    var playerManager: PlayerManagerProtocol { get }
    var recorderManager: RecorderManagerProtocol { get }
    var dateManager: DateManagerProtocol { get }
    var permissionManager: PermissionProtocol { get }
    var notificationManager: NotificationManagerProtocol { get }
    var storageManager: StorageManagerProtocol { get }
    var appearanceManager: AppearanceManagerProtocol { get }
    var telemetryManager: TelemetryManagerProtocol { get }
    var subscriptionManager: SubscriptionManagerProtocol { get }
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
//        var manager: DependenciesManagerProtocol
//    }
//}
//
//@propertyWrapper
//public final class Injected<T> {
//    private var keyPath: KeyPath<DependenciesManagerProtocol, T>
//    private var cached: T?
//    
//    public init(_ keyPath: KeyPath<DependenciesManagerProtocol, T>) {
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
