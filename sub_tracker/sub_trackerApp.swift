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
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed (e.g. Int → [Int]): delete the old store and start fresh.
            let storeURL = modelConfiguration.url
            if storeURL.isFileURL {
                let fm = FileManager.default
                let shmURL = storeURL.appendingPathExtension("sqlite-shm")
                let walURL = storeURL.appendingPathExtension("sqlite-wal")
                for url in [storeURL, shmURL, walURL] {
                    try? fm.removeItem(at: url)
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
