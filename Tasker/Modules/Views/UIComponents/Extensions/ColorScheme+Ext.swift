//
//  ColorScheme+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUI
import Models
import AppearanceManager

public extension ColorScheme {
    func taskBackground(_ task: UITaskModel, _ appearanceManager: AppearanceManagerProtocol) -> Color {
        if task.taskColor == .baseColor {
            return appearanceManager.backgroundColor
        } else {
            return task.taskColor.color(for: self)
        }
    }
    
    
   func invertedPrimaryLabel(_ task: UITaskModel) -> Color {
       guard task.taskColor != .baseColor else {
           return .labelPrimary
       }
       
       if self == .dark {
           return .labelPrimary
       } else {
           return task.taskColor.color(for: self).shouldInvertForReadability() ? .labelPrimaryInverted : .labelPrimary
       }
    }
    
    func invertedSecondaryLabel(_ task: UITaskModel) -> Color {
        guard task.taskColor != .baseColor else {
            return .labelSecondary
        }
        
        if self == .dark {
            return .labelSecondary
        } else {
            return task.taskColor.color(for: self).shouldInvertForReadability() ? .labelSecondaryInverted : .labelSecondary
        }
    }
    
    func invertedBackgroundTertiary(_ task: UITaskModel) -> Color {
        guard task.taskColor != .baseColor else {
            return .backgroundTertiary
        }
        
        if self == .dark {
            return .backgroundTertiary
        } else {
            return task.taskColor.color(for: self).shouldInvertForReadability() ? .backgroundTertiaryInverted : .backgroundTertiary
        }
    }
    
    func invertedTertiaryLabel(_ task: UITaskModel) -> Color {
        guard task.taskColor != .baseColor else {
            return .labelTertiary
        }
        
        if self == .dark {
            return .labelTertiary
        } else {
            return task.taskColor.color(for: self).shouldInvertForReadability() ? .labelTertiaryInverted : .labelTertiary
        }
    }
    
    func invertedSeparartorPrimary(_ task: UITaskModel) -> Color {
        guard task.taskColor != .baseColor else {
            return .separatorPrimary
        }
        
        if self == .dark {
            return .separatorPrimary
        } else {
            return task.taskColor.color(for: self).shouldInvertForReadability() ? .separatorPrimaryInverted : .separatorPrimary
        }
    }
}
