// TreatmentComparisonStoreTests.swift
// GLOWZATests

import XCTest
@testable import GLOWZA

final class TreatmentComparisonStoreTests: XCTestCase {

    private var store: TreatmentComparisonStore!

    override func setUp() {
        super.setUp()
        store = TreatmentComparisonStore.shared
        store.clear()
    }

    override func tearDown() {
        store.clear()
        super.tearDown()
    }

    // MARK: - add

    func test_add_appendsTreatment() {
        store.add(service: Fixtures.makeSalonService(name: "Facial"), salonName: "Spa A")
        XCTAssertEqual(store.items.count, 1)
    }

    func test_add_doesNotAddDuplicate() {
        let service = Fixtures.makeSalonService(name: "Peel")
        store.add(service: service, salonName: "Spa A")
        store.add(service: service, salonName: "Spa A")
        XCTAssertEqual(store.items.count, 1, "Duplicate must be rejected")
    }

    func test_add_sameServiceDifferentSalon_allowed() {
        let service = Fixtures.makeSalonService(name: "Massage")
        store.add(service: service, salonName: "Spa A")
        store.add(service: service, salonName: "Spa B")
        XCTAssertEqual(store.items.count, 2)
    }

    // MARK: - cap

    func test_canAddMore_falseAtTen() {
        for i in 0..<10 {
            store.add(service: Fixtures.makeSalonService(name: "Service \(i)"), salonName: "Salon \(i)")
        }
        XCTAssertFalse(store.canAddMore)
    }

    // MARK: - remove

    func test_remove_decreasesCount() {
        let service = Fixtures.makeSalonService()
        store.add(service: service, salonName: "Spa")
        store.remove(store.items.first!)
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - isAdded

    func test_isAdded_trueForAddedServiceAndSalon() {
        let service = Fixtures.makeSalonService(name: "Hydra Facial")
        store.add(service: service, salonName: "Glow Studio")
        XCTAssertTrue(store.isAdded(service, from: "Glow Studio"))
    }

    // MARK: - clear

    func test_clear_emptyesAllItems() {
        store.add(service: Fixtures.makeSalonService(name: "A"), salonName: "Spa")
        store.add(service: Fixtures.makeSalonService(name: "B"), salonName: "Spa")
        store.clear()
        XCTAssertTrue(store.items.isEmpty)
    }
}
