//
//  TelemetryManagerProtocol.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/20/25.
//

import Foundation

public protocol TelemetryManagerProtocol {
    func logEvent(_ event: EventType)
    func pageView()
}
