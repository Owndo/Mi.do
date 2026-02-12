//
//  MainView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/11/25.
//

import SwiftUI
import UIComponents
import CalendarView
import ListView
import TaskView
import ProfileView
import PaywallView
import StoreKit
import NotesView

public struct MainView: View {
    @Environment(\.appearanceManager) var appearanceManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    @Bindable var vm: MainVM
    
    @FocusState var focusState: Bool
    
    public init(vm: MainVM) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                CustomBackground()
                
                NotesView(vm: vm.notesVM)
            }
            .onAppear {
                Task {
                    await vm.checkWelcomeMido()
                }
            }
            .navigationDestination(for: MainViewNavigation.self) { destination in
                destination.destination()
            }
            .sheet(isPresented: $vm.mainViewSheetIsPresented) {
                MainViewBase(weekVM: vm.weekVM, listVM: vm.listVM)
                    .presentationBackground(appearanceManager.backgroundColor)
                    .sheet(item: $vm.sheetNavigation) { navigation in
                        navigation.destination()
                            .preferredColorScheme(colorScheme)
                    }
            }
            //MARK: - Toolbar
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Task {
                            await vm.calendarButtonTapped()
                        }
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 18))
                            .foregroundStyle(appearanceManager.accentColor)
                    }
                    .disabled(vm.disabledButton)
                }
                
                ToolbarItem(placement: .principal) {
                    TextField(text: $vm.profileModel.customTitle, prompt: Text("Write title 🎯", bundle: .module)) {}
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.labelPrimary)
                        .multilineTextAlignment(.center)
                        .onSubmit {
                            Task {
                                await vm.profileModelSave()
                            }
                        }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await vm.profileViewButtonTapped()
                        }
                    } label: {
                        ProfilePhoto()
                    }
                    .disabled(vm.disabledButton)
                }
            }
            .toolbarBackground(osVersion.majorVersion >= 26 ? .visible : .hidden, for: .navigationBar)
            .animation(.default, value: vm.isRecording)
            .animation(.default, value: vm.backgroundAnimation)
            .animation(.default, value: vm.hideRecordButtonTip)
            .sensoryFeedback(.selection, trigger: vm.sheetNavigation)
            .sensoryFeedback(.selection, trigger: vm.path)
            .sensoryFeedback(.warning, trigger: vm.isRecording)
            .sensoryFeedback(.error, trigger: vm.paywallVM)
        }
    }
    
    //MARK: - MainViewBase
    @ViewBuilder
    private func MainViewBase(weekVM: WeekVM, listVM: ListVM) -> some View {
        ZStack {
            VStack(spacing: 0) {
                ListView(vm: listVM)
                    .presentationContentInteraction(.scrolls)
                
                Spacer()
            }
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        appearanceManager.backgroundColor.opacity(0.98),
                        appearanceManager.backgroundColor.opacity(0.99),
                        appearanceManager.backgroundColor
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .blur(radius: 10)
                .frame(maxHeight: 60)
                .offset(y: 20)
            }
            
            VStack {
                Spacer()
                
                if vm.presentationPosition != PresentationMode.bottom.detent {
                    CreateButton()
                        .fixedSize()
                }
            }
            .ignoresSafeArea(.keyboard)
            
            VStack {
                WeekView(vm: weekVM)
                    .padding(.top, 17)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            colors: [
                                appearanceManager.backgroundColor,
                                appearanceManager.backgroundColor,
                                appearanceManager.backgroundColor.opacity(0.99),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                        .blur(radius: 5)
                        .offset(y: -12.5)
                    )
                
                Spacer()
            }
            
            if let vm = vm.paywallVM {
                PaywallView(vm: vm)
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
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(true)
        .presentationCornerRadius(osVersion.majorVersion >= 26 ? nil : 26)
        .presentationDetents(PresentationMode.detents, selection: $vm.presentationPosition)
    }
    
    //MARK: - Create Button
    @ViewBuilder
    private func CreateButton() -> some View {
        VStack {
            Spacer()
            
            RecordButton(isRecording: $vm.isRecording, hideTip: vm.hideRecordButtonTip, progress: vm.progress, countOfSec: vm.currentlyTime, decivelsLVL: vm.decibelLvl)
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
        .blendMode(colorScheme == .dark ? .normal : colorScheme == .light ? .darken : .normal)
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
            .foregroundStyle(appearanceManager.accentColor)
        //        }
    }
    
    @ViewBuilder
    private func CustomBackground() -> some View {
        if osVersion.majorVersion >= 26 && vm.presentationPosition == PresentationMode.base.detent {
            appearanceManager.backgroundColor.ignoresSafeArea()
            
            Color.black.opacity(0.10).ignoresSafeArea()
        } else if osVersion.majorVersion >= 26 && vm.presentationPosition != PresentationMode.base.detent {
            LinearGradient(
                colors: [.black.opacity(0.15), appearanceManager.backgroundColor, appearanceManager.backgroundColor],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        } else {
            appearanceManager.backgroundColor.ignoresSafeArea()
        }
    }
}

#Preview {
    MainView(vm: MainVM.createPreviewVM())
}
