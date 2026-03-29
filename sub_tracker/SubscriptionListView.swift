//
//  SubscriptionListView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData

struct SubscriptionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Subscription.nextPaymentDate) private var subscriptions: [Subscription]
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    @State private var showingAddSubscription = false
    @State private var selectedSubscription: Subscription?

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    var totalMonthly: Double {
        activeSubscriptions.reduce(0) { $0 + $1.convertedMonthlyEquivalent(to: displayCurrency) }
    }

    var totalYearly: Double {
        activeSubscriptions.reduce(0) { $0 + $1.convertedYearlyEquivalent(to: displayCurrency) }
    }
    
    var body: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Monthly Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyConverter.format(totalMonthly, currency: displayCurrency))
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Yearly Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyConverter.format(totalYearly, currency: displayCurrency))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    HStack {
                        Label("\(activeSubscriptions.count) Active", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        Spacer()
                        
                        if subscriptions.count > activeSubscriptions.count {
                            Label("\(subscriptions.count - activeSubscriptions.count) Inactive", systemImage: "pause.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Active Subscriptions
            if !activeSubscriptions.isEmpty {
                Section("Active Subscriptions") {
                    ForEach(activeSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .onTapGesture {
                                selectedSubscription = subscription
                            }
                    }
                    .onDelete(perform: deleteSubscriptions)
                }
            }
            
            // Inactive Subscriptions
            let inactiveSubscriptions = subscriptions.filter { !$0.isActive }
            if !inactiveSubscriptions.isEmpty {
                Section("Inactive Subscriptions") {
                    ForEach(inactiveSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .onTapGesture {
                                selectedSubscription = subscription
                            }
                    }
                    .onDelete(perform: deleteSubscriptions)
                }
            }
            
            // Empty State
            if subscriptions.isEmpty {
                ContentUnavailableView(
                    "No Subscriptions",
                    systemImage: "creditcard.and.123",
                    description: Text("Add your first subscription to start tracking your expenses")
                )
            }
        }
        .navigationTitle("Subscriptions")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSubscription = true
                } label: {
                    Label("Add Subscription", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSubscription) {
            NavigationStack {
                AddEditSubscriptionView()
            }
        }
        .sheet(item: $selectedSubscription) { subscription in
            NavigationStack {
                AddEditSubscriptionView(subscription: subscription)
            }
        }
        .task {
            await notificationManager.checkAuthorizationStatus()
            if !notificationManager.isAuthorized {
                await notificationManager.requestAuthorization()
            }
        }
    }
    
    private func deleteSubscriptions(at offsets: IndexSet) {
        for index in offsets {
            let subscription = subscriptions[index]
            Task {
                await notificationManager.cancelNotification(for: subscription)
            }
            modelContext.delete(subscription)
        }
    }
}

struct SubscriptionRowView: View {
    let subscription: Subscription
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    var daysUntilPayment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextPaymentDate).day ?? 0
    }

    var isPaymentSoon: Bool {
        daysUntilPayment <= subscription.notificationDaysBefore && daysUntilPayment >= 0
    }

    var urgencyColor: Color {
        switch daysUntilPayment {
        case 0...1: return .red
        case 2...3: return .orange
        default:    return .orange
        }
    }

    var daysLabel: String {
        switch daysUntilPayment {
        case 0:  return "Today"
        case 1:  return "Tomorrow"
        default: return "in \(daysUntilPayment) days"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            SubscriptionIconView(subscription: subscription, size: 50)

            // Name + billing cycle
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.headline)

                Label(subscription.billingCycle.rawValue, systemImage: subscription.billingCycle.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Price + due info
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyConverter.format(subscription.convertedPrice(to: displayCurrency), currency: displayCurrency))
                    .font(.headline)

                if !subscription.isActive {
                    Text("Inactive")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                } else {
                    Text(subscription.nextPaymentDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isPaymentSoon {
                        Label(daysLabel, systemImage: "bell.fill")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(urgencyColor)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(subscription.isActive ? 1.0 : 0.6)
    }
}

#Preview {
    NavigationStack {
        SubscriptionListView()
            .modelContainer(for: Subscription.self, inMemory: true)
    }
}
