import Foundation
import FirebaseFirestore

// MARK: - Firestore Salon Review Model
struct FirestoreSalonReview: Codable, Identifiable {
    @DocumentID var documentId: String?
    var id: String
    var salonId: String
    var userId: String
    var userName: String
    var rating: Int
    var comment: String
    var createdAt: Date
}

// MARK: - Salon Firestore Service
@MainActor
final class SalonFirestoreService {

    static let shared = SalonFirestoreService()
    private init() {}

    private let db = Firestore.firestore()

    // MARK: - Upsert Salon Data
    func upsertSalon(
        name: String,
        location: String,
        distance: String,
        rating: Double,
        reviewCount: Int,
        score: Double,
        categories: [String]
    ) async throws {
        let id = salonId(for: name)
        try await db.collection("salons").document(id).setData([
            "id": id,
            "name": name,
            "location": location,
            "distance": distance,
            "rating": rating,
            "reviewCount": reviewCount,
            "score": score,
            "categories": categories,
            "updatedAt": Timestamp()
        ], merge: true)
    }

    // MARK: - Fetch Reviews for a Salon
    func fetchReviews(forSalonId salonId: String) async throws -> [FirestoreSalonReview] {
        let snapshot = try await db.collection("salonReviews")
            .whereField("salonId", isEqualTo: salonId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: FirestoreSalonReview.self) }
    }

    // MARK: - Add Salon Review
    func addSalonReview(
        salonId: String,
        userId: String,
        userName: String,
        rating: Int,
        comment: String
    ) async throws {
        try await BookingService.shared.addSalonReview(
            salonId: salonId,
            userId: userId,
            userName: userName,
            rating: rating,
            comment: comment
        )
    }

    // MARK: - Map salon display name → Firestore salonId
    /// Returns the Firestore document ID for a given salon display name.
    func salonId(for salonName: String) -> String {
        let knownIds: [String: String] = [
            "Haley Avenue":       "haley_avenue",
            "Glow Studio":        "glow_studio",
            "Luxe Aesthetics":    "luxe_aesthetics",
            "Velvet Touch":       "velvet_touch",
            "Aura Beauty Bar":    "aura_beauty_bar",
            "Silk & Shine":       "silk_and_shine",
            "The Beauty Lounge":  "the_beauty_lounge",
            "Radiance Spa":       "radiance_spa",
            "Blossom Beauty":     "blossom_beauty",
            "Crystal Glow":       "crystal_glow",
            "Serenity Spa":       "serenity_spa",
            "Divine Beauty":      "divine_beauty",
            "Golden Touch":       "golden_touch",
            "Harmony Wellness":   "harmony_wellness",
            "Petal Spa":          "petal_spa"
        ]
        if let id = knownIds[salonName] { return id }
        // Fallback: lowercase + spaces→underscores (covers unlisted salons)
        return salonName.lowercased().replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")
    }
}
