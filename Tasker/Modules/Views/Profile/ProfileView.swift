//
//  ProfileView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/11/25.
//

import SwiftUI
import Models
import UIComponents

public struct ProfileView: View {
    @State private var vm = ProfileVM()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                colorScheme.backgroundColor.hexColor()
                    .ignoresSafeArea()
                
                ScrollViewContent()
                    .photosPicker(
                        isPresented: $vm.showLibrary,
                        selection: $vm.pickerSelection,
                        matching: .images
                    )
            }
            .navigationDestination(for: ProfileVM.ProfileDestination.self) { desctination in
                switch desctination {
                case .articles:
                    ArticlesView(path: $vm.path)
                case .history:
                    HistoryView(path: $vm.path)
                case .appearance:
                    AppearanceView(path: $vm.path)
                }
            }
            .alert(item: $vm.alert) { alert in
                alert.alert
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismissButton()
                    } label: {
                        Text("Close")
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(colorScheme.elementColor.hexColor())
                            .fixedSize()
                    }
                }
            }
            .toolbarBackground(colorScheme.backgroundColor.hexColor())
            .onDisappear {
                vm.profileModelSave()
            }
        }
    }
    
    //MARK: - Scroll View
    @ViewBuilder
    private func ScrollViewContent() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                
                ProfilePhoto()
                    .padding(.bottom, 14)
                
                TextField("Enter your name here", text: $vm.profileModel.value.name)
                    .font(.system(.title2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.labelPrimary)
                    .multilineTextAlignment(.center)
                    .tint(colorScheme.elementColor.hexColor())
                    .onSubmit {
                        vm.profileModelSave()
                    }
                
                TaskStatic()
                    .padding(.top, 20)
                    .padding(.bottom, 28)
                
                ButtonsList()
                    .padding(.bottom, 28)
                
                Text("App Version \(ConfigurationFile().appVersion)")
                    .font(.system(.subheadline, design: .default, weight: .regular))
                    .foregroundStyle(.labelTertiary)
                    .padding(.bottom, 37)
                
            }
            .padding(.top, 25)
            .padding(.horizontal, 16)
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollIndicators(.hidden)
    }
    
    //MARK: - Photo
    @ViewBuilder
    private func ProfilePhoto() -> some View {
        ZStack {
            VStack {
                if let data = vm.getPhotoFromCAS() {
                    if let image = UIImage(data: data) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .offset(vm.photoPosition)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        vm.photoPosition = value.translation
                                    }
                                    .onEnded { _ in
                                        vm.savePhotoPosition()
                                    }
                            )
                    }
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 28))
                        .foregroundStyle(.labelQuaternary)
                        .padding(50)
                        .background(
                            RoundedRectangle(cornerRadius: 1)
                                .fill(.backgroundTertiary)
                        )
                }
            }
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(colorScheme.backgroundColor.hexColor(), lineWidth: 1)
                    .shadow(color: colorScheme.elementColor.hexColor().opacity(0.8), radius: 5, x: 0, y: 3)
            )
            .frame(width: 128, height: 128)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                HStack(spacing: 0) {
                    
                    Spacer()
                    
                    ContextMenu()
                }
            }
        }
        .frame(width: 128, height: 128)
        .sensoryFeedback(.selection, trigger: vm.showLibrary)
    }
    
    //MARK: - Context menu
    @ViewBuilder
    private func ContextMenu() -> some View {
        Menu {
            
            Button {
                Task {
                    await vm.editAvatarButtonTapped()
                }
            } label: {
                HStack {
                    Text("Edit avatar")
                    
                    Image(systemName: "photo.on.rectangle")
                }
            }
            
            Button {
                
            } label: {
                HStack {
                    Text("Log out")
                    
                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                }
            }
            
            Button(role: .destructive) {
                
            } label: {
                HStack {
                    Text("Delete profile")
                    
                    Image(systemName: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(colorScheme.elementColor.hexColor())
                .font(.system(size: 28))
        }
        .padding(3)
        .background(
            Circle()
                .fill(colorScheme.backgroundColor.hexColor())
        )
    }
    
    //MARK: Task's static
    @ViewBuilder
    private func TaskStatic() -> some View {
        HStack {
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .today), text: "Today's tasks")
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .week), text: "Tasks this week")
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .completed), text: "Completed tasks")
            
            Spacer()
        }
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.backgroundTertiary)
        )
    }
    
    //MARK: Static row
    @ViewBuilder
    private func StaticRow(count: String, text: String) -> some View {
        VStack {
            Text(count)
                .font(.system(.title, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
            
            Text(text)
                .font(.system(.caption2, design: .rounded, weight: .regular))
                .foregroundStyle(.labelSecondary)
        }
    }
    
    //MARK: - Active buttons
    @ViewBuilder
    private func ButtonsList() -> some View {
        VStack {
            ButtonRow(icon: "text.rectangle.page", title: "Productivity articles") {
                vm.goTo(.articles)
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "clock.arrow.circlepath", title: "Task history") {
                vm.goTo(.history)
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "swirl.circle.righthalf.filled", title: "Appearance") {
                vm.goTo(.appearance)
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "calendar.badge.checkmark", title: "The day the week started", actionIcon: "chevron.up.chevron.down") {
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "lock.shield", title: "Privacy Policy") {
                
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "doc", title: "Terms of Use") {
                
            }
        }
    }
    
    //MARK: - Button Row
    @ViewBuilder
    private func ButtonRow(icon: String, title: String, actionIcon: String = "chevron.right", action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(colorScheme.elementColor.hexColor())
                    .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.system(.callout, design: .rounded, weight: .regular))
                    .foregroundStyle(.labelPrimary)
                
                Spacer()
                
                if actionIcon != "chevron.right" {
                    Menu {
                        Button {
                            vm.changeFirstDayOfWeek(1)
                        } label: {
                            Text("Sunday")
                        }
                        
                        Button {
                            vm.changeFirstDayOfWeek(2)
                        } label: {
                            Text("Monday")
                        }
                    } label: {
                        HStack {
                            Text(vm.firstWeekday)
                                .font(.system(.callout, design: .rounded, weight: .regular))
                            
                            Image(systemName: actionIcon)
                                .padding(.vertical, 12)
                        }
                    }
                    .tint(.labelQuaternary)
                } else {
                    Image(systemName: actionIcon)
                        .padding(.vertical, 12)
                        .tint(.labelQuaternary)
                }
            }
        }
    }
    
    //MARK: - Custom divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.separatorSecondary)
    }
}

#Preview {
    ProfileView()
}
