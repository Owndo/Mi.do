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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Binding var mainViewIsOpen: Bool
    
    @FocusState var notesFocusState: Bool
    
    @State private var vm = NotesVM()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    VStack {
                        Spacer()
                        
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
                            .padding([.top, .horizontal])
                            .padding(.bottom, notesFocusState ? 20 : 80)
                        
                        MockView()
                    }
                }
            }
            .onTapGesture {
                notesFocusState = true
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    KeyboardSafeAreaInset()
                }
            }
//            .customBlurForContainer(colorScheme: colorScheme)
            .onChange(of: notesFocusState) { _, _ in
                vm.saveNotes()
            }
        }
        .sensoryFeedback(.selection, trigger: mainViewIsOpen)
    }
    
    //MARK: - Mock View
    @ViewBuilder
    private func MockView() -> some View {
        if vm.profileModel.notes.isEmpty && notesFocusState == false {
            VStack {
                Spacer(minLength: 150)
                
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
    @ViewBuilder
    private func KeyboardSafeAreaInset() -> some View {
        if notesFocusState {
            if #available(iOS 26.0, *) {
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
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .glassEffect()
            } else {
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
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 16)
                .background(
                    colorScheme.backgroundColor()
                )
                .padding(.horizontal, horizontalSizeClass == .regular ? -20 : -16)
            }
        }
    }
}

#Preview {
    NotesView(mainViewIsOpen: .constant(false))
}
