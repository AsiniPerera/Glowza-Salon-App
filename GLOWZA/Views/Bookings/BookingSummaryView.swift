import SwiftUI

// MARK: - Booking Summary View
struct BookingSummaryView: View {

    @Binding var draft: BookingDraft
    let onProceed: () -> Void
    let onBack: () -> Void

    @Environment(AppSettings.self) private var appSettings

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var total: Double { service.price }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: draft.date)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Back button
                    Button(action: onBack) {
                        ZStack {
                            Circle()
                                .fill(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                                .frame(width: 36, height: 36)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "1C1C1E"))
                        }
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Title section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Booking Summary")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1C1C1E"))
                        Text("Review your appointment details before payment")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "8E8E93"))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    // Appointment details card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("APPOINTMENT DETAILS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 0) {
                            summaryRow(icon: "building.2.fill", label: "Salon", value: draft.salon.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "sparkles", label: "Treatment", value: service.name)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "clock.fill", label: "Duration", value: service.duration)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "calendar", label: "Date", value: formattedDate)
                            Divider().padding(.leading, 52)
                            summaryRow(icon: "clock", label: "Time", value: draft.timeSlot)
                        }
                        .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Price breakdown card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRICE SUMMARY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        VStack(spacing: 12) {
                            HStack {
                                Text("Treatment Fee")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(hex: "8E8E93"))
                                Spacer()
                                Text("LKR \(Int(service.price))")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1C1C1E"))
                            }
                            Divider().padding(.vertical, 4)
                            HStack {
                                Text("Total Amount")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1C1C1E"))
                                Spacer()
                                Text("LKR \(Int(total))")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.glowzaPrimary)
                            }
                        }
                        .padding(16)
                        .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // Terms & Info card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("IMPORTANT")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "8E8E93"))
                            .tracking(0.5)

                        Text("Please arrive 10–15 minutes early. For changes or cancellations, contact the salon directly.")
                            .font(.system(size: 15))
                            .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.8) : Color(hex: "1C1C1E"))
                            .lineSpacing(2)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 128)
                }
            }

            // Bottom button
            VStack(spacing: 0) {
                Button(action: onProceed) {
                    Text("Proceed to Payment")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 330, height: 55)
                        .background(Color.glowzaPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
            }
        }
        .navigationBarHidden(true)
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color.white)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.glowzaPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8E8E93"))
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1C1C1E"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

