//
//  NavigationCore.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 1/6/26.
//

import Foundation

public protocol HashableNavigation: AnyObject, Hashable {}

extension HashableNavigation {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs === rhs
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
