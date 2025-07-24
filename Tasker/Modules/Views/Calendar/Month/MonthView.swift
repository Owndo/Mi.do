//
//  MonthView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import SwiftUI
import Models
import UIComponents
import Paywall

public struct MonthView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    @State private var vm = MonthVM()
    
    @Binding var mainViewIsOpen: Bool
    @Binding var path: NavigationPath
    
    public init(mainViewIsOpen: Binding<Bool>, path: Binding<NavigationPath>) {
        self._mainViewIsOpen = mainViewIsOpen
        self._path = path
    }
    
    public var body: some View {
        ZStack {
            colorScheme.backgroundColor()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                CustomToolBar()
                
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
                }
                .customBlurForContainer(colorScheme: colorScheme)
                .scrollIndicators(.hidden)
                .navigationBarBackButtonHidden()
                .scrollPosition(id: $vm.scrollID, anchor: .top)
                .scrollDisabled(vm.showPaywall)
            }
            .onChange(of: vm.showPaywall) { oldValue, _ in
                vm.automaticlyClossScreen(path: &path, mainViewIsOpen: &mainViewIsOpen)
            }
            .onAppear {
                Task {
                    await vm.onAppear()
                }
            }
            .onDisappear {
                mainViewIsOpen = true
                vm.onDissapear()
            }
            
            if vm.showPaywall {
                PaywallView()
            }
        }
        .animation(.bouncy, value: vm.showPaywall)
    }
    
    //MARK: - ToolBar
    @ViewBuilder
    private func CustomToolBar() -> some View {
        HStack {
            Button {
                vm.closeScreenButtonTapped(path: &path, mainViewIsOpen: &mainViewIsOpen)
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                        .bold()
                    
                    Text("\(vm.selectedDate, format: .dateTime.month().day().year())")
                }
                .padding(.vertical, 7)
                .tint(colorScheme.accentColor())
                
                Spacer()
                
                if vm.selectedDayIsToday() {
                    Button {
                        vm.backToTodayButtonTapped()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward")
                            
                            Text("Today")
                        }
                        .tint(.labelSecondary)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule()
                                .fill(
                                    .backgroundTertiary
                                )
                        )
                    }
                }
            }
            .disabled(vm.showPaywall)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
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
        .onAppear {
            vm.handleMonthAppeared(month)
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
                    vm.closeScreenButtonTapped(path: &path, mainViewIsOpen: &mainViewIsOpen)
                } label: {
                    ZStack {
                        if vm.isSelectedDay(day) {
                            Circle()
                                .fill(.backgroundTertiary)
                        }
                        
                        SegmentedCircleView(date: day)
                            .frame(width: 40, height: 40)
                        
                        Text("\(day, format: .dateTime.day())")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(vm.isSameDay(day) ? .labelPrimary : .labelQuaternary)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(width: 45, height: 45)
            .padding(.vertical, 14)
        }
    }
}

#Preview {
    MonthView(mainViewIsOpen: .constant(true), path: .constant(NavigationPath()))
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
