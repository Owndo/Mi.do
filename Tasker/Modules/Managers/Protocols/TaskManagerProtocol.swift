//
//  TaskManagerProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import Foundation
import Models

public protocol TaskManagerProtocol {
    var tasks: [MainModel] { get }
    
    var completedTasks: [MainModel] { get }
    
    func sortedTasks(tasks: [MainModel]) -> [MainModel]
    
    func thisWeekTasks(date: Double) async -> [MainModel]
    
    func preparedTask(task: TaskModel, date: Date) -> TaskModel
    
    /// Delete task
    func deleteTask(task: MainModel, deleteCompletely: Bool) -> MainModel
    
    /// Checks whether the task has been marked as completed for the current day.
    func checkCompletedTaskForToday(task: TaskModel) -> Bool
    
    /// Toggles the task's completion state and saves the updated model.
    func checkMarkTapped(task: TaskModel) -> TaskModel
    
    /// Updates the list of deletion records for the given task by appending today's deletion record.
    func updateExistingTaskDeleted(task: TaskModel) -> [DeleteRecord]
    
    func updateNotificationTimeForDueDate(task: MainModel) -> MainModel
    
//    /// Simple func for check case where task has complete or delete record
//    func hasTaskCompleteOrDeleteMarkers(task: TaskModel) -> Bool
//    
//    /// Simple func for check case where task has complete or delete record in future
//    func hasTaskCompleteOrDeleteMarkersInFuture(task: TaskModel) -> Bool
}
