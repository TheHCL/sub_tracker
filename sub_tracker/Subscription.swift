//
//  Subscription.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import Foundation
import SwiftData

// MARK: - Backup / Restore helpers

struct SubscriptionExport: Codable {
    var id: UUID
    var name: String
    var price: Double
    var currency: String
    var billingCycle: String
    var nextPaymentDate: Date
    var category: String
    var icon: String
    var notificationDaysBefore: [Int]
    var notificationsEnabled: Bool?
    var isActive: Bool
    var notes: String
}

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
    var notificationDaysBefore: [Int]
    var notificationsEnabled: Bool
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
        notificationDaysBefore: [Int] = [7],
        notificationsEnabled: Bool = true,
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
        self.notificationsEnabled = notificationsEnabled
        self.isActive = isActive
        self.notes = notes
    }
    
    func toExport() -> SubscriptionExport {
        SubscriptionExport(
            id: id,
            name: name,
            price: price,
            currency: currency,
            billingCycle: billingCycle.rawValue,
            nextPaymentDate: nextPaymentDate,
            category: category.rawValue,
            icon: icon,
            notificationDaysBefore: notificationDaysBefore,
            notificationsEnabled: notificationsEnabled,
            isActive: isActive,
            notes: notes
        )
    }

    static func from(export e: SubscriptionExport) -> Subscription {
        Subscription(
            id: e.id,
            name: e.name,
            price: e.price,
            currency: e.currency,
            billingCycle: BillingCycle(rawValue: e.billingCycle) ?? .monthly,
            nextPaymentDate: e.nextPaymentDate,
            category: SubscriptionCategory(rawValue: e.category) ?? .other,
            icon: e.icon,
            notificationDaysBefore: e.notificationDaysBefore,
            notificationsEnabled: e.notificationsEnabled ?? true,
            isActive: e.isActive,
            notes: e.notes
        )
    }

    // Calculate the next payment date based on billing cycle
    func nextPaymentDateAfterRenewal(from date: Date, cycle: BillingCycle) -> Date {
        let calendar = Calendar.current
        switch cycle {
        case .monthly:    return calendar.date(byAdding: .month,  value: 1,  to: date) ?? date
        case .quarterly:  return calendar.date(byAdding: .month,  value: 3,  to: date) ?? date
        case .halfYearly: return calendar.date(byAdding: .month,  value: 6,  to: date) ?? date
        case .yearly:     return calendar.date(byAdding: .year,   value: 1,  to: date) ?? date
        }
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

    func localizedName(_ lm: LanguageManager) -> String {
        switch self {
        case .monthly:   return lm.s("Monthly", "每月")
        case .quarterly: return lm.s("Quarterly", "每季")
        case .halfYearly: return lm.s("Half-Yearly", "半年")
        case .yearly:    return lm.s("Yearly", "每年")
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

    func localizedName(_ lm: LanguageManager) -> String {
        switch self {
        case .streaming:    return lm.s("Streaming", "影音串流")
        case .music:        return lm.s("Music", "音樂")
        case .ai:           return lm.s("AI & Tools", "AI 工具")
        case .productivity: return lm.s("Productivity", "生產力")
        case .cloud:        return lm.s("Cloud Storage", "雲端儲存")
        case .gaming:       return lm.s("Gaming", "遊戲")
        case .news:         return lm.s("News & Media", "新聞媒體")
        case .fitness:      return lm.s("Fitness", "健身")
        case .other:        return lm.s("Other", "其他")
        }
    }
}
