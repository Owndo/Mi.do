//
//  AppearanceManagerProtocol.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI

public protocol AppearanceManagerProtocol {
    func backgroundColor() -> Color
    func accentColor() -> Color
    func colorScheme() -> String
    
    func changeColorSchemeMode(scheme: ColorSchemeMode)
    func changeAccentColor(_ color: AccentColorEnum)
    func changeBackgroundColor(_ color: BackgroundColorEnum)
    func changeProgressMode(_ value: Bool)
}
