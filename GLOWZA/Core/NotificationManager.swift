import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Models
struct NotificationItem: Identifiable {
    let id: UUID = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let type: NotificationType
    let timestamp: Date = Date()
    
    enum NotificationType {
        case success
        case info
        case error
        case warning
    }
}

// MARK: - Notification Manager
@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    var notifications: [NotificationItem] = []
    
    private let notificationRepository = NotificationRepository.shared
    
    private init() {
        requestNotificationPermission()
    }
    
    // MARK: - Local Notification (System)
    func sendLocalNotification(title: String, subtitle: String, delay: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - In-App Banner Notification
    func showNotification(_ item: NotificationItem, duration: TimeInterval = 4.0) {
        notifications.append(item)
        
        // Save to Core Data
        do {
            try notificationRepository.saveNotificationToCore(
                title: item.title,
                subtitle: item.subtitle,
                icon: item.icon,
                type: typeString(item.type)
            )
        } catch {
            print("❌ Failed to save notification to Core Data: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if let index = self.notifications.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.notifications.remove(at: index)
                }
            }
        }
    }
    
    // MARK: - Booking Success Notification
    func notifyBookingSuccess(serviceName: String, salonName: String, time: String, date: String) {
        let title = "Booking Confirmed"
        let subtitle = "\(serviceName) • \(salonName) • \(date) at \(time)"
        
        // System notification
        sendLocalNotification(title: title, subtitle: subtitle, delay: 0.5)
        
        // In-app banner
        let notification = NotificationItem(
            title: title,
            subtitle: subtitle,
            icon: "checkmark.circle.fill",
            type: .success
        )
        showNotification(notification, duration: 5.0)
    }
    
    // MARK: - Request Permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Dismiss All
    func dismissAll() {
        notifications.removeAll()
    }
    
    // MARK: - Helper
    private func typeString(_ type: NotificationItem.NotificationType) -> String {
        switch type {
        case .success: return "success"
        case .info: return "info"
        case .error: return "error"
        case .warning: return "warning"
        }
    }
}
