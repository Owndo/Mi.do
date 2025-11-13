//
//  CasManagerTests.swift
//  Tests
//
//  Created by Rodion Akhmedov on 10/27/25.
//

import Foundation
import Managers
import Models
import BlockSet
import Testing

struct TaskManagerTest {
    var dependenciesManager: DependenciesManagerProtocol
    var taskManager: TaskManagerProtocol
    
    private init(dependenciesManager: DependenciesManagerProtocol, taskManager: TaskManagerProtocol) {
        self.dependenciesManager = dependenciesManager
        self.taskManager = taskManager
    }
    
    static func createTestsManager() async -> TaskManagerTest {
        let dependenciesManager = await DependenciesManager.createDependenciesForTesting()
        
        let test = TaskManagerTest(
            dependenciesManager: dependenciesManager,
            taskManager: dependenciesManager.taskManager
        )
        
        return test
    }
}

//MARK: - Task model

@Test func createTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    #expect(activeTasks.first?.id == task.id)
    
    let task1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task1)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 2)
}

//MARK: - Fetch empty, add task, change date and fetch again, add task, fetch again

@Test func fetchEmptyTasks() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    var activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.isEmpty, "Before store task, active tasks should be empty")
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    manager.dependenciesManager.dateManager.selectedDateChange(nextDay)
    
    try await Task.sleep(for: .seconds(0.1))
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.isEmpty, "After changing date, active tasks should be empty")
    
    let newTask1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: nextDay.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(newTask1)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and update task

@Test func createAndUpdateTask() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    task.description = "New task for test"
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and delete task

@Test func createAndDeleteTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.deleteTask(task: task, deleteCompletely: true)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 0)
}

//MARK: - Add test for checkmark
@Test func checkMarkTapped() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 0)
    
    var completeTasks = manager.taskManager.completedTasks
    
    #expect(completeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    completeTasks = manager.taskManager.completedTasks
    
    #expect(completeTasks.isEmpty)
    
    activeTasks = manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}
