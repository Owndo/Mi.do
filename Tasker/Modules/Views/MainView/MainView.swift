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
import Paywall

public struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: MainVM
    
    @FocusState var focusState: Bool
    
    public init(vm: MainVM) {
        self._vm = Bindable(wrappedValue: vm)
    }
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                colorScheme.backgroundColor()
                    .ignoresSafeArea()
                
                NotesView(mainViewIsOpen: $vm.mainViewIsOpen)
                    .disabled(vm.showPaywall)
                
                if vm.showPaywall {
                    Color.backgroundDimDark.ignoresSafeArea()
                }
            }
            .sheet(isPresented: $vm.mainViewIsOpen) {
                MainViewBase()
                    .preferredColorScheme(colorScheme)
                    .sheet(isPresented: $vm.profileViewIsOpen) {
                        ProfileView()
                            .preferredColorScheme(colorScheme)
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
                            .foregroundStyle(colorScheme.accentColor())
                    }
                    .disabled(vm.showPaywall)
                }
                
                ToolbarItem(placement: .principal) {
                    TextField("Write your title here 🎯", text: $vm.profileModel.value.customTitle)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            vm.profileModelSave()
                        }
                        .disabled(vm.showPaywall)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.profileViewButtonTapped()
                    } label: {
                        ProfilePhoto()
                    }
                    .disabled(vm.showPaywall)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: vm.isRecording)
            .sensoryFeedback(.selection, trigger: vm.profileViewIsOpen)
            .sensoryFeedback(.warning, trigger: vm.isRecording)
        }
    }
    
    //MARK: - MainViewBase
    @ViewBuilder
    private func MainViewBase() -> some View {
        ZStack {
            colorScheme.backgroundColor()
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
            
            if vm.showPaywall {
                PaywallView()
            }
        }
        .sheet(item: $vm.model) { model in
            TaskView(mainModel: model)
                .onDisappear {
                    vm.disappear()
                }
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
                .onLongPressGesture(minimumDuration: 0.5, perform: {
                    Task {
                        try await vm.startAfterChek()
                    }
                }, onPressingChanged: { _ in
                    Task {
                        await vm.createTaskButtonHolding()
                    }
                })
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
    
    //MARK: - Profile photo
    @ViewBuilder
    private func ProfilePhoto() -> some View {
        //        if let image = vm.uiImage {
        //            Image(uiImage: image)
        //                .resizable()
        //                .frame(width: 42, height: 42)
        //                .clipShape(Circle())
        //        } else {
        Image(systemName: "person.circle")
            .foregroundStyle(colorScheme.accentColor())
        //        }
    }
}

#Preview {
    MainView(vm: MainVM())
}
