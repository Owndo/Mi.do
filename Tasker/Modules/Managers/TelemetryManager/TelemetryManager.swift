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
    
    
    //MARK: - Open screen actions
    public func logEvent(_ event: EventType) {
        switch event {
        case .openView(let view):
            openViewAction(view)
        case .taskAction(let action):
            trackTaskViewAction(action)
        case .mainViewAction(let action):
            trackMainViewAction(action)
        case .calendarAction(let action):
            trackCalendarViewAction(action)
        }
    }
    
    private func openViewAction(_ view: ViewsType) {
        switch view {
        case .home(let action):
            switch action {
            case .open:
                PostHogSDK.shared.screen("🏠 Home screen open")
            case .close:
                PostHogSDK.shared.screen("🏠 Home screen close ❌")
            }
        case .task:
            PostHogSDK.shared.screen("📝 Notes screen")
        case .calendar(let action):
            switch action {
            case .open:
                PostHogSDK.shared.screen("📅 Calendar screen")
            case .close:
                PostHogSDK.shared.screen("📅 Calendar screen close ❌")
            }
        case .profile:
            PostHogSDK.shared.screen("🫠 Profile screen")
        }
    }
    
    //MARK: - Main view
    private func trackMainViewAction(_ action: MainViewAction) {
        switch action {
        case .addTaskButtonTapped:
            PostHogSDK.shared.capture("Add task")
            //recording
        case .recordTaskButtonTapped(let recordAction):
            switch recordAction {
            case .tryRecording:
                PostHogSDK.shared.capture("Try recording")
            case .startRecording:
                PostHogSDK.shared.capture("Start recording", properties: ["Record from": "Main view"])
            case .stopRecording:
                PostHogSDK.shared.capture("Stop recording ")
            case .stopRecordingAfterTimeout:
                PostHogSDK.shared.capture("Timeout stop record")
                // Premissions
            case .error(let permission):
                PostHogSDK.shared.capture("Permission recording", properties: ["permission": permission.description])
                // Error
            case .tryRecordingWhyCalling(let error):
                PostHogSDK.shared.capture("Error recording", properties: ["recordUnavalible": error.description])
            }
            
        case .calendarButtonTapped:
            PostHogSDK.shared.capture("Calendar button")
        case .profileButtonTapped:
            PostHogSDK.shared.capture("Profile button")
        case .showNotesButtonTapped:
            PostHogSDK.shared.capture("Show notes button")
        case .addNotesButtonTapped:
            PostHogSDK.shared.capture("Add notes button")
        }
    }
    
    //MARK: - Task actions
    private func trackTaskViewAction(_ action: TaskAction) {
        switch action {
        case .filledTitle:
            PostHogSDK.shared.capture("Recognition", properties: ["Succes": "Title"])
        case .filledDate:
            PostHogSDK.shared.capture("Recognition", properties: ["Success": "Date"])
        case .correctionTitle:
            PostHogSDK.shared.capture("Correction", properties: ["Title after filling": ""])
        case .correctionDate:
            PostHogSDK.shared.capture("Correction", properties: ["Date after filling": ""])
        case .checkMarkButtonTapped(let action):
            switch action {
            case .taskView:
                PostHogSDK.shared.capture("Check mark tapped ✅", properties: ["Tapped from": "Task view"])
            case .taskListView:
                PostHogSDK.shared.capture("Check mark tapped ✅", properties: ["Tapped from": "Task List view"])
            }
        case .completeButtonTapped:
            PostHogSDK.shared.capture("Complete task")
        case .uncompleteButtonTapped:
            PostHogSDK.shared.capture("Uncomplete task")
        case .addVoiceButtonTapped:
            PostHogSDK.shared.capture("Start recording", properties: ["Record from": "Task view"])
        case .playVoiceButtonTapped(let place):
            switch place {
            case .taskView:
                PostHogSDK.shared.capture("Start playing", properties: ["Playing from": "Task view"])
            case .taskListView:
                PostHogSDK.shared.capture("Start playing", properties: ["Playing from": "Task List view"])
            }
        case .stopPlayingVoiceButtonTapped(let place):
            switch place {
            case .taskView:
                PostHogSDK.shared.capture("Stop playing", properties: ["Stopped from": "Task view"])
            case .taskListView:
                PostHogSDK.shared.capture("Stop playing", properties: ["Stopped from": "Task List view"])
            }
        case .seekToTime:
            PostHogSDK.shared.capture("Seeking voice")
        case .withoutVoiceNotificationButtonTapped:
            PostHogSDK.shared.capture("Turn off voice notification")
        case .withVoiceNotificationButtonTapped:
            PostHogSDK.shared.capture("Turn on voice notification")
        case .selectDateButtonTapped:
            PostHogSDK.shared.capture("Select date")
        case .autoClouseDate:
            PostHogSDK.shared.capture("Auto close date")
        case .selectTimeButtonTapped:
            PostHogSDK.shared.capture("Select time")
        case .autoClouseTime:
            PostHogSDK.shared.capture("Auto close time")
        case .repeatTaskButtonTapped(let repeatTask):
            switch repeatTask {
            default:
                PostHogSDK.shared.capture("Repeat", properties: ["Type of repeat" : repeatTask.description])
            }
        case .changeColorButtonTapped(let taskColor):
            switch taskColor {
            default:
                PostHogSDK.shared.capture("Color", properties: ["Selected color" : taskColor.id])
            }
        case .deleteButtonTapped(let typeOfDelete):
            switch typeOfDelete {
            case .deleteSingleTask(let place):
                switch place {
                case .taskView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete single task" : "Task view"])
                case .taskListView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete single task" : "Task List view"])
                }
            case .deleteOneOfManyTasks(let place):
                switch place {
                case .taskView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete one of many tasks" : "Task view"])
                case .taskListView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete one of many tasks" : "Task List view"])
                }
            case .deleteAllTasks(let place):
                switch place {
                case .taskView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete all tasks" : "Task view"])
                case .taskListView:
                    PostHogSDK.shared.capture("Delete task", properties: ["Delete all tasks" : "Task List view"])
                }
            }
        case .closeButtonTapped:
            PostHogSDK.shared.capture("Close task")
        case .openTaskButtonTapped:
            PostHogSDK.shared.capture("Open task")
        }
    }
    
    //MARK: - Calendar View
    private func trackCalendarViewAction(_ action: CalendarAction) {
        switch action {
        case .selectedDateButtonTapped(let place):
            switch place {
            case .mainView:
                PostHogSDK.shared.capture("Date change", properties: ["Change from": "Main view"])
            case .calendarView:
                PostHogSDK.shared.capture("Date change", properties: ["Change from": "Calendar view"])
            }
        case .changeWeekScrolled(let direction):
            switch direction {
            case .forward:
                PostHogSDK.shared.capture("WeekScroll", properties: ["Direction": "Future"])
            case .backward:
                PostHogSDK.shared.capture("WeekScroll", properties: ["Direction": "Past"])
            }
        case .backToTodayButtonTapped(let place):
            switch place {
            case .mainView:
                PostHogSDK.shared.capture("back todat", properties: ["Tapped from": "Main view"])
            case .calendarView:
                PostHogSDK.shared.capture("back todat", properties: ["Tapped from": "Calendar view"])
            }
        }
    }
}

public enum EventType {
    case openView(ViewsType)
    case mainViewAction(MainViewAction)
    case taskAction(TaskAction)
    case calendarAction(CalendarAction)
}

//MARK: - Views
public enum ViewsType {
    case home(ViewAction)
    case task(ViewAction)
    case calendar(ViewAction)
    case profile(ViewAction)
}

public enum ViewAction {
    case open
    case close
}

//MARK: Main Screen Action
public enum MainViewAction {
    case addTaskButtonTapped
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

//MARK: - Task Action
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
    
    case closeButtonTapped
    case openTaskButtonTapped
}

//MARK: - Delete action
public enum TypeOfDelete {
    case deleteSingleTask(PlaceForTaskAction)
    case deleteOneOfManyTasks(PlaceForTaskAction)
    case deleteAllTasks(PlaceForTaskAction)
}

public enum PlaceForTaskAction {
    case taskView
    case taskListView
}


//MARK: - Calendar action
public enum CalendarAction {
    case selectedDateButtonTapped(PlaceForDateChange)
    case changeWeekScrolled(WeekScrollDirection)
    case backToTodayButtonTapped(PlaceForDateChange)
}

public enum PlaceForDateChange {
    case mainView
    case calendarView
}

public enum WeekScrollDirection {
    case forward
    case backward
}
