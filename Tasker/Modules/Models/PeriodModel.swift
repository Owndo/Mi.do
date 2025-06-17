//
//  PeriodModel.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import Foundation

public struct PeriodModel: Identifiable {
    public var id: Int
    public var date: [Date]
    
    public init(id: Int, date: [Date]) {
        self.id = id
        self.date = date
    }
}
