//
//  ProfileAction.swift
//  Managers
//
//  Created by Rodion Akhmedov on 7/21/25.
//

import Foundation

// MARK: - Profile View Action Enum
public enum ProfileViewAction {
    case addPhotoButtonTapped
    case deletePhotoButtonTapped
    case productivityArticleView(ProductivityArticleViewAction)
    case taskHistoryButtonTapped
    case appearanceButtonTapped
    case dayOfWeekChangeButtonTapped
    case privacyButtonTapped
    case termsOfUseButtonTapped
    case closeButtonTapped
}

// MARK: - Supporting Enums
public enum ProductivityArticleViewAction {
    case openView
    case closeView
    case openArticle
}

// MARK: - Helper Extensions
extension ProductivityArticleViewAction {
    var analyticsData: (eventName: String, properties: [String: Any]?) {
        switch self {
        case .openView:
            return ("Productivity Article View Open", nil)
        case .closeView:
            return ("Productivity Article View Close", nil)
        case .openArticle:
            return ("Productivity Article Open", ["Source": "Profile"])
        }
    }
}

// MARK: - ProfileViewAction Analytics Extension
extension ProfileViewAction: AnalyticsTrackable {
    var eventName: String {
        switch self {
        case .addPhotoButtonTapped:
            return "Add Photo"
        case .deletePhotoButtonTapped:
            return "Delete Photo"
        case .productivityArticleView(let action):
            return action.analyticsData.eventName
        case .taskHistoryButtonTapped:
            return "Task History"
        case .appearanceButtonTapped:
            return "Appearance Settings"
        case .dayOfWeekChangeButtonTapped:
            return "Day Of Week Change"
        case .privacyButtonTapped:
            return "Privacy Policy"
        case .termsOfUseButtonTapped:
            return "Terms Of Use"
        case .closeButtonTapped:
            return "Close button"
        }
    }
    
    var properties: [String: Any]? {
        switch self {
        case .productivityArticleView(let action):
            return action.analyticsData.properties
        case .addPhotoButtonTapped, .deletePhotoButtonTapped:
            return ["Section": "Profile Photo"]
        case .taskHistoryButtonTapped, .appearanceButtonTapped, .dayOfWeekChangeButtonTapped:
            return ["Section": "Settings"]
        case .privacyButtonTapped, .termsOfUseButtonTapped:
            return ["Section": "Legal"]
        case .closeButtonTapped:
            return ["Button": "Close"]
        }
    }
}
