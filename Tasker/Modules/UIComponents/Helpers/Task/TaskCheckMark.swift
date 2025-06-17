//
//  TaskCheckMark.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/12/25.
//

import SwiftUI

public struct TaskCheckMark: View {
    var complete: Bool
    var action: () -> Void
    
    public init(complete: Bool, action: @escaping () -> Void) {
        self.complete = complete
        self.action = action
    }
    
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(.backgroundTertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.black.opacity(0.20), lineWidth: 1)
                )
            if complete {
                Image(systemName: "checkmark")
                    .foregroundStyle(.labelSecondary)
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
    TaskCheckMark(complete: true, action: {})
}
