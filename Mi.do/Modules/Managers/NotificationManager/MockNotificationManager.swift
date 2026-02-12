//
//  MockNotificationManager.swift
//  Managers
//
//  Created by Rodion Akhmedov on 10/27/25.
//

import Foundation
import Models

public final class MockNotificationManager: NotificationManagerProtocol {
    // MARK: - Stored properties to verify calls
    
    private(set) var createdNotifications: [[UITaskModel]] = []
    private(set) var removeAllEventsCalled = false
    private(set) var checkPermissionCalled = false
    private(set) var permissionGranted: Bool = true
    
    public init() {}
    
    public var alert: AlertModel? = nil
    
    public func createNotification(tasks: [UITaskModel]) async {
        createdNotifications.append(tasks)
    }
    
    public func removeAllEvents() {
        removeAllEventsCalled = true
    }
    
    public func checkPermission() async {
        checkPermissionCalled = true
    }
}
