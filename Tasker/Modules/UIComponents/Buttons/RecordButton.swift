//
//  RecordButton.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI

public struct RecordButton: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isRecording: Bool
    
    @State private var shadowXOffset: CGFloat = 0
    @State private var shadowYOffset: CGFloat = 0
    @State private var shadowRadius: CGFloat = 5
    @State private var shadowAngle: Double = 0
    
    var showTips: Bool
    
    var progress: Double
    var countOfSec: Double
    var animationAmount: Float
    
    var action: () -> Void
    
    public init(isRecording: Binding<Bool>, showTips: Bool, progress: Double, countOfSec: Double, animationAmount: Float, action: @escaping () -> Void) {
        self._isRecording = isRecording
        self.showTips = showTips
        self.progress = progress
        self.countOfSec = countOfSec
        self.animationAmount = animationAmount
        self.action = action
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            
            CustomPopOver()
            
            Button {
                action()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                if isRecording {
                    StopRecording()
                } else {
                    StartRecording()
                }
            }
        }
        .animation(.default, value: showTips)
    }
    
    @ViewBuilder
    private func CustomPopOver() -> some View {
        if showTips && isRecording == false {
            VStack {
                Text("Just say our task")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.labelPrimary)
                
                Text("Tap or hold the plus button\nto get started")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.labelTertiary)
            }
            .padding(12)
            .padding(.bottom, 10)
            .background(
                PopoverBubbleShape()
                    .fill(.tipsBackground)
                    .shadow(color: .black.opacity(0.22), radius: 30, y: 10)
            )
        }
    }
    
    
    
    @ViewBuilder
    private func StartRecording() -> some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 42))
                .foregroundStyle(colorScheme.elementColor.hexColor())
                .frame(width: 64, height: 64)
                .padding(13)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(
                            color: colorScheme.elementColor.hexColor(),
                            radius: shadowRadius,
                            x: shadowXOffset,
                            y: shadowYOffset
                        )
                )
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.7)) {
                    shadowXOffset = CGFloat.random(in: -4...4)
                    shadowYOffset = CGFloat.random(in: -4...4)
                    shadowRadius = CGFloat.random(in: 4...8)
                }
            }
        }
        .onDisappear {
            shadowYOffset = 0
            shadowXOffset = 0
        }
    }
    
    @ViewBuilder
    private func StopRecording() -> some View {
        Image(systemName: "pause.fill")
            .font(.system(size: 42))
            .foregroundStyle(colorScheme.elementColor.hexColor())
            .frame(width: 64, height: 64)
            .padding(13)
            .background(
                ZStack {
                    Circle()
                        .stroke(.labelTertiary, style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(colorScheme.elementColor.hexColor(), style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: 270))
                        .animation(.easeInOut(duration: 0.1), value: progress)
                        .overlay {
                            if animationAmount > 0.8 {
                                AnimationView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: animationAmount)
                        .animation(.spring, value: progress)
                }
            )
    }
    
    @ViewBuilder
    private func AnimationView() -> some View {
        ZStack {
            Circle()
                .stroke(colorScheme.elementColor.hexColor().opacity(0.4), lineWidth: 0.7)
                .scaleEffect(CGFloat(animationAmount) + 0.8)
                .animation(.easeOut(duration: 0.3), value: animationAmount)
                .shadow(color: colorScheme.elementColor.hexColor(), radius: 3)
            
            Circle()
                .stroke(colorScheme.elementColor.hexColor().opacity(0.6), lineWidth: 1.0)
                .scaleEffect(CGFloat(animationAmount) + 0.55)
                .animation(.easeOut(duration: 0.3).delay(0.05), value: animationAmount)
                .shadow(color: colorScheme.elementColor.hexColor(), radius: 2)
            
            Circle()
                .stroke(colorScheme.elementColor.hexColor().opacity(0.8), lineWidth: 1.5)
                .scaleEffect(CGFloat(animationAmount) + 0.3)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: animationAmount)
                .shadow(color: colorScheme.elementColor.hexColor(), radius: 1)
        }
    }
}

#Preview {
    RecordButton(isRecording: .constant(false), showTips: true, progress: 0.7, countOfSec: 23.1, animationAmount: 1.1, action: {})
}

struct PopoverBubbleShape: Shape {
    var cornerRadius: CGFloat = 12
    var arrowSize: CGSize = CGSize(width: 20, height: 10)
    var arrowOffset: CGFloat = 0
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let arrowHalfWidth = arrowSize.width / 2
        let arrowHeight = arrowSize.height
        let midX = rect.midX + arrowOffset
        
        let topLeft = CGPoint(x: rect.minX + cornerRadius, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX - cornerRadius, y: rect.minY)
        
        path.move(to: topLeft)
        
        path.addLine(to: topRight)
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(0),
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - arrowHeight - cornerRadius))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - arrowHeight - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: midX + arrowHalfWidth, y: rect.maxY - arrowHeight))
        path.addLine(to: CGPoint(x: midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: midX - arrowHalfWidth, y: rect.maxY - arrowHeight))
        
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - arrowHeight))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - arrowHeight - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)
        
        return path
    }
}

