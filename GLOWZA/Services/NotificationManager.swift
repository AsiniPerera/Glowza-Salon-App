import Foundation
import UserNotifications
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - Notification Models
// This struct represents a single notification item!
// It conforms to Identifiable (so it can be used in Lists) and Codable (for JSON).
struct NotificationItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let subtitle: String
    let icon: String // SFSymbol name.
    let type: NotificationType
    let timestamp: Date
    var isRead: Bool
    
    enum NotificationType: String, Codable {
        case success
        case info
        case error
        case warning
    }
    
    // Default initializer for new notifications!
    init(title: String, subtitle: String, icon: String, type: NotificationType, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    // Initializer for existing notifications (from DB/Cloud)!
    init(id: UUID, title: String, subtitle: String, icon: String, type: NotificationType, timestamp: Date, isRead: Bool) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.type = type
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

// MARK: - Notification Manager
// This class handles all notifications in the app:
// 1. System notifications (that appear in the iOS notification center).
// 2. In-app banners (that slide down from the top).
// 3. Notification history (saved to Core Data and Firestore).
@Observable
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager() // Singleton instance!
    let bookingSuccessBannerDuration: TimeInterval = 30.0 // Duration for success banner.
    
    var notificationHistory: [NotificationItem] = [] // All past notifications.
    
    var unreadCount: Int {
        notificationHistory.filter { !$0.isRead }.count
    }
    
    func clearMemory() {
        notificationHistory = []
    }
    
    private let historyKey = "glowza_notification_history" // UserDefaults key.
    
    private let db = Firestore.firestore() // Firestore reference.
    private let notificationRepo = NotificationRepository.shared // Core Data repo.
    
    // Updates the red number on the app icon and syncs to database for tracking!
    private func updateAppIconBadge() {
        let count = unreadCount
        
        // 1. Update iOS App Icon Badge
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("Error setting badge count: \(error)")
            }
        }
        
        // 2. Track unread count in Firestore database!
        Task {
            guard let uid = AuthService.shared.currentUID else { return }
            try? await db.collection("users").document(uid).updateData([
                "unreadNotificationsCount": count,
                "lastBadgeUpdate": Timestamp(date: Date())
            ])
        }
    }
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self // Set delegate!
        loadNotificationHistory()
        requestNotificationPermission()
        Task {
            await fetchNotificationsFromFirestore()
        }
    }
    
    // MARK: - Load & Save History
    // Loads history from UserDefaults and Core Data!
    func loadNotificationHistory() {
        let userId = AuthService.shared.currentUID ?? "GUEST"
        let userSpecificKey = "\(historyKey)_\(userId)"
        
        // Load from UserDefaults first (fastest access!).
        if let data = UserDefaults.standard.data(forKey: userSpecificKey),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            self.notificationHistory = decoded
        }
        
        // Also load from Core Data (ensures data is persisted offline!).
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
                        id: cd.id, // Preserve the original ID!
                        title: cd.title,
                        subtitle: cd.subtitle,
                        icon: cd.icon,
                        type: type,
                        timestamp: cd.createdAt,
                        isRead: cd.isRead // Restore the read status!
                    )
                    notificationHistory.append(item)
                }
            }
        }
    }
    
    // Saves history to UserDefaults!
    private func saveNotificationHistory() {
        let userId = AuthService.shared.currentUID ?? "GUEST"
        let userSpecificKey = "\(historyKey)_\(userId)"
        
        if let encoded = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(encoded, forKey: userSpecificKey)
        }
        updateAppIconBadge() // Keep the icon badge in sync!
    }
    
    // MARK: - Fetch from Firestore
    // Pulls notifications from the cloud!
    func fetchNotificationsFromFirestore() async {
        guard let uid = AuthService.shared.currentUID else { return }
        do {
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            
            let firestoreNotifs = snapshot.documents.compactMap { doc -> NotificationItem? in
                let d = doc.data()
                guard let idString = d["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = d["title"] as? String,
                      let subtitle = d["subtitle"] as? String,
                      let icon = d["icon"] as? String,
                      let typeStr = d["type"] as? String,
                      let timestamp = (d["createdAt"] as? Timestamp)?.dateValue() else { return nil }
                
                let type: NotificationItem.NotificationType = {
                    switch typeStr {
                    case "success": return .success
                    case "error": return .error
                    case "warning": return .warning
                    default: return .info
                    }
                }()
                
                return NotificationItem(
                    id: id, // Use the ID from Firestore!
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    type: type,
                    timestamp: timestamp,
                    isRead: d["isRead"] as? Bool ?? false
                )
            }
            
            await MainActor.run {
                // Merge with local history!
                for item in firestoreNotifs {
                    // Stricter deduplication: ID check OR (Title + Subtitle + Timestamp within 1s)
                    if let index = self.notificationHistory.firstIndex(where: { 
                        $0.id == item.id || 
                        ($0.title == item.title && 
                         $0.subtitle == item.subtitle && 
                         abs($0.timestamp.timeIntervalSince(item.timestamp)) < 1.0)
                    }) {
                        // Update read status if it changed in Firestore!
                        if self.notificationHistory[index].isRead != item.isRead {
                            self.notificationHistory[index].isRead = item.isRead
                        }
                    } else {
                        self.notificationHistory.append(item)
                    }
                }
                
                // Sort by timestamp (newest first).
                self.notificationHistory.sort(by: { $0.timestamp > $1.timestamp })
                self.saveNotificationHistory()
                self.updateAppIconBadge() // Ensure UI and Icon are in sync!
            }
        } catch {
            print("Failed to fetch notifications from Firestore: \(error)")
        }
    }
    
    // MARK: - Persist to Core Data & Firestore
    // Saves a new notification to both local and remote DBs!
    private func persistNotification(_ item: NotificationItem) {
        let userId = AuthService.shared.currentUID
        let typeStr = typeString(item.type)
        
        // Save to Core Data.
        try? notificationRepo.saveNotificationToCore(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            icon: item.icon,
            type: typeStr,
            userId: userId
        )
        
        // Save to Firestore.
        guard let uid = userId else { return }
        let data: [String: Any] = [
            "id": item.id.uuidString,
            "title": item.title,
            "subtitle": item.subtitle,
            "icon": item.icon,
            "type": typeStr,
            "userId": uid,
            "isRead": item.isRead,
            "createdAt": Timestamp(date: item.timestamp)
        ]
        db.collection("notifications").document(item.id.uuidString).setData(data, merge: true)
    }
    
    // MARK: - Mark as Read
    func markAsRead(_ item: NotificationItem) {
        guard let index = notificationHistory.firstIndex(where: { $0.id == item.id }) else { return }
        
        notificationHistory[index].isRead = true
        saveNotificationHistory()
        updateAppIconBadge() // Update the count immediately!
        
        let id = item.id
        Task {
            // Update Core Data
            try? notificationRepo.markNotificationAsRead(id)
            
            // Update Firestore
            try? await db.collection("notifications").document(id.uuidString).updateData(["isRead": true])
        }
    }
    
    func markAllAsRead() {
        for i in 0..<notificationHistory.count {
            notificationHistory[i].isRead = true
        }
        saveNotificationHistory()
        updateAppIconBadge() // Clear the icon badge!
        
        Task {
            guard let uid = AuthService.shared.currentUID else { return }
            
            // 1. Update Core Data (Essential for local persistence!)
            try? notificationRepo.markAllNotificationsAsRead(userId: uid)
            
            // 2. Update Firestore for all user's notifications
            let snapshot = try? await db.collection("notifications").whereField("userId", isEqualTo: uid).whereField("isRead", isEqualTo: false).getDocuments()
            for doc in snapshot?.documents ?? [] {
                try? await doc.reference.updateData(["isRead": true])
            }
        }
    }
    
    // MARK: - Dismiss Notification from History
    func dismissFromHistory(_ item: NotificationItem) {
        DispatchQueue.main.async {
            if let index = self.notificationHistory.firstIndex(where: { $0.id == item.id }) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.notificationHistory.remove(at: index)
                }
                self.saveNotificationHistory()
                self.updateAppIconBadge()
                
                let id = item.id
                Task {
                    // 1. Delete from Core Data
                    // Note: Need to add delete method to repo!
                    try? NotificationRepository.shared.deleteNotification(id)
                    
                    // 2. Delete from Firestore
                    try? await self.db.collection("notifications").document(id.uuidString).delete()
                }
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
            self.updateAppIconBadge()
            
            Task {
                guard let uid = AuthService.shared.currentUID else { return }
                
                // 1. Clear Core Data
                try? self.notificationRepo.clearAllNotifications()
                
                // 2. Clear Firestore (Delete all documents for this user)
                let snapshot = try? await self.db.collection("notifications").whereField("userId", isEqualTo: uid).getDocuments()
                for doc in snapshot?.documents ?? [] {
                    try? await doc.reference.delete()
                }
            }
        }
    }
    
    // MARK: - Local Notification (System)
    // Sends a real iOS system notification!
    func sendLocalNotification(title: String, subtitle: String, delay: TimeInterval = 1.0) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = subtitle // Use 'body' instead of 'subtitle' for standard regular font look!
        content.sound = .default
        // Increment the app badge number!
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        // Trigger the notification after a short delay.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    
    // MARK: - Save Notification to History
    // Saves a notification to history and persists it.
    func showNotification(_ item: NotificationItem, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                self.notificationHistory.insert(item, at: 0)  // Add to history at top!
            }
            self.saveNotificationHistory()
            self.persistNotification(item)  // Save to Core Data & Firestore!
        }
    }
    
    // MARK: - Booking Success Notification
    func notifyBookingSuccess(serviceName: String, salonName: String, time: String, date: String) {
        let title = "Booking Confirmed"
        let subtitle = "\(serviceName) at \(salonName)" // Clean and short!
        
        // Send native iOS local push notification!
        sendLocalNotification(title: title, subtitle: subtitle, delay: 0.3)
        
        // Save to history!
        let notification = NotificationItem(
            title: title,
            subtitle: subtitle,
            icon: "checkmark.seal.fill",
            type: .success
        )
        showNotification(notification, duration: bookingSuccessBannerDuration)
    }

    // MARK: - Booking Failure Notification
    func notifyBookingFailure(message: String = "Could not complete your booking. Please try again.") {
        let notification = NotificationItem(
            title: "Booking Failed",
            subtitle: message,
            icon: "exclamationmark.shield.fill",
            type: .error
        )
        showNotification(notification, duration: 2.5)
    }
    
    // MARK: - Request Permission
    // Requests permission from the user to send notifications!
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    // Register for remote notifications if permission is granted!
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // MARK: - Dismiss All
    func dismissAll() {
        // Do nothing as in-app banners are removed!
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // This allows notifications to show while the app is in the foreground!
        completionHandler([.banner, .sound, .badge])
    }
    
    // MARK: - Nearest Booking Reminder
    // Finds the closest upcoming booking and sends a reminder!
    func scheduleNearestBookingReminder(from bookings: [Booking]) {
        // 1. Get upcoming bookings only (today or future)
        let upcoming = bookings.filter { 
            $0.status == .upcoming && $0.date >= Calendar.current.startOfDay(for: Date()) 
        }.sorted(by: { $0.date < $1.date })
        
        guard let nearest = upcoming.first else { return }
        
        // 2. Format the message
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        let dateStr = df.string(from: nearest.date)
        
        let timePart = nearest.timeSlot.isEmpty ? "" : " at \(nearest.timeSlot)"
        let title = "Appointment Reminder"
        let subtitle = "\(nearest.service.name) • \(nearest.salon.name) on \(dateStr)\(timePart)"
        
        // 3. Send system notification
        sendLocalNotification(title: title, subtitle: subtitle, delay: 1.5)
        
        // 4. Also add to history for user to see in the app!
        let notification = NotificationItem(
            title: title,
            subtitle: subtitle,
            icon: "calendar.badge.clock", // Our unique icon!
            type: .info
        )
        showNotification(notification)
    }

    // MARK: - Helper
    // Converts enum to string for storage!
    private func typeString(_ type: NotificationItem.NotificationType) -> String {
        switch type {
        case .success: return "success"
        case .info: return "info"
        case .error: return "error"
        case .warning: return "warning"
        }
    }
}
