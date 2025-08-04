//
//  PeriodModel.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation

public struct PeriodModel: Identifiable, Equatable, Hashable {
    public var id: Int
    public var date: [Date]
    public var name: String?
    
    public init(id: Int, date: [Date], name: String? = nil) {
        self.id = id
        self.date = date
        self.name = name
    }
}
