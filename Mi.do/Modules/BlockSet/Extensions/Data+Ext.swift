//
//  Data+Ext.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 1/16/26.
//

import Foundation
import CryptoKit

public extension Data {
    func sha256Id() -> String {
        SHA256.hash(data: self).base32()
    }
}
