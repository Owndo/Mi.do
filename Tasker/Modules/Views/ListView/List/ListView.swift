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
    
    @Bindable public var vm: ListVM
    
    public init(vm: ListVM) {
        self.vm = vm
    }
    
    @State private var showBlur = false
    
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
                Button {
                    vm.taskTapped(task)
                } label: {
                    TaskRow(task: task)
                        .taskDeleteDialog(
                            isPresented: vm.dialogBinding(for: task),
                            task: task,
                            message: vm.messageForDelete,
                            isSingleTask: vm.singleTask,
                            onDelete: vm.deleteButtonTapped
                        )
                        .contentShape(Rectangle())
                        .padding(.leading, 16)
                        .padding(.trailing, 6)
                        .padding(.vertical, 2)
                }
                
                .contextMenu {
                    Button {
                        vm.taskTapped(task)
                    } label: {
                        Label("Open task", systemImage: "arrowshape.turn.up.right")
                    }
                    
                    Button {
                        vm.checkMarkTapped(task)
                    } label: {
                        Label("Complete task", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                } preview: {
                    TaskRow(task: task)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        if #available(iOS 26, *) {
                            Image(systemName: "trash")
                                .tint(.accentRed)
                        } else {
                            Image(uiImage: .delete)
                                .resizable()
                                .frame(width: 10, height: 10)
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
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(vm.completedTasksHidden ? 0 : 180))
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
                    Button {
                        vm.taskTapped(task)
                    } label: {
                        TaskRow(task: task)
                            .taskDeleteDialog(
                                isPresented: vm.dialogBinding(for: task),
                                task: task,
                                message: vm.messageForDelete,
                                isSingleTask: vm.singleTask,
                                onDelete: vm.deleteButtonTapped
                            )
                            .padding(.leading, 16)
                            .padding(.trailing, 6)
                            .padding(.vertical, 2)
                    }
                    .contextMenu {
                        Button {
                            vm.taskTapped(task)
                        } label: {
                            Label("Open task", systemImage: "arrowshape.turn.up.right")
                        }
                        
                        Button {
                            vm.checkMarkTapped(task)
                        } label: {
                            Label("Uncomplete task", systemImage: "circle")
                        }
                        
                        Button(role: .destructive) {
                            vm.deleteTaskButtonSwiped(task: task)
                        } label: {
                            Label("Delete task", systemImage: "trash")
                        }
                    } preview: {
                        TaskRow(task: task)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            vm.deleteTaskButtonSwiped(task: task)
                        } label: {
                            if #available(iOS 26, *) {
                                Image(systemName: "trash")
                                    .tint(.accentRed)
                            } else {
                                Image(uiImage: .trashRed)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 5, height: 5)
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
            
            RoundedRectangle(cornerRadius: 26)
                .fill(.clear)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
        }
        .onAppear {
            showBlur = true
        }
        .padding(.trailing, 10)
        .customBlurForContainer(colorScheme: colorScheme, apply: showBlur)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.inset)
        .ignoresSafeArea(edges: .top)
        .animation(.default, value: vm.completedTasksHidden)
        .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
        .animation(.spring, value: vm.tasks)
        .animation(.spring, value: vm.completedTasks)
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
    ListView(vm: ListVM())
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
