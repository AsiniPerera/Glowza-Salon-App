import Foundation
import FirebaseFirestore

// MARK: - Booking Summary Model
struct BookingSummary: Codable {
    let salon: String
    let salonLocation: String
    let service: String
    let servicePrice: Double
    let schedule: String  // Date + Time formatted
    let amount: Double
    let receiptNumber: String
}

// MARK: - Firestore Booking Model
struct FirestoreBooking: Codable {
    @DocumentID var id: String?
    let userId: String
    let userName: String
    let bookingSummary: BookingSummary
    let paymentMethod: String
    let status: String  // "upcoming", "completed", "cancelled"
    let createdAt: Date
    var rating: Double?
    var review: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case bookingSummary
        case paymentMethod
        case status
        case createdAt
        case rating
        case review
    }
}

// MARK: - Booking Service
@MainActor
final class BookingService {
    
    static let shared = BookingService()
    private init() {}
    
    private let db = Firestore.firestore()
    private let collectionName = "bookings"
    
    // MARK: - Create Booking
    /// - Returns: The Firestore document ID for the created booking.
    @discardableResult
    func createBooking(
        userId: String,
        userName: String,
        salonName: String,
        salonLocation: String,
        serviceName: String,
        servicePrice: Double,
        date: Date,
        timeSlot: String,
        paymentMethod: String,
        amountPaid: Double,
        receiptNumber: String
    ) async throws -> String {

        let bookingId = UUID().uuidString

        // Format date only (time comes from timeSlot)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let schedule = formatter.string(from: date) + " - " + timeSlot

        // Build booking summary using the caller-supplied receipt number
        let bookingSummary = BookingSummary(
            salon: salonName,
            salonLocation: salonLocation,
            service: serviceName,
            servicePrice: servicePrice,
            schedule: schedule,
            amount: amountPaid,
            receiptNumber: receiptNumber
        )

        let firestoreBooking = FirestoreBooking(
            id: bookingId,
            userId: userId,
            userName: userName,
            bookingSummary: bookingSummary,
            paymentMethod: paymentMethod,
            status: "upcoming",
            createdAt: Date()
        )

        try db.collection(collectionName).document(bookingId).setData(from: firestoreBooking)

        print("✅ Booking saved — ID: \(bookingId), Receipt: \(receiptNumber)")
        return bookingId
    }
    
    // MARK: - Fetch User Bookings
    func fetchUserBookings(userId: String) async throws -> [FirestoreBooking] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        let bookings = try snapshot.documents.compactMap { doc in
            try doc.data(as: FirestoreBooking.self)
        }
        
        return bookings.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    // MARK: - Get Single Booking
    func getBooking(bookingId: String) async throws -> FirestoreBooking? {
        let doc = try await db.collection(collectionName).document(bookingId).getDocument()
        return try doc.data(as: FirestoreBooking.self)
    }
    
    // MARK: - Update Booking Status
    func updateBookingStatus(bookingId: String, status: String) async throws {
        try await db.collection(collectionName)
            .document(bookingId)
            .updateData(["status": status])
    }
    
    // MARK: - Add Review
    func addReview(bookingId: String, rating: Double, review: String) async throws {
        guard !bookingId.isEmpty else {
            print(" bookingId is empty in addReview. Skipping Firestore update.")
            return
        }
        let data: [String: Any] = [
            "rating": rating,
            "review": review,
            "status": "completed"
        ]
        try await db.collection(collectionName)
            .document(bookingId)
            .setData(data, merge: true)
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(bookingId: String) async throws {
        try await db.collection(collectionName)
            .document(bookingId)
            .updateData(["status": "cancelled"])
    }

    // MARK: - Update Status by Receipt Number (fallback when Firestore doc ID isn't cached)
    func updateStatusByReceipt(_ receiptNumber: String, status: String) async throws {
        let snap = try await db.collection(collectionName)
            .whereField("bookingSummary.receiptNumber", isEqualTo: receiptNumber)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snap.documents.first else { return }
        try await doc.reference.updateData(["status": status])
        print("Status updated to '\(status)' for receipt \(receiptNumber)")
    }

    // MARK: - Add Review by Receipt Number (fallback)
    func addReviewByReceipt(_ receiptNumber: String, rating: Double, review: String) async throws {
        let snap = try await db.collection(collectionName)
            .whereField("bookingSummary.receiptNumber", isEqualTo: receiptNumber)
            .limit(to: 1)
            .getDocuments()
        guard let doc = snap.documents.first else { return }
        try await doc.reference.updateData([
            "rating": rating,
            "review": review,
            "status": "completed"
        ])
        print(" Review saved for receipt \(receiptNumber)")
    }

    // MARK: - Add Salon Review to salonReviews collection
    func addSalonReview(
        salonId: String,
        userId: String,
        userName: String,
        rating: Int,
        comment: String
    ) async throws {
        let reviewId = UUID().uuidString
        let data: [String: Any] = [
            "id": reviewId,
            "salonId": salonId,
            "userId": userId,
            "userName": userName,
            "rating": rating,
            "comment": comment,
            "createdAt": Timestamp()
        ]
        try await db.collection("salonReviews").document(reviewId).setData(data)
        print("✅ Salon review saved for salonId: \(salonId)")
    }
}
