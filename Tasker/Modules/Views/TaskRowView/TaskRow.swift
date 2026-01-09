//
//  TaskRow.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import SwiftUI
import Models
import UIComponents

struct TaskRow: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var vm: TaskRowVM
    
    
    init(vm: TaskRowVM) {
        self.vm = vm
    }
    
    //MARK: - Body
    
    var body: some View {
        TaskRow()
                    .taskDeleteDialog(
                        isPresented: $vm.confirmationDialogIsPresented,
                        task: vm.task,
                        message: vm.messageForDelete,
                        isSingleTask: vm.singleTask,
                        onDelete: vm.deleteButtonTapped
                    )
//                    .sheet(item: $vm.taskVM) { taskVM in
//                        TaskView(taskVM: taskVM)
//                    }
            .sensoryFeedback(.selection, trigger: vm.selectedTask)
            .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            .sensoryFeedback(.decrease, trigger: vm.taskDeleteTrigger)
            .sensoryFeedback(.selection, trigger: vm.showDeadlinePicker)
            .animation(.default, value: vm.showDeadlinePicker)
    }
    
    //MARK: Task row
    
    @ViewBuilder
    private func TaskRow() -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                TaskCheckMark(complete: vm.completedForToday, task: vm.task) {
                    Task {
                        await vm.checkMarkTapped()
                    }
                }
                
                HStack {
                    Text(LocalizedStringKey(vm.taskTitle), bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(vm.task.taskRowColor(colorScheme: colorScheme).invertedPrimaryLabel(task: vm.task, colorScheme))
                        .font(.callout)
                        .lineLimit(1)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            HStack(spacing: 12) {
                NotificationDeadlineDate()
                    .allowsHitTesting(vm.isTaskHasDeadline())
                    .onTapGesture {
                        vm.showDedalineButtonTapped()
                    }
                
                PlayButton()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 11)
        .background(
            withAnimation {
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        vm.task.taskRowColor(colorScheme: colorScheme)
                    )
            }
        )
        .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
        .frame(height: 52)
    }
    
    //MARK: - Notification/Deadline date
    @ViewBuilder
    private func NotificationDeadlineDate() -> some View {
        if vm.showDeadlinePicker {
            Text(vm.timeRemainingString, bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(vm.isTaskOverdue() ? .accentRed : vm.task.taskRowColor(colorScheme: colorScheme).invertedTertiaryLabel(task: vm.task, colorScheme))
                .underline(true, pattern: .dot, color: vm.isTaskOverdue() ? .accentRed : .labelQuaternary)
        } else {
            Text(Date(timeIntervalSince1970: vm.task.notificationDate), format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                .font(.system(.subheadline, design: .rounded, weight: .regular))
                .foregroundStyle(vm.task.taskRowColor(colorScheme: colorScheme).invertedTertiaryLabel(task: vm.task, colorScheme))
                .underline(vm.isTaskHasDeadline() ? true : false, pattern: .dot, color: vm.isTaskOverdue() ? .accentRed : .labelQuaternary)
                .padding(.leading, 6)
                .lineLimit(1)
        }
    }
    
    //MARK: - Play Button
    @ViewBuilder
    private func PlayButton() -> some View {
        ZStack {
            Circle()
                .fill(vm.task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(task: vm.task, colorScheme))
            
            if vm.task.audio != nil {
                Image(systemName: vm.playing ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
                    .onTapGesture {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        Task {
                            await vm.playButtonTapped()
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
    TaskRow(vm: TaskRowVM.createPreviewTaskRowVM())
}

struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
