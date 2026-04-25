import SwiftUI

// MARK: - Booking Flow Steps
enum BookingFlowStep {
    case dateTime, consent, payment, receipt
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
                step = .payment
            } onBack: {
                step = .dateTime
            }
        case .payment:
            PaymentView(draft: $draft) { booking in
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

    @State private var selectedDateOffset: Int = 1
    @State private var selectedTime: String    = ""

    private let dark   = Color(hex: "1A1A1A")
    private let accent = Color(hex: "AF1C47")
    private let bg     = Color.white

    private var weekDays: [(label: String, num: Int, date: Date)] {
        (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
            let day  = Calendar.current.component(.day, from: date)
            let wday = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"][Calendar.current.component(.weekday, from: date) - 1]
            return (wday, day, date)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    flowHeader
                    serviceCard
                    salonCard
                    dateSection
                    timeSection
                    bookingSummaryBox
                    secureNotice
                    Spacer().frame(height: 100)
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            bottomBar
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    private var flowHeader: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(dark)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Book Appointment")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(dark)
                Text("Secure your beauty time")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
            Image(systemName: "shield.checkered")
                .font(.system(size: 18))
                .foregroundColor(accent)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Selected Service Card
    private var serviceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected Service")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 20)

            if let service = draft.service {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "FFF0F4"))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: service.icon)
                                .font(.system(size: 26))
                                .foregroundColor(accent)
                        )
                    VStack(alignment: .leading, spacing: 5) {
                        Text(service.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(dark)
                        HStack(spacing: 12) {
                            Label(service.duration, systemImage: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8A8A8A"))
                        }
                    }
                    Spacer()
                    Text("LKR \(Int(service.price))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accent)
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
            } else {
                Text("No service selected")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Selected Salon Card
    private var salonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected Salon")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 20)

            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "FFF0F4"))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 22))
                            .foregroundColor(accent)
                    )
                VStack(alignment: .leading, spacing: 5) {
                    Text(draft.salon.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(dark)
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "8A8A8A"))
                        Text(draft.salon.location)
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "AF1C47"))
                        Text(String(format: "%.1f", draft.salon.rating))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(dark)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            .padding(14)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Date Section
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Date")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(dark)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 16))
                    .foregroundColor(accent)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(weekDays.indices, id: \.self) { i in
                        let day = weekDays[i]
                        let isSelected = selectedDateOffset == i
                        Button(action: {
                            selectedDateOffset = i
                            draft.date = day.date
                        }) {
                            VStack(spacing: 4) {
                                Text(day.label)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isSelected ? .white : Color(hex: "8A8A8A"))
                                Text("\(day.num)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(isSelected ? .white : dark)
                            }
                            .frame(width: 52, height: 66)
                            .background(isSelected ? Color(hex: "AF1C47") : Color.white)
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Time")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(dark)
                .padding(.horizontal, 20)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(BookingDraft.timeSlots, id: \.time) { slot in
                    let isSelected = selectedTime == slot.time
                    Button(action: {
                        guard slot.available else { return }
                        selectedTime = slot.time
                        draft.timeSlot = slot.time
                    }) {
                        Text(slot.time)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(
                                !slot.available ? Color(hex: "C8B8B0") :
                                isSelected ? .white : dark
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                isSelected ? Color(hex: "AF1C47") :
                                !slot.available ? Color(hex: "F0EDED") : Color.white
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(isSelected ? 0 : 0.04), radius: 3, x: 0, y: 1)
                    }
                    .disabled(!slot.available)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Booking Summary Box
    private var bookingSummaryBox: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 16))
                    .foregroundColor(accent)
                Text("Booking Summary")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(dark)
            }

            VStack(spacing: 8) {
                summaryRow(label: "Service",
                           value: draft.service?.name ?? "Not selected")
                summaryRow(label: "Salon",   value: draft.salon.name)
                summaryRow(label: "Date",    value: formattedDate(draft.date))
                summaryRow(label: "Time",    value: selectedTime.isEmpty ? "Not selected" : selectedTime)
                summaryRow(label: "Duration", value: draft.service?.duration ?? "—")
            }

            Rectangle()
                .fill(Color(hex: "E8E0DC"))
                .frame(height: 1)
                .overlay(
                    HStack(spacing: 4) {
                        ForEach(0..<15, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(hex: "E8E0DC"))
                                .frame(width: 8, height: 1)
                            Spacer()
                        }
                    }
                )

            HStack {
                Text("Total")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(dark)
                Spacer()
                Text("LKR \(Int(draft.service?.price ?? 0))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accent)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 20)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "8A8A8A"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(dark)
                .multilineTextAlignment(.trailing)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE, d MMM yyyy"
        return f.string(from: date)
    }

    // MARK: - Secure Notice
    private var secureNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 13))
                .foregroundColor(accent)
            Text("Your booking is secure and confirmed instantly.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "8A8A8A"))
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        let canProceed = !selectedTime.isEmpty && draft.service != nil
        return VStack(spacing: 6) {
            Button(action: {
                if canProceed { onNext() }
            }) {
                HStack {
                    Spacer()
                    Text("Review Booking")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(canProceed ? Color(hex: "1A1A1A") : Color(hex: "A0A0A0"))
                .cornerRadius(14)
            }
            .disabled(!canProceed)

            HStack(spacing: 5) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "8A8A8A"))
                Text("100% Secure Payments")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: -4)
        )
    }
}
