//
//  LanguageManager.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case chineseTraditional = "zh-Hant"

    var displayName: String {
        switch self {
        case .english:           return "English"
        case .chineseTraditional: return "繁體中文"
        }
    }
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    private init() {
        let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? ""
        language = AppLanguage(rawValue: stored) ?? .english
    }

    /// Returns the English or Traditional Chinese string based on current language.
    func s(_ en: String, _ zh: String) -> String {
        language == .chineseTraditional ? zh : en
    }
}

/// Convenience: read language without an ObservableObject (e.g. in NotificationManager).
func appLocalizedString(_ en: String, _ zh: String) -> String {
    let stored = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    return stored == "zh-Hant" ? zh : en
}
