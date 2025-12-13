//
//  Product+Ext.swift
//  AppDelegate
//
//  Created by Rodion Akhmedov on 12/9/25.
//

import Foundation
import StoreKit
import SwiftUI

//MARK: - Extension
public extension Product {
    var dividedByWeek: String {
        guard let unit = subscription?.subscriptionPeriod.unit else { return "" }
        
        let divisor: Decimal = unit == .month ? 4 : unit == .year ? 48 : 0
        guard divisor > 0 else { return "" }
        
        let weeklyPrice = price / divisor
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: weeklyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice)"
    }
    
    var dividedByMonth: String {
        guard subscription?.subscriptionPeriod.unit == .year else { return "" }
        
        let monthlyPrice = price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: monthlyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice)"
    }
    
    var dividedYearByWeek: String {
        guard subscription?.subscriptionPeriod.unit == .year else { return "" }
        
        let monthlyPrice = price / 52
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = priceFormatStyle.currencyCode
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        guard let formattedPrice = formatter.string(from: monthlyPrice as NSDecimalNumber) else { return "" }
        return "\(formattedPrice)"
    }
}

public extension Product {
    func isEligibleForFreeTrial() async -> Bool {
        guard let subscription = self.subscription else {
            return false
        }
        
        return await subscription.isEligibleForIntroOffer
    }
    
    func intoductoryOffer() -> LocalizedStringKey? {
        guard let offer = self.subscription?.introductoryOffer else {
            return nil
        }
        
        // TODO: - ask apple about this shit
        // In case debug mode
        guard offer.period.unit == .day else {
            if offer.period == .weekly {
                switch offer.period {
                case .weekly:
                    return "Free week"
                default:
                    return nil
                }
            } else {
                return nil
            }
        }
        
        // In case release mode
        if offer.period.value == 7 {
            return "Free week"
        } else {
            return nil
        }
    }
}

public extension Product.SubscriptionPeriod.Unit {
    var periodDescription: LocalizedStringKey {
        switch self {
        case .day:
            return "/ day"
        case .week:
            return "/ week"
        case .month:
            return "/ month"
        case .year:
            return "/ year"
        default:
            return ""
        }
    }
    
    var devidedPeriodByWeek: LocalizedStringKey {
        switch self {
        case .day:
            return " / week"
        case .week:
            return " / week"
        case .month:
            return " / week"
        case .year:
            return " / week"
        default:
            return ""
        }
    }
}
