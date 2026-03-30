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
    @EnvironmentObject private var lm: LanguageManager

    @State private var timeFrame: TimeFrame = .monthly

    enum TimeFrame: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"

        func label(_ lm: LanguageManager) -> String {
            switch self {
            case .monthly: return lm.s("Monthly", "每月")
            case .yearly:  return lm.s("Yearly", "每年")
            }
        }
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
                Picker(lm.s("Time Frame", "時間範圍"), selection: $timeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { frame in
                        Text(frame.label(lm)).tag(frame)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            // Total Spending
            Section {
                VStack(spacing: 8) {
                    Text(lm.s("Total \(timeFrame.label(lm)) Spending", "總\(timeFrame.label(lm))支出"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(CurrencyConverter.format(totalSpending, currency: displayCurrency))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(lm.s(
                        "\(activeSubscriptions.count) active subscription\(activeSubscriptions.count == 1 ? "" : "s")",
                        "\(activeSubscriptions.count) 個啟用中的訂閱"
                    ))
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
                                angle: .value(lm.s("Amount", "金額"), item.amount),
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
                                Text(timeFrame.label(lm))
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
                                            Text(item.category.localizedName(lm))
                                                .font(.subheadline)
                                            Spacer()
                                            Text(CurrencyConverter.format(item.amount, currency: displayCurrency))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                        }

                                        HStack {
                                            Text(lm.s(
                                                "\(item.count) subscription\(item.count == 1 ? "" : "s")",
                                                "\(item.count) 個訂閱"
                                            ))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(totalSpending > 0 ? "\(Int((item.amount / totalSpending) * 100))%" : "0%")
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
                    Text(lm.s("Spending by Category", "各類別支出"))
                }
            }

            // Billing Cycle Breakdown
            Section(lm.s("Billing Cycles", "計費週期")) {
                let cycleBreakdown = Dictionary(grouping: activeSubscriptions) { $0.billingCycle }

                ForEach(BillingCycle.allCases, id: \.self) { cycle in
                    if let subs = cycleBreakdown[cycle], !subs.isEmpty {
                        HStack {
                            Label(cycle.localizedName(lm), systemImage: cycle.icon)
                            Spacer()
                            Text("\(subs.count)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Upcoming Payments
            Section(lm.s("Upcoming Payments (30 Days)", "即將到期（30 天內）")) {
                let upcomingSubscriptions = activeSubscriptions
                    .filter { subscription in
                        let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: subscription.nextPaymentDate).day ?? 0
                        return daysUntil >= 0 && daysUntil <= 30
                    }
                    .sorted { $0.nextPaymentDate < $1.nextPaymentDate }

                if upcomingSubscriptions.isEmpty {
                    Text(lm.s("No upcoming payments in the next 30 days", "近 30 天內無到期付款"))
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
                    lm.s("No Active Subscriptions", "尚無啟用的訂閱"),
                    systemImage: "chart.pie",
                    description: Text(lm.s("Add some subscriptions to see your spending statistics", "新增訂閱以查看支出統計"))
                )
            }
        }
        .navigationTitle(lm.s("Statistics", "統計"))
    }
}

struct UpcomingPaymentRow: View {
    let subscription: Subscription
    @AppStorage("displayCurrency") private var displayCurrency = "USD"
    @EnvironmentObject private var lm: LanguageManager

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
        case 0:  return lm.s("Today", "今天")
        case 1:  return lm.s("Tomorrow", "明天")
        default: return lm.s("in \(daysUntil) days", "\(daysUntil) 天後")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            SubscriptionIconView(subscription: subscription, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Label(subscription.billingCycle.localizedName(lm), systemImage: subscription.billingCycle.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

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
