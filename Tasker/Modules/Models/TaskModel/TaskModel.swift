//
//  MainModel.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/10/25.
//

import Foundation
import SwiftData
import SwiftUI
import BlockSet

public typealias MainModel = UITaskModel

///Model for CAS
public struct TaskModel: Codable {
    public var title: String?
    public var description: String?
    public var speechDescription: String?
    public var audio: String?
    
    public var createDate = Date.now.timeIntervalSince1970
    public var notificationDate: Double?
    public var secondNotificationDate: Double?
    public var duration: Double?
    public var deadline: Double?
    public var endDate: Double?
    public var voiceMode: Bool?
    
    public var markAsDeleted: Bool?
    
    public var repeatTask: RepeatTask?
    public var dayOfWeek: [DayOfWeek]?
    
    public var completeRecords: [CompleteRecord]?
    public var deleteRecords: [DeleteRecord]?
    
    public var taskColor: TaskColor?
    
    public init(
        title: String? = nil,
        description: String? = nil,
        speechDescription: String? = nil,
        audio: String? = nil,
        createDate: Double = Date.now.timeIntervalSince1970,
        notificationDate: Double? = nil,
        secondNotificationDate: Double? = nil,
        duration: Double? = nil,
        deadline: Double? = nil,
        endDate: Double? = nil,
        voiceMode: Bool? = nil,
        markAsDeleted: Bool? = nil,
        repeatTask: RepeatTask? = nil,
        dayOfWeek: [DayOfWeek]? = nil,
        done: [CompleteRecord]? = nil,
        deleted: [DeleteRecord]? = nil,
        taskColor: TaskColor? = nil
    ) {
        self.title = title
        self.description = description
        self.speechDescription = speechDescription
        self.audio = audio
        self.createDate = createDate
        self.notificationDate = notificationDate
        self.secondNotificationDate = secondNotificationDate
        self.duration = duration
        self.deadline = deadline
        self.endDate = endDate
        self.voiceMode = voiceMode
        self.markAsDeleted = markAsDeleted
        self.repeatTask = repeatTask
        self.dayOfWeek = dayOfWeek
        self.completeRecords = done
        self.deleteRecords = deleted
        self.taskColor = taskColor
    }
}

public class TaskModelWrapper<T: Encodable>: Identifiable, Equatable {
    public var id: String
    public var model: Model<T>
    
    public init(_ model: Model<T>) {
        self.model = model
        self.id = hashID(model.value)
    }
    
    public static func == (lhs: TaskModelWrapper<T>, rhs: TaskModelWrapper<T>) -> Bool {
        lhs.id == rhs.id
    }
}

@Observable
public class UITaskModel: TaskModelWrapper<TaskModel> {
    public var title: String {
        get { model.value.title ?? ""}
        set { model.value.title = nilIfNeed(newValue, is: "") }
    }
    
    public var description: String {
        get { model.value.description ?? "" }
        set { model.value.description = nilIfNeed(newValue, is: "")}
    }
    
    public var speechDescription: String {
        get { model.value.speechDescription ?? "" }
        set { model.value.speechDescription = nilIfNeed(newValue, is: "")}
    }
    
    public var audio: String? {
        get { model.value.audio ?? nil }
        set { model.value.audio = nilIfNeed(newValue, is: nil)}
    }
    
    public var createDate: Double {
        get { model.value.createDate }
    }
    
    public var notificationDate: Double {
        get { model.value.notificationDate ?? 0.0 }
        set { model.value.notificationDate = nilIfNeed(newValue, is: 0.0)}
    }
    
    public var duration: Double {
        get { model.value.duration ?? 0.0 }
        set { model.value.duration = nilIfNeed(newValue, is: 0.0)}
    }
    
    public var deadline: Double? {
        get { model.value.deadline ?? nil }
        set { model.value.deadline = nilIfNeed(newValue, is: nil)}
    }
    
    public var secondNotificationDate: Double {
        get { model.value.secondNotificationDate ?? 0.0 }
        set { model.value.secondNotificationDate = nilIfNeed(newValue, is: 0.0) }
    }
    
    public var voiceMode: Bool {
        get { model.value.voiceMode ?? false }
        set { model.value.voiceMode = nilIfNeed(newValue, is: false) }
    }
    
    public var markAsDeleted: Bool {
        get { model.value.markAsDeleted ?? false }
        set { model.value.markAsDeleted = nilIfNeed(newValue, is: false) }
    }
    
    public var repeatTask: RepeatTask {
        get { model.value.repeatTask ?? .never }
        set { model.value.repeatTask = nilIfNeed(newValue, is: .never) }
    }
    
    public var dayOfWeek: [DayOfWeek] {
        get {
            model.value.dayOfWeek ?? DayOfWeekEnum.dayOfWeekArray(for: Calendar.current)
        }
        set {
            model.value.dayOfWeek = nilIfNeed(newValue, is: DayOfWeekEnum.dayOfWeekArray(for: Calendar.current))
        }
    }
    
    public var completeRecords: [CompleteRecord] {
        get { model.value.completeRecords ?? [] }
        set { model.value.completeRecords = nilIfNeed(newValue, is: []) }
    }
    
    public var deleteRecords: [DeleteRecord] {
        get { model.value.deleteRecords ?? [] }
        set { model.value.deleteRecords = nilIfNeed(newValue, is: []) }
    }
    
    public var taskColor: TaskColor {
        get { model.value.taskColor ?? .baseColor }
        set { model.value.taskColor = nilIfNeed(newValue, is: .baseColor) }
    }
}


public extension UITaskModel {
    func taskRowColor(colorScheme: ColorScheme) -> Color {
        self.taskColor.color(for: colorScheme)
    }
}

func nilIfNeed<T: Equatable>(_ value: T?, is defaultValue: T?) -> T? {
    return value == defaultValue ? nil : value
}


public func mockModel() -> MainModel {
#if targetEnvironment(simulator)
    MainModel(
        .initial(
            TaskModel(
                title: "New task",
                description: "",
                createDate: Date.now.timeIntervalSince1970,
                notificationDate: Date.now.timeIntervalSince1970,
                dayOfWeek: .default,
                done: [],
                deleted: []
            )
        )
    )
#else
    MainModel(
        .initial(
            TaskModel(
                title: "New task",
                description: "",
                createDate: Date.now.timeIntervalSince1970,
                notificationDate: Date.now.timeIntervalSince1970,
                dayOfWeek: [],
                done: [],
                deleted: []
            )
        )
    )
#endif
}

public struct CompleteRecord: Codable, Equatable {
    public var completedFor: Double
    public var timeMark: Double
    
    public init(completedFor: Double, timeMark: Double) {
        self.completedFor = completedFor
        self.timeMark = timeMark
    }
}

public struct DeleteRecord: Codable, Equatable {
    public var deletedFor: Double
    public var timeMark: Double
    
    public init(deletedFor: Double, timeMark: Double) {
        self.deletedFor = deletedFor
        self.timeMark = timeMark
    }
}

public enum RepeatTask: CaseIterable, Codable, Identifiable, Equatable, Hashable {
    case never
    case daily
    case weekly
    case monthly
    case yearly
    case dayOfWeek
    
    public var id: Self { self }
    
    public var description: LocalizedStringKey {
        switch self {
        case .never: return "Never"
        case .daily: return "Every day"
        case .weekly: return "Every week"
        case .monthly: return "Every month"
        case .yearly: return "Every year"
        case .dayOfWeek: return "Day of week"
        }
    }
}

public struct DayOfWeek: Codable, Identifiable {
    public var id: String = UUID().uuidString
    
    public var name: String
    public var value: Bool
    
    public init(name: String, value: Bool) {
        self.name = name
        self.value = value
    }
}

extension DayOfWeek: Equatable {
    public static func == (lhs: DayOfWeek, rhs: DayOfWeek) -> Bool {
        return lhs.name == rhs.name && lhs.value == rhs.value
    }
}

public extension [DayOfWeek] {
    mutating func actualyDayOFWeek(_ calendar: Calendar) -> [DayOfWeek] {
        if calendar.firstWeekday == 2 {
            guard self.first!.name != "Mon" else {
                return self
            }
            
            self.reverse()
            self[0..<6].reverse()
            return self
        } else {
            guard self.first!.name == "Sun" else {
                self.insert(self.last!, at: 0)
                self.removeLast()
                return self
            }
            
            return self
        }
    }
}

public enum DayOfWeekEnum: CaseIterable, Codable {
    case monday
    case sunday
    
    public static func dayOfWeekArray(for calendar: Calendar) -> [DayOfWeek] {
        let weekdayEnum: DayOfWeekEnum = calendar.firstWeekday == 1 ? .sunday : .monday
        switch weekdayEnum {
        case .monday:
            return [
                DayOfWeek(name: "Mon", value: false),
                DayOfWeek(name: "Tue", value: false),
                DayOfWeek(name: "Wed", value: false),
                DayOfWeek(name: "Thu", value: false),
                DayOfWeek(name: "Fri", value: false),
                DayOfWeek(name: "Sat", value: false),
                DayOfWeek(name: "Sun", value: false)
            ]
        case .sunday:
            return [
                DayOfWeek(name: "Sun", value: false),
                DayOfWeek(name: "Mon", value: false),
                DayOfWeek(name: "Tue", value: false),
                DayOfWeek(name: "Wed", value: false),
                DayOfWeek(name: "Thu", value: false),
                DayOfWeek(name: "Fri", value: false),
                DayOfWeek(name: "Sat", value: false)
            ]
        }
    }
}
