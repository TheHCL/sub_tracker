//
//  ContentView.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SubscriptionListView()
            }
            .tabItem {
                Label("Subscriptions", systemImage: "list.bullet.rectangle")
            }
            
            NavigationStack {
                StatisticsView()
            }
            .tabItem {
                Label("Statistics", systemImage: "chart.pie")
            }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
