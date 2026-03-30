//
//  NotificationManager.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import Foundation
import SwiftUI
import Combine
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    func scheduleNotification(for subscription: Subscription) async {
        // Request auth first if not yet authorized; then re-check
        if !isAuthorized {
            await requestAuthorization()
        }
        guard isAuthorized else { return }

        // Remove existing notification for this subscription
        await cancelNotification(for: subscription)

        // Calculate notification date (N days before payment)
        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -subscription.notificationDaysBefore,
            to: subscription.nextPaymentDate
        ) ?? subscription.nextPaymentDate

        // Only schedule if the notification date is in the future
        guard notificationDate > Date() else { return }

        let dueDateStr = subscription.nextPaymentDate.formatted(date: .abbreviated, time: .omitted)
        let content = UNMutableNotificationContent()
        content.title = "Subscription Payment Due"
        content.body = "\(subscription.name) — \(subscription.currency) \(String(format: "%.2f", subscription.price)) due on \(dueDateStr) (in \(subscription.notificationDaysBefore) day\(subscription.notificationDaysBefore == 1 ? "" : "s"))"
        content.sound = .default
        content.categoryIdentifier = "SUBSCRIPTION_REMINDER"
        applyIconAttachment(to: content)

        // Fire at 9:00 AM on the notification day (avoids random times)
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: notificationDate)
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: subscription.id.uuidString,
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    /// Finds active subscriptions that are within their notification window and
    /// fires their real notification content immediately (5 s delay so you can
    /// background the app first).  Returns the number of notifications sent.
    @discardableResult
    func sendTestNotifications(for subscriptions: [Subscription]) async -> Int {
        guard isAuthorized else { return 0 }

        let calendar = Calendar.current
        let now = Date()

        let upcoming = subscriptions.filter { sub in
            guard sub.isActive else { return false }
            let days = calendar.dateComponents([.day], from: now, to: sub.nextPaymentDate).day ?? Int.max
            return days >= 0 && days <= sub.notificationDaysBefore
        }

        for (index, sub) in upcoming.enumerated() {
            let days = calendar.dateComponents([.day], from: now, to: sub.nextPaymentDate).day ?? 0

            let dueDateStr = sub.nextPaymentDate.formatted(date: .abbreviated, time: .omitted)
            let content = UNMutableNotificationContent()
            content.title = "Subscription Payment Due"
            content.body = "\(sub.name) — \(sub.currency) \(String(format: "%.2f", sub.price)) due on \(dueDateStr) (in \(days) day\(days == 1 ? "" : "s"))"
            content.sound = .default
            content.categoryIdentifier = "SUBSCRIPTION_REMINDER"
            applyIconAttachment(to: content)

            // Stagger by 1 s so multiple notifications don't collapse
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: Double(5 + index),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "test-\(sub.id.uuidString)",
                content: content,
                trigger: trigger
            )

            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed to send test notification for \(sub.name): \(error)")
            }
        }

        return upcoming.count
    }
    
    // MARK: - Icon attachment

    /// Attaches the app icon to the notification content so the banner shows
    /// the correct icon on both Simulator and real devices.
    private func applyIconAttachment(to content: UNMutableNotificationContent) {
        let image = loadAppIcon() ?? drawFallbackIcon()
        guard let data = image.pngData() else { return }

        // Use Caches directory — more stable than tmp on real devices.
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let iconURL = cacheDir.appendingPathComponent("notif_icon.png")

        do {
            try data.write(to: iconURL)
            let options: [AnyHashable: Any] = [
                UNNotificationAttachmentOptionsTypeHintKey: "public.png"
            ]
            content.attachments = [
                try UNNotificationAttachment(identifier: "app_icon", url: iconURL, options: options)
            ]
        } catch {
            print("Notification attachment error: \(error)")
        }
    }

    /// Loads the app icon on both Simulator and real devices.
    /// On Simulator, Xcode places loose PNGs alongside Assets.car;
    /// on real devices we read from CFBundleIcons in the Info.plist.
    private func loadAppIcon() -> UIImage? {
        // Method 1: CFBundleIconName (modern Xcode with GENERATE_INFOPLIST_FILE, works on real devices)
        if let iconName = Bundle.main.infoDictionary?["CFBundleIconName"] as? String,
           let img = UIImage(named: iconName) { return img }

        // Method 2: Direct asset catalog name
        if let img = UIImage(named: "AppIcon") { return img }

        // Method 3: CFBundleIcons / CFBundleIconFiles (older projects)
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] {
            for name in files.reversed() {
                if let img = UIImage(named: name) { return img }
                if let url = Bundle.main.url(forResource: name, withExtension: "png"),
                   let img = UIImage(contentsOfFile: url.path) { return img }
            }
        }

        // Method 4: Xcode-generated loose PNG names (Simulator builds)
        let candidates = [
            "AppIcon60x60@3x", "AppIcon60x60@2x",
            "AppIcon40x40@3x", "AppIcon40x40@2x",
        ]
        for name in candidates {
            if let img = UIImage(named: name) { return img }
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let img = UIImage(contentsOfFile: url.path) { return img }
        }

        return nil
    }

    /// Draws a branded fallback icon in case the bundle icon cannot be loaded.
    private func drawFallbackIcon() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.systemBlue.setFill()
            UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: size),
                cornerRadius: 44
            ).fill()

            let config = UIImage.SymbolConfiguration(pointSize: 90, weight: .semibold)
            if let symbol = UIImage(systemName: "creditcard.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(
                    x: (size.width  - symbol.size.width)  / 2,
                    y: (size.height - symbol.size.height) / 2
                )
                symbol.draw(at: origin)
            }
        }
    }

    func cancelNotification(for subscription: Subscription) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [subscription.id.uuidString]
        )
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func rescheduleAllNotifications(subscriptions: [Subscription]) async {
        cancelAllNotifications()

        for subscription in subscriptions where subscription.isActive {
            await scheduleNotification(for: subscription)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show banner + play sound even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

