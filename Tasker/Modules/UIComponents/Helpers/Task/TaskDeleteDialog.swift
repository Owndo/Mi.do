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
    
    let task: MainModel
    let message: String
    let isSingleTask: Bool
    let onDelete: (MainModel, Bool) -> Void
    let dismissAction: DismissAction?
    
    public func body(content: Content) -> some View {
        content
            .confirmationDialog("", isPresented: $isPresented) {
                if isSingleTask {
                    Button(role: .destructive) {
                        Task {
                            dismissAction?()
                            try await Task.sleep(nanoseconds: 50_000_000)
                            onDelete(task, true)
                        }
                    } label: {
                        Text("Delete this task")
                    }
                } else {
                    Button(role: .destructive) {
                        Task {
                            dismissAction?()
                            try await Task.sleep(nanoseconds: 50_000_000)
                            onDelete(task, false)
                        }
                    } label: {
                        Text("Delete only this task")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            dismissAction?()
                            try await Task.sleep(nanoseconds: 50_000_000)
                            onDelete(task, true)
                        }
                    } label: {
                        Text("Delete all of these tasks")
                    }
                }
            } message: {
                Text(message)
            }
    }
}

public extension View {
    /// Confirmation dialog
    func taskDeleteDialog(isPresented: Binding<Bool>, task: MainModel, message: String, isSingleTask: Bool, onDelete: @escaping (MainModel, Bool) -> Void, dismissButton: DismissAction? = nil) -> some View {
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
