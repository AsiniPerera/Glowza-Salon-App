import SwiftUI

// This view shows the history of notifications received by the user.
// It groups them by date and allows clearing them.
struct NotificationsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) var dismiss
    
    // We use the shared NotificationManager to access the history!
    @State private var notificationManager = NotificationManager.shared
    
    // MARK: - Computed Colors
    // These adapt to dark mode and theme settings!
    private var pageBackground:    Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText:       Color { appSettings.themeText }
    private var secondaryText:     Color { appSettings.themeTextSecondary }
    private var borderColor:       Color { appSettings.themeBorder }
    private var brand:             Color { appSettings.themeBrand }
    
    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Empty state or List
                if notificationManager.notificationHistory.isEmpty {
                    // Show this when there are no notifications!
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(secondaryText.opacity(0.5))
                        
                        Text("No Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(primaryText)
                        
                        Text("You're all caught up!")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(secondaryText)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    // Show the list of notifications!
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Loop through the grouped dates (sorted newest first)
                            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                                Section {
                                    // Show rows for each notification on this date
                                    ForEach(groupedNotifications[date] ?? []) { notification in
                                        NotificationRow(notification: notification, onDismiss: {
                                            notificationManager.dismissFromHistory(notification)
                                        })
                                    }
                                } header: {
                                    // Section header (Today, Yesterday, etc.)
                                    Text(dateLabel(date))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(secondaryText)
                                        .textCase(nil)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                            .fixedSize()
                    }
                    .foregroundColor(Color(hex: "9E1B4C")) // Custom brand pink
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Notifications")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(primaryText)
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !notificationManager.notificationHistory.isEmpty {
                    Button(action: { notificationManager.clearAllHistory() }) {
                        Text("Clear")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "9E1B4C"))
                    }
                }
            }
        }
        .onAppear {
            // Refresh the manager on appear to get latest state
            notificationManager = NotificationManager.shared
        }
    }
    
    // MARK: - Grouped Notifications by Date
    // This computed property splits the array into a dictionary keyed by date (start of day).
    private var groupedNotifications: [Date: [NotificationItem]] {
        let calendar = Calendar.current
        var grouped: [Date: [NotificationItem]] = [:]
        
        for notification in notificationManager.notificationHistory {
            let dateKey = calendar.startOfDay(for: notification.timestamp)
            if grouped[dateKey] != nil {
                grouped[dateKey]?.append(notification)
            } else {
                grouped[dateKey] = [notification]
            }
        }
        
        return grouped
    }
    
    // MARK: - Date Label Helper
    // Converts a date into a friendly string like "Today" or "Yesterday".
    private func dateLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

// MARK: - Notification Row
// Represents a single notification card in the list!
struct NotificationRow: View {
    @Environment(AppSettings.self) private var appSettings
    
    let notification: NotificationItem
    let onDismiss: () -> Void // Callback to remove it from history.
    
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText:       Color { appSettings.themeText }
    private var secondaryText:     Color { appSettings.themeTextSecondary }
    private var borderColor:       Color { appSettings.themeBorder }
    private var brand:             Color { appSettings.themeBrand }
    
    // Pick an accent color based on the notification type!
    private var accentColor: Color {
        switch notification.type {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return brand
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon with colored background
            Image(systemName: notification.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content area
            VStack(alignment: .leading, spacing: 4) {
                // Header: Title + Time + Dismiss Button
                HStack {
                    Text(notification.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryText)
                    
                    Spacer()
                    
                    Text(timeAgo(notification.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(secondaryText)
                            .padding(4)
                            .background(Color.gray.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
                
                // Body message
                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(primaryText.opacity(0.9))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(
            // We use .ultraThinMaterial for a modern blurred look!
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
    
    // MARK: - Time Ago Helper
    // Formats the timestamp into a string relative to now (e.g. "5m ago").
    private func timeAgo(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "just now"
        }
    }
}

#Preview {
    NavigationStack {
        NotificationsView()
            .environment(AppSettings.shared)
    }
}
