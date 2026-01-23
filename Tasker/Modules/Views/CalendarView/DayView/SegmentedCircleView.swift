//
//  SegmentedCircleView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI
import UIComponents
import Models

//MARK: - Clock animation
struct SegmentedCircleView: View {
    
    var vm: DayViewVM
    
    var body: some View {
        let visibleSegments = Array(vm.segmentedTasks.prefix(10))
        
        ZStack {
            CircleBackgroundFill(colors: visibleSegments.map { $0.task.taskColor.color(for: .dark) },
                                 completed: visibleSegments.allSatisfy { $0.isCompleted })
            .frame(width: 36, height: 36)
            
            ForEach(Array(visibleSegments.enumerated()), id: \.element.id) { index, segment in
                CreateSegmentBorder(
                    for: index,
                    count: visibleSegments.count,
                    task: segment.task,
                    isCompleted: segment.isCompleted
                )
            }
        }
        .animation(.easeIn(duration: 0.3), value: vm.completedFlagsForToday)
        .frame(width: 36, height: 36)
        .task(id: vm.day) {
            vm.segmentProgress = 0
            
            withAnimation(.easeOut(duration: 0.4)) {
                vm.segmentProgress = 1.0
            }
        }
    }
    
    @ViewBuilder
    private func CircleBackgroundFill(colors: [Color], completed: Bool) -> some View {
        if colors.isEmpty {
            Circle()
                .fill(.clear)
        } else {
            if vm.useTaskColors {
                let gradient = AngularGradient(colors: colors, center: .center)
                
                let baseOpacity = completed ? 0.32 : 0.00
                
                Circle()
                    .fill(gradient)
                    .opacity(baseOpacity)
            } else {
                let baseColor = completed ? vm.appearanceManager.accentColor.opacity(0.42) : .clear
                Circle()
                    .fill(baseColor)
            }
        }
    }
    
    @ViewBuilder
    private func CreateSegmentBorder(for index: Int, count: Int, task: UITaskModel, isCompleted: Bool) -> some View {
        let totalGapAngle = count > 1 ? Double(count) * vm.gapAngle : 0
        let availableAngle = 360.0 - totalGapAngle
        let segmentAngle = availableAngle / Double(count)
        
        let baseRotation = -90.0
        let startAngle = baseRotation + Double(index) * (segmentAngle + (count > 1 ? vm.gapAngle : 0))
        let dynamicEnd = startAngle + segmentAngle * vm.segmentProgress
        
        let segmentColor = vm.useTaskColors
        ? task.taskColor == .baseColor ? vm.appearanceManager.accentColor : task.taskColor.color(for: .dark)
        : isCompleted ? vm.appearanceManager.accentColor : .separatorSecondary
        
        let appear = min(vm.segmentProgress * 2, 1.0)
        let scale = 0.8 + 0.2 * appear
        
        AnimatedArcShape(startAngle: startAngle, endAngle: dynamicEnd)
            .stroke(
                segmentColor.opacity(vm.useTaskColors ? task.taskColor != .baseColor
                                     ? isCompleted ? 0.8 : 0.3 : isCompleted ? 0.6 : 0.2
                                     : isCompleted ? 0.8 : 1),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .scaleEffect(scale)
            .opacity(appear)
    }
}


struct AnimatedArcShape: Shape {
    var startAngle: Double
    var endAngle: Double
    
    var animatableData: Double {
        get { endAngle }
        set { endAngle = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 2
        
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}

#Preview {
    SegmentedCircleView(vm: DayViewVM.createPreviewVM())
}
