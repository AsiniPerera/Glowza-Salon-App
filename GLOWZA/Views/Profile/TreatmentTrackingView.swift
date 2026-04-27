import SwiftUI

// MARK: - Treatment Tracking View
struct TreatmentTrackingView: View {

    @Environment(\.dismiss) private var dismiss

    private let brand = Color(hex: "962043")

    private var completedBookings: [Booking] {
        BookingStore.shared.bookings.filter { $0.status == .completed }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedBookings.isEmpty {
                    emptyState
                } else {
                    List(completedBookings) { booking in
                        treatmentRow(booking)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Treatment History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(brand)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(brand.opacity(0.4))
            Text("No Treatments Yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A1A"))
            Text("Your completed treatments will appear here.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A8A"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }

    private func treatmentRow(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(booking.service.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A1A"))
            Text(booking.salon.name)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8A8A8A"))
            Text(booking.date.dateFormatted)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "ABABAB"))
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TreatmentTrackingView()
}
