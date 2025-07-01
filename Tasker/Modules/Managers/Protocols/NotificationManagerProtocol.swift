//
//  NotificationManagerProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 6/30/25.
//

import Foundation
import Models

public protocol NotificationManagerProtocol {
    var alert: AlertModel? { get }
    
    func createNotification(_ task: TaskModel)
    func removeAllEvents()
    func checkPermission() async
}
