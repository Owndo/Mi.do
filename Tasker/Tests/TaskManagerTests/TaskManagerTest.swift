//
//  CasManagerTests.swift
//  Tests
//
//  Created by Rodion Akhmedov on 10/27/25.
//

import BlockSet
import Foundation
import Models
import TaskManager
import Testing

struct TaskManagerTest {
    var taskManager: TaskManagerProtocol
    
    private init(taskManager: TaskManagerProtocol) {
        self.taskManager = taskManager
    }
    
    static func createTestsManager() async -> TaskManagerTest {
        let taskManager = TaskManager.createMockTaskManager()
        
        let test = TaskManagerTest(taskManager: taskManager)
        
        return test
    }
}

//MARK: - Task model

@Test
func createTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let date = Date()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
    
    #expect(activeTasks.first?.id == task.id)
    
    let task1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task1)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 2)
}

//MARK: - Fetch empty, add task, change date and fetch again, add task, fetch again

@Test
func fetchEmptyTasks() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let date = Date()
    
    var activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.isEmpty, "Before store task, active tasks should be empty")
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
    
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date)!
    
    try await Task.sleep(for: .seconds(0.1))
    
    activeTasks = await manager.taskManager.activeTasks(for: nextDay)

    #expect(activeTasks.isEmpty, "After changing date, active tasks should be empty")
    
    let newTask1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: nextDay.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(newTask1)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and update task

@Test
func createAndUpdateTask() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let date = Date()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
    
    task.description = "New task for test"
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and delete task

@Test
func createAndDeleteTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let date = Date()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.deleteTask(task: task, deleteCompletely: true)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 0)
}

//MARK: - Check multicreate

//MARK: - 100

@Test
func create100models() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let clock = ContinuousClock()
    let duration = try await clock.measure {
        try await generateModels(count: 100, taskManager: manager.taskManager)
    }
    
    let models = await manager.taskManager.tasks
    
    print("⏱ Duration: \(duration)")
    #expect(models.count == 100)
}

//MARK: - 1000

@Test
func create1000models() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let clock = ContinuousClock()
    let duration = try await clock.measure {
        try await generateModels(count: 1000, taskManager: manager.taskManager)
    }
    
    let models = await manager.taskManager.tasks
    
    print("⏱ Duration: \(duration)")
    #expect(models.count == 1000)
}

//MARK: - 10000

@Test
func create10000models() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let clock = ContinuousClock()
    let duration = try await clock.measure {
        try await generateModels(count: 10000, taskManager: manager.taskManager)
    }
    
    let models = await manager.taskManager.tasks
    
    print("⏱ Duration: \(duration)")
    #expect(models.count == 10000)
}

//MARK: - Add test for checkmark

@Test
func checkMarkTapped() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let date = Date()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 0)
    
    var completeTasks = await manager.taskManager.completedTasks(for: date)
    
    #expect(completeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    completeTasks = await manager.taskManager.completedTasks(for: date)
    
    #expect(completeTasks.isEmpty)
    
    activeTasks = await manager.taskManager.activeTasks(for: date)
    
    #expect(activeTasks.count == 1)
}

//MARK: - Tasks For a week

func testTasksForAWeek() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let date = Date()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970)))
    let task1 = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970 + 10)))
    let task2 = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970 + 20)))
    let task3 = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970 + 30)))
    let task4 = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: date.timeIntervalSince1970 + 40)))
    
    try await manager.taskManager.saveTask(task)
    
    let tasks = manager.taskManager.downloadWeekTasks(date: date)
    
}

//MARK: - Generate Models

private func generateModels(count: Int, taskManager: TaskManagerProtocol) async throws {
    
    try await withThrowingTaskGroup(of: Void.self) { group in
        for i in 0..<count {
            group.addTask {
                let model = UITaskModel(
                    .initial(
                        TaskModel(
                            title: "Title - \(i)",
                            notificationDate: Date.now.timeIntervalSince1970
                        )
                    )
                )
                
                try await taskManager.saveTask(model)
            }
        }
        
        try await group.waitForAll()
    }
}
