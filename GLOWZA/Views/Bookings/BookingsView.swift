import SwiftUI

private let brand = Color(hex: "AF1C47")

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
                                    Text("Submit Review").font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(rating > 0 ? brand : Color(hex: "CCCCCC"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: rating > 0 ? brand.opacity(0.28) : Color.clear, radius: 10, y: 4)
                        }
                        .disabled(rating == 0 || isSubmitting)
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

// MARK: - BookingsView
struct BookingsView: View {

    @State private var store = BookingStore.shared
    @State private var selectedTab = 0
    @State private var reviewBooking: Booking? = nil
    @State private var receiptBooking: Booking? = nil
    @State private var rebookBooking: Booking? = nil
    @State private var rescheduleBooking: Booking? = nil

    private let tabs = ["Upcoming", "Completed", "Reviews"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Bookings")
                            .font(.system(size: 22, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                        Text("\(store.upcoming.count) upcoming")
                            .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(brand.opacity(0.10)).frame(width: 40, height: 40)
                        Image(systemName: "bell.fill").font(.system(size: 16)).foregroundColor(brand)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)
                .background(Color.white)

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i } }) {
                            VStack(spacing: 6) {
                                Text(tabs[i])
                                    .font(.system(size: 13, weight: selectedTab == i ? .bold : .regular))
                                    .foregroundColor(selectedTab == i ? brand : Color(hex: "8A8A8A"))
                                    .lineLimit(1)
                                Rectangle()
                                    .fill(selectedTab == i ? brand : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.white)

                Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)

                // Content
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        switch selectedTab {
                        case 0:
                            if store.upcoming.isEmpty { emptyState(tab: "upcoming") }
                            else { ForEach(store.upcoming) { bookingCard($0, isCompleted: false) } }
                        case 1:
                            if store.completed.isEmpty { emptyState(tab: "completed") }
                            else { ForEach(store.completed) { bookingCard($0, isCompleted: true) } }
                        default:
                            reviewsList
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 40)
                }
                .background(Color(hex: "F7F7F7"))
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(item: $reviewBooking) { booking in
            AddReviewView(
                bookingID: booking.id,
                salonName: booking.salon.name,
                serviceName: booking.service.name
            ) { reviewBooking = nil }
        }
        .sheet(item: $receiptBooking) { booking in
            ReceiptView(booking: booking) { receiptBooking = nil }
        }
        .sheet(item: $rebookBooking) { booking in
            BookingFlowView(draft: BookingDraft(salon: booking.salon, service: booking.service))
        }
        .sheet(item: $rescheduleBooking) { booking in
            BookingFlowView(draft: BookingDraft(salon: booking.salon, service: booking.service))
        }
    }

    // MARK: - Booking Card
    private func bookingCard(_ booking: Booking, isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status + date row
            HStack {
                Text(booking.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().year()))
                    .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                Spacer()
                statusBadge(isCompleted: isCompleted)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 14)

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(brand.opacity(0.08)).frame(width: 64, height: 64)
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24)).foregroundColor(brand.opacity(0.5))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.salon.name)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                    Text(booking.salon.location)
                        .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                    HStack(spacing: 4) {
                        Image(systemName: booking.service.icon)
                            .font(.system(size: 10)).foregroundColor(brand)
                        Text(booking.service.name)
                            .font(.system(size: 12)).foregroundColor(Color(hex: "6B6B6B"))
                    }
                    Text(booking.timeSlot)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(brand)
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 14)

            // Action buttons
            if isCompleted {
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Button(action: { reviewBooking = booking }) {
                            Text(booking.review == nil ? "Add Review" : "Edit Review")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(brand)
                                .frame(maxWidth: .infinity).frame(height: 38)
                                .background(brand.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(brand.opacity(0.25), lineWidth: 1))
                        }
                        Button(action: { receiptBooking = booking }) {
                            Text("View Receipt")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity).frame(height: 38)
                                .background(brand)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    Button(action: { rebookBooking = booking }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Book Again")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "00A878"))
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background(Color(hex: "00A878").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(hex: "00A878").opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14).padding(.top, 10)
            } else {
                HStack(spacing: 10) {
                    Button(action: { rescheduleBooking = booking }) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Reschedule")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(brand)
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background(brand.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(brand.opacity(0.25), lineWidth: 1))
                    }
                    Button(action: {}) {
                        Text("Cancel")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "D9534F"))
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(Color(hex: "D9534F").opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14).padding(.top, 10)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    private func statusBadge(isCompleted: Bool) -> some View {
        Text(isCompleted ? "Completed" : "Upcoming")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isCompleted ? Color(hex: "00A878") : brand)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(isCompleted ? Color(hex: "00A878").opacity(0.10) : brand.opacity(0.10))
            .clipShape(Capsule())
    }

    // MARK: - Reviews List
    private var reviewsList: some View {
        VStack(spacing: 14) {
            let reviewed = BookingStore.shared.bookings.filter { $0.review != nil }
            if reviewed.isEmpty {
                emptyState(tab: "reviews")
            } else {
                ForEach(reviewed) { booking in
                    if let review = booking.review { reviewCard(booking: booking, review: review) }
                }
            }
        }
    }

    private func reviewCard(booking: Booking, review: BookingReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.salon.name)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                    Text(booking.service.name)
                        .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundColor(i <= review.rating ? Color(hex: "F59E0B") : Color(hex: "CCCCCC"))
                    }
                }
            }
            Text(review.comment)
                .font(.system(size: 13)).foregroundColor(Color(hex: "1A1A1A").opacity(0.8)).lineSpacing(4)
            Text(review.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    // MARK: - Empty State
    private func emptyState(tab: String) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(brand.opacity(0.08)).frame(width: 80, height: 80)
                Image(systemName: tab == "reviews" ? "star.bubble" : "calendar.badge.clock")
                    .font(.system(size: 34)).foregroundColor(brand.opacity(0.4))
            }
            Text("No \(tab) bookings")
                .font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A"))
            Text("Your \(tab) bookings will appear here.")
                .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}
