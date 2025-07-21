//
//  TelemetryManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/20/25.
//

import Models
import Foundation
import PostHog

public final class TelemetryManager: TelemetryManagerProtocol {
    private let POSTHOG_API_KEY = "phc_I5vdL0An1zwuCn3bzVxixWaLgaJX7W7LK1P8VBxcltR"
    private let POSTHOG_HOST = "https://us.i.posthog.com"
    
    public init() {
        let config = PostHogConfig(apiKey: POSTHOG_API_KEY, host: POSTHOG_HOST)
        
        PostHogSDK.shared.setup(config)
    }
    

    public func trackOpenScreen(_ event: EventType) {
        switch event {
        case .screenOpen(let screen):
            switch screen {
            case .home:
                PostHogSDK.shared.screen("home_screen")
            case .task:
                PostHogSDK.shared.screen("task_screen")
            case .calendar:
                PostHogSDK.shared.screen("calendar_screen")
            case .profile:
                PostHogSDK.shared.screen("profile_screen")
            }
        }
    }
    
    public func trackMainScreenAction(_ action: MainScreenAction) {
        switch action {
        case .createTaskButtonTapped:
            PostHogSDK.shared.capture("create_task_button_tapped")
            
            //recording
        case .recordTaskButtonTapped(let recordAction):
            switch recordAction {
            case .tryRecording:
                PostHogSDK.shared.capture("try_recording_button_tapped")
            case .startRecording:
                PostHogSDK.shared.capture("start_recording_button_tapped")
            case .stopRecording:
                PostHogSDK.shared.capture("stop_recording_button_tapped")
            case .stopRecordingAfterTimeout:
                PostHogSDK.shared.capture("stop_recording_after_timeout")
                // Premissions
            case .error(let permission):
                PostHogSDK.shared.capture("permission_recording", properties: ["permission": permission.description])
                // Error
            case .tryRecordingWhyCalling(let error):
                PostHogSDK.shared.capture("error_recording", properties: ["recordUnavalible": error.description])
            }
            
        case .calendarButtonTapped:
            PostHogSDK.shared.capture("calendar_button_tapped")
        case .profileButtonTapped:
            PostHogSDK.shared.capture("profile_button_tapped")
        case .showNotesButtonTapped:
            PostHogSDK.shared.capture("notes_button_tapped")
        case .addNotesButtonTapped:
            PostHogSDK.shared.capture("add_notes_button_tapped")
        }
    }
}

public enum EventType {
    case screenOpen(Screen)
}
//MARK: - Screens
public enum Screen {
    case home
    case task
    case calendar
    case profile
}

//MARK: Main Screen Action
public enum MainScreenAction {
    case createTaskButtonTapped
    case recordTaskButtonTapped(RecordTaskAction)
    case calendarButtonTapped
    case profileButtonTapped
    case showNotesButtonTapped
    case addNotesButtonTapped
}

//MARK: - Record Task
public enum RecordTaskAction {
    case tryRecording
    case startRecording
    case stopRecording
    case stopRecordingAfterTimeout
    case error(MicrophonePermission)
    case tryRecordingWhyCalling(ErrorRecorder)
}

//MARK: Calendar action
public enum CalendarAction {
    case selectedDateButtonTapped
    case changeWeekScrolled
    case backToTodayButtonTapped
    case backToSelectedDateButtonTapped
}

//MARK: - Task Action
public enum TaskAction {
    // Check mark
    case completedButtonTapped
    case uncompleteButtonTapped
    // Voice
    case addVoiceButtonTapped
    case playVoiceButtonTapped
    case withoutVoiceNotificationButtonTapped
    case withVoiceNotificationButtonTapped
    // Date
    case changeDateButtonTapped
    case autoClouseDate
    case changeTimeButtonTapped
    case autoClouseTime
    // Repeat
    case repeatTaskButtonTapped(RepeatTask)
    case changeColorButtonTapped(TaskColor)
    
    case closeButtonTapped
}

//MARK: - Delete action
public enum DeleteDialogAction {
    case deleteTaskButtonTapped
    case deleteAllTasksButtonTapped
    case deleteSelectedTasksButtonTapped
}

public protocol TelemetryManagerProtocol {
    func trackOpenScreen(_ event: EventType)
    func trackMainScreenAction(_ action: MainScreenAction)
}
