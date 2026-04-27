import Foundation
import Observation
import Combine

@MainActor
@Observable
final class BookingStore {
    static let shared = BookingStore()
    private init() { 
        loadSampleData()
    }

    var bookings: [Booking] = []
    var firestoreBookings: [FirestoreBooking] = []
    var isLoading = false
    var error: String?
    
    private let bookingService = BookingService.shared
    private let authService = AuthService.shared
    private let bookingRepository = BookingRepository.shared

    var upcoming:   [Booking] { bookings.filter { $0.status == .upcoming   } }
    var completed:  [Booking] { bookings.filter { $0.status == .completed  } }
    var cancelled:  [Booking] { bookings.filter { $0.status == .cancelled  } }
    
    var upcomingFirestore: [FirestoreBooking] { firestoreBookings.filter { $0.status == "upcoming" } }
    var completedFirestore: [FirestoreBooking] { firestoreBookings.filter { $0.status == "completed" } }

    func add(_ booking: Booking) { 
        bookings.append(booking) 
    }

    func cancelBooking(id: UUID) {
        guard let idx = bookings.firstIndex(where: { $0.id == id }) else { return }
        bookings[idx].status = .cancelled
        
        // Save to Core Data
        do {
            try bookingRepository.updateBookingStatus(id, status: "cancelled")
            print("✅ Booking cancelled and saved to Core Data")
        } catch {
            print("❌ Failed to save cancelled booking to Core Data: \(error)")
        }
    }

    func addReview(bookingID: UUID, review: BookingReview) {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        bookings[idx].review = review
        
        // Save to Core Data
        do {
            try bookingRepository.addReviewToCore(
                bookingId: bookingID,
                rating: review.rating,
                comment: review.comment,
                reviewerName: review.reviewerName
            )
            print("✅ Review added and saved to Core Data")
        } catch {
            print("❌ Failed to save review to Core Data: \(error)")
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
        amountPaid: Double
    ) async {
        guard let userId = authService.currentUID else {
            error = "User not authenticated"
            return
        }
        let userName = authService.currentUserName ?? "Unknown User"
        
        isLoading = true
        error = nil
        
        let bookingId = UUID()
        
        do {
            // Save to Core Data first
            try bookingRepository.saveBookingToCore(
                id: bookingId,
                userId: userId,
                userName: userName,
                salonName: salonName,
                salonLocation: salonLocation,
                serviceName: serviceName,
                servicePrice: servicePrice,
                date: date,
                timeSlot: timeSlot,
                paymentMethod: paymentMethod,
                amountPaid: amountPaid
            )
            
            // Then save to Firebase
            try await bookingService.createBooking(
                userId: userId,
                userName: userName,
                salonName: salonName,
                salonLocation: salonLocation,
                serviceName: serviceName,
                servicePrice: servicePrice,
                date: date,
                timeSlot: timeSlot,
                paymentMethod: paymentMethod,
                amountPaid: amountPaid
            )
            
            // Refresh bookings from Firestore
            await fetchUserBookings()
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
        
        do {
            firestoreBookings = try await bookingService.fetchUserBookings(userId: userId)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            print("❌ Failed to fetch bookings: \(error)")
        }
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

    // MARK: - Sample Data
    private func loadSampleData() {
        let salon   = SalonCatalog.shared.salon(named: "Haley Avenue")
        let service = salon.services[0]
        let service2 = salon.services[3]
        bookings = [
            // Upcoming
            Booking(
                id: UUID(), salon: salon, service: service,
                date: makeDate(2026, 5, 10, 9, 30), timeSlot: "9:30 AM",
                receiptNumber: "GLZ-72341", paymentMethod: .card,
                amountPaid: service.price, signatureImage: nil,
                status: .upcoming, review: nil
            ),
            Booking(
                id: UUID(), salon: salon, service: service2,
                date: makeDate(2026, 5, 28, 11, 0), timeSlot: "11:00 AM",
                receiptNumber: "GLZ-72456", paymentMethod: .cash,
                amountPaid: service2.price, signatureImage: nil,
                status: .upcoming, review: nil
            ),
            // Completed
            Booking(
                id: UUID(), salon: salon, service: service,
                date: makeDate(2024, 9, 10, 9, 30), timeSlot: "9:30 AM",
                receiptNumber: "GLZ-48291", paymentMethod: .card,
                amountPaid: service.price, signatureImage: nil,
                status: .completed, review: nil
            ),
            Booking(
                id: UUID(), salon: salon, service: service,
                date: makeDate(2024, 9, 28, 9, 30), timeSlot: "9:30 AM",
                receiptNumber: "GLZ-51827", paymentMethod: .card,
                amountPaid: service.price, signatureImage: nil,
                status: .completed,
                review: BookingReview(
                    rating: 5,
                    comment: "Absolutely amazing! My skin glowed for days afterwards. The therapist was so professional.",
                    date: makeDate(2024, 9, 30, 14, 0),
                    reviewerName: "Asini P."
                )
            )
        ]
    }

    private func makeDate(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = mo; c.day = d; c.hour = h; c.minute = min
        return Calendar.current.date(from: c) ?? Date()
    }
}
