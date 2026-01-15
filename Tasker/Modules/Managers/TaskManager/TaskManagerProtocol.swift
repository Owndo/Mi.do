//
//  TaskManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import Foundation
import Models

public protocol TaskManagerProtocol: Actor {
    var tasks: [String: UITaskModel] { get set }
    var tasksStream: AsyncStream<Void> { get }
    
    func activeTasks(for date: Date) -> [UITaskModel]
    func completedTasks(for date: Date) -> [UITaskModel]
    func thisWeekTasks(date: Double) async -> [UITaskModel]
    
    /// Save Audio to cas
    func storeAudio(_ audio: Data) async throws -> String?
    
    /// Save model
    func saveTask(_ task: UITaskModel) async throws
    
    /// Delete task
    func deleteTask(task: UITaskModel, deleteCompletely: Bool) async throws
    
    /// Checks whether the task has been marked as completed for the current day.
    func checkCompletedTaskForToday(task: UITaskModel) -> Bool
    
    /// Toggles the task's completion state and saves the updated model.
    func checkMarkTapped(task: UITaskModel) async throws
    
    /// Updates the list of deletion records for the given task by appending today's deletion record.
    func updateExistingTaskDeleted(task: UITaskModel) -> [DeleteRecord]
    
    func updateNotificationTimeForDueDate(task: UITaskModel) -> UITaskModel
    
    /// last day in deadline
    func dayUntillDeadLine(_ task: UITaskModel) -> Int?
    
    /// Update notifications for all tasks
    func updateNotifications() async
}
