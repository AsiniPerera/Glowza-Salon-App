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
        amountPaid: Double
    ) async throws {
        
        let bookingId = UUID().uuidString
        
        // Format date and time
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        let schedule = formatter.string(from: date) + " - " + timeSlot
        
        // Generate receipt number
        let receiptNumber = "GLZ-\(UUID().uuidString.prefix(8).uppercased())"
        
        // Create booking summary
        let bookingSummary = BookingSummary(
            salon: salonName,
            salonLocation: salonLocation,
            service: serviceName,
            servicePrice: servicePrice,
            schedule: schedule,
            amount: amountPaid,
            receiptNumber: receiptNumber
        )
        
        // Create firestore booking
        let firestoreBooking = FirestoreBooking(
            id: bookingId,
            userId: userId,
            userName: userName,
            bookingSummary: bookingSummary,
            paymentMethod: paymentMethod,
            status: "upcoming",
            createdAt: Date()
        )
        
        // Save to Firestore
        try db.collection(collectionName)
            .document(bookingId)
            .setData(from: firestoreBooking)
        
        print("✅ Booking saved successfully")
        print("   Booking ID: \(bookingId)")
        print("   User: \(userName)")
        print("   Salon: \(salonName)")
        print("   Amount: $\(amountPaid)")
        print("   Receipt: \(receiptNumber)")
    }
    
    // MARK: - Fetch User Bookings
    func fetchUserBookings(userId: String) async throws -> [FirestoreBooking] {
        let snapshot = try await db.collection(collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try doc.data(as: FirestoreBooking.self)
        }
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
        try await db.collection(collectionName)
            .document(bookingId)
            .updateData([
                "rating": rating,
                "review": review,
                "status": "completed"
            ])
    }
    
    // MARK: - Cancel Booking
    func cancelBooking(bookingId: String) async throws {
        try await db.collection(collectionName)
            .document(bookingId)
            .updateData(["status": "cancelled"])
    }
}
