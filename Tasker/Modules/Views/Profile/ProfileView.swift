//
//  ProfileView.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 7/11/25.
//

import SwiftUI
import Models
import UIComponents
import Paywall

//TODO: - Keyboard ignore safe area
public struct ProfileView: View {
    
    @State private var vm = ProfileVM()
    
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismissButton
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $vm.path) {
            ZStack {
                colorScheme.backgroundColor()
                    .ignoresSafeArea()
                
                ScrollViewContent()
                    .photosPicker(
                        isPresented: $vm.showLibrary,
                        selection: $vm.pickerSelection,
                        matching: .images
                    )
                
                if vm.showPaywall {
                    PaywallView()
                }
            }
            .navigationDestination(for: ProfileDestination.self) { desctination in
                switch desctination {
                case .articles:
                    ArticlesView(path: $vm.path)
                case .history:
                    HistoryView(path: $vm.path)
                case .settings:
                    SettingsView(path: $vm.path)
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
                        if vm.showPaywall {
                            vm.closePaywallButtonTapped()
                        } else {
                            dismissButton()
                            
                            // telemetry
                            vm.closeButtonTapped()
                        }
                    } label: {
                        Text("Close", bundle: .module)
                            .font(.system(.body, design: .rounded, weight: .medium))
                            .foregroundStyle(colorScheme.accentColor())
                            .fixedSize()
                    }
                }
            }
            .toolbarBackground(colorScheme.backgroundColor())
            .onAppear {
                vm.onAppear()
            }
        }
        .onDisappear {
            vm.onDisappear()
        }
        .sensoryFeedback(.levelChange, trigger: vm.navigationTriger)
        .animation(.bouncy, value: vm.showPaywall)
    }
    
    //MARK: - Scroll View
    @ViewBuilder
    private func ScrollViewContent() -> some View {
        VStack(spacing: 0) {
            ZStack {
                SettingsButton()
                
                ProfilePhoto()
                    .padding(.bottom, 14)
            }
            .padding(.top, 25)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            TextField(text: $vm.profileModel.name, prompt: Text("Enter your name here", bundle: .module)) {}
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.labelPrimary)
                .multilineTextAlignment(.center)
                .tint(colorScheme.accentColor())
                .onSubmit {
                    vm.profileModelSave()
                }
            
            TaskStatic()
                .padding(.top, 20)
                .padding(.bottom, 28)
                .ignoresSafeArea(.keyboard)
            
            ButtonsList()
                .padding(.bottom, 28)
                .ignoresSafeArea(.keyboard)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .ignoresSafeArea(.keyboard)
    }
    
    //MARK: - Settings Button
    @ViewBuilder
    private func SettingsButton() -> some View {
        Button {
            vm.goTo(.settings)
        } label: {
            Image(systemName: "gearshape")
                .foregroundStyle(colorScheme.accentColor())
                .font(.system(size: 30))
                .rotationEffect(Angle(degrees: vm.gearAnimation ? 270 : 0))
                .symbolEffect(.bounce,options: .speed(0.6), value: vm.gearAnimation)
                .padding(4)
                .shadow(color: colorScheme.accentColor().opacity(0.5), radius: 16, y: 4)
                .background(
                    Circle()
                        .fill(.backgroundTertiary)
                )
        }
        .offset(vm.buttonOffset)
        .animation(.spring(duration: 2), value: vm.gearAnimation)
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
            .overlay(Circle().stroke(colorScheme.backgroundColor(), lineWidth: 1))
            .shadow(color: colorScheme.accentColor().opacity(0.7), radius: 15, x: 0, y: 8)
            .frame(width: 148, height: 148)
            
            VStack(spacing: 0) {
                
                Spacer()
                
                HStack(spacing: 0) {
                    
                    Spacer()
                    
                    ContextMenu()
                }
            }
        }
        .frame(width: 148, height: 148)
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
                    Text("Edit avatar", bundle: .module)
                    
                    Image(systemName: "photo.on.rectangle")
                }
            }
            
            Button(role: .destructive) {
                vm.deletePhotoFromProfile()
            } label: {
                HStack {
                    Text("Delete photo", bundle: .module)
                    
                    Image(systemName: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .foregroundStyle(colorScheme.accentColor())
                .font(.system(size: 28))
        }
        .padding(3)
        .background(
            Circle()
                .fill(colorScheme.backgroundColor())
        )
    }
    
    //MARK: Task's static
    @ViewBuilder
    private func TaskStatic() -> some View {
        HStack {
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .today), text: "Today's tasks")
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .week), text: "Tasks this week")
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            CustomDivider()
                .frame(maxWidth: 1, maxHeight: .infinity)
                .ignoresSafeArea()
            
            Spacer()
            
            StaticRow(count: vm.tasksState(of: .completed), text: "Completed")
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 18)
        .frame(maxHeight: 96)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.backgroundTertiary)
        )
    }
    
    //MARK: Static row
    @ViewBuilder
    private func StaticRow(count: String, text: LocalizedStringKey) -> some View {
        VStack {
            Text(count)
                .font(.system(.title, design: .rounded, weight: .regular))
                .foregroundStyle(.labelPrimary)
            
            Text(text, bundle: .module)
                .font(.system(.caption2, design: .rounded, weight: .regular))
                .foregroundStyle(.labelSecondary)
        }
    }
    
    //MARK: - Active buttons
    @ViewBuilder
    private func ButtonsList() -> some View {
        VStack {
            ButtonRow(icon: "text.rectangle.page", title: "Articles") {
                vm.goTo(.articles)
            }
            
            CustomDivider()
                .frame(height: 1)
                .padding(.leading, 38)
            
            ButtonRow(icon: "clock.arrow.circlepath", title: "Task history") {
                vm.goTo(.history)
            }
            
            if vm.isnotActiveSubscription() {
                CustomDivider()
                    .frame(height: 1)
                    .padding(.leading, 38)
                
                ButtonRow(icon: "crown", title: "Purchase a subscription") {
                    vm.subscriptionButtonTapped()
                }
            }
            
            Spacer()
            
            CreatedDate()
        }
        .sensoryFeedback(.levelChange, trigger: vm.path)
    }
    
    //MARK: - Custom divider
    @ViewBuilder
    private func CustomDivider() -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(.separatorSecondary)
    }
    
    //MARK: - Created Date
    @ViewBuilder
    private func CreatedDate() -> some View {
        HStack(alignment: .center, spacing: 4) {
            Image(systemName: "calendar")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text("Created:", bundle: .module)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelTertiary)
            
            Text(vm.createdDate.formatted(.dateTime.month().day().hour().minute().year()))
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.labelSecondary)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ProfileView()
}
