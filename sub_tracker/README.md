# Subscription Tracker

A comprehensive iOS app to track and manage your subscriptions with payment reminders and spending analytics.

## Features

### 📱 Subscription Management
- Add, edit, and delete subscriptions
- Quick templates for popular services (Apple Music, Netflix, YouTube Premium, Claude Pro, etc.)
- Categorize subscriptions (Streaming, Music, AI & Tools, Productivity, Cloud Storage, Gaming, News & Media, Fitness)
- Custom icons and colors for each subscription
- Track billing cycles: Monthly, Quarterly, Half-Yearly, Yearly
- Set subscriptions as active or inactive
- Add notes to subscriptions

### 🔔 Smart Notifications
- Customizable reminder notifications (3, 5, 7, 14, or 30 days before payment)
- Automatic notification scheduling
- Visual indicators for upcoming payments
- Notification management in Settings

### 📊 Analytics & Insights
- Interactive pie chart showing spending by category
- Monthly and yearly spending views
- Cost breakdown by category with percentages
- Billing cycle distribution
- Upcoming payments timeline (next 30 days)
- Automatic cost conversions (e.g., yearly subscriptions shown as monthly equivalent)

### 💰 Financial Overview
- Real-time monthly total calculation
- Real-time yearly total calculation
- Cost equivalents for different billing cycles
- Track active vs inactive subscriptions

## App Structure

### Files Created

1. **Subscription.swift** - Core data model
   - SwiftData model for subscriptions
   - Billing cycle and category enums
   - Automatic cost calculations

2. **NotificationManager.swift** - Notification handling
   - Request notification permissions
   - Schedule/cancel notifications
   - Manage notification lifecycle

3. **SubscriptionListView.swift** - Main list interface
   - Display all subscriptions
   - Summary cards with totals
   - Swipe-to-delete functionality
   - Quick-add button

4. **AddEditSubscriptionView.swift** - Add/Edit interface
   - Quick templates for popular services
   - Comprehensive form with all subscription details
   - Icon picker
   - Real-time cost calculations

5. **StatisticsView.swift** - Analytics dashboard
   - Pie chart visualization
   - Category breakdown
   - Billing cycle analysis
   - Upcoming payments list

6. **SettingsView.swift** - App settings
   - Notification management
   - Data management (delete all)
   - App information

7. **ContentView.swift** - Main tab view
   - Three tabs: Subscriptions, Statistics, Settings

8. **sub_trackerApp.swift** - App entry point
   - SwiftData configuration
   - Model container setup

## Setup Instructions

### 1. Enable Notifications
When you first launch the app, you'll be prompted to enable notifications. Tap "Allow" to receive payment reminders.

### 2. Add Your First Subscription

**Using Quick Templates:**
1. Tap the "+" button
2. Choose from popular subscription templates
3. Fill in the price and payment date
4. Tap "Save"

**Custom Subscription:**
1. Tap the "+" button
2. Enter subscription details:
   - Name
   - Icon (tap to choose from icon picker)
   - Category
   - Price and currency
   - Billing cycle
   - Next payment date
   - Notification days before payment
3. Tap "Save"

### 3. View Analytics
1. Switch to the "Statistics" tab
2. Toggle between Monthly/Yearly view
3. See your spending breakdown by category
4. Check upcoming payments

### 4. Manage Subscriptions
- **Edit:** Tap any subscription to edit its details
- **Delete:** Swipe left on a subscription
- **Mark Inactive:** Edit a subscription and toggle "Active Subscription" off

## Supported Services

The app includes quick templates for:
- Apple Music
- Netflix
- YouTube Premium
- Claude Pro
- ChatGPT Plus
- Spotify
- Disney+
- Amazon Prime
- iCloud+
- Dropbox
- Google One
- Adobe Creative Cloud
- Microsoft 365
- GitHub Pro

You can also add any custom subscription with your own details!

## Categories

- 🎬 Streaming
- 🎵 Music
- 🧠 AI & Tools
- 💼 Productivity
- ☁️ Cloud Storage
- 🎮 Gaming
- 📰 News & Media
- 🏃 Fitness
- ⭐ Other

## Currency Support

Currently supports:
- USD (US Dollar)
- EUR (Euro)
- GBP (British Pound)
- JPY (Japanese Yen)
- CNY (Chinese Yuan)
- CAD (Canadian Dollar)
- AUD (Australian Dollar)

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Privacy

All data is stored locally on your device using SwiftData. No data is sent to external servers. Notifications are handled entirely on-device by iOS.

## Tips

1. **Set Realistic Notification Times:** Choose notification days that give you enough time to cancel if needed
2. **Review Monthly:** Check the Statistics tab monthly to track spending trends
3. **Use Categories:** Properly categorize subscriptions for better insights
4. **Mark Inactive:** Don't delete old subscriptions - mark them inactive to keep history
5. **Add Notes:** Use the notes field to store account details, cancellation policies, etc.

## Future Enhancements

Potential features for future versions:
- Export data to CSV
- Budget warnings
- Subscription sharing tracking
- Annual cost savings calculator
- Widget support
- iCloud sync
- Multiple currency support in one view
- Subscription price history tracking

---

Made with ❤️ using SwiftUI and SwiftData
