import SwiftUI
import PhotosUI

// MARK: - Profile View
struct ProfileView: View {

    // App-wide settings
    @Environment(AppSettings.self) private var appSettings

    // Toggles
    @State private var isFaceIDEnabled      = true
    @State private var pushNotifications    = true
    @State private var voiceOverSupport     = true

    // Sheet navigation
    @State private var showEditProfile      = false
    @State private var showChangePassword   = false
    @State private var showTreatmentHistory = false
    @State private var showSecurity         = false
    @State private var showAppUpdates       = false
    @State private var showTerms            = false
    @State private var showSignOutAlert     = false

    // Avatar / name
    @State private var avatarData: Data?    = UserDefaults.standard.data(forKey: "profile_avatarData")
    @State private var showPhotoPicker      = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var displayName: String  = UserDefaults.standard.string(forKey: "profile_fullName") ?? "Asini Perera"

    private var brand: Color { appSettings.isHighContrast ? Color(hex: "FF66B2") : Color(hex: "962043") }
    private var pageBackground: Color { appSettings.isHighContrast ? .black : .white }
    private var primaryText: Color { appSettings.isHighContrast ? .white : Color(hex: "1C1C1E") }
    private var secondaryText: Color { appSettings.isHighContrast ? .white.opacity(0.78) : Color(hex: "8E8E93") }
    private var dividerColor: Color { appSettings.isHighContrast ? .white : Color(hex: "E5E5EA") }

    private var avatarImage: UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }

    private var initials: String {
        displayName.split(separator: " ").prefix(2).compactMap { $0.first?.uppercased() }.joined()
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileCard

                    sectionBlock(title: "Account Settings") {
                        navRow(icon: "person",               label: "Edit Profile")       { showEditProfile      = true }
                        navRow(icon: "lock",                 label: "Change Password")    { showChangePassword   = true }
                        navRow(icon: "clock.arrow.circlepath", label: "Treatment History") { showTreatmentHistory = true }
                    }
                    sectionBlock(title: "Security & Privacy") {
                        navRow(icon: "checkmark.shield",     label: "Security & Privacy") { showSecurity         = true }
                        toggleRow(icon: "faceid",            label: "Face ID",             value: $isFaceIDEnabled)
                    }
                    sectionBlock(title: "Notifications") {
                        toggleRow(icon: "bell",              label: "Push Notifications",  value: $pushNotifications)
                    }
                    sectionBlock(title: "Accessibility") {
                        toggleRow(icon: "mic",               label: "VoiceOver Support",   value: $voiceOverSupport)
                        toggleRow(icon: "eye",  label: "High Contrast Mode", value: Binding(get: { appSettings.isHighContrast }, set: { appSettings.isHighContrast = $0 }))
                        toggleRow(icon: "moon", label: "Dark Mode",           value: Binding(get: { appSettings.isDarkMode },      set: { appSettings.isDarkMode = $0 }))
                    }
                    sectionBlock(title: "General") {
                        navRow(icon: "gearshape",            label: "App Updates")        { showAppUpdates       = true }
                        navRow(icon: "doc.text",             label: "Terms & Conditions") { showTerms            = true }
                        navRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            label: "Sign Out",
                            foreground: .red,
                            showChevron: false
                        ) {
                            showSignOutAlert = true
                        }
                    }

                    Spacer().frame(height: 32)
                }
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(displayName: $displayName, avatarData: $avatarData)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView()
        }
        .sheet(isPresented: $showTreatmentHistory) {
            TreatmentTrackingView()
        }
        .sheet(isPresented: $showSecurity) {
            SecurityPrivacyView()
        }
        .sheet(isPresented: $showAppUpdates) {
            AppUpdatesView()
        }
        .sheet(isPresented: $showTerms) {
            TermsConditionsView()
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                NotificationCenter.default.post(name: .glowzaSignOut, object: nil)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        VStack(spacing: 12) {
            Text("Profile")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)

            Button(action: { showPhotoPicker = true }) {
                ZStack {
                    Circle()
                        .strokeBorder(brand, lineWidth: 3)
                        .frame(width: 100, height: 100)
                    if let ui = avatarImage {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 94, height: 94)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(appSettings.isHighContrast ? Color.black : Color(hex: "F2F2F7"))
                            .frame(width: 94, height: 94)
                        Text(initials)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(brand)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            avatarData = data
                            UserDefaults.standard.set(data, forKey: "profile_avatarData")
                        }
                    }
                }
            }

            Text(displayName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryText)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(pageBackground)
    }

    // MARK: - Section Block
    private func sectionBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(secondaryText)
                .textCase(.uppercase)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 8)
            VStack(spacing: 0) {
                content()
            }
            .background(pageBackground)
        }
    }

    // MARK: - Nav Row
    private func navRow(
        icon: String,
        label: String,
        foreground: Color = Color(hex: "1C1C1E"),
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(foreground == .red ? .red : secondaryText)
                    .frame(width: 28)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(foreground)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(secondaryText)
                }
            }
            .padding(.horizontal, 20)
            .frame(height: 52)
        }
        .buttonStyle(.plain)
        .overlay {
            if appSettings.isHighContrast {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(dividerColor).frame(height: appSettings.isHighContrast ? 1 : 0.5).padding(.leading, 62)
        }
    }

    // MARK: - Toggle Row
    private func toggleRow(icon: String, label: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(secondaryText)
                .frame(width: 28)
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(primaryText)
            Spacer()
            Toggle("", isOn: value).tint(brand).labelsHidden()
        }
        .padding(.horizontal, 20)
        .frame(height: 52)
        .overlay {
            if appSettings.isHighContrast {
                RoundedRectangle(cornerRadius: 25, style: .continuous)
                    .stroke(Color.white, lineWidth: 3)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(dividerColor).frame(height: appSettings.isHighContrast ? 1 : 0.5).padding(.leading, 62)
        }
    }
}

#Preview { ProfileView() }

