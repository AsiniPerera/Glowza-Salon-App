
import SwiftUI

struct NotificationsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var notificationManager = NotificationManager.shared
    
    private let brand = Color(hex: "962043")
    
    // MARK: - Computed Colors
    private var pageBackground: Color {
        appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white
    }
    
    private var surfaceBackground: Color {
        appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white
    }
    
    private var primaryText: Color {
        appSettings.isDarkMode ? Color.white : Color(hex: "1D1F24")
    }
    
    private var secondaryText: Color {
        appSettings.isDarkMode ? Color.white.opacity(0.6) : Color(hex: "8A8E95")
    }
    
    private var borderColor: Color {
        appSettings.isDarkMode ? Color.white.opacity(0.12) : Color(hex: "E5E5EA")
    }
    
    var body: some View {
        ZStack {
            pageBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Notifications")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(primaryText)
                    
                    Spacer()
                    
                    if !notificationManager.notificationHistory.isEmpty {
                        Button(action: { notificationManager.clearAllHistory() }) {
                            Text("Clear")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(brand)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(surfaceBackground)
                
                // Content
                if notificationManager.notificationHistory.isEmpty {
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
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                                Section {
                                    ForEach(groupedNotifications[date] ?? []) { notification in
                                        NotificationRow(notification: notification, onDismiss: {
                                            notificationManager.dismissFromHistory(notification)
                                        })
                                    }
                                } header: {
                                    Text(dateLabel(date))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(secondaryText)
                                        .textCase(nil)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(surfaceBackground)
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
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(brand)
                }
            }
        }
        .onAppear {
            notificationManager = NotificationManager.shared
        }
    }
    
    // MARK: - Grouped Notifications by Date
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
struct NotificationRow: View {
    @Environment(AppSettings.self) private var appSettings
    
    let notification: NotificationItem
    let onDismiss: () -> Void
    
    private let brand = Color(hex: "962043")
    
    private var surfaceBackground: Color {
        appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white
    }
    
    private var primaryText: Color {
        appSettings.isDarkMode ? Color.white : Color(hex: "1D1F24")
    }
    
    private var secondaryText: Color {
        appSettings.isDarkMode ? Color.white.opacity(0.6) : Color(hex: "8A8E95")
    }
    
    private var accentColor: Color {
        switch notification.type {
        case .success: return Color(hex: "34C759")
        case .error: return Color(hex: "FF3B30")
        case .warning: return Color(hex: "FF9500")
        case .info: return brand
        }
    }
    
    private var borderColor: Color {
        appSettings.isDarkMode ? Color.white.opacity(0.08) : Color(hex: "F2F2F7")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: notification.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 42, height: 42)
                .background(accentColor.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)
                
                Text(notification.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Time & Dismiss
            VStack(alignment: .trailing, spacing: 8) {
                Text(timeAgo(notification.timestamp))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(secondaryText)
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(secondaryText)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(surfaceBackground)
        .overlay(Divider(), alignment: .bottom)
    }
    
    // MARK: - Time Ago Helper
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
