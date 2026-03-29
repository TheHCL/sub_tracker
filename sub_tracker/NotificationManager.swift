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

    /// Attaches a visible icon image to the notification content.
    /// UIImage(named:"AppIcon") always returns nil for AppIcon asset sets,
    /// so we probe bundle-generated icon files first, then draw a fallback.
    private func applyIconAttachment(to content: UNMutableNotificationContent) {
        let image = loadBundleIcon() ?? drawFallbackIcon()
        guard let data = image.pngData() else { return }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("notif_icon_\(UUID().uuidString).png")

        do {
            try data.write(to: tempURL)
            content.attachments = [try UNNotificationAttachment(identifier: "icon", url: tempURL)]
        } catch {}
    }

    /// Tries several paths where Xcode places generated app icon PNGs in the bundle.
    private func loadBundleIcon() -> UIImage? {
        // Xcode generates loose PNG files alongside Assets.car using these names
        let candidates = [
            "AppIcon60x60@3x", "AppIcon60x60@2x",
            "AppIcon40x40@3x", "AppIcon40x40@2x",
            "AppIcon20x20@3x", "AppIcon20x20@2x",
        ]
        for name in candidates {
            // Try asset catalog lookup (works on some Xcode configs)
            if let img = UIImage(named: name) { return img }
            // Try loose file in bundle root
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let img = UIImage(contentsOfFile: url.path) { return img }
        }
        return nil
    }

    /// Draws a branded fallback icon so the notification always shows something.
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

