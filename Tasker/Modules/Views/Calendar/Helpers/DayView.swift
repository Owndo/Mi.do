//
//  DayView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 8/9/25.
//

import SwiftUI

struct DayView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = DayViewVM()
    
    var day: Date
    
    var body: some View {
        ZStack {
            SegmentedCircleView(date: day)
                .frame(width: 40, height: 40)
            
            if vm.showSmallFire, vm.lastDayForDeadline(day) {
                Image(systemName: "flame.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 1, height: 1)
                    .scaleEffect(0.5)
                    .foregroundStyle(vm.isOverdue(day: day) ? .accentRed : colorScheme.accentColor())
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
                    .foregroundStyle(vm.isOverdue(day: day) ? .accentRed : colorScheme.accentColor())
                    .symbolEffect(.bounce, options: .repeat(10).speed(0.8), value: vm.flameAnimation)
                    .frame(maxWidth: .infinity)
                    .scaleEffect(1.4)
            }
        }
        .onAppear {
            Task {
                vm.flameAnimation.toggle()
                try? await Task.sleep(for: .seconds(Int.random(in: 1...3)))
                vm.showSmallFire = true
            }
        }
        .animation(.default, value: vm.showSmallFire)
    }
}

#Preview {
    DayView(day: Date())
}
