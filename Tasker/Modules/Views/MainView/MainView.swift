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

public struct MainView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var vm = MainVM()
    
    @State var showingAlert = false
    
    @State var presentationPosition: PresentationDetent = PresentationMode.base.detent
    
    @FocusState var focusState: Bool
    
    enum PresentationMode: CGFloat, CaseIterable {
        case base = 0.96
        case bottom = 0.20
        
        var detent: PresentationDetent {
            .fraction(rawValue)
        }
        
        static let detents = Set(PresentationMode.allCases.map { $0.detent })
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme.backgroundColor.hexColor())
                    .ignoresSafeArea()
                
                NotesView(mainViewIsOpen: $vm.mainViewIsOpen)
            }
            .sheet(isPresented: $vm.mainViewIsOpen) {
                MainViewBase()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingAlert = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(colorScheme.elementColor.hexColor())
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    TextField("", text: $vm.textForYourSelf)
                        .font(.system(.headline, design: .default, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
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
                
                if presentationPosition == PresentationMode.base.detent {
                    withAnimation {
                        CreateButton()
                            .fixedSize()
                    }
                }
            }
        }
        .sheet(item: $vm.model) { model in
            TaskView(mainModel: model)
        }
        .alert("Easy there!", isPresented: $showingAlert) {
            Button {
                showingAlert = false
            } label: {
                Text("OKAAAAY🤬")
                    .tint(.black)
            }
            .tint(.black)
        } message: {
            Text("We can't keep up with your speed. Let's slow it down a bit.")
        }
        .alert(item: $vm.alert) { alert in
            alert.alert
        }
        .presentationDetents(PresentationMode.detents, selection: $presentationPosition)
        .presentationDragIndicator(.visible)
        .presentationBackgroundInteraction(.enabled)
        .interactiveDismissDisabled(true)
        .presentationCornerRadius(30)
    }
    
    //MARK: - Create Button
    @ViewBuilder
    private func CreateButton() -> some View {
        VStack {
            Spacer()
            
            RecordButton(isRecording: $vm.isRecording, progress: vm.progress, countOfSec: vm.currentlyTime, animationAmount: vm.decibelLvl) {
                Task {
                    await vm.handleButtonTap()
                }
            }
            .disabled(vm.disabledButton)
            .buttonStyle(.plain)
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
                    Task {
                        await vm.stopRecord(isAutoStop: true)
                    }
                }
            }
            .padding(.bottom, 15)
        }
        .frame(maxWidth: .infinity)
        .blendMode(.darken)
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    MainView()
}
