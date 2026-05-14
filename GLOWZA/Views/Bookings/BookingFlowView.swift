import SwiftUI

// MARK: - Booking Flow Steps
// An enum to represent the different steps in the booking process.
// This is a great way to manage state in a multi-step flow (wizard)!
enum BookingFlowStep {
    case dateTime, summary, consent, payment, confirmation, receipt
}

// MARK: - BookingFlowView (Container)
// This is the parent view that hosts all the steps and manages navigation between them.
struct BookingFlowView: View {

    @State var draft: BookingDraft // Holds the current state of the booking being built.
    @State private var step: BookingFlowStep = .dateTime // Current step in the flow.
    @State private var completedBooking: Booking? = nil // Holds the final booking data after success.
    @State private var isSubmittingPayment = false // Prevents double-tapping the pay button.
    @Environment(\.dismiss) private var dismiss // To close the sheet.

    var body: some View {
        // A switch statement is perfect for rendering different views based on the current step!
        switch step {
        case .dateTime:
            BookAppointmentView(draft: $draft) {
                step = .summary // Move to next step!
            } onBack: {
                dismiss() // Close the flow!
            }
        case .summary:
            BookingSummaryView(draft: $draft) {
                step = .consent
            } onBack: {
                step = .dateTime // Go back!
            }
        case .consent:
            ConsentFormView(draft: $draft) {
                step = .payment
            } onBack: {
                step = .summary
            }
        case .payment:
            PaymentView(draft: $draft, isProcessing: isSubmittingPayment) { booking in
                guard !isSubmittingPayment else { return }
                isSubmittingPayment = true

                // Move to booking confirmation only after successful Firestore save!
                Task {
                    do {
                        try await BookingStore.shared.createBooking(
                            salonName: booking.salon.name,
                            salonLocation: booking.salon.location,
                            serviceName: booking.service.name,
                            servicePrice: booking.service.price,
                            date: booking.date,
                            timeSlot: booking.timeSlot,
                            paymentMethod: booking.paymentMethod.rawValue,
                            amountPaid: booking.amountPaid,
                            receiptNumber: booking.receiptNumber,
                            agreedConsent: draft.agreedConsent,
                            signatureImage: booking.signatureImage
                        )

                        await MainActor.run {
                            isSubmittingPayment = false
                            completedBooking = booking
                            
                            // Success logic!
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
                            
                            // Update local store and widget
                            BookingStore.shared.add(booking)
                            WidgetBookingSyncService.shared.saveUpcomingBooking(booking)
                            
                            // Calendar save can still happen in background
                            Task {
                                let _ = await EventKitService.shared.saveBookingToCalendar(booking)
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isSubmittingPayment = false
                            // Show error notification!
                            NotificationManager.shared.showNotification(
                                NotificationItem(
                                    title: "Booking Failed",
                                    subtitle: error.localizedDescription,
                                    icon: "exclamationmark.triangle.fill",
                                    type: .error
                                ),
                                duration: 5.0
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
                BookingConfirmedView(booking: booking, onBackToHome: {
                    dismiss()
                })
                .environment(AppSettings.shared)
            }
        case .receipt:
            if let booking = completedBooking {
                ReceiptView(booking: booking) {
                    dismiss()
                }
                .environment(AppSettings.shared)
            }
        }
    }
}

// MARK: - Book Appointment View (Date + Time selection)
// This screen lets the user pick a date from a custom calendar and a time slot.
struct BookAppointmentView: View {

    @Binding var draft: BookingDraft // Bound to parent to share data.
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var selectedTime: String = ""
    @State private var displayMonth: Date = Date() // Tracks which month the calendar is showing.
    @State private var bookedSlots: [String] = [] // NEW: To be fetched from DB!
    @State private var isFetchingSlots = false // NEW: To show loading state!

    private var appSettings: AppSettings { AppSettings.shared }

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var selectedService: SalonService { draft.service ?? draft.salon.services[0] }

    // MARK: - Calendar Calculations
    // These helpers calculate the grid of dates for the current month!
    
    // Returns the month and year string (e.g., "MAY 2026").
    private var monthYear: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: displayMonth).uppercased()
    }

    // Calculates all the dates to show in the calendar grid, including padding.
    private var calendarDates: [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: displayMonth)!
        let numDays = range.count

        // Find the first day of the month.
        let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayMonth))!
        let firstWeekday = calendar.component(.weekday, from: first) - 1 // 0 = Sunday

        // Padding for days from the previous month.
        let paddingDays = Array(repeating: Optional<Date>(nil), count: firstWeekday)
        
        // Days of the current month.
        let dateDays: [Date?] = (0..<numDays).map { day in
            calendar.date(byAdding: .day, value: day, to: first)!
        }

        let combined = paddingDays + dateDays
        let remainder = combined.count % 7
        
        // Padding for days in the next month to fill the row.
        let trailing = remainder == 0 ? [] : Array(repeating: Optional<Date>(nil), count: 7 - remainder)
        return combined + trailing
    }

    // Chunks the flat array of dates into weeks (arrays of 7 days).
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
            // Set defaults if not already set!
            if draft.service == nil {
                draft.service = draft.salon.services.first
            }
            displayMonth = draft.date
            selectedTime = draft.timeSlot
            
            Task { await fetchBookedSlots() }
        }
        .onChange(of: draft.date) { _, _ in
            Task { await fetchBookedSlots() }
        }
    }

    private var topBack: some View {
        GlowzaCircleBackButton(action: onBack)
    }

    private var serviceSelectionHeader: some View {
        Text("Select Date & Time")
            .glowzaFont(size: 24, weight: .semibold)
            .foregroundColor(appSettings.themeText)
            .padding(.top, 6)
    }

    // Displays the selected salon and service details.
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

    // The calendar grid view.
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Month navigation header.
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

            // Day of week headers (SUN, MON, etc.).
            // We use GeometryReader to split the width equally into 7 columns!
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

            // The grid of days.
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
                                            guard isFuture else { return } // Can't pick past dates!
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

    // The grid of time slots.
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Available Times")
                    .glowzaFont(size: 15, weight: .regular)
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "56585F"))
                    .tracking(0.5)
                
                if isFetchingSlots {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.leading, 8)
                }
            }
            .padding(.top, 10)

            // LazyVGrid creates a grid with a fixed number of columns (3 in this case).
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(BookingDraft.timeSlots, id: \.time) { slot in
                    let isAvailable = isSlotActuallyAvailable(slot: slot.time)
                    let isSelected = selectedTime == slot.time
                    Button(action: {
                        guard isAvailable else { return }
                        selectedTime = slot.time
                        draft.timeSlot = slot.time
                    }) {
                        Text(slot.time)
                            .glowzaFont(size: 15, weight: .semibold)
                            .strikethrough(!isAvailable, color: Color(hex: "BDBFC5"))
                            .foregroundColor(
                                !isAvailable ? Color(hex: "BDBFC5") : (isSelected ? .white : dark)
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected ? accent : (appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F5F5F7"))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .hcBorder(radius: 10)
                            .overlay(
                                !isAvailable ? nil :
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isSelected ? Color.clear : Color(hex: "EBEBF0"), lineWidth: isSelected ? 0 : 1.5)
                            )
                    }
                    .disabled(!isAvailable) // Disables the button if slot is taken!
                }
            }
            .padding(.bottom, 6)
        }
    }

    // Bottom bar with the confirm button.
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

    // MARK: - Helper Logic
    
    /// Checks if a slot is actually available (not in the past AND not booked).
    private func isSlotActuallyAvailable(slot: String) -> Bool {
        // 1. Check if the slot was already taken in the database!
        if bookedSlots.contains(slot) { return false }
        
        // 2. Check if the slot is in the past (if booking for today).
        let calendar = Calendar.current
        if calendar.isDateInToday(draft.date) {
            let now = Date()
            
            // Parse the slot time (e.g., "10:30 AM")
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            
            if let slotTime = formatter.date(from: slot) {
                let slotComponents = calendar.dateComponents([.hour, .minute], from: slotTime)
                let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
                
                let slotTotalMinutes = (slotComponents.hour ?? 0) * 60 + (slotComponents.minute ?? 0)
                let nowTotalMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
                
                return slotTotalMinutes > nowTotalMinutes + 15 // Allow booking if it's 15 mins away!
            }
        }
        
        return true // Default: available for future dates!
    }

    /// Fetches all booked time slots for this salon on this specific date!
    private func fetchBookedSlots() async {
        let salonName = draft.salon.name
        isFetchingSlots = true
        
        // Format the date prefix using POSIX to match the DB exactly!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let datePrefix = formatter.string(from: draft.date)
        
        do {
            let booked = try await BookingService.shared.fetchBookedSlots(salon: salonName, datePrefix: datePrefix)
            await MainActor.run {
                self.bookedSlots = booked
                self.isFetchingSlots = false
            }
        } catch {
            print("Error fetching booked slots: \(error)")
            await MainActor.run {
                self.isFetchingSlots = false
            }
        }
    }
}

// MARK: - Array extension for calendar grid
// A very useful helper to split an array into chunks of a specific size!
// Used here to split a list of days into weeks of 7 days.
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
