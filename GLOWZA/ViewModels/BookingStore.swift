import Foundation
import Observation
import Combine
import UIKit

// MARK: - Booking Store
// This class manages the booking state for the app!
// It uses the newer @Observable macro (SwiftUI Observation framework) instead of ObservableObject.
// It handles offline-first data loading, syncing with Firestore, and updating the widget.
@MainActor
@Observable
final class BookingStore {
    // Singleton pattern!
    static let shared = BookingStore()
    private init() {}

    var bookings: [Booking] = []
    var firestoreBookings: [FirestoreBooking] = []
    var isLoading = false
    var error: String?
    
    func clearMemory() {
        bookings = []
        firestoreBookings = []
        receiptToFirestoreId = [:]
    }
    
    /// Maps local receipt number to Firestore document ID for cross-referencing!
    var receiptToFirestoreId: [String: String] = [:]

    private let bookingService = BookingService.shared
    private let authService = AuthService.shared
    private let bookingRepository = BookingRepository.shared

    // MARK: - Computed Properties
    // These properties automatically filter the bookings array!
    
    var upcoming: [Booking] {
        // Bookings that are marked as upcoming AND are for today or the future!
        bookings.filter { 
            $0.status == .upcoming && $0.date >= Calendar.current.startOfDay(for: Date()) 
        }
        .sorted(by: { $0.date < $1.date })
    }

    var completed: [Booking] {
        // Bookings that are explicitly marked as completed OR are marked as upcoming but the date has passed!
        bookings.filter {
            $0.status == .completed || ($0.status == .upcoming && $0.date < Calendar.current.startOfDay(for: Date()))
        }
        .sorted(by: { $0.date > $1.date }) // Most recent first
    }

    var cancelled: [Booking] { 
        bookings.filter { $0.status == .cancelled } 
        .sorted(by: { $0.date > $1.date })
    }

    // MARK: - Local Operations
    
    func add(_ booking: Booking) {
        bookings.append(booking)
        // Update the widget!
        WidgetBookingSyncService.shared.saveUpcomingBooking(booking)
    }

    func cancelBooking(id: UUID) {
        guard let idx = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[idx].status = .cancelled
        WidgetBookingSyncService.shared.updateFromBookings(bookings)

        let receipt = bookings[idx].receiptNumber

        // Update local Core Data!
        do {
            try bookingRepository.updateBookingStatus(id, status: "cancelled")
        } catch {
            print("Failed to save cancelled booking to Core Data: \(error)")
        }

        // Update remote Firestore!
        Task {
            if let firestoreId = receiptToFirestoreId[receipt] {
                await cancelBookingFirestore(firestoreId)
            } else {
                try? await bookingService.updateStatusByReceipt(receipt, status: "cancelled")
            }
        }
    }

    /// Triggers a push notification reminder for the nearest upcoming booking!
    func triggerNearestBookingReminder() {
        NotificationManager.shared.scheduleNearestBookingReminder(from: self.bookings)
    }

    func addReview(bookingID: UUID, review: BookingReview) {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        bookings[idx].review = review
        bookings[idx].status = .completed
        WidgetBookingSyncService.shared.updateFromBookings(bookings)

        let receipt = bookings[idx].receiptNumber

        // Update local Core Data!
        do {
            try bookingRepository.addReviewToCore(
                bookingId: bookingID,
                rating: review.rating,
                comment: review.comment,
                reviewerName: review.reviewerName
            )
        } catch {
            print("Failed to save review to Core Data: \(error)")
        }

        // Update remote Firestore!
        Task {
            if let firestoreId = receiptToFirestoreId[receipt] {
                await addReviewFirestore(firestoreId, rating: Double(review.rating), review: review.comment)
            } else {
                try? await bookingService.addReviewByReceipt(receipt, rating: Double(review.rating), review: review.comment)
            }
        }
    }

    func reviews(forSalon name: String) -> [BookingReview] {
        bookings.filter { $0.salon.name == name }.compactMap { $0.review }
    }

    // MARK: - Firebase Operations
    
    func createBooking(
        salonName: String,
        salonLocation: String,
        serviceName: String,
        servicePrice: Double,
        date: Date,
        timeSlot: String,
        paymentMethod: String,
        amountPaid: Double,
        receiptNumber: String,
        agreedConsent: String,
        signatureImage: UIImage?
    ) async throws {
        let userId = authService.currentUID ?? "GUEST"
        let userName = authService.currentUserName
            ?? UserDefaults.standard.string(forKey: "profile_fullName")
            ?? "Guest"
        
        isLoading = true
        error = nil
        
        // Convert signature image to Base64 for Firestore storage!
        var signatureBase64 = ""
        if let image = signatureImage, let imageData = image.jpegData(compressionQuality: 0.1) {
            signatureBase64 = imageData.base64EncodedString()
            print("📦 Signature converted to Base64 (length: \(signatureBase64.count))")
        } else {
            print("⚠️ No signature image found to save.")
        }
        
        do {
            var firestoreId: String? = nil
            
            // If logged in, save to Firestore!
            if userId != "GUEST" {
                firestoreId = try await bookingService.createBooking(
                    userId: userId,
                    userName: userName,
                    salonName: salonName,
                    salonLocation: salonLocation,
                    serviceName: serviceName,
                    servicePrice: servicePrice,
                    date: date,
                    timeSlot: timeSlot,
                    paymentMethod: paymentMethod,
                    amountPaid: amountPaid,
                    receiptNumber: receiptNumber,
                    agreedConsent: agreedConsent,
                    signatureBase64: signatureBase64
                )
                
                print("✅ Booking successfully saved to Firestore: \(firestoreId ?? "unknown")")
                receiptToFirestoreId[receiptNumber] = firestoreId!
            }
            
            // Always save to Core Data (local cache)!
            // NOTE: We DO NOT save the signatureImage to Core Data anymore for privacy!
            try? bookingRepository.saveBookingToCore(
                userId: userId,
                userName: userName,
                salonName: salonName,
                salonLocation: salonLocation,
                serviceName: serviceName,
                servicePrice: servicePrice,
                date: date,
                timeSlot: timeSlot,
                receiptNumber: receiptNumber,
                paymentMethod: paymentMethod,
                amountPaid: amountPaid,
                firestoreID: firestoreId,
                signatureImage: nil // Explicitly nil as per user request!
            )
            
            isLoading = false

        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("Booking creation failed: \(error)")
            throw error // Rethrow so caller knows it failed!
        }
    }

    func fetchUserBookings() async {
        let userId = authService.currentUID ?? "GUEST"
        
        // CRITICAL: Clear memory before fetching for a specific user to prevent data leaking!
        clearMemory()
        
        isLoading = true
        error = nil
        
        // 1. Offline-first: show cached data immediately!
        loadFromCoreData(userId: userId)
        
        // 2. Fetch fresh data from Firestore if logged in!
        if userId != "GUEST" {
            do {
                firestoreBookings = try await bookingService.fetchUserBookings(userId: userId)
                
                // Sync Firestore data with local state!
                syncFirestoreToLocalBookings()
                
                // Update Core Data cache!
                persistFirestoreBookingsToCoreData(userId: userId)
                
                // Auto-complete past bookings!
                updatePastBookingsStatus()
                
                isLoading = false
            } catch {
                isLoading = false
                print("Offline — showing cached bookings (\(bookings.count))")
            }
        } else {
            isLoading = false
        }

        // Final step: Inject demo data for lecturers/demo (if needed).
        // seedDemoData()
    }

    /// Injects hardcoded demo data to ensure every user has a populated profile (for lecturer demonstration).
    private func seedDemoData() {
        let catalog = SalonCatalog.shared
        let existingReceipts = Set(bookings.map { $0.receiptNumber })
        
        let demoBookings: [(salon: String, service: String, status: BookingStatus, dateOffset: Int)] = [
            ("Golden Avenue", "Chemical Peel", .completed, -5),
            ("Azure Spa", "Deep Tissue Massage", .upcoming, 2),
            ("The Glam Room", "Bridal Makeup", .cancelled, -10)
        ]

        for demo in demoBookings {
            let receipt = "DEMO-\(demo.salon.prefix(3).uppercased())-\(abs(demo.dateOffset))"
            if existingReceipts.contains(receipt) { continue }

            let salon = catalog.salon(named: demo.salon)
            let service = salon.services.first(where: { $0.name == demo.service }) 
                ?? salon.services.first!

            let demoDate = Calendar.current.date(byAdding: .day, value: demo.dateOffset, to: Date()) ?? Date()

            let localBooking = Booking(
                id: UUID(),
                salon: salon,
                service: service,
                date: demoDate,
                timeSlot: "10:00 AM",
                receiptNumber: receipt,
                paymentMethod: .card,
                amountPaid: service.price,
                signatureImage: nil,
                agreedConsent: "", // Demo data uses empty consent string.
                status: demo.status,
                review: demo.status == .completed ? BookingReview(rating: 5, comment: "Amazing service! Highly recommended.", date: demoDate, reviewerName: "Demo User") : nil
            )
            bookings.append(localBooking)
        }
    }

    // MARK: - Core Data offline helpers
    
    func loadFromCoreData(userId: String) {
        guard let cdBookings = try? bookingRepository.fetchBookingsFromCore(userId: userId),
              !cdBookings.isEmpty else { return }

        let existing = Set(bookings.map { $0.receiptNumber })
        for cd in cdBookings where !existing.contains(cd.receiptNumber) {
            if let booking = bookingRepository.convertCDBookingToBooking(cd) {
                bookings.append(booking)
                if let fid = cd.firestoreID {
                    receiptToFirestoreId[cd.receiptNumber] = fid
                }
            }
        }
    }

    private func persistFirestoreBookingsToCoreData(userId: String) {
        let userName = authService.currentUserName
            ?? UserDefaults.standard.string(forKey: "profile_fullName")
            ?? "Guest"

        let existingReceipts = Set(
            (try? bookingRepository.fetchBookingsFromCore(userId: userId))?.map { $0.receiptNumber } ?? []
        )

        for fb in firestoreBookings where !existingReceipts.contains(fb.bookingSummary.receiptNumber) {
            let scheduleParts = fb.bookingSummary.schedule.components(separatedBy: " - ")
            let timeSlot = scheduleParts.count > 1 ? scheduleParts.last! : ""
            
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            let appointmentDate = scheduleParts.first.flatMap { df.date(from: $0) } ?? fb.createdAt

            try? bookingRepository.saveBookingToCore(
                userId: userId,
                userName: userName,
                salonName: fb.bookingSummary.salon,
                salonLocation: fb.bookingSummary.salonLocation,
                serviceName: fb.bookingSummary.service,
                servicePrice: fb.bookingSummary.servicePrice,
                date: appointmentDate,
                timeSlot: timeSlot,
                receiptNumber: fb.bookingSummary.receiptNumber,
                paymentMethod: fb.paymentMethod,
                amountPaid: fb.bookingSummary.amount,
                firestoreID: fb.id
            )
        }
    }

    /// Merges Firestore bookings into local `bookings` while deduplicating by receipt number.
    private func syncFirestoreToLocalBookings() {
        let catalog = SalonCatalog.shared

        for fb in firestoreBookings {
            let receipt = fb.bookingSummary.receiptNumber
            if let docId = fb.id { receiptToFirestoreId[receipt] = docId }

            let status: BookingStatus
            switch fb.status {
            case "completed": status = .completed
            case "cancelled": status = .cancelled
            case "ongoing": status = .upcoming
            default: status = .upcoming
            }

            let review: BookingReview? = fb.review.map {
                BookingReview(
                    rating: Int(fb.rating ?? 0),
                    comment: $0,
                    date: fb.createdAt,
                    reviewerName: fb.userName
                )
            }

            if let idx = bookings.firstIndex(where: { $0.receiptNumber == receipt }) {
                // Update existing booking status and review!
                bookings[idx].status = status
                bookings[idx].review = review
                continue
            }

            let salon = catalog.salon(named: fb.bookingSummary.salon)
            let service = salon.services.first(where: { $0.name == fb.bookingSummary.service })
                ?? SalonService(
                    name: fb.bookingSummary.service,
                    icon: "sparkles",
                    duration: "",
                    price: fb.bookingSummary.servicePrice,
                    category: ""
                )

            let pm: PaymentMethodType
            switch fb.paymentMethod.lowercased() {
            case "cash", "pay at salon": pm = .cash
            case "online banking": pm = .online
            default: pm = .card
            }

            let scheduleParts = fb.bookingSummary.schedule.components(separatedBy: " - ")
            let timeSlot = scheduleParts.count > 1 ? scheduleParts.last! : ""
            
            let df = DateFormatter()
            df.dateFormat = "MMM d, yyyy"
            let appointmentDate = scheduleParts.first.flatMap { df.date(from: $0) } ?? fb.createdAt

            let localBooking = Booking(
                id: UUID(),
                salon: salon,
                service: service,
                date: appointmentDate,
                timeSlot: timeSlot,
                receiptNumber: receipt,
                paymentMethod: pm,
                amountPaid: fb.bookingSummary.amount,
                signatureImage: nil,
                agreedConsent: fb.bookingSummary.agreedConsent ?? "", // Restore from Firestore!
                status: status,
                review: review
            )
            bookings.append(localBooking)
        }

        WidgetBookingSyncService.shared.updateFromBookings(bookings)
    }

    /// Automatically marks past upcoming bookings as completed in local state, Core Data, and Firestore.
    func updatePastBookingsStatus() {
        let now = Date()
        let startOfToday = Calendar.current.startOfDay(for: now)
        
        for i in 0..<bookings.count {
            if bookings[i].status == .upcoming && bookings[i].date < startOfToday {
                bookings[i].status = .completed
                
                // Update Core Data!
                try? bookingRepository.updateBookingStatus(bookings[i].id, status: "completed")
                
                // Update Firestore!
                let receipt = bookings[i].receiptNumber
                Task {
                    try? await bookingService.updateStatusByReceipt(receipt, status: "completed")
                }
            }
        }
        WidgetBookingSyncService.shared.updateFromBookings(bookings)
    }

    func cancelBookingFirestore(_ bookingId: String) async {
        isLoading = true
        error = nil

        do {
            try await bookingService.cancelBooking(bookingId: bookingId)
            await fetchUserBookings()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }

    func addReviewFirestore(_ bookingId: String, rating: Double, review: String) async {
        isLoading = true
        error = nil

        do {
            try await bookingService.addReview(bookingId: bookingId, rating: rating, review: review)
            await fetchUserBookings()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
}

