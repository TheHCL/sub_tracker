//
//  SubTrackerWidget.swift
//  sub_tracker_widget
//

import WidgetKit
import SwiftUI

// MARK: - Shared data types (mirrors SubscriptionExport from main app)

struct WidgetSubscription: Codable, Identifiable {
    let id: UUID
    let name: String
    let price: Double
    let currency: String
    let billingCycle: String
    let nextPaymentDate: Date
    let category: String
    let icon: String
    let isActive: Bool

    var daysUntilPayment: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: nextPaymentDate)
        return cal.dateComponents([.day], from: today, to: target).day ?? 0
    }

    var isUrgent: Bool { daysUntilPayment <= 3 }

    var formattedPrice: String { WidgetCurrency.format(price, currency: currency) }
}

// MARK: - Currency formatter (duplicated for widget target)

private enum WidgetCurrency {
    static func symbol(for currency: String) -> String {
        switch currency {
        case "USD": return "US$"
        case "EUR": return "€"
        case "GBP": return "£"
        case "JPY": return "¥"
        case "CNY": return "CN¥"
        case "CAD": return "CA$"
        case "AUD": return "A$"
        case "TWD": return "NT$"
        default:    return currency
        }
    }

    static func format(_ amount: Double, currency: String) -> String {
        let sym = symbol(for: currency)
        if currency == "JPY" { return "\(sym)\(Int(amount.rounded()))" }
        return String(format: "\(sym)%.2f", amount)
    }
}

// MARK: - Category color

private func categoryColor(_ category: String) -> Color {
    switch category {
    case "Streaming":    return .red
    case "Music":        return .pink
    case "AI & Tools":   return .purple
    case "Productivity": return .blue
    case "Cloud Storage": return .cyan
    case "Gaming":       return .green
    case "News & Media": return .orange
    case "Fitness":      return .mint
    default:             return .gray
    }
}

// MARK: - Known brand colors (subset for widget icons)

private struct BrandStyle {
    let background: Color
    let text: Color
    let label: String
}

private let knownBrands: [String: BrandStyle] = [
    "netflix":         BrandStyle(background: Color(red: 0.898, green: 0.035, blue: 0.078), text: .white, label: "N"),
    "spotify":         BrandStyle(background: Color(red: 0.114, green: 0.725, blue: 0.329), text: .white, label: "S"),
    "apple music":     BrandStyle(background: Color(red: 0.988, green: 0.235, blue: 0.267), text: .white, label: "♪"),
    "youtube":         BrandStyle(background: .red, text: .white, label: "YT"),
    "disney+":         BrandStyle(background: Color(red: 0, green: 0.388, blue: 0.898), text: .white, label: "D+"),
    "amazon prime":    BrandStyle(background: Color(red: 0, green: 0.659, blue: 0.910), text: .white, label: "a"),
    "prime video":     BrandStyle(background: Color(red: 0, green: 0.659, blue: 0.910), text: .white, label: "a"),
    "icloud":          BrandStyle(background: Color(red: 0, green: 0.471, blue: 1.0), text: .white, label: "☁"),
    "dropbox":         BrandStyle(background: Color(red: 0, green: 0.380, blue: 1.0), text: .white, label: "✦"),
    "google one":      BrandStyle(background: Color(red: 0.259, green: 0.522, blue: 0.957), text: .white, label: "G"),
    "microsoft 365":   BrandStyle(background: Color(red: 0.847, green: 0.231, blue: 0.004), text: .white, label: "M"),
    "github":          BrandStyle(background: Color(red: 0.141, green: 0.161, blue: 0.184), text: .white, label: "GH"),
    "claude":          BrandStyle(background: Color(red: 0.851, green: 0.467, blue: 0.341), text: .white, label: "C"),
    "chatgpt":         BrandStyle(background: Color(red: 0.063, green: 0.639, blue: 0.498), text: .white, label: "G"),
    "openai":          BrandStyle(background: Color(red: 0.063, green: 0.639, blue: 0.498), text: .white, label: "G"),
    "notion":          BrandStyle(background: .black, text: .white, label: "N"),
    "slack":           BrandStyle(background: Color(red: 0.290, green: 0.082, blue: 0.294), text: .white, label: "#"),
    "zoom":            BrandStyle(background: Color(red: 0.176, green: 0.549, blue: 1.0), text: .white, label: "Z"),
    "apple tv":        BrandStyle(background: Color(red: 0.110, green: 0.110, blue: 0.118), text: .white, label: "TV"),
    "apple arcade":    BrandStyle(background: Color(red: 0.110, green: 0.110, blue: 0.118), text: .white, label: "A"),
    "xbox":            BrandStyle(background: Color(red: 0.063, green: 0.486, blue: 0.063), text: .white, label: "X"),
    "playstation":     BrandStyle(background: Color(red: 0, green: 0.188, blue: 0.529), text: .white, label: "PS"),
    "nintendo":        BrandStyle(background: Color(red: 0.902, green: 0, blue: 0.071), text: .white, label: "NS"),
    "1password":       BrandStyle(background: Color(red: 0.102, green: 0.545, blue: 0.945), text: .white, label: "1P"),
    "nordvpn":         BrandStyle(background: Color(red: 0.275, green: 0.529, blue: 1.0), text: .white, label: "N"),
    "duolingo":        BrandStyle(background: Color(red: 0.345, green: 0.800, blue: 0.008), text: .white, label: "D"),
    "hulu":            BrandStyle(background: Color(red: 0.110, green: 0.906, blue: 0.514), text: .black, label: "H"),
    "figma":           BrandStyle(background: Color(red: 0.949, green: 0.306, blue: 0.118), text: .white, label: "F"),
    "tidal":           BrandStyle(background: .black, text: .white, label: "T"),
    "grammarly":       BrandStyle(background: Color(red: 0.082, green: 0.765, blue: 0.604), text: .white, label: "G"),
    "linear":          BrandStyle(background: Color(red: 0.369, green: 0.416, blue: 0.824), text: .white, label: "L"),
    "todoist":         BrandStyle(background: Color(red: 0.859, green: 0.251, blue: 0.208), text: .white, label: "T"),
    "minimax":         BrandStyle(background: Color(red: 0.310, green: 0.275, blue: 0.898), text: .white, label: "M"),
    "strava":          BrandStyle(background: Color(red: 0.988, green: 0.298, blue: 0.008), text: .white, label: "S"),
    "peloton":         BrandStyle(background: Color(red: 0.898, green: 0.008, blue: 0.176), text: .white, label: "P"),
]

private func brandStyle(for name: String) -> BrandStyle? {
    let lower = name.lowercased()
    if let b = knownBrands[lower] { return b }
    for (key, b) in knownBrands where lower.contains(key) { return b }
    return nil
}

// MARK: - Widget icon view

private struct WidgetIconView: View {
    let subscription: WidgetSubscription
    let size: CGFloat

    private var initials: String {
        subscription.name
            .split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    var body: some View {
        if let brand = brandStyle(for: subscription.name) {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(brand.background)
                    .frame(width: size, height: size)
                Text(brand.label)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(brand.text)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.22)
                    .fill(categoryColor(subscription.category).opacity(0.2))
                    .frame(width: size, height: size)
                Text(initials.isEmpty ? "?" : initials)
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .foregroundStyle(categoryColor(subscription.category))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Data loading

private let widgetAppGroupID = "group.com.thehcl.sub-tracker"
private let widgetDataFileName = "widget_subscriptions.json"

private func loadSubscriptions() -> [WidgetSubscription] {
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: widgetAppGroupID
    ) else { return [] }
    let fileURL = containerURL.appendingPathComponent(widgetDataFileName)
    guard let data = try? Data(contentsOf: fileURL) else { return [] }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let exports = (try? decoder.decode([SubscriptionExportBridge].self, from: data)) ?? []
    return exports.compactMap {
        guard $0.isActive else { return nil }
        return WidgetSubscription(
            id: $0.id,
            name: $0.name,
            price: $0.price,
            currency: $0.currency,
            billingCycle: $0.billingCycle,
            nextPaymentDate: $0.nextPaymentDate,
            category: $0.category,
            icon: $0.icon,
            isActive: $0.isActive
        )
    }.sorted { $0.nextPaymentDate < $1.nextPaymentDate }
}

// Mirrors SubscriptionExport from main app
private struct SubscriptionExportBridge: Codable {
    let id: UUID
    let name: String
    let price: Double
    let currency: String
    let billingCycle: String
    let nextPaymentDate: Date
    let category: String
    let icon: String
    let notificationDaysBefore: [Int]
    let notificationsEnabled: Bool?
    let isActive: Bool
    let notes: String
}

// MARK: - Timeline Entry

struct SubTrackerEntry: TimelineEntry {
    let date: Date
    let subscriptions: [WidgetSubscription]
}

// MARK: - Timeline Provider

struct SubTrackerProvider: TimelineProvider {
    func placeholder(in context: Context) -> SubTrackerEntry {
        SubTrackerEntry(date: Date(), subscriptions: placeholderData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SubTrackerEntry) -> Void) {
        completion(SubTrackerEntry(date: Date(), subscriptions: loadSubscriptions()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SubTrackerEntry>) -> Void) {
        let subs = loadSubscriptions()
        let entry = SubTrackerEntry(date: Date(), subscriptions: subs)

        // Refresh at midnight so day-countdown updates
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        completion(Timeline(entries: [entry], policy: .after(midnight)))
    }

    private func placeholderData() -> [WidgetSubscription] {
        [
            WidgetSubscription(id: UUID(), name: "Netflix", price: 15.99, currency: "USD",
                               billingCycle: "Monthly", nextPaymentDate: Date().addingTimeInterval(86400 * 2),
                               category: "Streaming", icon: "tv.fill", isActive: true),
            WidgetSubscription(id: UUID(), name: "Spotify", price: 9.99, currency: "USD",
                               billingCycle: "Monthly", nextPaymentDate: Date().addingTimeInterval(86400 * 8),
                               category: "Music", icon: "music.note", isActive: true),
            WidgetSubscription(id: UUID(), name: "iCloud+", price: 2.99, currency: "USD",
                               billingCycle: "Monthly", nextPaymentDate: Date().addingTimeInterval(86400 * 15),
                               category: "Cloud Storage", icon: "cloud.fill", isActive: true),
        ]
    }
}

// MARK: - Accent color for urgency

private func paymentColor(for sub: WidgetSubscription) -> Color {
    sub.isUrgent ? Color.orange : Color.accentColor
}

// MARK: - Small Widget View

private struct SmallWidgetView: View {
    let entry: SubTrackerEntry

    var nextSub: WidgetSubscription? { entry.subscriptions.first }

    var body: some View {
        if let sub = nextSub {
            VStack(alignment: .leading, spacing: 6) {
                WidgetIconView(subscription: sub, size: 36)

                Spacer(minLength: 0)

                Text(sub.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(sub.daysUntilPayment)")
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(paymentColor(for: sub))
                    Text("d")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(sub.formattedPrice)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(.fill, for: .widget)
        } else {
            emptyView
        }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No subscriptions")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill, for: .widget)
    }
}

// MARK: - Medium Widget View

private struct MediumWidgetView: View {
    let entry: SubTrackerEntry

    var upcoming: [WidgetSubscription] { Array(entry.subscriptions.prefix(3)) }

    var body: some View {
        HStack(spacing: 12) {
            // Left: label
            VStack(alignment: .leading, spacing: 2) {
                Text("Next")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Payment")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
                if let first = upcoming.first {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(first.daysUntilPayment)")
                            .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundStyle(paymentColor(for: first))
                        Text("d")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Right: upcoming list
            VStack(alignment: .leading, spacing: 8) {
                if upcoming.isEmpty {
                    Text("No subscriptions")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(upcoming) { sub in
                        MediumRowView(sub: sub)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .containerBackground(.fill, for: .widget)
    }
}

private struct MediumRowView: View {
    let sub: WidgetSubscription

    var body: some View {
        HStack(spacing: 8) {
            WidgetIconView(subscription: sub, size: 24)

            VStack(alignment: .leading, spacing: 0) {
                Text(sub.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(sub.formattedPrice)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("\(sub.daysUntilPayment)d")
                .font(.caption2.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(paymentColor(for: sub))
        }
    }
}

// MARK: - Large Widget View

private struct LargeWidgetView: View {
    let entry: SubTrackerEntry

    // Show up to 8 upcoming within 30 days, else just the first 8
    var items: [WidgetSubscription] {
        let cutoff = Date().addingTimeInterval(86400 * 30)
        let within30 = entry.subscriptions.filter { $0.nextPaymentDate <= cutoff }
        return Array((within30.isEmpty ? entry.subscriptions : within30).prefix(8))
    }

    var totalMonthly: Double {
        entry.subscriptions.reduce(0.0) { acc, sub in
            let factor: Double
            switch sub.billingCycle {
            case "Monthly":     factor = 1
            case "Quarterly":   factor = 1.0 / 3
            case "Half-Yearly": factor = 1.0 / 6
            case "Yearly":      factor = 1.0 / 12
            default:            factor = 1
            }
            return acc + sub.price * factor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Upcoming")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("~\(WidgetCurrency.format(totalMonthly, currency: "USD"))/mo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 10)

            Divider()
                .padding(.bottom, 8)

            if items.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No upcoming payments")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(items) { sub in
                    LargeRowView(sub: sub)
                    if sub.id != items.last?.id {
                        Divider().padding(.vertical, 4)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .containerBackground(.fill, for: .widget)
    }
}

private struct LargeRowView: View {
    let sub: WidgetSubscription

    private var dateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: sub.nextPaymentDate)
    }

    var body: some View {
        HStack(spacing: 10) {
            WidgetIconView(subscription: sub, size: 32)

            VStack(alignment: .leading, spacing: 1) {
                Text(sub.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(sub.billingCycle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 1) {
                Text(sub.formattedPrice)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.semibold)
                    .foregroundStyle(sub.isUrgent ? .orange : .primary)
                Text(dateString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Widget Entry View (dispatcher)

struct SubTrackerWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SubTrackerEntry

    var body: some View {
        switch family {
        case .systemSmall:  SmallWidgetView(entry: entry)
        case .systemMedium: MediumWidgetView(entry: entry)
        case .systemLarge:  LargeWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct SubTrackerWidget: Widget {
    let kind = "SubTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SubTrackerProvider()) { entry in
            SubTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sub Tracker")
        .description("Track your upcoming subscription payments.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle

@main
struct SubTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        SubTrackerWidget()
    }
}
