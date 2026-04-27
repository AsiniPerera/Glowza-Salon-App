import SwiftUI

private let brand = Color(hex: "962043")

// MARK: - Salon Detail View
struct SalonDetailView: View {

    let salonName: String

    @Environment(TreatmentComparisonStore.self) private var comparisonStore
    @Environment(\.dismiss) private var dismiss

    @State private var showBookingFlow = false
    @State private var bookingDraft    = BookingDraft(salon: SalonCatalog.shared.salons[0])
    @State private var isFavourited    = false
    @State private var photoIndex      = 0
    @State private var selectedTab     = 0
    @State private var selectedService: SalonService? = nil

    private var salon: Salon {
        SalonCatalog.shared.salon(named: salonName)
    }

    private var reviews: [BookingReview] {
        let real = BookingStore.shared.reviews(forSalon: salonName)
        return real.isEmpty ? sampleReviews : real
    }

    private let sampleReviews: [BookingReview] = [
        BookingReview(rating: 5, comment: "Absolutely loved the facial treatment! Skin is glowing.", date: Date(), reviewerName: "Dilnoza R."),
        BookingReview(rating: 4, comment: "Professional staff, clean environment. Will return.", date: Date(), reviewerName: "Amara S."),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    infoSheet
                }
            }
            .ignoresSafeArea(edges: .top)

            bookNowBar
                .opacity(showBookNow ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showBookNow)
        }
        .navigationBarHidden(true)
        .onAppear {
            bookingDraft = BookingDraft(salon: salon)
        }
        .fullScreenCover(isPresented: $showBookingFlow) {
            BookingFlowView(draft: bookingDraft)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: "C0BBB7"))
                .frame(height: 260)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundColor(.white.opacity(0.3))
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
            .padding(.bottom, 20)
        }
        .frame(height: 260)
        .overlay(alignment: .topLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 5)
            }
            .padding(.leading, 20)
            .padding(.top, 56)
        }
        .overlay(alignment: .topTrailing) {
            HStack(spacing: 10) {
                Button(action: { isFavourited.toggle() }) {
                    Image(systemName: isFavourited ? "heart.fill" : "heart")
                        .font(.system(size: 15))
                        .foregroundColor(isFavourited ? brand : Color(hex: "1A1A1A"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 5)
                }
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .frame(width: 36, height: 36)
                        .background(Color.white)
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
            .padding(.bottom, 20)
        }
    }

    // MARK: - Info Sheet
    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(salon.about)
                .italic()
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "3A3A3A"))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 24)
                .padding(.vertical, 20)

            tabBar
            Divider()

            if selectedTab == 1 {
                servicesContent
            } else if selectedTab == 2 {
                reviewsContent
            } else {
                aboutContent
            }

            Spacer().frame(height: 100)
        }
        .background(Color.white)
    }

    

    // MARK: - Helpers

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach([("About", 0), ("Services", 1), ("Reviews & Ratings", 2)], id: \.1) { label, idx in
                Button(action: { selectedTab = idx }) {
                    VStack(spacing: 0) {
                        Text(label)
                            .font(.system(size: 13))
                            .foregroundColor(selectedTab == idx ? brand : Color(hex: "8A8A8A"))
                            .padding(.vertical, 14)
                        Rectangle()
                            .fill(selectedTab == idx ? brand : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
            }
        }
    }

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
                        .foregroundColor(Color(hex: "1A1A1A"))
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
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Button(action: {}) {
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
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(hex: "D5CFC9"))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.5))
                            )
                    }
                }
            }
            .padding(.horizontal, 24)

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i == 0 ? brand : Color(hex: "D0D0D0"))
                        .frame(width: i == 0 ? 10 : 8, height: i == 0 ? 10 : 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
        }
    }

    private var servicesContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(salon.services) { service in
                Button(action: {
                    if selectedService?.id == service.id {
                        selectedService = nil  // deselect
                    } else {
                        selectedService = service
                        bookingDraft.service = service
                    }
                }) {
                    HStack(spacing: 14) {
                        // Checkbox
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(selectedService?.id == service.id ? brand : Color(hex: "C7C7CC"), lineWidth: 1.5)
                                .frame(width: 22, height: 22)
                            if selectedService?.id == service.id {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(brand)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.name)
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "1A1A1A"))
                            Text(service.duration)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8A8A8A"))
                        }
                        Spacer()
                        Text("LKR \(Int(service.price))")
                            .font(.system(size: 14))
                            .foregroundColor(brand)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        selectedService?.id == service.id
                            ? brand.opacity(0.05)
                            : Color.clear
                    )
                }
                .buttonStyle(.plain)
                Divider().padding(.horizontal, 20)
            }
        }
        .padding(.top, 4)
    }

    private var reviewsContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(reviews.prefix(3)) { review in
                reviewRow(review)
                Divider().padding(.horizontal, 20)
            }
        }
        .padding(.top, 8)
    }

    private func reviewRow(_ review: BookingReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(brand.opacity(0.10)).frame(width: 36, height: 36)
                    Text(String(review.reviewerName.prefix(1)))
                        .font(.system(size: 14))
                        .foregroundColor(brand)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    HStack(spacing: 3) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= review.rating ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(i <= review.rating ? Color(hex: "F59E0B") : Color(hex: "DCDCDC"))
                        }
                    }
                }
                Spacer()
                Text(review.date, style: .date)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "ABABAB"))
            }
            Text(review.comment)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "6B6B6B"))
                .lineSpacing(3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var showBookNow: Bool {
        switch selectedTab {
        case 0: return true                        // About tab — always show
        case 1: return selectedService != nil      // Services tab — only when selection made
        default: return false                      // Reviews tab — hidden
        }
    }

    // Book Now Bar
    private var bookNowBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "962043")).frame(height: 1)
            Button(action: {
                if let svc = selectedService {
                    bookingDraft.service = svc
                }
                showBookingFlow = true
            }) {
                HStack(spacing: 10) {
                    if let svc = selectedService, selectedTab == 1 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(svc.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text("LKR \(Int(svc.price))")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        Spacer()
                    } else if selectedTab != 1 {
                        Spacer()
                    }
                    Text("Book Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    if selectedService == nil || selectedTab != 1 {
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
            .background(Color.white)
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
}

#Preview {
    NavigationStack {
        SalonDetailView(salonName: "Haley Avenue")
            .environment(TreatmentComparisonStore.shared)
    }
}
