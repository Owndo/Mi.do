//
//  TaskRow.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import SwiftUI
import Models
import TaskView
import UIComponents

struct TaskRow: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm: TaskRowVM

    var task: MainModel
    
    init(task: MainModel) {
        self._vm = State(wrappedValue: TaskRowVM(task: task))
        self.task = task
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
            .sheet(item: $vm.selectedTask) { task in
                TaskView(model: task)
            }
            .sensoryFeedback(.selection, trigger: vm.selectedTask)
            .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            .sensoryFeedback(.decrease, trigger: vm.taskDeleteTrigger)
    }
    
    //MARK: Task row
    @ViewBuilder
    private func TaskRow() -> some View {
        List {
            ForEach(0..<1) { _ in
                HStack(spacing: 0) {
                    HStack(spacing: 12) {
                        TaskCheckMark(complete: vm.checkCompletedTaskForToday(), task: vm.task.value) {
                            vm.checkMarkTapped()
                        }
                        
                        ScrollView(.horizontal) {
                            Text(LocalizedStringKey(vm.task.value.title), bundle: .module)
                                .font(.system(.body, design: .rounded, weight: .regular))
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(vm.task.value.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                                .font(.callout)
                                .lineLimit(1)
                        }
                        .scrollDisabled(vm.disabledScroll)
                        .scrollIndicators(.hidden)
                    }
                    
                    HStack(spacing: 12) {
                        Text(Date(timeIntervalSince1970: vm.task.value.notificationDate), format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                            .font(.system(.subheadline, design: .rounded, weight: .regular))
                            .foregroundStyle(vm.task.value.taskColor.color(for: colorScheme).invertedTertiaryLabel(colorScheme))
                            .padding(.leading, 6)
                            .lineLimit(1)
                        
                        PlayButton()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.selectedTaskButtonTapped()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 11)
                .background(
                    vm.task.value.taskColor.color(for: colorScheme)
                )
                .frame(maxWidth: .infinity)
                .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    vm.deleteTaskButtonSwiped()
                } label: {
                    Image(systemName: "trash")
                        .tint(.red)
                }
            }
            //TODO: - Next day for task
            //            .swipeActions(edge: .leading, allowsFullSwipe: false) {
            //                Button {
            //                    vm.updateNotificationTimeForDueDateSwipped(task: task)
            //                } label: {
            //                    Image(systemName: "arrow.forward.circle.fill")
            //                        .tint(colorScheme.accentColor())
            //                }
            //            }
        }
        .listStyle(PlainListStyle())
        .listRowSeparator(.hidden)
        .frame(height: vm.listRowHeight)
        .scrollDisabled(true)
    }
    
    //MARK: - Play Button
    @ViewBuilder
    private func PlayButton() -> some View {
        ZStack {
            Circle()
                .fill(vm.task.value.taskColor.color(for: colorScheme).invertedBackgroundTertiary(colorScheme))
            
            if vm.task.value.audio != nil {
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
    TaskRow(task: mockModel())
}

struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
