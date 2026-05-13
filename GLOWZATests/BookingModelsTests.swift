import XCTest
@testable import GLOWZA

final class BookingModelsTests: XCTestCase {

    func test_salonService_storedProperties() {
        let service = Fixtures.makeSalonService(
            name: "Chemical Peel",
            icon: "sparkles",
            duration: "45 min",
            price: 5500,
            category: "Skin",
            benefits: ["Exfoliation", "Brightening"]
        )
        XCTAssertEqual(service.name,     "Chemical Peel")
        XCTAssertEqual(service.icon,     "sparkles")
        XCTAssertEqual(service.duration, "45 min")
        XCTAssertEqual(service.price,    5500)
        XCTAssertEqual(service.category, "Skin")
        XCTAssertEqual(service.benefits, ["Exfoliation", "Brightening"])
    }

    func test_paymentMethodType_allCasesExist() {
        let all = PaymentMethodType.allCases
        XCTAssertTrue(all.contains(.card))
        XCTAssertTrue(all.contains(.cash))
        XCTAssertTrue(all.contains(.online))
        XCTAssertEqual(all.count, 3)
    }

    func test_booking_generateReceiptNumber_format() {
        let r       = Booking.generateReceiptNumber()
        let numeric = String(r.dropFirst(4))
        XCTAssertTrue(r.hasPrefix("GLZ-"))
        XCTAssertEqual(numeric.count, 5)
        XCTAssertNotNil(Int(numeric))
    }

    func test_salonCatalog_notEmpty() {
        XCTAssertFalse(SalonCatalog.shared.salons.isEmpty)
    }
    
    // 5. Test that salon default ID is unique!
    func test_salon_defaultIdIsUnique() {
        let a = Fixtures.makeSalon()
        let b = Fixtures.makeSalon()
        XCTAssertNotEqual(a.id, b.id)
    }
    
    // 6. Test that BookingDraft has time slots!
    func test_bookingDraft_timeSlotsNotEmpty() {
        XCTAssertFalse(BookingDraft.timeSlots.isEmpty)
    }
}
