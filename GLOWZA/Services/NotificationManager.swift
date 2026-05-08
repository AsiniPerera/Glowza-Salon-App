import Foundation
import UserNotifications
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Notification Models
struct NotificationItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let icon: String
    let type: NotificationType
    let timestamp: Date
    
    enum NotificationType: String, Codable {
        case success
        case info
        case error
        case warning
    }
    
    init(title: String, subtitle: String, icon: String, type: NotificationType, timestamp: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.type = type
        self.timestamp = timestamp
    }
}

// MARK: - Notification Manager
@Observable
class NotificationManager {
    static let shared = NotificationManager()
    let bookingSuccessBannerDuration: TimeInterval = 30.0
    
    var notifications: [NotificationItem] = []
    var notificationHistory: [NotificationItem] = []
    
    private let historyKey = "glowza_notification_history"
    
    private let db = Firestore.firestore()
    private let notificationRepo = NotificationRepository.shared
    
    private init() {
        loadNotificationHistory()
        requestNotificationPermission()
    }
    
    // MARK: - Load & Save History
    private func loadNotificationHistory() {
        // Load from UserDefaults first (fastest)
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            self.notificationHistory = decoded
        }
        
        // Also load from Core Data (offline persistence)
        let userId = Auth.auth().currentUser?.uid
        if let cdNotifs = try? notificationRepo.fetchNotificationsFromCore(userId: userId) {
            let existingIds = Set(notificationHistory.map { $0.id })
            for cd in cdNotifs {
                if !existingIds.contains(cd.id) {
                    let type: NotificationItem.NotificationType = {
                        switch cd.type {
                        case "success": return .success
                        case "error": return .error
                        case "warning": return .warning
                        default: return .info
                        }
                    }()
                    let item = NotificationItem(
                        title: cd.title,
                        subtitle: cd.subtitle,
                        icon: cd.icon,
                        type: type,
                        timestamp: cd.createdAt
                    )
                    notificationHistory.append(item)
                }
            }
        }
    }
    
    private func saveNotificationHistory() {
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    // MARK: - Persist to Core Data & Firestore
    private func persistNotification(_ item: NotificationItem) {
        let userId = Auth.auth().currentUser?.uid
        let typeStr = typeString(item.type)
        
        // Save to Core Data
        try? notificationRepo.saveNotificationToCore(
            title: item.title,
            subtitle: item.subtitle,
            icon: item.icon,
            type: typeStr,
            userId: userId
        )
        
        // Save to Firestore
        guard let uid = userId else { return }
        let data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "subtitle": item.subtitle,
            "icon": item.icon,
            "type": typeStr,
            "userId": uid,
            "isRead": false,
            "createdAt": Timestamp(date: item.timestamp)
        ]
        db.collection("notifications").document(item.id.uuidString).setData(data, merge: true)
    }
    
    // MARK: - Dismiss Notification from History
    func dismissFromHistory(_ item: NotificationItem) {
        DispatchQueue.main.async {
            if let index = self.notificationHistory.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.notificationHistory.remove(at: index)
                }
                self.saveNotificationHistory()
            }
        }
    }
    
    // MARK: - Clear All History
    func clearAllHistory() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.notificationHistory.removeAll()
            }
            self.saveNotificationHistory()
        }
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
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - In-App Banner Notification
    func showNotification(_ item: NotificationItem, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                self.notifications.append(item)
                self.notificationHistory.insert(item, at: 0)  // Add to history at top
            }
            self.saveNotificationHistory()
            self.persistNotification(item)  // Save to Core Data & Firestore

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if let index = self.notifications.firstIndex(where: { $0.id == item.id }) {
                    withAnimation(.easeInOut(duration: 0.9)) {
                        self.notifications.remove(at: index)
                    }
                }
            }
        }
    }
    
    // MARK: - Booking Success Notification
    func notifyBookingSuccess(serviceName: String, salonName: String, time: String, date: String) {
        let title = "Booking Confirmed"
        let subtitle = "\(serviceName) • \(salonName) • \(date) at \(time)"
        
        // System notification
        sendLocalNotification(title: title, subtitle: subtitle, delay: 0.3)
        
        // In-app banner
        let notification = NotificationItem(
            title: title,
            subtitle: subtitle,
            icon: "checkmark.circle.fill",
            type: .success
        )
        showNotification(notification, duration: bookingSuccessBannerDuration)
    }

    // MARK: - Booking Failure Notification
    func notifyBookingFailure(message: String = "Could not complete your booking. Please try again.") {
        let notification = NotificationItem(
            title: "Booking Failed",
            subtitle: message,
            icon: "exclamationmark.triangle.fill",
            type: .error
        )
        showNotification(notification, duration: 2.5)
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
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.25)) {
                self.notifications.removeAll()
            }
        }
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
