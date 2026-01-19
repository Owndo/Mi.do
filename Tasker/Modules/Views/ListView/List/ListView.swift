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
                
            } label: {
                TaskRow(task: task)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
            }
            
            //MARK: - Context Menu
            
            .contextMenu {
                ControlGroup {
                    // Open task
                    Button {
                        vm.taskTapped(task)
                    } label: {
                        VerticalButtonLabel(text: "Share", systemImage: "square.and.arrow.up")
                    }
                    
                    // Uncomplete task
                    Button {
                        Task {
                            await vm.checkMarkTapped(task: task)
                        }
                    } label: {
                        if vm.checkCompletedTaskForToday(task: task) {
                            VerticalButtonLabel(text: "Undo", systemImage: "circle")
                        } else {
                            VerticalButtonLabel(text: "Done", systemImage: "checkmark.circle")
                        }
                    }
                    
                    // Delete task
                    Button(role: .destructive) {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        VerticalButtonLabel(text: "Delete", systemImage: "trash")
                    }
                }
            } preview: {
                TaskViewPreview(listVM: vm, task: task)
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
    
    //MARK: Task row
    
    @ViewBuilder
    private func TaskRow(task: UITaskModel) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                TaskCheckMark(complete: vm.checkCompletedTaskForToday(task: task), task: task) {
                    Task {
                        await vm.checkMarkTapped(task: task)
                    }
                }
                
                HStack {
                    Text(LocalizedStringKey(vm.taskTitle(task: task)), bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(task.taskRowColor(colorScheme: colorScheme).invertedPrimaryLabel(task: task, colorScheme))
                        .font(.callout)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack(spacing: 12) {
                NotificationDeadlineDate(task: task)
                    .allowsHitTesting(vm.isTaskHasDeadline(task: task))
                    .onTapGesture {
                        vm.showDedalineButtonTapped(task: task)
                    }
                
                PlayButton(task: task)
            }
        }
        .taskDeleteDialog(isPresented: vm.dialogBinding(for: task), task: task) { value in
            await vm.deleteButtonTapped(task: task, deleteCompletely: value)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 11)
        .background(
            withAnimation {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        task.taskRowColor(colorScheme: colorScheme)
                    )
            }
        )
        .frame(height: 52)
    }
    
    //MARK: - Notification/Deadline date
    @ViewBuilder
    private func NotificationDeadlineDate(task: UITaskModel) -> some View {
        if vm.showDeadlinePicker {
            Text(LocalizedStringKey(vm.timeRemainingString(task: task)), bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(vm.isTaskOverdue(task: task) ? .accentRed : task.taskRowColor(colorScheme: colorScheme).invertedTertiaryLabel(task: task, colorScheme))
                .underline(true, pattern: .dot, color: vm.isTaskOverdue(task: task) ? .accentRed : .labelQuaternary)
        } else {
            Text(Date(timeIntervalSince1970: task.notificationDate), format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(task.taskRowColor(colorScheme: colorScheme).invertedTertiaryLabel(task: task, colorScheme))
                .underline(vm.isTaskHasDeadline(task: task) ? true : false, pattern: .dot, color: vm.isTaskOverdue(task: task) ? .accentRed : .labelQuaternary)
                .padding(.leading, 6)
                .lineLimit(1)
        }
    }
    
    //MARK: - Play Button
    
    @ViewBuilder
    private func PlayButton(task: UITaskModel) -> some View {
        ZStack {
            Circle()
                .fill(task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(task: task, colorScheme))
            
            if task.audio != nil {
                Image(systemName: vm.playing ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        Task {
                            await vm.playButtonTapped(task: task)
                        }
                    }
            } else {
                Image(systemName: "plus").bold()
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
            }
        }
        .frame(width: 28, height: 28)
    }
    
    //MARK: - Menu Buttons
    
    @ViewBuilder
    private func VerticalButtonLabel(text: LocalizedStringKey, systemImage: String) -> some View {
        VStack {
            Text(text, bundle: .module)
            
            Image(systemName: systemImage)
        }
    }
}

struct TaskViewPreview: View {
    
    var listVM: ListVM
    var task: UITaskModel
    
    var body: some View {
        TaskView(taskVM: listVM.tasksVM.first(where: { $0.task.id == task.id })!, preview: true)
            .task {
                listVM.previewTask = task
            }
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
