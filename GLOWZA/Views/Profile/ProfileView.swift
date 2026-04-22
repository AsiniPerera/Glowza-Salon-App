import SwiftUI

// MARK: - Color Hex Helper
func colorFromHex(_ hex: String) -> Color {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default: (a, r, g, b) = (255, 0, 0, 0)
    }
    return Color(
        .sRGB,
        red: Double(r) / 255,
        green: Double(g) / 255,
        blue: Double(b) / 255,
        opacity: Double(a) / 255
    )
}

// MARK: - ProfileView (iOS Settings Style)
struct ProfileView: View {
    @State private var showSignOutAlert = false
    @State private var showEditProfileSection = false
    @State private var showPasswordSection = false
    @State private var showSecuritySection = false
    
    @State private var isFaceIDEnabled = false
    @State private var isVoiceOverEnabled = false
    @State private var isDarkModeEnabled = false
    @State private var isContrastModeEnabled = false
    
    @State private var editFullName = "Asini Perera"
    @State private var editEmail = "asini.perera@email.com"
    @State private var editPhone = "+94 71 234 5678"
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var twoFactorEnabled = true
    @State private var loginNotificationsEnabled = true
    
    let goldColor = colorFromHex("E5A820")
    let goldDarkColor = colorFromHex("C8860A")
    let lightBg = colorFromHex("F5F0E8")
    let darkBg = colorFromHex("1A1A1A")
    let lightCard = Color.white
    let darkCard = colorFromHex("2D2D2D")
    let lightText = colorFromHex("1A1A1A")
    let darkText = colorFromHex("F5F0E8")
    let lightSubtext = colorFromHex("8A8A8A")
    let darkSubtext = colorFromHex("C0C0C0")
    let errorColor = colorFromHex("F44336")
    
    var backgroundColor: Color { isDarkModeEnabled ? darkBg : lightBg }
    var cardBackground: Color { isDarkModeEnabled ? darkCard : lightCard }
    var textPrimary: Color { isDarkModeEnabled ? darkText : lightText }
    var textSecondary: Color { isDarkModeEnabled ? darkSubtext : lightSubtext }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: - Profile Header
                        profileHeaderSection
                            .padding(.vertical, 24)
                        
                        // MARK: - Edit Profile Section
                        editProfileSection
                            .padding(.bottom, 20)
                        
                        // MARK: - Change Password Section
                        changePasswordSection
                            .padding(.bottom, 20)
                        
                        // MARK: - Security Section
                        securitySection
                            .padding(.bottom, 20)
                        
                        // MARK: - Face ID Toggle Section
                        faceIDSection
                            .padding(.bottom, 20)
                        
                        // MARK: - Accessibility
                        accessibilitySection
                            .padding(.bottom, 20)
                        
                        // MARK: - General
                        generalSection
                            .padding(.bottom, 20)
                        
                        // MARK: - Sign Out Button
                        VStack(spacing: 0) {
                            Button(action: { showSignOutAlert = true }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(errorColor)
                                        .frame(width: 32, height: 32)
                                        .background(errorColor.opacity(0.12))
                                        .cornerRadius(8)
                                    
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(errorColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .padding(16)
                                .contentShape(Rectangle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Profile")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textPrimary)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) {
                    NotificationCenter.default.post(name: .glowzaSignOut, object: nil)
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out of your account?")
            }
        }
    }
    
    // MARK: - Edit Profile Section
    private var editProfileSection: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { showEditProfileSection.toggle() } }) {
                HStack(spacing: 16) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit Profile")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textPrimary)
                        Text("Update your profile information")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showEditProfileSection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)
                }
                .padding(16)
            }
            
            if showEditProfileSection {
                Divider().padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    textInputField("Full Name", text: $editFullName)
                    textInputField("Email", text: $editEmail)
                    textInputField("Phone", text: $editPhone)
                    
                    Button(action: {}) {
                        Text("Save Profile")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(goldColor)
                            .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Change Password Section
    private var changePasswordSection: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { showPasswordSection.toggle() } }) {
                HStack(spacing: 16) {
                    Image(systemName: "key.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Change Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textPrimary)
                        Text("Update your account password")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showPasswordSection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)
                }
                .padding(16)
            }
            
            if showPasswordSection {
                Divider().padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    secureInputField("Current Password", text: $currentPassword)
                    secureInputField("New Password", text: $newPassword)
                    secureInputField("Confirm Password", text: $confirmPassword)
                    
                    Button(action: {}) {
                        Text("Update Password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(goldColor)
                            .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { showSecuritySection.toggle() } }) {
                HStack(spacing: 16) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Security Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textPrimary)
                        Text("Manage your security preferences")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showSecuritySection ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(textSecondary)
                }
                .padding(16)
            }
            
            if showSecuritySection {
                Divider().padding(.horizontal, 20)
                
                VStack(spacing: 16) {
                    toggleRow("Two-Factor Authentication", isOn: $twoFactorEnabled)
                    toggleRow("Login Notifications", isOn: $loginNotificationsEnabled)
                }
                .padding(16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Face ID Section
    private var faceIDSection: some View {
        VStack(spacing: 0) {
            Text("Authentication")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Image(systemName: "faceid")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Face ID")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(textPrimary)
                        Text("Use Face ID to unlock your account")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isFaceIDEnabled)
                        .tint(goldColor)
                }
                .padding(16)
            }
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Accessibility Section
    private var accessibilitySection: some View {
        VStack(spacing: 0) {
            Text("Accessibility")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            VStack(spacing: 0) {
                // VoiceOver Support
                HStack(spacing: 16) {
                    Image(systemName: "speaker.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VoiceOver Support")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(textPrimary)
                        Text("Enable voice navigation and audio descriptions")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isVoiceOverEnabled)
                        .tint(goldColor)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // High Contrast Mode
                HStack(spacing: 16) {
                    Image(systemName: "sun.max.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("High Contrast Mode")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(textPrimary)
                        Text("Enhance visual contrast for better visibility")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isContrastModeEnabled)
                        .tint(goldColor)
                }
                .padding(16)
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Dark Mode
                HStack(spacing: 16) {
                    Image(systemName: "moon.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goldDarkColor)
                        .frame(width: 32, height: 32)
                        .background(goldColor.opacity(0.12))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dark Mode")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(textPrimary)
                        Text("Reduce eye strain with a dark theme")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isDarkModeEnabled)
                        .tint(goldColor)
                }
                .padding(16)
            }
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - General Section
    private var generalSection: some View {
        VStack(spacing: 0) {
            Text("General")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            
            VStack(spacing: 0) {
                Button(action: {}) {
                    HStack(spacing: 16) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(goldDarkColor)
                            .frame(width: 32, height: 32)
                            .background(goldColor.opacity(0.12))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("App Updates")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(textPrimary)
                            Text("Check for new app versions")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textSecondary)
                    }
                    .padding(16)
                }
                
                Divider().padding(.horizontal, 20)
                
                Button(action: {}) {
                    HStack(spacing: 16) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(goldDarkColor)
                            .frame(width: 32, height: 32)
                            .background(goldColor.opacity(0.12))
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Terms & Conditions")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(textPrimary)
                            Text("Review our terms of service")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(textSecondary)
                    }
                    .padding(16)
                }
            }
            .background(cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Helper: Text Input Field
    private func textInputField(_ label: String, text: Binding<String>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textSecondary)
                Spacer()
            }
            TextField("", text: text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(textPrimary)
                .padding(12)
                .background(isDarkModeEnabled ? colorFromHex("3D3D3D") : colorFromHex("F5F5F5"))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Helper: Secure Input Field
    private func secureInputField(_ label: String, text: Binding<String>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textSecondary)
                Spacer()
            }
            SecureField("", text: text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(textPrimary)
                .padding(12)
                .background(isDarkModeEnabled ? colorFromHex("3D3D3D") : colorFromHex("F5F5F5"))
                .cornerRadius(8)
        }
    }
    
    // MARK: - Helper: Toggle Row
    private func toggleRow(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(textPrimary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .tint(goldColor)
        }
    }
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [goldColor.opacity(0.2), goldColor.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(goldDarkColor)
            }
            
            // Name
            Text("Asini Perera")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(textPrimary)
            
            // Email
            Text("asini.perera@email.com")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }
}

// MARK: - Sign Out Notification
extension Notification.Name {
    static let glowzaSignOut = Notification.Name("GlowzaSignOut")
}

#Preview {
    ProfileView()
}
