//
//  ListView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import SwiftUI
import UIComponents

public struct ListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = ListVM()
    
    public init() {}
    
    public var body: some View {
        GeometryReader { screenGeometry in
            ScrollView {
                VStack(spacing: 0) {
                    
                    VStack(spacing: 0) {
                        TasksList()
                        
                        CompletedTasksList()
                    }
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .preference(
                                    key: ContentHeightPreferenceKey.self,
                                    value: contentGeometry.size.height
                                )
                        }
                    )
                    
                    GestureDetectView()
                        .frame(height: vm.calculateGestureViewHeight(
                            screenHeight: screenGeometry.size.height,
                            contentHeight: vm.contentHeight,
                            safeAreaTop: screenGeometry.safeAreaInsets.top,
                            safeAreaBottom: screenGeometry.safeAreaInsets.bottom
                        ))
                        .popover(
                            isPresented: $vm.onboardingManager.createButtonTip,
                            attachmentAnchor: .point(.center),
                            arrowEdge: .bottom
                        ) {
                            OnboardingView(type: .createButtonTip)
                                .presentationCompactAdaptation(.popover)
                        }
                }
            }
            .scrollIndicators(.hidden)
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                vm.contentHeight = height
            }
        }
        .padding(.horizontal, 16)
        .customBlurForContainer(colorScheme: colorScheme)
        .animation(.linear, value: vm.completedTasksHidden)
        .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
    }
    
    @ViewBuilder
    private func TasksList() -> some View {
        if !vm.tasks.isEmpty {
            HStack {
                Text("Tasks", bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.labelTertiary)
                
                Spacer()
            }
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            VStack(spacing: 0) {
                ForEach(Array(vm.tasks.enumerated()), id: \.element) { index, task in
                    TaskRow(task: task)
                    
                    if index != vm.tasks.count - 1 {
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(
                                .separatorSecondary
                            )
                            .frame(height: 0.5)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    @ViewBuilder
    private func CompletedTasksList() -> some View {
        if !vm.completedTasks.isEmpty {
            HStack {
                Text("Completed task", bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color(.labelTertiary))
                
                Spacer()
                
                Image(systemName: vm.completedTasksHidden ? "chevron.down" : "chevron.up")
                    .foregroundStyle(.labelTertiary)
                    .bold()
            }
            .onTapGesture {
                vm.completedTaskViewChange()
            }
            .padding(.top, 18)
            .padding(.bottom, 12)
            
            
            if !vm.completedTasksHidden {
                VStack(spacing: 0) {
                    ForEach(Array(vm.completedTasks.enumerated()), id: \.element) { index, task in
                        TaskRow(task: task)
                            .foregroundStyle(.labelPrimary)
                        
                        if index != vm.completedTasks.count - 1 {
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(
                                    .separatorSecondary
                                )
                                .frame(height: 0.5)
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    //MARK: Gesture dectectView
    @ViewBuilder
    private func GestureDetectView() -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onEnded { value in
                        if value.translation.width < -75 {
                            vm.nextDaySwiped()
                        } else if value.translation.width > 75 {
                            vm.previousDaySwiped()
                        }
                        
                        if value.translation.height < -75 {
                            
                        } else if value.translation.height > 75 {
                            
                        }
                    }
            )
            .onTapGesture(count: 2) {
                vm.backToTodayButtonTapped()
            }
    }
}

#Preview {
    ListView()
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
