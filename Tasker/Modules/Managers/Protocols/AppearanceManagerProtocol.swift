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
    var profileData: ProfileData { get }
    var selectedColorScheme: ColorScheme? { get }
    
    func currentColorScheme() -> ColorScheme
    
    func setColorScheme(_ mode: ColorSchemeMode) 
    func changeAccentColor(_ color: AccentColorEnum)
    func changeBackgroundColor(_ color: BackgroundColorEnum)
    func changeProgressMode(_ value: Bool)
}
