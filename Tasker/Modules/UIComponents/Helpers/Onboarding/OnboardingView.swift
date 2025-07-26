//
//  Onboarding.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/25/25.
//

import SwiftUI
import Models

public struct OnboardingView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    var type: OnboardingModelEnum
    
    public init(type: OnboardingModelEnum) {
        self.type = type
    }
    
    public var body: some View {
        ZStack {
            colorScheme.backgroundColor().ignoresSafeArea()
            
            VStack(spacing: 2) {
                Text(type.typeOfTips.0)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                
                Text(type.typeOfTips.1)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.labelTertiary)
                    
            }
            .padding(12)
        }
    }
}

#Preview {
    OnboardingView(type: .calendarTip)
}
