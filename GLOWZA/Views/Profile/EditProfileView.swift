import SwiftUI
import PhotosUI

// MARK: - Edit Profile View
struct EditProfileView: View {

    @Binding var displayName: String
    @Binding var avatarData: Data?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String    = ""
    @State private var email: String   = ""
    @State private var phone: String   = ""
    @State private var dob: String     = ""
    @State private var skinType: String = ""
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var showSavedBanner = false
    @State private var nameError: String? = nil

    private let skinTypes = ["Normal", "Oily", "Dry", "Combination", "Sensitive"]
    private let accent = Color(hex: "962043")
    private let dark = Color(hex: "1F2126")

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
                Color(hex: "F2F2F7").ignoresSafeArea()

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
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(accent)
                                    }
                                }
                                ZStack {
                                    Circle().fill(accent).frame(width: 28, height: 28)
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 4, y: 4)
                            }
                        }
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
                        .padding(.top, 8)

                        // Form fields
                        VStack(spacing: 0) {
                            formField(icon: "person", label: "Full Name", content:
                                AnyView(
                                    TextField("Your name", text: $name)
                                        .font(.system(size: 15))
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "envelope", label: "Email", content:
                                AnyView(
                                    TextField("Email address", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .font(.system(size: 15))
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "phone", label: "Phone", content:
                                AnyView(
                                    TextField("Phone number", text: $phone)
                                        .keyboardType(.phonePad)
                                        .font(.system(size: 15))
                                        .foregroundColor(dark)
                                )
                            )
                            formField(icon: "calendar", label: "Date of Birth", content:
                                AnyView(
                                    TextField("e.g. 1998-06-15", text: $dob)
                                        .font(.system(size: 15))
                                        .foregroundColor(dark)
                                )
                            )

                            // Skin type picker
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "drop")
                                        .font(.system(size: 17))
                                        .foregroundColor(Color(hex: "6B6E77"))
                                        .frame(width: 28)
                                    Text("Skin Type")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "8A8D94"))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 14)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(skinTypes, id: \.self) { type in
                                            Button(action: { skinType = type }) {
                                                Text(type)
                                                    .font(.system(size: 13, weight: skinType == type ? .semibold : .regular))
                                                    .foregroundColor(skinType == type ? .white : dark)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(skinType == type ? accent : Color(hex: "EDEDED"))
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
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        // Error message
                        if let err = nameError {
                            Text(err)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                        }

                        // Save button
                        Button(action: saveProfile) {
                            Text("Save Changes")
                                .font(.system(size: 15, weight: .semibold))
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
                        .font(.system(size: 14, weight: .semibold))
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(accent)
                }
            }
        }
        .onAppear { loadSaved() }
    }

    private func formField(icon: String, label: String, content: AnyView) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: "6B6E77"))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12))
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
        name     = UserDefaults.standard.string(forKey: "profile_fullName") ?? "Asini Perera"
        email    = UserDefaults.standard.string(forKey: "profile_email")    ?? ""
        phone    = UserDefaults.standard.string(forKey: "profile_phone")    ?? ""
        dob      = UserDefaults.standard.string(forKey: "profile_dob")      ?? ""
        skinType = UserDefaults.standard.string(forKey: "profile_skinType") ?? "Combination"
    }

    private func saveProfile() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { nameError = "Name cannot be empty"; return }
        nameError = nil
        UserDefaults.standard.set(trimmed,   forKey: "profile_fullName")
        UserDefaults.standard.set(email,     forKey: "profile_email")
        UserDefaults.standard.set(phone,     forKey: "profile_phone")
        UserDefaults.standard.set(dob,       forKey: "profile_dob")
        UserDefaults.standard.set(skinType,  forKey: "profile_skinType")
        displayName = trimmed
        withAnimation { showSavedBanner = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedBanner = false }
            dismiss()
        }
    }
}
