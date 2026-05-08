// WidgetBookingSyncServiceTests.swift
// GLOWZATests

import XCTest
@testable import GLOWZA

final class WidgetBookingSyncServiceTests: XCTestCase {

    private let service     = WidgetBookingSyncService.shared
    private let snapshotKey = "widget_upcoming_booking"
    private let favSalonKey = "widget_favorite_salon"

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

    // MARK: - Codable round-trip

    func test_snapshot_codableRoundTrip() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = WidgetBookingSnapshot(
            salonName: "Luxe Spa", serviceName: "Facial",
            date: date, timeSlot: "10:00 AM",
            location: "Colombo", receiptNumber: "GLZ-99001"
        )
        let decoded = try JSONDecoder().decode(
            WidgetBookingSnapshot.self,
            from: JSONEncoder().encode(snapshot)
        )
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
        XCTAssertNotNil(data)
        let snapshot = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data!)
        XCTAssertEqual(snapshot.salonName, "Glow Studio")
        XCTAssertEqual(snapshot.timeSlot,  "2:00 PM")
    }

   

    // MARK: - updateFromBookings

    func test_updateFromBookings_picksEarliestUpcoming() throws {
        let cal = Calendar.current
        var c   = DateComponents(); c.year = 2026; c.month = 6
        c.day = 20; let dateFar  = cal.date(from: c)!
        c.day = 5;  let dateNear = cal.date(from: c)!

        service.updateFromBookings([
            Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "Far Salon"),
                                 date: dateFar,  timeSlot: "9:00 AM", status: .upcoming),
            Fixtures.makeBooking(salon: Fixtures.makeSalon(name: "Near Salon"),
                                 date: dateNear, timeSlot: "9:00 AM", status: .upcoming)
        ])

        let data     = defaults.data(forKey: snapshotKey)
        XCTAssertNotNil(data)
        let snapshot = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data!)
        XCTAssertEqual(snapshot.salonName, "Near Salon")
    }

    // MARK: - setFavoriteSalon

    func test_setFavoriteSalon_persistsName() {
        service.setFavoriteSalon("Top Salon")
        XCTAssertEqual(defaults.string(forKey: favSalonKey), "Top Salon")
    }
}
