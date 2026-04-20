import SwiftUI

struct SalonDetailView: View {

    let salonName: String
    @State private var showBookingFlow = false
    @State private var preselectedService: SalonService? = nil
    @State private var activeTab = 0
    @Environment(TreatmentComparisonStore.self) private var treatStore
    @Environment(\.dismiss) private var dismiss

    private var salon: Salon { SalonCatalog.shared.salon(named: salonName) }
    private var reviews: [BookingReview] { BookingStore.shared.reviews(forSalon: salonName) }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.glowzaBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    infoStrip
                    contentSection
                    Spacer().frame(height: 100)
                }
            }

            bookNowBar
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showBookingFlow) {
            BookingFlowView(
                draft: BookingDraft(salon: salon, service: preselectedService)
            )
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder hero image
            LinearGradient(
                colors: [Color(hex: "4A3828"), Color(hex: "C8860A").opacity(0.7)],
                startPoint: .bottomLeading, endPoint: .topTrailing
            )
            .frame(height: 260)
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.system(size: 90))
                    .foregroundColor(.white.opacity(0.07))
                    .offset(x: 80, y: 20)
            )

            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 20)

            // Name overlay
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color.glowzaGold)
                    Text("\(salon.rating, specifier: "%.1f")  (\(salon.reviewCount) reviews)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(salon.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                Label(salon.location, systemImage: "mappin.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
            .frame(height: 260, alignment: .bottom)
        }
    }

    // MARK: - Info Strip
    private var infoStrip: some View {
        HStack(spacing: 0) {
            infoChip(icon: "phone.fill",       text: salon.phone)
            Divider().frame(height: 30)
            infoChip(icon: "clock.fill",       text: salon.openHours)
            Divider().frame(height: 30)
            infoChip(icon: "location.fill",    text: salon.distance)
        }
        .padding(.vertical, 14)
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func infoChip(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color.glowzaGoldDark)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color.glowzaDark)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }

    // MARK: - Content (About / Services / Reviews tabs)
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Custom segmented tabs
            HStack(spacing: 0) {
                ForEach(["About", "Services", "Reviews"], id: \.self) { tab in
                    let idx = ["About", "Services", "Reviews"].firstIndex(of: tab)!
                    Button(action: { withAnimation { activeTab = idx } }) {
                        VStack(spacing: 6) {
                            Text(tab)
                                .font(.system(size: 14, weight: activeTab == idx ? .bold : .regular))
                                .foregroundColor(activeTab == idx ? Color.glowzaGoldDark : Color.glowzaSubtext)
                            Rectangle()
                                .fill(activeTab == idx ? Color.glowzaGoldDark : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)

            switch activeTab {
            case 0: aboutTab
            case 1: servicesTab
            default: reviewsTab
            }
        }
    }

    // About tab
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About Us")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.glowzaDark)

            Text(salon.about)
                .font(.system(size: 14))
                .foregroundColor(Color.glowzaDark.opacity(0.8))
                .lineSpacing(5)

            // Rating summary
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(salon.rating, specifier: "%.1f")")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color.glowzaGoldDark)
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: Double(i) <= salon.rating ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(Color.glowzaGold)
                        }
                    }
                    Text("\(salon.reviewCount) reviews")
                        .font(.system(size: 11))
                        .foregroundColor(Color.glowzaSubtext)
                }
                VStack(alignment: .leading, spacing: 6) {
                    ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                        HStack(spacing: 8) {
                            Text("\(star)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.glowzaSubtext)
                                .frame(width: 10)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3).fill(Color(hex: "E0D5C5")).frame(height: 6)
                                    RoundedRectangle(cornerRadius: 3).fill(Color.glowzaGold)
                                        .frame(width: geo.size.width * barFraction(star: star), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .padding(16)
            .glowzaCard()
        }
        .padding(.horizontal, 20)
    }

    private func barFraction(star: Int) -> CGFloat {
        let fractions: [Int: CGFloat] = [5: 0.72, 4: 0.15, 3: 0.07, 2: 0.04, 1: 0.02]
        return fractions[star] ?? 0
    }

    // Services tab
    private var servicesTab: some View {
        VStack(spacing: 12) {
            ForEach(salon.services) { service in
                serviceRow(service)
            }
        }
        .padding(.horizontal, 20)
    }

    private func serviceRow(_ service: SalonService) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.glowzaGold.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: service.icon)
                    .font(.system(size: 20))
                    .foregroundColor(Color.glowzaGoldDark)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(service.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.glowzaDark)
                HStack(spacing: 10) {
                    Label(service.duration, systemImage: "clock")
                    Text(service.category)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.glowzaGold.opacity(0.1))
                        .clipShape(Capsule())
                }
                .font(.system(size: 11))
                .foregroundColor(Color.glowzaSubtext)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("LKR \(Int(service.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.glowzaGoldDark)
                HStack(spacing: 8) {
                    // Compare toggle
                    let added = treatStore.isAdded(service, from: salon.name)
                    Button(action: {
                        if added {
                            if let item = treatStore.items.first(where: {
                                $0.service.id == service.id && $0.salonName == salon.name
                            }) { treatStore.remove(item) }
                        } else {
                            treatStore.add(service: service, salonName: salon.name)
                        }
                    }) {
                        Image(systemName: added ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 22))
                            .foregroundColor(added ? Color.glowzaGoldDark : Color.glowzaSubtext.opacity(0.5))
                    }
                    Button(action: {
                        preselectedService = service
                        showBookingFlow = true
                    }) {
                        Text("Book")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14).padding(.vertical, 6)
                            .background(Color.glowzaGoldDark)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .glowzaCard()
    }

    // Reviews tab
    private var reviewsTab: some View {
        VStack(spacing: 12) {
            if reviews.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "star.bubble")
                        .font(.system(size: 36)).foregroundColor(Color.glowzaSubtext.opacity(0.4))
                    Text("No reviews yet")
                        .font(.system(size: 15)).foregroundColor(Color.glowzaSubtext)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 40)
            } else {
                ForEach(reviews) { review in
                    reviewCard(review)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func reviewCard(_ review: BookingReview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    Circle().fill(Color.glowzaGold.opacity(0.15)).frame(width: 38, height: 38)
                    Text(String(review.reviewerName.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.glowzaGoldDark)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(Color.glowzaDark)
                    Text(review.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11)).foregroundColor(Color.glowzaSubtext)
                }
                Spacer()
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= review.rating ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(i <= review.rating ? Color.glowzaGold : Color.glowzaSubtext.opacity(0.3))
                    }
                }
            }
            Text(review.comment)
                .font(.system(size: 13)).foregroundColor(Color.glowzaDark.opacity(0.8)).lineSpacing(4)
        }
        .padding(14)
        .glowzaCard()
    }

    // MARK: - Book Now Bar
    private var bookNowBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Starting from")
                    .font(.system(size: 11)).foregroundColor(Color.glowzaSubtext)
                Text("LKR \(Int(salon.services.map(\.price).min() ?? 0))")
                    .font(.system(size: 18, weight: .bold)).foregroundColor(Color.glowzaGoldDark)
            }
            Button(action: {
                preselectedService = nil
                showBookingFlow = true
            }) {
                Text("Book Now")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(
                        LinearGradient(colors: [Color(hex: "E5A820"), Color(hex: "C8860A")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
}
