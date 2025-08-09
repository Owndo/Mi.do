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
    
    var model: MainModel
    
    @FocusState private var sectionInFocuse: SectionInFocuse?
    
    enum SectionInFocuse: Hashable {
        case title
        case description
    }
    
    public init(model: MainModel) {
        self._vm = State(initialValue: TaskVM(mainModel: model))
        self.model = model
    }
    
    public var body: some View {
        ZStack {
            LinearGradient(colors: [vm.backgroundColor, colorScheme.backgroundColor()], startPoint: .bottom, endPoint: .top)
                .opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                CustomTabBar()
                
                ScrollView {
                    VStack(spacing: 28) {
                        
                        AudioSection()
                        
                        MainSection()
                        
                        VStack(spacing: 0) {
                            DateSelection()
                            
                            TimeSelection()
                            
                            RepeatSelection()
                            
                            VStack {
                                HStack {
                                    Button {
                                        vm.showDedalineButtonTapped()
                                    } label: {
                                        Image(systemName: "flame.fill")
                                            .foregroundStyle(colorScheme.accentColor())
                                        
                                        Text("Deadline", bundle: .module)
                                            .font(.system(.body, design: .rounded, weight: .regular))
                                            .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                                            .padding(.vertical, 13)
                                        
                                     Spacer()
                                        
                                        Toggle(isOn: $vm.hasDeadline) {}
                                            .tint(colorScheme.accentColor())
                                            .padding(.trailing, 2)
                                    }
                                }
                                .padding(.leading, 17)
                                .padding(.trailing, 14)
                                
                                if vm.showDeadline {
                                    DatePicker("", selection: $vm.deadLineDate, displayedComponents: .date)
                                        .datePickerStyle(.graphical)
                                        .id(vm.deadLineDate)
                                        .tint(colorScheme.accentColor())
                                }
                            }
                            .clipped()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    vm.backgroundColor.invertedBackgroundTertiary(task: vm.task, colorScheme)
                                )
                        )
                        
                        CustomColorPicker()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        vm.backgroundColor.invertedBackgroundTertiary(task: vm.task, colorScheme)
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
            .onAppear {
                vm.backgroundColorForTask(colorScheme: colorScheme)
            }
            .onChange(of: vm.currentlyRecordTime) { newValue, _ in
                vm.stopAfterCheck(newValue)
            }
            .onDisappear {
                vm.stopPlaying()
            }
            .taskDeleteDialog(
                isPresented: $vm.confirmationDialogIsPresented,
                task: vm.task,
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
            .sensoryFeedback(.selection, trigger: vm.showDeadline)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.playButtonTrigger)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: vm.isRecording)
            .animation(.default, value: vm.task.audio)
            .animation(.easeInOut, value: vm.showDatePicker)
            .animation(.easeInOut, value: vm.showTimePicker)
            .animation(.easeInOut, value: vm.showDeadline)
            .animation(.easeInOut, value: vm.showDayOfWeekSelector)
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
        .animation(.default, value: colorScheme)
        .animation(.default, value: vm.task.taskColor)
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
            
            //            Button {
            //                vm.shareViewButtonTapped()
            //            } label: {
            //                Image(systemName: "square.and.arrow.up")
            //            }
                .padding(.vertical)
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
                    get: { NSLocalizedString(vm.task.description, bundle: .module, comment: "") },
                    set: { vm.task.description = $0 }
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
                vm.selectDateButtonTapped()
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "calendar")
                        .foregroundStyle(colorScheme.accentColor())
                    
                    Text("Date", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                        .padding(.vertical, 13)
                    
                    Spacer()
                    
                    Text(vm.dateForAppearence, bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            if vm.showDatePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .scrollDismissesKeyboard(.immediately)
                    .id(vm.notificationDate)
                    .tint(colorScheme.accentColor())
            }
            
            CustomDivider()
        }
        .sensoryFeedback(.impact, trigger: vm.showDatePicker)
        .clipped()
    }
    
    //MARK: Time Selector
    @ViewBuilder
    private func TimeSelection() -> some View {
        VStack(spacing: 0) {
            Button {
                vm.selectTimeButtonTapped()
            } label: {
                HStack(spacing: 13) {
                    Image(systemName: "clock")
                        .foregroundStyle(colorScheme.accentColor())
                    
                    Text("Time", bundle: .module)
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                        .padding(.vertical, 13)
                    
                    
                    Spacer()
                    
                    Text(vm.notificationDate, format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
                        .font(.system(.body, design: .rounded, weight: .regular))
                        .foregroundStyle(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
                }
            }
            .padding(.leading, 17)
            .padding(.trailing, 14)
            
            if vm.showTimePicker {
                DatePicker("", selection: $vm.notificationDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .tint(colorScheme.accentColor())
            }
            
            CustomDivider()
        }
        .sensoryFeedback(.impact, trigger: vm.showTimePicker)
        .clipped()
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
                    .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                    .padding(.vertical, 13)
                
                Spacer()
                
                Picker(selection: $vm.task.repeatTask) {
                    ForEach(RepeatTask.allCases, id: \.self) { type in
                        Text(type.description, bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                } label: {
                    HStack {
                        Text(vm.task.repeatTask.description)
                            .font(.system(.body, design: .rounded, weight: .regular))
                    }
                }
                .tint(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
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
                            .foregroundStyle(day.value ? colorScheme.accentColor() : vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                            .padding(.vertical, 13)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)
            
            HStack(alignment: .center,spacing: 4) {
                Image(systemName: "info.circle")
                    .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
                
                Text("Pick the days of the week to repeat", bundle: .module)
                    .font(.system(.footnote, design: .rounded, weight: .regular))
                    .foregroundStyle(vm.backgroundColor.invertedPrimaryLabel(task: vm.task, colorScheme))
            }
            .padding(.bottom, 13)
        }
        .clipped()
        .sensoryFeedback(.selection, trigger: vm.dayOfWeek)
    }
    
    //MARK: ColorPicker
    @ViewBuilder
    private func CustomColorPicker() -> some View {
        VStack {
            HStack {
                Text("Color task", bundle: .module)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .foregroundStyle(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
                
                Spacer()
            }
            .padding(.horizontal, 17)
            
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
                                        
                                        Image(systemName: "checkmark")
                                            .symbolEffect(.bounce, value: vm.selectedColorTapped)
                                            .foregroundStyle(
                                                vm.checkColorForCheckMark(color, for: colorScheme) ? vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme) : .clear
                                            )
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
                                .foregroundStyle(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
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
                    .fill(vm.backgroundColor.invertedBackgroundTertiary(task: vm.task, colorScheme))
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
                .foregroundStyle(vm.backgroundColor.invertedTertiaryLabel(task: vm.task, colorScheme))
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(vm.backgroundColor.invertedTertiaryLabel(task: vm.task, colorScheme))
            
            Text(Date(timeIntervalSince1970:vm.task.createDate).formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(vm.backgroundColor.invertedSecondaryLabel(task: vm.task, colorScheme))
        }
    }
    
    //MARK: - Divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(vm.backgroundColor.invertedSeparartorPrimary(task: vm.task, colorScheme))
            .frame(height: 1)
            .padding(.leading, 16)
    }
}

#Preview {
    TaskView(model: mockModel())
}

struct AnimatedPickerLabel: View {
    let text: LocalizedStringKey
    
    @State private var previousText: String = ""
    @State private var animate = false
    
    var body: some View {
        Text(text)
            .transition(.opacity.combined(with: .scale))
            .animation(.easeInOut(duration: 0.25), value: text)
            .onChange(of: text) { oldValue, newValue in
                animate.toggle()
            }
    }
}
