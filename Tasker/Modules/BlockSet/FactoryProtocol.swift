//
//  FactoryProtocol.swift
//  Tasker
//
//  Created by Rodion Akhmedov on 5/6/25.
//

import Foundation

protocol Factory {
    associatedtype Element
    func callAsFunction() -> Element
}
