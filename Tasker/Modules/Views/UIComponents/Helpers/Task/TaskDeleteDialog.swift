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

public struct TaskDeleteDialog: ViewModifier {
    @Binding var isPresented: Bool
    
    let task: UITaskModel
    let message: LocalizedStringKey
    let isSingleTask: Bool
    let dismissAction: DismissAction?
    let onDelete: (Bool) async -> Void
    
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
                            try await Task.sleep(nanoseconds: 30_000_000)
                            await onDelete(false)
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
        try? await Task.sleep(nanoseconds: 30_000_000)
        await onDelete(true)
    }
}

public extension View {
    /// Confirmation dialog
    func taskDeleteDialog(isPresented: Binding<Bool>, task: UITaskModel, message: LocalizedStringKey, isSingleTask: Bool, onDelete: @escaping (Bool) async -> Void, dismissButton: DismissAction? = nil) -> some View {
        modifier(
            TaskDeleteDialog(
                isPresented: isPresented,
                task: task,
                message: message,
                isSingleTask: isSingleTask,
                dismissAction: dismissButton,
                onDelete: onDelete
            )
        )
    }
}
