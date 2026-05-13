import Foundation
import CoreData
import Network
import FirebaseFirestore

// MARK: - Offline-first Data Sync Manager
// This manager handles syncing data between local Core Data and remote Firestore.
// Core Data is the single local cache (works offline); Firestore is the remote source of truth.
// On launch: load from Core Data immediately (fast!) then refresh from Firestore in background.
// On reconnect: push any bookings that were created while offline!
@MainActor
final class DataSyncManager {
    static let shared = DataSyncManager() // Singleton instance!

    private(set) var isOnline: Bool = true // Tracks network status!

    private let coreDataStack     = CoreDataStack.shared
    private let bookingRepository  = BookingRepository.shared
    private let userProfileRepo    = UserProfileRepository.shared
    private let salonRepository    = SalonRepository.shared

    // NWPathMonitor is Apple's framework for monitoring network changes!
    private nonisolated let monitor      = NWPathMonitor()
    private nonisolated let monitorQueue = DispatchQueue(label: "com.glowza.network", qos: .utility)

    private init() {
        // Set up the network monitor callback!
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                let nowOnline = path.status == .satisfied
                self?.isOnline = nowOnline
                
                // If we just came online, sync any pending offline bookings!
                if nowOnline { await self?.syncPendingBookingsToFirestore() }
            }
        }
        monitor.start(queue: monitorQueue)
        
        // Populate default data if empty (Crucial for first-time offline support!).
        populateDefaultDataIfEmpty()
    }
    
    /// Populates Core Data with default salons from Catalog if empty.
    func populateDefaultDataIfEmpty() {
        do {
            let existing = try salonRepository.fetchAllSalons()
            if existing.isEmpty {
                let defaultSalons = SalonCatalog.shared.salons
                try salonRepository.upsertSalons(defaultSalons)
                print("Core Data populated with default salons.")
            }
        } catch {
            print("Failed to populate default data: \(error)")
        }
    }

    // MARK: - Offline Bootstrap
    /// Called right after auth state is confirmed. Loads Core Data into in-memory stores
    /// so the UI is responsive before any Firestore network request completes!
    func bootstrapFromCoreData(userId: String) {
        BookingStore.shared.loadFromCoreData(userId: userId)
    }

    // MARK: - Salon Cache
    /// Persist a fresh Firestore salon list to Core Data for offline use.
    func cacheSalons(_ salons: [Salon]) {
        // We use a detached task to avoid blocking the main thread!
        Task.detached(priority: .utility) { [salonRepository] in
            try? salonRepository.upsertSalons(salons)
        }
    }

    /// Return salons from Core Data cache (offline fallback).
    func loadCachedSalons() -> [Salon] {
        (try? salonRepository.fetchAllSalons()) ?? []
    }

    // MARK: - Sync pending bookings to Firestore
    // Offline-created bookings have firestoreID == nil or empty.
    func syncPendingBookingsToFirestore() async {
        guard let userId = AuthService.shared.currentUID else { return }
        do {
            let all     = try bookingRepository.fetchBookingsFromCore(userId: userId)
            let pending = all.filter { $0.firestoreID == nil || $0.firestoreID == "" }
            guard !pending.isEmpty else { return }
            
            print("🔄 Syncing \(pending.count) offline booking(s) to Firestore…")
            for cd in pending {
                // Create the booking in Firestore!
                let fid = try await BookingService.shared.createBooking(
                    userId: cd.userId, userName: cd.userName,
                    salonName: cd.salonName, salonLocation: cd.salonLocation,
                    serviceName: cd.serviceName, servicePrice: cd.servicePrice,
                    date: cd.date, timeSlot: cd.timeSlot,
                    paymentMethod: cd.paymentMethod, amountPaid: cd.amountPaid,
                    receiptNumber: cd.receiptNumber
                )
                // Update the local Core Data record with the new Firestore ID!
                try await bookingRepository.syncBookingWithFirebase(cd, firestoreID: fid)
                print("Synced offline booking \(cd.receiptNumber) → \(fid)")
            }
        } catch {
            print("Pending booking sync failed: \(error)")
        }
    }

    // MARK: - Full Firestore → Core Data sync
    // Use after sign-in on a new device to pull all history down!
    func syncFirestoreToCoreData(userId: String) async {
        let userName = UserDefaults.standard.string(forKey: "profile_fullName") ?? "Guest"

        // 1. Push static salon catalog to Firestore (merge: true — safe to re-run)
        await SalonFirestoreService.shared.uploadSalonCatalog()

        // 2. Sync bookings from Firestore → Core Data
        if let fbBookings = try? await BookingService.shared.fetchUserBookings(userId: userId) {
            let existing = Set((try? bookingRepository.fetchBookingsFromCore(userId: userId))?.map { $0.receiptNumber } ?? [])
            for fb in fbBookings where !existing.contains(fb.bookingSummary.receiptNumber) {
                try? bookingRepository.saveBookingToCore(
                    userId: userId, userName: userName,
                    salonName: fb.bookingSummary.salon,
                    salonLocation: fb.bookingSummary.salonLocation,
                    serviceName: fb.bookingSummary.service,
                    servicePrice: fb.bookingSummary.servicePrice,
                    date: fb.createdAt, timeSlot: "",
                    receiptNumber: fb.bookingSummary.receiptNumber,
                    paymentMethod: fb.paymentMethod,
                    amountPaid: fb.bookingSummary.amount,
                    firestoreID: fb.id
                )
            }
        }

        // 3. Sync notifications from Firestore → Core Data
        let notificationRepo = NotificationRepository.shared
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("notifications")
                .whereField("userId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
                .getDocuments()
            
            for doc in snapshot.documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let subtitle = data["subtitle"] as? String else { continue }
                let icon = data["icon"] as? String ?? "bell.fill"
                let type = data["type"] as? String ?? "info"
                
                try? notificationRepo.saveNotificationToCore(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    type: type,
                    userId: userId
                )
            }
        } catch {
            print("Notification sync failed: \(error)")
        }

        // 4. Cache static catalog salons to Core Data for offline access
        try? salonRepository.upsertSalons(SalonCatalog.shared.salons)
    }

    // MARK: - Clear all local cache
    // Used when logging out or clearing data!
    func clearAllCoreData() throws {
        try coreDataStack.deleteAll("CDBooking")
        try coreDataStack.deleteAll("CDReview")
        try coreDataStack.deleteAll("CDNotification")
        try coreDataStack.deleteAll("CDUserProfile")
        try coreDataStack.deleteAll("CDSalon")
        try coreDataStack.deleteAll("CDSalonService")
    }
}
