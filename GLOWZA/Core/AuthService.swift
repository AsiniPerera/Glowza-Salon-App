import Foundation
import FirebaseAuth
import FirebaseFirestore
import Observation

// MARK: - User Profile Model
struct GlowzaUser: Codable {
    let uid: String
    let fullName: String
    let email: String
    let phone: String
    let createdAt: Date

    static let collection = "users"
}

// MARK: - Auth Service (Firebase)
@MainActor
@Observable
final class AuthService {

    static let shared = AuthService()
    nonisolated private init() {}

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    var currentUser: GlowzaUser?
    var isSignedIn = false

    // MARK: - Sign Up
    /// Creates Firebase Auth user and saves profile to Firestore
    func signUp(
        fullName: String,
        email: String,
        phone: String,
        password: String
    ) async throws {
        // Create auth user
        let result = try await auth.createUser(withEmail: email, password: password)
        let uid = result.user.uid
        
        // Update display name
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = fullName
        try await changeRequest.commitChanges()
        
        // Save user profile to Firestore
        let glowzaUser = GlowzaUser(
            uid: uid,
            fullName: fullName,
            email: email,
            phone: phone,
            createdAt: Date()
        )
        
        try db.collection(GlowzaUser.collection)
            .document(uid)
            .setData(from: glowzaUser)
        
        // Update local state
        self.currentUser = glowzaUser
        self.isSignedIn = true
    }

    // MARK: - Sign In
    /// Signs in with Firebase Auth
    func signIn(email: String, password: String) async throws {
        let result = try await auth.signIn(withEmail: email, password: password)
        let uid = result.user.uid
        
        // Fetch user profile from Firestore
        let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
        let glowzaUser = try doc.data(as: GlowzaUser.self)
        
        self.currentUser = glowzaUser
        self.isSignedIn = true
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isSignedIn = false
    }

    // MARK: - Fetch current user profile
    func fetchCurrentUserProfile() async throws -> GlowzaUser? {
        guard let uid = auth.currentUser?.uid else { return nil }
        let doc = try await db.collection(GlowzaUser.collection).document(uid).getDocument()
        return try doc.data(as: GlowzaUser.self)
    }

    // MARK: - Check authentication state
    func checkAuthState() {
        if let firebaseUser = auth.currentUser {
            isSignedIn = true
            // Fetch profile on app launch
            Task {
                do {
                    self.currentUser = try await fetchCurrentUserProfile()
                } catch {
                    print("Error fetching user profile: \(error)")
                }
            }
        } else {
            isSignedIn = false
            currentUser = nil
        }
    }

    // MARK: - Current user helpers
    var currentUID: String? { auth.currentUser?.uid }
    var currentUserName: String? { auth.currentUser?.displayName }
}
