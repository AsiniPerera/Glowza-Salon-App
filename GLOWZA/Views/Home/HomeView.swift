import SwiftUI
import MapKit

// MARK: - Models

struct ServiceCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let category: String   // matches SalonService.category
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

// MARK: - Salon Map Annotation

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

    // Search & filter state
    @State private var searchText        = ""
    @State private var selectedFilter    = "All"
    @State private var selectedServiceID: UUID? = nil   // tracks single tapped card by id
    @State private var showMapSheet      = false
    @State private var selectedSalonName: String? = nil
    @State private var specialForYouIndex = 0

    private let filters = ["All", "Nearest", "Top Rated", "Open Now", "Price ↓"]
    
    private var offers: [(title: String, subtitle: String, background: Color, icon: String)] = [
        (title: "Get Special Discount", subtitle: "Up to 30% off", background: .glowzaBrown, icon: "sparkles"),
        (title: "Pamper Yourself", subtitle: "Up to 40% off", background: .glowzaGoldDark, icon: "heart.fill"),
        (title: "Summer Collection", subtitle: "New arrivals", background: Color(hex: "9B6B5C"), icon: "star.fill")
    ]

    private let services: [ServiceCategory] = [
        .init(name: "Skin Care",     icon: "face.smiling",         category: "Skin"),
        .init(name: "Chemical Peel", icon: "wand.and.sparkles",   category: "Skin"),
        .init(name: "Laser Hair",    icon: "sun.max",              category: "Hair"),
        .init(name: "Hair Care",     icon: "leaf",                 category: "Hair"),
        .init(name: "Nails",         icon: "hand.raised.fill",     category: "Nails"),
        .init(name: "Fillers",       icon: "syringe",              category: "Aesthetic"),
        .init(name: "Botox",         icon: "cross.case.fill",      category: "Aesthetic"),
        .init(name: "Dark Circle",   icon: "eye.fill",             category: "Aesthetic"),
    ]

    private let allSalons: [SalonPreview] = [
        .init(name: "Haley Avenue",      location: "Moratuwa, Colombo",    distance: "2.0 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820), imageName: "Salon1"),
        .init(name: "Glow Studio",       location: "Moratuwa, Colombo",    distance: "3.5 km", rating: 4.6, reviews: 198, score: 0.88,
              coordinate: CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783), imageName: "salon2"),
        .init(name: "Luxe Aesthetics",   location: "Dehiwala, Colombo",    distance: "5.0 km", rating: 4.5, reviews: 245, score: 0.82,
              coordinate: CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684), imageName: "Salon1"),
        .init(name: "Velvet Touch",      location: "Nugegoda, Colombo",    distance: "6.2 km", rating: 4.4, reviews: 131, score: 0.78,
              coordinate: CLLocationCoordinate2D(latitude: 6.8696, longitude: 79.8999), imageName: "salon2"),
        .init(name: "Aura Beauty Bar",   location: "Colombo 03",           distance: "8.1 km", rating: 4.8, reviews: 420, score: 0.97,
              coordinate: CLLocationCoordinate2D(latitude: 6.8935, longitude: 79.8534), imageName: "Salon1"),
        .init(name: "Silk & Shine",      location: "Battaramulla, Colombo", distance: "4.3 km", rating: 4.9, reviews: 287, score: 0.93,
              coordinate: CLLocationCoordinate2D(latitude: 6.8901, longitude: 79.8812), imageName: "salon2"),
        .init(name: "Prime Beauty",      location: "Wattala, Colombo",     distance: "7.8 km", rating: 4.3, reviews: 165, score: 0.75,
              coordinate: CLLocationCoordinate2D(latitude: 6.8623, longitude: 79.8567), imageName: "Salon1"),
        .init(name: "Elegance Salon",    location: "Malabe, Colombo",      distance: "9.2 km", rating: 4.6, reviews: 276, score: 0.86,
              coordinate: CLLocationCoordinate2D(latitude: 6.8734, longitude: 79.9234), imageName: "salon2"),
        .init(name: "Crystal Beauty",    location: "Colombo 04",           distance: "6.5 km", rating: 4.7, reviews: 354, score: 0.92,
              coordinate: CLLocationCoordinate2D(latitude: 6.8845, longitude: 79.8645), imageName: "Salon1"),
        .init(name: "Radiant Aesthetic", location: "Galle Road, Colombo",   distance: "3.2 km", rating: 4.8, reviews: 398, score: 0.96,
              coordinate: CLLocationCoordinate2D(latitude: 6.8556, longitude: 79.8734), imageName: "salon2"),
    ]

    private var filteredSalons: [SalonPreview] {
        // 1. text search
        var result = searchText.isEmpty ? allSalons : allSalons.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
        // 2. service-category filter (from tapped service card)
        if let sid = selectedServiceID,
           let cat = services.first(where: { $0.id == sid })?.category {
            let names = Set(
                SalonCatalog.shared.salons
                    .filter { salon in salon.services.contains { $0.category == cat } }
                    .map { $0.name }
            )
            result = result.filter { names.contains($0.name) }
        }
        // 3. sort chip
        switch selectedFilter {
        case "Nearest":    return result.sorted { $0.distance < $1.distance }
        case "Top Rated":  return result.sorted { $0.rating > $1.rating }
        case "Price ↓":    return result.sorted { $0.score < $1.score }
        default:           return result
        }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.glowzaBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - Top Bar with Profile
                        topBarSection
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.lg)
                        
                        // MARK: - Search Bar
                        searchBarSection
                            .padding(.horizontal, Spacing.lg)
                            .padding(.bottom, Spacing.lg)
                        
                        // MARK: - Special For You (Carousel with dots)
                        specialForYouCarouselSection
                            .padding(.bottom, Spacing.xl)
                        
                        // MARK: - Services (Left Aligned)
                        servicesSection
                            .padding(.horizontal, Spacing.lg)
                            .padding(.bottom, Spacing.xl)
                        
                        // MARK: - Top Salons
                        topSalonsSection
                            .padding(.horizontal, Spacing.lg)
                            .padding(.bottom, Spacing.xxl)
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
    
    // MARK: - Top Bar with Profile Image
    private var topBarSection: some View {
        HStack(spacing: Spacing.base) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(Color.glowzaGold.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.glowzaBrown)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Welcome")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.glowzaSubtext)
                
                Text("Asini Perera")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.glowzaTextPrimary)
            }
            
            Spacer()
            
            Button { } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.glowzaTextPrimary)
                    Circle()
                        .fill(Color.glowzaError)
                        .frame(width: 8, height: 8)
                        .offset(x: 3, y: -3)
                }
            }
        }
    }
    
    
    // MARK: - Special For You (Swipeable Carousel)
    private var specialForYouCarouselSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Special For You")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.glowzaTextPrimary)
                .padding(.horizontal, Spacing.lg)
            
            // Carousel with TabView for paging
            TabView(selection: $specialForYouIndex) {
                ForEach(0..<offers.count, id: \.self) { index in
                    let offer = offers[index]
                    promoCard(
                        title: offer.title,
                        subtitle: offer.subtitle,
                        background: offer.background,
                        icon: offer.icon
                    )
                    .tag(index)
                }
            }
            .frame(height: 180)
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.horizontal, Spacing.lg)
            
            // Page indicators (dots)
            HStack(spacing: 6) {
                ForEach(0..<offers.count, id: \.self) { index in
                    Circle()
                        .fill(index == specialForYouIndex ? Color.glowzaBrown : Color.glowzaBrown.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: specialForYouIndex)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, Spacing.sm)
        }
    }
    
    // MARK: - Services Section
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Premium Services")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.glowzaTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(services) { service in
                        let isSelected = selectedServiceID == service.id
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedServiceID = isSelected ? nil : service.id
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(isSelected ? Color.glowzaGoldDark.opacity(0.15) : Color.white)
                                        .frame(width: 64, height: 64)
                                        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                                    Image(systemName: service.icon)
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color.glowzaGoldDark)
                                }
                                Text(service.name)
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                    .foregroundColor(isSelected ? Color.glowzaGoldDark : .glowzaTextPrimary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .frame(width: 64)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, 4)
            }
        }
    }
    
    // Location Header (deprecated - keeping for reference)
    private var locationHeaderSection: some View {
        HStack(spacing: Spacing.base) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Location")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.glowzaSubtext)
                
                HStack(spacing: Spacing.sm) {
                    Text("Lamphun, Thailand")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.glowzaTextPrimary)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.glowzaTextPrimary)
                }
            }
            
            Spacer()
            
            Button { } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.glowzaTextPrimary)
                    Circle()
                        .fill(Color.glowzaError)
                        .frame(width: 8, height: 8)
                        .offset(x: 3, y: -3)
                }
            }
        }
    }
    
    // Old Special For You Section (deprecated)
    private var specialForYouSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Special For You")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.glowzaTextPrimary)
                .padding(.horizontal, Spacing.lg)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    promoCard(
                        title: "Get Special Discount",
                        subtitle: "Up to 30% off",
                        background: .glowzaBrown,
                        icon: "sparkles"
                    )
                    
                    promoCard(
                        title: "Pamper Yourself",
                        subtitle: "Up to 40% off",
                        background: .glowzaGoldDark,
                        icon: "heart.fill"
                    )
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
    }
    
    // Old Services Grid Section (deprecated)
    private var servicesGridSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Services")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.glowzaTextPrimary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(services) { service in
                        NavigationLink(value: service) {
                            VStack(spacing: Spacing.sm) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .stroke(Color.glowzaGold.opacity(0.2), lineWidth: 1)
                                    
                                    Image(systemName: service.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.glowzaBrown)
                                }
                                .frame(height: 60)
                                
                                Text(service.name)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.glowzaTextPrimary)
                                    .lineLimit(1)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(minWidth: 80)
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
            }
        }
    }
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.glowzaSubtext)
                
                TextField("Search salons or city ...", text: $searchText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.glowzaTextPrimary)
            }
            .padding(Spacing.base)
            .background(Color.white)
            .cornerRadius(CornerRadius.lg)
            
            Button { } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.glowzaBrown)
                    .cornerRadius(CornerRadius.lg)
            }
        }
    }
    

    // MARK: - Promo Card Helper
    private func promoCard(title: String, subtitle: String, background: Color, icon: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(background.opacity(0.85))
            
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.sm) {
                    Text("Limited Time")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(CornerRadius.xs)
                    
                    Spacer()
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: Spacing.sm) {
                        Button("Book Now") {}
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.base)
                            .padding(.vertical, 6)
                            .background(Color(hex: "2C3E50"))
                            .cornerRadius(CornerRadius.sm)
                        
                        Spacer()
                    }
                }
            }
            .padding(Spacing.lg)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
    

    // MARK: - Nearby Salons Section
    private var topSalonsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Nearby Salons")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.glowzaTextPrimary)
                Spacer()
                Button(action: { showMapSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 13, weight: .medium))
                        Text("Map View")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(Color.glowzaGoldDark)
                }
            }

            VStack(spacing: 12) {
                ForEach(filteredSalons) { salon in
                    Button(action: { selectedSalonName = salon.name }) {
                        nearbySalonCard(salon)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Nearby Salon Card
    private func nearbySalonCard(_ salon: SalonPreview) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Left: real salon photo
            Image(salon.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            // Right: details
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(salon.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.glowzaTextPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text(salon.distance)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.glowzaSubtext)
                }

                Label(salon.location, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.glowzaSubtext)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.glowzaGoldDark)
                    Text(String(format: "%.1f", salon.rating))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.glowzaTextPrimary)
                    Text("(\(salon.reviews))")
                        .font(.system(size: 12))
                        .foregroundColor(.glowzaSubtext)
                    Spacer()
                    ReputationRing(score: salon.score)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Map Pin

private struct SalonMapPin: View {
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.glowzaGoldDark : Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    Image(systemName: "scissors")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.glowzaGoldDark)
                }
                Triangle()
                    .fill(isSelected ? Color.glowzaGoldDark : Color.white)
                    .frame(width: 12, height: 7)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
}

// MARK: - Salon Map Sheet

struct SalonMapView: View {
    let salons: [SalonPreview]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnnotation: SalonAnnotation? = nil
    @State private var cameraPosition: MapCameraPosition

    init(salons: [SalonPreview]) {
        self.salons = salons
        // Centre on midpoint of all salons
        let avgLat = salons.map(\.coordinate.latitude).reduce(0, +)  / max(1, Double(salons.count))
        let avgLon = salons.map(\.coordinate.longitude).reduce(0, +) / max(1, Double(salons.count))
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
                span:   MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
            )
        ))
    }

    private var annotations: [SalonAnnotation] {
        salons.map { SalonAnnotation(id: $0.id, name: $0.name, coordinate: $0.coordinate, rating: $0.rating) }
    }

    private func pinIsSelected(_ ann: SalonAnnotation) -> Bool {
        selectedAnnotation?.id == ann.id
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Map(position: $cameraPosition, selection: $selectedAnnotation) {
                    ForEach(annotations) { ann in
                        Annotation(ann.name, coordinate: ann.coordinate, anchor: .bottom) {
                            SalonMapPin(isSelected: pinIsSelected(ann)) {
                                withAnimation { selectedAnnotation = ann }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .ignoresSafeArea(edges: .bottom)

                // Selected salon card at bottom
                if let ann = selectedAnnotation,
                   let salon = salons.first(where: { $0.id == ann.id }) {
                    MapSalonCard(salon: salon)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("Salons Near You")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.glowzaGoldDark)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(salons.count) salons")
                        .font(Typography.caption)
                        .foregroundColor(.glowzaSubtext)
                }
            }
        }
    }
}

// MARK: - Triangle shape (pin tail)

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}

// MARK: - Map bottom salon card

struct MapSalonCard: View {
    let salon: SalonPreview

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.glowzaCardBg)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.glowzaGoldDark.opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.glowzaTextPrimary)

                Label(salon.location, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.glowzaSubtext)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.glowzaGold)
                    Text("\(String(format: "%.1f", salon.rating))  ·  \(salon.distance)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.glowzaBrown)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.glowzaGoldDark)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

// MARK: - Service Category Card

struct ServiceCategoryCard: View {
    let service: ServiceCategory
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.glowzaGoldDark : Color.glowzaGold.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: service.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color.glowzaGoldDark)
            }

            Text(service.name)
                .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color.glowzaGoldDark : Color.glowzaBrown)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(isSelected ? Color.glowzaCardBg : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color.glowzaGoldDark.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isSelected ? Color.glowzaGoldDark.opacity(0.18) : Color.black.opacity(0.04),
                radius: isSelected ? 8 : 6, x: 0, y: 2)
    }
}

// MARK: - Salon Preview Card

struct SalonPreviewCard: View {
    let salon: SalonPreview

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.glowzaCardBg)
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color.glowzaGoldDark.opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.glowzaTextPrimary)

                Label(salon.location, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(.glowzaSubtext)

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.glowzaGold)
                    Text("\(salon.rating, specifier: "%.1f") (\(salon.reviews) reviews)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.glowzaBrown)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(salon.distance)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.glowzaGoldDark)
                    .clipShape(Capsule())

                ReputationRing(score: salon.score)
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Reputation Ring

struct ReputationRing: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.glowzaGold.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: score)
                .stroke(Color.glowzaGoldDark,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)
            Text("\(Int(score * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.glowzaGoldDark)
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    HomeView()
}
