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
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        
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
