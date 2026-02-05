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
                .scrollPosition($vm.scrollPosition)
                .scrollDisabled(vm.scrollDisabled)
                .scrollBounceBehavior(.always)
                .scrollIndicators(.hidden)
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
                if vm.isScrolling {
                    Text(vm.currentYear ?? "")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(vm.appearanceManager.accentColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .fixedSize()
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
        .navigationBarBackButtonHidden()
        .animation(.spring, value: vm.scrolledFromCurrentMonth)
        .animation(.default, value: vm.selectedDate)
        .animation(.default, value: vm.isScrolling)
        .animation(.default, value: vm.scrollID)
    }
    
    //MARK: - ScrollBack Button
    
    @ViewBuilder
    private func ScrollBackButton() -> some View {
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
        }
    }
}

#Preview {
    @Previewable
    @State var vm: MonthsViewVM?
    
    NavigationStack {
        if let vm = vm {
            MonthsView(vm: vm)
        } else {
            ProgressView()
                .task {
                    vm = await MonthsViewVM.createPreviewVM()
                }
        }
    }
}

//MARK: - Month View

private struct MonthView: View {
    var month: Month
    
    @Bindable var vm: MonthsViewVM
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MonthInfoView(month: month, vm: vm)
            
            /// Weeks View
            VStack(spacing: 0) {
                ForEach(month.weeks) { week in
                    
                    /// Days view
                    HStack(spacing: 0) {
                        ForEach(week.days) { day in
                            Button {
                                vm.selectedDateChange(day.date)
                            } label: {
                                VStack {
                                    if day.isPlaceholder {
                                        Color.clear
                                    } else {
                                        DayView(vm: vm.returnDayVM(day))
                                            .background(
                                                Circle()
                                                    .fill(vm.isSelectedDay(day.date) ? .backgroundTertiary : .clear)
                                                    .scaledToFill()
                                            )
                                    }
                                }
                                .padding(.vertical, 25)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task {
            vm.checkIfUserScrolledFromSelectedDate(month: month)
        }
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
