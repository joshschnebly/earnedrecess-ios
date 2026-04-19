import CoreData
import Foundation

class SettingsRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getOrCreateSettings() -> ParentSettings {
        let request = ParentSettings.fetchRequest()
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            return existing
        }
        return ParentSettings.createDefaults(context: context)
    }

    func save() {
        CoreDataStack.shared.save()
    }
}
