import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Observation

// MARK: - Favourites Store
// This class manages the user's favourite salons!
// It is an Observable singleton, meaning views can watch it for changes.
// It persists to Firestore in the user's profile document.
@MainActor
@Observable
final class FavouritesStore {

    static let shared = FavouritesStore() // Singleton instance!
    private init() {}

    private let db = Firestore.firestore() // Firestore reference.

    // Salon display names currently favourited by the user!
    // private(set) means anyone can read it, but only this class can change it!
    private(set) var favouriteNames: [String] = []

    // MARK: - Public API
    
    // Clears favourites from memory (used on logout!).
    func clear() {
        favouriteNames = []
    }

    // Helper to check if a specific salon is favourited!
    func isFavourite(_ salonName: String) -> Bool {
        favouriteNames.contains(salonName)
    }

    // Toggle favourite status and immediately persist to Firestore!
    func toggle(_ salonName: String) async {
        // We use withAnimation to make the UI update smoothly when toggling!
        withAnimation(.spring(duration: 0.25)) {
            if let idx = favouriteNames.firstIndex(of: salonName) {
                favouriteNames.remove(at: idx)
            } else {
                favouriteNames.insert(salonName, at: 0)   // Newest at top!
            }
        }
        await persist() // Save the change to Firestore!
    }

    // Load the user's favourites from Firestore on sign-in or app launch!
    func load() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let doc = try? await db.collection("userProfiles").document(uid).getDocument()
        let ids = doc?.get("favoriteSalonIds") as? [String] ?? []
        withAnimation { favouriteNames = ids }
        
        // Inject demo data for lecturer demonstration if needed!
        // seedDemoData()
    }

    // Injects default favourites for lecturer demonstration.
    private func seedDemoData() {
        let demoFavs = ["Golden Avenue", "Azure Spa"]
        for fav in demoFavs {
            if !favouriteNames.contains(fav) {
                favouriteNames.append(fav)
            }
        }
    }

    // MARK: - Private

    // Saves the current favourites array to Firestore!
    private func persist() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ids = favouriteNames
        // Use merge: true so we don't overwrite the whole profile document!
        try? await db.collection("userProfiles").document(uid)
            .setData(["favoriteSalonIds": ids], merge: true)
    }
}
