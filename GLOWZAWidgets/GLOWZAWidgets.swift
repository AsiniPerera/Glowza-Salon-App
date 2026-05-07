import WidgetKit
import SwiftUI

struct AppointmentReminderEntry: TimelineEntry {
	let date: Date
	let booking: WidgetBookingSnapshot?
}

struct AppointmentReminderProvider: TimelineProvider {
	func placeholder(in context: Context) -> AppointmentReminderEntry {
		AppointmentReminderEntry(
			date: Date(),
			booking: WidgetBookingSnapshot(
				salonName: "Haley Avenue",
				serviceName: "Signature Facial",
				date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
				timeSlot: "10:30 AM",
				location: "Colombo",
				receiptNumber: "GLZ-00001"
			)
		)
	}

	func getSnapshot(in context: Context, completion: @escaping (AppointmentReminderEntry) -> Void) {
		completion(AppointmentReminderEntry(date: Date(), booking: loadBooking()))
	}

	func getTimeline(in context: Context, completion: @escaping (Timeline<AppointmentReminderEntry>) -> Void) {
		let entry = AppointmentReminderEntry(date: Date(), booking: loadBooking())
		let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
		completion(Timeline(entries: [entry], policy: .after(refreshDate)))
	}

	private func loadBooking() -> WidgetBookingSnapshot? {
		guard let data = WidgetSharedStore.defaults.data(forKey: WidgetSharedStore.bookingKey) else {
			return nil
		}
		return try? JSONDecoder().decode(WidgetBookingSnapshot.self, from: data)
	}
}

struct GLOWZAWidgetsEntryView: View {
	var entry: AppointmentReminderProvider.Entry

	private let neonPink = Color(red: 1.0, green: 0.4, blue: 0.698)
	private let glassTop = Color.white.opacity(0.9)
	private let glassBottom = Color.white.opacity(0.62)

	private var reminderLabel: String {
		guard let booking = entry.booking else { return "No upcoming appointment" }

		let calendar = Calendar.current
		let today = calendar.startOfDay(for: Date())
		let appointmentDay = calendar.startOfDay(for: booking.date)
		let days = calendar.dateComponents([.day], from: today, to: appointmentDay).day ?? 0

		if days <= 0 { return "Today" }
		if days == 1 { return "Tomorrow" }
		return "In \(days) days"
	}

	private var dateLabel: String {
		guard let booking = entry.booking else { return "Add a booking in GLOWZA" }
		let formatter = DateFormatter()
		formatter.dateFormat = "EEE, MMM d"
		return "\(formatter.string(from: booking.date)) at \(booking.timeSlot)"
	}

	var body: some View {
		ZStack {
			LinearGradient(
				colors: [glassTop, glassBottom],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)

			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Color.white.opacity(0.25))
				.padding(1)

			if let booking = entry.booking {
				VStack(alignment: .leading, spacing: 8) {
					HStack {
						Text("Upcoming")
							.font(.system(size: 11, weight: .semibold))
							.foregroundStyle(Color.black.opacity(0.65))
						Spacer()
						Text(reminderLabel)
							.font(.system(size: 11, weight: .bold))
							.foregroundStyle(neonPink)
					}

					Text(booking.salonName)
						.font(.system(size: 16, weight: .bold))
						.foregroundStyle(Color.black.opacity(0.9))
						.lineLimit(1)

					Text(booking.serviceName)
						.font(.system(size: 13, weight: .semibold))
						.foregroundStyle(neonPink)
						.lineLimit(1)

					Spacer(minLength: 0)

					VStack(alignment: .leading, spacing: 4) {
						Label(dateLabel, systemImage: "calendar")
						Label(booking.location, systemImage: "mappin.and.ellipse")
					}
					.font(.system(size: 11, weight: .medium))
					.foregroundStyle(Color.black.opacity(0.72))
					.lineLimit(1)
				}
				.padding(14)
			} else {
				VStack(alignment: .leading, spacing: 10) {
					Text("Upcoming")
						.font(.system(size: 11, weight: .semibold))
						.foregroundStyle(Color.black.opacity(0.65))

					Text("No appointment yet")
						.font(.system(size: 15, weight: .bold))
						.foregroundStyle(Color.black.opacity(0.9))

					Text("Tap to book your next salon visit")
						.font(.system(size: 12, weight: .medium))
						.foregroundStyle(Color.black.opacity(0.62))

					Spacer(minLength: 0)

					Text("GLOWZA")
						.font(.system(size: 12, weight: .bold))
						.foregroundStyle(neonPink)
				}
				.padding(14)
			}
		}
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Color.white.opacity(0.95), lineWidth: 1.6)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Color.black.opacity(0.08), lineWidth: 0.8)
		)
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		.widgetURL(URL(string: "glowza://bookings/upcoming"))
		.containerBackground(.clear, for: .widget)
	}
}

struct GLOWZAWidgets: Widget {
	let kind: String = "GLOWZAWidgets"

	var body: some WidgetConfiguration {
		StaticConfiguration(kind: kind, provider: AppointmentReminderProvider()) { entry in
			GLOWZAWidgetsEntryView(entry: entry)
		}
		.configurationDisplayName("Upcoming Appointment")
		.description("See your latest salon booking with a reminder.")
		.supportedFamilies([.systemSmall, .systemMedium])
	}
}

// MARK: - Step 6: Previews

#Preview("Small – Booked", as: .systemSmall) {
	GLOWZAWidgets()
} timeline: {
	AppointmentReminderEntry(
		date: .now,
		booking: WidgetBookingSnapshot(
			salonName: "Haley Avenue",
			serviceName: "Signature Facial",
			date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
			timeSlot: "10:30 AM",
			location: "Colombo",
			receiptNumber: "GLZ-00001"
		)
	)
}

#Preview("Small – Empty", as: .systemSmall) {
	GLOWZAWidgets()
} timeline: {
	AppointmentReminderEntry(date: .now, booking: nil)
}

#Preview("Medium – Booked", as: .systemMedium) {
	GLOWZAWidgets()
} timeline: {
	AppointmentReminderEntry(
		date: .now,
		booking: WidgetBookingSnapshot(
			salonName: "Aura Beauty Bar",
			serviceName: "Hydra Facial",
			date: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
			timeSlot: "2:00 PM",
			location: "Colombo 03",
			receiptNumber: "GLZ-00042"
		)
	)
}
