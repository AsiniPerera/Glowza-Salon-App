import SwiftUI

// This view shows the history of notifications received by the user.
// It groups them by date and allows clearing them.
struct NotificationsView: View {
    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) var dismiss
    
    // We use the shared NotificationManager to access the history!
    @State private var notificationManager = NotificationManager.shared
    
    // Filter state
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case read = "Read"
    }
    
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
                // 1. Filter Tabs
                HStack(spacing: 0) {
                    ForEach(NotificationFilter.allCases, id: \.self) { filter in
                        VStack(spacing: 8) {
                            Text(filter.rawValue)
                                .font(.system(size: 15, weight: selectedFilter == filter ? .bold : .medium))
                                .foregroundColor(selectedFilter == filter ? brand : secondaryText)
                            
                            Rectangle()
                                .fill(selectedFilter == filter ? brand : Color.clear)
                                .frame(height: 2)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .background(pageBackground)
                
                Divider()

                if filteredNotifications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: selectedFilter == .unread ? "bell.fill" : "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(secondaryText.opacity(0.5))
                        
                        Text(selectedFilter == .unread ? "No Unread Notifications" : "No Notifications")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(primaryText)
                        
                        Text(selectedFilter == .unread ? "You've read everything!" : "You're all caught up!")
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
                                        }, onMarkRead: {
                                            notificationManager.markAsRead(notification)
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
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 17))
                            .fixedSize()
                    }
                    .foregroundColor(Color(hex: "9E1B4C"))
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Notifications")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(primaryText)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !notificationManager.notificationHistory.allSatisfy({ $0.isRead }) {
                        Button(action: { notificationManager.markAllAsRead() }) {
                            Label("Mark All as Read", systemImage: "checkmark.circle")
                        }
                    }
                    
                    if !notificationManager.notificationHistory.isEmpty {
                        Button(role: .destructive, action: { notificationManager.clearAllHistory() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(brand)
                }
            }
        }
    } // End of body
    
    // MARK: - Filtered Notifications
    private var filteredNotifications: [NotificationItem] {
        switch selectedFilter {
        case .all:    return notificationManager.notificationHistory
        case .unread: return notificationManager.notificationHistory.filter { !$0.isRead }
        case .read:   return notificationManager.notificationHistory.filter { $0.isRead }
        }
    }

    private var groupedNotifications: [Date: [NotificationItem]] {
        let calendar = Calendar.current
        var grouped: [Date: [NotificationItem]] = [:]
        for notification in filteredNotifications {
            let dateKey = calendar.startOfDay(for: notification.timestamp)
            if grouped[dateKey] != nil {
                grouped[dateKey]?.append(notification)
            } else {
                grouped[dateKey] = [notification]
            }
        }
        return grouped
    }
    
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
    let onMarkRead: () -> Void
    
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
        Button(action: {
            if !notification.isRead { onMarkRead() }
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: notification.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        Group {
                            if !notification.isRead {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 12, y: -12)
                            }
                        }
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 14, weight: notification.isRead ? .semibold : .bold))
                            .foregroundColor(primaryText)
                            .opacity(notification.isRead ? 0.7 : 1.0)
                        
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
                    
                    Text(notification.subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(primaryText.opacity(notification.isRead ? 0.6 : 0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(notification.isRead ? surfaceBackground.opacity(0.5) : surfaceBackground)
                    .shadow(color: .black.opacity(notification.isRead ? 0.02 : 0.06), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(notification.isRead ? Color.clear : borderColor, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
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
