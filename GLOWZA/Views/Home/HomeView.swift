import SwiftUI
import MapKit

private let brand = Color(hex: "AF1C47")

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

    @State private var searchText        = ""
    @State private var selectedFilter    = "All"
    @State private var selectedServiceID: UUID? = nil
    @State private var showMapSheet      = false
    @State private var selectedSalonName: String? = nil
    @State private var promoIndex        = 0

    private let filters = ["All", "Nearest", "Top Rated", "Open Now"]

    private let promos: [(title: String, sub: String, icon: String)] = [
        ("Get 20% Off Your First Visit",   "Book any treatment today",    "sparkles"),
        ("Summer Glow Package",            "Up to 40% off skin care",     "sun.max.fill"),
        ("Refer a Friend & Save",          "Earn LKR 500 credit",         "person.2.fill"),
    ]

    private let services: [ServiceCategory] = [
        .init(name: "Skin Care",     icon: "face.smiling",       category: "Skin"),
        .init(name: "Chemical Peel", icon: "wand.and.sparkles",  category: "Skin"),
        .init(name: "Laser Hair",    icon: "sun.max",            category: "Hair"),
        .init(name: "Hair Care",     icon: "leaf",               category: "Hair"),
        .init(name: "Nails",         icon: "hand.raised.fill",   category: "Nails"),
        .init(name: "Fillers",       icon: "syringe",            category: "Aesthetic"),
        .init(name: "Botox",         icon: "cross.case.fill",    category: "Aesthetic"),
        .init(name: "Dark Circle",   icon: "eye.fill",           category: "Aesthetic"),
    ]

    private let allSalons: [SalonPreview] = [
        .init(name: "Haley Avenue",      location: "Moratuwa, Colombo",     distance: "2.0 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820), imageName: "Salon1"),
        .init(name: "Glow Studio",       location: "Moratuwa, Colombo",     distance: "3.5 km", rating: 4.6, reviews: 198, score: 0.88,
              coordinate: CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783), imageName: "salon2"),
        .init(name: "Luxe Aesthetics",   location: "Dehiwala, Colombo",     distance: "5.0 km", rating: 4.5, reviews: 245, score: 0.82,
              coordinate: CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684), imageName: "Salon1"),
        .init(name: "Velvet Touch",      location: "Nugegoda, Colombo",     distance: "6.2 km", rating: 4.4, reviews: 131, score: 0.78,
              coordinate: CLLocationCoordinate2D(latitude: 6.8696, longitude: 79.8999), imageName: "salon2"),
        .init(name: "Aura Beauty Bar",   location: "Colombo 03",            distance: "8.1 km", rating: 4.8, reviews: 420, score: 0.97,
              coordinate: CLLocationCoordinate2D(latitude: 6.8935, longitude: 79.8534), imageName: "Salon1"),
        .init(name: "Silk & Shine",      location: "Battaramulla, Colombo", distance: "4.3 km", rating: 4.9, reviews: 287, score: 0.93,
              coordinate: CLLocationCoordinate2D(latitude: 6.8901, longitude: 79.8812), imageName: "salon2"),
        .init(name: "Prime Beauty",      location: "Wattala, Colombo",      distance: "7.8 km", rating: 4.3, reviews: 165, score: 0.75,
              coordinate: CLLocationCoordinate2D(latitude: 6.8623, longitude: 79.8567), imageName: "Salon1"),
        .init(name: "Elegance Salon",    location: "Malabe, Colombo",       distance: "9.2 km", rating: 4.6, reviews: 276, score: 0.86,
              coordinate: CLLocationCoordinate2D(latitude: 6.8734, longitude: 79.9234), imageName: "salon2"),
        .init(name: "Crystal Beauty",    location: "Colombo 04",            distance: "6.5 km", rating: 4.7, reviews: 354, score: 0.92,
              coordinate: CLLocationCoordinate2D(latitude: 6.8845, longitude: 79.8645), imageName: "Salon1"),
        .init(name: "Radiant Aesthetic", location: "Galle Road, Colombo",   distance: "3.2 km", rating: 4.8, reviews: 398, score: 0.96,
              coordinate: CLLocationCoordinate2D(latitude: 6.8556, longitude: 79.8734), imageName: "salon2"),
    ]

    private var filteredSalons: [SalonPreview] {
        var result = searchText.isEmpty ? allSalons : allSalons.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
        if let sid = selectedServiceID,
           let cat = services.first(where: { $0.id == sid })?.category {
            let names = Set(
                SalonCatalog.shared.salons
                    .filter { $0.services.contains { $0.category == cat } }
                    .map { $0.name }
            )
            result = result.filter { names.contains($0.name) }
        }
        switch selectedFilter {
        case "Nearest":   return result.sorted { $0.distance < $1.distance }
        case "Top Rated": return result.sorted { $0.rating > $1.rating }
        default:          return result
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar.padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 16)
                        searchRow.padding(.horizontal, 20).padding(.bottom, 20)
                        promoCarousel.padding(.bottom, 28)
                        servicesSection.padding(.horizontal, 20).padding(.bottom, 28)
                        featuredSection.padding(.bottom, 32)
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
            .sheet(isPresented: $showMapSheet) {
                SalonMapView(salons: filteredSalons)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(brand.opacity(0.10)).frame(width: 44, height: 44)
                Image(systemName: "person.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(brand)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello 👋").font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                Text("Asini Perera").font(.system(size: 17, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
            }
            Spacer()
            Button(action: {}) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Circle().fill(brand).frame(width: 8, height: 8).offset(x: 2, y: -2)
                }
            }
        }
    }

    // MARK: - Search Row
    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "ABABAB"))
                TextField("Search salons, services…", text: $searchText)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(Color(hex: "F5F5F5"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Button(action: { showMapSheet = true }) {
                Image(systemName: "map")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(brand)
                    .frame(width: 46, height: 46)
                    .background(brand.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Promo Carousel
    private var promoCarousel: some View {
        VStack(spacing: 10) {
            TabView(selection: $promoIndex) {
                ForEach(promos.indices, id: \.self) { i in
                    PromoCard(title: promos[i].title, subtitle: promos[i].sub, icon: promos[i].icon)
                        .padding(.horizontal, 20)
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 162)

            HStack(spacing: 6) {
                ForEach(promos.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == promoIndex ? brand : Color(hex: "DCDCDC"))
                        .frame(width: i == promoIndex ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.35), value: promoIndex)
                }
            }
        }
    }

    // MARK: - Services
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Services").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
                Spacer()
                Text("See All").font(.system(size: 13, weight: .semibold)).foregroundColor(brand)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(services) { svc in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedServiceID = selectedServiceID == svc.id ? nil : svc.id
                            }
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(selectedServiceID == svc.id ? brand : brand.opacity(0.08))
                                        .frame(width: 54, height: 54)
                                    Image(systemName: svc.icon)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(selectedServiceID == svc.id ? .white : brand)
                                }
                                Text(svc.name)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                    .lineLimit(1)
                                    .frame(width: 64)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Featured Salons
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(filteredSalons.count == allSalons.count ? "Top Salons" : "Matching Salons")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Spacer()

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.self) { f in
                            Button(action: { selectedFilter = f }) {
                                Text(f)
                                    .font(.system(size: 12, weight: selectedFilter == f ? .semibold : .regular))
                                    .foregroundColor(selectedFilter == f ? .white : Color(hex: "6B6B6B"))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedFilter == f ? brand : Color(hex: "F5F5F5"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)

            if filteredSalons.isEmpty {
                Text("No salons match your search.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(filteredSalons) { salon in
                            Button(action: { selectedSalonName = salon.name }) {
                                SalonCard(salon: salon)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Promo Card
private struct PromoCard: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(hex: "AF1C47"))

            // Background accent circle
            Circle()
                .fill(Color.white.opacity(0.07))
                .frame(width: 140, height: 140)
                .offset(x: 220, y: -40)

            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 100, height: 100)
                .offset(x: 260, y: 20)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Limited Time", systemImage: "clock.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))

                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.80))

                    Text("Book Now →")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white.opacity(0.30))
            }
            .padding(.horizontal, 22)
        }
        .frame(height: 152)
    }
}

// MARK: - Salon Card
private struct SalonCard: View {
    let salon: SalonPreview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image area
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "F5F5F5"))
                    .frame(height: 130)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "DCDCDC"))
                    )

                // PRO badge
                Text("PRO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "AF1C47"))
                    .clipShape(Capsule())
                    .padding(10)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .lineLimit(1)

                Text(salon.location)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(String(format: "%.1f", salon.rating))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("(\(salon.reviews))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Spacer()
                    Text(salon.distance)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "AF1C47"))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
        .frame(width: 185)
    }
}

// MARK: - Legacy stubs (kept for compatibility)
struct ReputationRing: View {
    let score: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color(hex: "F0F0F0"), lineWidth: 4)
            Circle().trim(from: 0, to: score)
                .stroke(Color(hex: "AF1C47"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(score * 100))%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "AF1C47"))
        }
        .frame(width: 38, height: 38)
    }
}

struct SalonMapView: View {
    let salons: [SalonPreview]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Map()
                .navigationTitle("Salons Near You")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .foregroundColor(Color(hex: "AF1C47"))
                    }
                }
        }
    }
}

struct ServiceCategoryCard: View {
    let service: ServiceCategory
    var isSelected: Bool = false
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color(hex: "AF1C47") : Color(hex: "AF1C47").opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: service.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : Color(hex: "AF1C47"))
            }
            Text(service.name).font(.system(size: 11)).foregroundColor(Color(hex: "1A1A1A"))
        }
    }
}

#Preview { HomeView() }
