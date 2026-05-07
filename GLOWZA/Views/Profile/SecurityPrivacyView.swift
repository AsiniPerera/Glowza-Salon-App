import SwiftUI

// MARK: - Security & Privacy View
struct SecurityPrivacyView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    @State private var twoFactorEnabled      = UserDefaults.standard.bool(forKey: "sec_2fa")
    @State private var loginNotifications    = UserDefaults.standard.bool(forKey: "sec_loginNotif")
    @State private var biometricLogin        = UserDefaults.standard.bool(forKey: "sec_biometric")
    @State private var dataSharing           = UserDefaults.standard.bool(forKey: "sec_dataSharing")
    @State private var showDataDeleteAlert   = false

    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Security section
                    settingsSection(title: "Security") {
                        toggleRow(icon: "key.horizontal",   label: "Two-Factor Authentication",
                                  subtitle: "Require a code on each login",
                                  value: $twoFactorEnabled) { UserDefaults.standard.set($0, forKey: "sec_2fa") }
                        toggleRow(icon: "bell.badge",       label: "Login Notifications",
                                  subtitle: "Alert when your account is accessed",
                                  value: $loginNotifications) { UserDefaults.standard.set($0, forKey: "sec_loginNotif") }
                        toggleRow(icon: "faceid",           label: "Biometric Login",
                                  subtitle: "Use Face ID or Touch ID",
                                  value: $biometricLogin) { UserDefaults.standard.set($0, forKey: "sec_biometric") }
                    }

                    // Privacy section
                    settingsSection(title: "Privacy") {
                        toggleRow(icon: "hand.raised",      label: "Data Sharing",
                                  subtitle: "Allow anonymised data to improve the app",
                                  value: $dataSharing) { UserDefaults.standard.set($0, forKey: "sec_dataSharing") }
                    }

                    // Danger zone
                    settingsSection(title: "Account") {
                        Button(action: { showDataDeleteAlert = true }) {
                            HStack(spacing: 14) {
                                Image(systemName: "trash")
                                    .glowzaFont(size: 17)
                                    .foregroundColor(.red)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Delete My Account")
                                        .glowzaFont(size: 16)
                                        .foregroundColor(.red)
                                    Text("This action cannot be undone")
                                        .glowzaFont(size: 12)
                                        .foregroundColor(Color(hex: "ABABAB"))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .glowzaFont(size: 13, weight: .medium)
                                    .foregroundColor(Color(hex: "C7C7CC"))
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 60)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("Security & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.foregroundColor(accent)
                }
            }
            .alert("Delete Account", isPresented: $showDataDeleteAlert) {
                Button("Delete", role: .destructive) {}
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete your account and all data? This cannot be undone.")
            }
        }
    }

    // MARK: - Section Container
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .glowzaFont(size: 13, weight: .semibold)
                .foregroundColor(Color(hex: "8A8D94"))
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content()
            }
            .background(surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Toggle Row (with subtitle and save callback)
    private func toggleRow(icon: String, label: String, subtitle: String,
                            value: Binding<Bool>, onChange: @escaping (Bool) -> Void) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .glowzaFont(size: 17)
                .foregroundColor(Color(hex: "6B6E77"))
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .glowzaFont(size: 16)
                    .foregroundColor(dark)
                Text(subtitle)
                    .glowzaFont(size: 12)
                    .foregroundColor(Color(hex: "ABABAB"))
            }
            Spacer()
            Toggle("", isOn: value)
                .tint(accent)
                .labelsHidden()
                .onChange(of: value.wrappedValue) { onChange($0) }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 60)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "E8E8EC")).frame(height: 0.5).padding(.leading, 58)
        }
    }
}
