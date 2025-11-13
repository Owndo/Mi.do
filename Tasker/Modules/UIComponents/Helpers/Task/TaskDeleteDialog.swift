//
//  TaskDeleteDialog.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

//
//  TaskDeleteDialog.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI
import Models
import Managers

public struct TaskDeleteDialog: ViewModifier {
    @Environment(StorageManager.self) var storageManager
    
    @Binding var isPresented: Bool
    
    let task: MainModel
    let message: LocalizedStringKey
    let isSingleTask: Bool
    let onDelete: (MainModel, Bool) async -> Void
    let dismissAction: DismissAction?
    
    public func body(content: Content) -> some View {
        content
            .confirmationDialog(String(""), isPresented: $isPresented) {
                if isSingleTask {
                    Button(role: .destructive) {
                        Task {
                            await deleteTask()
                        }
                    } label: {
                        Text("Delete", bundle: .module)
                    }
                } else {
                    Button(role: .destructive) {
                        Task {
                            dismissAction?()
                            try await Task.sleep(nanoseconds: 50_000_000)
                            await onDelete(task, false)
                        }
                    } label: {
                        Text("Delete only this task", bundle: .module)
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await deleteTask()
                        }
                    } label: {
                        Text("Delete all of these tasks", bundle: .module)
                    }
                }
            } message: {
                Text(message, bundle: .module)
            }
    }
    
    private func deleteTask() async {
        dismissAction?()
        storageManager.deleteAudiFromDirectory(hash: task.audio)
        try? await Task.sleep(nanoseconds: 50_000_000)
        await onDelete(task, true)
    }
}

public extension View {
    /// Confirmation dialog
    func taskDeleteDialog(isPresented: Binding<Bool>, task: MainModel, message: LocalizedStringKey, isSingleTask: Bool, onDelete: @escaping (MainModel, Bool) async -> Void, dismissButton: DismissAction? = nil) -> some View {
        modifier(
            TaskDeleteDialog(
                isPresented: isPresented,
                task: task,
                message: message,
                isSingleTask: isSingleTask,
                onDelete: onDelete,
                dismissAction: dismissButton
            )
        )
    }
}
