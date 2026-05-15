import XCTest
import FirebaseFirestore
@testable import GLOWZA

@MainActor
final class GlowzaIntegrationTests: XCTestCase {

    // MARK: - Salon Identification Tests
    func test_SalonIdGeneration_IsConsistent() {
        let service = SalonFirestoreService.shared
        
        let id1 = service.salonId(for: "Golden Avenue")
        let id2 = service.salonId(for: "GOLDEN AVENUE ")
        
        XCTAssertEqual(id1, "golden_avenue", "Slug should be lowercase and underscored")
        XCTAssertEqual(id1, id2, "Slugs should be consistent despite casing and whitespace")
    }

    // MARK: - Review Model & Sync Tests
    func test_ReviewData_PreservesSocialContext() {
        let testUID = "user_abc_123"
        let review = FirestoreSalonReview(
            id: UUID().uuidString,
            salonId: "golden_avenue",
            userId: testUID,
            userName: "Anuki",
            rating: 5,
            comment: "Loved the chemical peel!",
            skinType: "Dry & Sensitive",
            createdAt: Date(),
            userAvatarBase64: "base64_sample_data"
        )
        
        XCTAssertEqual(review.userId, testUID)
        XCTAssertEqual(review.userName, "Anuki")
        XCTAssertEqual(review.skinType, "Dry & Sensitive")
    }

    // MARK: - Date & Time Logic Tests
    func test_DateFormatting_IsConsistentGlobally() {
        let date = Date(timeIntervalSince1970: 1778818200) // approx May 2026
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dateString = formatter.string(from: date)
        XCTAssertEqual(dateString, "May 15, 2026")
    }
}
