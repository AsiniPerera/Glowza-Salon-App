// NotificationManagerTests.swift
// GLOWZATests
//
// Tests for NotificationManager and NotificationItem:
// - NotificationItem model creation, Codable round-trip, type enum
// - NotificationManager: showNotification, dismissAll, history management

import XCTest
@testable import GLOWZA

final class NotificationManagerTests: XCTestCase {

    private var manager: NotificationManager!

    override func setUp() {
        super.setUp()
        manager = NotificationManager.shared
        manager.dismissAll()
        manager.clearAllHistory()
    }

    override func tearDown() {
        manager.dismissAll()
        manager.clearAllHistory()
        super.tearDown()
    }

    // MARK: - NotificationItem model

    func test_notificationItem_init_setsProperties() {
        let item = NotificationItem(
            title: "Test Title",
            subtitle: "Test Subtitle",
            icon: "bell.fill",
            type: .success
        )
        XCTAssertEqual(item.title,    "Test Title")
        XCTAssertEqual(item.subtitle, "Test Subtitle")
        XCTAssertEqual(item.icon,     "bell.fill")
        XCTAssertEqual(item.type,     .success)
    }

    func test_notificationItem_uniqueIds() {
        let a = NotificationItem(title: "A", subtitle: "", icon: "star", type: .info)
        let b = NotificationItem(title: "A", subtitle: "", icon: "star", type: .info)
        XCTAssertNotEqual(a.id, b.id)
    }

    func test_notificationItem_defaultTimestampIsNow() {
        let before = Date()
        let item   = NotificationItem(title: "T", subtitle: "S", icon: "x", type: .info)
        let after  = Date()
        XCTAssertGreaterThanOrEqual(item.timestamp, before)
        XCTAssertLessThanOrEqual(item.timestamp,    after)
    }

    // MARK: - NotificationItem Codable

    func test_notificationItem_codableRoundTrip() throws {
        let original = NotificationItem(
            title: "Booking Confirmed",
            subtitle: "Facial • Spa A • Tomorrow",
            icon: "checkmark.circle.fill",
            type: .success
        )
        let data    = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NotificationItem.self, from: data)

        XCTAssertEqual(decoded.id,       original.id)
        XCTAssertEqual(decoded.title,    original.title)
        XCTAssertEqual(decoded.subtitle, original.subtitle)
        XCTAssertEqual(decoded.icon,     original.icon)
        XCTAssertEqual(decoded.type,     original.type)
    }

    func test_notificationType_allTypesEncodeDecodeCorrectly() throws {
        let types: [NotificationItem.NotificationType] = [.success, .info, .error, .warning]
        for type in types {
            let item = NotificationItem(title: "T", subtitle: "S", icon: "i", type: type)
            let data = try JSONEncoder().encode(item)
            let back = try JSONDecoder().decode(NotificationItem.self, from: data)
            XCTAssertEqual(back.type, type, "Round-trip failed for type: \(type.rawValue)")
        }
    }

    // MARK: - NotificationManager.showNotification

    func test_showNotification_addsToActiveNotifications() {
        let item = NotificationItem(title: "X", subtitle: "Y", icon: "z", type: .info)
        // showNotification dispatches on main async; we wait for it.
        let expectation = expectation(description: "notification added")

        manager.showNotification(item, duration: 60)  // long duration so it doesn't auto-dismiss

        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(manager.notifications.contains { $0.id == item.id })
    }

    func test_showNotification_addsToHistory() {
        let item = NotificationItem(title: "History", subtitle: "", icon: "bell", type: .success)
        let expectation = expectation(description: "history updated")

        manager.showNotification(item, duration: 60)

        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(manager.notificationHistory.contains { $0.id == item.id })
    }

    // MARK: - NotificationManager.dismissAll

    func test_dismissAll_clearsActiveNotifications() {
        let expect1 = expectation(description: "added")
        let item = NotificationItem(title: "D", subtitle: "", icon: "x", type: .warning)
        manager.showNotification(item, duration: 60)
        DispatchQueue.main.async { expect1.fulfill() }
        wait(for: [expect1], timeout: 1.0)

        manager.dismissAll()

        let expect2 = expectation(description: "dismissed")
        DispatchQueue.main.async { expect2.fulfill() }
        wait(for: [expect2], timeout: 1.0)

        XCTAssertTrue(manager.notifications.isEmpty)
    }

    // MARK: - History management

    func test_clearAllHistory_emptiesHistory() {
        let expectAdded = expectation(description: "added")
        let item = NotificationItem(title: "H", subtitle: "", icon: "bell", type: .info)
        manager.showNotification(item, duration: 60)
        DispatchQueue.main.async { expectAdded.fulfill() }
        wait(for: [expectAdded], timeout: 1.0)

        manager.clearAllHistory()

        let expectCleared = expectation(description: "cleared")
        DispatchQueue.main.async { expectCleared.fulfill() }
        wait(for: [expectCleared], timeout: 1.0)

        XCTAssertTrue(manager.notificationHistory.isEmpty)
    }

    func test_dismissFromHistory_removesSpecificItem() {
        let expectAdded = expectation(description: "added")
        let item = NotificationItem(title: "Remove Me", subtitle: "", icon: "bell", type: .error)
        manager.showNotification(item, duration: 60)
        DispatchQueue.main.async { expectAdded.fulfill() }
        wait(for: [expectAdded], timeout: 1.0)

        manager.dismissFromHistory(item)

        let expectRemoved = expectation(description: "removed")
        DispatchQueue.main.async { expectRemoved.fulfill() }
        wait(for: [expectRemoved], timeout: 1.0)

        XCTAssertFalse(manager.notificationHistory.contains { $0.id == item.id })
    }

    func test_dismissFromHistory_keepsOtherItems() {
        let expectAdded = expectation(description: "both added")
        let a = NotificationItem(title: "Keep",   subtitle: "", icon: "bell", type: .info)
        let b = NotificationItem(title: "Remove", subtitle: "", icon: "bell", type: .info)
        manager.showNotification(a, duration: 60)
        manager.showNotification(b, duration: 60)
        DispatchQueue.main.async { expectAdded.fulfill() }
        wait(for: [expectAdded], timeout: 1.0)

        manager.dismissFromHistory(b)

        let expectDone = expectation(description: "removed")
        DispatchQueue.main.async { expectDone.fulfill() }
        wait(for: [expectDone], timeout: 1.0)

        XCTAssertTrue(manager.notificationHistory.contains  { $0.id == a.id })
        XCTAssertFalse(manager.notificationHistory.contains { $0.id == b.id })
    }
}


