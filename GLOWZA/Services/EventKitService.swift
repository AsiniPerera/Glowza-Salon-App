import Foundation
import EventKit

enum CalendarSaveResult {
    case saved(eventId: String)
    case permissionDenied
    case noWritableCalendar
    case saveFailed
}

final class EventKitService {
    static let shared = EventKitService()

    private let store = EKEventStore()

    private init() {}

    // MARK: - Permissions
    @MainActor
    func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        }

        return await withCheckedContinuation { continuation in
            store.requestAccess(to: .event) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

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
    @MainActor
    func saveBookingToCalendar(_ booking: Booking) async -> CalendarSaveResult {
        let granted = await requestCalendarAccess()
        guard granted else { return .permissionDenied }

        guard let calendar = writableCalendar() else { return .noWritableCalendar }
        let (startDate, endDate) = appointmentRange(for: booking)

        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = "\(booking.service.name) - \(booking.salon.name)"
        event.location = booking.salon.location
        event.startDate = startDate
        event.endDate = endDate
        event.notes = "Receipt: \(booking.receiptNumber)\nPayment: LKR \(Int(booking.amountPaid))\nBooked via GLOWZA"
        event.alarms = [EKAlarm(relativeOffset: -60 * 60)]

        do {
            try store.save(event, span: .thisEvent, commit: true)
            return .saved(eventId: event.eventIdentifier ?? "")
        } catch {
            return .saveFailed
        }
    }

    // MARK: - Calendar CRUD
    func fetchEvents(from start: Date, to end: Date) async -> [EKEvent] {
        let granted = await requestCalendarAccess()
        guard granted else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate)
    }

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

    private func writableCalendar() -> EKCalendar? {
        if let defaultCalendar = store.defaultCalendarForNewEvents,
           defaultCalendar.allowsContentModifications {
            return defaultCalendar
        }

        return store.calendars(for: .event).first(where: { $0.allowsContentModifications })
    }

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

    private func durationFromService(_ text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 60
    }
}
