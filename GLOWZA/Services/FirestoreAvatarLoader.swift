import Foundation
import FirebaseFirestore

// MARK: - Firestore Avatar Loader
/// Fetches the base64 avatar stored in `userProfiles/{uid}` and returns it as Data.
/// Called on ProfileView appear so the avatar is always in sync with Firestore.
enum FirestoreAvatarLoader {

    private static let db = Firestore.firestore()

    /// Returns the avatar image Data for a given Firebase UID, or nil if not set.
    static func loadAvatar(uid: String) async throws -> Data? {
        let doc = try await db.collection("userProfiles").document(uid).getDocument()
        guard let base64 = doc.get("avatarBase64") as? String, !base64.isEmpty else {
            return nil
        }
        return Data(base64Encoded: base64)
    }
}
