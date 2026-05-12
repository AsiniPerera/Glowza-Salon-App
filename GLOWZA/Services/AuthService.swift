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
    var avatarBase64: String?
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

    static func friendlyErrorMessage(for error: Error) -> String {
        let msg = error.localizedDescription
        if msg.contains("malformed") || msg.contains("expired") || msg.contains("credential") {
            return "Invalid email or password. Please try again."
        }
        if msg.contains("already in use") {
            return "This email is already registered. Please sign in instead."
        }
        if msg.contains("no user record") || msg.contains("user-not-found") {
            return "No account found with this email. Please sign up."
        }
        if msg.contains("network") {
            return "Network error. Please check your internet connection."
        }
        if msg.contains("wrong-password") {
            return "Incorrect password. Please try again."
        }
        return msg
    }

    static let shared = AuthService()
    nonisolated private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    @ObservationIgnored
    nonisolated(unsafe) private var authListener: AuthStateDidChangeListenerHandle?

    // MARK: - Published state
    var currentUser: GlowzaUser?
    var currentUserProfile: GlowzaUserProfile?
    var isSignedIn = false

    // MARK: - Sign Up (Create Account → saves to Firebase Auth + Firestore)
    func signUp(fullName: String, email: String, phone: String, password: String) async throws {
        // 1. Create the Firebase Auth user
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // 2. Set display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()

        // 3. Save basic user doc to Firestore `users` collection
        let glowzaUser = GlowzaUser(uid: uid, fullName: fullName, email: email, phone: phone, createdAt: Date())
        try db.collection(GlowzaUser.collection).document(uid).setData(from: glowzaUser)

        // 4. Save extended profile doc to Firestore `userProfiles` collection
        let userProfile = GlowzaUserProfile(
            uid: uid,
            fullName: fullName,
            email: email,
            phone: phone,
            avatarUrl: nil,
            avatarBase64: nil,
            skinType: "Normal",
            loyaltyPoints: 0,
            favoriteSalonIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        try db.collection(GlowzaUserProfile.collection).document(uid).setData(from: userProfile)

        // 5. Update local state
        self.currentUser = glowzaUser
        self.currentUserProfile = userProfile
        cacheProfileToDefaults(userProfile)
        UserDefaults.standard.set(true, forKey: "is_new_user")

        // 6. Cache to Core Data for offline access
        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: email,
            name: fullName,
            phone: phone,
            skinType: "Normal"
        )

        // 7. Sign out so the user must explicitly login with their credentials
        //    (enforces the Create Account → Login → Dashboard flow)
        try? auth.signOut()
        self.isSignedIn = false
        self.currentUser = nil
        self.currentUserProfile = nil
    }

    // MARK: - Sign In (Login → validates Firebase Auth + loads Firestore profile)
    func signIn(email: String, password: String) async throws {
        // 1. Authenticate with Firebase
        let result = try await auth.signIn(withEmail: email, password: password)
        let uid = result.user.uid

        // 2. Fetch profile
        await fetchProfile(uid: uid)

        // 3. Mark as signed in
        self.isSignedIn = true

        // 4. Background sync: push salons to Firestore + pull bookings to Core Data
        Task.detached(priority: .utility) { [uid] in
            await DataSyncManager.shared.syncFirestoreToCoreData(userId: uid)
        }
    }

    // MARK: - Fetch Profile from Firestore
    func fetchProfile(uid: String) async {
        do {
            let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
            if doc.exists, let glowzaUser = try? doc.data(as: GlowzaUser.self) {
                self.currentUser = glowzaUser
            }

            let profileDoc = try await db.collection(GlowzaUserProfile.collection).document(uid).getDocument()
            if let userProfile = try? profileDoc.data(as: GlowzaUserProfile.self) {
                self.currentUserProfile = userProfile
                cacheProfileToDefaults(userProfile)
            }

            let avatarB64 = profileDoc.get("avatarBase64") as? String
            let dob = profileDoc.get("dateOfBirth") as? String

            if let avatarB64, let imageData = Data(base64Encoded: avatarB64) {
                UserDefaults.standard.set(imageData, forKey: "profile_avatarData")
            }

            try? UserProfileRepository.shared.saveOrUpdateProfile(
                userId: uid,
                email: currentUser?.email ?? auth.currentUser?.email ?? "",
                name: currentUser?.fullName ?? auth.currentUser?.displayName ?? "User",
                phone: currentUser?.phone,
                skinType: currentUserProfile?.skinType,
                dateOfBirth: dob,
                avatarBase64: avatarB64
            )
        } catch {
            print("Failed to fetch profile: \(error)")
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        currentUserProfile = nil
        isSignedIn = false
        
        // Clear profile cache from UserDefaults
        UserDefaults.standard.removeObject(forKey: "profile_fullName")
        UserDefaults.standard.removeObject(forKey: "profile_email")
        UserDefaults.standard.removeObject(forKey: "profile_phone")
        UserDefaults.standard.removeObject(forKey: "profile_skinType")
        UserDefaults.standard.removeObject(forKey: "profile_loyalty")
        UserDefaults.standard.removeObject(forKey: "profile_avatarData")
    }

    // MARK: - Check & Listen to Auth State (called once on app launch)
    /// Sets up a real-time Firebase listener. This means:
    /// - If the user already has a saved session, isSignedIn → true immediately
    /// - If the user logs out from any screen, isSignedIn → false automatically
    func checkAuthState() {
        authListener = auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            Task { @MainActor in
                if let firebaseUser = firebaseUser {
                    // User has an active session
                    self.isSignedIn = true
                    await self.loadProfileFromCache(uid: firebaseUser.uid)
                    await self.fetchProfile(uid: firebaseUser.uid) // Fetch fresh data!
                } else {
                    // No active session
                    self.isSignedIn = false
                    self.currentUser = nil
                    self.currentUserProfile = nil
                }
            }
        }
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

        // Update reviews with new name
        let reviewsSnapshot = try await db.collection("salonReviews")
            .whereField("userId", isEqualTo: uid)
            .getDocuments()
        
        for doc in reviewsSnapshot.documents {
            try await doc.reference.updateData(["userName": fullName])
        }

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
        return try? doc.data(as: GlowzaUser.self)
    }

    func fetchUserProfileExtended() async throws -> GlowzaUserProfile? {
        guard let uid = auth.currentUser?.uid else { return nil }
        let doc = try await db.collection(GlowzaUserProfile.collection).document(uid).getDocument()
        return try? doc.data(as: GlowzaUserProfile.self)
    }

    // MARK: - Update Profile Avatar
    func updateProfileAvatarData(_ imageData: Data) async throws {
        guard let uid = auth.currentUser?.uid else { throw AuthError.notSignedIn }
        let base64 = imageData.base64EncodedString()

        try await db.collection(GlowzaUserProfile.collection).document(uid).setData([
            "avatarBase64": base64,
            "updatedAt": Timestamp()
        ], merge: true)

        currentUserProfile?.avatarBase64 = base64
        UserDefaults.standard.set(imageData, forKey: "profile_avatarData")

        try? UserProfileRepository.shared.saveOrUpdateProfile(
            userId: uid,
            email: currentUser?.email ?? "",
            name: currentUser?.fullName ?? "",
            avatarBase64: base64
        )
    }

    // MARK: - Helpers
    var currentUID: String? { auth.currentUser?.uid }
    var currentUserName: String? { auth.currentUser?.displayName }

    deinit {
        if let handle = authListener {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Private: Load profile from Core Data cache, then refresh from Firestore
    private func loadProfileFromCache(uid: String) async {
        // Step 1: Load immediately from Core Data (fast, works offline)
        if let cached = try? UserProfileRepository.shared.fetchProfile(userId: uid) {
            UserDefaults.standard.set(cached.name, forKey: "profile_fullName")
            UserDefaults.standard.set(cached.email, forKey: "profile_email")
            if let phone = cached.phone {
                UserDefaults.standard.set(phone, forKey: "profile_phone")
            }
            if let b64 = cached.avatarBase64, let data = Data(base64Encoded: b64) {
                UserDefaults.standard.set(data, forKey: "profile_avatarData")
            }
        }

        // Step 2: Refresh from Firestore in background
        do {
            self.currentUser = try await fetchCurrentUserProfile()
            if let profile = try await fetchUserProfileExtended() {
                self.currentUserProfile = profile
                cacheProfileToDefaults(profile)
            }
            // Sync fresh data back to Core Data
            if let user = self.currentUser {
                try? UserProfileRepository.shared.saveOrUpdateProfile(
                    userId: uid,
                    email: user.email,
                    name: user.fullName,
                    phone: user.phone,
                    skinType: currentUserProfile?.skinType
                )
            }
        } catch {
            print("AuthService: Failed to refresh profile from Firestore — \(error)")
        }
    }

    private func cacheProfileToDefaults(_ profile: GlowzaUserProfile) {
        UserDefaults.standard.set(profile.fullName, forKey: "profile_fullName")
        UserDefaults.standard.set(profile.email, forKey: "profile_email")
        UserDefaults.standard.set(profile.phone, forKey: "profile_phone")
        UserDefaults.standard.set(profile.skinType, forKey: "profile_skinType")
        UserDefaults.standard.set(profile.loyaltyPoints, forKey: "profile_loyalty")
    }
}
