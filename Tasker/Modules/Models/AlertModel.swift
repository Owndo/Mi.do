//
//  AlertModel.swift
//  UIComponents
//
//  Created by Rodion Akhmedov on 6/17/25.
//

import SwiftUI

public struct AlertModel: Identifiable {
    public var id = UUID()
    public var alert: Alert
    
    public init(id: UUID = UUID(), alert: Alert) {
        self.id = id
        self.alert = alert
    }
}
