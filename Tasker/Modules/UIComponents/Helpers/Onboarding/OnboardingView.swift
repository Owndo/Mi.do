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
                Text(type.typeOfTips.0, bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                    .padding(.top, 2)
                    .minimumScaleFactor(0.5)
                
                Text(type.typeOfTips.1, bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.labelTertiary)
                    .padding(.bottom, 2)
                    .minimumScaleFactor(0.5)
            }
//            .frame(maxWidth: 230)
            .padding(12)
            .clipped()
//            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingView(type: .calendarTip)
}
