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
import StoreKit

public struct MainView: View {
    @Environment(\.requestReview) var requestReview
    @Environment(\.colorScheme) var colorScheme
    
    @Bindable var vm: MainVM
    
    @FocusState var focusState: Bool
    
    public init(vm: MainVM) {
        self._vm = Bindable(wrappedValue: vm)
    }
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                CustomBackground()
                
                NotesView(mainViewIsOpen: $vm.mainViewIsOpen)
                    .disabled(vm.showPaywall)
                    .disabled(vm.presentationPosition == .fraction(0.93))
                
                if vm.showPaywall {
                    Color.backgroundDimDark.ignoresSafeArea()
                }
            }
            .sheet(isPresented: $vm.mainViewIsOpen) {
                MainViewBase()
                    .overlay(
                        GlowEffect(decibelLevel: vm.decibelLvl)
                            .opacity(vm.isRecording ? 1 : 0)
                    )
                    .sheet(item: $vm.sheetDestination) { destination in
                        switch destination {
                        case .details(let taskModel):
                            TaskView(taskVM: taskModel)
                                .preferredColorScheme(colorScheme)
                                .onDisappear {
                                    vm.disappear()
                                }
                        case .profile:
                            ProfileView()
                                .preferredColorScheme(colorScheme)
                        }
                      
                    }
                    .sheet(isPresented: $vm.onboardingManager.sayHello) {
                        SayHelloView()
                            .preferredColorScheme(colorScheme)
                            .presentationDragIndicator(.visible)
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
            //MARK: - Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.calendarButtonTapped()
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundStyle(colorScheme.accentColor())
                    }
                    .disabled(vm.showPaywall)
                    .disabled(vm.disabledButton)
                }
                
                ToolbarItem(placement: .principal) {
                    TextField(text: $vm.profileModel.customTitle, prompt: Text("Write title 🎯", bundle: .module)) {}
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.labelPrimary)
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
                    .disabled(vm.disabledButton)
                }
            }
            .toolbarBackground(osVersion.majorVersion >= 26 ? .visible : .hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: vm.isRecording)
            .animation(.default, value: vm.presentationPosition)
            .sensoryFeedback(.selection, trigger: vm.profileViewIsOpen)
            .sensoryFeedback(.warning, trigger: vm.isRecording)
        }
    }
    
    //MARK: - MainViewBase
    @ViewBuilder
    private func MainViewBase() -> some View {
        ZStack {
            colorScheme.backgroundColor().ignoresSafeArea()
            
            VStack(spacing: 0) {
                WeekView()
                    .padding(.top, 17)
                    .disabled(vm.disabledButton)
                
                ListView()
                    .disabled(vm.disabledButton)
                
                Spacer()
            }
            
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
        .overlay(
            GlowEffect(decibelLevel: vm.decibelLvl)
                .opacity(vm.isRecording ? 1 : 0)
        )
        .onChange(of: vm.askReview) { _ , newValue in
            requestReview()
        }
        .alert(item: $vm.alert) { alert in
            alert.alert
        }
        .preferredColorScheme(colorScheme)
        .presentationDetents(PresentationMode.detents, selection: $vm.presentationPosition)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(true)
        .presentationCornerRadius(osVersion.majorVersion >= 26 ? nil : 26)
    }
    
    //MARK: - Create Button
    @ViewBuilder
    private func CreateButton() -> some View {
        VStack {
            Spacer()
            
            RecordButton(isRecording: $vm.isRecording, showTips: vm.showTips, progress: vm.progress, countOfSec: vm.currentlyTime, decivelsLVL: vm.decibelLvl)
                .padding(20)
                .contentShape(.circle)
                .disabled(vm.disabledButton)
                .onTapGesture {
                    Task {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        await vm.handleButtonTap()
                    }
                }
                .onLongPressGesture(minimumDuration: 0.3, perform: {
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
    
    //TODO: Profile photo
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
            .font(.system(size: 18))
            .foregroundStyle(colorScheme.accentColor())
        //        }
    }
    
    @ViewBuilder
    private func CustomBackground() -> some View {
        if osVersion.majorVersion >= 26 && vm.presentationPosition == .fraction(0.93) {
            colorScheme.backgroundColor().ignoresSafeArea()
            
            Color.black.opacity(0.10).ignoresSafeArea()
        } else if osVersion.majorVersion >= 26 && vm.presentationPosition != .fraction(0.93) {
            LinearGradient(colors: [.black.opacity(0.15), colorScheme.backgroundColor(), colorScheme.backgroundColor()], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
        } else {
            colorScheme.backgroundColor().ignoresSafeArea()
        }
    }
}

#Preview {
    MainView(vm: MainVM())
}
