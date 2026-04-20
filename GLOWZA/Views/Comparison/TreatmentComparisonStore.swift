import Foundation
import Observation

// MARK: - Selected Treatment item

struct SelectedTreatment: Identifiable {
    let id = UUID()
    let service: SalonService
    let salonName: String
}

// MARK: - Treatment Comparison Store  (max 4 treatments)

@Observable
final class TreatmentComparisonStore {
    static let shared = TreatmentComparisonStore()
    private init() {}

    var items: [SelectedTreatment] = []

    var canAddMore: Bool { items.count < 4 }

    func add(service: SalonService, salonName: String) {
        guard canAddMore, !isAdded(service, from: salonName) else { return }
        items.append(SelectedTreatment(service: service, salonName: salonName))
    }

    func remove(_ item: SelectedTreatment) {
        items.removeAll { $0.id == item.id }
    }

    func isAdded(_ service: SalonService, from salonName: String) -> Bool {
        items.contains { $0.service.id == service.id && $0.salonName == salonName }
    }

    func clear() {
        items.removeAll()
    }
}
