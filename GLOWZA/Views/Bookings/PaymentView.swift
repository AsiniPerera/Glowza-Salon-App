import SwiftUI

private let brand = Color(hex: "FF006E")

private enum PaymentStage {
    case summary
    case method
}

struct PaymentView: View {

    @Binding var draft: BookingDraft
    let onPay: (Booking) -> Void
    let onBack: () -> Void

    @State private var stage: PaymentStage = .summary
    @State private var isPaying = false
    @State private var selectedSavedCard = "**** 2345"

    private var service: SalonService { draft.service ?? draft.salon.services[0] }
    private var subtotal: Double { service.price }
    private var tax: Double { subtotal * 0.10 }
    private var total: Double { subtotal + tax }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(hex: "F1F1F1").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if stage == .summary {
                        bookingSummaryContent
                    } else {
                        paymentMethodContent
                    }
                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
            }

            bottomButton
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                if stage == .summary {
                    onBack()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { stage = .summary }
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "5C5E65"))
            }
            Spacer()
        }
    }

    private var bookingSummaryContent: some View {
        VStack(spacing: 18) {
            Text("Booking Summary")
                .font(.system(size: 48, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: "1F2126"))
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                Image("SplashLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 62)
                Text("GLOWZA")
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .tracking(2)
                    .foregroundColor(Color(hex: "7B7D84"))
            }

            Text("THANK YOU FOR YOUR BOOKING.")
                .font(.system(size: 27, weight: .medium))
                .tracking(1)
                .foregroundColor(brand)

            Text("YOUR APPOINTMENT HAS BEEN\nSUCCESSFULLY SCHEDULED.")
                .font(.system(size: 16, weight: .medium))
                .tracking(1.3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "3C3F45"))
                .frame(maxWidth: .infinity)

            Text(summaryMultiline)
                .font(.system(size: 14, weight: .medium))
                .tracking(1)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color(hex: "2D2F35"))

            Text("PLEASE ARRIVE 10–15 MINUTES EARLY. CONTACT THE\nSALON FOR ANY CHANGES OR CANCELLATIONS. WE\nLOOK FORWARD TO SERVING YOU.")
                .font(.system(size: 11, weight: .medium))
                .tracking(1.3)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(hex: "4B4E55"))
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var paymentMethodContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Selected Payment Method")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "1F2126"))

            paymentOptionRow(
                title: "Credit/ Debit Card",
                selected: draft.paymentMethod == .card,
                action: { draft.paymentMethod = .card }
            )

            if draft.paymentMethod == .card {
                VStack(spacing: 14) {
                    savedCardRow(label: "**** 2345", iconText: "◉", iconColor: .orange)
                    savedCardRow(label: "**** 3456", iconText: "VISA", iconColor: Color(hex: "1554D1"))
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("Add Card")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "0E58E8"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            paymentOptionRow(
                title: "Apple Pay",
                selected: draft.paymentMethod == .online,
                trailingText: "Pay",
                action: { draft.paymentMethod = .online }
            )

            paymentOptionRow(
                title: "Google Pay",
                selected: draft.paymentMethod == .cash,
                trailingText: "GPay",
                action: { draft.paymentMethod = .cash }
            )
        }
    }

    private func paymentOptionRow(
        title: String,
        selected: Bool,
        trailingText: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Circle()
                    .stroke(selected ? brand : Color(hex: "D1D2D7"), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if selected {
                            Circle().fill(brand).frame(width: 10, height: 10)
                        }
                    }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2A2C32"))
                Spacer()
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "2A2C32"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: "F6F6F8"))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func savedCardRow(label: String, iconText: String, iconColor: Color) -> some View {
        Button(action: { selectedSavedCard = label }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 44, height: 30)
                    .overlay {
                        Text(iconText)
                            .font(.system(size: iconText == "VISA" ? 12 : 14, weight: .bold))
                            .foregroundColor(iconColor)
                    }
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: "D9DADE"), lineWidth: 1))
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "2A2C32"))
            Spacer()
                Circle()
                    .stroke(selectedSavedCard == label ? brand : Color(hex: "D0D1D5"), lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .overlay {
                        if selectedSavedCard == label {
                            Circle().fill(brand).frame(width: 10, height: 10)
                        }
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bottomButton: some View {
        VStack(spacing: 0) {
            Button(action: {
                if stage == .summary {
                    withAnimation(.easeInOut(duration: 0.2)) { stage = .method }
                } else {
                    processPayment()
                }
            }) {
                HStack(spacing: 8) {
                    if isPaying {
                        ProgressView().tint(.white)
                    } else {
                        Text(stage == .summary ? "Pay Securely" : "Pay Now")
                            .font(.system(size: 36, weight: .semibold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(brand)
                .clipShape(Capsule())
            }
            .disabled(isPaying)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(hex: "F1F1F1"))
        }
    }

    private var summaryMultiline: String {
        let date = draft.date.formatted(.dateTime.day().month(.wide).year())
        let time = draft.timeSlot.isEmpty ? "09:30 AM" : draft.timeSlot
        return """
        CLIENT NAME: ASINI PERERA
        SERVICE/TREATMENT: \(service.name.uppercased())
        SALON: \(draft.salon.name.uppercased())
        DATE & TIME: \(date.uppercased()), \(time)
        SPECIALIST: NADEESHA SILVA
        TOTAL COST: LKR \(Int(total))
        """
    }

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
