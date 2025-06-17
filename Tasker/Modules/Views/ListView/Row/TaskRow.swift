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
    @Environment(\.colorScheme) var colorTheme
    
    @State private var vm = TaskRowVM()
    
    var task: MainModel
    
    //MARK: - Body
    var body: some View {
        TaskRow()
            .sheet(item: $vm.selectedTask) { task in
                TaskView(mainModel: task)
            }
            .taskDeleteDialog(
                isPresented: $vm.confirmationDialogIsPresented,
                task: task,
                message: vm.messageForDelete,
                isSingleTask: vm.singleTask,
                onDelete: vm.deleteButtonTapped
            )
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
                        TaskCheckMark(complete: vm.checkCompletedTaskForToday(task: task)) {
                            vm.checkMarkTapped(task: task)
                        }
                        
                        ScrollView(.horizontal) {
                            Text(task.value.title)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(.labelPrimary)
                                .font(.callout)
                                .lineLimit(1)
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    HStack(spacing: 12) {
                        Text("\(Date(timeIntervalSince1970: task.value.notificationDate), format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))")
                            .font(.subheadline)
                            .foregroundStyle(.labelTertiary.opacity(0.6))
                            .padding(.leading, 6)
                            .lineLimit(1)
                        
                        PlayButton()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.selectedTaskButtonTapped(task)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 11)
                .background(
                    task.value.taskColor.color(for: colorTheme)
                )
                .frame(maxWidth: .infinity)
                .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button {
                    vm.deleteTaskButtonSwiped(task: task)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.labelSecondary)
                        .tint(.accentRed)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    vm.updateNotificationTimeForDueDateSwipped(task: task)
                } label: {
                    Image(systemName: "arrow.forward.circle.fill")
                        .foregroundStyle(.labelSecondary)
                        .tint(.green)
                }
            }
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
                .fill(
                    .labelTertiary.opacity(0.2)
                )
            
            if task.value.audio != nil {
                Image(systemName: vm.playing ? "pause.fill" : "play.fill")
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
            } else {
                Image(systemName: "plus").bold()
                    .foregroundStyle(.white)
                    .animation(.default, value: vm.playing)
            }
        }
        .frame(width: 28, height: 28)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            Task {
                await vm.playButtonTapped(task: task)
            }
        }
    }
}

#Preview {
    TaskRow(task: mockModel())
}
