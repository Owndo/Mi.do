//
//  ProfileModel.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import BlockSet
import SwiftUI
import UIKit

public struct ProfileModel: Codable {
    public var customTitle: String?
    public var notes: String?
    public var name: String?
    public var photo: String?
    public var photoPosition: CGSize?
    public var createdProfile: Double = Date.now.timeIntervalSince1970
    public var settings: SettingsModel?
    public var onboarding: OnboardingModel?
}

public class ProfileModelWrapper<T>: Identifiable {
    public var id: String
    public var model: Model<T>
    
    public init(_ model: Model<T>) {
        self.id = UUID().uuidString
        self.model = model
    }
}

@Observable
public final class UIProfileModel: ProfileModelWrapper<ProfileModel> {
    public var customTitle: String {
        get { model.value.customTitle ?? "" }
        set { model.value.customTitle = nilIfNeed(newValue, is: "") }
    }
    
    public var notes: String {
        get { model.value.notes ?? "" }
        set { model.value.notes = nilIfNeed(newValue, is: "") }
    }
    
    public var name: String {
        get { model.value.name ?? "" }
        set { model.value.name = nilIfNeed(newValue, is: "") }
    }
    
    public var photo: String {
        get { model.value.photo ?? "" }
        set { model.value.photo = nilIfNeed(newValue, is: "") }
    }
    
    public var photoPosition: CGSize {
        get { model.value.photoPosition ?? .zero }
        set { model.value.photoPosition = nilIfNeed(newValue, is: .zero) }
    }
    
    public var createdProfile: Double {
        get { model.value.createdProfile }
    }
    
    public var settings: UISettingsModel {
        get {
            let stored = model.value.settings ?? defaultSettingsModel()
            return UISettingsModel(stored) { [weak self] updated in
                self?.model.value.settings =
                (updated == defaultSettingsModel()) ? nil : updated
            }
        }
        set {
            let updated = newValue.model
            model.value.settings =
            (updated == defaultSettingsModel()) ? nil : updated
        }
    }
    
    public var onboarding: UIOnboardingModel {
        get {
            let stored = model.value.onboarding ?? defaultOnboardingModel()
            return UIOnboardingModel(stored) { [weak self] updated in
                self?.model.value.onboarding =
                (updated == defaultOnboardingModel()) ? nil : updated
            }
        }
        set {
            let updated = newValue.model
            model.value.onboarding =
            (updated == defaultOnboardingModel()) ? nil : updated
        }
    }
}

public func mockProfileData() -> UIProfileModel {
    UIProfileModel(
        .initial(
            ProfileModel()
        )
    )
}

public enum ColorSchemeMode: CaseIterable, Codable, Sendable {
    case light
    case dark
    case system
    
    public var description: LocalizedStringKey {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return ColorScheme.light
        case .dark:
            return ColorScheme.dark
        case .system:
            return nil
        }
    }
}

