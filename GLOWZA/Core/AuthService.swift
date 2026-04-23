import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - User Profile stored in Firestore
struct GlowzaUser: Codable {
    let uid: String
    let fullName: String
    let email: String
    let phone: String
    let createdAt: Date

    // Firestore collection/document path
    static let collection = "users"
}

// MARK: - Auth Service
@MainActor
final class AuthService {

    static let shared = AuthService()
    private init() {}

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()

    // MARK: - Sign Up
    /// Creates a Firebase Auth user, then saves the profile to Firestore.
    func signUp(
        fullName: String,
        email: String,
        phone: String,
        password: String
    ) async throws {

        // 1. Create the Auth account
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid

        // 2. Update the display name in Auth
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()

        // 3. Save the full profile to Firestore  users/{uid}
        let user = GlowzaUser(
            uid:       uid,
            fullName:  fullName,
            email:     email,
            phone:     phone,
            createdAt: Date()
        )
        try db.collection(GlowzaUser.collection)
              .document(uid)
              .setData(from: user)
    }

    // MARK: - Sign In
    /// Signs in with Firebase Auth.
    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
    }

    // MARK: - Fetch user profile from Firestore
    /// Returns the GlowzaUser document for the currently signed-in user.
    func fetchCurrentUserProfile() async throws -> GlowzaUser? {
        guard let uid = auth.currentUser?.uid else { return nil }
        let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
        return try doc.data(as: GlowzaUser.self)
    }

    // MARK: - Current UID helper
    var currentUID: String? { auth.currentUser?.uid }
    var isSignedIn: Bool    { auth.currentUser != nil }
}
