import Foundation

struct WidgetBookingSnapshot: Codable {
    let salonName: String
    let serviceName: String
    let date: Date
    let timeSlot: String
    let location: String
    let receiptNumber: String
}

enum WidgetSharedStore {
    static let appGroupId = "group.com.asini.glowza"
    static let bookingKey = "widget_upcoming_booking"
    static let favoriteSalonKey = "widget_favorite_salon"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupId) ?? .standard
    }
}
