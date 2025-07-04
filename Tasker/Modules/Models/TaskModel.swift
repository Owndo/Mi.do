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
    public var id: String
    
    public var title = ""
    public var info = ""
    public var audio: String? = nil
    public var repeatModel: Bool? = false
    
    public var createDate = Date.now.timeIntervalSince1970
    public var endDate: Double?
    public var notificationDate: Double
    public var secondNotificationDate: Double?
    public var voiceMode = true
    
    public var markAsDeleted = false
    
    public var repeatTask: RepeatTask = .never
    public var dayOfWeek: [DayOfWeek]
    
    public var done: [CompleteRecord] = []
    public var deleted: [DeleteRecord] = []
    
    public var taskColor = TaskColor.yellow
    
    public init(
        id: String,
        title: String = "",
        info: String = "",
        audio: String? = nil,
        repeatModel: Bool? = nil,
        createDate: Foundation.TimeInterval = Date.now.timeIntervalSince1970,
        endDate: Double? = nil,
        notificationDate: Double = 00,
        secondNotificationDate: Double? = nil,
        voiceMode: Bool = true,
        markAsDeleted: Bool = false,
        repeatTask: RepeatTask = RepeatTask.never,
        dayOfWeek: [DayOfWeek] = .default,
        done: [CompleteRecord],
        deleted: [DeleteRecord],
        taskColor: TaskColor = .yellow
    ) {
        self.id = id
        self.title = title
        self.info = info
        self.audio = audio
        self.repeatModel = repeatModel
        self.createDate = createDate
        self.endDate = endDate
        self.notificationDate = notificationDate
        self.secondNotificationDate = secondNotificationDate
        self.voiceMode = voiceMode
        self.markAsDeleted = markAsDeleted
        self.repeatTask = repeatTask
        self.dayOfWeek = dayOfWeek
        self.done = done
        self.deleted = deleted
        self.taskColor = taskColor
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        info = try container.decodeIfPresent(String.self, forKey: .info) ?? ""
        audio = try container.decodeIfPresent(String.self, forKey: .audio)
        repeatModel = try container.decodeIfPresent(Bool.self, forKey: .repeatModel) ?? false
        
        createDate = try container.decodeIfPresent(Double.self, forKey: .createDate) ?? Date.now.timeIntervalSince1970
        endDate = try container.decodeIfPresent(Double.self, forKey: .endDate)
        notificationDate = try container.decode(Double.self, forKey: .notificationDate)
        secondNotificationDate = try container.decodeIfPresent(Double.self, forKey: .secondNotificationDate)
        voiceMode = try container.decodeIfPresent(Bool.self, forKey: .voiceMode) ?? true
        
        markAsDeleted = try container.decodeIfPresent(Bool.self, forKey: .markAsDeleted) ?? false
        
        repeatTask = try container.decodeIfPresent(RepeatTask.self, forKey: .repeatTask) ?? .never
        dayOfWeek = try container.decode([DayOfWeek].self, forKey: .dayOfWeek)
        
        done = try container.decodeIfPresent([CompleteRecord].self, forKey: .done) ?? []
        deleted = try container.decodeIfPresent([DeleteRecord].self, forKey: .deleted) ?? []
        
        taskColor = try container.decodeIfPresent(TaskColor.self, forKey: .taskColor) ?? .yellow
    }
}

public func mockModel() -> MainModel {
#if targetEnvironment(simulator)
    MainModel.initial(TaskModel(id: UUID().uuidString, title: "New task", info: "", createDate: Date.now.timeIntervalSince1970, notificationDate: Date.now.timeIntervalSince1970, done: [], deleted: []))
#else
    MainModel.initial(TaskModel(id: UUID().uuidString, title: "New task", info: "", createDate: Date.now.timeIntervalSince1970, done: [], deleted: []))
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
    
    public var description: Text {
        switch self {
        case .never: return Text("Never")
        case .daily: return Text("Every day")
        case .weekly: return Text("Every week")
        case .monthly: return Text("Every month")
        case .yearly: return Text("Every year")
        case .dayOfWeek: return Text("Day of week")
        }
    }
}

public struct DayOfWeek: Codable, Hashable, Identifiable {
    public var id = UUID()
    
    public var name: String
    public var value: Bool
    
    public init(id: UUID = UUID(), name: String, value: Bool) {
        self.id = id
        self.name = name
        self.value = value
    }
}
