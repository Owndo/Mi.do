//
//  Alerts.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 12/9/25.
//

import Foundation
import SwiftUI

enum PaywallAlerts {
    case restoreAlert
    case cannotLoadProductsAlert
    case purchaseFailed
    
    static func makeAlert(_ type: Self) -> Alert {
        switch type {
        case .restoreAlert:
            return Alert(
                title: Text("Nothing to restore 🤷‍♂️"),
                message:  Text("I’d love to bring something back… but there’s nothing yet."),
                dismissButton: .default(Text("No luck"))
            )
        case .cannotLoadProductsAlert:
            return Alert(
                title: Text("Nothing to restore 🤷‍♂️"),
                message:  Text("I’d love to bring something back… but there’s nothing yet."),
                dismissButton: .default(Text("No luck"))
            )
        case .purchaseFailed:
            return Alert(
                title: Text("Wooow"),
                message: Text("We couldn’t process your purchase. Try again later."),
                dismissButton: .default(Text("I'll try"))
            )
        }
    }
}
