// NotificationManagerTests.swift
// GLOWZATests

import XCTest
@testable import GLOWZA

// Notification permission tests removed – hardware/permission dependent.
final class NotificationManagerTests: XCTestCase {

    @MainActor
    func test_NotifyBookingSuccess_AddsToHistory() {
        let manager = NotificationManager.shared
        let initialCount = manager.notificationHistory.count
        
        manager.notifyBookingSuccess(
            serviceName: "Facial",
            salonName: "Golden Avenue",
            time: "10:30 AM",
            date: "May 15, 2026"
        )
        
        XCTAssertEqual(manager.notificationHistory.count, initialCount + 1, "Should record one new notification in history")
        let latest = manager.notificationHistory.first
        XCTAssertEqual(latest?.title, "Booking Confirmed")
        XCTAssertTrue(latest?.subtitle.contains("Facial") ?? false)
    }

    @MainActor
    func test_NotifyPaymentSuccess_AddsToHistory() {
        let manager = NotificationManager.shared
        let initialCount = manager.notificationHistory.count
        
        manager.notifyPaymentSuccess(
            amount: 3500.0,
            method: "Visa Card",
            receipt: "RC-998877"
        )
        
        XCTAssertEqual(manager.notificationHistory.count, initialCount + 1)
        let latest = manager.notificationHistory.first
        XCTAssertEqual(latest?.title, "Payment Successful")
        XCTAssertTrue(latest?.subtitle.contains("RC-998877") ?? false)
    }
}
