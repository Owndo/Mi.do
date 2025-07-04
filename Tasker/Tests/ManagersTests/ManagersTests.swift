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
    
    
    func createSingleTask() -> TaskModel {
        TaskModel(
            id: "81402099-660D-4AB9-9BAA-047099E2E80A",
            title: "New Task",
            info: "",
            createDate: 1751482002.62469,
            notificationDate: 1751482800.0,
            voiceMode: true,
            markAsDeleted: false,
            repeatTask: RepeatTask.daily,
            dayOfWeek: [DayOfWeek(id: UUID(), name: "Sun", value: false), DayOfWeek(id: UUID(), name: "Mon", value: false), DayOfWeek(id: UUID(), name: "Tue", value: false), DayOfWeek(id: UUID(), name: "Wed", value: false), DayOfWeek(id: UUID(), name: "Thu", value: false), DayOfWeek(id: UUID(), name: "Fri", value: false), DayOfWeek(id: UUID(), name: "Sat", value: false)],
            done: [CompleteRecord(completedFor: 1751612400.0, timeMark: 1751481987.8940969), Models.CompleteRecord(completedFor: 1751698800.0, timeMark: 1751481987.8940969)],
            deleted: [],
            taskColor: Models.TaskColor.yellow
        )
    }

    @Test func check() async throws {
        @Injected(\.taskManager) var taskManager
        @Injected(\.notificationManager) var notificationManager
        
//        taskManager.createNotification(createSingleTask())
        
        #expect(
            2 == 2
        )
    }
}
