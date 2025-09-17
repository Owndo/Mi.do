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
    
    @State var animate = false
    
    var complete: Bool
    var task: UITaskModel
    var action: () -> Void
    
    public init(complete: Bool, task: UITaskModel, action: @escaping () -> Void) {
        self.complete = complete
        self.task = task
        self.action = action
        animate = complete
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(task: task, colorScheme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(task.taskColor.color(for: colorScheme).invertedSeparartorSecondary(task: task, colorScheme), lineWidth: 1)
                )
            
            if animate {
                Image(systemName: "checkmark")
                    .foregroundStyle(task.taskColor.color(for: colorScheme).invertedSecondaryLabel(task: task, colorScheme))
                    .transition(.symbolEffect(.disappear))
                    .bold()
            }
        }
        .frame(width: 24, height: 24)
        .onTapGesture {
            animate.toggle()
            
            Task {
                try await Task.sleep(for: .seconds(0.2))
                action()
            }
        }
        .onAppear {
            animate = complete
        }
    }
}

#Preview {
    TaskCheckMark(complete: true, task: mockModel(), action: {})
}
