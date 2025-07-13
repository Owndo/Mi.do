//
//  MainView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import UIComponents
import Calendar
import ListView
import TaskView
import Profile

public struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: MainVM
    
    @State var showingAlert = false
    
    @FocusState var focusState: Bool
    
    public init(vm: MainVM) {
        self._vm = Bindable(wrappedValue: vm)
    }
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                Color(colorScheme.backgroundColor.hexColor())
                    .ignoresSafeArea()
                
                NotesView(mainViewIsOpen: $vm.mainViewIsOpen)
            }
            .sheet(isPresented: $vm.mainViewIsOpen) {
                MainViewBase()
                    .sheet(isPresented: $showingAlert) {
                        ProfileView()
                    }
            }
            .navigationDestination(for: MainVM.Destination.self) { destination in
                switch destination {
                case .main:
                    MainView(vm: vm)
                case .calendar:
                    MonthView(mainViewIsOpen: $vm.mainViewIsOpen, path: $vm.path)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.calendarButtonTapped()
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(colorScheme.elementColor.hexColor())
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    TextField("Write your title here 🎯", text: $vm.profileModel.value.customTitle)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            vm.profileModelSave()
                        }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAlert = true
                    } label: {
                        Image(systemName: "person.circle")
                            .foregroundStyle(colorScheme.elementColor.hexColor())
                    }
                }
            }
            .onChange(of: vm.currentlyTime) { newValue, oldValue in
                Task {
                    await vm.stopAfterCheck(newValue)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: vm.isRecording)
            
        }
    }
    
    //MARK: - MainViewBase
    @ViewBuilder
    private func MainViewBase() -> some View {
        ZStack {
            Color(colorScheme.backgroundColor.hexColor())
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                WeekView()
                    .padding(.top, 17)
                
                ListView()
                
                Spacer()
            }
            .ignoresSafeArea(edges: .bottom)
            
            VStack {
                
                Spacer()
                
                if vm.presentationPosition == PresentationMode.base.detent {
                    withAnimation {
                        CreateButton()
                            .fixedSize()
                    }
                }
            }
            .ignoresSafeArea(.keyboard)
        }
        .sheet(item: $vm.model) { model in
            TaskView(mainModel: model)
        }
        .alert(item: $vm.alert) { alert in
            alert.alert
        }
        .presentationDetents(PresentationMode.detents, selection: $vm.presentationPosition)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(true)
        .presentationCornerRadius(16)
    }
    
    //MARK: - Create Button
    @ViewBuilder
    private func CreateButton() -> some View {
        VStack {
            Spacer()
            
            RecordButton(isRecording: $vm.isRecording, showTips: vm.showTips, progress: vm.progress, countOfSec: vm.currentlyTime, animationAmount: vm.decibelLvl)
                .disabled(vm.disabledButton)
                .onTapGesture {
                    Task {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        await vm.handleButtonTap()
                    }
                }
                .simultaneousGesture(
                    LongPressGesture().onEnded({ _ in
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            try await vm.startAfterChek()
                        }
                    })
                )
                .onChange(of: vm.currentlyTime) { newValue, _ in
                    if newValue > 15.0 && vm.recordingState == .recording {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            await vm.stopRecord(isAutoStop: true)
                        }
                    }
                }
                .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .blendMode(colorScheme == .dark ? .normal : .darken)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainView(vm: MainVM())
}
