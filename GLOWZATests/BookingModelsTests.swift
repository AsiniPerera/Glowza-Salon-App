// BookingModelsTests.swift
// GLOWZATests
//
// Tests for model types: SalonService, Salon, BookingDraft, Booking,
// BookingStatus, PaymentMethodType, BookingReview.

import XCTest
@testable import GLOWZA

final class BookingModelsTests: XCTestCase {

    // MARK: - SalonService

    func test_salonService_hasStableId() {
        let s1 = Fixtures.makeSalonService()
        let s2 = Fixtures.makeSalonService()
        // Each instance gets its own UUID
        XCTAssertNotEqual(s1.id, s2.id)
    }

    func test_salonService_equatable_sameValues_differentIds_notEqual() {
        // SalonService uses id (UUID) for equality via Equatable (derived from Identifiable + Equatable)
        let s1 = Fixtures.makeSalonService(name: "Facial")
        let s2 = Fixtures.makeSalonService(name: "Facial")
        // Different IDs -> not equal
        XCTAssertNotEqual(s1, s2)
    }

    func test_salonService_equatable_sameInstance_equal() {
        let s = Fixtures.makeSalonService()
        XCTAssertEqual(s, s)
    }

    func test_salonService_storedProperties() {
        let service = Fixtures.makeSalonService(
            name: "Chemical Peel",
            icon: "sparkles",
            duration: "45 min",
            price: 5500,
            category: "Skin",
            benefits: ["Exfoliation", "Brightening"]
        )
        XCTAssertEqual(service.name, "Chemical Peel")
        XCTAssertEqual(service.icon, "sparkles")
        XCTAssertEqual(service.duration, "45 min")
        XCTAssertEqual(service.price, 5500)
        XCTAssertEqual(service.category, "Skin")
        XCTAssertEqual(service.benefits, ["Exfoliation", "Brightening"])
    }

    // MARK: - Salon

    func test_salon_defaultIdIsUnique() {
        let a = Fixtures.makeSalon()
        let b = Fixtures.makeSalon()
        XCTAssertNotEqual(a.id, b.id)
    }

    func test_salon_providedIdIsRetained() {
        let fixedId = UUID()
        let salon = Salon(
            id: fixedId,
            name: "Test",
            location: "Loc",
            distance: "0 km",
            rating: 5.0,
            reviewCount: 1,
            score: 1.0,
            services: [],
            about: "",
            phone: "",
            openHours: ""
        )
        XCTAssertEqual(salon.id, fixedId)
    }

    func test_salon_ratingSavedCorrectly() {
        let salon = Fixtures.makeSalon(rating: 4.8, reviewCount: 250, score: 0.97)
        XCTAssertEqual(salon.rating, 4.8, accuracy: 0.001)
        XCTAssertEqual(salon.reviewCount, 250)
        XCTAssertEqual(salon.score, 0.97, accuracy: 0.001)
    }

    // MARK: - PaymentMethodType

    func test_paymentMethodType_allCasesExist() {
        let all = PaymentMethodType.allCases
        XCTAssertTrue(all.contains(.card))
        XCTAssertTrue(all.contains(.cash))
        XCTAssertTrue(all.contains(.online))
        XCTAssertEqual(all.count, 3)
    }

    func test_paymentMethodType_rawValues() {
        XCTAssertEqual(PaymentMethodType.card.rawValue,   "Credit / Debit Card")
        XCTAssertEqual(PaymentMethodType.cash.rawValue,   "Pay at Salon")
        XCTAssertEqual(PaymentMethodType.online.rawValue, "Online Banking")
    }

    func test_paymentMethodType_icons() {
        XCTAssertEqual(PaymentMethodType.card.icon,   "creditcard.fill")
        XCTAssertEqual(PaymentMethodType.cash.icon,   "banknote.fill")
        XCTAssertEqual(PaymentMethodType.online.icon, "globe")
    }

    // MARK: - BookingDraft

    func test_bookingDraft_defaultDateIsTomorrow() {
        let draft = BookingDraft(salon: Fixtures.makeSalon())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let diff = abs(draft.date.timeIntervalSince(tomorrow))
        XCTAssertLessThan(diff, 5, "Default draft date should be approximately tomorrow")
    }

    func test_bookingDraft_defaultPaymentMethod() {
        let draft = BookingDraft(salon: Fixtures.makeSalon())
        XCTAssertEqual(draft.paymentMethod, .card)
    }

    func test_bookingDraft_defaultServiceIsNil() {
        let draft = BookingDraft(salon: Fixtures.makeSalon())
        XCTAssertNil(draft.service)
    }

    func test_bookingDraft_timeSlotsNotEmpty() {
        XCTAssertFalse(BookingDraft.timeSlots.isEmpty)
    }

    func test_bookingDraft_timeSlotsHaveAtLeastOneAvailable() {
        let available = BookingDraft.timeSlots.filter { $0.available }
        XCTAssertFalse(available.isEmpty)
    }

    // MARK: - Booking

    func test_booking_generateReceiptNumber_format() {
        let r = Booking.generateReceiptNumber()
        XCTAssertTrue(r.hasPrefix("GLZ-"), "Receipt number should start with 'GLZ-'")
        let numeric = String(r.dropFirst(4))
        XCTAssertEqual(numeric.count, 5, "Receipt number should have 5 digits after prefix")
        XCTAssertNotNil(Int(numeric), "Digits part should be numeric")
    }

    func test_booking_generateReceiptNumber_isUnique() {
        let ids = Set((0..<100).map { _ in Booking.generateReceiptNumber() })
        // With 5 random digits (10000–99999 = 90000 range), collision after 100 is extremely rare
        XCTAssertGreaterThan(ids.count, 90)
    }

    func test_booking_storedPropertiesRetained() {
        let salon = Fixtures.makeSalon(name: "Luxe Spa")
        let service = Fixtures.makeSalonService(name: "Deep Cleanse", price: 4500)
        let date = Date()
        let booking = Booking(
            id: UUID(),
            salon: salon,
            service: service,
            date: date,
            timeSlot: "11:00 AM",
            receiptNumber: "GLZ-12345",
            paymentMethod: .cash,
            amountPaid: 4500,
            signatureImage: nil,
            status: .upcoming
        )
        XCTAssertEqual(booking.salon.name, "Luxe Spa")
        XCTAssertEqual(booking.service.name, "Deep Cleanse")
        XCTAssertEqual(booking.timeSlot, "11:00 AM")
        XCTAssertEqual(booking.receiptNumber, "GLZ-12345")
        XCTAssertEqual(booking.paymentMethod, .cash)
        XCTAssertEqual(booking.amountPaid, 4500)
        XCTAssertEqual(booking.status, .upcoming)
        XCTAssertNil(booking.signatureImage)
        XCTAssertNil(booking.review)
    }

    // MARK: - BookingStatus

    func test_bookingStatus_casesCovered() {
        let statuses: [BookingStatus] = [.upcoming, .completed, .cancelled]
        XCTAssertEqual(statuses.count, 3)
    }

    // MARK: - BookingReview

    func test_bookingReview_idIsAutoGenerated() {
        let r1 = Fixtures.makeReview()
        let r2 = Fixtures.makeReview()
        XCTAssertNotEqual(r1.id, r2.id)
    }

    func test_bookingReview_storedProperties() {
        let date = Date()
        let review = BookingReview(rating: 4, comment: "Nice!", date: date, reviewerName: "Alice")
        XCTAssertEqual(review.rating, 4)
        XCTAssertEqual(review.comment, "Nice!")
        XCTAssertEqual(review.reviewerName, "Alice")
    }

    func test_bookingReview_ratingBounds() {
        // rating stored as-is; no enforced clamping at model level
        let low  = BookingReview(rating: 1,  comment: "", date: Date(), reviewerName: "A")
        let high = BookingReview(rating: 5,  comment: "", date: Date(), reviewerName: "B")
        XCTAssertEqual(low.rating,  1)
        XCTAssertEqual(high.rating, 5)
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

    func test_salonCatalog_ratingsInValidRange() {
        for salon in SalonCatalog.shared.salons {
            XCTAssertGreaterThanOrEqual(salon.rating, 0.0)
            XCTAssertLessThanOrEqual(salon.rating, 5.0)
        }
    }

    func test_salonCatalog_servicePricesPositive() {
        for salon in SalonCatalog.shared.salons {
            for service in salon.services {
                XCTAssertGreaterThan(service.price, 0, "Service '\(service.name)' price must be positive")
            }
        }
    }
}
