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
    @Environment(\.dismiss) var dismissButton
    @Binding var isPresented: Bool
    
    let task: UITaskModel
    var message: LocalizedStringKey = ""
    var isSingleTask: Bool = true
    let onDelete: (Bool) async -> Void
    
    public init(isPresented: Binding<Bool>, task: UITaskModel, onDelete: @escaping (Bool) async -> Void) {
        self._isPresented = isPresented
        self.task = task
        self.onDelete = onDelete
        
        if task.repeatTask == .never {
            isSingleTask = true
            message = "Delete task?"
        } else {
            isSingleTask = false
            message = "This's a recurring task."
        }
    }
    
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
                            dismissButton()
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
        dismissButton()
        try? await Task.sleep(nanoseconds: 30_000_000)
        await onDelete(true)
    }
}

public extension View {
    /// Confirmation dialog
    func taskDeleteDialog(isPresented: Binding<Bool>, task: UITaskModel, onDelete: @escaping (Bool) async -> Void, dismissButton: DismissAction? = nil) -> some View {
        modifier(
            TaskDeleteDialog(
                isPresented: isPresented,
                task: task,
//                message: message,
//                isSingleTask: isSingleTask,
//                dismissAction: dismissButton,
                onDelete: onDelete
            )
        )
    }
}
