//
//  MonthsView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import SwiftUI
import Models
import UIComponents

public struct MonthsView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    
    @Bindable var vm: MonthsViewVM
    
    public init(vm: MonthsViewVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            appearanceManager.backgroundColor.ignoresSafeArea()
            
            if #available(iOS 18, *) {
                ScrollView {
                    LazyVStack {
                        ForEach(vm.allMonths) { month in
                            VStack(spacing: 0) {
                                MonthInfoView(month)
                                
                                LazyVGrid(columns: vm.columns) {
                                    EmptyDays(month)
                                    
                                    MonthRowView(month.date)
                                }
                            }
                            .id(month.id)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: $vm.scrollID, anchor: vm.scrollAnchor)
                .onScrollPhaseChange { _, newValue in
                    switch newValue {
                    case .idle:
                        vm.ableToDownloadTasksColors = true
                    default:
                        vm.ableToDownloadTasksColors = false
                    }
                }
            } else {
                ScrollView {
                    LazyVStack {
                        ForEach(vm.allMonths) { month in
                            
                            MonthInfoView(month)
                            
                            LazyVGrid(columns: vm.columns) {
                                EmptyDays(month)
                                
                                MonthRowView(month.date)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollPosition(id: $vm.scrollID, anchor: vm.scrollAnchor)
            }
            
            ScrollBackButton()
                .padding(.trailing, 25)
                .padding(.bottom, 20)
        }
        .task(id: vm.scrollID) {
            vm.handleMonthAppeared()
        }
        .onDisappear {
            vm.onDissapear()
        }
        .navigationBarBackButtonHidden(osVersion.majorVersion > 25 ? true : false)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    vm.backToMainViewButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17))
                            .foregroundStyle(vm.appearanceManager.accentColor)
                        
                        Text("\(vm.backToSelectedDayButtonText())")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(vm.appearanceManager.accentColor)
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
        .navigationBarBackButtonHidden()
        .animation(.spring, value: vm.scrolledFromCurrentMonth)
        .animation(.default, value: vm.selectedDate)
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
            Button {
                vm.selectedDateChange(day)
            } label: {
                ZStack {
                    if vm.isSelectedDay(day) {
                        Circle()
                            .fill(.backgroundTertiary)
                    }
                    
                    DayView(vm: vm.returnDayVM(day))
                        .frame(width: 45, height: 45)
                }
            }
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
                    await vm.backToSelectedMonthButtonTapped()
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
        MonthsView(vm: MonthsViewVM.createPreviewVM())
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
