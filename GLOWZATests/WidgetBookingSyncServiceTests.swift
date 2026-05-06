// WidgetBookingSyncServiceTests.swift
// GLOWZATests
//
// Tests for WidgetBookingSyncService and WidgetBookingSnapshot:
// - snapshot Codable round-trip
// - saveUpcomingBooking persists data
// - clearUpcomingBooking removes data
// - updateFromBookings picks the earliest upcoming booking
// - setFavoriteSalon persists salon name
//
// NOTE: In the test environment the App Group suite is unavailable, so the
// service falls back to UserDefaults.standard.  All keys are cleaned up in
// tearDown to avoid polluting other tests.

import XCTest
@testable import GLOWZA

final class WidgetBookingSyncServiceTests: XCTestCase {

    private let service = WidgetBookingSyncService.shared
    private let snapshotKey     = "widget_upcoming_booking"
    private let favSalonKey     = "widget_favorite_salon"

    /// The UserDefaults suite actually used at runtime (App Group or .standard).
    private var defaults: UserDefaults {
        UserDefaults(suiteName: WidgetBookingSyncService.appGroupId) ?? .standard
    }

    override func setUp() {
        super.setUp()
        defaults.removeObject(forKey: snapshotKey)
        defaults.removeObject(forKey: favSalonKey)
    }

    override func tearDown() {
        defaults.removeObject(forKey: snapshotKey)
        defaults.removeObject(forKey: favSalonKey)
        super.tearDown()
    }

    // MARK: - WidgetBookingSnapshot Codable

    func test_snapshot_codableRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = WidgetBookingSnapshot(
            salonName:     "Luxe Spa",
            serviceName:   "Facial",
            date:          date,
            timeSlot:      "10:00 AM",
            location:      "Colombo",
            receiptNumber: "GLZ-99001"
        )
        let data    = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data)

        XCTAssertEqual(decoded.salonName,     "Luxe Spa")
        XCTAssertEqual(decoded.serviceName,   "Facial")
        XCTAssertEqual(decoded.timeSlot,      "10:00 AM")
        XCTAssertEqual(decoded.location,      "Colombo")
        XCTAssertEqual(decoded.receiptNumber, "GLZ-99001")
        XCTAssertEqual(decoded.date,          date)
    }

    // MARK: - saveUpcomingBooking

    func test_saveUpcomingBooking_persistsSnapshot() throws {
        let booking = Fixtures.makeBooking(
            salon: Fixtures.makeSalon(name: "Glow Studio"),
            timeSlot: "2:00 PM"
        )
        service.saveUpcomingBooking(booking)

        let data = defaults.data(forKey: snapshotKey)
        XCTAssertNotNil(data, "Snapshot data should be written to UserDefaults")

        let snapshot = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data!)
        XCTAssertEqual(snapshot.salonName, "Glow Studio")
        XCTAssertEqual(snapshot.timeSlot,  "2:00 PM")
    }

    func test_saveUpcomingBooking_setsFavoriteSalonIfEmpty() {
        defaults.removeObject(forKey: favSalonKey)
        let booking = Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "First Salon"))
        service.saveUpcomingBooking(booking)
        XCTAssertEqual(defaults.string(forKey: favSalonKey), "First Salon")
    }

    func test_saveUpcomingBooking_doesNotOverwriteExistingFavorite() {
        defaults.set("Existing Favorite", forKey: favSalonKey)
        let booking = Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "New Salon"))
        service.saveUpcomingBooking(booking)
        XCTAssertEqual(defaults.string(forKey: favSalonKey), "Existing Favorite")
    }

    // MARK: - clearUpcomingBooking

    func test_clearUpcomingBooking_removesSnapshot() {
        let booking = Fixtures.makeBooking()
        service.saveUpcomingBooking(booking)
        XCTAssertNotNil(defaults.data(forKey: snapshotKey))

        service.clearUpcomingBooking()
        XCTAssertNil(defaults.data(forKey: snapshotKey))
    }

    // MARK: - updateFromBookings

    func test_updateFromBookings_picksEarliestUpcoming() throws {
        var dateComponents = DateComponents()
        dateComponents.year  = 2026
        dateComponents.month = 6
        let cal = Calendar.current

        let dateFar  = cal.date(from: { var c = dateComponents; c.day = 20; return c }())!
        let dateNear = cal.date(from: { var c = dateComponents; c.day = 5; return c }())!

        let bookingFar  = Fixtures.makeBooking(
            salon: Fixtures.makeSalon(name: "Far Salon"),
            date: dateFar,
            timeSlot: "9:00 AM",
            status: .upcoming
        )
        let bookingNear = Fixtures.makeBooking(
            salon: Fixtures.makeSalon(name: "Near Salon"),
            date: dateNear,
            timeSlot: "9:00 AM",
            status: .upcoming
        )

        service.updateFromBookings([bookingFar, bookingNear])

        let data     = defaults.data(forKey: snapshotKey)
        XCTAssertNotNil(data)
        let snapshot = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data!)
        XCTAssertEqual(snapshot.salonName, "Near Salon", "Should persist the nearest upcoming booking")
    }

    func test_updateFromBookings_excludesCancelledAndCompleted() {
        let cancelled = Fixtures.makeBooking(status: .cancelled)
        let completed = Fixtures.makeBooking(status: .completed)
        service.updateFromBookings([cancelled, completed])
        XCTAssertNil(defaults.data(forKey: snapshotKey), "No upcoming → snapshot should be nil")
    }

    func test_updateFromBookings_emptyList_clearsSnapshot() {
        service.saveUpcomingBooking(Fixtures.makeBooking())
        service.updateFromBookings([])
        XCTAssertNil(defaults.data(forKey: snapshotKey))
    }

    // MARK: - setFavoriteSalon

    func test_setFavoriteSalon_persistsName() {
        service.setFavoriteSalon("Top Salon")
        XCTAssertEqual(defaults.string(forKey: favSalonKey), "Top Salon")
    }

    func test_setFavoriteSalon_overwritesExisting() {
        service.setFavoriteSalon("Old Salon")
        service.setFavoriteSalon("New Salon")
        XCTAssertEqual(defaults.string(forKey: favSalonKey), "New Salon")
    }
}
