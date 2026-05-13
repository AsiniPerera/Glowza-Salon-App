import CoreData
import Foundation

// MARK: - Core Data Stack
// This class manages the Core Data stack for the app.
// Note: It uses a programmatic model — no .xcdatamodeld file required!
// This means we define our database tables and columns in code.
final class CoreDataStack {
    static let shared = CoreDataStack() // Singleton instance!
    
    let container: NSPersistentContainer
    
    // Helper to get the main context easily!
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        // We initialize the container with our custom programmatic model!
        container = NSPersistentContainer(name: "GLOWZA", managedObjectModel: Self.makeModel())
        
        let description = NSPersistentStoreDescription()
        // Enable history tracking (good for background sync!).
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        // Load the actual database file!
        container.loadPersistentStores { _, error in
            if let error { print("Core Data Error: \(error)") }
            else          { print("Core Data initialized") }
        }
        
        // Automatically merge changes from parent contexts!
        container.viewContext.automaticallyMergesChangesFromParent = true
        // If there are conflicts, the store wins!
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    }
    
    // MARK: - Programmatic Core Data Model
    // This function builds the database schema in code!
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ── CDBooking Entity ──
        let booking = makeEntity("CDBooking", props: [
            makeAttr("id",                 .UUIDAttributeType),
            makeAttr("salonName",          .stringAttributeType),
            makeAttr("salonLocation",      .stringAttributeType),
            makeAttr("serviceName",        .stringAttributeType),
            makeAttr("servicePrice",       .doubleAttributeType),
            makeAttr("date",               .dateAttributeType),
            makeAttr("timeSlot",           .stringAttributeType),
            makeAttr("receiptNumber",      .stringAttributeType),
            makeAttr("paymentMethod",      .stringAttributeType),
            makeAttr("amountPaid",         .doubleAttributeType),
            makeAttr("status",             .stringAttributeType),
            makeAttr("userId",             .stringAttributeType),
            makeAttr("userName",           .stringAttributeType),
            makeAttr("createdAt",          .dateAttributeType),
            makeAttr("updatedAt",          .dateAttributeType),
            makeAttr("firestoreID",        .stringAttributeType, opt: true), // Optional!
            makeAttr("signatureImageData", .binaryDataAttributeType, opt: true), // Optional!
        ])

        // ── CDReview Entity ──
        let review = makeEntity("CDReview", props: [
            makeAttr("id",           .UUIDAttributeType),
            makeAttr("rating",       .integer16AttributeType),
            makeAttr("comment",      .stringAttributeType),
            makeAttr("date",         .dateAttributeType),
            makeAttr("reviewerName", .stringAttributeType),
        ])

        // ── CDSalon Entity ──
        let salon = makeEntity("CDSalon", props: [
            makeAttr("id",          .UUIDAttributeType),
            makeAttr("name",        .stringAttributeType),
            makeAttr("location",    .stringAttributeType),
            makeAttr("distance",    .stringAttributeType),
            makeAttr("rating",      .doubleAttributeType),
            makeAttr("reviewCount", .integer32AttributeType),
            makeAttr("score",       .doubleAttributeType),
            makeAttr("about",       .stringAttributeType),
            makeAttr("phone",       .stringAttributeType),
            makeAttr("openHours",   .stringAttributeType),
        ])

        // ── CDSalonService Entity ──
        let salonService = makeEntity("CDSalonService", props: [
            makeAttr("id",       .UUIDAttributeType),
            makeAttr("name",     .stringAttributeType),
            makeAttr("icon",     .stringAttributeType),
            makeAttr("duration", .stringAttributeType),
            makeAttr("price",    .doubleAttributeType),
            makeAttr("category", .stringAttributeType),
            makeAttr("benefits", .stringAttributeType),  // Stored as JSON-encoded [String]
        ])

        // ── CDNotification Entity ──
        let notification = makeEntity("CDNotification", props: [
            makeAttr("id",        .UUIDAttributeType),
            makeAttr("title",     .stringAttributeType),
            makeAttr("subtitle",  .stringAttributeType),
            makeAttr("icon",      .stringAttributeType),
            makeAttr("type",      .stringAttributeType),
            makeAttr("createdAt", .dateAttributeType),
            makeAttr("isRead",    .booleanAttributeType),
            makeAttr("userId",    .stringAttributeType, opt: true),
        ])

        // ── CDUserProfile Entity ──
        let userProfile = makeEntity("CDUserProfile", props: [
            makeAttr("userId",           .stringAttributeType),
            makeAttr("email",            .stringAttributeType),
            makeAttr("name",             .stringAttributeType),
            makeAttr("phone",            .stringAttributeType, opt: true),
            makeAttr("skinType",         .stringAttributeType, opt: true),
            makeAttr("dateOfBirth",      .stringAttributeType, opt: true),
            makeAttr("profileImageData", .binaryDataAttributeType, opt: true),
            makeAttr("avatarBase64",     .stringAttributeType, opt: true),
            makeAttr("createdAt",        .dateAttributeType),
            makeAttr("updatedAt",        .dateAttributeType),
        ])

        // CDBooking ↔ CDReview (one-to-one, cascade delete review when booking deleted)
        let b2r = makeRel("review",  dest: review,  toMany: false, delete: .cascadeDeleteRule)
        let r2b = makeRel("booking", dest: booking, toMany: false, delete: .nullifyDeleteRule)
        b2r.inverseRelationship = r2b;  r2b.inverseRelationship = b2r
        booking.properties += [b2r];    review.properties  += [r2b]

        // CDSalon ↔ CDSalonService (one-to-many, cascade delete services when salon deleted)
        let s2sv = makeRel("services", dest: salonService, toMany: true,  delete: .cascadeDeleteRule)
        let sv2s = makeRel("salon",    dest: salon,        toMany: false, delete: .nullifyDeleteRule)
        s2sv.inverseRelationship = sv2s;  sv2s.inverseRelationship = s2sv
        salon.properties += [s2sv];       salonService.properties += [sv2s]

        model.entities = [booking, review, salon, salonService, notification, userProfile]
        return model
    }

    // Helper to create an entity description!
    private static func makeEntity(_ name: String, props: [NSPropertyDescription]) -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = name; e.managedObjectClassName = name; e.properties = props; return e
    }

    // Helper to create an attribute description!
    private static func makeAttr(_ name: String, _ type: NSAttributeType, opt: Bool = false) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name; a.attributeType = type; a.isOptional = opt; return a
    }

    // Helper to create a relationship description!
    private static func makeRel(_ name: String, dest: NSEntityDescription, toMany: Bool, delete: NSDeleteRule) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name; r.destinationEntity = dest
        r.minCount = 0; r.maxCount = toMany ? 0 : 1 // 0 means many!
        r.deleteRule = delete; r.isOptional = true; return r
    }

    // MARK: - CRUD helpers
    // Saves changes to the persistent store if there are any!
    func save() throws {
        if context.hasChanges { try context.save() }
    }

    // Deletes a specific object!
    func delete(_ object: NSManagedObject) throws {
        context.delete(object); try save()
    }

    // Deletes all objects of a specific entity type!
    func deleteAll(_ entityName: String) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        try context.fetch(request).forEach { context.delete($0) }
        try save()
    }
}
