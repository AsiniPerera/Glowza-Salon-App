import SwiftUI
import PhotosUI

// MARK: - Edit Profile View
struct EditProfileView: View {

    @Binding var displayName: String
    @Binding var avatarData: Data?
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSettings.self) private var appSettings

    @State private var name: String    = ""
    @State private var email: String   = ""
    @State private var phone: String   = ""
    @State private var dob: String     = ""
    @State private var skinType: String = ""
    @State private var showPhotoPicker  = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showSavedBanner  = false
    @State private var isSavingAvatar   = false   // shows spinner while uploading avatar
    @State private var nameError: String? = nil

    private let skinTypes = ["Normal", "Oily", "Dry", "Combination", "Sensitive"]
    private var accent: Color { appSettings.themeBrand }
    private var dark: Color { appSettings.themeText }
    private var pageBackground: Color { appSettings.themePage }
    private var surfaceBackground: Color { appSettings.themeSurface }
    private var chipBackground: Color { appSettings.isDarkMode ? Color(hex: "2A2A2A") : Color(hex: "EDEDED") }

    private var avatarImage: UIImage? {
        guard let data = avatarData else { return nil }
        return UIImage(data: data)
    }

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap { $0.first?.uppercased() }.joined()
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                pageBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Avatar picker
                        Button(action: { showPhotoPicker = true }) {
                            ZStack(alignment: .bottomTrailing) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(accent, lineWidth: 3)
                                        .frame(width: 100, height: 100)
                                    if let ui = avatarImage {
                                        Image(uiImage: ui)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 94, height: 94)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(accent.opacity(0.12))
                                            .frame(width: 94, height: 94)
                                        Text(initials)
                                            .glowzaFont(size: 18, weight: .semibold)
                                            .foregroundColor(accent)
                                    }
                                }
                                ZStack {
                                    Circle().fill(accent).frame(width: 28, height: 28)
                                    Image(systemName: "camera.fill")
                                        .glowzaFont(size: 12, weight: .semibold)
                                        .foregroundColor(.white)
                                }
                                .offset(x: 4, y: 4)

                                // Saving indicator while avatar uploads
                                if isSavingAvatar {
                                    ProgressView()
                                        .tint(accent)
                                        .frame(width: 20, height: 20)
                                        .offset(x: 4, y: 4)
                                }
                            }
                        }
                        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
                        .onChange(of: selectedPhoto) { _, item in
                            Task {
                                guard let item else { return }
                                isSavingAvatar = true
                                do {
                                    if let raw = try await item.loadTransferable(type: Data.self),
                                       let uiImage = UIImage(data: raw),
                                       let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                                        await MainActor.run {
                                            avatarData = compressed
                                            UserDefaults.standard.set(compressed, forKey: "profile_avatarData")
                                        }
                                        try await AuthService.shared.updateProfileAvatarData(compressed)
                                        NotificationCenter.default.post(name: .glowzaProfileUpdated, object: nil)
                                        print("✅ Avatar saved to Firestore")
                                    }
                                } catch {
                                    print("❌ Avatar upload failed: \(error)")
                                }
                                await MainActor.run { isSavingAvatar = false }
                            }
                        }
                        .padding(.top, 8)

                        // Form fields
                        VStack(spacing: 0) {
                            formField(icon: "person", label: "Full Name", content:
                                AnyView(
                                    TextField("Your name", text: $name)
                                        .glowzaFont(size: 15)
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "envelope", label: "Email", content:
                                AnyView(
                                    TextField("Email address", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .glowzaFont(size: 15)
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "phone", label: "Phone", content:
                                AnyView(
                                    TextField("Phone number", text: $phone)
                                        .keyboardType(.phonePad)
                                        .glowzaFont(size: 15)
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "calendar", label: "Date of Birth", content:
                                AnyView(
                                    TextField("e.g. 1998-06-15", text: $dob)
                                        .glowzaFont(size: 15)
                                        .foregroundColor(dark)
                                )
                            )

                            // Skin type picker
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "drop")
                                        .glowzaFont(size: 17)
                                        .foregroundColor(Color(hex: "6B6E77"))
                                        .frame(width: 28)
                                    Text("Skin Type")
                                        .glowzaFont(size: 13)
                                        .foregroundColor(Color(hex: "8A8D94"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(skinTypes, id: \.self) { type in
                                            Button(action: { skinType = type }) {
                                                Text(type)
                                                    .glowzaFont(size: 13, weight: skinType == type ? .semibold : .regular)
                                                    .foregroundColor(skinType == type ? .white : dark)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(skinType == type ? accent : chipBackground)
                                                    .clipShape(Capsule())
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .padding(.bottom, 14)

                                Rectangle().fill(Color(hex: "E8E8EC")).frame(height: 0.5)
                                    .padding(.leading, 16)
                            }
                        }
                        .background(surfaceBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    appSettings.isHighContrast ? Color.white.opacity(0.85) : Color.clear,
                                    lineWidth: appSettings.isHighContrast ? 3 : 0
                                )
                        )
                        if let err = nameError {
                            Text(err)
                                .glowzaFont(size: 13)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        // Save button
                        Button(action: saveProfile) {
                            Text("Save Changes")
                                .glowzaFont(size: 15, weight: .semibold)
                                .foregroundColor(.white)
                                .frame(width: 330, height: 55)
                                .background(accent)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }

                // Saved banner
                if showSavedBanner {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Profile saved!")
                        }
                        .glowzaFont(size: 14, weight: .semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "1F2126").opacity(0.9))
                        .clipShape(Capsule())
                        .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .glowzaFont(size: 16, weight: .medium)
                        .foregroundColor(accent)
                    }
                    .fixedSize()
                }
            }
        }
        .onAppear { loadSaved() }
    }

    private func formField(icon: String, label: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .glowzaFont(size: 17)
                    .foregroundColor(Color(hex: "6B6E77"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .glowzaFont(size: 12)
                        .foregroundColor(Color(hex: "8A8D94"))
                    content
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            Rectangle().fill(Color(hex: "E8E8EC")).frame(height: 0.5).padding(.leading, 56)
        }
    }

    private func loadSaved() {
        // Priority 1: live data from AuthService (populated from Firestore after login)
        let auth = AuthService.shared
        if let profile = auth.currentUserProfile {
            name     = profile.fullName
            email    = profile.email
            phone    = profile.phone
            skinType = profile.skinType.isEmpty ? "Normal" : profile.skinType
            dob      = UserDefaults.standard.string(forKey: "profile_dob") ?? ""
            return
        }
        // Priority 2: locally cached UserDefaults (fast offline fallback)
        name     = UserDefaults.standard.string(forKey: "profile_fullName") ?? ""
        email    = UserDefaults.standard.string(forKey: "profile_email")    ?? ""
        phone    = UserDefaults.standard.string(forKey: "profile_phone")    ?? ""
        dob      = UserDefaults.standard.string(forKey: "profile_dob")      ?? ""
        skinType = UserDefaults.standard.string(forKey: "profile_skinType") ?? "Normal"
    }

    private func saveProfile() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { nameError = "Name cannot be empty"; return }
        nameError = nil

        // 1. Save to UserDefaults immediately (offline-safe)
        UserDefaults.standard.set(trimmed,   forKey: "profile_fullName")
        UserDefaults.standard.set(email,     forKey: "profile_email")
        UserDefaults.standard.set(phone,     forKey: "profile_phone")
        UserDefaults.standard.set(dob,       forKey: "profile_dob")
        UserDefaults.standard.set(skinType,  forKey: "profile_skinType")

        // 2. Update parent binding immediately so ProfileView name updates
        displayName = trimmed

        // 3. Save to Firestore `users` + `userProfiles` collections
        Task {
            do {
                try await AuthService.shared.updateUserProfile(
                    fullName: trimmed,
                    email: email,
                    phone: phone,
                    skinType: skinType,
                    dateOfBirth: dob.isEmpty ? nil : dob
                )
                print("✅ Profile saved to Firestore")
            } catch {
                print("❌ Profile save failed: \(error)")
            }
        }

        NotificationCenter.default.post(name: .glowzaProfileUpdated, object: nil)
        withAnimation { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedBanner = false }
            dismiss()
        }
    }
}
