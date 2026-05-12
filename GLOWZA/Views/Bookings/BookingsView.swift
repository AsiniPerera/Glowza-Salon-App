import SwiftUI

private var brand: Color { Color.glowzaPrimary }

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
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        NavigationStack {
            ZStack {
                (appSettings.themePage).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Salon info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(salonName)
                                .glowzaFont(size: 15, weight: .bold).foregroundColor(appSettings.themeText)
                            Text(serviceName)
                                .glowzaFont(size: 12).foregroundColor(Color(hex: "8A8A8A"))
                        }

                        // Star rating
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Rating")
                                .glowzaFont(size: 15, weight: .semibold).foregroundColor(appSettings.themeText)
                            HStack(spacing: 12) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .glowzaFont(size: 34)
                                        .foregroundColor(star <= rating ? Color(hex: "F59E0B") : Color(hex: "CCCCCC"))
                                        .onTapGesture { withAnimation(.spring(response: 0.25)) { rating = star } }
                                        .scaleEffect(star <= rating ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.25), value: rating)
                                }
                            }
                            if rating > 0 {
                                Text(ratingLabel)
                                    .glowzaFont(size: 13, weight: .medium).foregroundColor(brand)
                                    .transition(.opacity)
                            }
                        }
                        .padding(16)
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        // Comment
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Review")
                                .glowzaFont(size: 15, weight: .semibold).foregroundColor(appSettings.themeText)
                            ZStack(alignment: .topLeading) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(appSettings.themeSurface)
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(hex: "EBEBEB"), lineWidth: 1))
                                if comment.isEmpty {
                                    Text("Share your experience...")
                                        .glowzaFont(size: 14).foregroundColor(Color(hex: "ABABAB"))
                                        .padding(14).allowsHitTesting(false)
                                }
                                TextEditor(text: $comment)
                                    .glowzaFont(size: 14).foregroundColor(appSettings.themeText)
                                    .padding(10).frame(minHeight: 120)
                                    .scrollContentBackground(.hidden).background(Color.clear)
                            }
                            .frame(minHeight: 120)
                            Text("\(comment.count)/300")
                                .glowzaFont(size: 11).foregroundColor(Color(hex: "8A8A8A"))
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Submit
                        Button(action: submitReview) {
                            Group {
                                if isSubmitting {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Submit Review").glowzaFont(size: 15, weight: .semibold)
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
            .navigationTitle(BookingStore.shared.bookings.first(where: { $0.id == bookingID })?.review != nil ? "Edit Review" : "Add Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(brand)
                        .fixedSize()
                }
            }
            .onAppear {
                // If a review already exists for this booking, pre-fill the fields.
                if let booking = BookingStore.shared.bookings.first(where: { $0.id == bookingID }),
                   let existingReview = booking.review {
                    rating = existingReview.rating
                    comment = existingReview.comment
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
        guard rating > 0 else { return }
        isSubmitting = true

        let reviewComment  = comment.trimmingCharacters(in: .whitespaces).isEmpty ? ratingLabel : comment
        let auth           = AuthService.shared
        let userId         = auth.currentUID ?? "guest"
        let reviewerName   = auth.currentUserProfile?.fullName
                             ?? UserDefaults.standard.string(forKey: "profile_fullName")
                             ?? "Anonymous"
        let salonId        = SalonFirestoreService.shared.salonId(for: salonName)

        // 1. Save to local BookingStore (updates UI immediately)
        BookingStore.shared.addReview(
            bookingID: bookingID,
            review: BookingReview(
                rating: rating,
                comment: reviewComment,
                date: Date(),
                reviewerName: reviewerName
            )
        )

        // 2. Save review + update salon rating in Firestore
        Task {
            defer {
                Task { @MainActor in
                    isSubmitting = false
                    onSubmit()
                    dismiss()
                }
            }
            
            do {
                // Determine if we're editing an existing review
                let existingReview = BookingStore.shared.bookings.first(where: { $0.id == bookingID })?.review
                
                // If editing, we'd ideally need the docId, but for now we'll just add it 
                // and the local store already handles the UI update.
                
                // 2a. Save review document to `salonReviews` collection
                try await SalonFirestoreService.shared.addSalonReview(
                    salonId: salonId,
                    userId: userId,
                    userName: reviewerName,
                    rating: rating,
                    comment: reviewComment
                )

                // 2b. Recalculate and update salon's average rating in `salons` collection
                let reviews = try await SalonFirestoreService.shared.fetchReviews(forSalonId: salonId)
                if !reviews.isEmpty {
                    let avgRating  = Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
                    let roundedAvg = (avgRating * 10).rounded() / 10
                    try? await SalonFirestoreService.shared.upsertSalon(
                        name:        salonName,
                        location:    "",         // merge: true — won't overwrite existing location
                        distance:    "",
                        rating:      roundedAvg,
                        reviewCount: reviews.count,
                        score:       min(roundedAvg / 5.0, 1.0),
                        categories:  []
                    )
                }

                // 2c. Also update the booking status to "completed" in Firestore
                await BookingStore.shared.addReviewFirestore(
                    BookingStore.shared.bookings
                        .first(where: { $0.id == bookingID })
                        .flatMap { b in
                            BookingStore.shared.firestoreBookings
                                .first(where: { $0.bookingSummary.receiptNumber == b.receiptNumber })?.id
                        } ?? "",
                    rating: Double(rating),
                    review: reviewComment
                )

                print("✅ Review saved to Firestore for salon: \(salonName)")
            } catch {
                print("❌ Failed to save review: \(error)")
                // The defer block will still dismiss the view, so user isn't stuck.
            }
        }
    }
}

// MARK: - Shared Booking Card

private struct BookingCardImage: View {
    let salonName: String
    @Environment(AppSettings.self) private var appSettings
    
    var body: some View {
        let imageName = mappedSalonImageName(salonName)
        
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(width: 80, height: 80)
    }
}

private func mappedSalonImageName(_ salonName: String) -> String {
    switch salonName {
    case "Golden Avenue": return "Salon1"
    case "Glow Studio": return "salon2"
    case "Luxe Aesthetics": return "salon3"
    case "Velvet Touch": return "salon4"
    case "Aura Beauty Bar": return "salon5"
    case "Silk & Shine": return "salon6"
    case "Prime Beauty": return "salon7"
    case "Elegance Salon": return "salon8"
    case "Crystal Beauty": return "salon9"
    case "Radiant Aesthetic": return "salon10"
    default: 
        // Fallback: Generate a consistent image index based on the name
        let hash = abs(salonName.hashValue)
        let index = (hash % 10) + 1
        return index == 1 ? "Salon1" : "salon\(index)"
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
    @Environment(AppSettings.self) private var appSettings

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
        .background(appSettings.themePage)
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
            HStack {
                Text(bookingDateLabel(booking))
                    .glowzaFont(size: 12, weight: .medium)
                    .foregroundColor(Color(hex: "8A8A8A"))
                
                Spacer()
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .glowzaFont(size: 15, weight: .bold)
                        .foregroundColor(appSettings.themeText)
                    Text(booking.salon.location)
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("Services: \(booking.service.name)")
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            // Action buttons
            HStack(spacing: 12) {
                Button(action: { receiptBooking = booking }) {
                    Text("View Receipt")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
                
                Button(action: { cancelTarget = booking }) {
                    Text("Cancel")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(brand.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16).padding(.top, 4)
        }
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Completed Bookings View

struct CompletedBookingsView: View {
    @State private var store = BookingStore.shared
    @Binding var receiptBooking: Booking?
    @Binding var reviewBooking: Booking?
    let onRebook: (Booking) -> Void
    @Environment(AppSettings.self) private var appSettings

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
        .background(appSettings.themePage)
    }

    private func completedCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            HStack {
                Text(bookingDateLabel(booking))
                    .glowzaFont(size: 12, weight: .medium)
                    .foregroundColor(Color(hex: "8A8A8A"))

                Spacer()

                Button(action: { onRebook(booking) }) {
                    Text("Rebook")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "962043"))
                        .padding(.horizontal, 24)
                        .frame(height: 32)
                        .background(appSettings.themeRaised)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "962043"), lineWidth: 1.2)
                        )
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .glowzaFont(size: 15, weight: .bold)
                        .foregroundColor(appSettings.themeText)
                    Text(booking.salon.location)
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("Services: \(booking.service.name)")
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            HStack(spacing: 12) {
                Button(action: { receiptBooking = booking }) {
                    Text("View Receipt")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
                
                Button(action: { reviewBooking = booking }) {
                    Text("Review")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(brand)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(brand.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Cancelled Bookings View

struct CancelledBookingsView: View {
    @State private var store = BookingStore.shared
    let onRebook: (Booking) -> Void
    @Environment(AppSettings.self) private var appSettings

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
        .background(appSettings.themePage)
    }

    private func cancelledCard(_ booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date header
            HStack {
                Text(bookingDateLabel(booking))
                    .glowzaFont(size: 12, weight: .medium)
                    .foregroundColor(Color(hex: "8A8A8A"))
                
                Spacer()
                
                Button(action: { onRebook(booking) }) {
                    Text("Rebook")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "962043"))
                        .padding(.horizontal, 24)
                        .frame(height: 32)
                        .background(appSettings.themeRaised)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "962043"), lineWidth: 1.2)
                        )
                }
            }
            .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 14)

            Divider().padding(.horizontal, 16)

            // Salon info
            HStack(alignment: .top, spacing: 14) {
                BookingCardImage(salonName: booking.salon.name)
                    .opacity(0.55)
                VStack(alignment: .leading, spacing: 5) {
                    Text(booking.salon.name)
                        .glowzaFont(size: 15, weight: .bold)
                        .foregroundColor(Color(hex: "1A1A1A").opacity(0.55))
                    Text(booking.salon.location)
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A").opacity(0.7))
                    Text("Services: \(booking.service.name)")
                        .glowzaFont(size: 13)
                        .foregroundColor(Color(hex: "8A8A8A").opacity(0.7))
                    Text("Cancelled")
                        .glowzaFont(size: 11, weight: .semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(Color(hex: "8A8A8A"))
                        .clipShape(Capsule())
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Shared Empty State

struct BookingEmptyState: View {
    let icon: String
    let label: String
    let subtitle: String
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(brand.opacity(0.08)).frame(width: 80, height: 80)
                Image(systemName: icon)
                    .glowzaFont(size: 34).foregroundColor(brand.opacity(0.45))
            }
            Text(label)
                .glowzaFont(size: 16, weight: .semibold).foregroundColor(appSettings.themeText)
            Text(subtitle)
                .glowzaFont(size: 13).foregroundColor(Color(hex: "8A8A8A"))
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
    @State private var rebookDraft: BookingDraft? = nil
    @Environment(AppSettings.self) private var appSettings

    private let tabs = ["Upcoming", "Completed", "Cancelled"]

    var body: some View {
        VStack(spacing: 0) {
                // Page title
                Text("Bookings")
                    .glowzaFont(size: 28, weight: .bold)
                    .foregroundColor(appSettings.themeText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                Picker("Booking Status", selection: $selectedTab) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Text(tabs[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 10)

                TabView(selection: $selectedTab) {
                    UpcomingBookingsView(receiptBooking: $receiptBooking)
                        .tag(0)
                    CompletedBookingsView(
                        receiptBooking: $receiptBooking,
                        reviewBooking: $reviewBooking,
                        onRebook: { booking in
                            var draft = BookingDraft(salon: booking.salon)
                            draft.service = booking.service
                            draft.date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                            draft.timeSlot = ""
                            rebookDraft = draft
                        }
                    )
                        .tag(1)
                    CancelledBookingsView(onRebook: { booking in
                        var draft = BookingDraft(salon: booking.salon)
                        draft.service = booking.service
                        draft.date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                        draft.timeSlot = ""
                        rebookDraft = draft
                    })
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.22), value: selectedTab)
        }
        .background(appSettings.themePage.ignoresSafeArea())
        .task {
            await BookingStore.shared.fetchUserBookings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .glowzaShowUpcomingBookings)) { _ in
            selectedTab = 0
        }
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
        .sheet(
            isPresented: Binding(
                get: { rebookDraft != nil },
                set: { if !$0 { rebookDraft = nil } }
            )
        ) {
            if let rebookDraft {
                BookingFlowView(draft: rebookDraft)
                    .environment(AppSettings.shared)
            }
        }
    }
}
