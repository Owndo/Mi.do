//
//  ListView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/26/25.
//

import SwiftUI
import UIComponents
import Models
import TaskView

//For Preview
import RecorderManager
import StorageManager

public struct ListView: View {
    @Environment(\.appearanceManager) private var appearanceManager
    @Environment(\.colorScheme) private var colorScheme
    
    @Bindable public var vm: ListVM
    
    public init(vm: ListVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ListBase()
            .padding(.horizontal, 8)
            .ignoresSafeArea()
            .animation(.easeInOut, value: vm.completedTasksHidden)
            .animation(.default, value: vm.activeTasks)
            .animation(.default, value: vm.completedTasks)
            .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
            .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            .sensoryFeedback(.decrease, trigger: vm.deletTaskButtonTrigger)
    }
    
    @ViewBuilder
    private func ListBase() -> some View {
        List {
            Section {
                ActiveTasks()
            } header: {
                if !vm.activeTasks.isEmpty {
                    Text("Tasks", bundle: .module)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.labelTertiary)
                        .listRowBackground(Color.clear)
                }
            }
            
            Section {
                CompletedTasks()
            } header: {
                if !vm.completedTasks.isEmpty {
                    HStack {
                        Text("Completed task", bundle: .module)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.labelTertiary)
                        
                        Spacer()
                        
                        //                        Text(vm.completedTasksHidden ? "Show" : "Hide")
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(vm.completedTasksHidden ? 180 : 0))
                            .symbolEffect(.bounce, value: vm.completedTasksHidden)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
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
            }
        }
        .safeAreaInset(edge: .top) {
            Color.clear
                .frame(maxHeight: 150)
        }
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.inset)
    }
    
    
    //MARK: - Active tasks
    
    @ViewBuilder
    private func ActiveTasks() -> some View {
        ForEachRespresentable(vm.activeTasks)
    }
    
    //MARK: - Completed tasks
    
    @ViewBuilder
    private func CompletedTasks() -> some View {
        //MARK: - For Each
        
        if !vm.completedTasksHidden {
            ForEachRespresentable(vm.completedTasks)
        }
    }
    
    //MARK: - For each representable
    
    @ViewBuilder
    private func ForEachRespresentable(_ tasks: [UITaskModel]) -> some View {
        ForEach(tasks) { task in
            Button {
                vm.taskTapped(task)
            } label: {
                TaskRowView(task: task, vm: vm)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
            }
            
            //MARK: - Swipe action
            
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
                            .tint(appearanceManager.backgroundColor)
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
}

struct TaskViewPreview: View {
    
    var listVM: ListVM
    var task: UITaskModel
    
    var body: some View {
        TaskView(taskVM: listVM.tasksVM.first(where: { $0.task.id == task.id })!, preview: true)
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
