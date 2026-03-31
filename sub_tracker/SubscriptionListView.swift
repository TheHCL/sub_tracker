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
    @EnvironmentObject private var lm: LanguageManager

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
                            Text(lm.s("Monthly Total", "每月總計"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyConverter.format(totalMonthly, currency: displayCurrency))
                                .font(.title2)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text(lm.s("Yearly Total", "每年總計"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyConverter.format(totalYearly, currency: displayCurrency))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }

                    HStack {
                        Label(lm.s("\(activeSubscriptions.count) Active", "\(activeSubscriptions.count) 個啟用"), systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)

                        Spacer()

                        if subscriptions.count > activeSubscriptions.count {
                            Label(lm.s("\(subscriptions.count - activeSubscriptions.count) Inactive", "\(subscriptions.count - activeSubscriptions.count) 個停用"), systemImage: "pause.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Active Subscriptions
            if !activeSubscriptions.isEmpty {
                Section(lm.s("Active Subscriptions", "啟用中的訂閱")) {
                    ForEach(activeSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .onTapGesture {
                                selectedSubscription = subscription
                            }
                    }
                    .onDelete { offsets in deleteSubscriptions(at: offsets, from: activeSubscriptions) }
                }
            }

            // Inactive Subscriptions
            let inactiveSubscriptions = subscriptions.filter { !$0.isActive }
            if !inactiveSubscriptions.isEmpty {
                Section(lm.s("Inactive Subscriptions", "已停用的訂閱")) {
                    ForEach(inactiveSubscriptions) { subscription in
                        SubscriptionRowView(subscription: subscription)
                            .onTapGesture {
                                selectedSubscription = subscription
                            }
                    }
                    .onDelete { offsets in deleteSubscriptions(at: offsets, from: inactiveSubscriptions) }
                }
            }
            
            // Empty State
            if subscriptions.isEmpty {
                ContentUnavailableView(
                    lm.s("No Subscriptions", "尚無訂閱"),
                    systemImage: "creditcard.and.123",
                    description: Text(lm.s("Add your first subscription to start tracking your expenses", "新增第一筆訂閱，開始追蹤你的支出"))
                )
            }
        }
        .navigationTitle(lm.s("Subscriptions", "訂閱"))
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSubscription = true
                } label: {
                    Label(lm.s("Add Subscription", "新增訂閱"), systemImage: "plus")
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
            WidgetDataWriter.write(subscriptions)
        }
        .onChange(of: subscriptions) {
            WidgetDataWriter.write(subscriptions)
        }
    }
    
    private func deleteSubscriptions(at offsets: IndexSet, from source: [Subscription]) {
        for index in offsets {
            let subscription = source[index]
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
    @EnvironmentObject private var lm: LanguageManager

    var daysUntilPayment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextPaymentDate).day ?? 0
    }

    var isPaymentSoon: Bool {
        daysUntilPayment >= 0 && subscription.notificationDaysBefore.contains(where: { daysUntilPayment <= $0 })
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
        case 0:  return lm.s("Today", "今天")
        case 1:  return lm.s("Tomorrow", "明天")
        default: return lm.s("in \(daysUntilPayment) days", "\(daysUntilPayment) 天後")
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
                    Text(lm.s("Inactive", "已停用"))
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

                    if !subscription.notificationsEnabled {
                        Label(lm.s("Muted", "已靜音"), systemImage: "bell.slash.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else if isPaymentSoon {
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
