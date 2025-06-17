//
//  DependenciesManager.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/11/25.
//

import Foundation

final class DependenciesManager: DependenciesManagerProtocol {
    lazy var casManager: CASManagerProtocol = {
#if targetEnvironment(simulator)
        return MockCas()
#else
        return CASManager()
#endif
    }()
    
    lazy var playerManager: PlayerManagerProtocol = PlayerManager()
    lazy var recorderManager: RecorderManagerProtocol = RecorderManager()
    lazy var dateManager: DateManagerProtocol = DateManager()
    lazy var permissionManager: PermissionProtocol = PermissionManager()
    lazy var taskManager: TaskManagerProtocol = TaskManager()
}

public protocol DependenciesManagerProtocol {
    var casManager: CASManagerProtocol { get }
    var playerManager: PlayerManagerProtocol { get }
    var recorderManager: RecorderManagerProtocol { get }
    var dateManager: DateManagerProtocol { get }
    var permissionManager: PermissionProtocol { get }
    var taskManager: TaskManagerProtocol { get }
}

public protocol DependencyRegister {
    var manager: DependenciesManagerProtocol { get set }
}

public enum DependependencyContext {
    private static var _current: DependencyRegister = DefaultRegister()
    
    public static var current: DependencyRegister {
        get {
            _current
        }
        set {
            _current = newValue
        }
    }
    
    private struct DefaultRegister: DependencyRegister {
        var manager: DependenciesManagerProtocol = DependenciesManager()
    }
}

@propertyWrapper
public final class Injected<T> {
    private var keyPath: KeyPath<DependenciesManagerProtocol, T>
    private var cashed: T?
    
    public init(_ keyPath: KeyPath<DependenciesManagerProtocol, T>) {
        self.keyPath = keyPath
    }
    
    public var wrappedValue: T {
        get {
            guard let cashedValue = cashed else {
                let resolved = DependependencyContext.current.manager[keyPath: keyPath]
                return resolved
            }
            return cashedValue
        }
        
        set {
            cashed = newValue
        }
    }
}
