//
//  sub_trackerApp.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData

@main
struct sub_trackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Subscription.self])

        // Use App Group container so the widget extension can read the same store.
        let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetDataWriter.appGroupID
        )
        let storeURL = groupURL?.appendingPathComponent("sub_tracker.sqlite")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("sub_tracker.sqlite"),
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed: delete the old store and start fresh.
            let url = modelConfiguration.url
            if url.isFileURL {
                let fm = FileManager.default
                for ext in ["", ".sqlite-shm", ".sqlite-wal"] {
                    try? fm.removeItem(at: url.appendingPathExtension(ext))
                }
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
