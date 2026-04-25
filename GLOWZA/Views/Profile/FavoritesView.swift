import SwiftUI

// MARK: - Favorites Store
@Observable
final class FavoritesStore {
    static let shared = FavoritesStore()
    private init() {}
    var favoriteIDs: Set<UUID> = []

    func toggle(_ salon: Salon) {
        if favoriteIDs.contains(salon.id) { favoriteIDs.remove(salon.id) }
        else { favoriteIDs.insert(salon.id) }
    }

    func isFavorite(_ salon: Salon) -> Bool { favoriteIDs.contains(salon.id) }
}

// MARK: - Favorites View
struct FavoritesView: View {

    private let brand = Color(hex: "AF1C47")
    @State private var store = FavoritesStore.shared

    private var favoriteSalons: [Salon] {
        SalonCatalog.shared.salons.filter { store.isFavorite($0) }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            if favoriteSalons.isEmpty {
                emptyState
            } else {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(favoriteSalons) { salon in
                        NavigationLink(destination: SalonDetailView(salonName: salon.name)) {
                            FavoriteSalonCard(salon: salon, store: store)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .background(Color(hex: "F7F7F7").ignoresSafeArea())
        .navigationTitle("Favourites")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 80)
            ZStack {
                Circle()
                    .fill(brand.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "heart.slash")
                    .font(.system(size: 44))
                    .foregroundColor(brand.opacity(0.5))
            }
            Text("No Favourites Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "1A1A1A"))
            Text("Tap the heart icon on any salon to\nadd it to your favourites.")
                .multilineTextAlignment(.center)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A8A"))
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

// MARK: - Favorite Salon Card
private struct FavoriteSalonCard: View {

    let salon: Salon
    var store: FavoritesStore

    private let brand = Color(hex: "AF1C47")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image placeholder header
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 0)
                    .fill(
                        LinearGradient(
                            colors: [brand.opacity(0.15), brand.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 110)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.system(size: 34))
                            .foregroundColor(brand.opacity(0.3))
                    }

                // Heart button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.toggle(salon)
                    }
                } label: {
                    Image(systemName: store.isFavorite(salon) ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(store.isFavorite(salon) ? brand : Color.white)
                        .padding(8)
                        .background(Color.white.opacity(0.9))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4)
                }
                .padding(10)
            }

            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(salon.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "1A1A1A"))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 9))
                        .foregroundColor(brand)
                    Text(salon.location)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "6B6B6B"))
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(String(format: "%.1f", salon.rating))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A1A"))
                    Text("(\(salon.reviewCount))")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "8A8A8A"))
                }

                if let price = salon.services.first?.price {
                    Text(String(format: "From Rs %.0f", price))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(brand)
                }
            }
            .padding(12)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
    }
}
