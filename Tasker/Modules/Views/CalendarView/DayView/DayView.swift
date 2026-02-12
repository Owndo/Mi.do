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
    @State var vm: DayViewVM
    
    var body: some View {
        VStack {
            ZStack {
                SegmentedCircleView(vm: vm)
                
                BaseContent()
                    .task {
                        await vm.loadIfNeeded()
                        await vm.onAppearSegmentedView()
                    }
            }
            .animation(.default, value: vm.showSmallFire)
            .animation(.default, value: vm.segmentedTasks)
        }
    }
    
    private func BaseContent() -> some View {
        ZStack {
            if vm.lastDayForDeadline {
                if vm.showSmallFire {
                    Text("\(vm.day.date, format: .dateTime.day())")
                        .font(.system(size: 17, weight: vm.isDateInToday() ? .semibold : .regular, design: .default))
                        .foregroundStyle(!vm.isDateInToday() ? .labelQuaternary : .labelSecondary)
                        .frame(maxWidth: .infinity)
                    
                    Image(systemName: "circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 1, height: 1)
                        .scaleEffect(0.2)
                        .foregroundStyle(vm.isOverdue() ? .accentRed : vm.appearanceManager.accentColor)
                        .offset(x: 0, y: 9)
                } else {
                    Image(systemName: "flame.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(vm.isOverdue() ? .accentRed : vm.appearanceManager.accentColor)
                        .symbolEffect(.bounce, options: .repeat(10).speed(0.8), value: vm.flameAnimation)
                        .frame(maxWidth: .infinity)
                        .scaleEffect(1.4)
                        .task {
                            vm.flameAnimation.toggle()
                        }
                }
            } else {
                Text("\(vm.day.date, format: .dateTime.day())")
                    .font(.system(size: 17, weight: vm.isDateInToday() ? .semibold : .regular, design: .default))
                    .foregroundStyle(!vm.isDateInToday() ? .labelQuaternary : .labelSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    DayView(vm: DayViewVM.createPreviewVM())
}
