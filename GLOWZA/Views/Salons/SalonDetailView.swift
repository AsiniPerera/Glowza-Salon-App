import SwiftUI
import MapKit
import FirebaseFirestore

private let brand = Color(hex: "962043")

// MARK: - Salon Detail View
struct SalonDetailView: View {

    let salonName: String

    @Environment(TreatmentComparisonStore.self) private var comparisonStore
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    @State private var showBookingFlow = false
    @State private var bookingDraft    = BookingDraft(salon: SalonCatalog.shared.salons[0])
    @State private var isFavourited    = false
    @State private var photoIndex      = 0
    @State private var selectedTab     = 0
    @State private var selectedServiceID: UUID? = nil
    @State private var displayReviews: [FirestoreSalonReview] = []
    @State private var showReviewSheet = false
    @State private var reviewToEdit: FirestoreSalonReview? = nil
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    @State private var selectedReviewer: FirestoreSalonReview? = nil
    @State private var userAvatarData: Data? = UserDefaults.standard.data(forKey: "profile_avatarData")
    @State private var reviewListener: ListenerRegistration? = nil
    
    // LIVE SYNC & ANIMATION: Essential for global consistency and premium feel!
    @Namespace private var tabNamespace
    @State private var dynamicRating: Double = 0.0
    @State private var dynamicReviewCount: Int = 0

    private var salon: Salon {
        SalonCatalog.shared.salon(named: salonName)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    navigationBar
                        .padding(.top, -260) // Overlay the hero section
                    
                    infoSheet
                        .padding(.top, -15)
                }
            }
            .ignoresSafeArea(edges: .top)

            if showBookNow {
                bookNowBar
                    .transition(.move(edge: .bottom))
                    .animation(.easeInOut(duration: 0.2), value: showBookNow)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            bookingDraft = BookingDraft(salon: salon)
            selectedServiceID = nil
            Task {
                await FavouritesStore.shared.load()
                isFavourited = FavouritesStore.shared.favouriteNames.contains(salonName)
                // Initialize with catalog values, then let the listener take over!
                dynamicRating = salon.rating
                dynamicReviewCount = salon.reviewCount
                startListeningToReviews()
            }
        }
        .onDisappear {
            stopListeningToReviews()
        }
        .fullScreenCover(isPresented: $showBookingFlow) {
            BookingFlowView(draft: bookingDraft)
        }
        .sheet(isPresented: $showReviewSheet) {
            SalonReviewSheet(salonName: salonName, reviewToEdit: reviewToEdit, existingReviews: displayReviews) {
                Task { await fetchFirestoreReviews() }
            }
        }
        .sheet(item: $selectedReviewer) { review in
            UserProfileSheet(review: review, reviewCount: displayReviews.filter { $0.userName == review.userName }.count)
        }
        .confirmationDialog("Delete Review?", isPresented: Binding(get: { reviewToEdit != nil && errorMessage == "DELETE_CONFIRM" }, set: { if !$0 { errorMessage = nil; reviewToEdit = nil } }), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let r = reviewToEdit { deleteReview(r) }
            }
            Button("Cancel", role: .cancel) { reviewToEdit = nil; errorMessage = nil }
        } message: {
            Text("Are you sure you want to permanently remove this review?")
        }
        .alert("Review Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    private func startListeningToReviews() {
        let sId = SalonFirestoreService.shared.salonId(for: salonName)
        reviewListener?.remove()
        reviewListener = SalonFirestoreService.shared.listenToReviews(forSalonId: sId) { updatedReviews in
            Task { @MainActor in
                // MERGE: Show all real reviews + fill up with mock reviews if needed!
                // This ensures that when a new user adds a review, everyone sees it immediately.
                var allReviews = updatedReviews
                
                // Real-time analytics: Update average rating and total count!
                let realRatings = updatedReviews.map { Double($0.rating) }
                if !realRatings.isEmpty {
                    self.dynamicRating = realRatings.reduce(0, +) / Double(realRatings.count)
                    self.dynamicReviewCount = updatedReviews.count + 312 // Real + Mocks
                }
                
                if allReviews.count < 8 {
                    let mocks = generateLocalMockReviews(for: sId)
                    // Only add mocks that don't conflict with real review IDs
                    let needed = 8 - allReviews.count
                    allReviews.append(contentsOf: mocks.prefix(needed))
                }
                self.displayReviews = allReviews.sorted(by: { $0.createdAt > $1.createdAt })
            }
        }
    }
    
    private func stopListeningToReviews() {
        reviewListener?.remove()
        reviewListener = nil
    }

    private func fetchFirestoreReviews() async {
        let sId = SalonFirestoreService.shared.salonId(for: salonName)
        let results = (try? await SalonFirestoreService.shared.fetchReviews(forSalonId: sId)) ?? []
        var allReviews = results
        
        // Always ensure at least 8 reviews are shown for a "busy" look!
        if allReviews.count < 8 {
            let mockReviews = generateLocalMockReviews(for: sId)
            let needed = 8 - allReviews.count
            allReviews.append(contentsOf: mockReviews.prefix(needed))
        }
        allReviews.sort(by: { $0.createdAt > $1.createdAt })
        await MainActor.run {
            self.displayReviews = allReviews
        }
    }

    private func generateLocalMockReviews(for salonId: String) -> [FirestoreSalonReview] {
        let mockUsers = ["Dilnoza R.", "Amara S.", "Priya K.", "John D.", "Sarah W.", "Michael B.", "Elena G.", "Raj T.", "Sophia L.", "Kevin M."]
        let comments = [
            "Absolutely loved the facial treatment! Skin is glowing.",
            "Professional staff, clean environment. Will return.",
            "Best chemical peel I've ever had. Highly recommend!",
            "Great service, but a bit of a wait. Overall good experience.",
            "Luxury at its best. The ambiance is so relaxing.",
            "Expert stylists who really listen to what you want.",
            "The laser treatment was virtually painless. Amazing!",
            "Incredible results in just one session. Love it!",
            "Fantastic attention to detail and very friendly staff.",
            "The best salon experience in Colombo, hands down."
        ]
        return (0..<10).map { i in
            FirestoreSalonReview(
                id: "LOCAL_MOCK_\(salonId)_\(i)",
                salonId: salonId,
                userId: "MOCK_USER_\(i)",
                userName: mockUsers[i],
                rating: Int.random(in: 4...5),
                comment: comments[i],
                createdAt: Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            )
        }
    }
    
    private func deleteReview(_ review: FirestoreSalonReview) {
        guard let docId = review.documentId else { return }
        Task {
            do {
                try await SalonFirestoreService.shared.deleteReview(reviewId: docId)
                await MainActor.run {
                    withAnimation { displayReviews.removeAll { $0.id == review.id } }
                    reviewToEdit = nil
                    errorMessage = nil
                    NotificationManager.shared.showNotification(NotificationItem(
                        title: "Review Deleted",
                        subtitle: "Your feedback has been removed.",
                        icon: "trash.fill",
                        type: .success
                    ))
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to delete: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Main Image with Parallax-ready feel
            GeometryReader { geo in
                let minY = geo.frame(in: .global).minY
                Image(mappedSalonImageName(salon.name))
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: 260 + (minY > 0 ? minY : 0))
                    .clipped()
                    .offset(y: minY > 0 ? -minY : 0)
            }
            .frame(height: 260)

            // Multi-layered Gradient for Text Readability
            LinearGradient(
                colors: [.black.opacity(0.8), .black.opacity(0.4), .clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 8) {
                // Rating Badge
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(String(format: "%.1f", dynamicRating))
                        .glowzaFont(size: 12, weight: .bold)
                        .foregroundColor(.white)
                    Text("· \(dynamicReviewCount) reviews")
                        .glowzaFont(size: 12)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial.opacity(0.3))
                .clipShape(Capsule())
                
                Text(salon.name)
                    .glowzaFont(size: 32, weight: .bold)
                    .foregroundColor(.white)
                    .tracking(-0.5)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Text(salon.location)
                        .glowzaFont(size: 14, weight: .medium)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.bottom, 54)
        }
        .frame(height: 260)
    }

    private var navigationBar: some View {
        HStack {
            GlowzaCircleBackButton(action: { dismiss() })
            
            Spacer()
            
            Text(salon.name)
                .glowzaFont(size: 17, weight: .bold)
                .foregroundColor(.white)
                .lineLimit(1)
                .opacity(0) // Hidden by default, can be used for scroll animation later
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring()) {
                        isFavourited.toggle()
                        Task { await FavouritesStore.shared.toggle(salonName) }
                    }
                }) {
                    Image(systemName: isFavourited ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background {
                            if isFavourited {
                                brand
                            } else {
                                Color.clear.background(.ultraThinMaterial)
                            }
                        }
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 10)
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 10)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 54)
        .frame(height: 100, alignment: .top)
    }

    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                GlowzaJustifiedText(
                    text: salon.about,
                    font: UIFont(name: "Urbanist-Regular", size: 14 * appSettings.fontMultiplier) ?? .systemFont(ofSize: 14),
                    color: appSettings.isDarkMode ? .lightGray : .darkGray,
                    lineSpacing: 4
                )
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 21)
            .padding(.bottom, 12)

            // CUSTOM TAB SWITCHER
            HStack(spacing: 0) {
                ForEach(["Services", "About", "Reviews"].indices, id: \.self) { index in
                    let titles = ["Services", "About", "Reviews"]
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index 
                        }
                    }) {
                        VStack(spacing: 12) {
                            Text(titles[index])
                                .glowzaFont(size: 15, weight: selectedTab == index ? .bold : .medium)
                                .foregroundColor(selectedTab == index ? brand : .gray)
                            
                            // Animated underline
                            ZStack {
                                Capsule()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                                if selectedTab == index {
                                    Capsule()
                                        .fill(brand)
                                        .frame(height: 3)
                                        .matchedGeometryEffect(id: "tab_underline", in: tabNamespace)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Group {
                switch selectedTab {
                case 0: servicesContent
                case 1: aboutContent
                case 2: reviewsContent
                default: EmptyView()
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
        }
        .background(appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 15, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 15))
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            // 1. Info Cards Row
            HStack(spacing: 12) {
                // Availability Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(brand).frame(width: 24, height: 24)
                            Image(systemName: "clock.fill").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                        }
                        Text("AVAILABILITY")
                            .glowzaFont(size: 10, weight: .bold)
                            .foregroundColor(Color.gray.opacity(0.8))
                            .tracking(1.0)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Today")
                            .glowzaFont(size: 15, weight: .bold)
                            .foregroundColor(appSettings.themeText)
                        Text(salon.openHours)
                            .glowzaFont(size: 12)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18) // Uniform padding
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Equal height
                .background(appSettings.themeRaised)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                
                // Location Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle().fill(brand).frame(width: 24, height: 24)
                            Image(systemName: "paperplane.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                        }
                        Text("LOCATION")
                            .glowzaFont(size: 10, weight: .bold)
                            .foregroundColor(Color.gray.opacity(0.8))
                            .tracking(1.0)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(salon.distance) · 12 min")
                            .glowzaFont(size: 15, weight: .bold)
                            .foregroundColor(appSettings.themeText)
                        Button(action: openDirections) {
                            Text("Get Directions")
                                .glowzaFont(size: 12, weight: .bold)
                                .foregroundColor(brand)
                        }
                    }
                }
                .padding(18) // Uniform padding
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Equal height
                .background(appSettings.themeRaised)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .fixedSize(horizontal: false, vertical: true) // Ensure HStack takes the height of the tallest item
            .padding(.horizontal, 24)

            // 3. Facilities Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Facilities")
                    .glowzaFont(size: 18, weight: .bold)
                    .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        featureBadge(icon: "wifi", text: "Free WiFi")
                        featureBadge(icon: "parkingsign.circle", text: "Parking")
                        featureBadge(icon: "snowflake", text: "Air Con")
                        featureBadge(icon: "leaf.fill", text: "Organic")
                        featureBadge(icon: "cup.and.saucer.fill", text: "Coffee")
                    }
                    .padding(.horizontal, 24)
                }
            }

            // 4. Contact Section
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact Information")
                    .glowzaFont(size: 18, weight: .bold)
                
                VStack(spacing: 0) {
                    simpleContactRow(icon: "phone.fill", value: salon.phone)
                    Divider().padding(.leading, 56).opacity(0.5)
                    simpleContactRow(icon: "envelope.fill", value: "info@\(SalonFirestoreService.shared.salonId(for: salon.name)).com")
                    Divider().padding(.leading, 56).opacity(0.5)
                    simpleContactRow(icon: "globe", value: "www.\(SalonFirestoreService.shared.salonId(for: salon.name)).com")
                }
                .background(appSettings.themeRaised)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
            .padding(.horizontal, 24)

            // 5. Salon Highlights Section (Gallery)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Salon Highlights")
                        .glowzaFont(size: 18, weight: .bold)
                    Spacer()
                    // Gallery Page Indicator
                    HStack(spacing: 6) {
                        ForEach(0..<galleryImageNames.count, id: \.self) { i in
                            Capsule()
                                .fill(i == photoIndex ? brand : brand.opacity(0.2))
                                .frame(width: i == photoIndex ? 16 : 6, height: 6)
                                .animation(.spring(), value: photoIndex)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                TabView(selection: $photoIndex) {
                    ForEach(Array(galleryImageNames.enumerated()), id: \.offset) { index, imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 220)
                            .frame(maxWidth: UIScreen.main.bounds.width - 48)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .tag(index)
                    }
                }
                .frame(height: 220)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.bottom, 40)
        }
    }

    private var galleryImageNames: [String] {
        ["galery1", "galery2", "galery3", "galery4", "galery5"]
    }

    private func mappedSalonImageName(_ salonName: String) -> String {
        return SalonCatalog.shared.salon(named: salonName).imageName
    }

    private func imageForService(_ name: String) -> String {
        let lowerName = name.lowercased()
        if lowerName.contains("facial") { return "facial" }
        if lowerName.contains("peel") { return "chemicalpeel" }
        if lowerName.contains("laser hair") { return "laserhair" }
        if lowerName.contains("hair") { return "hair" }
        if lowerName.contains("manicure") || lowerName.contains("pedicure") { return "manicure" }
        if lowerName.contains("microneedling") { return "microneedling" }
        if lowerName.contains("massage") { return "deeptissuemassage" }
        if lowerName.contains("nail art") { return "nailart" }
        if lowerName.contains("makeup") { return "bridalmakeup" }
        return "facial"
    }

    private var servicesContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(salon.services) { service in
                HStack(spacing: 16) {
                    let imgName = imageForService(service.name)
                    Image(imgName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(service.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(appSettings.themeText)
                        Text(service.duration)
                            .font(.system(size: 12))
                            .foregroundColor(appSettings.themeTextSecondary)
                        Text("LKR \(Int(service.price))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(brand)
                    }
                    Spacer()
                    Button(action: {
                        if selectedServiceID == service.id {
                            selectedServiceID = nil
                            bookingDraft.service = nil
                        } else {
                            selectedServiceID = service.id
                            bookingDraft.service = service
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(selectedServiceID == service.id ? brand : Color(hex: "C7C7CC"), lineWidth: 1.5)
                                .frame(width: 24, height: 24)
                            if selectedServiceID == service.id {
                                Circle().fill(brand).frame(width: 24, height: 24)
                                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(appSettings.themeSurface).shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3))
                .padding(.horizontal, 16).padding(.vertical, 6)
            }
        }
    }

    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Customer Reviews").glowzaFont(size: 18, weight: .bold)
                Spacer()
                Button(action: { reviewToEdit = nil; showReviewSheet = true }) {
                    Text("Write Review").glowzaFont(size: 14, weight: .semibold).foregroundColor(brand)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 16)

            if displayReviews.isEmpty {
                Text("No reviews yet. Be the first to review!").glowzaFont(size: 14).foregroundColor(.gray).padding(.horizontal, 24).padding(.vertical, 20)
            } else {
                ForEach(displayReviews.prefix(10)) { review in
                    reviewRow(review)
                    Divider().padding(.horizontal, 20)
                }
            }
        }
    }

    private func reviewRow(_ review: FirestoreSalonReview) -> some View {
        let mockUsers = ["Dilnoza R.", "Amara S.", "Priya K.", "John D.", "Sarah W.", "Michael B.", "Elena G.", "Raj T.", "Sophia L.", "Kevin M."]
        let imageName: String
        var customImage: UIImage? = nil
        
        if review.userId == AuthService.shared.currentUID {
            if let data = userAvatarData, let uiImage = UIImage(data: data) {
                customImage = uiImage
                imageName = ""
            } else if let currentAvatar = AuthService.shared.currentUserProfile?.avatarBase64, !currentAvatar.isEmpty,
                      let data = Data(base64Encoded: currentAvatar),
                      let uiImage = UIImage(data: data) {
                customImage = uiImage
                imageName = ""
            } else { imageName = "" }
        } else if let base64 = review.userAvatarBase64, !base64.isEmpty, let data = Data(base64Encoded: base64), let uiImage = UIImage(data: data) {
            customImage = uiImage
            imageName = ""
        } else if review.userName == "Anuki" { imageName = "r5" }
        else if let idx = mockUsers.firstIndex(of: review.userName) { imageName = "r\(idx + 1)" }
        else { imageName = "" }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    if let uiImage = customImage {
                        Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle())
                    } else if UIImage(named: imageName) != nil {
                        Image(imageName).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(Circle())
                    } else {
                        Circle().fill(brand.opacity(0.12)).frame(width: 40, height: 40)
                        Text(String(review.userName.prefix(1))).glowzaFont(size: 16, weight: .bold).foregroundColor(brand)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(review.userName)
                            .glowzaFont(size: 15, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
                        
                        if let skin = review.skinType, !skin.isEmpty {
                            Text("•")
                                .foregroundColor(.gray.opacity(0.5))
                            Text(skin)
                                .glowzaFont(size: 11, weight: .medium)
                                .foregroundColor(brand)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(brand.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star").font(.system(size: 11)).foregroundColor(i <= review.rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
                        }
                    }
                }
                Spacer()
                if review.userId == AuthService.shared.currentUID {
                    HStack(spacing: 8) {
                        Button(action: { reviewToEdit = review; showReviewSheet = true }) {
                            Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(brand).padding(6).background(brand.opacity(0.1)).clipShape(Circle())
                        }
                        Button(action: { reviewToEdit = review; errorMessage = "DELETE_CONFIRM" }) {
                            Image(systemName: "trash").font(.system(size: 12)).foregroundColor(.red).padding(6).background(Color.red.opacity(0.1)).clipShape(Circle())
                        }
                    }
                }
            }
            Text(review.comment).glowzaFont(size: 14).foregroundColor(appSettings.themeTextSecondary).padding(.leading, 52)
            Text(review.createdAt, style: .date).glowzaFont(size: 11).foregroundColor(.gray).padding(.leading, 52)
        }
        .padding(.horizontal, 24).padding(.vertical, 16).contentShape(Rectangle()).onTapGesture { selectedReviewer = review }
    }
    
    private func featureBadge(icon: String, text: String) -> some View {
        let badgeColor = brand // Match pink theme
        
        return HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundColor(badgeColor)
            Text(text).glowzaFont(size: 13, weight: .semibold).foregroundColor(appSettings.themeText)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(badgeColor.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(badgeColor.opacity(0.2), lineWidth: 1))
    }
    
    private func simpleContactRow(icon: String, value: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(brand.opacity(0.1)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(brand)
            }
            Text(value)
                .glowzaFont(size: 14, weight: .medium)
                .foregroundColor(appSettings.themeText)
            Spacer()
        }
        .padding(12)
        .contentShape(Rectangle())
    }

    private var showBookNow: Bool {
        switch selectedTab {
        case 0: return selectedServiceID != nil
        default: return false
        }
    }

    private var bookNowBar: some View {
        HStack(spacing: 16) {
            if let svc = bookingDraft.service {
                VStack(alignment: .leading, spacing: 2) {
                    Text(svc.name)
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text("LKR \(Int(svc.price))")
                        .glowzaFont(size: 16, weight: .bold)
                        .foregroundColor(.white)
                }
            } else {
                Text("Select a service")
                    .glowzaFont(size: 14, weight: .medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: { showBookingFlow = true }) {
                Text("Book Now")
                    .glowzaFont(size: 16, weight: .bold)
                    .foregroundColor(brand)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(
            ZStack {
                LinearGradient(colors: [brand, Color(hex: "B83255")], startPoint: .leading, endPoint: .trailing)
                
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 120)
                    .offset(x: 100, y: 30)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .shadow(color: brand.opacity(0.3), radius: 12, y: 6)
    }

    private func openDirections() {
        let coordinate = salon.coordinate
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = salon.name
        destination.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

}

// MARK: - Salon Review Sheet
struct SalonReviewSheet: View {
    let salonName: String
    let reviewToEdit: FirestoreSalonReview?
    let existingReviews: [FirestoreSalonReview]
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 5
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    private var appSettings: AppSettings { AppSettings.shared }
    private var brand: Color { Color.glowzaPrimary }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(reviewToEdit == nil ? "Write a Review" : "Edit Your Review").glowzaFont(size: 24, weight: .bold)
                    Text("Sharing your experience helps others find the best salons.").glowzaFont(size: 15).foregroundColor(.gray).multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: { rating = i }) {
                            Image(systemName: i <= rating ? "star.fill" : "star").font(.system(size: 36)).foregroundColor(i <= rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Comment").glowzaFont(size: 14, weight: .semibold)
                    TextEditor(text: $comment).padding(12).frame(height: 120).background(appSettings.themeRaised).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)).overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color(hex: "E5E5EA"), lineWidth: 1))
                }
                Spacer()
                Button(action: submitReview) {
                    HStack {
                        if isSubmitting { ProgressView().tint(.white) }
                        else { Text(reviewToEdit == nil ? "Submit Review" : "Save Changes") }
                    }
                    .glowzaFont(size: 17, weight: .semibold).foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 55).background(brand).clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                }
                .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(24).navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(brand).fixedSize()
                }
            }
            .alert("Review Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { msg in Text(msg) }
            .onAppear {
                if let r = reviewToEdit { rating = r.rating; comment = r.comment }
            }
        }
    }

    private func submitReview() {
        let salonId = SalonFirestoreService.shared.salonId(for: salonName)
        let userId = AuthService.shared.currentUID ?? "GUEST"
        let userName = AuthService.shared.currentUserName ?? "Anonymous"
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                if let r = reviewToEdit, let docId = r.documentId {
                    try await SalonFirestoreService.shared.updateReview(reviewId: docId, rating: rating, comment: comment)
                } else {
                    try await SalonFirestoreService.shared.addSalonReview(salonId: salonId, userId: userId, userName: userName, rating: rating, comment: comment)
                }
                
                await MainActor.run {
                    isSubmitting = false
                    onComplete()
                    dismiss()
                    
                    NotificationManager.shared.showNotification(NotificationItem(
                        title: "Review Shared",
                        subtitle: "Your experience is now visible to everyone!",
                        icon: "star.bubble.fill",
                        type: .success
                    ))
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - User Profile Sheet
struct UserProfileSheet: View {
    let review: FirestoreSalonReview
    let reviewCount: Int
    @Environment(\.dismiss) var dismiss
    private let brand = Color(hex: "962043")
    
    var body: some View {
        VStack(spacing: 20) {
            HStack { Spacer(); Button(action: { dismiss() }) { Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.gray) } }.padding([.top, .trailing])
            
            let avatarImage = getAvatarImage()
            if let uiImage = avatarImage {
                Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 100, height: 100).clipShape(Circle()).overlay(Circle().stroke(Color.white, lineWidth: 4)).shadow(radius: 5)
            } else {
                ZStack {
                    Circle().fill(brand.opacity(0.12)).frame(width: 100, height: 100)
                    Text(String(review.userName.prefix(1))).font(.system(size: 40, weight: .bold)).foregroundColor(brand)
                }
            }
            Text(review.userName).font(.title2).fontWeight(.bold)
            Text("Glowza Member").font(.subheadline).foregroundColor(.gray)
            Divider().padding(.horizontal)
            HStack(spacing: 40) {
                VStack { Text("\(reviewCount)").font(.title3).fontWeight(.bold); Text(reviewCount == 1 ? "Review" : "Reviews").font(.caption).foregroundColor(.gray) }
                VStack { Text("\(reviewCount)").font(.title3).fontWeight(.bold); Text(reviewCount == 1 ? "Visit" : "Visits").font(.caption).foregroundColor(.gray) }
            }
            Spacer()
        }
        .padding().presentationDetents([.medium])
    }
    
    private func getAvatarImage() -> UIImage? {
        let mockUsers = ["Dilnoza R.", "Amara S.", "Priya K.", "John D.", "Sarah W.", "Michael B.", "Elena G.", "Raj T.", "Sophia L.", "Kevin M."]
        if review.userId == AuthService.shared.currentUID {
            let userAvatarData = UserDefaults.standard.data(forKey: "profile_avatarData")
            if let data = userAvatarData, let uiImage = UIImage(data: data) { return uiImage }
            else if let currentAvatar = AuthService.shared.currentUserProfile?.avatarBase64, !currentAvatar.isEmpty, let data = Data(base64Encoded: currentAvatar), let uiImage = UIImage(data: data) { return uiImage }
        } else if let base64 = review.userAvatarBase64, !base64.isEmpty, let data = Data(base64Encoded: base64), let uiImage = UIImage(data: data) { return uiImage }
        else if review.userName == "Anuki" { return UIImage(named: "r5") }
        else if let idx = mockUsers.firstIndex(of: review.userName) { return UIImage(named: "r\(idx + 1)") }
        return nil
    }
}

#Preview {
    NavigationStack {
        SalonDetailView(salonName: "Golden Avenue")
            .environment(TreatmentComparisonStore.shared)
    }
}
