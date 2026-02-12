//
//  Subsctring+Ext.swift
//  BlockSet
//
//  Created by Rodion Akhmedov on 10/27/25.
//

import Foundation

extension Substring {
    func split2() -> (Substring, Substring) {
        (self.prefix(2), self.dropFirst(2))
    }
}
