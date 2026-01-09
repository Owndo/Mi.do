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
    
    
    var progress: Double
    var countOfSec: Double
    var decivelsLVL: Float
    
    public init(isRecording: Binding<Bool>, progress: Double, countOfSec: Double, decivelsLVL: Float) {
        self._isRecording = isRecording
        self.progress = progress
        self.countOfSec = countOfSec
        self.decivelsLVL = decivelsLVL
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            
            CustomPopOver()
            
            VStack {
                if isRecording {
                    if #available(iOS 26.0, *) {
                        StopRecording()
                            .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white).interactive())
                    } else {
                        StopRecording()
                    }
                } else {
                    if #available(iOS 26.0, *) {
                        StartRecording()
                            .glassEffect(.regular.tint(colorScheme == .dark ? .clear : .white).interactive())
                    } else {
                        StartRecording()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func CustomPopOver() -> some View {
        if isRecording == false {
            VStack {
                Text("Start here", bundle: .module)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.labelPrimary)
                
                Text("Hold or tap the plus button\n to create", bundle: .module)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.labelTertiary)
            }
            .padding(12)
            .padding(.bottom, 10)
            .background(
                PopoverBubbleShape()
                    .fill(Color(.tipsBackground))
                    .shadow(color: .black.opacity(0.22), radius: 30, y: 10)
            )
        }
    }
    
    
    
    @ViewBuilder
    private func StartRecording() -> some View {
        VStack {
            Image(systemName: "plus")
                .font(.system(size: 42))
                .foregroundStyle(colorScheme.accentColor())
                .frame(width: 64, height: 64)
                .padding(13)
                .background(
                    Circle()
                        .fill(.white)
                        .shadow(
                            color: colorScheme.accentColor(),
                            radius: shadowRadius,
                            x: shadowXOffset,
                            y: shadowYOffset
                        )
                )
        }
        .task {
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.7)) {
                    shadowXOffset = CGFloat.random(in: -4...4)
                    shadowYOffset = CGFloat.random(in: -4...4)
                    shadowRadius = CGFloat.random(in: 4...8)
                }
            }
        }
//        .onDisappear {
//            shadowYOffset = 0
//            shadowXOffset = 0
//        }
    }
    
    @ViewBuilder
    private func StopRecording() -> some View {
        Image(systemName: "pause.fill")
            .font(.system(size: 42))
            .foregroundStyle(colorScheme.accentColor())
            .frame(width: 64, height: 64)
            .padding(13)
            .background(
                ZStack {
                    Circle()
                        .stroke(.backgroundTertiary, style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(colorScheme.accentColor(), style: StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                        .rotationEffect(Angle(degrees: 270))
                        .animation(.easeInOut(duration: 0.1), value: progress)
                        .overlay {
                            if decivelsLVL > 0.8 {
                                AnimationView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.25), value: decivelsLVL)
                        .animation(.spring, value: progress)
                }
            )
    }
    
    @ViewBuilder
    private func AnimationView() -> some View {
        ZStack {
            Circle()
                .stroke(colorScheme.accentColor().opacity(0.4), lineWidth: 0.7)
                .scaleEffect(CGFloat(decivelsLVL) + 0.8)
                .animation(.easeOut(duration: 0.3), value: decivelsLVL)
                .shadow(color: colorScheme.accentColor(), radius: 3)
            
            Circle()
                .stroke(colorScheme.accentColor().opacity(0.6), lineWidth: 1.0)
                .scaleEffect(CGFloat(decivelsLVL) + 0.55)
                .animation(.easeOut(duration: 0.3).delay(0.05), value: decivelsLVL)
                .shadow(color: colorScheme.accentColor(), radius: 2)
            
            Circle()
                .stroke(colorScheme.accentColor().opacity(0.8), lineWidth: 1.5)
                .scaleEffect(CGFloat(decivelsLVL) + 0.3)
                .animation(.easeOut(duration: 0.3).delay(0.1), value: decivelsLVL)
                .shadow(color: colorScheme.accentColor(), radius: 1)
        }
    }
}

#Preview {
    RecordButton(isRecording: .constant(false), progress: 0.7, countOfSec: 23.1, decivelsLVL: 1.1)
}

struct PopoverBubbleShape: Shape {
    var cornerRadius: CGFloat = 26
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

