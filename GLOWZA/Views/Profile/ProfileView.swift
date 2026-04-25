import SwiftUI
import PhotosUI

private let brand = Color(hex: "FF006E")

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    @State private var showEditProfileSheet = false
    @State private var showChangePasswordSheet = false
    @State private var showSecurityPrivacySheet = false
    @State private var showTermsSheet = false
    @State private var showUpdatesAlert = false

    @AppStorage("faceIDEnabled") private var isFaceIDEnabled = true
    @AppStorage("pushNotifications") private var pushNotificationsOn = true
    @AppStorage("voiceOverEnabled") private var voiceOverEnabled = true
    @AppStorage("highContrastEnabled") private var highContrastEnabled = true
    @AppStorage("darkModeEnabled") private var darkModeEnabled = true

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var passwordError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    sectionTitle("Account Settings")
                    actionRow(icon: "person", title: "Edit Profile", hasChevron: true) {
                        showEditProfileSheet = true
                    }
                    actionRow(icon: "lock", title: "Change Password", hasChevron: true) {
                        showChangePasswordSheet = true
                    }
                    NavigationLink(destination: TreatmentTrackingView()) {
                        rowView(icon: "clock.arrow.circlepath", title: "Treatment History", hasChevron: true)
                    }
                    .buttonStyle(.plain)

                    sectionTitle("Security & Privacy")
                    actionRow(icon: "shield", title: "Security & Privacy", hasChevron: true) {
                        showSecurityPrivacySheet = true
                    }
                    toggleRow(icon: "faceid", title: "Face ID", isOn: $isFaceIDEnabled)

                    sectionTitle("Notifications")
                    toggleRow(icon: "bell", title: "Push Notifications", isOn: $pushNotificationsOn)

                    sectionTitle("Accessibility")
                    toggleRow(icon: "mic", title: "VoiceOver Support", isOn: $voiceOverEnabled)
                    toggleRow(icon: "eye", title: "High Contrast Mode", isOn: $highContrastEnabled)
                    toggleRow(icon: "moon", title: "Dark Mode", isOn: $darkModeEnabled)

                    sectionTitle("General")
                    actionRow(icon: "gearshape", title: "App Updates", hasChevron: true) {
                        showUpdatesAlert = true
                    }
                    actionRow(icon: "doc.text", title: "Terms & Conditions", hasChevron: true) {
                        showTermsSheet = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(hex: "F1F1F1").ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showEditProfileSheet) {
            NavigationStack {
                editProfileSheet
                    .navigationTitle("Edit Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showEditProfileSheet = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                viewModel.saveProfile()
                                showEditProfileSheet = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showChangePasswordSheet) {
            NavigationStack {
                changePasswordSheet
                    .navigationTitle("Change Password")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Close") { showChangePasswordSheet = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Update") { updatePassword() }
                        }
                    }
            }
        }
        .sheet(isPresented: $showSecurityPrivacySheet) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showTermsSheet) {
            NavigationStack {
                termsSheet
                    .navigationTitle("Terms & Conditions")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showTermsSheet = false }
                        }
                    }
            }
        }
        .alert("App is up to date", isPresented: $showUpdatesAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You are using the latest version of GLOWZA.")
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            viewModel.loadPhotoFromPicker()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("My profile")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(brand)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)

            PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                Circle()
                    .stroke(brand, lineWidth: 2)
                    .frame(width: 132, height: 132)
                    .overlay {
                        if let avatar = viewModel.avatarImage {
                            avatar
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: "F7D4E1"))
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Text(initials(viewModel.fullName))
                                        .font(.system(size: 38, weight: .bold, design: .rounded))
                                        .foregroundColor(brand)
                                }
                        }
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(brand)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                    }
                    .padding(.top, 4)
            }
            .buttonStyle(.plain)

            Text(viewModel.fullName)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(Color(hex: "4B4E54"))
                .padding(.bottom, 8)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 36, weight: .semibold, design: .rounded))
            .foregroundColor(brand)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }

    private func actionRow(icon: String, title: String, hasChevron: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            rowView(icon: icon, title: title, hasChevron: hasChevron)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "585A61"))
                .frame(width: 24)
            Text(title)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "4D5057"))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(brand)
        }
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "E7E7EA")).frame(height: 1)
        }
    }

    private func rowView(icon: String, title: String, hasChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "585A61"))
                .frame(width: 24)
            Text(title)
                .font(.system(size: 30, weight: .regular, design: .rounded))
                .foregroundColor(Color(hex: "4D5057"))
            Spacer()
            if hasChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "A2A5AC"))
            }
        }
        .frame(height: 56)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color(hex: "E7E7EA")).frame(height: 1)
        }
    }

    private var editProfileSheet: some View {
        Form {
            Section("Profile Photo") {
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo.on.rectangle")
                }
            }
            Section("Profile Information") {
                TextField("Full Name", text: $viewModel.fullName)
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Phone", text: $viewModel.phone)
                    .keyboardType(.phonePad)
            }
            Section("Skin Type") {
                Picker("Skin Type", selection: $viewModel.skinType) {
                    ForEach(viewModel.skinTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
            }
        }
    }

    private var changePasswordSheet: some View {
        Form {
            Section("Security") {
                SecureField("Current Password", text: $currentPassword)
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm Password", text: $confirmPassword)
            }
            if let passwordError {
                Section {
                    Text(passwordError)
                        .foregroundColor(.red)
                }
            }
        }
    }

    private var termsSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("By using GLOWZA, you agree to book responsibly, provide accurate details, and follow salon policies.")
                Text("Cancellations and rescheduling may be subject to salon terms. Payment information is handled securely.")
                Text("Treatment outcomes vary by individual. Please consult professionals before any procedure.")
                Text("For support, contact our in-app help center.")
            }
            .font(.system(size: 15))
            .padding(20)
        }
    }

    private func updatePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            passwordError = "Please fill all password fields."
            return
        }
        guard newPassword == confirmPassword else {
            passwordError = "New password and confirmation do not match."
            return
        }
        guard newPassword.count >= 6 else {
            passwordError = "Password must be at least 6 characters."
            return
        }
        passwordError = nil
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        showChangePasswordSheet = false
    }

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined()
    }
}

#Preview { ProfileView() }
