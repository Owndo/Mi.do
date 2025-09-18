//
//  ListView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import SwiftUI
import UIComponents
import TaskView
import Models

public struct ListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = ListVM()
    
    public init() {}
    
    public var body: some View {
        List {
            //MARK: Tasks section
            if !vm.tasks.isEmpty {
                Text("Tasks", bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelTertiary)
                    .listRowBackground(Color.clear)
            }
            
            ForEach(vm.tasks) { task in
                TaskRow(task: task)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button {
                            
                        } label: {
                            Label("Delete task?", systemImage: "trash")
                                .tint(.red)
                        }
                    }
           
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            //                                          vm.deleteTaskButtonSwiped()
                        } label: {
                            if #available(iOS 26, *) {
                                Image(systemName: "trash")
                                    .tint(.accentRed)
                            } else {
                                Image(uiImage: .paywall)
                                    .resizable()
                                    .scaledToFit()
                                    .tint(colorScheme.backgroundColor())
                            }
                        }
                    }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            
            //MARK: - Completed tasks section
            if !vm.completedTasks.isEmpty {
                HStack {
                    Text("Completed task", bundle: .module)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelTertiary)
                    
                    Spacer()
                    
                    Image(systemName: vm.completedTasksHidden ? "chevron.down" : "chevron.up")
                        .foregroundStyle(.labelTertiary)
                        .bold()
                }
                .listRowBackground(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.completedTaskViewChange()
                }
            }
            
            if !vm.completedTasksHidden {
                ForEach(vm.completedTasks) { task in
                    TaskRow(task: task)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 2)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                //                                          vm.deleteTaskButtonSwiped()
                            } label: {
                                if #available(iOS 26, *) {
                                    Image(systemName: "trash")
                                        .tint(.accentRed)
                                } else {
                                    Image(uiImage: .paywall)
                                        .resizable()
                                        .scaledToFit()
                                        .tint(colorScheme.backgroundColor())
                                }
                            }
                        }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            } else {
                RoundedRectangle(cornerRadius: 26)
                    .fill(.clear)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
        }
        .customBlurForContainer(colorScheme: colorScheme, apply: true)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .listStyle(.inset)
        .ignoresSafeArea(edges: .top)
        .animation(.default, value: vm.completedTasksHidden)
        .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
        .animation(.spring, value: vm.tasks)
        .animation(.spring, value: vm.completedTasks)
    }
    
    @ViewBuilder
    private func TasksList() -> some View {
        VStack(spacing: 1) {
            if !vm.tasks.isEmpty {
                HStack {
                    Text("Tasks", bundle: .module)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.labelTertiary)
                    
                    Spacer()
                }
                .padding(.top, 18)
                .padding(.bottom, 12)
                
                List {
                    ForEach(vm.tasks) { task in
                        TaskRow(task: task)
                        
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    //                                              vm.deleteTaskButtonSwiped()
                                } label: {
                                    Image(systemName: "trash")
                                        .tint(.red)
                                }
                            }
                    }
                }
                .clipped()
            }
        }
        .transition(.opacity)
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func CompletedTasksList() -> some View {
        VStack(spacing: 1) {
            if !vm.completedTasks.isEmpty {
                HStack {
                    Text("Completed task", bundle: .module)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.labelTertiary)
                    
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
                    VStack(spacing: 2) {
                        ForEach(vm.completedTasks) { task in
                            TaskRow(task: task)
                        }
                    }
                }
            }
        }
        .transition(.opacity)
        .padding(.horizontal, 16)
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
