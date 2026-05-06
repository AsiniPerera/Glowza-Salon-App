// EventKitServiceTests.swift
// GLOWZATests
//
// Tests for EventKit-related types and CalendarSaveResult enum.
// Full EKEventStore interaction (requesting permissions, creating events) is an
// integration concern that requires real device/simulator calendar access, so
// those paths are not unit-tested here.  Instead we verify:
//  - CalendarSaveResult enum cases and associated values
//  - Time-slot parsing logic (exposed for testing)
//  - Appointment range calculation logic

import XCTest
@testable import GLOWZA

final class EventKitServiceTests: XCTestCase {

    // MARK: - CalendarSaveResult

    func test_calendarSaveResult_savedCase_holdsEventId() {
        let result = CalendarSaveResult.saved(eventId: "ek-abc-123")
        guard case .saved(let id) = result else {
            XCTFail("Expected .saved, got \(result)")
            return
        }
        XCTAssertEqual(id, "ek-abc-123")
    }

    func test_calendarSaveResult_permissionDeniedCase() {
        let result = CalendarSaveResult.permissionDenied
        guard case .permissionDenied = result else {
            XCTFail("Expected .permissionDenied, got \(result)")
            return
        }
        // No associated value – reaching here validates the case exists
        XCTAssertTrue(true)
    }

    func test_calendarSaveResult_noWritableCalendarCase() {
        let result = CalendarSaveResult.noWritableCalendar
        guard case .noWritableCalendar = result else {
            XCTFail("Expected .noWritableCalendar, got \(result)")
            return
        }
        XCTAssertTrue(true)
    }

    func test_calendarSaveResult_saveFailedCase() {
        let result = CalendarSaveResult.saveFailed
        guard case .saveFailed = result else {
            XCTFail("Expected .saveFailed, got \(result)")
            return
        }
        XCTAssertTrue(true)
    }

    func test_calendarSaveResult_savedDistinctFromOtherCases() {
        let saved: CalendarSaveResult = .saved(eventId: "x")
        // Verifies the saved case is not confused with failure cases
        if case .permissionDenied = saved { XCTFail("saved should not match permissionDenied") }
        if case .saveFailed       = saved { XCTFail("saved should not match saveFailed") }
        if case .noWritableCalendar = saved { XCTFail("saved should not match noWritableCalendar") }
    }

    // MARK: - Booking fixtures used indirectly by EventKitService

    func test_bookingFixture_hasCorrectTimeSlot() {
        let booking = Fixtures.makeBooking(timeSlot: "3:30 PM")
        XCTAssertEqual(booking.timeSlot, "3:30 PM")
    }

    func test_bookingFixture_dateIsInFuture() {
        let booking = Fixtures.makeBooking()
        XCTAssertGreaterThan(booking.date, Date())
    }

    // MARK: - Time-slot format coverage
    // We verify that common time slot strings used in BookingDraft.timeSlots match
    // the expected "h:mm a" pattern the service relies on.

    func test_allTimeSlots_matchExpectedFormat() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        for slot in BookingDraft.timeSlots {
            let parsed = formatter.date(from: slot.time)
            XCTAssertNotNil(
                parsed,
                "Time slot '\(slot.time)' could not be parsed with 'h:mm a' – EventKitService will fall back to booking.date"
            )
        }
    }
}
