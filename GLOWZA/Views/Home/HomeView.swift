import SwiftUI
import MapKit

private let brand = Color(hex: "962043")

// MARK: - Models
struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let category: String
}

struct SalonPreview: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let distance: String
    let rating: Double
    let reviews: Int
    let score: Double
    let coordinate: CLLocationCoordinate2D
    let imageName: String
    let categories: [String]
}

struct SalonAnnotation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let rating: Double
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SalonAnnotation, rhs: SalonAnnotation) -> Bool { lhs.id == rhs.id }
}

// MARK: - HomeView
struct HomeView: View {

    @Environment(AppSettings.self) private var appSettings

    @State private var searchText = ""
    @State private var selectedServiceID: UUID? = nil
    @State private var selectedSalonName: String? = nil
    @State private var showMapSheet = false
    @State private var showNotificationsView = false
    @State private var showFavourites = false
    @State private var currentPromotionPage: Int = 0
    @State private var profileAvatarData: Data? = UserDefaults.standard.data(forKey: "profile_avatarData")
    @State private var profileName: String = UserDefaults.standard.string(forKey: "profile_fullName") ?? "User"
    @State private var isSalonsLoading = false

    private let services: [ServiceCategory] = [
        .init(name: "Facial Care", icon: "face.smiling", category: "Skin"),
        .init(name: "Skin Therapy", icon: "leaf", category: "Skin"),
        .init(name: "Chemical Peel", icon: "flask", category: "Skin"),
        .init(name: "HydraFacial", icon: "drop.fill", category: "Skin"),
        .init(name: "Microneedling", icon: "syringe", category: "Skin"),
        .init(name: "Hair Cut", icon: "scissors", category: "Hair"),
        .init(name: "Hair Color", icon: "paintbrush.pointed", category: "Hair"),
        .init(name: "Hair Styling", icon: "comb", category: "Hair"),
        .init(name: "Laser Hair", icon: "bolt", category: "Hair"),
        .init(name: "Hair Treatment", icon: "leaf.fill", category: "Hair"),
        .init(name: "PRP for Hair", icon: "heart.text.square", category: "Hair"),
        .init(name: "Manicure", icon: "hand.raised", category: "Nails"),
        .init(name: "Pedicure", icon: "heart", category: "Nails"),
        .init(name: "Nail Art", icon: "wand.and.stars", category: "Nails"),
        .init(name: "Gel Manicure", icon: "hand.point.up.fill", category: "Nails")
    ]

    @State private var allSalons: [SalonPreview] = [
      .init(name: "Golden Avenue", location: "Moratuwa, Colombo", distance: "2.0 km", rating: 4.7, reviews: 312, score: 0.95,
          coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820), imageName: "Salon1", categories: ["Facial Care", "Chemical Peel", "HydraFacial"]),
      .init(name: "Glow Studio", location: "Bambalapitiya, Colombo", distance: "3.5 km", rating: 4.6, reviews: 198, score: 0.88,
          coordinate: CLLocationCoordinate2D(latitude: 6.8971, longitude: 79.8554), imageName: "salon2", categories: ["Hair Cut", "Hair Color", "Hair Styling"]),
      .init(name: "Luxe Aesthetics", location: "Colombo 03", distance: "5.0 km", rating: 4.5, reviews: 245, score: 0.82,
          coordinate: CLLocationCoordinate2D(latitude: 6.9101, longitude: 79.8570), imageName: "Salon1", categories: ["Manicure", "Pedicure", "Nail Art"]),
      .init(name: "Velvet Touch", location: "Nugegoda, Colombo", distance: "6.2 km", rating: 4.4, reviews: 131, score: 0.78,
          coordinate: CLLocationCoordinate2D(latitude: 6.8655, longitude: 79.8991), imageName: "salon2", categories: ["Facial Care", "Hair Cut", "Manicure"]),
      .init(name: "Aura Beauty Bar", location: "Colombo 03", distance: "8.1 km", rating: 4.8, reviews: 420, score: 0.97,
          coordinate: CLLocationCoordinate2D(latitude: 6.8935, longitude: 79.8534), imageName: "Salon1", categories: ["Skin Therapy", "Hair Styling", "Nail Art"]),
      .init(name: "Silk & Shine", location: "Battaramulla, Colombo", distance: "4.3 km", rating: 4.9, reviews: 287, score: 0.93,
          coordinate: CLLocationCoordinate2D(latitude: 6.8901, longitude: 79.8812), imageName: "salon2", categories: ["Chemical Peel", "Laser Hair", "Gel Manicure"]),
      .init(name: "Prime Beauty", location: "Wattala, Colombo", distance: "7.8 km", rating: 4.3, reviews: 165, score: 0.75,
          coordinate: CLLocationCoordinate2D(latitude: 6.9907, longitude: 79.8910), imageName: "Salon1", categories: ["Microneedling", "PRP for Hair", "Manicure"]),
      .init(name: "Elegance Salon", location: "Malabe, Colombo", distance: "9.2 km", rating: 4.6, reviews: 276, score: 0.86,
          coordinate: CLLocationCoordinate2D(latitude: 6.9062, longitude: 79.9582), imageName: "salon2", categories: ["Facial Care", "Skin Therapy"]),
      .init(name: "Crystal Beauty", location: "Colombo 04", distance: "6.5 km", rating: 4.7, reviews: 354, score: 0.92,
          coordinate: CLLocationCoordinate2D(latitude: 6.8851, longitude: 79.8606), imageName: "Salon1", categories: ["Hair Cut", "Hair Color"]),
      .init(name: "Radiant Aesthetic", location: "Galle Road, Colombo", distance: "3.2 km", rating: 4.8, reviews: 398, score: 0.96,
          coordinate: CLLocationCoordinate2D(latitude: 6.8774, longitude: 79.8588), imageName: "salon2", categories: ["Manicure", "Pedicure"]),
      .init(name: "Cinnamon Glow", location: "Colombo 05", distance: "4.1 km", rating: 4.5, reviews: 214, score: 0.84,
          coordinate: CLLocationCoordinate2D(latitude: 6.8978, longitude: 79.8712), imageName: "Salon1", categories: ["HydraFacial", "Laser Hair"]),
      .init(name: "Rose Mirror", location: "Rajagiriya, Colombo", distance: "5.4 km", rating: 4.4, reviews: 176, score: 0.80,
          coordinate: CLLocationCoordinate2D(latitude: 6.9070, longitude: 79.8959), imageName: "salon2", categories: ["Microneedling", "Hair Treatment"]),
      .init(name: "Urban Bloom", location: "Wellawatte, Colombo", distance: "5.9 km", rating: 4.6, reviews: 239, score: 0.89,
          coordinate: CLLocationCoordinate2D(latitude: 6.8747, longitude: 79.8602), imageName: "Salon1", categories: ["Chemical Peel", "Gel Manicure"]),
      .init(name: "Coco Beauty Lounge", location: "Kirulapone, Colombo", distance: "6.1 km", rating: 4.3, reviews: 141, score: 0.77,
          coordinate: CLLocationCoordinate2D(latitude: 6.8792, longitude: 79.8768), imageName: "salon2", categories: ["Facial Care", "Hair Styling", "Nail Art"]),
      .init(name: "The Beauty Deck", location: "Colombo 06", distance: "6.8 km", rating: 4.7, reviews: 268, score: 0.91,
          coordinate: CLLocationCoordinate2D(latitude: 6.8760, longitude: 79.8583), imageName: "Salon1", categories: ["Skin Therapy", "Hair Cut"]),
      .init(name: "Lotus Salon", location: "Colombo 07", distance: "7.0 km", rating: 4.8, reviews: 305, score: 0.94,
          coordinate: CLLocationCoordinate2D(latitude: 6.9123, longitude: 79.8673), imageName: "salon2", categories: ["HydraFacial", "Hair Color"]),
      .init(name: "Pearl Skin Studio", location: "Colombo 08", distance: "7.3 km", rating: 4.6, reviews: 223, score: 0.87,
          coordinate: CLLocationCoordinate2D(latitude: 6.9142, longitude: 79.8774), imageName: "Salon1", categories: ["Microneedling", "Gel Manicure"]),
      .init(name: "Mirror Muse", location: "Colombo 02", distance: "7.7 km", rating: 4.4, reviews: 187, score: 0.81,
          coordinate: CLLocationCoordinate2D(latitude: 6.9272, longitude: 79.8503), imageName: "salon2", categories: ["Chemical Peel", "Hair Treatment"]),
      .init(name: "Golden Petals", location: "Colombo 01", distance: "8.0 km", rating: 4.2, reviews: 129, score: 0.73,
          coordinate: CLLocationCoordinate2D(latitude: 6.9350, longitude: 79.8447), imageName: "Salon1", categories: ["Skin Therapy", "Nail Art"]),
      .init(name: "Blush Avenue", location: "Thimbirigasyaya, Colombo", distance: "8.4 km", rating: 4.7, reviews: 261, score: 0.90,
          coordinate: CLLocationCoordinate2D(latitude: 6.8959, longitude: 79.8743), imageName: "salon2", categories: ["Facial Care", "Gel Manicure"]),
      .init(name: "Opal Aesthetics", location: "Havelock Town, Colombo", distance: "8.8 km", rating: 4.8, reviews: 334, score: 0.96,
          coordinate: CLLocationCoordinate2D(latitude: 6.8830, longitude: 79.8699), imageName: "Salon1", categories: ["HydraFacial", "PRP for Hair", "Gel Manicure"])
    ]

    private var filteredSalons: [SalonPreview] {
        var result = searchText.isEmpty ? allSalons : allSalons.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }

      if let selectedServiceID,
         let selectedService = services.first(where: { $0.id == selectedServiceID }) {
        result = result.filter { $0.categories.contains(selectedService.name) }
      }

        return result
    }

    // MARK: - Dark-mode helpers
    private var pageBackground:    Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText:       Color { appSettings.themeText }
    private var secondaryText:     Color { appSettings.themeTextSecondary }
    private var borderColor:       Color { appSettings.themeBorder }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 12)
                        searchBar
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        promotionsSection
                            .padding(.bottom, 28)
                        servicesSection
                            .padding(.bottom, 24)
                        nearbySection
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { selectedSalonName != nil },
                set: { if !$0 { selectedSalonName = nil } }
            )) {
                if let name = selectedSalonName {
                    SalonDetailView(salonName: name)
                }
            }
            .navigationDestination(isPresented: $showNotificationsView) {
                NotificationsView()
            }
            .sheet(isPresented: $showMapSheet) {
                SalonMapView(salons: allSalons)
            }
            .sheet(isPresented: $showFavourites) {
                FavouriteSalonsView().environment(appSettings)
            }
            .task {
                await syncSalonsToFirestore()
                await loadSalonsFromFirestore()
                await SalonFirestoreService.shared.seedMockReviews()
                refreshProfileHeader()
            }
            .onAppear {
                appSettings.speak("Home screen")
            }
            .onReceive(NotificationCenter.default.publisher(for: .glowzaProfileUpdated)) { _ in
                refreshProfileHeader()
            }
            .onReceive(NotificationCenter.default.publisher(for: .glowzaQuickBookRequested)) { notification in
                guard let salonName = notification.object as? String else { return }
                selectedSalonName = salonName
            }
        }
    }

    private func refreshProfileHeader() {
        profileAvatarData = UserDefaults.standard.data(forKey: "profile_avatarData")
        profileName = UserDefaults.standard.string(forKey: "profile_fullName") ?? "User"
    }

    @MainActor
    private func syncSalonsToFirestore() async {
        let salons = SalonCatalog.shared.salons
        for salon in salons {
            let categories = Array(Set(salon.services.map { $0.category }))
            do {
                try await SalonFirestoreService.shared.upsertSalon(
                    name: salon.name,
                    location: salon.location,
                    distance: salon.distance,
                    rating: salon.rating,
                    reviewCount: salon.reviewCount,
                    score: salon.score,
                    categories: categories
                )
            } catch {
                print("Failed to sync salon \(salon.name): \(error)")
            }
        }
    }

    @MainActor
    private func loadSalonsFromFirestore() async {
        isSalonsLoading = true
        defer { isSalonsLoading = false }
        
        // Hardcode 20 salons with ALL services/categories from screenshots
        let allCategories = [
            "Facial Care", "Skin Therapy", "Chemical Peel", "HydraFacial", "Microdermabrasion",
            "Microneedling", "Hair Cut", "Hair Color", "Hair Styling", "Laser Hair",
            "Hair Treatment", "PRP for Hair", "Manicure", "Pedicure", "Nail Art", "Gel Manicure"
        ]
        
        func getShuffledCategories(forIndex idx: Int) -> [String] {
            var cats = Set<String>()
            // Guarantee every category is used at least once across 20 salons
            cats.insert(allCategories[idx % allCategories.count])
            
            // Add 3 to 6 more random unique categories
            let additionalCount = Int.random(in: 3...6)
            for _ in 0..<additionalCount {
                if let randomCat = allCategories.randomElement() {
                    cats.insert(randomCat)
                }
            }
            return Array(cats)
        }
        
        let hardcodedSalons = [
            SalonPreview(name: "Golden Avenue", location: "Colombo", distance: "2 km", rating: 4.7, reviews: 312, score: 0.95, coordinate: CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612), imageName: "Salon1", categories: getShuffledCategories(forIndex: 0)),
            SalonPreview(name: "Glow Studio", location: "Colombo", distance: "3.5 km", rating: 4.5, reviews: 150, score: 0.88, coordinate: CLLocationCoordinate2D(latitude: 6.9344, longitude: 79.8450), imageName: "salon2", categories: getShuffledCategories(forIndex: 1)),
            SalonPreview(name: "Luxe Aesthetics", location: "Colombo", distance: "5 km", rating: 4.8, reviews: 200, score: 0.92, coordinate: CLLocationCoordinate2D(latitude: 6.9120, longitude: 79.8550), imageName: "salon3", categories: getShuffledCategories(forIndex: 2)),
            SalonPreview(name: "Velvet Touch", location: "Colombo", distance: "1.5 km", rating: 4.6, reviews: 180, score: 0.90, coordinate: CLLocationCoordinate2D(latitude: 6.9000, longitude: 79.8700), imageName: "salon4", categories: getShuffledCategories(forIndex: 3)),
            SalonPreview(name: "Aura Beauty Bar", location: "Colombo", distance: "4 km", rating: 4.4, reviews: 90, score: 0.85, coordinate: CLLocationCoordinate2D(latitude: 6.8850, longitude: 79.8600), imageName: "salon5", categories: getShuffledCategories(forIndex: 4)),
            SalonPreview(name: "Silk & Shine", location: "Colombo", distance: "2.5 km", rating: 4.3, reviews: 120, score: 0.80, coordinate: CLLocationCoordinate2D(latitude: 6.9200, longitude: 79.8500), imageName: "salon6", categories: getShuffledCategories(forIndex: 5)),
            SalonPreview(name: "Prime Beauty", location: "Colombo", distance: "3 km", rating: 4.9, reviews: 400, score: 0.98, coordinate: CLLocationCoordinate2D(latitude: 6.9400, longitude: 79.8650), imageName: "salon7", categories: getShuffledCategories(forIndex: 6)),
            SalonPreview(name: "Elegance Salon", location: "Colombo", distance: "6 km", rating: 4.2, reviews: 80, score: 0.75, coordinate: CLLocationCoordinate2D(latitude: 6.9500, longitude: 79.8750), imageName: "salon8", categories: getShuffledCategories(forIndex: 7)),
            SalonPreview(name: "Crystal Beauty", location: "Colombo", distance: "7 km", rating: 4.1, reviews: 60, score: 0.70, coordinate: CLLocationCoordinate2D(latitude: 6.9150, longitude: 79.8400), imageName: "salon9", categories: getShuffledCategories(forIndex: 8)),
            SalonPreview(name: "Radiant Aesthetic", location: "Colombo", distance: "1 km", rating: 5.0, reviews: 500, score: 1.00, coordinate: CLLocationCoordinate2D(latitude: 6.8900, longitude: 79.8800), imageName: "salon10", categories: getShuffledCategories(forIndex: 9)),
            SalonPreview(name: "Glow Palace", location: "Colombo", distance: "4.5 km", rating: 4.5, reviews: 140, score: 0.87, coordinate: CLLocationCoordinate2D(latitude: 6.9050, longitude: 79.8450), imageName: "salon6", categories: getShuffledCategories(forIndex: 10)),
            SalonPreview(name: "Pure Skin Lab", location: "Colombo", distance: "5.5 km", rating: 4.6, reviews: 160, score: 0.89, coordinate: CLLocationCoordinate2D(latitude: 6.9250, longitude: 79.8700), imageName: "salon7", categories: getShuffledCategories(forIndex: 11)),
            SalonPreview(name: "The Hair Lounge", location: "Colombo", distance: "2 km", rating: 4.4, reviews: 110, score: 0.84, coordinate: CLLocationCoordinate2D(latitude: 6.8700, longitude: 79.8550), imageName: "salon8", categories: getShuffledCategories(forIndex: 12)),
            SalonPreview(name: "Serene Spa", location: "Colombo", distance: "8 km", rating: 4.3, reviews: 70, score: 0.78, coordinate: CLLocationCoordinate2D(latitude: 6.8800, longitude: 79.8650), imageName: "salon9", categories: getShuffledCategories(forIndex: 13)),
            SalonPreview(name: "Urban Nails", location: "Colombo", distance: "3.5 km", rating: 4.7, reviews: 220, score: 0.91, coordinate: CLLocationCoordinate2D(latitude: 6.9100, longitude: 79.8400), imageName: "salon10", categories: getShuffledCategories(forIndex: 14)),
            SalonPreview(name: "Divine Beauty", location: "Colombo", distance: "4.2 km", rating: 4.5, reviews: 130, score: 0.86, coordinate: CLLocationCoordinate2D(latitude: 6.8950, longitude: 79.8750), imageName: "Salon1", categories: getShuffledCategories(forIndex: 15)),
            SalonPreview(name: "Bloom Studio", location: "Colombo", distance: "2.8 km", rating: 4.6, reviews: 170, score: 0.89, coordinate: CLLocationCoordinate2D(latitude: 6.9300, longitude: 79.8550), imageName: "salon2", categories: getShuffledCategories(forIndex: 16)),
            SalonPreview(name: "Infinity Glow", location: "Colombo", distance: "6.5 km", rating: 4.3, reviews: 95, score: 0.81, coordinate: CLLocationCoordinate2D(latitude: 6.9450, longitude: 79.8600), imageName: "salon3", categories: getShuffledCategories(forIndex: 17)),
            SalonPreview(name: "Skin Deep", location: "Colombo", distance: "1.8 km", rating: 4.8, reviews: 240, score: 0.93, coordinate: CLLocationCoordinate2D(latitude: 6.9000, longitude: 79.8500), imageName: "salon4", categories: getShuffledCategories(forIndex: 18)),
            SalonPreview(name: "The Beauty Room", location: "Colombo", distance: "3.2 km", rating: 4.4, reviews: 115, score: 0.83, coordinate: CLLocationCoordinate2D(latitude: 6.9150, longitude: 79.8650), imageName: "salon5", categories: getShuffledCategories(forIndex: 19))
        ]
        
        self.allSalons = hardcodedSalons
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            ZStack {
                if let data = profileAvatarData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(brand.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .glowzaFont(.h4)
                        .foregroundColor(brand)
                }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Welcome,")
                    .glowzaFont(.caption)
                    .foregroundColor(secondaryText)
                Text(profileName.components(separatedBy: " ").first ?? profileName)
                    .glowzaFont(.body, weight: .bold)
                    .foregroundColor(primaryText)
            }

            Spacer()

            if profileName != "User" {
                HStack(spacing: 10) {
                    Button(action: {
                        showFavourites = true
                    }) {
                        Image(systemName: "heart.fill")
                            .glowzaFont(size: 16, weight: .medium)
                            .foregroundColor(brand)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                    }
                    
                    Button(action: {
                        showNotificationsView = true
                    }) {
                        Image(systemName: "bell.fill")
                            .glowzaFont(size: 16, weight: .medium)
                            .foregroundColor(brand)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 6, y: 2)
                    }
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .glowzaFont(size: 16, weight: .medium)
                .foregroundColor(secondaryText)
            TextField("Search salons or city ...", text: $searchText, prompt: Text("Search salons or city ...").foregroundColor(appSettings.isHighContrast ? .white : secondaryText))
                .glowzaFont(size: 15, weight: .regular)
                .foregroundColor(primaryText)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 18)
        .frame(height: 48)
        .background(surfaceBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(borderColor, lineWidth: 1))
        .hcBorderCapsule()
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }

    private var featuredBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .glowzaFont(size: 11, weight: .semibold)
                    .foregroundColor(Color.white.opacity(0.9))
                Text("First Visit Offer")
                    .glowzaFont(size: 12, weight: .semibold)
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.18))
            .clipShape(Capsule())

            Text("20% off your")
                .glowzaFont(.h4, weight: .bold)
                .foregroundColor(.white)
            Text("first treatment")
                .glowzaFont(.h4, weight: .bold)
                .foregroundColor(.white)
                .padding(.top, -4)

            Text("Book now & glow up")
                .glowzaFont(.caption)
                .foregroundColor(Color.white.opacity(0.75))

            Button(action: {}) {
                Text("Book Now")
                    .glowzaFont(.caption, weight: .semibold)
                    .foregroundColor(Color(hex: "962043"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "962043"), Color(hex: "B83255")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 130, height: 130)
                    .offset(x: 80, y: -40)
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 90, height: 90)
                    .offset(x: 120, y: 35)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
    }

    private var promotionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Promotions")
                .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                .foregroundColor(primaryText)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                TabView(selection: $currentPromotionPage) {
                    // Promotion 1 - salon5 (Aura Beauty Bar)
                    PromoBannerCard(
                        imageName: "salon5",
                        title: "Luxury Skin Care",
                        subtitle: "Get 30% off on all facial treatments",
                        discount: "30",
                        salonName: "Aura Beauty Bar",
                        onBooking: { selectedSalonName = "Aura Beauty Bar" }
                    )
                    .tag(0)

                    // Promotion 2 - salon6 (Silk & Shine)
                    PromoBannerCard(
                        imageName: "salon6",
                        title: "Hair Transformation",
                        subtitle: "Professional styling & coloring service",
                        discount: "25",
                        salonName: "Silk & Shine",
                        onBooking: { selectedSalonName = "Silk & Shine" }
                    )
                    .tag(1)
                }
                .frame(height: 180)
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Dot indicators centered
                HStack(spacing: 8) {
                    Spacer()
                    ForEach(0..<2, id: \.self) { index in
                        Circle()
                            .fill(currentPromotionPage == index ? Color(hex: "962043") : Color(hex: "962043").opacity(0.25))
                            .frame(width: currentPromotionPage == index ? 10 : 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPromotionPage)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
        }
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Services")
                    .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                    .foregroundColor(primaryText)
                Spacer()
                if selectedServiceID != nil {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedServiceID = nil }
                    }) {
                        Text("Clear")
                            .glowzaFont(size: 13, weight: .medium)
                            .foregroundColor(brand)
                    }
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(services) { service in
                        let isSelected = selectedServiceID == service.id
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedServiceID = isSelected ? nil : service.id
                            }
                        }) {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(appSettings.isHighContrast ? .white : (isSelected ? brand.opacity(0.14) : surfaceBackground))
                                    .frame(width: 62, height: 62)
                                    .overlay {
                                        Circle()
                                            .stroke(appSettings.isHighContrast ? brand : (isSelected ? brand : brand.opacity(0.3)), lineWidth: 1.4)
                                        Image(systemName: service.icon)
                                            .glowzaFont(size: 20, weight: .medium)
                                            .foregroundColor(appSettings.isHighContrast ? .black : brand)
                                    }

                                Text(service.name.replacingOccurrences(of: "\n", with: " "))
                                    .glowzaFont(size: 11, weight: isSelected ? .semibold : .regular)
                                    .foregroundColor(appSettings.isHighContrast ? .white : (appSettings.isDarkMode ? Color.white.opacity(0.72) : Color(hex: "3E3E50")))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 74)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearby Salons")
                        .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                        .foregroundColor(primaryText)
                    if let svcID = selectedServiceID,
                       let svc = services.first(where: { $0.id == svcID }) {
                        Text("Filtered: \(svc.name.replacingOccurrences(of: "\n", with: " "))")
                            .glowzaFont(size: 12, weight: .medium)
                            .foregroundColor(brand)
                    }
                }
                Spacer()
                Button(action: { showMapSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "map.fill")
                            .glowzaFont(size: 12, weight: .medium)
                        Text("Map")
                            .glowzaFont(size: 13, weight: .semibold)
                    }
                    .foregroundColor(brand)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(brand.opacity(0.09))
                    .clipShape(Capsule())
                }
            }

            if isSalonsLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(brand)
                    Text("Loading salons...")
                        .glowzaFont(size: 14)
                        .foregroundColor(secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if filteredSalons.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .glowzaFont(size: 32)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.3) : Color(hex: "CACDD6"))
                    Text("No salons found")
                        .glowzaFont(size: 16, weight: .semibold)
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "8A8E95"))
                    Text("Try a different search or filter")
                        .glowzaFont(size: 14)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.5) : Color(hex: "AEAEB2"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredSalons) { salon in
                        Button(action: { selectedSalonName = salon.name }) {
                            SalonRowCard(salon: salon)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct SalonRowCard: View {
    let salon: SalonPreview
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(spacing: 14) {
            Image(salon.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 104)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(salon.name)
                        .glowzaFont(size: 15, weight: .semibold, design: .rounded)
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "1F2126"))
                        .lineLimit(1)
                    Spacer()
                    Text(salon.distance)
                        .glowzaFont(size: 12, weight: .medium)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.65) : Color(hex: "8A8E95"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "F2F2F7"))
                        .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "962043").opacity(0.55))
                    Text(salon.location)
                        .glowzaFont(size: 13)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.6) : Color(hex: "8A8E95"))
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "E4B234"))
                    Text(String(format: "%.1f", salon.rating))
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(appSettings.isDarkMode ? .white : Color(hex: "2E3036"))
                    Text("(\(salon.reviews))")
                        .glowzaFont(size: 12)
                        .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.45) : Color(hex: "AEAEB2"))
                }

                HStack(spacing: 5) {
                    ForEach(salon.categories.prefix(3), id: \.self) { cat in
                        Text(cat)
                            .glowzaFont(size: 10, weight: .semibold)
                            .foregroundColor(Color(hex: "962043"))
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color(hex: "962043").opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .glowzaFont(size: 12, weight: .semibold)
                .foregroundColor(appSettings.isDarkMode ? Color.white.opacity(0.3) : Color(hex: "CACDD6"))
        }
        .padding(14)
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

private struct PromoBannerCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let discount: String
    let salonName: String
    let onBooking: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.5),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .glowzaFont(size: 18, weight: .bold, design: .rounded)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .glowzaFont(size: 13, weight: .medium)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                }
                .padding(16)

                Spacer()

                Button(action: {
                    onBooking?()
                }) {
                    Text("Book Now")
                        .glowzaFont(size: 13, weight: .semibold)
                        .foregroundColor(Color(hex: "962043"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.97))
                        .clipShape(Capsule())
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Attractive circular discount badge - top right corner
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "962043"), Color(hex: "C83860")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                VStack(alignment: .center, spacing: -4) {
                    Text(discount)
                        .glowzaFont(size: 24, weight: .bold)
                        .foregroundColor(.white)
                    HStack(spacing: 0) {
                        Text("%")
                            .glowzaFont(size: 12, weight: .semibold)
                            .foregroundColor(.white)
                        Text("OFF")
                            .glowzaFont(size: 10, weight: .bold)
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
            }
            .frame(width: 76, height: 76)
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 2, y: 6)
            .offset(x: -12, y: -12)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(Color(hex: "962043").opacity(0.2), lineWidth: 1.5)
        )
        .padding(.horizontal, 20)
    }
}



// MARK: - Legacy stubs (kept for compatibility)
struct ReputationRing: View {
    let score: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: "F0F0F0"), lineWidth: 4)
            Circle().trim(from: 0, to: score)
                .stroke(Color(hex: "962043"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score * 100))%")
                .glowzaFont(size: 9, weight: .bold)
                .foregroundColor(Color(hex: "962043"))
        }
        .frame(width: 38, height: 38)
    }
}

struct SalonMapView: View {
    let salons: [SalonPreview]
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition

    private var colomboSalons: [SalonPreview] {
        let scoped = salons.filter { $0.location.localizedCaseInsensitiveContains("Colombo") }
        return scoped.isEmpty ? salons : scoped
    }

    init(salons: [SalonPreview]) {
        self.salons = salons
        let colomboCenter = CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612)
        let region = MKCoordinateRegion(
            center: colomboCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.24, longitudeDelta: 0.22)
        )
        _cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    ForEach(salons) { salon in
                        Annotation(salon.name, coordinate: salon.coordinate) {
                            VStack(spacing: 4) {
                                Image(salon.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                
                                Text(salon.name)
                                    .glowzaFont(size: 11, weight: .semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.75))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)

                if colomboSalons.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.slash")
                            .glowzaFont(size: 24, weight: .semibold)
                            .foregroundColor(.white)
                        Text("No salons to show on map")
                            .glowzaFont(size: 14, weight: .semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .onAppear { fitCameraToSalons() }
                .navigationTitle("Salons Near You")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { dismiss() }) {
                            Text("Close")
                                .glowzaFont(size: 16, weight: .semibold)
                                .fixedSize()
                                .foregroundColor(brand)
                        }
                    }
                }
        }
    }

    private func fitCameraToSalons() {
        guard !colomboSalons.isEmpty else { return }

        let latitudes = colomboSalons.map { $0.coordinate.latitude }
        let longitudes = colomboSalons.map { $0.coordinate.longitude }

        guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
              let minLon = longitudes.min(), let maxLon = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max(0.08, (maxLat - minLat) * 1.7)
        let lonDelta = max(0.08, (maxLon - minLon) * 1.7)

        cameraPosition = .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        )
    }
}

struct ServiceCategoryCard: View {
    let service: ServiceCategory
    var isSelected: Bool = false
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? brand : brand.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: service.icon)
                    .glowzaFont(size: 18)
                    .foregroundColor(isSelected ? .white : brand)
            }
            Text(service.name).glowzaFont(size: 11).foregroundColor(Color(hex: "1A1A1A"))
        }
    }
}

#Preview { HomeView() }
