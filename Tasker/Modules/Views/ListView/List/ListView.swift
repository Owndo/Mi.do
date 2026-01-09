//
//  ListView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import SwiftUI
import UIComponents
import Models
import TaskRowView
import TaskView

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
            if !vm.tasksRowVM.isEmpty {
                Text("Tasks", bundle: .module)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelTertiary)
                    .listRowBackground(Color.clear)
            }
            
            ForEach(vm.tasksRowVM, id: \.self) { task in
                Button {
                    vm.taskTapped(task.task)
                } label: {
                    TaskRow(vm: task)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 22)
                }
                //MARK: - Context menu
                
                .contextMenu {
                    Button {
                        //MARK: Open task
                        
                    } label: {
                        Label("Open task", systemImage: "arrowshape.turn.up.right")
                    }
                    
                    Button {
                        //MARK: Complete task
                        Task {
                            await task.checkMarkTapped()
                        }
                    } label: {
                        Label("Complete task", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive) {
                        //MARK: Delete task
                        task.deleteTaskButtonSwiped()
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                } preview: {
                    //                    TaskView(taskVM: TaskVM(mainModel: task), preview: true)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        task.deleteTaskButtonSwiped()
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
            if !vm.completedTasksRowVM.isEmpty {
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
                    Task {
                        await vm.completedTaskViewChange()
                    }
                }
            }
            
            if !vm.completedTasksHidden {
                ForEach(vm.completedTasksRowVM, id: \.self) { task in
                    Button {
                        vm.taskTapped(task.task)
                    } label: {
                        TaskRow(vm: task)
                            .padding(.vertical, 2)
                            .padding(.horizontal, 22)
                    }
                    .contextMenu {
                        Button {
                            vm.taskTapped(task.task)
                        } label: {
                            Label("Open task", systemImage: "arrowshape.turn.up.right")
                        }
                        
                        Button {
                            Task {
                                await task.checkMarkTapped()
                            }
                        } label: {
                            Label("Uncomplete task", systemImage: "circle")
                        }
                        
                        Button(role: .destructive) {
                            task.deleteTaskButtonSwiped()
                        } label: {
                            Label("Delete task", systemImage: "trash")
                        }
                    } preview: {
                        //                        TaskView(taskVM: TaskVM., preview: <#T##Bool#>)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            task.deleteTaskButtonSwiped()
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
        .customBlurForContainer(colorScheme: colorScheme, apply: true)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.inset)
        .animation(.default, value: vm.completedTasksHidden)
        .animation(.spring, value: vm.tasksRowVM)
        .animation(.spring, value: vm.completedTasksRowVM)
    }
}

#Preview {
    @Previewable
    @State var listVM: ListVM?
    
    VStack {
        if let listVM {
            ListView(vm: listVM)
        } else {
            ProgressView()
        }
    }
    .task {
        listVM = await ListVM.createPreviewListVM()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
