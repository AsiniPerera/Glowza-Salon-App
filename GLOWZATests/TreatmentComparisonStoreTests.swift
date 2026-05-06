// TreatmentComparisonStoreTests.swift
// GLOWZATests
//
// Tests for TreatmentComparisonStore: add, remove, isAdded, canAddMore, clear.

import XCTest
@testable import GLOWZA

final class TreatmentComparisonStoreTests: XCTestCase {

    private var store: TreatmentComparisonStore!

    override func setUp() {
        super.setUp()
        // Use the shared instance; clear state before each test.
        store = TreatmentComparisonStore.shared
        store.clear()
    }

    override func tearDown() {
        store.clear()
        super.tearDown()
    }

    // MARK: - add

    func test_add_appendsTreatment() {
        let service = Fixtures.makeSalonService(name: "Facial")
        store.add(service: service, salonName: "Spa A")
        XCTAssertEqual(store.items.count, 1)
    }

    func test_add_storesSalonNameCorrectly() {
        let service = Fixtures.makeSalonService()
        store.add(service: service, salonName: "Boutique B")
        XCTAssertEqual(store.items.first?.salonName, "Boutique B")
    }

    func test_add_doesNotAddDuplicate() {
        let service = Fixtures.makeSalonService(name: "Peel")
        store.add(service: service, salonName: "Spa A")
        store.add(service: service, salonName: "Spa A")   // duplicate
        XCTAssertEqual(store.items.count, 1, "Duplicate (same service + salon) must be rejected")
    }

    func test_add_sameServiceDifferentSalon_allowed() {
        let service = Fixtures.makeSalonService(name: "Massage")
        store.add(service: service, salonName: "Spa A")
        store.add(service: service, salonName: "Spa B")   // same service, different salon
        XCTAssertEqual(store.items.count, 2)
    }

    // MARK: - canAddMore / 10-item cap

    func test_canAddMore_trueWhenBelowTen() {
        for i in 0..<9 {
            let s = Fixtures.makeSalonService(name: "Service \(i)")
            store.add(service: s, salonName: "Salon \(i)")
        }
        XCTAssertTrue(store.canAddMore)
    }

    func test_canAddMore_falseAtTen() {
        for i in 0..<10 {
            let s = Fixtures.makeSalonService(name: "Service \(i)")
            store.add(service: s, salonName: "Salon \(i)")
        }
        XCTAssertFalse(store.canAddMore)
    }

    func test_add_ignoresItemsOverTenLimit() {
        for i in 0..<11 {
            let s = Fixtures.makeSalonService(name: "Service \(i)")
            store.add(service: s, salonName: "Salon \(i)")
        }
        XCTAssertEqual(store.items.count, 10, "Store should cap at 10 items")
    }

    // MARK: - remove

    func test_remove_decreasesCount() {
        let service = Fixtures.makeSalonService()
        store.add(service: service, salonName: "Spa")
        let item = store.items.first!
        store.remove(item)
        XCTAssertTrue(store.items.isEmpty)
    }

    func test_remove_onlyRemovesTarget() {
        let s1 = Fixtures.makeSalonService(name: "A")
        let s2 = Fixtures.makeSalonService(name: "B")
        store.add(service: s1, salonName: "Spa")
        store.add(service: s2, salonName: "Spa")

        let target = store.items.first { $0.service.name == "A" }!
        store.remove(target)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.service.name, "B")
    }

    // MARK: - isAdded

    func test_isAdded_trueForAddedServiceAndSalon() {
        let service = Fixtures.makeSalonService(name: "Hydra Facial")
        store.add(service: service, salonName: "Glow Studio")
        XCTAssertTrue(store.isAdded(service, from: "Glow Studio"))
    }

    func test_isAdded_falseForUnaddedService() {
        let service = Fixtures.makeSalonService(name: "Not Added")
        XCTAssertFalse(store.isAdded(service, from: "Any Salon"))
    }

    func test_isAdded_falseWhenSalonNameDiffers() {
        let service = Fixtures.makeSalonService(name: "Facial")
        store.add(service: service, salonName: "Salon X")
        XCTAssertFalse(store.isAdded(service, from: "Salon Y"))
    }

    // MARK: - clear

    func test_clear_emptyesAllItems() {
        store.add(service: Fixtures.makeSalonService(name: "A"), salonName: "Spa")
        store.add(service: Fixtures.makeSalonService(name: "B"), salonName: "Spa")
        store.clear()
        XCTAssertTrue(store.items.isEmpty)
    }

    func test_clear_allowsAddingAfterClear() {
        for i in 0..<10 {
            store.add(service: Fixtures.makeSalonService(name: "S\(i)"), salonName: "N\(i)")
        }
        XCTAssertFalse(store.canAddMore)
        store.clear()
        XCTAssertTrue(store.canAddMore)
    }
}
