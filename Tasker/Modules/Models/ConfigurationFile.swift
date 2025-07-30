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
    public var appVersion = "1.0.0"
    public let privacy = URL(string: "https://github.com/KodiMaberek/Mido.robocode/blob/main/PrivacyPolicy.md")!
    public let terms = URL(string: "https://github.com/KodiMaberek/Mido.robocode/blob/main/TermsOfUse.md")!
    
    public init() {}
}
