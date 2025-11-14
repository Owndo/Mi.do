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

@Test
func createTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    #expect(activeTasks.first?.id == task.id)
    
    let task1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task1)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 2)
}

//MARK: - Fetch empty, add task, change date and fetch again, add task, fetch again

@Test
func fetchEmptyTasks() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    var activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.isEmpty, "Before store task, active tasks should be empty")
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
    
    manager.dependenciesManager.dateManager.selectedDateChange(nextDay)
    
    try await Task.sleep(for: .seconds(0.1))
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.isEmpty, "After changing date, active tasks should be empty")
    
    let newTask1 = UITaskModel(.initial(TaskModel(title: "New task 1", notificationDate: nextDay.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(newTask1)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and update task

@Test
func createAndUpdateTask() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    task.description = "New task for test"
    
    try await manager.taskManager.saveTask(task)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}

//MARK: - Create and delete task

@Test
func createAndDeleteTaskModel() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.deleteTask(task: task, deleteCompletely: true)
    
    activeTasks = await manager.taskManager.activeTasks
    
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
    
    let models = await manager.taskManager.activeTasks
    
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
    
    let models = await manager.taskManager.activeTasks
    
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
    
    let models = await manager.taskManager.activeTasks
    
    print("⏱ Duration: \(duration)")
    #expect(models.count == 10000)
}

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

//MARK: - Add test for checkmark

@Test
func checkMarkTapped() async throws {
    let manager = await TaskManagerTest.createTestsManager()
    
    let task = UITaskModel(.initial(TaskModel(title: "New task", notificationDate: Date.now.timeIntervalSince1970)))
    
    try await manager.taskManager.saveTask(task)
    
    var activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 0)
    
    var completeTasks = await manager.taskManager.completedTasks
    
    #expect(completeTasks.count == 1)
    
    try await manager.taskManager.checkMarkTapped(task: task)
    
    completeTasks = await manager.taskManager.completedTasks
    
    #expect(completeTasks.isEmpty)
    
    activeTasks = await manager.taskManager.activeTasks
    
    #expect(activeTasks.count == 1)
}
