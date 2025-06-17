//
//  ColorScheme+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUICore

public extension ColorScheme {
    var elementColor: String {
        self == .dark ? "#18C585" : "#0EBC7C"
    }
    
    var backgroundColor: String {
        self == .dark ? "#202020" : "#F2F5EE"
    }
}
