//
//  AppearanceVM.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import SwiftUI

@Observable
final class AppearanceVM {
    @ObservationIgnored
    @AppStorage("colorSchemeMode") private var storedColorSchemeMode: String?
    
    var colorSchemeMode: ColorSchemeMode = .light {
        didSet {
            storedColorSchemeMode = colorSchemeMode.description
        }
    }
    
    init() {
        onAppear()
    }
    
    func onAppear() {
        switch storedColorSchemeMode {
        case "Light":
            colorSchemeMode = .light
        case "Dark":
            colorSchemeMode = .dark
        default:
            colorSchemeMode = .system
        }
    }
    
    func changeColorSchemeMode(scheme: ColorSchemeMode) {
        colorSchemeMode = scheme
    }
    
    enum ColorSchemeMode: CaseIterable {
        case light
        case dark
        case system
        
        var description: String {
            switch self {
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .system:
                return "System"
            }
        }
    }
}
