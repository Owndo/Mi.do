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
    @Environment(\.appearanceManager) private var appearanceManager
    
    @Bindable var vm: CalendarVM
    
    public init(vm: CalendarVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            appearanceManager.backgroundColor.ignoresSafeArea()
            
            if #available(iOS 26, *) {
                ScrollView {
                    LazyVStack {
                        ForEach(vm.allMonths) { month in
                            
                            MonthInfoView(month)
                                .task {
                                    await vm.handleMonthAppeared(month)
                                }
                            
                            LazyVGrid(columns: vm.columns) {
                                EmptyDays(month)
                                
                                MonthRowView(month.date)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: $vm.scrollID, anchor: .top)
                .navigationSubtitle(vm.navigationSubtitle)
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(vm.allMonths) { month in
                            
                            MonthInfoView(month)
                                .task {
                                    await vm.handleMonthAppeared(month)
                                }
                            
                            LazyVGrid(columns: vm.columns) {
                                EmptyDays(month)
                                
                                MonthRowView(month.date)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: $vm.scrollID, anchor: .top)
            }
            
            ScrollBackButton()
                .padding(.trailing, 25)
                .padding(.bottom, 20)
        }
        .task {
            await vm.onAppear()
        }
        .onDisappear {
            vm.onDissapear()
        }
        .navigationTitle(vm.navigationTitle)
        .navigationBarBackButtonHidden(osVersion.majorVersion > 25 ? true : false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if osVersion.majorVersion > 25 {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        vm.backToMainViewButtonTapped()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(appearanceManager.accentColor)
                    }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if vm.selectedDayIsToday() {
                    Button {
                        Task {
                            await vm.backToTodayButtonTapped()
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 17))
                            
                            Text("Today", bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .medium))
                        }
                        .tint(.labelSecondary)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 10)
                    }
                }
            }
        }
        .animation(.spring, value: vm.scrolledFromCurrentMonth)
    }
    
    @ViewBuilder
    private func MonthInfoView(_ month: PeriodModel) -> some View {
        VStack(spacing: 10) {
            
            HStack {
                Text(vm.monthName(month))
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
    
    //MARK: - ScrollBack Button
    
    @ViewBuilder
    private func ScrollBackButton() -> some View {
        if vm.scrolledFromCurrentMonth {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task {
                    await vm.backToSelectedDateButtonTapped()
                }
            } label: {
                Image(systemName: vm.imageForScrollBackButton)
                    .font(.title2.weight(.medium))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(appearanceManager.accentColor)
                    .frame(width: 44, height: 44)
                    .liquidIfAvailable(glass: .regular, isInteractive: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CalendarView(vm: CalendarVM.createPreviewVM())
    }
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
