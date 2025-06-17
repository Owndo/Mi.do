//
//  SegmentedCircleView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI
import UIComponents

struct SegmentedCircleView: View {
    var colorScheme: ColorScheme = .dark
    
    @State private var vm = SegmentedCircleVM()
    
    var date: Date
    
    private let center = CGPoint(x: 18, y: 18)
    private let radius: CGFloat = 18
    private let gapAngle: Double = 20.0
    
    var body: some View {
        ZStack {
            CircleBackgroundFill()
                .frame(width: 36, height: 36)
            
            ForEach(0..<vm.tasksForToday.count, id: \.self) { index in
                CreateSegmentBorder(for: index)
            }
        }
        .task(id: date) {
            vm.currentDay = date
            await vm.updateTasks()
        }
        .onChange(of: vm.updateTask) { _, _ in
            Task {
                await vm.updateTasks()
            }
        }
        .onChange(of: vm.updateWeek) { _, _ in
            Task {
                await vm.updateTasks()
            }
        }
        .frame(width: 36, height: 36)
    }
    
    @ViewBuilder
    private func CircleBackgroundFill() -> some View {
        if vm.useTaskColors {
            let colors = vm.tasksForToday.map { $0.value.taskColor.color(for: colorScheme) }
            let gradient = AngularGradient(colors: colors, center: .center)
            let baseOpacity = vm.allTaskCompletedForToday ? 0.22 : 0.05
            
            Circle()
                .fill(gradient)
                .opacity(baseOpacity)
        } else {
            let baseColor = vm.allTaskCompletedForToday
            ? colorScheme.elementColor.hexColor().opacity(0.12)
            : .clear
            
            Circle()
                .fill(baseColor)
        }
    }
    
    
    @ViewBuilder
    private func CreateSegmentBorder(for index: Int) -> some View {
        let count = vm.tasksForToday.count
        let totalGapAngle = count > 1 ? Double(count) * gapAngle : 0
        let availableAngle = 360.0 - totalGapAngle
        let segmentAngle = availableAngle / Double(count)
        
        let startAngle = Double(index) * (segmentAngle + (count > 1 ? gapAngle : 0))
        let endAngle = startAngle + segmentAngle
        
        let task = vm.tasksForToday[index]
        let isCompleted = vm.completedFlagsForToday[index]
        
        let segmentColor = vm.useTaskColors
        ? task.value.taskColor.color(for: colorScheme)
        : colorScheme.elementColor.hexColor()
        
        Path { path in
            path.addArc(
                center: center,
                radius: radius - 2,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
        }
        .stroke(
            segmentColor.opacity(vm.useTaskColors ? isCompleted ? 0.7 : 0.3 : isCompleted ? 1.0 : 0.3),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
    }
}

#Preview {
    SegmentedCircleView(date: Date())
}

