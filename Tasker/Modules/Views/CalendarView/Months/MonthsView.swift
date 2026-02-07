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
                    LazyVStack(spacing: 0) {
                        ForEach(vm.allMonths) { month in
                            MonthView(month: month, vm: vm)
                                .frame(height: vm.monthHeight)
                                .id(month.id)
                        }
                    }
                }
                .onScrollGeometryChange(
                    for: ScrollInfo.self,
                    of: {
                        let offsetY = $0.contentOffset.y + $0.contentInsets.top
                        let contentHeight = $0.contentSize.height
                        let containerHeight = $0.containerSize.height
                        
                        return .init(
                            offsetY: offsetY,
                            contentHeight: contentHeight,
                            contentainerHeight: containerHeight
                        )
                    },
                    action: { oldValue, newValue in
                        guard vm.allMonths.count > 10 && vm.viewStarted else { return }
                        
                        let threshold: CGFloat = 100
                        let offsetY = newValue.offsetY
                        let contentHeight = newValue.contentHeight
                        let frameHeight = newValue.contentainerHeight
                        
                        if offsetY > (contentHeight - frameHeight - threshold) && !vm.isLoadingBottom {
                            vm.loadFutureMonths(info: newValue)
                        }
                        
                        if offsetY < threshold && !vm.isLoadingTop {
                            vm.loadPastMonths(info: newValue)
                        }
                    })
                .onScrollPhaseChange { oldPhase, newPhase in
                    switch newPhase {
                    case .decelerating, .idle:
                        vm.downloadDay = true
                    default:
                        vm.downloadDay = false
                    }
                }
                .scrollPosition($vm.scrollPosition)
                .scrollDisabled(vm.scrollDisabled)
                .scrollBounceBehavior(.always)
                .scrollIndicators(.hidden)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar, .bottomBar)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.allMonths) { month in
                            MonthView(month: month, vm: vm)
                                .frame(height: vm.monthHeight)
                                .id(month.id)
                                .task {
                                    vm.handleMonthAppeared(month: month)
                                }
                        }
                    }
                }
                .scrollPosition(id: $vm.scrollID)
                .scrollDisabled(vm.scrollDisabled)
                .scrollBounceBehavior(.always)
                .scrollIndicators(.hidden)
            }
        }
        .task {
            if #available(iOS 18, *) {
                await vm.jumpToSelectedMonth18iOS()
            } else {
                await vm.jumpToSelectedMonth()
            }
        }
        .onDisappear {
            vm.endVM()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        //MARK: - Toolbar
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    vm.backToMainViewButtonTapped()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(vm.appearanceManager.accentColor)
                        
                        Text("\(vm.backToSelectedDayButtonText())")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(vm.appearanceManager.accentColor)
                            .padding(.trailing, 5)
                    }
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                if vm.selectedDayIsToday() {
                    Button {
                        Task {
                            if #available(iOS 18, *) {
                                await vm.backToTodayButton18iOS()
                            } else {
                                await vm.backToTodayButtonTapped()
                            }
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
            
            ToolbarItem(placement: .bottomBar) {
                if vm.showYear {
                    ScrollYear()
                }
            }
            
            if #available(iOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .bottomBar)
            }
            
            ToolbarItem(placement: .bottomBar) {
                if vm.scrolledFromCurrentMonth {
                    ScrollBackButton()
                }
            }
        }
        .animation(.spring, value: vm.scrolledFromCurrentMonth)
        .animation(.default, value: vm.selectedDate)
        .animation(.default, value: vm.showYear)
        .animation(.default, value: vm.scrollID)
    }
    
    //MARK: - Scroll year
    
    private func ScrollYear() -> some View {
        HStack {
            
            Text(vm.currentYear ?? "")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(vm.appearanceManager.accentColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .fixedSize()
            
            
            if osVersion.majorVersion < 26 {
                Spacer()
            }
        }
    }
    
    //MARK: - ScrollBack Button
    
    private func ScrollBackButton() -> some View {
        HStack {
            if osVersion.majorVersion < 26 {
                Spacer()
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task {
                    await vm.backToSelectedMonthButtonTapped()
                }
            } label: {
                Image(systemName: vm.imageForScrollBackButton)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundStyle(appearanceManager.accentColor)
                    .padding(.horizontal, osVersion.majorVersion < 26 ? 10 : 0)
            }
        }
    }
}

#Preview {
    @Previewable
    @State var vm: MonthsViewVM?
    
    NavigationStack {
        if let vm = vm {
            MonthsView(vm: vm)
                .task {
                    vm.startVM()
                }
        } else {
            ProgressView()
                .task {
                    vm = MonthsViewVM.createPreviewVM()
                }
        }
    }
}

//MARK: - Month View

private struct MonthView: View {
    var month: Month
    
    var vm: MonthsViewVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonthInfoView(month: month, vm: vm)
            
            /// Weeks View
            VStack(spacing: 0) {
                ForEach(month.weeks) { week in
                    
                    /// Days view
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            DayButton(day: day)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            await vm.checkIfUserScrolledFromSelectedDate(month: month)
        }
    }
    //MARK: - Day Button
    
    private func DayButton(day: Day) -> some View {
        Button {
            vm.selectedDateChange(day.date)
        } label: {
            if day.isPlaceholder {
                Color.clear
            } else {
                if vm.downloadDay {
                    RealDay(day: day)
                } else {
                    MockDay(day: day)
                }
            }
        }
    }
    
    //MARK: - Real day
    
    private func RealDay(day: Day) -> some View {
        DayView(vm: vm.returnDayVM(day))
            .background(
                Circle()
                    .fill(vm.isSelectedDay(day.date) ? .backgroundTertiary : .clear)
                    .scaledToFill()
                    .frame(width: 45, height: 45)
            )
    }
    
    //MARK: - Mock day
    
    private func MockDay(day: Day) -> some View {
        Text("\(day.date, format: .dateTime.day())")
            .font(.system(size: 17, weight: vm.isSelectedDay(day.date) ? .semibold : .regular, design: .default))
            .foregroundStyle(!vm.isSelectedDay(day.date) ? .labelQuaternary : .labelSecondary)
            .frame(maxWidth: .infinity)
            .background(
                Circle()
                    .fill(vm.isSelectedDay(day.date) ? .backgroundTertiary : .clear)
                    .scaledToFill()
                    .frame(width: 45, height: 45)
            )
    }
}

//MARK: - Month info

private struct MonthInfoView: View {
    
    var month: Month
    
    @Bindable var vm: MonthsViewVM
    
    var body: some View {
        VStack(spacing: 10) {
            
            HStack {
                Text(month.name)
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

struct ScrollInfo: Equatable {
    var offsetY: CGFloat = 0
    var contentHeight: CGFloat = 0
    var contentainerHeight: CGFloat = 0
}
