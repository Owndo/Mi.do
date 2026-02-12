//
//  ConfigurationFile.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation

public struct ConfigurationFile {
    public static let appID = "6749021753"
    public static let shareAppURL = URL(string: "https://apps.apple.com/us/app/id\(appID)")!
    public static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? " - Latest"
    public static let privacy = URL(string: "https://github.com/KodiMaberek/Mido.robocode/blob/main/PrivacyPolicy.md")!
    public static let terms = URL(string: "https://github.com/KodiMaberek/Mido.robocode/blob/main/TermsOfUse.md")!
    
    public init() {}
}
