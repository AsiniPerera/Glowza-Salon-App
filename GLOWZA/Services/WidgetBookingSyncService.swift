import Foundation
import WidgetKit

struct WidgetBookingSnapshot: Codable {
    let salonName: String
    let serviceName: String
    let date: Date
    let timeSlot: String
    let location: String
    let receiptNumber: String
}

final class WidgetBookingSyncService {
    static let shared = WidgetBookingSyncService()

    static let appGroupId = "group.com.asini.glowza"
    private let key = "widget_upcoming_booking"
    private let favoriteSalonKey = "widget_favorite_salon"

    private init() {}

    func saveUpcomingBooking(_ booking: Booking) {
        let appointmentDate = appointmentDate(for: booking)
        let snapshot = WidgetBookingSnapshot(
            salonName: booking.salon.name,
            serviceName: booking.service.name,
            date: appointmentDate,
            timeSlot: booking.timeSlot,
            location: booking.salon.location,
            receiptNumber: booking.receiptNumber
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
        reloadWidgets()

        if defaults.string(forKey: favoriteSalonKey)?.isEmpty ?? true {
            defaults.set(booking.salon.name, forKey: favoriteSalonKey)
        }
    }

    func clearUpcomingBooking() {
        defaults.removeObject(forKey: key)
        reloadWidgets()
    }

    func updateFromBookings(_ bookings: [Booking]) {
        let nextUpcoming = bookings
            .filter { $0.status == .upcoming }
            .sorted { appointmentDate(for: $0) < appointmentDate(for: $1) }
            .first

        if let nextUpcoming {
            saveUpcomingBooking(nextUpcoming)
        } else {
            clearUpcomingBooking()
        }
    }

    func setFavoriteSalon(_ salonName: String) {
        defaults.set(salonName, forKey: favoriteSalonKey)
        reloadWidgets()
    }

    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupId) ?? .standard
    }

    private func appointmentDate(for booking: Booking) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"

        guard let parsedTime = formatter.date(from: booking.timeSlot) else {
            return booking.date
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: parsedTime)
        return calendar.date(
            bySettingHour: components.hour ?? 9,
            minute: components.minute ?? 0,
            second: 0,
            of: booking.date
        ) ?? booking.date
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "GLOWZAWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "UpcomingBookingsWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "BookAgainWidget")
    }
}
