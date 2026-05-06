import WidgetKit
import SwiftUI

struct BookAgainEntry: TimelineEntry {
    let date: Date
    let salonName: String
    let serviceName: String
    let appointmentTime: String
    let appointmentDate: Date
    let deeplink: URL
    let hasAppointment: Bool
}

struct BookAgainProvider: TimelineProvider {
    func placeholder(in context: Context) -> BookAgainEntry {
        makeEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (BookAgainEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BookAgainEntry>) -> Void) {
        let entry = makeEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> BookAgainEntry {
        if let data = WidgetSharedStore.defaults.data(forKey: WidgetSharedStore.bookingKey),
           let booking = try? JSONDecoder().decode(WidgetBookingSnapshot.self, from: data) {
            return BookAgainEntry(
                date: Date(),
                salonName: booking.salonName,
                serviceName: booking.serviceName,
                appointmentTime: booking.timeSlot,
                appointmentDate: booking.date,
                deeplink: URL(string: "glowza://appointment/ongoing") ?? URL(string: "glowza://bookings")!,
                hasAppointment: true
            )
        } else {
            let encoded = "Haley%20Avenue"
            return BookAgainEntry(
                date: Date(),
                salonName: "Haley Avenue",
                serviceName: "Book Next",
                appointmentTime: "Available",
                appointmentDate: Date(),
                deeplink: URL(string: "glowza://quick-book?salon=\(encoded)")!,
                hasAppointment: false
            )
        }
    }
}

struct BookAgainWidgetView: View {
    var entry: BookAgainEntry

    private let neonPink = Color(red: 1.0, green: 0.0, blue: 0.6)
    private let goldAccent = Color(red: 1.0, green: 0.843, blue: 0.0)
    private let darkBg = Color(red: 0.12, green: 0.12, blue: 0.14)

    private var serviceEmoji: String {
        switch entry.serviceName.lowercased() {
        case let s where s.contains("facial"): return "✨"
        case let s where s.contains("massage"): return "🧖"
        case let s where s.contains("hair"): return "💇"
        case let s where s.contains("nails"): return "💅"
        case let s where s.contains("wax"): return "🌟"
        case let s where s.contains("skin"): return "🌸"
        default: return "💄"
        }
    }

    var body: some View {
        if entry.hasAppointment {
            // Upcoming Appointment Widget
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        darkBg,
                        Color(red: 0.15, green: 0.12, blue: 0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .leading, spacing: 12) {
                    // Top section: Time and Status
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("TIME")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(.white.opacity(0.5))

                            Text(entry.appointmentTime)
                                .font(.system(size: 18, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        // Service emoji indicator
                        Text(serviceEmoji)
                            .font(.system(size: 28))
                            .padding(8)
                            .background(neonPink.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Divider()
                        .opacity(0.2)

                    // Middle section: Service & Salon
                    VStack(alignment: .leading, spacing: 6) {
                        Text(entry.serviceName)
                            .font(.system(size: 12, weight: .semibold, design: .default))
                            .foregroundColor(goldAccent)
                            .lineLimit(1)

                        Text(entry.salonName)
                            .font(.system(size: 13, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Bottom section: Date & Status
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(neonPink)

                        Text(formattedDate(entry.appointmentDate))
                            .font(.system(size: 10, weight: .semibold, design: .default))
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        HStack(spacing: 4) {
                            Circle()
                                .fill(neonPink)
                                .frame(width: 6, height: 6)

                            Text("Live")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(neonPink)
                        }
                    }
                }
                .padding(14)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                neonPink.opacity(0.3),
                                goldAccent.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .widgetURL(entry.deeplink)
            .containerBackground(.clear, for: .widget)
        } else {
            // Empty State - Quick Book
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        darkBg,
                        Color(red: 0.15, green: 0.12, blue: 0.18)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(alignment: .center, spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(neonPink)

                    Text("Book Appointment")
                        .font(.system(size: 13, weight: .bold, design: .default))
                        .foregroundColor(.white)

                    Text("No upcoming bookings")
                        .font(.system(size: 10, weight: .regular, design: .default))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(neonPink.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .widgetURL(entry.deeplink)
            .containerBackground(.clear, for: .widget)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct BookAgainWidget: Widget {
    let kind: String = "BookAgainWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BookAgainProvider()) { entry in
            BookAgainWidgetView(entry: entry)
        }
        .configurationDisplayName("Appointment")
        .description("View your latest upcoming appointment at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
