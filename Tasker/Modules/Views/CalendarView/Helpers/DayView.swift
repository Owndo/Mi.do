//
//  DayView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 8/9/25.
//

import SwiftUI
import DateManager
import TaskManager
import AppearanceManager

struct DayView: View {
    @State private var vm: DayViewVM?
    
    var day: Date
    
    private let dateManager: DateManagerProtocol
    private let taskManager: TaskManagerProtocol
    private let appearanceManager: AppearanceManagerProtocol
    
    init(day: Date, dateManager: DateManagerProtocol, taskManager: TaskManagerProtocol, appearanceManager: AppearanceManagerProtocol) {
        self.day = day
        self.dateManager = dateManager
        self.taskManager = taskManager
        self.appearanceManager = appearanceManager
    }
    
    var body: some View {
        VStack {
            if let vm = vm {
                ZStack {
                    SegmentedCircleView(date: day, vm: vm.segmentedCircleVM)
                        .frame(width: 40, height: 40)
                        .task {
                            vm.flameAnimation.toggle()
                            try? await Task.sleep(for: .seconds(Int.random(in: 1...3)))
                            vm.showSmallFire = true
                        }
                    
                    if vm.showSmallFire, vm.lastDayForDeadline(day) {
                        Image(systemName: "circle.fill")
                            .contentTransition(.symbolEffect(.replace))
                            .frame(width: 1, height: 1)
                            .scaleEffect(0.2)
                            .foregroundStyle(vm.isOverdue(day: day) ? .accentRed : appearanceManager.accentColor)
                            .offset(x: 0, y: 9)
                    }
                    
                    if !vm.lastDayForDeadline(day) || vm.lastDayForDeadline(day) && vm.showSmallFire {
                        Text("\(day, format: .dateTime.day())")
                            .font(.system(size: 17, weight: vm.calendar.isDateInToday(day) ? .semibold : .regular, design: .default))
                            .foregroundStyle(!vm.calendar.isDateInToday(day) ? .labelQuaternary : .labelSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    
                    if vm.lastDayForDeadline(day), vm.showSmallFire == false {
                        Image(systemName: "flame.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(vm.isOverdue(day: day) ? .accentRed : appearanceManager.accentColor)
                            .symbolEffect(.bounce, options: .repeat(10).speed(0.8), value: vm.flameAnimation)
                            .frame(maxWidth: .infinity)
                            .scaleEffect(1.4)
                    }
                }
                
                .animation(.default, value: vm.showSmallFire)
            } else {
                HStack {
                    Spacer()
                    
                    ProgressView()
                    
                    Spacer()
                }
            }
        }
        .task {
            self.vm = await DayViewVM.createVM(dateManager: dateManager, taskManager: taskManager, appearanceManager: appearanceManager)
        }
    }
}

#Preview {
    DayView(
        day: Date(),
        dateManager: DateManager.createMockDateManager(),
        taskManager: TaskManager.createMockTaskManager(),
        appearanceManager: AppearanceManager.createMockAppearanceManager()
    )
}
