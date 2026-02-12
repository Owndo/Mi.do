//
//  PeriodModel.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation

public struct Month: Identifiable, Equatable {
    public var id = UUID().uuidString
    public var name: String
    public var weeks: [Week]
    public var date: Date
    
    public init(name: String, weeks: [Week], date: Date) {
        self.name = name
        self.weeks = weeks
        self.date = date
    }
}

public struct Week: Identifiable, Equatable {
    public var id = UUID().uuidString
    public var days: [Day]
    public var isLast = false
    public var index: Int?
    
    public init(days: [Day], isLast: Bool = false) {
        self.days = days
        self.isLast = isLast
    }
}

public struct Day: Identifiable, Hashable, Equatable {
    public var id = UUID().uuidString
    public var value: Int?
    public var date: Date
    public var isPlaceholder: Bool
    
    public init(value: Int? = nil, date: Date, isPlaceholder: Bool = false) {
        self.value = value
        self.date = date
        self.isPlaceholder = isPlaceholder
    }
}

public struct PeriodModel: Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var date: [Date]
    public var name: String?
    
    public init(id: Int, date: [Date], name: String? = nil) {
        self.id = id
        self.date = date
        self.name = name
    }
}
