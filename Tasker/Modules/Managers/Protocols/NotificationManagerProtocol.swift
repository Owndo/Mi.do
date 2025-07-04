//
//  NotificationManagerProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation
import Models
import UserNotifications

public protocol NotificationManagerProtocol {
    var alert: AlertModel? { get }
    var notificationCenter: UNUserNotificationCenter { get set }
    
    func createNotification() async
    func removeAllEvents()
    func checkPermission() async
}
