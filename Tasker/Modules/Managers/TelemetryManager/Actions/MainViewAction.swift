//
//  MainViewAction.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/21/25.
//

import Foundation
import Errors

// MARK: - Main View Action Enum
public enum MainViewAction {
    case addTaskButtonTapped
    case recordTaskButtonTapped(RecordTaskAction)
    case calendarButtonTapped
    case profileButtonTapped
    case showNotesButtonTapped
    case addNotesButtonTapped
}

// MARK: - Supporting Enums
public enum RecordTaskAction {
    case tryRecording
    case startRecording
    case stopRecording
    case stopRecordingAfterTimeout
    case error(MicrophonePermission)
    case tryRecordingWhyCalling(ErrorRecorder)
}

// MARK: - Helper Extensions
extension RecordTaskAction {
    var analyticsData: (eventName: String, properties: [String: Any]?) {
        switch self {
        case .tryRecording:
            return ("Try recording", nil)
        case .startRecording:
            return ("Start recording", ["Record from": "Main view"])
        case .stopRecording:
            return ("Stop recording", nil)
        case .stopRecordingAfterTimeout:
            return ("Timeout stop record", nil)
        case .error(let permission):
            return ("Permission recording", ["permission": permission.description])
        case .tryRecordingWhyCalling(let error):
            return ("Error recording", ["recordUnavailable": error.description])
        }
    }
}

// MARK: - MainViewAction Analytics Extension
extension MainViewAction: AnalyticsTrackable {
    var eventName: String {
        switch self {
        case .addTaskButtonTapped:
            return "Add task"
        case .recordTaskButtonTapped(let recordAction):
            return recordAction.analyticsData.eventName
        case .calendarButtonTapped:
            return "Calendar button"
        case .profileButtonTapped:
            return "Profile button"
        case .showNotesButtonTapped:
            return "Show notes button"
        case .addNotesButtonTapped:
            return "Add notes button"
        }
    }
    
    var properties: [String: Any]? {
        switch self {
        case .recordTaskButtonTapped(let recordAction):
            return recordAction.analyticsData.properties
        default:
            return ["Tapped from": "Main view"]
        }
    }
}
