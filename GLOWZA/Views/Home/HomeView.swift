// This file handles the main "Home" screen where users can search for salons, view categories, and see featured salons.
import SwiftUI
import MapKit // Needed for map annotations.

private let brand = Color(hex: "962043")

// MARK: - Models
// These structs define the data structures used in this view.
// Great for students to see how data is organized!

struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String // e.g., "Facial Care"
    let icon: String // SF Symbol name.
    let category: String // e.g., "Skin", "Hair"
}

struct SalonPreview: Identifiable {
    let id = UUID()
    let name: String
    let location: String
    let distance: String
    let rating: Double
    let reviews: Int
    let score: Double // Reputation score (0.0 to 1.0).
    let coordinate: CLLocationCoordinate2D // For map placement.
    let imageName: String
    let categories: [String] // Categories this salon offers.
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

    // @State variables for search and filtering.
    @State private var searchText = ""
    @State private var selectedServiceID: UUID? = nil
    @State private var selectedSalonName: String? = nil
    @State private var showMapSheet = false
    @State private var showNotificationsView = false
    @State private var showFavourites = false
    @State private var currentPromotionPage: Int = 0
    @State private var notificationManager = NotificationManager.shared
    
    // Loading profile data from UserDefaults (local storage).
    @State private var profileAvatarData: Data? = UserDefaults.standard.data(forKey: "profile_avatarData")
    @State private var profileName: String = UserDefaults.standard.string(forKey: "profile_fullName") ?? "User"
    @State private var hasShownSessionReminder = false // NEW: Only show reminder once per app session!
    @State private var isSalonsLoading = false

    // Mock data for service categories.
    // In a real app, these might come from a database, but hardcoding them here 
    // is a great way to build and test the UI first!
    private let services: [ServiceCategory] = [
        .init(name: "Facial Care", icon: "face.smiling", category: "Skin"),
        .init(name: "Skin Therapy", icon: "leaf", category: "Skin"),
        .init(name: "Chemical Peel", icon: "flask", category: "Skin"),
        .init(name: "HydraFacial", icon: "drop", category: "Skin"),
        .init(name: "Microneedling", icon: "syringe", category: "Skin"),
        .init(name: "Hair Cut", icon: "scissors", category: "Hair"),
        .init(name: "Hair Color", icon: "paintbrush.pointed", category: "Hair"),
        .init(name: "Hair Styling", icon: "comb", category: "Comb"),
        .init(name: "Laser Hair", icon: "bolt", category: "Hair"),
        .init(name: "Hair Treatment", icon: "leaf.fill", category: "Hair"),
        .init(name: "PRP for Hair", icon: "heart.text.square", category: "Hair"),
        .init(name: "Manicure", icon: "hand.raised", category: "Nails"),
        .init(name: "Pedicure", icon: "heart", category: "Nails"),
        .init(name: "Nail Art", icon: "wand.and.stars", category: "Nails"),
        .init(name: "Gel Manicure", icon: "hand.point.up.fill", category: "Nails")
    ]

    // Mock data for salons.
    // This allows us to show a list and map pins without needing internet!
    @State private var allSalons: [SalonPreview] = [
      .init(name: "Golden Avenue", location: "Moratuwa, Colombo", distance: "2.0 km", rating: 4.7, reviews: 312, score: 0.95,
          coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820), imageName: "Salon1", categories: ["Facial Care", "Chemical Peel", "HydraFacial"]),
      .init(name: "Glow Studio", location: "Kotte, Colombo", distance: "3.5 km", rating: 4.6, reviews: 198, score: 0.88,
          coordinate: CLLocationCoordinate2D(latitude: 6.8900, longitude: 79.9100), imageName: "salon2", categories: ["Hair Cut", "Hair Color", "Hair Styling"]),
      .init(name: "Luxe Aesthetics", location: "Dehiwala, Colombo", distance: "5.0 km", rating: 4.5, reviews: 245, score: 0.82,
          coordinate: CLLocationCoordinate2D(latitude: 6.8500, longitude: 79.8700), imageName: "salon3", categories: ["Manicure", "Pedicure", "Nail Art"]),
      .init(name: "Velvet Touch", location: "Nugegoda, Colombo", distance: "6.2 km", rating: 4.4, reviews: 131, score: 0.78,
          coordinate: CLLocationCoordinate2D(latitude: 6.8655, longitude: 79.8991), imageName: "salon4", categories: ["Facial Care", "Hair Cut", "Manicure"]),
      .init(name: "Aura Beauty Bar", location: "Mount Lavinia, Colombo", distance: "8.1 km", rating: 4.8, reviews: 420, score: 0.97,
          coordinate: CLLocationCoordinate2D(latitude: 6.8300, longitude: 79.8600), imageName: "salon5", categories: ["Skin Therapy", "Hair Styling", "Nail Art"]),
      .init(name: "Silk & Shine", location: "Battaramulla, Colombo", distance: "4.3 km", rating: 4.9, reviews: 287, score: 0.93,
          coordinate: CLLocationCoordinate2D(latitude: 6.8901, longitude: 79.8812), imageName: "salon6", categories: ["Chemical Peel", "Laser Hair", "Gel Manicure"]),
      .init(name: "Prime Beauty", location: "Wattala, Colombo", distance: "7.8 km", rating: 4.3, reviews: 165, score: 0.75,
          coordinate: CLLocationCoordinate2D(latitude: 6.9907, longitude: 79.8910), imageName: "salon7", categories: ["Microneedling", "PRP for Hair", "Manicure"]),
      .init(name: "Elegance Salon", location: "Malabe, Colombo", distance: "9.2 km", rating: 4.6, reviews: 276, score: 0.86,
          coordinate: CLLocationCoordinate2D(latitude: 6.9062, longitude: 79.9582), imageName: "salon8", categories: ["Facial Care", "Skin Therapy"]),
      .init(name: "Crystal Beauty", location: "Maharagama, Colombo", distance: "6.5 km", rating: 4.7, reviews: 354, score: 0.92,
          coordinate: CLLocationCoordinate2D(latitude: 6.8500, longitude: 79.9200), imageName: "salon9", categories: ["Hair Cut", "Hair Color"]),
      .init(name: "Radiant Aesthetic", location: "Rajagiriya, Colombo", distance: "3.2 km", rating: 4.8, reviews: 398, score: 0.96,
          coordinate: CLLocationCoordinate2D(latitude: 6.8800, longitude: 79.8900), imageName: "salon10", categories: ["Manicure", "Pedicure"]),
      .init(name: "Glow Palace", location: "Colombo 03", distance: "4.5 km", rating: 4.5, reviews: 140, score: 0.87,
          coordinate: CLLocationCoordinate2D(latitude: 6.8400, longitude: 79.9000), imageName: "salon11", categories: ["HydraFacial", "Laser Hair"]),
      .init(name: "Pure Skin Lab", location: "Colombo 07", distance: "5.5 km", rating: 4.6, reviews: 160, score: 0.89,
          coordinate: CLLocationCoordinate2D(latitude: 6.9070, longitude: 79.8959), imageName: "salon12", categories: ["Microneedling", "Hair Treatment"]),
      .init(name: "The Hair Lounge", location: "Colombo 04", distance: "2.0 km", rating: 4.4, reviews: 110, score: 0.84,
          coordinate: CLLocationCoordinate2D(latitude: 6.8747, longitude: 79.8602), imageName: "salon13", categories: ["Chemical Peel", "Gel Manicure"]),
      .init(name: "Serene Spa", location: "Colombo 05", distance: "8.0 km", rating: 4.3, reviews: 70, score: 0.78,
          coordinate: CLLocationCoordinate2D(latitude: 6.8792, longitude: 79.8768), imageName: "salon14", categories: ["Facial Care", "Hair Styling", "Nail Art"]),
      .init(name: "Urban Nails", location: "Colombo 06", distance: "3.5 km", rating: 4.7, reviews: 220, score: 0.91,
          coordinate: CLLocationCoordinate2D(latitude: 6.8760, longitude: 79.8583), imageName: "salon15", categories: ["Skin Therapy", "Hair Cut"]),
      .init(name: "Divine Beauty", location: "Colombo 08", distance: "4.2 km", rating: 4.5, reviews: 130, score: 0.86,
          coordinate: CLLocationCoordinate2D(latitude: 6.9123, longitude: 79.8673), imageName: "salon16", categories: ["HydraFacial", "Hair Color"]),
      .init(name: "Bloom Studio", location: "Colombo 01", distance: "2.8 km", rating: 4.6, reviews: 170, score: 0.89,
          coordinate: CLLocationCoordinate2D(latitude: 6.9142, longitude: 79.8774), imageName: "salon17", categories: ["Microneedling", "Gel Manicure"]),
      .init(name: "Infinity Glow", location: "Colombo 10", distance: "6.5 km", rating: 4.3, reviews: 95, score: 0.81,
          coordinate: CLLocationCoordinate2D(latitude: 6.9272, longitude: 79.8503), imageName: "salon18", categories: ["Chemical Peel", "Hair Treatment"]),
      .init(name: "Skin Deep", location: "Colombo 02", distance: "1.8 km", rating: 4.8, reviews: 240, score: 0.93,
          coordinate: CLLocationCoordinate2D(latitude: 6.9350, longitude: 79.8447), imageName: "salon19", categories: ["Skin Therapy", "Nail Art"]),
      .init(name: "The Beauty Room", location: "Colombo 09", distance: "3.2 km", rating: 4.4, reviews: 115, score: 0.83,
          coordinate: CLLocationCoordinate2D(latitude: 6.8959, longitude: 79.8743), imageName: "salon20", categories: ["Facial Care", "Gel Manicure"])
    ]

    // Computed property to filter salons based on search text and selected service.
    // This is a powerful SwiftUI concept: whenever searchText or selectedServiceID changes,
    // this property recalculates and updates the UI automatically!
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
    // These use the shared appSettings to support Dark Mode!
    private var pageBackground:    Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var primaryText:       Color { appSettings.themeText }
    private var secondaryText:     Color { appSettings.themeTextSecondary }
    private var borderColor:       Color { appSettings.themeBorder }

    var body: some View {
        NavigationStack {
            ZStack {
                pageBackground.ignoresSafeArea()
                
                // Main scrollable content.
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
            .navigationBarHidden(true) // We use our own custom topBar!
            
            // Navigation destinations for various screens.
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
            .fullScreenCover(isPresented: $showFavourites) {
                FavouriteSalonsView().environment(appSettings)
            }
            // .task runs when the view appears.
            .task {
                refreshProfileHeader() // Updates user name and avatar immediately!

                // Run heavy data tasks in the background to avoid blocking the UI!
                Task(priority: .background) {
                    await syncSalonsToFirestore() // Syncs local mock data to online Firebase.
                    await loadSalonsFromFirestore() // Loads data from Firebase.
                    await SalonFirestoreService.shared.seedMockReviews() // Seeds mock reviews.
                    await BookingStore.shared.fetchUserBookings() // Fetch fresh bookings.
                }
                
                // NEW: Show 'Login Successful' and then the 'Booking Reminder'!
                if !hasShownSessionReminder {
                    hasShownSessionReminder = true
                    
                    // 1. Welcome Notification
                    NotificationManager.shared.notifyWelcome(userName: profileName)

                    // 2. Booking Reminder after data is loaded!
                    Task {
                        // Wait for the background fetch to potentially complete first!
                        try? await Task.sleep(nanoseconds: 2_500_000_000) 
                        await BookingStore.shared.fetchUserBookings() // Ensure we have latest for the reminder!
                        
                        await MainActor.run {
                            BookingStore.shared.triggerNearestBookingReminder()
                        }
                    }
                }
            }
            .onAppear {
                generateVoiceOverSummary()
                appSettings.speak(appSettings.currentScreenSummary)
            }
            // Listens for notifications when profile is updated.
            .onReceive(NotificationCenter.default.publisher(for: .glowzaProfileUpdated)) { _ in
                refreshProfileHeader()
            }
            .onReceive(NotificationCenter.default.publisher(for: .glowzaQuickBookRequested)) { notification in
                guard let salonName = notification.object as? String else { return }
                selectedSalonName = salonName
            }
        }
    }

    // Reloads user profile data from local storage.
    private func refreshProfileHeader() {
        profileAvatarData = UserDefaults.standard.data(forKey: "profile_avatarData")
        profileName = UserDefaults.standard.string(forKey: "profile_fullName") ?? "User"
        generateVoiceOverSummary()
    }

    private func generateVoiceOverSummary() {
        let salonCount = allSalons.count
        let serviceCount = services.count
        let topSalon = allSalons.first?.name ?? "Golden Avenue"
        
        let summary = "Welcome back, \(profileName). You are on the Home screen. We have \(serviceCount) beauty service categories for you to explore. There are currently \(salonCount) top-rated salons available nearby. Our featured salon today is \(topSalon). Use the search bar at the top to find something specific."
        
        appSettings.currentScreenSummary = summary
    }

    // This method pushes our hardcoded salons to Firebase Firestore.
    // Useful for seeding a database with test data!
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

    // Loads salons from Firestore. For this demo, we use a hardcoded list of 20 salons
    // to guarantee that every service category has at least one matching salon!
    @MainActor
    private func loadSalonsFromFirestore() async {
        isSalonsLoading = true
        defer { isSalonsLoading = false } // Runs at the end of the method!
        
        let allCategories = [
            "Facial Care", "Skin Therapy", "Chemical Peel", "HydraFacial", "Microdermabrasion",
            "Microneedling", "Hair Cut", "Hair Color", "Hair Styling", "Laser Hair",
            "Hair Treatment", "PRP for Hair", "Manicure", "Pedicure", "Nail Art", "Gel Manicure"
        ]
        
        // Helper function to pick random categories for each salon.
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
    // Displays user avatar, greeting, and action buttons.
    private var topBar: some View {
        HStack(spacing: 12) {
            // User Avatar (Loads from local storage if available).
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
                // Shows only the first name!
                Text(profileName.components(separatedBy: " ").first ?? profileName)
                    .glowzaFont(.body, weight: .bold)
                    .foregroundColor(primaryText)
            }

            Spacer()

            // Favourites Button
            ZStack(alignment: .topTrailing) {
                Button(action: { showFavourites = true }) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                        .overlay {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(brand)
                        }
                }
                .buttonStyle(.plain)
            }
            
            // Notifications Button
            ZStack(alignment: .topTrailing) {
                Button(action: { showNotificationsView = true }) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 3)
                        .overlay {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(brand)
                        }
                }
                .buttonStyle(.plain)
                
                let count = notificationManager.unreadCount
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .frame(minWidth: 16, minHeight: 16)
                        .background(brand)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .offset(x: 2, y: -2)
                }
            }
        }
    }

    // Custom search bar.
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
        .hcBorderCapsule() // Accessibility border for high contrast mode!
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }

    // A beautiful banner showing a fake offer.
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

    // Promotions section with a swipeable carousel.
    private var promotionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Special Promotions")
                .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                .foregroundColor(primaryText)
                .padding(.horizontal, 20)

            VStack(spacing: 14) {
                // Another TabView used as a carousel!
                TabView(selection: $currentPromotionPage) {
                    // Promotion 1 - salon5 (Aura Beauty Bar)
                    PromoBannerCard(
                        imageName: "salon5",
                        title: "Luxury Skin Care",
                        subtitle: "Get 30% off on all premium facial treatments",
                        discount: "30",
                        salonName: "Aura Beauty Bar",
                        onBooking: { 
                            withAnimation { selectedSalonName = "Aura Beauty Bar" }
                        }
                    )
                    .tag(0)

                    // Promotion 2 - salon6 (Silk & Shine)
                    PromoBannerCard(
                        imageName: "salon6",
                        title: "Hair Transformation",
                        subtitle: "Master styling & professional coloring service",
                        discount: "25",
                        salonName: "Silk & Shine",
                        onBooking: { 
                            withAnimation { selectedSalonName = "Silk & Shine" }
                        }
                    )
                    .tag(1)
                    
                    // Promotion 3 - Salon1 (Golden Avenue)
                    PromoBannerCard(
                        imageName: "Salon1",
                        title: "Golden Glow Special",
                        subtitle: "Exclusive aesthetic treatments for a radiant look",
                        discount: "40",
                        salonName: "Golden Avenue",
                        onBooking: { 
                            withAnimation { selectedSalonName = "Golden Avenue" }
                        }
                    )
                    .tag(2)
                }
                .frame(height: 180)
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Custom Dot indicators for the promotion carousel.
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(currentPromotionPage == index ? Color(hex: "962043") : Color(hex: "962043").opacity(0.2))
                            .frame(width: currentPromotionPage == index ? 18 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPromotionPage)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 10)
        }
    }

    // Services section with a horizontal scroll of categories.
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Services")
                    .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                    .foregroundColor(primaryText)
                Spacer()
                // Show "Clear" button only if a service is selected!
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

            // Horizontal scroll of service circles.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(services) { service in
                        let isSelected = selectedServiceID == service.id
                        Button(action: {
                            // Toggles selection with a smooth animation!
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

    // Nearby salons section with filtering and list.
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Nearby Salons")
                        .glowzaFont(size: 18, weight: .semibold, design: .rounded)
                        .foregroundColor(primaryText)
                    
                    // Show active filter name if a service is selected!
                    if let svcID = selectedServiceID,
                       let svc = services.first(where: { $0.id == svcID }) {
                        Text("Filtered: \(svc.name.replacingOccurrences(of: "\n", with: " "))")
                            .glowzaFont(size: 12, weight: .medium)
                            .foregroundColor(brand)
                    }
                }
                Spacer()
                
                // Button to open the full-screen Map sheet.
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

            // Handling Loading State.
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
            } 
            // Handling Empty State (No salons found for search/filter).
            else if filteredSalons.isEmpty {
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
            } 
            // Showing the list of salons!
            else {
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

// MARK: - Components
// Small reusable views used in the HomeView.

// A card representing a single salon in the list.
private struct SalonRowCard: View {
    let salon: SalonPreview
    @Environment(AppSettings.self) private var appSettings

    var body: some View {
        HStack(spacing: 14) {
            // Salon Image.
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
                    
                    // Distance Badge.
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

                // Rating & Reviews.
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

                // Service Tags (Showing up to 3).
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

// A banner card used in the promotions carousel.
private struct PromoBannerCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    let discount: String
    let salonName: String
    let onBooking: (() -> Void)?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image.
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 350, height: 180)
                .clipped()
            
            // Sophisticated Cinematic Gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.85),
                    Color.black.opacity(0.4),
                    Color.clear,
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .top
            )

            // Content Layout
            VStack(alignment: .leading, spacing: 0) {
                // Top Tag + Discount row
                HStack(alignment: .top) {
                    // Salon Name Tag
                    Text(salonName.uppercased())
                        .glowzaFont(size: 9, weight: .bold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                    
                    Spacer()
                    
                    // Premium Discount Badge
                    VStack(spacing: -2) {
                        Text(discount)
                            .glowzaFont(size: 22, weight: .bold, design: .rounded)
                        Text("% OFF")
                            .glowzaFont(size: 8, weight: .heavy)
                    }
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "962043"), Color(hex: "D4829E")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                    )
                    .offset(y: -10)
                }
                .padding(.top, 14)
                .padding(.horizontal, 14)

                Spacer()

                // Main Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .glowzaFont(size: 22, weight: .bold, design: .rounded)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Text(subtitle)
                        .glowzaFont(size: 13, weight: .medium)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Refined Call to Action
                HStack {
                    HStack(spacing: 8) {
                        Text("Book Now")
                            .glowzaFont(size: 14, weight: .bold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(Color(hex: "962043"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 350, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .hcBorder(radius: 24)
        .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 20)
        .onTapGesture {
            onBooking?()
        }
    }
}



// MARK: - Legacy stubs (kept for compatibility)
// These are extra views that support the main screen.

// A circular progress ring showing a reputation score.
struct ReputationRing: View {
    let score: Double // Value between 0.0 and 1.0.
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: "F0F0F0"), lineWidth: 4)
            Circle().trim(from: 0, to: score) // Trims the circle based on score!
                .stroke(Color(hex: "962043"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90)) // Starts from the top!
            Text("\(Int(score * 100))%")
                .glowzaFont(size: 9, weight: .bold)
                .foregroundColor(Color(hex: "962043"))
        }
        .frame(width: 38, height: 38)
    }
}

// Full screen map sheet to see salons on a map.
struct SalonMapView: View {
    let salons: [SalonPreview]
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition

    // Filters for salons in Colombo to center the map there!
    private var colomboSalons: [SalonPreview] {
        let scoped = salons.filter { $0.location.localizedCaseInsensitiveContains("Colombo") }
        return scoped.isEmpty ? salons : scoped
    }

    // Custom initializer to set up the map center!
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
                // The new iOS 17 Map view!
                Map(position: $cameraPosition) {
                    ForEach(salons) { salon in
                        // Custom annotation for each salon.
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

                // Empty state if no salons to show.
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
            .onAppear { fitCameraToSalons() } // Auto-zooms to fit all salons!
                .navigationTitle("Salons Near You")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .glowzaFont(size: 14, weight: .bold)
                                .foregroundColor(brand)
                                .frame(width: 32, height: 32)
                                .background(brand.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
        }
    }

    // Math function to calculate the bounding box of all salons 
    // and zoom the map camera to fit them all perfectly!
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

// A simpler card for service categories (used in some legacy parts).
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
