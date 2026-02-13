//
//  View+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUI
import Models

public struct LiquidIfAvailable: ViewModifier {
    
    public enum GlassEffectType {
        case clear, identity, regular
        
        @available(iOS 26.0, *)
        func asGlass() -> Glass {
            switch self {
            case .clear:
                return .clear
            case .identity:
                return .identity
            case .regular:
                return .regular
            }
        }
    }
    
    let glass: GlassEffectType
    let isInteractive: Bool
    
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(glass.asGlass().interactive(isInteractive))
        } else {
            content
        }
    }
}

public extension View {
    func liquidIfAvailable(glass: LiquidIfAvailable.GlassEffectType = .regular, isInteractive: Bool = false) -> some View {
        modifier(LiquidIfAvailable(glass: glass, isInteractive: isInteractive))
    }
}

//MARK: - Check TaskView for preview
public extension View {
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if !shouldHide {
            self
        }
    }
    
    func customSafeAreaInset<Content: View>(edge: VerticalEdge, @ViewBuilder content: () -> Content) -> some View {
         Group {
             if #available(iOS 26, *) {
                 self
                     .safeAreaBar(edge: edge) {
                         content()
                     }
             } else {
                 self
                     .safeAreaInset(edge: edge) {
                         content()
                     }
             }
         }
     }
}
