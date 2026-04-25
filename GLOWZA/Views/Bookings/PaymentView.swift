import SwiftUI

private let brand = Color(hex: "AF1C47")

struct PaymentView: View {

    @Binding var draft: BookingDraft
    let onPay: (Booking) -> Void
    let onBack: () -> Void

    @State private var isPaying = false

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var subtotal: Double { service.price }
    private var tax: Double { subtotal * 0.10 }
    private var total: Double { subtotal + tax }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "F5F5F5"))
                        .clipShape(Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Payment").font(.system(size: 17, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                    Text("Step 3 of 3").font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 18)).foregroundColor(brand.opacity(0.7))
            }
            .padding(.horizontal, 20).padding(.vertical, 14)
            .background(Color.white)

            // Progress bar (3/3 filled)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(brand).frame(height: 4)
                }
            }
            .padding(.horizontal, 20)

            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    summaryCard
                    paymentMethodSection
                    priceBreakdownCard
                    securityNote
                    Spacer().frame(height: 90)
                }
                .padding(.horizontal, 20).padding(.top, 20)
            }

            // Pay button
            bottomBar
        }
        .background(Color.white.ignoresSafeArea())
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(brand.opacity(0.10)).frame(width: 54, height: 54)
                    Image(systemName: service.icon)
                        .font(.system(size: 22)).foregroundColor(brand)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                    Text(draft.salon.name)
                        .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22)).foregroundColor(brand)
            }
            .padding(16)

            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)

            VStack(spacing: 12) {
                summaryRow(icon: "calendar",      label: "Date",     value: draft.date.formatted(date: .long, time: .omitted))
                summaryRow(icon: "clock.fill",    label: "Time",     value: draft.timeSlot)
                summaryRow(icon: "timer",         label: "Duration", value: service.duration)
                summaryRow(icon: "mappin.fill",   label: "Location", value: draft.salon.location)
            }
            .padding(16)
        }
        .background(Color(hex: "F9F9F9"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(brand).frame(width: 20)
            Text(label).font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "1A1A1A"))
        }
    }

    // MARK: - Payment Method
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))

            ForEach(PaymentMethodType.allCases, id: \.self) { method in
                Button(action: { draft.paymentMethod = method }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(draft.paymentMethod == method ? brand : Color(hex: "F5F5F5"))
                                .frame(width: 42, height: 42)
                            Image(systemName: method.icon)
                                .font(.system(size: 17))
                                .foregroundColor(draft.paymentMethod == method ? .white : Color(hex: "8A8A8A"))
                        }
                        Text(method.rawValue)
                            .font(.system(size: 14, weight: draft.paymentMethod == method ? .semibold : .regular))
                            .foregroundColor(Color(hex: "1A1A1A"))
                        Spacer()
                        // Radio dot
                        ZStack {
                            Circle().stroke(Color(hex: "CCCCCC"), lineWidth: 1.5).frame(width: 22, height: 22)
                            if draft.paymentMethod == method {
                                Circle().fill(brand).frame(width: 13, height: 13)
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(draft.paymentMethod == method ? brand : Color(hex: "EBEBEB"), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Price Breakdown
    private var priceBreakdownCard: some View {
        VStack(spacing: 12) {
            priceRow(label: "Service Fee", value: "LKR \(Int(subtotal))")
            priceRow(label: "Tax (10%)", value: "LKR \(Int(tax))")
            Rectangle().fill(Color(hex: "EBEBEB")).frame(height: 1)
            HStack {
                Text("Total")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Spacer()
                Text("LKR \(Int(total))")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(brand)
            }
        }
        .padding(16)
        .background(Color(hex: "F9F9F9"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func priceRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            Spacer()
            Text(value).font(.system(size: 13, weight: .medium)).foregroundColor(Color(hex: "1A1A1A"))
        }
    }

    // MARK: - Security Note
    private var securityNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 16)).foregroundColor(brand)
            Text("Your payment is encrypted and processed securely. We never store your card details.")
                .font(.system(size: 12)).foregroundColor(Color(hex: "6B6B6B")).lineSpacing(3)
        }
        .padding(14)
        .background(Color(hex: "FFF0F4"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)
            VStack(spacing: 8) {
                Button(action: processPayment) {
                    HStack(spacing: 10) {
                        if isPaying {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "lock.fill").font(.system(size: 14))
                            Text("Pay LKR \(Int(total))")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: brand.opacity(0.28), radius: 10, x: 0, y: 4)
                }
                .disabled(isPaying)
                .padding(.horizontal, 20)

                HStack(spacing: 5) {
                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(brand.opacity(0.6))
                    Text("SSL Encrypted · 100% Secure").font(.system(size: 11)).foregroundColor(Color(hex: "ABABAB"))
                }
            }
            .padding(.vertical, 16).padding(.bottom, 8)
            .background(Color.white)
        }
    }

    // MARK: - Process Payment
    private func processPayment() {
        isPaying = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            let booking = Booking(
                id: UUID(),
                salon: draft.salon,
                service: service,
                date: draft.date,
                timeSlot: draft.timeSlot,
                receiptNumber: Booking.generateReceiptNumber(),
                paymentMethod: draft.paymentMethod,
                amountPaid: total,
                signatureImage: draft.signatureImage,
                status: .upcoming,
                review: nil
            )
            isPaying = false
            onPay(booking)
        }
    }
}
