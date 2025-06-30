//
//  Color+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import Models

public extension UIColor {
    func toHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        return String(format: "#%06x", rgb)
    }
    
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    convenience init(_ color: Color) {
        self.init(cgColor: color.cgColor!)
    }
    
    func brightness() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red * 0.299 + green * 0.587 + blue * 0.114)
    }
    
    func shouldInvertForReadability() -> Bool {
        let threshold: CGFloat = 0.573
        return brightness() < threshold
    }
}

public extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        return uiColor.toHex()
    }
    
    func brightness() -> CGFloat {
        let uiColor = UIColor(self)
        return uiColor.brightness()
    }
    
    func shouldInvertForReadability() -> Bool {
        let uiColor = UIColor(self)
        return uiColor.shouldInvertForReadability()
    }
    
    func contrastingTextColor() -> Color {
        return shouldInvertForReadability() ? Color.white : Color.black
    }
    
    func invertedPrimaryLabel(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .labelPrimary
        } else {
            return shouldInvertForReadability() ? Color(.labelPrimaryInverted) : Color(.labelPrimary)
        }
    }
    
    func invertedSecondaryLabel(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .labelPrimary
        } else {
            return shouldInvertForReadability() ? Color(.labelSecondaryInverted) : Color(.labelSecondary)
        }
    }
    
    func invertedTertiaryLabel(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
         return .labelTertiary
        } else {
            return shouldInvertForReadability() ? Color(.labelTertiaryInverted) : Color(.labelTertiary)
        }
    }
    
    func invertedBackgroundTertiary(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .backgroundTertiary
        } else {
            return shouldInvertForReadability() ? Color(.backgroundTertiaryInverted) : Color(.backgroundTertiary)
        }
    }
    
    func invertedSeparartorPrimary(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .separatorPrimary
        } else {
            return shouldInvertForReadability() ? Color(.separatorPrimaryInverted) : Color(.separatorPrimary)
        }
    }
    
    func invertedSeparartorSecondary(_ colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return .separatorSecondary
        } else {
            return shouldInvertForReadability() ? Color(.separatorSecondaryInverted) : Color(.separatorSecondary)
        }
    }
}
