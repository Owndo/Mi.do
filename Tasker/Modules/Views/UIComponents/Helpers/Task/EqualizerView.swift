//
//  EqualizerView.swift
//  Mi.dō
//
//  Created by Rodion Akhmedov on 6/2/25.
//

import SwiftUI

public struct EqualizerView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    
    @State private var animationTrigger = false
    
    let decibelLevel: Float
    let barCount: Int = 30
    let maxHeight: CGFloat = 35

    public init(decibelLevel: Float) {
        self.decibelLevel = decibelLevel
    }
    
    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [appearanceManager.accentColor],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: heightForBar(at: index)
                    )
                    .animation(
                        .easeInOut(duration: 0.1),
                        value: decibelLevel
                    )
            }
        }
        .onChange(of: decibelLevel) { oldValue, newValue in
            animationTrigger.toggle()
        }
    }
    
    private func heightForBar(at index: Int) -> CGFloat {
        let normalizedLevel = CGFloat(max(0, min(decibelLevel, 1.5))) / 1.5
        
        let position = CGFloat(index) / CGFloat(barCount - 1)
        
        let adjustedPosition = position * 0.4 + 0.15
        let threshold = adjustedPosition
        
        if normalizedLevel > threshold {
            let positionMultiplier = 3.0 + position * 1.5
            let barIntensity = min(1.0, (normalizedLevel - threshold) * positionMultiplier)
            
            let calculatedHeight = maxHeight * barIntensity * 0.8
            let clampedHeight = min(calculatedHeight, 33.5)
            
            let variation = sin(CGFloat(index) * 0.7 + CGFloat(decibelLevel) * 8) * 0.1 + 1.0
            
            return max(4, clampedHeight * variation)
        } else {
            return 4
        }
    }
}

#Preview {
    EqualizerView(decibelLevel: 23.5)
}
