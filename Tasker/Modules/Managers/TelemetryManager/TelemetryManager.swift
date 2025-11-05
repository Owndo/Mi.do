//
//  TelemetryManager.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/20/25.
//

import Models
import Foundation
import PostHog

public final class MockTelemetryManager: TelemetryManagerProtocol {
    public func logEvent(_ event: EventType) {
        
    }
    
    public func pageView() {
        
    }
}
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
            viewAction(view)
        case .taskAction(let action):
            trackTaskViewAction(action)
        case .mainViewAction(let action):
            trackMainViewAction(action)
        case .calendarAction(let action):
            trackCalendarViewAction(action)
        case .profileAction(let action):
            trackProfileViewAction(action)
        }
    }
    
    private func viewAction(_ view: ViewsType) {
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
        case .profile(let action):
            switch action {
            case .open:
                PostHogSDK.shared.screen("🫠 Profile screen")
            case .close:
                PostHogSDK.shared.screen("🫠 Profile screen close ❌")
            }
        }
    }
    
    //MARK: - Main view
    private func trackMainViewAction(_ action: MainViewAction) {
        PostHogSDK.shared.capture(action.eventName, properties: action.properties)
    }
    
    //MARK: - Task actions
    private func trackTaskViewAction(_ action: TaskAction) {
        PostHogSDK.shared.capture(action.eventName, properties: action.properties)
    }
    
    //MARK: - Calendar View
    private func trackCalendarViewAction(_ action: CalendarAction) {
        PostHogSDK.shared.capture(action.eventName, properties: action.properties)
    }
    
    //MARK: - Profile View
    private func trackProfileViewAction(_ action: ProfileViewAction) {
        PostHogSDK.shared.capture(action.eventName, properties: action.properties)
    }
    
    public func pageView() {
        PostHogSDK.shared.capture("$pageView")
    }
}

public enum ViewsType {
    case home(ViewAction)
    case task(ViewAction)
    case calendar(ViewAction)
    case profile(ViewAction)
}

// MARK: - Supporting Enums
public enum ViewAction {
    case open
    case close
}

// MARK: - Main Event Type
public enum EventType {
    case openView(ViewsType)
    case mainViewAction(MainViewAction)
    case taskAction(TaskAction)
    case calendarAction(CalendarAction)
    case profileAction(ProfileViewAction)
}

// MARK: - Helper Extensions
extension ViewAction {
    var displayName: String {
        switch self {
        case .open:
            return "open"
        case .close:
            return "close ❌"
        }
    }
}

extension EventType: AnalyticsTrackable {
    var eventName: String {
        switch self {
        case .openView(let viewType):
            return viewType.analyticsData.screenName
        case .mainViewAction(let action):
            return action.eventName
        case .taskAction(let action):
            return action.eventName
        case .calendarAction(let action):
            return action.eventName
        case .profileAction(let action):
            return action.eventName
        }
    }
    
    var properties: [String: Any]? {
        switch self {
        case .openView:
            return nil
        case .mainViewAction(let action):
            return action.properties
        case .taskAction(let action):
            return action.properties
        case .calendarAction(let action):
            return action.properties
        case .profileAction(let action):
            return action.properties
        }
    }
    
    var trackingType: TrackingType {
        switch self {
        case .openView:
            return .screen
        case .mainViewAction, .taskAction, .calendarAction, .profileAction:
            return .event
        }
    }
}

extension ViewsType {
    var screenName: String {
        switch self {
        case .home(let action):
            return "🏠 Home screen \(action.displayName)"
        case .task:
            return "📝 Task screen"
        case .calendar(let action):
            return "📅 Calendar screen \(action == .open ? "" : " \(action.displayName)")"
        case .profile(let action):
            return "🫠 Profile screen \(action == .open ? "" : " \(action.displayName)")"
        }
    }
    
    var analyticsData: (screenName: String, useScreenMethod: Bool) {
        switch self {
        case .home(.open):
            return ("🏠 Home screen open", true)
        case .home(.close):
            return ("🏠 Home screen close ❌", true)
        case .task:
            return ("📝 Task screen", true)
        case .calendar(.open):
            return ("📅 Calendar screen", true)
        case .calendar(.close):
            return ("📅 Calendar screen close ❌", true)
        case .profile(.open):
            return ("🫠 Profile screen", true)
        case .profile(.close):
            return ("🫠 Profile screen close ❌", true)
        }
    }
}

enum TrackingType {
    case screen
    case event
}

//MARK: - Protocol
protocol AnalyticsTrackable {
    var eventName: String { get }
    var properties: [String: Any]? { get }
}
