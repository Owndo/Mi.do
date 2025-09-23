//
//  View+Ext.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/22/25.
//

import Foundation
import SwiftUI
import Models

public extension View {
    func customBlurForContainer(colorScheme: ColorScheme, apply: Bool? = nil) -> some View {
        return self
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [apply != nil ? colorScheme.backgroundColor() : osVersion.majorVersion < 26 ? colorScheme.backgroundColor() : .clear, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, colorScheme.backgroundColor()],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                .frame(height: 100)
                .allowsHitTesting(false)
            }
    }
}

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
                .glassEffect(
                    glass.asGlass()
                        .interactive(isInteractive)
                )
        } else {
            content
        }
    }
}

public extension View {
    func liquidIfAvailable(
        glass: LiquidIfAvailable.GlassEffectType = .regular,
        isInteractive: Bool = false
    ) -> some View {
        modifier(LiquidIfAvailable(glass: glass, isInteractive: isInteractive))
    }
}
