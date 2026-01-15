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

public struct ListView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable public var vm: ListVM
    
    public init(vm: ListVM) {
        self.vm = vm
    }
    
    public var body: some View {
        ListBase()
            .ignoresSafeArea(edges: [.top, .horizontal])
            .animation(.default, value: vm.completedTasksHidden)
            .animation(.default, value: vm.activeTasks)
            .animation(.default, value: vm.completedTasks)
            .sensoryFeedback(.impact, trigger: vm.completedTasksHidden)
            .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            .sensoryFeedback(.decrease, trigger: vm.deletTaskButtonTrigger)
    }
    
    @ViewBuilder
    private func ListBase() -> some View {
        List {
            ActiveTasks()
            
            CompletedTasks()
        }
        .customBlurForContainer(colorScheme: colorScheme, apply: true)
        .listSectionSpacing(.compact)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .listStyle(.inset)
    }
    
    
    //MARK: - Active tasks
    
    @ViewBuilder
    private func ActiveTasks() -> some View {
        //MARK: Tasks section
        if !vm.activeTasks.isEmpty {
            Text("Tasks", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelTertiary)
                .listRowBackground(Color.clear)
        }
        
        ForEach(vm.activeTasks) { task in
            Button {
                vm.taskTapped(task)
            } label: {
                TaskRow(task: task)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
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
                        await vm.checkMarkTapped(task: task)
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
                            .frame(width: 10, height: 10)
                            .tint(colorScheme.backgroundColor())
                        
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
    }
    
    //MARK: - Completed tasks
    
    @ViewBuilder
    private func CompletedTasks() -> some View {
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
                Task {
                    await vm.completedTaskViewChange()
                }
            }
        }
        
        //MARK: - For Each
        
        if !vm.completedTasksHidden {
            ForEach(vm.completedTasks) { task in
                Button {
                    //                        vm.taskTapped(task)
                } label: {
                    TaskRow(task: task)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 8)
                }
                //MARK: - Context Menu
                
                .contextMenu {
                    // Open task
                    Button {
                        //                            vm.taskTapped(task.task)
                    } label: {
                        Label("Open task", systemImage: "arrowshape.turn.up.right")
                    }
                    
                    // Uncomplete task
                    Button {
                        Task {
                            await vm.checkMarkTapped(task: task)
                        }
                    } label: {
                        Label("Uncomplete task", systemImage: "circle")
                    }
                    
                    // Delete task
                    Button(role: .destructive) {
                        vm.deleteTaskButtonSwiped(task: task)
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                } preview: {
                    //                        TaskView(taskVM: TaskVM., preview: <#T##Bool#>)
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
