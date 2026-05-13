import SwiftUI

// MARK: - Favourite Salons View
// This view displays a list of salons that the user has marked as favorites.
// Users can tap on a salon to view its details or tap the heart to remove it.
struct FavouriteSalonsView: View {

    @Environment(AppSettings.self) private var appSettings
    @Environment(\.dismiss) private var dismiss

    private var favourites: FavouritesStore { FavouritesStore.shared }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Custom Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(appSettings.themeBrand)
                    }
                    .frame(minWidth: 70, alignment: .leading)

                    Spacer()

                    Text("Favourite Salons")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(appSettings.themeText)

                    Spacer()
                    Spacer().frame(width: 70) // To balance the back button width!
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(appSettings.themeDivider)
                    .frame(height: 0.5)

                // Show empty state if no favorites!
                if favourites.favouriteNames.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(favourites.favouriteNames, id: \.self) { name in
                                FavouriteSalonRow(salonName: name)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 36)
                    }
                }
            }
            .background(appSettings.themePage.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await favourites.load() } // Load favorites on appear!
        }
    }

    // MARK: - Empty State
    // Shown when there are no favorite salons.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 52, weight: .thin))
                .foregroundColor(appSettings.themeTextSecondary)
            Text("No Favourites Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(appSettings.themeText)
            Text("Tap the heart on any salon to save it here.")
                .font(.system(size: 14))
                .foregroundColor(appSettings.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Individual Row
// Displays a single favorite salon with its image, rating, and location.
private struct FavouriteSalonRow: View {
    let salonName: String
    @Environment(AppSettings.self) private var appSettings
    @State private var navigateToDetail = false

    private var salon: Salon { SalonCatalog.shared.salon(named: salonName) }
    private var favourites: FavouritesStore { FavouritesStore.shared }

    var body: some View {
        // NavigationLink to go to the salon detail view!
        NavigationLink(destination: SalonDetailView(salonName: salonName)) {
            HStack(spacing: 14) {
                // Salon Image
                Image(mappedSalonImageName(salonName))
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Salon Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(salon.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(appSettings.themeText)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(appSettings.themeBrand.opacity(0.6))
                        Text(salon.location)
                            .font(.system(size: 13))
                            .foregroundColor(appSettings.themeTextSecondary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "E4B234"))
                        Text(String(format: "%.1f", salon.rating))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(appSettings.themeText)
                        Text("(\(salon.reviewCount))")
                            .font(.system(size: 12))
                            .foregroundColor(appSettings.themeTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Remove / unfavourite button
                Button(action: { Task { await favourites.toggle(salonName) } }) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(appSettings.themeTextSecondary)
            }
            .padding(14)
            .background(appSettings.themeSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .hcBorder(radius: 16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FavouriteSalonsView()
        .environment(AppSettings.shared)
}

// MARK: - Salon image helper (mirrors HomeView mapping)
private func mappedSalonImageName(_ salonName: String) -> String {
    switch salonName {
    case "Golden Avenue":       return "Salon1"
    case "Glow Studio":        return "salon2"
    case "Luxe Aesthetics":    return "salon3"
    case "Velvet Touch":       return "salon4"
    case "Aura Beauty Bar":    return "salon5"
    case "Silk & Shine":       return "salon6"
    case "Prime Beauty":       return "salon7"
    case "Elegance Salon":     return "salon8"
    case "Crystal Beauty":     return "salon9"
    case "Radiant Aesthetic":  return "salon10"
    case "Cinnamon Glow":      return "Salon1"
    case "Rose Mirror":        return "salon2"
    case "Urban Bloom":        return "salon3"
    case "Coco Beauty Lounge": return "salon4"
    case "The Beauty Deck":    return "salon5"
    case "Lotus Salon":        return "salon6"
    case "Pearl Skin Studio":  return "salon7"
    case "Mirror Muse":        return "salon8"
    case "Golden Petals":      return "salon9"
    case "Blush Avenue":       return "salon10"
    case "Opal Aesthetics":    return "Salon1"
    default:                   return "Salon1"
    }
}
