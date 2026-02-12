//
//  AppearanceEnvironment.swift
//  UIComponents
//
//  Created by Rodion Akhmedov on 1/15/26.
//

import Foundation
import AppearanceManager
import SwiftUI

private struct AppearanceManagerKey: EnvironmentKey {
    static var defaultValue: AppearanceManagerProtocol = AppearanceManager.createEnvironmentManager()
}

public extension EnvironmentValues {
    var appearanceManager: AppearanceManagerProtocol {
        get { self[AppearanceManagerKey.self] }
        set { self[AppearanceManagerKey.self] = newValue }
    }
}
