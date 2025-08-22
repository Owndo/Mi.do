//
//  GlowEffect.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 8/21/25.
//

import SwiftUI

struct GlowEffect: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var gradientStops: [Gradient.Stop] = []
    
    let decibelLevel: Float
    
    var body: some View {
        ZStack {
            Effect(gradientStops: gradientStops, width: 3, blur: 1.5, decibelLevel: decibelLevel)
            
            Effect(gradientStops: gradientStops, width: 5, blur: 3, decibelLevel: decibelLevel)
            
            Effect(gradientStops: gradientStops, width: 7, blur: 6, decibelLevel: decibelLevel)
            
            Effect(gradientStops: gradientStops, width: 9, blur: 9, decibelLevel: decibelLevel)
        }
        
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                gradientStops = generateGradientStops()
            }
        }
    }
    
    private func generateGradientStops() -> [Gradient.Stop] {
        let c = colorScheme.accentColor()
        
        let pairs: [(Double, Double)] = [
            (0.00, 0.5),
            (0.10, 0.6),
            (0.20, 0.7),
            (0.30, 0.8),
            (0.40, 0.9),
            (0.50, 1.0),
            (0.60, 0.9),
            (0.70, 0.8),
            (0.80, 0.7),
            (0.90, 0.6),
            (1.00, 0.5),
        ]
        
        return pairs.map { loc, op in
                .init(color: c.opacity(op), location: loc)
        }
    }
}

struct Effect: View {
    var gradientStops: [Gradient.Stop]
    var width: CGFloat
    var blur: CGFloat
    let decibelLevel: Float
    
    private var maskHeight: CGFloat {
        let minHeight: CGFloat = 50
        let maxHeight: CGFloat = 400
        
        let normalizedLevel = max(0, min(1.5, decibelLevel)) / 1.5
        
        return minHeight + (maxHeight - minHeight) * CGFloat(normalizedLevel)
    }
    
    var body: some View {
        VStack {
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(stops: gradientStops),
                        center: .center,
                        startAngle: .degrees(90),
                        endAngle: .degrees(450)
                    ),
                    lineWidth: width
                )
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 2)
                .mask(
                    VStack(spacing: 0) {
                        LinearGradient(
                            colors: [
                                .clear,
                                .black.opacity(0.1),
                                .black.opacity(0.1),
                                .black.opacity(0.6),
                                .black.opacity(0.8),
                                .clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: maskHeight)
                    }
                )
                .blur(radius: blur)
        }
        .animation(.default, value: maskHeight)
        .ignoresSafeArea()
    }
}

#Preview {
    GlowEffect(decibelLevel: 1.1)
}
