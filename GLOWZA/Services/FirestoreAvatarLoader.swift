import Foundation
import FirebaseFirestore

// MARK: - Firestore Avatar Loader
// This is a helper to fetch the user's avatar from Firestore.
// We use an 'enum' with no cases as a namespace! This prevents anyone from
// accidentally creating an instance of this type (since it only has static methods).
enum FirestoreAvatarLoader {

    private static let db = Firestore.firestore() // Firestore reference.

    /// Returns the avatar image Data for a given Firebase UID, or nil if not set.
    // This is marked as `async` because network calls take time!
    static func loadAvatar(uid: String) async throws -> Data? {
        // Fetch the document from the 'userProfiles' collection!
        let doc = try await db.collection("userProfiles").document(uid).getDocument()
        
        // Extract the base64 string!
        guard let base64 = doc.get("avatarBase64") as? String, !base64.isEmpty else {
            return nil
        }
        
        // Convert the base64 string back into raw image Data!
        return Data(base64Encoded: base64)
    }
}
