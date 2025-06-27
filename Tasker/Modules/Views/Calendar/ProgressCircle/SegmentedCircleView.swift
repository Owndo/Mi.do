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
    var colorScheme: ColorScheme = .dark
    var date: Date
    
    @State private var vm = SegmentedCircleVM()
    @State private var segmentProgress: Double = 0.0
    
    private let center = CGPoint(x: 18, y: 18)
    private let radius: CGFloat = 18
    private let gapAngle: Double = 20.0
    
    var body: some View {
        let visibleTasks = Array(vm.tasksForToday.prefix(10))
        let completedFlags = Array(vm.completedFlagsForToday.prefix(10))
        
        ZStack {
            CircleBackgroundFill(colors: visibleTasks.map { $0.value.taskColor.color(for: colorScheme) },
                                 completed: completedFlags.allSatisfy { $0 })
            .frame(width: 36, height: 36)
            
            ForEach(0..<visibleTasks.count, id: \.self) { index in
                CreateSegmentBorder(for: index,
                                    count: visibleTasks.count,
                                    task: visibleTasks[index],
                                    isCompleted: completedFlags[index])
            }
        }
        .animation(.easeIn(duration: 0.3), value: vm.completedFlagsForToday)
        .frame(width: 36, height: 36)
        .task(id: date) {
            segmentProgress = 0
            
            vm.onAppear(date: date)
            
            withAnimation(.easeOut(duration: 0.4)) {
                segmentProgress = 1.0
            }
        }
        .onChange(of: vm.updateTask) { _, _ in
            Task { await vm.updateTasks() }
        }
        .onChange(of: vm.updateWeek) { _, _ in
            Task { await vm.updateTasks() }
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
                let baseColor = completed
                ? colorScheme.elementColor.hexColor().opacity(0.22)
                : .clear
                Circle()
                    .fill(baseColor)
            }
        }
    }
    
    @ViewBuilder
    private func CreateSegmentBorder(for index: Int, count: Int, task: MainModel, isCompleted: Bool) -> some View {
        let totalGapAngle = count > 1 ? Double(count) * gapAngle : 0
        let availableAngle = 360.0 - totalGapAngle
        let segmentAngle = availableAngle / Double(count)
        
        let baseRotation = -90.0
        let startAngle = baseRotation + Double(index) * (segmentAngle + (count > 1 ? gapAngle : 0))
        let dynamicEnd = startAngle + segmentAngle * segmentProgress
        
        let segmentColor = vm.useTaskColors
        ? task.value.taskColor.color(for: colorScheme)
        : colorScheme.elementColor.hexColor()
        
        let appear = min(segmentProgress * 2, 1.0)
        let scale = 0.8 + 0.2 * appear
        
        AnimatedArcShape(startAngle: startAngle, endAngle: dynamicEnd)
            .stroke(
                segmentColor.opacity(vm.useTaskColors
                                     ? isCompleted ? 0.7 : 0.3
                                     : isCompleted ? 0.7 : 0.3),
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
    SegmentedCircleView(date: Date())
}

//struct SegmentedCircleView: View {
//    var colorScheme: ColorScheme = .dark
//
//    @State private var vm = SegmentedCircleVM()
//    @State private var appear = false
//
//    var date: Date
//
//    private let center = CGPoint(x: 18, y: 18)
//    private let radius: CGFloat = 18
//    private let gapAngle: Double = 20.0
//
//    var body: some View {
//        let visibleTasks = Array(vm.tasksForToday.prefix(10))
//        let completedFlags = Array(vm.completedFlagsForToday.prefix(10))
//
//        ZStack {
//            CircleBackgroundFill(colors: visibleTasks.map { $0.value.taskColor.color(for: colorScheme) },
//                                 completed: completedFlags.allSatisfy { $0 })
//            .frame(width: 36, height: 36)
//
//            ForEach(0..<visibleTasks.count, id: \.self) { index in
//                CreateSegmentBorder(for: index,
//                                    count: visibleTasks.count,
//                                    task: visibleTasks[index],
//                                    isCompleted: completedFlags[index])
//            }
//        }
//        .task(id: date) {
//            appear = false
//            vm.currentDay = date
//            await vm.updateTasks()
//            withAnimation(.easeOut(duration: 0.3)) {
//                appear = true
//            }
//        }
//        .onChange(of: vm.updateTask) { _, _ in
//            Task {
//                await vm.updateTasks()
//            }
//        }
//        .onChange(of: vm.updateWeek) { _, _ in
//            Task {
//                await vm.updateTasks()
//            }
//        }
//        .frame(width: 36, height: 36)
//    }
//
//    @ViewBuilder
//    private func CreateSegmentBorder(for index: Int, count: Int, task: MainModel, isCompleted: Bool) -> some View {
//        let totalGapAngle = count > 1 ? Double(count) * gapAngle : 0
//        let availableAngle = 360.0 - totalGapAngle
//        let segmentAngle = availableAngle / Double(count)
//
//        let startAngle = Double(index) * (segmentAngle + (count > 1 ? gapAngle : 0))
//        let endAngle = startAngle + segmentAngle
//
//        let segmentColor = vm.useTaskColors
//        ? task.value.taskColor.color(for: colorScheme)
//        : colorScheme.elementColor.hexColor()
//
//        Path { path in
//            path.addArc(
//                center: center,
//                radius: radius - 2,
//                startAngle: .degrees(startAngle),
//                endAngle: .degrees(endAngle),
//                clockwise: false
//            )
//        }
//        .stroke(
//            segmentColor.opacity(vm.useTaskColors
//                                 ? isCompleted ? 0.7 : 0.3
//                                 : isCompleted ? 1.0 : 0.3),
//            style: StrokeStyle(lineWidth: 3, lineCap: .round)
//        )
//        .scaleEffect(appear ? 1.0 : 0.8)
//        .opacity(appear ? 1.0 : 0.0)
//        .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.04), value: appear)
//    }
//
//    @ViewBuilder
//    private func CircleBackgroundFill(colors: [Color], completed: Bool) -> some View {
//        if vm.useTaskColors {
//            let gradient = AngularGradient(colors: colors, center: .center)
//            let baseOpacity = completed ? 0.32 : 0.00
//
//            Circle()
//                .fill(gradient)
//                .opacity(baseOpacity)
//        } else {
//            let baseColor = completed
//            ? colorScheme.elementColor.hexColor().opacity(0.22)
//            : .clear
//
//            Circle()
//                .fill(baseColor)
//        }
//    }
//}
