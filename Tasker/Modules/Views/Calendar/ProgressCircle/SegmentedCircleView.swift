//
//  SegmentedCircleView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI
import UIComponents
import Models

struct SegmentedCircleView: View {
    var colorScheme: ColorScheme = .dark
    var date: Date

    @State private var vm = SegmentedCircleVM()
    @State private var animate = false

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
        .frame(width: 36, height: 36)
        .task(id: date) {
            animate = false
            vm.currentDay = date
            
            await vm.updateTasks()
            
            withAnimation(.easeOut(duration: 0.1)) {
                animate = true
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

    @ViewBuilder
    private func CreateSegmentBorder(for index: Int, count: Int, task: MainModel, isCompleted: Bool) -> some View {
        let totalGapAngle = count > 1 ? Double(count) * gapAngle : 0
        let availableAngle = 360.0 - totalGapAngle
        let segmentAngle = availableAngle / Double(count)

        let baseRotation = -90.0

        let startAngle = baseRotation + Double(index) * (segmentAngle + (count > 1 ? gapAngle : 0))
        let endAngle = startAngle + (animate ? segmentAngle : 0.0)

        let segmentColor = vm.useTaskColors
        ? task.value.taskColor.color(for: colorScheme)
        : colorScheme.elementColor.hexColor()

        AnimatedArcShape(startAngle: startAngle, endAngle: endAngle)
            .stroke(
                segmentColor.opacity(vm.useTaskColors
                    ? isCompleted ? 0.7 : 0.3
                    : isCompleted ? 1.0 : 0.3),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: endAngle)
    }
}


#Preview {
    SegmentedCircleView(date: Date())
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


