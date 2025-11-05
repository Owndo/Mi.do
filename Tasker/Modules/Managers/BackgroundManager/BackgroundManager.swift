//
//  BackgroundManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 9/15/25.
//

import Foundation
import BackgroundTasks

public final class BackgroundManager {
    private var taskManager: TaskManagerProtocol
    
    public init(taskManager: TaskManagerProtocol) {
        self.taskManager = taskManager
    }
    
    public func scheduleAppRefreshTask() async {
        let request = BGAppRefreshTaskRequest(identifier: "mido.robocode.updateNotificationsAndSync")
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch let error {
            print("BGTaskScheduler error:", error)
        }
    }
    
    public func backgroundUpdate() async {
        await taskManager.updateNotifications()
//        try? await casManager.syncCases()
    }
}
