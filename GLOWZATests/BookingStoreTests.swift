// BookingStoreTests.swift
// GLOWZATests
//
// Tests for BookingStore: add, cancel, review, filtered computed properties,
// and reviews-by-salon lookup.
//
// NOTE: BookingStore is @MainActor, so the test class is also annotated
// @MainActor.  All test methods run on the main actor automatically.

import XCTest
@testable import GLOWZA

@MainActor
final class BookingStoreTests: XCTestCase {

    // Fresh isolated state per test – we temporarily swap the shared store's
    // bookings array and restore it in tearDown.
    private var savedBookings: [Booking] = []

    override func setUp() {
        super.setUp()
        savedBookings = BookingStore.shared.bookings
        BookingStore.shared.bookings = []
    }

    override func tearDown() {
        BookingStore.shared.bookings = savedBookings
        super.tearDown()
    }

    // MARK: - add(_:)

    func test_add_appendsBooking() {
        let booking = Fixtures.makeBooking()
        BookingStore.shared.add(booking)
        XCTAssertEqual(BookingStore.shared.bookings.count, 1)
        XCTAssertEqual(BookingStore.shared.bookings.first?.id, booking.id)
    }

    func test_add_multipleBookings() {
        let b1 = Fixtures.makeBooking()
        let b2 = Fixtures.makeBooking()
        BookingStore.shared.add(b1)
        BookingStore.shared.add(b2)
        XCTAssertEqual(BookingStore.shared.bookings.count, 2)
    }

    // MARK: - Computed Filters

    func test_upcoming_filterReturnOnlyUpcomingBookings() {
        let upcoming  = Fixtures.makeBooking(status: .upcoming)
        let completed = Fixtures.makeBooking(status: .completed)
        let cancelled = Fixtures.makeBooking(status: .cancelled)
        BookingStore.shared.bookings = [upcoming, completed, cancelled]

        XCTAssertEqual(BookingStore.shared.upcoming.count,  1)
        XCTAssertEqual(BookingStore.shared.upcoming.first?.id, upcoming.id)
    }

    func test_completed_filterReturnsOnlyCompleted() {
        let b1 = Fixtures.makeBooking(status: .completed)
        let b2 = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [b1, b2]

        XCTAssertEqual(BookingStore.shared.completed.count, 1)
        XCTAssertEqual(BookingStore.shared.completed.first?.id, b1.id)
    }

    func test_cancelled_filterReturnsOnlyCancelled() {
        let b1 = Fixtures.makeBooking(status: .cancelled)
        let b2 = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [b1, b2]

        XCTAssertEqual(BookingStore.shared.cancelled.count, 1)
        XCTAssertEqual(BookingStore.shared.cancelled.first?.id, b1.id)
    }

    func test_emptyStore_allFiltersReturnEmpty() {
        XCTAssertTrue(BookingStore.shared.upcoming.isEmpty)
        XCTAssertTrue(BookingStore.shared.completed.isEmpty)
        XCTAssertTrue(BookingStore.shared.cancelled.isEmpty)
    }

    // MARK: - cancelBooking(id:)

    func test_cancelBooking_changesStatusToCancelled() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]

        BookingStore.shared.cancelBooking(id: booking.id)

        XCTAssertEqual(BookingStore.shared.bookings.first?.status, .cancelled)
    }

    func test_cancelBooking_unknownIdDoesNothing() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]

        BookingStore.shared.cancelBooking(id: UUID())   // random unknown id

        XCTAssertEqual(BookingStore.shared.bookings.first?.status, .upcoming)
    }

    func test_cancelBooking_onlyTargetedBookingChanges() {
        let b1 = Fixtures.makeBooking(status: .upcoming)
        let b2 = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [b1, b2]

        BookingStore.shared.cancelBooking(id: b1.id)

        let statuses = BookingStore.shared.bookings.map { $0.status }
        XCTAssertEqual(statuses[0], .cancelled)
        XCTAssertEqual(statuses[1], .upcoming)
    }

    // MARK: - addReview(bookingID:review:)

    func test_addReview_setsReviewOnBooking() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]

        let review = Fixtures.makeReview(rating: 5, comment: "Loved it!", reviewerName: "Jane")
        BookingStore.shared.addReview(bookingID: booking.id, review: review)

        let stored = BookingStore.shared.bookings.first?.review
        XCTAssertNotNil(stored)
        XCTAssertEqual(stored?.rating, 5)
        XCTAssertEqual(stored?.comment, "Loved it!")
        XCTAssertEqual(stored?.reviewerName, "Jane")
    }

    func test_addReview_changesStatusToCompleted() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]

        BookingStore.shared.addReview(bookingID: booking.id, review: Fixtures.makeReview())

        XCTAssertEqual(BookingStore.shared.bookings.first?.status, .completed)
    }

    func test_addReview_unknownIdDoesNotCrash() {
        BookingStore.shared.bookings = []
        // Should silently no-op
        BookingStore.shared.addReview(bookingID: UUID(), review: Fixtures.makeReview())
        XCTAssertTrue(BookingStore.shared.bookings.isEmpty)
    }

    // MARK: - reviews(forSalon:)

    func test_reviewsForSalon_returnsMatchingReviews() {
        let salonA = Fixtures.makeSalon(name: "Salon A")
        let salonB = Fixtures.makeSalon(name: "Salon B")

        var b1 = Fixtures.makeBooking(salon: salonA, status: .completed)
        b1.review = Fixtures.makeReview(comment: "Great A")
        var b2 = Fixtures.makeBooking(salon: salonB, status: .completed)
        b2.review = Fixtures.makeReview(comment: "Great B")
        var b3 = Fixtures.makeBooking(salon: salonA, status: .completed)
        b3.review = Fixtures.makeReview(comment: "Also A")

        BookingStore.shared.bookings = [b1, b2, b3]

        let reviews = BookingStore.shared.reviews(forSalon: "Salon A")
        XCTAssertEqual(reviews.count, 2)
        let comments = reviews.map { $0.comment }
        XCTAssertTrue(comments.contains("Great A"))
        XCTAssertTrue(comments.contains("Also A"))
    }

    func test_reviewsForSalon_noMatchReturnsEmpty() {
        let booking = Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "Spa X"))
        BookingStore.shared.bookings = [booking]
        let reviews = BookingStore.shared.reviews(forSalon: "Unknown Salon")
        XCTAssertTrue(reviews.isEmpty)
    }

    func test_reviewsForSalon_excludesBookingsWithoutReview() {
        let booking = Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "Spa Y"), status: .upcoming)
        // No review set
        BookingStore.shared.bookings = [booking]
        let reviews = BookingStore.shared.reviews(forSalon: "Spa Y")
        XCTAssertTrue(reviews.isEmpty)
    }
}
