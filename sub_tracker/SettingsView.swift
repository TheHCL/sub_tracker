//
//  SettingsView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData
import Combine

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @StateObject private var notificationManager = NotificationManager.shared
    @AppStorage("displayCurrency") private var displayCurrency = "USD"

    @State private var showingDeleteConfirmation = false
    @State private var testNotificationState: TestNotificationState = .idle

    enum TestNotificationState: Equatable {
        case idle
        case sent(count: Int)
        case noneFound
    }
    
    var body: some View {
        List {
            // Display Currency
            Section {
                Picker("Display Currency", selection: $displayCurrency) {
                    ForEach(allCurrencies, id: \.self) { currency in
                        HStack {
                            Text(currency)
                            Spacer()
                            Text(CurrencyConverter.symbol(for: currency))
                                .foregroundStyle(.secondary)
                        }
                        .tag(currency)
                    }
                }

                HStack {
                    Text("Rates are approximate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Static reference rates")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } header: {
                Text("Display Currency")
            } footer: {
                Text("All prices are shown converted to \(displayCurrency) (\(CurrencyConverter.symbol(for: displayCurrency))). Subscriptions are stored in their original currency.")
            }

            // Notifications Section
            Section {
                HStack {
                    Label("Notifications", systemImage: "bell.badge.fill")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Enable") {
                            Task {
                                await notificationManager.requestAuthorization()
                            }
                        }
                    }
                }
                
                if notificationManager.isAuthorized {
                    Button {
                        Task {
                            await notificationManager.rescheduleAllNotifications(subscriptions: subscriptions)
                        }
                    } label: {
                        Label("Reschedule All Notifications", systemImage: "arrow.clockwise")
                    }

                    Button {
                        Task {
                            let count = await notificationManager.sendTestNotifications(for: subscriptions)
                            testNotificationState = count > 0 ? .sent(count: count) : .noneFound
                            try? await Task.sleep(for: .seconds(8))
                            testNotificationState = .idle
                        }
                    } label: {
                        HStack {
                            Label("Test Upcoming Notifications", systemImage: "bell.and.waves.left.and.right")
                            Spacer()
                            switch testNotificationState {
                            case .idle:
                                EmptyView()
                            case .sent(let count):
                                Text("\(count) sent")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            case .noneFound:
                                Text("No upcoming")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(testNotificationState != .idle)
                }
            } header: {
                Text("Notifications")
            } footer: {
                if !notificationManager.isAuthorized {
                    Text("Enable notifications to receive reminders before payment dates")
                } else {
                    switch testNotificationState {
                    case .idle:
                        EmptyView()
                    case .sent(let count):
                        Text("找到 \(count) 個即將到期的訂閱，通知將在 5 秒後送出。請先將 App 切到背景。")
                    case .noneFound:
                        Text("目前沒有符合通知條件的訂閱（付款日未在各訂閱設定的提前天數內）。")
                    }
                }
            }
            
            // Data Management
            Section("Data Management") {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete All Subscriptions", systemImage: "trash.fill")
                }
            }
            
            // App Information
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Total Subscriptions")
                    Spacer()
                    Text("\(subscriptions.count)")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Active Subscriptions")
                    Spacer()
                    Text("\(subscriptions.filter { $0.isActive }.count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Delete All Subscriptions?", isPresented: $showingDeleteConfirmation) {
            Button("Delete All", role: .destructive) {
                deleteAllSubscriptions()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(subscriptions.count) subscriptions. This action cannot be undone.")
        }
        .task {
            await notificationManager.checkAuthorizationStatus()
        }
    }
    
    private func deleteAllSubscriptions() {
        notificationManager.cancelAllNotifications()

        let toDelete = Array(subscriptions)
        for subscription in toDelete {
            modelContext.delete(subscription)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
