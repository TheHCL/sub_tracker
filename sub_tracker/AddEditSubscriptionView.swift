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
    
    let subscription: Subscription?
    
    @State private var name: String = ""
    @State private var price: Double = 0.0
    @State private var currency: String = "USD"
    @State private var billingCycle: BillingCycle = .monthly
    @State private var nextPaymentDate: Date = Date()
    @State private var category: SubscriptionCategory = .other
    @State private var icon: String = "app.fill"
    @State private var notificationDaysBefore: Int = 7
    @State private var isActive: Bool = true
    @State private var notes: String = ""
    
    let currencies = allCurrencies
    let notificationOptions = [3, 5, 7, 14, 30]
    
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
                Section("Popular Subscriptions") {
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
            Section("Basic Information") {
                TextField("Name", text: $name)

                Picker("Category", selection: $category) {
                    ForEach(SubscriptionCategory.allCases, id: \.self) { cat in
                        Label(cat.rawValue, systemImage: cat.icon)
                            .tag(cat)
                    }
                }
            }
            
            // Pricing
            Section("Pricing") {
                HStack {
                    Picker("Currency", selection: $currency) {
                        ForEach(currencies, id: \.self) { curr in
                            Text(curr).tag(curr)
                        }
                    }
                    .frame(width: 100)
                    
                    TextField("Price", value: $price, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Billing Cycle", selection: $billingCycle) {
                    ForEach(BillingCycle.allCases, id: \.self) { cycle in
                        Label(cycle.rawValue, systemImage: cycle.icon)
                            .tag(cycle)
                    }
                }
                
                DatePicker("Next Payment", selection: $nextPaymentDate, displayedComponents: .date)
            }
            
            // Cost Summary
            Section {
                HStack {
                    Text("Monthly equivalent")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currency) \(monthlyEquivalent, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Yearly equivalent")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(currency) \(yearlyEquivalent, specifier: "%.2f")")
                        .fontWeight(.semibold)
                }
            }
            
            // Notifications
            Section("Reminders") {
                Picker("Notify me before", selection: $notificationDaysBefore) {
                    ForEach(notificationOptions, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
            }
            
            // Status
            Section {
                Toggle("Active Subscription", isOn: $isActive)
            }
            
            // Notes
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle(subscription == nil ? "Add Subscription" : "Edit Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
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
        notificationDaysBefore = subscription.notificationDaysBefore
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


#Preview {
    NavigationStack {
        AddEditSubscriptionView()
            .modelContainer(for: Subscription.self, inMemory: true)
    }
}
