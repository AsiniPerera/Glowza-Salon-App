import SwiftUI

private let brand = Color(hex: "AF1C47")

// MARK: - Profile View
struct ProfileView: View {

    @State private var showSignOutAlert = false
    @State private var showEditProfile  = false
    @State private var showPassword     = false
    @State private var showSecurity     = false

    @State private var isFaceIDEnabled        = false
    @State private var loginNotificationsOn   = true
    @State private var twoFactorEnabled       = true

    @State private var editFullName = "Asini Perera"
    @State private var editEmail    = "asini.perera@email.com"
    @State private var editPhone    = "+94 71 234 5678"

    @State private var currentPassword = ""
    @State private var newPassword     = ""
    @State private var confirmPassword = ""

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    profileHeader
                    statsRow.padding(.top, 20)
                    sectionGroup(title: "Account") {
                        expandableRow(
                            icon: "person.fill", label: "Edit Profile",
                            isExpanded: $showEditProfile,
                            content: editProfileContent
                        )
                        expandableRow(
                            icon: "lock.fill", label: "Change Password",
                            isExpanded: $showPassword,
                            content: changePasswordContent
                        )
                        expandableRow(
                            icon: "shield.fill", label: "Security",
                            isExpanded: $showSecurity,
                            content: securityContent
                        )
                    }
                    sectionGroup(title: "Preferences") {
                        toggleRow(icon: "faceid",        label: "Face ID Login",      value: $isFaceIDEnabled)
                        toggleRow(icon: "bell.fill",     label: "Login Notifications", value: $loginNotificationsOn)
                    }
                    sectionGroup(title: "My Activity") {
                        navLinkRow(icon: "heart.fill",       label: "Favourites",          destination: FavoritesView())
                        navLinkRow(icon: "chart.xyaxis.line", label: "Treatment Tracking",  destination: TreatmentTrackingView())
                    }
                    sectionGroup(title: "App") {
                        navLinkRow(icon: "gearshape.fill",   label: "Settings",            destination: SettingsView())
                    }
                    sectionGroup(title: "Support") {
                        linkRow(icon: "questionmark.circle.fill", label: "Help Center")
                        linkRow(icon: "doc.text.fill",            label: "Terms & Conditions")
                        linkRow(icon: "hand.raised.fill",         label: "Privacy Policy")
                    }
                    signOutButton.padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
                }
            }
            .background(Color(hex: "F7F7F7").ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Sign Out", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    // MARK: - Header
    private var profileHeader: some View {
        ZStack(alignment: .bottom) {
            brand.frame(height: 160)
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 90, height: 90)
                        .shadow(color: brand.opacity(0.2), radius: 12)
                    Text(initials(editFullName))
                        .font(.system(size: 30, weight: .bold)).foregroundColor(brand)
                }
                .offset(y: 45)
            }
        }
        .padding(.bottom, 60)
        .overlay(alignment: .topTrailing) {
            Button(action: { showEditProfile.toggle() }) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding(.top, 16).padding(.trailing, 20)
        }
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map { String($0) }.joined()
    }

    // MARK: - Name/email below avatar
    private var statsRow: some View {
        VStack(spacing: 4) {
            Text(editFullName)
                .font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: "1A1A1A"))
            Text(editEmail)
                .font(.system(size: 13)).foregroundColor(Color(hex: "8A8A8A"))
            HStack(spacing: 20) {
                statItem(value: "\(BookingStore.shared.bookings.count)", label: "Bookings")
                statDivider
                statItem(value: "\(BookingStore.shared.bookings.filter { $0.review != nil }.count)", label: "Reviews")
                statDivider
                statItem(value: "GLOWZA", label: "Member")
            }
            .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .bold)).foregroundColor(brand)
            Text(label).font(.system(size: 11)).foregroundColor(Color(hex: "8A8A8A"))
        }
    }

    private var statDivider: some View {
        Rectangle().fill(Color(hex: "EBEBEB")).frame(width: 1, height: 30)
    }

    // MARK: - Section Group
    private func sectionGroup<C: View>(title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold)).foregroundColor(Color(hex: "ABABAB"))
                .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 8)
            VStack(spacing: 0) { content() }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Expandable Row
    private func expandableRow<C: View>(
        icon: String, label: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> C
    ) -> some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.wrappedValue.toggle() } }) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(brand.opacity(0.10)).frame(width: 36, height: 36)
                        Image(systemName: icon).font(.system(size: 14)).foregroundColor(brand)
                    }
                    Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "1A1A1A"))
                    Spacer()
                    Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "ABABAB"))
                }
                .padding(.horizontal, 16).frame(height: 56)
            }
            .buttonStyle(.plain)

            if isExpanded.wrappedValue {
                Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 16)
                content().padding(.horizontal, 16).padding(.vertical, 16)
            }
            Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 16)
        }
    }

    // MARK: - Toggle Row
    @ViewBuilder
    private func toggleRow(icon: String, label: String, value: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(brand.opacity(0.10)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(brand)
            }
            Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "1A1A1A"))
            Spacer()
            Toggle("", isOn: value).tint(brand).labelsHidden()
        }
        .padding(.horizontal, 16).frame(height: 56)
        Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 16)
    }

    // MARK: - Link Row
    @ViewBuilder
    private func linkRow(icon: String, label: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color(hex: "F5F5F5")).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(Color(hex: "6B6B6B"))
                }
                Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "1A1A1A"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "CCCCCC"))
            }
            .padding(.horizontal, 16).frame(height: 56)
        }
        .buttonStyle(.plain)
        Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 16)
    }

    // MARK: - Navigation Link Row
    @ViewBuilder
    private func navLinkRow<D: View>(icon: String, label: String, destination: D) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(brand.opacity(0.10)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(brand)
                }
                Text(label).font(.system(size: 15)).foregroundColor(Color(hex: "1A1A1A"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Color(hex: "CCCCCC"))
            }
            .padding(.horizontal, 16).frame(height: 56)
        }
        .buttonStyle(.plain)
        Rectangle().fill(Color(hex: "F0F0F0")).frame(height: 1).padding(.horizontal, 16)
    }

    // MARK: - Edit Profile Content
    @ViewBuilder
    private func editProfileContent() -> some View {
        VStack(spacing: 14) {
            profileField(icon: "person.fill", placeholder: "Full Name", text: $editFullName)
            profileField(icon: "envelope.fill", placeholder: "Email", text: $editEmail, keyboard: .emailAddress)
            profileField(icon: "phone.fill", placeholder: "Phone", text: $editPhone, keyboard: .phonePad)
            Button(action: {}) {
                Text("Save Changes")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(brand)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func profileField(icon: String, placeholder: String,
                               text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(brand).frame(width: 20)
            TextField(placeholder, text: text).keyboardType(keyboard)
                .font(.system(size: 14)).foregroundColor(Color(hex: "1A1A1A"))
        }
        .padding(12)
        .background(Color(hex: "F5F5F5"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Change Password Content
    @ViewBuilder
    private func changePasswordContent() -> some View {
        VStack(spacing: 14) {
            secureField(placeholder: "Current Password", text: $currentPassword)
            secureField(placeholder: "New Password", text: $newPassword)
            secureField(placeholder: "Confirm New Password", text: $confirmPassword)
            if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords do not match")
                    .font(.system(size: 12)).foregroundColor(Color(hex: "D9534F"))
            }
            Button(action: {}) {
                Text("Update Password")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(newPassword == confirmPassword && !newPassword.isEmpty
                                ? brand : Color(hex: "CCCCCC"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(newPassword.isEmpty || newPassword != confirmPassword)
        }
    }

    private func secureField(placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.system(size: 14)).foregroundColor(Color(hex: "1A1A1A"))
            .padding(12)
            .background(Color(hex: "F5F5F5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Security Content
    @ViewBuilder
    private func securityContent() -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Two-Factor Authentication")
                        .font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "1A1A1A"))
                    Text("Add an extra layer of security")
                        .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
                Toggle("", isOn: $twoFactorEnabled).tint(brand).labelsHidden()
            }
            .padding(12)
            .background(Color(hex: "F5F5F5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Login Notifications")
                        .font(.system(size: 14, weight: .medium)).foregroundColor(Color(hex: "1A1A1A"))
                    Text("Get alerts for new logins")
                        .font(.system(size: 12)).foregroundColor(Color(hex: "8A8A8A"))
                }
                Spacer()
                Toggle("", isOn: $loginNotificationsOn).tint(brand).labelsHidden()
            }
            .padding(12)
            .background(Color(hex: "F5F5F5"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Sign Out
    private var signOutButton: some View {
        Button(action: { showSignOutAlert = true }) {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14))
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(Color(hex: "D9534F"))
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Color(hex: "D9534F").opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "D9534F").opacity(0.2), lineWidth: 1))
        }
    }
}

#Preview { ProfileView() }
