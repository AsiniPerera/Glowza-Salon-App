import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Observation

// MARK: - Favourites Store
/// Observable singleton that manages the user's favourite salons.
/// Persists to Firestore `userProfiles/{uid}.favoriteSalonIds` as an array of
/// salon display-names. Call `load()` once after sign-in.
@MainActor
@Observable
final class FavouritesStore {

    static let shared = FavouritesStore()
    private init() {}

    private let db = Firestore.firestore()

    /// Salon display names currently favourited by the user.
    private(set) var favouriteNames: [String] = []

    // MARK: - Public API

    func isFavourite(_ salonName: String) -> Bool {
        favouriteNames.contains(salonName)
    }

    /// Toggle favourite status and immediately persist to Firestore.
    func toggle(_ salonName: String) async {
        withAnimation(.spring(duration: 0.25)) {
            if let idx = favouriteNames.firstIndex(of: salonName) {
                favouriteNames.remove(at: idx)
            } else {
                favouriteNames.insert(salonName, at: 0)   // newest at top
            }
        }
        await persist()
    }

    /// Load the user's favourites from Firestore on sign-in / app launch.
    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = try? await db.collection("userProfiles").document(uid).getDocument()
        let ids = doc?.get("favoriteSalonIds") as? [String] ?? []
        withAnimation { favouriteNames = ids }
        
        // Inject demo data for lecturer demonstration
        seedDemoData()
    }

    /// Injects default favourites for lecturer demonstration.
    private func seedDemoData() {
        let demoFavs = ["Haley Avenue", "Azure Spa"]
        for fav in demoFavs {
            if !favouriteNames.contains(fav) {
                favouriteNames.append(fav)
            }
        }
    }

    // MARK: - Private

    private func persist() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ids = favouriteNames
        try? await db.collection("userProfiles").document(uid)
            .setData(["favoriteSalonIds": ids], merge: true)
    }
}
