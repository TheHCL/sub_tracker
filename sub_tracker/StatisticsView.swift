//
//  StatisticsView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query private var subscriptions: [Subscription]
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    @State private var timeFrame: TimeFrame = .monthly

    enum TimeFrame: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.isActive }
    }

    var categoryBreakdown: [(category: SubscriptionCategory, amount: Double, count: Int)] {
        let grouped = Dictionary(grouping: activeSubscriptions) { $0.category }

        return grouped.map { category, subs in
            let amount = subs.reduce(0.0) { total, sub in
                total + (timeFrame == .monthly
                    ? sub.convertedMonthlyEquivalent(to: displayCurrency)
                    : sub.convertedYearlyEquivalent(to: displayCurrency))
            }
            return (category, amount, subs.count)
        }
        .sorted { $0.amount > $1.amount }
    }

    var totalSpending: Double {
        activeSubscriptions.reduce(0) { total, sub in
            total + (timeFrame == .monthly
                ? sub.convertedMonthlyEquivalent(to: displayCurrency)
                : sub.convertedYearlyEquivalent(to: displayCurrency))
        }
    }
    
    var body: some View {
        List {
            // Time Frame Picker
            Section {
                Picker("Time Frame", selection: $timeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { frame in
                        Text(frame.rawValue).tag(frame)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)
            
            // Total Spending
            Section {
                VStack(spacing: 8) {
                    Text("Total \(timeFrame.rawValue) Spending")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(CurrencyConverter.format(totalSpending, currency: displayCurrency))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("\(activeSubscriptions.count) active subscription\(activeSubscriptions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
            
            // Pie Chart
            if !categoryBreakdown.isEmpty {
                Section {
                    VStack(spacing: 20) {
                        Chart(categoryBreakdown, id: \.category) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.5),
                                angularInset: 2
                            )
                            .foregroundStyle(item.category.swiftUIColor)
                            .cornerRadius(4)
                            .opacity(0.85)
                        }
                        .frame(height: 300)
                        .chartBackground { _ in
                            VStack(spacing: 4) {
                                Text(CurrencyConverter.format(totalSpending, currency: displayCurrency))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                Text(timeFrame.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 8)
                        }
                        
                        // Legend
                        VStack(spacing: 12) {
                            ForEach(categoryBreakdown, id: \.category) { item in
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(item.category.swiftUIColor)
                                        .frame(width: 30, height: 20)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(item.category.rawValue)
                                                .font(.subheadline)
                                            Spacer()
                                            Text(CurrencyConverter.format(item.amount, currency: displayCurrency))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        HStack {
                                            Text("\(item.count) subscription\(item.count == 1 ? "" : "s")")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("\(Int((item.amount / totalSpending) * 100))%")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Spending by Category")
                }
            }
            
            // Billing Cycle Breakdown
            Section("Billing Cycles") {
                let cycleBreakdown = Dictionary(grouping: activeSubscriptions) { $0.billingCycle }
                
                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                    if let subs = cycleBreakdown[cycle], !subs.isEmpty {
                        HStack {
                            Label(cycle.rawValue, systemImage: cycle.icon)
                            Spacer()
                            Text("\(subs.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Upcoming Payments
            Section("Upcoming Payments (30 Days)") {
                let upcomingSubscriptions = activeSubscriptions
                    .filter { subscription in
                        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextPaymentDate).day ?? 0
                        return daysUntil >= 0 && daysUntil <= 30
                    }
                    .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
                
                if upcomingSubscriptions.isEmpty {
                    Text("No upcoming payments in the next 30 days")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(upcomingSubscriptions) { subscription in
                        UpcomingPaymentRow(subscription: subscription)
                    }
                }
            }
            
            // Empty State
            if activeSubscriptions.isEmpty {
                ContentUnavailableView(
                    "No Active Subscriptions",
                    systemImage: "chart.pie",
                    description: Text("Add some subscriptions to see your spending statistics")
                )
            }
        }
        .navigationTitle("Statistics")
    }
}

struct UpcomingPaymentRow: View {
    let subscription: Subscription
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextPaymentDate).day ?? 0
    }

    var urgencyColor: Color {
        switch daysUntil {
        case 0...1:  return .red
        case 2...3:  return .orange
        default:     return .secondary
        }
    }

    var daysLabel: String {
        switch daysUntil {
        case 0:  return "Today"
        case 1:  return "Tomorrow"
        default: return "in \(daysUntil) days"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Brand / category icon
            SubscriptionIconView(subscription: subscription, size: 44)

            // Name + billing cycle
            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Label(subscription.billingCycle.rawValue, systemImage: subscription.billingCycle.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Price + due info
            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyConverter.format(
                    subscription.convertedPrice(to: displayCurrency),
                    currency: displayCurrency
                ))
                .font(.subheadline)
                .fontWeight(.semibold)

                Text(subscription.nextPaymentDate, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(daysLabel, systemImage: "bell.fill")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(urgencyColor)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
            .modelContainer(for: Subscription.self, inMemory: true)
    }
}
