import SwiftUI

// MARK: - Booking Confirmed (Thank you & Booking Summary screen)
struct BookingConfirmedView: View {

    let booking: Booking
    let onProceedToReceipt: () -> Void

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

                // ── Animated hero ──────────────────────────────────────
                ZStack {
                    Circle()
                        .stroke(brand.opacity(0.12), lineWidth: 1)
                        .frame(width: 170, height: 170)
                        .scaleEffect(ring2Scale)
                        .opacity(ring2Opacity)

                    Circle()
                        .stroke(brand.opacity(0.28), lineWidth: 1.8)
                        .frame(width: 126, height: 126)
                        .scaleEffect(ring1Scale)
                        .opacity(ring1Opacity)

                    Circle()
                        .fill(brand.opacity(0.10))
                        .frame(width: 90, height: 90)

                    Circle()
                        .stroke(brand, lineWidth: 2.5)
                        .frame(width: 90, height: 90)

                    Image(systemName: "checkmark")
                        .font(.system(size: 38, weight: .bold))
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

                // ── View Receipt button ────────────────────────────────
                Button(action: onProceedToReceipt) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("View Receipt & Download")
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
        .onAppear { animateIn() }
    }

    // MARK: - Animation
    private func animateIn() {
        withAnimation(.spring(response: 0.52, dampingFraction: 0.65).delay(0.08)) {
            checkScale = 1.0
            checkOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.7).delay(0.28)) {
            ring1Scale = 1.0
            ring1Opacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.95).delay(0.44)) {
            ring2Scale = 1.0
            ring2Opacity = 0.0
        }
        withAnimation(.easeOut(duration: 0.48).delay(0.32)) {
            contentOpacity = 1.0
            contentOffset = 0
        }
    }

    // MARK: - Row helper
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

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM yyyy"
        return f.string(from: booking.date)
    }
}
