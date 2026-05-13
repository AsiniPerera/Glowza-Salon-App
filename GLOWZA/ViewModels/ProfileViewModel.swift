import SwiftUI
import PhotosUI

// MARK: - Profile View Model
// This class manages the state for the User Profile screen!
// It uses the newer @Observable macro for clean state management.
// It persists profile data locally in UserDefaults and syncs it with Firestore.
@Observable
final class ProfileViewModel {

    // MARK: Stored fields (persisted via UserDefaults)
    // We use fallback values if nothing is stored yet!
    var fullName: String       = UserDefaults.standard.string(forKey: "profile_fullName")    ?? "Asini Perera"
    var email: String          = UserDefaults.standard.string(forKey: "profile_email")       ?? "asini@example.com"
    var phone: String          = UserDefaults.standard.string(forKey: "profile_phone")       ?? "+94 77 123 4567"
    var dateOfBirth: String    = UserDefaults.standard.string(forKey: "profile_dob")         ?? "1998-06-15"
    var skinType: String       = UserDefaults.standard.string(forKey: "profile_skinType")    ?? "Combination"
    var loyaltyPoints: Int     = UserDefaults.standard.integer(forKey: "profile_loyalty")

    // Photo stored as JPEG data!
    var avatarData: Data?      = UserDefaults.standard.data(forKey: "profile_avatarData")

    // MARK: UI State
    var isEditing: Bool        = false
    var isSaving: Bool         = false
    var showSavedBanner: Bool  = false
    var showPhotoPicker: Bool  = false
    var selectedPhotoItem: PhotosPickerItem? = nil
    var validationError: String? = nil

    // Skin-type options!
    let skinTypes = ["Normal", "Oily", "Dry", "Combination", "Sensitive"]

    // MARK: - Computed Properties
    
    // Converts the stored Data back into a SwiftUI Image!
    var avatarImage: Image? {
        guard let data = avatarData, let ui = UIImage(data: data) else { return nil }
        return Image(uiImage: ui)
    }

    // Generates initials from the full name (e.g. "Asini Perera" -> "AP")!
    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first?.uppercased() }
        return letters.joined()
    }

    // MARK: - Actions
    
    func startEditing() { isEditing = true }

    func cancelEditing() {
        // Re-load from storage to discard unsaved changes!
        fullName    = UserDefaults.standard.string(forKey: "profile_fullName")    ?? fullName
        email       = UserDefaults.standard.string(forKey: "profile_email")       ?? email
        phone       = UserDefaults.standard.string(forKey: "profile_phone")       ?? phone
        dateOfBirth = UserDefaults.standard.string(forKey: "profile_dob")         ?? dateOfBirth
        skinType    = UserDefaults.standard.string(forKey: "profile_skinType")    ?? skinType
        validationError = nil
        isEditing = false
    }

    func saveProfile() {
        // Validate inputs first!
        guard validate() else { return }

        isSaving = true

        // Simulate a brief save delay for UX polish!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            // Save to UserDefaults!
            UserDefaults.standard.set(fullName,    forKey: "profile_fullName")
            UserDefaults.standard.set(email,       forKey: "profile_email")
            UserDefaults.standard.set(phone,       forKey: "profile_phone")
            UserDefaults.standard.set(dateOfBirth, forKey: "profile_dob")
            UserDefaults.standard.set(skinType,    forKey: "profile_skinType")
            if let data = avatarData {
                UserDefaults.standard.set(data, forKey: "profile_avatarData")
            }

            // Persist to Firestore asynchronously!
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
            
            // Show a success banner and hide it after 2 seconds!
            withAnimation { showSavedBanner = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                withAnimation { showSavedBanner = false }
            }
        }
    }

    // Loads the selected photo from the PhotosPicker!
    func loadPhotoFromPicker() {
        guard let item = selectedPhotoItem else { return }
        Task {
            // Load the image as Data!
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    avatarData = data
                    UserDefaults.standard.set(data, forKey: "profile_avatarData")
                }
                // Sync avatar to Firestore!
                try? await AuthService.shared.updateProfileAvatarData(data)
            }
        }
    }

    // MARK: - Validation
    // Checks that the inputs are valid before saving!
    private func validate() -> Bool {
        if fullName.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError = "Name cannot be empty."
            return false
        }
        
        // Simple email regex!
        let emailRegex = #"^[A-Z0-9a-z._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        if !NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email) {
            validationError = "Please enter a valid email address."
            return false
        }
        validationError = nil
        return true
    }
}
