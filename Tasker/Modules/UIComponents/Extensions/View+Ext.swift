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
    func customBlurForContainer(colorScheme: ColorScheme) -> some View {
        self
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [colorScheme.backgroundColor.hexColor(), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 30)
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, colorScheme.backgroundColor.hexColor()],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                .frame(height: 100)
                .allowsHitTesting(false)
            }
    }
}
