//
//  CurrencyManager.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI

// MARK: - Supported currencies

let allCurrencies = ["USD", "EUR", "GBP", "JPY", "CNY", "CAD", "AUD", "TWD"]

// MARK: - Converter

struct CurrencyConverter {
    /// Static approximate rates relative to USD.
    /// Replace with a live-API call for production use.
    static let ratesFromUSD: [String: Double] = [
        "USD": 1.00,
        "EUR": 0.92,
        "GBP": 0.79,
        "JPY": 149.50,
        "CNY": 7.24,
        "CAD": 1.36,
        "AUD": 1.53,
        "TWD": 32.30,
    ]

    static func convert(_ amount: Double, from: String, to: String) -> Double {
        guard from != to else { return amount }
        let fromRate = ratesFromUSD[from] ?? 1.0
        let toRate   = ratesFromUSD[to]   ?? 1.0
        return (amount / fromRate) * toRate
    }

    static func symbol(for currency: String) -> String {
        switch currency {
        case "USD": return "US$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "CN¥"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        case "TWD": return "NT$"
        default:    return currency
        }
    }

    /// Formats an amount with the correct currency symbol and decimal places.
    static func format(_ amount: Double, currency: String) -> String {
        let sym = symbol(for: currency)
        switch currency {
        case "JPY":
            return "\(sym)\(Int(amount.rounded()))"
        default:
            return String(format: "\(sym)%.2f", amount)
        }
    }
}

// MARK: - Subscription helpers

extension Subscription {
    func convertedPrice(to displayCurrency: String) -> Double {
        CurrencyConverter.convert(price, from: currency, to: displayCurrency)
    }

    func convertedMonthlyEquivalent(to displayCurrency: String) -> Double {
        CurrencyConverter.convert(monthlyEquivalent, from: currency, to: displayCurrency)
    }

    func convertedYearlyEquivalent(to displayCurrency: String) -> Double {
        CurrencyConverter.convert(yearlyEquivalent, from: currency, to: displayCurrency)
    }
}
