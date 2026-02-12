//
//  TaskActions.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/21/25.
//

import Foundation
import Models

// MARK: - Task Action Enum
public enum TaskAction {
    // Recognition
    case filledTitle
    case filledDate
    // Correction
    case correctionDate
    case correctionTitle
    // Check mark
    case checkMarkButtonTapped(PlaceForTaskAction)
    case completeButtonTapped
    case uncompleteButtonTapped
    // Voice
    case addVoiceButtonTapped
    case playVoiceButtonTapped(PlaceForTaskAction)
    case stopPlayingVoiceButtonTapped(PlaceForTaskAction)
    case seekToTime
    case withoutVoiceNotificationButtonTapped
    case withVoiceNotificationButtonTapped
    // Date
    case selectDateButtonTapped
    case autoClouseDate
    case selectTimeButtonTapped
    case autoClouseTime
    // Repeat
    case repeatTaskButtonTapped(RepeatTask)
    case changeColorButtonTapped(TaskColor)
    // Delete
    case deleteButtonTapped(TypeOfDelete)
    
    case closeButtonTapped(OpenCloseTask)
    case openTaskButtonTapped(OpenCloseTask)
    
    case hideCompletedButtonTapped
    case showCompletedButtonTapped
}

// MARK: - Helper Extensions
extension PlaceForTaskAction {
    var displayName: String {
        switch self {
        case .taskView:
            return "Task view"
        case .taskListView:
            return "Task List view"
        }
    }
}

//MARK: - Delete action
public enum TypeOfDelete {
    case deleteSingleTask(PlaceForTaskAction)
    case deleteOneOfManyTasks(PlaceForTaskAction)
    case deleteAllTasks(PlaceForTaskAction)
    
    var analyticsProperties: [String: Any] {
        switch self {
        case .deleteSingleTask(let place):
            return ["Delete single task": place.displayName]
        case .deleteOneOfManyTasks(let place):
            return ["Delete one of many tasks": place.displayName]
        case .deleteAllTasks(let place):
            return ["Delete all tasks": place.displayName]
        }
    }
}

public enum PlaceForTaskAction {
    case taskView
    case taskListView
}

public enum OpenCloseTask {
    case list
    case profile
    
    var displayName: String {
        switch self {
        case .list:
            return " Task List view"
        case .profile:
            return "Profile view"
        }
    }
}

//MARK: - Task Action Extension
extension TaskAction: AnalyticsTrackable {
    var eventName: String {
        switch self {
        case .filledTitle, .filledDate:
            return "Recognition"
        case .correctionDate, .correctionTitle:
            return "Correction"
        case .checkMarkButtonTapped:
            return "Check mark tapped ✅"
        case .completeButtonTapped:
            return "Complete task"
        case .uncompleteButtonTapped:
            return "Uncomplete task"
        case .addVoiceButtonTapped:
            return "Start recording"
        case .playVoiceButtonTapped:
            return "Start playing"
        case .stopPlayingVoiceButtonTapped:
            return "Stop playing"
        case .seekToTime:
            return "Seeking voice"
        case .withoutVoiceNotificationButtonTapped:
            return "Turn off voice notification"
        case .withVoiceNotificationButtonTapped:
            return "Turn on voice notification"
        case .selectDateButtonTapped:
            return "Select date"
        case .autoClouseDate:
            return "Auto close date"
        case .selectTimeButtonTapped:
            return "Select time"
        case .autoClouseTime:
            return "Auto close time"
        case .repeatTaskButtonTapped:
            return "Repeat"
        case .changeColorButtonTapped:
            return "Color"
        case .deleteButtonTapped:
            return "Delete task"
        case .closeButtonTapped:
            return "Close task"
        case .openTaskButtonTapped:
            return "Open task"
        case .hideCompletedButtonTapped:
            return "Hide completed"
        case .showCompletedButtonTapped:
            return "Show completed"
        }
    }
    
    var properties: [String: Any]? {
        switch self {
        case .filledTitle:
            return ["Success": "Title"]
        case .filledDate:
            return ["Success": "Date"]
        case .correctionTitle:
            return ["Title after filling": ""]
        case .correctionDate:
            return ["Date after filling": ""]
        case .checkMarkButtonTapped(let place):
            return ["Tapped from": place.displayName]
        case .addVoiceButtonTapped:
            return ["Record from": "Task view"]
        case .playVoiceButtonTapped(let place):
            return ["Playing from": place.displayName]
        case .stopPlayingVoiceButtonTapped(let place):
            return ["Stopped from": place.displayName]
        case .repeatTaskButtonTapped(let repeatTask):
            return ["Type of repeat": repeatTask.description]
        case .changeColorButtonTapped(let taskColor):
            return ["Selected color": taskColor.id]
        case .deleteButtonTapped(let typeOfDelete):
            return typeOfDelete.analyticsProperties
        default:
            return nil
        }
    }
}
