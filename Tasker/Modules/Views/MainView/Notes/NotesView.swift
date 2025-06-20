//
//  NotesView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/19/25.
//

import SwiftUI

struct NotesView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("notes") var notes = ""
    
    @Binding var mainViewIsOpen: Bool
    
    @FocusState var notesFocusState: Bool
    
    var body: some View {
        ZStack {
            TextEditor(text: $notes)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
                .focused($notesFocusState)
                .scrollDismissesKeyboard(.immediately)
                .textEditorStyle(.plain)
                .safeAreaInset(edge: .bottom) {
                    KeyboardSafeAreaInset()
                }
                .padding(.horizontal)
            
            BackButton()
            
            MockView()
            
        }
        .sensoryFeedback(.selection, trigger: mainViewIsOpen)
    }
    
    //MARK: - Mock View
    @ViewBuilder
    private func MockView() -> some View {
        if notes.isEmpty && notesFocusState == false {
            VStack {
                Image(systemName: "note.text.badge.plus")
                    .foregroundStyle(.labelQuintuple)
                    .scaleEffect(1.5)
                
                Text("Tap and add your notes here...")
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.labelQuaternary)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .padding(.top, 3)
                
            }
        }
    }
    
    //MARK: - Keyboard commands
    @ViewBuilder private func KeyboardSafeAreaInset() -> some View {
        if notesFocusState {
            HStack {
                
                Spacer()
                
                Button {
                    notesFocusState = false
                } label: {
                    Text("Done")
                        .foregroundStyle(colorScheme.elementColor.hexColor())
                        .padding(.vertical, 9)
                }
            }
            .padding(.horizontal, 16)
            .background(
                colorScheme.backgroundColor.hexColor()
            )
        }
    }
    
    //MARK: - Back Button
    @ViewBuilder
    private func BackButton() -> some View {
        VStack {
            
            Spacer()
            
            Button {
                mainViewIsOpen = true
            } label: {
                VStack {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 42))
                        .foregroundStyle(colorScheme.elementColor.hexColor())
                        .frame(width: 64, height: 64)
                        .padding(13)
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: colorScheme.elementColor.hexColor(), radius: 3)
                        )
                }
            }
            
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    NotesView(mainViewIsOpen: .constant(false))
}
