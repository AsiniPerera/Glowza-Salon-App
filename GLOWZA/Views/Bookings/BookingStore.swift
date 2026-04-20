import Foundation
import Observation

@Observable
final class BookingStore {
    static let shared = BookingStore()
    private init() { loadSampleData() }

    var bookings: [Booking] = []

    var upcoming:  [Booking] { bookings.filter { $0.status == .upcoming  } }
    var completed: [Booking] { bookings.filter { $0.status == .completed } }

    func add(_ booking: Booking) { bookings.append(booking) }

    func addReview(bookingID: UUID, review: BookingReview) {
        guard let idx = bookings.firstIndex(where: { $0.id == bookingID }) else { return }
        bookings[idx].review = review
    }

    func reviews(forSalon name: String) -> [BookingReview] {
        bookings.filter { $0.salon.name == name }.compactMap { $0.review }
    }

    // MARK: - Sample Data
    private func loadSampleData() {
        let salon   = SalonCatalog.shared.salon(named: "Haley Avenue")
        let service = salon.services[0]
        bookings = [
            Booking(
                id: UUID(), salon: salon, service: service,
                date: makeDate(2024, 9, 10, 9, 30), timeSlot: "9:30 AM",
                receiptNumber: "GLZ-48291", paymentMethod: .card,
                amountPaid: service.price, signatureImage: nil,
                status: .completed, review: nil
            ),
            Booking(
                id: UUID(), salon: salon, service: service,
                date: makeDate(2024, 9, 28, 9, 30), timeSlot: "9:30 AM",
                receiptNumber: "GLZ-51827", paymentMethod: .card,
                amountPaid: service.price, signatureImage: nil,
                status: .completed,
                review: BookingReview(
                    rating: 5,
                    comment: "Absolutely amazing! My skin glowed for days afterwards. The therapist was so professional.",
                    date: makeDate(2024, 9, 30, 14, 0),
                    reviewerName: "Asini P."
                )
            )
        ]
    }

    private func makeDate(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = mo; c.day = d; c.hour = h; c.minute = min
        return Calendar.current.date(from: c) ?? Date()
    }
}
