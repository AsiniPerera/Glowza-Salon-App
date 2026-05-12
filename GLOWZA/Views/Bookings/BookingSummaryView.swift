import SwiftUI

// MARK: - Booking Summary View
struct BookingSummaryView: View {

    @Binding var draft: BookingDraft
    let onProceed: () -> Void
    let onBack: () -> Void

    private var appSettings: AppSettings { AppSettings.shared }

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: draft.date)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.themePage).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    GlowzaCircleBackButton(action: onBack)
                        .padding(.top, 24)
                        .padding(.horizontal, 20)

                    Spacer().frame(height: 32)

                    // Title section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Booking Summary")
                            .glowzaFont(size: 28, weight: .bold)
                            .foregroundColor(appSettings.themeText)
                        Text("Review your appointment details before payment")
                            .glowzaFont(size: 17)
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 32)

                    // Appointment details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPOINTMENT DETAILS")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            summaryRow(icon: "storefront", label: "Salon", value: draft.salon.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: service.icon, label: "Treatment", value: service.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "clock.fill", label: "Duration", value: service.duration)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "calendar", label: "Date", value: formattedDate)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "clock", label: "Time", value: draft.timeSlot)
                        }
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Price breakdown card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRICE SUMMARY")
                            .glowzaFont(size: 11, weight: .semibold)
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 12) {

                            HStack {
                                Text("Total Amount")
                                    .glowzaFont(size: 17, weight: .semibold)
                                    .foregroundColor(appSettings.themeText)
                                Spacer()
                                Text("LKR \(Int(total))")
                                    .glowzaFont(size: 17, weight: .semibold)
                                    .foregroundColor(.glowzaPrimary)
                            }
                        }
                        .padding(16)
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)



                    Spacer().frame(height: 128)
                }
            }

            // Bottom button
            VStack(spacing: 0) {
                Button(action: onProceed) {
                    Text("Proceed to Payment")
                        .glowzaFont(size: 17, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(Color.glowzaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(appSettings.themeSurface)
            }
        }
        .navigationBarHidden(true)
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(appSettings.themeRaised)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .glowzaFont(size: 14, weight: .semibold)
                    .foregroundColor(.glowzaPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .glowzaFont(size: 12)
                    .foregroundColor(Color(hex: "8E8E93"))
                Text(value)
                    .glowzaFont(size: 15, weight: .semibold)
                    .foregroundColor(appSettings.themeText)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

