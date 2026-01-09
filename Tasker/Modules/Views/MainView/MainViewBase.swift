////
////  MainViewBase.swift
////  MainView
////
////  Created by Rodion Akhmedov on 1/8/26.
////
//
//import SwiftUI
//import ListView
//import CalendarView
//import UIComponents
//import StoreKit
//
//struct MainViewBase: View {
//    @Environment(\.colorScheme) var colorScheme
//    @Environment(\.requestReview) var requestReview
//    
//    @Bindable var vm: MainVM
//    @Bindable var weekVM: WeekVM
//    @Bindable var listVM: ListVM
//    
//    //    init(vm: MainVM, weekVM: WeekVM, listVM: ListVM) {
//    //        self.vm = vm
//    //    }
//    
//    var body: some View {
//        ZStack {
//            colorScheme.backgroundColor().ignoresSafeArea()
//            
//            VStack(spacing: 0) {
//                
//                WeekView(vm: weekVM)
//                    .padding(.top, 17)
//                
//                ListView(vm: listVM)
//                    .presentationContentInteraction(.scrolls)
//                
//                Spacer()
//            }
//            
//            VStack {
//                
//                Spacer()
//                
//                if vm.presentationPosition != PresentationMode.bottom.detent {
//                    withAnimation {
//                        CreateButton()
//                            .fixedSize()
//                    }
//                }
//            }
//            .ignoresSafeArea(.keyboard)
//        }
//        .overlay(
//            GlowEffect(decibelLevel: vm.decibelLvl)
//                .opacity(vm.isRecording ? 1 : 0)
//        )
//        .onChange(of: vm.askReview) { _ , newValue in
//            requestReview()
//        }
//        .alert(item: $vm.alert) { alert in
//            alert.alert
//        }
//        .preferredColorScheme(colorScheme)
//        .presentationDragIndicator(.visible)
//        .presentationBackgroundInteraction(.enabled)
//        .interactiveDismissDisabled(true)
//        .presentationCornerRadius(osVersion.majorVersion >= 26 ? nil : 26)
//        .presentationDetents(PresentationMode.detents, selection: $vm.presentationPosition)
//    }
//    
//    //MARK: - Create Button
//    @ViewBuilder
//    private func CreateButton() -> some View {
//        VStack {
//            Spacer()
//            
//            RecordButton(isRecording: $vm.isRecording, progress: vm.progress, countOfSec: vm.currentlyTime, decivelsLVL: vm.decibelLvl)
//                .padding(20)
//                .contentShape(.circle)
//                .disabled(vm.disabledButton)
//                .onTapGesture {
//                    Task {
//                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                        await vm.handleButtonTap()
//                    }
//                }
//                .onLongPressGesture(minimumDuration: 0.3, perform: {
//                    Task {
//                        try await vm.startAfterChek()
//                    }
//                }, onPressingChanged: { _ in
//                    Task {
//                        await vm.createTaskButtonHolding()
//                    }
//                })
//                .onChange(of: vm.currentlyTime) { newValue, _ in
//                    if newValue > 15.0 && vm.recordingState == .recording {
//                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
//                        Task {
//                            await vm.stopRecord(isAutoStop: true)
//                        }
//                    }
//                }
//                .padding(.bottom, 15)
//        }
//        .frame(maxWidth: .infinity)
//        .blendMode(colorScheme == .dark ? .normal : .darken)
//        .ignoresSafeArea(.keyboard)
//    }
//}
//
////#Preview {
////    MainViewBase(vm: MainVM.createPreviewVM(), weekVM: WeekVM.createPreviewVM(), listVM: ListVM.creteMockListVM())
////}
