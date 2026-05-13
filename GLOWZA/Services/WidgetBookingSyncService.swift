import Foundation
import WidgetKit

// MARK: - Widget Booking Snapshot
// This struct represents the data we share with the iOS Widget!
// It conforms to Codable so we can encode it to JSON and save it in UserDefaults!
struct WidgetBookingSnapshot: Codable {
    let salonName: String
    let serviceName: String
    let date: Date
    let timeSlot: String
    let location: String
    let receiptNumber: String
}

// MARK: - Widget Booking Sync Service
// This class handles sharing booking data with the app's home screen widgets!
// It uses "App Groups" to share data between the main app and the widget extension.
final class WidgetBookingSyncService {
    static let shared = WidgetBookingSyncService() // Singleton instance!

    // The App Group ID defined in your developer account and project capabilities!
    static let appGroupId = "group.com.asini.glowza"
    
    private let key = "widget_upcoming_booking"
    private let favoriteSalonKey = "widget_favorite_salon"

    private init() {}

    // Saves the next upcoming booking to shared storage so the widget can see it!
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

        // Encode to JSON data.
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        
        // Save to the shared App Group storage!
        defaults.set(data, forKey: key)
        
        // Tell iOS to refresh the widgets!
        reloadWidgets()

        // Set favorite salon as fallback if none exists.
        if defaults.string(forKey: favoriteSalonKey)?.isEmpty ?? true {
            defaults.set(booking.salon.name, forKey: favoriteSalonKey)
        }
    }

    // Clears the data (e.g. when a booking is completed or cancelled).
    func clearUpcomingBooking() {
        defaults.removeObject(forKey: key)
        reloadWidgets()
    }

    // Finds the *next* upcoming booking from a list and updates the widget!
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

    // Saves the user's favorite salon for the "Book Again" widget!
    func setFavoriteSalon(_ salonName: String) {
        defaults.set(salonName, forKey: favoriteSalonKey)
        reloadWidgets()
    }

    // Helper to get the shared UserDefaults instance!
    private var defaults: UserDefaults {
        UserDefaults(suiteName: Self.appGroupId) ?? .standard
    }

    // Helper to combine the Date and TimeSlot string into a single Date object!
    private func appointmentDate(for booking: Booking) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a" // Expects formats like "10:30 AM".

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

    // Helper to tell iOS to reload specific widget timelines!
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "GLOWZAWidgets")
        WidgetCenter.shared.reloadTimelines(ofKind: "UpcomingBookingsWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "BookAgainWidget")
    }
}
