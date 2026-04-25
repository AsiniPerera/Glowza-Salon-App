import SwiftUI

// MARK: - Settings View
struct SettingsView: View {

    private let brand = Color(hex: "AF1C47")

    // Appearance
    @AppStorage("darkModeEnabled")      private var darkModeEnabled      = false
    @AppStorage("highContrastEnabled")  private var highContrastEnabled  = false
    @AppStorage("largeTextEnabled")     private var largeTextEnabled     = false

    // Notifications
    @AppStorage("bookingReminders")     private var bookingReminders     = true
    @AppStorage("promoNotifications")   private var promoNotifications   = true
    @AppStorage("reviewReminders")      private var reviewReminders      = false
    @AppStorage("newSalonAlerts")       private var newSalonAlerts       = true

    // Security
    @AppStorage("faceIDEnabled")        private var faceIDEnabled        = false
    @AppStorage("autoLockEnabled")      private var autoLockEnabled      = true

    // Privacy
    @AppStorage("analyticsEnabled")     private var analyticsEnabled     = true
    @AppStorage("locationEnabled")      private var locationEnabled      = true

    @State private var showDeleteAlert  = false
    @State private var showClearAlert   = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                appearanceSection
                notificationsSection
                securitySection
                privacySection
                aboutSection
                dangerSection

                Spacer().frame(height: 40)
            }
        }
        .background(Color(hex: "F7F7F7").ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { /* handle delete */ }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete your account and all data. This action cannot be undone.")
        }
        .alert("Clear All Bookings", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) { BookingStore.shared.bookings.removeAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all your booking history from this device.")
        }
    }

    // MARK: - Appearance Section
    private var appearanceSection: some View {
        settingsSection(title: "Appearance") {
            settingsToggle(
                icon: "moon.fill", iconBg: Color(hex: "3B3B6D"),
                label: "Dark Mode", subtitle: "Switch to dark interface",
                value: $darkModeEnabled
            )
            settingsDivider
            settingsToggle(
                icon: "circle.lefthalf.filled", iconBg: Color(hex: "4A4A8A"),
                label: "High Contrast", subtitle: "Improve readability",
                value: $highContrastEnabled
            )
            settingsDivider
            settingsToggle(
                icon: "textformat.size", iconBg: Color(hex: "5856D6"),
                label: "Larger Text", subtitle: "Increase text size throughout the app",
                value: $largeTextEnabled
            )
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        settingsSection(title: "Notifications") {
            settingsToggle(
                icon: "calendar.badge.clock", iconBg: Color(hex: "FF3B30"),
                label: "Booking Reminders",  subtitle: "Get reminded before appointments",
                value: $bookingReminders
            )
            settingsDivider
            settingsToggle(
                icon: "tag.fill", iconBg: Color(hex: "FF9500"),
                label: "Promotions & Offers", subtitle: "Exclusive deals and discounts",
                value: $promoNotifications
            )
            settingsDivider
            settingsToggle(
                icon: "star.fill", iconBg: Color(hex: "FFCC00"),
                label: "Review Reminders", subtitle: "Rate your experiences",
                value: $reviewReminders
            )
            settingsDivider
            settingsToggle(
                icon: "mappin.circle.fill", iconBg: Color(hex: "AF1C47"),
                label: "New Salons Nearby", subtitle: "Discover salons in your area",
                value: $newSalonAlerts
            )
        }
    }

    // MARK: - Security Section
    private var securitySection: some View {
        settingsSection(title: "Security") {
            settingsToggle(
                icon: "faceid", iconBg: Color(hex: "30D158"),
                label: "Face ID Login", subtitle: "Use Face ID to sign in",
                value: $faceIDEnabled
            )
            settingsDivider
            settingsToggle(
                icon: "lock.fill", iconBg: Color(hex: "8E8E93"),
                label: "Auto-Lock", subtitle: "Lock app when not in use",
                value: $autoLockEnabled
            )
            settingsDivider
            settingsLink(
                icon: "key.fill", iconBg: Color(hex: "AF1C47"),
                label: "Change Password", subtitle: "Update your account password"
            )
            settingsDivider
            settingsLink(
                icon: "shield.fill", iconBg: Color(hex: "007AFF"),
                label: "Two-Factor Authentication", subtitle: "Extra layer of security"
            )
        }
    }

    // MARK: - Privacy Section
    private var privacySection: some View {
        settingsSection(title: "Privacy") {
            settingsToggle(
                icon: "chart.bar.fill", iconBg: Color(hex: "34C759"),
                label: "Analytics", subtitle: "Help improve GLOWZA with usage data",
                value: $analyticsEnabled
            )
            settingsDivider
            settingsToggle(
                icon: "location.fill", iconBg: Color(hex: "AF1C47"),
                label: "Location Access", subtitle: "Find salons near you",
                value: $locationEnabled
            )
            settingsDivider
            settingsLink(
                icon: "hand.raised.fill", iconBg: Color(hex: "5AC8FA"),
                label: "Privacy Policy", subtitle: "How we handle your data"
            )
            settingsDivider
            settingsLink(
                icon: "doc.text.fill", iconBg: Color(hex: "4A90D9"),
                label: "Terms of Service", subtitle: "App usage terms and conditions"
            )
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        settingsSection(title: "About") {
            settingsInfoRow(icon: "info.circle.fill", iconBg: Color(hex: "007AFF"),
                            label: "App Version", value: "1.0.0 (Build 100)")
            settingsDivider
            settingsInfoRow(icon: "globe", iconBg: Color(hex: "34C759"),
                            label: "Region", value: "Sri Lanka")
            settingsDivider
            settingsLink(
                icon: "questionmark.circle.fill", iconBg: Color(hex: "FF9500"),
                label: "Help & Support", subtitle: "Get in touch with us"
            )
            settingsDivider
            settingsLink(
                icon: "exclamationmark.bubble.fill", iconBg: Color(hex: "FF3B30"),
                label: "Report a Problem", subtitle: "Let us know about issues"
            )
        }
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        settingsSection(title: "Data") {
            Button {
                showClearAlert = true
            } label: {
                settingsRowBase(
                    icon: "trash.fill", iconBg: Color(hex: "FF9500"),
                    label: "Clear Booking History",
                    subtitle: "Remove all local booking data"
                )
            }
            settingsDivider
            Button {
                showDeleteAlert = true
            } label: {
                HStack(spacing: 14) {
                    iconBadge(icon: "person.fill.xmark", bg: Color(hex: "FF3B30"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete Account")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "FF3B30"))
                        Text("Permanently remove your account")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "8A8A8A"))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Reusable Components

    private func settingsSection<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "ABABAB"))
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
        }
    }

    private func settingsToggle(icon: String, iconBg: Color, label: String, subtitle: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon: icon, bg: iconBg)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
            Toggle("", isOn: value)
                .labelsHidden()
                .tint(brand)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func settingsLink(icon: String, iconBg: Color, label: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon: icon, bg: iconBg)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "C7C7CC"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func settingsInfoRow(icon: String, iconBg: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon: icon, bg: iconBg)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "1A1A1A"))
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "8A8A8A"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func settingsRowBase(icon: String, iconBg: Color, label: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon: icon, bg: iconBg)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "1A1A1A"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "8A8A8A"))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "C7C7CC"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func iconBadge(icon: String, bg: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(bg)
                .frame(width: 36, height: 36)
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }

    private var settingsDivider: some View {
        Divider()
            .padding(.leading, 66)
    }
}
