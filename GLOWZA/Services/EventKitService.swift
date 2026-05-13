import Foundation
import EventKit

// Enum to represent the result of saving to the calendar!
enum CalendarSaveResult {
    case saved(eventId: String)
    case permissionDenied
    case noWritableCalendar
    case saveFailed
}

// MARK: - EventKit Service
// This class handles all interactions with Apple's Calendar and Reminders apps!
final class EventKitService {
    static let shared = EventKitService() // Singleton instance!

    // The event store is the database of all calendar events and reminders!
    private let store = EKEventStore()

    private init() {}

    // MARK: - Permissions
    // Requests access to the user's calendar!
    @MainActor
    func requestCalendarAccess() async -> Bool {
        // iOS 17 introduced a new API for this!
        if #available(iOS 17.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        }

        // Fallback for older iOS versions using a closure-based API.
        // we use withCheckedContinuation to turn a closure into an async function!
        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    // Requests access to the user's reminders!
    func requestReminderAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await store.requestFullAccessToReminders()
            } catch {
                return false
            }
        }

        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .reminder) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    // MARK: - Booking Calendar Integration
    // Saves a completed booking to the user's calendar!
    @MainActor
    func saveBookingToCalendar(_ booking: Booking) async -> CalendarSaveResult {
        let granted = await requestCalendarAccess()
        guard granted else { return .permissionDenied }

        guard let calendar = writableCalendar() else { return .noWritableCalendar }
        let (startDate, endDate) = appointmentRange(for: booking)

        // Create a new event!
        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = "\(booking.service.name) - \(booking.salon.name)"
        event.location = booking.salon.location
        event.startDate = startDate
        event.endDate = endDate
        event.notes = "Receipt: \(booking.receiptNumber)\nPayment: LKR \(Int(booking.amountPaid))\nBooked via GLOWZA"
        
        // Add an alarm for 1 hour before the appointment!
        event.alarms = [EKAlarm(relativeOffset: -60 * 60)]

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return .saved(eventId: event.eventIdentifier ?? "")
        } catch {
            return .saveFailed
        }
    }

    // MARK: - Calendar CRUD
    // Fetches events between two dates!
    func fetchEvents(from start: Date, to end: Date) async -> [EKEvent] {
        let granted = await requestCalendarAccess()
        guard granted else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
    }

    // Updates an existing event!
    func updateEvent(
        eventId: String,
        newTitle: String? = nil,
        newStartDate: Date? = nil,
        newEndDate: Date? = nil,
        newNotes: String? = nil
    ) async -> Bool {
        let granted = await requestCalendarAccess()
        guard granted, let event = store.event(withIdentifier: eventId) else { return false }

        if let newTitle { event.title = newTitle }
        if let newStartDate { event.startDate = newStartDate }
        if let newEndDate { event.endDate = newEndDate }
        if let newNotes { event.notes = newNotes }

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return true
        } catch {
            return false
        }
    }

    // Deletes an event!
    func deleteEvent(eventId: String) async -> Bool {
        let granted = await requestCalendarAccess()
        guard granted, let event = store.event(withIdentifier: eventId) else { return false }

        do {
            try store.remove(event, span: .thisEvent, commit: true)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Reminder CRUD
    // Creates a new reminder!
    func createReminder(title: String, dueDate: Date?, notes: String?) async -> String? {
        let granted = await requestReminderAccess()
        guard granted, let calendar = store.defaultCalendarForNewReminders() else { return nil }

        let reminder = EKReminder(eventStore: store)
        reminder.calendar = calendar
        reminder.title = title
        reminder.notes = notes

        if let dueDate {
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
            reminder.dueDateComponents = comps
        }

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            return nil
        }
    }

    // Fetches all reminders!
    func fetchReminders() async -> [EKReminder] {
        let granted = await requestReminderAccess()
        guard granted else { return [] }

        return await withCheckedContinuation { continuation in
            let predicate = store.predicateForReminders(in: nil)
            store.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // Updates an existing reminder!
    func updateReminder(id: String, newTitle: String? = nil, newDueDate: Date? = nil) async -> Bool {
        let granted = await requestReminderAccess()
        guard granted else { return false }

        let reminders = await fetchReminders()
        guard let reminder = reminders.first(where: { $0.calendarItemIdentifier == id }) else { return false }

        if let newTitle { reminder.title = newTitle }
        if let newDueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: newDueDate
            )
        }

        do {
            try store.save(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    // Deletes a reminder!
    func deleteReminder(id: String) async -> Bool {
        let granted = await requestReminderAccess()
        guard granted else { return false }

        let reminders = await fetchReminders()
        guard let reminder = reminders.first(where: { $0.calendarItemIdentifier == id }) else { return false }

        do {
            try store.remove(reminder, commit: true)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Helpers
    // Helper to calculate the start and end time of an appointment!
    private func appointmentRange(for booking: Booking) -> (Date, Date) {
        let calendar = Calendar.current
        let parsedTime = parseSlotTime(booking.timeSlot)
        let durationMinutes = durationFromService(booking.service.duration)

        var startDate = booking.date
        if let parsedTime {
            let components = calendar.dateComponents([.hour, .minute], from: parsedTime)
            startDate = calendar.date(
                bySettingHour: components.hour ?? 9,
                minute: components.minute ?? 0,
                second: 0,
                of: booking.date
            ) ?? booking.date
        }

        let endDate = calendar.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate.addingTimeInterval(3600)
        return (startDate, endDate)
    }

    // Helper to find a calendar that we are allowed to write to!
    private func writableCalendar() -> EKCalendar? {
        if let defaultCalendar = store.defaultCalendarForNewEvents,
           defaultCalendar.allowsContentModifications {
            return defaultCalendar
        }

        return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
    }

    // Helper to parse strings like "10:30 AM" into a Date object!
    private func parseSlotTime(_ raw: String) -> Date? {
        let normalized = raw
            .replacingOccurrences(of: " ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let formats = ["h:mm a", "hh:mm a", "H:mm", "HH:mm"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        for format in formats {
            formatter.dateFormat = format
            if let parsed = formatter.date(from: normalized) {
                return parsed
            }
        }
        return nil
    }

    // Helper to extract the number of minutes from a string like "60 min"!
    private func durationFromService(_ text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 60
    }
}
