//
//  NotesView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 6/19/25.
//

import SwiftUI
import UIComponents

struct NotesView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var mainViewIsOpen: Bool
    
    @FocusState var notesFocusState: Bool
    
    @State private var vm = NotesVM()
    
    var body: some View {
        ZStack {
            TextEditor(text: $vm.profileModel.value.notes)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
                .focused($notesFocusState)
                .scrollDismissesKeyboard(.immediately)
                .textEditorStyle(.plain)
                .onSubmit {
                    vm.saveNotes()
                }
                .safeAreaInset(edge: .bottom) {
                    KeyboardSafeAreaInset()
                }
                .padding(.horizontal)
            
            MockView()
            
        }
        .onChange(of: notesFocusState) { _, _ in
            vm.saveNotes()
        }
        .sensoryFeedback(.selection, trigger: mainViewIsOpen)
    }
    
    //MARK: - Mock View
    @ViewBuilder
    private func MockView() -> some View {
        if vm.profileModel.value.notes.isEmpty && notesFocusState == false {
            VStack {
                Image(systemName: "note.text.badge.plus")
                    .foregroundStyle(.labelQuintuple)
                    .scaleEffect(1.5)
                
                Text("Tap and add your notes here...")
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.labelQuaternary)
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
                    vm.saveNotes()
                } label: {
                    Text("Done")
                        .foregroundStyle(colorScheme.accentColor())
                        .padding(.vertical, 9)
                }
            }
            .padding(.horizontal, 16)
            .background(
                colorScheme.backgroundColor()
            )
        }
    }
}

#Preview {
    NotesView(mainViewIsOpen: .constant(false))
}
