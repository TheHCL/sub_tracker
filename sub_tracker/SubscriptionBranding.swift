//
//  SubscriptionBranding.swift
//  sub_tracker
//
//  Created by TheHCL on 2026/3/29.
//

import SwiftUI

struct ServiceBrand {
    let primaryColor: Color
    let backgroundColor: Color
    let displayText: String      // Short label shown in icon (e.g. "N", "YT")
    let sfSymbol: String         // Fallback SF symbol
}

// Maps lowercase service name keywords → brand identity
let knownServiceBrands: [String: ServiceBrand] = [
    "netflix":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#E50914"), displayText: "N",   sfSymbol: "tv.fill"),
    "spotify":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#1DB954"), displayText: "S",   sfSymbol: "music.quarternote.3"),
    "apple music":      ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FC3C44"), displayText: "♪",   sfSymbol: "music.note"),
    "youtube premium":  ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF0000"), displayText: "YT",  sfSymbol: "play.rectangle.fill"),
    "youtube":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF0000"), displayText: "YT",  sfSymbol: "play.rectangle.fill"),
    "disney+":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#0063E5"), displayText: "D+",  sfSymbol: "play.tv.fill"),
    "disney plus":      ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#0063E5"), displayText: "D+",  sfSymbol: "play.tv.fill"),
    "amazon prime":     ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#00A8E8"), displayText: "a",   sfSymbol: "shippingbox.fill"),
    "prime video":      ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#00A8E8"), displayText: "a",   sfSymbol: "play.rectangle.fill"),
    "icloud":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#0078FF"), displayText: "☁",   sfSymbol: "cloud.fill"),
    "icloud+":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#0078FF"), displayText: "☁",   sfSymbol: "cloud.fill"),
    "dropbox":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#0061FF"), displayText: "✦",   sfSymbol: "folder.fill"),
    "google one":       ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#4285F4"), displayText: "G",   sfSymbol: "internaldrive.fill"),
    "adobe":            ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF0000"), displayText: "Ai",  sfSymbol: "paintbrush.fill"),
    "creative cloud":   ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF0000"), displayText: "Cc",  sfSymbol: "paintbrush.fill"),
    "microsoft 365":    ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#D83B01"), displayText: "M",   sfSymbol: "doc.text.fill"),
    "microsoft":        ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#00A4EF"), displayText: "M",   sfSymbol: "doc.text.fill"),
    "github":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#24292F"), displayText: "GH",  sfSymbol: "chevron.left.forwardslash.chevron.right"),
    "claude":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#D97757"), displayText: "C",   sfSymbol: "brain.head.profile"),
    "chatgpt":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#10A37F"), displayText: "G",   sfSymbol: "bubble.left.and.bubble.right.fill"),
    "openai":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#10A37F"), displayText: "G",   sfSymbol: "bubble.left.and.bubble.right.fill"),
    "hulu":             ServiceBrand(primaryColor: .black,        backgroundColor: Color(hex: "#1CE783"), displayText: "H",   sfSymbol: "tv.fill"),
    "notion":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#000000"), displayText: "N",   sfSymbol: "doc.text.fill"),
    "figma":            ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#F24E1E"), displayText: "F",   sfSymbol: "pencil.and.ruler.fill"),
    "slack":            ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#4A154B"), displayText: "#",   sfSymbol: "bubble.left.and.bubble.right.fill"),
    "zoom":             ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#2D8CFF"), displayText: "Z",   sfSymbol: "video.fill"),
    "1password":        ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#1A8BF1"), displayText: "1P",  sfSymbol: "lock.fill"),
    "lastpass":         ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#D32D27"), displayText: "LP",  sfSymbol: "lock.fill"),
    "nordvpn":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#4687FF"), displayText: "N",   sfSymbol: "network"),
    "expressvpn":       ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#DA3940"), displayText: "E",   sfSymbol: "network"),
    "duolingo":         ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#58CC02"), displayText: "D",   sfSymbol: "textformat.abc"),
    "headspace":        ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF8000"), displayText: "H",   sfSymbol: "brain.head.profile"),
    "calm":             ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#02C6C6"), displayText: "C",   sfSymbol: "brain.head.profile"),
    "tidal":            ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#000000"), displayText: "T",   sfSymbol: "music.note"),
    "deezer":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#A238FF"), displayText: "D",   sfSymbol: "music.note"),
    "apple tv":         ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#1C1C1E"), displayText: "TV",  sfSymbol: "appletv.fill"),
    "apple arcade":     ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#1C1C1E"), displayText: "A",   sfSymbol: "gamecontroller.fill"),
    "xbox":             ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#107C10"), displayText: "X",   sfSymbol: "gamecontroller.fill"),
    "playstation":      ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#003087"), displayText: "PS",  sfSymbol: "gamecontroller.fill"),
    "nintendo":         ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#E60012"), displayText: "NS",  sfSymbol: "gamecontroller.fill"),
    "nytimes":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#000000"), displayText: "NY",  sfSymbol: "newspaper.fill"),
    "new york times":   ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#000000"), displayText: "NY",  sfSymbol: "newspaper.fill"),
    "medium":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#000000"), displayText: "M",   sfSymbol: "book.fill"),
    "substack":         ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FF6719"), displayText: "S",   sfSymbol: "envelope.fill"),
    "strava":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#FC4C02"), displayText: "S",   sfSymbol: "figure.run"),
    "peloton":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#E5022D"), displayText: "P",   sfSymbol: "figure.indoor.cycle"),
    "grammarly":        ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#15C39A"), displayText: "G",   sfSymbol: "textformat.abc"),
    "linear":           ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#5E6AD2"), displayText: "L",   sfSymbol: "checklist"),
    "todoist":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#DB4035"), displayText: "T",   sfSymbol: "checkmark.circle.fill"),
    "minimax":          ServiceBrand(primaryColor: .white,        backgroundColor: Color(hex: "#4F46E5"), displayText: "M",   sfSymbol: "brain.head.profile"),
]

extension Subscription {
    /// Returns the matching ServiceBrand for well-known services, nil otherwise.
    var serviceBrand: ServiceBrand? {
        let lowercased = name.lowercased()
        // Exact match first
        if let brand = knownServiceBrands[lowercased] { return brand }
        // Partial match (e.g. "Netflix Basic" → "netflix")
        for (key, brand) in knownServiceBrands {
            if lowercased.contains(key) { return brand }
        }
        return nil
    }
}

// MARK: - Icon Views

/// A single unified icon view that renders brand icons for known services
/// and SF Symbols for custom ones.
struct SubscriptionIconView: View {
    let subscription: Subscription
    var size: CGFloat = 50

    var body: some View {
        if let brand = subscription.serviceBrand {
            BrandIconView(brand: brand, size: size)
        } else {
            SFSymbolIconView(
                symbol: subscription.icon,
                color: subscription.category.swiftUIColor,
                size: size
            )
        }
    }
}

struct BrandIconView: View {
    let brand: ServiceBrand
    var size: CGFloat = 50

    private var fontSize: CGFloat { size * 0.38 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(brand.backgroundColor)
                .frame(width: size, height: size)

            Text(brand.displayText)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(brand.primaryColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
    }
}

struct SFSymbolIconView: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 50

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: size, height: size)

            Image(systemName: symbol)
                .font(.system(size: size * 0.38))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Template icon (for Add/Edit picker)

struct TemplateIconView: View {
    let name: String
    let sfSymbol: String
    let category: SubscriptionCategory
    var size: CGFloat = 60

    private var brand: ServiceBrand? {
        let lowercased = name.lowercased()
        if let b = knownServiceBrands[lowercased] { return b }
        for (key, b) in knownServiceBrands {
            if lowercased.contains(key) { return b }
        }
        return nil
    }

    var body: some View {
        if let brand = brand {
            BrandIconView(brand: brand, size: size)
        } else {
            SFSymbolIconView(symbol: sfSymbol, color: category.swiftUIColor, size: size)
        }
    }
}

// MARK: - Category → real SwiftUI Color

extension SubscriptionCategory {
    /// Returns an actual SwiftUI Color (not an asset-catalog lookup).
    var swiftUIColor: Color {
        switch self {
        case .streaming:    return .red
        case .music:        return .pink
        case .ai:           return .purple
        case .productivity: return .blue
        case .cloud:        return .cyan
        case .gaming:       return .green
        case .news:         return .orange
        case .fitness:      return .mint
        case .other:        return .gray
        }
    }
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
