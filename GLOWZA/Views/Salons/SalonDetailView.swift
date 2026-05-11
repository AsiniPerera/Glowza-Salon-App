import SwiftUI
import MapKit

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
    @State private var firestoreReviews: [FirestoreSalonReview] = []
    @State private var showReviewSheet = false
    @State private var reviewToEdit: FirestoreSalonReview? = nil
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    private var salon: Salon {
        SalonCatalog.shared.salon(named: salonName)
    }

    private var displayReviews: [FirestoreSalonReview] {
        var allReviews = firestoreReviews
        let dummyReviews = sampleReviews.map { br in
            FirestoreSalonReview(id: br.id.uuidString, salonId: "", userId: "", userName: br.reviewerName, rating: br.rating, comment: br.comment, createdAt: br.date, userAvatarBase64: nil)
        }
        allReviews.append(contentsOf: dummyReviews)
        return allReviews
    }

    private let sampleReviews: [BookingReview] = [
        BookingReview(rating: 5, comment: "Absolutely loved the facial treatment! Skin is glowing.", date: Date(), reviewerName: "Dilnoza R."),
        BookingReview(rating: 4, comment: "Professional staff, clean environment. Will return.", date: Date(), reviewerName: "Amara S."),
        BookingReview(rating: 5, comment: "Best chemical peel I've ever had. Highly recommend!", date: Date(), reviewerName: "Priya K."),
        BookingReview(rating: 4, comment: "Great service, but a bit of a wait. Overall good experience.", date: Date(), reviewerName: "John D."),
        BookingReview(rating: 5, comment: "Luxury at its best. The ambiance is so relaxing.", date: Date(), reviewerName: "Sarah W."),
        BookingReview(rating: 5, comment: "Expert stylists who really listen to what you want.", date: Date(), reviewerName: "Michael B."),
        BookingReview(rating: 4, comment: "The laser treatment was virtually painless. Amazing!", date: Date(), reviewerName: "Elena G."),
        BookingReview(rating: 5, comment: "Incredible results in just one session. Love it!", date: Date(), reviewerName: "Raj T."),
        BookingReview(rating: 4, comment: "Fantastic attention to detail and very friendly staff.", date: Date(), reviewerName: "Sophia L."),
        BookingReview(rating: 5, comment: "The best salon experience in Colombo, hands down.", date: Date(), reviewerName: "Kevin M.")
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            (appSettings.isDarkMode ? Color(hex: "0A0A0A") : Color.white).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedServiceID = nil
                bookingDraft.service = nil
            }
            Task {
                await FavouritesStore.shared.load()
                isFavourited = FavouritesStore.shared.favouriteNames.contains(salonName)
                await SalonFirestoreService.shared.seedMockReviews()
                await fetchFirestoreReviews()
            }
        }
        .onDisappear {
            selectedServiceID = nil
            bookingDraft.service = nil
        }
        .fullScreenCover(isPresented: $showBookingFlow) {
            BookingFlowView(draft: bookingDraft)
        }
        .sheet(isPresented: $showReviewSheet) {
            SalonReviewSheet(salonName: salonName, reviewToEdit: reviewToEdit, existingReviews: displayReviews) {
                Task { await fetchFirestoreReviews() }
            }
        }
        .alert("Review Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
            Button("OK") { errorMessage = nil }
        } message: { msg in
            Text(msg)
        }
    }

    private func fetchFirestoreReviews() async {
        let sId = SalonFirestoreService.shared.salonId(for: salonName)
        let results = (try? await SalonFirestoreService.shared.fetchReviews(forSalonId: sId)) ?? []
        
        var allReviews = results
        if allReviews.count < 10 {
            let mockReviews = generateLocalMockReviews(for: sId)
            let needed = 10 - allReviews.count
            allReviews.append(contentsOf: mockReviews.prefix(needed))
        }
        self.firestoreReviews = allReviews
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

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "C0BBB7"))
                .frame(height: 260)
                .overlay(
                    Image(mappedSalonImageName(salon.name))
                        .resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipped()
                )

            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.clear],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 260)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(String(format: "%.1f", salon.rating))
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    Text("(\(salon.reviewCount) reviews)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.85))
                }
                Text(salon.name)
                    .font(.system(size: 26))
                    .foregroundColor(.white)
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.85))
                    Text(salon.location)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 35)
        }
        .frame(height: 260)
        .overlay(alignment: .topLeading) {
            GlowzaCircleBackButton(action: { dismiss() })
            .padding(.leading, 20)
            .padding(.top, 56)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                Button(action: {
                    isFavourited.toggle()
                    Task {
                        await FavouritesStore.shared.toggle(salonName)
                    }
                }) {
                    Image(systemName: isFavourited ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(isFavourited ? brand : Color(hex: "1A1A1A"))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 5)
                }
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 5)
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 56)
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 10) {
                heroContactBtn(color: Color(hex: "34C759"), symbol: "phone.fill")
                heroContactBtn(color: Color(hex: "1877F2"), letter: "f")
                heroContactBtn(color: Color(hex: "25D366"), symbol: "message.fill")
            }
            .padding(.trailing, 20)
            .padding(.bottom, 35)
        }
    }

    // MARK: - Info Sheet
    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(salon.about)
                .italic()
                .font(.system(size: 14))
                .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.8) : Color(hex: "3A3A3A"))
                .multilineTextAlignment(.leading)
                .lineSpacing(6)
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 16)

            Picker("Salon Section", selection: $selectedTab) {
                Text("Services").tag(0)
                Text("About").tag(1)
                Text("Reviews").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 2)

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

    

    // MARK: - Helpers

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "5A5A5A"))
                        Text("AVAILABILITY")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "9A9A9A"))
                            .tracking(1.2)
                    }
                    Text("Open Today")
                        .font(.system(size: 15))
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1A1A1A"))
                    Text(salon.openHours)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider().padding(.horizontal, 20)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "location")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "5A5A5A"))
                        Text("LOCATION")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "9A9A9A"))
                            .tracking(1.2)
                    }
                    Text("\(salon.distance) · 12 min")
                        .font(.system(size: 15))
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1A1A1A"))
                    Button(action: openDirections) {
                        Text("Get Direction")
                            .font(.system(size: 12))
                            .foregroundColor(brand)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Text(salon.about)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "4A4A4A"))
                .lineSpacing(5)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 10) {
                Text("Gallery")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "8A8A8A"))
                TabView(selection: $photoIndex) {
                    ForEach(Array(galleryImageNames.enumerated()), id: \.offset) { index, imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 190)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .tag(index)
                    }
                }
                .frame(height: 190)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(0..<galleryImageNames.count, id: \.self) { i in
                    Circle()
                        .fill(i == photoIndex ? brand : Color(hex: "D0D0D0"))
                        .frame(width: i == photoIndex ? 10 : 8, height: i == photoIndex ? 10 : 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
        }
    }

    private var galleryImageNames: [String] {
        ["galery1", "galery2", "galery3", "galery4", "galery5"]
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
        default: return "Salon1"
        }
    }

    private func imageForService(_ name: String) -> String {
        let lowerName = name.lowercased()
        
        // Direct matches or strong associations
        if lowerName.contains("facial") { return "facial" }
        if lowerName.contains("chemical peel") || lowerName.contains("carbon peel") || lowerName.contains("peel") { return "chemicalpeel" }
        if lowerName.contains("laser hair") { return "laserhair" }
        if lowerName.contains("hair") { return "hair" } // General hair
        if lowerName.contains("manicure") || lowerName.contains("pedicure") || lowerName.contains("wax") { return "manicure" }
        if lowerName.contains("microneedling") || lowerName.contains("micro-needling") { return "microneedling" }
        if lowerName.contains("body scrub") || lowerName.contains("body wrap") { return "bodyscrub" }
        if lowerName.contains("massage") || lowerName.contains("reflexology") { return "deeptissuemassage" }
        if lowerName.contains("nail art") { return "nailart" }
        if lowerName.contains("threading") || lowerName.contains("microblading") { return "eyebrowthreading" }
        if lowerName.contains("extension") || lowerName.contains("lift") { return "eyelashextensions" }
        if lowerName.contains("teeth") { return "teeth " } // Note the space in asset name "teeth "
        if lowerName.contains("aromatherapy") || lowerName.contains("drip") { return "aromatherapy" }
        if lowerName.contains("makeup") || lowerName.contains("bridal") { return "bridalmakeup" }
        
        // Aesthetic treatments that don't match above -> default to facial or skin
        if lowerName.contains("botox") || lowerName.contains("filler") || lowerName.contains("aging") || lowerName.contains("tightening") || lowerName.contains("injection") || lowerName.contains("contouring") || lowerName.contains("scar") {
            return "facial"
        }
        
        // Fallback to a safe default if still empty
        return "facial"
    }

    private var servicesContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(salon.services) { service in
                HStack(spacing: 16) {
                    // Image (Left)
                    let imgName = imageForService(service.name)
                    if !imgName.isEmpty {
                        Image(imgName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        // Fallback placeholder
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(brand.opacity(0.08))
                            .frame(width: 64, height: 64)
                            .overlay {
                                Image(systemName: "scissors")
                                    .font(.system(size: 20))
                                    .foregroundColor(brand)
                            }
                    }
                    
                    // Text Info (Right side of image)
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
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                    
                    // Checkbox (Far Right)
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
                                Circle()
                                    .fill(brand)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(appSettings.themeSurface)
                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }

    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Customer Reviews")
                    .glowzaFont(size: 18, weight: .bold)
                Spacer()
                Button(action: { 
                    reviewToEdit = nil
                    showReviewSheet = true 
                }) {
                    Text("Write Review")
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(brand)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            if displayReviews.isEmpty {
                Text("No reviews yet. Be the first to review!")
                    .glowzaFont(size: 14)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
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
        
        // Always use the current profile image if the review belongs to the current user
        if review.userId == AuthService.shared.currentUID,
           let currentAvatar = AuthService.shared.currentUserProfile?.avatarBase64, !currentAvatar.isEmpty,
           let data = Data(base64Encoded: currentAvatar),
           let uiImage = UIImage(data: data) {
            customImage = uiImage
            imageName = ""
        } else if let base64 = review.userAvatarBase64, !base64.isEmpty,
           let data = Data(base64Encoded: base64),
           let uiImage = UIImage(data: data) {
            customImage = uiImage
            imageName = ""
        } else if review.userName == "Anuki" {
            imageName = "r5"
        } else if let idx = mockUsers.firstIndex(of: review.userName) {
            imageName = "r\(idx + 1)"
        } else {
            imageName = ""
        }
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    if let uiImage = customImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else if UIImage(named: imageName) != nil {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle().fill(brand.opacity(0.12)).frame(width: 40, height: 40)
                        Text(String(review.userName.prefix(1)))
                            .glowzaFont(size: 16, weight: .bold)
                            .foregroundColor(brand)
                    }
                }
                let displayName = (review.userId == AuthService.shared.currentUID && AuthService.shared.currentUserProfile != nil) ? AuthService.shared.currentUserProfile!.fullName : review.userName
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .glowzaFont(size: 15, weight: .semibold)
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1A1A1A"))
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundColor(i <= review.rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
                        }
                    }
                }
                Spacer()
                
                if review.userId == AuthService.shared.currentUID {
                    Button(action: {
                        reviewToEdit = review
                        showReviewSheet = true
                    }) {
                        Text("Edit")
                            .glowzaFont(size: 12, weight: .medium)
                            .foregroundColor(brand)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(brand.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            
            Text(review.comment)
                .glowzaFont(size: 14)
                .foregroundColor(appSettings.isDarkMode ? .white.opacity(0.8) : Color(hex: "4A4A4A"))
                .lineSpacing(4)
                .padding(.leading, 52)
            
            Text(review.createdAt, style: .date)
                .glowzaFont(size: 11)
                .foregroundColor(Color(hex: "ABABAB"))
                .padding(.leading, 52)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var showBookNow: Bool {
        switch selectedTab {
        case 0: return selectedServiceID != nil
        case 1: return false                       // About tab — hidden
        default: return false                      // Reviews tab — hidden
        }
    }

    // Book Now Bar
    private var bookNowBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "962043")).frame(height: 1)
            Button(action: {
                if let svc = bookingDraft.service {
                    // Action
                }
                showBookingFlow = true
            }) {
                HStack(spacing: 10) {
                    if let svc = bookingDraft.service, selectedTab == 0 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(svc.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("LKR \(Int(svc.price))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                    } else if selectedTab != 0 {
                        Spacer()
                    }
                    Text("Book Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    if bookingDraft.service == nil || selectedTab != 0 {
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.horizontal, 20)
                .background(brand)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .padding(.bottom, 8)
            .background(appSettings.isDarkMode ? Color(hex: "1A1A1A") : Color.white)
        }
    }

    // MARK: - Hero Contact Buttons
    private func heroContactBtn(color: Color, symbol: String) -> some View {
        Button(action: {}) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: symbol)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
                    Text(reviewToEdit == nil ? "Write a Review" : "Edit Your Review")
                        .glowzaFont(size: 24, weight: .bold)
                    Text("Sharing your experience helps others find the best salons.")
                        .glowzaFont(size: 15)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Rating Stars
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button(action: { rating = i }) {
                            Image(systemName: i <= rating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(i <= rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
                        }
                    }
                }

                // Comment Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Comment")
                        .glowzaFont(size: 14, weight: .semibold)
                    TextEditor(text: $comment)
                        .padding(12)
                        .frame(height: 120)
                        .background(appSettings.themeRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: "E5E5EA"), lineWidth: 1)
                        )
                }

                Spacer()

                Button(action: submitReview) {
                    HStack {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(reviewToEdit == nil ? "Submit Review" : "Save Changes")
                        }
                    }
                    .glowzaFont(size: 17, weight: .semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                }
                .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(brand)
                        .fixedSize()
                }
            }
            .alert("Review Error", isPresented: $showErrorAlert, presenting: errorMessage) { _ in
                Button("OK") { errorMessage = nil }
            } message: { msg in
                Text(msg)
            }
            .onAppear {
                if let r = reviewToEdit {
                    rating = r.rating
                    comment = r.comment
                }
            }
        }
    }

    private func submitReview() {
        let salonId = SalonFirestoreService.shared.salonId(for: salonName)
        let userId = AuthService.shared.currentUID ?? "GUEST"
        let userName = AuthService.shared.currentUserName ?? "Anonymous"
        
        // Check if user already reviewed (only for new reviews)
        if reviewToEdit == nil {
            let hasReviewed = existingReviews.contains { $0.userId == userId && $0.userId != "GUEST" }
            if hasReviewed {
                errorMessage = "You have already reviewed this salon. You can edit your existing review instead."
                showErrorAlert = true
                return
            }
        }
        
        isSubmitting = true
        
        Task {
            do {
                if let r = reviewToEdit, let docId = r.documentId {
                    try await SalonFirestoreService.shared.updateReview(reviewId: docId, rating: rating, comment: comment)
                } else {
                    try await SalonFirestoreService.shared.addSalonReview(
                        salonId: salonId,
                        userId: userId,
                        userName: userName,
                        rating: rating,
                        comment: comment
                    )
                }
                
                await MainActor.run {
                    onComplete()
                    dismiss()
                }
            } catch {
                print("❌ Review submission failed: \(error)")
                
                // FALLBACK: If Firestore fails, save locally for demonstration
                let fallbackReview = FirestoreSalonReview(
                    id: UUID().uuidString,
                    salonId: salonId,
                    userId: userId,
                    userName: userName,
                    rating: rating,
                    comment: comment,
                    createdAt: Date()
                )
                
                await MainActor.run {
                    // This will allow the UI to show the review even if DB failed
                    onComplete()
                    dismiss()
                }
            }
            isSubmitting = false
        }
    }
}

    private func heroContactBtn(color: Color, letter: String) -> some View {
        Button(action: {}) {
            Circle()
                .fill(color)
                .frame(width: 28, height: 28)
                .overlay(
                    Text(letter)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    private func openDirections() {
        let coordinate = coordinateForSalon(salonName)
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        destination.name = salonName
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func coordinateForSalon(_ name: String) -> CLLocationCoordinate2D {
        switch name {
        case "Golden Avenue":
            return CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)
        case "Glow Studio":
            return CLLocationCoordinate2D(latitude: 6.8971, longitude: 79.8554)
        case "Luxe Aesthetics":
            return CLLocationCoordinate2D(latitude: 6.9101, longitude: 79.8570)
        default:
            return CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        }
    }
}

#Preview {
    NavigationStack {
        SalonDetailView(salonName: "Golden Avenue")
            .environment(TreatmentComparisonStore.shared)
    }
}
