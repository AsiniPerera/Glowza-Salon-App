import WidgetKit
import SwiftUI

struct UpcomingBookingsEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetBookingSnapshot?
}

struct UpcomingBookingsProvider: TimelineProvider {
    func placeholder(in context: Context) -> UpcomingBookingsEntry {
        UpcomingBookingsEntry(
            date: Date(),
            snapshot: WidgetBookingSnapshot(
                salonName: "Golden Avenue",
                serviceName: "Facial Treatment",
                date: Date(),
                timeSlot: "10:00 AM",
                location: "Moratuwa, Colombo",
                receiptNumber: "GLZ-12345"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (UpcomingBookingsEntry) -> Void) {
        completion(UpcomingBookingsEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpcomingBookingsEntry>) -> Void) {
        let entry = UpcomingBookingsEntry(date: Date(), snapshot: loadSnapshot())
        let refresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func loadSnapshot() -> WidgetBookingSnapshot? {
        guard let data = WidgetSharedStore.defaults.data(forKey: WidgetSharedStore.bookingKey) else { return nil }
        return try? JSONDecoder().decode(WidgetBookingSnapshot.self, from: data)
    }
}

struct UpcomingBookingsWidgetView: View {
    var entry: UpcomingBookingsEntry

    private let neonPink = Color(red: 1.0, green: 0.0, blue: 0.6)

    private var daysLabel: String {
        guard let snapshot = entry.snapshot else { return "3" }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: snapshot.date)
        let days = max(0, calendar.dateComponents([.day], from: start, to: target).day ?? 0)
        return String(days)
    }

    var body: some View {
        ZStack {
            Color.white

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(neonPink)
                        .frame(width: 88, height: 88)

                    Text(daysLabel)
                        .font(.system(size: 54, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.7)
                }

                Text("DAYS UNTIL NEXT APPOINTMENT")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(neonPink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .tracking(0.6)
                    .padding(.horizontal, 10)
            }
            .padding(12)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(neonPink, lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .widgetURL(URL(string: "glowza://bookings/upcoming"))
        .containerBackground(.white, for: .widget)
    }
}

struct UpcomingBookingsWidget: Widget {
    let kind: String = "UpcomingBookingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpcomingBookingsProvider()) { entry in
            UpcomingBookingsWidgetView(entry: entry)
        }
        .configurationDisplayName("Appointment Countdown")
        .description("Luxury countdown to your next salon appointment.")
        .supportedFamilies([.systemSmall])
    }
}
