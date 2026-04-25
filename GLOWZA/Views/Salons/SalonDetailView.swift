import SwiftUI
import MapKit

private let brand = Color(hex: "FF006E")

private enum DetailTab: String, CaseIterable {
    case about = "About"
    case services = "Services"
    case reviews = "Reviews & Ratings"
}

struct SalonDetailView: View {
    let salonName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var selectedTab: DetailTab = .about
    @State private var galleryIndex = 0

    private var salon: Salon {
        SalonCatalog.shared.salon(named: salonName)
    }

    private var salonCoordinate: CLLocationCoordinate2D {
        switch salon.name {
        case "Haley Avenue":
            return CLLocationCoordinate2D(latitude: 6.7730, longitude: 79.8820)
        case "Glow Studio":
            return CLLocationCoordinate2D(latitude: 6.7713, longitude: 79.8783)
        case "Luxe Aesthetics":
            return CLLocationCoordinate2D(latitude: 6.8490, longitude: 79.8684)
        default:
            return CLLocationCoordinate2D(latitude: 6.8920, longitude: 79.8560)
        }
    }

    private var reviews: [BookingReview] {
        let real = BookingStore.shared.reviews(forSalon: salonName)
        if !real.isEmpty { return real }
        return [
            BookingReview(rating: 5, comment: "Very clean place and friendly staff. Great facial results.", date: Date(), reviewerName: "Alexandra K."),
            BookingReview(rating: 4, comment: "Nice ambience and professional service. Will book again.", date: Date(), reviewerName: "Madhavi S.")
        ]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                heroSection
                headerSection
                tabBar
                tabContent
            }
        }
        .background(Color(hex: "F1F1F1").ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            Image("Salon1")
                .resizable()
                .scaledToFill()
                .frame(height: 250)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.black.opacity(0.10)],
                startPoint: .bottom,
                endPoint: .top
            )
            .frame(height: 250)

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.white)
                    Text("\(String(format: "%.1f", salon.rating)) (\(salon.reviewCount) reviews)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }

                Text(salon.name)
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .foregroundColor(.white.opacity(0.95))
                    Text(salon.location)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.95))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity, alignment: .bottomLeading)

            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2F33"))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.95))
                    .clipShape(Circle())
            }
            .padding(.top, 50)
            .padding(.leading, 14)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("A premium beauty studio offering expert hair, skin & nail services in a luxurious and relaxing setting")
                .font(.system(size: 17))
                .foregroundColor(Color(hex: "4A4C52"))
                .lineSpacing(4)

            Divider().overlay(Color(hex: "E3E3E6"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(selectedTab == tab ? brand : Color(hex: "787A80"))
                        Rectangle()
                            .fill(selectedTab == tab ? brand : .clear)
                            .frame(height: 2.2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .about:
                aboutContent
            case .services:
                servicesContent
            case .reviews:
                reviewsContent
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -50 {
                        moveToNextTab()
                    } else if value.translation.width > 50 {
                        moveToPreviousTab()
                    }
                }
        )
    }

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 16) {
                detailInfoCard(
                    icon: "clock",
                    title: "AVAILABILITY",
                    main: "Open Today",
                    sub: salon.openHours.replacingOccurrences(of: "Mon–Sat: ", with: "")
                )
                detailInfoCard(
                    icon: "paperplane",
                    title: "LOCATION",
                    main: "\(salon.distance) · 12 min",
                    sub: "Get Direction",
                    isAction: true,
                    action: openDirections
                )
            }

            Text(salon.about)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "777A82"))
                .lineSpacing(3)

            HStack(spacing: 26) {
                Text("Contact Us")
                    .font(.system(size: 30, weight: .regular, design: .rounded))
                    .foregroundColor(Color(hex: "666870"))

                Button(action: callSalon) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(hex: "23C167"))
                }
                Button(action: openFacebook) {
                    Image(systemName: "f.cursive.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(Color(hex: "1C63D7"))
                }
                Button(action: openWhatsApp) {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(Color(hex: "13B15E"))
                }
            }

            Text("Gallery")
                .font(.system(size: 32, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "5E6067"))

            TabView(selection: $galleryIndex) {
                ForEach(0..<3, id: \.self) { idx in
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(0..<4, id: \.self) { cell in
                            Image((idx + cell).isMultiple(of: 2) ? "Salon1" : "salon2")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 92)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { idx in
                    Circle()
                        .fill(idx == galleryIndex ? brand : Color(hex: "CDCFD4"))
                        .frame(width: 12, height: 12)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var servicesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(salon.services) { service in
                HStack(spacing: 12) {
                    Circle()
                        .fill(brand.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: service.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(brand)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(service.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1F2125"))
                        Text(service.duration)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "7A7E86"))
                    }
                    Spacer()
                    Text("LKR \(Int(service.price))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(brand)
                }
                .padding(12)
                .background(Color(hex: "F8F8FA"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(review.reviewerName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(hex: "222429"))
                        Spacer()
                        Text(review.date, style: .date)
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "9A9DA4"))
                    }

                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 11))
                                .foregroundColor(i <= review.rating ? Color(hex: "E5AF32") : Color(hex: "D2D4D9"))
                        }
                    }

                    Text(review.comment)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6A6D74"))
                        .lineSpacing(3)
                }
                .padding(12)
                .background(Color(hex: "F8F8FA"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 24)
    }

    private func detailInfoCard(
        icon: String,
        title: String,
        main: String,
        sub: String,
        isAction: Bool = false,
        action: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "5A5D63"))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "60636A"))
            }
            Text(main)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "1D1F24"))
            if let action, isAction {
                Button(action: action) {
                    Text(sub)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "9A6D3D"))
                }
                .buttonStyle(.plain)
            } else {
                Text(sub)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "6A6D74"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func moveToNextTab() {
        guard let idx = DetailTab.allCases.firstIndex(of: selectedTab),
              idx < DetailTab.allCases.count - 1 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = DetailTab.allCases[idx + 1]
        }
    }

    private func moveToPreviousTab() {
        guard let idx = DetailTab.allCases.firstIndex(of: selectedTab), idx > 0 else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = DetailTab.allCases[idx - 1]
        }
    }

    private func callSalon() {
        let digits = salon.phone.filter(\.isNumber)
        if let url = URL(string: "tel://\(digits)") {
            openURL(url)
        }
    }

    private func openWhatsApp() {
        let digits = salon.phone.filter(\.isNumber)
        if let url = URL(string: "https://wa.me/\(digits)") {
            openURL(url)
        }
    }

    private func openFacebook() {
        if let url = URL(string: "https://facebook.com") {
            openURL(url)
        }
    }

    private func openDirections() {
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: salonCoordinate))
        destination.name = salon.name
        destination.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

#Preview {
    NavigationStack {
        SalonDetailView(salonName: "Haley Avenue")
            .environment(TreatmentComparisonStore.shared)
    }
}
