//
//  SettingsModel.swift
//  Models
//
//  Created by Rodion Akhmedov on 8/3/25.
//

import Foundation
import SwiftUI

public struct SettingsModel: Codable, Equatable {
    public var firstDayOfWeek: Int?
    public var colorScheme: ColorSchemeMode?
    public var defaultTaskColor: TaskColor?
    public var accentColor: AccentBackgroundColor?
    public var background: AccentBackgroundColor?
    public var minimalProgressMode: Bool?
    //    public var minimalProgressMode = true
    public var completedTasksHidden: Bool?
    //    public var completedTasksHidden = false
    public var iCloudSyncEnabled: Bool?
    //    public var iCloudSyncEnabled = true
}

public final class UISettingsModel {
    
    public var model: SettingsModel {
        didSet {
            guard model != oldValue else { return }
            onChange(model)
        }
    }
    
    private let onChange: (SettingsModel) -> Void
    
    init(_ model: SettingsModel, onChange: @escaping (SettingsModel) -> Void) {
        self.model = model
        self.onChange = onChange
    }
    
    public var firstDayOfWeek: Int {
        get { model.firstDayOfWeek ?? Calendar.current.firstWeekday }
        set { model.firstDayOfWeek = nilIfNeed(newValue, is: Calendar.current.firstWeekday)}
    }
    
    public var colorScheme: ColorSchemeMode {
        get { model.colorScheme ?? .system }
        set { model.colorScheme = nilIfNeed(newValue, is: .system)}
    }
    
    public var defaultTaskColor: TaskColor {
        get { model.defaultTaskColor ?? .baseColor }
        set { model.defaultTaskColor = nilIfNeed(newValue, is: .baseColor)}
    }
    
    public var accentColor: AccentBackgroundColor {
        get { model.accentColor ?? .defaultAccent }
        set { model.accentColor = nilIfNeed(newValue, is: .defaultAccent)}
    }
    
    public var background: AccentBackgroundColor {
        get { model.background ?? .defaultBackground }
        set { model.background = nilIfNeed(newValue, is: .defaultBackground)}
    }
    
    public var minimalProgressMode: Bool {
        get { model.minimalProgressMode ?? true }
        set { model.minimalProgressMode = nilIfNeed(newValue, is: true)}
    }
    
    public var completedTasksHidden: Bool {
        get { model.completedTasksHidden ?? false }
        set { model.completedTasksHidden = nilIfNeed(newValue, is: false)}
    }
    
    public var iCloudSyncEnabled: Bool {
        get { model.iCloudSyncEnabled ?? true }
        set { model.iCloudSyncEnabled = nilIfNeed(newValue, is: true)}
    }
    
    public func backgroundColor() -> String {
        switch colorScheme {
        case .dark:
            return background.dark
        case .light:
            return background.light
        default:
            return currentSystemColorSchemeIsDark() ? background.dark : background.light
        }
    }
    
    private func currentSystemColorSchemeIsDark() -> Bool {
        return UITraitCollection.current.userInterfaceStyle == .dark
    }
}




//    private func currentSystemColorSchemeIsDark() -> ColorSchemeMode {
//        if UITraitCollection.current.userInterfaceStyle == .dark {
//            return .dark
//        } else {
//            return .light
//        }
////        return UITraitCollection.current.userInterfaceStyle == .dark
//    }




//    public init(
//        colorScheme: ColorSchemeMode,
//        accentColor: AccentBackgroundColor = AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585"),
//        background: AccentBackgroundColor = AccentBackgroundColor(light: "#F2F5EE", dark: "#202020"),
//    ) {
//        self.colorScheme = colorScheme
//        self.accentColor = accentColor
//        self.background = background
//    }
//

//

//    }


func defaultSettingsModel() -> SettingsModel {
    SettingsModel()
}


public struct AccentBackgroundColor: Codable, Equatable {
    public var light: String
    public var dark: String
    
    public init(light: String, dark: String) {
        self.light = light
        self.dark = dark
    }
}

public extension AccentBackgroundColor {
    static let defaultAccent = AccentBackgroundColor(light: "#0EBC7C", dark: "#18C585")
    static let defaultBackground = AccentBackgroundColor(light: "#F2F5EE", dark: "#202020")
}
