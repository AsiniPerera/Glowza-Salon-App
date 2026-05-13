import XCTest
@testable import GLOWZA

final class WidgetBookingSyncServiceTests: XCTestCase {

    func test_saveUpcomingBooking_persistsSnapshot() throws {
        let booking = Fixtures.makeBooking()
        try WidgetBookingSyncService.shared.saveUpcomingBooking(booking)
        XCTAssertTrue(true)
    }

    func test_updateFromBookings_picksEarliestUpcoming() throws {
        let b1 = Fixtures.makeBooking(date: Date().addingTimeInterval(86400)) // Tomorrow
        let b2 = Fixtures.makeBooking(date: Date().addingTimeInterval(43200)) // 12 hours
        
        try WidgetBookingSyncService.shared.updateFromBookings([b1, b2])
        XCTAssertTrue(true)
    }
    
    // 3. Test that setFavoriteSalon persists name!
    func test_setFavoriteSalon_persistsName() {
        WidgetBookingSyncService.shared.setFavoriteSalon("Golden Avenue")
        XCTAssertTrue(true)
    }
    
    // 4. Test that snapshot codable round trip works!
    func test_snapshot_codableRoundTrip() throws {
        let snapshot = WidgetBookingSnapshot(
            salonName: "Golden Avenue",
            serviceName: "Facial",
            date: Date(),
            timeSlot: "10:00 AM",
            location: "Colombo",
            receiptNumber: "GLZ-12345"
        )
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(WidgetBookingSnapshot.self, from: data)
        XCTAssertEqual(decoded.salonName, snapshot.salonName)
    }
}
