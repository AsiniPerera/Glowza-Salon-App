import SwiftUI

// MARK: - Booking Confirmed (Thank you & Booking Summary screen)
// This view appears after a successful booking. It shows a summary and a nice animation!
struct BookingConfirmedView: View {

    let booking: Booking // The booking data passed from the previous screen.
    let onBackToHome: () -> Void // Callback to navigate back to the home screen.

    // State variables for managing the intro animations.
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: Double = 0.0
    @State private var ring1Scale: CGFloat = 0.5
    @State private var ring1Opacity: Double = 0.0
    @State private var ring2Scale: CGFloat = 0.5
    @State private var ring2Opacity: Double = 0.0
    @State private var contentOpacity: Double = 0.0
    @State private var contentOffset: CGFloat = 28

    private var brand: Color { Color.glowzaPrimary }
    private let surfaceColor = Color(hex: "F9F9F9")

    var body: some View {
        ZStack {
            surfaceColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Animated Hero Section ──────────────────────────────
                // This creates layered rings that scale up when the view appears.
                ZStack {
                    // Outer pulsing ring.
                    Circle()
                        .stroke(brand.opacity(0.12), lineWidth: 1)
                        .frame(width: 130, height: 130)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    // Inner pulsing ring.
                    Circle()
                        .stroke(brand.opacity(0.28), lineWidth: 1.5)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ring1Scale)
                        .opacity(ring1Opacity)

                    // Static filled circle.
                    Circle()
                        .fill(brand.opacity(0.10))
                        .frame(width: 70, height: 70)

                    // Static border circle.
                    Circle()
                        .stroke(brand, lineWidth: 2)
                        .frame(width: 70, height: 70)

                    // Checkmark icon.
                    Image(systemName: "checkmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(brand)
                }
                .scaleEffect(checkScale)
                .opacity(checkOpacity)

                Spacer().frame(height: 28)

                // ── Title ──────────────────────────────────────────────
                VStack(spacing: 8) {
                    Text("Thank You!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "1F2126"))
                    Text("Your booking is confirmed")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "8E8E93"))
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer().frame(height: 15)

                Text("Receipt #\(booking.receiptNumber)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                Spacer().frame(height: 15)

                // ── Details card ───────────────────────────────────────
                // Shows the summary of what was booked.
                VStack(spacing: 0) {
                    detailRow(icon: "sparkles", label: "Treatment", value: booking.service.name, color: brand)
                    Divider().padding(.leading, 52).opacity(0.4)
                    detailRow(icon: "building.2.fill", label: "Salon", value: booking.salon.name, color: brand)
                    Divider().padding(.leading, 52).opacity(0.4)
                    detailRow(icon: "calendar", label: "Date", value: formattedDate, color: brand)
                    Divider().padding(.leading, 52).opacity(0.4)
                    detailRow(icon: "clock.fill", label: "Time", value: booking.timeSlot, color: brand)
                    Divider().padding(.leading, 52).opacity(0.4)
                    detailRow(icon: "creditcard.fill", label: "Amount Paid", value: "LKR \(Int(booking.amountPaid))", color: brand)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 6)
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
                .offset(y: contentOffset)

                Spacer()

                // ── Back to Home button ────────────────────────────────
                Button(action: onBackToHome) {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Back to Home")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(contentOpacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear { animateIn() } // Trigger animations when view appears!
    }

    // MARK: - Animation Logic
    // Smoothly animates the UI elements in sequence.
    private func animateIn() {
        // Spring animation for the checkmark!
        withAnimation(.spring(response: 0.52, dampingFraction: 0.65).delay(0.08)) {
            checkScale = 1.0
            checkOpacity = 1.0
        }
        // Fade and scale for the first ring.
        withAnimation(.easeOut(duration: 0.7).delay(0.28)) {
            ring1Scale = 1.0
            ring1Opacity = 1.0
        }
        // Fade and scale for the second ring.
        withAnimation(.easeOut(duration: 0.95).delay(0.44)) {
            ring2Scale = 1.0
            ring2Opacity = 0.0 // Fades out at the end!
        }
        // Slide up animation for the content card.
        withAnimation(.easeOut(duration: 0.48).delay(0.32)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
    }

    // MARK: - Row helper
    // A helper function to create a consistent layout for each detail row.
    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "8E8E93"))
                    .tracking(0.3)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2126"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // Helper to format the date nicely.
    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: booking.date)
    }
}
