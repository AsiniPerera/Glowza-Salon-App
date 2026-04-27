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

    @State private var searchText = ""
    @State private var selectedSalonName: String? = nil
    @State private var showMapSheet = false

    private let services: [ServiceCategory] = [
        .init(name: "Skin Care", icon: "leaf", category: "Skin"),
        .init(name: "Chemical\nPeel", icon: "atom", category: "Skin"),
        .init(name: "Laser Hair", icon: "bolt", category: "Hair"),
        .init(name: "Hair Care", icon: "scissors", category: "Hair")
    ]

    private let allSalons: [SalonPreview] = [
        .init(name: "Haley Avenue", location: "Moratuwa, Colombo", distance: "2 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820), imageName: "Salon1"),
        .init(name: "Haley Avenue", location: "Moratuwa, Colombo", distance: "2 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783), imageName: "Salon1"),
        .init(name: "Haley Avenue", location: "Moratuwa, Colombo", distance: "2 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684), imageName: "Salon1"),
        .init(name: "Haley Avenue", location: "Moratuwa, Colombo", distance: "2 km", rating: 4.7, reviews: 312, score: 0.95,
              coordinate: CLLocationCoordinate2D(latitude: 6.8696, longitude: 79.8999), imageName: "Salon1")
    ]

    private var filteredSalons: [SalonPreview] {
        var result = searchText.isEmpty ? allSalons : allSalons.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFFFFF").ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        topBar
                            .padding(.horizontal, 24)
                            .padding(.top, 18)
                            .padding(.bottom, 18)
                        searchBar
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        servicesSection
                            .padding(.horizontal, 24)
                            .padding(.bottom, 22)
                        nearbySection
                            .padding(.horizontal, 14)
                            .padding(.bottom, 24)
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

    // MARK: - Top Bar (as design)
    private var topBar: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(hex: "9FD8CE"))
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "3E4A50"))
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("Welcome")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "1D1F24"))
                Text("Asini")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "1D1F24"))
            }

            Spacer()

            Button(action: {}) {
                Circle()
                    .fill(Color(hex: "FAF3F4"))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: "bell")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(brand)
                    }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(hex: "A4A7AF"))
            TextField("Search salons or city ...", text: $searchText)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "71757F"))
        }
        .padding(.horizontal, 18)
        .frame(height: 46)
        .background(Color(hex: "EDEDEF"))
        .clipShape(Capsule())
    }

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Services")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "1B1D21"))

            HStack(alignment: .top, spacing: 20) {
                ForEach(services) { service in
                    VStack(spacing: 8) {
                        Circle()
                            .stroke(brand, lineWidth: 1.4)
                            .frame(width: 62, height: 62)
                            .overlay {
                                Image(systemName: service.icon)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(brand)
                            }
                        Text(service.name)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(hex: "962043"))
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                }
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(" Nearby Salons")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(Color(hex: "1B1D21"))
                Spacer()
                Button(action: { showMapSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12, weight: .medium))
                        Text("Map View")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(brand)
                }
            }

            VStack(spacing: 8) {
                ForEach(filteredSalons) { salon in
                    Button(action: { selectedSalonName = salon.name }) {
                        SalonRowCard(salon: salon)
                    }
                }
            }
        }
    }
}

private struct SalonRowCard: View {
    let salon: SalonPreview

    var body: some View {
        HStack(spacing: 12) {
            Image(salon.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 92, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(salon.name)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "1F2126"))
                    Spacer()
                    Text(salon.distance)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "8E9198"))
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "A3A6AE"))
                    Text(salon.location)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "8A8E95"))
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "E4B234"))
                    Text(String(format: "%.1f", salon.rating))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "2E3036"))
                    Text("(\(salon.reviews))")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(Color(hex: "8A8E95"))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "F8F8F8"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(Color(hex: "962043"))
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
                            .foregroundColor(brand)
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
                    .fill(isSelected ? brand : brand.opacity(0.08))
                    .frame(width: 44, height: 44)
                Image(systemName: service.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : brand)
            }
            Text(service.name).font(.system(size: 11)).foregroundColor(Color(hex: "1A1A1A"))
        }
    }
}

#Preview { HomeView() }
