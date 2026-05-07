import SwiftUI

// MARK: - Treatment Tracking View
struct TreatmentTrackingView: View {

    @Environment(\.dismiss) private var dismiss

    private var brand: Color { Color.glowzaPrimary }

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
