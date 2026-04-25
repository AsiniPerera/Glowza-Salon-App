import SwiftUI

// MARK: - Treatment Tracking View
struct TreatmentTrackingView: View {

    private let brand = Color(hex: "AF1C47")

    @State private var selectedTab: TrackingTab = .history
    @State private var store = BookingStore.shared

    enum TrackingTab: String, CaseIterable {
        case history  = "History"
        case insights = "Insights"
    }

    private var bookings: [Booking] { store.bookings }

    private var completedBookings: [Booking] {
        store.bookings.filter { $0.status == .completed }
            .sorted { $0.date > $1.date }
    }

    private var upcomingBookings: [Booking] {
        store.bookings.filter { $0.status == .upcoming }
            .sorted { $0.date < $1.date }
    }

    // Monthly aggregation for chart
    private var monthlyVisits: [(month: String, count: Int)] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM"
        var counts: [String: Int] = [:]
        // Build ordered month keys for last 6 months
        var months: [String] = []
        for i in (0..<6).reversed() {
            if let d = cal.date(byAdding: .month, value: -i, to: Date()) {
                months.append(fmt.string(from: d))
            }
        }
        months.forEach { counts[$0] = 0 }
        for b in bookings {
            let key = fmt.string(from: b.date)
            if counts[key] != nil { counts[key]! += 1 }
        }
        return months.map { ($0, counts[$0] ?? 0) }
    }

    private var totalSpend: Double {
        completedBookings.reduce(0) { $0 + $1.amountPaid }
    }

    private var avgRating: Double {
        let rated = completedBookings.compactMap { $0.review?.rating }
        guard !rated.isEmpty else { return 0 }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }

    // Most visited salon
    private var mostVisited: String {
        let freq = Dictionary(grouping: completedBookings, by: { $0.salon.name })
            .mapValues { $0.count }
        return freq.max(by: { $0.value < $1.value })?.key ?? "–"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                summaryStrip
                tabPicker.padding(.horizontal, 16).padding(.top, 20)

                if selectedTab == .history {
                    historyContent
                } else {
                    insightsContent
                }

                Spacer().frame(height: 40)
            }
        }
        .background(Color(hex: "F7F7F7").ignoresSafeArea())
        .navigationTitle("Treatment Tracking")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Summary Strip
    private var summaryStrip: some View {
        HStack(spacing: 0) {
            summaryCell(value: "\(completedBookings.count)", label: "Treatments")
            stripDivider
            summaryCell(value: String(format: "Rs %.0f", totalSpend), label: "Total Spent")
            stripDivider
            summaryCell(value: avgRating > 0 ? String(format: "%.1f ★", avgRating) : "–", label: "Avg Rating")
        }
        .padding(.vertical, 20)
        .background(brand)
    }

    private func summaryCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var stripDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.3))
            .frame(width: 1, height: 36)
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(TrackingTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundColor(selectedTab == tab ? brand : Color(hex: "8A8A8A"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            VStack {
                                Spacer()
                                if selectedTab == tab {
                                    Rectangle().fill(brand).frame(height: 2)
                                }
                            }
                        )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
    }

    // MARK: - History Content
    private var historyContent: some View {
        VStack(spacing: 16) {
            if upcomingBookings.isEmpty && completedBookings.isEmpty {
                emptyState
            } else {
                if !upcomingBookings.isEmpty {
                    sectionHeader("Upcoming")
                    ForEach(upcomingBookings) { booking in
                        treatmentCard(booking, isUpcoming: true)
                    }
                }
                if !completedBookings.isEmpty {
                    sectionHeader("Past Treatments")
                    ForEach(completedBookings) { booking in
                        treatmentCard(booking, isUpcoming: false)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "ABABAB"))
            Spacer()
        }
        .padding(.top, 8)
    }

    private func treatmentCard(_ booking: Booking, isUpcoming: Bool) -> some View {
        HStack(spacing: 14) {
            // Category colour pill
            RoundedRectangle(cornerRadius: 4)
                .fill(categoryColor(booking.service.category))
                .frame(width: 4, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.service.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(booking.salon.name)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6B6B6B"))
                Text(formatDate(booking.date) + " · " + booking.timeSlot)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "ABABAB"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "Rs %.0f", booking.amountPaid))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(brand)
                if let review = booking.review {
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: "F59E0B"))
                        }
                    }
                } else if isUpcoming {
                    Text("Upcoming")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(brand)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 40)
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "DEDEDE"))
            Text("No treatments yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A1A"))
            Text("Your treatment history will appear here\nafter your first booking.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A8A"))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Insights Content
    private var insightsContent: some View {
        VStack(spacing: 16) {
            visitChartCard
            spendBreakdownCard
            favoriteSessionCard
            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var visitChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Visits")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "1A1A1A"))

            let maxCount = max(monthlyVisits.map { $0.count }.max() ?? 1, 1)

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(monthlyVisits, id: \.month) { item in
                    VStack(spacing: 6) {
                        Text("\(item.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(item.count > 0 ? brand : Color(hex: "DEDEDE"))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.count > 0 ? brand : Color(hex: "F0F0F0"))
                            .frame(
                                width: .infinity,
                                height: max(CGFloat(item.count) / CGFloat(maxCount) * 100, 4)
                            )

                        Text(item.month)
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 130, alignment: .bottom)
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var spendBreakdownCard: some View {
        let categorySpends = Dictionary(
            grouping: completedBookings, by: { $0.service.category }
        ).mapValues { bookings in bookings.reduce(0.0) { $0 + $1.amountPaid } }

        let sorted = categorySpends.sorted { $0.value > $1.value }
        let total  = sorted.reduce(0.0) { $0 + $1.value }

        return VStack(alignment: .leading, spacing: 14) {
            Text("Spend by Category")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(hex: "1A1A1A"))

            if sorted.isEmpty {
                Text("Complete some bookings to see spending insights.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8A8A8A"))
            } else {
                ForEach(sorted, id: \.key) { item in
                    VStack(spacing: 6) {
                        HStack {
                            Text(item.key)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            Spacer()
                            Text(String(format: "Rs %.0f", item.value))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(brand)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(hex: "F5F5F5"))
                                Capsule()
                                    .fill(brand.opacity(0.8))
                                    .frame(width: total > 0 ? geo.size.width * CGFloat(item.value / total) : 0)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var favoriteSessionCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(brand.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "crown.fill")
                    .font(.system(size: 22))
                    .foregroundColor(brand)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Most Visited Salon")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
                Text(mostVisited)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func categoryColor(_ cat: String) -> Color {
        switch cat {
        case "Skin":       return Color(hex: "AF1C47")
        case "Hair":       return Color(hex: "007AFF")
        case "Nails":      return Color(hex: "30D158")
        case "Aesthetic":  return Color(hex: "FF9500")
        default:           return Color(hex: "8E8E93")
        }
    }
}
