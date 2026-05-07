import SwiftUI

// MARK: - Booking Flow Steps
enum BookingFlowStep {
    case dateTime, summary, consent, payment, confirmation, receipt
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

                // Move to confirmation screen after payment
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
                    step = .confirmation
                }

                // Add to local store immediately so BookingsView shows it right away
                BookingStore.shared.add(booking)

                // ── Step 5: Sync to widget via App Group ──────────────────────
                WidgetBookingSyncService.shared.saveUpcomingBooking(booking)

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
        case .confirmation:
            if let booking = completedBooking {
                BookingConfirmedView(booking: booking) {
                    step = .receipt
                }
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

    @State private var selectedTime: String = ""
    @State private var displayMonth: Date = Date()

    @Environment(AppSettings.self) private var appSettings

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var selectedService: SalonService { draft.service ?? draft.salon.services[0] }

    // MARK: - Calendar Calculations
    private var monthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth).uppercased()
    }

    private var calendarDates: [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: displayMonth)!
        let numDays = range.count

        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let firstWeekday = calendar.component(.weekday, from: first) - 1 // 0 = Sunday

        let paddingDays = Array(repeating: Optional<Date>(nil), count: firstWeekday)
        let dateDays: [Date?] = (0..<numDays).map { day in
            calendar.date(byAdding: .day, value: day, to: first)!
        }

        let combined = paddingDays + dateDays
        let remainder = combined.count % 7
        let trailing = remainder == 0 ? [] : Array(repeating: Optional<Date>(nil), count: 7 - remainder)
        return combined + trailing
    }

    private var calendarWeeks: [[Date?]] {
        calendarDates.chunked(into: 7)
    }

    private var dayOfWeekHeaders: [String] {
        ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.themePage).ignoresSafeArea()

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
            displayMonth = draft.date
            selectedTime = draft.timeSlot
        }
    }

    private var topBack: some View {
        Button(action: onBack) {
            Image(systemName: "chevron.left")
                .glowzaFont(size: 20, weight: .semibold)
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "5F6168"))
        }
        .padding(.top, 2)
    }

    private var serviceSelectionHeader: some View {
        Text("Select Date & Time")
            .glowzaFont(size: 16, weight: .semibold)
            .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
            .tracking(1.4)
            .padding(.top, 6)
    }

    private var selectedServiceCard: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(accent)
                .frame(width: 4)
                .padding(.vertical, 14)
                .padding(.leading, 14)

            VStack(alignment: .leading, spacing: 10) {
                // Salon row
                HStack(spacing: 8) {
                    Text(draft.salon.name)
                        .glowzaFont(size: 16, weight: .semibold)
                        .foregroundColor(appSettings.themeText)
                }

                Divider()
                    .padding(.trailing, 16)

                // Service + meta row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedService.name)
                            .glowzaFont(size: 13, weight: .medium)
                            .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.85) : Color(hex: "3A3A3A"))
                        HStack(spacing: 10) {
                            Label(selectedService.duration, systemImage: "clock")
                                .glowzaFont(size: 11)
                                .foregroundColor(Color(hex: "8A8A8A"))
                            Label(selectedService.category, systemImage: "tag")
                                .glowzaFont(size: 11)
                                .foregroundColor(Color(hex: "8A8A8A"))
                        }
                    }
                    Spacer()
                    Text("LKR \(Int(selectedService.price))")
                        .glowzaFont(size: 14, weight: .bold)
                        .foregroundColor(accent)
                        .padding(.trailing, 16)
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 16)
        }
        .background(appSettings.isDarkMode ? Color(hex: "1E1E1E") : Color(hex: "FAFAFA"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(appSettings.isDarkMode ? 0.3 : 0.07), radius: 8, x: 0, y: 3)
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: {
                    let cal = Calendar.current
                    displayMonth = cal.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                }) {
                    Image(systemName: "chevron.left")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(accent)
                }
                
                Text(monthYear)
                    .glowzaFont(size: 16, weight: .semibold)
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
                    .tracking(1)
                
                Spacer()
                
                Button(action: {
                    let cal = Calendar.current
                    displayMonth = cal.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                }) {
                    Image(systemName: "chevron.right")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(accent)
                }
            }

            // Day of week headers
            GeometryReader { geo in
                let cellW = geo.size.width / 7
                HStack(spacing: 0) {
                    ForEach(dayOfWeekHeaders, id: \.self) { day in
                        Text(day)
                            .glowzaFont(size: 10, weight: .semibold)
                            .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.5) : Color(hex: "8A8D94"))
                            .frame(width: cellW, height: 26)
                    }
                }
            }
            .frame(height: 26)

            // Calendar grid
            GeometryReader { geo in
                let cellW = geo.size.width / 7
                let cellH: CGFloat = 34
                let weeks = calendarWeeks
                VStack(spacing: 4) {
                    ForEach(weeks.indices, id: \.self) { weekIndex in
                        HStack(spacing: 0) {
                            ForEach(weeks[weekIndex].indices, id: \.self) { dayIndex in
                                let date = weeks[weekIndex][dayIndex]
                                let isSelected = date.map { Calendar.current.isDate($0, inSameDayAs: draft.date) } ?? false
                                let isFuture = date.map { $0 >= Calendar.current.startOfDay(for: Date()) } ?? false

                                ZStack {
                                    if let date = date {
                                        let day = Calendar.current.component(.day, from: date)
                                        Button(action: {
                                            guard isFuture else { return }
                                            draft.date = date
                                        }) {
                                            Text("\(day)")
                                                .glowzaFont(size: 13, weight: .medium)
                                                .foregroundColor(
                                                    !isFuture ? Color(hex: "C5C5C5") :
                                                    isSelected ? .white : (appSettings.themeText)
                                                )
                                                .frame(width: cellW - 4, height: cellH - 4)
                                                .background(
                                                    Group {
                                                        if isSelected {
                                                            Circle().fill(accent)
                                                        } else if isFuture {
                                                            Circle().fill(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F5F5F7"))
                                                        } else {
                                                            Circle().fill(Color.clear)
                                                        }
                                                    }
                                                )
                                        }
                                        .disabled(!isFuture)
                                    }
                                }
                                .frame(width: cellW, height: cellH)
                            }
                        }
                    }
                }
            }
            .frame(height: CGFloat(calendarWeeks.count) * 34)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Times")
                .glowzaFont(size: 15, weight: .regular)
                .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
                .tracking(0.5)
                .padding(.top, 10)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(BookingDraft.timeSlots, id: \.time) { slot in
                    let isSelected = selectedTime == slot.time
                    Button(action: {
                        guard slot.available else { return }
                        selectedTime = slot.time
                        draft.timeSlot = slot.time
                    }) {
                        Text(slot.time)
                            .glowzaFont(size: 15, weight: .semibold)
                            .foregroundColor(
                                !slot.available ? Color(hex: "BDBFC5") : (isSelected ? .white : dark)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected ? accent : (appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F5F5F7"))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .hcBorder(radius: 10)
                            .overlay(
                                !slot.available ? nil :
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Color(hex: "EBEBF0"), lineWidth: isSelected ? 0 : 1.5)
                            )
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
                    .glowzaFont(size: 15, weight: .semibold)
                    .foregroundColor(.white)
                    .frame(width: 330, height: 55)
                    .background(canProceed ? accent : Color(hex: "D4829E"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!canProceed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(appSettings.themeSurface)
        }
    }
}

// MARK: - Array extension for calendar grid
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
