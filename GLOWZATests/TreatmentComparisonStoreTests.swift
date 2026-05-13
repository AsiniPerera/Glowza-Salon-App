import XCTest
@testable import GLOWZA

@MainActor
final class TreatmentComparisonStoreTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TreatmentComparisonStore.shared.clear()
    }

    func test_add_appendsTreatment() {
        let service = Fixtures.makeSalonService(name: "Facial")
        let salon = Fixtures.makeSalon(name: "Salon A")
        TreatmentComparisonStore.shared.add(service: service, salonName: salon.name)
        XCTAssertEqual(TreatmentComparisonStore.shared.items.count, 1)
    }

    func test_remove_decreasesCount() {
        let service = Fixtures.makeSalonService(name: "Facial")
        let salon = Fixtures.makeSalon(name: "Salon A")
        TreatmentComparisonStore.shared.add(service: service, salonName: salon.name)
        let item = TreatmentComparisonStore.shared.items.first!
        TreatmentComparisonStore.shared.remove(item)
        XCTAssertTrue(TreatmentComparisonStore.shared.items.isEmpty)
    }

    func test_isAdded_trueForAddedServiceAndSalon() {
        let service = Fixtures.makeSalonService(name: "Facial")
        let salon = Fixtures.makeSalon(name: "Salon A")
        TreatmentComparisonStore.shared.add(service: service, salonName: salon.name)
        XCTAssertTrue(TreatmentComparisonStore.shared.isAdded(service, from: salon.name))
    }

    func test_clear_emptyesAllItems() {
        TreatmentComparisonStore.shared.add(service: Fixtures.makeSalonService(), salonName: "Salon A")
        TreatmentComparisonStore.shared.clear()
        XCTAssertTrue(TreatmentComparisonStore.shared.items.isEmpty)
    }
    
    // 5. Test that add does not add duplicate!
    func test_add_doesNotAddDuplicate() {
        let service = Fixtures.makeSalonService(name: "Facial")
        let salon = Fixtures.makeSalon(name: "Salon A")
        TreatmentComparisonStore.shared.add(service: service, salonName: salon.name)
        TreatmentComparisonStore.shared.add(service: service, salonName: salon.name)
        XCTAssertEqual(TreatmentComparisonStore.shared.items.count, 1)
    }
    
    // 6. Test that canAddMore returns false at 10 items!
    func test_canAddMore_falseAtTen() {
        for i in 0..<10 {
            TreatmentComparisonStore.shared.add(service: Fixtures.makeSalonService(name: "Facial \(i)"), salonName: "Salon A")
        }
        XCTAssertFalse(TreatmentComparisonStore.shared.canAddMore)
    }
}
