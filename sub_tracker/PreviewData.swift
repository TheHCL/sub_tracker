//
//  PreviewData.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import Foundation
import SwiftData

@MainActor
class PreviewData {
    static let shared = PreviewData()
    
    let container: ModelContainer
    
    private init() {
        let schema = Schema([
            Subscription.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Add sample data
            let sampleSubscriptions = [
                Subscription(
                    name: "Apple Music",
                    price: 10.99,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                    category: .music,
                    icon: "music.note",
                    notificationDaysBefore: [7]
                ),
                Subscription(
                    name: "Netflix",
                    price: 15.99,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
                    category: .streaming,
                    icon: "tv.fill",
                    notificationDaysBefore: [7]
                ),
                Subscription(
                    name: "YouTube Premium",
                    price: 13.99,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                    category: .streaming,
                    icon: "play.rectangle.fill",
                    notificationDaysBefore: [7]
                ),
                Subscription(
                    name: "Claude Pro",
                    price: 20.00,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!,
                    category: .ai,
                    icon: "brain.head.profile",
                    notificationDaysBefore: [3]
                ),
                Subscription(
                    name: "iCloud+",
                    price: 99.99,
                    currency: "USD",
                    billingCycle: .yearly,
                    nextPaymentDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
                    category: .cloud,
                    icon: "cloud.fill",
                    notificationDaysBefore: [14]
                ),
                Subscription(
                    name: "Adobe Creative Cloud",
                    price: 54.99,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
                    category: .productivity,
                    icon: "paintbrush.fill",
                    notificationDaysBefore: [7]
                ),
                Subscription(
                    name: "Spotify (Old)",
                    price: 9.99,
                    currency: "USD",
                    billingCycle: .monthly,
                    nextPaymentDate: Calendar.current.date(byAdding: .day, value: -30, to: Date())!,
                    category: .music,
                    icon: "music.quarternote.3",
                    notificationDaysBefore: [7],
                    isActive: false
                )
            ]
            
            for subscription in sampleSubscriptions {
                container.mainContext.insert(subscription)
            }
            
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
