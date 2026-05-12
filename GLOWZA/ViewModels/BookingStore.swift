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

    var upcoming: [Booking] {
        // Bookings that are marked as upcoming AND are for today or the future
        bookings.filter { 
            $0.status == .upcoming && $0.date >= Calendar.current.startOfDay(for: Date()) 
        }
        .sorted(by: { $0.date < $1.date })
    }

    var completed: [Booking] {
        // Bookings that are explicitly marked as completed OR are marked as upcoming but the date has passed
        bookings.filter {
            $0.status == .completed || ($0.status == .upcoming && $0.date < Calendar.current.startOfDay(for: Date()))
        }
        .sorted(by: { $0.date > $1.date }) // Most recent first
    }

    var cancelled: [Booking] { 
        bookings.filter { $0.status == .cancelled } 
        .sorted(by: { $0.date > $1.date })
    }

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
        let userId = authService.currentUID ?? "GUEST"
        
        let userName = authService.currentUserName
            ?? UserDefaults.standard.string(forKey: "profile_fullName")
            ?? "Guest"
        
        isLoading = true
        error = nil
        
        do {
            var firestoreId: String? = nil
            
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
                    receiptNumber: receiptNumber
                )
                
                receiptToFirestoreId[receiptNumber] = firestoreId!
            }
            
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
        let userId = authService.currentUID ?? "GUEST"
        
        isLoading = true
        error = nil
        
        // Offline-first: show cached data immediately.
        loadFromCoreData(userId: userId)
        
        if userId != "GUEST" {
            do {
                firestoreBookings = try await bookingService.fetchUserBookings(userId: userId)
                syncFirestoreToLocalBookings()
                persistFirestoreBookingsToCoreData(userId: userId)
                isLoading = false
            } catch {
                isLoading = false
                print("⚠️ Offline — showing cached bookings (\(bookings.count))")
            }
        } else {
            isLoading = false
        }

        // Final step: Inject demo data for lecturers/demo
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
