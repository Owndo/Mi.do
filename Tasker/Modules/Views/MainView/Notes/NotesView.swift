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
            TextEditor(text: $vm.profileModel.notes)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
                .focused($notesFocusState)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .textEditorStyle(.plain)
                .onSubmit {
                    vm.saveNotes()
                }
                .padding(.bottom, notesFocusState ? 20 : 80)
                .safeAreaInset(edge: .bottom) {
                    KeyboardSafeAreaInset()
                }
                .padding(.horizontal)
            
            MockView()
            
        }
        .customBlurForContainer(colorScheme: colorScheme)
        .onChange(of: notesFocusState) { _, _ in
            vm.saveNotes()
        }
        .sensoryFeedback(.selection, trigger: mainViewIsOpen)
    }
    
    //MARK: - Mock View
    @ViewBuilder
    private func MockView() -> some View {
        if vm.profileModel.notes.isEmpty && notesFocusState == false {
            VStack {
                Image(systemName: "note.text.badge.plus")
                    .foregroundStyle(.labelQuintuple)
                    .scaleEffect(1.5)
                
                Text("Tap and add your notes here...", bundle: .module)
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
                    Text("Done", bundle: .module)
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
