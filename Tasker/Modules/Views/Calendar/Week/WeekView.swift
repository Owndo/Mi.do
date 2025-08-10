//
//  WeekView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import UIComponents

public struct WeekView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = WeekVM()
    
    let shape = UnevenRoundedRectangle(
        topLeadingRadius: 16,
        bottomLeadingRadius: 33,
        bottomTrailingRadius: 33,
        topTrailingRadius: 16,
        style: .circular
    )
    
    public init() {}
    
    public var body: some View {
        VStack {
            ZStack {
                HStack {
                    ForEach(0..<7) { index in
                        if vm.isSelectedDayOfWeek(index) {
                            shape
                                .fill(.backgroundTertiary)
                                .frame(maxWidth: .infinity)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
                
                VStack {
                    HStack {
                        ForEach(0..<vm.orderedWeekdaySymbols().count, id: \.self) { symbol in
                            Text(vm.orderedWeekdaySymbols()[symbol])
                                .font(.system(.subheadline, design: .rounded, weight: .medium))
                                .fontDesign(.default)
                                .foregroundStyle(.labelSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    DayOfWeeksView()
                }
            }
            .frame(height: 84)
            
            TodayButton()
                .padding(.top, 8)
        }
        .padding(.bottom, 2)
        .animation(.default, value: vm.indexForWeek)
        .animation(.default, value: vm.selectedDate)
        .animation(.default, value: vm.scaleEffect)
        .sensoryFeedback(.impact, trigger: vm.selectedDate)
        .sensoryFeedback(.levelChange, trigger: vm.indexForWeek)
        .sensoryFeedback(.impact, trigger: vm.trigger)
    }
    
    //MARK: - Day of week
    @ViewBuilder
    private func DayOfWeeksView() -> some View {
        TabView(selection: $vm.dateManager.indexForWeek) {
            ForEach(vm.weeks) { week in
                HStack {
                    ForEach(week.date, id: \.self) { day in
                        Button {
                            vm.selectedDateButtonTapped(day)
                        } label: {
                            DayView(day: day)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 1.8, blendDuration: 0), value: vm.indexForWeek)
        .frame(height: 36)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    
    //MARK: - Today Button
    @ViewBuilder
    private func TodayButton() -> some View {
        Button {
            vm.backToTodayButtonTapped()
        } label: {
            HStack {
                if !vm.selectedDayIsToday() {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundStyle(.labelSecondary)
                }
                
                Text(vm.dateToString())
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.labelSecondary)
                    .scaleEffect(vm.scaleEffect)
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        .backgroundTertiary
                    )
            )
        }
    }
}

#Preview {
    WeekView()
}
