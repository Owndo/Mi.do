//
//  AppearanceManagerProtocol.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI
import Models

public protocol AppearanceManagerProtocol {
    var profileModel: UIProfileModel { get }
    var selectedColorScheme: ColorScheme? { get }
    
    func currentColorScheme() -> ColorScheme?
    
    func setColorScheme(_ mode: ColorSchemeMode) async throws
    func changeProgressMode(_ value: Bool) async throws
    func changeDefaultTaskColor(_ color: TaskColor) async throws
    func changeAccentColor(_ color: AccentColorEnum) async throws
    func changeBackgroundColor(_ color: BackgroundColorEnum) async throws
}
