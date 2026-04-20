import SwiftUI
import MapKit

// MARK: - Models

struct ServiceCategory: Identifiable {
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

    private let filters = ["All", "Nearest", "Top Rated", "Open Now", "Price ↓"]

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
        .init(name: "Haley Avenue",    location: "Moratuwa, Colombo",  distance: "2.0 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)),
        .init(name: "Glow Studio",     location: "Moratuwa, Colombo",  distance: "3.5 km", rating: 4.6, reviews: 198, score: 0.88,
              coordinate: CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783)),
        .init(name: "Luxe Aesthetics", location: "Dehiwala, Colombo",  distance: "5.0 km", rating: 4.5, reviews: 245, score: 0.82,
              coordinate: CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684)),
        .init(name: "Velvet Touch",    location: "Nugegoda, Colombo",  distance: "6.2 km", rating: 4.4, reviews: 131, score: 0.78,
              coordinate: CLLocationCoordinate2D(latitude: 6.8696, longitude: 79.8999)),
        .init(name: "Aura Beauty Bar", location: "Colombo 03",         distance: "8.1 km", rating: 4.8, reviews: 420, score: 0.97,
              coordinate: CLLocationCoordinate2D(latitude: 6.8935, longitude: 79.8534)),
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
                Color(hex: "F5F0E8").ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        searchFilterSection
                        promoBanner
                        servicesSection
                        nearbySalonsSection
                        Spacer().frame(height: 20)
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

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E5A820").opacity(0.18))
                    .frame(width: 46, height: 46)
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "C8860A"))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Good morning 👋")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
                Text("Asini")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 21))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 1, y: -1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Search + Filter

    private var searchFilterSection: some View {
        VStack(spacing: 12) {

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "ABABAB"))

                TextField("Search salons, city or service…", text: $searchText)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .submitLabel(.search)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "ABABAB"))
                    }
                }

                // Map button inside search bar
                Button(action: { showMapSheet = true }) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "C8860A"))
                        .padding(8)
                        .background(Color(hex: "E5A820").opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
            .padding(.horizontal, 20)

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(filters, id: \.self) { filter in
                        Button(action: { withAnimation(.spring(response: 0.3)) { selectedFilter = filter } }) {
                            Text(filter)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(selectedFilter == filter ? .white : Color(hex: "4A3828"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    selectedFilter == filter
                                    ? LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [Color.white, Color.white],
                                                     startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFilter == filter
                                                ? Color.clear
                                                : Color(hex: "E5A820").opacity(0.35), lineWidth: 1)
                                )
                                .shadow(color: selectedFilter == filter
                                        ? Color(hex: "E5A820").opacity(0.3) : Color.clear,
                                        radius: 6, x: 0, y: 3)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Promo Banner

    private var promoBanner: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "3D2E18"), Color(hex: "7A5A2E")],
                        startPoint: .bottomLeading, endPoint: .topTrailing
                    )
                )
                .frame(height: 152)

            HStack {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 100))
                    .foregroundColor(Color(hex: "E5A820").opacity(0.10))
                    .rotationEffect(.degrees(15))
                    .padding(.trailing, 16)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Morning Special 🌅")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "E5A820"))

                Text("Get 20% Off")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("All facial treatments · 9 AM – 11 AM")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.bottom, 8)

                Button(action: {}) {
                    Text("Book Now →")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "3D2E18"))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 22)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Services

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Services")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    if let sid = selectedServiceID,
                       let svc = services.first(where: { $0.id == sid }) {
                        Text("Filtered by \(svc.name)")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "C8860A"))
                            .transition(.opacity)
                    }
                }
                Spacer()
                if selectedServiceID != nil {
                    Button(action: { withAnimation(.spring(response: 0.3)) { selectedServiceID = nil } }) {
                        Text("Show All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "C8860A"))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Color(hex: "E5A820").opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.2), value: selectedServiceID)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(services) { service in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedServiceID = service.id
                        }
                    }) {
                        ServiceCategoryCard(service: service,
                                            isSelected: selectedServiceID == service.id)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Nearby Salons

    private var nearbySalonsSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedServiceID != nil
                         ? "\(services.first(where: { $0.id == selectedServiceID })?.name ?? "") Salons"
                         : "Nearby Salons")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .animation(.easeInOut(duration: 0.2), value: selectedServiceID)
                    Text("\(filteredSalons.count) found")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }

                Spacer()

                Button(action: { showMapSheet = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 12))
                        Text("Map View")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            if filteredSalons.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "building.2.slash")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "ABABAB"))
                    Text("No salons match your search")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredSalons) { salon in
                        Button(action: { selectedSalonName = salon.name }) {
                            SalonPreviewCard(salon: salon)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
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
                        .fill(isSelected ? Color(hex: "C8860A") : Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    Image(systemName: "scissors")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color(hex: "C8860A"))
                }
                Triangle()
                    .fill(isSelected ? Color(hex: "C8860A") : Color.white)
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
                        .foregroundColor(Color(hex: "C8860A"))
                }
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(salons.count) salons")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "8A8A8A"))
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
                .fill(Color(hex: "E5D5BB"))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "C8860A").opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))

                Label(salon.location, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "E5A820"))
                    Text("\(salon.rating, specifier: "%.1f")  ·  \(salon.distance)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "4A3828"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "C8860A"))
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
                    .fill(isSelected ? Color(hex: "C8860A") : Color(hex: "E5A820").opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: service.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : Color(hex: "C8860A"))
            }

            Text(service.name)
                .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color(hex: "C8860A") : Color(hex: "4A3828"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(isSelected ? Color(hex: "FFF8EE") : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? Color(hex: "C8860A").opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isSelected ? Color(hex: "C8860A").opacity(0.18) : Color.black.opacity(0.04),
                radius: isSelected ? 8 : 6, x: 0, y: 2)
    }
}

// MARK: - Salon Preview Card

struct SalonPreviewCard: View {
    let salon: SalonPreview

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: "E5D5BB"))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 26))
                        .foregroundColor(Color(hex: "C8860A").opacity(0.5))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(salon.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))

                Label(salon.location, systemImage: "mappin")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "E5A820"))
                    Text("\(salon.rating, specifier: "%.1f") (\(salon.reviews) reviews)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(hex: "4A3828"))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(salon.distance)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "C8860A"))
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
                .stroke(Color(hex: "E5A820").opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: score)
                .stroke(Color(hex: "C8860A"),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: score)
            Text("\(Int(score * 100))%")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(hex: "C8860A"))
        }
        .frame(width: 40, height: 40)
    }
}

#Preview {
    HomeView()
}
