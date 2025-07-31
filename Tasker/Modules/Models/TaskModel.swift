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

public typealias MainModel = Model<TaskModel>

///Model for CAS
public struct TaskModel: Identifiable, Codable {
    public var id: String = UUID().uuidString
    
    public var title = ""
    public var description = ""
    public var speechDescription: String?
    public var audio: String? = nil
    public var repeatModel: Bool? = false
    
    public var createDate = Date.now.timeIntervalSince1970
    public var notificationDate: Double
    public var duration: Double?
    public var endDate: Double?
    public var secondNotificationDate: Double?
    public var voiceMode = false
    
    public var markAsDeleted = false
    
    public var repeatTask: RepeatTask = .never
    public var dayOfWeek: [DayOfWeek]
    
    public var done: [CompleteRecord] = []
    public var deleted: [DeleteRecord] = []
    
    public var taskColor = TaskColor.yellow
    
    public init(
        title: String = "",
        description: String = "",
        speechDescription: String? = nil,
        audio: String? = nil,
        repeatModel: Bool? = nil,
        createDate: Foundation.TimeInterval = Date.now.timeIntervalSince1970,
        notificationDate: Double = 00,
        endDate: Double? = nil,
        duration: Double? = nil,
        secondNotificationDate: Double? = nil,
        voiceMode: Bool = true,
        markAsDeleted: Bool = false,
        repeatTask: RepeatTask = RepeatTask.never,
        dayOfWeek: [DayOfWeek],
        done: [CompleteRecord],
        deleted: [DeleteRecord],
        taskColor: TaskColor = .yellow
    ) {
        self.title = title
        self.speechDescription = speechDescription
        self.description = description
        self.audio = audio
        self.repeatModel = repeatModel
        self.createDate = createDate
        self.notificationDate = notificationDate
        self.duration = duration
        self.endDate = endDate
        self.secondNotificationDate = secondNotificationDate
        self.voiceMode = voiceMode
        self.markAsDeleted = markAsDeleted
        self.repeatTask = repeatTask
        self.dayOfWeek = dayOfWeek
        self.done = done
        self.deleted = deleted
        self.taskColor = taskColor
    }
    
    //    public init(from decoder: Decoder) throws {
    //        let container = try decoder.container(keyedBy: CodingKeys.self)
    //
    //        id = try container.decode(String.self, forKey: .id)
    //        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    //        info = try container.decodeIfPresent(String.self, forKey: .info) ?? ""
    //        speechDescription = try container.decodeIfPresent(String.self, forKey: .speechDescription) ?? nil
    //        audio = try container.decodeIfPresent(String.self, forKey: .audio)
    //        repeatModel = try container.decodeIfPresent(Bool.self, forKey: .repeatModel) ?? false
    //
    //        createDate = try container.decodeIfPresent(Double.self, forKey: .createDate) ?? Date.now.timeIntervalSince1970
    //        endDate = try container.decodeIfPresent(Double.self, forKey: .endDate)
    //        notificationDate = try container.decode(Double.self, forKey: .notificationDate)
    //        secondNotificationDate = try container.decodeIfPresent(Double.self, forKey: .secondNotificationDate)
    //        voiceMode = try container.decodeIfPresent(Bool.self, forKey: .voiceMode) ?? true
    //
    //        markAsDeleted = try container.decodeIfPresent(Bool.self, forKey: .markAsDeleted) ?? false
    //
    //        repeatTask = try container.decodeIfPresent(RepeatTask.self, forKey: .repeatTask) ?? .never
    //        dayOfWeek = try container.decode([DayOfWeek].self, forKey: .dayOfWeek)
    //
    //        done = try container.decodeIfPresent([CompleteRecord].self, forKey: .done) ?? []
    //        deleted = try container.decodeIfPresent([DeleteRecord].self, forKey: .deleted) ?? []
    //
    //        taskColor = try container.decodeIfPresent(TaskColor.self, forKey: .taskColor) ?? .yellow
    //    }
}

public func mockModel() -> MainModel {
#if targetEnvironment(simulator)
    MainModel.initial(TaskModel(title: "New task", description: "", createDate: Date.now.timeIntervalSince1970, notificationDate: Date.now.timeIntervalSince1970, dayOfWeek: [], done: [], deleted: []))
#else
    MainModel.initial(TaskModel(title: "New task", description: "", createDate: Date.now.timeIntervalSince1970, dayOfWeek: [], done: [], deleted: []))
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

public struct DeleteRecord: Codable {
    public var deletedFor: Double
    public var timeMark: Double
    
    public init(deletedFor: Double, timeMark: Double) {
        self.deletedFor = deletedFor
        self.timeMark = timeMark
    }
}

public enum RepeatTask: CaseIterable, Codable, Identifiable {
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

public struct DayOfWeek: Codable, Hashable, Identifiable {
    public var id: String = UUID().uuidString
    
    public var name: String
    public var value: Bool
    
    public init(name: String, value: Bool) {
        self.name = name
        self.value = value
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
