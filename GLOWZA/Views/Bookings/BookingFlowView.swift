import SwiftUI

// MARK: - Booking Flow Steps
enum BookingFlowStep {
    case dateTime, summary, consent, payment, receipt
}

// MARK: - BookingFlowView (Container)
struct BookingFlowView: View {

    @State var draft: BookingDraft
    @State private var step: BookingFlowStep = .dateTime
    @State private var completedBooking: Booking? = nil
    @State private var isSubmittingPayment = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch step {
        case .dateTime:
            BookAppointmentView(draft: $draft) {
                step = .summary
            } onBack: {
                dismiss()
            }
        case .summary:
            BookingSummaryView(draft: $draft) {
                step = .consent
            } onBack: {
                step = .dateTime
            }
        case .consent:
            ConsentFormView(draft: $draft) {
                step = .payment
            } onBack: {
                step = .summary
            }
        case .payment:
            PaymentView(draft: $draft) { booking in
                guard !isSubmittingPayment else { return }
                isSubmittingPayment = true

                // Move straight to receipt to avoid duplicate confirmation screens.
                completedBooking = booking

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMM d, yyyy"
                let dateString = dateFormatter.string(from: booking.date)

                NotificationManager.shared.notifyBookingSuccess(
                    serviceName: booking.service.name,
                    salonName: booking.salon.name,
                    time: booking.timeSlot,
                    date: dateString
                )

                withAnimation(.easeInOut(duration: 0.3)) {
                    step = .receipt
                }

                // Add to local store immediately so BookingsView shows it right away
                BookingStore.shared.add(booking)

                // Save appointment to iOS Calendar (simulator/device) in background.
                Task {
                    let result = await EventKitService.shared.saveBookingToCalendar(booking)

                    await MainActor.run {
                        switch result {
                        case .saved:
                            NotificationManager.shared.showNotification(
                                NotificationItem(
                                    title: "Added to Calendar",
                                    subtitle: "Your appointment was saved in Calendar.",
                                    icon: "calendar.badge.checkmark",
                                    type: .info
                                ),
                                duration: 2.5
                            )
                        case .permissionDenied:
                            NotificationManager.shared.showNotification(
                                NotificationItem(
                                    title: "Calendar Permission Needed",
                                    subtitle: "Enable Calendar access in Settings to auto-save bookings.",
                                    icon: "calendar.badge.exclamationmark",
                                    type: .warning
                                ),
                                duration: 3.0
                            )
                        case .noWritableCalendar:
                            NotificationManager.shared.showNotification(
                                NotificationItem(
                                    title: "No Writable Calendar",
                                    subtitle: "Create or enable a calendar account to save appointments.",
                                    icon: "calendar",
                                    type: .warning
                                ),
                                duration: 3.0
                            )
                        case .saveFailed:
                            NotificationManager.shared.showNotification(
                                NotificationItem(
                                    title: "Calendar Save Failed",
                                    subtitle: "Could not save this booking to Calendar.",
                                    icon: "calendar.badge.exclamationmark",
                                    type: .error
                                ),
                                duration: 3.0
                            )
                        }
                    }
                }

                Task {
                    await BookingStore.shared.createBooking(
                        salonName: booking.salon.name,
                        salonLocation: booking.salon.location,
                        serviceName: booking.service.name,
                        servicePrice: booking.service.price,
                        date: booking.date,
                        timeSlot: booking.timeSlot,
                        paymentMethod: booking.paymentMethod.rawValue,
                        amountPaid: booking.amountPaid,
                        receiptNumber: booking.receiptNumber
                    )

                    await MainActor.run {
                        isSubmittingPayment = false
                    }

                    if BookingStore.shared.error != nil {
                        await MainActor.run {
                            NotificationManager.shared.notifyBookingFailure(
                                message: BookingStore.shared.error ?? "Could not complete your booking. Please try again."
                            )
                        }
                    }
                }
            } onBack: {
                if isSubmittingPayment { return }
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

    @Environment(AppSettings.self) private var appSettings

    private let accent = Color(hex: "962043")
    private var dark: Color { appSettings.isDarkMode ? .white : Color(hex: "2A2C32") }
    private var selectedService: SalonService { draft.service ?? draft.salon.services[0] }

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
            (appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white).ignoresSafeArea()

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
            if draft.service == nil {
                draft.service = draft.salon.services.first
            }
            draft.date = days[selectedDateOffset].date
            selectedTime = draft.timeSlot
        }
    }

    private var topBack: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "5F6168"))
        }
        .padding(.top, 2)
    }

    private var serviceSelectionHeader: some View {
        Text("Select Date & Time")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
            .tracking(1.4)
            .padding(.top, 6)
    }

    private var selectedServiceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.salon.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(dark)
                Text(selectedService.name)
                    .font(.system(size: 13))
                    .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.6) : Color(hex: "7A7D84"))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 86)
        .background(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "E5E2E2"))
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
                Text("Select Date")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
                    .tracking(1.2)
                Spacer()
                Text(monthYear)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
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
                            .foregroundColor(isSelected ? .white : (appSettings.isDarkMode ? .white : Color(hex: "3B3D42")))
                            .frame(width: 64, height: 96)
                            .background(isSelected ? accent : (appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "EAE7E7")))
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
            Text("Available Times")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
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
                                isSelected ? accent : (appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F1F1F1"))
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
            .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
        }
    }
}
