import SwiftUI
import PhotosUI

// MARK: - Profile View Model
@Observable
final class ProfileViewModel {

    // MARK: Stored fields (persisted via UserDefaults)
    var fullName: String       = UserDefaults.standard.string(forKey: "profile_fullName")    ?? "Asini Perera"
    var email: String          = UserDefaults.standard.string(forKey: "profile_email")       ?? "asini@example.com"
    var phone: String          = UserDefaults.standard.string(forKey: "profile_phone")       ?? "+94 77 123 4567"
    var dateOfBirth: String    = UserDefaults.standard.string(forKey: "profile_dob")         ?? "1998-06-15"
    var skinType: String       = UserDefaults.standard.string(forKey: "profile_skinType")    ?? "Combination"
    var loyaltyPoints: Int     = UserDefaults.standard.integer(forKey: "profile_loyalty")

    // Photo stored as JPEG data
    var avatarData: Data?      = UserDefaults.standard.data(forKey: "profile_avatarData")

    // MARK: UI State
    var isEditing: Bool        = false
    var isSaving: Bool         = false
    var showSavedBanner: Bool  = false
    var showPhotoPicker: Bool  = false
    var selectedPhotoItem: PhotosPickerItem? = nil
    var validationError: String? = nil

    // Skin-type options
    let skinTypes = ["Normal", "Oily", "Dry", "Combination", "Sensitive"]

    // MARK: - Computed
    var avatarImage: Image? {
        guard let data = avatarData, let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first?.uppercased() }
        return letters.joined()
    }

    // MARK: - Actions
    func startEditing() { isEditing = true }

    func cancelEditing() {
        // Re-load from storage to discard unsaved changes
        fullName    = UserDefaults.standard.string(forKey: "profile_fullName")    ?? fullName
        email       = UserDefaults.standard.string(forKey: "profile_email")       ?? email
        phone       = UserDefaults.standard.string(forKey: "profile_phone")       ?? phone
        dateOfBirth = UserDefaults.standard.string(forKey: "profile_dob")         ?? dateOfBirth
        skinType    = UserDefaults.standard.string(forKey: "profile_skinType")    ?? skinType
        validationError = nil
        isEditing = false
    }

    func saveProfile() {
        guard validate() else { return }

        isSaving = true

        // Simulate a brief save delay for UX polish
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            UserDefaults.standard.set(fullName,    forKey: "profile_fullName")
            UserDefaults.standard.set(email,       forKey: "profile_email")
            UserDefaults.standard.set(phone,       forKey: "profile_phone")
            UserDefaults.standard.set(dateOfBirth, forKey: "profile_dob")
            UserDefaults.standard.set(skinType,    forKey: "profile_skinType")
            if let data = avatarData {
                UserDefaults.standard.set(data, forKey: "profile_avatarData")
            }

            // Persist to Firestore
            Task {
                try? await AuthService.shared.updateUserProfile(
                    fullName: fullName,
                    email: email,
                    phone: phone,
                    skinType: skinType,
                    dateOfBirth: dateOfBirth
                )
            }

            isSaving = false
            isEditing = false
            withAnimation { showSavedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                withAnimation { showSavedBanner = false }
            }
        }
    }

    func loadPhotoFromPicker() {
        guard let item = selectedPhotoItem else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    avatarData = data
                    UserDefaults.standard.set(data, forKey: "profile_avatarData")
                }
            }
        }
    }

    // MARK: - Validation
    private func validate() -> Bool {
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError = "Name cannot be empty."
            return false
        }
        let emailRegex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            validationError = "Please enter a valid email address."
            return false
        }
        validationError = nil
        return true
    }
}
