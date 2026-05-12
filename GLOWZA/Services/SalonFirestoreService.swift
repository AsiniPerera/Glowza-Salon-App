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
    var userAvatarBase64: String?
}

// MARK: - Firestore Salon Model
struct FirestoreSalon: Codable {
    var id: String
    var name: String
    var location: String
    var distance: String
    var rating: Double
    var reviewCount: Int
    var score: Double
    var categories: [String]
    var about: String
    var phone: String
    var openHours: String
    var updatedAt: Date?
}

// MARK: - Salon Firestore Service
@MainActor
final class SalonFirestoreService {

    static let shared = SalonFirestoreService()
    private init() {}

    private let db = Firestore.firestore()
    private var cachedSalons: [FirestoreSalon]?

    // MARK: - Upload Full Salon Catalog to Firestore
    /// Saves all salons from SalonCatalog into the `salons` Firestore collection.
    /// Uses merge: true so existing data (e.g. live ratings) is NOT overwritten.
    func uploadSalonCatalog() async {
        let salons = SalonCatalog.shared.salons
        for salon in salons {
            let id = salonId(for: salon.name)
            let categories = Array(Set(salon.services.map { $0.category }))

            // Build service sub-documents
            let serviceDocs: [[String: Any]] = salon.services.map { s in
                ["name": s.name, "icon": s.icon, "duration": s.duration,
                 "price": s.price, "category": s.category, "benefits": s.benefits]
            }

            let data: [String: Any] = [
                "id":          id,
                "name":        salon.name,
                "location":    salon.location,
                "distance":    salon.distance,
                "rating":      salon.rating,
                "reviewCount": salon.reviewCount,
                "score":       salon.score,
                "categories":  categories,
                "services":    serviceDocs,
                "about":       salon.about,
                "phone":       salon.phone,
                "openHours":   salon.openHours,
                "updatedAt":   Timestamp()
            ]
            do {
                try await db.collection("salons").document(id).setData(data, merge: true)
                print("✅ Salon saved to Firestore: \(salon.name)")
            } catch {
                print("❌ Failed to save salon \(salon.name): \(error)")
            }
        }
    }

    // MARK: - Fetch All Salons from Firestore
    func fetchAllSalons(forceRefresh: Bool = false) async throws -> [FirestoreSalon] {
        if !forceRefresh, let cached = cachedSalons {
            return cached
        }
        let snapshot = try await db.collection("salons").getDocuments()
        let salons = snapshot.documents.compactMap { doc -> FirestoreSalon? in
            let d = doc.data()
            guard let id       = d["id"] as? String,
                  let name     = d["name"] as? String,
                  let location = d["location"] as? String else { return nil }
            return FirestoreSalon(
                id:          id,
                name:        name,
                location:    location,
                distance:    d["distance"]    as? String ?? "",
                rating:      d["rating"]      as? Double ?? 0,
                reviewCount: d["reviewCount"] as? Int    ?? 0,
                score:       d["score"]       as? Double ?? 0,
                categories:  d["categories"]  as? [String] ?? [],
                about:       d["about"]       as? String ?? "",
                phone:       d["phone"]       as? String ?? "",
                openHours:   d["openHours"]   as? String ?? "",
                updatedAt:   (d["updatedAt"] as? Timestamp)?.dateValue()
            )
        }
        self.cachedSalons = salons
        return salons
    }

    // MARK: - Upsert Individual Salon (used when rating/review changes)
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

        // Only include non-empty fields so a partial call (e.g. rating update)
        // never overwrites existing location/distance/categories in Firestore.
        var data: [String: Any] = [
            "id":          id,
            "name":        name,
            "rating":      rating,
            "reviewCount": reviewCount,
            "score":       score,
            "updatedAt":   Timestamp()
        ]
        if !location.isEmpty    { data["location"]   = location }
        if !distance.isEmpty    { data["distance"]   = distance }
        if !categories.isEmpty  { data["categories"] = categories }

        try await db.collection("salons").document(id).setData(data, merge: true)
    }

    // MARK: - Fetch Reviews for a Salon
    func fetchReviews(forSalonId salonId: String) async throws -> [FirestoreSalonReview] {
        let snapshot = try await db.collection("salonReviews")
            .whereField("salonId", isEqualTo: salonId)
            .getDocuments()
        
        let reviews = try snapshot.documents.compactMap { try $0.data(as: FirestoreSalonReview.self) }
        return reviews.sorted(by: { $0.createdAt > $1.createdAt })
    }

    // MARK: - Add Salon Review
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
            "createdAt": Timestamp(),
            "userAvatarBase64": AuthService.shared.currentUserProfile?.avatarBase64 ?? ""
        ]
        try await db.collection("salonReviews").document(reviewId).setData(data)
    }

    // MARK: - Update Salon Review
    func updateReview(reviewId: String, rating: Int, comment: String) async throws {
        try await db.collection("salonReviews").document(reviewId).updateData([
            "rating": rating,
            "comment": comment,
            "updatedAt": Timestamp()
        ])
    }

    // MARK: - Seed Mock Reviews
    /// Populates the database with 8 high-quality reviews for each of the main salons.
    func seedMockReviews() async {
        let salonIds = [
            "haley_avenue", "glow_studio", "luxe_aesthetics", "velvet_touch",
            "aura_beauty_bar", "silk_and_shine", "the_beauty_lounge", "radiance_spa",
            "blossom_beauty", "crystal_glow", "serenity_spa", "divine_beauty",
            "golden_touch", "harmony_wellness", "petal_spa"
        ]
        let mockUsers = ["Dilnoza R.", "Amara S.", "Priya K.", "John D.", "Sarah W.", "Michael B.", "Elena G.", "Raj T.", "Sophia L.", "Kevin M."]
        let comments = [
            "Absolutely loved the facial treatment! Skin is glowing.",
            "Professional staff, clean environment. Will return.",
            "Best chemical peel I've ever had. Highly recommend!",
            "Great service, but a bit of a wait. Overall good experience.",
            "Luxury at its best. The ambiance is so relaxing.",
            "Expert stylists who really listen to what you want.",
            "The laser treatment was virtually painless. Amazing!",
            "Incredible results in just one session. Love it!",
            "Fantastic attention to detail and very friendly staff.",
            "The best salon experience in Colombo, hands down."
        ]

        for sId in salonIds {
            do {
                for i in 0..<10 {
                    let reviewId = "MOCK_REVIEW_\(sId)_\(i)"
                    let data: [String: Any] = [
                        "id": reviewId,
                        "salonId": sId,
                        "userId": "DEMO_USER_\(i)",
                        "userName": mockUsers[i % mockUsers.count],
                        "rating": Int.random(in: 4...5),
                        "comment": comments[i % comments.count],
                        "createdAt": Timestamp(date: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date())
                    ]
                    try await db.collection("salonReviews").document(reviewId).setData(data, merge: true)
                }
                print("✅ Seeded/Updated 10 reviews for \(sId)")
            } catch {
                print("❌ Failed to seed reviews for \(sId): \(error)")
            }
        }
    }

    // MARK: - Map salon display name → Firestore salonId
    func salonId(for salonName: String) -> String {
        let knownIds: [String: String] = [
            "Golden Avenue":       "haley_avenue",
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
        return salonName.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "&", with: "and")
    }
}
