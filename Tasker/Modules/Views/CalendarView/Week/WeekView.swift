//
//  WeekView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import Models
import UIComponents

public struct WeekView: View {
    
    @Bindable var vm: WeekVM
    
    let shape = UnevenRoundedRectangle(
        topLeadingRadius: 22,
        bottomLeadingRadius: 33,
        bottomTrailingRadius: 33,
        topTrailingRadius: 22,
        style: .circular
    )
    
    public init(vm: WeekVM) {
        self.vm = vm
    }
    
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
                
                VStack(spacing: 0) {
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
                .padding(.top, 8)
            }
            .frame(height: 84)
            
            TodayButton()
                .padding(.top, 8)
        }
        .padding(.top, 5)
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
                    ForEach(week.days) { day in
                        Button {
                            vm.selectedDateButtonTapped(day)
                        } label: {
                            DayView(vm: vm.returnDayVM(day))
                        }
                    }
                }
                .tag(week.index ?? 0)
            }
        }
        .animation(.spring(response: 0.2, dampingFraction: 1.8, blendDuration: 0), value: vm.indexForWeek)
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
                    .fill(.backgroundTertiary)
                    .liquidIfAvailable(glass: .regular, isInteractive: true)
            )
        }
    }
}

#Preview {
    WeekView(vm: WeekVM.createPreviewVM())
}

struct CustomHorizontalPagingBehavior: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        // Current ScrollView width
        let scrollViewWidth = context.containerSize.width
        
        // Adjust the target position based on scroll direction
        if context.velocity.dx > 0 {
            // Scroll right: target position = starting position + ScrollView width
            target.rect.origin.x = context.originalTarget.rect.minX + scrollViewWidth
        } else if context.velocity.dx < 0 {
            // Scroll left: target position = starting position - ScrollView width
            target.rect.origin.x = context.originalTarget.rect.minX - scrollViewWidth
        }
    }
}

extension ScrollTargetBehavior where Self == CustomHorizontalPagingBehavior {
    static var horizontalPaging: CustomHorizontalPagingBehavior { .init() }
}
