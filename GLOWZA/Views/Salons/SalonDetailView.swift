import SwiftUI

private let brand = Color(hex: "AF1C47")

// MARK: - Rounded Corner Helper
struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Salon Detail View
struct SalonDetailView: View {

    let salonName: String

    @Environment(TreatmentComparisonStore.self) private var comparisonStore
    @Environment(\.dismiss) private var dismiss

    @State private var showBookingFlow = false
    @State private var bookingDraft    = BookingDraft(salon: SalonCatalog.shared.salons[0])
    @State private var isFavourited    = false
    @State private var photoIndex      = 0

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

            // Sticky book bar
            bookBar
        }
        .navigationBarHidden(true)
        .onAppear {
            bookingDraft = BookingDraft(salon: salon)
            isFavourited = FavoritesStore.shared.isFavorite(salon)
        }
        .fullScreenCover(isPresented: $showBookingFlow) {
            BookingFlowView(draft: bookingDraft)
        }
    }

    // MARK: - Hero
    private var heroSection: some View {
        ZStack(alignment: .top) {
            // Photo placeholder
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [brand.opacity(0.15), Color(hex: "F5F5F5")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(height: 320)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(Color(hex: "DCDCDC"))
                )

            // Overlay gradient
            LinearGradient(
                colors: [Color.black.opacity(0.35), .clear],
                startPoint: .top, endPoint: .center
            )
            .frame(height: 320)

            // Photo counter
            Text("\(photoIndex + 1) / 6")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 56)
                .padding(.trailing, 20)

            // Back + action buttons
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                        .frame(width: 40, height: 40)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: {
                        isFavourited.toggle()
                        FavoritesStore.shared.toggle(salon)
                    }) {
                        Image(systemName: isFavourited ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isFavourited ? brand : Color(hex: "1A1A1A"))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6)
                    }
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1A1A1A"))
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.12), radius: 6)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
        }
    }

    // MARK: - Info Sheet
    private var infoSheet: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header ──
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(salon.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "1A1A1A"))

                        HStack(spacing: 8) {
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(brand)
                                .clipShape(Capsule())

                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "F59E0B"))
                                Text(String(format: "%.1f", salon.rating))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "1A1A1A"))
                                Text("(\(salon.reviewCount) reviews)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "8A8A8A"))
                            }
                        }
                    }
                    Spacer()
                    // Add first service to compare
                    if let firstService = salon.services.first {
                        Button(action: {
                            if comparisonStore.isAdded(firstService, from: salon.name) {
                                if let item = comparisonStore.items.first(where: {
                                    $0.service.id == firstService.id && $0.salonName == salon.name
                                }) { comparisonStore.remove(item) }
                            } else {
                                comparisonStore.add(service: firstService, salonName: salon.name)
                            }
                        }) {
                            Image(systemName: comparisonStore.isAdded(firstService, from: salon.name)
                                  ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: 28))
                                .foregroundColor(brand)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(brand)
                    Text(salon.location)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "6B6B6B"))
                }

                Text(salon.about)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6B6B6B"))
                    .lineSpacing(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            divider

            // ── Popular Services ──
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular Services")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(salon.services) { service in
                            Button(action: {
                                bookingDraft.service = service
                                showBookingFlow = true
                            }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(service.name)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "1A1A1A"))
                                    Text(service.duration)
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "8A8A8A"))
                                    Text("LKR \(Int(service.price))")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(brand)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color(hex: "FFF0F4"))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(brand.opacity(0.20), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 20)

            divider

            // ── Info Cards ──
            HStack(spacing: 12) {
                infoCard(icon: "clock.fill", title: "Open Today", value: "9 AM – 7 PM")
                infoCard(icon: "mappin.and.ellipse", title: "Get Direction", value: salon.location)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)

            divider

            // ── Reviews ──
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Reviews")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Spacer()
                    Text("See All")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brand)
                }
                .padding(.horizontal, 20)

                ForEach(reviews.prefix(2)) { review in
                    reviewRow(review)
                }
            }
            .padding(.vertical, 20)

            // Bottom padding for sticky bar
            Spacer().frame(height: 100)
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
        .offset(y: -24)
    }

    // MARK: - Book Bar
    private var bookBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1)
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Starting from")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                    Text("LKR \(Int(salon.services.first?.price ?? 0))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                }
                Button(action: { showBookingFlow = true }) {
                    Text("Book Now")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(brand)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: brand.opacity(0.28), radius: 10, x: 0, y: 4)
                }
                .frame(maxWidth: 200)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .padding(.bottom, 8)
            .background(Color.white)
        }
    }

    // MARK: - Helpers
    private var divider: some View {
        Rectangle().fill(Color(hex: "F5F5F5")).frame(height: 6)
    }

    private func infoCard(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(brand)
                .frame(width: 36, height: 36)
                .background(brand.opacity(0.08))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
                Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(Color(hex: "1A1A1A")).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(hex: "F9F9F9"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func reviewRow(_ review: BookingReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(brand.opacity(0.10)).frame(width: 38, height: 38)
                    Text(String(review.reviewerName.prefix(1)))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(brand)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(review.reviewerName)
                        .font(.system(size: 14, weight: .semibold))
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
    }
}

#Preview {
    NavigationStack {
        SalonDetailView(salonName: "Haley Avenue")
            .environment(TreatmentComparisonStore.shared)
    }
}
