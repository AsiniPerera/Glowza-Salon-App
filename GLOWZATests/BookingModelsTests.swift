// BookingModelsTests.swift
// GLOWZATests

import XCTest
@testable import GLOWZA

final class BookingModelsTests: XCTestCase {

    // MARK: - SalonService

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

    // MARK: - Salon

    func test_salon_defaultIdIsUnique() {
        let a = Fixtures.makeSalon()
        let b = Fixtures.makeSalon()
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - PaymentMethodType

    func test_paymentMethodType_allCasesExist() {
        let all = PaymentMethodType.allCases
        XCTAssertTrue(all.contains(.card))
        XCTAssertTrue(all.contains(.cash))
        XCTAssertTrue(all.contains(.online))
        XCTAssertEqual(all.count, 3)
    }

    // MARK: - BookingDraft

    func test_bookingDraft_defaultDateIsTomorrow() {
        let draft    = BookingDraft(salon: Fixtures.makeSalon())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        XCTAssertLessThan(abs(draft.date.timeIntervalSince(tomorrow)), 5)
    }

    func test_bookingDraft_timeSlotsNotEmpty() {
        XCTAssertFalse(BookingDraft.timeSlots.isEmpty)
    }

    // MARK: - Booking

    func test_booking_generateReceiptNumber_format() {
        let r       = Booking.generateReceiptNumber()
        let numeric = String(r.dropFirst(4))
        XCTAssertTrue(r.hasPrefix("GLZ-"))
        XCTAssertEqual(numeric.count, 5)
        XCTAssertNotNil(Int(numeric))
    }

    // MARK: - SalonCatalog

    func test_salonCatalog_notEmpty() {
        XCTAssertFalse(SalonCatalog.shared.salons.isEmpty)
    }

    func test_salonCatalog_eachSalonHasAtLeastOneService() {
        for salon in SalonCatalog.shared.salons {
            XCTAssertFalse(
                salon.services.isEmpty,
                "Salon '\(salon.name)' should have at least one service"
            )
        }
    }
}
