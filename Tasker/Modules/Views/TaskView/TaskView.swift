//
//  TaskView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 4/14/25.
//

import SwiftUI
import Models
import UIComponents
import Paywall

public struct TaskView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.dismiss) var dismissButton
    
    @State private var vm: TaskVM
    
    @FocusState private var sectionInFocuse: SectionInFocuse?
    
    enum SectionInFocuse: Hashable {
        case title
        case description
    }
    
    public init(mainModel: MainModel) {
        vm = TaskVM(mainModel: mainModel)
    }
    
    public var body: some View {
        ZStack {
            LinearGradient(colors: [vm.task.taskColor.color(for: colorScheme), colorScheme.backgroundColor()], startPoint: .bottom, endPoint: .top)
                .opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                CustomTabBar()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        AudioSection()
                        
                        MainSection()
                        
                        VStack {
                            DateSelection()
                            
                            TimeSelection()
                            
                            RepeatSelection()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    vm.task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(colorScheme)
                                )
                        )
                        
                        CustomColorPicker()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        vm.task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(colorScheme)
                                    )
                            )
                        
                        CreatedDate()
                        
                        Spacer()
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                
                SaveButton()
                
            }
            .onChange(of: vm.currentlyRecordTime) { newValue, _ in
                vm.stopAfterCheck(newValue)
            }
            .onDisappear {
                vm.stopPlaying()
            }
            .taskDeleteDialog(
                isPresented: $vm.confirmationDialogIsPresented,
                task: vm.mainModel,
                message: vm.messageForDelete,
                isSingleTask: vm.singleTask,
                onDelete: vm.deleteButtonTapped,
                dismissButton: dismissButton
            )
            .alert(item: $vm.alert) { alert in
                alert.alert
            }
            .sensoryFeedback(.success, trigger: vm.taskDoneTrigger)
            .sensoryFeedback(.selection, trigger: vm.notificationDate)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.playButtonTrigger)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.isRecording)
            .animation(.default, value: vm.task.audio)
            .sheet(isPresented: $vm.shareViewIsShowing) {
                ShareView(activityItems: [vm.task])
                    .presentationDetents([.medium])
            }
            .padding(.horizontal, 16)
            
            if vm.showPaywall {
                PaywallView()
            }
        }
        .animation(.bouncy, value: vm.showPaywall)
    }
    
    //MARK: TabBar
    @ViewBuilder
    private func CustomTabBar() -> some View {
        HStack(alignment: .center) {
            Button {
                vm.deleteTaskButtonTapped()
            } label: {
                Text("Delete", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(.accentRed)
            }
            
            Spacer()
            
            Button {
                vm.shareViewButtonTapped()
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
            .padding(.vertical, 11)
        }
        .tint(colorScheme.accentColor())
        .padding(.top, 14)
        .padding(.bottom, 3)
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
    
    //MARK: Voice Playing
    @ViewBuilder
    private func VoicePlaying() -> some View {
        HStack(spacing: 12) {
            Image(systemName: vm.isPlaying ? "pause" : "play")
                .frame(width: 21, height: 21)
                .onTapGesture {
                    Task {
                        await vm.playButtonTapped(task: vm.task)
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
            .tint(colorScheme.accentColor())
            
            Text(vm.currentTimeString())
                .font(.system(.callout, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
                .foregroundStyle(colorScheme.accentColor())
            
            Toggle(isOn: $vm.task.voiceMode) {
                Text("Play your voice in notification")
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelPrimary)
            }
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
                ZStack {
                    Circle()
                        .fill(
                            colorScheme.accentColor()
                        )
                        .frame(width: 34, height: 34)
                    
                    Image(systemName: vm.isRecording ? "pause.fill" : "microphone.fill")
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    .backgroundTertiary
                )
        )
    }
    
    
    //MARK: - Title, Info
    @ViewBuilder
    private func MainSection() -> some View {
        VStack(spacing: 0) {
            TextField(text: Binding(
                get: { NSLocalizedString(vm.task.title, bundle: .module, comment: "") },
                set: { vm.task.title = $0 }
            ), prompt: Text("New task", bundle: .module)) {}
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.labelPrimary)
                .padding(.vertical, 13)
                .padding(.horizontal, 16)
                .focused($sectionInFocuse, equals: .title)
                .onSubmit {
                    sectionInFocuse = nil
                }
            
            RoundedRectangle(cornerRadius: 1)
                .fill(.separatorPrimary)
                .frame(height: 1)
                .padding(.leading, 16)
            
            VStack {
                TextField(text: Binding(
                    get: { NSLocalizedString(vm.task.info, bundle: .module, comment: "") },
                    set: { vm.task.info = $0 }
                ), prompt: Text("Add more information", bundle: .module), axis: .vertical) {}
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .frame(minHeight: 70, alignment: .top)
                    .foregroundStyle(.labelPrimary)
                    .padding(.vertical, 13)
                    .padding(.horizontal, 16)
                    .focused($sectionInFocuse, equals: .description)
            }
        }
        .onChange(of: vm.showDatePicker) { newValue, oldValue in
            sectionInFocuse = nil
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    .backgroundTertiary
                )
        )
    }
    
    //MARK: Date Selector
    @ViewBuilder
    private func DateSelection() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: vm.showDatePicker == false ? 0 : 0.2)) {
                    vm.selectDateButtonTapped()
                }
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "calendar")
                        .foregroundStyle(colorScheme.accentColor())
                    
                    Text("Date", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                        .padding(.vertical, 13)
                    
                    Spacer()
                    
                    Text(vm.dateForAppearence, bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            CustomDivider()
            
            if vm.showDatePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .scrollDismissesKeyboard(.immediately)
                    .id(vm.notificationDate)
                    .tint(colorScheme.accentColor())
            }
        }
        .sensoryFeedback(.impact, trigger: vm.showDatePicker)
    }
    
    //MARK: Time Selector
    @ViewBuilder
    private func TimeSelection() -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: vm.showTimePicker == false ? 0 : 0.2)) {
                    vm.selectTimeButtonTapped()
                }
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "clock")
                        .foregroundStyle(colorScheme.accentColor())
                    
                    Text("Time", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                        .padding(.vertical, 13)
                    
                    
                    Spacer()
                    
                    Text(vm.notificationDate, format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            CustomDivider()
            
            if vm.showTimePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .tint(colorScheme.accentColor())
            }
        }
        .sensoryFeedback(.impact, trigger: vm.showTimePicker)
    }
    
    //MARK: Repeat Selector
    @ViewBuilder
    private func RepeatSelection() -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "clock.arrow.trianglehead.2.counterclockwise.rotate.90")
                    .foregroundStyle(colorScheme.accentColor())
                
                Text("Repeat", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                    .padding(.vertical, 13)
                
                Spacer()
                
                Picker(selection: $vm.task.repeatTask, content: {
                    ForEach(RepeatTask.allCases, id: \.self) { type in
                        Text(type.description, bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                }, label: {
                    HStack {
                        Text(vm.task.repeatTask.description)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                })
                .tint(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                .pickerStyle(.menu)
            }
            .padding(.leading, 17)
            
            if vm.task.repeatTask == .dayOfWeek {
                DayOfWeekSelection()
            }
        }
        .sensoryFeedback(.selection, trigger: vm.task.repeatTask)
    }
    
    @ViewBuilder
    private func DayOfWeekSelection() -> some View {
        VStack(spacing: 0) {
            
            CustomDivider()
            
            HStack {
                ForEach($vm.dayOfWeek) { $day in
                    Button {
                        day.value.toggle()
                    } label: {
                        Text(LocalizedStringKey(day.name), bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                            .foregroundStyle(day.value ? colorScheme.accentColor() : vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                            .padding(.vertical, 13)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            HStack(alignment: .center,spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
                
                Text("Pick the days of the week to repeat", bundle: .module)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedPrimaryLabel(colorScheme))
            }
            .padding(.bottom, 13)
        }
        .sensoryFeedback(.selection, trigger: vm.dayOfWeek)
    }
    
    //MARK: ColorPicker
    @ViewBuilder
    private func CustomColorPicker() -> some View {
        VStack {
            HStack {
                Text("Color task", bundle: .module)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, 17)
            
            ScrollView(.horizontal) {
                HStack {
                    ForEach(TaskColor.allCases, id: \.id) { color in
                        
                        Spacer()
                        
                        Button {
                            vm.selectedColorButtonTapped(color)
                        } label: {
                            Circle()
                                .fill(color.color(for: colorScheme))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    ZStack {
                                        Circle()
                                            .stroke(.separatorPrimary, lineWidth: vm.task.taskColor.id == color.id ? 1.5 : 0.3)
                                            .shadow(radius: 8, y: 4)
                                        
                                        Image(systemName: "checkmark")
                                            .symbolEffect(.bounce, value: vm.selectedColorTapped)
                                            .foregroundStyle(vm.task.taskColor.id == color.id ? vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme) : .clear)
                                    }
                                )
                        }
                        
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
                                .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
            }
            .sensoryFeedback(.selection, trigger: vm.selectedColorTapped)
        }
        .padding(.vertical, 13)
    }
    
    //MARK: Save button
    @ViewBuilder
    private func SaveButton() -> some View {
        HStack {
            TaskCheckMark(complete: vm.checkCompletedTaskForToday(), task: vm.task) {
                Task {
                    dismissButton()
                    
                    try await Task.sleep(nanoseconds: 50_000_000)
                    await vm.checkMarkTapped()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(vm.task.taskColor.color(for: colorScheme).invertedBackgroundTertiary(colorScheme))
            )
            .popover(
                isPresented: $vm.checkMarkTip,
                attachmentAnchor: .point(.center),
                arrowEdge: .bottom
            ) {
                OnboardingView(type: .checkMarkTip)
                    .presentationCompactAdaptation(.popover)
            }
            
            Button {
                Task {
                    dismissButton()
                    
                    try await Task.sleep(nanoseconds: 50_000_000)
                    await vm.saveTask()
                }
            } label: {
                Text("Close", bundle: .module)
                    .font(.system(.body, design: .rounded, weight: .regular))
                    .foregroundStyle(.white)
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                colorScheme.accentColor()
                            )
                    )
            }
        }
        .padding(.top, 5)
        .padding(.bottom, 10)
    }
    
    //MARK: - Created Date
    @ViewBuilder
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedTertiaryLabel(colorScheme))
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedTertiaryLabel(colorScheme))
            
            Text(Date(timeIntervalSince1970:vm.task.createDate).formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(vm.task.taskColor.color(for: colorScheme).invertedSecondaryLabel(colorScheme))
        }
    }
    
    //MARK: - Divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(vm.task.taskColor.color(for: colorScheme).invertedSeparartorPrimary(colorScheme))
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

#Preview {
    TaskView(mainModel: mockModel())
}
