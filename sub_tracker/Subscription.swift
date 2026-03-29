//
//  Subscription.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import Foundation
import SwiftData

@Model
final class Subscription {
    var id: UUID
    var name: String
    var price: Double
    var currency: String
    var billingCycle: BillingCycle
    var nextPaymentDate: Date
    var category: SubscriptionCategory
    var icon: String
    var notificationDaysBefore: Int
    var isActive: Bool
    var notes: String
    
    init(
        id: UUID = UUID(),
        name: String,
        price: Double,
        currency: String = "USD",
        billingCycle: BillingCycle,
        nextPaymentDate: Date,
        category: SubscriptionCategory,
        icon: String = "app.fill",
        notificationDaysBefore: Int = 7,
        isActive: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.billingCycle = billingCycle
        self.nextPaymentDate = nextPaymentDate
        self.category = category
        self.icon = icon
        self.notificationDaysBefore = notificationDaysBefore
        self.isActive = isActive
        self.notes = notes
    }
    
    // Calculate monthly cost for analytics
    var monthlyEquivalent: Double {
        switch billingCycle {
        case .monthly:
            return price
        case .quarterly:
            return price / 3
        case .halfYearly:
            return price / 6
        case .yearly:
            return price / 12
        }
    }
    
    // Calculate yearly cost for analytics
    var yearlyEquivalent: Double {
        switch billingCycle {
        case .monthly:
            return price * 12
        case .quarterly:
            return price * 4
        case .halfYearly:
            return price * 2
        case .yearly:
            return price
        }
    }
}

enum BillingCycle: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case halfYearly = "Half-Yearly"
    case yearly = "Yearly"
    
    var icon: String {
        switch self {
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.clock"
        case .halfYearly: return "calendar.circle"
        case .yearly: return "calendar.badge.plus"
        }
    }
}

enum SubscriptionCategory: String, Codable, CaseIterable {
    case streaming = "Streaming"
    case music = "Music"
    case ai = "AI & Tools"
    case productivity = "Productivity"
    case cloud = "Cloud Storage"
    case gaming = "Gaming"
    case news = "News & Media"
    case fitness = "Fitness"
    case other = "Other"
    
    var color: String {
        switch self {
        case .streaming: return "red"
        case .music: return "pink"
        case .ai: return "purple"
        case .productivity: return "blue"
        case .cloud: return "cyan"
        case .gaming: return "green"
        case .news: return "orange"
        case .fitness: return "mint"
        case .other: return "gray"
        }
    }
    
    var icon: String {
        switch self {
        case .streaming: return "tv.fill"
        case .music: return "music.note"
        case .ai: return "brain.head.profile"
        case .productivity: return "briefcase.fill"
        case .cloud: return "cloud.fill"
        case .gaming: return "gamecontroller.fill"
        case .news: return "newspaper.fill"
        case .fitness: return "figure.run"
        case .other: return "star.fill"
        }
    }
}
