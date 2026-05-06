import Foundation
import Observation
import Combine

@MainActor
@Observable
final class BookingStore {
    static let shared = BookingStore()
    private init() {}

    var bookings: [Booking] = []
    var firestoreBookings: [FirestoreBooking] = []
    var isLoading = false
    var error: String?
    /// Maps local receipt number to Firestore document ID for cross-referencing.
    private var receiptToFirestoreId: [String: String] = [:]

    private let bookingService = BookingService.shared
    private let authService = AuthService.shared
    private let bookingRepository = BookingRepository.shared

    var upcoming: [Booking] { bookings.filter { $0.status == .upcoming } }
    var completed: [Booking] { bookings.filter { $0.status == .completed } }
    var cancelled: [Booking] { bookings.filter { $0.status == .cancelled } }

    var upcomingFirestore: [FirestoreBooking] { firestoreBookings.filter { $0.status == "upcoming" } }
    var completedFirestore: [FirestoreBooking] { firestoreBookings.filter { $0.status == "completed" } }

    func add(_ booking: Booking) {
        bookings.append(booking)
        WidgetBookingSyncService.shared.saveUpcomingBooking(booking)
    }

    func cancelBooking(id: UUID) {
        guard let idx = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[idx].status = .cancelled
        WidgetBookingSyncService.shared.updateFromBookings(bookings)

        let receipt = bookings[idx].receiptNumber

        do {
            try bookingRepository.updateBookingStatus(id, status: "cancelled")
        } catch {
            print("Failed to save cancelled booking to Core Data: \(error)")
        }

        Task {
            if let firestoreId = receiptToFirestoreId[receipt] {
                await cancelBookingFirestore(firestoreId)
            } else {
                try? await bookingService.updateStatusByReceipt(receipt, status: "cancelled")
            }
        }
    }

    func addReview(bookingID: UUID, review: BookingReview) {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        bookings[idx].review = review
        bookings[idx].status = .completed
        WidgetBookingSyncService.shared.updateFromBookings(bookings)

        let receipt = bookings[idx].receiptNumber

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
        receiptNumber: String
    ) async {
        guard let userId = authService.currentUID else {
            error = "User not authenticated"
            return
        }

        let userName = authService.currentUserName
            ?? UserDefaults.standard.string(forKey: "profile_fullName")
            ?? "Guest"

        isLoading = true
        error = nil

        do {
            let firestoreId = try await bookingService.createBooking(
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
                receiptNumber: receiptNumber
            )

            receiptToFirestoreId[receiptNumber] = firestoreId

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
                firestoreID: firestoreId
            )

            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Booking creation failed: \(error)")
        }
    }

    func fetchUserBookings() async {
        guard let userId = authService.currentUID else {
            error = "User not authenticated"
            return
        }

        isLoading = true
        error = nil

        // Offline-first: show cached data immediately.
        loadFromCoreData(userId: userId)

        do {
            firestoreBookings = try await bookingService.fetchUserBookings(userId: userId)
            syncFirestoreToLocalBookings()
            persistFirestoreBookingsToCoreData(userId: userId)
            isLoading = false
        } catch {
            self.error = nil
            isLoading = false
            print("⚠️ Offline — showing cached bookings (\(bookings.count))")
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

            try? bookingRepository.saveBookingToCore(
                userId: userId,
                userName: userName,
                salonName: fb.bookingSummary.salon,
                salonLocation: fb.bookingSummary.salonLocation,
                serviceName: fb.bookingSummary.service,
                servicePrice: fb.bookingSummary.servicePrice,
                date: fb.createdAt,
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
        let existingReceipts = Set(bookings.map { $0.receiptNumber })

        for fb in firestoreBookings {
            let receipt = fb.bookingSummary.receiptNumber
            if let docId = fb.id { receiptToFirestoreId[receipt] = docId }
            if existingReceipts.contains(receipt) { continue }

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

            let status: BookingStatus
            switch fb.status {
            case "completed": status = .completed
            case "cancelled": status = .cancelled
            default: status = .upcoming
            }

            let scheduleParts = fb.bookingSummary.schedule.components(separatedBy: " - ")
            let timeSlot = scheduleParts.count > 1 ? scheduleParts.last! : ""

            let review: BookingReview? = fb.review.map {
                BookingReview(
                    rating: Int(fb.rating ?? 0),
                    comment: $0,
                    date: fb.createdAt,
                    reviewerName: fb.userName
                )
            }

            let localBooking = Booking(
                id: UUID(),
                salon: salon,
                service: service,
                date: fb.createdAt,
                timeSlot: timeSlot,
                receiptNumber: receipt,
                paymentMethod: pm,
                amountPaid: fb.bookingSummary.amount,
                signatureImage: nil,
                status: status,
                review: review
            )
            bookings.append(localBooking)
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
