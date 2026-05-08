
import SwiftUI

struct NotificationsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) var dismiss
    
    @State private var notificationManager = NotificationManager.shared
    
    // MARK: - Computed Colors
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
                        LazyVStack(spacing: 12) {
                            ForEach(groupedNotifications.keys.sorted(by: >), id: \.self) { date in
                                Section {
                                    ForEach(groupedNotifications[date] ?? []) { notification in
                                        NotificationRow(notification: notification, onDismiss: {
                                            notificationManager.dismissFromHistory(notification)
                                        })
                                    }
                                } header: {
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
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .fixedSize()
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
    
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText:       Color { appSettings.themeText }
    private var secondaryText:     Color { appSettings.themeTextSecondary }
    private var borderColor:       Color { appSettings.themeBorder }
    private var brand:             Color { appSettings.themeBrand }
    
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
            // App Icon (Square with rounded corners)
            Image(systemName: notification.icon)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Header: Title + Time + Dismiss
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
                
                // Body
                Text(notification.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(primaryText.opacity(0.9))
                    .lineLimit(3)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
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
