import SwiftUI

private let brand = Color(hex: "962043")

// MARK: - Add Review View
struct AddReviewView: View {

    let bookingID: UUID
    let salonName: String
    let serviceName: String
    let onSubmit: () -> Void

    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Salon info
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(brand.opacity(0.10)).frame(width: 46, height: 46)
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 20)).foregroundColor(brand)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(salonName)
                                    .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                                Text(serviceName)
                                    .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                            }
                        }

                        // Star rating
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Rating")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 34))
                                        .foregroundColor(star <= rating ? Color(hex: "F59E0B") : Color(hex: "CCCCCC"))
                                        .onTapGesture { withAnimation(.spring(response: 0.25)) { rating = star } }
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.25), value: rating)
                                }
                            }
                            if rating > 0 {
                                Text(ratingLabel)
                                    .font(.system(size: 13, weight: .medium)).foregroundColor(brand)
                                    .transition(.opacity)
                            }
                        }
                        .padding(16)
                        .background(Color(hex: "F9F9F9"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Comment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Review")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(hex: "F5F5F5"))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(hex: "EBEBEB"), lineWidth: 1))
                                if comment.isEmpty {
                                    Text("Share your experience...")
                                        .font(.system(size: 14)).foregroundColor(Color(hex: "ABABAB"))
                                        .padding(14).allowsHitTesting(false)
                                }
                                TextEditor(text: $comment)
                                    .font(.system(size: 14)).foregroundColor(Color(hex: "1A1A1A"))
                                    .padding(10).frame(minHeight: 120)
                                    .scrollContentBackground(.hidden).background(Color.clear)
                            }
                            .frame(minHeight: 120)
                            Text("\(comment.count)/300")
                                .font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Submit
                        Button(action: submitReview) {
                            Group {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Submit Review").font(.system(size: 15, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(width: 330, height: 55)
                            .background(rating > 0 ? Color(hex: "962043") : Color(hex: "D4829E"))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(rating == 0 || isSubmitting)
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(brand)
                }
            }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Poor"; case 2: return "Fair"; case 3: return "Good"
        case 4: return "Very Good"; case 5: return "Excellent!"; default: return ""
        }
    }

    private func submitReview() {
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            BookingStore.shared.addReview(
                bookingID: bookingID,
                review: BookingReview(
                    rating: rating,
                    comment: comment.isEmpty ? ratingLabel : comment,
                    date: Date(),
                    reviewerName: UserDefaults.standard.string(forKey: "profile_name") ?? "You"
                )
            )
            isSubmitting = false
            onSubmit()
            dismiss()
        }
    }
}

// MARK: - Shared Booking Card

private struct BookingCardImage: View {
    let salonName: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "F0EBE8"))
                .frame(width: 80, height: 80)
            if UIImage(named: "Salon1") != nil {
                Image("Salon1")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(brand.opacity(0.4))
            }
        }
    }
}

private func bookingDateLabel(_ booking: Booking) -> String {
    let df = DateFormatter()
    df.dateFormat = "MMM d, yyyy"
    return "\(df.string(from: booking.date)) · \(booking.timeSlot)"
}

// MARK: - Upcoming Bookings View

struct UpcomingBookingsView: View {
    @State private var store = BookingStore.shared
    @Binding var receiptBooking: Booking?
    @State private var cancelTarget: Booking? = nil

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if store.upcoming.isEmpty {
                    BookingEmptyState(icon: "calendar.badge.clock", label: "No upcoming bookings",
                                      subtitle: "Your upcoming bookings will appear here.")
                } else {
                    ForEach(store.upcoming) { booking in
                        upcomingCard(booking)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 40)
        }
        .background(Color.white)
        .alert("Cancel Booking", isPresented: Binding(
            get: { cancelTarget != nil },
            set: { if !$0 { cancelTarget = nil } }
        )) {
            Button("Cancel Booking", role: .destructive) {
                if let b = cancelTarget { store.cancelBooking(id: b.id) }
                cancelTarget = nil
            }
            Button("Keep", role: .cancel) { cancelTarget = nil }
        } message: {
            Text("Are you sure you want to cancel this booking? This action cannot be undone.")
        }
    }

    private func upcomingCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            Text(bookingDateLabel(booking))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text(booking.salon.location)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("Services: \(booking.service.name)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { cancelTarget = booking }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "962043"))
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color(hex: "962043"), lineWidth: 1.5))
                }
                Button(action: { receiptBooking = booking }) {
                    Text("View Receipt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(Color(hex: "962043"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16).padding(.top, 4)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Completed Bookings View

struct CompletedBookingsView: View {
    @State private var store = BookingStore.shared
    @Binding var receiptBooking: Booking?
    @Binding var reviewBooking: Booking?

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if store.completed.isEmpty {
                    BookingEmptyState(icon: "checkmark.circle", label: "No completed bookings",
                                      subtitle: "Your completed bookings will appear here.")
                } else {
                    ForEach(store.completed) { booking in
                        completedCard(booking)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 40)
        }
        .background(Color.white)
    }

    private func completedCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            Text(bookingDateLabel(booking))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text(booking.salon.location)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("Services: \(booking.service.name)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            // Action buttons — same layout as upcomingCard
            HStack(spacing: 12) {
                Button(action: { reviewBooking = booking }) {
                    Text(booking.review != nil ? "Reviewed" : "Leave Review")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(booking.review != nil ? Color(hex: "8E8E93") : Color(hex: "962043"))
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(booking.review != nil ? Color(hex: "E5E5EA") : Color(hex: "962043"), lineWidth: 1.5))
                }
                .disabled(booking.review != nil)
                Button(action: { receiptBooking = booking }) {
                    Text("View Receipt")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(Color(hex: "962043"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16).padding(.top, 4)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Cancelled Bookings View

struct CancelledBookingsView: View {
    @State private var store = BookingStore.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                if store.cancelled.isEmpty {
                    BookingEmptyState(icon: "xmark.circle", label: "No cancelled bookings",
                                      subtitle: "Your cancelled bookings will appear here.")
                } else {
                    ForEach(store.cancelled) { booking in
                        cancelledCard(booking)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 40)
        }
        .background(Color.white)
    }

    private func cancelledCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            Text(bookingDateLabel(booking))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(hex: "8A8A8A"))
                .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                    .opacity(0.55)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A").opacity(0.55))
                    Text(booking.salon.location)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A").opacity(0.7))
                    Text("Services: \(booking.service.name)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A").opacity(0.7))
                    Text("Cancelled")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color(hex: "8A8A8A"))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Shared Empty State

struct BookingEmptyState: View {
    let icon: String
    let label: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(brand.opacity(0.08)).frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 34)).foregroundColor(brand.opacity(0.45))
            }
            Text(label)
                .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
            Text(subtitle)
                .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}

// MARK: - BookingsView

struct BookingsView: View {
    @State private var selectedTab = 0
    @State private var receiptBooking: Booking? = nil
    @State private var reviewBooking: Booking? = nil
    @Environment(AppSettings.self) private var appSettings

    private let tabs = ["Upcoming", "Completed", "Cancelled"]

    var body: some View {
        VStack(spacing: 0) {
            // Navigation header
            HStack {
                Text("Bookings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1C1C1E"))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 14)
            .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)

            // Segmented tab bar
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { i in
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) { selectedTab = i }
                    } label: {
                        VStack(spacing: 0) {
                            Text(tabs[i])
                                .font(.system(size: 14, weight: selectedTab == i ? .semibold : .regular))
                                .foregroundColor(selectedTab == i ? Color(hex: "962043") : (appSettings.isDarkMode ? Color.white.opacity(0.5) : Color(hex: "8E8E93")))
                                .padding(.bottom, 10)
                            Rectangle()
                                .fill(selectedTab == i ? Color(hex: "962043") : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)

            Divider()

            // Tab content using TabView for swipe support
            TabView(selection: $selectedTab) {
                UpcomingBookingsView(receiptBooking: $receiptBooking)
                    .tag(0)
                CompletedBookingsView(receiptBooking: $receiptBooking, reviewBooking: $reviewBooking)
                    .tag(1)
                CancelledBookingsView()
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.22), value: selectedTab)
        }
        .background(Color.white.ignoresSafeArea())
        .sheet(item: $receiptBooking) { booking in
            ReceiptView(booking: booking) { receiptBooking = nil }
        }
        .sheet(item: $reviewBooking) { booking in
            AddReviewView(
                bookingID: booking.id,
                salonName: booking.salon.name,
                serviceName: booking.service.name
            ) { reviewBooking = nil }
        }
    }
}
