//
//  ManagersTests.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/2/25.
//

import Testing
import Managers
import Models
import Foundation
import NotificationCenter

struct ManagersTests {

    @Test func check() async throws {
        @Injected(\.taskManager) var taskManager
        @Injected(\.notificationManager) var notificationManager
        
//        taskManager.createNotification(createSingleTask())
        
        #expect(
            2 == 2
        )
    }
}
