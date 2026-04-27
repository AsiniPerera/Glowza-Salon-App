import SwiftUI

// MARK: - Booking Flow Steps
enum BookingFlowStep {
    case dateTime, consent, summary, payment, receipt
}

// MARK: - BookingFlowView (Container)
struct BookingFlowView: View {

    @State var draft: BookingDraft
    @State private var step: BookingFlowStep = .dateTime
    @State private var completedBooking: Booking? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch step {
        case .dateTime:
            BookAppointmentView(draft: $draft) {
                step = .consent
            } onBack: {
                dismiss()
            }
        case .consent:
            ConsentFormView(draft: $draft) {
                step = .summary
            } onBack: {
                step = .dateTime
            }
        case .summary:
            BookingSummaryView(draft: $draft) {
                step = .payment
            } onBack: {
                step = .consent
            }
        case .payment:
            PaymentView(draft: $draft) { booking in
                Task {
                    await BookingStore.shared.createBooking(
                        salonName: booking.salon.name,
                        salonLocation: booking.salon.location,
                        serviceName: booking.service.name,
                        servicePrice: booking.service.price,
                        date: booking.date,
                        timeSlot: booking.timeSlot,
                        paymentMethod: booking.paymentMethod.rawValue,
                        amountPaid: booking.amountPaid
                    )
                }
                completedBooking = booking
                step = .receipt
            } onBack: {
                step = .consent
            }
        case .receipt:
            if let booking = completedBooking {
                ReceiptView(booking: booking) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Book Appointment View (Date + Time selection)
struct BookAppointmentView: View {

    @Binding var draft: BookingDraft
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var selectedDateOffset: Int = 0
    @State private var selectedTime: String = ""

    private let accent = Color(hex: "962043")
    private let dark = Color(hex: "2A2C32")

    private var days: [(label: String, num: Int, date: Date)] {
        (0..<10).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let day = Calendar.current.component(.day, from: date)
            let wday = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][Calendar.current.component(.weekday, from: date) - 1]
            return (wday, day, date)
        }
    }

    private var monthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: draft.date).uppercased()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBack
                    serviceSelectionHeader
                    selectedServiceCard
                    Divider().overlay(Color(hex: "E4E4E7"))
                    dateSection
                    timeSection
                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 20)
            }

            bottomBar
        }
        .navigationBarHidden(true)
        .onAppear {
            draft.date = days[selectedDateOffset].date
            selectedTime = draft.timeSlot
        }
    }

    private var topBack: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "5F6168"))
        }
        .padding(.top, 2)
    }

    private var serviceSelectionHeader: some View {
        Text("SELECT SALON & SERVICES")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(Color(hex: "56585F"))
            .tracking(1.4)
            .padding(.top, 6)
    }

    private var selectedServiceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.salon.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(dark)
                Text(draft.service?.name ?? "Skin Facials")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "7A7D84"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 86)
        .background(Color(hex: "E5E2E2"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accent, lineWidth: 1.6)
                .mask(
                    HStack {
                        Rectangle().frame(width: 6)
                        Spacer()
                    }
                )
        )
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("SELECT DATE")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "56585F"))
                    .tracking(1.2)
                Spacer()
                Text(monthYear)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "56585F"))
                    .tracking(1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(days.indices, id: \.self) { i in
                        let item = days[i]
                        let isSelected = i == selectedDateOffset
                        Button(action: {
                            selectedDateOffset = i
                            draft.date = item.date
                        }) {
                            VStack(spacing: 6) {
                                Text(item.label)
                                    .font(.system(size: 14, weight: .medium))
                                Text("\(item.num)")
                                    .font(.system(size: 34, weight: .medium, design: .serif))
                            }
                            .foregroundColor(isSelected ? .white : Color(hex: "3B3D42"))
                            .frame(width: 64, height: 96)
                            .background(isSelected ? accent : Color(hex: "EAE7E7"))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AVAILABLE TIMES")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "56585F"))
                .tracking(1.2)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(BookingDraft.timeSlots, id: \.time) { slot in
                    let isSelected = selectedTime == slot.time
                    Button(action: {
                        guard slot.available else { return }
                        selectedTime = slot.time
                        draft.timeSlot = slot.time
                    }) {
                        Text(slot.time)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(
                                !slot.available ? Color(hex: "BDBFC5") : (isSelected ? .white : dark)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                isSelected ? accent : Color(hex: "F1F1F1")
                            )
                            .overlay(
                                Capsule().stroke(Color(hex: "BBBBBE"), lineWidth: isSelected ? 0 : 1)
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(!slot.available)
                }
            }
            .padding(.bottom, 6)
        }
    }

    private var bottomBar: some View {
        let canProceed = !selectedTime.isEmpty
        return VStack(spacing: 0) {
            Button(action: {
                if canProceed { onNext() }
            }) {
                Text("Confirm")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(canProceed ? accent : Color(hex: "D4829E"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!canProceed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
        }
    }
}
