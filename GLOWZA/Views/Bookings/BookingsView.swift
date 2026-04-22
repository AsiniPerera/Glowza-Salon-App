import SwiftUI

// MARK: - Add Review View
struct AddReviewView: View {

    let bookingID: UUID
    let salonName: String
    let serviceName: String
    let onSubmit: () -> Void

    @State private var rating: Int    = 0
    @State private var comment: String = ""
    @State private var isSubmitting    = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.glowzaBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Salon info row
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.glowzaGold.opacity(0.12)).frame(width: 46, height: 46)
                                Image(systemName: "building.2.fill").font(.system(size: 20))
                                    .foregroundColor(Color.glowzaGoldDark)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(salonName).font(.system(size: 15, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
                                Text(serviceName).font(.system(size: 12)).foregroundColor(Color.glowzaSubtext)
                            }
                        }

                        // Star rating
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Rating")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.glowzaTextPrimary)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.system(size: 34))
                                        .foregroundColor(star <= rating ? Color.glowzaGold : Color.glowzaSubtext.opacity(0.3))
                                        .onTapGesture { withAnimation(.spring(response: 0.25)) { rating = star } }
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.25), value: rating)
                                }
                            }
                            if rating > 0 {
                                Text(ratingLabel)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color.glowzaGoldDark)
                                    .transition(.opacity)
                            }
                        }
                        .padding(16).glowzaCard()

                        // Comment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Review")
                                .font(.system(size: 15, weight: .semibold)).foregroundColor(Color.glowzaTextPrimary)

                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white)
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.glowzaGold.opacity(0.35), lineWidth: 1))

                                if comment.isEmpty {
                                    Text("Share your experience...")
                                        .font(.system(size: 14)).foregroundColor(Color.glowzaSubtext.opacity(0.6))
                                        .padding(14).allowsHitTesting(false)
                                }
                                TextEditor(text: $comment)
                                    .font(.system(size: 14)).foregroundColor(Color.glowzaTextPrimary)
                                    .padding(10).frame(minHeight: 120)
                                    .scrollContentBackground(.hidden).background(Color.clear)
                            }
                            .frame(minHeight: 120)

                            Text("\(comment.count)/300")
                                .font(.system(size: 11)).foregroundColor(Color.glowzaSubtext)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Submit button
                        Button(action: submitReview) {
                            Group {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Submit Review").font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(
                                LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                               startPoint: .leading, endPoint: .trailing)
                                    .opacity(rating > 0 ? 1 : 0.4)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.glowzaGoldDark)
                }
            }
        }
    }

    private var ratingLabel: String {
        switch rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent!"
        default: return ""
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

    @State private var store         = BookingStore.shared
    @State private var selectedTab   = 0
    @State private var reviewBooking: Booking? = nil
    @State private var receiptBooking: Booking? = nil

    private let tabs = ["Upcoming", "Completed", "Reviews & Ratings"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.glowzaBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    bookingsHeader
                    tabBar
                    tabContent
                }
            }
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
    }

    // MARK: - Header
    private var bookingsHeader: some View {
        HStack {
            Text("Bookings")
                .font(.system(size: 22, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
            Spacer()
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 10)
        .background(Color.glowzaBackground)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { i in
                Button(action: { withAnimation { selectedTab = i } }) {
                    VStack(spacing: 6) {
                        Text(tabs[i])
                            .font(.system(size: 13, weight: selectedTab == i ? .bold : .regular))
                            .foregroundColor(selectedTab == i ? Color.glowzaGoldDark : Color.glowzaSubtext)
                            .lineLimit(1).minimumScaleFactor(0.8)
                        Rectangle()
                            .fill(selectedTab == i ? Color.glowzaGoldDark : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 6)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                switch selectedTab {
                case 0:
                    if store.upcoming.isEmpty { emptyState(tab: "upcoming") }
                    else { ForEach(store.upcoming)  { bookingCard($0, isCompleted: false) } }
                case 1:
                    if store.completed.isEmpty { emptyState(tab: "completed") }
                    else { ForEach(store.completed) { bookingCard($0, isCompleted: true) } }
                default:
                    reviewsList
                }
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 40)
        }
    }

    // MARK: - Booking Card (matches design screenshot)
    private func bookingCard(_ booking: Booking, isCompleted: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date row
            Text(booking.date.formatted(.dateTime.month(.abbreviated).day().year().hour().minute()))
                .font(.system(size: 12)).foregroundColor(Color.glowzaSubtext)
                .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            Divider().padding(.horizontal, 14)

            HStack(spacing: 12) {
                // Salon thumbnail
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(hex: "E5D5BB"))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 26)).foregroundColor(Color(hex: "C8860A").opacity(0.5))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.salon.name)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
                    Text(booking.salon.location)
                        .font(.system(size: 12)).foregroundColor(Color.glowzaSubtext)
                    Text("Services: \(booking.service.name)")
                        .font(.system(size: 12)).foregroundColor(Color.glowzaSubtext)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            // Action buttons
            if isCompleted {
                HStack(spacing: 10) {
                    // Add Review
                    Button(action: { reviewBooking = booking }) {
                        Text(booking.review == nil ? "Add Review" : "Edit Review")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.glowzaGoldDark)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.glowzaGold, lineWidth: 1.5))
                    }
                    // View Receipt
                    Button(action: { receiptBooking = booking }) {
                        Text("View Receipt")
                            .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 38)
                            .background(Color.glowzaGoldDark)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            } else {
                Button(action: {}) {
                    Text("Cancel Booking")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "D9534F"))
                        .frame(maxWidth: .infinity).frame(height: 38)
                        .background(Color(hex: "D9534F").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Reviews List
    private var reviewsList: some View {
        VStack(spacing: 14) {
            let reviewed = BookingStore.shared.bookings.filter { $0.review != nil }
            if reviewed.isEmpty {
                emptyState(tab: "reviews")
            } else {
                ForEach(reviewed) { booking in
                    if let review = booking.review {
                        reviewCard(booking: booking, review: review)
                    }
                }
            }
        }
    }

    private func reviewCard(booking: Booking, review: BookingReview) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(booking.salon.name)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(Color.glowzaTextPrimary)
                    Text(booking.service.name)
                        .font(.system(size: 12)).foregroundColor(Color.glowzaSubtext)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 13))
                            .foregroundColor(i <= review.rating ? Color.glowzaGold : Color.glowzaSubtext.opacity(0.3))
                    }
                }
            }
            Text(review.comment)
                .font(.system(size: 13)).foregroundColor(Color.glowzaTextPrimary.opacity(0.8)).lineSpacing(4)
            Text(review.date.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11)).foregroundColor(Color.glowzaSubtext)
        }
        .padding(14).glowzaCard()
    }

    // MARK: - Empty State
    private func emptyState(tab: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: tab == "reviews" ? "star.bubble" : "calendar.badge.clock")
                .font(.system(size: 40)).foregroundColor(Color.glowzaSubtext.opacity(0.35))
            Text("No \(tab) bookings")
                .font(.system(size: 15)).foregroundColor(Color.glowzaSubtext)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}
