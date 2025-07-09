//
//  MonthView.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/9/25.
//

import SwiftUI

public struct MonthView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = MonthVM()
    
    @Binding var presentationDetens: PresentationDetent
    @Binding var path: NavigationPath
    
    public init(presentationDetents: Binding<PresentationDetent>, path: Binding<NavigationPath>) {
        self._presentationDetens = presentationDetents
        self._path = path
    }
    
    public var body: some View {
        ZStack {
            Color(colorScheme.backgroundColor.hexColor())
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                CustomToolBar()
                
                ScrollView {
                    LazyVStack {
                        ForEach(vm.allMonths) { month in
                            
                            VStack(spacing: 10) {
                                
                                HStack {
                                    Text(month.name ?? "")
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
                            
                            LazyVGrid(columns: vm.columns) {
                                let weekday = vm.calculateEmptyDay(for: month)
                                
                                ForEach(0..<weekday, id: \.self) { _ in
                                    Text("")
                                }
                                .padding(.vertical, 14)
                                
                                
                                ForEach(month.date, id: \.self) { day in
                                    VStack {
                                        Button {
                                            vm.selectedDateChange(day)
                                            vm.closeScreenButtonTapped(path: &path, presentationDetens: &presentationDetens)
                                        } label: {
                                            Text("\(day, format: .dateTime.day())")
                                                .font(.system(.body, design: .rounded, weight: .medium))
                                                .foregroundStyle(vm.isSameDay(day) ? .labelPrimary : .labelQuaternary)
                                                .frame(maxWidth: .infinity)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .padding(.vertical, 14)
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $vm.scrollID, anchor: .top)
                .scrollIndicators(.hidden)
                .navigationBarBackButtonHidden()
            }
        }
    }
    
    //MARK: - ToolBar
    @ViewBuilder
    private func CustomToolBar() -> some View {
        HStack {
            Button {
                vm.closeScreenButtonTapped(path: &path, presentationDetens: &presentationDetens)
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    
                    Text("\(vm.selectedDate, format: .dateTime.month().day().year())")
                }
                .padding(.vertical, 7)
                .tint(colorScheme.elementColor.hexColor())
                
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
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
    }
}

#Preview {
    MonthView(presentationDetents: .constant(.fraction(0.20)), path: .constant(NavigationPath()))
}
