//
//  TaskCheckMark.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI
import Models

public struct TaskCheckMark: View {
    @Environment(\.colorScheme) var colorScheme
    
    var complete: Bool
    var task: TaskModel
    var action: () -> Void
    
    public init(complete: Bool, task: TaskModel, action: @escaping () -> Void) {
        self.complete = complete
        self.task = task
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(colorScheme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(task.taskColor.color(for: colorScheme).invertedSeparartorSecondary(colorScheme), lineWidth: 1)
                )
            if complete {
                Image(systemName: "checkmark")
                    .foregroundStyle(task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                    .bold()
            }
        }
        .frame(width: 24, height: 24)
        .onTapGesture {
            action()
        }
    }
}

#Preview {
    TaskCheckMark(complete: true, task: mockModel().value, action: {})
}
