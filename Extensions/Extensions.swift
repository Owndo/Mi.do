//
//  Extensions.swift
//  Packages
//
//  Created by Rodion Akhmedov on 7/13/25.
//

import Foundation
import ProjectDescription

extension SettingsDictionary {
    func setProjectVersions() -> SettingsDictionary {
        let currentProjectVersion = "0.7.0"
        let markettingVersion = "0.7.0"
        
        return appleGenericVersioningSystem().merging([
            "CURRENT_PROJECT_VERSION": SettingValue(stringLiteral: currentProjectVersion),
            "MARKETING_VERSION": SettingValue(stringLiteral: markettingVersion)
        ])
    }
}
