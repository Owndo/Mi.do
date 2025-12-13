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
            Circle()
                .fill(task.taskColor.color(for: colorScheme)
                    .invertedBackgroundTertiary(task: task, colorScheme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    Circle()
                        .stroke(task.taskColor.color(for: colorScheme)
                            .invertedSeparartorSecondary(task: task, colorScheme),
                            lineWidth: 1)
                )
                .liquidIfAvailable(glass: .clear, isInteractive: true)
            
            if animate {
                Image(systemName: "checkmark")
                    .foregroundStyle(task.taskColor.color(for: colorScheme).invertedSecondaryLabel(task: task, colorScheme))
                    .bold()
                    .transition(.scale)
            }
        }
        .frame(width: 26, height: 26)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                animate.toggle()
            }
            
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


//
//  TaskCheckMark.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

//import SwiftUI
//import Models
//
//public struct TaskCheckMark: View {
//    @Environment(\.colorScheme) var colorScheme
//    
//    @State var animate = false
//    
//    var complete: Bool
//    var task: UITaskModel
//    var action: () -> Void
//    
//    public init(complete: Bool, task: UITaskModel, action: @escaping () -> Void) {
//        self.complete = complete
//        self.task = task
//        self.action = action
//        animate = complete
//    }
//    
//    public var body: some View {
//        ZStack {
//            Circle()
//                .fill(task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(task: task, colorScheme))
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                .overlay(
//                    Circle()
//                        .stroke(task.taskColor.color(for: colorScheme).invertedSeparartorSecondary(task: task, colorScheme), lineWidth: 1)
//                )
//            
//            Image(systemName: complete ? "checkmark" : "circle.fill")
//                .foregroundStyle(complete ? task.taskColor.color(for: colorScheme).invertedSecondaryLabel(task: task, colorScheme) : .clear)
//                .contentTransition(.symbolEffect(.replace))
//                .bold()
//        }
//        .frame(width: 26, height: 26)
//        .onTapGesture {
//            //            animate.toggle()
//            
////            Task {
////                try await Task.sleep(for: .seconds(0.3))
//                action()
////            }
//        }
////        .animation(.default, value: complete)
//    }
//}
//
//#Preview {
//    TaskCheckMark(complete: true, task: mockModel(), action: {})
//}
