//
//  TaskManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import Foundation
import Models

public protocol TaskManagerProtocol {
//    var tasks: [String: UITaskModel] { get set }
    var activeTasks: [UITaskModel] { get }
    var completedTasks: [UITaskModel] { get }
    
    func thisWeekTasks(date: Double) async -> [UITaskModel]
    
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
    
    func updateNotificationTimeForDueDate(task: UITaskModel) -> MainModel
    
    /// last day in deadline
    func dayUntillDeadLine(_ task: UITaskModel) -> Int?
    func updateNotifications() async
}
