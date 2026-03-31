//
//  RenewalPromptView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/31.
//

import SwiftUI
import SwiftData

struct RenewalPromptView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var lm: LanguageManager
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    let subscription: Subscription
    var onSnooze: (() -> Void)? = nil

    @State private var renewPrice: Double
    @State private var renewCurrency: String
    @State private var renewBillingCycle: BillingCycle

    let currencies = allCurrencies

    init(subscription: Subscription, onSnooze: (() -> Void)? = nil) {
        self.subscription = subscription
        self.onSnooze = onSnooze
        _renewPrice = State(initialValue: subscription.price)
        _renewCurrency = State(initialValue: subscription.currency)
        _renewBillingCycle = State(initialValue: subscription.billingCycle)
    }

    private var nextDatePreview: Date {
        let base = max(subscription.nextPaymentDate, Calendar.current.startOfDay(for: Date()))
        return subscription.nextPaymentDateAfterRenewal(from: base, cycle: renewBillingCycle)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Subscription header
                Section {
                    HStack(spacing: 14) {
                        SubscriptionIconView(subscription: subscription, size: 50)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscription.name)
                                .font(.headline)
                            Text(lm.s("Subscription has expired or is due today", "訂閱已到期或今天到期"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Renewal terms (editable)
                Section(lm.s("Renewal Terms", "續訂條件")) {
                    HStack {
                        Picker(lm.s("Currency", "貨幣"), selection: $renewCurrency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .frame(width: 100)

                        TextField(lm.s("Price", "金額"), value: $renewPrice, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }

                    Picker(lm.s("Billing Cycle", "計費週期"), selection: $renewBillingCycle) {
                        ForEach(BillingCycle.allCases, id: \.self) { cycle in
                            Label(cycle.localizedName(lm), systemImage: cycle.icon)
                                .tag(cycle)
                        }
                    }
                }

                // Preview next payment date
                Section {
                    HStack {
                        Text(lm.s("Next Payment Date", "下次付款日"))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(nextDatePreview, style: .date)
                            .fontWeight(.semibold)
                    }
                }

                // Actions
                Section {
                    Button {
                        confirmRenewal()
                    } label: {
                        Label(lm.s("Confirm Renewal", "確認續訂"), systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.white)
                    }
                    .listRowBackground(Color.accentColor)
                    .disabled(renewPrice <= 0)

                    Button(role: .destructive) {
                        cancelSubscription()
                    } label: {
                        Label(lm.s("Cancel Subscription", "取消訂閱"), systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }

                // Dismiss without action
                Section {
                    Button {
                        onSnooze?()
                        dismiss()
                    } label: {
                        Text(lm.s("Remind Me Later", "稍後提醒"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(lm.s("Renewal Due", "訂閱到期"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(lm.s("Later", "稍後")) {
                        onSnooze?()
                        dismiss()
                    }
                }
            }
        }
    }

    private func confirmRenewal() {
        let base = max(subscription.nextPaymentDate, Calendar.current.startOfDay(for: Date()))
        // Cancel old notifications before mutating nextPaymentDate,
        // because the identifiers are derived from the current date.
        Task {
            await notificationManager.cancelNotification(for: subscription)
            subscription.price = renewPrice
            subscription.currency = renewCurrency
            subscription.billingCycle = renewBillingCycle
            subscription.nextPaymentDate = subscription.nextPaymentDateAfterRenewal(from: base, cycle: renewBillingCycle)
            subscription.isActive = true
            await notificationManager.scheduleNotification(for: subscription)
        }
        dismiss()
    }

    private func cancelSubscription() {
        subscription.isActive = false
        Task {
            await notificationManager.cancelNotification(for: subscription)
        }
        dismiss()
    }
}
