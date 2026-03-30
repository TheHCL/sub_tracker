//
//  ContentView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        TabView {
            NavigationStack {
                SubscriptionListView()
            }
            .tabItem {
                Label(lm.s("Subscriptions", "訂閱"), systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label(lm.s("Statistics", "統計"), systemImage: "chart.pie")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label(lm.s("Settings", "設定"), systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
