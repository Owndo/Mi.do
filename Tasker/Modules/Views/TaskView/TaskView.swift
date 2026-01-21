//
//  TaskView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import SwiftUI
import Models
import UIComponents
import UIKit
import PaywallView

public struct TaskView: View {
//    @Environment(\.appearanceManager) var appearanceManager
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.dismiss) var dismissButton
    
    @Bindable private var vm: TaskVM
    
    @FocusState var sectionInFocus: SectionInFocus?
    
    var preview = false
    
    public enum SectionInFocus: Hashable {
        case title
        case description
    }
    
    public init(taskVM: TaskVM, preview: Bool = false) {
        self.vm = taskVM
        self.preview = preview
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
            BackgroundGradient()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        AudioSection()
                            .hidden(preview)
                        
                        MainSection()
                        
                        SetupSection()
                        
                        CustomColorPicker()
                            .hidden(preview)
                        
                        CreatedDate()
                    }
                }
                .fixedSize(horizontal: false, vertical: preview)
                .ignoresSafeArea(edges: .bottom)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .disabled(vm.showPaywall)
                .padding(.horizontal, 16)
                .safeAreaInset(edge: .bottom) {
                    SaveButton()
                        .disabled(vm.paywallVM != nil)
                        .hidden(preview)
                        .padding(.leading, 16)
                        .padding(.trailing, 10)
                }
                .task {
                    vm.onAppear(colorScheme: colorScheme)
                    
                    if vm.titleFocused {
                        sectionInFocus = .title
                    }
                }
                .onChange(of: vm.currentlyRecordTime) { newValue, _ in
                    Task {
                        await vm.stopAfterCheck(newValue)
                    }
                }
                .onDisappear {
                    vm.disappear()
                }
                .alert(item: $vm.alert) { alert in
                    alert.alert
                }
                .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
                .sensoryFeedback(.selection, trigger: vm.notificationDate)
                .sensoryFeedback(.selection, trigger: vm.showDeadline)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.playButtonTrigger)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.isRecording)
                .sensoryFeedback(.error, trigger: vm.paywallHapticFeedback)
                .animation(.default, value: vm.task.audio)
                .animation(.easeInOut, value: vm.showDatePicker)
                .animation(.easeInOut, value: vm.showTimePicker)
                .animation(.easeInOut, value: vm.showDeadline)
                .animation(.easeInOut, value: vm.showDayOfWeekSelector)
                .sheet(isPresented: $vm.shareViewIsShowing) {
                    ShareView(activityItems: [vm.task])
                        .presentationDetents([.medium])
                }
                
                if let model = vm.paywallVM {
                    PaywallView(vm: model)
                }
            }
            // MARK: - Tool Bar
            
            .toolbar {
                if !preview {
                    if #available(iOS 26.0, *) {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                vm.deleteTaskButtonTapped()
                            } label: {
                                Text("Delete", bundle: .module)
                                    .font(.system(.body, design: .rounded, weight: .regular))
                                    .foregroundStyle(.accentRed)
                                    .taskDeleteDialog(isPresented: $vm.confirmationDialogIsPresented, task: vm.task) { value in
                                        await vm.deleteButtonTapped(deleteCompletely: value)
                                    }
                            }
                            .opacity(vm.paywallVM != nil ? 0 : 1)
                            .disabled(vm.paywallVM != nil)
                        }
                        .sharedBackgroundVisibility(vm.paywallVM != nil ? .hidden : .visible)
                    } else {
                        ToolbarItem(placement: .cancellationAction) {
                            Button {
                                vm.deleteTaskButtonTapped()
                            } label: {
                                Text("Delete", bundle: .module)
                                    .font(.system(.body, design: .rounded, weight: .regular))
                                    .foregroundStyle(.accentRed)
                                    .taskDeleteDialog(isPresented: $vm.confirmationDialogIsPresented, task: vm.task) { value in
                                        await vm.deleteButtonTapped(deleteCompletely: value)
                                    }
                            }
                            .opacity(vm.paywallVM != nil ? 0 : 1)
                            .disabled(vm.paywallVM != nil)
                        }
                    }
                }
            }
        }
        .presentationCornerRadius(osVersion.majorVersion >= 26 ? nil : 26)
        .animation(.bouncy, value: vm.showPaywall)
        .animation(.default, value: vm.appearanceManager.colorScheme)
        .animation(.default, value: vm.task.taskColor)
    }
    
    //MARK: - Background gradient
    
    @ViewBuilder
    private func BackgroundGradient() -> some View {
        LinearGradient(
            colors: [
                colorScheme.taskBackground(
                    vm.task,
                    vm.appearanceManager),
                vm.appearanceManager.backgroundColor
            ],
            startPoint: .bottom, endPoint: .top)
            .opacity(0.7)
    }
    
    //MARK: - Audio Section
    
    @ViewBuilder
    private func AudioSection() -> some View {
        VStack(spacing: 28) {
            if vm.task.audio != nil {
                VoicePlaying()
                
                VoiceModeToogle()
            } else {
                AddVoice()
            }
        }
        .padding(.top, 12)
    }
    
    //MARK: - Voice Playing
    
    @ViewBuilder
    private func VoicePlaying() -> some View {
        HStack(spacing: 12) {
            Image(systemName: vm.isPlaying ? "pause" : "play")
                .frame(width: 21, height: 21)
                .onTapGesture {
                    Task {
                        await vm.playButtonTapped()
                    }
                }
            
            Slider(
                value: Binding(
                    get: {
                        vm.isDragging ? vm.sliderValue : vm.currentProgressTime
                    },
                    set: { newValue in
                        vm.sliderValue = newValue
                        if vm.isDragging {
                            vm.seekAudio(newValue)
                        } else {
                            vm.seekAudio(newValue)
                        }
                    }
                ),
                in: 0...vm.totalProgressTime,
                onEditingChanged: { editing in
                    vm.isDragging = editing
                }
            )
            .tint(vm.appearanceManager.accentColor)
            
            Text(vm.currentTimeString())
                .font(.system(.callout, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    .backgroundTertiary
                )
        )
        .animation(.default, value: vm.currentProgressTime)
    }
    
    //MARK: - Voice Toogle
    
    @ViewBuilder
    private func VoiceModeToogle() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "bell")
                .foregroundStyle(vm.appearanceManager.accentColor)
            
            Toggle(isOn: $vm.task.voiceMode) {
                Text("Play your voice in notification", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelPrimary)
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    .backgroundTertiary
                )
        )
    }
    
    //MARK: - Add Voice
    
    @ViewBuilder
    private func AddVoice() -> some View {
        HStack(spacing: 12) {
            if vm.isRecording {
                EqualizerView(decibelLevel: vm.decibelLVL)
            } else {
                Text("Add voice recording", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelPrimary)
            }
            
            Spacer()
            
            Button {
                Task {
                    await vm.recordButtonTapped()
                }
            } label: {
                if #available(iOS 26.0, *) {
                    Image(systemName: vm.isRecording ? "pause.fill" : "microphone.fill")
                        .foregroundStyle(.white)
                        .padding(8)
                        .glassEffect(.regular.tint(vm.appearanceManager.accentColor).interactive(), in: .circle)
                    
                } else {
                    ZStack {
                        Circle()
                            .fill(vm.appearanceManager.accentColor)
                            .frame(width: 34, height: 34)
                        
                        Image(systemName: vm.isRecording ? "pause.fill" : "microphone.fill")
                            .foregroundStyle(.white)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    .backgroundTertiary
                )
        )
    }
    
    
    //MARK: - Title, Info
    
    @ViewBuilder
    private func MainSection() -> some View {
        VStack(spacing: 0) {
            TextField("", text: $vm.task.title, prompt: Text("New task", bundle: .module))
                .font(.title2)
                .fontWeight(.bold)
                .tint(vm.appearanceManager.accentColor)
                .foregroundStyle(.labelPrimary)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .focused($sectionInFocus, equals: .title)
                .onSubmit {
                    sectionInFocus = nil
                }
            
            RoundedRectangle(cornerRadius: 1)
                .fill(.separatorPrimary)
                .frame(height: 1)
                .padding(.leading, 16)
            
            TextField("", text: $vm.task.description, prompt: Text("Add more information", bundle: .module), axis: .vertical)
                .font(.system(.body, design: .rounded, weight: .regular))
                .frame(minHeight: 70, alignment: .top)
                .tint(vm.appearanceManager.accentColor)
                .foregroundStyle(.labelPrimary)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .focused($sectionInFocus, equals: .description)
        }
        .onChange(of: vm.showDatePicker) { newValue, oldValue in
            sectionInFocus = nil
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    .backgroundTertiary
                )
        )
    }
    
    //MARK: - Setup section
    @ViewBuilder
    private func SetupSection() -> some View {
        VStack(spacing: 0) {
            DateSelection()
            
            TimeSelection()
            
            RepeatSelection()
            
            Deadline()
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    colorScheme.invertedBackgroundTertiary(vm.task)
                )
        )
        
    }
    
    //MARK: - Date Selector
    
    @ViewBuilder
    private func DateSelection() -> some View {
        VStack(spacing: 0) {
            Button {
                vm.selectDateButtonTapped()
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "calendar")
                        .foregroundStyle(vm.appearanceManager.accentColor)
                    
                    Text("Date", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
                        .padding(.vertical, 13)
                    
                    Spacer()
                    
                    Text(vm.textForNotificationDate, bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            if vm.showDatePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .scrollDismissesKeyboard(.immediately)
                    .id(vm.notificationDate)
                    .tint(vm.appearanceManager.accentColor)
            }
            
            CustomDivider()
        }
        .sensoryFeedback(.impact, trigger: vm.showDatePicker)
        .clipped()
    }
    
    //MARK: - Time Selector
    
    @ViewBuilder
    private func TimeSelection() -> some View {
        VStack(spacing: 0) {
            Button {
                vm.selectTimeButtonTapped()
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "clock")
                        .foregroundStyle(vm.appearanceManager.accentColor)
                    
                    Text("Time", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
                        .padding(.vertical, 13)
                    
                    
                    Spacer()
                    
                    Text(vm.notificationDate, format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            if vm.showTimePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .tint(vm.appearanceManager.accentColor)
            }
            
            CustomDivider()
        }
        .sensoryFeedback(.impact, trigger: vm.showTimePicker)
        .clipped()
    }
    
    //MARK: - Repeat Selector
    
    @ViewBuilder
    private func RepeatSelection() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                    .foregroundStyle(vm.appearanceManager.accentColor)
                
                Text("Repeat", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
                    .padding(.vertical, 13)
                
                Spacer()
                
                //TODO: - Add repeat task from TASK
                Picker(selection: $vm.repeatTask) {
                    ForEach(RepeatTask.allCases, id: \.self) { type in
                        Text(type.description, bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                } label: {
                    HStack {
                        Text(vm.repeatTask.description)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                }
                .tint(colorScheme.invertedSecondaryLabel(vm.task))
                .pickerStyle(.menu)
            }
            .padding(.leading, 17)
            
            if vm.showDayOfWeekSelector {
                DayOfWeekSelection()
            }
            
            CustomDivider()
        }
        .onChange(of: vm.task.repeatTask) { oldValue, newValue in
            vm.changeTypeOfRepeat(newValue)
        }
        .sensoryFeedback(.selection, trigger: vm.task.repeatTask)
    }
    
    //TODO: - Add day of week from TASK
    
    @ViewBuilder
    private func DayOfWeekSelection() -> some View {
        VStack(spacing: 0) {
            HStack {
                ForEach($vm.dayOfWeek) { $day in
                    Button {
                        day.value.toggle()
                    } label: {
                        Text(LocalizedStringKey(day.name), bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(day.value ? vm.appearanceManager.accentColor : colorScheme.invertedPrimaryLabel(vm.task))
                            .padding(.vertical, 13)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            HStack(alignment: .center,spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
                
                Text("Pick the days of the week to repeat", bundle: .module)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
            }
            .padding(.bottom, 13)
        }
        .clipped()
        .sensoryFeedback(.selection, trigger: vm.dayOfWeek)
    }
    
    //MARK: - Color Picker
    
    @ViewBuilder
    private func CustomColorPicker() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text("Color task", bundle: .module)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
                
                Spacer()
            }
            .padding(.horizontal, 17)
            .offset(y: 10)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(TaskColor.allCases, id: \.id) { color in
                        
                        Spacer()
                        
                        Button {
                            vm.selectedColorButtonTapped(color, colorScheme: colorScheme)
                        } label: {
                            Circle()
                                .fill(color.color(for: colorScheme))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    ZStack {
                                        Circle()
                                            .stroke(.separatorPrimary, lineWidth: vm.checkColorForCheckMark(color, for: colorScheme) ? 1.5 : 0.3)
                                            .shadow(radius: 8, y: 4)
                                            .liquidIfAvailable(glass: .clear, isInteractive: true)
                                        
                                        Image(systemName: "checkmark")
                                            .symbolEffect(.bounce, value: vm.selectedColorTapped)
                                            .foregroundStyle(
                                                vm.checkColorForCheckMark(color, for: colorScheme) ? colorScheme.invertedSecondaryLabel(vm.task) : .clear
                                            )
                                    }
                                )
                        }
                        .padding(.top, 23)
                        .padding(.bottom, 13)
                        
                        Spacer()
                    }
                    
                    ZStack {
                        ColorPicker("", selection: $vm.color)
                            .scaleEffect(0.5)
                            .fixedSize()
                            .tint(.clear)
                        
                        Image(uiImage: .colorPicker)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .allowsHitTesting(false)
                        
                        if vm.task.taskColor == .custom(vm.color.toHex()) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
                        }
                    }
                    .offset(y: 5)
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 26)
            )
            .sensoryFeedback(.selection, trigger: vm.selectedColorTapped)
        }
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    colorScheme.invertedBackgroundTertiary(vm.task)
                )
        )
    }
    
    //MARK: - Deadline
    
    @ViewBuilder
    private func Deadline() -> some View {
        VStack {
            HStack {
                Button {
                    vm.showDedalineButtonTapped()
                } label: {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(vm.appearanceManager.accentColor)
                    
                    Text("Deadline", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(colorScheme.invertedPrimaryLabel(vm.task))
                        .padding(.vertical, 13)
                    
                    Spacer()
                    
                    if vm.task.deadline != nil {
                        Text(vm.textForDeadlineDate, bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
                    }
                    
                    Toggle(isOn: $vm.hasDeadline) {}
                        .tint(vm.appearanceManager.accentColor)
                        .padding(.trailing, 2)
                        .fixedSize()
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            if vm.showDeadline {
                DatePicker("", selection: $vm.deadLineDate, in: vm.notificationDate..., displayedComponents: .date, )
                    .datePickerStyle(.graphical)
                    .id(vm.deadLineDate)
                    .tint(vm.appearanceManager.accentColor)
            }
        }
        //        .onChange(of: vm.hasDeadline) { oldValue, newValue in
        //            Task {
        //                if newValue {
        //                    await vm.checkSubscriptionForDeadline()
        //                }
        //            }
        //        }
        .clipped()
    }
    
    //MARK: - Save button
    
    @ViewBuilder
    private func SaveButton() -> some View {
        
        //TODO: - Add complete to preset mode
        
        HStack {
            TaskCheckMark(complete: vm.taskCompletedforToday, task: vm.task) {
                Task {
                    dismissButton()
                    
                    try await Task.sleep(nanoseconds: 50_000_000)
                    await vm.checkMarkTapped()
                }
            }
            .padding(12)
            .background(
                Circle()
                    .fill(colorScheme.invertedBackgroundTertiary(vm.task))
            )
            
            HStack {
                Spacer()
                
                Button {
                    Task {
                        dismissButton()
                        
                        try await Task.sleep(nanoseconds: 50_000_000)
                        await vm.closeButtonTapped()
                    }
                } label: {
                    if #available(iOS 26.0, *) {
                        Text("Close", bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .glassEffect(.regular.tint(vm.appearanceManager.accentColor).interactive())
                    } else {
                        Text("Close", bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(.white)
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 26)
                                    .fill(vm.appearanceManager.accentColor)
                            )
                    }
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 5)
        //        .background(
        //            RoundedRectangle(cornerRadius: 26)
        //                .fill(
        //                    appearanceManager.backgroundColor()
        //                        .opacity(
        //                            vm.showDatePicker ||
        //                            vm.showTimePicker ||
        //                            vm.showDeadline ||
        //                            vm.repeatTask == .dayOfWeek ||
        //                            sectionInFocus != nil
        //                            ? 0.6 : 0.0)
        //                )
        //                .blur(radius: 4)
        //        )
    }
    
    //MARK: - Created Date
    
    @ViewBuilder
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(colorScheme.invertedTertiaryLabel(vm.task))
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(colorScheme.invertedTertiaryLabel(vm.task))
            
            Text(Date(timeIntervalSince1970:vm.task.createDate).formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(colorScheme.invertedSecondaryLabel(vm.task))
        }
    }
    
    //MARK: - Divider
    
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(colorScheme.invertedSeparartorPrimary(vm.task))
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

#Preview("Ubsubscribed") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TaskView(taskVM: TaskVM.createPreviewTaskVM())
        }
}

#Preview("Subscribed") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            TaskView(taskVM: TaskVM.createSubscribedPreviewTaskVM())
        }
}
