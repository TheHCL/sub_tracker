//
//  AddEditSubscriptionView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData

struct AddEditSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var lm: LanguageManager

    let subscription: Subscription?
    
    @State private var name: String = ""
    @State private var price: Double = 0.0
    @State private var currency: String = "USD"
    @State private var billingCycle: BillingCycle = .monthly
    @State private var nextPaymentDate: Date = Date()
    @State private var category: SubscriptionCategory = .other
    @State private var icon: String = "app.fill"
    @State private var notificationDaysBefore: [Int] = [7]
    @State private var notificationsEnabled: Bool = true
    @State private var isActive: Bool = true
    @State private var notes: String = ""

    let currencies = allCurrencies
    
    // Predefined subscription templates
    let subscriptionTemplates: [(name: String, icon: String, category: SubscriptionCategory)] = [
        ("Apple Music", "music.note", .music),
        ("Netflix", "tv.fill", .streaming),
        ("YouTube Premium", "play.rectangle.fill", .streaming),
        ("Claude Pro", "brain.head.profile", .ai),
        ("ChatGPT Plus", "bubble.left.and.bubble.right.fill", .ai),
        ("Spotify", "music.quarternote.3", .music),
        ("Disney+", "play.tv.fill", .streaming),
        ("Amazon Prime", "shippingbox.fill", .streaming),
        ("iCloud+", "cloud.fill", .cloud),
        ("Dropbox", "folder.fill", .cloud),
        ("Google One", "internaldrive.fill", .cloud),
        ("Adobe Creative Cloud", "paintbrush.fill", .productivity),
        ("Microsoft 365", "doc.text.fill", .productivity),
        ("GitHub Pro", "chevron.left.forwardslash.chevron.right", .productivity),
    ]
    
    init(subscription: Subscription? = nil) {
        self.subscription = subscription
    }
    
    var body: some View {
        Form {
            // Quick Templates
            if subscription == nil {
                Section(lm.s("Popular Subscriptions", "熱門訂閱")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(subscriptionTemplates, id: \.name) { template in
                                TemplateButton(
                                    name: template.name,
                                    icon: template.icon,
                                    category: template.category
                                ) {
                                    name = template.name
                                    icon = template.icon
                                    category = template.category
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }
            }
            
            // Basic Information
            Section(lm.s("Basic Information", "基本資訊")) {
                TextField(lm.s("Name", "名稱"), text: $name)

                Picker(lm.s("Category", "類別"), selection: $category) {
                    ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }
            }
            
            // Pricing
            Section(lm.s("Pricing", "費用")) {
                HStack {
                    Picker(lm.s("Currency", "貨幣"), selection: $currency) {
                        ForEach(currencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                    .frame(width: 100)
                    
                    TextField(lm.s("Price", "金額"), value: $price, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker(lm.s("Billing Cycle", "計費週期"), selection: $billingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Label(cycle.rawValue, systemImage: cycle.icon)
                            .tag(cycle)
                    }
                }
                
                DatePicker(lm.s("Next Payment", "下次付款"), selection: $nextPaymentDate, displayedComponents: .date)
            }
            
            // Cost Summary
            Section {
                HStack {
                    Text(lm.s("Monthly equivalent", "每月費用"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currency) \(monthlyEquivalent, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }

                HStack {
                    Text(lm.s("Yearly equivalent", "每年費用"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currency) \(yearlyEquivalent, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
            }
            
            // Notifications
            Section {
                Toggle(isOn: $notificationsEnabled) {
                    Label(lm.s("Enable Notifications", "啟用通知"), systemImage: notificationsEnabled ? "bell.fill" : "bell.slash.fill")
                }

                if notificationsEnabled {
                    NotificationReminderRow(days: 30, label: lm.s("30 days before", "30 天前"), selection: $notificationDaysBefore)
                    NotificationReminderRow(days: 7,  label: lm.s("7 days before",  "7 天前"),  selection: $notificationDaysBefore)
                    NotificationReminderRow(days: 3,  label: lm.s("3 days before",  "3 天前"),  selection: $notificationDaysBefore)
                    NotificationReminderRow(days: 0,  label: lm.s("On the day",     "當天"),    selection: $notificationDaysBefore)
                }
            } header: {
                Text(lm.s("Reminders", "提醒"))
            } footer: {
                if notificationsEnabled {
                    Text(lm.s(
                        "Daily reminders will be sent every day from the selected start date until the payment date, at the time set in Settings.",
                        "從所選起始天數到付款當天，每天都會在設定的時間點發出通知。"
                    ))
                }
            }
            
            // Status
            Section {
                Toggle(lm.s("Active Subscription", "啟用訂閱"), isOn: $isActive)
            }
            
            // Notes
            Section(lm.s("Notes", "備註")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(subscription == nil ? lm.s("Add Subscription", "新增訂閱") : lm.s("Edit Subscription", "編輯訂閱"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(lm.s("Cancel", "取消")) {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button(lm.s("Save", "儲存")) {
                    saveSubscription()
                }
                .disabled(name.isEmpty || price <= 0)
            }
        }
        .onAppear {
            loadSubscriptionData()
        }
    }
    
    private var monthlyEquivalent: Double {
        switch billingCycle {
        case .monthly: return price
        case .quarterly: return price / 3
        case .halfYearly: return price / 6
        case .yearly: return price / 12
        }
    }
    
    private var yearlyEquivalent: Double {
        switch billingCycle {
        case .monthly: return price * 12
        case .quarterly: return price * 4
        case .halfYearly: return price * 2
        case .yearly: return price
        }
    }
    
    private func loadSubscriptionData() {
        guard let subscription = subscription else { return }
        
        name = subscription.name
        price = subscription.price
        currency = subscription.currency
        billingCycle = subscription.billingCycle
        nextPaymentDate = subscription.nextPaymentDate
        category = subscription.category
        icon = subscription.icon
        notificationDaysBefore = subscription.notificationDaysBefore.isEmpty ? [7] : subscription.notificationDaysBefore
        notificationsEnabled = subscription.notificationsEnabled
        isActive = subscription.isActive
        notes = subscription.notes
    }
    
    private func saveSubscription() {
        if let existingSubscription = subscription {
            // Update existing
            existingSubscription.name = name
            existingSubscription.price = price
            existingSubscription.currency = currency
            existingSubscription.billingCycle = billingCycle
            existingSubscription.nextPaymentDate = nextPaymentDate
            existingSubscription.category = category
            existingSubscription.icon = icon
            existingSubscription.notificationDaysBefore = notificationDaysBefore
            existingSubscription.notificationsEnabled = notificationsEnabled
            existingSubscription.isActive = isActive
            existingSubscription.notes = notes
            
            Task {
                await notificationManager.scheduleNotification(for: existingSubscription)
            }
        } else {
            // Create new
            let newSubscription = Subscription(
                name: name,
                price: price,
                currency: currency,
                billingCycle: billingCycle,
                nextPaymentDate: nextPaymentDate,
                category: category,
                icon: icon,
                notificationDaysBefore: notificationDaysBefore,
                notificationsEnabled: notificationsEnabled,
                isActive: isActive,
                notes: notes
            )
            
            modelContext.insert(newSubscription)
            
            Task {
                await notificationManager.scheduleNotification(for: newSubscription)
            }
        }
        
        dismiss()
    }
}

struct TemplateButton: View {
    let name: String
    let icon: String
    let category: SubscriptionCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                TemplateIconView(name: name, sfSymbol: icon, category: category, size: 60)

                Text(name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
            }
        }
        .buttonStyle(.plain)
    }
}


private struct NotificationReminderRow: View {
    let days: Int
    let label: String
    @Binding var selection: [Int]

    var body: some View {
        let selected = selection.contains(days)
        Button(action: {
            if selected {
                selection.removeAll { $0 == days }
            } else {
                selection.append(days)
            }
        }) {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddEditSubscriptionView()
            .modelContainer(for: Subscription.self, inMemory: true)
    }
}
