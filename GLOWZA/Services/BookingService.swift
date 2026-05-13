import Foundation
import FirebaseFirestore

// MARK: - Booking Summary Model
// This struct represents a summary of a booking, stored inside the main booking document.
// It conforms to Codable so it can be easily converted to/from JSON in Firestore!
struct BookingSummary: Codable {
    let salon: String
    let salonLocation: String
    let service: String
    let servicePrice: Double
    let schedule: String  // Date + Time formatted (e.g., "Oct 24, 2026 - 10:30 AM")
    let amount: Double
    let receiptNumber: String
}

// MARK: - Firestore Booking Model
// This is the full model stored in the 'bookings' collection in Firestore.
struct FirestoreBooking: Codable {
    @DocumentID var id: String? // Firestore document ID (automatically populated!).
    let userId: String
    let userName: String
    let bookingSummary: BookingSummary // Nested summary object!
    let paymentMethod: String
    let status: String  // "upcoming", "completed", "cancelled"
    let createdAt: Date
    var rating: Double? // Optional rating (added when reviewing).
    var review: String? // Optional review text.
    
    // We use CodingKeys to map Swift properties to JSON keys if they are different,
    // or just to be explicit about what gets encoded/decoded!
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
// This class handles all network calls related to bookings in Firestore.
// @MainActor ensures all updates happen on the main thread!
@MainActor
final class BookingService {
    
    static let shared = BookingService() // Singleton instance!
    private init() {}
    
    private let db = Firestore.firestore() // Firestore reference.
    private let collectionName = "bookings"
    
    // MARK: - Create Booking
    /// - Returns: The Firestore document ID for the created booking.
    // @discardableResult means the caller can ignore the return value if they don't need it!
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

        let bookingId = UUID().uuidString // Generate a unique ID for the document!

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

        // Save the booking document to Firestore!
        try db.collection(collectionName).document(bookingId).setData(from: firestoreBooking)

        print("Booking saved — ID: \(bookingId), Receipt: \(receiptNumber)")
        return bookingId
    }
    
    // MARK: - Fetch User Bookings
    // Fetches all bookings for a specific user!
    func fetchUserBookings(userId: String) async throws -> [FirestoreBooking] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId) // Query by userId!
            .getDocuments()
        
        // compactMap is great here! It skips any documents that fail to decode!
        let bookings = try snapshot.documents.compactMap { doc in
            try doc.data(as: FirestoreBooking.self)
        }
        
        // Return sorted by creation date (newest first).
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
            "status": "completed" // Automatically complete the booking when reviewed!
        ]
        try await db.collection(collectionName)
            .document(bookingId)
            .setData(data, merge: true) // Use merge: true to avoid overwriting other fields!
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(bookingId: String) async throws {
        try await db.collection(collectionName)
            .document(bookingId)
            .updateData(["status": "cancelled"])
    }

    // MARK: - Update Status by Receipt Number
    // Fallback method when the Firestore doc ID isn't cached locally!
    func updateStatusByReceipt(_ receiptNumber: String, status: String) async throws {
        let snap = try await db.collection(collectionName)
            .whereField("bookingSummary.receiptNumber", isEqualTo: receiptNumber)
            .limit(to: 1) // We only expect one match!
            .getDocuments()
        guard let doc = snap.documents.first else { return }
        try await doc.reference.updateData(["status": status])
        print("Status updated to '\(status)' for receipt \(receiptNumber)")
    }

    // MARK: - Add Review by Receipt Number
    // Fallback method when the Firestore doc ID isn't cached locally!
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
    // This adds a review to a separate collection, not just the booking document!
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
            "createdAt": Timestamp() // Use Firestore Timestamp for dates!
        ]
        try await db.collection("salonReviews").document(reviewId).setData(data)
        print("Salon review saved for salonId: \(salonId)")
    }
}
