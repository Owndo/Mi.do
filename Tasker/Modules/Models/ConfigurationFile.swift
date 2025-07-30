//
//  ConfigurationFile.swift
//  Models
//
//  Created by Rodion Akhmedov on 7/12/25.
//

import Foundation

public struct ConfigurationFile {
    public static let appID = ""
    public static let shareAppURL = URL(string: "https://apps.apple.com/us/app/id\(appID)")!
    public var appVersion = "1.0.0"
    static let privacy = URL(string: "https://docs.google.com/document/d/1-F4jmvOF08bNwX61sbBEdidkz0fL5Bb-ZU-gn03Krwk/edit?usp=sharing")!
    static let terms = URL(string: "https://docs.google.com/document/d/1cSjNSavncEGGQSagC1T2karPltNip8PRvssBlClmZZ8/edit?usp=sharing")!
    
    public init() {}
}
