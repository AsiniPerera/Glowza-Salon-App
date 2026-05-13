import Foundation
import Observation

// MARK: - Selected Treatment
// A wrapper struct to hold a treatment and the salon it belongs to!
struct SelectedTreatment: Identifiable {
    let id = UUID()
    let service: SalonService
    let salonName: String
}

// MARK: - Treatment Comparison Store
// This class manages the list of treatments the user wants to compare!
// It limits the selection to a maximum of 10 treatments.
@Observable
final class TreatmentComparisonStore {
    // Singleton pattern!
    static let shared = TreatmentComparisonStore()
    private init() {}

    // The list of selected treatments!
    var items: [SelectedTreatment] = []

    // Computed property to check if more items can be added!
    var canAddMore: Bool { items.count < 10 }

    func add(service: SalonService, salonName: String) {
        // Only add if we have space and it's not already added!
        guard canAddMore, !isAdded(service, from: salonName) else { return }
        items.append(SelectedTreatment(service: service, salonName: salonName))
    }

    func remove(_ item: SelectedTreatment) {
        items.removeAll { $0.id == item.id }
    }

    // Helper to check if a specific treatment is already in the comparison list!
    func isAdded(_ service: SalonService, from salonName: String) -> Bool {
        items.contains { $0.service.id == service.id && $0.salonName == salonName }
    }

    func clear() {
        items.removeAll()
    }
}
