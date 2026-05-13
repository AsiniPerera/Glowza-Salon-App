import XCTest
@testable import GLOWZA

@MainActor
final class BookingStoreTests: XCTestCase {

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

    func test_add_appendsBooking() {
        let booking = Fixtures.makeBooking()
        BookingStore.shared.add(booking)
        XCTAssertEqual(BookingStore.shared.bookings.count, 1)
        XCTAssertEqual(BookingStore.shared.bookings.first?.id, booking.id)
    }

    func test_upcoming_filterReturnOnlyUpcomingBookings() {
        BookingStore.shared.bookings = [
            Fixtures.makeBooking(status: .upcoming),
            Fixtures.makeBooking(status: .completed),
            Fixtures.makeBooking(status: .cancelled)
        ]
        XCTAssertEqual(BookingStore.shared.upcoming.count, 1)
    }

    func test_cancelBooking_changesStatusToCancelled() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]
        BookingStore.shared.cancelBooking(id: booking.id)
        XCTAssertEqual(BookingStore.shared.bookings.first?.status, .cancelled)
    }

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
    
    // 5. Test that cancelled filter returns only cancelled bookings!
    func test_cancelled_filterReturnsOnlyCancelled() {
        BookingStore.shared.bookings = [
            Fixtures.makeBooking(status: .cancelled),
            Fixtures.makeBooking(status: .upcoming)
        ]
        XCTAssertEqual(BookingStore.shared.cancelled.count, 1)
    }
    
    // 6. Test that cancelBooking with unknown ID does nothing!
    func test_cancelBooking_unknownIdDoesNothing() {
        let booking = Fixtures.makeBooking(status: .upcoming)
        BookingStore.shared.bookings = [booking]
        BookingStore.shared.cancelBooking(id: UUID())
        XCTAssertEqual(BookingStore.shared.bookings.first?.status, .upcoming)
    }
}
