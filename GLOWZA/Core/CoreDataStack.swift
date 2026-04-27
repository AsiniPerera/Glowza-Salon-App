import CoreData
import Foundation

// MARK: - Core Data Stack Setup
final class CoreDataStack {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    private init() {
        container = NSPersistentContainer(name: "GLOWZA")
        
        // Setup automatic cloud sync if available
        let description = NSPersistentStoreDescription()
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data Error: \(error.localizedDescription)")
            } else {
                print("✅ Core Data initialized successfully")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    }
    
    func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
            print("✅ Core Data saved successfully")
        }
    }
    
    func delete(_ object: NSManagedObject) throws {
        let context = container.viewContext
        context.delete(object)
        try save()
    }
    
    func deleteAll(_ entityName: String) throws {
        let context = container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
        let results = try context.fetch(request)
        results.forEach { context.delete($0) }
        try save()
    }
}
