import SwiftUI
import Charts // We import Charts to draw the bar chart!

// MARK: - Treatment Tracking View
// This view shows a history of the user's completed treatments.
// It uses a bar chart to compare the number of treatments in each category.
struct TreatmentTrackingView: View {

    @Environment(\.dismiss) private var dismiss

    private var brand: Color { Color.glowzaPrimary }

    // Computed property to get completed bookings from the store.
    private var completedBookings: [Booking] {
        BookingStore.shared.completed
    }

    // Computed property to group bookings by service name for the chart!
    private var chartData: [(category: String, count: Int)] {
        let grouped = Dictionary(grouping: completedBookings, by: { $0.service.name })
        return grouped.map { (category: $0.key, count: $0.value.count) }
            .filter { $0.category != "Aesthetic" } // Keep filter just in case a service is named "Aesthetic"
            .sorted(by: { $0.count > $1.count }) // Sort by count descending!
    }

    // The chart view using the Charts framework.
    private var treatmentChart: some View {
        Chart {
            ForEach(chartData, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Category", item.category)
                )
                .foregroundStyle(brand.gradient)
                .cornerRadius(6)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .glowzaFont(size: 11, weight: .bold)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
            }
        }
        .chartXAxis(.hidden) // Hide the X axis as we have annotations!
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel()
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .frame(height: CGFloat(max(chartData.count * 40, 120))) // Dynamic height!
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedBookings.isEmpty {
                    emptyState
                } else {
                    List {
                        Section("Main Treatments") {
                            treatmentChart
                                .padding(.vertical, 8)
                        }
                        
                        Section("History") {
                            ForEach(completedBookings) { booking in
                                treatmentRow(booking)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Treatment History")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await BookingStore.shared.fetchUserBookings() // Fetch on appear!
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .glowzaFont(size: 16, weight: .medium)
                        .foregroundColor(brand)
                    }
                    .fixedSize()
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .glowzaFont(size: 48, weight: .light)
                .foregroundColor(brand.opacity(0.4))
            Text("No Treatments Yet")
                .glowzaFont(size: 17, weight: .semibold)
                .foregroundColor(Color(hex: "1A1A1A"))
            Text("Your completed treatments will appear here.")
                .glowzaFont(size: 14)
                .foregroundColor(Color(hex: "8A8A8A"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    // MARK: - Treatment Row
    private func treatmentRow(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(booking.service.name)
                .glowzaFont(size: 15, weight: .semibold)
                .foregroundColor(Color(hex: "1A1A1A"))
            Text(booking.salon.name)
                .glowzaFont(size: 13)
                .foregroundColor(Color(hex: "8A8A8A"))
            Text(booking.date.dateFormatted)
                .glowzaFont(size: 12)
                .foregroundColor(Color(hex: "ABABAB"))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TreatmentTrackingView()
}
