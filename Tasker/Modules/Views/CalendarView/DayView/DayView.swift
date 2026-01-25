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
    var vm: DayViewVM
    
    var body: some View {
        VStack {
            ZStack {
                SegmentedCircleView(vm: vm)
                    .frame(width: 40, height: 40)
                    .task {
                        vm.flameAnimation.toggle()
                        try? await Task.sleep(for: .seconds(Int.random(in: 1...3)))
                        vm.showSmallFire = true
                    }
                
                if vm.showSmallFire, vm.lastDayForDeadline() {
                    Image(systemName: "circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 1, height: 1)
                        .scaleEffect(0.2)
                        .foregroundStyle(vm.isOverdue() ? .accentRed : vm.appearanceManager.accentColor)
                        .offset(x: 0, y: 9)
                }
                
                if !vm.lastDayForDeadline() || vm.lastDayForDeadline() && vm.showSmallFire {
                    Text("\(vm.day, format: .dateTime.day())")
                        .font(.system(size: 17, weight: vm.isDateInToday() ? .semibold : .regular, design: .default))
                        .foregroundStyle(!vm.isDateInToday() ? .labelQuaternary : .labelSecondary)
                        .frame(maxWidth: .infinity)
                }
                
                if vm.lastDayForDeadline(), vm.showSmallFire == false {
                    Image(systemName: "flame.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(vm.isOverdue() ? .accentRed : vm.appearanceManager.accentColor)
                        .symbolEffect(.bounce, options: .repeat(10).speed(0.8), value: vm.flameAnimation)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(1.4)
                }
            }
            .animation(.default, value: vm.showSmallFire)
            .animation(.default, value: vm.segmentedTasks)
        }
    }
}

#Preview {
    DayView(vm: DayViewVM.createPreviewVM())
}
