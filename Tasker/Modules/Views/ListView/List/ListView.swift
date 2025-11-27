//
//  ListView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import SwiftUI
import UIComponents
import Models

public struct ListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable public var vm: ListVM
    
    public init(vm: ListVM) {
        self.vm = vm
    }
    
    public var body: some View {
        CustomList()
            .ignoresSafeArea(edges: [.top, .horizontal])
            .animation(.default, value: vm.completedTasksHidden)
            .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
    }
    
    //MARK: ListView
    @ViewBuilder
    private func CustomList() -> some View {
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
                        .padding(.vertical, 2)
                }
                //MARK: - Context menu
                
                .contextMenu {
                    Button {
                        //MARK: Open task
                        vm.taskTapped(task)
                    } label: {
                        Label("Open task", systemImage: "arrowshape.turn.up.right")
                    }
                    
                    Button {
                        //MARK: Complete task
                        Task {
                            await vm.checkMarkTapped(task)
                        }
                    } label: {
                        Label("Complete task", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        //MARK: Delete task
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                } preview: {
                    //                    TaskView(taskVM: TaskVM(mainModel: task), preview: true)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        if #available(iOS 26, *) {
                            Image(systemName: "trash")
                                .tint(.accentRed)
                        } else {
                            Image(systemName: "trash")
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
                            .padding(.vertical, 2)
                    }
                    .contextMenu {
                        Button {
                            vm.taskTapped(task)
                        } label: {
                            Label("Open task", systemImage: "arrowshape.turn.up.right")
                        }
                        
                        Button {
                            Task {
                                await vm.checkMarkTapped(task)
                            }
                        } label: {
                            Label("Uncomplete task", systemImage: "circle")
                        }
                        
                        Button(role: .destructive) {
                            vm.deleteTaskButtonSwiped(task: task)
                        } label: {
                            Label("Delete task", systemImage: "trash")
                        }
                    } preview: {
                        //                        TaskView(taskVM: TaskVM(mainModel: task), preview: true)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            vm.deleteTaskButtonSwiped(task: task)
                        } label: {
                            if #available(iOS 26, *) {
                                Image(systemName: "trash")
                                    .tint(.accentRed)
                            } else {
                                Image(systemName: "trash")
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
        .padding(.horizontal, 22)
        .customBlurForContainer(colorScheme: colorScheme, apply: true)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.inset)
        .animation(.default, value: vm.completedTasksHidden)
        .animation(.spring, value: vm.tasks)
        .animation(.spring, value: vm.completedTasks)
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
