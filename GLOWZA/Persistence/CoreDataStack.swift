import CoreData
import Foundation

// MARK: - Core Data Stack
// Uses a programmatic model — no .xcdatamodeld file required.
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "GLOWZA", managedObjectModel: Self.makeModel())
        let description = NSPersistentStoreDescription()
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error { print("Core Data Error: \(error)") }
            else          { print("Core Data initialized") }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    }
    
    // MARK: - Programmatic Core Data Model
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // ── CDBooking ──
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
            makeAttr("firestoreID",        .stringAttributeType, opt: true),
            makeAttr("signatureImageData", .binaryDataAttributeType, opt: true),
        ])

        // ── CDReview ──
        let review = makeEntity("CDReview", props: [
            makeAttr("id",           .UUIDAttributeType),
            makeAttr("rating",       .integer16AttributeType),
            makeAttr("comment",      .stringAttributeType),
            makeAttr("date",         .dateAttributeType),
            makeAttr("reviewerName", .stringAttributeType),
        ])

        // ── CDSalon ──
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

        // ── CDSalonService ──
        let salonService = makeEntity("CDSalonService", props: [
            makeAttr("id",       .UUIDAttributeType),
            makeAttr("name",     .stringAttributeType),
            makeAttr("icon",     .stringAttributeType),
            makeAttr("duration", .stringAttributeType),
            makeAttr("price",    .doubleAttributeType),
            makeAttr("category", .stringAttributeType),
            makeAttr("benefits", .stringAttributeType),  // JSON-encoded [String]
        ])

        // ── CDNotification ──
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

        // ── CDUserProfile ──
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

    private static func makeEntity(_ name: String, props: [NSPropertyDescription]) -> NSEntityDescription {
        let e = NSEntityDescription()
        e.name = name; e.managedObjectClassName = name; e.properties = props; return e
    }

    private static func makeAttr(_ name: String, _ type: NSAttributeType, opt: Bool = false) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name; a.attributeType = type; a.isOptional = opt; return a
    }

    private static func makeRel(_ name: String, dest: NSEntityDescription, toMany: Bool, delete: NSDeleteRule) -> NSRelationshipDescription {
        let r = NSRelationshipDescription()
        r.name = name; r.destinationEntity = dest
        r.minCount = 0; r.maxCount = toMany ? 0 : 1
        r.deleteRule = delete; r.isOptional = true; return r
    }

    // MARK: - CRUD helpers
    func save() throws {
        if context.hasChanges { try context.save() }
    }

    func delete(_ object: NSManagedObject) throws {
        context.delete(object); try save()
    }

    func deleteAll(_ entityName: String) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        try context.fetch(request).forEach { context.delete($0) }
        try save()
    }
}
