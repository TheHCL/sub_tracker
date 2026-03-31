//
//  WidgetDataWriter.swift
//  sub_tracker
//

import Foundation
import WidgetKit

enum WidgetDataWriter {
    static let appGroupID = "group.com.thehcl.sub-tracker"
    static let fileName = "widget_subscriptions.json"

    static func write(_ subscriptions: [Subscription]) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return }

        let exports = subscriptions
            .filter(\.isActive)
            .sorted { $0.nextPaymentDate < $1.nextPaymentDate }
            .map { $0.toExport() }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(exports) else { return }
        try? data.write(to: containerURL.appendingPathComponent(fileName))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
