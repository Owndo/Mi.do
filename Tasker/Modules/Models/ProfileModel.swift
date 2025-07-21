//
//  ProfileModel.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation
import BlockSet

public typealias ProfileData = Model<ProfileModel>

public struct ProfileModel: Codable {
    public var customTitle: String
    public var notes: String
    public var name: String
    public var photo: String
    public var photoPosition: CGSize
    public var settings: SettingsModel
    
    public init(
        customTitle: String,
        notes: String,
        name: String,
        photo: String,
        photoPosition: CGSize,
        settings: SettingsModel
    ) {
        self.customTitle = customTitle
        self.notes = notes
        self.name = name
        self.photo = photo
        self.photoPosition = photoPosition
        self.settings = settings
    }
}

public struct SettingsModel: Codable, Equatable {
    public var firstDayOfWeek: Int
    public var colorScheme: String
    public var accentColor: String
    public var background: String
    public var minimalProgressMode: Bool
    public var completedTasksHidden: Bool
    
    public init(
        firstDayOfWeek: Int,
        colorScheme: String,
        accentColor: String,
        background: String,
        minimalProgressMode: Bool = true,
        completedTasksHidden: Bool = false
    ) {
        self.firstDayOfWeek = firstDayOfWeek
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.background = background
        self.minimalProgressMode = minimalProgressMode
        self.completedTasksHidden = completedTasksHidden
    }
}

public func mockProfileData() -> ProfileData {
    ProfileData.initial(ProfileModel(customTitle: "", notes: "", name: "", photo: "", photoPosition: .zero, settings: SettingsModel(firstDayOfWeek: 1, colorScheme: "System", accentColor: "#0EBC7C", background: "#F2F5EE")))
}
