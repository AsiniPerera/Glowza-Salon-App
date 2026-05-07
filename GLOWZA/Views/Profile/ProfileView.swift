import SwiftUI
import PhotosUI

// MARK: - Profile View
struct ProfileView: View {

    @Environment(AppSettings.self) private var appSettings

    @State private var isFaceIDEnabled   = true
    @State private var pushNotifications = true
    @State private var voiceOverSupport  = true

    @State private var showEditProfile      = false
    @State private var showChangePassword   = false
    @State private var showTreatmentHistory = false
    @State private var showSecurity         = false
    @State private var showAppUpdates       = false
    @State private var showTerms            = false
    @State private var showFontSizeSettings = false
    @State private var showSignOutAlert     = false
    @State private var showFavourites       = false

    private var favourites: FavouritesStore { FavouritesStore.shared }

    @State private var avatarData: Data?               = UserDefaults.standard.data(forKey: "profile_avatarData")
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var displayName: String             = UserDefaults.standard.string(forKey: "profile_fullName") ?? "Asini Perera"

    private var brand: Color { appSettings.themeBrand }

    private var avatarImage: UIImage? {
        guard let d = avatarData else { return nil }
        return UIImage(data: d)
    }

    private var initials: String {
        displayName.split(separator: " ").prefix(2).compactMap { $0.first?.uppercased() }.joined()
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // MARK: Page title
                    Text("Profile")
                        .glowzaFont(size: 20, weight: .bold)
                        .foregroundColor(appSettings.themeText)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    // MARK: Avatar card
                    VStack(spacing: 14) {
                        avatarView(size: 80)
                        Text(displayName)
                            .glowzaFont(size: 18, weight: .semibold)
                            .foregroundColor(appSettings.themeText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(appSettings.themeSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .hcBorder(radius: 16)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // MARK: Favourites
                    sectionLabel("Favourites")
                    profileCard {
                        navButton(
                            title: "Favourite Salons",
                            icon: "heart.fill",
                            color: .red
                        ) { showFavourites = true }
                        .overlay(alignment: .trailing) {
                            if !favourites.favouriteNames.isEmpty {
                                Text("\(favourites.favouriteNames.count)")
                                    .glowzaFont(size: 12, weight: .bold)
                                    .foregroundColor(.white)
                                    .frame(minWidth: 20, minHeight: 20)
                                    .padding(.horizontal, 6)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .padding(.trailing, 36)
                            }
                        }
                    }

                    // MARK: Account
                    sectionLabel("Account")
                    profileCard {
                        navButton(title: "Edit Profile",      icon: "person.crop.circle.fill", color: brand)   { showEditProfile = true }
                        cardDivider
                        navButton(title: "Change Password",   icon: "lock.fill",               color: .purple) { showChangePassword = true }
                        cardDivider
                        navButton(title: "Treatment History", icon: "clock.arrow.circlepath",  color: .teal)   { showTreatmentHistory = true }
                    }

                    // MARK: Security
                    sectionLabel("Security")
                    profileCard {
                        navButton(title: "Security & Privacy", icon: "checkmark.shield.fill", color: .green) { showSecurity = true }
                        cardDivider
                        toggleRow(title: "Face ID",
                                  icon: "faceid",
                                  color: Color(red: 0, green: 0.55, blue: 1),
                                  isOn: $isFaceIDEnabled)
                    }

                    // MARK: Preferences
                    sectionLabel("Preferences")
                    profileCard {
                        toggleRow(title: "Push Notifications", icon: "bell.badge.fill",        color: .red,    isOn: $pushNotifications)
                        cardDivider
                        toggleRow(title: "VoiceOver Support",  icon: "speaker.wave.2.fill",    color: .orange, isOn: $voiceOverSupport)
                        cardDivider
                        toggleRow(title: "High Contrast",      icon: "circle.lefthalf.filled", color: .pink,
                                  isOn: Binding(get: { appSettings.isHighContrast },
                                                set: { appSettings.isHighContrast = $0 }))
                        cardDivider
                        toggleRow(title: "Dark Mode",          icon: "moon.fill",              color: .indigo,
                                  isOn: Binding(get: { appSettings.isDarkMode },
                                                set: { appSettings.isDarkMode = $0 }))
                        cardDivider
                        fontSizeNavRow
                    }

                    // MARK: General
                    sectionLabel("General")
                    profileCard {
                        navButton(title: "App Updates",        icon: "arrow.down.app.fill", color: .cyan)              { showAppUpdates = true }
                        cardDivider
                        navButton(title: "Terms & Conditions", icon: "doc.text.fill",       color: Color(.systemGray)) { showTerms = true }
                    }

                    // MARK: Sign Out
                    Button(action: { showSignOutAlert = true }) {
                        HStack(spacing: 12) {
                            iconBadge(icon: "rectangle.portrait.and.arrow.right", color: .red)
                            Text("Sign Out")
                                .glowzaFont(size: 15, weight: .medium)
                                .foregroundStyle(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .glowzaFont(size: 12, weight: .semibold)
                                .foregroundStyle(Color(.tertiaryLabel))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(appSettings.themeSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .hcBorder(radius: 16)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                    .buttonStyle(.plain)

                    Spacer().frame(height: 40)
                }
            }
            .background(appSettings.themePage.ignoresSafeArea())
            .navigationBarHidden(true)
            .photosPicker(isPresented: .constant(false), selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            avatarData = data
                            UserDefaults.standard.set(data, forKey: "profile_avatarData")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFavourites)       { FavouriteSalonsView().environment(appSettings) }
        .sheet(isPresented: $showEditProfile)      { EditProfileView(displayName: $displayName, avatarData: $avatarData) }
        .sheet(isPresented: $showChangePassword)   { ChangePasswordView() }
        .sheet(isPresented: $showTreatmentHistory) { TreatmentTrackingView() }
        .sheet(isPresented: $showSecurity)         { SecurityPrivacyView() }
        .sheet(isPresented: $showAppUpdates)       { AppUpdatesView() }
        .sheet(isPresented: $showTerms)            { TermsConditionsView() }
        .sheet(isPresented: $showFontSizeSettings)  { FontSizeSettingsView().environment(appSettings).preferredColorScheme(appSettings.colorScheme) }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                NotificationCenter.default.post(name: .glowzaSignOut, object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Card helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .glowzaFont(size: 13, weight: .semibold)
            .foregroundColor(appSettings.themeTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
            .padding(.horizontal, 28)
            .padding(.top, 8)
            .padding(.bottom, 6)
    }

    private func profileCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(appSettings.themeSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .hcBorder(radius: 16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private var cardDivider: some View {
        Rectangle()
            .fill(appSettings.themeDivider)
            .frame(height: 0.5)
            .padding(.leading, 58)
    }

    // MARK: - Row builders

    private func navButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(icon: icon, color: color)
                Text(title)
                    .glowzaFont(size: 15, weight: .medium)
                    .foregroundColor(appSettings.themeText)
                Spacer()
                Image(systemName: "chevron.right")
                    .glowzaFont(size: 12, weight: .semibold)
                    .foregroundColor(appSettings.themeTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(title: String, icon: String, color: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, color: color)
            Toggle(title, isOn: isOn)
                .glowzaFont(size: 15, weight: .medium)
                .foregroundColor(appSettings.themeText)
                .tint(brand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var fontSizeNavRow: some View {
        Button(action: { showFontSizeSettings = true }) {
            HStack(spacing: 12) {
                iconBadge(icon: "textformat.size", color: Color(.sRGB, red: 88/255, green: 86/255, blue: 214/255))
                Text("Font Size")
                    .glowzaFont(size: 15, weight: .medium)
                    .foregroundColor(appSettings.themeText)
                Spacer()
                Text(appSettings.fontSizeScale.label)
                    .glowzaFont(size: 13, weight: .medium)
                    .foregroundColor(appSettings.themeTextSecondary)
                Image(systemName: "chevron.right")
                    .glowzaFont(size: 12, weight: .semibold)
                    .foregroundColor(appSettings.themeTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private func avatarView(size: CGFloat) -> some View {
        ZStack {
            if let ui = avatarImage {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(brand.opacity(0.12))
                    .frame(width: size, height: size)
                    .overlay(
                        Text(initials)
                            .glowzaFont(size: size * 0.34, weight: .bold)
                            .foregroundStyle(brand)
                    )
            }
        }
    }

    private func iconBadge(icon: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(color)
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .glowzaFont(size: 14, weight: .semibold)
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppSettings.shared)
}
