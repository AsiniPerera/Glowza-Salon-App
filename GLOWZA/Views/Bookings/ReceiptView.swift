import SwiftUI

private let brand = Color(hex: "AF1C47")

// MARK: - Receipt View
struct ReceiptView: View {

    let booking: Booking
    let onDone: () -> Void

    @State private var appear = false
    @State private var checkScale: CGFloat = 0.3
    @State private var checkOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    successHeader
                    serviceCard.padding(.horizontal, 20).padding(.top, 24)
                    appointmentDetails.padding(.horizontal, 20).padding(.top, 16)
                    confirmationNotice.padding(.horizontal, 20).padding(.top, 16)
                    whatsNext.padding(.top, 28)
                    Spacer().frame(height: 110)
                }
            }
            bottomBar
        }
        .background(Color.white.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.3)) {
                checkScale = 1; checkOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.7)) { appear = true }
        }
    }

    // MARK: - Success Header
    private var successHeader: some View {
        ZStack {
            brand.opacity(0.06)
                .frame(maxWidth: .infinity)
                .frame(height: 220)

            VStack(spacing: 16) {
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(brand.opacity(0.10 - Double(i) * 0.03), lineWidth: 2)
                            .frame(width: CGFloat(80 + i * 28), height: CGFloat(80 + i * 28))
                    }
                    Circle().fill(brand.opacity(0.15)).frame(width: 80, height: 80)
                    Circle().fill(brand).frame(width: 64, height: 64)
                        .shadow(color: brand.opacity(0.30), radius: 16)
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(checkScale)
                .opacity(checkOpacity)

                VStack(spacing: 6) {
                    Text("Booking Confirmed!")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("Receipt #\(booking.receiptNumber)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(brand)
                }
                .opacity(appear ? 1 : 0)
            }
        }
    }

    // MARK: - Service Card
    private var serviceCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(brand.opacity(0.10)).frame(width: 54, height: 54)
                Image(systemName: booking.service.icon)
                    .font(.system(size: 22)).foregroundColor(brand)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(booking.service.name)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                    Text("PRO")
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(brand).clipShape(Capsule())
                }
                Text(booking.service.duration + " · " + booking.salon.location)
                    .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
        }
        .padding(16)
        .background(Color(hex: "FFF0F4"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(appear ? 1 : 0)
    }

    // MARK: - Appointment Details
    private var appointmentDetails: some View {
        VStack(spacing: 0) {
            Text("Appointment Details")
                .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 14)

            VStack(spacing: 12) {
                detailRow(icon: "calendar", label: "Date",
                          value: booking.date.formatted(.dateTime.weekday(.abbreviated).day().month(.wide).year()))
                detailRow(icon: "clock.fill", label: "Time", value: booking.timeSlot)
                Button(action: {}) {
                    detailRow(icon: "mappin.circle.fill", label: "Salon",
                              value: booking.salon.name, showChevron: true)
                }
                detailRow(icon: "checkmark.seal.fill", label: "Amount Paid",
                          value: "LKR \(Int(booking.amountPaid))", valueColor: Color(hex: "00A878"))
            }
        }
        .padding(18)
        .background(Color(hex: "F9F9F9"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(appear ? 1 : 0)
    }

    private func detailRow(icon: String, label: String, value: String,
                           valueColor: Color = Color(hex: "1A1A1A"),
                           showChevron: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundColor(brand)
                .frame(width: 28)
            Text(label).font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(valueColor)
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11)).foregroundColor(Color(hex: "ABABAB"))
            }
        }
    }

    // MARK: - Confirmation Notice
    private var confirmationNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 18)).foregroundColor(brand)
            Text("A confirmation has been sent to your email. You'll receive a reminder 24 hours before your appointment.")
                .font(.system(size: 12)).foregroundColor(Color(hex: "6B6B6B")).lineSpacing(3)
        }
        .padding(14)
        .background(Color(hex: "FFF0F4"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(appear ? 1 : 0)
    }

    // MARK: - What's Next
    private var whatsNext: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's Next?")
                .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                nextTile(icon: "arrow.down.to.line.circle.fill", label: "Download Receipt") {}
                nextTile(icon: "calendar.badge.plus", label: "Add to Calendar") {}
                nextTile(icon: "list.bullet.clipboard.fill", label: "View Booking") {}
                nextTile(icon: "house.fill", label: "Back to Home") { onDone() }
            }
            .padding(.horizontal, 20)
        }
        .opacity(appear ? 1 : 0)
    }

    private func nextTile(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24)).foregroundColor(brand)
                    .frame(width: 48, height: 48)
                    .background(brand.opacity(0.08))
                    .clipShape(Circle())
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color(hex: "F9F9F9"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)
            VStack(spacing: 8) {
                Button(action: onDone) {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: brand.opacity(0.28), radius: 10, x: 0, y: 4)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 5) {
                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(brand.opacity(0.6))
                    Text("100% Secure Payments").font(.system(size: 11)).foregroundColor(Color(hex: "ABABAB"))
                }
            }
            .padding(.vertical, 16).padding(.bottom, 8)
            .background(Color.white)
        }
        .opacity(appear ? 1 : 0)
    }
}

#Preview {
    let salon = SalonCatalog.shared.salons[0]
    let booking = Booking(
        id: UUID(), salon: salon, service: salon.services[0],
        date: Date(), timeSlot: "10:00 AM",
        receiptNumber: "GLZ-12345", paymentMethod: .card,
        amountPaid: 3850, signatureImage: nil, status: .upcoming, review: nil
    )
    return ReceiptView(booking: booking, onDone: {})
}
