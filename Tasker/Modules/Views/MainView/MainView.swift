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
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme.backgroundColor.hexColor())
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    WeekView()
                    
                    ListView()
                        .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .ignoresSafeArea(edges: .bottom)
                
                VStack {
                    
                    Spacer()
                    
                    RecordButton(isRecording: $vm.isRecording, progress: vm.progress, countOfSec: vm.currentlyTime, animationAmount: vm.decibelLvl) {
                        vm.stopRecord()
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(
                        LongPressGesture().onEnded({ _ in
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            Task {
                                try await vm.startAfterChek()
                            }
                        })
                    )
                    .padding(.bottom, 15)
                }
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
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard)
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
                        .font(.system(size: 17, weight: .semibold))
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
                if newValue > 15.0 {
                    vm.stopRecord()
                }
            }
            .sheet(item: $vm.model) { model in
                TaskView(mainModel: model)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: vm.isRecording)
    }
}

#Preview {
    MainView()
}
