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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        vm.calendarButtonTapped()
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(colorScheme.accentColor())
                    }
                    .disabled(vm.showPaywall)
                    .disabled(vm.disabledButton)
                }
                
                ToolbarItem(placement: .principal) {
                    TextField(text: $vm.profileModel.value.customTitle, prompt: Text("Write title 🎯", bundle: .module)) {}
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
                    .disabled(vm.disabledButton)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: vm.isRecording)
            .sensoryFeedback(.selection, trigger: vm.profileViewIsOpen)
            .sensoryFeedback(.warning, trigger: vm.isRecording)
            .sensoryFeedback(
                .increase,
                trigger: [
                    vm.onboardingManager.dayTip,
                    vm.onboardingManager.calendarTip,
                    vm.onboardingManager.profileTip,
                    vm.onboardingManager.notesTip,
                    vm.onboardingManager.deleteTip,
                    vm.onboardingManager.listSwipeTip
                ]
            )
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
                    .disabled(vm.disabledButton)
                    .popover(
                        isPresented: $vm.onboardingManager.calendarTip,
                        attachmentAnchor: .point(.topLeading),
                        arrowEdge: .top
                    ) {
                        OnboardingView(type: .calendarTip)
                            .presentationCompactAdaptation(.popover)
                    }
                    .popover(
                        isPresented: $vm.onboardingManager.dayTip,
                        attachmentAnchor: .point(.center),
                        arrowEdge: .top
                    ) {
                        OnboardingView(type: .dayTip)
                            .presentationCompactAdaptation(.popover)
                    }
                    .popover(
                        isPresented: $vm.onboardingManager.profileTip,
                        attachmentAnchor: .point(.topTrailing),
                        arrowEdge: .top
                    ) {
                        OnboardingView(type: .profileTip)
                            .presentationCompactAdaptation(.popover)
                    }
                
                ListView()
                    .disabled(vm.disabledButton)
                    .popover(
                        isPresented: $vm.onboardingManager.deleteTip,
                        attachmentAnchor: .rect(
                            .rect(
                                CGRect(
                                    x: UIScreen.main.bounds.width / 1.5,
                                    y: UIScreen.main.bounds.height / 11,
                                    width: 15,
                                    height: 15
                                )
                            )
                        ),
                        arrowEdge: .bottom
                    ) {
                        OnboardingView(type: .deleteTip)
                            .presentationCompactAdaptation(.popover)
                    }
                    .popover(
                        isPresented: $vm.onboardingManager.listSwipeTip,
                        attachmentAnchor: .rect(
                            .rect(
                                CGRect(
                                    x: UIScreen.main.bounds.width / 2,
                                    y: UIScreen.main.bounds.height / 2,
                                    width: 15,
                                    height: 15
                                )
                            )
                        ),
                        arrowEdge: .bottom
                    ) {
                        OnboardingView(type: .listSwipeTip)
                            .presentationCompactAdaptation(.popover)
                    }
                
                Spacer()
            }
            .popover(
                isPresented: $vm.onboardingManager.notesTip,
                attachmentAnchor: .point(.top),
                arrowEdge: .top
            ) {
                OnboardingView(type: .noteTip)
                    .presentationCompactAdaptation(.popover)
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
            .foregroundStyle(colorScheme.accentColor())
        //        }
    }
}

#Preview {
    MainView(vm: MainVM())
}
