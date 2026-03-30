//
//  SettingsView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData
import Combine
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject private var lm: LanguageManager
    @AppStorage("displayCurrency") private var displayCurrency = "USD"
    @AppStorage("notificationTimeInterval") private var notificationTimeInterval: Double = 9 * 3600

    private var notificationTime: Binding<Date> {
        Binding(
            get: {
                let comps = DateComponents(hour: Int(notificationTimeInterval / 3600),
                                          minute: Int((Int(notificationTimeInterval) % 3600) / 60))
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { date in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                notificationTimeInterval = Double((comps.hour ?? 9) * 3600 + (comps.minute ?? 0) * 60)
            }
        )
    }

    @State private var showingDeleteConfirmation = false
    @State private var testNotificationState: TestNotificationState = .idle

    // Backup / Restore
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportDocument: SubscriptionBackupDocument?
    @State private var showImportConfirm = false
    @State private var pendingImportData: Data?
    @State private var backupMessage: String?

    enum TestNotificationState: Equatable {
        case idle
        case sent(count: Int)
        case noneFound
    }

    var body: some View {
        List {
            // Language
            Section {
                Picker(lm.s("Language", "語言"), selection: $lm.language) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
            } header: {
                Text(lm.s("Language", "語言"))
            }

            // Display Currency
            Section {
                Picker(lm.s("Display Currency", "顯示貨幣"), selection: $displayCurrency) {
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
                    Text(lm.s("Rates are approximate", "匯率為參考值"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(lm.s("Static reference rates", "靜態參考匯率"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } header: {
                Text(lm.s("Display Currency", "顯示貨幣"))
            } footer: {
                Text(lm.s(
                    "All prices are shown converted to \(displayCurrency) (\(CurrencyConverter.symbol(for: displayCurrency))). Subscriptions are stored in their original currency.",
                    "所有價格均換算為 \(displayCurrency) (\(CurrencyConverter.symbol(for: displayCurrency))) 顯示，訂閱以原始貨幣儲存。"
                ))
            }

            // Notifications Section
            Section {
                HStack {
                    Label(lm.s("Notifications", "通知"), systemImage: "bell.badge.fill")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button(lm.s("Enable", "開啟")) {
                            Task { await notificationManager.requestAuthorization() }
                        }
                    }
                }

                if notificationManager.isAuthorized {
                    DatePicker(lm.s("Notification Time", "通知時間"), selection: notificationTime, displayedComponents: .hourAndMinute)

                    Button {
                        Task { await notificationManager.rescheduleAllNotifications(subscriptions: subscriptions) }
                    } label: {
                        Label(lm.s("Reschedule All Notifications", "重新排程所有通知"), systemImage: "arrow.clockwise")
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
                            Label(lm.s("Test Upcoming Notifications", "測試即將到期通知"), systemImage: "bell.and.waves.left.and.right")
                            Spacer()
                            switch testNotificationState {
                            case .idle:
                                EmptyView()
                            case .sent(let count):
                                Text(lm.s("\(count) sent", "已送出 \(count) 則"))
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            case .noneFound:
                                Text(lm.s("No upcoming", "無符合條件"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(testNotificationState != .idle)
                }
            } header: {
                Text(lm.s("Notifications", "通知"))
            } footer: {
                if !notificationManager.isAuthorized {
                    Text(lm.s("Enable notifications to receive reminders before payment dates", "開啟通知以在付款日前收到提醒"))
                } else {
                    switch testNotificationState {
                    case .idle:
                        EmptyView()
                    case .sent(let count):
                        Text(lm.s(
                            "Found \(count) upcoming subscription(s). Notifications will fire in 5 seconds. Please background the app first.",
                            "找到 \(count) 個即將到期的訂閱，通知將在 5 秒後送出。請先將 App 切到背景。"
                        ))
                    case .noneFound:
                        Text(lm.s(
                            "No subscriptions match the notification conditions (payment date not within the configured reminder days).",
                            "目前沒有符合通知條件的訂閱（付款日未在各訂閱設定的提前天數內）。"
                        ))
                    }
                }
            }

            // Backup & Restore
            Section {
                Button {
                    prepareExport()
                } label: {
                    Label(lm.s("Export Backup", "匯出備份"), systemImage: "arrow.up.doc.fill")
                }

                Button {
                    isImporting = true
                } label: {
                    Label(lm.s("Restore from Backup", "從備份還原"), systemImage: "arrow.down.doc.fill")
                }

                if let msg = backupMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(lm.s("Backup & Restore", "備份與還原"))
            } footer: {
                Text(lm.s(
                    "The exported JSON file can be saved to Google Drive or iCloud Drive. To restore, select the file from the Files app.",
                    "匯出的 JSON 檔案可儲存到 Google Drive 或 iCloud Drive，還原時從 Files App 選取該檔案即可。"
                ))
            }

            // Data Management
            Section(lm.s("Data Management", "資料管理")) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label(lm.s("Delete All Subscriptions", "刪除所有訂閱"), systemImage: "trash.fill")
                }
            }

            // About
            Section(lm.s("About", "關於")) {
                HStack {
                    Text(lm.s("Version", "版本"))
                    Spacer()
                    Text("1.0.0").foregroundStyle(.secondary)
                }

                HStack {
                    Text(lm.s("Total Subscriptions", "訂閱總數"))
                    Spacer()
                    Text("\(subscriptions.count)").foregroundStyle(.secondary)
                }

                HStack {
                    Text(lm.s("Active Subscriptions", "啟用中的訂閱"))
                    Spacer()
                    Text("\(subscriptions.filter { $0.isActive }.count)").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(lm.s("Settings", "設定"))
        .confirmationDialog(lm.s("Delete All Subscriptions?", "刪除所有訂閱？"), isPresented: $showingDeleteConfirmation) {
            Button(lm.s("Delete All", "全部刪除"), role: .destructive) {
                deleteAllSubscriptions()
            }
            Button(lm.s("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(lm.s(
                "This will permanently delete all \(subscriptions.count) subscriptions. This action cannot be undone.",
                "這將永久刪除所有 \(subscriptions.count) 筆訂閱，此操作無法復原。"
            ))
        }
        .task {
            await notificationManager.checkAuthorizationStatus()
        }
        .onChange(of: notificationTimeInterval) {
            Task { await notificationManager.rescheduleAllNotifications(subscriptions: subscriptions) }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "subscriptions_backup"
        ) { result in
            switch result {
            case .success:
                showBackupMessage(lm.s("Backup exported successfully", "備份已成功匯出"))
            case .failure(let error):
                showBackupMessage(lm.s("Export failed: \(error.localizedDescription)", "匯出失敗：\(error.localizedDescription)"))
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url) {
                    pendingImportData = data
                    showImportConfirm = true
                }
            case .failure(let error):
                showBackupMessage(lm.s("Read failed: \(error.localizedDescription)", "讀取失敗：\(error.localizedDescription)"))
            }
        }
        .confirmationDialog(lm.s("Restore Backup?", "還原備份？"), isPresented: $showImportConfirm) {
            Button(lm.s("Restore", "還原"), role: .destructive) {
                if let data = pendingImportData { restoreBackup(from: data) }
            }
            Button(lm.s("Cancel", "取消"), role: .cancel) {}
        } message: {
            Text(lm.s(
                "This will overwrite all current subscriptions. This action cannot be undone.",
                "這將會覆蓋目前所有訂閱資料，此操作無法復原。"
            ))
        }
    }

    private func prepareExport() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let exports = subscriptions.map { $0.toExport() }
        guard let data = try? encoder.encode(exports) else { return }
        exportDocument = SubscriptionBackupDocument(data: data)
        isExporting = true
    }

    private func restoreBackup(from data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let exports = try? decoder.decode([SubscriptionExport].self, from: data) else {
            showBackupMessage(lm.s("Restore failed: invalid file format", "還原失敗：檔案格式無效"))
            return
        }

        notificationManager.cancelAllNotifications()
        for sub in subscriptions { modelContext.delete(sub) }

        let restored = exports.map { Subscription.from(export: $0) }
        for sub in restored { modelContext.insert(sub) }

        Task { await notificationManager.rescheduleAllNotifications(subscriptions: restored) }
        showBackupMessage(lm.s("Restored \(restored.count) subscription(s)", "已成功還原 \(restored.count) 筆訂閱"))
    }

    private func showBackupMessage(_ message: String) {
        backupMessage = message
        Task {
            try? await Task.sleep(for: .seconds(5))
            backupMessage = nil
        }
    }

    private func deleteAllSubscriptions() {
        notificationManager.cancelAllNotifications()
        for subscription in Array(subscriptions) { modelContext.delete(subscription) }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
