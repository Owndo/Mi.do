//
//  CalendarView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import SwiftUI
import Models
import UIComponents

public struct CalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: CalendarVM
    
    public init(vm: CalendarVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            
            ScrollView {
                LazyVStack {
                    ForEach(vm.allMonths) { month in
                        
                        MonthInfoView(month)
                            .onAppear {
                                vm.handleMonthAppeared(month)
                            }
                        
                        LazyVGrid(columns: vm.columns) {
                            EmptyDays(month)
                            
                            MonthRowView(month.date)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .task {
                vm.onAppear()
            }
            .onDisappear {
                vm.onDissapear()
            }
            .scrollIndicators(.hidden)
            .navigationBarBackButtonHidden()
            .scrollPosition(id: $vm.scrollID, anchor: .top)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    vm.backToMainViewButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17))
                            .foregroundStyle(colorScheme.accentColor())
                        
                        Text("\(vm.selectedDate, format: .dateTime.month().day().year())")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(colorScheme.accentColor())
                    }
                    .padding(.vertical, 7)
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if vm.selectedDayIsToday() {
                    Button {
                        Task {
                            await vm.backToTodayButtonTapped()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 17))
                            
                            Text("Today", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(.labelSecondary)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func MonthInfoView(_ month: PeriodModel) -> some View {
        VStack(spacing: 10) {
            
            HStack {
                Text(month.name ?? "")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelSecondary)
                
                Text(vm.currentYear(month) ?? "")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelSecondary)
                
                Spacer()
            }
            .padding(.leading, 16)
            
            HStack {
                ForEach(Array(vm.shiftedWeekdaySymbols().enumerated()), id: \.offset) { index, symbol in
                    Text(symbol)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.labelTertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top)
        }
        .padding(.top, 32)
        .padding(.bottom, 12)
    }
    
    
    //MARK: - Empty Days
    @ViewBuilder
    private func EmptyDays(_ month: PeriodModel) -> some View {
        let weekday = vm.calculateEmptyDay(for: month)
        
        ForEach(0..<weekday, id: \.self) { _ in
            Text("")
        }
        .padding(.vertical, 14)
    }
    
    //MARK: - Days at month
    
    @ViewBuilder
    private func MonthRowView(_ dates: [Date]) -> some View {
        ForEach(dates, id: \.self) { day in
            VStack {
                Button {
                    vm.selectedDateChange(day)
                } label: {
                    ZStack {
                        if vm.isSelectedDay(day) {
                            Circle()
                                .fill(.backgroundTertiary)
                        }
                        
                        DayView(day: day, dateManager: vm.dateManager, taskManager: vm.taskManager, appearanceManager: vm.appearanceManager)
                    }
                }
            }
            .frame(width: 45, height: 45)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    CalendarView(vm: CalendarVM.createPreviewVM())
}

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
