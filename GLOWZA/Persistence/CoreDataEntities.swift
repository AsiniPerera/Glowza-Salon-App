import CoreData
import Foundation
import UIKit

// MARK: - Core Data Entity: CDBooking
// This class represents a Booking stored in Core Data.
// The @objc attribute makes it available to the Objective-C runtime (needed for Core Data).
@objc(CDBooking)
public class CDBooking: NSManagedObject {
    // @NSManaged tells Swift that Core Data will handle the storage of these properties!
    @NSManaged public var id: UUID
    @NSManaged public var salonName: String
    @NSManaged public var salonLocation: String
    @NSManaged public var serviceName: String
    @NSManaged public var servicePrice: Double
    @NSManaged public var date: Date
    @NSManaged public var timeSlot: String
    @NSManaged public var receiptNumber: String
    @NSManaged public var paymentMethod: String
    @NSManaged public var amountPaid: Double
    @NSManaged public var status: String  // "upcoming", "completed", "cancelled"
    @NSManaged public var signatureImageData: Data?
    @NSManaged public var review: CDReview? // Relationship to a review!
    @NSManaged public var userId: String
    @NSManaged public var userName: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var firestoreID: String?  // For syncing with Firebase.
}

// MARK: - Core Data Entity: CDReview
@objc(CDReview)
public class CDReview: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var rating: Int16 // Core Data uses specific integer types like Int16!
    @NSManaged public var comment: String
    @NSManaged public var date: Date
    @NSManaged public var reviewerName: String
    @NSManaged public var booking: CDBooking? // Inverse relationship back to booking.
}

// MARK: - Core Data Entity: CDSalon
@objc(CDSalon)
public class CDSalon: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var location: String
    @NSManaged public var distance: String
    @NSManaged public var rating: Double
    @NSManaged public var reviewCount: Int32
    @NSManaged public var score: Double
    @NSManaged public var about: String
    @NSManaged public var phone: String
    @NSManaged public var openHours: String
    @NSManaged public var services: NSSet?  // To-many relationship to CDSalonService!
}

// MARK: - Core Data Entity: CDSalonService
@objc(CDSalonService)
public class CDSalonService: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var icon: String
    @NSManaged public var duration: String
    @NSManaged public var price: Double
    @NSManaged public var category: String
    @NSManaged public var benefits: String  // Stored as a JSON encoded string.
    @NSManaged public var salon: CDSalon? // Inverse relationship back to salon.
}

// MARK: - Core Data Entity: CDNotification
@objc(CDNotification)
public class CDNotification: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var subtitle: String
    @NSManaged public var icon: String
    @NSManaged public var type: String  // "success", "info", "error", "warning"
    @NSManaged public var createdAt: Date
    @NSManaged public var isRead: Bool
    @NSManaged public var userId: String?
}

// MARK: - Core Data Entity: CDUserProfile
@objc(CDUserProfile)
public class CDUserProfile: NSManagedObject {
    @NSManaged public var userId: String
    @NSManaged public var email: String
    @NSManaged public var name: String
    @NSManaged public var phone: String?
    @NSManaged public var profileImageData: Data?
    @NSManaged public var skinType: String?
    @NSManaged public var dateOfBirth: String?
    @NSManaged public var avatarBase64: String?
    @NSManaged public var favoriteSalonIds: String? // JSON string
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

// MARK: - Typed Fetch Request Extensions
// These helpers make it easy to create fetch requests without typing strings!
extension CDBooking {
    static func fetchRequest() -> NSFetchRequest<CDBooking> {
        return NSFetchRequest<CDBooking>(entityName: "CDBooking")
    }
}

extension CDReview {
    static func fetchRequest() -> NSFetchRequest<CDReview> {
        return NSFetchRequest<CDReview>(entityName: "CDReview")
    }
}

extension CDNotification {
    static func fetchRequest() -> NSFetchRequest<CDNotification> {
        return NSFetchRequest<CDNotification>(entityName: "CDNotification")
    }
}

extension CDUserProfile {
    static func fetchRequest() -> NSFetchRequest<CDUserProfile> {
        return NSFetchRequest<CDUserProfile>(entityName: "CDUserProfile")
    }
}

extension CDSalon {
    static func fetchRequest() -> NSFetchRequest<CDSalon> {
        return NSFetchRequest<CDSalon>(entityName: "CDSalon")
    }
}

extension CDSalonService {
    static func fetchRequest() -> NSFetchRequest<CDSalonService> {
        return NSFetchRequest<CDSalonService>(entityName: "CDSalonService")
    }
}
