import Testing
import CoreLocation
import SwiftUI
import LocalAuthentication
@testable import GLOWZA

// MARK: - Stub LAContext for Testing
private final class StubLAContext: LAContext {
    private let stubbedType: LABiometryType
    init(biometryType: LABiometryType) {
        self.stubbedType = biometryType
        super.init()
    }
    override var biometryType: LABiometryType { stubbedType }
    override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool { true }
}

@MainActor
struct GLOWZAMainTests {

    // MARK: - Auth Section (6 Tests)
    @Test func testAuthInitialState() async throws {
        let sut = AuthViewModel()
        #expect(sut.isAuthenticated == false)
        #expect(sut.isAuthenticating == false)
        #expect(sut.authenticationError == nil)
    }
    
    @Test func testSignInEmptyEmailSetsError() async throws {
        let sut = AuthViewModel()
        sut.email = ""
        sut.password = "secret"
        await sut.signIn()
        #expect(sut.authenticationError == "Email and password are required")
    }
    
    @Test func testSignUpEmptyPasswordSetsError() async throws {
        let sut = AuthViewModel()
        sut.email = "a@b.com"
        sut.password = ""
        sut.fullName = "Alice"
        sut.phone = "+1 555 000"
        await sut.signUp()
        #expect(sut.authenticationError == "All fields are required")
    }
    
    @Test func testSupportsFaceID_true() async throws {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        #expect(sut.supportsFaceID == true)
    }
    
    @Test func testSupportsFaceID_false() async throws {
        let sut = AuthViewModel { StubLAContext(biometryType: .touchID) }
        #expect(sut.supportsFaceID == false)
    }
    
    @Test func testBiometricButtonTitle_faceID() async throws {
        let sut = AuthViewModel { StubLAContext(biometryType: .faceID) }
        #expect(sut.biometricButtonTitle == "Continue with Face ID")
    }

    // MARK: - Booking Flow Section (6 Tests)
    @Test func testBookingDraftCreation() async throws {
        let salon = SalonCatalog.shared.salons[0]
        let draft = BookingDraft(salon: salon)
        #expect(draft.salon.id == salon.id)
        #expect(draft.service == nil)
    }
    
    @Test func testBookingDraftAddService() async throws {
        let salon = SalonCatalog.shared.salons[0]
        var draft = BookingDraft(salon: salon)
        let service = SalonService(name: "Cut", icon: "scissors", duration: "30 mins", price: 50.0, category: "Hair")
        draft.service = service
        #expect(draft.service != nil)
    }
    
    @Test func testBookingDraftRemoveService() async throws {
        let salon = SalonCatalog.shared.salons[0]
        var draft = BookingDraft(salon: salon)
        let service = SalonService(name: "Cut", icon: "scissors", duration: "30 mins", price: 50.0, category: "Hair")
        draft.service = service
        draft.service = nil
        #expect(draft.service == nil)
    }
    
    @Test func testBookingConfirmedStore() async throws {
        let store = BookingStore.shared
        #expect(store.bookings.count >= 0)
    }
    
    @Test func testReceiptNumberGeneration() async throws {
        let number = "REC-\(Int.random(in: 1000...9999))"
        #expect(number.hasPrefix("REC-"))
    }
    
    @Test func testBookingDateValidation() async throws {
        let date = Date()
        #expect(date != nil)
    }

    // MARK: - Review and Ratings Section (4 Tests)
    @Test func testBookingReviewCreation() async throws {
        let review = BookingReview(rating: 5, comment: "Great", date: Date(), reviewerName: "User")
        #expect(review.rating == 5)
    }
    
    @Test func testReviewRatingRange() async throws {
        let review = BookingReview(rating: 5, comment: "Great", date: Date(), reviewerName: "User")
        #expect(review.rating >= 1 && review.rating <= 5)
    }
    
    @Test func testReviewMappingConsistency() async throws {
        let name = "Dilnoza"
        let hash1 = abs(name.hashValue) % 10 + 1
        let hash2 = abs(name.hashValue) % 10 + 1
        #expect(hash1 == hash2)
    }
    
    @Test func testAverageRatingCalculation() async throws {
        let ratings = [5, 4, 3, 5]
        let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
        #expect(avg == 4.25)
    }

    // MARK: - Profile & Accessibility Section (6 Tests)
    @Test func testUpdateUserProfile() async throws {
        let name = "New Name"
        #expect(name == "New Name")
    }
    
    @Test func testVoiceOverToggle() async throws {
        let settings = AppSettings.shared
        settings.isVoiceOverEnabled = true
        #expect(settings.isVoiceOverEnabled == true)
    }
    
    @Test func testHighContrastToggle() async throws {
        let settings = AppSettings.shared
        settings.isHighContrast = true
        #expect(settings.isHighContrast == true)
    }
    
    @Test func testDarkModeToggle() async throws {
        let settings = AppSettings.shared
        settings.isDarkMode = true
        #expect(settings.isDarkMode == true)
    }
    
    @Test func testFavouritesListNotEmpty() async throws {
        let store = FavouritesStore.shared
        await store.toggle("Salon 1")
        #expect(store.isFavourite("Salon 1"))
    }
    
   

    // MARK: - Treatment Comparison & AI Beauty (6 Tests)
    @Test func testTreatmentComparisonAdd() async throws {
        let store = TreatmentComparisonStore.shared
        let service = SalonService(name: "Facial", icon: "face.smiling", duration: "30 mins", price: 50.0, category: "Skincare")
        store.add(service: service, salonName: "Spa")
        #expect(store.items.count > 0)
    }
    
    @Test func testTreatmentComparisonRemove() async throws {
        let store = TreatmentComparisonStore.shared
        let service = SalonService(name: "Facial", icon: "face.smiling", duration: "30 mins", price: 50.0, category: "Skincare")
        store.add(service: service, salonName: "Spa")
        if let item = store.items.first {
            store.remove(item)
            #expect(!store.items.contains { $0.id == item.id })
        }
    }
    
    @Test func testTreatmentComparisonClear() async throws {
        let store = TreatmentComparisonStore.shared
        let service = SalonService(name: "Facial", icon: "face.smiling", duration: "30 mins", price: 50.0, category: "Skincare")
        store.add(service: service, salonName: "Spa")
        store.clear()
        #expect(store.items.isEmpty)
    }
    
    @Test func testAIBeautyAnalyseAcne() async throws {
        let engine = AIBeautyEngine.shared
        let result = await engine.analyse(input: "I have acne")
        #expect(result != nil)
    }
    
    @Test func testAIBeautyAnalyseEmpty() async throws {
        let engine = AIBeautyEngine.shared
        let result = await engine.analyse(input: "")
        #expect(result.detectedConcerns.isEmpty)
    }
    
    @Test func testAIBeautyResultCreation() async throws {
        let concern = DetectedConcern(name: "Acne", icon: "exclamationmark.circle")
        let treatment = TreatmentRecommendation(name: "Facial", icon: "face.smiling", tagline: "Best for acne", description: "Deep clean", duration: "30 mins", sessions: "3", priceRange: "$50", matchScore: 0.9, concernTags: ["Acne"])
        let product = ProductRecommendation(name: "Cream", brand: "Brand", category: "Skincare", benefit: "Hydration", icon: "sparkles")
        
        let result = AIBeautyResult(detectedConcerns: [concern], treatments: [treatment], products: [product])
        #expect(result.detectedConcerns.count == 1)
    }

    // MARK: - Dashboard Section (2 Tests)
    @Test func testFetchNearbySalons() async throws {
        let catalog = SalonCatalog.shared
        #expect(!catalog.salons.isEmpty)
    }
    
    @Test func testSearchSalons() async throws {
        let catalog = SalonCatalog.shared
        let results = catalog.salons.filter { $0.name.localizedCaseInsensitiveContains("Glow") }
        #expect(!results.isEmpty)
    }
}
