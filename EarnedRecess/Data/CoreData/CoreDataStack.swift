import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let container: NSPersistentContainer

    var context: NSManagedObjectContext {
        container.viewContext
    }

    private init() {
        container = NSPersistentContainer(name: "EarnedRecess")
        container.loadPersistentStores { description, error in
            if let error {
                print("CoreData failed to load store '\(description.url?.lastPathComponent ?? "unknown")': \(error.localizedDescription). Falling back to in-memory store.")
                let inMemoryDescription = NSPersistentStoreDescription()
                inMemoryDescription.type = NSInMemoryStoreType
                self.container.persistentStoreDescriptions = [inMemoryDescription]
                self.container.loadPersistentStores { _, fallbackError in
                    if let fallbackError {
                        print("CoreData in-memory fallback also failed: \(fallbackError.localizedDescription)")
                    }
                }
            }
        }
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("CoreData save error: \(error.localizedDescription)")
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
