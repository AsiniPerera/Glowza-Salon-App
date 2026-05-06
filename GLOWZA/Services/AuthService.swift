import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

// MARK: - User Profile Model (users collection — basic auth data)
struct GlowzaUser: Codable {
    let uid: String
    let fullName: String
    let email: String
    let phone: String
    let createdAt: Date
    static let collection = "users"
}

// MARK: - Extended User Profile (userProfiles collection — full profile data)
struct GlowzaUserProfile: Codable {
    var uid: String
    var fullName: String
    var email: String
    var phone: String
    var avatarUrl: String?
    var skinType: String
    var loyaltyPoints: Int
    var favoriteSalonIds: [String]
    let createdAt: Date
    var updatedAt: Date
    static let collection = "userProfiles"
}

// MARK: - Auth Error
enum AuthError: Error, LocalizedError {
    case notSignedIn
    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "User is not signed in."
        }
    }
}

// MARK: - Auth Service (Firebase + Core Data cache)
@MainActor
@Observable
final class AuthService {

    static let shared = AuthService()
    nonisolated private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    var currentUser: GlowzaUser?
    var currentUserProfile: GlowzaUserProfile?
    var isSignedIn = false

    // MARK: - Sign Up
    func signUp(fullName: String, email: String, phone: String, password: String) async throws {
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()

        let glowzaUser = GlowzaUser(uid: uid, fullName: fullName, email: email, phone: phone, createdAt: Date())
        try db.collection(GlowzaUser.collection).document(uid).setData(from: glowzaUser)

        let userProfile = GlowzaUserProfile(
            uid: uid,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarUrl: nil,
            skinType: "Normal",
            loyaltyPoints: 0,
            favoriteSalonIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        try db.collection(GlowzaUserProfile.collection).document(uid).setData(from: userProfile)

        self.currentUser = glowzaUser
        self.currentUserProfile = userProfile
        cacheProfileToDefaults(userProfile)
        self.isSignedIn = true

        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: email,
            name: fullName,
            phone: phone,
            skinType: "Normal"
        )
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        let uid = result.user.uid

        let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
        let glowzaUser = try doc.data(as: GlowzaUser.self)
        self.currentUser = glowzaUser

        let profileDoc = try await db.collection(GlowzaUserProfile.collection).document(uid).getDocument()
        if let userProfile = try? profileDoc.data(as: GlowzaUserProfile.self) {
            self.currentUserProfile = userProfile
            cacheProfileToDefaults(userProfile)
        }

        let avatarB64 = profileDoc.get("avatarBase64") as? String
        let dob = profileDoc.get("dateOfBirth") as? String

        if let avatarB64,
           let imageData = Data(base64Encoded: avatarB64) {
            UserDefaults.standard.set(imageData, forKey: "profile_avatarData")
        }

        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: glowzaUser.email,
            name: glowzaUser.fullName,
            phone: glowzaUser.phone,
            skinType: currentUserProfile?.skinType,
            dateOfBirth: dob,
            avatarBase64: avatarB64
        )

        self.isSignedIn = true
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        currentUserProfile = nil
        isSignedIn = false
    }

    // MARK: - Update User Profile
    func updateUserProfile(
        fullName: String,
        email: String,
        phone: String,
        skinType: String,
        dateOfBirth: String? = nil,
        avatarUrl: String? = nil
    ) async throws {
        guard let uid = auth.currentUser?.uid else { throw AuthError.notSignedIn }

        var profileData: [String: Any] = [
            "fullName": fullName,
            "email": email,
            "phone": phone,
            "skinType": skinType,
            "updatedAt": Timestamp()
        ]
        if let dateOfBirth { profileData["dateOfBirth"] = dateOfBirth }
        if let avatarUrl { profileData["avatarUrl"] = avatarUrl }

        try await db.collection(GlowzaUserProfile.collection).document(uid).setData(profileData, merge: true)
        try await db.collection(GlowzaUser.collection).document(uid).setData([
            "fullName": fullName,
            "email": email,
            "phone": phone
        ], merge: true)

        currentUserProfile?.fullName = fullName
        currentUserProfile?.email = email
        currentUserProfile?.phone = phone
        currentUserProfile?.skinType = skinType
        if let avatarUrl { currentUserProfile?.avatarUrl = avatarUrl }

        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: email,
            name: fullName,
            phone: phone,
            skinType: skinType,
            dateOfBirth: dateOfBirth
        )
    }

    // MARK: - Fetch Profiles
    func fetchCurrentUserProfile() async throws -> GlowzaUser? {
        guard let uid = auth.currentUser?.uid else { return nil }
        let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
        return try doc.data(as: GlowzaUser.self)
    }

    func fetchUserProfileExtended() async throws -> GlowzaUserProfile? {
        guard let uid = auth.currentUser?.uid else { return nil }
        let doc = try await db.collection(GlowzaUserProfile.collection).document(uid).getDocument()
        return try? doc.data(as: GlowzaUserProfile.self)
    }

    // MARK: - Update Profile Avatar
    /// Stores avatar image as base64 in Firestore and Core Data.
    func updateProfileAvatarData(_ imageData: Data) async throws {
        guard let uid = auth.currentUser?.uid else { throw AuthError.notSignedIn }
        let base64 = imageData.base64EncodedString()

        try await db.collection(GlowzaUserProfile.collection).document(uid).setData([
            "avatarBase64": base64,
            "updatedAt": Timestamp()
        ], merge: true)

        UserDefaults.standard.set(imageData, forKey: "profile_avatarData")

        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: currentUser?.email ?? "",
            name: currentUser?.fullName ?? "",
            avatarBase64: base64
        )
    }

    // MARK: - Check Authentication State (called on app launch)
    func checkAuthState() {
        guard auth.currentUser != nil else {
            isSignedIn = false
            currentUser = nil
            currentUserProfile = nil
            return
        }

        isSignedIn = true

        Task {
            do {
                // Bootstrap from Core Data immediately (offline-safe)
                if let uid = auth.currentUser?.uid,
                   let cached = try? UserProfileRepository.shared.fetchProfile(userId: uid) {
                    UserDefaults.standard.set(cached.name, forKey: "profile_fullName")
                    UserDefaults.standard.set(cached.email, forKey: "profile_email")
                    if let phone = cached.phone {
                        UserDefaults.standard.set(phone, forKey: "profile_phone")
                    }
                    if let b64 = cached.avatarBase64,
                       let data = Data(base64Encoded: b64),
                       UserDefaults.standard.data(forKey: "profile_avatarData") == nil {
                        UserDefaults.standard.set(data, forKey: "profile_avatarData")
                    }
                }

                self.currentUser = try await fetchCurrentUserProfile()
                if let profile = try await fetchUserProfileExtended() {
                    self.currentUserProfile = profile
                    cacheProfileToDefaults(profile)
                }

                if let uid = auth.currentUser?.uid {
                    let profileDoc = try await db.collection(GlowzaUserProfile.collection).document(uid).getDocument()
                    if let avatarBase64 = profileDoc.get("avatarBase64") as? String,
                       let imageData = Data(base64Encoded: avatarBase64) {
                        UserDefaults.standard.set(imageData, forKey: "profile_avatarData")
                    }
                }
            } catch {
                print("Error fetching user profile: \(error)")
            }
        }
    }

    // MARK: - Helpers
    var currentUID: String? { auth.currentUser?.uid }
    var currentUserName: String? { auth.currentUser?.displayName }

    private func cacheProfileToDefaults(_ profile: GlowzaUserProfile) {
        UserDefaults.standard.set(profile.fullName, forKey: "profile_fullName")
        UserDefaults.standard.set(profile.email, forKey: "profile_email")
        UserDefaults.standard.set(profile.phone, forKey: "profile_phone")
        UserDefaults.standard.set(profile.skinType, forKey: "profile_skinType")
        UserDefaults.standard.set(profile.loyaltyPoints, forKey: "profile_loyalty")
    }
}
